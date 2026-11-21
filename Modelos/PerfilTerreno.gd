extends RefCounted
class_name PerfilTerreno

## Una altura por columna evita túneles y permite limitar la excavación sin crear material.
const PASO := 4.0
const ANCHO := 1800.0
const BASE := 1005.0
const PROFUNDIDAD_MAXIMA := 80.0
const PENDIENTE := 0.62486935 # tan(32°), en unidades verticales por horizontal.
const CONFIGURACION := {
	"estandar": Vector2(80, 20), "pesado": Vector2(120, 45),
	"bombardeo": Vector2(150, 32), "dispersion": Vector2(32, 8),
	"incendiario": Vector2(60, 6),
}

var inicial := PackedFloat32Array()
var alturas := PackedFloat32Array()
var limites := PackedFloat32Array()
var protecciones: Array[Vector2] = []


func configurar(crestas: Array, futuras_posiciones: Array = []) -> void:
	inicial.resize(int(ANCHO / PASO) + 1)
	for i in range(inicial.size()):
		var x := i * PASO
		var y := 800.0
		for cresta: PackedVector2Array in crestas:
			for j in range(cresta.size() - 1):
				if x >= cresta[j].x and x <= cresta[j + 1].x:
					y = minf(y, lerpf(cresta[j].y, cresta[j + 1].y, inverse_lerp(cresta[j].x, cresta[j + 1].x, x)))
		inicial[i] = y
	alturas = inicial.duplicate()
	protecciones.clear()
	for posicion: Vector2 in futuras_posiciones:
		protecciones.append(Vector2(posicion.x - 135.0, posicion.x + 135.0))
	_actualizar_limites()


func liberar_posicion(x: float) -> void:
	for i in range(protecciones.size() - 1, -1, -1):
		if x >= protecciones[i].x and x <= protecciones[i].y:
			protecciones.remove_at(i)
	_actualizar_limites()


func _actualizar_limites() -> void:
	limites = inicial.duplicate()
	for i in range(limites.size()):
		var x := i * PASO
		var protegido := x >= 1640.0
		for tramo in protecciones:
			protegido = protegido or (x >= tramo.x and x <= tramo.y)
		if not protegido:
			limites[i] += PROFUNDIDAD_MAXIMA
	_limitar_pendientes(limites)


func obtener_altura(x: float) -> float:
	var indice := clampf(x / PASO, 0.0, alturas.size() - 1.0)
	var izquierda := int(indice)
	return lerpf(alturas[izquierda], alturas[mini(izquierda + 1, alturas.size() - 1)], indice - izquierda)


func calcular_objetivo(posicion: Vector2, tipo: String, es_fragmento: bool = false) -> PackedFloat32Array:
	var objetivo := alturas.duplicate()
	var configuracion: Vector2 = CONFIGURACION.get("dispersion" if es_fragmento else tipo, Vector2.ZERO)
	if configuracion.x <= 0.0:
		return objetivo
	var separacion := absf(posicion.y - obtener_altura(posicion.x))
	if separacion >= configuracion.x:
		return objetivo
	var intensidad := 1.0 - separacion / configuracion.x
	for i in range(objetivo.size()):
		var distancia := absf(i * PASO - posicion.x) / configuracion.x
		if distancia >= 1.0:
			continue
		var cuenco := 0.5 + 0.5 * cos(PI * distancia)
		objetivo[i] = minf(limites[i], alturas[i] + configuracion.y * intensidad * cuenco)
	# Dos pasadas calculan la envolvente inferior de pendiente acotada. Como el perfil
	# anterior ya era válido, limitar el objetivo nunca restaura terreno excavado.
	_limitar_pendientes(objetivo)
	return objetivo


func aplicar_objetivo(desde: PackedFloat32Array, objetivo: PackedFloat32Array, progreso: float) -> Vector2i:
	var region := Vector2i(alturas.size(), -1)
	for i in range(alturas.size()):
		var valor := maxf(alturas[i], lerpf(desde[i], objetivo[i], clampf(progreso, 0.0, 1.0)))
		if valor - alturas[i] > 0.0001:
			alturas[i] = valor
			region.x = mini(region.x, i)
			region.y = maxi(region.y, i)
	return region


func _limitar_pendientes(perfil: PackedFloat32Array) -> void:
	var salto := PENDIENTE * PASO
	for i in range(1, perfil.size()):
		perfil[i] = minf(perfil[i], perfil[i - 1] + salto)
	for i in range(perfil.size() - 2, -1, -1):
		perfil[i] = minf(perfil[i], perfil[i + 1] + salto)
