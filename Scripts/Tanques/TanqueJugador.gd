extends Tanque
class_name TanqueJugador

signal combustible_actualizado(actual: float, maximo: float)
signal disparo_solicitado(origen: Vector2, velocidad: Vector2)

@export var velocidad_movimiento: float = 180.0
@export var combustible_maximo: float = 180.0
@export var consumo_por_pixel: float = 0.8
@export var potencia_minima: float = 300.0
@export var potencia_maxima: float = 1050.0
@export var multiplicador_municion_actual: float = 1.0

const FRACCION_PREVISUALIZACION_TRAYECTORIA := 0.62

@onready var punto_disparo: Marker2D = $Visuales/PivoteCanon/PuntoDisparo
@onready var linea_trayectoria: Line2D = $LineaTrayectoria

var combustible_actual: float
var turno_activo := false
var movimiento_retirada_ilimitado := false
var _velocidad_disparo: Vector2
var _tiempo_apuntado := 0.0
var _vector_apuntado_joystick := Vector2(0.48, -0.36)


func _ready() -> void:
	super._ready()
	combustible_actual = combustible_maximo
	combustible_actualizado.emit(combustible_actual, combustible_maximo)
	linea_trayectoria.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GameConfig.GRAVEDAD * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	var direccion := 0.0
	if turno_activo and not get_node("/root/GestorAudioPartida").interfaz_abierta and (movimiento_retirada_ilimitado or combustible_actual > 0.0):
		direccion = Input.get_axis("Izquierda", "Derecha")

	velocity.x = direccion * velocidad_movimiento
	if not is_zero_approx(direccion) and not movimiento_retirada_ilimitado:
		combustible_actual = maxf(combustible_actual - absf(velocity.x) * delta * consumo_por_pixel, 0.0)
		combustible_actualizado.emit(combustible_actual, combustible_maximo)

	var posicion_antes := global_position
	move_and_slide()
	limitar_movimiento_al_mapa()
	visual_tanque.actualizar_movimiento(
		delta,
		global_position - posicion_antes,
		is_on_floor(),
		get_floor_normal() if is_on_floor() else Vector2.UP
	)
	linea_trayectoria.visible = turno_activo and not movimiento_retirada_ilimitado
	if turno_activo and not movimiento_retirada_ilimitado:
		_actualizar_apuntado()


func _unhandled_input(event: InputEvent) -> void:
	if get_node("/root/GestorAudioPartida").interfaz_abierta:
		return
	if not turno_activo:
		return
	if event.is_action_pressed("Disparo") or (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		# La retirada es una fase de desplazamiento: no debe consumir el control al intentar atacar.
		if movimiento_retirada_ilimitado:
			return
		disparo_solicitado.emit(punto_disparo.global_position, _velocidad_disparo)
		turno_activo = false


func aplicar_cosmetico(id_cosmetico: String) -> void:
	visual_tanque.aplicar_apariencia(id_cosmetico)

func iniciar_turno() -> void:
	if not movimiento_retirada_ilimitado:
		combustible_actual = combustible_maximo
		combustible_actualizado.emit(combustible_actual, combustible_maximo)
	turno_activo = true


func activar_movimiento_retirada_ilimitado() -> void:
	# Tras vencer al enemigo, el combustible deja de limitar el avance hacia el objetivo.
	movimiento_retirada_ilimitado = true


func terminar_turno() -> void:
	turno_activo = false
	linea_trayectoria.visible = false


func refrescar_apuntado() -> void:
	# Actualiza la curva inmediatamente cuando cambia la munición durante el turno.
	if turno_activo and not movimiento_retirada_ilimitado:
		_actualizar_apuntado()


func actualizar_apuntado_joystick(vector: Vector2) -> void:
	_vector_apuntado_joystick = vector.limit_length(1.0)
	if turno_activo and not movimiento_retirada_ilimitado:
		_actualizar_apuntado()


func _actualizar_apuntado() -> void:
	if multiplicador_municion_actual <= 0.0:
		push_error("El multiplicador de potencia debe ser mayor que cero.")
		return
	var intensidad := clampf(_vector_apuntado_joystick.length(), 0.0, 1.0)
	var angulo := 0.0
	if not _vector_apuntado_joystick.is_zero_approx():
		angulo = atan2(-_vector_apuntado_joystick.y, _vector_apuntado_joystick.x)
	angulo = clampf(angulo, -PI * 0.43, PI * 0.43)
	var direccion := Vector2.RIGHT.rotated(-angulo)
	var potencia := lerpf(potencia_minima, potencia_maxima, intensidad)
	_velocidad_disparo = direccion * potencia
	var velocidad_real := _velocidad_disparo * multiplicador_municion_actual
	visual_tanque.apuntar_canon(velocidad_real)
	_tiempo_apuntado = _calcular_tiempo_hasta_suelo(
		punto_disparo.global_position,
		velocidad_real
	)
	_dibujar_trayectoria(
		punto_disparo.global_position,
		velocidad_real
	)


func _calcular_tiempo_hasta_suelo(origen: Vector2, velocidad: Vector2) -> float:
	# Consulta el relieve actual y las ruinas sin revelar el punto final al jugador.
	var terreno := get_tree().get_first_node_in_group("terreno_destructible")
	if terreno != null:
		var mundo := get_world_2d().direct_space_state
		var anterior := origen
		for paso in range(1, 301):
			var tiempo := paso * 0.025
			var siguiente := origen + velocidad * tiempo + Vector2(0, 0.5 * GameConfig.GRAVEDAD * tiempo * tiempo)
			var consulta := PhysicsRayQueryParameters2D.create(anterior, siguiente, 1, [get_rid()])
			var impacto := mundo.intersect_ray(consulta)
			if not impacto.is_empty():
				return tiempo
			if siguiente.x < 0.0 or siguiente.x > 1800.0 or siguiente.y > 1005.0:
				return tiempo
			anterior = siguiente
		return 7.5
	var altura_suelo := 800.0
	var colision_suelo := get_node_or_null("../Suelo/CollisionShape2D") as CollisionShape2D
	if colision_suelo != null and colision_suelo.shape is RectangleShape2D:
		var forma_suelo := colision_suelo.shape as RectangleShape2D
		altura_suelo = colision_suelo.global_position.y - forma_suelo.size.y * 0.5

	var gravedad := GameConfig.GRAVEDAD
	var desplazamiento_vertical := maxf(altura_suelo - origen.y, 0.0)
	var discriminante := velocidad.y * velocidad.y + 2.0 * gravedad * desplazamiento_vertical
	return maxf((-velocidad.y + sqrt(discriminante)) / gravedad, 0.12)


func _dibujar_trayectoria(origen: Vector2, velocidad: Vector2) -> void:
	var puntos := PackedVector2Array()
	var intervalo := 0.04
	var tiempo_visible := _tiempo_apuntado * FRACCION_PREVISUALIZACION_TRAYECTORIA
	puntos.append(linea_trayectoria.to_local(origen))
	var tiempo := 0.0
	while tiempo < tiempo_visible:
		tiempo = minf(tiempo + intervalo, tiempo_visible)
		var punto := (
			origen
			+ velocidad * tiempo
			+ Vector2(0.0, 0.5 * GameConfig.GRAVEDAD * tiempo * tiempo)
		)
		puntos.append(linea_trayectoria.to_local(punto))
	linea_trayectoria.points = puntos
