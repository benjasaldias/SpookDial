extends "res://test/test_case.gd"

const DIAL := preload("res://scenes/desk/dial_gauge.tscn")


func _make_dial() -> Node2D:
	var dial := DIAL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(dial)
	return dial


func test_la_aguja_sigue_al_valor() -> bool:
	var dial := _make_dial()
	var needle := dial.get_node("Needle") as AnimatedSprite2D
	dial.value = 0.0
	check(is_equal_approx(needle.rotation_degrees, -120.0), "valor 0: %s" % needle.rotation_degrees)
	dial.value = 1.0
	check(is_equal_approx(needle.rotation_degrees, 120.0), "valor 1: %s" % needle.rotation_degrees)
	dial.free()
	return true


func test_color_de_la_aguja() -> bool:
	var dial := _make_dial()
	dial.needle_color = &"red"
	check_eq((dial.get_node("Needle") as AnimatedSprite2D).animation, &"red", "animación roja")
	dial.free()
	return true


func test_eje_de_giro_en_la_base_de_la_aguja() -> bool:
	var dial := _make_dial()
	var needle := dial.get_node("Needle") as AnimatedSprite2D
	check_eq(needle.position, Vector2(56, 56), "eje en el centro del dial")
	check_eq(needle.offset, Vector2(-7, -43), "píxel (7,43) del archivo sobre el eje")
	dial.free()
	return true
