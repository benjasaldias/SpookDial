extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo (parpadean
## y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación. El cuaderno se abre
## con un clic en él o en el nombre de la entidad, y muestra la página del amigo del chat. El chat y el
## cuaderno son independientes y pueden estar abiertos a la vez (decisión de Benja). Cada uno se cierra
## con clic derecho sobre él; Esc o un clic fuera de los paneles cierra los dos.
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, la viñeta oscurece
## la vista cuando baja Sanity, y al terminar la noche aparece una pantalla que explica qué pasó.
## Desde el Plan 6, un clic en el mixer abre su vista (Audio Sync) y uno en el celular, sus redes sociales.
## Son modos exclusivos: cierran los paneles y el otro modo, y abrir un panel los cierra (decisión de Benja).
## El botón «Sincronizar» del chat también abre el mixer, en el canal de ese amigo.
## Cuando se anuncia una interferencia, suena estática.

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
@onready var _end_screen: Control = $Overlay/EndScreen
@onready var _mixer: Control = $UI/MixerView
@onready var _phone: Control = $UI/PhoneView
@onready var _interference_sound: AudioStreamPlayer = $InterferenceSound

## Qué amigos tenían anunciada una interferencia en el frame anterior: la estática suena al empezar el aviso.
var _warned: Array[bool] = []


func _ready() -> void:
	var friends := _requests.catalog.friends
	notebook_memory = NotebookMemory.new(friends.size())
	_night.setup(_requests)
	_chat_panel.setup(_requests, friends, notebook_memory)
	_notebook_panel.setup(notebook_memory, _requests.catalog.known_entities(_requests.night_number), friends)
	_mixer.setup(_requests, friends)
	_phone.setup(_requests.state, _requests.catalog.phone_posts)
	_warned.resize(friends.size())
	_warned.fill(false)
	for index in _entries.size():
		_entries[index].display_name = tr(friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.friend_selected.connect(_notebook_panel.select_friend)
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
	_chat_panel.sync_requested.connect(open_mixer_for)
	_requests.request_started.connect(_on_request_started)
	_night.night_ended.connect(_on_night_ended)
	_end_screen.retry_pressed.connect(_on_retry_pressed)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
	$DeskPlane/Mixer.clicked.connect(open_mixer)
	$DeskPlane/Phone.clicked.connect(open_phone)


func _process(_delta: float) -> void:
	_refresh_entries()
	_refresh_meters()


## Cierra el chat y el cuaderno. El celular y el mixer se usan sin ningún panel abierto (decisión de Benja).
func close_panels() -> void:
	_chat_panel.hide()
	_notebook_panel.hide()


## Cierra el mixer y el celular.
func close_modes() -> void:
	_mixer.close()
	_phone.close()


## Audio Sync: el mixer se usa sin paneles y sin el celular.
func open_mixer() -> void:
	close_panels()
	_phone.close()
	_mixer.open()


## El botón «Sincronizar» del chat: el mixer se abre en el canal de ese amigo, con la ronda empezada.
func open_mixer_for(friend_index: int) -> void:
	close_panels()
	_phone.close()
	_mixer.open_for(friend_index)


## Las redes sociales: el celular se usa sin paneles y sin el mixer.
func open_phone() -> void:
	close_panels()
	_mixer.close()
	_phone.open()


## El escritorio es el último en recibir la entrada: aquí llega lo que nadie atendió. Las entradas del PC
## y los objetos del escritorio consumen sus clics, y los paneles, el mixer y el celular, los que caen sobre
## ellos. Esc o un clic fuera de ellos los cierra.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible or _mixer.visible or _phone.visible):
		return
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	if event.is_action_pressed(&"ui_cancel") or click:
		close_panels()
		close_modes()
		get_viewport().set_input_as_handled()


func _on_entry_pressed(index: int) -> void:
	close_modes()
	_chat_panel.open_for(index)
	_refresh_entries()


## Abre el cuaderno en la página del amigo del chat. El chat queda como estaba: abierto o cerrado.
func _open_notebook() -> void:
	close_modes()
	_notebook_panel.open_for(_chat_panel.selected_friend)


func _on_entity_page_requested(friend_index: int, entity: EntityData) -> void:
	notebook_memory.open_page(friend_index, entity)
	_notebook_panel.open_for(friend_index)


## Una solicitud nueva empieza en el índice: la página de la anterior casi nunca sirve (decisión de Benja).
func _on_request_started(friend_index: int, _request: FriendRequest) -> void:
	notebook_memory.close_page(friend_index)


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
## y el celular se cierran, para que la ronda de Audio Sync no siga sonando.
func _on_night_ended(ending: NightState.Ending, fatal_request: FriendRequest) -> void:
	close_modes()
	var names: Array[String] = []
	for friend: FriendData in _requests.catalog.friends:
		names.append(tr(friend.name_key))
	_end_screen.show_ending(ending, _requests.state, fatal_request, names)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5).
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta o la
## descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le queda para responder,
## para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y si viene una
## interferencia.
func _refresh_entries() -> void:
	var state := _requests.state
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := state.friends[index]
		var offer := state.videos.offer_for(index)
		var entry_state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			entry_state = ChatEntry.State.SELECTED
		elif not friend.is_online():
			entry_state = ChatEntry.State.DISCONNECTED
		elif request != null or offer != null:
			entry_state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			entry_state = ChatEntry.State.STUNNED
		if entry.state != entry_state:
			entry.set_state(entry_state)
		entry.set_health(friend.health, friend.max_health)
		entry.set_signal(friend.signal_level)
		var warning := state.interference_warning(index)
		entry.set_interference_warning(warning)
		if warning and not _warned[index]:
			_interference_sound.play()
		_warned[index] = warning
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif offer != null:
			entry.show_video(ceili(offer.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		elif not friend.is_online():
			entry.show_offline()
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
