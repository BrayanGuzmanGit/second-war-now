extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var c: Node = await _abrir_mision("francia")
	c.set_process(false)
	c.jugador.set_physics_process(false)
	c.enemigo.set_physics_process(false)
	for id in ["TNQ-01","TNQ-02","TNQ-03","TNQ-04","TNQ-06","ENM-01"]:
		c.jugador.visual_tanque.aplicar_apariencia(id)
		var r: Node = c.jugador.visual_tanque.rodaje
		for fps in [30,60,120]:
			r.reiniciar()
			for paso in fps:
				r.actualizar(1.0/fps, Vector2(120.0/fps,0), true, Vector2.UP)
			_verificar(is_equal_approx(r.distancia,120), "Distancia independiente de FPS: " + id)
			for paso in fps:
				r.actualizar(1.0/fps, Vector2(-120.0/fps,0), true, Vector2.UP)
			_verificar(absf(r.distancia) < 0.001, "Retroceder recupera fase: " + id)
		r.reiniciar()
		r.actualizar(0.1, Vector2(10,10), false, Vector2.UP)
		_verificar(r.distancia == 0, "Caída no hace circular las orugas.")
		r.actualizar(0.1, Vector2.ZERO, true, Vector2.UP)
		_verificar(r.distancia == 0, "Bloqueo no anima ruedas.")
		var radio: float = r.radios[0]
		for i in 100:
			r.actualizar(1.0/60, Vector2(TAU*radio/100,0), true, Vector2.UP)
		r.call("_dibujar",1.0)
		_verificar(is_equal_approx(cos(r.ruedas[0].rotation),1.0), "Una circunferencia equivale a una vuelta.")
		var eslabones: int = r.cadena.multimesh.instance_count
		r.actualizar(0.1, Vector2(2,-1), true, Vector2(-1,-2).normalized())
		for apoyo: float in r.apoyos:
			_verificar(absf(apoyo) <= 2.0, "Suspensión dentro de dos píxeles del mundo.")
		r.call("_dibujar",0.5)
		_verificar(r.cadena.multimesh.instance_count == eslabones, "Suspensión conserva el número de eslabones.")
		r.actualizar(0.1,Vector2(500,0),true,Vector2.UP)
		_verificar(r.distancia == 0, "Reposicionar reinicia la fase.")
		r.detener()
		var fase: float = r.distancia
		r.actualizar(0.1,Vector2(10,0),true,Vector2.UP)
		_verificar(r.distancia == fase, "Los restos permanecen quietos.")
		if OS.get_cmdline_user_args().has("capturas"):
			r.reiniciar()
			c.hud.hide()
			c.jugador.position.x = 500
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-rodaje"))
			for fotograma in 12:
				r.actualizar(1.0/30,Vector2(6,0),true,Vector2.UP)
				r.call("_dibujar",1.0)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.godot/qa-rodaje/%s-%02d.png" % [id,fotograma])
	var re: Node = c.enemigo.visual_tanque.rodaje
	re.reiniciar()
	re.actualizar(0.1,Vector2(10,0),true,Vector2.UP)
	_verificar(re.distancia < 0, "La IA reflejada invierte una sola vez.")
	_restaurar_progreso_usuario()
	print("Rodaje: %d fallos." % _fallos)
	quit(1 if _fallos else 0)
