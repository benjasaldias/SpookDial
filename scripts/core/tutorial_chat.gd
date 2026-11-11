extends RefCounted
## La conversación de León en la noche 0 (pedido de Benja, 11 de noviembre): en vez de un aviso arriba de la pantalla,
## León enseña en su chat, con chistes y sin entidades reales. Describe a Gonzalo: hay que preguntarle qué ve, marcar
## lo que sirve, preguntar por el ambiente y abrir la página de Gonzalo. Después pide la mejor decisión y la peor (la
## de la calavera), y si se elige otra, pide intentarlo de nuevo. La peor le cuesta un combo, pero manda un video que
## hay que descargar. Al final se le corta la señal, hay que sincronizarlo, y se despide.
## Lógica pura: RequestManager le cuenta lo que hace el jugador y escribe las líneas de León; cada método devuelve un
## Reply con esas líneas y lo que el juego tiene que hacer.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

enum Step { ASK_SIGHT, MARK, ASK_AMBIENT, OPEN_PAGE, BEST, WORST, DOWNLOAD, SIGNAL, DONE }

## Las líneas de León (ui.csv), en el orden en que pueden aparecer.
const HELLO_KEY := "TUTORIAL_LEON_HELLO"
const GUESS_KEY := "TUTORIAL_LEON_GUESS"
const ASK_SIGHT_AGAIN_KEY := "TUTORIAL_LEON_ASK_SIGHT_AGAIN"
const MARK_KEY := "TUTORIAL_LEON_MARK"
const DECOY_KEY := "TUTORIAL_LEON_DECOY"
const AMBIENT_KEY := "TUTORIAL_LEON_AMBIENT"
const NAME_KEY := "TUTORIAL_LEON_NAME"
const NAME_OPEN_KEY := "TUTORIAL_LEON_NAME_OPEN"
const DECIDE_KEY := "TUTORIAL_LEON_DECIDE"
const BEST_KEY := "TUTORIAL_LEON_BEST"
const RETRY_KEY := "TUTORIAL_LEON_RETRY"
const BEST_OK_KEY := "TUTORIAL_LEON_BEST_OK"
const WORST_KEY := "TUTORIAL_LEON_WORST"
const WORST_RETRY_KEY := "TUTORIAL_LEON_WORST_RETRY"
const WORST_OK_KEY := "TUTORIAL_LEON_WORST_OK"
const DOWNLOAD_KEY := "TUTORIAL_LEON_DOWNLOAD"
const VIDEO_OK_KEY := "TUTORIAL_LEON_VIDEO_OK"
const SIGNAL_WARN_KEY := "TUTORIAL_LEON_SIGNAL_WARN"
const SIGNAL_CUT_KEY := "TUTORIAL_LEON_SIGNAL_CUT"
const BACK_KEY := "TUTORIAL_LEON_BACK"
const READY_KEY := "TUTORIAL_LEON_READY"
const WAIT_KEY := "TUTORIAL_LEON_WAIT"
const ALL_KEYS: Array[String] = [HELLO_KEY, GUESS_KEY, ASK_SIGHT_AGAIN_KEY, MARK_KEY, DECOY_KEY, AMBIENT_KEY, NAME_KEY,
		NAME_OPEN_KEY, DECIDE_KEY, BEST_KEY, RETRY_KEY, BEST_OK_KEY, WORST_KEY, WORST_RETRY_KEY, WORST_OK_KEY,
		DOWNLOAD_KEY, VIDEO_OK_KEY, SIGNAL_WARN_KEY, SIGNAL_CUT_KEY, BACK_KEY, READY_KEY, WAIT_KEY]


## Lo que pasa después de algo que hizo el jugador.
class Reply:
	## Las líneas que escribe León, en orden (claves de ui.csv).
	var lines: Array[String] = []
	## La respuesta del jugador cuenta: la solicitud termina.
	var accept_answer := false
	## León manda un video, después de sus líneas.
	var send_video := false
	## A León se le corta la señal, después de sus líneas.
	var cut_signal := false
	## Terminó la conversación.
	var finished := false

	func _init(reply_lines: Array[String] = []) -> void:
		lines = reply_lines


var step := Step.ASK_SIGHT

## León ya bromeó con un señuelo.
var _decoy_joked := false
## La página de Gonzalo ya está abierta.
var _page_open := false


## Empieza: León saluda y pide que le pregunten qué ve.
func start() -> Reply:
	step = Step.ASK_SIGHT
	return Reply.new([HELLO_KEY, GUESS_KEY])


## El jugador preguntó por `category`.
func question_asked(category: ClueCategory.Kind) -> Reply:
	match step:
		Step.ASK_SIGHT:
			if category != ClueCategory.Kind.SIGHT:
				return Reply.new([ASK_SIGHT_AGAIN_KEY])
			step = Step.MARK
			return Reply.new([MARK_KEY])
	return Reply.new()


## El jugador marcó una frase: un señuelo o una característica. `marked` son las características marcadas.
func clue_marked(is_decoy: bool, marked: int) -> Reply:
	var reply := Reply.new()
	if is_decoy:
		if not _decoy_joked:
			_decoy_joked = true
			reply.lines.append(DECOY_KEY)
		return reply
	if step == Step.MARK and marked == 1:
		step = Step.ASK_AMBIENT
		reply.lines.append(AMBIENT_KEY)
	return reply


## Apareció el nombre de Gonzalo. Si su página ya está abierta (`page_open`), sigue directo a la tabla.
func identified(page_open: bool) -> Reply:
	if step > Step.OPEN_PAGE:
		return Reply.new()
	_page_open = _page_open or page_open
	if _page_open:
		step = Step.BEST
		return Reply.new([NAME_OPEN_KEY, DECIDE_KEY, BEST_KEY])
	step = Step.OPEN_PAGE
	return Reply.new([NAME_KEY])


## Se abrió la página de Gonzalo.
func page_opened() -> Reply:
	_page_open = true
	if step != Step.OPEN_PAGE:
		return Reply.new()
	step = Step.BEST
	return Reply.new([DECIDE_KEY, BEST_KEY])


## El jugador respondió con una acción de resultado `outcome`. Primero cuenta solo la correcta y después solo la de
## mayor riesgo; cualquier otra no cuenta, y León pide intentarlo de nuevo.
func answered(outcome: RuleEvaluator.Outcome) -> Reply:
	match step:
		Step.BEST:
			if outcome != RuleEvaluator.Outcome.CORRECT:
				return Reply.new([RETRY_KEY])
			step = Step.WORST
			return Reply.new([BEST_OK_KEY, WORST_KEY])
		Step.WORST:
			if outcome != RuleEvaluator.Outcome.RISKY:
				return Reply.new([WORST_RETRY_KEY])
			step = Step.DOWNLOAD
			var reply := Reply.new([WORST_OK_KEY, DOWNLOAD_KEY])
			reply.accept_answer = true
			reply.send_video = true
			return reply
		Step.ASK_SIGHT, Step.MARK, Step.ASK_AMBIENT, Step.OPEN_PAGE:
			return Reply.new([WAIT_KEY])
	return Reply.new()


## Se descargó el video: León avisa que la señal es mala, y se corta.
func video_received() -> Reply:
	if step != Step.DOWNLOAD:
		return Reply.new()
	step = Step.SIGNAL
	var reply := Reply.new([VIDEO_OK_KEY, SIGNAL_WARN_KEY, SIGNAL_CUT_KEY])
	reply.cut_signal = true
	return reply


## Volvió la señal: León se despide y termina.
func signal_restored() -> Reply:
	if step != Step.SIGNAL:
		return Reply.new()
	step = Step.DONE
	var reply := Reply.new([BACK_KEY, READY_KEY])
	reply.finished = true
	return reply
