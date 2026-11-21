extends "res://tests/test_campana.gd"

## Partidas completas: el bot solo usa apuntado, disparo y movimiento públicos.
## No modifica vida, daño, tiempo de evacuación ni posición de ningún tanque.
func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	if _fallos > 0:
		quit(1)
		return
	var guardado: Node = root.get_node("GestorGuardado")
	guardado.comprar_paquete("MON-03", "fondos-qa-1")
	guardado.comprar_paquete("MON-03", "fondos-qa-2")
	var casos := [
		["francia", "TNQ-01"], ["francia", "TNQ-02"], ["alamein", "TNQ-03"],
		["berlin", "TNQ-04"], ["francia", "TNQ-06"],
	]
	for caso in casos:
		guardado.registrar_cosmetico_comprado(caso[1])
		_verificar(guardado.equipar_cosmetico(caso[1]), "La skin del recorrido debe equiparse: " + caso[1])
		await _jugar_mision(caso[0])
	_restaurar_progreso_usuario()
	print("Partidas completas: %d fallos." % _fallos)
	quit(1 if _fallos else 0)


func _jugar_mision(id_mision: String) -> void:
	var c: Node = await _abrir_mision(id_mision)
	var disparos := 0
	var limite := Time.get_ticks_msec() + 150000
	while c.fase != c.Fase.RESULTADO and Time.get_ticks_msec() < limite:
		if c.fase == c.Fase.COMBATE and c.get("_turno_jugador") and not c.get("_proyectil_en_vuelo") and c.jugador.turno_activo:
			Input.action_release("Derecha")
			var solucion := _buscar_tiro(c)
			c.call("_seleccionar_municion", solucion["tipo"])
			c.jugador.actualizar_apuntado_joystick(solucion["vector"])
			c.jugador.call("_unhandled_input", _evento_disparo())
			disparos += 1
		elif c.fase == c.Fase.AVANCE or c.fase == c.Fase.EVACUACION:
			Input.action_press("Derecha")
		await physics_frame
	Input.action_release("Derecha")
	_verificar(c.fase == c.Fase.RESULTADO and c.jugador.vida_actual > 0, "Debe poder ganarse una partida con tiros reales: " + id_mision)
	print("Partida %s: %d disparos, %d HP, fase %d" % [id_mision, disparos, c.jugador.vida_actual, c.fase])


func _evento_disparo() -> InputEventAction:
	var evento := InputEventAction.new()
	evento.action = "Disparo"
	evento.pressed = true
	return evento


func _buscar_tiro(c: Node) -> Dictionary:
	var resultado := {"tipo": c.gestor_jugador.obtener_disponibles()[0], "vector": Vector2(0.6,-0.5)}
	for tipo in ["pesado", "bombardeo", "estandar", "incendiario", "dispersion"]:
		if not c.gestor_jugador.esta_disponible(tipo):
			continue
		var multiplicador: float = c.gestor_jugador.obtener_multiplicador_potencia(tipo)
		for grados in range(18, 77, 3):
			var angulo := deg_to_rad(float(grados))
			var direccion := Vector2(cos(angulo), -sin(angulo))
			var potencia := 800.0
			# La boca rota con el cañón: recalcular origen y velocidad evita apuntar desde el centro.
			for repeticion in range(5):
				c.jugador.visual_tanque.apuntar_canon(direccion)
				var origen: Vector2 = c.jugador.punto_disparo.global_position
				var objetivo: Vector2 = c.enemigo.obtener_punto_impacto_global()
				var dx := objetivo.x - origen.x
				var altura := origen.y - objetivo.y
				var divisor := 2.0 * cos(angulo) * cos(angulo) * (dx * tan(angulo) - altura)
				if divisor > 0.0:
					potencia = sqrt(GameConfig.GRAVEDAD * dx * dx / divisor) / multiplicador
			if potencia < c.jugador.potencia_minima or potencia > c.jugador.potencia_maxima:
				continue
			var velocidad := direccion * potencia * multiplicador
			var punto: Vector2 = c.jugador.punto_disparo.global_position
			var mundo: PhysicsDirectSpaceState2D = c.jugador.get_world_2d().direct_space_state
			for paso in range(180):
				var siguiente := punto + velocidad * 0.03 + Vector2(0, 0.5 * GameConfig.GRAVEDAD * 0.03 * 0.03)
				var consulta := PhysicsRayQueryParameters2D.create(punto, siguiente, 1, [c.jugador.get_rid()])
				var contacto := mundo.intersect_ray(consulta)
				if not contacto.is_empty():
					if contacto["collider"] == c.enemigo:
						var intensidad: float = (potencia - c.jugador.potencia_minima) / (c.jugador.potencia_maxima - c.jugador.potencia_minima)
						return {"tipo": tipo, "vector": direccion * intensidad}
					break
				punto = siguiente
				velocidad.y += GameConfig.GRAVEDAD * 0.03
	return resultado
