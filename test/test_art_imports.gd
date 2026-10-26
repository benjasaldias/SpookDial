extends "res://test/test_case.gd"

const SPRITES := "res://art/sprites/"


func test_sprites_importados_como_spriteframes() -> bool:
	for sprite_name in ["background", "exterior", "curtains", "window", "enemy", "glasspane", "dial",
			"arrow", "desk", "cables", "mixer", "phone", "pc", "entry", "microphone", "notebook"]:
		var resource := load(SPRITES + sprite_name + "_sprite.aseprite")
		check(resource is SpriteFrames, sprite_name + " debería importarse como SpriteFrames")
	return true


func test_pc_sin_capas_de_entradas() -> bool:
	var frames: SpriteFrames = load(SPRITES + "pc_sprite.aseprite")
	var image := frames.get_frame_texture(&"default", 0).get_image()
	# (150, 30) está dentro de Entry1: con la capa sería azul (37, 47, 153); sin ella, pantalla negra.
	check(image.get_pixel(150, 30).b < 0.4, "la zona de Entry1 no debería ser azul")
	return true


func test_panel_como_textura() -> bool:
	var panel: Variant = load(SPRITES + "screen_sprite.aseprite")
	check(panel is Texture2D, "screen_sprite debería ser Texture2D")
	if panel is Texture2D:
		check_eq(panel.get_size(), Vector2(449, 696), "tamaño del panel")
	return true
