extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var g: Node = root.get_node("GestorGuardado")
	for id in ["francia", "alamein", "berlin"]:
		g.progreso = g._crear_progreso_inicial()
		var c: Node = await _abrir_mision(id)
		c.set_process(false)
		c._finalizar_combate(true)
		var panel: Node = c.hud.panel_resultado
		_verificar(not panel.visible, "El informe espera al video: " + id)
		for hijo in c.get_children():
			if hijo is VideoMision:
				hijo.cerrar()
		await process_frame
		await process_frame
		_verificar(panel.visible and panel.titulo.text == c._mision.nombre, "Informe de la misión correcta.")
		_verificar(panel.resumen.text.contains("QUÉ OCURRIÓ") and panel.resumen.text.contains("POR QUÉ IMPORTÓ"), "Hechos y significado separados.")
		_verificar(panel.resumen.text.contains("EL COSTE HUMANO"), "Incluye consecuencias humanas.")
		var esperado: int = {"francia":150,"alamein":200,"berlin":250}[id]
		_verificar(panel.total.text == "+%d" % esperado, "Importe exacto con primer bono: " + id)
		_verificar(panel.recompensa.text.contains(str(g.obtener_saldo())), "Saldo proviene del guardado.")
		if id == "berlin":
			_verificar(panel.resumen.text.contains("CAMPAÑA COMPLETADA"), "Epílogo conservado.")
		if id == "alamein":
			_verificar(panel.fecha.text.contains("4 de noviembre"), "Fecha histórica corregida.")
		var saldo: int = g.obtener_saldo()
		if OS.get_cmdline_user_args().has("capturas"):
			for tamano in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1280,800)]:
				root.size = tamano
				await process_frame
				await process_frame
				_validar_diseno(panel)
				await _capturar("%s-%dx%d" % [id,tamano.x,tamano.y])
			root.size = Vector2i(1280,720)
		panel.recordar.pressed.emit()
		_verificar(panel.resumen.text.contains("IDEA CLAVE") and panel.resumen.text.contains("EL JUEGO Y LA HISTORIA"), "Distingue aprendizaje y simulación.")
		_verificar(panel.respuesta.visible and not panel.resumen.text.contains("[b]EXPLICACIÓN"), "La pregunta permite pensar antes de revelar.")
		panel.respuesta.pressed.emit()
		_verificar(panel.resumen.text.contains("[b]EXPLICACIÓN"), "Puede revelarse la explicación.")
		_verificar(g.obtener_saldo() == saldo, "Leer y revelar nunca altera monedas.")
		await process_frame
		await _capturar(id + "-recordar")
		panel.resumen.scroll_to_line(panel.resumen.get_line_count() - 1)
		await process_frame
		_verificar(panel.resumen.get_v_scroll_bar().value > 0, "Lectura completa disponible por desplazamiento.")
		await _capturar(id + "-fuentes")
		var lectura: float = panel.resumen.get_v_scroll_bar().value
		c._guardar_resultado()
		_verificar(g.obtener_saldo() == saldo, "Actualizar informe no acredita dos veces.")
		# El reintento conserva la pestaña elegida, sin reiniciar la lectura.
		_verificar(panel.resumen.text.contains("IDEA CLAVE"), "Reintento conserva la pestaña.")
		_verificar(is_equal_approx(panel.resumen.get_v_scroll_bar().value, lectura), "Reintento conserva la posición de lectura.")
		_validar_diseno(panel)
		panel.historia.pressed.emit()
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_TAB
		tecla.pressed = true
		panel.historia.grab_focus()
		Input.parse_input_event(tecla)
		await process_frame
		_verificar(root.gui_get_focus_owner() == panel.recordar, "Tab navega por las pestañas.")
		tecla.pressed = false
		Input.parse_input_event(tecla)
	await _probar_fallo_y_derrota(g)
	_restaurar_progreso_usuario()
	print("Resultados educativos: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _probar_fallo_y_derrota(g: Node) -> void:
	g.progreso = g._crear_progreso_inicial()
	var c: Node = await _abrir_mision("francia")
	var ruta: String = g.ruta_archivo
	g.ruta_archivo = "user://directorio_inexistente_resultados/guardado.json"
	c._finalizar_combate(true)
	for hijo in c.get_children():
		if hijo is VideoMision:
			hijo.cerrar()
	await process_frame
	var panel: Node = c.hud.panel_resultado
	_verificar(panel.total.text == "PENDIENTE" and panel.reintentar.visible, "Fallo no anuncia acreditación.")
	_verificar(g.obtener_saldo() == 100, "Fallo conserva saldo.")
	await _capturar("guardado-pendiente")
	g.ruta_archivo = ruta
	panel.reintentar.pressed.emit()
	_verificar(panel.total.text == "+150" and not panel.reintentar.visible and g.obtener_saldo() == 250, "Reintentar acredita una vez y actualiza informe.")
	c._guardar_resultado()
	_verificar(g.obtener_saldo() == 250, "Reintento repetido no duplica premio.")
	c = await _abrir_mision("francia")
	c._defensas_destruidas = 1
	c._finalizar_combate(false)
	panel = c.hud.panel_resultado
	_verificar(c.hud.etiqueta_resultado.text == "MISIÓN FALLIDA" and panel.total.text == "+25", "Derrota mantiene su estado y recompensa.")
	_verificar(panel.resumen.text.contains("TU PARTIDA") and not panel.logro.text.contains("completada con vida"), "Derrota no afirma victoria.")
	await process_frame
	await _capturar("derrota")
	_validar_diseno(panel)
	panel.volver.pressed.emit()
	await scene_changed
	_verificar(current_scene.scene_file_path.ends_with("MenuMisiones.tscn"), "Volver abre el selector.")

func _validar_diseno(panel: Node) -> void:
	for control in panel.contenido.get_children():
		if control is Label and control.visible:
			_verificar(control.get_line_count() <= control.get_visible_line_count(), "Etiqueta sin recorte: " + control.name)
		if control is Control and control.visible and control.name not in ["Marco", "Papel", "Velo"]:
			_verificar(panel.contenido.get_global_rect().encloses(control.get_global_rect()), "Control dentro del pergamino: %s %s / %s" % [control.name, control.get_global_rect(), panel.contenido.get_global_rect()])
	_verificar(panel.get_global_rect().encloses(panel.contenido.get_global_rect()), "Informe dentro del viewport.")

func _capturar(nombre: String) -> void:
	if not OS.get_cmdline_user_args().has("capturas") or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-resultados"))
	root.get_texture().get_image().save_png("res://.godot/qa-resultados/" + nombre + ".png")
