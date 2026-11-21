extends ColorRect
## Informe de cierre: recompensa transaccional y aprendizaje en espacios separados.
const ESTILO = preload("res://Vistas/UI/EstiloInforme.gd")
var contenido: Control
var titulo: Label
var fecha: Label
var logro: Label
var total: Label
var recompensa: Label
var estado: Label
var resumen: RichTextLabel
var historia: Button
var recordar: Button
var respuesta: Button
var reintentar: Button
var volver: Button
var pista: Label
var _mision: Dictionary
var _datos: Dictionary
var _victoria := false
var _resumen_original := ""
var _pagina := 0
var _respuesta_visible := false
var _frame_apertura := -1
var _teclas_pendientes: Array[int] = []

func _ready() -> void:
	contenido = Control.new()
	contenido.name = "Contenido"
	contenido.custom_minimum_size = Vector2(1120, 620)
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Centro.add_child(contenido)
	# EstiloInforme conserva el arte del selector y solo dibuja papel y bordes limpios.
	ESTILO.decorar(contenido)
	contenido.theme = ESTILO.tema()
	ESTILO.etiqueta(contenido, "Resultado", "MISIÓN COMPLETADA", Rect2(46,25,1028,26),18)
	titulo = ESTILO.etiqueta(contenido, "Titulo", "", Rect2(46,57,1028,46),32)
	fecha = ESTILO.etiqueta(contenido, "Fecha", "", Rect2(46,111,1028,27),19)
	var separador := ColorRect.new()
	separador.color = Color("96764b")
	ESTILO.situar(separador, contenido, "Separador", Rect2(46,145,1028,2))
	var marco := Panel.new()
	marco.add_theme_stylebox_override("panel", ESTILO.caja(Color("5b4630")))
	ESTILO.situar(marco, contenido, "MarcoEscenario", Rect2(42,158,338,194))
	var imagen := TextureRect.new()
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ESTILO.situar(imagen, contenido, "Escenario", Rect2(46,162,330,186))
	logro = ESTILO.etiqueta(contenido, "Logro", "", Rect2(46,354,330,30),18)
	var placa := Panel.new()
	placa.add_theme_stylebox_override("panel", ESTILO.caja(Color("ddc79c")))
	ESTILO.situar(placa, contenido, "PlacaRecompensa", Rect2(46,390,330,150))
	ESTILO.etiqueta(contenido, "RotuloRecompensa", "MONEDAS GANADAS", Rect2(60,398,300,23),16)
	total = ESTILO.etiqueta(contenido, "Total", "+0", Rect2(60,420,300,48),38)
	total.add_theme_color_override("font_color", Color("4b512d"))
	recompensa = ESTILO.etiqueta(contenido, "Recompensa", "", Rect2(60,472,300,62),17)
	historia = ESTILO.boton(contenido, "Historia", "Hechos y significado", Rect2(416,160,314,43))
	recordar = ESTILO.boton(contenido, "Recordar", "Para recordar", Rect2(744,160,330,43))
	var papel := Panel.new()
	papel.add_theme_stylebox_override("panel", ESTILO.caja(Color(0.97,0.91,0.79,0.75),Color("b39a70"),1))
	ESTILO.situar(papel, contenido, "PapelHistoria", Rect2(410,214,670,290))
	resumen = RichTextLabel.new()
	resumen.bbcode_enabled = true
	resumen.scroll_active = true
	resumen.selection_enabled = true
	resumen.focus_mode = Control.FOCUS_ALL
	resumen.add_theme_color_override("default_color", ESTILO.TINTA)
	resumen.add_theme_color_override("font_selected_color", Color.WHITE)
	resumen.add_theme_color_override("selection_color", Color("695131"))
	resumen.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	resumen.add_theme_constant_override("outline_size", 0)
	resumen.add_theme_constant_override("normal_outline_size", 0)
	resumen.add_theme_font_size_override("normal_font_size", 21)
	resumen.add_theme_font_size_override("bold_font_size", 22)
	resumen.add_theme_stylebox_override("focus", ESTILO.caja(Color.TRANSPARENT,Color("896039"),2))
	ESTILO.situar(resumen, contenido, "Resumen", Rect2(424,224,642,268))
	resumen.mouse_filter = Control.MOUSE_FILTER_STOP
	resumen.meta_clicked.connect(_abrir_fuente)
	pista = ESTILO.etiqueta(contenido, "Pista", "Desplázate para leer el informe completo · rueda o flechas", Rect2(416,509,658,25),16)
	respuesta = ESTILO.boton(contenido, "Respuesta", "Ver explicación", Rect2(416,506,228,34))
	respuesta.add_theme_font_size_override("font_size",18)
	respuesta.hide()
	reintentar = ESTILO.boton(contenido, "ReintentarGuardado", "Reintentar guardado", Rect2(46,557,270,44))
	reintentar.hide()
	estado = ESTILO.etiqueta(contenido, "EstadoGuardado", "", Rect2(332,553,440,48),17)
	volver = ESTILO.boton(contenido, "BotonMenu", "VOLVER A MISIONES  →", Rect2(804,553,270,48))
	volver.add_theme_stylebox_override("normal",ESTILO.caja(Color("dfbb70"),Color("6b4924"),3))
	historia.pressed.connect(func() -> void: _seleccionar_pagina(0))
	recordar.pressed.connect(func() -> void: _seleccionar_pagina(1))
	respuesta.pressed.connect(func() -> void:
		_respuesta_visible = not _respuesta_visible
		_actualizar_lectura()
		if _respuesta_visible:
			var parrafo := resumen.text.get_slice("[b]PARA PENSAR", 0).count("\n")
			resumen.call_deferred("scroll_to_paragraph", parrafo)
	)
	visibility_changed.connect(_al_cambiar_visibilidad)
	_configurar_foco()

func mostrar(victoria: bool, texto: String, guardado: bool, mision: Dictionary) -> void:
	if _mision.is_empty():
		_mision = mision
		_datos = mision.get("cierre_educativo", {})
	_victoria = victoria
	_resumen_original = texto
	contenido.get_node("Resultado").text = "MISIÓN COMPLETADA" if victoria else "MISIÓN FALLIDA"
	titulo.text = mision["nombre"]
	fecha.text = "%s  ·  %s" % [mision["fecha"], mision["ubicacion"]]
	contenido.get_node("Escenario").texture = load(mision["imagen_informe"])
	logro.text = _datos.get("logro", "Objetivo alcanzado") if victoria else "El objetivo de la partida no se completó"
	_actualizar_lectura()
	_estado_guardado(guardado)
	show()

func _seccion(encabezado: String, texto: String) -> String:
	return "[b]" + encabezado + "[/b]\n" + texto + "\n\n"

func _actualizar_lectura() -> void:
	historia.add_theme_stylebox_override("normal", ESTILO.caja(Color("dfbb70") if _pagina == 0 else Color("cfb58b")))
	recordar.add_theme_stylebox_override("normal", ESTILO.caja(Color("dfbb70") if _pagina == 1 else Color("cfb58b")))
	respuesta.visible = _pagina == 1 and not _datos.is_empty()
	pista.visible = not respuesta.visible
	var texto := ""
	if _pagina == 0:
		if not _victoria:
			texto += _seccion("TU PARTIDA", _resumen_original)
		texto += _seccion("QUÉ OCURRIÓ", _datos.get("hechos", _resumen_original))
		texto += _seccion("POR QUÉ IMPORTÓ", _datos.get("importancia", ""))
		texto += _seccion("EL COSTE HUMANO", _datos.get("personas", ""))
		if _victoria and _mision.get("id", "") == "berlin":
			texto += _seccion("CIERRE DE CAMPAÑA", _mision.get("epilogo", ""))
	else:
		texto += _seccion("IDEA CLAVE", _datos.get("idea", ""))
		texto += _seccion("UBÍCATE EN EL TIEMPO", "\n".join(_datos.get("hitos", [])))
		texto += _seccion("PARA PENSAR", _datos.get("pregunta", ""))
		if _respuesta_visible:
			texto += _seccion("EXPLICACIÓN", _datos.get("respuesta", ""))
		texto += _seccion("EL JUEGO Y LA HISTORIA", "Esta misión es una representación simplificada. Los vehículos, tiempos y combates se adaptan al juego. Tu resultado y las monedas no cambian los hechos históricos.")
		texto += "[b]FUENTES PARA SEGUIR APRENDIENDO[/b]\n"
		for fuente: Dictionary in _datos.get("fuentes", []):
			texto += "[url=%s]%s[/url]\n" % [fuente["url"], fuente["nombre"]]
	if resumen.text != texto.strip_edges():
		resumen.text = texto.strip_edges()
	respuesta.text = "Ocultar explicación" if _respuesta_visible else "Ver explicación"
	_configurar_foco()

func _seleccionar_pagina(indice: int) -> void:
	_pagina = indice
	_actualizar_lectura()
	resumen.scroll_to_line(0)

func actualizar_recompensa(resultado: Dictionary) -> void:
	var correcto: bool = resultado.get("ok", false)
	_estado_guardado(correcto)
	if not correcto:
		total.text = "PENDIENTE"
		total.add_theme_font_size_override("font_size",30)
		recompensa.text = "Sin acreditar. Reintenta el guardado.\nSALDO CONSERVADO: %d" % resultado.get("saldo",0)
		return
	total.add_theme_font_size_override("font_size",38)
	total.text = "+%d" % resultado.get("importe",0)
	if _victoria:
		recompensa.text = "Victoria: +%d  ·  Primer triunfo: +%d\nSALDO ACTUAL: %d monedas" % [resultado.get("base",0),resultado.get("bono",0),resultado.get("saldo",0)]
	else:
		recompensa.text = "Defensas destruidas: +%d\nSALDO ACTUAL: %d monedas" % [resultado.get("defensas",0),resultado.get("saldo",0)]

func _estado_guardado(correcto: bool) -> void:
	reintentar.visible = not correcto
	estado.text = "Progreso y monedas guardados" if correcto else "No se pudo guardar. La recompensa sigue pendiente."
	_configurar_foco()

func _configurar_foco() -> void:
	if not is_instance_valid(volver):
		return
	var lista: Array[Control] = [historia, recordar, resumen]
	if respuesta.visible:
		lista.append(respuesta)
	if reintentar.visible:
		lista.append(reintentar)
	lista.append(volver)
	for i in lista.size():
		var control := lista[i]
		control.focus_next = control.get_path_to(lista[(i + 1) % lista.size()])
		control.focus_previous = control.get_path_to(lista[(i - 1 + lista.size()) % lista.size()])
		control.focus_neighbor_left = control.focus_previous
		control.focus_neighbor_right = control.focus_next
		if control != resumen:
			control.focus_neighbor_bottom = control.focus_next
			control.focus_neighbor_top = control.focus_previous

func _al_cambiar_visibilidad() -> void:
	if not visible:
		return
	_frame_apertura = Engine.get_process_frames()
	_teclas_pendientes.clear()
	for tecla in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
		if Input.is_key_pressed(tecla):
			_teclas_pendientes.append(tecla)
	# El primer foco invita a leer; volver siempre requiere una nueva acción.
	_enfocar_informe.call_deferred()

func _enfocar_informe() -> void:
	if is_inside_tree() and is_visible_in_tree():
		historia.grab_focus()

func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree() or not evento is InputEventKey:
		return
	if evento.keycode in _teclas_pendientes or Engine.get_process_frames() <= _frame_apertura:
		if not evento.pressed:
			_teclas_pendientes.erase(evento.keycode)
		get_viewport().set_input_as_handled()
	elif evento.echo and evento.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()

func _abrir_fuente(meta: Variant) -> void:
	# Solo abre enlaces verificados del catálogo cuando el usuario los pulsa.
	for fuente: Dictionary in _datos.get("fuentes", []):
		if str(meta) == fuente["url"]:
			OS.shell_open(str(meta))
			return
