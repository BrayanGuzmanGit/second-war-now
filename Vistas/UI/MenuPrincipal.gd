extends Control
class_name MenuPrincipal

const ESCENA_MISIONES := "res://Vistas/UI/MenuMisiones.tscn"
const ESCENA_TIENDA := "res://Vistas/UI/Tienda.tscn"
const DURACION_APARICION_BOTON := 0.8
const RETRASO_ENTRE_BOTONES := 0.35

signal aparicion_terminada

@onready var boton_jugar: Button = $BotonJugar
@onready var boton_tienda: Button = $BotonTienda
@onready var boton_salir: Button = $BotonSalir
@onready var fondo: TextureRect = $Fondo

var es_intro := false
var ajustes: Control
var _botones: Array[Button]
var _animaciones_hover: Dictionary = {}


func _ready() -> void:
	if not es_intro:
		get_node("/root/GestorMusica").solicitar("menu")
	var indicador := PanelContainer.new()
	indicador.set_script(preload("res://Vistas/UI/IndicadorMonedas.gd"))
	add_child(indicador)
	boton_jugar.pressed.connect(_iniciar_juego)
	boton_tienda.pressed.connect(_abrir_tienda)
	boton_salir.pressed.connect(_salir)
	ajustes = preload("res://Vistas/UI/PanelSonido.gd").new()
	ajustes.desde_menu = true
	add_child(ajustes)
	ajustes.visible = not es_intro
	_botones = [boton_jugar, boton_tienda, boton_salir]
	for boton in _botones:
		boton.mouse_entered.connect(_animar_estado_boton.bind(boton, true))
		boton.mouse_exited.connect(_animar_estado_boton.bind(boton, false))


func terminar_intro() -> void:
	get_node("/root/GestorMusica").solicitar("menu")
	ajustes.show()

func preparar_para_aparicion() -> void:
	fondo.show()
	fondo.modulate.a = 0.0
	for boton in _botones:
		boton.modulate.a = 0.0
		boton.scale = Vector2(0.98, 0.98)
		boton.pivot_offset = boton.size * 0.5
		boton.disabled = true


func iniciar_animacion_aparicion() -> void:
	var aparicion_fondo := create_tween()
	aparicion_fondo.tween_property(fondo, "modulate:a", 1.0, 0.65)

	for indice in range(_botones.size()):
		var boton := _botones[indice]
		var animacion := create_tween()
		if indice > 0:
			animacion.tween_interval(RETRASO_ENTRE_BOTONES * indice)
		animacion.tween_property(
			boton,
			"modulate:a",
			1.0,
			DURACION_APARICION_BOTON
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		animacion.parallel().tween_property(
			boton,
			"scale",
			Vector2.ONE,
			DURACION_APARICION_BOTON
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if indice == _botones.size() - 1:
			animacion.finished.connect(_al_terminar_aparicion)


func _al_terminar_aparicion() -> void:
	for boton in _botones:
		boton.disabled = false
	aparicion_terminada.emit()


func _animar_estado_boton(boton: Button, resaltado: bool) -> void:
	if boton.disabled:
		return
	var identidad := boton.get_instance_id()
	if _animaciones_hover.has(identidad):
		var animacion_anterior: Tween = _animaciones_hover[identidad]
		if animacion_anterior.is_running():
			animacion_anterior.kill()

	var animacion := create_tween()
	_animaciones_hover[identidad] = animacion
	animacion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(
		boton,
		"scale",
		Vector2(1.025, 1.025) if resaltado else Vector2.ONE,
		0.16
	)
	animacion.parallel().tween_property(
		boton,
		"modulate",
		Color(1.0, 1.0, 0.93, 1.0) if resaltado else Color.WHITE,
		0.16
	)


func _iniciar_juego() -> void:
	var resultado := get_tree().change_scene_to_file(ESCENA_MISIONES)
	if resultado != OK:
		push_error("No se pudo abrir el menú de misiones: %s (código %d)." % [ESCENA_MISIONES, resultado])


func _abrir_tienda() -> void:
	var resultado := get_tree().change_scene_to_file(ESCENA_TIENDA)
	if resultado != OK:
		push_error("No se pudo abrir la tienda: %s (código %d)." % [ESCENA_TIENDA, resultado])


func _salir() -> void:
	get_tree().quit()
