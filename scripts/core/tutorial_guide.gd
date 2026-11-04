extends RefCounted
## El guía de la noche 0, el tutorial (decisión de Benja): mira cómo va la noche y dice qué hacer ahora, en un
## aviso arriba de la pantalla. Enseña a abrir el chat, preguntar, marcar las características, abrir la página
## de la entidad, responder desde el cuaderno y descargar un video. Después del susto guionado, a responderle al
## amigo y a usar el celular. El tutorial termina cuando Matías cierra el celular.
## Lógica pura: el escritorio le cuenta lo que se ve (View) y muestra el aviso (Hint).

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Los textos del aviso (ui.csv). Los que hablan de un amigo llevan {friend}.
const TITLE_KEY := "TUTORIAL_TITLE"
const SKIP_KEY := "TUTORIAL_SKIP"
const WELCOME_KEY := "TUTORIAL_WELCOME"
const OPEN_CHAT_KEY := "TUTORIAL_OPEN_CHAT"
const ASK_KEY := "TUTORIAL_ASK"
const MARK_KEY := "TUTORIAL_MARK"
const OPEN_PAGE_KEY := "TUTORIAL_OPEN_PAGE"
const ANSWER_KEY := "TUTORIAL_ANSWER"
const CORRECT_KEY := "TUTORIAL_CORRECT"
const RISKY_KEY := "TUTORIAL_RISKY"
const WRONG_KEY := "TUTORIAL_WRONG"
const VIDEO_KEY := "TUTORIAL_VIDEO"
const HOLD_KEY := "TUTORIAL_HOLD"
const REPLY_KEY := "TUTORIAL_REPLY"
const PHONE_KEY := "TUTORIAL_PHONE"
const SCROLL_KEY := "TUTORIAL_SCROLL"
const DIALS_KEY := "TUTORIAL_DIALS"
const DIALS_OK_KEY := "TUTORIAL_DIALS_OK"
## Cómo le fue al amigo con la última respuesta.
const OUTCOME_KEYS := {
	RuleEvaluator.Outcome.CORRECT: CORRECT_KEY,
	RuleEvaluator.Outcome.RISKY: RISKY_KEY,
	RuleEvaluator.Outcome.WRONG: WRONG_KEY,
}

## Lo que se ve en el escritorio.
class View:
	## La solicitud del tutorial en curso, o null.
	var request: FriendRequest
	## El amigo cuyo chat está abierto, o -1 con el chat cerrado.
	var chat_friend := -1
	## La página del cuaderno abierta para el amigo de la solicitud, o null.
	var page: EntityData
	## El amigo cuyo video espera su descarga, o -1.
	var video_friend := -1
	## El amigo del chat guionado que espera la respuesta de Matías, o -1.
	var script_friend := -1


## El aviso: su clave en ui.csv (vacía: sin aviso) y el amigo del que habla, o -1.
class Hint:
	var key := ""
	var friend_index := -1
	## El aviso lleva un botón "Entendido": sigue hasta que Matías lo presiona.
	var needs_ok := false

	func _init(hint_key: String, hint_friend := -1, with_ok := false) -> void:
		key = hint_key
		friend_index = hint_friend
		needs_ok = with_ok


## La lección del celular, después del chat guionado.
enum Phone { WAITING, HIGHLIGHTED, OPEN, DONE }

## Lo primero que dice el tutorial son los diales (decisión de Benja, 4 de noviembre). Lo enciende el escritorio.
var explain_dials := false
var _phone := Phone.WAITING
var _last_request: FriendRequest


## Terminó una solicitud: el aviso dice cómo le fue al amigo.
func request_finished(request: FriendRequest) -> void:
	_last_request = request


## El celular empezó a parpadear: el amigo le dijo a Matías que lo use.
func phone_highlighted() -> void:
	_phone = Phone.HIGHLIGHTED


func phone_opened() -> void:
	if _phone == Phone.HIGHLIGHTED:
		_phone = Phone.OPEN


func phone_closed() -> void:
	if _phone == Phone.OPEN:
		_phone = Phone.DONE


## Matías usó el celular: el tutorial terminó.
func is_done() -> bool:
	return _phone == Phone.DONE


## Matías presionó "Entendido" en el aviso de los diales.
func dials_understood() -> void:
	explain_dials = false


## Qué hacer ahora. Primero los diales, después el celular, el chat guionado, el video y la solicitud en curso.
func hint(view: View) -> Hint:
	if explain_dials:
		return Hint.new(DIALS_KEY, -1, true)
	match _phone:
		Phone.HIGHLIGHTED:
			return Hint.new(PHONE_KEY)
		Phone.OPEN:
			return Hint.new(SCROLL_KEY)
		Phone.DONE:
			return Hint.new("")
	if view.script_friend >= 0:
		return Hint.new(REPLY_KEY) if view.chat_friend == view.script_friend else Hint.new(OPEN_CHAT_KEY, view.script_friend)
	if view.video_friend >= 0:
		return Hint.new(HOLD_KEY) if view.chat_friend == view.video_friend else Hint.new(VIDEO_KEY, view.video_friend)
	var request := view.request
	if request == null:
		if _last_request == null:
			return Hint.new(WELCOME_KEY)
		return Hint.new(OUTCOME_KEYS[_last_request.outcome], _last_request.friend_index)
	if view.chat_friend != request.friend_index:
		return Hint.new(OPEN_CHAT_KEY, request.friend_index)
	if request.identification == FriendRequest.Identification.PENDING:
		return Hint.new(ASK_KEY, request.friend_index) if request.questions_asked == 0 else Hint.new(MARK_KEY)
	if view.page != request.entity:
		return Hint.new(OPEN_PAGE_KEY)
	return Hint.new(ANSWER_KEY)
