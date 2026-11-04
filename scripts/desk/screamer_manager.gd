extends Node
## Los screamers de la noche (Plan 7, diseño §11). El director dice cuándo toca uno y el escritorio, qué se ve;
## aquí se elige cuál (Screamer), se anuncia con su señal previa (las luces parpadean y baja el sonido
## ambiente) y se muestra con su sonido. Cada uno resta Sanity, y el jumpscare pausa la noche mientras tapa la
## pantalla. Después del susto guionado empieza su chat guionado (decisión de Benja).
## Con Sanity bajo suenan alucinaciones: golpes, pasos, susurros y rasguños, y también la estática y el
## celular, que no vienen de nada (decisión de Benja). Nada de esto empieza durante una ronda de Audio Sync.
## Hasta el arte de Benja (docs/06 §3), los screamers usan las piezas del escritorio y la figura de la ventana.
## Con "Reducir destellos" (diseño §19), la señal previa, el apagón de las luces y el rojo del jumpscare se
## oscurecen una sola vez, más suave, en lugar de parpadear.

## Empezó un screamer, después de su señal previa.
signal scare_started(kind: ScareKind.Kind)
## Sonó una alucinación.
signal hallucinated(sound: AudioStream)

const HallucinationClock := preload("res://scripts/core/hallucination_clock.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const Screamer := preload("res://scripts/core/screamer.gd")

## Volumen del sonido ambiente durante la señal previa y el screamer, en decibeles.
const DUCKED_DB := -40.0
## Segundos que tarda en bajar el sonido ambiente y, después del screamer, en volver.
const DUCK_SECONDS := 0.3
const RETURN_SECONDS := 2.0
## Segundos que duran la cortina, la figura, el celular y las luces.
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
	ScareKind.Kind.JUMPSCARE: "JumpscareSound",
}
## Segundos de cada paso de un oscurecer suave, con "Reducir destellos".
const GENTLE_STEP := 0.4
## Desde dónde suena una alucinación: fuera de la pantalla, a la izquierda o a la derecha.
const HALLUCINATION_SIDES: Array[Vector2] = [Vector2(-200, 360), Vector2(1480, 360)]

@export var curtains: Node2D
## La figura de la ventana: escondida, aparece en el screamer de la ventana (decisión de Benja).
@export var figure: CanvasItem
## El celular del escritorio.
@export var phone: Node2D
## Oscurece el cuarto cuando las luces parpadean.
@export var darkness: CanvasItem
## La pantalla del jumpscare: la silueta de la figura a ×2 sobre un destello gris, provisional hasta el arte de
## Benja.
@export var jumpscare: Control
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

@onready var _hallucination: AudioStreamPlayer2D = $Hallucination


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


## Avanza `delta` segundos con lo que se ve del escritorio (`view`). Con `busy` (una ronda de Audio Sync),
## no empieza nada: ni screamers ni alucinaciones.
func advance(delta: float, view: Screamer.View, busy: bool) -> void:
	if _requests == null or _night.ended:
		return
	var calm := not busy and not is_warning() and not _night.is_paused()
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


## Muestra el screamer `kind` ahora, con su sonido, y resta Sanity. Después del susto guionado (`scripted`)
## empieza su chat guionado.
func play(kind: ScareKind.Kind, scripted := false) -> void:
	var balance := _requests.catalog.balance
	_requests.state.scare(Screamer.sanity_cost(kind, balance))
	(get_node(SOUND_NODES[kind]) as AudioStreamPlayer).play()
	match kind:
		ScareKind.Kind.CURTAINS:
			_sway_curtains()
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
			_show_jumpscare(balance.jumpscare_seconds)
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


## La cortina se mece, colgada de su barra.
func _sway_curtains() -> void:
	var tween := create_tween()
	for skew_value: float in [0.08, -0.05, 0.03, 0.0]:
		tween.tween_property(curtains, ^"skew", skew_value, EFFECT_SECONDS / 4.0)


## La figura aparece en la ventana y se desvanece.
func _show_figure() -> void:
	figure.modulate.a = 1.0
	figure.show()
	var tween := create_tween()
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


## El jumpscare tapa la pantalla `seconds` segundos, con parpadeos rojos, y la noche se pausa mientras tanto.
func _show_jumpscare(seconds: float) -> void:
	_night.pause(seconds)
	jumpscare.show()
	var red := jumpscare.get_node("Red") as ColorRect
	var alphas := jumpscare_alphas()
	_tween_alphas(red, ^"color:a", alphas, seconds / alphas.size()).tween_callback(jumpscare.hide)


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


## El rojo del jumpscare: tres parpadeos, o uno suave.
func jumpscare_alphas() -> Array[float]:
	if reduce_flashes:
		return [0.3, 0.3, 0.0]
	return [0.5, 0.0, 0.35, 0.0, 0.25, 0.0]


## Lleva `property` de `target` por cada opacidad de `alphas`, `step` segundos cada una.
func _tween_alphas(target: Object, property: NodePath, alphas: Array[float], step: float) -> Tween:
	var tween := create_tween()
	for alpha: float in alphas:
		tween.tween_property(target, property, alpha, step)
	return tween
