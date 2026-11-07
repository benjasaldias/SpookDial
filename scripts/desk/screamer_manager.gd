extends Node
## Los screamers de la noche (Plan 7, diseño §11). El director dice cuándo toca uno y el escritorio, qué se ve;
## aquí se elige cuál (Screamer), se anuncia con su señal previa (las luces parpadean y baja el sonido
## ambiente) y se muestra con su sonido. Cada uno resta Sanity. El antiguo jumpscare es ahora la criatura que se
## asoma por la ventana, con respiración pesada y golpes (decisión de Benja, 4 de noviembre): se arma cuando el
## chat o el mixer tapan la ventana, y está ahí al cerrarlos. Se queda un tiempo fijo: si las cortinas estaban
## cerradas las abre, y cerrarlas no la espanta, pero baja menos Sanity y no se oye, así que hay que abrirlas para
## revisar si sigue ahí (decisión de Benja, 7 de noviembre). Después del susto guionado empieza su chat guionado
## (decisión de Benja).
## Con Sanity bajo suenan alucinaciones: golpes, pasos, susurros y rasguños, y también la estática y el
## celular, que no vienen de nada (decisión de Benja). Nada de esto empieza durante una ronda de Audio Sync.
## Hasta el arte de Benja (docs/06 §3), los screamers usan las piezas del escritorio y la figura de la ventana.
## Con "Reducir destellos" (diseño §19), la señal previa y el apagón de las luces se oscurecen una sola vez,
## más suave, en lugar de parpadear.

## Empezó un screamer, después de su señal previa.
signal scare_started(kind: ScareKind.Kind)
## Sonó una alucinación.
signal hallucinated(sound: AudioStream)

const HallucinationClock := preload("res://scripts/core/hallucination_clock.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const Screamer := preload("res://scripts/core/screamer.gd")

## Las animaciones de las cortinas (tags del arte de Benja).
const CURTAINS_OPEN := &"Open"
const CURTAINS_CLOSED := &"Closed"
## Cuánto se oscurece el cuarto con las cortinas cerradas.
const CLOSED_SHADE := 0.35
## Volumen del sonido ambiente durante la señal previa y el screamer, en decibeles.
const DUCKED_DB := -40.0
## Segundos que tarda en bajar el sonido ambiente y, después del screamer, en volver.
const DUCK_SECONDS := 0.3
const RETURN_SECONDS := 2.0
## Segundos que duran la figura, el celular y las luces.
const EFFECT_SECONDS := 1.5
## Opacidad de la oscuridad con las luces apagadas.
const DARK := 0.85
## El sonido de cada screamer: sus nodos.
const SOUND_NODES := {
	ScareKind.Kind.CURTAINS: "CurtainsSound",
	ScareKind.Kind.WINDOW: "WindowSound",
	ScareKind.Kind.PHONE: "PhoneSound",
	ScareKind.Kind.LIGHTS: "LightsSound",
	ScareKind.Kind.NOTEBOOK_SLAM: "SlamSound",
	ScareKind.Kind.INK: "InkSound",
	ScareKind.Kind.JUMPSCARE: "CreatureBreathing",
}
## Segundos de cada paso de un oscurecer suave, con "Reducir destellos".
const GENTLE_STEP := 0.4
## Desde dónde suena una alucinación: fuera de la pantalla, a la izquierda o a la derecha.
const HALLUCINATION_SIDES: Array[Vector2] = [Vector2(-200, 360), Vector2(1480, 360)]
## Volumen de la respiración de la criatura mientras espera detrás de un panel, en decibeles.
const HIDDEN_BREATHING_DB := -9.0
## Segundos que tarda la criatura en desvanecerse al retirarse.
const LEAVE_SECONDS := 0.4

## Dónde está la criatura de la ventana: lejos, detrás de un panel que tapa la ventana, o a la vista.
enum Creature { AWAY, HIDDEN, SEEN }

@export var curtains: AnimatedSprite2D
## La figura de la ventana: escondida. Aparece en el screamer de la ventana y es la criatura que se asoma
## (decisión de Benja).
@export var figure: CanvasItem
## El celular del escritorio.
@export var phone: Node2D
## Oscurece el cuarto cuando las luces parpadean.
@export var darkness: CanvasItem
## Oscurece el cuarto mientras las cortinas están cerradas.
@export var curtain_shade: CanvasItem
@export var notebook: Control
@export var ambient: AudioStreamPlayer
## Los sonidos que pueden ser una alucinación.
@export var hallucination_sounds: Array[AudioStream] = []
## La opción "Reducir destellos" (diseño §19).
var reduce_flashes := false

var _requests: RequestManager
var _night: NightManager
var _clock: HallucinationClock
## El screamer anunciado, que empieza al terminar su señal previa, o Screamer.NONE.
var _pending := Screamer.NONE
var _pending_scripted := false
var _warning_left := 0.0
var _ambient_db := 0.0
var _phone_rest := Vector2.ZERO
var _creature := Creature.AWAY
## Segundos que la criatura se queda todavía afuera.
var _creature_left := 0.0
## La ventana está a la vista (ni un panel ni el celular la tapan), según el último avance.
var _window_visible := true
## El desvanecimiento de la figura de la ventana, que comparten el screamer de la ventana y la criatura.
var _figure_tween: Tween

@onready var _hallucination: AudioStreamPlayer2D = $Hallucination
@onready var _breathing: AudioStreamPlayer = $CreatureBreathing
@onready var _knocks: AudioStreamPlayer = $CreatureKnocks


func setup(requests: RequestManager, night: NightManager) -> void:
	_requests = requests
	_night = night
	_clock = HallucinationClock.new(requests.catalog.balance, requests.rng)
	_ambient_db = ambient.volume_db
	_phone_rest = phone.position
	# El sonido ambiente se repite sin fin.
	ambient.finished.connect(ambient.play)


## Hay un screamer anunciado, esperando que termine su señal previa.
func is_warning() -> bool:
	return _pending != Screamer.NONE


## La criatura de la ventana está cerca: detrás de un panel o a la vista.
func is_creature_near() -> bool:
	return _creature != Creature.AWAY


## Avanza `delta` segundos con lo que se ve del escritorio (`view`). Con `busy` (una ronda de Audio Sync o un audio
## de un amigo), no empieza nada: ni screamers ni alucinaciones.
func advance(delta: float, view: Screamer.View, busy: bool) -> void:
	if _requests == null or _night.ended:
		return
	_window_visible = view.desk_visible
	_advance_creature(delta)
	var calm := not busy and not is_warning() and not _night.is_paused() and not is_creature_near()
	if _clock.advance(delta, _requests.state.sanity, calm):
		_hallucinate()
	if is_warning():
		_warning_left -= delta
		if _warning_left <= 0.0:
			var kind := _pending
			_pending = Screamer.NONE
			play(kind, _pending_scripted)
		return
	if not calm:
		return
	var now := _requests.state.elapsed
	var director := _requests.director
	if director.scripted_scare_due(now, _requests.pending_count()):
		director.scripted_scare_started(now)
		_announce(_requests.night().scripted_scare, true)
		return
	if not director.scare_due(now):
		return
	var time_lefts := []
	for request: RefCounted in _requests.requests:
		if request != null:
			time_lefts.append(request.time_left)
	var kind := Screamer.pick(view, director.next_is_jumpscare(), time_lefts, _requests.catalog.balance, _requests.rng)
	if kind == Screamer.NONE:
		return
	director.scare_started(now)
	_announce(kind, false)


## Clic en las cortinas: se cierran o se abren, con su sonido (decisión de Benja, 7 de noviembre).
func toggle_curtains() -> void:
	_set_curtains(not _requests.state.curtains_closed)
	($CurtainsSound as AudioStreamPlayer).play()


## Muestra el screamer `kind` ahora, con su sonido, y resta Sanity. Después del susto guionado (`scripted`)
## empieza su chat guionado.
func play(kind: ScareKind.Kind, scripted := false) -> void:
	var balance := _requests.catalog.balance
	_requests.state.scare(Screamer.sanity_cost(kind, balance))
	(get_node(SOUND_NODES[kind]) as AudioStreamPlayer).play()
	match kind:
		ScareKind.Kind.CURTAINS:
			_set_curtains(not _requests.state.curtains_closed)
		ScareKind.Kind.WINDOW:
			_show_figure()
		ScareKind.Kind.PHONE:
			_shake_phone()
		ScareKind.Kind.LIGHTS:
			_flicker_lights()
		ScareKind.Kind.NOTEBOOK_SLAM:
			notebook.slam()
		ScareKind.Kind.INK:
			notebook.splash_ink(balance.ink_seconds)
		ScareKind.Kind.JUMPSCARE:
			_creature_arrives()
	var back := create_tween()
	back.tween_interval(EFFECT_SECONDS)
	back.tween_property(ambient, ^"volume_db", _ambient_db, RETURN_SECONDS)
	if scripted:
		_requests.start_chat_script(_requests.night().scripted_chat)
	scare_started.emit(kind)


## Anuncia el screamer `kind` con su señal previa: las luces parpadean y baja el sonido ambiente (diseño §11).
func _announce(kind: ScareKind.Kind, scripted: bool) -> void:
	_pending = kind
	_pending_scripted = scripted
	_warning_left = _requests.catalog.balance.scare_warning
	_tween_alphas(darkness, ^"modulate:a", warning_alphas(), GENTLE_STEP if reduce_flashes else 0.08)
	create_tween().tween_property(ambient, ^"volume_db", DUCKED_DB, DUCK_SECONDS)


## Las cortinas quedan cerradas o abiertas. Cerradas, tapan la ventana y el cuarto se oscurece.
func _set_curtains(closed: bool) -> void:
	_requests.state.curtains_closed = closed
	curtains.animation = CURTAINS_CLOSED if closed else CURTAINS_OPEN
	curtain_shade.modulate.a = CLOSED_SHADE if closed else 0.0


## La figura aparece en la ventana y se desvanece.
func _show_figure() -> void:
	figure.modulate.a = 1.0
	figure.show()
	var tween := _new_figure_tween()
	tween.tween_interval(EFFECT_SECONDS * 0.6)
	tween.tween_property(figure, ^"modulate:a", 0.0, EFFECT_SECONDS * 0.4)
	tween.tween_callback(figure.hide)


## El celular del escritorio vibra: se mueve 2 píxeles a cada lado.
func _shake_phone() -> void:
	var tween := create_tween()
	for index in 12:
		var side := 2.0 if index % 2 == 0 else -2.0
		tween.tween_property(phone, ^"position", _phone_rest + Vector2(side, 0.0), EFFECT_SECONDS / 12.0)
	tween.tween_property(phone, ^"position", _phone_rest, 0.05)


## Las luces se apagan y se prenden varias veces.
func _flicker_lights() -> void:
	var alphas := lights_alphas()
	_tween_alphas(darkness, ^"modulate:a", alphas, EFFECT_SECONDS / alphas.size())


## La criatura llega a la ventana, con su respiración y sus golpes en el vidrio, y abre las cortinas si estaban
## cerradas. Si la ventana está a la vista, aparece enseguida; si un panel la tapa, espera detrás, y al cerrarlo ya
## está ahí, sin animación de entrada.
func _creature_arrives() -> void:
	var state := _requests.state
	state.creature_outside = true
	_creature_left = _requests.catalog.balance.creature_seconds
	if state.curtains_closed:
		_set_curtains(false)
		($CurtainsSound as AudioStreamPlayer).play()
	_knocks.play()
	if _window_visible:
		_show_creature()
	else:
		_creature = Creature.HIDDEN
	_refresh_creature_sound()


## La criatura se ve en la ventana. Las cortinas cerradas la tapan, porque se dibujan encima.
func _show_creature() -> void:
	_creature = Creature.SEEN
	if _figure_tween != null:
		_figure_tween.kill()
	figure.modulate.a = 1.0
	figure.show()


## La criatura detrás de un panel se ve apenas la ventana queda a la vista, y se va a los creature_seconds de
## llegar, con las cortinas abiertas o cerradas.
func _advance_creature(delta: float) -> void:
	if _creature == Creature.AWAY:
		return
	_creature_left -= delta
	if _creature_left <= 0.0:
		_creature_leaves()
		return
	if _creature == Creature.HIDDEN and _window_visible:
		_show_creature()
	_refresh_creature_sound()


## Con las cortinas abiertas se oye su respiración, más fuerte si se ve, y detrás de un panel se repiten sus golpes,
## que avisan que hay que ir a la ventana. Con las cortinas cerradas no se oye nada: hay que abrirlas para saber si
## sigue ahí.
func _refresh_creature_sound() -> void:
	if _requests.state.curtains_closed:
		_breathing.stop()
		_knocks.stop()
		return
	_breathing.volume_db = 0.0 if _creature == Creature.SEEN else HIDDEN_BREATHING_DB
	if not _breathing.playing:
		_breathing.play()
	if _creature == Creature.HIDDEN and not _knocks.playing:
		_knocks.play()


## La criatura se desvanece y se calla.
func _creature_leaves() -> void:
	_creature = Creature.AWAY
	_requests.state.creature_outside = false
	_breathing.stop()
	_knocks.stop()
	var tween := _new_figure_tween()
	tween.tween_property(figure, ^"modulate:a", 0.0, LEAVE_SECONDS)
	tween.tween_callback(figure.hide)


## Un tween nuevo para la figura de la ventana, que corta el anterior.
func _new_figure_tween() -> Tween:
	if _figure_tween != null:
		_figure_tween.kill()
	_figure_tween = create_tween()
	return _figure_tween


## Suena una alucinación al azar, a un lado de la pantalla, más fuerte mientras más baja Sanity.
func _hallucinate() -> void:
	if hallucination_sounds.is_empty():
		return
	var rng := _requests.rng
	var sound := hallucination_sounds[rng.randi_range(0, hallucination_sounds.size() - 1)]
	_hallucination.stream = sound
	_hallucination.position = HALLUCINATION_SIDES[rng.randi_range(0, HALLUCINATION_SIDES.size() - 1)]
	_hallucination.volume_db = _clock.volume_db(_requests.state.sanity)
	_hallucination.play()
	hallucinated.emit(sound)


## La oscuridad durante la señal previa: dos parpadeos, o un oscurecer suave.
func warning_alphas() -> Array[float]:
	if reduce_flashes:
		return [0.35, 0.0]
	return [0.6, 0.0, 0.75, 0.0]


## La oscuridad del apagón de las luces: se apagan y se prenden varias veces, o se apagan una sola vez.
func lights_alphas() -> Array[float]:
	if reduce_flashes:
		return [DARK, DARK, 0.0]
	return [DARK, 0.2, DARK, 0.0, DARK, DARK, 0.3, 0.0]


## Lleva `property` de `target` por cada opacidad de `alphas`, `step` segundos cada una.
func _tween_alphas(target: Object, property: NodePath, alphas: Array[float], step: float) -> Tween:
	var tween := create_tween()
	for alpha: float in alphas:
		tween.tween_property(target, property, alpha, step)
	return tween
