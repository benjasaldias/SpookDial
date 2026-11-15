extends RefCounted
## La historia de una noche en curso (decisiones de Benja en S21b, docs/21; Plan 9.7, docs/31): recorre sus momentos en
## orden y dice qué escribir y cuándo.
## - **Cuándo:** cada momento llega con el director: al empezar la noche, unos segundos antes de una ola, al empezar una
##   calma y al cerrar. En Extremo, la "ola 2" de la historia es la última ola común. Un momento cuya ola ya empezó, o
##   que ya no puede llegar porque llegó uno posterior, se salta; uno que estaba contando cuando empezó su ola, se corta.
##   En los dos casos se aplican sus pasos de separarse y reunirse, para que la historia siga teniendo sentido (si la
##   final llegara encima de la ola 2, se reunirían solos: decisión de Benja, S21l; desde el Plan 9.9 la final espera a la ola 2 y ya no llega encima).
## - **Dónde:** con los 3 juntos, las líneas van a la llamada grupal, y esperan a que se vea (sin nada que jugar);
##   separados, al chat de quien habla. Cada línea espera lo que tarda en escribirse y en leerse, por sus palabras, más
##   una pausa (line_seconds; pedidos de Benja en los planes 9.8 y 9.9).
## - **El horario:** story_needs() dice cuánto dura cada momento, y el director lo deja en el horario (Plan 9.8). Un
##   momento "antes de" una ola empieza lo que dura antes de ella (más 2 s), y nunca menos que su lead_seconds.
## - **Las decisiones** esperan a que su amigo esté libre y con señal; después, la respuesta de Matías (o que se acabe su
##   tiempo). La opción deja su marca, que eligen los pasos que siguen, y el amigo contesta.
## - **Mientras cuenta algo, la próxima ola espera** (holds), a lo más BalanceData.story_hold_limit segundos.
## Lógica pura: RequestManager la avanza con el director y cumple sus órdenes; el modelo de la prueba de equilibrio
## (test/balance_model.gd), también.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")

## Lo que hay que hacer: una línea en el chat de un amigo, una línea en la llamada o una decisión.
enum Command { LINE, CALL_LINE, DECISION }

## Una línea queda lo que tarda en escribirse, lo que se tarda en leerla y una pausa (pedido de Benja, Plan 9.9: el inicio
## se sentía rápido): se escribe a TYPING_CHARS_PER_SECOND letras por segundo (lo mismo que el chat,
## ChatMessageView.CHARS_PER_SECOND), se lee a READING_WORDS_PER_SECOND palabras por segundo y después espera LINE_PAUSE.
## Nunca menos que MIN_LINE_SECONDS.
const TYPING_CHARS_PER_SECOND := 60.0
const READING_WORDS_PER_SECOND := 3.5
const LINE_PAUSE := 1.0
const MIN_LINE_SECONDS := 2.0
## Un momento "antes de" una ola termina, al menos, tantos segundos antes de ella.
const LEAD_MARGIN := 2.0


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
## Segundos hasta el próximo paso: lo que tarda en leerse la última línea.
var _wait := 0.0
## Cuántos segundos antes de su ola empieza cada momento "antes de" (StoryBeatData → segundos).
var _leads := {}


## `friends`: los amigos del catálogo, en orden. `translate` recibe una clave y devuelve su texto. `decision_seconds`: lo
## que dura una decisión, para calcular cuándo empieza un momento "antes de" que trae una.
func _init(story: StoryData, friends: Array[FriendData], translate: Callable, decision_seconds := 15.0) -> void:
	data = story
	_friends = friends
	_translate = translate
	together = story.starts_together
	for beat: StoryBeatData in story.beats:
		if beat != null and beat.is_before_wave():
			_leads[beat] = maxf(beat.lead_seconds, beat_seconds(beat, translate, decision_seconds) + LEAD_MARGIN)


## Lo que queda una línea de `text`: lo que tarda en escribirse, en leerse (por sus palabras) y la pausa.
static func line_seconds(text: String) -> float:
	var typing := text.length() / TYPING_CHARS_PER_SECOND
	var reading := text.split(" ", false).size() / READING_WORDS_PER_SECOND
	return maxf(typing + reading + LINE_PAUSE, MIN_LINE_SECONDS)


## Lo que dura `beat`: sus líneas y, por cada decisión, la pregunta, `decision_seconds` y la respuesta más larga. De los
## pasos con una marca y los que van sin ella (que se excluyen), cuenta lo más largo.
static func beat_seconds(beat: StoryBeatData, translate: Callable, decision_seconds: float) -> float:
	var total := 0.0
	## Por marca: [lo que dura con ella, lo que dura sin ella].
	var by_flag := {}
	for step: StoryStepData in beat.steps:
		if step == null:
			continue
		var seconds := _step_seconds(step, translate, decision_seconds)
		if not step.requires_flag.is_empty():
			by_flag[step.requires_flag] = by_flag.get(step.requires_flag, [0.0, 0.0])
			by_flag[step.requires_flag][0] += seconds
		elif not step.unless_flag.is_empty():
			by_flag[step.unless_flag] = by_flag.get(step.unless_flag, [0.0, 0.0])
			by_flag[step.unless_flag][1] += seconds
		else:
			total += seconds
	for pair: Array in by_flag.values():
		total += maxf(pair[0], pair[1])
	return total


## Lo que dura cada momento de `story` (StoryBeatData.Moment → segundos), para el horario del director. A un momento
## "antes de" se le suma LEAD_MARGIN, lo que lo separa de su ola.
static func story_needs(story: StoryData, translate: Callable, decision_seconds: float) -> Dictionary:
	var needs := {}
	for beat: StoryBeatData in story.beats:
		if beat == null:
			continue
		var seconds := beat_seconds(beat, translate, decision_seconds)
		if beat.is_before_wave():
			seconds += LEAD_MARGIN
		needs[beat.moment] = float(needs.get(beat.moment, 0.0)) + seconds
	return needs


static func _step_seconds(step: StoryStepData, translate: Callable, decision_seconds: float) -> float:
	if step.kind == StoryStepData.Kind.LINE:
		return line_seconds(String(translate.call(step.text_key)))
	if step.kind != StoryStepData.Kind.DECISION or step.decision == null:
		return 0.0
	var longest := 0.0
	var options: Array[StoryOptionData] = step.decision.options.duplicate()
	options.append(step.decision.no_answer)
	for option: StoryOptionData in options:
		if option == null:
			continue
		var replies := 0.0
		for key: String in option.reply_keys:
			replies += line_seconds(String(translate.call(key)))
		longest = maxf(longest, replies)
	return line_seconds(String(translate.call(step.decision.message_key))) + decision_seconds + longest


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
	return line_seconds(String(_translate.call(key)))


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
	var lead_reached := now >= director.next_at - float(_leads.get(beat, beat.lead_seconds))
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
