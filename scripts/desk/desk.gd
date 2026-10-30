extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo
## (parpadean y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación.
## Los clics en el cuaderno, el celular y el mixer solo se registran (sus paneles llegan en los planes 4 y 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _requests: RequestManager = $RequestManager


func _ready() -> void:
	_chat_panel.setup(_requests, _requests.catalog.friends)
	for index in _entries.size():
		_entries[index].display_name = tr(_requests.catalog.friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.entity_page_requested.connect(func(_friend_index: int, entity: EntityData) -> void:
		print("Abrir en el cuaderno la página de ", tr(entity.name_key), " (Plan 4)"))
	for clickable_name in ["Notebook", "Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void: print("Clic en ", clickable_name))


func _process(_delta: float) -> void:
	_refresh_entries()


func _on_entry_pressed(index: int) -> void:
	_chat_panel.open_for(index)
	_refresh_entries()


## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta. El tiempo, mientras espera.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		if entry.state != state:
			entry.set_state(state)
		entry.set_seconds_left(ceili(request.time_left) if request != null else -1)
