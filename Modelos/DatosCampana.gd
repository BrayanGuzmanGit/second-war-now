extends RefCounted
class_name DatosCampana

## Configuración táctica separada de los textos históricos y del controlador de turnos.
## Las coordenadas de aparición son del cuerpo del tanque, antes de asentarse en el suelo.
static var ESCENARIOS: Dictionary = {
	"francia": {
		"jugador": Vector2(360, 720),
		"posiciones": [Vector2(1300, 720)],
		"activacion": 0.0,
		"dano_ia": 1.0,
		"evacuacion_segundos": 30.0,
		"objetivos": ["Resiste: destruye la posición blindada enemiga."],
		"avance": "¡Retírate a Dunkerque antes de que lleguen los refuerzos!",
		"terreno": [],
		"ruinas": [],
	},
	"alamein": {
		"jugador": Vector2(260, 720),
		"posiciones": [Vector2(850, 650), Vector2(1480, 720)],
		"activacion": 970.0,
		"dano_ia": 0.45,
		"evacuacion_segundos": 0.0,
		"objetivos": ["Rompe la primera posición del Eje.", "Rompe la segunda posición del Eje."],
		"avance": "Primera posición superada. Avanza hasta la siguiente línea defensiva.",
		"terreno": [
			PackedVector2Array([Vector2(430,800), Vector2(710,730), Vector2(890,730), Vector2(1030,800)]),
			PackedVector2Array([Vector2(1050,800), Vector2(1230,695), Vector2(1290,695), Vector2(1470,800)]),
		],
		"ruinas": [],
	},
	"berlin": {
		"jugador": Vector2(260, 720),
		"posiciones": [Vector2(850, 710), Vector2(1480, 710)],
		"activacion": 970.0,
		"dano_ia": 0.55,
		"evacuacion_segundos": 0.0,
		"objetivos": ["Supera la posición urbana de entrada.", "Destruye la defensa final de Berlín."],
		"avance": "Entrada asegurada. Cruza las barricadas hacia la defensa final.",
		# Los escombros forman rampas apoyadas en el suelo, sin bloques aéreos
		# que intercepten las trayectorias del jugador o de la IA.
		"terreno": [
			PackedVector2Array([Vector2(450,800), Vector2(600,760), Vector2(680,760), Vector2(800,800)]),
			PackedVector2Array([Vector2(1020,800), Vector2(1160,735), Vector2(1220,735), Vector2(1390,800)]),
		],
		"ruinas": [],
	},
}


static func obtener(id_mision: String) -> Dictionary:
	var datos: Dictionary = ESCENARIOS.get(id_mision, ESCENARIOS["francia"]).duplicate(true)
	datos["apariencia_enemiga"] = "ENM-01"
	return datos
