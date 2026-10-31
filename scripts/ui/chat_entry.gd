extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, la vida, el estado y el temporizador.

signal pressed

enum State { IDLE, WARNING, DISCONNECTED, SELECTED, STUNNED }

const SIZE := Vector2(243, 26)
const STATE_MODULATE := {
	State.IDLE: Color(1, 1, 1),
	State.WARNING: Color(1, 1, 1),
	State.DISCONNECTED: Color(0.45, 0.45, 0.5),
	State.SELECTED: Color(1.3, 1.3, 1.3),
	State.STUNNED: Color(0.7, 0.6, 0.6),
}
## Lo que dice el temporizador mientras el amigo está aturdido (ui.csv). Lleva {seconds}.
const STUNNED_KEY := "ENTRY_STUNNED"
## Las marcas de vida son provisionales, hasta el arte de las entradas.
const HEALTH_PIP_SIZE := Vector2(6, 10)
const HEALTH_COLOR := Color(0.85, 0.9, 0.95)

@export var display_name := "":
	set(value):
		display_name = value
		if is_node_ready():
			_name_label.text = value

var state: State = State.IDLE
## La vida que muestra, de `max_health`. -1 hasta la primera vez.
var health := -1
var max_health := -1

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _health_box: HBoxContainer = $Health
@onready var _timer_label: Label = $TimerLabel


func _ready() -> void:
	_name_label.text = display_name
	set_state(State.IDLE)
	set_seconds_left(-1)


func set_state(new_state: State) -> void:
	state = new_state
	_background.play(&"warning" if new_state == State.WARNING else &"idle")
	_background.modulate = STATE_MODULATE[new_state]


## Muestra los segundos restantes. Con un valor negativo, oculta el temporizador.
func set_seconds_left(seconds: int) -> void:
	_timer_label.visible = seconds >= 0
	_timer_label.text = str(seconds)


## Muestra cuánto le queda de aturdimiento, en lugar del temporizador.
func show_stun(seconds: int) -> void:
	_timer_label.visible = true
	_timer_label.text = tr(STUNNED_KEY).format({"seconds": seconds})


## Una marca por punto de vida: llena si lo tiene y vacía (solo el borde) si lo perdió, para que no
## dependa del color (diseño §19). Solo se rehacen si la vida cambió.
func set_health(current: int, maximum: int) -> void:
	if current == health and maximum == max_health:
		return
	health = current
	max_health = maximum
	for pip: Node in _health_box.get_children():
		_health_box.remove_child(pip)
		pip.queue_free()
	for index in maximum:
		var pip := Panel.new()
		pip.custom_minimum_size = HEALTH_PIP_SIZE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.add_theme_stylebox_override(&"panel", _pip_style(index < current))
		_health_box.add_child(pip)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and Rect2(Vector2.ZERO, SIZE).has_point(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()


static func _pip_style(full: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEALTH_COLOR
	style.draw_center = full
	style.border_color = HEALTH_COLOR
	style.set_border_width_all(1)
	return style
