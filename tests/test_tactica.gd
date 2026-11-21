extends "res://tests/test_campana.gd"

func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	var c := await _abrir_mision("francia")
	var ia: TanqueIA = c.enemigo
	var jugador: Tanque = c.jugador
	var opciones: Array[String] = ["estandar", "pesado", "bombardeo"]
	var primera := ia.decidir(jugador, opciones, c._datos, 0, false)
	_verificar(primera.tipo == "estandar", "Francia abre con tiro de referencia.")
	var blanco := jugador.obtener_punto_impacto_global()
	ia.preparar_tiro(jugador, primera, c._datos, 1.0)
	ia.observar_impacto(blanco + Vector2(50, 0), null)
	ia.preparar_tiro(jugador, primera, c._datos, 1.0)
	_verificar(is_equal_approx(ia.margen_anterior, 0.5), "Reduce margen contra un blanco quieto.")
	ia.observar_impacto(blanco, jugador)
	var ajustado := ia.decidir(jugador, opciones, c._datos, 0, false)
	_verificar(ajustado.tipo == "pesado", "Con idéntico inventario aprovecha un acierto.")
	jugador.vida_actual = 20
	_verificar(ia.decidir(jugador, opciones, c._datos, 0, false).tipo == "estandar", "Reserva el pesado al rematar.")
	jugador.position.x += jugador.forma_colision.shape.get_rect().size.x + 1
	ia.preparar_tiro(jugador, primera, c._datos, 1.0)
	_verificar(is_equal_approx(ia.margen_anterior, 1.0), "Cambiar de posición recupera el margen.")
	# Un muro alto intercepta el arco bajo y deja pasar un tiro elevado.
	jugador.position.x -= jugador.forma_colision.shape.get_rect().size.x + 1
	var obstaculo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rectangulo := RectangleShape2D.new()
	rectangulo.size = Vector2(32, 410)
	forma.shape = rectangulo
	obstaculo.add_child(forma)
	current_scene.add_child(obstaculo)
	obstaculo.global_position = (ia.global_position + jugador.global_position) * 0.5 + Vector2(0, -35)
	await physics_frame
	await physics_frame
	var protegido := ia.decidir(jugador, opciones, c._datos, 0, false)
	_verificar(protegido.arco > 35, "Una barrera real cambia el arco seleccionado.")
	ia.observar_impacto(ia.referencia + Vector2(180, 0), obstaculo)
	_verificar(ia.cobertura, "Reconoce un impacto bloqueado antes del blanco.")
	ia.observar_impacto(ia.referencia, jugador)
	ia.observar_impacto(ia.referencia + Vector2(150, 0), obstaculo)
	_verificar(ia.acierto and not ia.cobertura, "El acierto de un fragmento prevalece sobre el resto.")
	obstaculo.free()
	_restaurar_progreso_usuario()
	print("Decisiones tácticas: %d fallos." % _fallos)
	quit(1 if _fallos else 0)
