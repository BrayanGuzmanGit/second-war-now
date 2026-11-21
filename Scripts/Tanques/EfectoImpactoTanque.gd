extends Node2D
class_name EfectoImpactoTanque

var direccion_impacto := Vector2.UP
var tipo_proyectil := "estandar"
var superficie := "metal"
var tiempo := 0.0
var duracion := 0.45
const COLORES := {"tierra": Color("#775436"), "arena": Color("#e6c184"), "escombros": Color("#88827c"), "metal": Color("#ffd881"), "division": Color("#ffcf79")}

static func crear(origen: Node, punto: Vector2, normal: Vector2, tipo: String, material: String) -> void:
	if tipo == "dispersion" and origen.get_tree().get_node_count_in_group("particulas_dispersion") >= 8:
		return
	var efecto := new()
	if tipo == "dispersion":
		efecto.add_to_group("particulas_dispersion")
	efecto.tipo_proyectil = tipo
	efecto.superficie = material
	efecto.direccion_impacto = normal.normalized() if not normal.is_zero_approx() else Vector2.UP
	efecto.z_index = 24
	origen.get_tree().current_scene.add_child(efecto)
	efecto.global_position = punto
	efecto.add_to_group("efectos_impacto")

func _ready() -> void:
	if tipo_proyectil == "pesado":
		duracion = 0.62
	elif tipo_proyectil == "dispersion":
		duracion = 0.25

func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()
	if tiempo >= duracion:
		queue_free()

func _draw() -> void:
	if OS.get_cmdline_user_args().has("impactos-debug"):
		draw_line(Vector2(-5,0), Vector2(5,0), Color.CYAN, 1)
		draw_line(Vector2(0,-5), Vector2(0,5), Color.CYAN, 1)
		draw_line(Vector2.ZERO, direccion_impacto*15, Color.GREEN, 1)
	var p := clampf(tiempo / duracion, 0.0, 1.0)
	var fuerza := 1.45 if tipo_proyectil == "pesado" else (0.65 if tipo_proyectil == "dispersion" else 1.0)
	var color: Color = COLORES.get(superficie, COLORES.tierra)
	var cantidad := 5 if tipo_proyectil == "dispersion" else 14
	var chispa := superficie in ["metal","division"]
	var normal := direccion_impacto.normalized()
	if p < 0.20:
		draw_circle(Vector2.ZERO, (3.0 + 8.0*p)*fuerza, Color(1,0.92,0.7,1.0-p*5),true,-1,true)
	for i in cantidad:
		var eje := normal.rotated(sin(i*7.13)*1.12)
		var v := eje * (48.0 + fmod(i*53.7,145.0)) * fuerza
		var punto := v*tiempo + Vector2.DOWN*165.0*tiempo*tiempo
		if chispa:
			draw_line(punto, punto-v*0.032, Color(color,1.0-p),1.7*fuerza,true)
		else:
			var r := (1.5+float(i%3))*fuerza
			draw_colored_polygon(PackedVector2Array([punto+Vector2(-r,0),punto+Vector2(0,-r),punto+Vector2(r,r*0.45)]),Color(color.darkened(0.2),1.0-p))
		if i < 5:
			var polvo := Color("#645b53") if chispa else color
			draw_circle(v*tiempo*0.36 + Vector2.UP*p*9, (2+p*10)*fuerza, Color(polvo,(1-p)*0.27),true,-1,true)
		if tipo_proyectil == "incendiario" and i < 6:
			draw_circle(eje*p*18 + Vector2.UP*p*12, (1-p)*6, Color(1,0.37+p*0.3,0.08,(1-p)*0.8),true,-1,true)

