extends Control
## Panel del chat (planes 3, 4 y 6): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la descarga de su video, la barra de identificación, las preguntas y las respuestas.
## Los botones de respuesta son las acciones de la página que el cuaderno tiene abierta para ese amigo
## (diseño §8.5). Un video se descarga manteniendo presionada su barra (decisión de Benja), aunque el clic haya empezado
## un instante antes de que apareciera (observación 10 del primer testeo), y con un amigo sin señal no se puede preguntar
## ni responder. El botón «Sincronizar» abre el mixer en el canal del amigo
## (decisión de Benja).
## En un chat guionado, Matías responde con un botón que tiene su línea (decisión de Benja, Plan 7).
## Se ve como una terminal: cada mensaje lleva el nombre de quien escribe ("LEÓN:") en su color, y las
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
## Un accidente se responde aquí mismo, con sus opciones en los botones de respuesta, sin cuaderno (decisión de
## Benja, 7 de noviembre).
## Los audios que mandan los amigos suenan aquí, con un clic en el mensaje (decisión de Benja, 7 de noviembre), y
## al cerrar el chat se cortan.
## Desde el Plan 9.3 (tras el primer testeo), el chat va en bloques: la conversación toma el alto que sobra, y debajo van
## la descarga, la identificación y los bloques PREGUNTAR y RESPONDER, cada uno con un título que dice por qué no se puede
## usar. Las respuestas tienen su alto reservado, para que nada se mueva al abrir una página.
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

## Clic en el nombre de la entidad: el cuaderno abre su página.
signal entity_page_requested(friend_index: int, entity: EntityData)
## Se eligió la conversación de un amigo: el cuaderno salta a su página.
signal friend_selected(friend_index: int)
## Clic en «Sincronizar»: el mixer se abre en el canal de este amigo, con la ronda empezada.
signal sync_requested(friend_index: int)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
## Los títulos de los bloques y lo que agregan cuando no se puede preguntar o responder (ui.csv).
const ASK_TITLE_KEY := "CHAT_ASK_TITLE"
const ANSWER_TITLE_KEY := "CHAT_ANSWER_TITLE"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
const NO_TIME_KEY := "CHAT_NO_TIME"
const NO_SIGNAL_KEY := "CHAT_NO_SIGNAL"
## Lo que separa el título de su detalle: "RESPONDER · EL TRAUCO".
const TITLE_SEPARATOR := " · "
## El nombre de Matías en sus mensajes (ui.csv).
const PLAYER_NAME_KEY := "CHAT_PLAYER_NAME"
## El color de Matías: el de la terminal.
const PLAYER_COLOR := Color(0.25, 0.76, 0.79)
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"
## Un botón de respuesta por acción: cada entidad tiene 4 (docs/02 §5.1).
const ANSWER_COUNT := 4
## La descarga de un video (ui.csv). Llevan {seconds}; las que muestran el avance, también {percent}.
const DOWNLOAD_START_KEY := "DOWNLOAD_START"
const DOWNLOAD_ACTIVE_KEY := "DOWNLOAD_ACTIVE"
const DOWNLOAD_SLOW_KEY := "DOWNLOAD_SLOW"
const DOWNLOAD_PAUSED_KEY := "DOWNLOAD_PAUSED"
const DOWNLOAD_OFFLINE_KEY := "DOWNLOAD_OFFLINE"
## La flecha de la descarga, delante de su texto.
const DOWNLOAD_MARK := "▼"
## Sin señal no se puede responder: hay que sincronizar al amigo (ui.csv).
const OFFLINE_KEY := "CHAT_OFFLINE"
## Sobre las opciones de un accidente (ui.csv).
const INCIDENT_HINT_KEY := "CHAT_INCIDENT_HINT"
const ChatVoice := preload("res://scripts/core/chat_voice.gd")
## El botón que abre el mixer en el canal del amigo (ui.csv).
const SYNC_KEY := "CHAT_SYNC"

var selected_friend := 0
## La opción "Subtítulos de los audios": vale para los mensajes que llegan desde ahora.
var audio_captions := false

var _manager: RequestManager
var _memory: NotebookMemory
var _friend_names: Array[String] = []
var _friend_colors: Array[Color] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []
## El último mensaje de cada conversación que se escribe de a poco: el siguiente espera a que termine.
var _last_typed: Array[Node] = []
var _answer_buttons: Array[Button] = []
## La voz de cada amigo y el sonido que usa, en orden.
var _voices: Array[ChatVoice] = []
var _voice_streams: Array[AudioStream] = []
## El botón izquierdo del mouse está apretado, y dónde está el mouse, en la ventana del juego. Los sigue el panel y no
## la barra: un clic que empezó un instante antes de que apareciera la barra lo recibe la conversación, y aun así tiene
## que descargar (observación 10 del primer testeo, docs/27).
var _mouse_held := false
var _mouse_position := Vector2(-1, -1)
## Cómo se ve la barra de descarga: normal, iluminada o apretada.
var _hold_look := &""

@onready var _panel: TextureRect = $Panel
@onready var _layout: VBoxContainer = $Panel/Layout
@onready var _tab_bar: HBoxContainer = %Tabs
@onready var _conversation_area: Control = %Conversations
@onready var _download: Control = %Download
@onready var _download_bar: ProgressBar = %Download/Bar
@onready var _download_text: Label = %Download/Text
@onready var _download_hold: Panel = %Hold
@onready var _progress: Label = %Progress
@onready var _entity_button: Button = %EntityName
@onready var _sync_button: Button = %Sync
@onready var _ask_title: Label = %AskTitle
@onready var _questions: GridContainer = %Questions
@onready var _answer_title: Label = %AnswerTitle
@onready var _answer_area: Control = %AnswerArea
@onready var _answers: VBoxContainer = %Answers
@onready var _script_reply: Button = %ScriptReply
@onready var _audio_clip: AudioStreamPlayer = $AudioClip
@onready var _voice: AudioStreamPlayer = $Voice


func _ready() -> void:
	hide()
	_answer_title.text = _title(ANSWER_TITLE_KEY, tr(OPEN_NOTEBOOK_KEY))
	_ask_title.text = _title(ASK_TITLE_KEY)
	for category: ClueCategory.Kind in MessageBuilder.QUESTION_KEYS:
		var button := Button.new()
		button.text = tr(MessageBuilder.QUESTION_KEYS[category]).to_upper()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
	for index in ANSWER_COUNT:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Las acciones pueden ser largas: el botón crece hacia abajo en vez de salirse del panel.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_answer_pressed.bind(index))
		_answers.add_child(button)
		_answer_buttons.append(button)
	_entity_button.pressed.connect(_on_entity_pressed)
	_sync_button.text = tr(SYNC_KEY).to_upper()
	_sync_button.pressed.connect(_on_sync_pressed)
	_script_reply.pressed.connect(_on_script_reply_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)
	visibility_changed.connect(_audio_clip.stop)
	var sizer := get_node_or_null(^"/root/PixelTextSizer")
	if sizer != null:
		sizer.changed.connect(_reserve_answer_space)


## Conecta el panel a las solicitudes y a la memoria del cuaderno. Crea una pestaña y una conversación
## por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData], memory: NotebookMemory) -> void:
	_manager = manager
	_memory = memory
	var tab_group := ButtonGroup.new()
	for index in friends.size():
		_friend_names.append(tr(friends[index].name_key))
		_friend_colors.append(friends[index].color)
		_unread.append(false)
		_last_typed.append(null)
		_voices.append(ChatVoice.new(friends[index]))
		_voice_streams.append(friends[index].voice)
		var tab := Button.new()
		tab.theme_type_variation = &"ChatTab"
		tab.add_theme_color_override(&"font_pressed_color", friends[index].color)
		tab.add_theme_color_override(&"font_hover_pressed_color", friends[index].color)
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# A 1080p la letra es más grande: si el nombre, el tiempo y el aviso no caben, se cortan, sin ensanchar el chat.
		tab.clip_text = true
		tab.pressed.connect(open_for.bind(index))
		_tab_bar.add_child(tab)
		_tabs.append(tab)
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override(&"separation", 6)
		scroll.add_child(list)
		# Cuando la conversación crece (mensaje nuevo o escritura progresiva), baja hasta el final.
		scroll.get_v_scroll_bar().changed.connect(_scroll_to_bottom.bind(scroll))
		_conversation_area.add_child(scroll)
		_scrolls.append(scroll)
		_lists.append(list)
	manager.message_added.connect(_on_message_added)
	manager.request_changed.connect(_on_request_changed)
	manager.request_finished.connect(_on_request_changed)
	_reserve_answer_space()
	_select(selected_friend)


## Abre el panel en la conversación del amigo `friend_index`.
func open_for(friend_index: int) -> void:
	_select(friend_index)
	show()


## Suena un audio de un amigo. Mientras tanto no empiezan screamers ni alucinaciones, que se confundirían con él.
func is_audio_playing() -> bool:
	return _audio_clip.playing


## Mensajes de un amigo, en orden.
func message_views(friend_index: int) -> Array[Node]:
	return _lists[friend_index].get_children()


## Matías mantiene apretada la barra del video del amigo elegido: el botón izquierdo apretado, con el mouse sobre la
## barra y el chat abierto, sin importar dónde empezó el clic.
func is_holding_download() -> bool:
	if not visible or _manager == null or _manager.state.videos.offer_for(selected_friend) == null:
		return false
	return _mouse_held and _is_mouse_over(_download_hold)


func _process(_delta: float) -> void:
	_update_status()


## Sigue el botón izquierdo y el mouse, empiece donde empiece el clic: _input recibe todo, antes que los controles.
func _input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	_mouse_position = mouse.position
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_mouse_held = button.pressed


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación, las preguntas,
## las respuestas y la descarga.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	# Sin Audio Sync esa noche (la 1), no hay nada que sincronizar.
	_sync_button.visible = _manager.night().audio_sync_beats > 0
	_update_questions()
	_update_answers()
	_update_download()


func _select(friend_index: int) -> void:
	selected_friend = friend_index
	_unread[friend_index] = false
	for index in _scrolls.size():
		_scrolls[index].visible = index == friend_index
		_tabs[index].set_pressed_no_signal(index == friend_index)
	_update_status()
	friend_selected.emit(friend_index)


func _tab_text(index: int) -> String:
	var text := _friend_names[index].to_upper()
	var request := _manager.requests[index]
	var incident := _manager.incidents[index]
	if request != null:
		text += " %d" % ceili(request.time_left)
	elif incident != null:
		text += " %d" % ceili(incident.time_left)
	if _unread[index]:
		text += " " + UNREAD_MARK
	return text


## Sobre las preguntas: cuántas características van marcadas, "Matías piensa…" o el nombre de la entidad.
func _update_identify_bar() -> void:
	var request := _manager.requests[selected_friend]
	var revealed := request != null and request.identification == FriendRequest.Identification.REVEALED
	_progress.visible = request != null and not revealed
	_entity_button.visible = revealed
	if request == null:
		return
	match request.identification:
		FriendRequest.Identification.PENDING:
			_progress.text = tr(PROGRESS_KEY).format({"marked": request.marked_count(), "total": request.traits.size()})
		FriendRequest.Identification.THINKING:
			_progress.text = tr(THINKING_KEY)
		FriendRequest.Identification.REVEALED:
			_entity_button.text = tr(request.entity.name_key)


## Con 5 s o menos, sin solicitud o con el amigo sin señal, no se puede preguntar. El título dice por qué.
func _update_questions() -> void:
	var request := _manager.requests[selected_friend]
	var online := _manager.state.friends[selected_friend].is_online()
	var can_ask := request != null and request.can_ask() and online
	for button: Button in _questions.get_children():
		button.disabled = not can_ask
	var detail := ""
	if request != null and not online:
		detail = tr(NO_SIGNAL_KEY)
	elif request != null and not request.can_ask():
		detail = tr(NO_TIME_KEY)
	_ask_title.text = _title(ASK_TITLE_KEY, detail)


## Las acciones de la página que el cuaderno tiene abierta para este amigo. Sin página, el título pide abrir el
## cuaderno. Sin solicitud, los botones se ven pero no responden. Con el amigo sin señal, tampoco, y el título pide
## sincronizarlo.
func _update_answers() -> void:
	# Mientras el chat guionado espera la respuesta de Matías, solo está su botón.
	var reply := _manager.chat_script_reply(selected_friend)
	_script_reply.visible = reply != null
	if reply != null:
		_script_reply.text = tr(reply.text_key)
		_answers.visible = false
		_answer_title.text = _title(ANSWER_TITLE_KEY)
		return
	var online := _manager.state.friends[selected_friend].is_online()
	var incident := _manager.incidents[selected_friend]
	if incident != null:
		_show_incident_options(incident.options, online)
		return
	var page := _memory.page_for(selected_friend)
	_answers.visible = page != null
	if not online:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(OFFLINE_KEY))
	elif page == null:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(OPEN_NOTEBOOK_KEY))
	else:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(page.name_key))
	if page == null:
		return
	var waiting := _manager.requests[selected_friend] != null and online
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < page.actions.size()
		if button.visible:
			button.text = tr(page.actions[index].label_key)
		button.disabled = not waiting


## Las opciones de un accidente, en los botones de respuesta. Sin señal, el amigo no las lee.
func _show_incident_options(options: Array[String], online: bool) -> void:
	_answers.visible = true
	_answer_title.text = _title(ANSWER_TITLE_KEY, tr(INCIDENT_HINT_KEY) if online else tr(OFFLINE_KEY))
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < options.size()
		if button.visible:
			button.text = tr(options[index])
		button.disabled = not online


## La barra de descarga del video que mandó este amigo, si mandó uno. Mientras el chat esté abierto y la
## barra presionada, el video se descarga; al soltarla, se pausa.
func _update_download() -> void:
	var state := _manager.state
	var offer := state.videos.offer_for(selected_friend)
	_download.visible = offer != null
	var holding := is_holding_download()
	state.holding_download = selected_friend if holding else -1
	_paint_hold(holding)
	if offer == null:
		return
	_download_bar.value = offer.progress * 100.0
	var signal_level := state.friends[selected_friend].signal_level
	var key := DOWNLOAD_PAUSED_KEY if offer.started else DOWNLOAD_START_KEY
	if signal_level <= 0.0:
		key = DOWNLOAD_OFFLINE_KEY
	elif holding:
		key = DOWNLOAD_SLOW_KEY if signal_level < _manager.catalog.balance.download_slow_below else DOWNLOAD_ACTIVE_KEY
	var values := {"seconds": ceili(offer.time_left), "percent": floori(offer.progress * 100.0)}
	_download_text.text = "%s %s" % [DOWNLOAD_MARK, tr(key).format(values).to_upper()]


## La barra se ve apretada mientras se descarga, e iluminada con el mouse encima.
func _paint_hold(holding: bool) -> void:
	var look := &"pressed" if holding else (&"hover" if _is_mouse_over(_download_hold) else &"panel")
	if look == _hold_look:
		return
	_hold_look = look
	_download_hold.add_theme_stylebox_override(&"panel", _download_hold.get_theme_stylebox(look, &"DownloadHold"))


## Un título de bloque, en mayúsculas: "PREGUNTAR" o, con un detalle, "RESPONDER · EL TRAUCO".
func _title(key: String, detail := "") -> String:
	return (tr(key) if detail.is_empty() else tr(key) + TITLE_SEPARATOR + detail).to_upper()


## Reserva el alto de las respuestas: el que piden las acciones más largas de las entidades de la noche, o las opciones
## de un accidente, con la letra de ahora. Así, al abrir una página, las preguntas no se mueven. Se vuelve a medir
## cuando cambia el tamaño de la letra (PixelTextSizer).
func _reserve_answer_space() -> void:
	if _manager == null or _answer_buttons.is_empty():
		return
	var needed := 0.0
	for entity: EntityData in _manager.catalog.known_entities(_manager.night_number):
		needed = maxf(needed, _stack_height(entity.actions.map(func(action: ActionData) -> String:
				return tr(action.label_key))))
	for incident: IncidentData in _manager.catalog.incidents:
		var options: Array[String] = [incident.correct_key]
		options.append_array(incident.wrong_keys)
		needed = maxf(needed, _stack_height(options.map(func(key: String) -> String: return tr(key))))
	_answer_area.custom_minimum_size.y = ceilf(needed)


## El alto de los botones de respuesta con `labels`, uno debajo del otro, a todo el ancho del chat.
func _stack_height(labels: Array) -> float:
	var button := _answer_buttons[0]
	var style := button.get_theme_stylebox(&"normal")
	var font := button.get_theme_font(&"font")
	var font_size := button.get_theme_font_size(&"font_size")
	var width := _layout.size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
	var total := 0.0
	for label: String in labels:
		var text_height := font.get_multiline_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
		total += maxf(text_height + style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM), button.custom_minimum_size.y)
	return total + _answers.get_theme_constant(&"separation") * maxf(labels.size() - 1, 0.0)


## El mouse está sobre `control`, que se ve.
func _is_mouse_over(control: Control) -> bool:
	var local := control.get_global_transform_with_canvas().affine_inverse() * _mouse_position
	return control.is_visible_in_tree() and Rect2(Vector2.ZERO, control.size).has_point(local)


func _on_message_added(friend_index: int, message: ChatMessage) -> void:
	# Quién escribe, en mayúsculas y con su color: el amigo o Matías. Los avisos del juego van sin nombre.
	var speaker := ""
	var color := PLAYER_COLOR
	match message.sender:
		ChatMessage.Sender.FRIEND:
			speaker = _friend_names[friend_index].to_upper()
			color = _friend_colors[friend_index]
		ChatMessage.Sender.PLAYER:
			speaker = tr(PLAYER_NAME_KEY).to_upper()
	var view := ChatMessageView.new(message, speaker, color, audio_captions)
	view.clue_clicked.connect(_on_clue_clicked)
	view.audio_clicked.connect(_on_audio_clicked)
	if message.sender == ChatMessage.Sender.FRIEND:
		view.letter_typed.connect(_on_letter_typed.bind(friend_index))
	# Los mensajes se escriben de a uno, en orden: si llegan juntos, el segundo espera al primero.
	if message.sender != ChatMessage.Sender.SYSTEM:
		view.wait_for = _last_typed[friend_index]
		_last_typed[friend_index] = view
	_lists[friend_index].add_child(view)
	if message.sender != ChatMessage.Sender.PLAYER and not (visible and friend_index == selected_friend):
		_unread[friend_index] = true


## Suena la voz del amigo que está escribiendo, si se está viendo su chat. No tapa un audio, que hay que oír.
func _on_letter_typed(letter: String, friend_index: int) -> void:
	var pitch := _voices[friend_index].next_pitch(letter)
	if pitch <= 0.0 or not visible or friend_index != selected_friend or _audio_clip.playing:
		return
	_voice.stream = _voice_streams[friend_index]
	_voice.pitch_scale = pitch
	_voice.play()


func _on_audio_clicked(view: ChatMessageView) -> void:
	_audio_clip.stream = view.message.audio
	_audio_clip.play()


## Un señuelo vibra y se pone rojo, sin costo (decisión de Benja, 11 de noviembre, tras el primer testeo).
func _on_clue_clicked(view: ChatMessageView, clue_id: StringName) -> void:
	if _manager.click_clue(view.message, clue_id) == FriendRequest.ClueState.DECOY:
		view.shake(clue_id)


## Vuelve a armar los mensajes de esa solicitud: frases marcadas, en rojo o sin enlaces si terminó.
func _on_request_changed(friend_index: int, request: FriendRequest) -> void:
	for view: ChatMessageView in message_views(friend_index):
		if view.message.request == request:
			view.refresh()


func _on_question_pressed(category: ClueCategory.Kind) -> void:
	_manager.ask(selected_friend, category)


## Responde el accidente del amigo o, si no tiene, con la acción `index` de la página abierta para él.
func _on_answer_pressed(index: int) -> void:
	if _manager.incidents[selected_friend] != null:
		_manager.answer_incident(selected_friend, index)
		return
	var page := _memory.page_for(selected_friend)
	if page != null and index < page.actions.size():
		_manager.answer(selected_friend, page.actions[index])


func _on_entity_pressed() -> void:
	var request := _manager.requests[selected_friend]
	if request != null:
		entity_page_requested.emit(selected_friend, request.entity)


func _on_sync_pressed() -> void:
	sync_requested.emit(selected_friend)


func _on_script_reply_pressed() -> void:
	_manager.reply_chat_script()


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## El panel tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_panel_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_panel.accept_event()
