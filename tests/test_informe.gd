extends "res://tests/test_core.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var g: Node = root.get_node("GestorGuardado")
	g.progreso["misiones_completadas"] = ["francia","alamein","berlin"]
	var inicial: Dictionary = g.progreso.duplicate(true)
	for id in ["francia","alamein","berlin"]:
		var panel: Node = await _abrir_informe(id)
		var video: Node = panel.video_mision
		await create_timer(0.3).timeout
		if id == "francia":
			await _tecla(KEY_ESCAPE)
		else:
			video.get("_boton").pressed.emit()
			await process_frame
		_verificar(current_scene == panel and panel.get_node("Centro").visible, "Omitir video no vuelve al selector.")
		_verificar(not panel.boton_continuar.disabled, "Se puede comenzar durante escritura.")
		_verificar(panel.controles.pasos.size() == 3, "Tres objetivos desde el inicio.")
		_verificar(panel.etiqueta_titulo.text == panel.get("_mision")["nombre"], "Título de la misión actual.")
		if id == "francia":
			var segundos: int = preload("res://Modelos/DatosCampana.gd").obtener(id)["evacuacion_segundos"]
			_verificar(panel.controles.aviso.text.contains(str(segundos)), "Aviso usa plazo de campaña.")
		else:
			_verificar(panel.controles.aviso == null, "Solo Francia presenta evacuación.")
		var posicion_objetivos: Vector2 = panel.controles.pasos[0].global_position
		if OS.get_cmdline_user_args().has("capturas"):
			await _capturar(id+"-entrada")
		await _tecla(KEY_ENTER)
		_verificar(current_scene == panel and panel.etiqueta_contexto.visible_characters == -1, "Primer Enter revela sin entrar al combate.")
		_verificar(posicion_objetivos == panel.controles.pasos[0].global_position, "Revelar no mueve los objetivos.")
		await create_timer(0.3).timeout
		_verificar(is_equal_approx(panel.get_node("Centro").modulate.a,1.0), "Fundido concluye.")
		_validar_lectura(panel)
		if OS.get_cmdline_user_args().has("capturas"):
			for resolucion in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1280,800)]:
				root.size = resolucion
				await process_frame
				await process_frame
				_validar_lectura(panel)
				await _capturar("%s-%dx%d" % [id,resolucion.x,resolucion.y])
			root.size = Vector2i(1280,720)
			await process_frame
		panel.controles.repetir.pressed.emit()
		_verificar(is_instance_valid(panel.video_mision) and not panel.get("_escribiendo"), "Repetir cancela escritura y abre video.")
		panel.video_mision.cerrar()
		await process_frame
		_verificar(panel.etiqueta_contexto.visible_characters == -1, "Regreso de repetición muestra contexto completo.")
		panel.controles.volver.grab_focus()
		await _tecla(KEY_RIGHT)
		_verificar(panel.boton_continuar.has_focus(), "Flecha alcanza comenzar desde volver.")
		panel.grab_focus()
		await _tecla(KEY_ESCAPE)
		_verificar(current_scene.scene_file_path.ends_with("MenuMisiones.tscn"), "Escape vuelve al selector.")
		_verificar(root.get_node("GestorMisiones").id_mision_actual == id, "Volver conserva selección.")
		_verificar(g.progreso == inicial, "Informe no modifica progreso ni inventario.")
	# Recurso ausente: ficha utilizable y acción de reproducción deshabilitada.
	var panel: Node = await _abrir_informe("francia")
	panel.video_mision.cerrar()
	await process_frame
	panel.get("_mision")["video_introduccion"] = "res://no-existe.ogv"
	panel.call("_actualizar_video_disponible")
	_verificar(panel.controles.repetir.disabled and not panel.controles.disponibilidad.text.is_empty(), "Se explica el recurso ausente.")
	panel.call("_reproducir_video", true)
	await process_frame
	await _tecla(KEY_ENTER)
	_verificar(current_scene.scene_file_path.ends_with("nivel_1.tscn"), "Enter con texto completo inicia misión.")
	_restaurar_progreso_usuario()
	print("Informes de misión: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _abrir_informe(id: String) -> Node:
	root.get_node("GestorMisiones").seleccionar_mision(id)
	change_scene_to_file("res://Vistas/UI/CinematicaPanel.tscn")
	await scene_changed
	await process_frame
	return current_scene

func _tecla(codigo: int) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	evento = InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = false
	Input.parse_input_event(evento)
	await process_frame
	await process_frame

func _validar_lectura(panel: Node) -> void:
	for label in [panel.etiqueta_titulo,panel.etiqueta_fecha,panel.etiqueta_contexto]+panel.controles.pasos:
		_verificar(label.get_line_count() <= label.get_visible_line_count(), "Texto sin recortes: " + label.name)
	var limite: Rect2 = panel.get_node("Centro/Panel").get_global_rect()
	for control in panel.get_node("Centro/Panel/Contenido").get_children():
		if control is Control and control.visible:
			_verificar(limite.encloses(control.get_global_rect()), "Control dentro del marco: " + control.name)

func _capturar(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-informe"))
	root.get_texture().get_image().save_png("res://.godot/qa-informe/"+nombre+".png")
