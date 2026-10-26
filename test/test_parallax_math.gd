extends "res://test/test_case.gd"

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")
const SCREEN := Vector2(1280, 720)
const MAX := Vector2(3, 2)


func test_mouse_al_centro_no_mueve() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(640, 360), SCREEN, MAX), Vector2i.ZERO, "centro")
	return true


func test_bordes_dan_el_maximo_en_la_direccion_del_mouse() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(1280, 360), SCREEN, MAX), Vector2i(3, 0), "borde derecho")
	check_eq(ParallaxMath.offset_for(Vector2(0, 0), SCREEN, MAX), Vector2i(-3, -2), "esquina superior izquierda")
	return true


func test_fuera_de_la_pantalla_se_limita() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(2000, -50), SCREEN, MAX), Vector2i(3, -2), "fuera")
	return true


func test_resultado_redondeado_a_pixel_entero() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(960, 360), SCREEN, MAX), Vector2i(2, 0), "a 3/4 del ancho: 1,5 → 2")
	return true
