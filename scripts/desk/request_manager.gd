extends Node
## Las solicitudes de la noche (planes 3 a 6): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## Desde el Plan 6 también avisa en el chat lo que pasa con los videos y la señal.
## El ritmo es provisional, hasta el director del Plan 7: llega una solicitud cada
## (duración de la noche ÷ solicitudes de la noche) segundos, sin pasar de las simultáneas.
## En el escritorio lo avanza NightManager, junto con el estado de la noche.

signal message_added(friend_index: int, message: ChatMessage)
signal request_started(friend_index: int, request: FriendRequest)
## Cambió algo que se ve: una frase marcada o en rojo, Matías pensando, el nombre o el tiempo tras preguntar.
signal request_changed(friend_index: int, request: FriendRequest)
## Terminó una solicitud, con su consecuencia ya aplicada al estado de la noche.
signal request_finished(friend_index: int, request: FriendRequest)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Segundos hasta la primera solicitud.
const FIRST_REQUEST_DELAY := 5.0

@export var catalog: ContentCatalog
## Noche que se juega. Por ahora la 3, la única con una entidad (El Trauco).
@export_range(1, 5) var night_number := 3
## Señal con la que empiezan los 3 amigos. Bájala para ver la estática; con 0 empiezan desconectados.
@export_range(0, 100) var test_signal := 100
## Si está apagado, las solicitudes no llegan solas (para las pruebas).
@export var requests_arrive := true
## 0: cada partida es distinta. Otro número repite la misma secuencia.
@export var random_seed := 0

var rng := RandomNumberGenerator.new()
## La solicitud activa de cada amigo, o null si no tiene.
var requests: Array[FriendRequest] = []
## El estado de la noche: la hora, Sanity, Trust, cómo está cada amigo y los videos. Lo crea el manager,
## que tiene el catálogo y la noche; NightManager lo avanza.
var state: NightState

var _since_last_request := 0.0
var _started_count := 0


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
	for index in catalog.friends.size():
		requests.append(null)
		state.friends[index].signal_level = test_signal


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


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una, si no está disponible
## (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto.
func start_request(friend_index: int) -> FriendRequest:
	if requests[friend_index] != null or not state.is_available(friend_index):
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng, state.trust)
	if request == null:
		return null
	requests[friend_index] = request
	_started_count += 1
	request_started.emit(friend_index, request)
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request


## Matías pregunta por una categoría: cuesta 5 s y el amigo responde. false si no se pudo preguntar:
## sin solicitud, sin tiempo o sin señal.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not state.friends[friend_index].is_online() or not request.pay_question():
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
	var clue_state := request.click_clue(clue_id)
	request_changed.emit(request.friend_index, request)
	return clue_state


## Matías responde con `action`, desde la página abierta en el cuaderno, y la solicitud termina.
## Una acción de la página de otra entidad es incorrecta (docs/02 §5.2).
## Devuelve false si el amigo no espera respuesta o está sin señal.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null or not state.friends[friend_index].is_online():
		return false
	request.finish(action, true)
	_resolve(request)
	requests[friend_index] = null
	message_added.emit(friend_index, MessageBuilder.player_answer(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	_add_damage_notice(friend_index, request)
	request_finished.emit(friend_index, request)
	return true


## Avisa en el chat lo que pasó en un paso de la noche: el amigo que se quedó sin señal, el video que mandó
## un amigo y el que se recibió o se perdió. NightManager lo llama después de avanzar el estado de la noche.
func report(events: NightState.Events) -> void:
	for friend_index: int in events.disconnected:
		_add_notice(friend_index, MessageBuilder.SIGNAL_LOST_KEY, ChatMessage.Tone.DANGER)
	for friend_index: int in events.videos.offered:
		_add_friend_message(friend_index, MessageBuilder.video_sent(tr))
	for friend_index: int in events.videos.received:
		_add_notice(friend_index, MessageBuilder.VIDEO_RECEIVED_KEY, ChatMessage.Tone.GOOD)
	for friend_index: int in events.videos.lost:
		_add_notice(friend_index, MessageBuilder.VIDEO_LOST_KEY, ChatMessage.Tone.DANGER)


## Audio Sync salió bien: la señal del amigo vuelve a 100. Si estaba desconectado, el chat avisa que volvió.
func restore_signal(friend_index: int) -> void:
	var friend := state.friends[friend_index]
	var was_offline := not friend.is_online()
	friend.restore_signal()
	if was_offline:
		_add_notice(friend_index, MessageBuilder.SIGNAL_BACK_KEY, ChatMessage.Tone.GOOD)


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
## (decisión de Benja), y sus mensajes llegan tapados enteros.
func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng, not state.friends[friend_index].is_online())
	_resolve(request)
	requests[friend_index] = null
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	_add_damage_notice(friend_index, request)
	request_finished.emit(friend_index, request)


## Tira la consecuencia y la aplica al estado de la noche. Va antes de la reacción del amigo, que
## depende de si quedó herido.
func _resolve(request: FriendRequest) -> void:
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng,
			request.decided_offline)
	state.apply(request.friend_index, request.consequence)


## Si el amigo quedó herido, el juego lo avisa en el chat con la vida que le queda. El aviso no pasa
## por la estática.
func _add_damage_notice(friend_index: int, request: FriendRequest) -> void:
	if not request.consequence.is_hurt():
		return
	var friend := state.friends[friend_index]
	var friend_name := tr(catalog.friends[friend_index].name_key)
	message_added.emit(friend_index, MessageBuilder.damage_notice(request, friend_name, friend.health, friend.max_health, tr))


## Un aviso del juego en el chat del amigo, con su nombre y los videos de la noche.
func _add_notice(friend_index: int, key: String, tone: ChatMessage.Tone) -> void:
	var values := {"friend": tr(catalog.friends[friend_index].name_key), "received": state.videos.received,
			"quota": state.videos.quota}
	message_added.emit(friend_index, MessageBuilder.notice(key, values, tone, tr))


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
	ChatStatic.apply(message, state.friends[friend_index].signal_level, rng)
	message_added.emit(friend_index, message)


func _maybe_start_request(delta: float) -> void:
	_since_last_request += delta
	var current := night()
	var wait := FIRST_REQUEST_DELAY if _started_count == 0 else catalog.balance.night_seconds / current.requests_total
	if _since_last_request < wait or _started_count >= current.requests_total:
		return
	if active_count() >= current.max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if requests[index] == null and state.is_available(index):
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_request(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		_since_last_request = 0.0
