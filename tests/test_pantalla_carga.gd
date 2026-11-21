extends SceneTree

var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar_transicion_de_carga")


func _probar_transicion_de_carga() -> void:
	# Verifica el fundido al arte interactivo y que las acciones naveguen a sus escenas reales.
	var recurso := load("res://Vistas/UI/PantallaCarga.tscn") as PackedScene
	if recurso == null:
		push_error("No se pudo cargar la escena de pantalla de carga.")
		quit(1)
		return

	var pantalla := recurso.instantiate()
	root.add_child(pantalla)
	current_scene = pantalla
	if pantalla.reproductor_video.bus != "Videos":
		_fallos += 1
		push_error("La introducción inicial debe utilizar el bus Videos.")
	var menu: MenuPrincipal
	var verifico_aparicion_escalonada := false

	for _indice in range(1800):
		await process_frame
		if (
			not verifico_aparicion_escalonada
			and pantalla.get("_animacion_menu_iniciada")
		):
			menu = pantalla.get_node("MenuPrincipal") as MenuPrincipal
			await create_timer(0.15).timeout
			_verificar(
				menu.boton_jugar.modulate.a > 0.0
				and is_zero_approx(menu.boton_tienda.modulate.a)
				and is_zero_approx(menu.boton_salir.modulate.a),
				"Los botones deben revelarse de forma escalonada, comenzando por seleccionar misión."
			)
			verifico_aparicion_escalonada = true
		if pantalla.get("_transicion_iniciada"):
			break

	if menu == null:
		menu = pantalla.get_node_or_null("MenuPrincipal") as MenuPrincipal
	if menu == null:
		push_error("La pantalla de carga no mostró el menú principal.")
		quit(1)
		return

	_verificar(
		current_scene == pantalla
		and menu.visible
		and menu.fondo.texture != null
		and menu.fondo.texture.resource_path
		== "res://Gemini_Generated_Image_c1mwl4c1mwl4c1mw.jpeg"
		and menu.boton_jugar.visible
		and menu.boton_tienda.visible
		and menu.boton_salir.visible
		and menu.boton_jugar.size.x <= 490.0
		and menu.boton_tienda.size.x <= 490.0
		and menu.boton_salir.size.x <= 220.0
		and menu.boton_jugar.tooltip_text == "Seleccionar misión"
		and menu.boton_tienda.tooltip_text == "Tienda de tanques"
		and menu.boton_salir.tooltip_text == "Salir del juego"
		and not menu.boton_jugar.disabled
		and not menu.boton_tienda.disabled
		and not menu.boton_salir.disabled
		and absf(menu.boton_jugar.global_position.x - menu.boton_tienda.global_position.x) < 1.0
		and absf(
			menu.boton_jugar.get_global_rect().get_center().x
			- menu.boton_salir.get_global_rect().get_center().x
		) < 1.0,
		"El menú debe usar la imagen completa con zonas de interacción ajustadas a sus placas."
	)
	_verificar(
		pantalla.get_node("FotogramaCongelado").visible
		and pantalla.get_node("FotogramaCongelado").texture != null
		and not pantalla.get_node("Video").visible
		and not pantalla.get_node("Video").is_playing()
		and root.get_node("GestorMusica").contexto == "menu"
		and pantalla.get_node("Video").volume_db <= -17.9,
		"El fotograma debe quedar fijo con el tema del menú y el reproductor de video detenido."
	)

	menu.boton_tienda.mouse_entered.emit()
	await create_timer(0.2).timeout
	_verificar(
		menu.boton_tienda.scale.x > 1.02
		and menu.boton_tienda.modulate.b < 1.0,
		"Las zonas transparentes del menú deben conservar el resaltado interactivo."
	)
	menu.boton_tienda.mouse_exited.emit()
	await create_timer(0.2).timeout

	menu.boton_jugar.pressed.emit()
	await process_frame
	await process_frame
	_verificar(
		current_scene != null
		and current_scene.scene_file_path == "res://Vistas/UI/MenuMisiones.tscn",
		"El botón gráfico de seleccionar misión debe abrir la selección de misiones."
	)
	if _fallos > 0:
		quit(1)
		return
	print("La introducción terminó con arte principal interactivo, banda sonora de menú y navegación funcional.")
	quit()


func _verificar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallar(mensaje)


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error(mensaje)
