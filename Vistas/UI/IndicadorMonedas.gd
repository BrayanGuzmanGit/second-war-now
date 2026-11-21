extends PanelContainer

var _saldo: Label

func _ready() -> void:
	name = "IndicadorMonedas"
	theme = preload("res://Vistas/UI/EstiloEconomia.gd").crear_tema()
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -340
	offset_right = -22
	offset_top = 18
	offset_bottom = 68
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_saldo = Label.new()
	add_child(_saldo)
	_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saldo.add_theme_color_override("font_color", Color("#e1bd72"))
	var guardado: Node = get_tree().root.get_node("GestorGuardado")
	guardado.saldo_actualizado.connect(_actualizar)
	_actualizar(guardado.obtener_saldo())
	if not guardado.aviso_guardado.is_empty():
		var aviso := AcceptDialog.new()
		aviso.title = "Estado del guardado"
		aviso.dialog_text = guardado.aviso_guardado
		add_child(aviso)
		aviso.call_deferred("popup_centered", Vector2i(520, 160))

func _actualizar(saldo: int) -> void:
	_saldo.text = "MONEDAS  ·  %d" % saldo
