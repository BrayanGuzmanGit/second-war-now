extends Node

signal saldo_actualizado(saldo: int)

const RUTA_ARCHIVO := "user://save_data.json"
const VERSION_PROGRESO := 3
const ECONOMIA = preload("res://Modelos/ReglasEconomia.gd")
const ORDEN := ["francia", "alamein", "berlin"]

var progreso: Dictionary
var ruta_archivo := RUTA_ARCHIVO
var aviso_guardado := ""
var _bloqueado := false

func _ready() -> void:
	cargar_progreso()

func _leer(ruta: String) -> Dictionary:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return {}
	var lector := JSON.new()
	if lector.parse(archivo.get_as_text()) != OK:
		return {}
	var datos: Variant = lector.data
	if typeof(datos) != TYPE_DICTIONARY:
		return {}
	if typeof(datos.get("cosmeticos_comprados")) != TYPE_ARRAY or typeof(datos.get("cosmetico_equipado")) != TYPE_STRING:
		return {}
	if typeof(datos.get("misiones_completadas", datos.get("misiones_desbloqueadas"))) != TYPE_ARRAY:
		return {}
	var version: Variant = datos.get("version", 1)
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(version)) or float(version) != floorf(float(version)):
		return {}
	if int(version) < 1 or int(version) > VERSION_PROGRESO:
		return {}
	if int(datos.get("version", 1)) >= 3:
		var saldo: Variant = datos.get("monedas")
		if not (typeof(saldo) in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(saldo)) or float(saldo) < 0 or float(saldo) != floorf(float(saldo)) or float(saldo) > 9007199254740991.0:
			return {}
		if typeof(datos.get("bonos_cobrados")) != TYPE_ARRAY or typeof(datos.get("operaciones_aplicadas")) != TYPE_DICTIONARY:
			return {}
		for bono in datos["bonos_cobrados"]:
			if typeof(bono) != TYPE_STRING or not ORDEN.has(bono):
				return {}
		for id in datos["operaciones_aplicadas"]:
			var operacion: Variant = datos["operaciones_aplicadas"][id]
			if typeof(operacion) != TYPE_DICTIONARY:
				return {}
			if typeof(operacion.get("firma")) != TYPE_STRING or operacion.get("ok") != true:
				return {}
			if typeof(operacion.get("importe")) not in [TYPE_INT, TYPE_FLOAT]:
				return {}
	return datos

func cargar_progreso() -> bool:
	_bloqueado = false
	aviso_guardado = ""
	if not FileAccess.file_exists(ruta_archivo) and not FileAccess.file_exists(ruta_archivo + ".bak"):
		progreso = _crear_progreso_inicial()
		return guardar_progreso()
	var datos := _leer(ruta_archivo)
	var recuperado := false
	if datos.is_empty():
		datos = _leer(ruta_archivo + ".bak")
		recuperado = not datos.is_empty()
	if datos.is_empty():
		aviso_guardado = "No se pudo recuperar el guardado. Se conserva el archivo original; compras y recompensas están bloqueadas."
		_bloqueado = true
		progreso = _crear_progreso_inicial()
		progreso["monedas"] = 0
		push_warning(aviso_guardado)
		return false
	progreso = _migrar(datos)
	if recuperado:
		aviso_guardado = "Se recuperó el progreso desde el respaldo."
		# No sustituir el respaldo válido por el archivo corrupto.
		if FileAccess.file_exists(ruta_archivo):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(ruta_archivo), ProjectSettings.globalize_path(ruta_archivo + ".corrupto"))
	if recuperado or progreso != datos:
		if not guardar_progreso():
			_bloqueado = true
			aviso_guardado = "No se pudo guardar la recuperación o migración. Reintenta abrir el juego."
			return false
	saldo_actualizado.emit(obtener_saldo())
	return true

func _migrar(datos: Dictionary) -> Dictionary:
	# Los bonos anteriores se dan por consumidos y la bienvenida nace solo al migrar.
	var nuevo := datos.duplicate(true)
	var completadas: Array = []
	if nuevo.has("misiones_completadas"):
		completadas = nuevo["misiones_completadas"].duplicate()
	else:
		for indice in range(1, ORDEN.size()):
			if nuevo["misiones_desbloqueadas"].has(ORDEN[indice]):
				for anterior in range(indice):
					if not completadas.has(ORDEN[anterior]):
						completadas.append(ORDEN[anterior])
	var ordenadas: Array = []
	for id in ORDEN:
		if not completadas.has(id):
			break
		ordenadas.append(id)
	nuevo["misiones_completadas"] = ordenadas
	nuevo.erase("misiones_desbloqueadas")
	var comprados: Array = ["TNQ-01"]
	for id in nuevo["cosmeticos_comprados"]:
		if ECONOMIA.PRECIOS.has(id) and not comprados.has(id):
			comprados.append(id)
	nuevo["cosmeticos_comprados"] = comprados
	if not comprados.has(nuevo["cosmetico_equipado"]):
		nuevo["cosmetico_equipado"] = "TNQ-01"
	if int(nuevo.get("version", 1)) < 3:
		nuevo["monedas"] = ECONOMIA.BIENVENIDA
		nuevo["bonos_cobrados"] = ordenadas.duplicate()
		nuevo["operaciones_aplicadas"] = {}
	nuevo["monedas"] = int(nuevo["monedas"])
	nuevo["version"] = VERSION_PROGRESO
	return nuevo

func guardar_progreso() -> bool:
	if _bloqueado:
		return false
	var temporal := ruta_archivo + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(progreso, "\t"))
	archivo.flush()
	var error := archivo.get_error()
	archivo.close()
	if error != OK:
		return false
	var destino := ProjectSettings.globalize_path(ruta_archivo)
	# Copiar solo un guardado válido; el temporal se renombra en el mismo volumen.
	if not _leer(ruta_archivo).is_empty():
		if DirAccess.copy_absolute(destino, destino + ".bak") != OK:
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporal), destino) != OK:
		return false
	return true

func obtener_saldo() -> int:
	return int(progreso.get("monedas", 0))

func nuevo_id_operacion() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func _respuesta(codigo: String, importe: int = 0) -> Dictionary:
	return {"ok": codigo == "ok", "codigo": codigo, "importe": importe, "saldo": obtener_saldo()}

func _anterior(id: String, firma: String) -> Dictionary:
	# La firma impide reutilizar un recibo para un artículo o resultado distinto.
	var operaciones: Dictionary = progreso["operaciones_aplicadas"]
	if operaciones.has(id):
		var anterior: Dictionary = operaciones[id]
		if anterior.get("firma") != firma:
			return _respuesta("operacion_invalida")
		var respuesta := anterior.duplicate(true)
		respuesta["saldo"] = obtener_saldo()
		return respuesta
	return {}

func _confirmar(id: String, firma: String, anterior: Dictionary, resultado: Dictionary) -> Dictionary:
	# El recibo, las monedas y la propiedad/progreso pertenecen a una única escritura.
	resultado["ok"] = true
	resultado["codigo"] = "ok"
	resultado["saldo"] = obtener_saldo()
	resultado["firma"] = firma
	progreso["operaciones_aplicadas"][id] = resultado.duplicate(true)
	if not guardar_progreso():
		progreso = anterior
		return _respuesta("error_guardado")
	saldo_actualizado.emit(obtener_saldo())
	return resultado

func comprar_cosmetico(id: String, operacion: String) -> Dictionary:
	if not ECONOMIA.PRECIOS.has(id) or operacion.is_empty():
		return _respuesta("articulo_invalido")
	var firma := "skin:" + id
	var existente := _anterior(operacion, firma)
	if not existente.is_empty():
		return existente
	if progreso["cosmeticos_comprados"].has(id):
		return _respuesta("ya_comprado")
	var precio: int = ECONOMIA.PRECIOS[id]
	if obtener_saldo() < precio:
		return _respuesta("saldo_insuficiente")
	var anterior := progreso.duplicate(true)
	progreso["monedas"] = obtener_saldo() - precio
	progreso["cosmeticos_comprados"].append(id)
	return _confirmar(operacion, firma, anterior, {"importe": -precio})

func comprar_paquete(id: String, operacion: String) -> Dictionary:
	var paquete := ECONOMIA.paquete(id)
	if paquete.is_empty() or operacion.is_empty():
		return _respuesta("articulo_invalido")
	var firma := "paquete:" + id
	var existente := _anterior(operacion, firma)
	if not existente.is_empty():
		return existente
	var anterior := progreso.duplicate(true)
	progreso["monedas"] = obtener_saldo() + int(paquete["monedas"])
	return _confirmar(operacion, firma, anterior, {"importe": int(paquete["monedas"])})

func liquidar_partida(operacion: String, mision: String, victoria: bool, defensas: int) -> Dictionary:
	if not ORDEN.has(mision) or operacion.is_empty():
		return _respuesta("mision_invalida")
	var firma := "partida:%s:%s:%d" % [mision, victoria, defensas]
	var existente := _anterior(operacion, firma)
	if not existente.is_empty():
		return existente
	var indice := ORDEN.find(mision)
	if indice > 0 and not progreso["misiones_completadas"].has(ORDEN[indice - 1]):
		return _respuesta("mision_bloqueada")
	var anterior := progreso.duplicate(true)
	var resultado := ECONOMIA.recompensa(mision, victoria, defensas, progreso["bonos_cobrados"].has(mision))
	progreso["monedas"] = obtener_saldo() + int(resultado["importe"])
	if victoria:
		if not progreso["misiones_completadas"].has(mision):
			progreso["misiones_completadas"].append(mision)
		if not progreso["bonos_cobrados"].has(mision):
			progreso["bonos_cobrados"].append(mision)
	return _confirmar(operacion, firma, anterior, resultado)

func registrar_mision_completada(id_mision: String) -> bool:
	# Compatibilidad con herramientas: completar sin inventar una partida ni recompensas.
	if not ORDEN.has(id_mision):
		return false
	var anterior := progreso.duplicate(true)
	if not progreso["misiones_completadas"].has(id_mision):
		progreso["misiones_completadas"].append(id_mision)
	if guardar_progreso():
		return true
	progreso = anterior
	return false

func reiniciar_progreso_misiones() -> bool:
	var anterior := progreso.duplicate(true)
	progreso["misiones_completadas"] = []
	if guardar_progreso():
		return true
	progreso = anterior
	return false

func registrar_cosmetico_comprado(id: String) -> bool:
	# Las llamadas antiguas también cobran; no queda una ruta gratuita de adquisición.
	if progreso["cosmeticos_comprados"].has(id):
		return true
	return comprar_cosmetico(id, nuevo_id_operacion())["ok"]

func equipar_cosmetico(id: String) -> bool:
	if not ECONOMIA.PRECIOS.has(id) or not progreso["cosmeticos_comprados"].has(id):
		return false
	var anterior := progreso.duplicate(true)
	progreso["cosmetico_equipado"] = id
	if guardar_progreso():
		return true
	progreso = anterior
	return false

func _crear_progreso_inicial() -> Dictionary:
	return {"version": VERSION_PROGRESO, "misiones_completadas": [],
		"cosmeticos_comprados": ["TNQ-01"], "cosmetico_equipado": "TNQ-01",
		"monedas": ECONOMIA.BIENVENIDA, "bonos_cobrados": [], "operaciones_aplicadas": {}}
