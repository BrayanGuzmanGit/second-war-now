extends RefCounted

## Recortes del arte existente: papel limpio y borde exterior, sin rótulos impresos.
const ARTE = preload("res://Gemini_Generated_Image_eio3aseio3aseio3.jpeg")
const FUENTE = preload("res://Vistas/Recursos/Fuentes/Oswald-Variable.ttf")
const TINTA := Color("#35291b")
const BRONCE := Color("#896039")

static func caja(color: Color, borde: Color = BRONCE, grosor: int = 2) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(6)
	return estilo

static func tema() -> Theme:
	var t := Theme.new()
	t.default_font = FUENTE
	t.default_font_size = 22
	t.set_color("font_color", "Label", TINTA)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(estado, "Button", TINTA)
	t.set_color("font_disabled_color", "Button", Color("#786e5d"))
	t.set_stylebox("normal", "Button", caja(Color("#cfb58b")))
	t.set_stylebox("hover", "Button", caja(Color("#eed9aa")))
	t.set_stylebox("pressed", "Button", caja(Color("#bca074")))
	t.set_stylebox("disabled", "Button", caja(Color("#bcb09a")))
	t.set_stylebox("focus", "Button", caja(Color.TRANSPARENT, Color("#5a391c"), 4))
	return t

static func situar(nodo: Control, padre: Node, nombre: String, rect: Rect2) -> void:
	nodo.name = nombre
	padre.add_child(nodo)
	nodo.position = rect.position
	nodo.size = rect.size
	# Label recalcula su mínimo al recibir el ancho; aplicar después el alto reservado.
	nodo.set_deferred("size", rect.size)
	if not nodo is Button:
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func etiqueta(padre: Node, nombre: String, texto: String, rect: Rect2, tamano: int = 22) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", tamano)
	situar(label, padre, nombre, rect)
	# Medir el texto con su ancho definitivo, no con el ancho cero inicial.
	label.text = texto
	return label

static func boton(padre: Node, nombre: String, texto: String, rect: Rect2) -> Button:
	var control := Button.new()
	control.text = texto
	situar(control, padre, nombre, rect)
	return control

static func decorar(panel: Control) -> void:
	var papel := TextureRect.new()
	var recorte := AtlasTexture.new()
	recorte.atlas = ARTE
	recorte.region = Rect2(130, 90, 420, 150)
	papel.texture = recorte
	papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	situar(papel, panel, "Papel", Rect2(0,0,1120,620))
	var velo := ColorRect.new()
	velo.color = Color(0.89,0.81,0.65,0.25)
	situar(velo, panel, "Velo", Rect2(0,0,1120,620))
	# El centro queda desactivado: no se dibujan CAMPANA, candados ni botones originales.
	var marco := NinePatchRect.new()
	marco.texture = ARTE
	marco.draw_center = false
	marco.patch_margin_left = 100
	marco.patch_margin_right = 100
	marco.patch_margin_top = 70
	marco.patch_margin_bottom = 70
	situar(marco, panel, "Marco", Rect2(0,0,2240,1240))
	marco.scale = Vector2(0.5,0.5)
	var contenido := panel.get_node_or_null("Contenido")
	if contenido != null:
		contenido.move_to_front()

static func construir(contenido: Control, mision: Dictionary, aviso: String) -> Dictionary:
	contenido.theme = tema()
	etiqueta(contenido, "Rotulo", "INFORME DE MISIÓN", Rect2(46,27,1028,24),18)
	var titulo := etiqueta(contenido, "Titulo", mision["nombre"],Rect2(46,55,1028,52),32)
	var fecha := etiqueta(contenido,"Fecha","%s  ·  %s" % [mision["fecha"], mision["ubicacion"]],Rect2(46,111,1028,28),20)
	var linea := ColorRect.new()
	linea.color = Color("#96764b")
	situar(linea,contenido,"Separador",Rect2(46,150,1028,2))
	var borde := Panel.new()
	borde.add_theme_stylebox_override("panel", caja(Color("#5b4630")))
	situar(borde,contenido,"MarcoEscenario",Rect2(42,172,348,199))
	var imagen := TextureRect.new()
	imagen.texture = load(mision["imagen_informe"])
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	situar(imagen,contenido,"Escenario",Rect2(46,176,340,191))
	var placa := Panel.new()
	placa.add_theme_stylebox_override("panel", caja(Color("#cfb58b")))
	situar(placa,contenido,"PlacaOperacion",Rect2(46,389,340,44))
	var operacion := etiqueta(contenido,"Operacion",mision["operacion"],Rect2(52,394,328,34),22)
	operacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var repetir := boton(contenido,"Repetir","Ver introducción",Rect2(46,455,340,48))
	var disponibilidad := etiqueta(contenido,"Disponibilidad","",Rect2(46,507,340,30),16)
	etiqueta(contenido,"EncabezadoHistoria","CONTEXTO HISTÓRICO",Rect2(418,164,650,28),22)
	var contexto := etiqueta(contenido,"Contexto",mision["contexto_historico"],Rect2(418,201,650,94),22)
	contexto.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var revelar := boton(contenido,"Revelar","Mostrar texto completo",Rect2(418,300,250,32))
	revelar.add_theme_font_size_override("font_size",18)
	etiqueta(contenido,"EncabezadoObjetivos","OBJETIVOS",Rect2(418,340,650,28),22)
	var pasos: Array[Label] = []
	for i in mision["objetivos_informe"].size():
		pasos.append(etiqueta(contenido,"Objetivo%d" % i, "%d.  %s" % [i+1,mision["objetivos_informe"][i]],Rect2(418,376+i*30,650,30),22))
	var aviso_label: Label
	if not aviso.is_empty():
		var fondo := Panel.new()
		fondo.add_theme_stylebox_override("panel", caja(Color("#dfc48d"),Color("#a67635")))
		situar(fondo,contenido,"PlacaAviso",Rect2(412,474,662,66))
		aviso_label = etiqueta(contenido,"Aviso",aviso,Rect2(424,480,638,54),19)
	var volver := boton(contenido,"Volver","Volver a misiones",Rect2(46,554,270,46))
	var continuar := boton(contenido,"Continuar","COMENZAR MISIÓN  →",Rect2(758,550,316,50))
	continuar.add_theme_stylebox_override("normal",caja(Color("#dfbb70"),Color("#6b4924"),3))
	return {"titulo":titulo,"fecha":fecha,"contexto":contexto,"revelar":revelar,"repetir":repetir,"volver":volver,"continuar":continuar,"disponibilidad":disponibilidad,"imagen":imagen,"pasos":pasos,"aviso":aviso_label}
