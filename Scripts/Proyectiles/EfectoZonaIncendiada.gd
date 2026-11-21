extends Node2D
class_name EfectoZonaIncendiada

var radio := 72.0
var duracion := 1.95
var _tiempo := 0.0


func _process(delta: float) -> void:
	# La animación cubre el mismo intervalo que el daño periódico, pero no calcula daño.
	_tiempo += delta
	queue_redraw()
	if _tiempo >= duracion:
		queue_free()


func _draw() -> void:
	var progreso := clampf(_tiempo / duracion, 0.0, 1.0)
	var pulso := 0.72 + 0.28 * sin(_tiempo * 18.0)
	var opacidad := 1.0 - progreso * 0.55
	draw_arc(
		Vector2.ZERO,
		radio * 0.82,
		0.0,
		TAU,
		40,
		Color(1.0, 0.28, 0.06, opacidad * 0.6),
		3.0
	)
	draw_circle(Vector2.ZERO, radio * 0.55, Color(1.0, 0.24, 0.04, opacidad * 0.12))

	for indice in range(9):
		var proporcion := float(indice) / 9.0
		var angulo := TAU * proporcion + _tiempo * (0.35 if indice % 2 == 0 else -0.25)
		var centro := Vector2.from_angle(angulo) * radio * (0.28 + 0.42 * pulso)
		var altura := 7.0 + 8.0 * pulso
		var llama := PackedVector2Array([
			centro + Vector2(-4.0, 0.0),
			centro + Vector2(0.0, -altura),
			centro + Vector2(4.0, 0.0),
		])
		draw_colored_polygon(llama, Color(1.0, 0.38 + proporcion * 0.25, 0.04, opacidad * 0.85))
		draw_circle(
			centro + Vector2(0.0, -altura * 0.25),
			2.0 * pulso,
			Color(1.0, 0.87, 0.34, opacidad)
		)
