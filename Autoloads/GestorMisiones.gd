extends Node

const MISIONES: Array[Dictionary] = [
	{
		"id": "francia",
		"contexto_historico": "Mayo de 1940. La ofensiva alemana fuerza el repliegue aliado hacia la costa. Este episodio representa una posición defensiva en la ruta hacia Dunkerque.",
		"operacion": "Resistencia y evacuación",
		"imagen_informe": "res://Imagenes/Fondos/MapaFrancia1940.jpeg",
		"objetivos_informe": ["Destruir la posición enemiga inicial.", "Retirarse hacia Dunkerque.", "Entrar vivo en evacuación antes del vencimiento."],
		"video_introduccion": "res://Vistas/Recursos/Misiones/FranciaIntroduccion.ogv",
		"video_victoria": "res://Vistas/Recursos/Misiones/FranciaVictoria.ogv",
		"nombre": "Batalla de Francia",
		"anio": 1940,
		"ubicacion": "Dunkerque, Francia",
		"fecha": "10 de mayo – 25 de junio de 1940",
		"descripcion": "Resiste el avance enemigo, neutraliza la posición blindada y llega a la zona de evacuación.",
		"introduccion": "Mayo de 1940. La ofensiva alemana obliga a las fuerzas aliadas a replegarse hacia la costa. En este episodio ficticio inspirado en la campaña de Francia, debes neutralizar una posición enemiga y retirarte vivo hacia Dunkerque.\n\nTras vencer tendrás 30 segundos para evacuar: los refuerzos cortarán la retirada si te demoras.",
		"mensaje_retirada": "La posición ha caído, pero llegan refuerzos. ¡Retírate a Dunkerque antes de que sea demasiado tarde!",
		"resumen_historico": "Has conseguido mantener la posición y permitir la retirada de las fuerzas aliadas.\n\nLa evacuación de Dunkerque permitió retirar a cientos de miles de soldados aliados tras la campaña de Francia.",
		"paleta": "francia",
		"escena": "res://Niveles/nivel_1.tscn",
	},
	{
		"id": "alamein",
		"contexto_historico": "Octubre de 1942. El Octavo Ejército británico inicia su ofensiva contra las posiciones del Eje en el desierto egipcio.",
		"operacion": "Ofensiva en el desierto",
		"imagen_informe": "res://Imagenes/Fondos/MapaElAlamein1942.jpeg",
		"objetivos_informe": ["Destruir la primera defensa.", "Avanzar hasta la segunda posición y destruirla.", "Alcanzar vivo la salida ofensiva."],
		"video_introduccion": "res://Vistas/Recursos/Misiones/AlameinIntroduccion.ogv",
		"video_victoria": "res://Vistas/Recursos/Misiones/AlameinVictoria.ogv",
		"nombre": "Segunda Batalla de El Alamein",
		"anio": 1942,
		"ubicacion": "El Alamein, Egipto",
		"fecha": "23 de octubre – 4 de noviembre de 1942",
		"descripcion": "Rompe dos posiciones defensivas sucesivas del Eje y alcanza la salida ofensiva.",
		"introduccion": "Octubre de 1942. El Octavo Ejército británico inicia su ofensiva contra las posiciones del Eje en El Alamein.\n\nSupera la primera defensa, avanza entre las dunas y destruye la segunda posición. Conserva la vida de tu tanque hasta alcanzar la salida ofensiva.",
		"mensaje_retirada": "Las posiciones enemigas han caído. El avance aliado continúa por el desierto.\n\n¡Avanza para completar la ofensiva!",
		"resumen_historico": "La victoria aliada en El Alamein recuperó la iniciativa en el norte de África y forzó la retirada del Eje.",
		"paleta": "alamein",
		"escena": "res://Niveles/nivel_1.tscn",
	},
	{
		"id": "berlin",
		"contexto_historico": "Abril de 1945. El Ejército Rojo avanza hacia el centro de Berlín entre ruinas y defensas alemanas.",
		"operacion": "Avance urbano",
		"imagen_informe": "res://Imagenes/Fondos/MapaBerlin1945.jpeg",
		"objetivos_informe": ["Superar la posición urbana.", "Atravesar las barricadas y destruir la defensa final.", "Alcanzar vivo el objetivo."],
		"video_introduccion": "res://Vistas/Recursos/Misiones/BerlinIntroduccion.ogv",
		"video_victoria": "res://Vistas/Recursos/Misiones/BerlinVictoria.ogv",
		"nombre": "Batalla de Berlín",
		"anio": 1945,
		"ubicacion": "Berlín, Alemania",
		"fecha": "16 de abril – 2 de mayo de 1945",
		"descripcion": "Supera la posición urbana, cruza las barricadas y destruye la defensa final antes de llegar al objetivo.",
		"introduccion": "Abril de 1945. El Ejército Rojo avanza sobre Berlín entre calles, ruinas y posiciones defensivas alemanas.\n\nSupera la defensa de entrada y atraviesa los escombros hasta la posición final. Las ruinas bloquean disparos: ajusta el ángulo y la potencia para alcanzar a los defensores.",
		"epilogo": "CAMPAÑA COMPLETADA\nDe la retirada de Francia al avance final sobre Berlín, has recorrido tres episodios inspirados en el conflicto europeo. Estos escenarios simplifican los hechos con fines educativos. La guerra dejó un enorme coste humano: recordar su historia también invita a valorar la paz.",
		"mensaje_retirada": "La última posición enemiga ha sido neutralizada. El Ejército Rojo avanza hacia el centro de Berlín.\n\n¡Avanza para completar la misión!",
		"resumen_historico": "La batalla terminó el 2 de mayo de 1945 con la rendición de las fuerzas alemanas que defendían Berlín.",
		"paleta": "berlin",
		"escena": "res://Niveles/nivel_1.tscn",
	},
]

var id_mision_actual := "francia"


func _ready() -> void:
	_normalizar_progreso_campana()


func obtener_misiones() -> Array[Dictionary]:
	_normalizar_progreso_campana()
	var completadas: Array = GestorGuardado.progreso["misiones_completadas"]
	var disponibles: Array[Dictionary] = []
	for indice in range(MISIONES.size()):
		var mision: Dictionary = MISIONES[indice]
		var copia: Dictionary = mision.duplicate(true)
		copia["desbloqueada"] = _esta_desbloqueada(indice, completadas)
		disponibles.append(copia)
	return disponibles


func obtener_mision(id_mision: String) -> Dictionary:
	for mision in MISIONES:
		if mision["id"] == id_mision:
			var resultado: Dictionary = mision.duplicate(true)
			resultado["cierre_educativo"] = preload("res://Modelos/CierresHistoricos.gd").obtener(id_mision)
			return resultado
	push_error("No existe la misión solicitada: %s." % id_mision)
	return {}


func obtener_mision_actual() -> Dictionary:
	return obtener_mision(id_mision_actual)


func seleccionar_mision(id_mision: String) -> bool:
	var mision := obtener_mision(id_mision)
	if mision.is_empty():
		return false
	var indice := _buscar_indice_mision(id_mision)
	var completadas: Array = GestorGuardado.progreso["misiones_completadas"]
	if not _esta_desbloqueada(indice, completadas):
		push_warning("La misión todavía está bloqueada: %s." % id_mision)
		return false
	id_mision_actual = id_mision
	return true


func completar_mision_actual() -> bool:
	_normalizar_progreso_campana()
	var indice := _buscar_indice_mision(id_mision_actual)
	var completadas: Array = GestorGuardado.progreso["misiones_completadas"]
	if indice < 0 or not _esta_desbloqueada(indice, completadas):
		push_warning("No se puede completar una misión que todavía está bloqueada: %s." % id_mision_actual)
		return false
	return GestorGuardado.registrar_mision_completada(id_mision_actual)


func _normalizar_progreso_campana() -> void:
	var progreso: Dictionary = GestorGuardado.progreso
	var progreso_anterior := progreso.duplicate(true)
	var ids_completados: Array = []
	if progreso.has("misiones_completadas"):
		ids_completados = progreso["misiones_completadas"]
	else:
		# En partidas anteriores, desbloquear la siguiente misión representaba completar la actual.
		var ids_desbloqueados: Array = progreso.get("misiones_desbloqueadas", [])
		for indice in range(1, MISIONES.size()):
			if ids_desbloqueados.has(MISIONES[indice]["id"]):
				for indice_anterior in range(indice):
					var id_anterior: String = MISIONES[indice_anterior]["id"]
					if not ids_completados.has(id_anterior):
						ids_completados.append(id_anterior)

	var completadas_en_orden: Array[String] = []
	for mision in MISIONES:
		if not ids_completados.has(mision["id"]):
			break
		completadas_en_orden.append(mision["id"])

	progreso["misiones_completadas"] = completadas_en_orden
	progreso.erase("misiones_desbloqueadas")
	progreso["version"] = GestorGuardado.VERSION_PROGRESO
	if progreso != progreso_anterior:
		GestorGuardado.guardar_progreso()


func _esta_desbloqueada(indice: int, completadas: Array) -> bool:
	return indice >= 0 and indice < MISIONES.size() and (
		indice == 0 or completadas.has(MISIONES[indice - 1]["id"])
	)


func _buscar_indice_mision(id_mision: String) -> int:
	for indice in range(MISIONES.size()):
		if MISIONES[indice]["id"] == id_mision:
			return indice
	return -1
