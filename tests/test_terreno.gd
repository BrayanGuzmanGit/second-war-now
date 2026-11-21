extends "res://tests/test_campana.gd"

const MODELO_PERFIL = preload("res://Modelos/PerfilTerreno.gd")


func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	if _fallos > 0:
		quit(1)
		return
	_probar_modelo()
	await _probar_bombardeo()
	await _probar_dano_unico_y_cancelacion()
	await _probar_movimiento_deformado()
	_restaurar_progreso_usuario()
	print("Terreno destructible: %d fallos." % _fallos)
	quit(1 if _fallos else 0)


func _probar_modelo() -> void:
	for id_mision in ["francia", "alamein", "berlin"]:
		var datos: Dictionary = DatosCampana.obtener(id_mision)
		var perfil := MODELO_PERFIL.new()
		perfil.configurar(datos["terreno"], datos["posiciones"].slice(1))
		for i in range(120):
			var centro := float(160 + (i * 137) % 1450)
			var tipo: String = ["estandar", "pesado", "bombardeo", "dispersion", "incendiario"][i % 5]
			var anterior := perfil.alturas.duplicate()
			var objetivo := perfil.calcular_objetivo(Vector2(centro, perfil.obtener_altura(centro)), tipo)
			perfil.aplicar_objetivo(anterior, objetivo, 1.0)
			var valido := true
			for j in range(perfil.alturas.size()):
				valido = valido and perfil.alturas[j] >= anterior[j] - 0.001 and perfil.alturas[j] <= perfil.inicial[j] + 80.001
				if j > 0:
					valido = valido and absf(perfil.alturas[j] - perfil.alturas[j - 1]) <= MODELO_PERFIL.PENDIENTE * MODELO_PERFIL.PASO + 0.001
				if j * 4 >= 1640:
					valido = valido and is_equal_approx(perfil.alturas[j], perfil.inicial[j])
			_verificar(valido, "La acumulación debe respetar profundidad, pendiente, monotonía y llegada: " + id_mision)
		if id_mision != "francia":
			_verificar(is_equal_approx(perfil.obtener_altura(1480), 800.0), "La defensa futura debe mantener su soporte.")
			perfil.liberar_posicion(1480)
			var desde := perfil.alturas.duplicate()
			perfil.aplicar_objetivo(desde, perfil.calcular_objetivo(Vector2(1480,800), "pesado"), 1.0)
			_verificar(perfil.obtener_altura(1480) > 800, "El suelo debe poder excavarse tras activar la defensa.")


func _probar_bombardeo() -> void:
	var c: Node = await _abrir_mision("francia")
	c.set_process(false)
	var t: Node = c.terreno
	var superficie: float = t.obtener_altura(900)
	var proyectil: Proyectil = c.gestor_jugador.crear_proyectil("bombardeo")
	proyectil.terreno = t
	current_scene.add_child(proyectil)
	proyectil.configurar(Vector2.ZERO, c.jugador)
	var finalizado := [false]
	proyectil.finalizado.connect(func() -> void: finalizado[0] = true)
	proyectil.call("_resolver_impacto", t.get_child(2), Vector2(900,superficie))
	await create_timer(1.2).timeout
	_verificar(is_equal_approx(t.obtener_altura(900), superficie), "La bengala no debe excavar durante la espera.")
	var lecturas: Array[float] = []
	for i in range(7):
		await create_timer(0.15).timeout
		lecturas.append(t.obtener_altura(900))
	_verificar(lecturas[2] > superficie and lecturas[2] < superficie + 31.99, "El bombardeo debe tener una altura intermedia, no un cráter instantáneo.")
	for i in range(1, lecturas.size()):
		_verificar(lecturas[i] >= lecturas[i-1] - 0.001, "La excavación progresiva no debe rellenar suelo.")
	await create_timer(0.3).timeout
	_verificar(is_equal_approx(t.obtener_altura(900), superficie + 32.0), "La excavación debe terminar exactamente en el objetivo.")
	_verificar(finalizado[0] and not t.hay_deformaciones(), "El proyectil debe finalizar tras publicar la geometría final.")
	await physics_frame
	var contacto: Dictionary = c.jugador.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(900,750), Vector2(900,900), 1))
	_verificar(not contacto.is_empty() and absf(contacto["position"].y - t.obtener_altura(900)) < 0.1, "La colisión debe seguir exactamente el cráter visible.")
	# El mismo progreso de una operación no puede sumar profundidad una y otra vez.
	var id: int = t.iniciar_deformacion_progresiva(Vector2(600,800), "bombardeo")
	t.actualizar_deformacion(id, 0.5)
	var mitad: float = t.obtener_altura(600)
	for i in range(20):
		t.actualizar_deformacion(id, 0.5)
	_verificar(is_equal_approx(t.obtener_altura(600), mitad), "Repetir progreso no debe multiplicar excavación.")
	t.actualizar_deformacion(id, 1.0)
	await process_frame


func _probar_movimiento_deformado() -> void:
	for id_mision in ["francia", "alamein", "berlin"]:
		var c: Node = await _abrir_mision(id_mision)
		var t: Node = c.terreno
		var vida: float = c.jugador.vida_actual
		var original_y: float = c.jugador.position.y
		# Un cuenco más ancho que el tanque comprueba que realmente pierde soporte.
		for x in range(160, 601, 40):
			for repeticion in range(3):
				t.solicitar_impacto(Vector2(x, t.obtener_altura(x)), "pesado")
		for i in range(75):
			await physics_frame
		_verificar(c.jugador.position.y > original_y + 10 and c.jugador.vida_actual == vida, "El tanque debe bajar físicamente sin daño por caída: " + id_mision)
		c.enemigo.recibir_dano(100)
		Input.action_press("Derecha")
		for i in range(540):
			await physics_frame
			if c.jugador.position.x >= 700:
				break
		Input.action_release("Derecha")
		_verificar(c.jugador.position.x >= 700, "Debe poder salir del terreno craterizado: " + id_mision)
	# Cambiar de escena debe restaurar el perfil inicial y cancelar animaciones pendientes.
	var c: Node = await _abrir_mision("francia")
	_verificar(is_equal_approx(c.terreno.obtener_altura(360),800), "Una misión nueva debe restaurar el terreno.")


func _probar_dano_unico_y_cancelacion() -> void:
	var c: Node = await _abrir_mision("francia")
	var proyectil: Proyectil = c.gestor_jugador.crear_proyectil("bombardeo")
	proyectil.terreno = c.terreno
	current_scene.add_child(proyectil)
	proyectil.configurar(Vector2.ZERO, c.jugador)
	proyectil.call("_resolver_impacto", c.enemigo, c.enemigo.obtener_punto_impacto_global())
	await create_timer(1.6).timeout
	_verificar(is_equal_approx(c.enemigo.vida_actual,55.0), "El bombardeo debe aplicar una sola vez sus 45 puntos de daño.")
	await create_timer(1.0).timeout
	_verificar(is_equal_approx(c.enemigo.vida_actual,55.0), "Los pasos de excavación no deben repetir el daño.")
	var fuego: Proyectil = c.gestor_jugador.crear_proyectil("incendiario")
	fuego.terreno = c.terreno
	current_scene.add_child(fuego)
	fuego.configurar(Vector2.ZERO, c.jugador)
	fuego.call("_resolver_impacto", c.terreno.get_child(2), Vector2(800,800))
	await create_timer(0.1).timeout
	var altura_fuego: float = c.terreno.obtener_altura(800)
	await create_timer(2.0).timeout
	_verificar(is_equal_approx(altura_fuego,c.terreno.obtener_altura(800)), "Los ticks incendiarios no deben excavar más terreno.")
	var vida_ia: float = c.enemigo.vida_actual
	var y_ia: float = c.enemigo.position.y
	for x in range(1150,1451,40):
		for i in range(3):
			c.terreno.solicitar_impacto(Vector2(x,c.terreno.obtener_altura(x)), "pesado")
	for i in range(75):
		await physics_frame
	_verificar(c.enemigo.position.y > y_ia + 10 and c.enemigo.vida_actual == vida_ia, "La IA también debe caer sin daño adicional.")
	var x_ia: float = c.enemigo.position.x
	c.enemigo.mover_en_turno(Vector2(1600,0))
	for i in range(100):
		await physics_frame
	_verificar(c.enemigo.position.x > x_ia + 60, "La IA debe poder avanzar por el cráter sin confundir la pendiente con una pared.")
	# Reiniciar durante el efecto debe destruir el reloj, el VFX y la operación de la escena anterior.
	var pendiente: Proyectil = c.gestor_jugador.crear_proyectil("bombardeo")
	pendiente.terreno = c.terreno
	current_scene.add_child(pendiente)
	pendiente.configurar(Vector2.ZERO,c.jugador)
	pendiente.call("_resolver_impacto", c.terreno.get_child(2), Vector2(700,800))
	await create_timer(1.6).timeout
	c = await _abrir_mision("francia")
	await create_timer(0.8).timeout
	_verificar(not c.terreno.hay_deformaciones() and is_equal_approx(c.terreno.obtener_altura(700),800), "Reiniciar durante el bombardeo debe cancelar toda deformación pendiente.")
