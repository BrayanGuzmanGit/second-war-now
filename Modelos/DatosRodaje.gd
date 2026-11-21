extends RefCounted
class_name DatosRodaje

## Coordenadas medidas sobre las fuentes originales, antes de escala y reflejo.
## Vector3 = centro X/Y y radio exterior; el orden determina la superposición.
const MODELOS := {
	"TNQ-01": {
		"corte": 202.0,
		"ruedas": [Vector3(80,232,22),Vector3(133,260,21),Vector3(196,260,21),Vector3(248,260,21),Vector3(310,260,21),Vector3(362,260,21),Vector3(423,260,21),Vector3(464,231,25)],
		"ruta": [Vector2(79,206),Vector2(464,206),Vector2(493,231),Vector2(452,270),Vector2(423,281),Vector2(133,281),Vector2(55,249),Vector2(54,225)],
		"paso": 12.0, "eslabon": Rect2(269,276,11,8),
		"brazos": [Vector4(163,218,32,42),Vector4(279,218,32,42),Vector4(393,218,32,42)],
		"reconstruir": [1,2,3,4,5,6],
	},
	"TNQ-02": {
		"corte": 529.0,
		"ruedas": [Vector3(180,597,49),Vector3(303,659,48),Vector3(463,659,48),Vector3(572,659,48),Vector3(732,660,48),Vector3(842,659,48),Vector3(999,660,48),Vector3(1086,596,65)],
		"ruta": [Vector2(180,535),Vector2(1086,535),Vector2(1161,591),Vector2(1099,668),Vector2(999,715),Vector2(303,715),Vector2(119,648),Vector2(107,590)],
		"paso": 34.0, "eslabon": Rect2(578,707,30,16),
		"brazos": [Vector4(382,563,81,97),Vector4(652,563,81,97),Vector4(921,563,80,97)],
		"reconstruir": [1,2,3,4,5,6],
	},
	"TNQ-03": {
		"corte": 535.0,
		"ruedas": [Vector3(138,604,63),Vector3(286,637,81),Vector3(463,637,81),Vector3(636,637,81),Vector3(818,637,81),Vector3(996,637,81),Vector3(1137,598,57)],
		"ruta": [Vector2(138,535),Vector2(1137,535),Vector2(1204,591),Vector2(1147,682),Vector2(996,734),Vector2(286,734),Vector2(65,649),Vector2(60,589)],
		"paso": 38.0, "eslabon": Rect2(554,727,31,14),
	},
	"TNQ-04": {
		"corte": 544.0,
		"ruedas": [Vector3(229,598,34),Vector3(353,623,35),Vector3(447,623,35),Vector3(545,623,35),Vector3(638,623,35),Vector3(732,623,35),Vector3(827,623,35),Vector3(923,623,35),Vector3(1037,598,34)],
		"ruta": [Vector2(126,492),Vector2(1139,494),Vector2(1170,520),Vector2(1050,640),Vector2(923,662),Vector2(353,662),Vector2(207,639),Vector2(101,508)],
		"paso": 30.0, "eslabon": Rect2(565,657,28,13),
		"soportes": [Vector2(271,544),Vector2(368,544),Vector2(464,544),Vector2(559,544),Vector2(655,544),Vector2(751,544),Vector2(847,544),Vector2(943,544)],
	},
	"TNQ-06": {
		"corte": 561.0,
		"ruedas": [Vector3(132,506,51),Vector3(203,619,34),Vector3(332,645,35),Vector3(432,645,35),Vector3(537,645,35),Vector3(636,645,35),Vector3(735,645,35),Vector3(838,645,35),Vector3(938,645,35),Vector3(1057,620,35),Vector3(1135,506,50)],
		"ruta": [Vector2(132,449),Vector2(1135,449),Vector2(1200,506),Vector2(1170,585),Vector2(1057,679),Vector2(938,686),Vector2(332,686),Vector2(181,659),Vector2(66,540),Vector2(66,490)],
		"paso": 30.0, "eslabon": Rect2(564,678,29,14),
		"soportes": [Vector2(250,562),Vector2(353,562),Vector2(455,562),Vector2(558,562),Vector2(659,562),Vector2(762,562),Vector2(865,562),Vector2(968,562)],
	},
	"ENM-01": {
		"corte": 551.0,
		# Ruedas interiores primero; las exteriores tapan sus bordes como en la fuente.
		"ruedas": [Vector3(188,626,58),Vector3(1104,596,67),Vector3(303,646,73),Vector3(497,646,73),Vector3(687,646,73),Vector3(878,646,73),Vector3(401,646,73),Vector3(593,646,73),Vector3(784,646,73),Vector3(973,646,73)],
		"fuentes": {2:Vector3(401,646,73),3:Vector3(401,646,73),4:Vector3(593,646,73),5:Vector3(784,646,73)},
		"ruta": [Vector2(188,559),Vector2(880,559),Vector2(1104,519),Vector2(1191,589),Vector2(1169,673),Vector2(973,735),Vector2(303,735),Vector2(119,681),Vector2(112,605)],
		"paso": 35.0, "eslabon": Rect2(550,728,29,16),
	},
}

static func obtener(id: String) -> Dictionary:
	return MODELOS.get(id, {}).duplicate(true)
