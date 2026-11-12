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
## En la noche 0 (el tutorial), desde el Plan 9.2, León enseña en su chat (RequestManager y TutorialChat), con la página
## de Gonzalo, la única del cuaderno esa noche. Cuando se despide, unas tarjetas con videos enseñan los medidores, el
## celular, la ventana y la Mano, y después el juego pasa a la noche 1. "Saltar tutorial" está en la pausa (decisiones
## de Benja, 11 de noviembre).
## Con Esc y sin nada abierto, la noche se pausa y aparece el menú de pausa (decisión de Benja, sesión 18).
## Desde el Plan 9, unas barras arriba de la pantalla muestran lo mismo que los diales, que se quedan (decisión de
## Benja). Las cortinas se abren y se cierran con un clic (ScreamerManager), y la batería del celular se ve en su
## barra.
## Desde el Plan 9.1, la Mano (HandManager) asoma por la derecha hacia un dial, y la linterna del celular la espanta
## (decisión de Benja, 11 de noviembre).

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
const HandManager := preload("res://scripts/desk/hand_manager.gd")

## Videos recibidos, en el PC (ui.csv). Lleva {received} y {quota}. Si ya no alcanzan la cuota, el otro texto, en
## rojo (decisión de Benja, 11 de noviembre).
const VIDEOS_KEY := "PC_VIDEOS"
const VIDEOS_SHORT_KEY := "PC_VIDEOS_SHORT"
const VIDEOS_SHORT_COLOR := Color(1.0, 0.3, 0.37)

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
@onready var _hands: HandManager = $Hands
@onready var _phone_sprite: AnimatedSprite2D = $DeskPlane/Phone
@onready var _pause_menu: Control = $Overlay/PauseMenu
@onready var _tutorial_cards: Control = $Overlay/TutorialCards

## Las opciones del jugador que se aplicaron; el menú de pausa las cambia.
var _settings := GameSettings.new()


## Qué amigos tenían anunciada una interferencia en el frame anterior: la estática suena al empezar el aviso.
var _warned: Array[bool] = []

## El color de los videos del PC cuando alcanzan.
var _videos_color := Color.WHITE


func _ready() -> void:
	var friends := _requests.catalog.friends
	_videos_color = _videos.get_theme_color(&"font_color")
	notebook_memory = NotebookMemory.new(friends.size())
	_night.setup(_requests)
	_chat_panel.setup(_requests, friends, notebook_memory)
	_notebook_panel.setup(notebook_memory, _requests.catalog.known_entities(_requests.night_number,
			_requests.difficulty), friends)
	_mixer.setup(_requests, friends)
	_phone.setup(_requests.state, _requests.catalog.phone_posts, _requests.catalog.phone_disturbing_posts)
	_screamers.setup(_requests, _night)
	_hands.setup(_requests, _night, _screamers)
	_screamers.hands = _hands
	_phone.flash_pressed.connect(_hands.flash)
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
		notebook_memory.page_changed.connect(_on_tutorial_page_changed)
		_requests.tutorial_finished.connect(_on_tutorial_finished)
		_tutorial_cards.finished.connect(next_night_requested.emit)
	_pause_menu.allow_skip_tutorial(_requests.night().is_tutorial())
	_pause_menu.skip_tutorial_pressed.connect(tutorial_skipped.emit)
	_pause_menu.resumed.connect(func() -> void: get_tree().paused = false)
	_pause_menu.menu_pressed.connect(menu_requested.emit)
	_pause_menu.settings_changed.connect(_on_pause_settings_changed)


func _process(delta: float) -> void:
	_refresh_entries()
	_refresh_meters()
	_screamers.advance(delta, _scare_view(), _mixer.is_playing() or _chat_panel.is_audio_playing())
	_hands.advance(delta)


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
	_hands.reduce_flashes = settings.reduce_flashes
	_stat_bars.reduce_flashes = settings.reduce_flashes
	_chat_panel.reduce_flashes = settings.reduce_flashes
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


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
## y el celular se cierran, para que la ronda de Audio Sync no siga sonando.
func _on_night_ended(ending: NightState.Ending, fatal_request: FriendRequest) -> void:
	close_modes()
	var names: Array[String] = []
	for friend: FriendData in _requests.catalog.friends:
		names.append(tr(friend.name_key))
	var night_number := _requests.night_number
	var pages: Array[String] = []
	if ending == NightState.Ending.WON and night_number < _requests.catalog.nights(_requests.difficulty).size():
		for entity: EntityData in _requests.catalog.new_pages(night_number + 1, _requests.difficulty):
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
## un accidente o un chat guionado) o la descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le
## queda para responder, para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y
## si viene una interferencia.
func _refresh_entries() -> void:
	var state := _requests.state
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var incident := _requests.incidents[index]
		var friend := state.friends[index]
		var offer := state.videos.offer_for(index)
		var entry_state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			entry_state = ChatEntry.State.SELECTED
		elif not friend.is_online():
			entry_state = ChatEntry.State.DISCONNECTED
		elif request != null or incident != null or offer != null or _requests.chat_script_reply(index) != null:
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
		elif incident != null:
			entry.set_seconds_left(ceili(incident.time_left))
		elif offer != null:
			entry.show_video(ceili(offer.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		elif not friend.is_online():
			entry.show_offline()
		else:
			entry.set_seconds_left(-1)


## Los diales y las barras (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del
## PC (en rojo si ya no alcanzan) y la viñeta de Sanity.
func _refresh_meters() -> void:
	var state := _requests.state
	_dial_connection.value = state.connection() / NightState.METER_MAX
	_dial_sanity.value = state.sanity / NightState.METER_MAX
	_dial_trust.value = state.trust / NightState.METER_MAX
	_stat_bars.set_values(state.connection(), state.sanity, state.trust)
	_clock.text = state.clock_text()
	_battery_bar.size.x = roundf(BATTERY_BAR_WIDTH * state.battery / NightState.METER_MAX)
	var short := state.videos.is_short()
	_videos.text = tr(VIDEOS_SHORT_KEY if short else VIDEOS_KEY).format({"received": state.videos.received,
			"quota": state.videos.quota})
	_videos.add_theme_color_override(&"font_color", VIDEOS_SHORT_COLOR if short else _videos_color)
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", state.vignette_strength())


## En la noche 0, se abrió la página de la entidad que describe León: él sigue con la tabla.
func _on_tutorial_page_changed(friend_index: int, entity: EntityData) -> void:
	var request := _requests.requests[friend_index]
	if request != null and entity == request.entity:
		_requests.tutorial_page_opened()


## León se despidió: aparecen las tarjetas con videos (pedido de Benja, 11 de noviembre) y, al terminarlas, la noche 1.
func _on_tutorial_finished() -> void:
	close_panels()
	close_modes()
	var cards := _requests.night().tutorial_cards
	if cards.is_empty():
		next_night_requested.emit()
	else:
		_tutorial_cards.open(cards)


func _on_pause_settings_changed(settings: GameSettings) -> void:
	apply_settings(settings)
	settings_changed.emit(settings)
