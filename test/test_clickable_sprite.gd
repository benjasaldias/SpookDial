extends "res://test/test_case.gd"

const CLICKABLE := preload("res://scripts/desk/clickable_sprite.gd")


func _make_phone() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.set_script(CLICKABLE)
	sprite.sprite_frames = load("res://art/sprites/phone_sprite.aseprite")
	sprite.centered = false
	(Engine.get_main_loop() as SceneTree).root.add_child(sprite)
	return sprite


func test_usa_el_shader_de_contorno_apagado() -> bool:
	var phone := _make_phone()
	var material := phone.material as ShaderMaterial
	check(material != null, "tiene ShaderMaterial")
	if material:
		check_eq(material.get_shader_parameter("enabled"), false, "contorno apagado al inicio")
	phone.free()
	return true


func test_resaltado_enciende_el_contorno() -> bool:
	var phone := _make_phone()
	phone.hovered = true
	check_eq((phone.material as ShaderMaterial).get_shader_parameter("enabled"), true, "contorno encendido")
	phone.free()
	return true


func test_clic_con_resaltado_emite_clicked() -> bool:
	var phone := _make_phone()
	var received := [false]
	phone.clicked.connect(func() -> void: received[0] = true)
	phone.hovered = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	phone._unhandled_input(click)
	check(received[0], "emitió clicked")
	phone.free()
	return true
