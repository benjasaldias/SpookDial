extends Button
## Un botón de pregunta del chat (Plan 9.3): el ícono de su categoría, su etiqueta corta y, a la derecha, lo que cuesta
## ("−5 s") y su marca: ✓ si ya se preguntó y la respuesta llegó entera, o la estática si llegó tapada y se puede
## repetir (decisiones de Benja, 11 de noviembre, tras el primer testeo). El chat elige la marca y si se puede apretar.

## La marca a la derecha: ninguna, ya preguntada (✓) o con la respuesta tapada (estática).
enum Mark { NONE, ASKED, STATIC }

const PixelText := preload("res://scripts/ui/pixel_text.gd")
const CHECK_ICON := preload("res://art/ui/chat_icon_check.png")
const STATIC_ICON := preload("res://art/ui/chat_icon_static.png")
## El lado de los íconos en el arte.
const ICON_PIXELS := 9
## Lo que separa la marca y el costo del borde derecho del botón.
const SIDE_MARGIN := 6
## El costo, en el rojo suave de lo que se pierde.
const COST_COLOR := Color(1.0, 0.45, 0.42)
## Sin poder preguntar, el costo y la marca se apagan como la letra.
const DIM_ALPHA := 0.45

var mark := Mark.NONE
## Lo que cuesta la pregunta, como se ve ("−5 s").
var cost_text := "":
	set(value):
		cost_text = value
		_cost.text = value

var _side: HBoxContainer
var _mark_icon: TextureRect
var _cost: Label


func _init() -> void:
	theme_type_variation = &"QuestionButton"
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	_side = HBoxContainer.new()
	_side.name = "Side"
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.alignment = BoxContainer.ALIGNMENT_END
	_side.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_side.offset_right = -SIDE_MARGIN
	add_child(_side)
	_mark_icon = TextureRect.new()
	_mark_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mark_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mark_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_side.add_child(_mark_icon)
	_cost = Label.new()
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost.add_theme_color_override(&"font_color", COST_COLOR)
	_side.add_child(_cost)
	resize_icons()
	show_state(Mark.NONE, false)


## Muestra la marca `new_mark` y si se puede preguntar (`enabled`). Una pregunta ya hecha no muestra su costo.
func show_state(new_mark: Mark, enabled: bool) -> void:
	mark = new_mark
	disabled = not enabled
	_mark_icon.visible = new_mark != Mark.NONE
	_mark_icon.texture = CHECK_ICON if new_mark == Mark.ASKED else STATIC_ICON
	_cost.visible = new_mark != Mark.ASKED
	_side.modulate.a = 1.0 if enabled or new_mark == Mark.ASKED else DIM_ALPHA


## Los íconos crecen con la letra, para seguir nítidos (PixelText).
func resize_icons() -> void:
	var side := PixelText.icon_size(ICON_PIXELS)
	add_theme_constant_override(&"icon_max_width", side)
	_mark_icon.custom_minimum_size = Vector2(side, side)
