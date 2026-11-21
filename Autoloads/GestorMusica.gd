extends Node
## Dos voces persistentes. La pausa del árbol congela voces y envolventes juntas.
const PISTAS := ["menu", "tienda", "francia", "alamein", "berlin"]
var contexto := ""
var voces: Array[AudioStreamPlayer] = []
var activa := 0
var _ganancias := [0.0, 0.0]
var _inicio := [0.0, 0.0]
var _destino := [0.0, 0.0]
var _fundido := 1.0
var _marca_menu := 0.0
var _aviso := 0.0
var _cuenta := false
var _reduccion := 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	for i in 2:
		var voz := AudioStreamPlayer.new()
		add_child(voz)
		voz.bus = "Musica"
		voces.append(voz)
	get_node("/root/GestorAudioPartida").evento_reproducido.connect(_al_evento)

func solicitar(nuevo: String) -> void:
	if nuevo == contexto:
		return
	var pista := "menu" if nuevo == "informe" else nuevo
	if pista not in PISTAS:
		push_error("Contexto musical desconocido: " + nuevo)
		return
	var anterior := "menu" if contexto == "informe" else contexto
	if anterior == "menu":
		_marca_menu = voces[activa].get_playback_position()
	if anterior != pista:
		var recurso := load("res://Vistas/Recursos/Musica/%s.ogg" % pista) as AudioStreamOggVorbis
		if recurso == null:
			silenciar()
			return
		activa = 1 - activa
		var voz := voces[activa]
		# Al invertir un fundido rápido, recuperar la voz que todavía está sonando.
		if not voz.playing or voz.stream != recurso or pista not in ["menu", "tienda"]:
			voz.stop()
			recurso.loop = true
			voz.stream = recurso
			voz.volume_linear = 0.0
			_ganancias[activa] = 0.0
			voz.play(fmod(_marca_menu, recurso.get_length()) if pista == "menu" else 0.0)
	contexto = nuevo
	_aviso = 0.0
	_cuenta = false
	_destino.fill(0.0)
	_destino[activa] = db_to_linear(-7.0 if nuevo == "informe" else (-4.0 if pista in ["francia","alamein","berlin"] else 0.0))
	_iniciar_fundido()

func _iniciar_fundido() -> void:
	_inicio = _ganancias.duplicate()
	_fundido = 0.0

func finalizar_mision() -> void:
	if contexto in ["francia","alamein","berlin"]:
		contexto = ""
		_cuenta = false
		_destino.fill(0.0)
		_iniciar_fundido()

func silenciar() -> void:
	if contexto in ["menu","informe"]:
		_marca_menu = voces[activa].get_playback_position()
	contexto = ""
	for voz in voces:
		voz.stop()
	_ganancias.fill(0.0)
	_destino.fill(0.0)
	_inicio.fill(0.0)
	_fundido = 1.0
	_reduccion = 0.0
	_aviso = 0.0
	_cuenta = false

func _al_evento(tipo: String, _material: String) -> void:
	if not contexto in ["francia","alamein","berlin"]:
		return
	if tipo == "cuenta":
		_cuenta = true
	if tipo == "refuerzos":
		_cuenta = false
	if tipo in ["turno_jugador","turno_enemigo","evacuacion","refuerzos"]:
		_aviso = 0.55

func _process(delta: float) -> void:
	if contexto.is_empty() and _fundido >= 1.0:
		return
	_fundido = minf(1.0, _fundido + delta)
	_aviso = maxf(0.0, _aviso - delta)
	var objetivo := -4.0 if _cuenta or _aviso > 0.0 else 0.0
	_reduccion = move_toward(_reduccion, objetivo, delta * (50.0 if objetivo < _reduccion else 12.0))
	for i in 2:
		_ganancias[i] = lerpf(_inicio[i], _destino[i], smoothstep(0.0, 1.0, _fundido))
		voces[i].volume_linear = float(_ganancias[i]) * db_to_linear(_reduccion)
		if _fundido >= 1.0 and _destino[i] == 0.0 and voces[i].playing:
			voces[i].stop()
