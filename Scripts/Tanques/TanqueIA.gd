extends Tanque
class_name TanqueIA

@export var angulo_disparo_grados: float = 35.0
@export var potencia_minima: float = 500.0
@export var potencia_maxima: float = 1100.0
@export var velocidad_movimiento: float = 160.0
@export var desplazamiento_maximo_turno: float = 100.0
@export var distancia_objetivo: float = 700.0

@onready var punto_disparo: Marker2D = $Visuales/PivoteCanon/PuntoDisparo

var _destino_x := 0.0
var _en_movimiento := false
var _tiempo_movimiento := 0.0


# Memoria privada de esta posición defensiva. Para dispersión se conserva
# el fragmento más próximo al blanco; un impacto directo siempre prevalece.
var referencia := Vector2.INF
var impacto := Vector2.INF
var acierto := false
var cobertura := false
var margen_anterior := 1.0
var ultimo_arco := -1.0
var sesgo := 1.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GameConfig.GRAVEDAD * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if _en_movimiento:
		_tiempo_movimiento += delta
		var distancia_restante := _destino_x - global_position.x
		velocity.x = signf(distancia_restante) * velocidad_movimiento
		if absf(distancia_restante) <= velocidad_movimiento * delta:
			velocity.x = distancia_restante / delta
	else:
		velocity.x = 0.0

	var posicion_antes := global_position
	move_and_slide()
	limitar_movimiento_al_mapa()
	visual_tanque.actualizar_movimiento(
		delta,
		global_position - posicion_antes,
		is_on_floor(),
		get_floor_normal() if is_on_floor() else Vector2.UP
	)

	if _en_movimiento:
		var bloqueado := false
		for indice in range(get_slide_collision_count()):
			var normal := get_slide_collision(indice).get_normal()
			if absf(normal.x) > 0.5 and normal.y > -cos(floor_max_angle):
				bloqueado = true
				break
		if (
			bloqueado
			or _tiempo_movimiento >= 1.5
			or absf(_destino_x - global_position.x) <= 2.0
		):
			_en_movimiento = false
			velocity.x = 0.0


func mover_en_turno(posicion_objetivo: Vector2, paso := INF) -> void:
	var posicion_deseada := clampf(
		posicion_objetivo.x + distancia_objetivo,
		limite_izquierdo_mapa,
		limite_derecho_mapa
	)
	var desplazamiento := clampf(
		posicion_deseada - global_position.x,
		-desplazamiento_maximo_turno,
		desplazamiento_maximo_turno
	)
	if is_finite(paso):
		desplazamiento = clampf(global_position.x + paso, limite_izquierdo_mapa, limite_derecho_mapa) - global_position.x
	if absf(desplazamiento) < 8.0:
		return

	_destino_x = global_position.x + desplazamiento
	_tiempo_movimiento = 0.0
	_en_movimiento = true
	while _en_movimiento and not _destruido:
		await get_tree().physics_frame
		while is_inside_tree() and get_tree().paused:
			await get_tree().process_frame
	_en_movimiento = false


func calcular_disparo(posicion_objetivo: Vector2, multiplicador: float = 1.0) -> Vector2:
	if multiplicador <= 0.0:
		push_error("El multiplicador de munición de la IA debe ser mayor que cero.")
		return Vector2.ZERO
	var origen := _origen_virtual(posicion_objetivo, angulo_disparo_grados, Vector2.ZERO)
	var velocidad := _calcular_velocidad_disparo(posicion_objetivo, multiplicador, origen)
	visual_tanque.apuntar_canon(velocidad)
	return _calcular_velocidad_disparo(posicion_objetivo, multiplicador)


func _calcular_velocidad_disparo(posicion_objetivo: Vector2, multiplicador: float, origen := Vector2.INF, grados := -1.0) -> Vector2:
	if origen == Vector2.INF:
		origen = punto_disparo.global_position
	var distancia_x := absf(posicion_objetivo.x - origen.x)
	var direccion_x := signf(posicion_objetivo.x - origen.x)
	if is_zero_approx(direccion_x):
		direccion_x = -1.0
	var altura_objetivo := origen.y - posicion_objetivo.y
	var angulo := deg_to_rad(angulo_disparo_grados if grados < 0.0 else grados)
	var denominador := 2.0 * cos(angulo) * cos(angulo) * (
		distancia_x * tan(angulo) - altura_objetivo
	)
	var potencia := potencia_maxima
	if denominador > 0.0:
		potencia = sqrt(GameConfig.GRAVEDAD * distancia_x * distancia_x / denominador)
	potencia = clampf(potencia, potencia_minima, potencia_maxima)
	return Vector2(direccion_x * cos(angulo), -sin(angulo)) * potencia / multiplicador


func observar_impacto(punto: Vector2, cuerpo: Node2D) -> void:
	var directo := cuerpo is Tanque
	if not referencia.is_finite() or acierto:
		return
	if not directo and impacto.distance_squared_to(referencia) < punto.distance_squared_to(referencia):
		return
	impacto = punto
	acierto = directo
	var antes_del_blanco := (punto.x - referencia.x) * signf(global_position.x - referencia.x) > 90.0
	var interrumpe_arco := cuerpo != null and (not cuerpo.is_in_group("suelo_destructible") or punto.y < referencia.y)
	cobertura = not directo and antes_del_blanco and interrumpe_arco

func _origen_virtual(objetivo: Vector2, grados: float, traslado: Vector2) -> Vector2:
	var pivote := punto_disparo.get_parent() as Node2D
	var direccion := Vector2(signf(objetivo.x - global_position.x) * cos(deg_to_rad(grados)), -sin(deg_to_rad(grados)))
	return pivote.global_position + traslado + direccion * pivote.global_position.distance_to(punto_disparo.global_position)

# Estimar el primer contacto sobre la geometría actual sin instanciar proyectiles.
func _contacto(origen: Vector2, velocidad_inicial: Vector2, duracion: float, objetivo: Tanque) -> Dictionary:
	var pos := origen
	var v := velocidad_inicial
	var gravedad := Vector2.DOWN * GameConfig.GRAVEDAD
	var consulta := PhysicsRayQueryParameters2D.create(pos, pos, 1, [get_rid()])
	var espacio := get_world_2d().direct_space_state
	var tiempo := 0.0
	while tiempo < duracion:
		var dt := minf(0.10, duracion - tiempo)
		var fin := pos + v * dt + gravedad * dt * dt * 0.5
		consulta.from = pos
		consulta.to = fin
		var choque := espacio.intersect_ray(consulta)
		if not choque.is_empty():
			return {"p":choque.position, "directo":choque.collider == objetivo, "cuerpo":choque.collider, "v":v, "libre":false}
		pos = fin
		v += gravedad * dt
		tiempo += dt
		if pos.y > 1150 or pos.x < -110 or pos.x > 1910:
			break
	return {"p":pos, "directo":false, "cuerpo":null, "v":v, "libre":true}

func _valorar_posicion(objetivo: Tanque, disponibles: Array[String], datos: Dictionary, indice: int, traslado: Vector2) -> Dictionary:
	var blanco := objetivo.obtener_punto_impacto_global()
	var cambio := referencia != Vector2.INF and blanco.distance_to(referencia) >= (objetivo.forma_colision.shape.get_rect().size.x * absf(objetivo.forma_colision.global_scale.x)) * 0.5
	var mejor := {"tipo":disponibles[0], "arco":35.0, "valor":-INF, "desplazamiento":traslado.x}
	for arco: float in datos.arcos:
		var origen := _origen_virtual(blanco, arco, traslado)
		var v := _calcular_velocidad_disparo(blanco, 1.0, origen, arco)
		var contacto := _contacto(origen, v, 4.0, objetivo)
		var distancia := blanco.distance_to(contacto.p)
		for tipo in disponibles:
			var dano := 0.0
			var preferencia := 0.0
			match tipo:
				"estandar":
					dano = 25 if contacto.directo or distancia <= 35 else 0
					preferencia = 12 if referencia == Vector2.INF else 4
				"pesado":
					dano = 48 if contacto.directo or distancia <= 58 else 0
					preferencia = 12 if acierto and not cambio else -17
				"bombardeo":
					dano = 45 if not contacto.libre and distancia <= 160 else 0
					preferencia = -22 if contacto.directo else -5
					if cobertura and contacto.cuerpo != null and contacto.cuerpo.is_in_group("suelo_destructible") and distancia < 220:
						preferencia += 42 if datos.priorizar_remate_final and indice > 0 else 24
				"incendiario":
					dano = 36 if distancia <= 72 else (12 if contacto.directo else 0)
					preferencia = -7 if not cambio else -13
				"dispersion":
					var division := _contacto(origen, v, 0.45, objetivo)
					if division.libre:
						for i in 5:
							var frag := Vector2(division.v).rotated(deg_to_rad((i - 2) * 9.5)) * 0.72
							if _contacto(division.p, frag, 2.0, objetivo).directo:
								dano += 4
					preferencia = 28 if cambio and dano > 0 else -6
			var valor := dano + preferencia
			if dano == 0:
				valor = -75 - distancia * 0.1 + preferencia
			if dano * float(datos.dano_ia) >= objetivo.vida_actual:
				valor += 140 if datos.priorizar_remate_final and indice > 0 else 100
				if tipo == "estandar":
					valor += 70
			if cobertura and is_equal_approx(arco, ultimo_arco) and not contacto.directo:
				valor -= 14
			if valor > float(mejor.valor):
				mejor = {"tipo":tipo,"arco":arco,"valor":valor,"desplazamiento":traslado.x}
	return mejor

func decidir(objetivo: Tanque, opciones: Array[String], datos: Dictionary, indice: int, permitir_movimiento := true) -> Dictionary:
	var actual := _valorar_posicion(objetivo, opciones, datos, indice, Vector2.ZERO)
	if not permitir_movimiento or actual.valor >= 10:
		return actual
	var terreno := get_tree().get_first_node_in_group("terreno_destructible")
	for sentido in [-1.0, 1.0]:
		var x := clampf(global_position.x + float(sentido) * desplazamiento_maximo_turno, limite_izquierdo_mapa, limite_derecho_mapa)
		var dy := 0.0
		if terreno != null:
			dy = terreno.obtener_altura(x) - terreno.obtener_altura(global_position.x)
		var otra := _valorar_posicion(objetivo, opciones, datos, indice, Vector2(x-global_position.x, dy))
		if otra.valor > actual.valor + 5:
			actual = otra
	return actual

func preparar_tiro(objetivo: Tanque, decision: Dictionary, datos: Dictionary, multiplicador: float) -> Vector2:
	var blanco := objetivo.obtener_punto_impacto_global()
	var ancho := maxf(1.0, (objetivo.forma_colision.shape.get_rect().size.x * absf(objetivo.forma_colision.global_scale.x)))
	var margen := 1.0
	if referencia != Vector2.INF and impacto.is_finite():
		margen = lerpf(margen_anterior * 0.5, 1.0, clampf(blanco.distance_to(referencia) / ancho, 0, 1))
		if not acierto and not cobertura:
			sesgo = signf(referencia.x - impacto.x)
	else:
		sesgo = 1 if randf() < 0.5 else -1
	margen_anterior = margen
	referencia = blanco
	acierto = false
	cobertura = false
	impacto = Vector2.INF
	ultimo_arco = decision.arco
	var ajuste := margen * float(datos.margen_cascos) * ancho * smoothstep(200, 750, absf(blanco.x-global_position.x))
	blanco.x += sesgo * ajuste
	var origen := _origen_virtual(blanco, ultimo_arco, Vector2.ZERO)
	var tiro := _calcular_velocidad_disparo(blanco, multiplicador, origen, ultimo_arco)
	visual_tanque.apuntar_canon(tiro)
	return _calcular_velocidad_disparo(blanco, multiplicador, punto_disparo.global_position, ultimo_arco)
