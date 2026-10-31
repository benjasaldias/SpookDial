extends Control
## Cuaderno (Plan 4, diseño §12): un índice con una pestaña por entidad conocida y la página de la elegida.
## Muestra la página que tiene abierta el amigo del chat (NotebookMemory) y salta a la de otro amigo
## al cambiar de chat. Elegir una pestaña abre esa página para ese amigo, y el chat muestra sus acciones
## para responder. Va a la derecha, como espejo del chat, y es independiente de él (decisión de Benja).
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const NotebookPage := preload("res://scripts/core/notebook_page.gd")

## Textos del panel (ui.csv). NOTEBOOK_FOR_FRIEND lleva {friend}.
const PICK_ENTITY_KEY := "NOTEBOOK_PICK_ENTITY"
const FOR_FRIEND_KEY := "NOTEBOOK_FOR_FRIEND"

## El amigo cuya página se muestra: el del chat.
var friend_index := 0

var _memory: NotebookMemory
var _entities: Array[EntityData] = []
var _friend_names: Array[String] = []
var _tabs: Array[Button] = []
## La entidad cuya página se ve ahora: al cambiar de página, la página vuelve arriba.
var _shown_entity: EntityData

@onready var _page: PanelContainer = $Page
@onready var _friend_label: Label = $Page/Layout/Friend
@onready var _index: HFlowContainer = $Page/Layout/Index
@onready var _scroll: ScrollContainer = $Page/Layout/Scroll
@onready var _title: Label = $Page/Layout/Scroll/Content/Title
@onready var _sketch: TextureRect = $Page/Layout/Scroll/Content/Sketch
@onready var _body: RichTextLabel = $Page/Layout/Scroll/Content/Body


func _ready() -> void:
	hide()
	_page.gui_input.connect(_on_page_gui_input)


## Conecta el cuaderno a la memoria de páginas. Crea una pestaña por cada entidad de `entities`
## (las conocidas en la noche), en orden.
func setup(memory: NotebookMemory, entities: Array[EntityData], friends: Array[FriendData]) -> void:
	_memory = memory
	_entities = entities
	for friend: FriendData in friends:
		_friend_names.append(tr(friend.name_key))
	var tab_group := ButtonGroup.new()
	for entity: EntityData in entities:
		var tab := Button.new()
		tab.text = tr(entity.name_key)
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.pressed.connect(_on_tab_pressed.bind(entity))
		_index.add_child(tab)
		_tabs.append(tab)
	memory.page_changed.connect(_on_page_changed)
	_refresh()


## Abre el cuaderno en la página del amigo `index`.
func open_for(index: int) -> void:
	select_friend(index)
	show()


## Muestra la página del amigo `index`, sin abrir ni cerrar el cuaderno. Se llama al cambiar de chat.
func select_friend(index: int) -> void:
	friend_index = index
	_refresh()


func _refresh() -> void:
	if _memory == null:
		return
	var entity := _memory.page_for(friend_index)
	_friend_label.text = tr(FOR_FRIEND_KEY).format({"friend": _friend_names[friend_index]})
	for index in _tabs.size():
		_tabs[index].set_pressed_no_signal(_entities[index] == entity)
	if entity != _shown_entity:
		_shown_entity = entity
		_scroll.scroll_vertical = 0
	_title.visible = entity != null
	_sketch.visible = entity != null and entity.sketch != null
	if entity == null:
		_body.text = tr(PICK_ENTITY_KEY)
		return
	_title.text = tr(entity.name_key)
	_sketch.texture = entity.sketch
	_body.text = NotebookPage.bbcode(entity, tr)


func _on_tab_pressed(entity: EntityData) -> void:
	_memory.open_page(friend_index, entity)


func _on_page_changed(index: int, _entity: EntityData) -> void:
	if index == friend_index:
		_refresh()


## El cuaderno tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_page_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_page.accept_event()
