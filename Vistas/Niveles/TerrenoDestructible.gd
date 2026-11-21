extends Node2D
class_name TerrenoDestructible

signal terreno_actualizado
signal deformacion_finalizada(id: int)

const PERFIL = preload("res://Modelos/PerfilTerreno.gd")
const SOMBREADOR = preload("res://Vistas/Niveles/terreno_texturizado.gdshader")
const ANCHO_BLOQUE := 128
const IMAGENES := {
	"francia": [preload("res://francia interior.jpeg"), preload("res://francia_superficie.jpeg")],
	"alamein": [preload("res://alamein_interior.jpeg"), preload("res://Alamein_superficie.jpeg")],
	"berlin": [preload("res://Berlin_interior.jpeg"), preload("res://Berlin_superficie.jpeg")],
}
static var _bordes_por_mision: Dictionary = {}

var perfil := PERFIL.new()
var version := 0
var actualizacion_pendiente := false
var _bloques: Array[Dictionary] = []
var _sucios: Dictionary = {}
var _operaciones: Dictionary = {}
var _finalizadas: Array[int] = []
var _siguiente_id := 1
var _textura_perfiles: ImageTexture
var _material: ShaderMaterial


func configurar(datos: Dictionary, id_mision: String) -> void:
	add_to_group("terreno_destructible")
	var futuras: Array = datos["posiciones"].slice(1)
	perfil.configurar(datos["terreno"], futuras)
	_preparar_material(id_mision)
	for x in range(0, 1800, ANCHO_BLOQUE):
		var cuerpo := StaticBody2D.new()
		cuerpo.set_meta("material_audio", CatalogoSonidos.superficie(id_mision))
		cuerpo.name = "Bloque_%04d" % x
		cuerpo.add_to_group("obstaculos_campana")
		cuerpo.add_to_group("suelo_destructible")
		var colision := CollisionPolygon2D.new()
		cuerpo.add_child(colision)
		var fondo := Polygon2D.new()
		fondo.material = _material.duplicate()
		(fondo.material as ShaderMaterial).set_shader_parameter("pared_interior", true)
		fondo.polygon = _poligono(x, mini(x + ANCHO_BLOQUE, 1800), perfil.inicial)
		add_child(fondo)
		var dibujo := Polygon2D.new()
		dibujo.material = _material
		# El shader controla el color; la banda AA automática introduce un halo claro.
		dibujo.antialiased = false
		add_child(dibujo)
		add_child(cuerpo)
		_bloques.append({"inicio": x, "fin": mini(x + ANCHO_BLOQUE, 1800), "colision": colision, "dibujo": dibujo})
		_sucios[_bloques.size() - 1] = true
	_publicar()


func _preparar_material(id_mision: String) -> void:
	_material = ShaderMaterial.new()
	_material.shader = SOMBREADOR
	_material.set_shader_parameter("interior", IMAGENES[id_mision][0])
	_material.set_shader_parameter("superficie", IMAGENES[id_mision][1])
	if id_mision == "francia":
		# El archivo original contiene blanco y césped arriba. La región inferior es tierra limpia.
		_material.set_shader_parameter("region_interior", Vector4(0.0, 0.55, 1.0, 0.44))
	_material.set_shader_parameter("tinte", Color(0.94, 0.96, 0.94) if id_mision == "berlin" else Color.WHITE)
	_material.set_shader_parameter("alto_superficie", float(IMAGENES[id_mision][1].get_height()))
	if not _bordes_por_mision.has(id_mision):
		_bordes_por_mision[id_mision] = _medir_bordes(IMAGENES[id_mision][1])
	_material.set_shader_parameter("bordes", _bordes_por_mision[id_mision])
	_textura_perfiles = ImageTexture.create_from_image(_imagen_perfil())
	_material.set_shader_parameter("perfiles", _textura_perfiles)


func _medir_bordes(textura: Texture2D) -> ImageTexture:
	var imagen := textura.get_image()
	# Una textura numérica de una fila describe dónde empieza el material en cada columna.
	# No edita la imagen: el shader usa este mapa para saltarse el falso fondo transparente.
	var bordes := Image.create(1024, 1, false, Image.FORMAT_RF)
	for i in range(1024):
		var x := int(float(i) * (imagen.get_width() - 1) / 1023.0)
		var y_borde := 0
		for y in range(int(imagen.get_height() * 0.75)):
			# Buscar el ÚLTIMO fondo claro evita elegir una brizna aislada con damero debajo.
			for desplazamiento in [-6, 0, 6]:
				var color := imagen.get_pixel(clampi(x + desplazamiento, 0, imagen.get_width() - 1), y)
				if minf(color.r, minf(color.g, color.b)) > 0.72:
					y_borde = y + 12
		bordes.set_pixel(i, 0, Color(float(y_borde) / imagen.get_height(), 0, 0))
	return ImageTexture.create_from_image(bordes)


func _imagen_perfil() -> Image:
	var imagen := Image.create(perfil.alturas.size(), 1, false, Image.FORMAT_RGF)
	for i in range(perfil.alturas.size()):
		imagen.set_pixel(i, 0, Color(perfil.alturas[i] / 1100.0, perfil.inicial[i] / 1100.0, 0.0))
	return imagen


func _poligono(inicio: int, fin: int, alturas: PackedFloat32Array) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for x in range(inicio, fin + 1, 4):
		puntos.append(Vector2(x, alturas[x / 4]))
	puntos.append(Vector2(fin, PERFIL.BASE))
	puntos.append(Vector2(inicio, PERFIL.BASE))
	return puntos


func obtener_altura(x: float) -> float:
	return perfil.obtener_altura(x)


func solicitar_impacto(posicion: Vector2, tipo: String, es_fragmento: bool = false) -> void:
	var objetivo := perfil.calcular_objetivo(posicion, tipo, es_fragmento)
	_marcar_region(perfil.aplicar_objetivo(perfil.alturas.duplicate(), objetivo, 1.0))


func iniciar_deformacion_progresiva(posicion: Vector2, tipo: String, _duracion: float = 0.9) -> int:
	var id := _siguiente_id
	_siguiente_id += 1
	_operaciones[id] = {"desde": perfil.alturas.duplicate(), "objetivo": perfil.calcular_objetivo(posicion, tipo)}
	return id


func actualizar_deformacion(id: int, progreso: float) -> void:
	if not _operaciones.has(id):
		return
	var operacion: Dictionary = _operaciones[id]
	_marcar_region(perfil.aplicar_objetivo(operacion["desde"], operacion["objetivo"], progreso))
	if progreso >= 1.0:
		_operaciones.erase(id)
		_finalizadas.append(id)
		_programar_publicacion()


func hay_deformaciones() -> bool:
	return actualizacion_pendiente or not _operaciones.is_empty()


func _marcar_region(region: Vector2i) -> void:
	if region.y < region.x:
		return
	for i in range(_bloques.size()):
		if _bloques[i]["fin"] >= region.x * 4 and _bloques[i]["inicio"] <= region.y * 4:
			_sucios[i] = true
	_programar_publicacion()


func _programar_publicacion() -> void:
	if actualizacion_pendiente:
		return
	actualizacion_pendiente = true
	call_deferred("_publicar")


func _publicar() -> void:
	# Dibujo y colisión se publican en el mismo punto seguro, fuera de señales físicas.
	for i in _sucios:
		var bloque: Dictionary = _bloques[i]
		var puntos := _poligono(bloque["inicio"], bloque["fin"], perfil.alturas)
		bloque["colision"].polygon = puntos
		bloque["dibujo"].polygon = puntos
	_textura_perfiles.update(_imagen_perfil())
	_sucios.clear()
	actualizacion_pendiente = false
	version += 1
	terreno_actualizado.emit()
	for id in _finalizadas:
		deformacion_finalizada.emit(id)
	_finalizadas.clear()
