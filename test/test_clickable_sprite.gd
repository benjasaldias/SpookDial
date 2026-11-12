extends "res://test/test_case.gd"

const CLICKABLE := preload("res://scripts/desk/clickable_sprite.gd")
const PixelHit := preload("res://scripts/desk/pixel_hit.gd")


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


func test_parpadea_cuando_pide_atencion() -> bool:
	var phone := _make_phone()
	# Lejos del mouse, para que no se resalte.
	phone.position = Vector2(5000, 5000)
	var material := phone.material as ShaderMaterial
	phone.blinking = true
	phone._process(0.1)
	check_eq(material.get_shader_parameter("enabled"), true, "encendido")
	phone._process(0.4)
	check_eq(material.get_shader_parameter("enabled"), false, "apagado")
	phone._process(0.4)
	check_eq(material.get_shader_parameter("enabled"), true, "encendido otra vez")
	phone.blinking = false
	phone._process(0.1)
	check_eq(material.get_shader_parameter("enabled"), false, "deja de parpadear")
	phone.free()
	return true


## Las cortinas abiertas se clickean también en el hueco de la ventana: el clic usa el dibujo de las cerradas.
func test_el_clic_puede_usar_el_dibujo_de_otra_animacion() -> bool:
	var curtains := AnimatedSprite2D.new()
	curtains.set_script(CLICKABLE)
	curtains.sprite_frames = load("res://art/sprites/curtains_sprite.aseprite")
	curtains.animation = &"Open"
	curtains.centered = false
	curtains.hit_animation = &"Closed"
	(Engine.get_main_loop() as SceneTree).root.add_child(curtains)
	check(PixelHit.is_opaque(curtains._bitmap, Vector2(170, 200)), "el hueco de la ventana recibe el clic")
	curtains.free()
	return true


## Bloqueado (en la noche 0, hasta que León lo use), no se resalta ni recibe clics (Plan 9.5).
func test_bloqueado_no_responde() -> bool:
	var phone := _make_phone()
	var received := [false]
	phone.clicked.connect(func() -> void: received[0] = true)
	phone.hovered = true
	phone.enabled = false
	check(not phone.hovered, "al bloquearse deja de estar resaltado")
	check_eq((phone.material as ShaderMaterial).get_shader_parameter("enabled"), false, "sin contorno")
	phone.hovered = true
	check(not phone.hovered, "no se resalta")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	phone._unhandled_input(click)
	check(not received[0], "no emite clicked")
	phone.free()
	return true
