extends Node2D
class_name EfectoSalidaProyectil

const DURACION := 0.42

var tipo_proyectil := "estandar"
var _tiempo := 0.0


func _process(delta: float) -> void:
	# El fogonazo es independiente de la trayectoria física y desaparece sin bloquear el turno.
	_tiempo += delta
	queue_redraw()
	if _tiempo >= DURACION:
		queue_free()


func _draw() -> void:
	var fase := clampf(_tiempo / DURACION, 0.0, 1.0)
	var peso := 1.4 if tipo_proyectil == "pesado" else 0.85
	for i in 6:
		var centro := Vector2(3 + fase*(10+i*3.5), sin(i*3.7)*(2+fase*6))
		centro += Vector2.UP.rotated(-global_rotation)*fase*10
		draw_circle(centro, (1.4+fase*(5+i))*peso, Color(0.51,0.47,0.42,(1-fase)*0.23),true,-1,true)
	var progreso := clampf(_tiempo / 0.095, 0.0, 1.0)
	if progreso >= 1.0:
		return
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(7,-4)*peso,Vector2(26,0)*peso,Vector2(8,3)*peso]), Color(1,0.95,0.78,1-progreso))
	var opacidad := 1.0 - progreso
	var pulso := 1.0 - progreso * 0.45
	match tipo_proyectil:
		"estandar":
			draw_colored_polygon(
				PackedVector2Array([Vector2(-2, -4), Vector2(17, 0), Vector2(-2, 4)]),
				Color(1.0, 0.88, 0.53, opacidad)
			)
			draw_line(Vector2.ZERO, Vector2(23.0, 0.0), Color(1.0, 1.0, 0.85, opacidad), 2.0)
		"pesado":
			draw_circle(Vector2(5.0, 0.0), 11.0 * pulso, Color(1.0, 0.4, 0.17, opacidad))
			draw_circle(Vector2(8.0, 0.0), 6.0 * pulso, Color(1.0, 0.86, 0.48, opacidad))
			for indice in range(6):
				var vector := Vector2.RIGHT.rotated(TAU * float(indice) / 6.0)
				draw_line(vector * 8.0, vector * 18.0 * pulso, Color(0.8, 0.65, 0.48, opacidad), 2.0)
		"dispersion":
			draw_arc(Vector2(5.0, 0.0), 9.0 * pulso, -1.0, 1.0, 12, Color(1.0, 0.85, 0.42, opacidad), 2.0)
			for indice in range(5):
				var vector := Vector2.RIGHT.rotated(-0.7 + float(indice) * 0.35)
				draw_circle(vector * 15.0 * pulso, 2.2, Color(1.0, 0.94, 0.64, opacidad))
		"bombardeo":
			draw_colored_polygon(
				PackedVector2Array([Vector2(-3, -5), Vector2(8, 0), Vector2(-3, 5), Vector2(2, 0)]),
				Color(1.0, 0.46, 0.16, opacidad)
			)
			for indice in range(8):
				var vector := Vector2.RIGHT.rotated(TAU * float(indice) / 8.0)
				draw_line(vector * 9.0, vector * 19.0 * pulso, Color(1.0, 0.84, 0.4, opacidad), 1.5)
		"incendiario":
			for indice in range(6):
				var x := float(indice) * 4.0
				var altura := (7.0 - indice * 0.7) * pulso
				draw_colored_polygon(
					PackedVector2Array([
						Vector2(x, -altura * 0.5),
						Vector2(x + 13.0 * pulso, 0.0),
						Vector2(x, altura * 0.5),
					]),
					Color(1.0, 0.26 + indice * 0.1, 0.04, opacidad * (1.0 - indice * 0.1))
				)
