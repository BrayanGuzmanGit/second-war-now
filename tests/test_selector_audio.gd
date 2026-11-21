extends "res://tests/test_campana.gd"
var eventos: Array = []
var audio: Node

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	audio = root.get_node("GestorAudioPartida")
	audio.ruta_preferencias = "user://selector_qa_%d.cfg" % OS.get_process_id()
	audio.cargar_preferencias()
	audio.selector_reproducido.connect(func(tipo: String, municion: String) -> void: eventos.append([tipo,municion]))
	var grabacion: AudioEffectRecord
	if OS.get_cmdline_user_args().has("grabar"):
		grabacion = AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,grabacion)
	for mision in ["francia","alamein","berlin"]:
		var c: Node = await _abrir_mision(mision)
		var hud: Node = c.hud
		_verificar(eventos.is_empty(), "Aparición y HUD no reproducen selector.")
		if grabacion:
			grabacion.set_recording_active(true)
		hud._alternar_menu_municion()
		await create_timer(0.15).timeout
		_verificar(eventos == [["abrir",""]], "Abrir suena una vez.")
		hud._alternar_menu_municion()
		await create_timer(0.15).timeout
		_verificar(eventos.back() == ["cerrar",""], "Botón cierra con sonido.")
		hud._alternar_menu_municion()
		await create_timer(0.15).timeout
		var fuera := InputEventMouseButton.new()
		fuera.button_index = MOUSE_BUTTON_LEFT
		fuera.pressed = true
		fuera.position = Vector2.ZERO
		hud._input(fuera)
		await create_timer(0.15).timeout
		_verificar(not hud.menu_desplegable_municion.visible and eventos.back() == ["cerrar",""], "Clic fuera cierra con sonido.")
		for tipo in ["pesado","dispersion","bombardeo","incendiario","estandar"]:
			hud._alternar_menu_municion()
			await create_timer(0.15).timeout
			var antes := eventos.size()
			var atenuacion: float = audio._atenuacion
			hud.botones_municion[tipo].pressed.emit()
			await create_timer(0.06).timeout
			_verificar(eventos.size() == antes+1 and eventos.back() == ["seleccion",tipo], "Cambio aceptado sin doble cierre: "+tipo)
			_verificar(not hud.menu_desplegable_municion.visible, "Selección cierra menú.")
			_verificar(audio._voz_selector.bus == "PartidaEfectos" and audio._voz_selector is AudioStreamPlayer, "Efecto centrado en bus correcto.")
			_verificar(audio._atenuacion <= atenuacion, "Selector no atenúa mecanismos.")
			await create_timer(0.4).timeout
		hud._alternar_menu_municion()
		await create_timer(0.15).timeout
		var antes := eventos.size()
		hud._seleccionar_municion("estandar")
		await create_timer(0.15).timeout
		_verificar(eventos.size() == antes+1 and eventos.back() == ["cerrar",""], "Repetir seleccionada solo cierra.")
		antes = eventos.size()
		for i in 5:
			c._actualizar_municion_hud()
		c.gestor_jugador.registrar_uso("pesado")
		c._seleccionar_municion("pesado")
		c._proyectil_en_vuelo = true
		c._seleccionar_municion("dispersion")
		c._proyectil_en_vuelo = false
		c._turno_jugador = false
		c._seleccionar_municion("dispersion")
		c._turno_jugador = true
		await create_timer(0.05).timeout
		_verificar(eventos.size() == antes, "HUD y rechazos no suenan.")
		c.gestor_jugador.registrar_uso("estandar")
		c._actualizar_municion_hud()
		_verificar(eventos.size() == antes, "Selección automática es silenciosa.")
		c.gestor_jugador._proyectiles_usados.clear()
		# Cambios rápidos mantienen solo la última petición pendiente.
		c._seleccionar_municion("dispersion")
		var voz: Node = audio._voz_selector
		for tipo in ["bombardeo","estandar","incendiario"]:
			c._seleccionar_municion(tipo)
		await create_timer(0.06).timeout
		_verificar(audio._voz_selector == voz and eventos.back() == ["seleccion","incendiario"], "Una voz y última selección al cambiar rápidamente.")
		audio.configurar_volumen("efectos",0.0,true)
		_verificar(AudioServer.is_bus_mute(AudioServer.get_bus_index("PartidaEfectos")), "Silencio respeta ajustes.")
		audio.configurar_volumen("efectos",0.8,false)
		hud._alternar_menu_municion()
		var menu: Node = get_first_node_in_group("panel_sonido")
		menu.abrir(true)
		antes = eventos.size()
		await create_timer(0.2).timeout
		_verificar(eventos.size() == antes and not hud.menu_desplegable_municion.visible, "Pausa congela voz pendiente y cierra silenciosamente.")
		menu.abrir(false)
		await create_timer(0.15).timeout
		# Entrada real de teclado activa un botón enfocado.
		hud._alternar_menu_municion()
		await process_frame
		hud.botones_municion.estandar.grab_focus()
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_ENTER
		tecla.pressed = true
		Input.parse_input_event(tecla)
		await process_frame
		tecla = InputEventKey.new()
		tecla.keycode = KEY_ENTER
		Input.parse_input_event(tecla)
		await create_timer(0.1).timeout
		_verificar(c._municion_seleccionada == "estandar", "Teclado selecciona munición.")
		if grabacion:
			grabacion.set_recording_active(false)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-selector"))
			grabacion.get_recording().save_to_wav(ProjectSettings.globalize_path("res://.godot/qa-selector/"+mision+".wav"))
		audio.interfaz("seleccion","pesado")
		audio.interfaz("seleccion","bombardeo")
		c._finalizar_combate(mision != "alamein")
		await create_timer(0.06).timeout
		_verificar(not is_instance_valid(audio._voz_selector) and audio._selector_pendiente.is_empty(), "Victoria/derrota limpia voz y petición.")
		eventos.clear()
	if grabacion:
		AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var c: Node = await _abrir_mision("francia")
	audio.interfaz("seleccion","estandar")
	var menu: Node = get_first_node_in_group("panel_sonido")
	menu.abrir(true)
	menu._abandonar()
	await scene_changed
	_verificar(not is_instance_valid(audio._voz_selector) and audio._selector_pendiente.is_empty(), "Abandonar limpia selector.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(audio.ruta_preferencias))
	audio.ruta_preferencias = "user://audio.cfg"
	audio.cargar_preferencias()
	_restaurar_progreso_usuario()
	print("Selector sonoro: %d fallos." % _fallos)
	quit(1 if _fallos else 0)
