extends "res://test/test_case.gd"

const THEME := preload("res://scenes/ui/chat_theme.tres")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ENTRY := preload("res://scenes/ui/chat_entry.tscn")
const FONT_PATH := "res://fonts/departure_mono/DepartureMono-Regular.otf"


func test_la_fuente_del_chat_es_pixel() -> bool:
	var font := THEME.default_font as FontFile
	check(font != null and font.resource_path == FONT_PATH, "Departure Mono")
	check_eq(THEME.default_font_size % 11, 0, "se ve nítida en múltiplos de 11 px")
	if font != null:
		check_eq(font.antialiasing, TextServer.FONT_ANTIALIASING_NONE, "sin suavizado, como el pixel art")
		check(font.has_char(0x2592), "tiene ▒ para la estática")
		for character: String in "áéíóúñÑ¿¡…•":
			check(font.has_char(character.unicode_at(0)), "tiene %s" % character)
	return true


func test_la_licencia_de_la_fuente_va_con_ella() -> bool:
	check(FileAccess.file_exists("res://fonts/departure_mono/OFL.txt"), "la licencia OFL pide incluirla")
	return true


func test_el_fondo_y_las_lineas_no_tapan_los_clics() -> bool:
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	var screen := panel.get_node_or_null("Screen") as Control
	var scanlines := panel.get_node_or_null("Panel/Scanlines") as Control
	check(screen != null and screen.mouse_filter == Control.MOUSE_FILTER_IGNORE, "el fondo oscuro detrás del vidrio")
	check(scanlines != null and scanlines.mouse_filter == Control.MOUSE_FILTER_IGNORE, "las líneas de la pantalla")
	panel.free()
	return true


func test_las_entradas_del_pc_usan_la_misma_fuente() -> bool:
	var entry := ENTRY.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(entry)
	for label_name: String in ["NameLabel", "TimerLabel"]:
		var font := (entry.get_node(label_name) as Label).get_theme_font(&"font")
		check(font != null and font.resource_path == FONT_PATH, label_name)
	entry.free()
	return true
