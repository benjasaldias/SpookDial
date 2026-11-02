extends Control
## El celular ampliado (diseño §10.2): las redes sociales que Matías scrollea con la rueda del mouse para
## recuperar Sanity. Es provisional hasta el arte de Benja: el celular y las publicaciones se dibujan con
## rectángulos, y una publicación sin imagen muestra un paisaje de su color.
## Las publicaciones se repiten sin fin. Se cierra con clic derecho; Esc y un clic fuera lo cierran desde
## el escritorio.

const NightState := preload("res://scripts/core/night_state.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## El nombre de la red social (phone.csv).
const APP_NAME_KEY := "PHONE_APP_NAME"
const SIZE := Vector2(260, 520)
const FONT_SIZE := 11
## Alto de cada publicación en el feed.
const POST_HEIGHT := 236.0
## Cuántos píxeles avanza el feed con cada movimiento de la rueda.
const WHEEL_STEP := 60.0
## Cuánto avanza con el touchpad, por unidad de su gesto.
const PAN_STEP := 30.0
## Qué tan rápido sigue el feed a la rueda.
const SCROLL_SPEED := 10.0
## Colores provisionales: el celular de noche, en modo oscuro.
const BODY_COLOR := Color(0.07, 0.08, 0.12)
const EDGE_COLOR := Color(0.24, 0.26, 0.34)
const GLASS_COLOR := Color(0.01, 0.01, 0.03)
const FEED_COLOR := Color(0.07, 0.08, 0.11)
const TEXT_COLOR := Color(0.86, 0.88, 0.94)
const DIM_COLOR := Color(0.5, 0.54, 0.64)
const ACCENT_COLOR := Color(1.0, 0.7, 0.4)
const HEART_COLOR := Color(1.0, 0.35, 0.45)
const DIVIDER_COLOR := Color(0.16, 0.17, 0.22)

## Cuántos píxeles se scrolleó. Crece sin fin hacia abajo: las publicaciones se repiten.
var scroll := 0.0

var _target_scroll := 0.0
var _state: NightState
var _posts: Array[PhonePostData] = []
var _rest_position := Vector2.ZERO

@onready var _feed: Control = $Feed


func _ready() -> void:
	hide()
	_rest_position = position
	_feed.draw.connect(_draw_feed)


## Conecta el celular al estado de la noche (la hora y Sanity) y a sus publicaciones.
func setup(state: NightState, posts: Array[PhonePostData]) -> void:
	_state = state
	_posts = posts


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


## Avanza el feed `amount` píxeles (hacia abajo si es positivo). Mientras Matías scrollea, Sanity sube.
func scroll_by(amount: float) -> void:
	_target_scroll += amount
	_state.scroll()


## La publicación que está arriba del feed, por su posición en la lista.
func post_at_top() -> int:
	if _posts.is_empty():
		return -1
	return floori(fposmod(scroll, POST_HEIGHT * _posts.size()) / POST_HEIGHT)


func _process(delta: float) -> void:
	if not visible:
		return
	scroll = lerpf(scroll, _target_scroll, minf(delta * SCROLL_SPEED, 1.0))
	queue_redraw()
	_feed.queue_redraw()


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


## El celular: el cuerpo con las esquinas en escalón, la barra con la hora, el nombre de la red social y,
## abajo, la barra de inicio. El feed se dibuja aparte, recortado a su pantalla.
func _draw() -> void:
	draw_rect(Rect2(4, 0, SIZE.x - 8, SIZE.y), BODY_COLOR)
	draw_rect(Rect2(0, 4, SIZE.x, SIZE.y - 8), BODY_COLOR)
	draw_rect(Rect2(2, 2, SIZE.x - 4, SIZE.y - 4), BODY_COLOR)
	draw_rect(Rect2(2, 2, SIZE.x - 4, SIZE.y - 4), EDGE_COLOR, false)
	draw_rect(Rect2(10, 14, 240, 492), GLASS_COLOR)
	draw_rect(Rect2(110, 6, 40, 3), EDGE_COLOR)
	draw_rect(Rect2(14, 18, 232, 478), FEED_COLOR)
	_draw_text(self, _state.clock_text(), Vector2(22, 31), TEXT_COLOR)
	for bar in 4:
		draw_rect(Rect2(196 + bar * 4, 28 - bar * 2, 3, 3 + bar * 2), TEXT_COLOR)
	draw_rect(Rect2(216, 22, 20, 9), TEXT_COLOR, false)
	draw_rect(Rect2(218, 24, 12, 5), TEXT_COLOR)
	draw_rect(Rect2(236, 24, 2, 5), TEXT_COLOR)
	draw_string(FONT, Vector2(22, 57), tr(APP_NAME_KEY), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE * 2, ACCENT_COLOR)
	draw_string(FONT, Vector2(214, 55), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	draw_rect(Rect2(14, 63, 232, 1), DIVIDER_COLOR)
	draw_rect(Rect2(98, 487, 64, 3), DIM_COLOR)


## Las publicaciones, una debajo de otra y repetidas sin fin, corridas según el scroll.
func _draw_feed() -> void:
	if _posts.is_empty():
		return
	var offset := fposmod(scroll, POST_HEIGHT * _posts.size())
	var index := floori(offset / POST_HEIGHT)
	var top := index * POST_HEIGHT - offset
	while top < _feed.size.y:
		_draw_post(index % _posts.size(), top)
		top += POST_HEIGHT
		index += 1


## Una publicación: quién la publica, su imagen, los "me gusta" y su texto en hasta 2 líneas.
func _draw_post(index: int, top: float) -> void:
	var post := _posts[index]
	var author := tr(post.author_key)
	var avatar := Rect2(10, top + 8, 20, 20)
	_feed.draw_rect(avatar, post.color)
	_draw_text(_feed, author.trim_prefix("@").left(1).to_upper(), avatar.position + Vector2(7, 15), FEED_COLOR)
	_draw_text(_feed, author, Vector2(36, top + 22), TEXT_COLOR)
	_draw_text(_feed, "···", Vector2(200, top + 22), DIM_COLOR)
	var picture := Rect2(10, top + 34, 212, 140)
	if post.picture != null:
		_feed.draw_texture_rect(post.picture, picture, false)
	else:
		_draw_landscape(picture, post.color, index)
	_draw_text(_feed, "♥ %d" % _likes(index), Vector2(10, top + 192), HEART_COLOR)
	_feed.draw_multiline_string(FONT, Vector2(10, top + 210), tr(post.text_key), HORIZONTAL_ALIGNMENT_LEFT, 212,
			FONT_SIZE, 2, TEXT_COLOR)
	_feed.draw_rect(Rect2(0, top + POST_HEIGHT - 1, _feed.size.x, 1), DIVIDER_COLOR)


## Una imagen provisional: un paisaje del color de la publicación, distinto en cada una.
func _draw_landscape(rect: Rect2, color: Color, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sky := rect.size.y * 0.6
	for band in 6:
		_feed.draw_rect(Rect2(rect.position.x, rect.position.y + band * sky / 6.0, rect.size.x, sky / 6.0 + 1.0),
				color.lightened(0.45 - band * 0.07))
	var sun := rect.position + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.15, 0.35)) * rect.size
	_feed.draw_circle(sun.round(), 12.0, color.lightened(0.75))
	var height := rng.randf_range(0.3, 0.5)
	for x in range(0, int(rect.size.x), 4):
		height = clampf(height + rng.randf_range(-0.05, 0.05), 0.2, 0.6)
		var hill := roundf(height * rect.size.y)
		_feed.draw_rect(Rect2(rect.position.x + x, rect.end.y - hill, 4, hill), color.darkened(0.45))
	_feed.draw_rect(Rect2(rect.position.x, rect.end.y - 20, rect.size.x, 20), color.darkened(0.7))


## Los "me gusta" de una publicación: siempre los mismos para cada una.
func _likes(index: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = index + 100
	return rng.randi_range(12, 2400)


func _draw_text(canvas: CanvasItem, text: String, baseline_left: Vector2, color: Color) -> void:
	canvas.draw_string(FONT, baseline_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
