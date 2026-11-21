extends "res://tests/test_partidas.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var musica: Node = root.get_node("GestorMusica")
	var audio: Node = root.get_node("GestorAudioPartida")
	change_scene_to_file("res://Vistas/UI/MenuPrincipal.tscn")
	await scene_changed
	await create_timer(2.5).timeout
	var voz: AudioStreamPlayer = musica.voces[musica.activa]
	_verificar(voz.playing and voz.bus == "Musica", "El menú reproduce su tema por el bus propio.")
	current_scene.boton_jugar.pressed.emit()
	await scene_changed
	_verificar(musica.voces[musica.activa] == voz and voz.playing, "El selector conserva la voz del menú.")
	await create_timer(1.2).timeout
	change_scene_to_file("res://Vistas/UI/Tienda.tscn")
	await scene_changed
	await create_timer(3.2).timeout
	_verificar(musica.contexto == "tienda" and not voz.playing, "La tienda completa el fundido y libera la voz anterior.")
	current_scene.call("_regresar")
	await scene_changed
	_verificar(musica.contexto == "menu" and musica._marca_menu > 0, "La vuelta recupera la marca del tema principal.")
	for id in ["francia","alamein","berlin"]:
		var c := await _abrir_mision(id)
		voz = musica.voces[musica.activa]
		_verificar(musica.contexto == id and voz.playing and voz.stream.loop, "Bucle de " + id)
		await create_timer(1.5).timeout
		c.call("_cambiar_pausa", true)
		var marca := voz.get_playback_position()
		await create_timer(0.25, true).timeout
		_verificar(voz.stream_paused and absf(voz.get_playback_position() - marca) < 0.06, "Pausa musical " + id)
		c.call("_cambiar_pausa", false)
		c.jugador.call("_unhandled_input", _evento_disparo())
		await create_timer(2.8).timeout
		if id == "francia":
			audio.cuenta_atras(4.8)
			await create_timer(1.1).timeout
			_verificar(musica._cuenta and is_equal_approx(musica._reduccion, -4), "La cuenta atrás mantiene la atenuación entre pitidos.")
		c.call("_finalizar_combate", false)
		await create_timer(1.1).timeout
		_verificar(musica.contexto.is_empty() and not voz.playing, "El resultado queda en silencio.")
	_restaurar_progreso_usuario()
	print("Banda sonora: %d fallos." % _fallos)
	quit(1 if _fallos else 0)
