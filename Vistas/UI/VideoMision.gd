extends CanvasLayer
class_name VideoMision

## Capa modal compartida: reproduce la voz original y libera el audio al cerrar.
signal finalizado

var reproductor: VideoStreamPlayer
var _cerrado := false
var _tiempo := 0.0
var _boton: Button

static func mostrar(padre: Node, ruta: String) -> VideoMision:
	if ruta.is_empty():
		return null
	if not ResourceLoader.exists(ruta):
		push_warning("Video de misión no disponible; se muestra el panel: " + ruta)
		return null
	var video := VideoMision.new()
	padre.add_child(video)
	if not video._reproducir(ruta):
		video.queue_free()
		return null
	return video

func _reproducir(ruta: String) -> bool:
	var recurso := load(ruta) as VideoStream
	if recurso == null:
		push_warning("No se pudo cargar el video de misión: " + ruta)
		return false
	get_node("/root/GestorMusica").silenciar()
	layer = 100
	get_node("/root/GestorAudioPartida").detener_todo()
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	# AspectRatioContainer conserva la imagen completa al redimensionar la ventana.
	var encuadre := AspectRatioContainer.new()
	encuadre.ratio = 16.0 / 9.0
	encuadre.stretch_mode = AspectRatioContainer.STRETCH_FIT
	encuadre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(encuadre)
	reproductor = VideoStreamPlayer.new()
	reproductor.bus = "Videos"
	reproductor.expand = true
	reproductor.stream = recurso
	reproductor.loop = false
	reproductor.volume_db = 0.0
	encuadre.add_child(reproductor)
	reproductor.finished.connect(cerrar)
	_boton = Button.new()
	_boton.text = "Omitir video · Esc"
	_boton.theme = preload("res://Vistas/UI/EstiloEconomia.gd").crear_tema()
	_boton.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_boton.offset_left = -240
	_boton.offset_top = -64
	_boton.offset_right = -20
	_boton.offset_bottom = -16
	add_child(_boton)
	_boton.pressed.connect(cerrar)
	_boton.grab_focus()
	reproductor.play()
	return true

func _process(delta: float) -> void:
	_tiempo += delta
	# Recuperación si falla el decodificador: el usuario nunca queda encerrado.
	if _tiempo > 30.0 or (_tiempo > 1.0 and not reproductor.is_playing()):
		cerrar()

func _input(event: InputEvent) -> void:
	if _cerrado:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and _tiempo > 0.25:
			get_viewport().set_input_as_handled()
			cerrar()
	elif event is InputEventMouseButton:
		# El botón recibe el clic; el resto de la capa modal lo absorbe.
		pass

func cerrar() -> void:
	if _cerrado:
		return
	_cerrado = true
	reproductor.stop()
	finalizado.emit()
	queue_free()

func _exit_tree() -> void:
	if reproductor != null:
		reproductor.stop()
