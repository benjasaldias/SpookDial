extends RefCounted
## La historia de una noche en curso (decisiones de Benja en S21b, docs/21; Plan 9.7, docs/31): recorre sus momentos en
## orden y dice qué escribir y cuándo.
## - **Cuándo:** cada momento llega con el director: al empezar la noche, unos segundos antes de una ola, al empezar una
##   calma y al cerrar. En Extremo, la "ola 2" de la historia es la última ola común. Un momento cuya ola ya empezó, o
##   que ya no puede llegar porque llegó uno posterior, se salta; uno que estaba contando cuando empezó su ola, se corta.
##   En los dos casos se aplican sus pasos de separarse y reunirse, para que la historia siga teniendo sentido (si la
##   final llega encima de la ola 2, se reúnen solos: decisión de Benja, S21l).
## - **Dónde:** con los 3 juntos, las líneas van a la llamada grupal, y esperan a que se vea (sin nada que jugar);
##   separados, al chat de quien habla. Cada línea espera lo que tarda en escribirse, más un momento para leerla.
## - **Las decisiones** esperan a que su amigo esté libre y con señal; después, la respuesta de Matías (o que se acabe su
##   tiempo). La opción deja su marca, que eligen los pasos que siguen, y el amigo contesta.
## - **Mientras cuenta algo, la próxima ola espera** (holds), a lo más BalanceData.story_hold_limit segundos.
## Lógica pura: RequestManager la avanza con el director y cumple sus órdenes; el modelo de la prueba de equilibrio
## (test/balance_model.gd), también.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")

## Lo que hay que hacer: una línea en el chat de un amigo, una línea en la llamada o una decisión.
enum Command { LINE, CALL_LINE, DECISION }

## Las líneas se escriben a la velocidad del chat (ChatMessageView), y después queda un momento para leerlas.
const CHARS_PER_SECOND := 60.0
const LINE_PAUSE := 1.2


## Una orden de la historia.
class Item:
	var command: Command
	## Quién habla o quién decide (su índice en los amigos del catálogo).
	var friend := -1
	## La clave del texto: la línea o la pregunta de la decisión.
	var key := ""
	var decision: StoryDecisionData

	func _init(item_command: Command, item_friend: int, item_key: String, item_decision: StoryDecisionData = null) -> void:
		command = item_command
		friend = item_friend
		key = item_key
		decision = item_decision


var data: StoryData
## Los 3 amigos están juntos: las líneas van a la llamada grupal.
var together := true
## Las marcas que dejaron las decisiones.
var flags: Array[StringName] = []
## El momento en curso (su índice en data.beats), si ya empezó y su próximo paso.
var beat_index := 0
var started := false
var step_index := 0
## Una decisión espera la respuesta de Matías, y quién la pregunta.
var deciding := false
var decider := -1
## Los momentos que terminaron enteros, los que se saltaron y los que se cortaron (para las pruebas y el modelo).
var finished_beats: Array[int] = []
var skipped_beats: Array[int] = []
var cut_beats: Array[int] = []

var _friends: Array[FriendData] = []
var _translate: Callable
## Segundos hasta el próximo paso: lo que tarda en escribirse la última línea.
var _wait := 0.0


## `friends`: los amigos del catálogo, en orden. `translate` recibe una clave y devuelve su texto.
func _init(story: StoryData, friends: Array[FriendData], translate: Callable) -> void:
	data = story
	_friends = friends
	_translate = translate
	together = story.starts_together


func is_done() -> bool:
	return beat_index >= data.beats.size()


## La historia está contando algo (un momento empezado): la próxima ola espera.
func holds() -> bool:
	return started and not is_done()


## Avanza `delta` segundos a la hora `now`. `busy`: hay consultas, accidentes o decisiones abiertas; `call_open`: la
## llamada se puede ver (además, sin videos por descargar); `is_free(amigo)`: el amigo puede decidir (libre, despierto y
## con señal). Devuelve lo que hay que hacer ahora, en orden.
func advance(delta: float, now: float, director: PacingDirector, busy: bool, call_open: bool,
		is_free: Callable) -> Array[Item]:
	_wait = maxf(_wait - delta, 0.0)
	var items: Array[Item] = []
	while not is_done():
		var beat := data.beats[beat_index]
		if not started:
			if _closed(beat, director):
				_end_beat(skipped_beats)
				continue
			if _reached(beat, now, director, busy):
				started = true
				step_index = 0
			elif _passed(now, director, busy):
				_end_beat(skipped_beats)
				continue
			else:
				break
		if deciding:
			break
		if _closed(beat, director):
			_end_beat(cut_beats)
			continue
		if _wait > 0.0:
			break
		if step_index >= beat.steps.size():
			finished_beats.append(beat_index)
			_next_beat()
			continue
		var step := beat.steps[step_index]
		if step == null or not step.applies(flags):
			step_index += 1
		elif step.kind == StoryStepData.Kind.SEPARATE:
			together = false
			step_index += 1
		elif step.kind == StoryStepData.Kind.JOIN:
			together = true
			step_index += 1
		elif step.kind == StoryStepData.Kind.LINE:
			if together and not call_open:
				break
			items.append(_line(_friends.find(step.speaker), step.text_key))
			step_index += 1
		elif step.kind == StoryStepData.Kind.DECISION:
			var friend := _friends.find(step.decision.friend)
			if not is_free.call(friend):
				break
			deciding = true
			decider = friend
			items.append(Item.new(Command.DECISION, friend, step.decision.message_key, step.decision))
			step_index += 1
	return items


## Terminó la decisión con `option` (o con la de sin respuesta): deja su marca y devuelve lo que contesta el amigo, que se
## escribe de a una línea; lo que sigue espera a que termine.
func decided(option: StoryOptionData) -> Array[Item]:
	var friend := decider
	deciding = false
	decider = -1
	var items: Array[Item] = []
	if option == null:
		return items
	if not option.sets_flag.is_empty() and not flags.has(option.sets_flag):
		flags.append(option.sets_flag)
	var total := 0.0
	for key: String in option.reply_keys:
		items.append(Item.new(Command.CALL_LINE if together else Command.LINE, friend, key))
		total += _seconds(key)
	_wait = total
	return items


## Una línea de `friend`: en la llamada si están juntos. Lo siguiente espera lo que tarda en escribirse.
func _line(friend: int, key: String) -> Item:
	_wait = _seconds(key)
	return Item.new(Command.CALL_LINE if together else Command.LINE, friend, key)


func _seconds(key: String) -> float:
	return String(_translate.call(key)).length() / CHARS_PER_SECOND + LINE_PAUSE


## El momento termina antes de tiempo: se aplican sus pasos de separarse y reunirse que faltan, sin líneas ni decisiones,
## y queda anotado en `record`.
func _end_beat(record: Array[int]) -> void:
	var beat := data.beats[beat_index]
	for index in range(step_index if started else 0, beat.steps.size()):
		var step := beat.steps[index]
		if step == null or not step.applies(flags):
			continue
		if step.kind == StoryStepData.Kind.SEPARATE:
			together = false
		elif step.kind == StoryStepData.Kind.JOIN:
			together = true
	record.append(beat_index)
	_next_beat()


func _next_beat() -> void:
	beat_index += 1
	started = false
	step_index = 0
	_wait = 0.0


## Llegó la hora del momento.
func _reached(beat: StoryBeatData, now: float, director: PacingDirector, busy: bool) -> bool:
	var lead_reached := now >= director.next_at - beat.lead_seconds
	match beat.moment:
		StoryBeatData.Moment.NIGHT_START:
			return true
		StoryBeatData.Moment.BEFORE_FIRST_WAVE:
			return director.phase == PacingDirector.Phase.SILENCE and lead_reached
		StoryBeatData.Moment.AFTER_FIRST_WAVE:
			return director.calms_started >= 1
		StoryBeatData.Moment.BEFORE_LAST_WAVE:
			return _in_calm_before(director, director.last_regular_index()) and lead_reached
		StoryBeatData.Moment.AFTER_LAST_WAVE:
			return _in_calm_before(director, director.finale_index())
		StoryBeatData.Moment.BEFORE_FINALE:
			return _in_calm_before(director, director.finale_index()) and lead_reached
		StoryBeatData.Moment.AFTER_FINALE:
			return director.finale_started() and director.phase == PacingDirector.Phase.DONE and not busy
	return false


## Ya empezó la ola de la que hablaba el momento (o la que lo termina): no se dice.
func _closed(beat: StoryBeatData, director: PacingDirector) -> bool:
	match beat.moment:
		StoryBeatData.Moment.NIGHT_START, StoryBeatData.Moment.BEFORE_FIRST_WAVE:
			return director.waves_started >= 1
		StoryBeatData.Moment.AFTER_FIRST_WAVE:
			return director.waves_started >= 2
		StoryBeatData.Moment.BEFORE_LAST_WAVE:
			return director.finale_started() or director.waves_started > director.last_regular_index()
		StoryBeatData.Moment.AFTER_LAST_WAVE, StoryBeatData.Moment.BEFORE_FINALE:
			return director.finale_started()
	return false


## Ya llegó un momento posterior: este no va a llegar (el director se saltó su ola).
func _passed(now: float, director: PacingDirector, busy: bool) -> bool:
	for index in range(beat_index + 1, data.beats.size()):
		if _reached(data.beats[index], now, director, busy):
			return true
	return false


## La noche está en la calma antes de la ola `index`.
static func _in_calm_before(director: PacingDirector, index: int) -> bool:
	return index >= 0 and director.phase == PacingDirector.Phase.CALM and director.wave_index == index
