extends SceneTree
## Misma escena y ráfaga en ambos paquetes. El reloj mide tiempo real entre frames.
func _initialize() -> void:
	medir.call_deferred()

func medir() -> void:
	change_scene_to_file("res://Niveles/nivel_1.tscn")
	await scene_changed
	var c := current_scene.get_node("ControladorCombate")
	var recurso := load("res://Vistas/Proyectiles/FragmentoProyectil.tscn") as PackedScene
	var muestras: Array[float] = []
	for i in 420:
		if i % 8 == 0:
			for j in 6:
				var fragmento = recurso.instantiate()
				fragmento.configurar(c.jugador.position + Vector2(40,-48),Vector2(330,-110+j*38),c.jugador,0.01)
				current_scene.add_child(fragmento)
		var inicio := Time.get_ticks_usec()
		await process_frame
		if i >= 60:
			muestras.append((Time.get_ticks_usec()-inicio)/1000.0)
	muestras.sort()
	print("MEDICION ms por frame: mediana %.3f, p95 %.3f" % [muestras[180],muestras[342]])
	quit()
