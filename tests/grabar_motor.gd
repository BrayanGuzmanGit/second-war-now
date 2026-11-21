extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var grabacion := AudioEffectRecord.new()
	grabacion.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,grabacion)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-pausa"))
	for id in ["francia","alamein","berlin"]:
		var c: Node = await _abrir_mision(id)
		grabacion.set_recording_active(true)
		await create_timer(2.0).timeout
		Input.action_press("Derecha")
		await create_timer(1.5).timeout
		Input.action_release("Derecha")
		await create_timer(1.5).timeout
		get_node_audio().evento("disparo",c.jugador.global_position,"estandar")
		await create_timer(1.0).timeout
		grabacion.set_recording_active(false)
		grabacion.get_recording().save_to_wav(ProjectSettings.globalize_path("res://.godot/qa-pausa/motor-"+id+".wav"))
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	_restaurar_progreso_usuario()
	print("Muestras de motor: tres archivos.")
	quit()

func get_node_audio() -> Node:
	return root.get_node("GestorAudioPartida")
