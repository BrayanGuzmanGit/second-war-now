extends "res://tests/test_campana.gd"

## Capturas del renderer real para revisar materiales. No modifica las imágenes fuente.
func _ejecutar_pruebas() -> void:
	_aislar_progreso_usuario()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa-terreno"))
	for id_mision in ["francia", "alamein", "berlin"]:
		var c: Node = await _abrir_mision(id_mision)
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/qa-terreno/%s-inicial.png" % id_mision)
		c.terreno.solicitar_impacto(Vector2(760,c.terreno.obtener_altura(760)), "pesado")
		var id: int = c.terreno.iniciar_deformacion_progresiva(Vector2(1050,c.terreno.obtener_altura(1050)), "bombardeo")
		c.terreno.actualizar_deformacion(id,1.0)
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/qa-terreno/%s-crateres.png" % id_mision)
		if id_mision == "francia":
			var proyectil: Proyectil = c.gestor_jugador.crear_proyectil("bombardeo")
			proyectil.terreno = c.terreno
			current_scene.add_child(proyectil)
			proyectil.configurar(Vector2.ZERO, c.jugador)
			proyectil.call("_resolver_impacto", c.terreno.get_child(2), Vector2(960,c.terreno.obtener_altura(960)))
			for porcentaje in [0.25,0.5,0.75]:
				for intento in range(180):
					await process_frame
					var efectos := get_nodes_in_group("efectos_bombardeo_terreno")
					if not efectos.is_empty() and efectos[0].progreso >= porcentaje:
						break
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.godot/qa-terreno/bombardeo-%02d.png" % roundi(porcentaje * 100))
			await create_timer(0.5).timeout
	_restaurar_progreso_usuario()
	quit()
