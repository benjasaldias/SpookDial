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
## Desde el Plan 7 suena el ambiente del cuarto, y los screamers (ScreamerManager) asustan con lo que se ve
## del escritorio, con el cuaderno y con la criatura de la ventana. En un chat guionado, la entrada del amigo avisa mientras
## espera la respuesta de Matías, y si el guion lo pide, el celular parpadea hasta que Matías lo abre.
## Desde el Plan 8, en la noche 0 (el tutorial) un aviso arriba de la pantalla dice qué hacer en cada paso
## (TutorialGuide), y la noche termina al cerrar el celular. El aviso tiene un botón para saltar el tutorial.
## Con Esc y sin nada abierto, la noche se pausa y aparece el menú de pausa (decisión de Benja, sesión 18).
## Desde el Plan 9, unas barras arriba de la pantalla muestran lo mismo que los diales, que se quedan (decisión de
## Benja). Las cortinas se abren y se cierran con un clic (ScreamerManager), y la batería del celular se ve en su
## barra.

## Se apretó "Saltar tutorial": el juego pasa a la noche 1.
signal tutorial_skipped
## Los botones de la pantalla final: empezar la noche siguiente, reintentar la noche o volver al menú.
## Los atiende GameState.
signal next_night_requested
signal retry_requested
signal menu_requested
## Cambió una opción desde el menú de pausa: GameState la guarda.
signal settings_changed(settings: GameSettings)

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const DialGauge := preload("res://scripts/desk/dial_gauge.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const Screamer := preload("res://scripts/core/screamer.gd")
const ScreamerManager := preload("res://scripts/desk/screamer_manager.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")

## Videos recibidos, en el PC (ui.csv). Lleva {received} y {quota}.
const VIDEOS_KEY := "PC_VIDEOS"

## El largo de la barra de batería del celular del escritorio, llena.
const BATTERY_BAR_WIDTH := 44.0

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
@onready var _battery_bar: ColorRect = $DeskPlane/Phone/BatteryBar
@onready var _videos: Label = $DeskPlane/PC/Videos
@onready var _vignette: ColorRect = $Overlay/Vignette
@onready var _stat_bars: Control = $Overlay/StatBars
@onready var _end_screen: Control = $Overlay/EndScreen
@onready var _mixer: Control = $UI/MixerView
@onready var _phone: Control = $UI/PhoneView
@onready var _interference_sound: AudioStreamPlayer = $InterferenceSound
@onready var _screamers: ScreamerManager = $Screamers
@onready var _phone_sprite: AnimatedSprite2D = $DeskPlane/Phone
@onready var _tutorial_hint: Control = $Overlay/TutorialHint
@onready var _pause_menu: Control = $Overlay/PauseMenu

## Las opciones del jugador que se aplicaron; el menú de pausa las cambia.
var _settings := GameSettings.new()

## El guía del tutorial en la noche 0, o null en las demás.
var _guide: TutorialGuide

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
	_screamers.setup(_requests, _night)
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
	_requests.chat_script_finished.connect(_on_chat_script_finished)
	_night.night_ended.connect(_on_night_ended)
	_end_screen.retry_pressed.connect(_on_retry_pressed)
	_end_screen.next_pressed.connect(next_night_requested.emit)
	_end_screen.menu_pressed.connect(menu_requested.emit)
	$WallPlane/Curtains.clicked.connect(_screamers.toggle_curtains)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
	$DeskPlane/Mixer.clicked.connect(open_mixer)
	$DeskPlane/Phone.clicked.connect(open_phone)
	if _requests.night().is_tutorial():
		_guide = TutorialGuide.new()
		_requests.request_finished.connect(func(_friend_index: int, request: FriendRequest) -> void:
			_guide.request_finished(request))
		_phone.visibility_changed.connect(_on_phone_visibility_changed)
		_tutorial_hint.skip_pressed.connect(tutorial_skipped.emit)
		_guide.explain_dials = true
		_tutorial_hint.ok_pressed.connect(_guide.dials_understood)
	_tutorial_hint.visible = _guide != null
	_pause_menu.resumed.connect(func() -> void: get_tree().paused = false)
	_pause_menu.menu_pressed.connect(menu_requested.emit)
	_pause_menu.settings_changed.connect(_on_pause_settings_changed)


func _process(delta: float) -> void:
	_refresh_entries()
	_refresh_meters()
	_screamers.advance(delta, _scare_view(), _mixer.is_playing() or _chat_panel.is_audio_playing())
	if _guide != null:
		_refresh_tutorial()


## Lo que se ve del escritorio, para elegir un screamer: el chat, el mixer y el celular ampliado tapan la
## ventana y el celular del escritorio.
func _scare_view() -> Screamer.View:
	var view := Screamer.View.new()
	view.desk_visible = not (_chat_panel.visible or _mixer.visible or _phone.visible)
	view.panel_open = _chat_panel.visible or _mixer.visible
	view.curtains_closed = _requests.state.curtains_closed
	view.notebook_open = _notebook_panel.visible
	view.notebook_page = _notebook_panel.shows_page()
	return view


## Aplica las opciones del jugador (diseño §19): menos destellos, la cámara fija y más tiempo para responder.
func apply_settings(settings: GameSettings) -> void:
	_settings = settings
	for entry: Node in _entries:
		entry.reduce_flashes = settings.reduce_flashes
	_mixer.reduce_flashes = settings.reduce_flashes
	_screamers.reduce_flashes = settings.reduce_flashes
	_stat_bars.reduce_flashes = settings.reduce_flashes
	$LookCamera.set_look(not settings.still_camera)
	_requests.timer_scale = settings.timer_scale()
	_chat_panel.audio_captions = settings.audio_captions


## Pausa la noche y abre el menú de pausa. Una noche que terminó no se pausa.
func pause() -> void:
	if _night.ended:
		return
	get_tree().paused = true
	_pause_menu.open(_settings)


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


## Las redes sociales: el celular se usa sin paneles y sin el mixer. Si parpadeaba, ya cumplió.
func open_phone() -> void:
	close_panels()
	_mixer.close()
	_phone_sprite.blinking = false
	_phone.open()
	if _guide != null:
		_guide.phone_opened()


## El escritorio es el último en recibir la entrada: aquí llega lo que nadie atendió. Las entradas del PC
## y los objetos del escritorio consumen sus clics, y los paneles, el mixer y el celular, los que caen sobre
## ellos. Esc o un clic fuera de ellos los cierra. Sin nada abierto, Esc pausa la noche.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible or _mixer.visible or _phone.visible):
		if event.is_action_pressed(&"ui_cancel"):
			pause()
			get_viewport().set_input_as_handled()
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


## Terminó un chat guionado: si su guion lo pide, el celular parpadea hasta que Matías lo abre (así se enseña
## que el celular calma, decisión de Benja).
func _on_chat_script_finished(chat: RefCounted) -> void:
	if chat.data.highlight_phone:
		_phone_sprite.blinking = true
		if _guide != null:
			_guide.phone_highlighted()


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
## y el celular se cierran, para que la ronda de Audio Sync no siga sonando.
func _on_night_ended(ending: NightState.Ending, fatal_request: FriendRequest) -> void:
	close_modes()
	_tutorial_hint.hide()
	var names: Array[String] = []
	for friend: FriendData in _requests.catalog.friends:
		names.append(tr(friend.name_key))
	var night_number := _requests.night_number
	var pages: Array[String] = []
	if ending == NightState.Ending.WON and night_number < _requests.catalog.nights.size():
		for entity: EntityData in _requests.catalog.new_pages(night_number + 1):
			pages.append(tr(entity.name_key))
	_end_screen.show_ending(ending, _requests.state, fatal_request, names, night_number, pages)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5). La reinicia
## GameState; si el escritorio se abrió solo, desde el editor, se recarga la escena.
func _on_retry_pressed() -> void:
	if retry_requested.get_connections().is_empty():
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()


## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta (también en
## un chat guionado) o la descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le
## queda para responder, para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y
## si viene una interferencia.
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
		elif request != null or offer != null or _requests.chat_script_reply(index) != null:
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


## Los diales y las barras (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del
## PC y la viñeta de Sanity.
func _refresh_meters() -> void:
	var state := _requests.state
	_dial_connection.value = state.connection() / NightState.METER_MAX
	_dial_sanity.value = state.sanity / NightState.METER_MAX
	_dial_trust.value = state.trust / NightState.METER_MAX
	_stat_bars.set_values(state.connection(), state.sanity, state.trust)
	_clock.text = state.clock_text()
	_battery_bar.size.x = roundf(BATTERY_BAR_WIDTH * state.battery / NightState.METER_MAX)
	_videos.text = tr(VIDEOS_KEY).format({"received": state.videos.received, "quota": state.videos.quota})
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", state.vignette_strength())


## El aviso del tutorial: qué hacer ahora. Cuando Matías termina de usar el celular, el tutorial se gana.
func _refresh_tutorial() -> void:
	if _night.ended:
		return
	var hint := _guide.hint(_tutorial_view())
	var friend_name := ""
	if hint.friend_index >= 0:
		friend_name = tr(_requests.catalog.friends[hint.friend_index].name_key)
	_tutorial_hint.show_text(tr(hint.key).format({"friend": friend_name}) if not hint.key.is_empty() else "",
			hint.needs_ok)
	if _guide.is_done():
		_night.finish(NightState.Ending.WON)


## Lo que el guía necesita ver: la solicitud en curso, el chat abierto, la página de ese amigo, el video que
## espera, el chat guionado, la criatura y las cortinas.
func _tutorial_view() -> TutorialGuide.View:
	var view := TutorialGuide.View.new()
	var state := _requests.state
	view.chat_friend = _chat_panel.selected_friend if _chat_panel.visible else -1
	view.creature_at_window = state.creature_outside and not state.curtains_closed
	view.curtains_closed = state.curtains_closed
	for index in _requests.requests.size():
		if _requests.requests[index] != null:
			view.request = _requests.requests[index]
			view.page = notebook_memory.page_for(index)
		if _requests.chat_script_reply(index) != null:
			view.script_friend = index
	if not state.videos.offers.is_empty():
		view.video_friend = state.videos.offers[0].friend_index
	return view


func _on_phone_visibility_changed() -> void:
	if not _phone.visible:
		_guide.phone_closed()


func _on_pause_settings_changed(settings: GameSettings) -> void:
	apply_settings(settings)
	settings_changed.emit(settings)
