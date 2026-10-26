extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, el estado y el temporizador.

signal pressed

enum State { IDLE, WARNING, DISCONNECTED, SELECTED }

const SIZE := Vector2(243, 26)
const STATE_MODULATE := {
	State.IDLE: Color(1, 1, 1),
	State.WARNING: Color(1, 1, 1),
	State.DISCONNECTED: Color(0.45, 0.45, 0.5),
	State.SELECTED: Color(1.3, 1.3, 1.3),
}

@export var display_name := "":
	set(value):
		display_name = value
		if is_node_ready():
			_name_label.text = value

var state: State = State.IDLE

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
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


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and Rect2(Vector2.ZERO, SIZE).has_point(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()
