extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo (parpadean
## y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación. El cuaderno se abre
## con un clic en él o en el nombre de la entidad, y muestra la página del amigo del chat. El chat y el
## cuaderno son independientes y pueden estar abiertos a la vez (decisión de Benja). Cada uno se cierra
## con clic derecho sobre él; Esc o un clic fuera de los paneles cierra los dos.
## Un clic en el celular o el mixer cierra los paneles y por ahora solo se registra (sus vistas, en el Plan 6).
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, y la viñeta oscurece
## la vista cuando baja Sanity.

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const DialGauge := preload("res://scripts/desk/dial_gauge.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Videos recibidos, en el PC (ui.csv). Lleva {received} y {quota}.
const VIDEOS_KEY := "PC_VIDEOS"

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
var notebook_memory: NotebookMemory

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _notebook_panel: Control = $UI/NotebookPanel
@onready var _requests: RequestManager = $RequestManager
@onready var _night: NightManager = $NightManager
@onready var _dial_connection: DialGauge = $WallPlane/DialConnection
@onready var _dial_sanity: DialGauge = $WallPlane/DialSanity
@onready var _dial_trust: DialGauge = $WallPlane/DialTrust
@onready var _clock: Label = $DeskPlane/Phone/Clock
@onready var _videos: Label = $DeskPlane/PC/Videos
@onready var _vignette: ColorRect = $Overlay/Vignette


func _ready() -> void:
	var friends := _requests.catalog.friends
	notebook_memory = NotebookMemory.new(friends.size())
	_night.setup(_requests)
	_chat_panel.setup(_requests, friends, notebook_memory)
	_notebook_panel.setup(notebook_memory, _requests.catalog.known_entities(_requests.night_number), friends)
	for index in _entries.size():
		_entries[index].display_name = tr(friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.friend_selected.connect(_notebook_panel.select_friend)
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
	_requests.request_started.connect(_on_request_started)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
	for clickable_name in ["Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void:
			close_panels()
			print("Clic en ", clickable_name))


func _process(_delta: float) -> void:
	_refresh_entries()
	_refresh_meters()


## Cierra el chat y el cuaderno. El celular y el mixer se usan sin ningún panel abierto (decisión de Benja).
func close_panels() -> void:
	_chat_panel.hide()
	_notebook_panel.hide()


## El escritorio es el último en recibir la entrada: aquí llega lo que nadie atendió. Las entradas del PC
## y los objetos del escritorio consumen sus clics, y los paneles, los que caen sobre ellos.
## Esc o un clic fuera de los paneles los cierra.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible):
		return
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	if event.is_action_pressed(&"ui_cancel") or click:
		close_panels()
		get_viewport().set_input_as_handled()


func _on_entry_pressed(index: int) -> void:
	_chat_panel.open_for(index)
	_refresh_entries()


## Abre el cuaderno en la página del amigo del chat. El chat queda como estaba: abierto o cerrado.
func _open_notebook() -> void:
	_notebook_panel.open_for(_chat_panel.selected_friend)


func _on_entity_page_requested(friend_index: int, entity: EntityData) -> void:
	notebook_memory.open_page(friend_index, entity)
	_notebook_panel.open_for(friend_index)


## Una solicitud nueva empieza en el índice: la página de la anterior casi nunca sirve (decisión de Benja).
func _on_request_started(friend_index: int, _request: FriendRequest) -> void:
	notebook_memory.close_page(friend_index)


## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta, o más oscura si el amigo
## está aturdido. El tiempo que le queda para responder o para recuperarse, y su vida.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := _requests.state.friends[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			state = ChatEntry.State.STUNNED
		if entry.state != state:
			entry.set_state(state)
		entry.set_health(friend.health, friend.max_health)
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		else:
			entry.set_seconds_left(-1)


## Los diales (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del PC
## y la viñeta de Sanity.
func _refresh_meters() -> void:
	var state := _requests.state
	_dial_connection.value = state.connection() / NightState.METER_MAX
	_dial_sanity.value = state.sanity / NightState.METER_MAX
	_dial_trust.value = state.trust / NightState.METER_MAX
	_clock.text = state.clock_text()
	_videos.text = tr(VIDEOS_KEY).format({"received": state.videos.received, "quota": state.videos.quota})
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", state.vignette_strength())
