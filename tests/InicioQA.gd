extends Node

## Las plantillas release no admiten --script. Esta escena exclusiva del preset QA
## ejecuta las partidas con scripts compilados y recursos exportados reales.
func _ready() -> void:
	var arbol := get_tree()
	var suite := "test_terreno" if OS.get_cmdline_user_args().has("terreno") else "test_partidas"
	if OS.get_cmdline_user_args().has("selector_audio"):
		suite = "test_selector_audio"
	if OS.get_cmdline_user_args().has("contornos"):
		suite = "test_contornos"
	if OS.get_cmdline_user_args().has("pausa"):
		suite = "test_pausa"
	if OS.get_cmdline_user_args().has("economia"):
		suite = "test_economia"
	if OS.get_cmdline_user_args().has("rodaje"):
		suite = "test_rodaje"
	if OS.get_cmdline_user_args().has("videos"):
		suite = "test_videos"
	if OS.get_cmdline_user_args().has("informe"):
		suite = "test_informe"
	if OS.get_cmdline_user_args().has("audio"):
		suite = "test_audio"
	if OS.get_cmdline_user_args().has("resultados"):
		suite = "test_resultados"
	if OS.get_cmdline_user_args().has("musica"):
		suite = "test_musica"
	if OS.get_cmdline_user_args().has("grabar_audio"):
		suite = "grabar_audio"
	arbol.call_deferred("set_script", load("res://tests/%s.gd" % suite))
	arbol.call_deferred("_ejecutar_pruebas")
