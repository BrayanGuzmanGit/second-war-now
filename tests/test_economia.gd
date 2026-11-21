extends "res://tests/test_campana.gd"

var g: Node

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	g = root.get_node("GestorGuardado")
	_probar_operaciones()
	_probar_recompensas()
	_probar_migracion_y_recuperacion()
	await _probar_tienda()
	await _probar_apariencias_y_resultados()
	_restaurar_progreso_usuario()
	print("Economía y apariencias: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _nuevo() -> void:
	g.progreso = g.call("_crear_progreso_inicial")
	g.set("_bloqueado", false)
	_verificar(g.guardar_progreso(), "El guardado de pruebas debe poder escribirse.")

func _probar_operaciones() -> void:
	_nuevo()
	_verificar(g.obtener_saldo() == 100, "La bienvenida entrega 100.")
	var anterior: Dictionary = g.progreso.duplicate(true)
	_verificar(not g.comprar_cosmetico("TNQ-02", "sin-saldo")["ok"] and g.progreso == anterior, "Saldo insuficiente no cambia nada.")
	_verificar(not g.comprar_cosmetico("ENM-01", "enemigo")["ok"], "El enemigo no se compra.")
	_verificar(g.comprar_paquete("MON-01", "paquete-1")["ok"] and g.obtener_saldo() == 400, "Paquete pequeño acredita 300.")
	g.comprar_paquete("MON-01", "paquete-1")
	_verificar(g.obtener_saldo() == 400, "Mismo identificador no duplica un paquete.")
	_verificar(not g.comprar_paquete("MON-02", "paquete-1")["ok"], "Un identificador no puede reutilizarse para otro paquete.")
	_verificar(g.comprar_cosmetico("TNQ-02", "compra-1")["ok"] and g.obtener_saldo() == 100, "Comprar descuenta y concede la skin.")
	g.comprar_cosmetico("TNQ-02", "compra-1")
	g.comprar_cosmetico("TNQ-02", "compra-2")
	_verificar(g.obtener_saldo() == 100, "Recomprar o repetir confirmación nunca vuelve a descontar.")
	_verificar(g.equipar_cosmetico("TNQ-02") and not g.equipar_cosmetico("ENM-01"), "Solo pueden equiparse skins propias del jugador.")
	g.comprar_paquete("MON-01", "paquete-2")
	_verificar(g.obtener_saldo() == 400, "Otra confirmación permite repetir paquete.")
	g.progreso["monedas"] = 700
	_verificar(g.comprar_cosmetico("TNQ-03", "saldo-exacto")["ok"] and g.obtener_saldo() == 0, "Saldo exacto permite comprar.")
	var ruta: String = g.ruta_archivo
	g.ruta_archivo = "user://directorio_inexistente_%d/save.json" % OS.get_process_id()
	anterior = g.progreso.duplicate(true)
	_verificar(not g.comprar_paquete("MON-03", "fallo-paquete")["ok"] and g.progreso == anterior, "Fallo al guardar paquete revierte todo.")
	g.ruta_archivo = ruta
	_verificar(g.comprar_paquete("MON-03", "fallo-paquete")["ok"] and g.obtener_saldo() == 1600, "Reintentar la operación fallida la aplica una sola vez.")
	anterior = g.progreso.duplicate(true)
	g.ruta_archivo = "user://directorio_inexistente_%d/save.json" % OS.get_process_id()
	_verificar(not g.comprar_cosmetico("TNQ-06", "fallo-skin")["ok"] and g.progreso == anterior, "Fallo de compra revierte saldo y propiedad.")
	_verificar(not g.equipar_cosmetico("TNQ-03") and g.progreso == anterior, "Fallo de equipamiento conserva el anterior.")
	g.ruta_archivo = ruta
	g.cargar_progreso()
	_verificar(g.obtener_saldo() == 1600 and g.progreso["cosmetico_equipado"] == "TNQ-02", "Recarga conserva saldo y equipamiento.")

func _probar_recompensas() -> void:
	_nuevo()
	for id in ["francia", "alamein", "berlin"]:
		var base: int = ReglasEconomia.VICTORIAS[id]
		var saldo: int = g.obtener_saldo()
		var resultado: Dictionary = g.liquidar_partida("victoria-" + id, id, true, 2)
		_verificar(resultado["ok"] and resultado["importe"] == base + 50 and resultado["defensas"] == 0, "Primera victoria y bono: " + id)
		g.liquidar_partida("victoria-" + id, id, true, 2)
		_verificar(g.obtener_saldo() == saldo + base + 50, "Un resultado repetido no duplica recompensa.")
		resultado = g.liquidar_partida("repeticion-" + id, id, true, 2)
		_verificar(resultado["importe"] == base and resultado["bono"] == 0, "Repetir victoria entrega solo base.")
		for defensas in range(int(ReglasEconomia.DEFENSAS[id]) + 1):
			resultado = g.liquidar_partida("derrota-%s-%d" % [id, defensas], id, false, defensas)
			_verificar(resultado["importe"] == defensas * 25, "Derrota paga únicamente las defensas destruidas.")
	var saldo_antes: int = g.obtener_saldo()
	var bonos: Array = g.progreso["bonos_cobrados"].duplicate()
	g.reiniciar_progreso_misiones()
	_verificar(g.obtener_saldo() == saldo_antes and g.progreso["bonos_cobrados"] == bonos, "Reiniciar conserva economía y bonos.")
	_verificar(g.liquidar_partida("tras-reset", "francia", true, 1)["bono"] == 0, "Reiniciar no restaura el bono.")
	var ruta: String = g.ruta_archivo
	var anterior: Dictionary = g.progreso.duplicate(true)
	g.ruta_archivo = "user://directorio_inexistente_%d/save.json" % OS.get_process_id()
	_verificar(not g.liquidar_partida("resultado-fallido", "alamein", true, 2)["ok"] and g.progreso == anterior, "Fallo de resultado revierte progreso, bono y monedas.")
	g.ruta_archivo = ruta
	_verificar(g.liquidar_partida("resultado-fallido", "alamein", true, 2)["ok"], "El mismo resultado puede reintentarse.")

func _escribir(datos: String, ruta: String) -> void:
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_string(datos)
	archivo.close()

func _probar_migracion_y_recuperacion() -> void:
	var viejo := {"version": 2, "misiones_completadas": ["francia"], "cosmeticos_comprados": ["TNQ-01", "TNQ-03"], "cosmetico_equipado": "TNQ-03"}
	_escribir(JSON.stringify(viejo), g.ruta_archivo)
	_verificar(g.cargar_progreso() and g.obtener_saldo() == 100, "Versión 2 migra con bienvenida.")
	_verificar(g.progreso["bonos_cobrados"] == ["francia"] and g.progreso["cosmetico_equipado"] == "TNQ-03", "Migrar conserva compras y no regala bonos anteriores.")
	g.cargar_progreso()
	_verificar(g.obtener_saldo() == 100, "Recargar no repite bienvenida.")
	g.comprar_paquete("MON-01", "despues-migracion")
	g.guardar_progreso()
	var respaldo: Dictionary = g.call("_leer", g.ruta_archivo + ".bak")
	_escribir("{corrupto", g.ruta_archivo)
	_verificar(g.cargar_progreso() and g.obtener_saldo() == int(respaldo["monedas"]) and not g.aviso_guardado.is_empty(), "Archivo corrupto recupera respaldo y avisa.")
	_escribir("{corrupto", g.ruta_archivo)
	_escribir("{corrupto", g.ruta_archivo + ".bak")
	_verificar(not g.cargar_progreso(), "Dos archivos corruptos bloquean escrituras.")
	var contenido := FileAccess.get_file_as_string(g.ruta_archivo)
	_verificar(not g.comprar_paquete("MON-03", "corrupto")["ok"] and FileAccess.get_file_as_string(g.ruta_archivo) == contenido, "No sobrescribir un guardado corrupto.")
	_nuevo()

func _probar_tienda() -> void:
	_nuevo()
	var tienda: Control = load("res://Vistas/UI/Tienda.tscn").instantiate()
	root.add_child(tienda)
	await process_frame
	_verificar(tienda.pestañas.get_tab_count() == 2 and tienda.lista_cosmeticos.get_child_count() == 5, "Tienda muestra dos pestañas y cinco skins, sin enemigo.")
	tienda.lista_cosmeticos.get_node("TNQ-01").grab_focus()
	var flecha := InputEventKey.new()
	flecha.keycode = KEY_DOWN
	flecha.pressed = true
	root.push_input(flecha)
	flecha.pressed = false
	root.push_input(flecha)
	_verificar(tienda.seleccionado == "TNQ-02" and tienda.detalle.text.contains("Bruselas"), "El foco de la fila muestra su ficha histórica.")
	tienda.call("_accion_seleccionada")
	_verificar(not tienda.confirmacion.visible and tienda.etiqueta_estado.text.contains("200"), "La UI informa monedas que faltan.")
	var clic := InputEventMouseButton.new()
	clic.position = tienda.ver_monedas.get_global_rect().get_center()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	root.push_input(clic, true)
	clic.pressed = false
	root.push_input(clic, true)
	_verificar(tienda.pestañas.current_tab == 1, "El aviso abre la pestaña de paquetes.")
	tienda.call("_solicitar_paquete", "MON-01")
	tienda.confirmacion.canceled.emit()
	tienda.confirmacion.hide()
	_verificar(g.obtener_saldo() == 100, "Cancelar no acredita monedas.")
	tienda.call("_solicitar_paquete", "MON-01")
	tienda.confirmacion.confirmed.emit()
	tienda.confirmacion.hide()
	tienda.confirmacion.confirmed.emit()
	_verificar(g.obtener_saldo() == 400, "Doble confirmación UI acredita una sola vez.")
	tienda.pestañas.current_tab = 0
	_verificar(tienda.seleccionado == "TNQ-02" and tienda.etiqueta_saldo.text.contains("400"), "Volver a Tanques conserva selección y actualiza saldo.")
	tienda.call("_accion_seleccionada")
	tienda.confirmacion.confirmed.emit()
	tienda.confirmacion.hide()
	_verificar(g.obtener_saldo() == 100 and tienda.ofrecer_equipo.visible, "Compra ofrece equipar.")
	tienda.ofrecer_equipo.confirmed.emit()
	tienda.ofrecer_equipo.hide()
	_verificar(g.progreso["cosmetico_equipado"] == "TNQ-02", "Equipar ahora persiste.")
	if OS.get_cmdline_user_args().has("capturas"):
		var original := root.size
		for tamano in [Vector2i(960, 540), Vector2i(1920, 1080), Vector2i(1280, 800)]:
			root.size = tamano
			await process_frame
			await _capturar("tienda-%dx%d" % [tamano.x, tamano.y])
		root.size = original
		await _capturar("tienda")
		tienda.pestañas.current_tab = 1
		await _capturar("paquetes")
	tienda.free()
	g.cargar_progreso()
	tienda = load("res://Vistas/UI/Tienda.tscn").instantiate()
	root.add_child(tienda)
	await process_frame
	_verificar(tienda.seleccionado == "TNQ-02" and tienda.accion.disabled, "La tienda reabre en el modelo equipado.")
	tienda.free()
	var combate := await _abrir_mision("francia")
	_verificar(combate.jugador.visual_tanque.id_apariencia == "TNQ-02", "La misión utiliza la apariencia adquirida.")

func _capturar(nombre: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-economia"))
	root.get_texture().get_image().save_png("res://.godot/qa-economia/%s.png" % nombre)

func _probar_apariencias_y_resultados() -> void:
	_nuevo()
	var c: Node = await _abrir_mision("francia")
	_verificar(c.enemigo.visual_tanque.id_apariencia == "ENM-01", "El enemigo inicial utiliza su propio bando.")
	var origen: Vector2 = c.jugador.punto_disparo.position
	var hitbox: Vector2 = c.jugador.forma_colision.shape.size
	for id in ReglasEconomia.PRECIOS:
		c.jugador.aplicar_cosmetico(id)
		_verificar(c.jugador.visual_tanque.id_apariencia == id and c.jugador.punto_disparo.position == origen and c.jugador.forma_colision.shape.size == hitbox, "Las skins no cambian geometría física/balística: " + id)
		_verificar(c.enemigo.visual_tanque.id_apariencia == "ENM-01", "Equipar jugador no modifica enemigo.")
		if id != "TNQ-01":
			var arte: Dictionary = CatalogoApariencias.obtener(id)
			_verificar(arte["casco"].get_image().is_invisible() == false and arte["canon"].get_image().is_invisible() == false, "Casco y cañón contienen píxeles visibles.")
		if OS.get_cmdline_user_args().has("capturas"):
			await _capturar(id)
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	c.call("_actualizar_fase", 30.0)
	_verificar(c.enemigo.visual_tanque.id_apariencia == "ENM-01", "El refuerzo usa ENM-01.")
	c.call("_actualizar_fase", 2.0)
	await create_timer(0.5).timeout
	_verificar(c._defensas_destruidas == 1 and c.fase == c.Fase.RESULTADO and g.obtener_saldo() == 125, "Francia vencida entrega 25 por una defensa, nunca por refuerzo.")
	for id in ["alamein", "berlin"]:
		c = await _abrir_mision(id)
		var resto: Node = c.enemigo
		c.enemigo.recibir_dano(100)
		c.call("_iniciar_siguiente_posicion")
		_verificar(c.enemigo.visual_tanque.id_apariencia == "ENM-01" and resto.visual_tanque.id_apariencia == "ENM-01", "Segunda defensa y restos conservan apariencia.")
		c.enemigo.recibir_dano(100)
		c.jugador.position = Vector2(1730, 720)
		c.call("_evaluar_victoria")
		_verificar(c.fase == c.Fase.RESULTADO and c.hud.get_node("Interfaz/PanelResultado/Centro/Contenido/Recompensa").text.contains("SALDO"), "Victoria muestra desglose guardado.")
		if OS.get_cmdline_user_args().has("capturas"):
			await _capturar("resultado-" + id)
		var saldo: int = g.obtener_saldo()
		c.call("_guardar_resultado")
		_verificar(g.obtener_saldo() == saldo, "Reintentar resultado guardado no paga dos veces.")
