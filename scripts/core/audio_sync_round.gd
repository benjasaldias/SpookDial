extends RefCounted
## Una ronda de Audio Sync (diseño §10.6): sobre una base que marca el tiempo, el amigo aplaude un ritmo y
## después Matías lo repite, con la barra espaciadora o con clics en el mixer (decisión de Benja).
## Lógica pura: el mixer la avanza, la muestra y la hace sonar.
##
## Todo va en corcheas, la mitad de un golpe de la base. La ronda tiene tres partes seguidas:
##   1. la cuenta: un compás de 8 corcheas, solo con la base;
##   2. el amigo aplaude `beats` veces en beats × 2 corcheas, la primera siempre al comienzo;
##   3. Matías repite los aplausos en otras tantas corcheas.
## Sale bien si cada aplauso tiene un golpe de Matías a menos de `tolerance` segundos y no sobra ningún
## golpe. Termina apenas acierta el último aplauso o apenas falla.

## En qué parte va la ronda.
enum Phase { COUNT_IN, CALL, RESPONSE, DONE }
## Qué pasó con un golpe de Matías: no contaba (antes de su parte o al terminar), acertó o sobró.
enum Tap { IGNORED, HIT, MISS }

## Corcheas por compás. La cuenta dura un compás.
const STEPS_PER_BAR := 8

## Aplausos del amigo: 4 u 8, según la noche (docs/02 §6).
var beats := 4
## Segundos de una corchea.
var step_seconds := 0.3
var tolerance := 0.15
## Corcheas de la parte del amigo, que son también las de la parte de Matías.
var steps := 8
## En qué corcheas aplaude el amigo, contadas desde el comienzo de su parte, de menor a mayor.
var pattern: Array[int] = []
## Segundos desde que empezó la ronda.
var elapsed := 0.0
var succeeded := false
var failed := false

## Los aplausos del patrón que Matías ya acertó.
var _hits: Array[int] = []
## La próxima corchea que suena, contada desde el comienzo de la cuenta.
var _next_step := 0


func _init(beat_count: int, bpm: float, tap_tolerance: float, rng: RandomNumberGenerator) -> void:
	beats = beat_count
	step_seconds = 30.0 / bpm
	tolerance = tap_tolerance
	steps = beat_count * 2
	# El primer aplauso marca el comienzo; los demás caen en corcheas al azar, sin repetirse.
	var others: Array[int] = []
	for step in range(1, steps):
		others.append(step)
	for index in range(others.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := others[index]
		others[index] = others[other]
		others[other] = swap
	pattern.append(0)
	pattern.append_array(others.slice(0, beats - 1))
	pattern.sort()


func phase() -> Phase:
	if succeeded or failed:
		return Phase.DONE
	if elapsed < call_start():
		return Phase.COUNT_IN
	if elapsed < response_start() - tolerance:
		return Phase.CALL
	return Phase.RESPONSE


## Corcheas de toda la ronda: la cuenta, el amigo y Matías.
func total_steps() -> int:
	return STEPS_PER_BAR + steps * 2


## Segundos desde el comienzo de la ronda hasta la parte del amigo.
func call_start() -> float:
	return STEPS_PER_BAR * step_seconds


## Segundos desde el comienzo de la ronda hasta la parte de Matías.
func response_start() -> float:
	return (STEPS_PER_BAR + steps) * step_seconds


## La base suena en cada golpe, una corchea sí y otra no.
func is_beat(step: int) -> bool:
	return step % 2 == 0


## Y suena más fuerte al empezar cada compás.
func is_accent(step: int) -> bool:
	return step % STEPS_PER_BAR == 0


## En la corchea `step`, contada desde la cuenta, aplaude el amigo.
func is_clap(step: int) -> bool:
	var call_step := step - STEPS_PER_BAR
	return call_step >= 0 and call_step < steps and pattern.has(call_step)


## Avanza `delta` segundos y devuelve las corcheas (contadas desde la cuenta) a las que llegó en este paso,
## para que suenen. Si a Matías se le pasó un aplauso, la ronda sale mal.
func advance(delta: float) -> Array[int]:
	var reached: Array[int] = []
	if phase() == Phase.DONE:
		return reached
	elapsed += delta
	while _next_step < total_steps() and _next_step * step_seconds <= elapsed:
		reached.append(_next_step)
		_next_step += 1
	for call_step: int in pattern:
		if not _hits.has(call_step) and elapsed > _tap_time(call_step) + tolerance:
			failed = true
	return reached


## Matías golpea ahora. Antes de su parte no cuenta. En su parte, acierta si hay un aplauso sin acertar a
## menos de `tolerance` segundos; si no, el golpe sobra y la ronda sale mal.
func tap() -> Tap:
	if phase() != Phase.RESPONSE:
		return Tap.IGNORED
	for call_step: int in pattern:
		if not _hits.has(call_step) and absf(elapsed - _tap_time(call_step)) <= tolerance:
			_hits.append(call_step)
			succeeded = _hits.size() == pattern.size()
			return Tap.HIT
	failed = true
	return Tap.MISS


## Los aplausos que Matías ya acertó, contados desde el comienzo de su parte.
func hits() -> Array[int]:
	return _hits


## Cuándo tiene que golpear Matías para repetir el aplauso de la corchea `call_step`.
func _tap_time(call_step: int) -> float:
	return response_start() + call_step * step_seconds
