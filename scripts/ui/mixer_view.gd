extends Control
## El mixer visto desde arriba, para hacer Audio Sync (diseño §10.6). Es provisional hasta el arte de Benja:
## se dibuja con rectángulos, con los colores del mixer del escritorio.
##
## Cada fader es el canal de un amigo, y su altura es la señal. Al elegir un canal empieza una ronda: la base
## marca el tiempo, el amigo aplaude un ritmo y Matías lo repite con la barra espaciadora o con clics en el
## mixer (decisión de Benja). El VU-metro de la izquierda muestra los golpes de Matías, y el de la derecha,
## los aplausos del amigo. Si sale bien, la señal del amigo vuelve a 100; si no, se reintenta.
## Se cierra con clic derecho; Esc y un clic fuera lo cierran desde el escritorio.

const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## Textos del mixer (ui.csv). MIXER_LISTEN y MIXER_SUCCESS llevan {friend}.
const TITLE_KEY := "MIXER_TITLE"
const YOU_KEY := "MIXER_YOU"
const PICK_KEY := "MIXER_PICK"
const COUNT_IN_KEY := "MIXER_COUNT_IN"
const LISTEN_KEY := "MIXER_LISTEN"
const YOUR_TURN_KEY := "MIXER_YOUR_TURN"
const SUCCESS_KEY := "MIXER_SUCCESS"
const FAIL_KEY := "MIXER_FAIL"
const HINT_KEY := "MIXER_HINT"
const NO_SYNC_KEY := "MIXER_NO_SYNC"

const SIZE := Vector2(440, 430)
const FONT_SIZE := 11
## Colores provisionales, tomados de mixer_sprite.
const BODY_COLOR := Color(0.11, 0.12, 0.22)
const PANEL_COLOR := Color(0.15, 0.16, 0.29)
const EDGE_COLOR := Color(0.62, 0.64, 0.7)
const SHADOW_COLOR := Color(0.04, 0.04, 0.09)
const SCREEN_COLOR := Color(0.13, 0.22, 0.58)
const NEEDLE_COLOR := Color(0.55, 0.93, 0.95)
const TEXT_COLOR := Color(0.79, 0.84, 0.95)
const DIM_COLOR := Color(0.45, 0.5, 0.62)
const LIGHT_OFF := Color(0.2, 0.22, 0.34)
const CLAP_LIGHT := Color(0.38, 0.62, 1.0)
const HIT_LIGHT := Color(0.49, 0.88, 0.54)
const MISS_LIGHT := Color(1.0, 0.3, 0.37)
const LED_RED := Color(1.0, 0.25, 0.3)
const LED_GREEN := Color(0.35, 0.85, 0.45)
## Dónde va cada parte, en píxeles del mixer.
const METER_PLAYER := Rect2(100, 36, 112, 72)
const METER_FRIEND := Rect2(228, 36, 112, 72)
const STEP_TOP := 140.0
const STEP_SIZE := 10.0
const STEP_GAP := 4.0
const CHANNEL_TOP := 168.0
const CHANNEL_LEFT := 92.0
const CHANNEL_SIZE := Vector2(76, 192)
const CHANNEL_GAP := 12.0
## El riel del fader, desde arriba del canal.
const FADER_TOP := 52.0
const FADER_HEIGHT := 104.0
## Cuánto baja por segundo la aguja de un VU-metro después de un golpe (de 1 a 0).
const METER_FALL := 3.0

var selected_friend := 0
## La ronda en curso o la última, o null si todavía no empieza ninguna.
var sync_round: AudioSyncRound
## La aguja de cada VU-metro, de 0 a 1: la de Matías, a la izquierda, y la del amigo, a la derecha.
var player_level := 0.0
var friend_level := 0.0

var _manager: RequestManager
var _friend_names: Array[String] = []
var _friend_colors: Array[Color] = []
## La altura que muestra cada fader, de 0 a 1. Sigue a la señal con suavidad.
var _faders: Array[float] = []
## Las luces encendidas: corchea de la parte del amigo o de Matías → su color.
var _lights := {}
## La corchea que suena ahora en la parte del amigo o en la de Matías, o -1.
var _playhead := -1
## El LED de arriba parpadea con la base.
var _led := 0.0
## Para el parpadeo de los LED de los canales.
var _blink := 0.0
var _round_finished := false
var _rest_position := Vector2.ZERO

@onready var _kick: AudioStreamPlayer = $Kick
@onready var _tick: AudioStreamPlayer = $Tick
@onready var _clap: AudioStreamPlayer = $Clap
@onready var _tap: AudioStreamPlayer = $Tap
@onready var _success: AudioStreamPlayer = $Success
@onready var _fail: AudioStreamPlayer = $Fail


func _ready() -> void:
	hide()
	_rest_position = position


## Conecta el mixer a las solicitudes, que tienen el estado de la noche. Un canal por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData]) -> void:
	_manager = manager
	for friend: FriendData in friends:
		_friend_names.append(tr(friend.name_key))
		_friend_colors.append(friend.color)
		_faders.append(1.0)


## Aplausos del Audio Sync de esta noche: 0 si no hay.
func beats() -> int:
	return _manager.night().audio_sync_beats


## Se abre en el canal del amigo con menos señal, sin ronda: Matías la empieza cuando quiere.
func open() -> void:
	sync_round = null
	_lights.clear()
	_playhead = -1
	selected_friend = _weakest_friend()
	for index in _faders.size():
		_faders[index] = _manager.state.friends[index].signal_level / 100.0
	show()
	# Sube desde el escritorio.
	position = _rest_position + Vector2(0, 24)
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position", _rest_position, 0.15)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)


## Se abre en el canal del amigo `friend_index` y la ronda empieza enseguida: es lo que hace el botón
## «Sincronizar» del chat (decisión de Benja).
func open_for(friend_index: int) -> void:
	open()
	selected_friend = friend_index
	start_round(friend_index)


## Se cierra y corta la ronda.
func close() -> void:
	sync_round = null
	hide()


## Empieza una ronda en el canal del amigo `friend_index`. No hay rondas si la noche no tiene Audio Sync.
func start_round(friend_index: int) -> void:
	if beats() <= 0:
		return
	selected_friend = friend_index
	var balance := _manager.catalog.balance
	sync_round = AudioSyncRound.new(beats(), balance.audio_sync_bpm, balance.audio_sync_tolerance, _manager.rng)
	_round_finished = false
	_lights.clear()
	_playhead = -1


## Hay una ronda sonando.
func is_playing() -> bool:
	return sync_round != null and sync_round.phase() != AudioSyncRound.Phase.DONE


## Matías golpea: suena su golpe y se levanta su VU-metro. En su parte, la luz de la corchea queda verde si
## acertó o roja si el golpe sobró.
func tap() -> void:
	if not is_playing():
		return
	_tap.play()
	player_level = 1.0
	match sync_round.tap():
		AudioSyncRound.Tap.HIT:
			_lights[sync_round.hits()[-1]] = HIT_LIGHT
		AudioSyncRound.Tap.MISS:
			_lights[maxi(_playhead, 0)] = MISS_LIGHT
	if sync_round.phase() == AudioSyncRound.Phase.DONE:
		_finish_round()


## El rectángulo del canal del amigo `friend_index`, en píxeles del mixer.
func channel_rect(friend_index: int) -> Rect2:
	return Rect2(Vector2(CHANNEL_LEFT + friend_index * (CHANNEL_SIZE.x + CHANNEL_GAP), CHANNEL_TOP), CHANNEL_SIZE)


## Lo que dice el mixer abajo: qué hacer o cómo salió la ronda.
func status_text() -> String:
	var friend := _friend_names[selected_friend]
	if beats() <= 0:
		return tr(NO_SYNC_KEY)
	if sync_round == null:
		return tr(PICK_KEY)
	match sync_round.phase():
		AudioSyncRound.Phase.COUNT_IN:
			return tr(COUNT_IN_KEY)
		AudioSyncRound.Phase.CALL:
			return tr(LISTEN_KEY).format({"friend": friend})
		AudioSyncRound.Phase.RESPONSE:
			return tr(YOUR_TURN_KEY)
	return tr(SUCCESS_KEY if sync_round.succeeded else FAIL_KEY).format({"friend": friend})


func _process(delta: float) -> void:
	if not visible:
		return
	player_level = maxf(player_level - delta * METER_FALL, 0.0)
	friend_level = maxf(friend_level - delta * METER_FALL, 0.0)
	_led = maxf(_led - delta * 4.0, 0.0)
	_blink += delta
	for index in _faders.size():
		var target := _manager.state.friends[index].signal_level / 100.0
		_faders[index] = lerpf(_faders[index], target, minf(delta * 8.0, 1.0))
	if is_playing():
		for step: int in sync_round.advance(delta):
			_play_step(step)
		if sync_round.phase() == AudioSyncRound.Phase.DONE:
			_finish_round()
	queue_redraw()


## Clic izquierdo: durante una ronda, golpea; si no, empieza la ronda del canal clickeado.
## Clic derecho: se cierra.
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	accept_event()
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		close()
	elif mouse.button_index == MOUSE_BUTTON_LEFT:
		if is_playing():
			tap()
			return
		for index in _faders.size():
			if channel_rect(index).has_point(mouse.position):
				start_round(index)


## La barra espaciadora golpea durante una ronda; si no hay ninguna sonando, empieza la del canal elegido.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo or key.keycode != KEY_SPACE:
		return
	get_viewport().set_input_as_handled()
	if is_playing():
		tap()
	else:
		start_round(selected_friend)


## Suena la corchea `step`: la base en cada golpe (bombo y platillo) y el aplauso del amigo, con su luz.
## Cuando le toca a Matías, las luces se apagan: el ritmo hay que recordarlo.
func _play_step(step: int) -> void:
	if sync_round.is_beat(step):
		_led = 1.0
		if step % 4 == 0:
			_kick.volume_db = 0.0 if sync_round.is_accent(step) else -6.0
			_kick.play()
		else:
			_tick.play()
	var response_step := AudioSyncRound.STEPS_PER_BAR + sync_round.steps
	if step == response_step:
		_lights.clear()
	if step >= response_step:
		_playhead = step - response_step
	elif step >= AudioSyncRound.STEPS_PER_BAR:
		_playhead = step - AudioSyncRound.STEPS_PER_BAR
	if sync_round.is_clap(step):
		_clap.play()
		friend_level = 1.0
		_lights[step - AudioSyncRound.STEPS_PER_BAR] = CLAP_LIGHT


## Al terminar la ronda, las luces muestran el ritmo: en verde lo que acertó Matías y en rojo lo que se le
## pasó. Si salió bien, la señal del amigo vuelve a 100 y el chat avisa si estaba desconectado.
func _finish_round() -> void:
	if _round_finished:
		return
	_round_finished = true
	_playhead = -1
	for call_step: int in sync_round.pattern:
		_lights[call_step] = HIT_LIGHT if sync_round.hits().has(call_step) else MISS_LIGHT
	if sync_round.succeeded:
		_success.play()
		_manager.restore_signal(selected_friend)
	else:
		_fail.play()


## El amigo con menos señal: el que más necesita sincronizarse.
func _weakest_friend() -> int:
	var friends := _manager.state.friends
	var weakest := 0
	for index in range(1, friends.size()):
		if friends[index].signal_level < friends[weakest].signal_level:
			weakest = index
	return weakest


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, SIZE)
	draw_rect(body, SHADOW_COLOR)
	draw_rect(body.grow(-2), EDGE_COLOR)
	draw_rect(body.grow(-4), BODY_COLOR)
	draw_rect(body.grow(-10), PANEL_COLOR, false)
	_draw_text(tr(TITLE_KEY).to_upper(), Vector2(18, 26), DIM_COLOR)
	_draw_led(Vector2(410, 16), LED_RED, _led if is_playing() else 0.0)
	_draw_knob(Vector2(52, 72))
	_draw_knob(Vector2(388, 72))
	_draw_meter(METER_PLAYER, player_level)
	_draw_meter(METER_FRIEND, friend_level)
	_draw_text_centered(tr(YOU_KEY).to_upper(), METER_PLAYER.get_center().x, 128, TEXT_COLOR)
	_draw_text_centered(_friend_names[selected_friend].to_upper(), METER_FRIEND.get_center().x, 128,
			_friend_colors[selected_friend])
	_draw_steps()
	for index in _faders.size():
		_draw_channel(index)
	_draw_decor()
	_draw_text_centered(status_text().to_upper(), SIZE.x / 2.0, 394, TEXT_COLOR)
	_draw_text_centered(tr(HINT_KEY).to_upper(), SIZE.x / 2.0, 414, DIM_COLOR)


## Un VU-metro azul: la aguja se levanta con cada golpe y vuelve a caer.
func _draw_meter(rect: Rect2, level: float) -> void:
	draw_rect(rect, SHADOW_COLOR)
	draw_rect(rect.grow(-2), SCREEN_COLOR)
	var pivot := Vector2(rect.get_center().x, rect.end.y - 8)
	for index in 9:
		var angle := deg_to_rad(-50.0 + index * 12.5)
		var direction := Vector2(sin(angle), -cos(angle))
		var mark_length := 6.0 if index % 2 == 0 else 3.0
		draw_line(pivot + direction * 48.0, pivot + direction * (48.0 + mark_length), NEEDLE_COLOR.darkened(0.35))
	var needle := deg_to_rad(lerpf(-50.0, 50.0, level))
	draw_line(pivot, pivot + Vector2(sin(needle), -cos(needle)) * 50.0, NEEDLE_COLOR, 2.0)
	draw_rect(Rect2(pivot - Vector2(3, 3), Vector2(6, 6)), EDGE_COLOR)


## Una luz por corchea de la parte del amigo: se encienden con sus aplausos y, en la parte de Matías, con sus
## golpes. La que suena ahora se ve más clara, y cada golpe de la base tiene una marca debajo.
func _draw_steps() -> void:
	var count := beats() * 2
	if count <= 0:
		return
	var left := (SIZE.x - count * STEP_SIZE - (count - 1) * STEP_GAP) / 2.0
	for index in count:
		var rect := Rect2(left + index * (STEP_SIZE + STEP_GAP), STEP_TOP, STEP_SIZE, STEP_SIZE)
		var color: Color = _lights.get(index, LIGHT_OFF)
		if index == _playhead:
			color = color.lightened(0.4)
		draw_rect(rect.grow(1), SHADOW_COLOR)
		draw_rect(rect, color)
		if index % 2 == 0:
			draw_rect(Rect2(rect.position + Vector2(4, 14), Vector2(2, 2)), DIM_COLOR)


## El canal de un amigo: su nombre, un LED, el fader a la altura de su señal y el número. El canal elegido
## lleva un borde de su color.
func _draw_channel(index: int) -> void:
	var rect := channel_rect(index)
	var friend := _manager.state.friends[index]
	draw_rect(rect, _friend_colors[index] if index == selected_friend else SHADOW_COLOR)
	draw_rect(rect.grow(-2), PANEL_COLOR)
	var center_x := rect.get_center().x
	_draw_text_centered(_friend_names[index].to_upper(), center_x, rect.position.y + 18, _friend_colors[index])
	# El LED: rojo fijo sin señal, rojo parpadeando si viene una interferencia y verde si está bien.
	var led_color := LED_GREEN
	var lit := 0.6
	if not friend.is_online():
		led_color = LED_RED
		lit = 1.0
	elif _manager.state.interference_warning(index):
		led_color = LED_RED
		lit = 1.0 if fmod(_blink, 0.24) < 0.12 else 0.0
	_draw_led(Vector2(center_x - 4, rect.position.y + 28), led_color, lit)
	var track := Rect2(center_x - 2, rect.position.y + FADER_TOP, 4, FADER_HEIGHT)
	draw_rect(track, SHADOW_COLOR)
	for mark in 6:
		var y := track.position.y + mark * FADER_HEIGHT / 5.0
		draw_rect(Rect2(center_x - 14, y, 6, 1), DIM_COLOR)
		draw_rect(Rect2(center_x + 8, y, 6, 1), DIM_COLOR)
	var knob_y := roundf(track.end.y - _faders[index] * FADER_HEIGHT)
	draw_rect(Rect2(center_x - 15, knob_y - 6, 30, 12), SHADOW_COLOR)
	draw_rect(Rect2(center_x - 14, knob_y - 5, 28, 10), EDGE_COLOR)
	draw_rect(Rect2(center_x - 14, knob_y - 1, 28, 2), SHADOW_COLOR)
	var value_color := TEXT_COLOR if friend.is_online() else LED_RED
	_draw_text_centered("%d" % roundi(friend.signal_level), center_x, rect.end.y - 12, value_color)


func _draw_led(top_left: Vector2, color: Color, lit: float) -> void:
	draw_rect(Rect2(top_left - Vector2.ONE, Vector2(10, 10)), SHADOW_COLOR)
	draw_rect(Rect2(top_left, Vector2(8, 8)), color.darkened(0.75).lerp(color, lit))


## Una perilla de adorno, como las del mixer del escritorio.
func _draw_knob(center: Vector2) -> void:
	draw_circle(center, 24.0, SHADOW_COLOR)
	draw_circle(center, 22.0, EDGE_COLOR.darkened(0.25))
	draw_circle(center, 16.0, EDGE_COLOR)
	draw_line(center, center + Vector2(9, -12), SHADOW_COLOR, 2.0)


## Botones y barras de colores de adorno, como los del mixer del escritorio.
func _draw_decor() -> void:
	var button_colors := [Color(0.85, 0.25, 0.25), Color(0.93, 0.83, 0.3), Color(0.35, 0.75, 0.35)]
	for row in 3:
		for column in 3:
			var top_left := Vector2(26 + column * 18, 196 + row * 22)
			draw_rect(Rect2(top_left - Vector2.ONE, Vector2(14, 14)), SHADOW_COLOR)
			draw_rect(Rect2(top_left, Vector2(12, 12)), EDGE_COLOR)
			draw_rect(Rect2(top_left + Vector2(3, 3), Vector2(6, 6)), button_colors[column])
	var bar_colors := [Color(0.35, 0.75, 0.35), Color(0.93, 0.83, 0.3), Color(0.3, 0.5, 0.95), Color(0.85, 0.45, 0.2)]
	for row in bar_colors.size():
		draw_rect(Rect2(366, 200 + row * 12, 48, 6), bar_colors[row])


func _draw_text(text: String, baseline_left: Vector2, color: Color) -> void:
	draw_string(FONT, baseline_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _draw_text_centered(text: String, center_x: float, baseline: float, color: Color) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_draw_text(text, Vector2(roundf(center_x - width / 2.0), baseline), color)
