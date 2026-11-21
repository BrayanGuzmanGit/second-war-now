extends CanvasLayer
class_name HUD

signal volver_al_menu
signal reintentar_guardado
signal municion_seleccionada(tipo: String)
signal apuntado_joystick(actual: Vector2)

const RADIO_ARRASTRE_JOYSTICK := 52.0
const VECTOR_JOYSTICK_INICIAL := Vector2(0.48, -0.36)

@onready var etiqueta_estado: Label = $Interfaz/PanelEstado/Contenido/Estado
@onready var etiqueta_turno: Label = $Interfaz/PanelEstado/Contenido/Turno
@onready var etiqueta_mision: Label = $Interfaz/PanelEstado/Contenido/Mision
@onready var etiqueta_objetivo: Label = $Interfaz/PanelEstado/Contenido/Objetivo
@onready var etiqueta_vida_jugador: Label = $Interfaz/PanelEstado/Contenido/VidaJugador
@onready var etiqueta_combustible: Label = $Interfaz/PanelEstado/Contenido/Combustible
@onready var etiqueta_vida_enemigo: Label = $Interfaz/PanelEstado/Contenido/VidaEnemigo
@onready var indicacion_joystick: Label = $Interfaz/IndicacionJoystick
@onready var base_joystick: Panel = $Interfaz/JoystickBase
@onready var control_joystick: Panel = $Interfaz/JoystickBase/Perilla
@onready var boton_municion_seleccionada: Button = (
	$Interfaz/PanelMunicion/Contenido/BotonMunicionSeleccionada
)
@onready var menu_desplegable_municion: PanelContainer = $Interfaz/MenuDesplegable
@onready var panel_aviso_retirada: Control = $Interfaz/AvisoRetirada
@onready var etiqueta_titulo_retirada: Label = $Interfaz/AvisoRetirada/Panel/Contenido/Titulo
@onready var etiqueta_texto_retirada: Label = $Interfaz/AvisoRetirada/Panel/Contenido/Mensaje
@onready var panel_resultado: Control = $Interfaz/PanelResultado
@onready var etiqueta_resultado: Label = $Interfaz/PanelResultado/Centro/Contenido/Resultado
@onready var boton_menu: Button = $Interfaz/PanelResultado/Centro/Contenido/BotonMenu
@onready var etiqueta_resumen: RichTextLabel = $Interfaz/PanelResultado/Centro/Contenido/Resumen
@onready var botones_municion: Dictionary = {
	"estandar": $Interfaz/MenuDesplegable/Opciones/Estandar,
	"pesado": $Interfaz/MenuDesplegable/Opciones/Pesado,
	"dispersion": $Interfaz/MenuDesplegable/Opciones/Dispersion,
	"bombardeo": $Interfaz/MenuDesplegable/Opciones/Bombardeo,
	"incendiario": $Interfaz/MenuDesplegable/Opciones/Incendiario,
}

var _turno_jugador_activo := true
var _municiones_disponibles: Array[String] = []
var _municion_seleccionada := "estandar"
var _arrastrando_joystick := false
var _vector_joystick := VECTOR_JOYSTICK_INICIAL
var _cierre_aviso: Tween


func _ready() -> void:
	var sonido := preload("res://Vistas/UI/PanelSonido.gd").new()
	$Interfaz.add_child(sonido)
	panel_resultado.visible = false
	panel_aviso_retirada.visible = false
	menu_desplegable_municion.visible = false
	_actualizar_posicion_control_joystick()
	actualizar_turno("TU TURNO", true)
	boton_menu.pressed.connect(func() -> void: volver_al_menu.emit())
	$Interfaz/PanelResultado/Centro/Contenido/ReintentarGuardado.pressed.connect(
		func() -> void: reintentar_guardado.emit()
	)
	boton_municion_seleccionada.pressed.connect(_alternar_menu_municion)
	for tipo in botones_municion:
		var boton: Button = botones_municion[tipo]
		var fila: HBoxContainer = boton.get_node("Contenido")
		fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var nombre: Label = fila.get_node("Nombre")
		nombre.text += "\n" + GestorProyectiles.descripcion_dano(tipo)
		boton.pressed.connect(_seleccionar_municion.bind(tipo))


func actualizar_estado(texto: String) -> void:
	etiqueta_estado.text = texto


func actualizar_turno(texto: String, es_turno_jugador: bool) -> void:
	etiqueta_turno.text = texto
	etiqueta_turno.add_theme_color_override(
		"font_color",
		Color(0.72, 0.9, 0.55) if es_turno_jugador else Color(1.0, 0.62, 0.48)
	)
	_turno_jugador_activo = es_turno_jugador
	indicacion_joystick.visible = es_turno_jugador
	base_joystick.visible = es_turno_jugador
	if not es_turno_jugador:
		_arrastrando_joystick = false
	boton_municion_seleccionada.disabled = not es_turno_jugador
	if not es_turno_jugador:
		menu_desplegable_municion.hide()
	_actualizar_botones_municion()


func obtener_vector_apuntado_joystick() -> Vector2:
	return _vector_joystick


func actualizar_mision(nombre: String, objetivo: String) -> void:
	etiqueta_mision.text = nombre
	etiqueta_objetivo.text = _ajustar_ancho_texto(objetivo, 55)


func _ajustar_ancho_texto(texto: String, maximo_caracteres: int) -> String:
	var lineas := PackedStringArray()
	var linea_actual := ""
	for palabra in texto.split(" ", false):
		var longitud_nueva := linea_actual.length() + palabra.length()
		if not linea_actual.is_empty():
			longitud_nueva += 1
		if longitud_nueva > maximo_caracteres and not linea_actual.is_empty():
			lineas.append(linea_actual)
			linea_actual = palabra
		elif linea_actual.is_empty():
			linea_actual = palabra
		else:
			linea_actual += " " + palabra
	if not linea_actual.is_empty():
		lineas.append(linea_actual)
	return "\n".join(lineas)


func actualizar_vida_jugador(actual: float, maxima: float) -> void:
	etiqueta_vida_jugador.text = "Jugador: %d / %d HP" % [roundi(actual), roundi(maxima)]


func actualizar_combustible(actual: float, maximo: float) -> void:
	etiqueta_combustible.text = "Combustible: %d / %d" % [roundi(actual), roundi(maximo)]


func mostrar_aviso_retirada(mensaje: String) -> void:
	if _cierre_aviso != null and _cierre_aviso.is_valid():
		_cierre_aviso.kill()
	etiqueta_combustible.text = "Combustible: ILIMITADO"
	etiqueta_titulo_retirada.text = "¡POSICIÓN NEUTRALIZADA!"
	etiqueta_texto_retirada.text = mensaje
	panel_aviso_retirada.visible = true
	panel_aviso_retirada.modulate.a = 0.0
	panel_aviso_retirada.scale = Vector2(0.88, 0.88)
	panel_aviso_retirada.position.y = 92.0

	# La entrada combina desvanecimiento, desplazamiento y rebote suave para destacar la nueva fase.
	var animacion := create_tween().set_parallel(true)
	animacion.tween_property(panel_aviso_retirada, "modulate:a", 1.0, 0.35)
	animacion.tween_property(panel_aviso_retirada, "scale", Vector2.ONE, 0.45).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	animacion.tween_property(panel_aviso_retirada, "position:y", 110.0, 0.4).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)

	var cierre := create_tween()
	_cierre_aviso = cierre
	cierre.tween_interval(6.0)
	cierre.tween_property(panel_aviso_retirada, "modulate:a", 0.0, 0.45)
	cierre.tween_callback(func() -> void: panel_aviso_retirada.visible = false)


func actualizar_objetivo(texto: String, posicion: int, total: int) -> void:
	etiqueta_objetivo.text = _ajustar_ancho_texto(texto, 55)
	$Interfaz/PanelEstado/Contenido/Posicion.text = "Posición defensiva: %d / %d" % [posicion, total]


func actualizar_cuenta_atras(segundos: float) -> void:
	var etiqueta: Label = $Interfaz/CuentaAtras
	etiqueta.visible = segundos >= 0.0
	etiqueta.text = "EVACÚA EN %02d s" % ceili(maxf(segundos, 0.0))
	etiqueta.modulate = Color(1.0, 0.4, 0.3) if segundos <= 10.0 else Color(1.0, 0.87, 0.55)


func actualizar_vida_enemigo(actual: float, maxima: float) -> void:
	etiqueta_vida_enemigo.text = "Enemigo: %d / %d HP" % [roundi(actual), roundi(maxima)]


func actualizar_municion(seleccionada: String, disponibles: Array[String]) -> void:
	_municion_seleccionada = seleccionada
	_municiones_disponibles = disponibles.duplicate()
	_actualizar_botones_municion()


func _actualizar_botones_municion() -> void:
	for tipo in botones_municion:
		var boton: Button = botones_municion[tipo]
		var disponible := _municiones_disponibles.has(tipo)
		boton.disabled = not _turno_jugador_activo or not disponible
		var etiqueta_estado: Label = boton.get_node("Contenido/Estado")
		if tipo == _municion_seleccionada:
			etiqueta_estado.text = "SELECCIONADA"
		elif disponible:
			etiqueta_estado.text = "DISPONIBLE"
		else:
			etiqueta_estado.text = "AGOTADA"

	boton_municion_seleccionada.text = (
		"Munición seleccionada: %s  ▾" % _municion_seleccionada.capitalize()
	)
	if botones_municion.has(_municion_seleccionada):
		var boton_seleccionado: Button = botones_municion[_municion_seleccionada]
		var icono: TextureRect = boton_seleccionado.get_node("Contenido/Icono")
		boton_municion_seleccionada.icon = icono.texture
	boton_municion_seleccionada.add_theme_constant_override("icon_max_width", 44)


func _alternar_menu_municion() -> void:
	if not _turno_jugador_activo:
		return
	if menu_desplegable_municion.visible:
		cerrar_selector(true)
	else:
		menu_desplegable_municion.show()
		get_node("/root/GestorAudioPartida").interfaz("abrir")

func cerrar_selector(voluntario := false) -> void:
	if not menu_desplegable_municion.visible:
		return
	menu_desplegable_municion.hide()
	if voluntario:
		get_node("/root/GestorAudioPartida").interfaz("cerrar")


func _seleccionar_municion(tipo: String) -> void:
	if not _turno_jugador_activo or not _municiones_disponibles.has(tipo):
		return
	municion_seleccionada.emit(tipo)


func _input(event: InputEvent) -> void:
	if get_node("/root/GestorAudioPartida").interfaz_abierta:
		_arrastrando_joystick = false
		return
	if _arrastrando_joystick:
		if event is InputEventMouseMotion:
			_actualizar_joystick_desde_posicion(event.position)
			get_viewport().set_input_as_handled()
			return
		if (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			_actualizar_joystick_desde_posicion(event.position)
			_arrastrando_joystick = false
			get_viewport().set_input_as_handled()
			return
	elif (
		_turno_jugador_activo
		and base_joystick.visible
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		var centro := base_joystick.get_global_rect().get_center()
		if event.position.distance_to(centro) <= base_joystick.size.x * 0.5:
			_arrastrando_joystick = true
			_actualizar_joystick_desde_posicion(event.position)
			get_viewport().set_input_as_handled()
			return
	if not menu_desplegable_municion.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		menu_desplegable_municion.hide()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var esta_sobre_menu := menu_desplegable_municion.get_global_rect().has_point(event.position)
		var esta_sobre_selector := boton_municion_seleccionada.get_global_rect().has_point(
			event.position
		)
		if not esta_sobre_menu and not esta_sobre_selector:
			cerrar_selector(true)


func _actualizar_joystick_desde_posicion(posicion: Vector2) -> void:
	var centro := base_joystick.get_global_rect().get_center()
	_actualizar_vector_joystick(posicion - centro)


func _actualizar_vector_joystick(desplazamiento: Vector2) -> void:
	var desplazamiento_limitado := desplazamiento.limit_length(RADIO_ARRASTRE_JOYSTICK)
	_vector_joystick = desplazamiento_limitado / RADIO_ARRASTRE_JOYSTICK
	_actualizar_posicion_control_joystick()
	apuntado_joystick.emit(_vector_joystick)


func _actualizar_posicion_control_joystick() -> void:
	var centro := base_joystick.size * 0.5
	var desplazamiento := _vector_joystick * RADIO_ARRASTRE_JOYSTICK
	control_joystick.position = centro + desplazamiento - control_joystick.size * 0.5


func mostrar_resultado(victoria: bool, resumen: String, guardado_correcto: bool) -> void:
	panel_resultado.mostrar(victoria, resumen, guardado_correcto, get_node("/root/GestorMisiones").obtener_mision_actual())
	panel_resultado.move_to_front()


func mostrar_recompensa(resultado: Dictionary) -> void:
	panel_resultado.actualizar_recompensa(resultado)
