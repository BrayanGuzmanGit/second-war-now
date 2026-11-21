extends RefCounted
class_name ReglasEconomia

## Valores de diseño; la simulación nunca solicita dinero ni datos bancarios.
const BIENVENIDA := 100
const BONO_PRIMERA_VICTORIA := 50
const POR_DEFENSA := 25
const VICTORIAS := {"francia": 100, "alamein": 150, "berlin": 200}
const DEFENSAS := {"francia": 1, "alamein": 2, "berlin": 2}
const PRECIOS := {"TNQ-01": 0, "TNQ-02": 300, "TNQ-03": 700, "TNQ-04": 600, "TNQ-06": 900}
const PAQUETES: Array[Dictionary] = [
	{"id": "MON-01", "nombre": "Pequeño", "monedas": 300, "precio_cop": "COP $3.000"},
	{"id": "MON-02", "nombre": "Mediano", "monedas": 800, "precio_cop": "COP $7.000"},
	{"id": "MON-03", "nombre": "Grande", "monedas": 1600, "precio_cop": "COP $12.000"},
]

static func recompensa(mision: String, victoria: bool, defensas: int, bono_cobrado: bool) -> Dictionary:
	var base: int = int(VICTORIAS.get(mision, 0)) if victoria else 0
	var bono := BONO_PRIMERA_VICTORIA if victoria and not bono_cobrado else 0
	var posiciones := clampi(defensas, 0, int(DEFENSAS.get(mision, 0)))
	var por_defensas := posiciones * POR_DEFENSA if not victoria else 0
	return {"base": base, "bono": bono, "defensas": por_defensas, "importe": base + bono + por_defensas}

static func paquete(id: String) -> Dictionary:
	for item in PAQUETES:
		if item["id"] == id:
			return item.duplicate(true)
	return {}
