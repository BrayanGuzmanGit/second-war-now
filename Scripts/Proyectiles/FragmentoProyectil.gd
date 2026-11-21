extends Area2D
class_name FragmentoProyectil

signal observado(punto: Vector2, cuerpo: Node2D)
signal finalizado

@export var dano: float = 10.0
@export var vida_en_segundos: float = 2.0

var barrido: ShapeCast2D
var normal_contacto := Vector2.UP
var velocidad: Vector2
var emisor: Node2D
var terreno: Node2D
var _tiempo_vuelo := 0.0
var _finalizado := false


func _ready() -> void:
	add_to_group("fragmentos")
	monitoring = false
	barrido = preload("res://Scripts/Proyectiles/BarridoProyectil.gd").crear(self)


func configurar(origen: Vector2, nueva_velocidad: Vector2, tanque_emisor: Node2D, dano_fragmento: float) -> void:
	global_position = origen
	velocidad = nueva_velocidad
	emisor = tanque_emisor
	dano = dano_fragmento


func _physics_process(delta: float) -> void:
	if _finalizado:
		return
	_tiempo_vuelo += delta
	var posicion_anterior := global_position
	velocidad.y += GameConfig.GRAVEDAD * delta
	global_position += velocidad * delta
	if not velocidad.is_zero_approx():
		rotation = velocidad.angle()
	# Barre el movimiento completo del fragmento para no perder blancos entre frames.
	var impacto: Dictionary = barrido.contacto(posicion_anterior, global_position, emisor)
	barrido.position = Vector2.ZERO
	if not impacto.is_empty():
		normal_contacto = impacto.normal
		_resolver_impacto(impacto["collider"], impacto["position"])
		return
	if _tiempo_vuelo >= vida_en_segundos or global_position.y > 1100.0:
		observado.emit(global_position, null)
		_finalizar()


func _al_entrar_en_cuerpo(cuerpo: Node2D) -> void:
	_resolver_impacto(cuerpo, global_position)


func _resolver_impacto(cuerpo: Node2D, posicion_impacto: Vector2) -> void:
	if _finalizado or cuerpo == emisor:
		return
	# Bloquea ambas rutas de colisión antes de publicar daño o sonido.
	_finalizado = true
	observado.emit(posicion_impacto, cuerpo)
	var audio := get_node("/root/GestorAudioPartida")
	var material := CatalogoSonidos.material(cuerpo, audio.superficie)
	audio.evento("impacto", posicion_impacto, "dispersion", material)
	preload("res://Scripts/Tanques/EfectoImpactoTanque.gd").crear(self, posicion_impacto, normal_contacto, "dispersion", material)
	if cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dano)
	if is_instance_valid(terreno):
		terreno.solicitar_impacto(posicion_impacto, "dispersion", true)
	finalizado.emit()
	queue_free()


func _finalizar() -> void:
	if _finalizado:
		return
	_finalizado = true
	finalizado.emit()
	queue_free()
