extends Control

const ESCENA_MENU_PRINCIPAL := "res://Vistas/UI/MenuPrincipal.tscn"
const DURACION_INTRODUCCION_SEGUNDOS := 10.03
const INICIO_APARICION_MENU_SEGUNDOS := 8.15
const DURACION_FUNDIDO_AUDIO := 1.6
const VOLUMEN_MENU_DB := -18.0

@onready var reproductor_video: VideoStreamPlayer = $Video
@onready var fotograma_congelado: TextureRect = $FotogramaCongelado
@onready var barra_progreso: ProgressBar = $Interfaz/PanelCarga/BarraProgreso
@onready var etiqueta_porcentaje: Label = $Interfaz/PanelCarga/Porcentaje
@onready var etiqueta_estado: Label = $Interfaz/PanelCarga/Estado
@onready var etiqueta_error: Label = $Interfaz/PanelCarga/Error
@onready var boton_reintentar: Button = $Interfaz/PanelCarga/Reintentar
@onready var titulo: Label = $Interfaz/Titulo
@onready var subtitulo: Label = $Interfaz/Subtitulo
@onready var panel_carga: Control = $Interfaz/PanelCarga

var _progreso_recursos: Array = []
var _progreso_carga := 0.0
var _tiempo_intro := 0.0
var _escena_menu: PackedScene
var _menu_instanciado: MenuPrincipal
var _transicion_iniciada := false
var _animacion_menu_iniciada := false
var _animacion_menu_terminada := false


func _ready() -> void:
	reproductor_video.bus = "Videos"
	boton_reintentar.pressed.connect(_solicitar_carga_menu)
	reproductor_video.loop = true
	reproductor_video.play()
	_solicitar_carga_menu()


func _process(delta: float) -> void:
	_tiempo_intro = minf(_tiempo_intro + delta, DURACION_INTRODUCCION_SEGUNDOS)
	if _escena_menu == null and etiqueta_error.visible == false:
		_actualizar_carga_menu()
	_actualizar_interfaz_progreso()
	if (
		_tiempo_intro >= INICIO_APARICION_MENU_SEGUNDOS
		and _escena_menu != null
		and not _animacion_menu_iniciada
	):
		_iniciar_aparicion_menu()
	if (
		_tiempo_intro >= DURACION_INTRODUCCION_SEGUNDOS
		and _animacion_menu_terminada
		and not _transicion_iniciada
	):
		_congelar_video_para_menu()


func _solicitar_carga_menu() -> void:
	get_node("/root/GestorMusica").silenciar()
	if _menu_instanciado != null:
		_menu_instanciado.queue_free()
		_menu_instanciado = null
	_animacion_menu_iniciada = false
	_animacion_menu_terminada = false
	_transicion_iniciada = false
	_tiempo_intro = 0.0
	titulo.modulate.a = 1.0
	subtitulo.modulate.a = 1.0
	panel_carga.modulate.a = 1.0
	fotograma_congelado.texture = null
	fotograma_congelado.visible = false
	reproductor_video.visible = true
	reproductor_video.volume_db = 0.0
	reproductor_video.stream_position = 0.0
	reproductor_video.play()

	etiqueta_error.visible = false
	boton_reintentar.visible = false
	etiqueta_estado.text = "CARGANDO RECURSOS..."
	_progreso_carga = 0.0
	_progreso_recursos.clear()
	_escena_menu = null

	var resultado := ResourceLoader.load_threaded_request(ESCENA_MENU_PRINCIPAL)
	if resultado != OK:
		_mostrar_error_carga(
			"No se pudo iniciar la carga del menú (código %d)." % resultado
		)


func _actualizar_carga_menu() -> void:
	var estado_carga := ResourceLoader.load_threaded_get_status(
		ESCENA_MENU_PRINCIPAL,
		_progreso_recursos
	)
	if not _progreso_recursos.is_empty():
		_progreso_carga = clampf(float(_progreso_recursos[0]), 0.0, 1.0)

	match estado_carga:
		ResourceLoader.THREAD_LOAD_LOADED:
			var recurso_cargado := ResourceLoader.load_threaded_get(ESCENA_MENU_PRINCIPAL)
			if recurso_cargado is PackedScene:
				_escena_menu = recurso_cargado
				_progreso_carga = 1.0
				etiqueta_estado.text = "PREPARANDO MENÚ..."
			else:
				_mostrar_error_carga("El recurso del menú no es una escena válida.")
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_mostrar_error_carga("Godot no pudo cargar la escena del menú principal.")


func _actualizar_interfaz_progreso() -> void:
	# El porcentaje combina la carga real de la escena siguiente con la intro de diez segundos.
	var progreso_intro := _tiempo_intro / DURACION_INTRODUCCION_SEGUNDOS
	var progreso_total := minf(_progreso_carga, progreso_intro)
	barra_progreso.value = progreso_total * 100.0
	etiqueta_porcentaje.text = "%02d%%" % roundi(progreso_total * 100.0)


func _iniciar_aparicion_menu() -> void:
	_animacion_menu_iniciada = true
	_menu_instanciado = _escena_menu.instantiate() as MenuPrincipal
	if _menu_instanciado == null:
		_mostrar_error_carga("La escena del menú no contiene un controlador MenuPrincipal.")
		return

	_menu_instanciado.es_intro = true
	add_child(_menu_instanciado)
	_menu_instanciado.preparar_para_aparicion()
	_menu_instanciado.aparicion_terminada.connect(_al_terminar_aparicion_menu)
	_menu_instanciado.iniciar_animacion_aparicion()

	var fundido_interfaz := create_tween().set_parallel(true)
	fundido_interfaz.tween_property(titulo, "modulate:a", 0.0, 0.6)
	fundido_interfaz.tween_property(subtitulo, "modulate:a", 0.0, 0.6)
	fundido_interfaz.tween_property(panel_carga, "modulate:a", 0.0, 0.6)
	var fundido_audio := create_tween()
	fundido_audio.tween_property(
		reproductor_video,
		"volume_db",
		VOLUMEN_MENU_DB,
		DURACION_FUNDIDO_AUDIO
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _al_terminar_aparicion_menu() -> void:
	_animacion_menu_terminada = true


func _congelar_video_para_menu() -> void:
	_transicion_iniciada = true
	var textura_video := reproductor_video.get_video_texture()
	if textura_video == null:
		_mostrar_error_carga("No se pudo capturar el último fotograma de la introducción.")
		return
	var imagen_video := textura_video.get_image()
	if imagen_video == null or imagen_video.is_empty():
		_mostrar_error_carga("La introducción aún no tiene un fotograma disponible para el menú.")
		return

	# Una copia estática conserva la imagen antes de detener el audio del video.
	fotograma_congelado.texture = ImageTexture.create_from_image(imagen_video)
	fotograma_congelado.visible = true
	reproductor_video.visible = false
	reproductor_video.stop()
	_menu_instanciado.terminar_intro()


func _mostrar_error_carga(mensaje: String) -> void:
	push_error(mensaje)
	etiqueta_estado.text = "NO SE PUDO PREPARAR LA CAMPAÑA"
	etiqueta_error.text = mensaje
	etiqueta_error.visible = true
	panel_carga.modulate.a = 1.0
	boton_reintentar.visible = true
