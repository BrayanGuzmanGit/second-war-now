extends Node
class_name GestorProyectiles

const ESCENAS_PROYECTILES: Dictionary = {
	"estandar": preload("res://Vistas/Proyectiles/ProyectilEstandar.tscn"),
	"pesado": preload("res://Vistas/Proyectiles/ProyectilPesado.tscn"),
	"dispersion": preload("res://Vistas/Proyectiles/ProyectilDispersion.tscn"),
	"bombardeo": preload("res://Vistas/Proyectiles/ProyectilBombardeo.tscn"),
	"incendiario": preload("res://Vistas/Proyectiles/ProyectilIncendiario.tscn"),
}
const MULTIPLICADORES_POTENCIA: Dictionary = {
	"estandar": 1.0,
	"pesado": 0.78,
	"dispersion": 0.82,
	"bombardeo": 1.05,
	"incendiario": 1.0,
}

var _proyectiles_usados: Array[String] = []

static func descripcion_dano(tipo: String) -> String:
	# Leer la configuración de la escena sin lanzar el proyectil ni consumir munición.
	var proyectil: Proyectil = ESCENAS_PROYECTILES[tipo].instantiate()
	var base := String.num(proyectil.dano_base)
	var texto := "%s de daño" % base
	if proyectil.cantidad_fragmentos > 0:
		texto = "%d × %s de daño" % [proyectil.cantidad_fragmentos, String.num(proyectil.dano_base / proyectil.cantidad_fragmentos)]
	elif proyectil.cantidad_ticks > 0:
		texto = "%s + %d × %s de fuego" % [base, proyectil.cantidad_ticks, String.num(proyectil.dano_por_tick)]
	proyectil.free()
	return texto


func crear_proyectil(tipo: String) -> Proyectil:
	if not ESCENAS_PROYECTILES.has(tipo):
		push_error("Tipo de proyectil desconocido: %s." % tipo)
		return null
	if not esta_disponible(tipo):
		return null
	var proyectil := ESCENAS_PROYECTILES[tipo].instantiate() as Proyectil
	if proyectil == null:
		push_error("La escena de proyectil no contiene un nodo Proyectil: %s." % tipo)
		return null
	proyectil.multiplicador_potencia = MULTIPLICADORES_POTENCIA[tipo]
	return proyectil


func obtener_multiplicador_potencia(tipo: String) -> float:
	if not MULTIPLICADORES_POTENCIA.has(tipo):
		push_error("No existe un multiplicador de potencia para: %s." % tipo)
		return 0.0
	return MULTIPLICADORES_POTENCIA[tipo]


func esta_disponible(tipo: String) -> bool:
	return ESCENAS_PROYECTILES.has(tipo) and not _proyectiles_usados.has(tipo)


func registrar_uso(tipo: String) -> bool:
	if not esta_disponible(tipo):
		push_error("No se puede registrar el proyectil no disponible: %s." % tipo)
		return false
	_proyectiles_usados.append(tipo)
	if _proyectiles_usados.size() == ESCENAS_PROYECTILES.size():
		_proyectiles_usados.clear()
	return true


func obtener_disponibles() -> Array[String]:
	var disponibles: Array[String] = []
	for tipo in ESCENAS_PROYECTILES:
		if esta_disponible(tipo):
			disponibles.append(tipo)
	return disponibles
