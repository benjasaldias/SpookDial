extends "res://test/test_case.gd"

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")
const SCREEN := Vector2(1280, 720)
const ZOOM := 1.05


func test_mouse_al_centro_no_mueve() -> bool:
	check_eq(ParallaxMath.camera_offset_for(Vector2(640, 360), SCREEN, ZOOM), Vector2.ZERO, "centro")
	return true


func test_la_camara_mira_hacia_el_mouse_hasta_el_margen_del_zoom() -> bool:
	var margin := SCREEN * 0.5 * (1.0 - 1.0 / ZOOM)
	var right := ParallaxMath.camera_offset_for(Vector2(1280, 360), SCREEN, ZOOM)
	var top_left := ParallaxMath.camera_offset_for(Vector2(0, 0), SCREEN, ZOOM)
	check(right.is_equal_approx(Vector2(margin.x, 0)), "borde derecho: %s" % right)
	check(top_left.is_equal_approx(-margin), "esquina superior izquierda: %s" % top_left)
	return true


func test_fuera_de_la_pantalla_se_limita() -> bool:
	var margin := SCREEN * 0.5 * (1.0 - 1.0 / ZOOM)
	var outside := ParallaxMath.camera_offset_for(Vector2(2000, -50), SCREEN, ZOOM)
	check(outside.is_equal_approx(Vector2(margin.x, -margin.y)), "fuera: %s" % outside)
	return true


func test_sin_zoom_no_mueve() -> bool:
	check_eq(ParallaxMath.camera_offset_for(Vector2(0, 0), SCREEN, 1.0), Vector2.ZERO, "zoom 1")
	return true


func test_todo_punto_de_la_escena_es_alcanzable() -> bool:
	# El punto de la escena bajo el mouse coincide con la posición del mouse, como sin zoom.
	for mouse: Vector2 in [Vector2(0, 0), Vector2(1279, 719), Vector2(1100, 600), Vector2(30, 700), Vector2(640, 360)]:
		var camera_center := SCREEN * 0.5 + ParallaxMath.camera_offset_for(mouse, SCREEN, ZOOM)
		var world_point := camera_center + (mouse - SCREEN * 0.5) / ZOOM
		check(world_point.distance_to(mouse) < 0.01, "mouse %s → escena %s" % [mouse, world_point])
	return true
