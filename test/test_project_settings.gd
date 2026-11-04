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


## Desde el Plan 8, el juego empieza en el menú principal, y GameState lo lleva de noche en noche.
func test_escena_principal_es_el_menu() -> bool:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/menu/main_menu.tscn", "escena principal")
	check_eq(ProjectSettings.get_setting("autoload/GameState"), "*res://scripts/autoload/game_state.gd", "autoload")
	return true
