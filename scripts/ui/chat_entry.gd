extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, la señal, la vida, el estado y el temporizador.
## Titila mientras se anuncia una interferencia (diseño §10.1).

signal pressed

enum State { IDLE, WARNING, DISCONNECTED, SELECTED, STUNNED }

const SIZE := Vector2(243, 26)
const STATE_MODULATE := {
	State.IDLE: Color(1, 1, 1),
	State.WARNING: Color(1, 1, 1),
	State.DISCONNECTED: Color(0.45, 0.45, 0.5),
	State.SELECTED: Color(1.3, 1.3, 1.3),
	State.STUNNED: Color(0.7, 0.6, 0.6),
}
## Lo que dice el temporizador mientras el amigo está aturdido (ui.csv). Lleva {seconds}.
const STUNNED_KEY := "ENTRY_STUNNED"
## Las marcas de vida son provisionales, hasta el arte de las entradas.
const HEALTH_PIP_SIZE := Vector2(6, 10)
const HEALTH_COLOR := Color(0.85, 0.9, 0.95)
## Las barras de señal también son provisionales (docs/06 §3): 5 barras que crecen de a 2 px.
const SIGNAL_BARS := 5
const SIGNAL_BAR_WIDTH := 3
## Lo que dice el temporizador cuando el amigo mandó un video (lleva {seconds}) y cuando está sin señal (ui.csv).
const VIDEO_KEY := "ENTRY_VIDEO"
const OFFLINE_KEY := "ENTRY_OFFLINE"
## Cada cuánto titila la entrada mientras se anuncia una interferencia.
const FLICKER_SECONDS := 0.12

@export var display_name := "":
	set(value):
		display_name = value
		if is_node_ready():
			_name_label.text = value

var state: State = State.IDLE
## La vida que muestra, de `max_health`. -1 hasta la primera vez.
var health := -1
var max_health := -1
## Las barras de señal que muestra, de 0 a 5. -1 hasta la primera vez.
var signal_bars := -1
## Se anuncia una interferencia: la entrada titila.
var interference_warning := false

var _flicker_time := 0.0

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _signal_box: HBoxContainer = $Signal
@onready var _health_box: HBoxContainer = $Health
@onready var _timer_label: Label = $TimerLabel


func _ready() -> void:
	_name_label.text = display_name
	set_state(State.IDLE)
	set_seconds_left(-1)


func _process(delta: float) -> void:
	if not interference_warning:
		return
	_flicker_time += delta
	modulate.a = 0.35 if fmod(_flicker_time, FLICKER_SECONDS * 2.0) < FLICKER_SECONDS else 1.0


func set_state(new_state: State) -> void:
	state = new_state
	_background.play(&"warning" if new_state == State.WARNING else &"idle")
	_background.modulate = STATE_MODULATE[new_state]


## Muestra los segundos restantes. Con un valor negativo, oculta el temporizador.
func set_seconds_left(seconds: int) -> void:
	_timer_label.visible = seconds >= 0
	_timer_label.text = str(seconds)


## Muestra cuánto le queda de aturdimiento, en lugar del temporizador.
func show_stun(seconds: int) -> void:
	_timer_label.visible = true
	_timer_label.text = tr(STUNNED_KEY).format({"seconds": seconds})


## El amigo mandó un video: cuánto le queda para empezar o terminar la descarga, en lugar del temporizador.
func show_video(seconds: int) -> void:
	_timer_label.visible = true
	_timer_label.text = tr(VIDEO_KEY).format({"seconds": seconds})


## El amigo está sin señal.
func show_offline() -> void:
	_timer_label.visible = true
	_timer_label.text = tr(OFFLINE_KEY)


## Titila mientras se anuncia una interferencia; al pasar, queda encendida.
func set_interference_warning(active: bool) -> void:
	interference_warning = active
	if not active:
		_flicker_time = 0.0
		modulate.a = 1.0


## Una barra por cada 20 de señal: llenas hasta su nivel y vacías (solo el borde) arriba de él, para que no
## dependa del color. Solo se rehacen si cambió cuántas van llenas.
func set_signal(level: float) -> void:
	var bars := ceili(clampf(level, 0.0, 100.0) / (100.0 / SIGNAL_BARS))
	if bars == signal_bars:
		return
	signal_bars = bars
	for bar: Node in _signal_box.get_children():
		_signal_box.remove_child(bar)
		bar.queue_free()
	for index in SIGNAL_BARS:
		var bar := Panel.new()
		bar.custom_minimum_size = Vector2(SIGNAL_BAR_WIDTH, 4 + index * 2)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override(&"panel", _pip_style(index < bars))
		_signal_box.add_child(bar)


## Una marca por punto de vida: llena si lo tiene y vacía (solo el borde) si lo perdió, para que no
## dependa del color (diseño §19). Solo se rehacen si la vida cambió.
func set_health(current: int, maximum: int) -> void:
	if current == health and maximum == max_health:
		return
	health = current
	max_health = maximum
	for pip: Node in _health_box.get_children():
		_health_box.remove_child(pip)
		pip.queue_free()
	for index in maximum:
		var pip := Panel.new()
		pip.custom_minimum_size = HEALTH_PIP_SIZE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.add_theme_stylebox_override(&"panel", _pip_style(index < current))
		_health_box.add_child(pip)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and Rect2(Vector2.ZERO, SIZE).has_point(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()


static func _pip_style(full: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEALTH_COLOR
	style.draw_center = full
	style.border_color = HEALTH_COLOR
	style.set_border_width_all(1)
	return style
