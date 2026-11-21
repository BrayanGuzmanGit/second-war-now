extends Node2D
class_name EscenarioCampana

const TERRENO = preload("res://Vistas/Niveles/TerrenoDestructible.gd")
var terreno: Node2D

## El dibujo y la geometría física comparten puntos: el relieve visible es el jugable.
func configurar(datos: Dictionary, id_mision: String) -> void:
	terreno = TERRENO.new()
	terreno.name = "TerrenoDestructible"
	add_child(terreno)
	terreno.configurar(datos, id_mision)
	for ruina: Rect2 in datos["ruinas"]:
		_crear_obstaculo(PackedVector2Array([
			ruina.position, ruina.position + Vector2(ruina.size.x, 0),
			ruina.end, ruina.position + Vector2(0, ruina.size.y)
		]), Color(0.28, 0.23, 0.22))


func _crear_obstaculo(puntos: PackedVector2Array, color: Color) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.set_meta("material_audio", "escombros")
	cuerpo.add_to_group("obstaculos_campana")
	var dibujo := Polygon2D.new()
	dibujo.polygon = puntos
	dibujo.texture = preload("res://Berlin_interior.jpeg")
	dibujo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var coordenadas_uv := PackedVector2Array()
	for punto in puntos:
		coordenadas_uv.append(punto * 6.0)
	dibujo.uv = coordenadas_uv
	dibujo.color = Color(0.84, 0.82, 0.80)
	cuerpo.add_child(dibujo)
	var borde := Line2D.new()
	borde.points = puntos
	borde.closed = true
	borde.width = 1.0
	borde.default_color = color.darkened(0.15)
	cuerpo.add_child(borde)
	var colision := CollisionPolygon2D.new()
	colision.polygon = puntos
	cuerpo.add_child(colision)
	add_child(cuerpo)
