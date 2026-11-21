extends ShapeCast2D
const BLANCO = preload("res://Scripts/Tanques/BlancoProyectil.gd")

var excepciones_listas := false

static func crear(proyectil: Area2D) -> ShapeCast2D:
	var barrido := new()
	var visual := proyectil.get_node("Visual") as Polygon2D
	var cuerpo := ConvexPolygonShape2D.new()
	cuerpo.points = visual.transform * visual.polygon
	barrido.shape = cuerpo
	barrido.enabled = false
	barrido.collision_mask = proyectil.collision_mask | BLANCO.CAPA
	barrido.collide_with_areas = true
	barrido.max_results = 1
	proyectil.add_child(barrido)
	barrido.visible = OS.get_cmdline_user_args().has("impactos-debug")
	return barrido

func contacto(desde: Vector2, hasta: Vector2, emisor: Node2D) -> Dictionary:
	global_position = desde
	target_position = to_local(hasta)
	if not excepciones_listas:
		excepciones_listas = true
		clear_exceptions()
		for tanque in get_tree().get_nodes_in_group("tanques"):
			add_exception(tanque)
			if tanque == emisor or tanque._destruido:
				for blanco in tanque.find_children("*", "Area2D", true, false):
					if blanco is BLANCO:
						add_exception(blanco)
	force_shapecast_update()
	if not is_colliding():
		return {}
	var objeto = get_collider(0)
	return {"collider": objeto.tanque if objeto is BLANCO else objeto, "position": get_collision_point(0), "normal": get_collision_normal(0)}

func _draw() -> void:
	var borde: PackedVector2Array = shape.points.duplicate()
	borde.append(borde[0])
	draw_polyline(borde, Color.CYAN, 1.0, true)

