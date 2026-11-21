extends RefCounted
class_name CatalogoSonidos

const RUTA := "res://Vistas/Recursos/Audio/"
const MATERIALES := ["metal", "tierra", "arena", "escombros"]
const MUNICIONES := ["estandar", "pesado", "dispersion", "bombardeo", "incendiario"]
const BUCLES := ["motor", "cadenas", "engranajes", "rodar_tierra", "rodar_arena", "rodar_escombros", "fuego", "bombardeo"]
const AVISOS := ["turno_jugador", "turno_enemigo", "evacuacion", "cuenta", "refuerzos"]
const SELECTOR := ["selector_abrir", "selector_cerrar", "selector_estandar", "selector_pesado", "selector_dispersion", "selector_bombardeo", "selector_incendiario"]

static func superficie(mision: String) -> String:
	return {"francia": "tierra", "alamein": "arena", "berlin": "escombros"}.get(mision, "tierra")

static func material(cuerpo: Node, predeterminado: String) -> String:
	if not is_instance_valid(cuerpo):
		return predeterminado
	if cuerpo.is_in_group("tanques"):
		return "metal"
	var valor: String = cuerpo.get_meta("material_audio", predeterminado)
	return valor if valor in MATERIALES else predeterminado

static func ruta(clave: String) -> String:
	return RUTA + clave + (".ogg" if clave in BUCLES else ".wav")
