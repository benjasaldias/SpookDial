extends Control
## Panel lateral del chat. En el Plan 1 solo se abre con el nombre del amigo y se cierra.
## Los mensajes, las preguntas y las respuestas llegan en el Plan 3.
## Se cierra con Esc, con clic derecho o con un clic izquierdo fuera del panel.

@onready var _panel: TextureRect = $Panel
@onready var _title: Label = $Panel/Title


func _ready() -> void:
	hide()


func open_for(friend_name: String) -> void:
	_title.text = friend_name
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		get_viewport().set_input_as_handled()
	elif mouse.button_index == MOUSE_BUTTON_LEFT and not _panel.get_global_rect().has_point(mouse.position):
		# No se consume el clic: si cae en otra entrada del PC, abre el chat de ese amigo.
		hide()
