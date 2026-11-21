extends Area2D
## Contornos en coordenadas de la ilustración, compartidos entre instancias.
const CAPA := 8
static var contornos: Dictionary = {}
var tanque: Node2D

static func montar(pieza: Node2D, unidad: Node2D, clave: String, textura: Texture2D, rect: Rect2i, origen: Vector2, oruga := PackedVector2Array()) -> Area2D:
	if not contornos.has(clave):
		var imagen := textura.get_image().get_region(rect)
		var mascara := BitMap.new()
		mascara.create_from_image_alpha(imagen, 0.35)
		var formas := mascara.opaque_to_polygons(Rect2i(Vector2i.ZERO, imagen.get_size()), 1.5)
		var locales: Array[PackedVector2Array] = []
		for puntos in formas:
			if puntos.size() >= 3 and Geometry2D.triangulate_polygon(puntos).size() > 0:
				locales.append(Transform2D(0.0, origen) * puntos)
		if not oruga.is_empty():
			locales.append(oruga)
		contornos[clave] = locales
	var blanco := new()
	blanco.tanque = unidad
	blanco.collision_layer = CAPA
	blanco.collision_mask = 0
	blanco.monitoring = false
	pieza.add_child(blanco)
	for puntos: PackedVector2Array in contornos[clave]:
		var forma := CollisionPolygon2D.new()
		forma.polygon = puntos
		blanco.add_child(forma)
	blanco.visible = OS.get_cmdline_user_args().has("impactos-debug")
	return blanco

func _draw() -> void:
	for forma: CollisionPolygon2D in get_children():
		var borde := forma.polygon.duplicate()
		borde.append(borde[0])
		draw_polyline(borde, Color(0.2,1,0.8,0.9), -1, true)

