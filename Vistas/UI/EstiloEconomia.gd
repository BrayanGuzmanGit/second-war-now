extends RefCounted
class_name EstiloEconomia

const ORO := Color("#e1bd72")
const CLARO := Color("#f2eadb")

static func caja(color: Color, borde: Color = Color("#53627a")) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_border_width_all(1)
	estilo.border_color = borde
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	return estilo

static func crear_tema() -> Theme:
	var tema := Theme.new()
	tema.default_font = load("res://Vistas/Recursos/Fuentes/Oswald-Variable.ttf")
	tema.default_font_size = 20
	tema.set_color("font_color", "Label", CLARO)
	tema.set_color("font_color", "Button", CLARO)
	tema.set_color("font_focus_color", "Button", ORO)
	tema.set_stylebox("normal", "Button", caja(Color("#23354b")))
	tema.set_stylebox("hover", "Button", caja(Color("#344d66"), ORO))
	tema.set_stylebox("pressed", "Button", caja(Color("#415673"), ORO))
	tema.set_stylebox("focus", "Button", caja(Color(0, 0, 0, 0), ORO))
	tema.set_stylebox("disabled", "Button", caja(Color("#202935")))
	tema.set_color("font_disabled_color", "Button", Color("#85909c"))
	tema.set_stylebox("panel", "PanelContainer", caja(Color("#152235")))
	tema.set_stylebox("panel", "TabContainer", caja(Color("#101b2b")))
	tema.set_stylebox("tab_selected", "TabContainer", caja(Color("#344d66"), ORO))
	tema.set_stylebox("tab_unselected", "TabContainer", caja(Color("#1b2a3e")))
	tema.set_color("font_selected_color", "TabContainer", ORO)
	tema.set_color("font_unselected_color", "TabContainer", CLARO)
	return tema
