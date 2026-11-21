extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var audio: Node = root.get_node("GestorAudioPartida")
	audio.ruta_preferencias = "user://qa_pausa_%d.cfg" % OS.get_process_id()
	var viejo := ConfigFile.new()
	viejo.set_value("audio","efectos",0.42)
	viejo.save(audio.ruta_preferencias)
	audio.cargar_preferencias()
	_verificar(audio.preferencias.musica == 0.4 and audio.preferencias.videos == 1.0 and audio.preferencias.efectos == 0.42, "Preferencias antiguas compatibles.")
	var c: Node = await _abrir_mision("berlin")
	var menu: Node = get_first_node_in_group("panel_sonido")
	Input.action_press("Derecha")
	await create_timer(0.2).timeout
	menu.abrir(true)
	var posicion: Vector2 = c.jugador.position
	var combustible: float = c.jugador.combustible_actual
	var motor: Node = audio._unidades[c.jugador.get_instance_id()].piezas.motor
	var reproduccion: float = motor.get_playback_position()
	await create_timer(0.25).timeout
	_verificar(paused and c.jugador.position == posicion and c.jugador.combustible_actual == combustible, "Pausa congela movimiento y combustible.")
	_verificar(absf(motor.get_playback_position()-reproduccion) < 0.08, "Audio conserva su posición durante la pausa.")
	Input.action_release("Derecha")
	for tamano in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
		if OS.get_cmdline_user_args().has("capturas"):
			root.size = tamano
		for pagina in ["principal","sonido","confirmar"]:
			menu.mostrar_pagina(pagina)
			await process_frame
			await process_frame
			_verificar(menu.get_global_rect().encloses(menu.contenido.get_global_rect()), "Menú dentro del viewport.")
			await _capturar("pausa-%s-%d" % [pagina,tamano.x])
	menu.mostrar_pagina("sonido")
	menu.controles.musica.slider.value = 27
	menu.controles.musica.silencio.button_pressed = true
	menu.controles.videos.slider.value = 37
	menu.controles.videos.silencio.button_pressed = true
	audio.cargar_preferencias()
	_verificar(audio.preferencias.musica == 0.27 and audio.preferencias.silencio_musica and audio.preferencias.videos == 0.37 and audio.preferencias.silencio_videos, "Videos persisten de forma independiente.")
	var ruta: String = audio.ruta_preferencias
	audio.ruta_preferencias = "user://no_existe_pausa/audio.cfg"
	menu.controles.videos.slider.value = 45
	_verificar(menu.reintentar.visible and menu.error_guardado.visible, "Error permite reintentar.")
	audio.ruta_preferencias = ruta
	menu.reintentar.pressed.emit()
	_verificar(not menu.error_guardado.visible, "Reintento guarda ajustes.")
	menu.abrir(false)
	await process_frame
	_verificar(not paused, "Continuar reanuda.")
	await _tecla(KEY_F8)
	_verificar(paused and menu.panel.visible, "F8 abre pausa.")
	menu.mostrar_pagina("sonido")
	await _tecla(KEY_ESCAPE)
	_verificar(paused and menu.pagina == "principal", "Escape vuelve desde sonido.")
	await _tecla(KEY_ESCAPE)
	_verificar(not paused, "Escape reanuda desde principal.")
	c._iniciar_turno_ia()
	menu.abrir(true)
	await create_timer(0.9).timeout
	_verificar(not c.enemigo._en_movimiento and not c._proyectil_en_vuelo, "Espera de IA no avanza durante pausa.")
	menu.abrir(false)
	c = await _abrir_mision("francia")
	menu = get_first_node_in_group("panel_sonido")
	var vuelo: Proyectil = c.gestor_jugador.crear_proyectil("estandar")
	current_scene.add_child(vuelo)
	vuelo.position = Vector2(500,300)
	vuelo.configurar(Vector2(100,-100),c.jugador)
	menu.abrir(true)
	var origen: Vector2 = vuelo.position
	await create_timer(0.2).timeout
	_verificar(vuelo.position == origen, "Proyectil en vuelo permanece inmóvil.")
	menu.abrir(false)
	await create_timer(0.1).timeout
	_verificar(vuelo.position != origen, "Proyectil reanuda su trayectoria.")
	vuelo.queue_free()
	# Ejercitar espera y excavación progresiva reales.
	var p: Proyectil = c.gestor_jugador.crear_proyectil("bombardeo")
	p.terreno = c.terreno
	current_scene.add_child(p)
	p.configurar(Vector2.ZERO,c.jugador)
	p._resolver_impacto(c.terreno.get_child(2),Vector2(900,800))
	menu.abrir(true)
	await create_timer(1.6).timeout
	_verificar(p._esperando_bombardeo and c.terreno.obtener_altura(900) == 800, "Bengala pausada no inicia bombardeo.")
	menu.abrir(false)
	await create_timer(1.65).timeout
	menu.abrir(true)
	var altura: float = c.terreno.obtener_altura(900)
	await create_timer(0.4).timeout
	_verificar(is_equal_approx(altura,c.terreno.obtener_altura(900)), "Excavación no avanza pausada.")
	menu.abrir(false)
	await create_timer(1.0).timeout
	_verificar(c.terreno.obtener_altura(900) > altura, "Excavación continúa al reanudar.")
	var fuego: Proyectil = c.gestor_jugador.crear_proyectil("incendiario")
	current_scene.add_child(fuego)
	fuego.configurar(Vector2.ZERO,c.jugador)
	fuego._resolver_impacto(c.terreno.get_child(2),c.jugador.position)
	menu.abrir(true)
	var vida: float = c.jugador.vida_actual
	await create_timer(0.8).timeout
	_verificar(is_instance_valid(fuego) and c.jugador.vida_actual == vida, "Fuego no aplica ticks durante pausa.")
	menu.abrir(false)
	fuego.queue_free()
	c.enemigo.recibir_dano(100)
	menu.abrir(true)
	var tiempo: float = c.tiempo_evacuacion
	await create_timer(0.3).timeout
	_verificar(c.tiempo_evacuacion == tiempo, "Evacuación congelada.")
	menu.abrir(false)
	c._actualizar_fase(30.0)
	menu.abrir(true)
	await create_timer(2.2).timeout
	_verificar(not c._disparo_refuerzo_realizado and c.jugador.vida_actual > 0, "Refuerzo no ataca durante pausa.")
	var g: Node = root.get_node("GestorGuardado")
	var antes: Dictionary = g.progreso.duplicate(true)
	menu.mostrar_pagina("confirmar")
	menu.mostrar_pagina("principal")
	_verificar(paused, "Cancelar abandono conserva pausa.")
	menu._abandonar()
	await scene_changed
	await process_frame
	_verificar(not paused and current_scene.scene_file_path.ends_with("MenuMisiones.tscn"), "Abandono vuelve sin pausa.")
	_verificar(g.progreso == antes and not audio.activo and audio._unidades.is_empty(), "Abandono no liquida y limpia audio.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	audio.ruta_preferencias = "user://audio.cfg"
	audio.cargar_preferencias()
	_restaurar_progreso_usuario()
	print("Pausa: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _tecla(codigo: Key) -> void:
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

func _capturar(nombre: String) -> void:
	if not OS.get_cmdline_user_args().has("capturas") or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-pausa"))
	root.get_texture().get_image().save_png("res://.godot/qa-pausa/"+nombre+".png")
