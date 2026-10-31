extends Control
## Panel del chat (planes 3 y 4): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la barra de identificación, las preguntas y las respuestas. Los botones de respuesta
## son las acciones de la página que el cuaderno tiene abierta para ese amigo (diseño §8.5).
## Se ve como una terminal: cada mensaje lleva el nombre de quien escribe ("LEÓN:") en su color, y las
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

## Clic en el nombre de la entidad: el cuaderno abre su página.
signal entity_page_requested(friend_index: int, entity: EntityData)
## Se eligió la conversación de un amigo: el cuaderno salta a su página.
signal friend_selected(friend_index: int)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}; ANSWER_FROM_PAGE lleva {entity}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
const ANSWER_FROM_PAGE_KEY := "ANSWER_FROM_PAGE"
## El nombre de Matías en sus mensajes (ui.csv).
const PLAYER_NAME_KEY := "CHAT_PLAYER_NAME"
## El color de Matías: el de la terminal.
const PLAYER_COLOR := Color(0.25, 0.76, 0.79)
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"
## Un botón de respuesta por acción: cada entidad tiene 4 (docs/02 §5.1).
const ANSWER_COUNT := 4

var selected_friend := 0

var _manager: RequestManager
var _memory: NotebookMemory
var _friend_names: Array[String] = []
var _friend_colors: Array[Color] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []
var _answer_buttons: Array[Button] = []

@onready var _panel: TextureRect = $Panel
@onready var _tab_bar: HBoxContainer = $Panel/Tabs
@onready var _conversation_area: Control = $Panel/Conversations
@onready var _progress: Label = $Panel/IdentifyBar/Progress
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _questions: GridContainer = $Panel/Questions
@onready var _answer_hint: Label = $Panel/AnswerHint
@onready var _answers: GridContainer = $Panel/Answers


func _ready() -> void:
	hide()
	_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
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
	_panel.gui_input.connect(_on_panel_gui_input)


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
		var tab := Button.new()
		tab.theme_type_variation = &"ChatTab"
		tab.add_theme_color_override(&"font_pressed_color", friends[index].color)
		tab.add_theme_color_override(&"font_hover_pressed_color", friends[index].color)
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_select(selected_friend)


## Abre el panel en la conversación del amigo `friend_index`.
func open_for(friend_index: int) -> void:
	_select(friend_index)
	show()


## Mensajes de un amigo, en orden.
func message_views(friend_index: int) -> Array[Node]:
	return _lists[friend_index].get_children()


func _process(_delta: float) -> void:
	_update_status()


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación, las preguntas y las respuestas.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	_update_questions()
	_update_answers()


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
	if request != null:
		text += "  %d" % ceili(request.time_left)
	if _unread[index]:
		text += "  " + UNREAD_MARK
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


## Con 5 s o menos, o sin solicitud, no se puede preguntar.
func _update_questions() -> void:
	var request := _manager.requests[selected_friend]
	var can_ask := request != null and request.can_ask()
	for button: Button in _questions.get_children():
		button.disabled = not can_ask


## Las acciones de la página que el cuaderno tiene abierta para este amigo. Sin página, el aviso
## "Abre el cuaderno para responder". Sin solicitud, los botones se ven pero no responden.
func _update_answers() -> void:
	var page := _memory.page_for(selected_friend)
	_answers.visible = page != null
	if page == null:
		_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
		return
	_answer_hint.text = tr(ANSWER_FROM_PAGE_KEY).format({"entity": tr(page.name_key)})
	var waiting := _manager.requests[selected_friend] != null
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < page.actions.size()
		if button.visible:
			button.text = tr(page.actions[index].label_key)
		button.disabled = not waiting


func _on_message_added(friend_index: int, message: ChatMessage) -> void:
	# Quién escribe, en mayúsculas y con su color: el amigo o Matías.
	var speaker := ""
	var color := PLAYER_COLOR
	match message.sender:
		ChatMessage.Sender.FRIEND:
			speaker = _friend_names[friend_index].to_upper()
			color = _friend_colors[friend_index]
		ChatMessage.Sender.PLAYER:
			speaker = tr(PLAYER_NAME_KEY).to_upper()
	var view := ChatMessageView.new(message, speaker, color)
	view.clue_clicked.connect(_on_clue_clicked)
	_lists[friend_index].add_child(view)
	if message.sender == ChatMessage.Sender.FRIEND and not (visible and friend_index == selected_friend):
		_unread[friend_index] = true


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


## Responde con la acción `index` de la página abierta para este amigo.
func _on_answer_pressed(index: int) -> void:
	var page := _memory.page_for(selected_friend)
	if page != null and index < page.actions.size():
		_manager.answer(selected_friend, page.actions[index])


func _on_entity_pressed() -> void:
	var request := _manager.requests[selected_friend]
	if request != null:
		entity_page_requested.emit(selected_friend, request.entity)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## El panel tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_panel_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_panel.accept_event()
