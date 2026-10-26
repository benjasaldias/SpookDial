extends Node2D
## Escena principal del escritorio (Plan 1): las entradas del PC abren el panel del chat,
## y los clics en el cuaderno, el celular y el mixer solo se registran (sus paneles llegan en los planes 4 y 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel


func _ready() -> void:
	for entry in _entries:
		entry.pressed.connect(_on_entry_pressed.bind(entry))
	_chat_panel.visibility_changed.connect(_on_chat_visibility_changed)
	for clickable_name in ["Notebook", "Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void: print("Clic en ", clickable_name))


func _on_entry_pressed(entry: Node) -> void:
	for other in _entries:
		other.set_state(ChatEntry.State.SELECTED if other == entry else ChatEntry.State.IDLE)
	_chat_panel.open_for(entry.display_name)


func _on_chat_visibility_changed() -> void:
	if not _chat_panel.visible:
		for entry in _entries:
			entry.set_state(ChatEntry.State.IDLE)
