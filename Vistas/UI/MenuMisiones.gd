extends Control

const ESCENA_CINEMATICA := "res://Vistas/UI/CinematicaPanel.tscn"
const ESCENA_MENU := "res://Vistas/UI/MenuPrincipal.tscn"

@onready var botones: Dictionary = {
	"francia": $Francia,
	"alamein": $Alamein,
	"berlin": $Berlin,
}
@onready var boton_regresar: Button = $Regresar
@onready var boton_reiniciar: Button = $ReiniciarMisiones
@onready var dialogo_reinicio: ConfirmationDialog = $DialogoReinicio
@onready var estado_reinicio: Label = $EstadoReinicio


func _ready() -> void:
	get_node("/root/GestorMusica").solicitar("menu")
	var indicador := PanelContainer.new()
	indicador.set_script(preload("res://Vistas/UI/IndicadorMonedas.gd"))
	add_child(indicador)
	boton_regresar.pressed.connect(_regresar)
	boton_reiniciar.pressed.connect(_confirmar_reinicio)
	dialogo_reinicio.confirmed.connect(_reiniciar_misiones)
	for id_mision in botones:
		var boton: Button = botones[id_mision]
		boton.pressed.connect(_iniciar_mision.bind(id_mision))
	_actualizar_misiones()


func _actualizar_misiones() -> void:
	var completadas: Array = GestorGuardado.progreso.get("misiones_completadas", [])
	for mision in GestorMisiones.obtener_misiones():
		var id_mision: String = mision["id"]
		var boton: Button = botones[id_mision]
		var esta_completada: bool = completadas.has(id_mision)
		var estado := "Disponible"
		if esta_completada:
			estado = "Completada"
		elif not mision["desbloqueada"]:
			estado = "Bloqueada"
		boton.text = "%d — %s · %s" % [mision["anio"], mision["nombre"], estado]
		boton.disabled = not mision["desbloqueada"]
		boton.modulate = Color(0.62, 0.62, 0.62, 1.0) if boton.disabled else Color.WHITE
		boton.tooltip_text = ""
		if boton.disabled:
			boton.tooltip_text = "Completa la misión anterior para desbloquear esta misión."
		elif esta_completada:
			boton.tooltip_text = "Ya completaste esta misión. Puedes volver a jugarla."


func _confirmar_reinicio() -> void:
	dialogo_reinicio.popup_centered()


func _reiniciar_misiones() -> void:
	if not GestorGuardado.reiniciar_progreso_misiones():
		estado_reinicio.text = "No se pudo guardar el reinicio. Inténtalo de nuevo."
		estado_reinicio.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		estado_reinicio.show()
		return

	GestorMisiones.id_mision_actual = "francia"
	_actualizar_misiones()
	estado_reinicio.text = "Campaña reiniciada. Francia es la única misión disponible."
	estado_reinicio.add_theme_color_override("font_color", Color(0.75, 0.9, 0.72))
	estado_reinicio.show()


func _iniciar_mision(id_mision: String) -> void:
	if not GestorMisiones.seleccionar_mision(id_mision):
		return
	var resultado := get_tree().change_scene_to_file(ESCENA_CINEMATICA)
	if resultado != OK:
		push_error("No se pudo abrir la ficha histórica (código %d)." % resultado)


func _regresar() -> void:
	var resultado := get_tree().change_scene_to_file(ESCENA_MENU)
	if resultado != OK:
		push_error("No se pudo regresar al menú principal (código %d)." % resultado)
