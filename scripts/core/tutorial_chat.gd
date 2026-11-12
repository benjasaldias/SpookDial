extends RefCounted
## La conversación de León en la noche 0 (pedido de Benja, 11 de noviembre; rehecha en el Plan 9.5 tras el primer
## testeo, docs/26 §4). León enseña en su chat, con chistes y sin entidades reales, describiendo a Gonzalo:
## 1. hay que preguntarle qué ve, y cada pregunta cuesta 5 s;
## 2. marcar lo amarillo (el polerón es un señuelo);
## 3. lo azul no se clickea, pero decide la fila de la tabla;
## 4. preguntar qué oye y escuchar el audio: las tripas de Gonzalo;
## 5. preguntar por el ambiente, marcar la otra y abrir la página con el nombre;
## 6. elegir la mejor decisión y después la peor, que manda un video para descargar.
## Después Gonzalo escribe en su chat y muestra qué pasa si nadie contesta: 15 s reales y decide solo, sin efecto
## (decisión de Benja, D6). De vuelta con León, su señal baja y un mensaje llega tapado por la estática; después se le
## corta, hay que sincronizarlo y se despide.
## Cada paso dice qué parpadea (Focus) y qué se desbloquea del escritorio (Unlock): en la noche 0 solo funciona lo que
## León va enseñando (decisión de Benja, S21j).
## Lógica pura: RequestManager le cuenta lo que hace el jugador y cumple, en orden, lo que devuelve cada método.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

enum Step { ASK_SIGHT, MARK, ASK_SOUND, LISTEN, ASK_AMBIENT, MARK_SECOND, OPEN_PAGE, BEST, WORST, DOWNLOAD, DEMO_CALL,
		DEMO, DEMO_DONE, SIGNAL, DONE }
## Lo que parpadea y es lo único que se puede usar en el chat (y, en el escritorio, la entrada que hay que abrir).
enum Focus { NONE, ASK_SIGHT, ASK_SOUND, ASK_ENVIRONMENT, CLUES, AUDIO, ENTITY_NAME, ANSWERS, DOWNLOAD, DEMO_ENTRY,
		GUIDE_ENTRY, SYNC }
## Lo que se desbloquea del escritorio: el cuaderno, la entrada (y la pestaña) del amigo de la demostración y el mixer.
## La entrada de León está desbloqueada desde el principio; el celular, las cortinas y el tercer amigo, nunca.
enum Unlock { NOTEBOOK, DEMO_FRIEND, MIXER }
## Lo que hace el juego, en orden:
## - LINE: León escribe la línea `value` (clave de ui.csv); DEMO_LINE: la escribe el amigo de la demostración;
## - FOCUS y UNLOCK: cambia lo que parpadea o se desbloquea algo;
## - SEND_VIDEO: León manda un video; START_DEMO: llega la solicitud de la demostración; DEMO_HURT: el aviso de daño
##   del amigo de la demostración, sin efecto;
## - SET_SIGNAL: la señal de León pasa a `value`; STATIC_LINE: León escribe `value` con estática fija; CUT_SIGNAL: se
##   queda sin señal;
## - OPEN_GUIDE_CHAT: se abre el chat de León; PAUSE: espera `value` segundos; FINISH: terminó.
enum Command { LINE, DEMO_LINE, FOCUS, UNLOCK, SEND_VIDEO, START_DEMO, DEMO_HURT, SET_SIGNAL, STATIC_LINE, CUT_SIGNAL,
		OPEN_GUIDE_CHAT, PAUSE, FINISH }

## Las líneas de León (ui.csv), en el orden en que pueden aparecer.
const HELLO_KEY := "TUTORIAL_LEON_HELLO"
const GUESS_KEY := "TUTORIAL_LEON_GUESS"
const COST_KEY := "TUTORIAL_LEON_COST"
const MARK_KEY := "TUTORIAL_LEON_MARK"
const DECOY_KEY := "TUTORIAL_LEON_DECOY"
const BLUE_KEY := "TUTORIAL_LEON_BLUE"
const ASK_SOUND_KEY := "TUTORIAL_LEON_ASK_SOUND"
const LISTEN_KEY := "TUTORIAL_LEON_LISTEN"
const HEARD_KEY := "TUTORIAL_LEON_HEARD"
const AMBIENT_KEY := "TUTORIAL_LEON_AMBIENT"
const NAME_KEY := "TUTORIAL_LEON_NAME"
const DECIDE_KEY := "TUTORIAL_LEON_DECIDE"
const BEST_KEY := "TUTORIAL_LEON_BEST"
const RETRY_KEY := "TUTORIAL_LEON_RETRY"
const BEST_OK_KEY := "TUTORIAL_LEON_BEST_OK"
const WORST_KEY := "TUTORIAL_LEON_WORST"
const WORST_RETRY_KEY := "TUTORIAL_LEON_WORST_RETRY"
const WORST_OK_KEY := "TUTORIAL_LEON_WORST_OK"
const DOWNLOAD_KEY := "TUTORIAL_LEON_DOWNLOAD"
const VIDEO_OK_KEY := "TUTORIAL_LEON_VIDEO_OK"
const GONZALO_KEY := "TUTORIAL_LEON_GONZALO"
const NO_ANSWER_KEY := "TUTORIAL_LEON_NO_ANSWER"
const STATIC_KEY := "TUTORIAL_LEON_STATIC"
const STATIC_EXPLAIN_KEY := "TUTORIAL_LEON_STATIC_EXPLAIN"
const SIGNAL_WARN_KEY := "TUTORIAL_LEON_SIGNAL_WARN"
const SIGNAL_CUT_KEY := "TUTORIAL_LEON_SIGNAL_CUT"
const BACK_KEY := "TUTORIAL_LEON_BACK"
const READY_KEY := "TUTORIAL_LEON_READY"
## Lo que escribe Gonzalo en la demostración (ui.csv): pide ayuda, y al llegar a 0 cuenta qué hizo solo.
const GONZALO_HELP_KEY := "TUTORIAL_GONZALO_HELP"
const GONZALO_ALONE_KEY := "TUTORIAL_GONZALO_ALONE"
const GONZALO_HURT_KEY := "TUTORIAL_GONZALO_HURT"
## Lo que dice el título de las respuestas en su chat, que no se pueden usar (ui.csv).
const GONZALO_WATCH_KEY := "TUTORIAL_GONZALO_WATCH"
const ALL_KEYS: Array[String] = [HELLO_KEY, GUESS_KEY, COST_KEY, MARK_KEY, DECOY_KEY, BLUE_KEY, ASK_SOUND_KEY,
		LISTEN_KEY, HEARD_KEY, AMBIENT_KEY, NAME_KEY, DECIDE_KEY, BEST_KEY, RETRY_KEY, BEST_OK_KEY, WORST_KEY,
		WORST_RETRY_KEY, WORST_OK_KEY, DOWNLOAD_KEY, VIDEO_OK_KEY, GONZALO_KEY, NO_ANSWER_KEY, STATIC_KEY,
		STATIC_EXPLAIN_KEY, SIGNAL_WARN_KEY, SIGNAL_CUT_KEY, BACK_KEY, READY_KEY, GONZALO_HELP_KEY, GONZALO_ALONE_KEY,
		GONZALO_HURT_KEY, GONZALO_WATCH_KEY]

## La señal de León mientras enseña la estática: con 30 se ven las barritas en rojo y ámbar.
const STATIC_SIGNAL := 30.0
## Segundos que se ve el mixer después de sincronizar, antes de volver al chat de León.
const SYNC_PAUSE := 1.2
## Segundos entre la despedida y las tarjetas.
const END_PAUSE := 2.5


## Una cosa que hace el juego: una orden y su valor.
class Item:
	var command: Command
	var value: Variant

	func _init(item_command: Command, item_value: Variant = null) -> void:
		command = item_command
		value = item_value


## Lo que pasa después de algo que hizo el jugador: lo que se hace en orden, con las pausas de León entre sus líneas,
## y lo que vale enseguida.
class Reply:
	var items: Array[Item] = []
	## La respuesta del jugador cuenta: la solicitud termina (enseguida).
	var accept_answer := false
	## Empieza a correr el tiempo de la demostración (enseguida).
	var run_demo := false

	func say(key: String) -> Reply:
		return then(Command.LINE, key)

	func then(command: Command, value: Variant = null) -> Reply:
		items.append(Item.new(command, value))
		return self

	## Las líneas de León, con la de estática fija, en orden.
	func lines() -> Array[String]:
		var keys: Array[String] = []
		for item: Item in items:
			if item.command in [Command.LINE, Command.STATIC_LINE]:
				keys.append(item.value)
		return keys

	## Las líneas del amigo de la demostración, en orden.
	func demo_lines() -> Array[String]:
		var keys: Array[String] = []
		for item: Item in items:
			if item.command == Command.DEMO_LINE:
				keys.append(item.value)
		return keys

	func has(command: Command) -> bool:
		return items.any(func(item: Item) -> bool: return item.command == command)

	## El valor de la última orden `command`, o null.
	func value_of(command: Command) -> Variant:
		for index in range(items.size() - 1, -1, -1):
			if items[index].command == command:
				return items[index].value
		return null


var step := Step.ASK_SIGHT

## León ya bromeó con un señuelo.
var _decoy_joked := false


## Empieza: León saluda y pide que le pregunten qué ve.
func start() -> Reply:
	step = Step.ASK_SIGHT
	return Reply.new().say(HELLO_KEY).say(GUESS_KEY).then(Command.FOCUS, Focus.ASK_SIGHT)


## El jugador preguntó por `category`.
func question_asked(category: ClueCategory.Kind) -> Reply:
	match [step, category]:
		[Step.ASK_SIGHT, ClueCategory.Kind.SIGHT]:
			step = Step.MARK
			return Reply.new().say(COST_KEY).say(MARK_KEY).then(Command.FOCUS, Focus.CLUES)
		[Step.ASK_SOUND, ClueCategory.Kind.SOUND]:
			step = Step.LISTEN
			return Reply.new().say(LISTEN_KEY).then(Command.FOCUS, Focus.AUDIO)
		[Step.ASK_AMBIENT, ClueCategory.Kind.ENVIRONMENT]:
			step = Step.MARK_SECOND
			return Reply.new().then(Command.FOCUS, Focus.CLUES)
	return Reply.new()


## El jugador marcó una frase: un señuelo o una característica. `marked` son las características marcadas.
func clue_marked(is_decoy: bool, marked: int) -> Reply:
	var reply := Reply.new()
	if is_decoy:
		if not _decoy_joked:
			_decoy_joked = true
			reply.say(DECOY_KEY)
		return reply
	if step == Step.MARK and marked >= 1:
		step = Step.ASK_SOUND
		reply.say(BLUE_KEY).say(ASK_SOUND_KEY).then(Command.FOCUS, Focus.ASK_SOUND)
	elif step == Step.MARK_SECOND and marked >= 2:
		# Matías piensa: no hay nada que apretar hasta que aparezca el nombre.
		reply.then(Command.FOCUS, Focus.NONE)
	return reply


## Se escuchó el audio que mandó León.
func audio_played() -> Reply:
	if step != Step.LISTEN:
		return Reply.new()
	step = Step.ASK_AMBIENT
	return Reply.new().say(HEARD_KEY).say(AMBIENT_KEY).then(Command.FOCUS, Focus.ASK_ENVIRONMENT)


## Apareció el nombre de Gonzalo: el cuaderno se desbloquea y hay que abrir su página.
func identified() -> Reply:
	if step != Step.MARK_SECOND:
		return Reply.new()
	step = Step.OPEN_PAGE
	return Reply.new().then(Command.UNLOCK, Unlock.NOTEBOOK).say(NAME_KEY).then(Command.FOCUS, Focus.ENTITY_NAME)


## Se abrió la página de Gonzalo.
func page_opened() -> Reply:
	if step != Step.OPEN_PAGE:
		return Reply.new()
	step = Step.BEST
	return Reply.new().say(DECIDE_KEY).say(BEST_KEY).then(Command.FOCUS, Focus.ANSWERS)


## El jugador respondió con una acción de resultado `outcome`. Primero cuenta solo la correcta y después solo la de
## mayor riesgo; cualquier otra no cuenta, y León pide intentarlo de nuevo.
func answered(outcome: RuleEvaluator.Outcome) -> Reply:
	match step:
		Step.BEST:
			if outcome != RuleEvaluator.Outcome.CORRECT:
				return Reply.new().say(RETRY_KEY)
			step = Step.WORST
			return Reply.new().say(BEST_OK_KEY).say(WORST_KEY)
		Step.WORST:
			if outcome != RuleEvaluator.Outcome.RISKY:
				return Reply.new().say(WORST_RETRY_KEY)
			step = Step.DOWNLOAD
			var reply := Reply.new().say(WORST_OK_KEY).say(DOWNLOAD_KEY).then(Command.SEND_VIDEO)
			reply.then(Command.FOCUS, Focus.DOWNLOAD)
			reply.accept_answer = true
			return reply
	return Reply.new()


## Se descargó el video: León avisa que Gonzalo le está escribiendo, y llega la solicitud de Gonzalo.
func video_received() -> Reply:
	if step != Step.DOWNLOAD:
		return Reply.new()
	step = Step.DEMO_CALL
	return Reply.new().say(VIDEO_OK_KEY).say(GONZALO_KEY).then(Command.START_DEMO) \
			.then(Command.UNLOCK, Unlock.DEMO_FRIEND).then(Command.FOCUS, Focus.DEMO_ENTRY)


## El jugador está mirando un chat: el del amigo de la demostración (`demo_friend`) o el de León. Al abrir el de Gonzalo,
## su tiempo empieza a correr; al volver con León después, León explica y sigue con la estática.
func chat_opened(demo_friend: bool) -> Reply:
	var reply := Reply.new()
	if step == Step.DEMO_CALL and demo_friend:
		step = Step.DEMO
		reply.run_demo = true
		reply.then(Command.FOCUS, Focus.NONE)
	elif step == Step.DEMO_DONE and not demo_friend:
		step = Step.SIGNAL
		reply.say(NO_ANSWER_KEY).then(Command.SET_SIGNAL, STATIC_SIGNAL).then(Command.STATIC_LINE, STATIC_KEY)
		reply.say(STATIC_EXPLAIN_KEY).say(SIGNAL_WARN_KEY).say(SIGNAL_CUT_KEY).then(Command.CUT_SIGNAL)
		reply.then(Command.UNLOCK, Unlock.MIXER).then(Command.FOCUS, Focus.SYNC)
	return reply


## Se le acabó el tiempo a Gonzalo: cuenta qué hizo solo, sale el aviso de daño (sin efecto) y hay que volver con León.
func demo_timed_out() -> Reply:
	if step != Step.DEMO:
		return Reply.new()
	step = Step.DEMO_DONE
	return Reply.new().then(Command.DEMO_LINE, GONZALO_ALONE_KEY).then(Command.DEMO_LINE, GONZALO_HURT_KEY) \
			.then(Command.DEMO_HURT).then(Command.FOCUS, Focus.GUIDE_ENTRY)


## Volvió la señal: se ve el mixer un momento, se abre el chat de León, se despide y termina.
func signal_restored() -> Reply:
	if step != Step.SIGNAL:
		return Reply.new()
	step = Step.DONE
	return Reply.new().then(Command.FOCUS, Focus.NONE).then(Command.PAUSE, SYNC_PAUSE).then(Command.OPEN_GUIDE_CHAT) \
			.say(BACK_KEY).say(READY_KEY).then(Command.PAUSE, END_PAUSE).then(Command.FINISH)
