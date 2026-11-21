extends SceneTree

const SOURCE := "res://Imagenes/TanqueM4Sherman.png"
const OUTPUT_DIR := "res://Imagenes/TanqueSherman"
const REGION_CANON := Rect2i(354, 98, 184, 25)


func _initialize() -> void:
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if imagen == null or imagen.is_empty():
		push_error("No se pudo abrir la textura fuente del tanque.")
		quit(1)
		return

	var directorio := DirAccess.open("res://")
	if directorio == null:
		push_error("No se pudo abrir el directorio del proyecto.")
		quit(1)
		return
	var error_directorio := directorio.make_dir_recursive("Imagenes/TanqueSherman")
	if error_directorio != OK and error_directorio != ERR_ALREADY_EXISTS:
		push_error("No se pudo crear la carpeta de capas visuales: %s." % error_string(error_directorio))
		quit(1)
		return

	var casco := imagen.duplicate()
	var canon := Image.create(imagen.get_width(), imagen.get_height(), false, Image.FORMAT_RGBA8)
	canon.fill(Color.TRANSPARENT)
	for y in range(REGION_CANON.position.y, REGION_CANON.end.y):
		for x in range(REGION_CANON.position.x, REGION_CANON.end.x):
			var pixel := imagen.get_pixel(x, y)
			canon.set_pixel(x, y, pixel)
			casco.set_pixel(x, y, Color.TRANSPARENT)

	var error_guardado: Error = casco.save_png(
		ProjectSettings.globalize_path(OUTPUT_DIR + "/TanqueM4Sherman_Casco.png")
	)
	if error_guardado == OK:
		error_guardado = canon.save_png(
			ProjectSettings.globalize_path(OUTPUT_DIR + "/TanqueM4Sherman_Canon.png")
		)
	if error_guardado != OK:
		push_error("No se pudieron guardar las capas del Sherman: %s." % error_string(error_guardado))
		quit(1)
		return

	print("Capas del Sherman escritas desde el original sin alterarlo.")
	quit()
