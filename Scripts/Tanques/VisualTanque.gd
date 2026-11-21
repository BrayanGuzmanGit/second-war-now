extends Node2D
class_name VisualTanque

const TEXTURA_CASCO: Texture2D = preload(
	"res://Imagenes/TanqueSherman/TanqueM4Sherman_Casco.png"
)
const TEXTURA_CANON: Texture2D = preload(
	"res://Imagenes/TanqueSherman/TanqueM4Sherman_Canon.png"
)
const RODAJE = preload("res://Scripts/Tanques/VisualRodaje.gd")
var rodaje: Node2D
const BLANCO = preload("res://Scripts/Tanques/BlancoProyectil.gd")
var blanco_canon: Area2D
const CENTRO_TEXTURA := Vector2(343.0, 182.0)
const PIVOTE_CANON := Vector2(354.0, 110.0)
const BOCA_CANON := Vector2(533.0, 110.0)

@onready var sprite_casco: Sprite2D = $Sprite2D
@onready var pivote_canon: Node2D = $PivoteCanon
@onready var sprite_canon: Sprite2D = $PivoteCanon/Canon
@onready var punto_disparo: Marker2D = $PivoteCanon/PuntoDisparo

var giro_ruedas := 0.0
var id_apariencia := "TNQ-01"
var _cuerpo_alternativo: Node2D
const APARIENCIAS = preload("res://Modelos/CatalogoApariencias.gd")


func _ready() -> void:
	# Las capas visuales proceden del arte fuente y mantienen escala y tono del tanque.
	sprite_casco.texture = TEXTURA_CASCO
	sprite_canon.texture = TEXTURA_CANON
	var desplazamiento_pivote := PIVOTE_CANON - CENTRO_TEXTURA
	if sprite_casco.flip_h:
		desplazamiento_pivote.x *= -1.0
	if sprite_casco.flip_v:
		desplazamiento_pivote.y *= -1.0
	pivote_canon.position = sprite_casco.position + desplazamiento_pivote * sprite_casco.scale
	pivote_canon.scale = sprite_casco.scale
	if sprite_casco.flip_h:
		pivote_canon.scale.x *= -1.0
	if sprite_casco.flip_v:
		pivote_canon.scale.y *= -1.0
	sprite_canon.position = -(PIVOTE_CANON - CENTRO_TEXTURA)
	punto_disparo.position = BOCA_CANON - PIVOTE_CANON

	aplicar_apariencia("TNQ-01")


func apuntar_canon(direccion_global: Vector2) -> void:
	if direccion_global.is_zero_approx():
		return

	var direccion_local := global_transform.basis_xform_inv(direccion_global.normalized())
	var angulo := direccion_local.angle()
	# El volteo horizontal invierte el eje local del tubo antes de aplicar la rotación.
	if sprite_casco.flip_h:
		angulo -= PI
	pivote_canon.rotation = angulo


func actualizar_movimiento(delta: float, desplazamiento: Vector2, en_suelo: bool, normal: Vector2) -> void:
	get_node("/root/GestorAudioPartida").actualizar_tanque(get_parent(), delta, desplazamiento, en_suelo, normal)
	if rodaje != null:
		rodaje.actualizar(delta, desplazamiento, en_suelo, normal)
		giro_ruedas = rodaje.distancia / 8.0


func aplicar_tinte(color: Color) -> void:
	self_modulate = color


func aplicar_apariencia(id: String) -> void:
	get_node("/root/GestorAudioPartida").reiniciar_unidad(get_parent())
	var datos: Dictionary = APARIENCIAS.obtener(id)
	if datos.is_empty():
		return
	if is_instance_valid(blanco_canon):
		blanco_canon.free()
	if rodaje != null:
		rodaje.free()
		rodaje = null
	id_apariencia = id
	giro_ruedas = 0.0
	self_modulate = Color.WHITE
	if _cuerpo_alternativo != null:
		_cuerpo_alternativo.free()
		_cuerpo_alternativo = null
	sprite_casco.visible = id == "TNQ-01"
	if id == "TNQ-01":
		pivote_canon.z_index = 5
		sprite_canon.texture = TEXTURA_CANON
		sprite_canon.centered = true
		sprite_canon.scale = Vector2.ONE
		sprite_canon.position = -(PIVOTE_CANON - CENTRO_TEXTURA)
		_crear_rodaje(TEXTURA_CASCO, sprite_casco.position - CENTRO_TEXTURA * sprite_casco.scale * Vector2(-1 if sprite_casco.flip_h else 1, 1), sprite_casco.scale * Vector2(-1 if sprite_casco.flip_h else 1, 1))
		return
	# El arte se adapta a la montura común sin modificar hitbox ni marcador balístico.
	var region: Rect2i = datos["region_casco"]
	var montura: Vector2 = datos["montura"]
	var escala_arte := Vector2(
		(PIVOTE_CANON.x - 38.0) / (montura.x - region.position.x),
		(289.0 - PIVOTE_CANON.y) / (region.end.y - montura.y)
	)
	_cuerpo_alternativo = Node2D.new()
	_cuerpo_alternativo.position = pivote_canon.position
	var escala_fija := sprite_casco.scale * Vector2(-1 if sprite_casco.flip_h else 1, 1)
	_cuerpo_alternativo.scale = escala_fija
	add_child(_cuerpo_alternativo)
	var cuerpo := Sprite2D.new()
	cuerpo.texture = datos["casco"]
	cuerpo.centered = false
	cuerpo.scale = escala_arte
	cuerpo.position = -(montura - Vector2(region.position)) * escala_arte
	_cuerpo_alternativo.add_child(cuerpo)
	sprite_canon.texture = datos["canon"]
	sprite_canon.centered = false
	var tamano: Vector2 = sprite_canon.texture.get_size()
	sprite_canon.scale = Vector2((BOCA_CANON.x - PIVOTE_CANON.x) / tamano.x, 25.0 / tamano.y)
	sprite_canon.position = Vector2(0, -12.5)
	pivote_canon.z_index = 5
	_crear_rodaje(datos["casco"].atlas, pivote_canon.position - montura * escala_arte * escala_fija, escala_arte * escala_fija)
	cuerpo.hide()
	
func _crear_rodaje(textura: Texture2D, origen: Vector2, escala: Vector2) -> void:
	sprite_casco.hide()
	rodaje = RODAJE.new()
	rodaje.position = origen
	rodaje.scale = escala
	add_child(rodaje)
	rodaje.configurar(textura, preload("res://Modelos/DatosRodaje.gd").obtener(id_apariencia))
	var datos := preload("res://Modelos/DatosRodaje.gd").obtener(id_apariencia)
	var region := Rect2i(0, 0, textura.get_width(), ceili(datos.corte))
	var bordes := Geometry2D.offset_polygon(rodaje.ruta, float(datos.eslabon.size.y) * 0.5)
	var exterior: PackedVector2Array = rodaje.ruta if bordes.is_empty() else bordes[0]
	BLANCO.montar(rodaje, get_parent(), id_apariencia + "_casco", textura, region, Vector2.ZERO, exterior)
	var tubo := sprite_canon.texture
	blanco_canon = BLANCO.montar(sprite_canon, get_parent(), id_apariencia + "_canon", tubo, Rect2i(Vector2i.ZERO, Vector2i(tubo.get_size())), sprite_canon.get_rect().position)

