extends Control

const VISTA = preload("res://Vistas/UI/VistaApariencia.gd")
const ESTILO = preload("res://Vistas/UI/EstiloInforme.gd")
var pestañas: TabContainer
var lista_cosmeticos: VBoxContainer
var etiqueta_estado: Label
var etiqueta_saldo: Label
var vista: Control
var nombre: Label
var pais: Label
var detalle: Label
var accion: Button
var ver_monedas: Button
var reintentar: Button
var confirmacion: ConfirmationDialog
var ofrecer_equipo: ConfirmationDialog
var seleccionado: String
var _pendiente: Dictionary = {}
var _equipar_id := ""
var _ocupado := false
var _origen_dialogo: Control

func _ready() -> void:
	get_node("/root/GestorMusica").solicitar("tienda")
	theme = ESTILO.tema()
	var fondo := ColorRect.new()
	fondo.color = Color("#28251e")
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(1120, 620)
	centro.add_child(panel)
	ESTILO.decorar(panel)
	ESTILO.etiqueta(panel, "Titulo", "Tienda de tanques", Rect2(48, 26, 740, 54), 37)
	_placa(panel, "PlacaSaldo", Rect2(820, 32, 252, 45), Color("#dec596"))
	etiqueta_saldo = ESTILO.etiqueta(panel, "Saldo", "", Rect2(827, 37, 238, 35), 22)
	etiqueta_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GestorGuardado.saldo_actualizado.connect(_actualizar_saldo)
	_actualizar_saldo(GestorGuardado.obtener_saldo())
	pestañas = TabContainer.new()
	ESTILO.situar(pestañas, panel, "Catalogo", Rect2(48, 90, 1024, 431))
	pestañas.mouse_filter = Control.MOUSE_FILTER_STOP
	pestañas.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var tabs := pestañas.get_tab_bar()
	for estado in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var color := Color("#dfbe81") if estado == "tab_selected" else Color("#cbb58f")
		var caja := ESTILO.caja(color)
		caja.content_margin_left = 23
		caja.content_margin_right = 23
		pestañas.add_theme_stylebox_override(estado, caja)
	for estado in ["font_selected_color", "font_unselected_color", "font_hovered_color"]:
		pestañas.add_theme_color_override(estado, ESTILO.TINTA)
	pestañas.add_theme_stylebox_override("tab_focus", ESTILO.caja(Color.TRANSPARENT, ESTILO.TINTA, 3))
	seleccionado = GestorGuardado.progreso["cosmetico_equipado"]
	_crear_tanques()
	_crear_monedas()
	etiqueta_estado = ESTILO.etiqueta(panel, "Estado", "", Rect2(48, 523, 1024, 30), 18)
	var volver := ESTILO.boton(panel, "Volver", "Volver al menú", Rect2(48, 555, 198, 40))
	volver.pressed.connect(_regresar)
	ver_monedas = ESTILO.boton(panel, "VerMonedas", "Ver paquetes", Rect2(865, 555, 207, 40))
	ver_monedas.pressed.connect(func() -> void:
		pestañas.current_tab = 1
		tabs.grab_focus()
	)
	ver_monedas.hide()
	reintentar = ESTILO.boton(panel, "Reintentar", "Reintentar compra", Rect2(597, 555, 244, 40))
	reintentar.pressed.connect(_ejecutar_compra)
	reintentar.hide()
	pestañas.tab_changed.connect(func(_indice: int) -> void:
		ver_monedas.hide()
		if not reintentar.visible:
			etiqueta_estado.text = ""
	)
	confirmacion = _dialogo("Confirmar compra", "Confirmar", "Cancelar")
	confirmacion.confirmed.connect(_ejecutar_compra)
	confirmacion.canceled.connect(func() -> void: _pendiente = {}; reintentar.hide())
	ofrecer_equipo = _dialogo("Tanque adquirido", "Equipar ahora", "Seguir viendo")
	ofrecer_equipo.confirmed.connect(func() -> void: _equipar(_equipar_id))
	_actualizar_catalogo()
	lista_cosmeticos.get_node(seleccionado).grab_focus()
	etiqueta_estado.text = GestorGuardado.aviso_guardado

func _dialogo(titulo: String, aceptar: String, cancelar: String) -> ConfirmationDialog:
	var dialogo := ConfirmationDialog.new()
	dialogo.title = titulo
	dialogo.theme = theme.duplicate()
	dialogo.theme.set_stylebox("panel", "AcceptDialog", ESTILO.caja(Color("#e7d6b3")))
	dialogo.get_ok_button().text = aceptar
	dialogo.get_cancel_button().text = cancelar
	dialogo.visibility_changed.connect(func() -> void:
		if not dialogo.visible:
			_restaurar_foco.call_deferred()
	)
	add_child(dialogo)
	return dialogo

func _restaurar_foco() -> void:
	if confirmacion.visible or ofrecer_equipo.visible:
		return
	if is_instance_valid(_origen_dialogo) and _origen_dialogo.is_visible_in_tree() and not (_origen_dialogo is Button and _origen_dialogo.disabled):
		_origen_dialogo.grab_focus()
	elif pestañas.current_tab == 0:
		lista_cosmeticos.get_node(seleccionado).grab_focus()

func _actualizar_saldo(saldo: int) -> void:
	etiqueta_saldo.text = "%d monedas" % saldo

func _placa(padre: Control, id: String, rect: Rect2, color: Color) -> void:
	var placa := Panel.new()
	placa.add_theme_stylebox_override("panel", ESTILO.caja(color))
	ESTILO.situar(placa, padre, id, rect)

func _crear_tanques() -> void:
	var pagina := Control.new()
	pagina.name = "Tanques"
	pestañas.add_child(pagina)
	lista_cosmeticos = VBoxContainer.new()
	ESTILO.situar(lista_cosmeticos, pagina, "Lista", Rect2(0, 10, 310, 350))
	lista_cosmeticos.add_theme_constant_override("separation", 6)
	for item in Tienda.obtener_catalogo():
		var id: String = item["id"]
		var fila := Button.new()
		fila.name = id
		fila.custom_minimum_size.y = 64
		lista_cosmeticos.add_child(fila)
		fila.pressed.connect(_seleccionar_cosmetico.bind(id))
		fila.focus_entered.connect(_seleccionar_cosmetico.bind(id))
		var miniatura := VISTA.new()
		ESTILO.situar(miniatura, fila, "Miniatura", Rect2(6, 3, 92, 58))
		miniatura.mostrar(id)
		ESTILO.etiqueta(fila, "Modelo", item["nombre"], Rect2(104, 2, 197, 32), 22)
		ESTILO.etiqueta(fila, "Estado", "", Rect2(105, 33, 195, 25), 16)
	_placa(pagina, "PlacaFicha", Rect2(333, 10, 690, 358), Color("#eadbbd"))
	nombre = ESTILO.etiqueta(pagina, "Modelo", "", Rect2(353, 16, 416, 46), 32)
	pais = ESTILO.etiqueta(pagina, "Pais", "", Rect2(770, 25, 233, 35), 21)
	pais.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vista = VISTA.new()
	ESTILO.situar(vista, pagina, "Ilustracion", Rect2(350, 63, 652, 185))
	detalle = ESTILO.etiqueta(pagina, "Historia", "", Rect2(354, 253, 645, 63), 20)
	accion = ESTILO.boton(pagina, "Accion", "", Rect2(711, 317, 289, 41))
	accion.pressed.connect(_accion_seleccionada)
	ESTILO.etiqueta(pagina, "Leyenda", "Todas las apariencias comparten estadísticas.", Rect2(354, 324, 350, 30), 16)

func _crear_monedas() -> void:
	var pagina := Control.new()
	pagina.name = "Monedas"
	pestañas.add_child(pagina)
	ESTILO.etiqueta(pagina, "Aviso", "Simulación: no se realizará ningún cobro", Rect2(0, 16, 1024, 44), 28)
	var x := 0
	for paquete in Tienda.obtener_paquetes():
		var id: String = paquete["id"]
		_placa(pagina, id, Rect2(x, 78, 328, 246), Color("#deca9e"))
		ESTILO.etiqueta(pagina, id + "Nombre", "Paquete " + str(paquete["nombre"]).to_lower(), Rect2(x + 20, 93, 288, 39), 24)
		ESTILO.etiqueta(pagina, id + "Cantidad", "%d monedas" % paquete["monedas"], Rect2(x + 20, 143, 288, 64), 37)
		ESTILO.etiqueta(pagina, id + "Precio", "Precio ficticio · " + paquete["precio_cop"], Rect2(x + 20, 215, 288, 34), 20)
		var comprar := ESTILO.boton(pagina, id + "Comprar", "Compra simulada", Rect2(x + 20, 260, 288, 44))
		comprar.pressed.connect(_solicitar_paquete.bind(id))
		x += 348
	ESTILO.etiqueta(pagina, "Recompensas", "También puedes ganar monedas jugando las misiones.", Rect2(0, 336, 1024, 35), 20)

func _actualizar_catalogo() -> void:
	for item in Tienda.obtener_catalogo():
		var fila: Button = lista_cosmeticos.get_node(item["id"])
		var estado: String = "Equipado" if item["equipado"] else ("En tu colección" if item["comprado"] else "%d monedas" % item["precio"])
		fila.get_node("Estado").text = estado
		fila.tooltip_text = "%s · %s" % [item["nombre"], estado]
		if item["id"] == seleccionado:
			fila.add_theme_stylebox_override("normal", ESTILO.caja(Color("#e1c38a"), ESTILO.BRONCE, 3))
			nombre.text = item["nombre"]
			pais.text = item["bando"]
			vista.mostrar(seleccionado)
			detalle.text = item["historia"]
			accion.text = "Equipado" if item["equipado"] else ("Equipar" if item["comprado"] else "Comprar por %d monedas" % item["precio"])
			accion.disabled = item["equipado"] or _ocupado
		else:
			fila.remove_theme_stylebox_override("normal")

func _seleccionar_cosmetico(id: String) -> void:
	if seleccionado == id:
		return
	seleccionado = id
	ver_monedas.hide()
	if not reintentar.visible:
		etiqueta_estado.text = ""
	_actualizar_catalogo()


func _accion_seleccionada() -> void:
	if _ocupado or confirmacion.visible:
		return
	for item in Tienda.obtener_catalogo():
		if item["id"] != seleccionado:
			continue
		if item["comprado"]:
			_equipar(seleccionado)
			return
		var saldo := GestorGuardado.obtener_saldo()
		if saldo < int(item["precio"]):
			etiqueta_estado.text = "Te faltan %d monedas. Puedes ganarlas jugando o abrir los paquetes simulados." % (int(item["precio"]) - saldo)
			ver_monedas.show()
			ver_monedas.grab_focus()
			return
		_pendiente = {"tipo": "skin", "id": seleccionado, "operacion": GestorGuardado.nuevo_id_operacion()}
		reintentar.hide()
		confirmacion.dialog_text = "Comprar %s por %d monedas.\nSaldo actual: %d · Saldo restante: %d" % [item["nombre"], item["precio"], saldo, saldo - int(item["precio"])]
		_origen_dialogo = get_viewport().gui_get_focus_owner()
		confirmacion.popup_centered(Vector2i(540, 180))
		return

func _solicitar_paquete(id: String) -> void:
	if _ocupado or confirmacion.visible:
		return
	var paquete: Dictionary = ReglasEconomia.paquete(id)
	_pendiente = {"tipo": "paquete", "id": id, "operacion": GestorGuardado.nuevo_id_operacion()}
	reintentar.hide()
	confirmacion.dialog_text = "Añadir %d monedas · %s (precio ficticio).\nSimulación: no se realizará ningún cobro." % [paquete["monedas"], paquete["precio_cop"]]
	_origen_dialogo = get_viewport().gui_get_focus_owner()
	confirmacion.popup_centered(Vector2i(540, 180))

func _ejecutar_compra() -> void:
	if _ocupado or _pendiente.is_empty():
		return
	confirmacion.hide()
	_ocupado = true
	accion.disabled = true
	var resultado: Dictionary
	if _pendiente["tipo"] == "skin":
		resultado = Tienda.comprar_cosmetico(_pendiente["id"], _pendiente["operacion"])
	else:
		resultado = Tienda.comprar_paquete(_pendiente["id"], _pendiente["operacion"])
	_ocupado = false
	if resultado["ok"]:
		etiqueta_estado.text = "Compra guardada. Saldo: %d monedas." % resultado["saldo"]
		if _pendiente["tipo"] == "skin":
			_equipar_id = _pendiente["id"]
			ofrecer_equipo.dialog_text = CatalogoApariencias.DATOS[_equipar_id]["nombre"] + " ya forma parte de tu colección."
			ofrecer_equipo.popup_centered(Vector2i(480, 170))
		_pendiente = {}
		reintentar.hide()
	else:
		etiqueta_estado.text = "No se completó la compra (%s). Tu saldo no se ha modificado." % resultado["codigo"]
		reintentar.visible = resultado["codigo"] == "error_guardado"
	_actualizar_catalogo()

func _equipar(id: String) -> void:
	etiqueta_estado.text = "Tanque equipado." if Tienda.equipar_cosmetico(id) else "No se pudo guardar el equipamiento. Vuelve a intentarlo."
	_actualizar_catalogo()

func _regresar() -> void:
	get_tree().change_scene_to_file("res://Vistas/UI/MenuPrincipal.tscn")
