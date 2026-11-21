extends Control
## Menú modal; solo sus controles procesan durante la pausa.
signal pausa_solicitada(valor: bool)
signal abandono_solicitado
const ESTILO = preload("res://Vistas/UI/EstiloInforme.gd")
var desde_menu := false
var boton: Button
var panel: ColorRect
var contenido: Control
var paginas: Dictionary = {}
var controles: Dictionary = {}
var error_guardado: Label
var reintentar: Button
var pagina := "principal"
var saliendo := false
var _bloquear_disparo := false
var _ultimo_canal := "efectos"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 90
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = ESTILO.tema()
	boton = ESTILO.boton(self, "BotonSonido", "Sonido" if desde_menu else "Menú / Pausa", Rect2(32,640,155,45) if desde_menu else Rect2(16,294,170,40))
	boton.pressed.connect(func() -> void: abrir(true))
	panel = ColorRect.new()
	panel.color = Color(0.05,0.04,0.03,0.85)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	panel.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenido = Control.new()
	contenido.custom_minimum_size = Vector2(1120,620)
	centro.add_child(contenido)
	ESTILO.decorar(contenido)
	ESTILO.etiqueta(contenido,"Titulo","Sonido" if desde_menu else "MISIÓN EN PAUSA",Rect2(80,40,960,50),32)
	ESTILO.etiqueta(contenido,"Mision","" if desde_menu else get_node("/root/GestorMisiones").obtener_mision_actual().nombre,Rect2(80,98,960,40),24)
	for nombre in ["principal","sonido","confirmar"]:
		var p := Control.new()
		ESTILO.situar(p,contenido,nombre,Rect2(80,160,960,410))
		paginas[nombre] = p
	_accion("principal","Continuar",40,func() -> void: abrir(false))
	_accion("principal","Sonido",120,func() -> void: mostrar_pagina("sonido"))
	_accion("principal","Volver a misiones",200,func() -> void: mostrar_pagina("confirmar"))
	ESTILO.etiqueta(paginas.confirmar,"Aviso","¿Abandonar la misión? Perderás el avance de esta partida y no recibirás monedas. Conservarás tu saldo, compras y progreso anterior.",Rect2(90,20,780,130),24)
	_accion("confirmar","Seguir jugando",190,func() -> void: mostrar_pagina("principal"))
	_accion("confirmar","Abandonar misión",270,_abandonar)
	for i in 4:
		var canal: String = ["efectos","avisos","videos","musica"][i]
		var y := float(i * 63)
		ESTILO.etiqueta(paginas.sonido,"Etiqueta"+canal,["Efectos","Avisos","Introducciones y videos","Música"][i],Rect2(20,y,300,32),22)
		var slider := HSlider.new()
		slider.max_value = 100
		slider.step = 1
		slider.value = get_node("/root/GestorAudioPartida").preferencias[canal] * 100
		ESTILO.situar(slider,paginas.sonido,"Volumen"+canal,Rect2(330,y,330,36))
		slider.mouse_filter = Control.MOUSE_FILTER_STOP
		var porcentaje := ESTILO.etiqueta(paginas.sonido,"Valor"+canal,"%d %%" % slider.value,Rect2(680,y,70,34),22)
		var silencio := CheckButton.new()
		silencio.text = "Silenciar"
		silencio.button_pressed = get_node("/root/GestorAudioPartida").preferencias["silencio_"+canal]
		ESTILO.situar(silencio,paginas.sonido,"Silencio"+canal,Rect2(770,y,170,36))
		controles[canal] = {"slider":slider,"silencio":silencio,"porcentaje":porcentaje}
		slider.value_changed.connect(func(_v: float) -> void: _cambiar(canal))
		silencio.toggled.connect(func(_v: bool) -> void: _cambiar(canal))
	error_guardado = ESTILO.etiqueta(paginas.sonido,"Error","No se guardaron los ajustes.",Rect2(20,265,530,32),20)
	reintentar = ESTILO.boton(paginas.sonido,"Reintentar","Reintentar",Rect2(580,260,200,40))
	reintentar.pressed.connect(func() -> void: _cambiar(_ultimo_canal))
	error_guardado.hide()
	reintentar.hide()
	_accion("sonido","Volver",330,_volver_de_sonido)
	panel.hide()
	add_to_group("panel_sonido")

func _volver_de_sonido() -> void:
	if desde_menu:
		abrir(false)
	else:
		mostrar_pagina("principal")

func _accion(seccion: String, texto: String, y: float, accion: Callable) -> void:
	var control := ESTILO.boton(paginas[seccion],texto.replace(" ",""),texto,Rect2(280,y,400,54))
	control.pressed.connect(accion)

func mostrar_pagina(nombre: String) -> void:
	pagina = nombre
	for clave in paginas:
		paginas[clave].visible = clave == nombre
	_configurar_foco(true)

func _configurar_foco(enfocar: bool) -> void:
	var focos: Array[Control] = []
	for control in paginas[pagina].get_children():
		if control is Control and control.visible and control.focus_mode == Control.FOCUS_ALL:
			focos.append(control)
	for i in focos.size():
		var anterior := focos[i].get_path_to(focos[(i-1+focos.size()) % focos.size()])
		var siguiente := focos[i].get_path_to(focos[(i+1) % focos.size()])
		focos[i].focus_previous = anterior
		focos[i].focus_next = siguiente
		focos[i].focus_neighbor_top = anterior
		focos[i].focus_neighbor_bottom = siguiente
	if enfocar and not focos.is_empty():
		focos[0].grab_focus()

func _cambiar(canal: String) -> void:
	_ultimo_canal = canal
	var c: Dictionary = controles[canal]
	c.porcentaje.text = "%d %%" % c.slider.value
	var resultado: Error = get_node("/root/GestorAudioPartida").configurar_volumen(canal,c.slider.value/100.0,c.silencio.button_pressed)
	error_guardado.visible = resultado != OK
	reintentar.visible = resultado != OK
	_configurar_foco(false)

func abrir(valor: bool) -> void:
	if desde_menu:
		panel.visible = valor
		if valor:
			mostrar_pagina("sonido")
		else:
			boton.grab_focus()
		return
	if saliendo or (valor and not get_node("/root/GestorAudioPartida").activo):
		return
	panel.visible = valor
	get_node("/root/GestorAudioPartida").interfaz_abierta = valor
	pausa_solicitada.emit(valor)
	if valor:
		mostrar_pagina("principal")
	else:
		_bloquear_disparo = true
		get_viewport().gui_release_focus()

func _abandonar() -> void:
	if saliendo:
		return
	saliendo = true
	abandono_solicitado.emit()

func _process(_delta: float) -> void:
	boton.visible = desde_menu or get_node("/root/GestorAudioPartida").activo
	if _bloquear_disparo and not Input.is_action_pressed("Disparo"):
		_bloquear_disparo = false

func _input(evento: InputEvent) -> void:
	if _bloquear_disparo and evento.is_action("Disparo"):
		get_viewport().set_input_as_handled()
		return
	if desde_menu:
		if panel.visible and evento.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			abrir(false)
		return
	if not get_node("/root/GestorAudioPartida").activo:
		return
	if evento is InputEventKey and evento.pressed and evento.keycode in [KEY_ESCAPE, KEY_F8]:
		get_viewport().set_input_as_handled()
		if evento.echo:
			return
		if panel.visible and pagina != "principal":
			mostrar_pagina("principal")
		else:
			abrir(not panel.visible)

func _exit_tree() -> void:
	if desde_menu:
		return
	get_tree().paused = false
	get_node("/root/GestorAudioPartida").interfaz_abierta = false
