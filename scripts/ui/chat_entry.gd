extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, la señal, la vida, el estado y el temporizador.
## Titila mientras se anuncia una interferencia (diseño §10.1). Con "Reducir destellos" (diseño §19), la alerta
## queda fija en lugar de parpadear, y el aviso de una interferencia atenúa la entrada en lugar de hacerla titilar.
## En alerta pita una vez por segundo, con la nota de su amigo (pedido de Benja, 12 de noviembre): el escritorio le da un
## reloj común a las 3 entradas, así que pitan juntas y hacen su acorde, y la entrada se enciende en rojo con el pitido.

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
## Los 6 cuadros de las barras de señal, de 0 a 5 barras llenas.
const SIGNAL_SHEET := preload("res://art/ui/signal_bars.png")
const SIGNAL_FRAME := Vector2(19, 12)
## Lo que dice el temporizador cuando el amigo mandó un video (lleva {seconds}) y cuando está sin señal (ui.csv).
const VIDEO_KEY := "ENTRY_VIDEO"
const OFFLINE_KEY := "ENTRY_OFFLINE"
## Cada cuánto titila la entrada mientras se anuncia una interferencia.
const FLICKER_SECONDS := 0.12
## Qué tan atenuada queda la entrada al titilar, o mientras dura el aviso si se reducen los destellos.
const DIM_ALPHA := 0.35
## Cada cuántos segundos pita en alerta.
const ALARM_SECONDS := 1.0
const Highlight := preload("res://scripts/ui/highlight.gd")

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
## La opción "Reducir destellos" (diseño §19).
var reduce_flashes := false:
	set(value):
		reduce_flashes = value
		if is_node_ready():
			set_state(state)
			_highlight.reduce_flashes = value

## El pitido de su amigo, o null.
var alarm: AudioStream:
	set(value):
		alarm = value
		if _alarm_player != null:
			_alarm_player.stream = value
## No pita: el escritorio la calla durante Audio Sync y mientras suena un audio de un amigo.
var muted := false
## Recibe clics. En la noche 0, solo las de los amigos que León va usando (Plan 9.5).
var enabled := true
## Parpadea un borde a su alrededor: en la noche 0, la entrada que hay que abrir.
var highlighted := false:
	set(value):
		highlighted = value
		if _highlight != null:
			_highlight.active = value

var _flicker_time := 0.0
## El segundo del reloj común en que pitó o se miró por última vez; -1 antes de la primera.
var _alarm_beat := -1
var _alarm_player: AudioStreamPlayer
var _highlight: Highlight

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _signal_box: HBoxContainer = $Signal
@onready var _health_box: HBoxContainer = $Health
@onready var _timer_label: Label = $TimerLabel


func _ready() -> void:
	_name_label.text = display_name
	_alarm_player = AudioStreamPlayer.new()
	_alarm_player.name = "Alarm"
	_alarm_player.bus = &"Effects"
	_alarm_player.stream = alarm
	add_child(_alarm_player)
	_highlight = Highlight.new()
	_highlight.name = "Highlight"
	_highlight.target_size = SIZE
	_highlight.active = highlighted
	add_child(_highlight)
	set_state(State.IDLE)
	set_seconds_left(-1)


func _process(delta: float) -> void:
	if not interference_warning:
		return
	_flicker_time += delta
	var dim := reduce_flashes or fmod(_flicker_time, FLICKER_SECONDS * 2.0) < FLICKER_SECONDS
	modulate.a = DIM_ALPHA if dim else 1.0


func set_state(new_state: State) -> void:
	state = new_state
	_background.play(&"warning" if new_state == State.WARNING else &"idle")
	if reduce_flashes and new_state == State.WARNING:
		# Fija en el cuadro de la alerta, sin parpadear.
		_background.pause()
		_background.frame = 0
	_background.modulate = STATE_MODULATE[new_state]


## Mira el reloj común (`clock`, en segundos): al empezar cada segundo, si está en alerta y no está callada, pita y se
## enciende en rojo. Devuelve si pitó.
func ring(clock: float) -> bool:
	var beat := floori(clock / ALARM_SECONDS)
	var first := _alarm_beat < 0
	var new_beat := beat != _alarm_beat
	_alarm_beat = beat
	if first or not new_beat or state != State.WARNING or muted or alarm == null:
		return false
	_alarm_player.play()
	_background.frame = 0
	_background.frame_progress = 0.0
	return true


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


## Una barra por cada 20 de señal: llenas hasta su nivel y vacías (solo el borde) arriba de él, y sin señal una x,
## para que no dependa del color. Es un cuadro de art/ui/signal_bars.png (pixel art de Claude), uno por cada
## cantidad de barras llenas.
func set_signal(level: float) -> void:
	var bars := ceili(clampf(level, 0.0, 100.0) / (100.0 / SIGNAL_BARS))
	if bars == signal_bars:
		return
	signal_bars = bars
	if _signal_box.get_child_count() == 0:
		var picture := TextureRect.new()
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.size_flags_vertical = Control.SIZE_SHRINK_END
		picture.texture = AtlasTexture.new()
		(picture.texture as AtlasTexture).atlas = SIGNAL_SHEET
		_signal_box.add_child(picture)
	var atlas := (_signal_box.get_child(0) as TextureRect).texture as AtlasTexture
	atlas.region = Rect2(bars * SIGNAL_FRAME.x, 0, SIGNAL_FRAME.x, SIGNAL_FRAME.y)


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
			and accepts_click_at(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()


## Un clic en `local` (en su espacio) la abre: está habilitada y el clic cae sobre ella.
func accepts_click_at(local: Vector2) -> bool:
	return enabled and Rect2(Vector2.ZERO, SIZE).has_point(local)


static func _pip_style(full: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEALTH_COLOR
	style.draw_center = full
	style.border_color = HEALTH_COLOR
	style.set_border_width_all(1)
	return style
