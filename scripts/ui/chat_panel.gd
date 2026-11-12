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
## En la noche 0 (Plan 9.5, tras el primer testeo), solo se puede usar lo que León pide, cuando terminó de escribir, y
## eso parpadea: la pregunta, las frases y el audio (laten), el nombre, las hojas, la barra de descarga y las barritas.
## En la demostración de Gonzalo, las respuestas dicen que hay que mirar qué pasa.
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
const Highlight := preload("res://scripts/ui/highlight.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const PixelText := preload("res://scripts/ui/pixel_text.gd")
const QuestionButton := preload("res://scripts/ui/question_button.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")
## Lo que pide León para cada pregunta en el tutorial. "¿Huellas?" no se enseña.
const QUESTION_FOCUS := {
	ClueCategory.Kind.SIGHT: TutorialChat.Focus.ASK_SIGHT,
	ClueCategory.Kind.SOUND: TutorialChat.Focus.ASK_SOUND,
	ClueCategory.Kind.ENVIRONMENT: TutorialChat.Focus.ASK_ENVIRONMENT,
}

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
## La etiqueta corta de cada pregunta en su botón (ui.csv): Matías pregunta con la frase completa, de QUESTION_KEYS.
const QUESTION_LABEL_KEYS := {
	ClueCategory.Kind.SIGHT: "QUESTION_SIGHT_SHORT",
	ClueCategory.Kind.SOUND: "QUESTION_SOUND_SHORT",
	ClueCategory.Kind.ENVIRONMENT: "QUESTION_ENVIRONMENT_SHORT",
	ClueCategory.Kind.TRACES: "QUESTION_TRACES_SHORT",
}
## El ícono de cada pregunta (art/ui/, pixel art de Claude): ojo, parlante, nube con niebla y huella.
const QUESTION_ICONS := {
	ClueCategory.Kind.SIGHT: preload("res://art/ui/chat_icon_sight.png"),
	ClueCategory.Kind.SOUND: preload("res://art/ui/chat_icon_sound.png"),
	ClueCategory.Kind.ENVIRONMENT: preload("res://art/ui/chat_icon_environment.png"),
	ClueCategory.Kind.TRACES: preload("res://art/ui/chat_icon_traces.png"),
}
## Las respuestas desde el cuaderno son hojas del cuaderno, con el número de su columna en una nota adhesiva; las de un
## accidente, que se responde sin cuaderno, botones de terminal (docs/26 §2.3).
const ANSWER_SHEET := &"AnswerSheet"
const TERMINAL_BUTTON := &"Button"
## Lo que separa la nota adhesiva del borde izquierdo de la hoja.
const NUMBER_MARGIN := 4
## La tinta del número.
const NUMBER_COLOR := Color(0.12, 0.13, 0.2)
## Lo que cuesta una pregunta (ui.csv). Lleva {seconds}.
const QUESTION_COST_KEY := "CHAT_QUESTION_COST"
## Lo que costó una pregunta sube desde la pestaña del amigo y se desvanece en estos segundos, subiendo tantos píxeles.
const COST_POPUP_SECONDS := 1.2
const COST_POPUP_RISE := 8.0
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
## La ayuda del botón que abre el mixer en el canal del amigo (ui.csv).
const SYNC_KEY := "CHAT_SYNC"
## El botón de sincronizar muestra la señal del amigo elegido (docs/26 §2.3): 5 cuadros de 0 a 4 barritas, en 3 filas
## (verde, ámbar y rojo), de art/ui/chat_signal.png.
const SIGNAL_SHEET := preload("res://art/ui/chat_signal.png")
const SIGNAL_FRAME_SIZE := Vector2(15, 12)
## Una barrita por cada tantos puntos de señal.
const SIGNAL_PER_BAR := 25.0
## Los colores siguen los tramos de la estática (ChatStatic.COVERAGE): verde sin estática, rojo con mucha.
const SIGNAL_CLEAR := 70.0
const SIGNAL_WEAK := 30.0
## Sin señal, el botón parpadea con un borde rojo.
const SYNC_ALERT_COLOR := Color(1.0, 0.3, 0.37)
## El cuaderno junto al nombre de la entidad: se entiende que abre su página (docs/26 §2.3). Crece con la letra del nombre.
const NOTEBOOK_ICON := preload("res://art/ui/chat_icon_notebook.png")
const NOTEBOOK_ICON_PIXELS := 11
const ENTITY_FONT_SIZE := 22

var selected_friend := 0
## La opción "Subtítulos de los audios": vale para los mensajes que llegan desde ahora.
var audio_captions := false
## La opción "Reducir destellos" (diseño §19): el borde del botón de sincronizar queda fijo en vez de parpadear.
var reduce_flashes := false:
	set(value):
		reduce_flashes = value
		if _sync_highlight != null:
			_sync_highlight.reduce_flashes = value
		for highlight: Highlight in _highlights.values():
			highlight.reduce_flashes = value
		_view_flags = []

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
## Los botones de pregunta, por categoría.
var _question_buttons := {}
## El cuadro de la señal en el botón de sincronizar, y el borde que parpadea sin señal.
var _sync_icon := AtlasTexture.new()
var _sync_highlight: Highlight
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
## En el tutorial, el borde que parpadea en cada control, por lo que pide León (TutorialChat.Focus).
var _highlights := {}
## Cómo están las frases y el audio de los mensajes (enlaces, latido y "Reducir destellos"): se vuelven a armar solo
## cuando cambia.
var _view_flags := []

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
		var button := QuestionButton.new()
		button.icon = QUESTION_ICONS[category]
		button.text = tr(QUESTION_LABEL_KEYS[category]).to_upper()
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
		_question_buttons[category] = button
		if QUESTION_FOCUS.has(category):
			_add_highlight(button, QUESTION_FOCUS[category])
	for index in ANSWER_COUNT:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		# Las acciones pueden ser largas: el botón crece hacia abajo en vez de salirse del panel.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_answer_pressed.bind(index))
		button.add_child(_answer_number(index + 1))
		_answers.add_child(button)
		_answer_buttons.append(button)
	_entity_button.icon = NOTEBOOK_ICON
	_entity_button.expand_icon = true
	_entity_button.pressed.connect(_on_entity_pressed)
	_add_highlight(_entity_button, TutorialChat.Focus.ENTITY_NAME)
	# Las hojas cambian de alto: su borde va en el área reservada, con el tamaño de las hojas.
	_add_highlight(_answer_area, TutorialChat.Focus.ANSWERS)
	_add_highlight(_download_hold, TutorialChat.Focus.DOWNLOAD)
	_sync_icon.atlas = SIGNAL_SHEET
	_sync_button.icon = _sync_icon
	_sync_button.expand_icon = true
	_sync_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sync_button.tooltip_text = tr(SYNC_KEY)
	_sync_button.pressed.connect(_on_sync_pressed)
	_sync_highlight = Highlight.new()
	_sync_highlight.name = "Highlight"
	_sync_highlight.color = SYNC_ALERT_COLOR
	_sync_highlight.reduce_flashes = reduce_flashes
	_sync_button.add_child(_sync_highlight)
	_resize_icons()
	_script_reply.pressed.connect(_on_script_reply_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)
	visibility_changed.connect(_audio_clip.stop)
	var sizer := get_node_or_null(^"/root/PixelTextSizer")
	if sizer != null:
		sizer.changed.connect(_on_text_size_changed)


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
	for button: QuestionButton in _question_buttons.values():
		button.cost_text = _cost_text(manager.catalog.balance.question_cost)
	_reserve_answer_space()
	_select(selected_friend)


## Habilita o bloquea la pestaña del amigo `friend_index`: en la noche 0, solo las de los amigos que León va usando
## (Plan 9.5).
func set_tab_enabled(friend_index: int, enabled: bool) -> void:
	_tabs[friend_index].disabled = not enabled


func is_tab_enabled(friend_index: int) -> bool:
	return not _tabs[friend_index].disabled


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
	return _mouse_held and _is_mouse_over(_download_hold) and _allows(TutorialChat.Focus.DOWNLOAD)


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
	_update_sync()
	_update_questions()
	_update_answers()
	_update_download()
	_update_tutorial()


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


## Sobre las preguntas: cuántas características van marcadas, "Matías piensa…" o el nombre de la entidad. En Difícil no
## hay nada de eso: se lee y se busca la página en el índice del cuaderno (decisión de Benja, D3).
func _update_identify_bar() -> void:
	var request := _manager.requests[selected_friend]
	# En Difícil no hay barra; en la demostración de Gonzalo, tampoco: no se identifica nada.
	if not _manager.highlights() or _is_demo_waiting():
		request = null
	var revealed := request != null and request.identification == FriendRequest.Identification.REVEALED
	_progress.visible = request != null and not revealed
	_entity_button.visible = revealed
	# En el tutorial se habilita cuando León lo pide, y después sigue abriendo la página.
	_entity_button.disabled = not (_allows(TutorialChat.Focus.ENTITY_NAME)
			or _manager.tutorial_chat.step > TutorialChat.Step.OPEN_PAGE)
	if request == null:
		return
	match request.identification:
		FriendRequest.Identification.PENDING:
			_progress.text = tr(PROGRESS_KEY).format({"marked": request.marked_count(), "total": request.traits.size()})
		FriendRequest.Identification.THINKING:
			_progress.text = tr(THINKING_KEY)
		FriendRequest.Identification.REVEALED:
			_entity_button.text = tr(request.entity.name_key)


## El botón de sincronizar muestra la señal del amigo elegido y, sin señal, parpadea. Sin Audio Sync esa noche, no hay
## nada que sincronizar.
func _update_sync() -> void:
	_sync_button.visible = _manager.night().audio_sync_beats > 0
	var level := _manager.state.friends[selected_friend].signal_level
	var frame := signal_frame(level)
	_sync_icon.region = Rect2(Vector2(frame) * SIGNAL_FRAME_SIZE, SIGNAL_FRAME_SIZE)
	_sync_button.disabled = not _allows(TutorialChat.Focus.SYNC)
	_sync_highlight.active = _sync_button.visible and not _sync_button.disabled \
			and (level <= 0.0 or _ready_for(TutorialChat.Focus.SYNC))


## El cuadro de la señal para `level`: cuántas barritas (una por cada 25) y en qué fila de color (0 verde, 1 ámbar y
## 2 rojo).
static func signal_frame(level: float) -> Vector2i:
	var bars := ceili(clampf(level, 0.0, 100.0) / SIGNAL_PER_BAR)
	var row := 0 if level >= SIGNAL_CLEAR else (1 if level >= SIGNAL_WEAK else 2)
	return Vector2i(bars, row)


## Con 5 s o menos, sin solicitud o con el amigo sin señal, no se puede preguntar, y una pregunta ya respondida no se
## repite salvo que la estática haya tapado su respuesta (docs/26 §2.1). El título dice por qué no se puede.
func _update_questions() -> void:
	var request := _manager.requests[selected_friend]
	var online := _manager.state.friends[selected_friend].is_online()
	for category: ClueCategory.Kind in _question_buttons:
		var mark := QuestionButton.Mark.NONE
		if request != null and request.was_asked(category):
			mark = QuestionButton.Mark.STATIC if request.answer_covered(category) else QuestionButton.Mark.ASKED
		var enabled := request != null and online and request.can_ask_about(category) \
				and _allows(QUESTION_FOCUS.get(category, TutorialChat.Focus.NONE))
		(_question_buttons[category] as QuestionButton).show_state(mark, enabled)
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
	if _is_demo_waiting():
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(TutorialChat.GONZALO_WATCH_KEY))
	elif not online:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(OFFLINE_KEY))
	elif page == null:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(OPEN_NOTEBOOK_KEY))
	else:
		_answer_title.text = _title(ANSWER_TITLE_KEY, tr(page.name_key))
	if page == null:
		return
	var waiting := _manager.requests[selected_friend] != null and online and _allows(TutorialChat.Focus.ANSWERS)
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		_set_answer_look(button, true)
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
		_set_answer_look(button, false)
		button.visible = index < options.size()
		if button.visible:
			button.text = tr(options[index])
		button.disabled = not online


## La nota adhesiva con el número de la columna de la tabla, a la izquierda de una hoja de respuesta.
func _answer_number(number: int) -> PanelContainer:
	var note := PanelContainer.new()
	note.name = "Number"
	note.theme_type_variation = &"AnswerNumber"
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "Label"
	label.text = str(number)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", NUMBER_COLOR)
	note.add_child(label)
	note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, NUMBER_MARGIN)
	return note


## Una hoja del cuaderno con su número, para responder desde la página, o un botón de terminal, para un accidente.
func _set_answer_look(button: Button, sheet: bool) -> void:
	button.theme_type_variation = ANSWER_SHEET if sheet else &""
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if sheet else HORIZONTAL_ALIGNMENT_CENTER
	(button.get_node("Number") as Control).visible = sheet


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
	for entity: EntityData in _manager.catalog.known_entities(_manager.night_number, _manager.difficulty):
		needed = maxf(needed, _stack_height(entity.actions.map(func(action: ActionData) -> String:
				return tr(action.label_key)), ANSWER_SHEET))
	for incident: IncidentData in _manager.catalog.incidents:
		var options: Array[String] = [incident.correct_key]
		options.append_array(incident.wrong_keys)
		needed = maxf(needed, _stack_height(options.map(func(key: String) -> String: return tr(key)), TERMINAL_BUTTON))
	_answer_area.custom_minimum_size.y = ceilf(needed)


## El alto de los botones de respuesta con `labels`, con el estilo `variation`, uno debajo del otro, a todo el ancho del
## chat. Una hoja nunca es más baja que su nota adhesiva.
func _stack_height(labels: Array, variation: StringName) -> float:
	var style := get_theme_stylebox(&"normal", variation)
	var font := get_theme_font(&"font", variation)
	var font_size := get_theme_font_size(&"font_size", variation)
	var width := _layout.size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
	var note_height := 0.0
	if variation == ANSWER_SHEET:
		note_height = (_answer_buttons[0].get_node("Number") as Control).get_combined_minimum_size().y + 2.0
	var total := 0.0
	for label: String in labels:
		var text_height := font.get_multiline_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
		total += maxf(text_height + style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM), note_height)
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
	var view := ChatMessageView.new(message, speaker, color, audio_captions, _manager.highlights())
	_apply_view_flags(view, _current_view_flags())
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
	if view.message.request != null:
		_manager.tutorial_audio_played(view.message.request.friend_index, view.message.audio)


## Un señuelo vibra y se pone rojo, sin costo (decisión de Benja, 11 de noviembre, tras el primer testeo).
func _on_clue_clicked(view: ChatMessageView, clue_id: StringName) -> void:
	if _manager.click_clue(view.message, clue_id) == FriendRequest.ClueState.DECOY:
		view.shake(clue_id)


## Vuelve a armar los mensajes de esa solicitud: frases marcadas, en rojo o sin enlaces si terminó.
func _on_request_changed(friend_index: int, request: FriendRequest) -> void:
	for view: ChatMessageView in message_views(friend_index):
		if view.message.request == request:
			view.refresh()


## Pregunta y, si se pudo, la pestaña del amigo muestra lo que costó.
func _on_question_pressed(category: ClueCategory.Kind) -> void:
	var request := _manager.requests[selected_friend]
	if request != null and _manager.ask(selected_friend, category):
		_show_cost(selected_friend, request.question_cost)


## Lo que costó una pregunta, sobre el borde de abajo de la pestaña del amigo: un "−5 s" rojo, con fondo para leerse sobre
## la conversación, que sube y se desvanece (docs/26 §2.1).
func _show_cost(friend_index: int, seconds: float) -> void:
	var popup := Label.new()
	popup.name = "CostPopup"
	popup.theme_type_variation = &"CostPopup"
	popup.text = _cost_text(seconds)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(popup)
	popup.reset_size()
	var tab_rect := _tabs[friend_index].get_global_rect()
	popup.global_position = Vector2(roundf(tab_rect.get_center().x - popup.size.x / 2.0),
			roundf(tab_rect.end.y - popup.size.y / 2.0))
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, ^"position:y", popup.position.y - COST_POPUP_RISE, COST_POPUP_SECONDS)
	tween.tween_property(popup, ^"modulate:a", 0.0, COST_POPUP_SECONDS).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(popup.queue_free)


## "−5 s": los segundos sin decimales si son enteros.
func _cost_text(seconds: float) -> String:
	return tr(QUESTION_COST_KEY).format({"seconds": ("%.1f" % seconds).trim_suffix(".0")})


## Cambió el tamaño de la letra: los íconos crecen con ella y las respuestas vuelven a medir su espacio.
func _on_text_size_changed() -> void:
	for button: QuestionButton in _question_buttons.values():
		button.resize_icons()
	_resize_icons()
	_reserve_answer_space()


## En la noche 0, lo que pide León se puede usar (TutorialChat.Focus). Fuera del tutorial, todo.
func _allows(focus: TutorialChat.Focus) -> bool:
	return not _manager.is_tutorial() or _ready_for(focus)


## En la noche 0, León pide `focus` y terminó de escribir: se puede usar y parpadea.
func _ready_for(focus: TutorialChat.Focus) -> bool:
	if focus == TutorialChat.Focus.NONE or not _manager.tutorial_wants(focus):
		return false
	var last: Node = _last_typed[selected_friend]
	return last == null or not is_instance_valid(last) or last.is_done()


## En la demostración de Gonzalo, su chat espera que se acabe el tiempo: las respuestas no se usan.
func _is_demo_waiting() -> bool:
	return _manager.is_tutorial() and selected_friend == _manager.tutorial_demo_friend() \
			and _manager.requests[selected_friend] != null


## Un borde que parpadea en `control` cuando León pide `focus`.
func _add_highlight(control: Control, focus: TutorialChat.Focus) -> void:
	var highlight := Highlight.new()
	highlight.name = "Highlight"
	highlight.reduce_flashes = reduce_flashes
	control.add_child(highlight)
	_highlights[focus] = highlight


## En la noche 0, parpadea lo que pide León, si se ve; y las frases y el audio de los mensajes laten o se apagan.
func _update_tutorial() -> void:
	(_highlights[TutorialChat.Focus.ANSWERS] as Highlight).target_size = _answers.size
	for focus: TutorialChat.Focus in _highlights:
		var highlight: Highlight = _highlights[focus]
		var shown := _answers.visible if focus == TutorialChat.Focus.ANSWERS \
				else (highlight.get_parent() as Control).is_visible_in_tree()
		highlight.active = _ready_for(focus) and shown
	var flags := _current_view_flags()
	if flags == _view_flags:
		return
	_view_flags = flags
	for list: VBoxContainer in _lists:
		for view: ChatMessageView in list.get_children():
			_apply_view_flags(view, flags)
			view.refresh()


## Cómo van ahora las frases y el audio: [enlaces de las frases, frases que laten, audio, audio que late, menos destellos].
## En el tutorial, el audio se puede volver a escuchar después de su paso.
func _current_view_flags() -> Array:
	if _manager == null or not _manager.is_tutorial():
		return [true, false, true, false, reduce_flashes]
	var audio_past: bool = _manager.tutorial_chat.step > TutorialChat.Step.LISTEN
	return [_ready_for(TutorialChat.Focus.CLUES), _ready_for(TutorialChat.Focus.CLUES),
			_ready_for(TutorialChat.Focus.AUDIO) or audio_past, _ready_for(TutorialChat.Focus.AUDIO), reduce_flashes]


func _apply_view_flags(view: ChatMessageView, flags: Array) -> void:
	view.links_enabled = flags[0]
	view.attention = flags[1]
	view.audio_enabled = flags[2]
	view.audio_attention = flags[3]
	view.reduce_flashes = flags[4]


## El cuaderno del nombre y la señal de sincronizar, del tamaño que los deja nítidos junto a su letra (PixelText). El
## botón de sincronizar es cuadrado y tan ancho como su ícono lo pide.
func _resize_icons() -> void:
	var notebook := PixelText.icon_size_for(NOTEBOOK_ICON_PIXELS, PixelText.size(ENTITY_FONT_SIZE))
	_entity_button.add_theme_constant_override(&"icon_max_width", notebook)
	var signal_width := PixelText.icon_size(int(SIGNAL_FRAME_SIZE.x))
	_sync_button.add_theme_constant_override(&"icon_max_width", signal_width)
	var style := _sync_button.get_theme_stylebox(&"normal")
	var side := maxf(signal_width + style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT), _identify_height())
	_sync_button.custom_minimum_size = Vector2(side, 0)


## El alto mínimo de la barra de identificación.
func _identify_height() -> float:
	return (%IdentifyBar as Control).custom_minimum_size.y


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
