extends Node
## Las solicitudes de la noche (planes 3 a 6): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## Desde el Plan 6 también avisa en el chat lo que pasa con los videos y la señal.
## Desde el Plan 7, el director de ritmo (PacingDirector) decide cuándo llega cada solicitud, y desde el Plan 9.1 en
## olas de verdad, con calmas y una ola final (decisión de Benja, 11 de noviembre): las olas traen interferencias y las
## calmas, videos, que el manager les da a amigos al azar.
## En la noche 0 (el tutorial), desde el Plan 9.2, León enseña en su chat (TutorialChat): llega su solicitud fija, sin
## mensaje inicial, y él escribe sus líneas de a una. Una respuesta que el tutorial no acepta no termina la solicitud.
## Después de la peor decisión León manda un video, se le corta la señal y, cuando vuelve, se despide (decisión de
## Benja, 11 de noviembre). Nadie sale herido.
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
## León terminó el tutorial de la noche 0 y se despidió (Plan 9.2).
signal tutorial_finished

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
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")

## En el tutorial, León escribe sus líneas de a una: cada una espera lo que tarda en escribirse la anterior (las letras
## por segundo del chat) y una pausa para leerla. Al despedirse, una pausa más larga antes de terminar.
const TUTORIAL_CHARS_PER_SECOND := 60.0
const TUTORIAL_LINE_PAUSE := 1.0
const TUTORIAL_END_PAUSE := 2.5

@export var catalog: ContentCatalog
## Noche que se juega (0: el tutorial). En el juego la elige GameState; este valor es el de las pruebas y el de
## abrir el escritorio solo, desde el editor.
@export_range(0, 5) var night_number := 3
## La dificultad de la partida (docs/26 §3): de ella salen las noches y si la identificación es guiada. La elige
## GameState; sin dificultad, la de por defecto del catálogo (Normal).
@export var difficulty: DifficultyData
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
## En el tutorial, las solicitudes fijas que todavía no llegan, en orden. Solo se usa la primera: la de León.
var tutorial_queue: Array[TutorialRequestData] = []
## La conversación de León en el tutorial, o null en las demás noches.
var tutorial_chat: TutorialChat
## En el tutorial, la página de la entidad de León ya está abierta en el cuaderno.
var tutorial_page_open := false

## Segundos desde las 00:00, como la hora del estado de la noche: el director cuenta en esa hora.
var _elapsed := 0.0
## En el tutorial, la hora desde la que puede llegar la solicitud de León.
var _next_tutorial_at := 0.0
## El amigo que enseña en el tutorial, o -1.
var _tutorial_friend := -1
## Lo que falta que haga León: sus líneas (claves de ui.csv) y sus órdenes (TUTORIAL_* de abajo), en orden.
var _tutorial_items: Array = []
## Segundos hasta lo próximo de León.
var _tutorial_wait := 0.0

## Las órdenes de León en el tutorial: mandar el video, cortar su señal, esperar y terminar.
const TUTORIAL_SEND_VIDEO := &"send_video"
const TUTORIAL_CUT_SIGNAL := &"cut_signal"
const TUTORIAL_PAUSE := &"pause"
const TUTORIAL_FINISH := &"finish"


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
	director = PacingDirector.new(night(), catalog.balance, rng)
	tutorial_queue.assign(night().tutorial_requests)
	_next_tutorial_at = catalog.balance.first_request_delay
	if night().is_tutorial():
		tutorial_chat = TutorialChat.new()
	for index in catalog.friends.size():
		requests.append(null)
		incidents.append(null)
		state.friends[index].signal_level = test_signal


func _process(delta: float) -> void:
	advance(delta)


func night() -> NightData:
	return catalog.night(night_number, difficulty)


## La dificultad que se juega: la elegida o, sin elegir, la de por defecto.
func current_difficulty() -> DifficultyData:
	return difficulty if difficulty != null else catalog.default_difficulty()


## La identificación es guiada (Normal): se destaca lo que importa, se marcan las características y Matías dice el nombre.
## En Difícil se lee (decisión de Benja, D3).
func highlights() -> bool:
	var current := current_difficulty()
	return current == null or current.highlights


func active_count() -> int:
	return requests.size() - requests.count(null)


## Lo que hace esperar al susto guionado: las solicitudes activas y, en el tutorial, las fijas que faltan.
func pending_count() -> int:
	return active_count() + (tutorial_queue.size() if night().is_tutorial() else 0)


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
			if index == _tutorial_friend:
				_tutorial(tutorial_chat.identified(tutorial_page_open))
		if request.is_out_of_time():
			_decide_alone(index)
	_advance_incidents(delta)
	_advance_chat_script(delta)
	if not requests_arrive:
		return
	if night().is_tutorial():
		_maybe_start_tutorial_request()
		_advance_tutorial(delta)
	else:
		_follow_director()
		_maybe_start_request()
		_maybe_start_incident()


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o un accidente, si no está
## disponible (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la
## opción "Temporizadores ×1,5", más largo, pero nunca pasa de las 06:00.
func start_request(friend_index: int) -> FriendRequest:
	if not _is_free(friend_index):
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng, state.trust)
	if request == null:
		return null
	request.time_left = minf(request.time_left * timer_scale, maxf(catalog.balance.night_seconds - _elapsed, 0.0))
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
## sin solicitud, sin tiempo, sin señal o porque ya la preguntó y su respuesta llegó entera (decisión de Benja, 11 de
## noviembre). La solicitud guarda si la estática tapó algo de la respuesta.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not state.friends[friend_index].is_online() or not request.can_ask_about(category) \
			or not request.pay_question():
		return false
	message_added.emit(friend_index, MessageBuilder.question(request, category, tr))
	var answer := MessageBuilder.answer(request, category, tr)
	_add_friend_message(friend_index, answer)
	request.record_answer(category, answer.lost_information())
	request_changed.emit(friend_index, request)
	if friend_index == _tutorial_friend:
		_tutorial(tutorial_chat.question_asked(category))
	return true


## Clic en una frase de `message`. Solo cuenta si su solicitud sigue activa. Devuelve el estado de la frase.
func click_clue(message: ChatMessage, clue_id: StringName) -> FriendRequest.ClueState:
	var request := message.request
	if request == null or request.finished:
		return FriendRequest.ClueState.UNMARKED
	var clue_state := request.click_clue(clue_id)
	request_changed.emit(request.friend_index, request)
	if request.friend_index == _tutorial_friend:
		_tutorial(tutorial_chat.clue_marked(clue_state == FriendRequest.ClueState.DECOY, request.marked_count()))
	return clue_state


## Matías responde con `action`, desde la página abierta en el cuaderno, y la solicitud termina.
## Una acción de la página de otra entidad es incorrecta (docs/02 §5.2).
## Devuelve false si el amigo no espera respuesta o está sin señal.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null or not state.friends[friend_index].is_online():
		return false
	if friend_index == _tutorial_friend:
		return _answer_tutorial(request, action)
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
		if friend_index == _tutorial_friend:
			_tutorial(tutorial_chat.video_received())
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
		if friend_index == _tutorial_friend:
			_tutorial(tutorial_chat.signal_restored())


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


## Avanza el director: empiezan las olas y las calmas. Cada interferencia de una ola le toca a un amigo al azar, y cada
## video de una calma lo manda un amigo al azar.
func _follow_director() -> void:
	var beat := director.advance(_elapsed, active_count())
	var friend_count := catalog.friends.size()
	for time: float in beat.interferences:
		state.interferences.add(rng.randi_range(0, friend_count - 1), time)
	for time: float in beat.videos:
		state.videos.release(rng.randi_range(0, friend_count - 1), time)


## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
## Si no hay a quién dársela, espera. El director decide si alcanza a terminar antes de las 06:00 con el tiempo sin
## alargar: con "Temporizadores ×1,5", start_request lo corta a las 06:00.
func _maybe_start_request() -> void:
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust)):
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


## En el tutorial, la solicitud de León llega a su hora, sin mensaje inicial: él escribe por su cuenta.
func _maybe_start_tutorial_request() -> void:
	if tutorial_queue.is_empty() or _tutorial_friend >= 0 or _elapsed < _next_tutorial_at:
		return
	var data: TutorialRequestData = tutorial_queue.pop_front()
	var request := RequestGenerator.generate_tutorial(catalog, night(), data, rng)
	requests[request.friend_index] = request
	_tutorial_friend = request.friend_index
	request_started.emit(request.friend_index, request)
	_tutorial(tutorial_chat.start())


## En el tutorial, se abrió la página de la entidad de León en el cuaderno: lo avisa el escritorio.
func tutorial_page_opened() -> void:
	tutorial_page_open = true
	if tutorial_chat != null and _tutorial_friend >= 0:
		_tutorial(tutorial_chat.page_opened())


## Matías le responde a León en el tutorial: se ve su respuesta, y León dice si cuenta. Solo cuando cuenta (la peor
## decisión), la solicitud termina, sin consecuencias.
func _answer_tutorial(request: FriendRequest, action: ActionData) -> bool:
	var friend_index := request.friend_index
	message_added.emit(friend_index, MessageBuilder.line(ChatMessage.Sender.PLAYER, action.label_key, tr))
	var reply := tutorial_chat.answered(RuleEvaluator.outcome(request.entity, request.situation, action))
	if reply.accept_answer:
		request.finish(action, true)
		_resolve(request)
		requests[friend_index] = null
		request_finished.emit(friend_index, request)
	_tutorial(reply)
	return true


## Encola lo que hace León después de algo que hizo Matías: sus líneas y, después, sus órdenes.
func _tutorial(reply: TutorialChat.Reply) -> void:
	_tutorial_items.append_array(reply.lines)
	if reply.send_video:
		_tutorial_items.append(TUTORIAL_SEND_VIDEO)
	if reply.cut_signal:
		_tutorial_items.append(TUTORIAL_CUT_SIGNAL)
	if reply.finished:
		_tutorial_items.append_array([TUTORIAL_PAUSE, TUTORIAL_FINISH])


## León escribe sus líneas de a una y cumple sus órdenes cuando les toca.
func _advance_tutorial(delta: float) -> void:
	_tutorial_wait -= delta
	while _tutorial_wait <= 0.0 and not _tutorial_items.is_empty():
		var item: Variant = _tutorial_items.pop_front()
		if item is String:
			_add_friend_message(_tutorial_friend, MessageBuilder.line(ChatMessage.Sender.FRIEND, item, tr))
			_tutorial_wait = tr(item).length() / TUTORIAL_CHARS_PER_SECOND + TUTORIAL_LINE_PAUSE
		elif item == TUTORIAL_SEND_VIDEO:
			state.videos.add_extra(_tutorial_friend, _elapsed)
		elif item == TUTORIAL_CUT_SIGNAL:
			state.friends[_tutorial_friend].signal_level = 0.0
		elif item == TUTORIAL_PAUSE:
			_tutorial_wait = TUTORIAL_END_PAUSE
		elif item == TUTORIAL_FINISH:
			tutorial_finished.emit()
