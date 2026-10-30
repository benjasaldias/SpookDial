extends Node
## Las solicitudes de la noche (Plan 3): las genera, avanza sus temporizadores, recibe las preguntas
## y los clics del chat, y arma los mensajes con estática.
## El ritmo es provisional, hasta el director del Plan 7: llega una solicitud cada
## (duración de la noche ÷ solicitudes de la noche) segundos, sin pasar de las simultáneas.

signal message_added(friend_index: int, message: ChatMessage)
signal request_started(friend_index: int, request: FriendRequest)
## Cambió algo que se ve: una frase marcada o en rojo, Matías pensando, el nombre o el tiempo tras preguntar.
signal request_changed(friend_index: int, request: FriendRequest)
signal request_finished(friend_index: int, request: FriendRequest)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Duración de una noche en segundos reales (diseño §5).
const NIGHT_SECONDS := 420.0
## Segundos hasta la primera solicitud.
const FIRST_REQUEST_DELAY := 5.0

@export var catalog: ContentCatalog
## Noche que se juega. Por ahora la 3, la única con una entidad (El Trauco).
@export_range(1, 5) var night_number := 3
## Señal de los 3 amigos mientras no exista la del Plan 6. Bájala para ver la estática.
@export_range(1, 100) var test_signal := 100
## Si está apagado, las solicitudes no llegan solas (para las pruebas).
@export var requests_arrive := true
## 0: cada partida es distinta. Otro número repite la misma secuencia.
@export var random_seed := 0

var rng := RandomNumberGenerator.new()
## La solicitud activa de cada amigo, o null si no tiene.
var requests: Array[FriendRequest] = []
## Señal de cada amigo (0–100).
var signal_levels: Array[float] = []

var _since_last_request := 0.0
var _started_count := 0


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	for _friend: FriendData in catalog.friends:
		requests.append(null)
		signal_levels.append(float(test_signal))


func _process(delta: float) -> void:
	advance(delta)


func night() -> NightData:
	return catalog.nights[night_number - 1]


func active_count() -> int:
	return requests.size() - requests.count(null)


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
func advance(delta: float) -> void:
	for index in requests.size():
		var request := requests[index]
		if request == null:
			continue
		if request.advance(delta):
			request_changed.emit(index, request)
		if request.is_out_of_time():
			_decide_alone(index)
	if requests_arrive:
		_maybe_start_request(delta)


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o si no hay entidades.
func start_request(friend_index: int) -> FriendRequest:
	if requests[friend_index] != null:
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng)
	if request == null:
		return null
	requests[friend_index] = request
	_started_count += 1
	request_started.emit(friend_index, request)
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request


## Matías pregunta por una categoría: cuesta 5 s y el amigo responde. false si no se pudo preguntar.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not request.pay_question():
		return false
	message_added.emit(friend_index, MessageBuilder.question(request, category, tr))
	_add_friend_message(friend_index, MessageBuilder.answer(request, category, tr))
	request_changed.emit(friend_index, request)
	return true


## Clic en una frase de `message`. Solo cuenta si su solicitud sigue activa. Devuelve el estado de la frase.
func click_clue(message: ChatMessage, clue_id: StringName) -> FriendRequest.ClueState:
	var request := message.request
	if request == null or request.finished:
		return FriendRequest.ClueState.UNMARKED
	var state := request.click_clue(clue_id)
	request_changed.emit(request.friend_index, request)
	return state


func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng)
	requests[friend_index] = null
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	request_finished.emit(friend_index, request)


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
	ChatStatic.apply(message, signal_levels[friend_index], rng)
	message_added.emit(friend_index, message)


func _maybe_start_request(delta: float) -> void:
	_since_last_request += delta
	var current := night()
	var wait := FIRST_REQUEST_DELAY if _started_count == 0 else NIGHT_SECONDS / current.requests_total
	if _since_last_request < wait or _started_count >= current.requests_total:
		return
	if active_count() >= current.max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if requests[index] == null:
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_request(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		_since_last_request = 0.0
