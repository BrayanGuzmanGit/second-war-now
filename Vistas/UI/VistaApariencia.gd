extends Control
class_name VistaApariencia

const CATALOGO = preload("res://Modelos/CatalogoApariencias.gd")
var id_apariencia := "TNQ-01"

func mostrar(id: String) -> void:
	id_apariencia = id
	queue_redraw()

func _draw() -> void:
	var datos: Dictionary = CATALOGO.obtener(id_apariencia)
	if datos.is_empty():
		return
	if id_apariencia == "TNQ-01":
		var textura: Texture2D = datos["miniatura"]
		var area := textura.get_image().get_used_rect()
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2(area)
		_dibujar([{"textura": atlas, "rect": Rect2(Vector2.ZERO, area.size)}])
		return
	var region: Rect2i = datos["region_casco"]
	var montura: Vector2 = datos["montura"]
	var escala := Vector2(316.0 / (montura.x - region.position.x), 179.0 / (region.end.y - montura.y))
	var casco := Rect2(Vector2(354, 110) - (montura - Vector2(region.position)) * escala, Vector2(region.size) * escala)
	_dibujar([
		{"textura": datos["casco"], "rect": casco},
		{"textura": datos["canon"], "rect": Rect2(354, 97.5, 179, 25)},
	])

func _dibujar(piezas: Array) -> void:
	var limites: Rect2 = piezas[0]["rect"]
	for pieza in piezas:
		limites = limites.merge(pieza["rect"])
	var factor := minf((size.x - 24.0) / limites.size.x, (size.y - 18.0) / limites.size.y)
	var origen := (size - limites.size * factor) * 0.5 - limites.position * factor
	for pieza in piezas:
		var rect: Rect2 = pieza["rect"]
		draw_texture_rect(pieza["textura"], Rect2(origen + rect.position * factor, rect.size * factor), false)
