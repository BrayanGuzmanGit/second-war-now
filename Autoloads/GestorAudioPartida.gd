extends Node
## Audio de presentación: nunca espera ni cambia la simulación.
signal evento_reproducido(evento: String, material: String)
signal preferencias_actualizadas
signal selector_reproducido(tipo: String, municion: String)
var _voz_selector: AudioStreamPlayer
var _fundido_selector: Tween
var _selector_pendiente: Dictionary = {}

const CATALOGO = preload("res://Modelos/CatalogoSonidos.gd")
const MAX_VOCES := 18
const BUS_EFECTOS := "PartidaEfectos"
const BUS_MECANISMOS := "PartidaMecanismos"
const BUS_AVISOS := "PartidaAvisos"
var ruta_preferencias := "user://audio.cfg"
const VOLUMEN_INICIAL := {"efectos": 0.8, "avisos": 0.8, "videos": 1.0, "musica": 0.4}
var preferencias: Dictionary = {}
var activo := false
var interfaz_abierta := false
var superficie := "tierra"
var _unidades: Dictionary = {}
var _bucles: Dictionary = {}
var _voces: Array = []
var _recursos: Dictionary = {}
var _ultimas: Dictionary = {}
var _atenuacion := 0.0
var _generacion := 0
var _ultimo_segundo := 31
var _fragmentos_frame := -1
var _fragmentos_en_frame := 0

func _ready() -> void:
	for nombre in [BUS_EFECTOS, BUS_AVISOS, BUS_MECANISMOS, "Videos", "Musica"]:
		if AudioServer.get_bus_index(nombre) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, nombre)
	AudioServer.set_bus_send(AudioServer.get_bus_index(BUS_MECANISMOS), BUS_EFECTOS)
	var limite := AudioEffectLimiter.new()
	limite.ceiling_db = -2.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(BUS_EFECTOS), limite)
	cargar_preferencias()

func cargar_preferencias() -> void:
	var archivo := ConfigFile.new()
	preferencias = VOLUMEN_INICIAL.duplicate()
	for canal: String in VOLUMEN_INICIAL:
		preferencias["silencio_" + canal] = false
	if archivo.load(ruta_preferencias) == OK:
		for canal: String in VOLUMEN_INICIAL:
			var valor: Variant = archivo.get_value("audio", canal, VOLUMEN_INICIAL[canal])
			if (valor is float or valor is int) and is_finite(float(valor)):
				preferencias[canal] = clampf(float(valor), 0.0, 1.0)
			preferencias["silencio_" + canal] = archivo.get_value("audio", "silencio_" + canal, false) == true
	_aplicar_volumen()

func configurar_volumen(canal: String, volumen: float, silencio: bool) -> Error:
	if canal not in VOLUMEN_INICIAL or not is_finite(volumen):
		return ERR_INVALID_PARAMETER
	preferencias[canal] = clampf(volumen, 0.0, 1.0)
	preferencias["silencio_" + canal] = silencio
	_aplicar_volumen()
	var archivo := ConfigFile.new()
	for clave in preferencias:
		archivo.set_value("audio", clave, preferencias[clave])
	preferencias_actualizadas.emit()
	return archivo.save(ruta_preferencias)

func _aplicar_volumen() -> void:
	for canal: String in VOLUMEN_INICIAL:
		var bus := AudioServer.get_bus_index({"efectos":BUS_EFECTOS, "avisos":BUS_AVISOS, "videos":"Videos", "musica":"Musica"}[canal])
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(preferencias[canal], 0.0001)))
		AudioServer.set_bus_mute(bus, preferencias["silencio_" + canal] or preferencias[canal] <= 0.0)

func iniciar(dueno: Node, mision: String) -> void:
	detener_todo()
	activo = true
	get_node("/root/GestorMusica").solicitar(mision)
	superficie = CATALOGO.superficie(mision)
	_ultimo_segundo = 31
	var generacion := _generacion
	dueno.tree_exiting.connect(func() -> void:
		if generacion == _generacion:
			detener_todo()
	, CONNECT_ONE_SHOT)

func _recurso(clave: String) -> AudioStream:
	if not _recursos.has(clave):
		var ruta: String = CATALOGO.ruta(clave)
		if not ResourceLoader.exists(ruta):
			push_warning("Sonido no disponible: " + ruta)
			return null
		var recurso := load(ruta) as AudioStream
		if recurso is AudioStreamOggVorbis and clave in CATALOGO.BUCLES:
			recurso = recurso.duplicate()
			recurso.loop = true
		_recursos[clave] = recurso
	return _recursos[clave]

func _crear(clave: String, posicion: Vector2, db: float, bus: String, centrado := false) -> Node:
	var stream := _recurso(clave)
	if stream == null:
		return null
	var reproductor: Node = AudioStreamPlayer.new() if centrado else AudioStreamPlayer2D.new()
	reproductor.stream = stream
	reproductor.bus = bus
	reproductor.volume_db = db
	if not centrado:
		reproductor.position = posicion
		reproductor.max_distance = 6000.0
		reproductor.attenuation = 0.6
		reproductor.panning_strength = 0.45
	add_child(reproductor)
	return reproductor

func _limpiar_voces() -> void:
	for indice in range(_voces.size() - 1, -1, -1):
		if not is_instance_valid(_voces[indice]) or _voces[indice].is_queued_for_deletion():
			_voces.remove_at(indice)

func _una_vez(clave: String, posicion: Vector2, db: float, aviso := false, tono := 1.0) -> void:
	_limpiar_voces()
	if _voces.size() >= MAX_VOCES:
		var antigua: Node = _voces.pop_front()
		antigua.stop()
		antigua.queue_free()
	var voz := _crear(clave, posicion, db, BUS_AVISOS if aviso else BUS_EFECTOS, aviso)
	if voz == null:
		return
	voz.pitch_scale = tono
	_voces.append(voz)
	voz.finished.connect(voz.queue_free)
	voz.play()

func _variante(clave: String) -> String:
	var anterior: int = _ultimas.get(clave, -1)
	var indice := randi_range(0, 2) if anterior < 0 else (anterior + randi_range(1, 2)) % 3
	_ultimas[clave] = indice
	return clave + "_" + str(indice)

func evento(tipo: String, posicion := Vector2.ZERO, municion := "estandar", material := "") -> void:
	if not activo:
		return
	if tipo in CATALOGO.AVISOS:
		_una_vez(tipo, posicion, -13.0, true)
		_atenuacion = maxf(_atenuacion, 0.32)
	elif tipo == "impacto":
		if municion not in CATALOGO.MUNICIONES:
			return
		if municion == "dispersion":
			var frame := Engine.get_physics_frames()
			if frame != _fragmentos_frame:
				_fragmentos_frame = frame
				_fragmentos_en_frame = 0
			_fragmentos_en_frame += 1
			if _fragmentos_en_frame > 4:
				return
		var db := -16.0 if municion == "dispersion" else -9.0
		_una_vez(_variante("impacto_" + municion), posicion, db)
		var superficie_impacto := material if material in CATALOGO.MATERIALES else superficie
		_una_vez(_variante(superficie_impacto), posicion, db - 4.0)
		_atenuacion = maxf(_atenuacion, 0.35)
	elif tipo in ["disparo", "destruccion", "division", "bengala"]:
		var db := -10.0 if tipo in ["disparo", "destruccion"] else -20.0
		var tono := 0.88 if municion == "pesado" else 1.0
		_una_vez(tipo, posicion, db, false, tono)
		_atenuacion = maxf(_atenuacion, 0.25)
	else:
		return
	evento_reproducido.emit(tipo, material)

func impacto(cuerpo: Node, posicion: Vector2, municion: String) -> void:
	evento("impacto", posicion, municion, CATALOGO.material(cuerpo, superficie))

func cuenta_atras(restante: float) -> void:
	var segundo := ceili(restante)
	if segundo > 0 and segundo <= 5 and segundo < _ultimo_segundo:
		evento("cuenta")
	_ultimo_segundo = mini(_ultimo_segundo, segundo)

func actualizar_tanque(tanque: Node2D, delta: float, desplazamiento: Vector2, en_suelo: bool, normal: Vector2) -> void:
	if not activo or tanque.get("_destruido") == true:
		return
	var id := tanque.get_instance_id()
	if not _unidades.has(id):
		var piezas: Dictionary = {}
		for clave in ["motor", "cadenas", "rodar_" + superficie, "engranajes"]:
			piezas[clave] = _crear(clave, tanque.global_position, -80.0, BUS_MECANISMOS)
		_unidades[id] = {"ref": weakref(tanque), "piezas": piezas, "velocidad": 0.0, "mezcla": 0.0, "angulo": 0.0, "inicio": true, "engranaje": 0.0}
	var estado: Dictionary = _unidades[id]
	var tangente := Vector2(-normal.y, normal.x).normalized()
	estado["velocidad"] = absf(desplazamiento.dot(tangente)) / maxf(delta, 0.001) if en_suelo else 0.0
	# Reposiciones explícitas no son desplazamiento de las orugas.
	if desplazamiento.length() > 30.0:
		estado["velocidad"] = 0.0
		estado["inicio"] = true

func reiniciar_unidad(tanque: Node) -> void:
	var estado: Dictionary = _unidades.get(tanque.get_instance_id(), {})
	if not estado.is_empty():
		estado["inicio"] = true
		estado["engranaje"] = 0.0
		estado["velocidad"] = 0.0
		estado["mezcla"] = 0.0

func detener_unidad(tanque: Node) -> void:
	var id := tanque.get_instance_id()
	if _unidades.has(id):
		_liberar_unidad(id)

func _liberar_unidad(id: int) -> void:
	for pieza: Node in _unidades[id]["piezas"].values():
		if is_instance_valid(pieza):
			pieza.stop()
			pieza.queue_free()
	_unidades.erase(id)

func bucle(dueno: Node2D, clave: String) -> void:
	if not activo or _bucles.has(dueno.get_instance_id()):
		return
	var voz := _crear(clave, dueno.global_position, -21.0, BUS_EFECTOS)
	if voz == null:
		return
	_bucles[dueno.get_instance_id()] = {"ref": weakref(dueno), "voz": voz, "clave": clave}
	voz.play()
	dueno.tree_exiting.connect(detener_bucle.bind(dueno.get_instance_id()), CONNECT_ONE_SHOT)

func detener_bucle(id: int) -> void:
	if _bucles.has(id):
		var voz: Node = _bucles[id]["voz"]
		voz.stop()
		voz.queue_free()
		_bucles.erase(id)

func _process(delta: float) -> void:
	_atenuacion = maxf(0.0, _atenuacion - delta)
	var bus := AudioServer.get_bus_index(BUS_MECANISMOS)
	AudioServer.set_bus_volume_db(bus, lerpf(AudioServer.get_bus_volume_db(bus), -7.0 if _atenuacion > 0.0 else 0.0, 1.0 - exp(-delta / 0.1)))
	for id: int in _unidades.keys():
		var estado: Dictionary = _unidades[id]
		var tanque: Node2D = estado["ref"].get_ref()
		if not is_instance_valid(tanque) or not tanque.is_inside_tree() or tanque.get("_destruido"):
			_liberar_unidad(id)
			continue
		var angulo: float = tanque.visual_tanque.pivote_canon.rotation
		var cambio := absf(angle_difference(estado["angulo"], angulo))
		if not estado["inicio"] and cambio > 0.002:
			estado["engranaje"] = clampf(cambio / maxf(delta, 0.001), 0.25, 1.0)
		else:
			estado["engranaje"] = move_toward(estado["engranaje"], 0.0, delta / 0.12)
		estado["inicio"] = false
		estado["angulo"] = angulo
		estado["mezcla"] = lerpf(estado["mezcla"], clampf(estado["velocidad"] / 160.0, 0.0, 1.0), 1.0 - exp(-delta / 0.15))
		for clave: String in estado["piezas"]:
			var pieza: Node = estado["piezas"][clave]
			if not is_instance_valid(pieza):
				continue
			pieza.position = tanque.global_position
			var fuerza: float = estado["engranaje"] if clave == "engranajes" else estado["mezcla"]
			var db := -30.0 if clave == "engranajes" else -23.0
			if clave == "motor":
				db = lerpf(-33.0, -21.0, fuerza)
				pieza.pitch_scale = lerpf(0.82, 1.06, fuerza)
			else:
				db += linear_to_db(maxf(fuerza, 0.0001))
				pieza.pitch_scale = lerpf(0.85, 1.1, fuerza)
			pieza.volume_db = db
			if db > -65.0 and not pieza.playing:
				pieza.play()
			elif db <= -65.0 and pieza.playing:
				pieza.stop()
	for id: int in _bucles.keys():
		var estado: Dictionary = _bucles[id]
		var dueno: Node2D = estado["ref"].get_ref()
		if not is_instance_valid(dueno) or not dueno.is_inside_tree():
			detener_bucle(id)
			continue
		estado["voz"].position = dueno.global_position
		if estado["clave"] == "bombardeo":
			estado["voz"].volume_db = lerpf(-26.0, -13.0, clampf(dueno.progreso, 0.0, 1.0))
	_limpiar_voces()

func finalizar() -> void:
	if activo:
		get_node("/root/GestorMusica").finalizar_mision()
	_detener_selector()
	activo = false
	for id: int in _unidades.keys():
		_liberar_unidad(id)
	for id: int in _bucles.keys():
		detener_bucle(id)
	for voz in _voces:
		if is_instance_valid(voz) and voz.bus == BUS_AVISOS:
			voz.stop()
			voz.queue_free()

func detener_todo() -> void:
	finalizar()
	_generacion += 1
	for voz in _voces:
		if is_instance_valid(voz):
			voz.stop()
			voz.queue_free()
	_voces.clear()
	_atenuacion = 0.0

## Una sola voz centrada, independiente del cupo y atenuación del combate.
func interfaz(tipo: String, municion := "") -> void:
	if not activo or get_tree().paused or interfaz_abierta:
		return
	var clave := "selector_" + (municion if tipo == "seleccion" else tipo)
	if clave not in CATALOGO.SELECTOR or tipo not in ["abrir", "cerrar", "seleccion"]:
		return
	_selector_pendiente = {"clave":clave, "tipo":tipo, "municion":municion}
	if is_instance_valid(_voz_selector) and _voz_selector.playing:
		if is_instance_valid(_fundido_selector) and _fundido_selector.is_running():
			return # La petición más reciente reemplaza a las intermedias.
		_fundido_selector = create_tween()
		_fundido_selector.tween_property(_voz_selector, "volume_db", -80.0, 0.015)
		_fundido_selector.tween_callback(_iniciar_selector)
	else:
		_iniciar_selector()

func _iniciar_selector() -> void:
	if not activo or _selector_pendiente.is_empty():
		return
	var peticion := _selector_pendiente.duplicate()
	_selector_pendiente.clear()
	var recurso := _recurso(peticion.clave)
	if recurso == null:
		return
	if not is_instance_valid(_voz_selector):
		_voz_selector = AudioStreamPlayer.new()
		_voz_selector.bus = BUS_EFECTOS
		add_child(_voz_selector)
	_voz_selector.stop()
	_voz_selector.stream = recurso
	_voz_selector.volume_db = -18.0 if peticion.tipo == "seleccion" else -24.0
	_voz_selector.play()
	selector_reproducido.emit(peticion.tipo, peticion.municion)

func _detener_selector() -> void:
	if is_instance_valid(_fundido_selector):
		_fundido_selector.kill()
	_selector_pendiente.clear()
	if is_instance_valid(_voz_selector):
		_voz_selector.stop()
		_voz_selector.queue_free()
		_voz_selector = null
