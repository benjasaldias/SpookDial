extends "res://test/test_case.gd"

const PixelHit := preload("res://scripts/desk/pixel_hit.gd")


func _bitmap_with_one_pixel() -> BitMap:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.set_pixel(1, 1, Color.WHITE)
	return PixelHit.bitmap_from_texture(ImageTexture.create_from_image(image))


func test_pixel_opaco_y_transparente() -> bool:
	var bitmap := _bitmap_with_one_pixel()
	check(PixelHit.is_opaque(bitmap, Vector2(1.5, 1.2)), "(1,1) es opaco")
	check(not PixelHit.is_opaque(bitmap, Vector2(2, 2)), "(2,2) es transparente")
	return true


func test_fuera_de_la_imagen_no_es_opaco() -> bool:
	var bitmap := _bitmap_with_one_pixel()
	check(not PixelHit.is_opaque(bitmap, Vector2(-1, 0)), "x negativa")
	check(not PixelHit.is_opaque(bitmap, Vector2(10, 10)), "más allá del borde")
	return true


func test_esquinas_reales_del_celular() -> bool:
	var frames: SpriteFrames = load("res://art/sprites/phone_sprite.aseprite")
	var bitmap := PixelHit.bitmap_from_texture(frames.get_frame_texture(&"default", 0))
	check(not PixelHit.is_opaque(bitmap, Vector2(0, 0)), "la esquina (0,0) del celular es transparente")
	check(PixelHit.is_opaque(bitmap, Vector2(43, 27)), "el centro del celular es opaco")
	return true
