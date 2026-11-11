extends Node
## Las solicitudes de la noche (planes 3 a 6): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## Desde el Plan 6 también avisa en el chat lo que pasa con los videos y la señal.
## Desde el Plan 7, el director de ritmo (PacingDirector) decide cuándo llega cada solicitud: en olas, con un
## respiro después de cada una (decisión de Benja), sin pasar de las simultáneas.
## Desde el Plan 8, en la noche 0 (el tutorial) llegan las solicitudes fijas de la noche, de a una, y nadie sale
## herido (decisión de Benja).
## Desde el Plan 9, también los accidentes de los amigos: se responden en el chat, sin cuaderno, y una mala
## respuesta los hiere (decisión de Benja, 7 de noviembre).
## En el escritorio lo avanza NightManager, junto con el estado de la noche.

signal message_added(friend_index: int, message: ChatMessage)
signal request_started(friend_index: int, request: FriendRequest)
## Cambió algo que se ve: una frase marcada o en rojo, Matías pensando, el nombre o el tiempo tras preguntar.
signal request_changed(friend_index: int, request: FriendRequest)
## Terminó una solicitud, con su consecuencia ya aplicada al estado de la noche.
signal request_finished(friend_index: int, request: FriendRequest)
## Terminó el chat guionado (Plan 7).
signal chat_script_finished(chat: ChatScript)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatScript := preload("res://scripts/core/chat_script.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const FriendIncident := preload("res://scripts/core/friend_incident.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Segundos que pasan entre una solicitud del tutorial y la siguiente, para leer lo que pasó.
const TUTORIAL_GAP := 4.0

@export var catalog: ContentCatalog
## Noche que se juega (0: el tutorial). En el juego la elige GameState; este valor es el de las pruebas y el de
## abrir el escritorio solo, desde el editor.
@export_range(0, 5) var night_number := 3
## Señal con la que empiezan los 3 amigos. Bájala para ver la estática; con 0 empiezan desconectados.
@export_range(0, 100) var test_signal := 100
## Si está apagado, las solicitudes no llegan solas (para las pruebas).
@export var requests_arrive := true
## 0: cada partida es distinta. Otro número repite la misma secuencia.
@export var random_seed := 0
## Cuánto se alarga el tiempo para responder: 1,5 con la opción "Temporizadores ×1,5" (diseño §19).
var timer_scale := 1.0

var rng := RandomNumberGenerator.new()
## La solicitud activa de cada amigo, o null si no tiene.
var requests: Array[FriendRequest] = []
## El accidente en curso de cada amigo, o null.
var incidents: Array[FriendIncident] = []
## El estado de la noche: la hora, Sanity, Trust, cómo está cada amigo y los videos. Lo crea el manager,
## que tiene el catálogo y la noche; NightManager lo avanza.
var state: NightState
## Decide cuándo llega cada solicitud y cada screamer (Plan 7).
var director: PacingDirector
## El chat guionado en curso, o null (Plan 7).
var chat_script: ChatScript
## En el tutorial, las solicitudes fijas que todavía no llegan, en orden.
var tutorial_queue: Array[TutorialRequestData] = []

## Segundos desde las 00:00, como la hora del estado de la noche: el director cuenta en esa hora.
var _elapsed := 0.0
## En el tutorial, la hora desde la que puede llegar la próxima solicitud fija.
var _next_tutorial_at := 0.0
## La solicitud fija en curso en el tutorial, o null.
var _tutorial_current: TutorialRequestData


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
	director = PacingDirector.new(night(), catalog.balance, rng)
	tutorial_queue.assign(night().tutorial_requests)
	_next_tutorial_at = catalog.balance.first_request_delay
	for index in catalog.friends.size():
		requests.append(null)
		incidents.append(null)
		state.friends[index].signal_level = test_signal


func _process(delta: float) -> void:
	advance(delta)


func night() -> NightData:
	return catalog.night(night_number)


func active_count() -> int:
	return requests.size() - requests.count(null)


## Lo que hace esperar al susto guionado: las solicitudes activas y, en el tutorial, las fijas que faltan, el
## respiro antes de la próxima y el video que espera.
func pending_count() -> int:
	var count := active_count()
	if night().is_tutorial():
		count += tutorial_queue.size()
		if _elapsed < _next_tutorial_at or not (state.videos.pending.is_empty() and state.videos.offers.is_empty()):
			count += 1
	return count


## Cuántas solicitudes esperan más de la cuenta y hacen bajar Trust (decisión de Benja, 4 de noviembre): las que
## llevan más de slow_answer_grace segundos abiertas (más con "Temporizadores ×1,5") y tienen un amigo con señal;
## sin señal, Trust ya baja por eso.
func impatient_count() -> int:
	var grace := catalog.balance.slow_answer_grace * timer_scale
	var count := 0
	for index in requests.size():
		var request := requests[index]
		if request != null and state.friends[index].is_online() and request.is_slow(grace):
			count += 1
	return count


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
func advance(delta: float) -> void:
	_elapsed += delta
	for index in requests.size():
		var request := requests[index]
		if request == null:
			continue
		if request.advance(delta):
			request_changed.emit(index, request)
		if request.is_out_of_time():
			_decide_alone(index)
	_advance_incidents(delta)
	_advance_chat_script(delta)
	if not requests_arrive:
		return
	if night().is_tutorial():
		_maybe_start_tutorial_request()
	else:
		_maybe_start_request()
		_maybe_start_incident()


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o un accidente, si no está
## disponible (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la
## opción "Temporizadores ×1,5", más largo.
func start_request(friend_index: int) -> FriendRequest:
	if not _is_free(friend_index):
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng, state.trust)
	if request == null:
		return null
	request.time_left *= timer_scale
	requests[friend_index] = request
	request_started.emit(friend_index, request)
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request


## Empieza un accidente al azar para el amigo `friend_index`. Devuelve null si no puede tenerlo: tiene que estar
## libre y con señal, y con vida de sobra, porque un accidente nunca mata a un amigo.
func start_incident(friend_index: int) -> FriendIncident:
	if not _can_have_incident(friend_index) or catalog.incidents.is_empty():
		return null
	var data := catalog.incidents[rng.randi_range(0, catalog.incidents.size() - 1)]
	var incident := FriendIncident.new(data, friend_index, catalog.balance.incident_seconds * timer_scale, rng)
	incidents[friend_index] = incident
	_add_friend_message(friend_index, MessageBuilder.incident(data, tr))
	return incident


## Matías responde el accidente con la opción `option`. Devuelve false si el amigo no espera respuesta o está sin
## señal.
func answer_incident(friend_index: int, option: int) -> bool:
	var incident := incidents[friend_index]
	if incident == null or not state.friends[friend_index].is_online():
		return false
	message_added.emit(friend_index, MessageBuilder.line(ChatMessage.Sender.PLAYER, incident.options[option], tr))
	if incident.is_correct(option):
		incidents[friend_index] = null
		_add_friend_message(friend_index, MessageBuilder.line(ChatMessage.Sender.FRIEND, MessageBuilder.INCIDENT_GOOD_KEY, tr))
	else:
		_incident_hurts(friend_index, MessageBuilder.INCIDENT_BAD_KEY)
	return true


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


## Empieza el chat guionado `data`: su amigo escribe sus líneas y Matías responde las suyas con un botón
## (decisión de Benja). Sin un amigo del catálogo o sin líneas, no pasa nada.
func start_chat_script(data: ChatScriptData) -> void:
	if data == null or data.lines.is_empty():
		return
	var friend_index := catalog.friends.find(data.friend)
	if friend_index < 0:
		return
	chat_script = ChatScript.new(data, friend_index)


## La línea que Matías tiene que responder en el chat del amigo `friend_index`, o null.
func chat_script_reply(friend_index: int) -> ChatLineData:
	if chat_script == null or chat_script.friend_index != friend_index:
		return null
	return chat_script.pending_reply()


## Matías responde con el botón del chat guionado. Devuelve false si no había nada que responder.
func reply_chat_script() -> bool:
	if chat_script == null:
		return false
	var line := chat_script.reply()
	if line == null:
		return false
	message_added.emit(chat_script.friend_index, MessageBuilder.script_line(line, tr))
	_finish_chat_script_if_done()
	return true


## Avisa en el chat lo que pasó en un paso de la noche: el amigo que se quedó sin señal, el video que mandó
## un amigo y el que se recibió o se perdió. Si al perderse uno los que quedan ya no alcanzan la cuota, lo avisa ahí
## mismo: alguien tiene que arriesgarse (decisión de Benja, 11 de noviembre). NightManager lo llama después de
## avanzar el estado de la noche.
func report(events: NightState.Events) -> void:
	for friend_index: int in events.disconnected:
		_add_notice(friend_index, MessageBuilder.SIGNAL_LOST_KEY, ChatMessage.Tone.DANGER)
	for friend_index: int in events.videos.offered:
		_add_friend_message(friend_index, MessageBuilder.video_sent(tr))
	for friend_index: int in events.videos.received:
		_add_notice(friend_index, MessageBuilder.VIDEO_RECEIVED_KEY, ChatMessage.Tone.GOOD)
	for friend_index: int in events.videos.lost:
		_add_notice(friend_index, MessageBuilder.VIDEO_LOST_KEY, ChatMessage.Tone.DANGER)
		if state.videos.is_short():
			_add_notice(friend_index, MessageBuilder.VIDEOS_SHORT_KEY, ChatMessage.Tone.DANGER)


## Audio Sync salió bien: la señal del amigo vuelve a 100. Si estaba desconectado, el chat avisa que volvió.
func restore_signal(friend_index: int) -> void:
	var friend := state.friends[friend_index]
	var was_offline := not friend.is_online()
	friend.restore_signal()
	if was_offline:
		_add_notice(friend_index, MessageBuilder.SIGNAL_BACK_KEY, ChatMessage.Tone.GOOD)


## El amigo no tiene ni solicitud ni accidente, y está disponible.
func _is_free(friend_index: int) -> bool:
	return requests[friend_index] == null and incidents[friend_index] == null and state.is_available(friend_index)


func _can_have_incident(friend_index: int) -> bool:
	var friend := state.friends[friend_index]
	return _is_free(friend_index) and friend.is_online() and friend.health > catalog.balance.incident_damage


## Avanza los accidentes. Si a uno se le acaba el tiempo, el amigo sale herido.
func _advance_incidents(delta: float) -> void:
	for index in incidents.size():
		var incident := incidents[index]
		if incident == null:
			continue
		incident.advance(delta)
		if incident.is_out_of_time():
			_incident_hurts(index, MessageBuilder.INCIDENT_NO_ANSWER_KEY)


## Termina el accidente con el amigo herido: lo cuenta y el juego avisa cuánta vida le queda. Las solicitudes que
## faltan se atrasan, como con cualquier amigo herido.
func _incident_hurts(friend_index: int, reaction_key: String) -> void:
	incidents[friend_index] = null
	state.injure(friend_index)
	director.friend_hurt()
	_add_friend_message(friend_index, MessageBuilder.line(ChatMessage.Sender.FRIEND, reaction_key, tr))
	var friend := state.friends[friend_index]
	var friend_name := tr(catalog.friends[friend_index].name_key)
	message_added.emit(friend_index, MessageBuilder.damage_notice(null, friend_name, friend.health, friend.max_health, tr))


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
## depende de si quedó herido. Un amigo herido atrasa las solicitudes que faltan (decisión de Benja).
## En el tutorial no hay consecuencias.
func _resolve(request: FriendRequest) -> void:
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng,
			request.decided_offline, night().is_tutorial())
	state.apply(request.friend_index, request.consequence)
	if request.consequence.is_hurt():
		director.friend_hurt()
	if _tutorial_current != null:
		_finish_tutorial_request(request.friend_index)


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


## El amigo del chat guionado escribe su próxima línea cuando le toca.
func _advance_chat_script(delta: float) -> void:
	if chat_script == null:
		return
	var line := chat_script.advance(delta)
	if line != null:
		_add_friend_message(chat_script.friend_index, MessageBuilder.script_line(line, tr))
	_finish_chat_script_if_done()


func _finish_chat_script_if_done() -> void:
	if chat_script == null or not chat_script.is_done():
		return
	var finished := chat_script
	chat_script = null
	chat_script_finished.emit(finished)


## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
## Si no hay a quién dársela, espera: el director atrasa las que faltan.
func _maybe_start_request() -> void:
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust) * timer_scale):
		return
	if active_count() >= night().max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if _is_free(index):
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_request(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		director.request_started(_elapsed)


## Cuando el director lo pide, a un amigo libre al azar le pasa un accidente. Si la ola está llena o nadie puede
## tenerlo, espera.
func _maybe_start_incident() -> void:
	if not director.incident_due(_elapsed) or active_count() >= night().max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if _can_have_incident(index):
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_incident(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		director.incident_started()


## En el tutorial, la próxima solicitud fija llega cuando no hay otra, pasó el respiro y no hay un video
## esperando.
func _maybe_start_tutorial_request() -> void:
	if tutorial_queue.is_empty() or active_count() > 0 or _elapsed < _next_tutorial_at:
		return
	if not (state.videos.pending.is_empty() and state.videos.offers.is_empty()):
		return
	var data: TutorialRequestData = tutorial_queue.pop_front()
	var request := RequestGenerator.generate_tutorial(catalog, night(), data, rng)
	requests[request.friend_index] = request
	_tutorial_current = data
	request_started.emit(request.friend_index, request)
	_add_friend_message(request.friend_index, MessageBuilder.first_message(request, tr))


## Terminó la solicitud fija en curso: empieza el respiro y, si la solicitud lo pide, el amigo manda un video.
func _finish_tutorial_request(friend_index: int) -> void:
	if _tutorial_current.sends_video:
		state.videos.add_extra(friend_index, _elapsed)
	_tutorial_current = null
	_next_tutorial_at = _elapsed + TUTORIAL_GAP
