extends CharacterBody2D
class_name Tanque

const ESCENA_EXPLOSION: PackedScene = preload("res://Vistas/Efectos/ExplosionTanque.tscn")
const ESCENA_IMPACTO: PackedScene = preload("res://Vistas/Efectos/ImpactoTanque.tscn")
const TEXTURA_REFERENCIA_HITBOX: Texture2D = preload("res://Imagenes/TanqueM4Sherman.png")
const UMBRAL_OPACIDAD_HITBOX := 0.15
const SIMPLIFICACION_HITBOX_PIXELES := 2.0
const AREA_MINIMA_POLIGONO_PIXELES := 12.0

signal vida_actualizada(actual: float, maxima: float)
signal tanque_destruido

@export var vida_maxima: float = 100.0
@export var limite_izquierdo_mapa: float = 120.0
@export var limite_derecho_mapa: float = 1680.0

@onready var forma_colision: CollisionShape2D = $CollisionShape2D
@onready var sprite_tanque: Sprite2D = $Visuales/Sprite2D
@onready var visual_tanque: VisualTanque = $Visuales

var vida_actual: float
var _destruido := false
var _colisiones_silueta: Array[CollisionPolygon2D] = []


func _ready() -> void:
	# El suelo deformable necesita adherencia al bajar y pendientes algo mayores que su límite de 32°.
	floor_snap_length = 16.0
	floor_max_angle = deg_to_rad(40.0)
	floor_constant_speed = true
	_ajustar_hitbox_al_sprite()
	add_to_group("tanques")
	vida_actual = vida_maxima
	vida_actualizada.emit(vida_actual, vida_maxima)


func _ajustar_hitbox_al_sprite() -> void:
	# Crea colisionadores desde la silueta alfa para no tratar como tanque los huecos transparentes.
	if sprite_tanque.texture == null:
		push_error("El tanque %s no tiene textura para calibrar su hitbox." % name)
		return
	if not forma_colision.shape is RectangleShape2D:
		push_error("La forma de referencia del tanque %s debe usar RectangleShape2D." % name)
		return

	# La colisión conserva el arte completo aunque la capa visible del casco no incluya el cañón.
	var imagen := TEXTURA_REFERENCIA_HITBOX.get_image()
	var limites_visibles := imagen.get_used_rect()
	if limites_visibles.size == Vector2i.ZERO:
		push_error("La textura del tanque %s no contiene píxeles visibles." % name)
		return

	# Conserva la caja envolvente como referencia para apuntado/objetivos, no como colisión física.
	var rectangulo := forma_colision.shape as RectangleShape2D
	rectangulo = rectangulo.duplicate() as RectangleShape2D
	forma_colision.shape = rectangulo
	forma_colision.disabled = true
	var escala := sprite_tanque.scale.abs()
	rectangulo.size = Vector2(limites_visibles.size) * escala

	var centro_imagen := Vector2.ZERO
	if sprite_tanque.centered:
		centro_imagen = Vector2(imagen.get_size()) * 0.5
	var centro_pixeles := (
		Vector2(limites_visibles.position)
		+ Vector2(limites_visibles.size) * 0.5
		- centro_imagen
	)
	if sprite_tanque.flip_h:
		centro_pixeles.x *= -1.0
	if sprite_tanque.flip_v:
		centro_pixeles.y *= -1.0
	forma_colision.position = (
		sprite_tanque.position
		+ sprite_tanque.offset
		+ centro_pixeles * sprite_tanque.scale
	)

	var mascara := BitMap.new()
	mascara.create_from_image_alpha(imagen, UMBRAL_OPACIDAD_HITBOX)
	var poligonos := mascara.opaque_to_polygons(
		limites_visibles,
		SIMPLIFICACION_HITBOX_PIXELES
	)
	var indice_poligono := 0
	for poligono: PackedVector2Array in poligonos:
		if absf(_calcular_area_poligono(poligono)) < AREA_MINIMA_POLIGONO_PIXELES:
			continue
		var colision := CollisionPolygon2D.new()
		colision.name = "HitboxSilueta_%02d" % indice_poligono
		colision.polygon = _transformar_puntos_de_silueta(
			poligono,
			imagen.get_size(),
			limites_visibles.position
		)
		add_child(colision)
		_colisiones_silueta.append(colision)
		indice_poligono += 1

	if indice_poligono == 0:
		push_error("No se pudieron generar polígonos de colisión para el tanque %s." % name)


func _calcular_area_poligono(puntos: PackedVector2Array) -> float:
	# Fórmula del cordón: el resultado queda en píxeles cuadrados de la textura.
	var area_doble := 0.0
	for indice in range(puntos.size()):
		var siguiente := (indice + 1) % puntos.size()
		area_doble += puntos[indice].x * puntos[siguiente].y
		area_doble -= puntos[siguiente].x * puntos[indice].y
	return area_doble * 0.5


func _transformar_puntos_de_silueta(
	puntos_textura: PackedVector2Array,
	tamano_textura: Vector2i,
	origen_textura: Vector2i = Vector2i.ZERO
) -> PackedVector2Array:
	# Traduce el contorno al espacio local del tanque y conserva el volteo/escala visual del sprite.
	var centro_textura := Vector2(tamano_textura) * 0.5 if sprite_tanque.centered else Vector2.ZERO
	var puntos_locales := PackedVector2Array()
	for punto in puntos_textura:
		var desplazamiento := punto + Vector2(origen_textura) - centro_textura
		if sprite_tanque.flip_h:
			desplazamiento.x *= -1.0
		if sprite_tanque.flip_v:
			desplazamiento.y *= -1.0
		puntos_locales.append(
			sprite_tanque.position
			+ sprite_tanque.offset
			+ desplazamiento * sprite_tanque.scale
		)
	return puntos_locales


func recibir_dano(cantidad: float) -> void:
	if _destruido or cantidad <= 0.0:
		return

	vida_actual = maxf(vida_actual - cantidad, 0.0)
	vida_actualizada.emit(vida_actual, vida_maxima)
	if is_zero_approx(vida_actual):
		_destruido = true
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		for colision in find_children("*", "CollisionShape2D", true, false):
			colision.set_deferred("disabled", true)
		_iniciar_animacion_destruccion()
		tanque_destruido.emit()


func recibir_impacto_proyectil(
	cantidad: float,
	posicion_global: Vector2,
	direccion_impacto: Vector2,
	tipo_proyectil: String = "estandar"
) -> void:
	# Centraliza el VFX y el daño directo sin permitir que el efecto visual aplique salud por su cuenta.
	if _destruido or cantidad <= 0.0:
		return

	_mostrar_efecto_impacto(posicion_global, direccion_impacto, tipo_proyectil)
	recibir_dano(cantidad)


func _mostrar_efecto_impacto(
	posicion_global: Vector2,
	direccion_impacto: Vector2,
	tipo_proyectil: String
) -> void:
	var efecto := ESCENA_IMPACTO.instantiate() as EfectoImpactoTanque
	efecto.direccion_impacto = direccion_impacto
	efecto.tipo_proyectil = tipo_proyectil
	efecto.add_to_group("efectos_impacto")
	get_tree().current_scene.add_child(efecto)
	efecto.global_position = posicion_global


func _iniciar_animacion_destruccion() -> void:
	get_node("/root/GestorAudioPartida").detener_unidad(self)
	get_node("/root/GestorAudioPartida").evento("destruccion", global_position)
	# Detiene la física de la unidad, pero deja el nodo para mostrar el vehículo destruido.
	if visual_tanque.rodaje != null:
		visual_tanque.rodaje.detener()
	set_physics_process(false)
	velocity = Vector2.ZERO
	for poligono in find_children("*", "CollisionPolygon2D", true, false):
		poligono.set_deferred("disabled", true)

	var explosion := ESCENA_EXPLOSION.instantiate() as EfectoExplosionTanque
	explosion.color_explosion = Color(1.0, 0.48, 0.16) if name == "Enemigo" else Color(1.0, 0.78, 0.32)
	get_parent().add_child(explosion)
	explosion.global_position = forma_colision.global_position

	# La animación es visual y no espera: la señal de destrucción libera inmediatamente el flujo del combate.
	var destello := Color(1.0, 0.8, 0.52, 1.0)
	var resto := Color(0.28, 0.25, 0.22, 0.78)
	var animacion_color := create_tween()
	animacion_color.tween_property(visual_tanque, "self_modulate", destello, 0.07)
	animacion_color.tween_property(visual_tanque, "self_modulate", resto, 0.32).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)

	var inclinacion := -11.0 if sprite_tanque.flip_h else 11.0
	var animacion_caida := create_tween().set_parallel(true)
	animacion_caida.tween_property(visual_tanque, "rotation_degrees", inclinacion, 0.38).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	animacion_caida.tween_property(
		visual_tanque,
		"position:y",
		visual_tanque.position.y + 13.0,
		0.38
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion_caida.tween_property(
		visual_tanque,
		"scale:y",
		visual_tanque.scale.y * 0.82,
		0.38
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func obtener_punto_impacto_global() -> Vector2:
	return forma_colision.global_position


func obtener_punto_frontal_global() -> Vector2:
	# Usa el borde delantero de la colisión para que alcanzar una bandera no dependa del centro del sprite.
	var ancho_colision := forma_colision.shape.get_rect().size.x
	var semiancho_global := ancho_colision * absf(forma_colision.global_scale.x) * 0.5
	return forma_colision.global_position + Vector2(semiancho_global, 0.0)


func limitar_movimiento_al_mapa() -> void:
	var posicion := global_position
	posicion.x = clampf(posicion.x, limite_izquierdo_mapa, limite_derecho_mapa)
	global_position = posicion
