extends SceneTree

## Proceso de lectura usado por test_campana: no modifica el archivo recibido.
func _initialize() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var guardado: Node = root.get_node("GestorGuardado")
	if not OS.get_cmdline_user_args().is_empty():
		guardado.ruta_archivo = OS.get_cmdline_user_args()[0]
		guardado.cargar_progreso()
	var datos: Dictionary = root.get_node("GestorGuardado").progreso
	var correcto: bool = datos["misiones_completadas"] == ["francia", "alamein", "berlin"] and datos["cosmetico_equipado"] == "TNQ-03" and datos["cosmeticos_comprados"].has("TNQ-03")
	print("Guardado tras reinicio: ", correcto)
	quit(0 if correcto else 1)
