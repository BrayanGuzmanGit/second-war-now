extends Control

const ESCENA_COMBATE := "res://Niveles/nivel_1.tscn"
const ESCENA_SELECTOR := "res://Vistas/UI/MenuMisiones.tscn"
const ESTILO = preload("res://Vistas/UI/EstiloInforme.gd")
var video_mision: CanvasLayer
var etiqueta_titulo: Label
var etiqueta_fecha: Label
var etiqueta_contexto: Label
var boton_continuar: Button
var controles: Dictionary
var _mision: Dictionary
var _cambiando := false
var _escribiendo := false
var _tiempo_texto := 0.0
var _fundido: Tween
var _frame_retorno := -1
var _teclas_pendientes: Array[int] = []

func _ready() -> void:
	_mision = GestorMisiones.obtener_mision_actual()
	var tactica: Dictionary = preload("res://Modelos/DatosCampana.gd").obtener(_mision["id"])
	var aviso := ""
	if tactica["evacuacion_segundos"] > 0:
		aviso = "Tras destruir al enemigo tendrás %d segundos para evacuar. Si el plazo vence, los refuerzos cortarán la retirada." % tactica["evacuacion_segundos"]
	ESTILO.decorar($Centro/Panel)
	controles = ESTILO.construir($Centro/Panel/Contenido, _mision, aviso)
	etiqueta_titulo = controles.titulo
	etiqueta_fecha = controles.fecha
	etiqueta_contexto = controles.contexto
	boton_continuar = controles.continuar
	boton_continuar.pressed.connect(_continuar)
	controles.volver.pressed.connect(_volver)
	controles.revelar.pressed.connect(_revelar)
	controles.repetir.pressed.connect(_repetir_video)
	_configurar_foco()
	_actualizar_video_disponible()
	_reproducir_video(false)

func _actualizar_video_disponible() -> void:
	var ruta: String = _mision.get("video_introduccion", "")
	var disponible := not ruta.is_empty() and ResourceLoader.exists(ruta)
	controles.repetir.disabled = not disponible
	controles.disponibilidad.text = "" if disponible else "Introducción no disponible."

func _configurar_foco() -> void:
	# Orden estable: el botón de revelar se salta automáticamente cuando se oculta.
	var botones: Array = []
	for candidato in [controles.revelar,controles.repetir,controles.volver,boton_continuar]:
		if candidato.visible and not candidato.disabled:
			botones.append(candidato)
	focus_next = get_path_to(botones[0])
	focus_previous = get_path_to(botones[-1])
	focus_neighbor_bottom = focus_next
	focus_neighbor_right = focus_next
	focus_neighbor_top = focus_previous
	focus_neighbor_left = focus_previous
	for i in botones.size():
		var actual: Button = botones[i]
		var previo: Button = botones[(i-1+botones.size())%botones.size()]
		var siguiente: Button = botones[(i+1)%botones.size()]
		actual.focus_next = actual.get_path_to(siguiente)
		actual.focus_previous = actual.get_path_to(previo)
		actual.focus_neighbor_left = actual.focus_previous
		actual.focus_neighbor_top = actual.focus_previous
		actual.focus_neighbor_right = actual.focus_next
		actual.focus_neighbor_bottom = actual.focus_next

func _cancelar_presentacion() -> void:
	_escribiendo = false
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()

func _reproducir_video(repeticion: bool) -> void:
	if _cambiando or is_instance_valid(video_mision):
		return
	_cancelar_presentacion()
	$Centro.hide()
	boton_continuar.disabled = true
	video_mision = preload("res://Vistas/UI/VideoMision.gd").mostrar(self, _mision.get("video_introduccion", ""))
	if video_mision != null:
		await video_mision.finalizado
		video_mision = null
	else:
		controles.repetir.disabled = true
		controles.disponibilidad.text = "Introducción no disponible."
	_mostrar_informe(repeticion)

func _mostrar_informe(completo: bool) -> void:
	get_node("/root/GestorMusica").solicitar("informe")
	# No reutilizar la pulsación que acaba de omitir el video, incluidos sus ecos.
	_frame_retorno = Engine.get_process_frames()
	_teclas_pendientes.clear()
	for tecla in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		if Input.is_key_pressed(tecla):
			_teclas_pendientes.append(tecla)
	$Centro.show()
	$Centro.modulate.a = 0.0
	_fundido = create_tween()
	_fundido.tween_property($Centro,"modulate:a",1.0,0.25)
	boton_continuar.disabled = false
	_tiempo_texto = 0.0
	_escribiendo = not completo
	etiqueta_contexto.visible_characters = -1 if completo else 0
	controles.revelar.visible = not completo
	_configurar_foco()
	grab_focus()

func _process(delta: float) -> void:
	if not _escribiendo:
		return
	_tiempo_texto += delta
	etiqueta_contexto.visible_characters = mini(int(_tiempo_texto / 0.018), etiqueta_contexto.text.length())
	if etiqueta_contexto.visible_characters >= etiqueta_contexto.text.length():
		_revelar()

func _revelar() -> void:
	_escribiendo = false
	etiqueta_contexto.visible_characters = -1
	if controles.revelar.has_focus():
		grab_focus()
	controles.revelar.hide()
	_configurar_foco()

func _input(event: InputEvent) -> void:
	if is_instance_valid(video_mision) or _cambiando or not event is InputEventKey:
		return
	if not event.pressed:
		_teclas_pendientes.erase(event.keycode)
		return
	if event.echo or event.keycode in _teclas_pendientes or Engine.get_process_frames() == _frame_retorno:
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_volver()
	elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and has_focus():
		get_viewport().set_input_as_handled()
		if _escribiendo:
			_revelar()
		else:
			_continuar()

func _repetir_video() -> void:
	_reproducir_video(true)

func _continuar() -> void:
	_cambiar_escena(ESCENA_COMBATE)

func _volver() -> void:
	_cambiar_escena(ESCENA_SELECTOR)

func _cambiar_escena(ruta: String) -> void:
	if is_instance_valid(video_mision) or _cambiando:
		return
	_cambiando = true
	_cancelar_presentacion()
	var resultado := get_tree().change_scene_to_file(ruta)
	if resultado != OK:
		_cambiando = false
		controles.disponibilidad.text = "No se pudo abrir la pantalla. Inténtalo de nuevo."
		push_error("No se pudo cambiar de escena (código %d)." % resultado)

func _exit_tree() -> void:
	_cancelar_presentacion()
