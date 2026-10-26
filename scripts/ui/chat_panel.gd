extends Control
## Panel lateral del chat. En el Plan 1 solo se abre con el nombre del amigo y se cierra.
## Los mensajes, las preguntas y las respuestas llegan en el Plan 3.

@onready var _title: Label = $Panel/Title


func _ready() -> void:
	hide()


func open_for(friend_name: String) -> void:
	_title.text = friend_name
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var mouse := event as InputEventMouseButton
	var right_click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT
	if event.is_action_pressed(&"ui_cancel") or right_click:
		hide()
		get_viewport().set_input_as_handled()
