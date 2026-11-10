extends Control
## El celular ampliado (diseño §10.2): Snapgram, la red social que Matías scrollea con la rueda del mouse para
## recuperar Sanity. El feed imita a una red real, pero son solo fotos de gatitos: las cuentas no tienen nombre y
## el texto se simula con barras grises (decisión de Benja, 9 de noviembre). Los botones son solo dibujo.
## El marco y los íconos son provisionales hasta el arte de Benja.
## Las publicaciones se repiten sin fin. Se cierra con clic derecho; Esc y un clic fuera lo cierran desde
## el escritorio. La batería alcanza para un rato por noche y, sin ella, no hay nada que mirar (decisión de Benja,
## 7 de noviembre).

const NightState := preload("res://scripts/core/night_state.gd")
const PhoneFeed := preload("res://scripts/core/phone_feed.gd")
const PhoneIcons := preload("res://scripts/ui/phone_icons.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")
## El marco del celular: la carcasa azul, los botones y el vidrio negro alrededor de la pantalla.
const FRAME := preload("res://art/ui/phone_frame.png")

## El nombre de la red social (phone.csv).
const APP_NAME_KEY := "PHONE_APP_NAME"
## Lo que se ve sin batería (phone.csv).
const NO_BATTERY_KEY := "PHONE_NO_BATTERY"
## Bajo este porcentaje, la batería se ve en rojo.
const LOW_BATTERY := 20.0
const SIZE := Vector2(260, 520)
const FONT_SIZE := 11
## Alto de cada publicación en el feed.
const POST_HEIGHT := 332.0
## Lado de las fotos: se muestran sin escalar y a todo el ancho del feed.
const PHOTO_SIZE := 232
## Margen de la cabecera y de lo que va bajo la foto.
const POST_MARGIN := 8.0
## Alto de la barra gris que simula una línea de texto.
const TEXT_BAR_HEIGHT := 5.0
## Cuántos píxeles avanza el feed con cada movimiento de la rueda.
const WHEEL_STEP := 60.0
## Cuánto avanza con el touchpad, por unidad de su gesto.
const PAN_STEP := 30.0
## Qué tan rápido sigue el feed a la rueda.
const SCROLL_SPEED := 10.0
## Colores provisionales: el celular de noche, en modo oscuro.
const GLASS_COLOR := Color(0.01, 0.01, 0.03)
const FEED_COLOR := Color(0.07, 0.08, 0.11)
const TEXT_COLOR := Color(0.86, 0.88, 0.94)
const DIM_COLOR := Color(0.5, 0.54, 0.64)
const LOW_BATTERY_COLOR := Color(1.0, 0.35, 0.45)
const DIVIDER_COLOR := Color(0.16, 0.17, 0.22)
const AVATAR_COLOR := Color(0.32, 0.34, 0.4)
const BAR_COLOR := Color(0.26, 0.28, 0.34)
const STRONG_BAR_COLOR := Color(0.42, 0.44, 0.5)
## La barra de navegación de abajo, de izquierda a derecha.
const NAV_ICONS: Array = [PhoneIcons.HOME, PhoneIcons.SEARCH, PhoneIcons.NEW_POST, PhoneIcons.VIDEOS, PhoneIcons.PROFILE]

## Cuántos píxeles se scrolleó. Crece sin fin hacia abajo: las publicaciones se repiten.
var scroll := 0.0

var _target_scroll := 0.0
var _state: NightState
var _posts: Array[PhonePostData] = []
var _disturbing_posts: Array[PhonePostData] = []
## Las publicaciones a la vista, por su lugar en el feed. Se deciden al entrar a la pantalla y quedan fijas hasta
## que salen: una foto nunca cambia frente al jugador.
var _slots: Dictionary = {}
var _rest_position := Vector2.ZERO

@onready var _feed: Control = $Feed


func _ready() -> void:
	hide()
	_rest_position = position
	_feed.draw.connect(_draw_feed)


## Conecta el celular al estado de la noche (la hora y Sanity) y a sus publicaciones.
func setup(state: NightState, posts: Array[PhonePostData], disturbing_posts: Array[PhonePostData] = []) -> void:
	_state = state
	_posts = posts
	_disturbing_posts = disturbing_posts


func open() -> void:
	show()
	# Sube desde el escritorio.
	position = _rest_position + Vector2(0, 24)
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position", _rest_position, 0.15)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)


func close() -> void:
	hide()
	# Cerrado no se ve el cambio: al volver a abrirlo se decide de nuevo.
	_slots.clear()


## Avanza el feed `amount` píxeles (hacia abajo si es positivo). Mientras Matías scrollea, Sanity sube.
func scroll_by(amount: float) -> void:
	if not _state.has_battery():
		return
	_target_scroll += amount
	_state.scroll()


## La publicación que está arriba del feed, por su posición en la lista.
func post_at_top() -> int:
	if _posts.is_empty():
		return -1
	return floori(fposmod(scroll, POST_HEIGHT * _posts.size()) / POST_HEIGHT)


## La publicación que se ve en el lugar `slot` del feed, o null si ese lugar no está a la vista.
func post_in_slot(slot: int) -> PhonePostData:
	return _slots.get(slot)


func _process(delta: float) -> void:
	if not visible:
		return
	scroll = lerpf(scroll, _target_scroll, minf(delta * SCROLL_SPEED, 1.0))
	_update_slots()
	queue_redraw()
	_feed.queue_redraw()


## Olvida los lugares que salieron de la pantalla y decide los que entraron, con la Sanity de ahora.
func _update_slots() -> void:
	var first := floori(scroll / POST_HEIGHT)
	var last := floori((scroll + _feed.size.y - 1.0) / POST_HEIGHT)
	for slot: int in _slots.keys():
		if slot < first or slot > last:
			_slots.erase(slot)
	for slot in range(first, last + 1):
		if not _slots.has(slot):
			_slots[slot] = PhoneFeed.post_for_slot(slot, _state.sanity, _posts, _disturbing_posts, _state.balance)


## La rueda del mouse y el touchpad scrollean. El clic derecho cierra el celular.
func _gui_input(event: InputEvent) -> void:
	var pan := event as InputEventPanGesture
	if pan != null:
		scroll_by(pan.delta.y * PAN_STEP)
		accept_event()
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	accept_event()
	match mouse.button_index:
		MOUSE_BUTTON_WHEEL_DOWN:
			scroll_by(WHEEL_STEP)
		MOUSE_BUTTON_WHEEL_UP:
			scroll_by(-WHEEL_STEP)
		MOUSE_BUTTON_RIGHT:
			close()


## El celular: el marco (pixel art de Claude, art/ui/phone_frame.png), la barra con la hora y la barra de inicio.
## Con batería, además, las barras de Snapgram. El feed se dibuja aparte, recortado a su pantalla.
func _draw() -> void:
	draw_texture(FRAME, Vector2.ZERO)
	var has_battery := _state.has_battery()
	draw_rect(Rect2(14, 18, 232, 478), FEED_COLOR if has_battery else GLASS_COLOR)
	_draw_text(self, _state.clock_text(), Vector2(22, 31), TEXT_COLOR)
	for bar in 4:
		draw_rect(Rect2(196 + bar * 4, 28 - bar * 2, 3, 3 + bar * 2), TEXT_COLOR)
	_draw_battery()
	if has_battery:
		_draw_app_bars()
	draw_rect(Rect2(98, 487, 64, 3), DIM_COLOR)


## La barra superior, con el nombre de la red social y sus íconos, y la de navegación, abajo.
func _draw_app_bars() -> void:
	draw_string(FONT, Vector2(22, 57), tr(APP_NAME_KEY), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE * 2, TEXT_COLOR)
	PhoneIcons.draw_icon(self, PhoneIcons.HEART, Vector2(204, 45), TEXT_COLOR)
	PhoneIcons.draw_icon(self, PhoneIcons.SEND, Vector2(226, 45), TEXT_COLOR)
	draw_rect(Rect2(14, 63, 232, 1), DIVIDER_COLOR)
	draw_rect(Rect2(14, 456, 232, 1), DIVIDER_COLOR)
	for index in NAV_ICONS.size():
		var center := 14.0 + 232.0 * (index + 0.5) / NAV_ICONS.size()
		var icon: Array[String] = []
		icon.assign(NAV_ICONS[index])
		PhoneIcons.draw_icon(self, icon, Vector2(roundf(center - PhoneIcons.SIZE / 2.0), 463), TEXT_COLOR)


## La batería: el ícono, que se vacía, y su porcentaje. Con poca, en rojo.
func _draw_battery() -> void:
	var color := LOW_BATTERY_COLOR if _state.battery < LOW_BATTERY else TEXT_COLOR
	draw_rect(Rect2(216, 22, 20, 9), color, false)
	draw_rect(Rect2(218, 24, roundf(16.0 * _state.battery / 100.0), 5), color)
	draw_rect(Rect2(236, 24, 2, 5), color)
	_draw_text(self, "%d%%" % ceili(_state.battery), Vector2(162, 31), color)


## Las publicaciones a la vista, corridas según el scroll. Sin batería, un aviso.
func _draw_feed() -> void:
	if not _state.has_battery():
		_feed.draw_rect(Rect2(Vector2.ZERO, _feed.size), GLASS_COLOR)
		var center := Vector2(0, _feed.size.y / 2.0)
		_feed.draw_string(FONT, center, tr(NO_BATTERY_KEY), HORIZONTAL_ALIGNMENT_CENTER, _feed.size.x, FONT_SIZE, DIM_COLOR)
		return
	if _posts.is_empty():
		return
	for slot: int in _slots:
		_draw_post(slot, roundf(slot * POST_HEIGHT - scroll))


## Una publicación: avatar y usuario, la foto, los íconos, y los "me gusta" y el texto. Los nombres y los textos son
## barras grises, siempre del mismo largo en cada lugar de la lista.
func _draw_post(slot: int, top: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = posmod(slot, _posts.size()) + 100
	_feed.draw_circle(Vector2(POST_MARGIN + 9.0, top + 14.0), 9.0, AVATAR_COLOR)
	_draw_text_bar(POST_MARGIN + 26.0, top + 11.0, rng.randi_range(50, 110), STRONG_BAR_COLOR)
	_draw_text(_feed, "···", Vector2(204, top + 18), DIM_COLOR)
	var photo := Rect2(0, top + 28.0, PHOTO_SIZE, PHOTO_SIZE)
	var picture: Texture2D = _slots[slot].picture
	if picture != null:
		_feed.draw_texture_rect(picture, photo, false)
	else:
		_feed.draw_rect(photo, AVATAR_COLOR)
	var icons_top := top + 266.0
	PhoneIcons.draw_icon(_feed, PhoneIcons.HEART, Vector2(POST_MARGIN, icons_top), TEXT_COLOR)
	PhoneIcons.draw_icon(_feed, PhoneIcons.COMMENT, Vector2(POST_MARGIN + 20.0, icons_top), TEXT_COLOR)
	PhoneIcons.draw_icon(_feed, PhoneIcons.SEND, Vector2(POST_MARGIN + 40.0, icons_top), TEXT_COLOR)
	PhoneIcons.draw_icon(_feed, PhoneIcons.BOOKMARK, Vector2(PHOTO_SIZE - POST_MARGIN - 9.0, icons_top), TEXT_COLOR)
	_draw_text_bar(POST_MARGIN, top + 288.0, rng.randi_range(40, 70), STRONG_BAR_COLOR)
	_draw_text_bar(POST_MARGIN, top + 301.0, rng.randi_range(150, 216), BAR_COLOR)
	_draw_text_bar(POST_MARGIN, top + 312.0, rng.randi_range(60, 180), BAR_COLOR)
	_feed.draw_rect(Rect2(0, top + POST_HEIGHT - 1.0, _feed.size.x, 1), DIVIDER_COLOR)


## Una barra gris que simula una línea de texto.
func _draw_text_bar(left: float, top: float, width: float, color: Color) -> void:
	_feed.draw_rect(Rect2(left, top, width, TEXT_BAR_HEIGHT), color)


func _draw_text(canvas: CanvasItem, text: String, baseline_left: Vector2, color: Color) -> void:
	canvas.draw_string(FONT, baseline_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
