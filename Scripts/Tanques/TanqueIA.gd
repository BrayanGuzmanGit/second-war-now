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


func mover_en_turno(posicion_objetivo: Vector2) -> void:
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
	var velocidad := Vector2.ZERO
	for _iteracion in range(5):
		velocidad = _calcular_velocidad_disparo(posicion_objetivo, multiplicador)
		visual_tanque.apuntar_canon(velocidad * multiplicador)
	return velocidad


func _calcular_velocidad_disparo(posicion_objetivo: Vector2, multiplicador: float) -> Vector2:
	var distancia_x := absf(posicion_objetivo.x - punto_disparo.global_position.x)
	var direccion_x := signf(posicion_objetivo.x - punto_disparo.global_position.x)
	if is_zero_approx(direccion_x):
		direccion_x = -1.0
	var altura_objetivo := punto_disparo.global_position.y - posicion_objetivo.y
	var angulo := deg_to_rad(angulo_disparo_grados)
	var denominador := 2.0 * cos(angulo) * cos(angulo) * (
		distancia_x * tan(angulo) - altura_objetivo
	)
	var potencia := potencia_maxima
	if denominador > 0.0:
		potencia = sqrt(GameConfig.GRAVEDAD * distancia_x * distancia_x / denominador)
	potencia = clampf(potencia, potencia_minima, potencia_maxima)
	return Vector2(direccion_x * cos(angulo), -sin(angulo)) * potencia / multiplicador
