extends AnimatedSprite2D
## Objeto del escritorio que se resalta al pasar el mouse y emite `clicked`.
## Para sprites de un solo frame con centered = false.

signal clicked

const PixelHit := preload("res://scripts/desk/pixel_hit.gd")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")

var hovered := false:
	set(value):
		if value == hovered:
			return
		hovered = value
		(material as ShaderMaterial).set_shader_parameter("enabled", value)

var _bitmap: BitMap


func _ready() -> void:
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("enabled", false)
	material = outline
	_bitmap = PixelHit.bitmap_from_texture(sprite_frames.get_frame_texture(animation, 0))


func _process(_delta: float) -> void:
	hovered = is_visible_in_tree() and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if hovered and mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		get_viewport().set_input_as_handled()
