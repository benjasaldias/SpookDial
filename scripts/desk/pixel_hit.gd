extends RefCounted
## Prueba si un punto local cae sobre un píxel visible de una textura.


static func bitmap_from_texture(texture: Texture2D) -> BitMap:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image(), 0.1)
	return bitmap


static func is_opaque(bitmap: BitMap, local_position: Vector2) -> bool:
	var point := Vector2i(local_position.floor())
	var size := bitmap.get_size()
	if point.x < 0 or point.y < 0 or point.x >= size.x or point.y >= size.y:
		return false
	return bitmap.get_bitv(point)
