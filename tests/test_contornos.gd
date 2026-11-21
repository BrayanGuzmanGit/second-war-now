extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var c: Node = await _abrir_mision("francia")
	var unidad: Tanque = c.jugador
	for id in ["TNQ-01","TNQ-02","TNQ-03","TNQ-04","TNQ-06","ENM-01"]:
		unidad = c.enemigo if id == "ENM-01" else c.jugador
		var visual := unidad.visual_tanque
		visual.aplicar_apariencia(id)
		unidad.set_physics_process(false)
		for pendiente in [0.0,0.16]:
			visual.rotation = pendiente
			for angulo in [0.0,0.4,0.95]:
				var eje := Vector2(cos(angulo),-sin(angulo))
				if unidad == c.enemigo:
					eje.x *= -1
				visual.apuntar_canon(eje)
				await physics_frame
				await physics_frame
				var boca := visual.punto_disparo.global_position
				var consulta := PhysicsRayQueryParameters2D.create(boca+eje*16,boca-eje*20,8)
				consulta.collide_with_areas = true
				consulta.collide_with_bodies = false
				var golpe := unidad.get_world_2d().direct_space_state.intersect_ray(consulta)
				var error := INF if golpe.is_empty() else boca.distance_to(golpe.position)
				_verificar(error <= 2.0, "Boca y borde visible a dos píxeles: %s ángulo %.2f error %.2f" % [id,angulo,error])
		visual.rotation = 0
		await _probar_barrido(c, unidad)
	if OS.get_cmdline_user_args().has("muestra"):
		for mision in ["francia","alamein","berlin"]:
			c = await _abrir_mision(mision)
			c.set_process(false)
			c.jugador.set_physics_process(false)
			c.jugador.position = c.enemigo.position - Vector2(380,12)
			c.camara.global_position = c.enemigo.global_position - Vector2(180,65)
			for tipo in ["estandar","pesado","dispersion","bombardeo","incendiario"]:
				for blindaje in [true,false]:
					var suelo := Vector2(c.enemigo.position.x-160,0)
					suelo.y = c.terreno.obtener_altura(suelo.x)
					var destino: Vector2 = c.enemigo.obtener_punto_impacto_global() if blindaje else suelo
					var origen: Vector2 = c.jugador.punto_disparo.global_position
					var velocidad := Vector2.ZERO
					for ajuste in 4:
						velocidad = (destino-origen)/0.4 - Vector2.DOWN*GameConfig.GRAVEDAD*0.2
						c.jugador.visual_tanque.apuntar_canon(velocidad)
						origen = c.jugador.punto_disparo.global_position
					c._mostrar_efecto_salida(origen,velocidad,tipo)
					var p: Proyectil = c.gestor_jugador.crear_proyectil(tipo)
					current_scene.add_child(p)
					p.global_position = origen
					p.terreno = c.terreno
					p.configurar(velocidad/p.multiplicador_potencia,c.jugador,0.1)
					p.dano_por_tick = 0.1
					await create_timer(2.7 if tipo == "bombardeo" else 0.7).timeout
	_restaurar_progreso_usuario()
	print("Contornos balísticos: %d fallos." % _fallos)
	quit(1 if _fallos else 0)

func _probar_barrido(c: Node, unidad: Tanque) -> void:
	var p: Proyectil = c.gestor_jugador.crear_proyectil("estandar")
	current_scene.add_child(p)
	p.set_physics_process(false)
	var contrario: Node2D = c.jugador if unidad == c.enemigo else c.enemigo
	var visual := unidad.visual_tanque
	var cuerpo: Area2D = visual.rodaje.get_child(-1)
	var techo := INF
	for forma: CollisionPolygon2D in cuerpo.get_children():
		for punto in forma.polygon:
			techo = minf(techo,forma.to_global(punto).y)
	visual.apuntar_canon(Vector2.LEFT if unidad == c.enemigo else Vector2.RIGHT)
	await physics_frame
	await physics_frame
	var centro := unidad.global_position.x
	for margen in [-4.5,-2.0]:
		var desde := Vector2(centro-180,techo+margen)
		var hasta := Vector2(centro+180,desde.y)
		var golpe: Dictionary = p.barrido.contacto(desde,hasta,contrario)
		if margen < -3:
			_verificar(golpe.is_empty(), "Proyectil completamente sobre la torreta pasa.")
		else:
			_verificar(golpe.get("collider") == unidad, "El costado del proyectil roza la torreta.")
	var pared := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var placa := RectangleShape2D.new()
	placa.size = Vector2(6,55)
	forma.shape = placa
	pared.add_child(forma)
	pared.position = Vector2(centro-160,techo+15)
	current_scene.add_child(pared)
	await physics_frame
	await physics_frame
	var primero: Dictionary = p.barrido.contacto(pared.position-Vector2(60,0),pared.position+Vector2(290,0),contrario)
	_verificar(primero.get("collider") == pared, "La pared anterior al tanque intercepta el tiro rápido.")
	pared.queue_free()
	p.queue_free()

