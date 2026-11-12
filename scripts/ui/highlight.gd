extends Node2D
## El parpadeo (docs/26 §2.3): un borde que se enciende y se apaga alrededor de un control para avisar qué apretar. Lo
## usa el botón de la señal del chat cuando el amigo está sin señal y, desde S21j, el tutorial. Con "Reducir destellos"
## (diseño §19), el borde queda fijo.
## Se agrega como hijo del control que rodea, con add_child, y dibuja en su espacio, por encima de sus vecinos. También
## rodea un nodo 2D (las entradas del PC), con el tamaño que se le dé.

## Segundos encendido y apagado.
const ON_SECONDS := 0.4
const OFF_SECONDS := 0.4
## El grosor del borde y cuánto se separa del control, en píxeles.
const WIDTH := 2
const MARGIN := 2
## Ámbar, como las frases que se pueden clickear.
const DEFAULT_COLOR := Color(1.0, 0.7, 0.28)

## Sin activar no se dibuja nada. Al activarlo, empieza encendido.
var active := false:
	set(value):
		if value == active:
			return
		active = value
		_time = 0.0
		queue_redraw()
## La opción "Reducir destellos": el borde queda fijo.
var reduce_flashes := false:
	set(value):
		reduce_flashes = value
		queue_redraw()
var color := DEFAULT_COLOR
## El tamaño de lo que rodea, si no es un Control.
var target_size := Vector2.ZERO

## Segundos desde que se activó.
var _time := 0.0


func _init() -> void:
	z_index = 1


## Si el borde está encendido a los `time` segundos de activarse.
static func is_lit(time: float, reduce: bool) -> bool:
	return reduce or fmod(time, ON_SECONDS + OFF_SECONDS) < ON_SECONDS


## El borde se ve ahora.
func is_showing() -> bool:
	return active and is_lit(_time, reduce_flashes)


## El rectángulo del borde, en el espacio del control: el del control, agrandado por la separación y el grosor.
func border_rect() -> Rect2:
	var target := get_parent() as Control
	var size := target.size if target != null else target_size
	if size == Vector2.ZERO:
		return Rect2()
	return Rect2(Vector2.ZERO, size).grow(MARGIN + WIDTH)


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	# Cada cuadro: así también sigue al control si cambia de tamaño.
	queue_redraw()


## Cuatro rectángulos llenos, para que los píxeles queden nítidos.
func _draw() -> void:
	if not is_showing():
		return
	var rect := border_rect()
	var across := Vector2(rect.size.x, WIDTH)
	var down := Vector2(WIDTH, rect.size.y - 2 * WIDTH)
	draw_rect(Rect2(rect.position, across), color)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - WIDTH), across), color)
	draw_rect(Rect2(rect.position + Vector2(0, WIDTH), down), color)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - WIDTH, WIDTH), down), color)
