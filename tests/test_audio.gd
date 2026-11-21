extends "res://tests/test_campana.gd"

var eventos: Array[Dictionary] = []
var audio: Node

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	audio = root.get_node("GestorAudioPartida")
	if OS.get_cmdline_user_args().has("preferencias_escribir") or OS.get_cmdline_user_args().has("preferencias_leer"):
		audio.ruta_preferencias = "user://qa_audio_entre_procesos.cfg"
		if OS.get_cmdline_user_args().has("preferencias_escribir"):
			_verificar(audio.configurar_volumen("avisos", 0.23, true) == OK, "Escritura independiente.")
		else:
			audio.cargar_preferencias()
			_verificar(is_equal_approx(audio.preferencias.avisos, 0.23) and audio.preferencias.silencio_avisos, "Preferencias conservadas en otro proceso.")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(audio.ruta_preferencias))
		_restaurar_progreso_usuario()
		print("Preferencias entre procesos: %d fallos." % _fallos)
		quit(1 if _fallos else 0)
		return
	audio.ruta_preferencias = "user://qa_audio_%d.cfg" % OS.get_process_id()
	audio.cargar_preferencias()
	audio.evento_reproducido.connect(func(tipo: String, material: String) -> void: eventos.append({"tipo": tipo, "material": material}))
	_verificar(audio.preferencias.efectos == 0.8, "Volumen inicial al 80 %.")
	var master := AudioServer.get_bus_volume_db(0)
	_verificar(audio.configurar_volumen("efectos", 0.37, true) == OK, "Guardar preferencias.")
	audio.cargar_preferencias()
	_verificar(audio.preferencias.efectos == 0.37 and audio.preferencias.silencio_efectos, "Recarga volumen y silencio.")
	_verificar(AudioServer.get_bus_volume_db(0) == master, "No modifica el bus de videos.")
	audio.configurar_volumen("efectos", 0.8, false)
	for mision in ["francia", "alamein", "berlin"]:
		var c: Node = await _abrir_mision(mision)
		c.set_process(false)
		c.jugador.set_physics_process(false)
		c.enemigo.set_physics_process(false)
		_verificar(audio.superficie == CatalogoSonidos.superficie(mision), "Material de " + mision)
		await _probar_impactos(c)
		await _probar_panel(c)
	await _probar_rodaje()
	await _probar_fases()
	var c: Node = await _abrir_mision("berlin")
	audio.evento("impacto", c.jugador.global_position)
	change_scene_to_file("res://Vistas/UI/MenuMisiones.tscn")
	await scene_changed
	await process_frame
	_verificar(not audio.activo and audio._unidades.is_empty() and audio._voces.is_empty() and audio._bucles.is_empty(), "Salir limpia todas las voces.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(audio.ruta_preferencias))
	audio.ruta_preferencias = "user://audio.cfg"
	audio.cargar_preferencias()
	_restaurar_progreso_usuario()
	print("Audio de partida: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _contar(tipo: String) -> int:
	return eventos.filter(func(e: Dictionary) -> bool: return e.tipo == tipo).size()

func _probar_impactos(c: Node) -> void:
	var pared := StaticBody2D.new()
	pared.set_meta("material_audio", "escombros")
	current_scene.add_child(pared)
	for tipo in CatalogoSonidos.MUNICIONES:
		for material in CatalogoSonidos.MATERIALES:
			pared.set_meta("material_audio", material)
			audio.impacto(pared, Vector2(900, 200), tipo)
			_verificar(eventos.back().material == material, "Munición/material: " + tipo + "/" + material)
			await physics_frame
		var anterior := ""
		for i in range(12):
			var variante: String = audio._variante("impacto_" + tipo)
			_verificar(variante != anterior, "No repite variante consecutiva.")
			_verificar(ResourceLoader.exists(CatalogoSonidos.ruta(variante)), "Recurso exportable: " + variante)
			anterior = variante
	# Colisión real por ambas rutas: un único sonido y finalización por proyectil.
	var p: Node = c.gestor_jugador.crear_proyectil("estandar")
	current_scene.add_child(p)
	p.configurar(Vector2(100, 0), c.jugador)
	var antes := _contar("impacto")
	p._resolver_impacto(pared, Vector2(900, 50))
	p._al_entrar_en_cuerpo(pared)
	_verificar(_contar("impacto") == antes + 1, "Barrido y señal no duplican impacto.")
	await process_frame
	var fragmento := preload("res://Vistas/Proyectiles/FragmentoProyectil.tscn").instantiate()
	current_scene.add_child(fragmento)
	antes = _contar("impacto")
	fragmento._resolver_impacto(pared, Vector2(900, 50))
	fragmento._resolver_impacto(pared, Vector2(900, 50))
	_verificar(_contar("impacto") == antes + 1, "Fragmento no duplica impacto.")
	await physics_frame
	for i in range(20):
		audio.impacto(pared, Vector2(900, 50), "dispersion")
	_verificar(audio._voces.size() <= audio.MAX_VOCES, "Polifonía limitada.")
	for tipo in ["bombardeo", "incendiario"]:
		p = c.gestor_jugador.crear_proyectil(tipo)
		current_scene.add_child(p)
		p.configurar(Vector2(100, 0), c.jugador)
		antes = _contar("impacto")
		p._resolver_impacto(pared, Vector2(900, 50))
		await create_timer(1.6 if tipo == "bombardeo" else 0.1).timeout
		_verificar(audio._bucles.size() == 1, "Un bucle asociado al efecto: " + tipo)
		await create_timer(2.3).timeout
		_verificar(audio._bucles.is_empty(), "El bucle termina con el efecto: " + tipo)
		_verificar(_contar("impacto") == antes + 1, "Ticks/deformación no repiten impactos: " + tipo)
	pared.queue_free()

func _probar_panel(c: Node) -> void:
	var panel: Node = get_first_node_in_group("panel_sonido")
	panel.abrir(true)
	var evento := InputEventAction.new()
	evento.action = "Disparo"
	evento.pressed = true
	c.jugador._unhandled_input(evento)
	_verificar(not c._proyectil_en_vuelo, "Ajustar sonido no dispara.")
	panel.controles.avisos.slider.value = 42
	_verificar(is_equal_approx(audio.preferencias.avisos, 0.42), "El HUD controla el bus.")
	panel.controles.avisos.slider.value = 80
	if OS.get_cmdline_user_args().has("capturas") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-audio"))
		root.get_texture().get_image().save_png("res://.godot/qa-audio/panel-" + c._mision.id + ".png")
	panel.abrir(false)

func _probar_rodaje() -> void:
	var c: Node = await _abrir_mision("francia")
	c.set_process(false)
	c.jugador.set_physics_process(false)
	c.enemigo.set_physics_process(false)
	audio.set_process(false)
	for skin in ["TNQ-01", "TNQ-02", "TNQ-03", "TNQ-04", "TNQ-06", "ENM-01"]:
		c.jugador.visual_tanque.aplicar_apariencia(skin)
		for fps in [30, 60, 120]:
			audio.reiniciar_unidad(c.jugador)
			for direccion in [1.0, -1.0]:
				for paso in range(fps):
					c.jugador.visual_tanque.actualizar_movimiento(1.0/fps, Vector2(direccion*160.0/fps,0), true, Vector2.UP)
					audio._process(1.0/fps)
				var estado: Dictionary = audio._unidades[c.jugador.get_instance_id()]
				_verificar(estado.mezcla > 0.99, "Rodaje sincronizado: " + skin + " FPS " + str(fps))
			for paso in range(fps * 2):
				c.jugador.visual_tanque.actualizar_movimiento(1.0/fps, Vector2(0,3), false, Vector2.UP)
				audio._process(1.0/fps)
			var estado: Dictionary = audio._unidades[c.jugador.get_instance_id()]
			_verificar(not estado.piezas.cadenas.playing and estado.piezas.motor.playing, "Caída/bloqueo silencia cadenas, mantiene ralentí.")
			for paso in range(fps):
				c.jugador.visual_tanque.actualizar_movimiento(1.0/fps, Vector2.ZERO, true, Vector2.UP)
				audio._process(1.0/fps)
			_verificar(not estado.piezas.cadenas.playing, "Contacto sin desplazamiento no hace circular cadenas.")
			c.jugador.visual_tanque.apuntar_canon(Vector2(1,-0.8))
			audio._process(1.0/fps)
			for paso in range(fps):
				audio._process(1.0/fps)
			_verificar(not estado.piezas.engranajes.playing, "Cañón inmóvil queda silencioso.")
	var enemigo_id: int = c.enemigo.get_instance_id()
	_verificar(audio._unidades[enemigo_id].mezcla < 0.001, "Mover jugador no anima audio enemigo.")
	c.enemigo.calcular_disparo(c.jugador.global_position)
	audio._process(0.016)
	_verificar(audio._unidades[enemigo_id].piezas.size() == 4, "IA comparte sistema sin crear bucles por cada cálculo.")
	c.enemigo.recibir_dano(100)
	_verificar(not audio._unidades.has(enemigo_id), "Los restos no conservan motor.")
	audio.set_process(true)

func _probar_fases() -> void:
	var c: Node = await _abrir_mision("francia")
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	var antes := _contar("cuenta")
	audio.cuenta_atras(5.0)
	audio.cuenta_atras(4.9)
	audio.cuenta_atras(1.0)
	_verificar(_contar("cuenta") == antes + 2, "Un aviso por segundo, sin ráfaga al saltar frames.")
	c.jugador.position.x = 1730
	c.tiempo_evacuacion = 0.01
	c._actualizar_fase(1.0)
	audio.cuenta_atras(0.5)
	_verificar(_contar("cuenta") == antes + 2 and not audio.activo, "Llegada prioritaria cancela avisos y audio de victoria.")
	c = await _abrir_mision("francia")
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	c._actualizar_fase(30.0)
	await physics_frame
	_verificar(audio._unidades.has(c.enemigo.get_instance_id()), "Refuerzo tiene motor propio.")
	antes = _contar("disparo")
	c._actualizar_fase(2.0)
	await create_timer(0.6).timeout
	_verificar(_contar("disparo") == antes + 1 and not audio.activo, "Disparo letal suena y limpia al perder.")
	for mision in ["alamein", "berlin"]:
		c = await _abrir_mision(mision)
		c.enemigo.recibir_dano(100)
		c._iniciar_siguiente_posicion()
		await physics_frame
		await process_frame
		_verificar(audio._unidades.has(c.enemigo.get_instance_id()), "Segunda posición tiene audio: " + mision)
