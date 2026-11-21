extends SceneTree

var _fallos := 0
var _progreso_original: Dictionary
var _contenido_guardado_original := ""
var _existia_guardado_original := false


func _initialize() -> void:
	call_deferred("_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	if _fallos > 0:
		quit(1)
		return
	await _probar_factory_y_ciclo()
	await _probar_navegacion()
	await _probar_escena_de_combate()
	root.get_node("GestorGuardado").progreso = root.get_node("GestorGuardado").call(
		"_crear_progreso_inicial"
	)
	_probar_catalogo_y_misiones()
	_restaurar_progreso_usuario()
	if _fallos > 0:
		push_error("Fallaron %d verificaciones." % _fallos)
		quit(1)
		return
	print("Pruebas básicas correctas.")
	quit()


func _aislar_progreso_usuario() -> void:
	var gestor_guardado: Node = root.get_node("GestorGuardado")
	_progreso_original = gestor_guardado.progreso.duplicate(true)
	# Todas las suites escriben en un archivo exclusivo, nunca en el progreso real.
	gestor_guardado.ruta_archivo = "user://qa_suite_%d.json" % OS.get_process_id()
	gestor_guardado.progreso = gestor_guardado.call("_crear_progreso_inicial")


func _restaurar_progreso_usuario() -> void:
	var gestor_guardado: Node = root.get_node("GestorGuardado")
	for sufijo in ["", ".bak", ".tmp", ".corrupto"]:
		var ruta: String = gestor_guardado.ruta_archivo + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	gestor_guardado.progreso = _progreso_original
	gestor_guardado.ruta_archivo = GestorGuardado.RUTA_ARCHIVO
	gestor_guardado.set("_bloqueado", false)


func _probar_factory_y_ciclo() -> void:
	var gestor := GestorProyectiles.new()
	root.add_child(gestor)
	var tipos: Array[String] = ["estandar", "pesado", "dispersion", "bombardeo", "incendiario"]
	var siluetas_visuales: Array[PackedVector2Array] = []
	var colores_visuales: Array[Color] = []

	for indice in range(tipos.size()):
		var tipo := tipos[indice]
		_verificar(gestor.esta_disponible(tipo), "La munición debería estar disponible al inicio del ciclo.")
		var proyectil: Proyectil = gestor.crear_proyectil(tipo)
		_verificar(proyectil != null, "El Factory debe instanciar cada tipo de proyectil.")
		if proyectil == null:
			continue
		_verificar(
			proyectil.tipo_visual == tipo,
			"Cada escena de munición debe declarar su presentación propia: %s." % tipo
		)
		root.add_child(proyectil)
		await process_frame
		var visual := proyectil.get_node("Visual") as Polygon2D
		_verificar(
			not siluetas_visuales.has(visual.polygon),
			"Cada munición debe tener una silueta visual distinta: %s." % tipo
		)
		_verificar(
			not colores_visuales.has(visual.color),
			"Cada munición debe tener un color distintivo: %s." % tipo
		)
		siluetas_visuales.append(visual.polygon.duplicate())
		colores_visuales.append(visual.color)
		proyectil.free()
		_verificar(gestor.registrar_uso(tipo), "El Factory debe registrar la munición usada.")
		if indice == 0:
			_verificar(not gestor.esta_disponible(tipo), "No debe repetirse una munición dentro del ciclo.")

	_verificar(gestor.obtener_disponibles().size() == tipos.size(), "El ciclo debe reiniciarse tras usar las cinco municiones.")
	gestor.free()


func _probar_navegacion() -> void:
	var menu := (load("res://Vistas/UI/MenuPrincipal.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.boton_jugar.pressed.emit()
	await process_frame
	await process_frame
	_verificar(
		current_scene != null and current_scene.scene_file_path == "res://Vistas/UI/MenuMisiones.tscn",
		"El menú principal debe abrir la selección de misiones."
	)
	if current_scene == null:
		return

	current_scene.get_node("Francia").pressed.emit()
	await process_frame
	await process_frame
	_verificar(
		current_scene != null and current_scene.scene_file_path == "res://Vistas/UI/CinematicaPanel.tscn",
		"La ficha histórica debe abrirse al elegir una misión desbloqueada."
	)
	if current_scene == null:
		return

	if is_instance_valid(current_scene.get("video_mision")):
		current_scene.video_mision.cerrar()
		await process_frame
	current_scene.get_node("Centro/Panel/Contenido/Continuar").pressed.emit()
	await process_frame
	await process_frame
	_verificar(
		current_scene != null and current_scene.scene_file_path == "res://Niveles/nivel_1.tscn",
		"Continuar desde la ficha debe cargar el combate."
	)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
		current_scene = null


func _probar_escena_de_combate() -> void:
	var escena := load("res://Niveles/nivel_1.tscn") as PackedScene
	_verificar(escena != null, "Debe poder cargarse la escena de combate.")
	if escena == null:
		return
	var nivel := escena.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await process_frame

	var jugador := nivel.get_node("Jugador") as TanqueJugador
	var enemigo := nivel.get_node("Enemigo") as TanqueIA
	var visual_jugador := jugador.visual_tanque
	var visual_enemigo := enemigo.visual_tanque
	var etiqueta_turno: Label = nivel.get_node("HUD/Interfaz/PanelEstado/Contenido/Turno")
	var gestor_jugador: GestorProyectiles = nivel.get_node("ControladorCombate/GestorProyectilesJugador")
	var mapa_francia: Sprite2D = nivel.get_node("MapaFrancia")
	var mapa_alamein: Sprite2D = nivel.get_node("MapaElAlamein")
	var mapa_berlin: Sprite2D = nivel.get_node("MapaBerlin")
	var camara: Camera2D = nivel.get_node("Camara")
	var controlador: Node = nivel.get_node("ControladorCombate")
	var hud: HUD = nivel.get_node("HUD")
	var panel_estado: Panel = nivel.get_node("HUD/Interfaz/PanelEstado")
	var estilo_panel_estado := panel_estado.get_theme_stylebox("panel") as StyleBoxFlat
	var contenido_estado: VBoxContainer = nivel.get_node("HUD/Interfaz/PanelEstado/Contenido")
	var etiqueta_mision_hud: Label = contenido_estado.get_node("Mision")
	var etiqueta_objetivo_hud: Label = contenido_estado.get_node("Objetivo")
	var filas_estado: Array[Control] = [
		contenido_estado.get_node("VidaJugador"),
		contenido_estado.get_node("Combustible"),
		contenido_estado.get_node("VidaEnemigo"),
	]
	var base_joystick: Panel = nivel.get_node("HUD/Interfaz/JoystickBase")
	var perilla_joystick: Panel = nivel.get_node("HUD/Interfaz/JoystickBase/Perilla")
	_verificar(
		base_joystick.visible
		and base_joystick.size == Vector2(140.0, 140.0)
		and base_joystick.get_global_rect().position.y > 500.0
		and perilla_joystick.size == Vector2(42.0, 42.0),
		"El joystick debe permanecer compacto y fijo en la esquina inferior de la interfaz."
	)
	_verificar(
		panel_estado.size == Vector2(360.0, 268.0)
		and estilo_panel_estado != null
		and estilo_panel_estado.bg_color.a < 1.0
		and contenido_estado.get_node("Encabezado") != null
		and etiqueta_mision_hud.size.x <= contenido_estado.size.x
		and etiqueta_objetivo_hud.size.x <= contenido_estado.size.x
		and etiqueta_objetivo_hud.text.count("\n") <= 1
		and filas_estado[0].size == filas_estado[1].size
		and filas_estado[1].size == filas_estado[2].size,
		"El panel informativo debe ser compacto, consistente, semitransparente y evitar desbordes."
	)
	_verificar(
		mapa_francia.texture != null
		and mapa_francia.texture.resource_path == "res://Imagenes/Fondos/MapaFrancia1940.jpeg"
		and mapa_alamein.texture != null
		and mapa_alamein.texture.resource_path == "res://Imagenes/Fondos/MapaElAlamein1942.jpeg"
		and mapa_berlin.texture != null
		and mapa_berlin.texture.resource_path == "res://Imagenes/Fondos/MapaBerlin1945.jpeg",
		"Cada misión debe tener cargado su propio fondo ilustrado."
	)
	_verificar(
		mapa_francia.visible and not mapa_alamein.visible and not mapa_berlin.visible,
		"El mapa de Francia debe ser el único fondo visible al iniciar la primera misión."
	)
	_verificar(
		(Vector2(mapa_francia.texture.get_size()) * mapa_francia.scale)
		.distance_to(Vector2(1800.0, 1004.6512)) < 0.1
		and camara.zoom.x > 1.0
		and camara.limit_right == 1800
		and camara.limit_bottom == 1005,
		"El mapa ampliado debe conservar sus límites y el zoom de cámara."
	)
	var camara_antes_seguimiento := camara.global_position.x
	jugador.global_position.x += 50.0
	controlador.call("_actualizar_camara", 0.1)
	_verificar(
		camara.global_position.x > camara_antes_seguimiento,
		"La cámara debe seguir el movimiento del centro del combate."
	)
	jugador.global_position.x -= 50.0
	controlador.call("_configurar_fondo", "alamein")
	_verificar(
		not mapa_francia.visible and mapa_alamein.visible and not mapa_berlin.visible,
		"El Alamein debe mostrar exclusivamente su fondo ilustrado."
	)
	controlador.call("_configurar_fondo", "berlin")
	_verificar(
		not mapa_francia.visible and not mapa_alamein.visible and mapa_berlin.visible,
		"Berlín debe mostrar exclusivamente su fondo ilustrado."
	)
	controlador.call("_configurar_fondo", "francia")
	var forma_suelo := (nivel.get_node("Suelo/CollisionShape2D").shape as RectangleShape2D)
	_verificar(
		is_equal_approx(forma_suelo.size.x, 1800.0)
		and is_equal_approx(nivel.get_node("Suelo").global_position.y - forma_suelo.size.y * 0.5, 800.0)
		and nivel.get_node("Suelo/CollisionShape2D").disabled
		and controlador.terreno != null,
		"La plataforma de referencia debe estar desactivada y reemplazada por terreno deformable."
	)
	_verificar_hitbox_coincide_con_sprite(jugador, false)
	_verificar_hitbox_coincide_con_sprite(enemigo, true)
	_verificar(
		jugador.punto_disparo.get_parent() == visual_jugador.pivote_canon
		and enemigo.punto_disparo.get_parent() == visual_enemigo.pivote_canon,
		"El punto de salida de ambos tanques debe estar ligado al pivote del cañón."
	)
	_verificar(jugador.vida_actual == jugador.vida_maxima, "El tanque jugador debe iniciar con la vida completa.")
	_verificar(enemigo.vida_actual == enemigo.vida_maxima, "La IA debe iniciar con la vida completa.")
	_verificar(etiqueta_turno.text == "TU TURNO", "El HUD debe indicar claramente el turno activo.")
	var disparos_joystick := {"cantidad": 0}
	jugador.disparo_solicitado.connect(
		func(_origen: Vector2, _velocidad: Vector2) -> void:
			disparos_joystick["cantidad"] += 1
	)
	var centro_joystick := base_joystick.get_global_rect().get_center()
	var pulsar_joystick := InputEventMouseButton.new()
	pulsar_joystick.button_index = MOUSE_BUTTON_LEFT
	pulsar_joystick.pressed = true
	pulsar_joystick.position = centro_joystick
	hud.call("_input", pulsar_joystick)
	var arrastrar_joystick := InputEventMouseMotion.new()
	arrastrar_joystick.position = centro_joystick + Vector2(48.0, -24.0)
	arrastrar_joystick.relative = Vector2(48.0, -24.0)
	arrastrar_joystick.button_mask = MOUSE_BUTTON_MASK_LEFT
	hud.call("_input", arrastrar_joystick)
	var soltar_joystick := InputEventMouseButton.new()
	soltar_joystick.button_index = MOUSE_BUTTON_LEFT
	soltar_joystick.position = arrastrar_joystick.position
	soltar_joystick.pressed = false
	hud.call("_input", soltar_joystick)
	await process_frame
	var vector_joystick: Vector2 = hud.obtener_vector_apuntado_joystick()
	var vector_esperado_joystick := (
		Vector2(48.0, -24.0).limit_length(HUD.RADIO_ARRASTRE_JOYSTICK)
		/ HUD.RADIO_ARRASTRE_JOYSTICK
	)
	_verificar(
		disparos_joystick["cantidad"] == 0
		and jugador.turno_activo
		and not hud.get("_arrastrando_joystick")
		and vector_joystick.distance_to(vector_esperado_joystick) < 0.01,
		"Arrastrar y soltar el joystick debe conservar la puntería sin disparar ni consumir el turno."
	)
	var vida_antes_impacto_visual := enemigo.vida_actual
	enemigo.recibir_impacto_proyectil(
		1.0,
		enemigo.obtener_punto_impacto_global(),
		Vector2.LEFT,
		"pesado"
	)
	_verificar(
		is_equal_approx(enemigo.vida_actual, vida_antes_impacto_visual - 1.0),
		"El contrato visual de impacto también debe aplicar el daño una sola vez."
	)
	_verificar(
		get_nodes_in_group("efectos_impacto").size() == 1
		and get_nodes_in_group("efectos_impacto")[0].tipo_proyectil == "pesado",
		"El impacto directo debe crear el efecto visual correspondiente a su munición."
	)
	var proyectil_incendiario := gestor_jugador.crear_proyectil("incendiario")
	nivel.add_child(proyectil_incendiario)
	proyectil_incendiario.global_position = enemigo.obtener_punto_impacto_global()
	proyectil_incendiario.configurar(Vector2.ZERO, jugador, 1.0)
	proyectil_incendiario.call(
		"_aplicar_dano_area",
		null,
		1.0,
		enemigo.obtener_punto_impacto_global(),
		false
	)
	proyectil_incendiario.call(
		"_crear_efecto_zona_incendiada",
		enemigo.obtener_punto_impacto_global()
	)
	_verificar(
		get_nodes_in_group("efectos_impacto").size() == 1,
		"El daño periódico incendiario no debe crear efectos visuales repetidos."
	)
	_verificar(
		get_nodes_in_group("efectos_zona_incendiada").size() == 1
		and is_equal_approx(
			get_nodes_in_group("efectos_zona_incendiada")[0].duracion,
			proyectil_incendiario.cantidad_ticks * 0.65
		)
		and is_equal_approx(
			get_nodes_in_group("efectos_zona_incendiada")[0].radio,
			proyectil_incendiario.radio_explosion
		),
		"El impacto incendiario debe mostrar una zona de fuego durante el daño periódico."
	)
	proyectil_incendiario.free()
	enemigo.vida_actual = vida_antes_impacto_visual
	enemigo.vida_actualizada.emit(enemigo.vida_actual, enemigo.vida_maxima)
	var velocidad := enemigo.calcular_disparo(jugador.global_position)
	_verificar(velocidad.x < 0.0 and velocidad.y < 0.0, "La IA debe calcular un disparo hacia el jugador.")
	_verificar(
		(visual_enemigo.punto_disparo.global_position - visual_enemigo.pivote_canon.global_position)
		.normalized().dot(velocidad.normalized()) > 0.999,
		"El cañón de la IA debe orientarse según la velocidad inicial de su disparo."
	)
	visual_jugador.apuntar_canon(Vector2(1.0, -1.0))
	_verificar(
		(visual_jugador.punto_disparo.global_position - visual_jugador.pivote_canon.global_position)
		.normalized().dot(Vector2(1.0, -1.0).normalized()) > 0.999,
		"El cañón del jugador debe orientarse correctamente hacia el vector recibido."
	)
	jugador.actualizar_apuntado_joystick(Vector2(0.7, -0.6))
	jugador._actualizar_apuntado()
	var velocidad_apuntada: Vector2 = jugador.get("_velocidad_disparo") * jugador.multiplicador_municion_actual
	var punto_final_curva := jugador.linea_trayectoria.to_global(
		jugador.linea_trayectoria.points[-1]
	)
	var tiempo_visible := (
		float(jugador.get("_tiempo_apuntado"))
		* TanqueJugador.FRACCION_PREVISUALIZACION_TRAYECTORIA
	)
	var tiempo_total := float(jugador.get("_tiempo_apuntado"))
	var punto_final_esperado := (
		jugador.punto_disparo.global_position
		+ velocidad_apuntada * tiempo_visible
		+ Vector2(0.0, 0.5 * GameConfig.GRAVEDAD * tiempo_visible * tiempo_visible)
	)
	_verificar(
		(visual_jugador.punto_disparo.global_position - visual_jugador.pivote_canon.global_position)
		.normalized().dot(velocidad_apuntada.normalized()) > 0.999
		and velocidad_apuntada.x > 0.0
		and velocidad_apuntada.y < 0.0
		and velocidad_apuntada.length() >= jugador.potencia_minima
		and velocidad_apuntada.length() <= jugador.potencia_maxima
		and punto_final_curva.distance_to(jugador.punto_disparo.global_position) > 1.0
		and punto_final_curva.distance_to(punto_final_esperado) < 1.0
		and tiempo_visible < tiempo_total
		and tiempo_total > 0.0,
		"El joystick debe ajustar ángulo y potencia, y mostrar solo el tramo inicial desde la boca."
	)
	var tipos_municion: Array[String] = [
		"estandar",
		"pesado",
		"dispersion",
		"bombardeo",
		"incendiario",
	]
	for tipo in tipos_municion:
		var multiplicador := gestor_jugador.obtener_multiplicador_potencia(tipo)
		jugador.multiplicador_municion_actual = multiplicador
		jugador.refrescar_apuntado()
		var velocidad_municion: Vector2 = (
			jugador.get("_velocidad_disparo") * multiplicador
		)
		_verificar(
			is_equal_approx(
				velocidad_municion.length(),
				velocidad_apuntada.length() * multiplicador
			),
			"La munición %s debe aplicar su multiplicador a la potencia del joystick." % tipo
		)
	jugador.multiplicador_municion_actual = gestor_jugador.obtener_multiplicador_potencia(
		"estandar"
	)
	jugador.refrescar_apuntado()
	var posicion_inicial := jugador.global_position.x
	jugador.combustible_actual = 10.0
	Input.action_press("Derecha")
	for indice in range(5):
		await physics_frame
	Input.action_release("Derecha")
	_verificar(jugador.global_position.x > posicion_inicial, "A/D debe mover al tanque durante su turno.")
	_verificar(jugador.combustible_actual < 10.0, "El movimiento debe consumir combustible.")
	_verificar(
		not is_zero_approx(visual_jugador.giro_ruedas),
		"Las ruedas deben girar al avanzar el tanque del jugador."
	)
	var posicion_inicial_ia := enemigo.global_position.x
	await enemigo.mover_en_turno(jugador.global_position)
	_verificar(
		enemigo.global_position.x < posicion_inicial_ia,
		"La IA debe reposicionarse hacia el jugador durante su turno."
	)
	_verificar(
		not is_zero_approx(visual_enemigo.giro_ruedas),
		"Las ruedas deben girar cuando la IA se reposiciona."
	)
	_verificar(
		visual_jugador.rodaje != null
		and visual_jugador.rodaje.apoyos.size() == visual_jugador.rodaje.ruedas.size(),
		"La suspensión visual debe actualizarse con el movimiento sin alterar la física."
	)
	var dispersion := gestor_jugador.crear_proyectil("dispersion")
	var termino_dispersion := {"valor": false}
	dispersion.finalizado.connect(func() -> void: termino_dispersion["valor"] = true)
	dispersion.configurar(Vector2(350.0, -120.0), jugador)
	nivel.add_child(dispersion)
	for indice in range(35):
		await physics_frame
	_verificar(get_nodes_in_group("fragmentos").size() > 0, "La munición de dispersión debe dividirse en fragmentos.")
	for indice in range(150):
		await physics_frame
	_verificar(termino_dispersion["valor"], "El disparo de dispersión debe terminar cuando sus fragmentos se resuelven.")
	var origen_disparo := jugador.punto_disparo.global_position
	var objetivo_disparo := enemigo.obtener_punto_impacto_global()
	var desplazamiento_x := objetivo_disparo.x - origen_disparo.x
	var desplazamiento_y := objetivo_disparo.y - origen_disparo.y
	var angulo_disparo := PI * 0.25
	var denominador_potencia := (
		2.0
		* cos(angulo_disparo) ** 2.0
		* (desplazamiento_y + desplazamiento_x * tan(angulo_disparo))
	)
	var potencia_requerida := sqrt(
		GameConfig.GRAVEDAD * desplazamiento_x * desplazamiento_x / denominador_potencia
	)
	var intensidad_joystick := clampf(
		(potencia_requerida - jugador.potencia_minima)
		/ (jugador.potencia_maxima - jugador.potencia_minima),
		0.1,
		1.0
	)
	jugador.actualizar_apuntado_joystick(
		Vector2(cos(angulo_disparo), -sin(angulo_disparo)) * intensidad_joystick
	)
	var velocidad_jugador: Vector2 = jugador.get("_velocidad_disparo")
	jugador.disparo_solicitado.emit(origen_disparo, velocidad_jugador)
	var proyectil_disparado: Proyectil
	for nodo in nivel.get_children():
		if nodo is Proyectil:
			proyectil_disparado = nodo
			break
	_verificar(
		proyectil_disparado != null
		and proyectil_disparado.global_position.distance_to(origen_disparo) < 0.01,
		"El proyectil debe aparecer en el punto de disparo del tanque."
	)
	_verificar(
		etiqueta_turno.text == "DISPARO DEL JUGADOR EN VUELO"
		and not base_joystick.visible,
		"El HUD debe identificar el disparo y ocultar el joystick mientras no sea el turno del jugador."
	)
	var efectos_salida := get_nodes_in_group("efectos_salida_proyectil")
	_verificar(
		not efectos_salida.is_empty()
		and efectos_salida.back().tipo_proyectil == proyectil_disparado.tipo_visual
		and efectos_salida.back().global_position.distance_to(origen_disparo) < 0.01,
		"El disparo debe mostrar su fogonazo específico desde el punto de salida del tanque."
	)
	if not efectos_salida.is_empty():
		_verificar(
			absf(wrapf(efectos_salida.back().rotation - velocidad_jugador.angle(), -PI, PI)) < 0.01,
			"El fogonazo debe orientarse hacia la dirección inicial del proyectil."
		)
	var velocidad_real := (
		proyectil_disparado.velocidad
		if is_instance_valid(proyectil_disparado)
		else Vector2.ZERO
	)
	for indice in range(10):
		await physics_frame
	if is_instance_valid(proyectil_disparado):
		var tiempo_vuelo := 10.0 / float(Engine.physics_ticks_per_second)
		var posicion_esperada := origen_disparo + velocidad_real * tiempo_vuelo
		posicion_esperada.y += 0.5 * GameConfig.GRAVEDAD * tiempo_vuelo * tiempo_vuelo
		_verificar(
			proyectil_disparado.global_position.distance_to(posicion_esperada) < 1.0,
			"El proyectil debe seguir la parábola dibujada durante el vuelo."
		)
	for indice in range(290):
		await physics_frame
	_verificar(enemigo.vida_actual < enemigo.vida_maxima, "El proyectil del jugador debe impactar al enemigo.")
	_verificar(jugador.vida_actual < jugador.vida_maxima, "La IA debe responder al disparo del jugador.")
	_verificar(
		etiqueta_turno.text == "TU TURNO" and base_joystick.visible,
		"El turno y el joystick deben regresar al jugador después del ataque de la IA."
	)

	var selector_municion: Button = nivel.get_node(
		"HUD/Interfaz/PanelMunicion/Contenido/BotonMunicionSeleccionada"
	)
	var menu_municion: Control = nivel.get_node("HUD/Interfaz/MenuDesplegable")
	var boton_estandar: Button = nivel.get_node("HUD/Interfaz/MenuDesplegable/Opciones/Estandar")
	var boton_pesado: Button = nivel.get_node("HUD/Interfaz/MenuDesplegable/Opciones/Pesado")
	var etiqueta_estado: Label = nivel.get_node("HUD/Interfaz/PanelEstado/Contenido/Estado")
	_verificar(
		selector_municion.get_global_rect().position.x > 900.0
		and menu_municion.get_global_rect().position.x > 900.0
		and menu_municion.get_global_rect().position.y
		>= selector_municion.get_global_rect().end.y,
		"El selector debe ocupar poco espacio arriba a la derecha y desplegarse hacia abajo."
	)
	_verificar(
		nivel.get_node_or_null("HUD/Interfaz/PanelMunicion/Contenido/FinalizarTurno") == null,
		"El HUD no debe mostrar el botón de finalizar turno."
	)
	_verificar(boton_estandar.disabled, "La munición estándar usada debe quedar deshabilitada.")
	_verificar(not boton_pesado.disabled, "La munición pesada debe seguir disponible.")
	_verificar(
		selector_municion.text == "Munición seleccionada: Pesado  ▾",
		"Al regresar de la IA debe seleccionarse automáticamente la siguiente munición."
	)
	_verificar(
		not menu_municion.visible
		and nivel.get_node("HUD/Interfaz/MenuDesplegable/Opciones/Estandar/Contenido/Estado").text
		== "AGOTADA"
		and nivel.get_node("HUD/Interfaz/MenuDesplegable/Opciones/Pesado/Contenido/Icono").texture
		!= null,
		"El menú debe mostrar los iconos y distinguir munición agotada de la disponible."
	)
	var nombres_municion := ["Estandar", "Pesado", "Dispersion", "Bombardeo", "Incendiario"]
	var iconos_distintos: Array[Texture2D] = []
	for nombre in nombres_municion:
		var icono: Texture2D = nivel.get_node(
			"HUD/Interfaz/MenuDesplegable/Opciones/%s/Contenido/Icono" % nombre
		).texture
		_verificar(icono != null, "Cada opción de munición debe tener su ilustración.")
		if icono != null:
			_verificar(
				not iconos_distintos.has(icono),
				"Cada tipo debe usar una región propia de la lámina de munición."
			)
			iconos_distintos.append(icono)
	# Simula una selección desactualizada para comprobar que se repara sin disparar ni ceder turno.
	controlador.set("_municion_seleccionada", "estandar")
	controlador.call(
		"_disparar_jugador",
		jugador.punto_disparo.global_position,
		Vector2.RIGHT * 500.0
	)
	await physics_frame
	_verificar(
		etiqueta_estado.text == "Se seleccionó Pesado automáticamente; dispara de nuevo."
		and jugador.turno_activo
		and etiqueta_turno.text == "TU TURNO",
		"Una selección repetida debe corregirse automáticamente sin consumir el turno."
	)
	selector_municion.pressed.emit()
	_verificar(menu_municion.visible, "El selector debe desplegar las cinco opciones de munición.")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	nivel.get_node("HUD").call("_input", escape)
	_verificar(not menu_municion.visible, "Escape debe cerrar el menú de munición.")
	selector_municion.pressed.emit()
	boton_pesado.pressed.emit()
	await process_frame
	await physics_frame
	_verificar(
		selector_municion.text == "Munición seleccionada: Pesado  ▾"
		and not menu_municion.visible,
		"El jugador debe poder seleccionar otra munición sin finalizar el turno."
	)
	_verificar(
		is_equal_approx(
			jugador.multiplicador_municion_actual,
			gestor_jugador.obtener_multiplicador_potencia("pesado")
		),
		"El cambio de munición debe actualizar la potencia usada al apuntar."
	)
	_verificar(
		jugador.turno_activo
		and jugador.linea_trayectoria.visible
		and jugador.linea_trayectoria.points.size() > 1,
		"La trayectoria debe aparecer al seleccionar munición durante el turno."
	)

	var vida_enemigo_antes_pesado := enemigo.vida_actual
	var origen_disparo_pesado := jugador.punto_disparo.global_position
	var objetivo_pesado := enemigo.obtener_punto_impacto_global()
	var desplazamiento_pesado := objetivo_pesado - origen_disparo_pesado
	var multiplicador_pesado := gestor_jugador.obtener_multiplicador_potencia("pesado")
	var denominador_pesado := (
		2.0
		* cos(angulo_disparo) ** 2.0
		* (
			desplazamiento_pesado.y
			+ desplazamiento_pesado.x * tan(angulo_disparo)
		)
	)
	var potencia_base_pesado := sqrt(
		GameConfig.GRAVEDAD
		* desplazamiento_pesado.x
		* desplazamiento_pesado.x
		/ denominador_pesado
	) / multiplicador_pesado
	var intensidad_pesado := clampf(
		(potencia_base_pesado - jugador.potencia_minima)
		/ (jugador.potencia_maxima - jugador.potencia_minima),
		0.1,
		1.0
	)
	jugador.actualizar_apuntado_joystick(
		Vector2(cos(angulo_disparo), -sin(angulo_disparo)) * intensidad_pesado
	)
	var velocidad_pesado: Vector2 = jugador.get("_velocidad_disparo")
	jugador.disparo_solicitado.emit(origen_disparo_pesado, velocidad_pesado)
	_verificar(
		etiqueta_turno.text == "DISPARO DEL JUGADOR EN VUELO",
		"El jugador debe poder disparar munición diferente sin pasar el turno manualmente."
	)
	for indice in range(600):
		if etiqueta_turno.text == "TU TURNO" or _es_etiqueta_turno_estado_terminal(etiqueta_turno.text):
			break
		await physics_frame
	_verificar(
		enemigo.vida_actual < vida_enemigo_antes_pesado,
		"La munición pesada seleccionada debe completar su disparo e impactar."
	)

	# Prepara el progreso de Francia para que esta comprobación no escriba el guardado de usuario.
	var gestor_guardado: Node = root.get_node("GestorGuardado")
	var progreso: Dictionary = gestor_guardado.get("progreso")
	var misiones_completadas_guardadas: Array = progreso["misiones_completadas"].duplicate()
	progreso["misiones_completadas"] = ["francia"]
	enemigo.recibir_dano(enemigo.vida_actual)
	var etiqueta_combustible: Label = nivel.get_node("HUD/Interfaz/PanelEstado/Contenido/Combustible")
	var aviso_retirada: Control = nivel.get_node("HUD/Interfaz/AvisoRetirada")
	_verificar(
		jugador.movimiento_retirada_ilimitado
		and etiqueta_combustible.text == "Combustible: ILIMITADO"
		and aviso_retirada.visible
		and aviso_retirada.get_node("Panel/Contenido/Mensaje").text.contains("Dunkerque")
		and jugador.turno_activo
		and not controlador.get("_turno_jugador")
		and etiqueta_turno.text == "FASE DE RETIRADA"
		and not menu_municion.visible
		and not base_joystick.visible
		and selector_municion.disabled,
		"Al destruir al enemigo debe comenzar la retirada y dejar inactivos los controles de turno."
	)
	var proyectil_en_vuelo_antes_intento: bool = controlador.get("_proyectil_en_vuelo")
	var intento_disparo := InputEventMouseButton.new()
	intento_disparo.button_index = MOUSE_BUTTON_LEFT
	intento_disparo.pressed = true
	jugador.call("_unhandled_input", intento_disparo)
	_verificar(
		jugador.turno_activo
		and controlador.get("_proyectil_en_vuelo") == proyectil_en_vuelo_antes_intento
		and etiqueta_turno.text == "FASE DE RETIRADA",
		"Intentar disparar durante la retirada no debe consumir el control ni reactivar el combate."
	)
	await process_frame
	_verificar(
		not nivel.get_node("Enemigo").is_physics_processing()
		and enemigo.visual_tanque.id_apariencia == "ENM-01"
		and enemigo.visual_tanque.get("_cuerpo_alternativo").visible,
		"El tanque destruido debe conservarse como resto mientras termina su animación."
	)
	for colision_silueta: CollisionPolygon2D in enemigo.find_children(
		"*",
		"CollisionPolygon2D",
		true,
		false
	):
		_verificar(
			colision_silueta.disabled,
			"La destrucción debe desactivar cada polígono físico del tanque."
		)
	var efectos_explosion := nivel.get_children().filter(
		func(nodo: Node) -> bool: return nodo is EfectoExplosionTanque
	)
	_verificar(
		not efectos_explosion.is_empty(),
		"La unidad destruida debe crear una explosión visual breve."
	)
	for indice in range(600):
		if jugador.turno_activo:
			break
		await physics_frame
	jugador.global_position = Vector2(900.0, jugador.global_position.y)
	jugador.combustible_actual = 0.0
	var posicion_antes_retirada := jugador.global_position.x
	Input.action_press("Derecha")
	for indice in range(5):
		await physics_frame
	Input.action_release("Derecha")
	_verificar(
		jugador.global_position.x > posicion_antes_retirada
		and is_zero_approx(jugador.combustible_actual),
		"El tanque debe poder avanzar sin consumir combustible después de vencer al enemigo."
	)
	var posicion_antes_reversa := jugador.global_position.x
	Input.action_press("Izquierda")
	for indice in range(5):
		await physics_frame
	Input.action_release("Izquierda")
	_verificar(
		jugador.global_position.x < posicion_antes_reversa
		and is_zero_approx(jugador.combustible_actual),
		"El tanque debe poder retroceder sin consumir combustible durante la retirada."
	)
	var zona_evac: Area2D = nivel.get_node("ZonaEvacuacion")
	jugador.global_position.x = zona_evac.global_position.x
	await physics_frame
	_verificar(
		zona_evac.overlaps_body(jugador)
		or controlador.call("_jugador_esta_en_zona_evac"),
		"El tanque debe activar la zona de evacuación incluso si cruza entre actualizaciones físicas."
	)
	controlador.call("_process", 0.0)
	for hijo in controlador.get_children():
		if hijo is VideoMision:
			hijo.cerrar()
	await process_frame
	_verificar(
		nivel.get_node("HUD/Interfaz/PanelResultado").visible
		and nivel.get_node("HUD/Interfaz/PanelResultado/Centro/Contenido/Resultado").text
		== "MISIÓN COMPLETADA",
		"Alcanzar el objetivo con el enemigo neutralizado debe mostrar la victoria."
	)
	_verificar(
		nivel.get_node("HUD").etiqueta_resumen.text.contains("Dunkerque")
		and nivel.get_node("HUD").etiqueta_resumen.text.contains("conservar fuerzas")
		and nivel.get_node("HUD").etiqueta_resumen.text.contains("derrota militar"),
		"La victoria de Francia debe explicar la retirada aliada según el GDD."
	)
	var gestor_misiones: Node = root.get_node("GestorMisiones")
	var misiones_tras_victoria: Array[Dictionary] = gestor_misiones.call("obtener_misiones")
	_verificar(
		misiones_tras_victoria[1]["desbloqueada"]
		and not misiones_tras_victoria[2]["desbloqueada"],
		"La victoria de Francia debe desbloquear solo la misión siguiente."
	)
	await create_timer(0.1).timeout
	await process_frame
	_verificar(
		current_scene != null
		and current_scene.scene_file_path == "res://Niveles/nivel_1.tscn"
		and nivel.get_node("HUD/Interfaz/PanelResultado").visible,
		"La pantalla de victoria debe permanecer visible hasta que el jugador decida salir."
	)
	var boton_resultado: Button = nivel.get_node(
		"HUD/Interfaz/PanelResultado/Centro/Contenido/BotonMenu"
	)
	_verificar(
		boton_resultado.text.to_lower().contains("volver a misiones"),
		"El botón de resultado debe indicar que vuelve a la selección de misiones."
	)
	boton_resultado.pressed.emit()
	await process_frame
	await process_frame
	_verificar(
		current_scene != null
		and current_scene.scene_file_path == "res://Vistas/UI/MenuMisiones.tscn",
		"El botón de resultado debe regresar a la selección de misiones."
	)
	progreso["misiones_completadas"] = misiones_completadas_guardadas
	gestor_guardado.set("progreso", progreso)
	if is_instance_valid(nivel):
		nivel.queue_free()


func _es_etiqueta_turno_estado_terminal(texto: String) -> bool:
	# Detiene la espera si el combate termina antes de recuperar el turno del jugador.
	return texto == "POSICIÓN ENEMIGA NEUTRALIZADA" or texto == "MISIÓN FINALIZADA"


func _verificar_hitbox_coincide_con_sprite(tanque: Tanque, espejo_horizontal: bool) -> void:
	# Verifica la caja de referencia y la cobertura real de un píxel opaco por la silueta física.
	var sprite: Sprite2D = tanque.get_node("Visuales/Sprite2D")
	var imagen := Tanque.TEXTURA_REFERENCIA_HITBOX.get_image()
	var limites_visibles := imagen.get_used_rect()
	var colision: CollisionShape2D = tanque.get_node("CollisionShape2D")
	var forma := colision.shape as RectangleShape2D
	var escala := sprite.scale.abs()
	var tamano_esperado := Vector2(limites_visibles.size) * escala
	var centro_pixeles := (
		Vector2(limites_visibles.position)
		+ Vector2(limites_visibles.size) * 0.5
		- Vector2(imagen.get_size()) * 0.5
	)
	if espejo_horizontal:
		centro_pixeles.x *= -1.0
	var posicion_esperada := centro_pixeles * sprite.scale
	if sprite.flip_v:
		posicion_esperada.y -= 2.0 * centro_pixeles.y * sprite.scale.y
	posicion_esperada += sprite.position + sprite.offset

	_verificar(
		forma != null
		and forma.size.distance_to(tamano_esperado) < 0.1,
		"La caja de referencia de %s debe medir los límites opacos del sprite." % tanque.name
	)
	_verificar(
		colision.position.distance_to(posicion_esperada) < 0.1,
		"La caja de referencia de %s debe centrarse sobre los píxeles visibles." % tanque.name
	)
	_verificar(
		colision.disabled,
		"La caja rectangular de referencia no debe participar en la colisión física."
	)

	var colisiones_silueta := tanque.find_children("*", "CollisionPolygon2D", true, false)
	_verificar(
		not colisiones_silueta.is_empty(),
		"La hitbox física de %s debe generarse como polígonos de silueta." % tanque.name
	)
	var mascara := BitMap.new()
	mascara.create_from_image_alpha(imagen, 0.15)
	var punto_opaco := Vector2.ZERO
	var encontro_punto_opaco := false
	for y in range(limites_visibles.position.y, limites_visibles.end.y):
		for x in range(limites_visibles.position.x, limites_visibles.end.x):
			if mascara.get_bitv(Vector2i(x, y)):
				punto_opaco = Vector2(x, y) + Vector2(0.5, 0.5)
				encontro_punto_opaco = true
				break
		if encontro_punto_opaco:
			break
	_verificar(encontro_punto_opaco, "La textura del tanque debe tener píxeles opacos.")
	if not encontro_punto_opaco:
		return

	var punto_local: Vector2 = tanque.call(
		"_transformar_puntos_de_silueta",
		PackedVector2Array([punto_opaco]),
		imagen.get_size()
	)[0]
	var punto_cubierto := false
	for colision_silueta: CollisionPolygon2D in colisiones_silueta:
		if Geometry2D.is_point_in_polygon(punto_local, colision_silueta.polygon):
			punto_cubierto = true
			break
	_verificar(
		punto_cubierto,
		"La hitbox de %s debe cubrir los píxeles opacos de la imagen." % tanque.name
	)

	var transparencia_fuera_de_hitbox := false
	for y in range(limites_visibles.position.y, limites_visibles.end.y):
		for x in range(limites_visibles.position.x, limites_visibles.end.x):
			if mascara.get_bitv(Vector2i(x, y)):
				continue
			var punto_transparente: Vector2 = tanque.call(
				"_transformar_puntos_de_silueta",
				PackedVector2Array([Vector2(x, y) + Vector2(0.5, 0.5)]),
				imagen.get_size()
			)[0]
			var transparencia_cubierta := false
			for colision_silueta: CollisionPolygon2D in colisiones_silueta:
				if Geometry2D.is_point_in_polygon(punto_transparente, colision_silueta.polygon):
					transparencia_cubierta = true
					break
			if not transparencia_cubierta:
				transparencia_fuera_de_hitbox = true
				break
		if transparencia_fuera_de_hitbox:
			break
	_verificar(
		transparencia_fuera_de_hitbox,
		"La hitbox de %s no debe extenderse sobre píxeles transparentes." % tanque.name
	)


func _probar_catalogo_y_misiones() -> void:
	var tienda: Node = root.get_node("Tienda")
	var gestor_misiones: Node = root.get_node("GestorMisiones")
	var gestor_guardado: Node = root.get_node("GestorGuardado")
	_verificar(tienda.call("obtener_catalogo").size() == 5, "La tienda debe ofrecer los cinco cosméticos del GDD.")
	var misiones: Array[Dictionary] = gestor_misiones.call("obtener_misiones")
	_verificar(misiones.size() == 3, "La campaña debe definir tres misiones.")
	_verificar(misiones[0]["desbloqueada"], "La primera misión debe estar desbloqueada al iniciar.")
	_verificar(not misiones[1]["desbloqueada"], "La segunda misión debe iniciar bloqueada.")
	_verificar(not misiones[2]["desbloqueada"], "La tercera misión debe iniciar bloqueada.")
	_verificar(
		not gestor_misiones.call("seleccionar_mision", "alamein"),
		"No debe ser posible iniciar la segunda misión antes de completar la primera."
	)
	_verificar(
		not gestor_misiones.call("seleccionar_mision", "berlin"),
		"No debe ser posible iniciar la tercera misión antes de completar las anteriores."
	)

	_verificar(
		gestor_misiones.call("seleccionar_mision", "francia")
		and gestor_misiones.call("completar_mision_actual"),
		"Completar la primera misión debe registrar su progreso."
	)
	_verificar(
		gestor_guardado.call("cargar_progreso"),
		"El progreso de Francia debe poder recargarse desde el archivo JSON."
	)
	misiones = gestor_misiones.call("obtener_misiones")
	_verificar(
		misiones[0]["desbloqueada"]
		and misiones[1]["desbloqueada"]
		and not misiones[2]["desbloqueada"],
		"Completar Francia debe desbloquear El Alamein, pero mantener Berlín bloqueada."
	)
	_verificar(
		gestor_misiones.call("seleccionar_mision", "alamein")
		and gestor_misiones.call("completar_mision_actual"),
		"Completar la segunda misión debe registrar su progreso."
	)
	_verificar(
		gestor_guardado.call("cargar_progreso"),
		"El progreso de El Alamein debe poder recargarse desde el archivo JSON."
	)
	misiones = gestor_misiones.call("obtener_misiones")
	_verificar(
		misiones[0]["desbloqueada"]
		and misiones[1]["desbloqueada"]
		and misiones[2]["desbloqueada"],
		"Completar El Alamein debe desbloquear Berlín."
	)
	_verificar(
		gestor_misiones.call("seleccionar_mision", "berlin")
		and gestor_misiones.call("completar_mision_actual"),
		"La última misión debe poder completarse sin buscar una misión siguiente."
	)

	var progreso_legacy: Dictionary = gestor_guardado.call("_crear_progreso_inicial")
	progreso_legacy["version"] = 1
	progreso_legacy.erase("misiones_completadas")
	progreso_legacy["misiones_desbloqueadas"] = ["francia", "alamein"]
	var archivo_legacy := FileAccess.open(gestor_guardado.ruta_archivo, FileAccess.WRITE)
	if archivo_legacy == null:
		_fallar("No se pudo crear el guardado antiguo para comprobar la migración.")
		return
	archivo_legacy.store_string(JSON.stringify(progreso_legacy))
	var error_guardado_legacy := archivo_legacy.get_error()
	archivo_legacy.close()
	if error_guardado_legacy != OK:
		_fallar("No se pudo escribir el guardado antiguo de prueba.")
		return
	_verificar(
		gestor_guardado.call("cargar_progreso"),
		"El guardado anterior debe seguir siendo legible."
	)
	misiones = gestor_misiones.call("obtener_misiones")
	var progreso_migrado: Dictionary = gestor_guardado.get("progreso")
	_verificar(
		progreso_migrado["misiones_completadas"] == ["francia"]
		and progreso_migrado["version"] == 3
		and not progreso_migrado.has("misiones_desbloqueadas")
		and misiones[1]["desbloqueada"]
		and not misiones[2]["desbloqueada"],
		"Un guardado anterior debe migrar el progreso sin saltarse la misión pendiente."
	)

	gestor_guardado.progreso["misiones_completadas"] = ["francia", "alamein", "berlin"]
	_verificar(
		gestor_guardado.call("guardar_progreso"),
		"Debe guardarse el progreso completo antes de probar el reinicio desde el menú."
	)
	var cosmeticos_comprados_antes: Array = gestor_guardado.progreso[
		"cosmeticos_comprados"
	].duplicate()
	var cosmetico_equipado_antes: String = gestor_guardado.progreso["cosmetico_equipado"]
	var menu_misiones := (
		load("res://Vistas/UI/MenuMisiones.tscn") as PackedScene
	).instantiate()
	root.add_child(menu_misiones)
	await process_frame
	var botones_mision: Dictionary = menu_misiones.get("botones")
	var fuente_mision := (
		(botones_mision["francia"] as Button).get_theme_font("font")
		as FontVariation
	)
	_verificar(
		(menu_misiones.get_node("Fondo") as TextureRect).texture != null
		and fuente_mision != null
		and fuente_mision.base_font.resource_path
		== "res://Vistas/Recursos/Fuentes/Oswald-Variable.ttf"
		and int(fuente_mision.variation_opentype.get("wght", 0.0)) == 700
		and (botones_mision["francia"] as Button).text.ends_with("Completada")
		and not (botones_mision["francia"] as Button).disabled
		and is_equal_approx((botones_mision["francia"] as Button).modulate.r, 1.0)
		and (botones_mision["berlin"] as Button).text.ends_with("Completada"),
		"La campaña debe usar el arte de referencia y mostrar el progreso completado."
	)
	var boton_reiniciar: Button = menu_misiones.get_node("ReiniciarMisiones")
	var dialogo_reinicio: ConfirmationDialog = menu_misiones.get_node("DialogoReinicio")
	boton_reiniciar.pressed.emit()
	_verificar(
		dialogo_reinicio.visible,
		"El botón de reinicio debe pedir confirmación antes de alterar el progreso."
	)
	dialogo_reinicio.canceled.emit()
	_verificar(
		gestor_guardado.progreso["misiones_completadas"].size() == 3,
		"Cancelar el reinicio debe conservar las misiones completadas."
	)
	boton_reiniciar.pressed.emit()
	dialogo_reinicio.confirmed.emit()
	await process_frame
	misiones = gestor_misiones.call("obtener_misiones")
	_verificar(
		misiones[0]["desbloqueada"]
		and not misiones[1]["desbloqueada"]
		and not misiones[2]["desbloqueada"]
		and gestor_guardado.progreso["misiones_completadas"].is_empty(),
		"Confirmar el reinicio debe dejar disponible únicamente Francia."
	)
	_verificar(
		gestor_guardado.progreso["cosmeticos_comprados"] == cosmeticos_comprados_antes
		and gestor_guardado.progreso["cosmetico_equipado"] == cosmetico_equipado_antes
		and gestor_guardado.call("cargar_progreso"),
		"Reiniciar misiones debe conservar los cosméticos y persistir el nuevo progreso."
	)
	_verificar(
		not (botones_mision["francia"] as Button).disabled
		and (botones_mision["alamein"] as Button).disabled
		and (botones_mision["berlin"] as Button).disabled
		and is_equal_approx(
			(botones_mision["alamein"] as Button).modulate.r,
			0.62
		)
		and (botones_mision["alamein"] as Button).text.ends_with("Bloqueada")
		and (botones_mision["francia"] as Button).text.ends_with("Disponible")
		and (botones_mision["alamein"] as Button).mouse_filter
		== Control.MOUSE_FILTER_STOP,
		"El menú debe reflejar las misiones bloqueadas y disponibles tras reiniciar."
	)
	var mision_seleccionada_antes: String = gestor_misiones.get("id_mision_actual")
	(botones_mision["alamein"] as Button).pressed.emit()
	_verificar(
		gestor_misiones.get("id_mision_actual") == mision_seleccionada_antes
		and current_scene == null,
		"Una misión bloqueada no debe poder iniciarse mediante el botón."
	)
	menu_misiones.queue_free()
	await process_frame

	var progreso_inconsistente: Dictionary = gestor_guardado.call("_crear_progreso_inicial")
	progreso_inconsistente["misiones_completadas"] = ["berlin"]
	gestor_guardado.set("progreso", progreso_inconsistente)
	misiones = gestor_misiones.call("obtener_misiones")
	var progreso_normalizado: Dictionary = gestor_guardado.get("progreso")
	_verificar(
		progreso_normalizado["misiones_completadas"].is_empty()
		and misiones[0]["desbloqueada"]
		and not misiones[1]["desbloqueada"]
		and not misiones[2]["desbloqueada"],
		"Un registro fuera de orden no debe permitir saltar misiones."
	)


func _verificar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallar(mensaje)


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error(mensaje)
