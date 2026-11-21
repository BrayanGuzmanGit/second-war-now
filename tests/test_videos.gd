extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var g: Node = root.get_node("GestorGuardado")
	var misiones: Node = root.get_node("GestorMisiones")
	g.progreso["misiones_completadas"] = ["francia","alamein","berlin"]
	for id in ["francia","alamein","berlin"]:
		misiones.seleccionar_mision(id)
		change_scene_to_file("res://Vistas/UI/CinematicaPanel.tscn")
		await scene_changed
		await process_frame
		var panel := current_scene
		var video: Node = panel.video_mision
		_verificar(is_instance_valid(video), "Introducción disponible: " + id)
		if is_instance_valid(video):
			_verificar(video.reproductor.bus == "Videos" and root.get_node("GestorMusica").contexto.is_empty(), "Introducción usa el canal independiente.")
			_verificar(video.reproductor.is_playing(), "Video reproduce: " + id)
			_verificar(not panel.get_node("Centro").visible, "La ficha espera al video.")
			if OS.get_cmdline_user_args().has("reproduccion"):
				await _capturar_video(video, id + "-introduccion")
				var inicio := Time.get_ticks_msec()
				await video.finalizado
				_verificar(Time.get_ticks_msec() - inicio < 14000, "Fin natural antes del límite de recuperación.")
			else:
				await create_timer(0.3).timeout
				if id == "francia":
					var tecla := InputEventKey.new()
					tecla.keycode = KEY_ESCAPE
					tecla.pressed = true
					Input.parse_input_event(tecla)
				else:
					video.get("_boton").pressed.emit()
			await process_frame
		_verificar(root.get_node("GestorMusica").contexto == "informe" and panel.boton_continuar.disabled == false and panel.get_node("Centro").visible, "Ficha accesible al terminar/omitir.")
		var c: Node = await _abrir_mision(id)
		c.set_process(false)
		c.call("_finalizar_combate", true)
		var saldo: int = g.obtener_saldo()
		var capas := _videos(c)
		_verificar(capas.size() == 1, "Las tres victorias tienen video: " + id)
		_verificar(g.progreso["misiones_completadas"].has(id), "Progreso guardado antes del video: " + id)
		_verificar(not root.get_node("GestorAudioPartida").activo, "Audio de combate detenido durante victoria.")
		if not capas.is_empty():
			_verificar(capas[0].reproductor.bus == "Videos", "Victoria usa el canal independiente.")
			_verificar(not c.hud.panel_resultado.visible, "Resultado espera al cierre del video.")
			if OS.get_cmdline_user_args().has("reproduccion"):
				await _capturar_video(capas[0], id + "-victoria")
				var inicio := Time.get_ticks_msec()
				await capas[0].finalizado
				var duracion := Time.get_ticks_msec() - inicio
				_verificar(duracion > 7000 and duracion < 14000, "Victoria se reproduce completa antes del límite de recuperación.")
			else:
				await create_timer(0.3).timeout
				if id == "berlin":
					var tecla := InputEventKey.new()
					tecla.keycode = KEY_ESCAPE
					tecla.pressed = true
					Input.parse_input_event(tecla)
					tecla = InputEventKey.new()
					tecla.keycode = KEY_ESCAPE
					Input.parse_input_event(tecla)
				else:
					capas[0].get("_boton").pressed.emit()
			await process_frame
		_verificar(c.hud.panel_resultado.visible, "Resultado/epílogo disponible tras victoria.")
		if id == "berlin":
			_verificar(c.hud.etiqueta_resumen.text.contains("CAMPAÑA COMPLETADA"), "El video de Berlín conserva el epílogo.")
			_verificar(_videos(c).is_empty(), "El video de Berlín se libera al cerrar.")
		_verificar(g.obtener_saldo() == saldo, "Video no duplica recompensa.")
		c.call("_finalizar_combate", true)
		_verificar(_videos(c).is_empty(), "Resultado repetido no repite video.")
	var derrota: Node = await _abrir_mision("francia")
	derrota.call("_finalizar_combate", false)
	_verificar(_videos(derrota).is_empty(), "Derrota no reproduce victoria.")
	var sin_recurso = preload("res://Vistas/UI/VideoMision.gd").mostrar(derrota, "res://ausente.ogv")
	_verificar(sin_recurso == null, "Fallo de recurso permite seguir con panel.")
	_restaurar_progreso_usuario()
	print("Videos de misión: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _videos(padre: Node) -> Array:
	var encontrados: Array = []
	for hijo in padre.get_children():
		if hijo is VideoMision and not hijo.is_queued_for_deletion():
			encontrados.append(hijo)
	return encontrados

func _capturar_video(video: Node, nombre: String) -> void:
	await create_timer(1.0).timeout
	_verificar(video.reproductor.stream_position > 0.0, "El decodificador avanza: " + nombre)
	print("Reproduciendo " + nombre)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-videos"))
		root.get_texture().get_image().save_png("res://.godot/qa-videos/" + nombre + ".png")
