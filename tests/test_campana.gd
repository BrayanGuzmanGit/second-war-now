extends "res://tests/test_core.gd"

## Integra fases, física real de avance, límites temporales y persistencia sin alterar partidas.
func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	if _fallos > 0:
		quit(1)
		return
	await _probar_francia()
	for id_mision in ["alamein", "berlin"]:
		await _probar_dos_posiciones(id_mision)
	_probar_persistencia()
	_restaurar_progreso_usuario()
	print("Campaña: %d fallos." % _fallos)
	quit(1 if _fallos else 0)


func _abrir_mision(id_mision: String) -> Node:
	root.get_node("GestorGuardado").progreso["misiones_completadas"] = ["francia", "alamein", "berlin"]
	root.get_node("GestorMisiones").seleccionar_mision(id_mision)
	change_scene_to_file("res://Niveles/nivel_1.tscn")
	await scene_changed
	for i in range(15):
		await physics_frame
	return current_scene.get_node("ControladorCombate")


func _probar_francia() -> void:
	var c: Node = await _abrir_mision("francia")
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	_verificar(c.fase == c.Fase.EVACUACION and c.tiempo_evacuacion == 30.0, "Francia debe iniciar 30 s de evacuación al vencer.")
	_verificar(c.hud.get_node("Interfaz/CuentaAtras").visible, "La cuenta atrás debe ser visible en Francia.")
	c.call("_seleccionar_municion", "pesado")
	_verificar(c.get("_municion_seleccionada") == "estandar", "La retirada debe rechazar cambios ofensivos.")
	# Recorrer físicamente toda la distancia, sin teletransportar a la zona de victoria.
	Input.action_press("Derecha")
	for i in range(570):
		await physics_frame
		c.call("_actualizar_fase", 1.0 / 60.0)
		if c.fase == c.Fase.RESULTADO:
			break
	Input.action_release("Derecha")
	_verificar(c.fase == c.Fase.RESULTADO and c.jugador.vida_actual > 0, "Francia debe poder evacuarse andando con margen de tiempo.")
	c.call("_actualizar_fase", 60.0)
	_verificar(not c.get("_disparo_refuerzo_realizado"), "No deben aparecer refuerzos tras la victoria.")

	c = await _abrir_mision("francia")
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	c.call("_actualizar_fase", 30.0)
	_verificar(c.fase == c.Fase.REFUERZOS and not c.jugador.turno_activo, "Agotar 30 s debe cerrar victoria y detener al jugador.")
	_verificar(c.enemigo.vida_actual > 0, "Debe aparecer un refuerzo vivo diferente del resto.")
	c.jugador.position = Vector2(1730, 720)
	c.call("_actualizar_fase", 1.99)
	_verificar(not c.get("_disparo_refuerzo_realizado"), "El refuerzo debe anunciarse durante dos segundos.")
	c.call("_actualizar_fase", 0.01)
	await create_timer(0.5).timeout
	_verificar(c.jugador.vida_actual == 0 and c.fase == c.Fase.RESULTADO, "El disparo del refuerzo debe ser letal aunque el jugador llegue tarde.")
	_verificar(c.hud.etiqueta_resultado.text == "MISIÓN FALLIDA", "El plazo vencido debe mostrar derrota.")

	c = await _abrir_mision("francia")
	c.set_process(false)
	c.enemigo.recibir_dano(100)
	c.jugador.position = Vector2(1730, 720)
	c.tiempo_evacuacion = 0.01
	c.call("_actualizar_fase", 1.0)
	_verificar(c.fase == c.Fase.RESULTADO and c.jugador.vida_actual > 0, "La llegada debe tener precedencia al plazo en el mismo frame.")

	c = await _abrir_mision("francia")
	c.enemigo.recibir_dano(100)
	c.jugador.recibir_dano(100)
	c.call("_actualizar_fase", 60.0)
	_verificar(c.fase == c.Fase.RESULTADO and not c.get("_disparo_refuerzo_realizado"), "No debe haber refuerzos tras morir durante la retirada.")


func _probar_dos_posiciones(id_mision: String) -> void:
	var c: Node = await _abrir_mision(id_mision)
	_verificar(not c.hud.get_node("Interfaz/CuentaAtras").visible, "Solo Francia debe mostrar una cuenta atrás.")
	_verificar(get_nodes_in_group("obstaculos_campana").size() >= 2, "Cada mapa debe contener relieve físico propio.")
	# Un disparo horizontal debe encontrar el relieve real; se comprueban también fragmentos.
	var origen := Vector2(500, 780)
	var consulta := PhysicsRayQueryParameters2D.create(origen, Vector2(1400, 780), 1)
	var impacto: Dictionary = c.jugador.get_world_2d().direct_space_state.intersect_ray(consulta)
	_verificar(not impacto.is_empty(), "El relieve debe interceptar disparos a baja altura.")
	var proyectil: Proyectil = c.gestor_jugador.crear_proyectil("estandar")
	current_scene.add_child(proyectil)
	proyectil.global_position = origen
	proyectil.configurar(Vector2(1000, 0), c.jugador)
	for i in range(30):
		await physics_frame
	_verificar(not is_instance_valid(proyectil), "El proyectil debe impactar contra la geometría.")
	var fragmento := preload("res://Vistas/Proyectiles/FragmentoProyectil.tscn").instantiate()
	current_scene.add_child(fragmento)
	fragmento.configurar(origen, Vector2(1000,0), c.jugador, 10)
	for i in range(30):
		await physics_frame
	_verificar(not is_instance_valid(fragmento), "Los fragmentos deben impactar contra la geometría.")
	c.jugador.recibir_dano(20)
	c.gestor_jugador.registrar_uso("estandar")
	var vida: float = c.jugador.vida_actual
	var primer_enemigo: Node = c.enemigo
	c.enemigo.recibir_dano(100)
	_verificar(c.fase == c.Fase.AVANCE and c.indice_posicion == 0, "La primera defensa solo debe habilitar avance.")
	# Atravesar el relieve usando el controlador de movimiento y el combustible ilimitado.
	Input.action_press("Derecha")
	for i in range(650):
		await physics_frame
		if c.indice_posicion == 1:
			break
	Input.action_release("Derecha")
	_verificar(c.indice_posicion == 1 and c.fase == c.Fase.COMBATE, "El avance real debe activar el segundo combate sin quedar atascado: " + id_mision)
	_verificar(c.enemigo != primer_enemigo and primer_enemigo.vida_actual == 0, "Debe existir un único enemigo activo y permanecer el primer resto.")
	_verificar(c.jugador.vida_actual == vida and not c.gestor_jugador.esta_disponible("estandar"), "Vida y ciclo del jugador deben persistir entre posiciones.")
	_verificar(not c.jugador.movimiento_retirada_ilimitado and c.jugador.combustible_actual == c.jugador.combustible_maximo, "El segundo combate debe restituir combustible limitado.")
	# Cruzar el objetivo antes de vencer a la segunda defensa no debe completar la misión.
	var posicion: Vector2 = c.jugador.position
	c.jugador.position = Vector2(1730,720)
	c.call("_evaluar_victoria")
	_verificar(c.fase == c.Fase.COMBATE, "La salida no debe saltarse la defensa final.")
	c.jugador.position = posicion
	c.enemigo.recibir_dano(100)
	Input.action_press("Derecha")
	for i in range(550):
		await physics_frame
		if c.fase == c.Fase.RESULTADO:
			break
	Input.action_release("Derecha")
	_verificar(c.fase == c.Fase.RESULTADO and c.jugador.vida_actual > 0, "La salida debe ser alcanzable andando tras la segunda defensa: " + id_mision)
	if id_mision == "berlin":
		_verificar(c.hud.etiqueta_resumen.text.contains("CAMPAÑA COMPLETADA"), "Berlín debe incluir el epílogo.")


func _probar_persistencia() -> void:
	var guardado: Node = root.get_node("GestorGuardado")
	guardado.progreso = guardado.call("_crear_progreso_inicial")
	guardado.comprar_paquete("MON-02", "paquete-persistencia")
	_verificar(guardado.registrar_cosmetico_comprado("TNQ-03") and guardado.equipar_cosmetico("TNQ-03"), "La compra simulada y equipamiento deben persistir.")
	for id_mision in ["francia", "alamein", "berlin"]:
		root.get_node("GestorMisiones").seleccionar_mision(id_mision)
		_verificar(root.get_node("GestorMisiones").completar_mision_actual(), "Debe guardarse la progresión secuencial.")
	# Otro proceso arranca con los Autoloads desde cero, leyendo el JSON escrito por este.
	var salida: Array = []
	var resultado := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/verificar_guardado.gd", "--", guardado.ruta_archivo], salida, true)
	_verificar(resultado == 0, "El progreso y cosmético deben sobrevivir a un proceso nuevo: " + str(salida))
