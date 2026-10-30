extends Control
## Panel del chat (Plan 3): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la barra de identificación, las preguntas y el lugar de las respuestas (Plan 4).
## Se cierra con Esc, con clic derecho o con un clic izquierdo fuera del panel.

## Clic en el nombre de la entidad: el cuaderno abre su página (Plan 4).
signal entity_page_requested(friend_index: int, entity: EntityData)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"

var selected_friend := 0

var _manager: RequestManager
var _friend_names: Array[String] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []

@onready var _panel: TextureRect = $Panel
@onready var _tab_bar: HBoxContainer = $Panel/Tabs
@onready var _conversation_area: Control = $Panel/Conversations
@onready var _progress: Label = $Panel/IdentifyBar/Progress
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _questions: GridContainer = $Panel/Questions
@onready var _answer_hint: Label = $Panel/AnswerHint


func _ready() -> void:
	hide()
	_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
	for category: ClueCategory.Kind in MessageBuilder.QUESTION_KEYS:
		var button := Button.new()
		button.text = tr(MessageBuilder.QUESTION_KEYS[category])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
	_entity_button.pressed.connect(_on_entity_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)


## Conecta el panel a las solicitudes. Crea una pestaña y una conversación por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData]) -> void:
	_manager = manager
	var tab_group := ButtonGroup.new()
	for index in friends.size():
		_friend_names.append(tr(friends[index].name_key))
		_unread.append(false)
		var tab := Button.new()
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


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación y las preguntas.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	_update_questions()


func _select(friend_index: int) -> void:
	selected_friend = friend_index
	_unread[friend_index] = false
	for index in _scrolls.size():
		_scrolls[index].visible = index == friend_index
		_tabs[index].set_pressed_no_signal(index == friend_index)
	_update_status()


func _tab_text(index: int) -> String:
	var text := _friend_names[index]
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


func _on_message_added(friend_index: int, message: ChatMessage) -> void:
	var view := ChatMessageView.new(message)
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
