extends Control
## La mancha de tinta del screamer del cuaderno (diseño §11): tapa la página unos segundos y se desvanece al
## final. La dibujó Claude en pixel art (tools/make_ui_art.py): salpica en 3 cuadros, y después los chorreones
## bajan de a poco por la hoja.

## Los cuadros de la salpicadura, del más chico a la mancha entera. Miden lo mismo que este nodo.
const FRAMES: Array[Texture2D] = [
	preload("res://art/ui/ink_blot_0.png"),
	preload("res://art/ui/ink_blot_1.png"),
	preload("res://art/ui/ink_blot_2.png"),
]
## Los chorreones que caen de la mancha: se descubren de arriba hacia abajo.
const DRIPS := preload("res://art/ui/ink_drips.png")
## Segundos que dura cada cuadro de la salpicadura.
const FRAME_SECONDS := 0.04
## Segundos que tardan los chorreones en bajar del todo, desde que la mancha está entera.
const DRIP_SECONDS := 1.6
## Segundos que tarda en desvanecerse, al final.
const FADE_SECONDS := 0.5

## Segundos que le quedan.
var time_left := 0.0
## Segundos desde que cayó.
var _elapsed := 0.0
## Dónde están los chorreones dentro de su imagen: lo de arriba es transparente.
var _drip_area := Rect2()


func _ready() -> void:
	hide()
	_drip_area = Rect2(DRIPS.get_image().get_used_rect())


## Aparece y tapa la página `seconds` segundos.
func splash(seconds: float) -> void:
	time_left = seconds
	_elapsed = 0.0
	modulate.a = 1.0
	show()
	queue_redraw()


func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	_elapsed += delta
	modulate.a = clampf(time_left / FADE_SECONDS, 0.0, 1.0)
	if time_left <= 0.0:
		hide()
	queue_redraw()


## Cuál cuadro de la salpicadura se ve ahora.
func frame() -> int:
	return mini(floori(_elapsed / FRAME_SECONDS), FRAMES.size() - 1)


## Cuánto de los chorreones se ve, de 0 a 1.
func drip_progress() -> float:
	var since_full := _elapsed - FRAME_SECONDS * (FRAMES.size() - 1)
	return clampf(since_full / DRIP_SECONDS, 0.0, 1.0)


func _draw() -> void:
	draw_texture(FRAMES[frame()], Vector2.ZERO)
	var height := roundf(_drip_area.end.y - _drip_area.size.y * (1.0 - ease(drip_progress(), 0.6)))
	if drip_progress() > 0.0 and height > 0.0:
		var region := Rect2(0, 0, DRIPS.get_width(), height)
		draw_texture_rect_region(DRIPS, region, region)
