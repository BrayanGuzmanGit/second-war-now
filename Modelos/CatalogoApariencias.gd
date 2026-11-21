extends RefCounted
class_name CatalogoApariencias

## Atlas preparados desde el arte del usuario. ENM-01 nunca pertenece al inventario.
const DATOS := {
	"TNQ-01": {"historia": "El Sherman entró en combate con el ejército británico en El Alamein, en octubre de 1942. Era un tanque estadounidense en manos de un aliado.", "nombre": "M4 Sherman", "bando": "Estados Unidos", "uso": "jugador"},
	"TNQ-02": {"historia": "En 1944, los Cromwell encabezaron el avance aliado hacia Bruselas y Amberes. Su velocidad los hacía especialmente útiles para el reconocimiento.", "nombre": "Cromwell Mk VIII", "bando": "Gran Bretaña", "uso": "jugador", "montura": Vector2(862, 305)},
	"TNQ-03": {"historia": "La torreta del T-34-85 soviético tenía espacio para tres tripulantes. El comandante podía dirigir el tanque mientras sus compañeros atendían el cañón.", "nombre": "T-34-85", "bando": "Unión Soviética", "uso": "jugador", "montura": Vector2(980, 290)},
	"TNQ-04": {"historia": "El Churchill británico acompañaba a la infantería a pie. Su grueso blindaje respondía a la necesidad de avanzar junto a los soldados bajo fuego.", "nombre": "Churchill Mk IV", "bando": "Gran Bretaña", "uso": "jugador", "montura": Vector2(885, 290)},
	"TNQ-06": {"historia": "El Ejército Rojo desarrolló el KV-2 durante la guerra con Finlandia para atacar las fortificaciones de la línea Mannerheim.", "nombre": "KV-2", "bando": "Unión Soviética", "uso": "jugador", "montura": Vector2(920, 270)},
	"ENM-01": {"nombre": "Pz.Kpfw. VI", "bando": "Alemania", "uso": "enemigo", "montura": Vector2(855, 295)},
}
static var _cache: Dictionary = {}


static func obtener(id: String) -> Dictionary:
	if not DATOS.has(id):
		return {}
	if _cache.has(id):
		return _cache[id]
	var datos: Dictionary = DATOS[id].duplicate(true)
	datos["id"] = id
	datos["rodaje"] = preload("res://Modelos/DatosRodaje.gd").obtener(id)
	if id != "TNQ-01":
		var atlas := load("res://Imagenes/Apariencias/%s.png" % id) as Texture2D
		if atlas == null:
			push_error("Falta el atlas de apariencia: " + id)
			return {}
		var imagen := atlas.get_image()
		# Separación por regiones de un atlas; no se alteran los PNG originales.
		var corte := roundi(imagen.get_height() * 0.66)
		var casco := _limites_opacos(imagen, Rect2i(0, 0, imagen.get_width(), corte))
		var canon := _limites_opacos(imagen, Rect2i(0, corte, imagen.get_width(), imagen.get_height() - corte))
		datos["casco"] = _region(atlas, casco)
		datos["canon"] = _region(atlas, canon)
		datos["region_casco"] = casco
		datos["region_canon"] = canon
	else:
		datos["miniatura"] = load("res://Imagenes/TanqueM4Sherman.png")
	_cache[id] = datos
	return datos


static func _region(textura: Texture2D, region: Rect2i) -> AtlasTexture:
	var resultado := AtlasTexture.new()
	resultado.atlas = textura
	resultado.region = Rect2(region)
	resultado.filter_clip = true
	return resultado


static func _limites_opacos(imagen: Image, region: Rect2i) -> Rect2i:
	# El generador deja píxeles con alfa residual fuera de los sprites.
	# Se ignoran al calcular el encuadre, sin alterar la imagen ni su transparencia.
	var minimo := region.end
	var maximo := region.position
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if imagen.get_pixel(x, y).a > 0.25:
				minimo.x = mini(minimo.x, x)
				minimo.y = mini(minimo.y, y)
				maximo.x = maxi(maximo.x, x)
				maximo.y = maxi(maximo.y, y)
	return Rect2i(minimo, maximo - minimo + Vector2i.ONE)
