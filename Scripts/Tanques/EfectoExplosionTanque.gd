extends Node2D
class_name EfectoExplosionTanque

const DURACION := 0.55
const CANTIDAD_CHISPAS := 12

var color_explosion := Color(1.0, 0.55, 0.2)
var _tiempo := 0.0


func _process(delta: float) -> void:
	# El efecto dura poco y se actualiza visualmente sin detener el flujo del combate.
	_tiempo += delta
	queue_redraw()
	if _tiempo >= DURACION:
		queue_free()


func _draw() -> void:
	# El progreso controla la expansión y el desvanecimiento de la explosión y sus chispas.
	var progreso := clampf(_tiempo / DURACION, 0.0, 1.0)
	var opacidad := 1.0 - progreso
	var radio := lerpf(8.0, 48.0, progreso)
	var color := color_explosion
	color.a = opacidad * 0.8
	draw_circle(Vector2.ZERO, radio, color)

	var centro := Color(1.0, 0.9, 0.55, opacidad)
	draw_circle(Vector2.ZERO, lerpf(5.0, 17.0, progreso), centro)

	for indice in range(CANTIDAD_CHISPAS):
		var angulo := TAU * float(indice) / float(CANTIDAD_CHISPAS)
		var direccion := Vector2.from_angle(angulo)
		var inicio := direccion * (radio * 0.45)
		var fin := direccion * (radio + 12.0)
		var color_chispa := Color(1.0, 0.72, 0.28, opacidad)
		draw_line(inicio, fin, color_chispa, 3.0 - progreso)
