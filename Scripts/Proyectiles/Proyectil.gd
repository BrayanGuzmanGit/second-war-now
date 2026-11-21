extends Area2D
class_name Proyectil

const ESCENA_FRAGMENTO: PackedScene = preload("res://Vistas/Proyectiles/FragmentoProyectil.tscn")
const ESCENA_ZONA_INCENDIADA: PackedScene = preload(
	"res://Vistas/Proyectiles/EfectoZonaIncendiada.tscn"
)
const EFECTO_BOMBARDEO = preload("res://Scripts/Proyectiles/EfectoBombardeoTerreno.gd")
const DURACION_EXCAVACION_BOMBARDEO := 0.9

signal finalizado

@export var dano_base: float = 25.0
@export var radio_explosion: float = 35.0
@export var multiplicador_potencia: float = 1.0
@export var demora_bombardeo: float = 0.0
@export var dano_por_tick: float = 0.0
@export var cantidad_ticks: int = 0
@export var cantidad_fragmentos: int = 0
@export var demora_division: float = 0.45
@export_enum("estandar", "pesado", "dispersion", "bombardeo", "incendiario")
var tipo_visual := "estandar"

var barrido: ShapeCast2D
var normal_contacto := Vector2.UP
var velocidad: Vector2
var emisor: Node2D
var terreno: Node2D
var _finalizado := false
var _impactado := false
var _tiempo_vuelo := 0.0
var _tiempo_visual := 0.0
var _esperando_bombardeo := false
var _fragmentos_pendientes := 0


func _ready() -> void:
	monitoring = false
	_configurar_visual()
	barrido = preload("res://Scripts/Proyectiles/BarridoProyectil.gd").crear(self)


func configurar(nueva_velocidad: Vector2, tanque_emisor: Node2D, dano: float = -1.0) -> void:
	velocidad = nueva_velocidad * multiplicador_potencia
	emisor = tanque_emisor
	rotation = velocidad.angle()
	if dano > 0.0:
		dano_base = dano


func _process(delta: float) -> void:
	# El rastro solo anima presentación; el movimiento y las colisiones siguen en física.
	_tiempo_visual += delta
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _finalizado:
		return
	_tiempo_vuelo += delta
	var aceleracion := Vector2(0.0, GameConfig.GRAVEDAD)
	# Consulta el segmento completo de este paso para evitar que un proyectil rápido atraviese la hitbox entre frames.
	var posicion_anterior := global_position
	global_position += velocidad * delta + aceleracion * 0.5 * delta * delta
	velocidad += aceleracion * delta
	if not velocidad.is_zero_approx():
		rotation = velocidad.angle()
	var impacto: Dictionary = barrido.contacto(posicion_anterior, global_position, emisor)
	barrido.position = Vector2.ZERO
	if not impacto.is_empty():
		normal_contacto = impacto.normal
		_resolver_impacto(impacto["collider"], impacto["position"])
		return
	if cantidad_fragmentos > 0 and _tiempo_vuelo >= demora_division:
		_dividirse()
		return
	if global_position.x < -100.0 or global_position.x > 1900.0 or global_position.y > 1100.0 or _tiempo_vuelo > 12.0:
		_finalizar()


func _configurar_visual() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual == null:
		push_error("La escena de proyectil %s necesita un nodo Polygon2D llamado Visual." % name)
		return

	match tipo_visual:
		"estandar":
			visual.polygon = PackedVector2Array([
				Vector2(-11, -3), Vector2(5, -3), Vector2(11, 0), Vector2(5, 3), Vector2(-11, 3)
			])
			visual.color = Color(1.0, 0.83, 0.3)
		"pesado":
			visual.polygon = PackedVector2Array([
				Vector2(-10, -6), Vector2(5, -6), Vector2(11, 0), Vector2(5, 6), Vector2(-10, 6)
			])
			visual.color = Color(0.9, 0.43, 0.25)
		"dispersion":
			visual.polygon = PackedVector2Array([
				Vector2(-9, -5), Vector2(3, -5), Vector2(9, 0), Vector2(3, 5), Vector2(-9, 5)
			])
			visual.color = Color(0.94, 0.79, 0.36)
		"bombardeo":
			visual.polygon = PackedVector2Array([
				Vector2(-5, -5),
				Vector2(3, -5),
				Vector2(8, 0),
				Vector2(3, 5),
				Vector2(-5, 5),
				Vector2(-9, 0),
			])
			visual.color = Color(1.0, 0.53, 0.2)
		"incendiario":
			visual.polygon = PackedVector2Array([
				Vector2(-9, -4), Vector2(3, -4), Vector2(10, 0), Vector2(3, 4), Vector2(-9, 4)
			])
			visual.color = Color(1.0, 0.33, 0.12)
		_:
			push_error("Tipo visual de proyectil desconocido: %s." % tipo_visual)


func _draw() -> void:
	if _esperando_bombardeo:
		var pulso_bengala := 0.75 + 0.25 * sin(_tiempo_visual * 14.0)
		draw_circle(Vector2.ZERO, 7.0 * pulso_bengala, Color(1.0, 0.76, 0.32, 0.9))
		draw_arc(
			Vector2.ZERO,
			lerpf(16.0, radio_explosion, fposmod(_tiempo_visual * 0.8, 1.0)),
			0.0,
			TAU,
			28,
			Color(1.0, 0.38, 0.12, 0.78),
			2.5
		)
		draw_arc(
			Vector2.ZERO,
			lerpf(radio_explosion * 0.35, radio_explosion * 0.75, fposmod(_tiempo_visual * 0.8 + 0.5, 1.0)),
			0.0,
			TAU,
			24,
			Color(1.0, 0.82, 0.42, 0.58),
			1.5
		)
		return
	if velocidad.is_zero_approx():
		return

	var pulso := 0.65 + 0.35 * sin(_tiempo_visual * 28.0)
	match tipo_visual:
		"estandar":
			draw_line(Vector2(-8.0, 0.0), Vector2(-32.0, 0.0), Color(1.0, 0.9, 0.58, 0.72), 2.0)
			draw_line(Vector2(-12.0, -2.0), Vector2(-25.0, -2.0), Color(1.0, 1.0, 0.86, 0.55), 1.0)
		"pesado":
			draw_line(Vector2(-8.0, 0.0), Vector2(-35.0, 0.0), Color(0.47, 0.34, 0.29, 0.66), 7.0)
			draw_circle(Vector2(-24.0, 0.0), 4.0 * pulso, Color(1.0, 0.43, 0.2, 0.55))
		"dispersion":
			for indice in range(4):
				var x := -12.0 - float(indice) * 8.0
				draw_circle(Vector2(x, 0.0), 2.0, Color(1.0, 0.86, 0.44, 0.7 - indice * 0.12))
			draw_arc(Vector2(-16.0, 0.0), 7.0 * pulso, -0.8, 0.8, 12, Color(1.0, 0.9, 0.58, 0.55), 1.5)
		"bombardeo":
			draw_line(Vector2(-8.0, 0.0), Vector2(-28.0, 0.0), Color(1.0, 0.36, 0.12, 0.8), 3.0)
			draw_circle(Vector2(-15.0, 0.0), 5.0 * pulso, Color(1.0, 0.83, 0.42, 0.55))
			draw_arc(Vector2(-15.0, 0.0), 9.0 * pulso, 0.0, TAU, 16, Color(1.0, 0.55, 0.18, 0.6), 1.2)
		"incendiario":
			for indice in range(5):
				var x := -10.0 - float(indice) * 6.0
				var y := sin(_tiempo_visual * 24.0 + indice * 1.7) * 3.0
				draw_circle(
					Vector2(x, y),
					lerpf(4.0, 1.0, float(indice) / 5.0) * pulso,
					Color(1.0, 0.32 + indice * 0.1, 0.08, 0.72 - indice * 0.1)
				)


func _al_entrar_en_cuerpo(cuerpo: Node2D) -> void:
	_resolver_impacto(cuerpo, global_position)


func _resolver_impacto(cuerpo: Node2D, posicion_impacto: Vector2) -> void:
	if _finalizado or _impactado or cuerpo == emisor:
		return
	if cantidad_fragmentos > 0:
		global_position = posicion_impacto
		_dividirse()
		return
	_impactado = true
	set_physics_process(false)
	_impactar(cuerpo, posicion_impacto)


func _dividirse() -> void:
	if _finalizado or _impactado:
		return
	_impactado = true
	preload("res://Scripts/Tanques/EfectoImpactoTanque.gd").crear(self, global_position, Vector2.UP, "dispersion", "division")
	get_node("/root/GestorAudioPartida").evento("division", global_position)
	set_physics_process(false)
	set_deferred("monitoring", false)
	visible = false
	_fragmentos_pendientes = cantidad_fragmentos
	var angulo_central := velocidad.angle()
	for indice in range(cantidad_fragmentos):
		var proporcion := 0.0 if cantidad_fragmentos == 1 else (
			float(indice) / float(cantidad_fragmentos - 1) - 0.5
		)
		var angulo := angulo_central + deg_to_rad(proporcion * 38.0)
		var fragmento := ESCENA_FRAGMENTO.instantiate() as FragmentoProyectil
		fragmento.finalizado.connect(_al_finalizar_fragmento)
		fragmento.terreno = terreno
		fragmento.configurar(
			global_position,
			Vector2.from_angle(angulo) * velocidad.length() * 0.72,
			emisor,
			dano_base / float(cantidad_fragmentos)
		)
		get_tree().current_scene.add_child(fragmento)
	if _fragmentos_pendientes == 0:
		_finalizar()


func _al_finalizar_fragmento() -> void:
	_fragmentos_pendientes -= 1
	if _fragmentos_pendientes <= 0:
		_finalizar()


func _impactar(cuerpo: Node2D, posicion_impacto: Vector2) -> void:
	# Mantener el centro fijo también para impactos procedentes de body_entered.
	global_position = posicion_impacto
	$Visual.hide()
	velocidad = Vector2.ZERO
	set_physics_process(false)
	set_deferred("monitoring", false)
	if demora_bombardeo > 0.0:
		get_node("/root/GestorAudioPartida").evento("bengala", posicion_impacto)
		# La bengala marca el punto mientras se resuelve el retraso del bombardeo.
		_esperando_bombardeo = true
		global_position = posicion_impacto
		queue_redraw()
		await get_tree().create_timer(demora_bombardeo, false).timeout
		_esperando_bombardeo = false

	var audio := get_node("/root/GestorAudioPartida")
	var material := CatalogoSonidos.material(cuerpo, audio.superficie)
	audio.evento("impacto", posicion_impacto, tipo_visual, material)
	preload("res://Scripts/Tanques/EfectoImpactoTanque.gd").crear(self, posicion_impacto, normal_contacto, tipo_visual, material)
	if cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dano_base)
	_aplicar_dano_area(cuerpo, -1.0, posicion_impacto, false)
	if tipo_visual == "bombardeo":
		await _excavar_bombardeo(posicion_impacto)
	elif is_instance_valid(terreno):
		terreno.solicitar_impacto(posicion_impacto, tipo_visual)

	if tipo_visual == "incendiario" and cantidad_ticks > 0:
		_crear_efecto_zona_incendiada(posicion_impacto)

	for indice in range(cantidad_ticks):
		await get_tree().create_timer(0.65, false).timeout
		_aplicar_dano_area(null, dano_por_tick, Vector2.ZERO, false)
	_finalizar()


func _excavar_bombardeo(posicion_impacto: Vector2) -> void:
	var efecto := EFECTO_BOMBARDEO.new()
	get_tree().current_scene.add_child(efecto)
	efecto.global_position = posicion_impacto
	visible = false
	get_node("/root/GestorAudioPartida").bucle(efecto, "bombardeo")
	var id := -1
	if is_instance_valid(terreno):
		id = terreno.iniciar_deformacion_progresiva(posicion_impacto, "bombardeo", DURACION_EXCAVACION_BOMBARDEO)
	var tiempo := 0.0
	while tiempo < DURACION_EXCAVACION_BOMBARDEO:
		if not is_inside_tree():
			return
		await get_tree().physics_frame
		while is_inside_tree() and get_tree().paused:
			await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(efecto):
			return
		tiempo = minf(DURACION_EXCAVACION_BOMBARDEO, tiempo + get_physics_process_delta_time())
		var lineal := tiempo / DURACION_EXCAVACION_BOMBARDEO
		var progreso := lineal * lineal * (3.0 - 2.0 * lineal)
		var suelo := posicion_impacto
		if is_instance_valid(terreno):
			terreno.actualizar_deformacion(id, progreso)
			suelo.y = terreno.obtener_altura(posicion_impacto.x)
		efecto.actualizar(progreso, suelo - posicion_impacto)
	# La última geometría debe estar publicada antes de liberar la acción del proyectil.
	while is_instance_valid(terreno) and terreno.actualizacion_pendiente:
		if not is_inside_tree():
			return
		await get_tree().physics_frame
		while is_inside_tree() and get_tree().paused:
			await get_tree().process_frame
	efecto.queue_free()


func _crear_efecto_zona_incendiada(posicion_impacto: Vector2) -> void:
	# Un solo fuego visual permanece durante los ticks en vez de repetir fogonazos por daño.
	var efecto := ESCENA_ZONA_INCENDIADA.instantiate() as EfectoZonaIncendiada
	efecto.radio = radio_explosion
	efecto.duracion = 0.65 * float(cantidad_ticks)
	efecto.add_to_group("efectos_zona_incendiada")
	get_tree().current_scene.add_child(efecto)
	efecto.global_position = posicion_impacto
	get_node("/root/GestorAudioPartida").bucle(efecto, "fuego")


func _aplicar_dano_area(
	objetivo_directo: Node2D,
	dano: float = -1.0,
	posicion_impacto: Vector2 = Vector2.ZERO,
	mostrar_efecto: bool = true
) -> void:
	var dano_area := dano_base if dano <= 0.0 else dano
	for tanque in get_tree().get_nodes_in_group("tanques"):
		if tanque == emisor or tanque == objetivo_directo or not tanque.has_method("recibir_dano"):
			continue
		var objetivo := tanque as Tanque
		if objetivo == null:
			continue
		var punto_objetivo: Vector2 = objetivo.obtener_punto_impacto_global()
		var punto_explosion := posicion_impacto if posicion_impacto != Vector2.ZERO else global_position
		if punto_objetivo.distance_to(punto_explosion) <= radio_explosion:
			var direccion: Vector2 = (punto_objetivo - punto_explosion).normalized()
			if mostrar_efecto:
				objetivo.recibir_impacto_proyectil(
					dano_area,
					punto_objetivo,
					direccion,
					tipo_visual
				)
			else:
				objetivo.recibir_dano(dano_area)


func _finalizar() -> void:
	if _finalizado:
		return
	_finalizado = true
	finalizado.emit()
	queue_free()
