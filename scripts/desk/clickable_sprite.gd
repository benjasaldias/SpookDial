extends AnimatedSprite2D
## Objeto del escritorio que se resalta al pasar el mouse y emite `clicked`. Desde el Plan 7, su contorno
## también puede parpadear para pedir atención (así se enseña el celular, decisión de Benja).
## Para sprites de un solo frame con centered = false.

signal clicked

## La animación cuyo dibujo recibe los clics. Vacía: la que tiene el sprite. Así las cortinas abiertas se clickean
## también en el hueco de la ventana.
@export var hit_animation: StringName

const PixelHit := preload("res://scripts/desk/pixel_hit.gd")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
## Segundos que el contorno está encendido, y después apagado, mientras parpadea.
const BLINK_SECONDS := 0.4

var hovered := false:
	set(value):
		if value == hovered:
			return
		hovered = value
		_refresh_outline()

## Pide atención: el contorno parpadea hasta que se apague.
var blinking := false:
	set(value):
		blinking = value
		_blink_time = 0.0

var _bitmap: BitMap
var _blink_time := 0.0


func _ready() -> void:
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("enabled", false)
	material = outline
	var drawing := animation if hit_animation.is_empty() else hit_animation
	_bitmap = PixelHit.bitmap_from_texture(sprite_frames.get_frame_texture(drawing, 0))


func _process(delta: float) -> void:
	_blink_time += delta
	# Si un panel abierto (como el chat) tapa el objeto, el mouse está sobre el panel: no se resalta.
	hovered = is_visible_in_tree() and get_viewport().gui_get_hovered_control() == null \
			and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)
	_refresh_outline()


## El contorno se ve con el mouse encima o, si parpadea, en la mitad encendida de cada parpadeo.
func _refresh_outline() -> void:
	if material == null:
		return
	var blink_on := blinking and fmod(_blink_time, BLINK_SECONDS * 2.0) < BLINK_SECONDS
	(material as ShaderMaterial).set_shader_parameter("enabled", hovered or blink_on)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if hovered and mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		get_viewport().set_input_as_handled()
