extends Node

enum Fase { COMBATE, AVANCE, EVACUACION, REFUERZOS, RESULTADO }
const ESCENA_ENEMIGO: PackedScene = preload("res://Vistas/Tanques/TanqueIA.tscn")
const DATOS_CAMPANA = preload("res://Modelos/DatosCampana.gd")
const ESCENARIO_CAMPANA = preload("res://Vistas/Niveles/EscenarioCampana.gd")

const ESCENA_MENU_MISIONES := "res://Vistas/UI/MenuMisiones.tscn"
const ESCENA_EFECTO_SALIDA: PackedScene = preload(
	"res://Vistas/Proyectiles/EfectoSalidaProyectil.tscn"
)

@onready var jugador: TanqueJugador = $"../Jugador"
@onready var enemigo: TanqueIA = $"../Enemigo"
@onready var gestor_jugador: GestorProyectiles = $GestorProyectilesJugador
@onready var gestor_ia: GestorProyectiles = $GestorProyectilesIA
@onready var hud: HUD = $"../HUD"
@onready var zona_evac: Area2D = $"../ZonaEvacuacion"
@onready var camara: Camera2D = $"../Camara"
@onready var mapa_francia: Sprite2D = $"../MapaFrancia"
@onready var mapa_alamein: Sprite2D = $"../MapaElAlamein"
@onready var mapa_berlin: Sprite2D = $"../MapaBerlin"

const TAMANO_MAPA := Vector2(1800.0, 1004.6512)
const CENTRO_VERTICAL_CAMARA := 502.3256

var _combate_finalizado := false
var _id_partida := ""
var _defensas_destruidas := 0
var _resultado_victoria := false
var _resumen_resultado := ""
var _proyectil_en_vuelo := false
var _turno_jugador := true
var _municion_seleccionada := "estandar"
var _enemigo_destruido := false
var fase: Fase = Fase.COMBATE
var indice_posicion := 0
var tiempo_evacuacion := -1.0
var _tiempo_refuerzos := 0.0
var _disparo_refuerzo_realizado := false
var _datos: Dictionary
var _mision: Dictionary
var _secuencia := 0
var terreno: Node2D


func _ready() -> void:
	var menu: Node = get_tree().get_first_node_in_group("panel_sonido")
	menu.pausa_solicitada.connect(_cambiar_pausa)
	menu.abandono_solicitado.connect(_abandonar_mision)
	_id_partida = GestorGuardado.nuevo_id_operacion()
	hud.reintentar_guardado.connect(_guardar_resultado)
	jugador.disparo_solicitado.connect(_disparar_jugador)
	jugador.vida_actualizada.connect(hud.actualizar_vida_jugador)
	jugador.combustible_actualizado.connect(hud.actualizar_combustible)
	enemigo.vida_actualizada.connect(hud.actualizar_vida_enemigo)
	jugador.tanque_destruido.connect(_al_destruir_jugador)
	enemigo.tanque_destruido.connect(_al_destruir_enemigo)
	hud.municion_seleccionada.connect(_seleccionar_municion)
	hud.apuntado_joystick.connect(jugador.actualizar_apuntado_joystick)
	hud.volver_al_menu.connect(_volver_al_menu)
	jugador.actualizar_apuntado_joystick(hud.obtener_vector_apuntado_joystick())
	var mision: Dictionary = GestorMisiones.obtener_mision_actual()
	if mision.is_empty():
		push_error("No se pudo cargar la misión activa.")
		return
	_mision = mision
	get_node("/root/GestorAudioPartida").iniciar(self, mision["id"])
	_datos = DATOS_CAMPANA.obtener(mision["id"])
	jugador.position = _datos["jugador"]
	enemigo.position = _datos["posiciones"][0]
	# Instancia únicamente el relieve de la misión activa, manteniendo la escena y Factory comunes.
	var escenario := ESCENARIO_CAMPANA.new()
	add_child(escenario)
	escenario.configurar(_datos, mision["id"])
	terreno = escenario.terreno
	_colocar_sobre_terreno(jugador)
	_colocar_sobre_terreno(enemigo)
	if mision["id"] != "francia":
		jugador.limite_derecho_mapa = float(_datos["activacion"]) - 30.0
		enemigo.distancia_objetivo = 530.0
		enemigo.angulo_disparo_grados = 52.0 if mision["id"] == "alamein" else 58.0
	hud.actualizar_mision(mision["nombre"], mision["descripcion"])
	jugador.aplicar_cosmetico(GestorGuardado.progreso["cosmetico_equipado"])
	_aplicar_apariencia_enemiga()
	_configurar_fondo(mision["paleta"])
	hud.actualizar_vida_jugador(jugador.vida_actual, jugador.vida_maxima)
	hud.actualizar_combustible(jugador.combustible_maximo, jugador.combustible_maximo)
	hud.actualizar_vida_enemigo(enemigo.vida_actual, enemigo.vida_maxima)
	_actualizar_municion_hud()
	_actualizar_objetivo()
	_activar_turno_jugador(
		"A/D MOVER  •  JOYSTICK APUNTAR  •  CLIC/ESPACIO DISPARAR"
	)


func _process(delta: float) -> void:
	_actualizar_camara(delta)
	_actualizar_fase(delta)


func _actualizar_fase(delta: float) -> void:
	if _combate_finalizado:
		return
	# La llegada tiene precedencia ante el vencimiento en la misma actualización.
	_evaluar_victoria()
	if _combate_finalizado:
		return
	match fase:
		Fase.AVANCE:
			if jugador.global_position.x >= float(_datos["activacion"]) and not _proyectil_en_vuelo:
				_iniciar_siguiente_posicion()
		Fase.EVACUACION:
			if tiempo_evacuacion >= 0.0:
				tiempo_evacuacion = maxf(0.0, tiempo_evacuacion - delta)
				hud.actualizar_cuenta_atras(tiempo_evacuacion)
				get_node("/root/GestorAudioPartida").cuenta_atras(tiempo_evacuacion)
				if tiempo_evacuacion <= 0.0:
					_iniciar_refuerzos()
		Fase.REFUERZOS:
			_tiempo_refuerzos += delta
			if _tiempo_refuerzos >= 2.0 and not _disparo_refuerzo_realizado:
				_disparar_refuerzo()


func _disparar_jugador(origen: Vector2, velocidad: Vector2) -> void:
	if _combate_finalizado:
		return
	if fase != Fase.COMBATE:
		return
	if _proyectil_en_vuelo or not _turno_jugador:
		return
	if not gestor_jugador.esta_disponible(_municion_seleccionada):
		_actualizar_municion_hud()
		hud.actualizar_estado(
			"Se seleccionó %s automáticamente; dispara de nuevo."
			% _municion_seleccionada.capitalize()
		)
		return
	jugador.terminar_turno()
	hud.actualizar_turno("DISPARO DEL JUGADOR EN VUELO", false)
	if _lanzar_proyectil(origen, velocidad, jugador, true, _municion_seleccionada, gestor_jugador):
		hud.actualizar_estado("Proyectil en vuelo")


func _lanzar_proyectil(
	origen: Vector2,
	velocidad: Vector2,
	emisor: Node2D,
	es_turno_jugador: bool,
	tipo: String,
	gestor: GestorProyectiles
) -> bool:
	var proyectil := gestor.crear_proyectil(tipo)
	if proyectil == null:
		hud.actualizar_estado("No se pudo crear la munición seleccionada")
		if es_turno_jugador:
			jugador.turno_activo = true
			hud.actualizar_turno("TU TURNO", true)
		else:
			_recuperar_turno_jugador("La IA no pudo crear su proyectil; puedes continuar.")
		return false
	if not gestor.registrar_uso(tipo):
		proyectil.free()
		hud.actualizar_estado("No se pudo registrar el uso de la munición")
		if es_turno_jugador:
			jugador.turno_activo = true
			hud.actualizar_turno("TU TURNO", true)
		else:
			_recuperar_turno_jugador("La IA no pudo registrar su munición; puedes continuar.")
		return false

	# Prepara automáticamente la siguiente munición para que el próximo turno siempre pueda disparar.
	if es_turno_jugador:
		_seleccionar_siguiente_municion_disponible()

	_proyectil_en_vuelo = true
	proyectil.terreno = terreno
	proyectil.finalizado.connect(_al_finalizar_proyectil.bind(es_turno_jugador, _secuencia))
	get_tree().current_scene.add_child(proyectil)
	proyectil.global_position = origen
	# Dos combates sin curación deben ser superables; la escala incluye el daño periódico.
	if not es_turno_jugador:
		proyectil.dano_base *= float(_datos["dano_ia"])
		proyectil.dano_por_tick *= float(_datos["dano_ia"])
	proyectil.configurar(velocidad, emisor)
	_mostrar_efecto_salida(origen, velocidad, tipo)
	_actualizar_municion_hud()
	return true


func _mostrar_efecto_salida(origen: Vector2, velocidad: Vector2, tipo: String) -> void:
	get_node("/root/GestorAudioPartida").evento("disparo", origen, tipo)
	# El fogonazo solo se crea tras validar Factory y ciclo, junto al marcador de disparo.
	var efecto := ESCENA_EFECTO_SALIDA.instantiate() as EfectoSalidaProyectil
	efecto.tipo_proyectil = tipo
	efecto.add_to_group("efectos_salida_proyectil")
	get_tree().current_scene.add_child(efecto)
	efecto.global_position = origen
	if not velocidad.is_zero_approx():
		efecto.rotation = velocidad.angle()


func _al_finalizar_proyectil(es_turno_jugador: bool, secuencia: int = -1) -> void:
	# Ignora finalizaciones de una posición anterior o de una misión ya resuelta.
	if secuencia >= 0 and secuencia != _secuencia:
		return
	# Mantiene la acción pendiente mientras se publican colisiones y se asientan los cuerpos.
	await _esperar_asentamiento()
	if secuencia >= 0 and secuencia != _secuencia:
		return
	_proyectil_en_vuelo = false
	if _combate_finalizado:
		return
	if fase != Fase.COMBATE:
		return
	if es_turno_jugador:
		_iniciar_turno_ia()
	else:
		if jugador.vida_actual <= 0.0:
			_finalizar_combate(false)
			return
		_activar_turno_jugador(
			"A/D MOVER  •  JOYSTICK APUNTAR  •  CLIC/ESPACIO DISPARAR"
		)


func _esperar_asentamiento() -> void:
	var estables := 0
	for paso in range(120):
		if _combate_finalizado:
			return
		var quietos: bool = not terreno.hay_deformaciones()
		for tanque in [jugador, enemigo]:
			if is_instance_valid(tanque) and tanque.vida_actual > 0:
				quietos = quietos and tanque.is_on_floor() and absf(tanque.velocity.y) < 1.0
		estables = estables + 1 if quietos else 0
		if estables >= 3:
			return
		await get_tree().physics_frame
		while is_inside_tree() and get_tree().paused:
			await get_tree().process_frame


func _colocar_sobre_terreno(tanque: Tanque) -> void:
	# La aparición usa el punto inferior de la silueta, no una altura fija del mapa.
	var inferior := tanque.forma_colision.position.y + tanque.forma_colision.shape.get_rect().size.y * 0.5
	var ancho := tanque.forma_colision.shape.get_rect().size.x
	var centro := tanque.position.x + tanque.forma_colision.position.x
	var altura: float = terreno.obtener_altura(centro)
	for x in range(int(centro - ancho * 0.5), int(centro + ancho * 0.5) + 1, 4):
		altura = minf(altura, terreno.obtener_altura(x))
	tanque.position.y = altura - inferior - 1.0
	tanque.velocity = Vector2.ZERO
	get_node("/root/GestorAudioPartida").reiniciar_unidad(tanque)
	if tanque.visual_tanque.rodaje != null:
		tanque.visual_tanque.rodaje.reiniciar()


func _iniciar_turno_ia() -> void:
	if fase != Fase.COMBATE or _combate_finalizado:
		return
	var secuencia := _secuencia
	_turno_jugador = false
	jugador.terminar_turno()
	hud.actualizar_turno("TURNO DEL ENEMIGO", false)
	get_node("/root/GestorAudioPartida").evento("turno_enemigo")
	hud.actualizar_estado("Turno de la IA")
	await get_tree().create_timer(0.7, false).timeout
	if _combate_finalizado or fase != Fase.COMBATE or secuencia != _secuencia or enemigo.vida_actual <= 0.0:
		return
	hud.actualizar_estado("El enemigo está reposicionándose...")
	await enemigo.mover_en_turno(jugador.global_position)
	if _combate_finalizado or fase != Fase.COMBATE or secuencia != _secuencia or enemigo.vida_actual <= 0.0:
		return
	var municion_ia: Array[String] = gestor_ia.obtener_disponibles()
	if municion_ia.is_empty():
		push_error("La IA no tiene munición disponible para continuar el combate.")
		_recuperar_turno_jugador("La IA no tiene munición disponible; continúa tu turno.")
		return
	var multiplicador := gestor_ia.obtener_multiplicador_potencia(municion_ia[0])
	var velocidad := enemigo.calcular_disparo(
		jugador.obtener_punto_impacto_global(),
		multiplicador
	)
	var origen := enemigo.punto_disparo.global_position
	hud.actualizar_turno("DISPARO DEL ENEMIGO EN VUELO", false)
	if _lanzar_proyectil(origen, velocidad, enemigo, false, municion_ia[0], gestor_ia):
		hud.actualizar_estado("El enemigo ha disparado")


func _seleccionar_municion(tipo: String) -> void:
	if get_tree().paused or fase != Fase.COMBATE or _combate_finalizado or not _turno_jugador or _proyectil_en_vuelo:
		return
	if not gestor_jugador.esta_disponible(tipo):
		hud.actualizar_estado("Esa munición no está disponible hasta completar el ciclo")
		return
	if tipo == _municion_seleccionada:
		hud.cerrar_selector(true)
		return
	hud.cerrar_selector()
	_municion_seleccionada = tipo
	_actualizar_municion_hud()
	get_node("/root/GestorAudioPartida").interfaz("seleccion", tipo)
	hud.actualizar_estado("Munición seleccionada: %s" % tipo.capitalize())


func _actualizar_municion_hud() -> void:
	# Mantiene sincronizados la selección visual, el multiplicador del tanque y su curva.
	var disponibles := gestor_jugador.obtener_disponibles()
	if not disponibles.is_empty() and not disponibles.has(_municion_seleccionada):
		_seleccionar_siguiente_municion_disponible(disponibles)
	hud.actualizar_municion(_municion_seleccionada, disponibles)
	jugador.multiplicador_municion_actual = gestor_jugador.obtener_multiplicador_potencia(
		_municion_seleccionada
	)
	jugador.refrescar_apuntado()


func _al_destruir_jugador() -> void:
	_finalizar_combate(false)


func _al_destruir_enemigo() -> void:
	if _combate_finalizado or fase != Fase.COMBATE:
		return
	_enemigo_destruido = true
	_defensas_destruidas += 1
	var quedan_posiciones: bool = indice_posicion + 1 < _datos["posiciones"].size()
	fase = Fase.AVANCE if quedan_posiciones else Fase.EVACUACION
	tiempo_evacuacion = float(_datos["evacuacion_segundos"]) if _mision["id"] == "francia" else -1.0
	if tiempo_evacuacion > 0.0:
		get_node("/root/GestorAudioPartida").evento("evacuacion")
	jugador.activar_movimiento_retirada_ilimitado()
	jugador.limite_derecho_mapa = 1680.0
	# La retirada sustituye al combate; los controles de ataque quedan inactivos desde el impacto.
	_activar_fase_retirada()
	var aviso: String = _datos["avance"] if quedan_posiciones else _mision["mensaje_retirada"]
	hud.mostrar_aviso_retirada(aviso)
	hud.actualizar_cuenta_atras(tiempo_evacuacion)
	_actualizar_objetivo()
	_evaluar_victoria()


func _activar_fase_retirada() -> void:
	# Mantiene el movimiento disponible sin representar la retirada como otro turno de combate.
	_turno_jugador = false
	jugador.iniciar_turno()
	hud.actualizar_turno("FASE DE RETIRADA" if _mision["id"] == "francia" else "FASE DE AVANCE", false)
	hud.actualizar_estado("A/D para avanzar • Movimiento ilimitado • Disparos desactivados")


func _actualizar_objetivo() -> void:
	var objetivo: String = _datos["objetivos"][indice_posicion]
	if fase == Fase.AVANCE:
		objetivo = _datos["avance"]
	elif fase == Fase.EVACUACION:
		objetivo = "Evacúa a Dunkerque antes de los refuerzos." if _mision["id"] == "francia" else "Defensas superadas. Alcanza la bandera final."
	hud.actualizar_objetivo(objetivo, indice_posicion + 1, _datos["posiciones"].size())


func _iniciar_siguiente_posicion() -> void:
	indice_posicion += 1
	_secuencia += 1
	_enemigo_destruido = false
	fase = Fase.COMBATE
	# El resto del primer enemigo permanece en el escenario; solo se sustituye la referencia activa.
	enemigo = ESCENA_ENEMIGO.instantiate() as TanqueIA
	enemigo.position = _datos["posiciones"][indice_posicion]
	enemigo.distancia_objetivo = 510.0
	enemigo.angulo_disparo_grados = 52.0 if _mision["id"] == "alamein" else 58.0
	get_parent().add_child(enemigo)
	_aplicar_apariencia_enemiga()
	_colocar_sobre_terreno(enemigo)
	terreno.perfil.liberar_posicion(enemigo.position.x)
	enemigo.vida_actualizada.connect(hud.actualizar_vida_enemigo)
	enemigo.tanque_destruido.connect(_al_destruir_enemigo)
	# Cada enemigo conserva su ciclo independiente; el ciclo del jugador no se reinicia.
	gestor_ia = GestorProyectiles.new()
	add_child(gestor_ia)
	jugador.movimiento_retirada_ilimitado = false
	hud.panel_aviso_retirada.hide()
	hud.actualizar_vida_enemigo(enemigo.vida_actual, enemigo.vida_maxima)
	_actualizar_objetivo()
	_activar_turno_jugador("Segunda posición defensiva: apunta y dispara")


func _iniciar_refuerzos() -> void:
	get_node("/root/GestorAudioPartida").evento("refuerzos")
	# El plazo es definitivo: la animación anuncia la derrota, no abre otra ventana de victoria.
	fase = Fase.REFUERZOS
	_secuencia += 1
	_proyectil_en_vuelo = false
	jugador.terminar_turno()
	jugador.velocity = Vector2.ZERO
	hud.actualizar_turno("¡REFUERZOS ENEMIGOS!", false)
	hud.actualizar_estado("La ruta de evacuación ha sido cortada")
	hud.mostrar_aviso_retirada("¡Refuerzos enemigos! La ruta de evacuación ha sido cortada")
	hud.etiqueta_titulo_retirada.text = "¡REFUERZOS ENEMIGOS!"
	enemigo = ESCENA_ENEMIGO.instantiate() as TanqueIA
	# Aparece dentro del encuadre, sin reaprovechar ni revivir el enemigo destruido.
	enemigo.position = Vector2(clampf(jugador.position.x + 420.0, 1100.0, 1640.0), 720)
	get_parent().add_child(enemigo)
	_aplicar_apariencia_enemiga()
	_colocar_sobre_terreno(enemigo)
	enemigo.visual_tanque.apuntar_canon(jugador.obtener_punto_impacto_global() - enemigo.punto_disparo.global_position)


func _disparar_refuerzo() -> void:
	_disparo_refuerzo_realizado = true
	# La Factory crea también el disparo de la secuencia letal. Es una animación dirigida,
	# independiente de obstáculos y turnos, porque el fracaso ya se decidió al vencer el plazo.
	var gestor := GestorProyectiles.new()
	add_child(gestor)
	var proyectil := gestor.crear_proyectil("estandar")
	gestor.registrar_uso("estandar")
	get_parent().add_child(proyectil)
	var origen := enemigo.punto_disparo.global_position
	var destino := jugador.obtener_punto_impacto_global()
	proyectil.global_position = origen
	proyectil.configurar((destino - origen) / 0.35, enemigo)
	proyectil.set_physics_process(false)
	proyectil.set_deferred("monitoring", false)
	_mostrar_efecto_salida(origen, destino - origen, "estandar")
	var animacion := create_tween()
	animacion.tween_property(proyectil, "global_position", destino, 0.35)
	animacion.tween_callback(func() -> void:
		proyectil.queue_free()
		if fase == Fase.REFUERZOS and not _combate_finalizado:
			get_node("/root/GestorAudioPartida").impacto(jugador, destino, "estandar")
			jugador.recibir_impacto_proyectil(jugador.vida_actual, destino, (destino - origen).normalized(), "estandar")
	)


func _evaluar_victoria() -> void:
	if (
		not _combate_finalizado
		and fase == Fase.EVACUACION
		and jugador.vida_actual > 0.0
		and _enemigo_destruido
		and _jugador_esta_en_zona_evac()
	):
		_finalizar_combate(true)


func _jugador_esta_en_zona_evac() -> bool:
	if zona_evac.overlaps_body(jugador):
		return true

	# El chequeo geométrico también detecta cuerpos que cruzaron el área entre actualizaciones físicas.
	var forma_zona := zona_evac.get_node("CollisionShape2D") as CollisionShape2D
	var rectangulo_zona := forma_zona.shape as RectangleShape2D
	var forma_jugador := jugador.get_node("CollisionShape2D") as CollisionShape2D
	var rectangulo_jugador := forma_jugador.shape as RectangleShape2D
	var tamano_zona := rectangulo_zona.size * forma_zona.global_scale.abs()
	var tamano_jugador := rectangulo_jugador.size * forma_jugador.global_scale.abs()
	var limites_zona := Rect2(forma_zona.global_position - tamano_zona * 0.5, tamano_zona)
	var limites_jugador := Rect2(
		forma_jugador.global_position - tamano_jugador * 0.5,
		tamano_jugador
	)
	return limites_zona.intersects(limites_jugador)


func _finalizar_combate(victoria: bool) -> void:
	if _combate_finalizado:
		return
	_combate_finalizado = true
	get_node("/root/GestorAudioPartida").finalizar()
	fase = Fase.RESULTADO
	_secuencia += 1
	tiempo_evacuacion = -1.0
	hud.actualizar_cuenta_atras(-1.0)
	hud.panel_aviso_retirada.hide()
	hud.actualizar_turno("MISIÓN FINALIZADA", false)
	jugador.terminar_turno()
	var mision: Dictionary = GestorMisiones.obtener_mision_actual()
	var resumen: String = mision["resumen_historico"] if victoria else mision["descripcion"]
	if victoria and mision["id"] == "berlin":
		resumen += "\n\n" + mision["epilogo"]
	elif not victoria and _disparo_refuerzo_realizado:
		resumen = "No evacuaste a tiempo. Los refuerzos cortaron la ruta de retirada hacia Dunkerque."
	_resultado_victoria = victoria
	_resumen_resultado = resumen
	_guardar_resultado()
	# Liquidar antes de reproducir: omitir/cerrar nunca pierde ni duplica monedas.
	if victoria:
		var video := preload("res://Vistas/UI/VideoMision.gd").mostrar(self, mision.get("video_victoria", ""))
		if video != null:
			hud.panel_resultado.hide()
			await video.finalizado
			hud.panel_resultado.show()


func _guardar_resultado() -> void:
	var resultado: Dictionary = GestorGuardado.liquidar_partida(
		_id_partida, _mision["id"], _resultado_victoria, _defensas_destruidas
	)
	hud.mostrar_resultado(_resultado_victoria, _resumen_resultado, resultado["ok"])
	hud.mostrar_recompensa(resultado)


func _aplicar_apariencia_enemiga() -> void:
	enemigo.visual_tanque.aplicar_apariencia(_datos["apariencia_enemiga"])


func _configurar_fondo(paleta: String) -> void:
	mapa_francia.visible = paleta == "francia"
	mapa_alamein.visible = paleta == "alamein"
	mapa_berlin.visible = paleta == "berlin"
	if not mapa_francia.visible and not mapa_alamein.visible and not mapa_berlin.visible:
		push_error("No existe un fondo para la paleta de misión: %s." % paleta)
		return

	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(TAMANO_MAPA.x)
	camara.limit_bottom = ceili(TAMANO_MAPA.y)
	camara.global_position = Vector2(
		(jugador.global_position.x + enemigo.global_position.x) * 0.5,
		CENTRO_VERTICAL_CAMARA
	)


func _actualizar_camara(delta: float) -> void:
	var objetivo_x := jugador.global_position.x
	var zoom_objetivo := 1.08
	if not _enemigo_destruido:
		var caja_jugador := jugador.forma_colision.shape.get_rect().size.x * 0.5
		var caja_enemigo := enemigo.forma_colision.shape.get_rect().size.x * 0.5
		var izquierda := minf(jugador.obtener_punto_impacto_global().x - caja_jugador, enemigo.obtener_punto_impacto_global().x - caja_enemigo)
		var derecha := maxf(jugador.obtener_punto_impacto_global().x + caja_jugador, enemigo.obtener_punto_impacto_global().x + caja_enemigo)
		objetivo_x = (izquierda + derecha) * 0.5
		zoom_objetivo = clampf(camara.get_viewport_rect().size.x / (derecha - izquierda + 48.0), 0.85, 1.08)
	camara.zoom = Vector2.ONE * zoom_objetivo
	var mitad_vista: float = camara.get_viewport_rect().size.x / (2.0 * camara.zoom.x)
	objetivo_x = clampf(objetivo_x, mitad_vista, TAMANO_MAPA.x - mitad_vista)
	# Conserva margen bajo las orugas incluso cuando el suelo queda 80 unidades más abajo.
	var mitad_alto: float = camara.get_viewport_rect().size.y / (2.0 * camara.zoom.y)
	var suelo_visible: float = terreno.obtener_altura(jugador.position.x)
	if not _enemigo_destruido:
		suelo_visible = maxf(suelo_visible, terreno.obtener_altura(enemigo.position.x))
	var objetivo_y := clampf(maxf(CENTRO_VERTICAL_CAMARA, suelo_visible + 65.0 - mitad_alto), mitad_alto, TAMANO_MAPA.y - mitad_alto)
	var factor_suavizado := 1.0 - exp(-5.0 * delta)
	camara.global_position = camara.global_position.lerp(
		Vector2(objetivo_x, objetivo_y),
		factor_suavizado
	)


func _volver_al_menu() -> void:
	get_tree().paused = false
	var resultado := get_tree().change_scene_to_file(ESCENA_MENU_MISIONES)
	if resultado != OK:
		push_error("No se pudo volver al menú de misiones (código %d)." % resultado)

func _cambiar_pausa(valor: bool) -> void:
	if _combate_finalizado:
		return
	hud.set("_arrastrando_joystick", false)
	hud.menu_desplegable_municion.hide()
	get_tree().paused = valor

func _abandonar_mision() -> void:
	_combate_finalizado = true
	_secuencia += 1
	get_node("/root/GestorAudioPartida").detener_todo()
	_volver_al_menu()


func _activar_turno_jugador(mensaje: String) -> void:
	get_node("/root/GestorAudioPartida").evento("turno_jugador")
	if fase != Fase.COMBATE or _combate_finalizado:
		return
	_turno_jugador = true
	jugador.iniciar_turno()
	_actualizar_municion_hud()
	hud.actualizar_turno("TU TURNO", true)
	hud.actualizar_estado(mensaje)


func _recuperar_turno_jugador(mensaje: String) -> void:
	_proyectil_en_vuelo = false
	_activar_turno_jugador(mensaje)


func _seleccionar_siguiente_municion_disponible(disponibles: Array[String] = []) -> void:
	# Conserva la munición actual si sigue disponible; en caso contrario elige la primera del ciclo.
	var municiones_disponibles := disponibles
	if municiones_disponibles.is_empty():
		municiones_disponibles = gestor_jugador.obtener_disponibles()
	if municiones_disponibles.is_empty():
		push_error("No hay munición disponible para seleccionar en el ciclo actual.")
		return
	if not municiones_disponibles.has(_municion_seleccionada):
		_municion_seleccionada = municiones_disponibles[0]
