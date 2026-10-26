extends "res://test/test_case.gd"


func test_pantalla_1280x720_con_aspecto_fijo() -> bool:
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280, "ancho")
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 720, "alto")
	check_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")
	check_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "aspect")
	return true


func test_texturas_nearest_y_snap_a_pixel() -> bool:
	check_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "filtro Nearest")
	check_eq(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), true, "snap a píxel")
	return true


func test_escena_principal_es_el_escritorio() -> bool:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/desk/desk.tscn", "escena principal")
	return true
