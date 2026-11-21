extends "res://tests/test_partidas.gd"

## Recorrido reproducible con audio real del mezclador de Godot (Movie Maker).
func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var mision := "francia"
	for argumento in OS.get_cmdline_user_args():
		if argumento in ["francia", "alamein", "berlin"]:
			mision = argumento
	await _jugar_mision(mision)
	await create_timer(0.5).timeout
	_restaurar_progreso_usuario()
	print("Recorrido audiovisual %s: %d fallos." % [mision, _fallos])
	quit(1 if _fallos else 0)
