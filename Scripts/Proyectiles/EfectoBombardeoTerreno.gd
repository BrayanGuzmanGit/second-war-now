extends Node2D

## El proyectil proporciona el progreso: no hay otro reloj, daño ni física en este VFX.
var color_polvo := Color("#846647")
var progreso := 0.0
var origen_polvo := Vector2.ZERO


func _ready() -> void:
	add_to_group("efectos_bombardeo_terreno")
	color_polvo = {"arena": Color("#dcbc82"), "escombros": Color("#817e79")}.get(get_node("/root/GestorAudioPartida").superficie, color_polvo)


func actualizar(valor: float, suelo_local: Vector2) -> void:
	progreso = valor
	origen_polvo = suelo_local
	queue_redraw()


func _draw() -> void:
	var radio := lerpf(10.0, 150.0, progreso)
	var opacidad := sin(PI * clampf(progreso, 0.0, 1.0))
	draw_circle(origen_polvo + Vector2(0, -18), 30.0 * (1.0 - progreso), Color(1.0, 0.81, 0.44, 1.0 - progreso))
	for i in range(18):
		var lado := -1.0 if i % 2 == 0 else 1.0
		var distancia := radio * (0.3 + float(i % 5) * 0.14)
		var altura := sin(PI * progreso) * (25.0 + (i % 6) * 10.0)
		var centro := origen_polvo + Vector2(lado * distancia, -altura)
		draw_circle(centro, 9.0 + 11.0 * progreso, Color(color_polvo, opacidad * 0.40))
		var r := 2.0 + float(i % 3)
		draw_colored_polygon(PackedVector2Array([centro+Vector2(-r,-6), centro+Vector2(0,-8-r), centro+Vector2(r,-7)]), Color(color_polvo.darkened(0.3), opacidad))
