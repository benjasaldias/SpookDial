extends Node
## Las solicitudes de la noche (planes 3 a 6): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## Desde el Plan 6 también avisa en el chat lo que pasa con los videos y la señal.
## Desde el Plan 7, el director de ritmo (PacingDirector) decide cuándo llega cada solicitud, y desde el Plan 9.1 en
## olas de verdad, con calmas y una ola final (decisión de Benja, 11 de noviembre): las olas traen interferencias y las
## calmas, videos, que el manager les da a amigos al azar.
## En la noche 0 (el tutorial), desde el Plan 9.2, León enseña en su chat (TutorialChat): llega su solicitud fija, sin
## mensaje inicial, y él escribe sus líneas de a una. Una respuesta que el tutorial no acepta no termina la solicitud.
## Nadie sale herido. Desde el Plan 9.5 (tras el primer testeo), el manager cumple en orden lo que pide TutorialChat:
## qué parpadea (y es lo único que se puede usar), qué se desbloquea del escritorio, el video, la demostración de
## Gonzalo (15 s reales sin poder responder; al llegar a 0 cuenta qué hizo y sale el aviso de daño, sin efecto), la
## señal que baja con una línea de estática fija, la señal que se corta y la despedida. Las demás líneas de León no
## llevan estática.
## Desde el Plan 9, también los accidentes de los amigos: se responden en el chat, sin cuaderno, y una mala
## respuesta los hiere (decisión de Benja, 7 de noviembre).
## Desde el Plan 9.7 (docs/31), la historia de la noche (StoryRunner, decisiones de Benja en S21b): las líneas de los
## amigos van a sus chats o, con los 3 juntos, a la llamada grupal, que se ve cuando no hay nada que jugar (call_active).
## Una decisión de la historia llega como un accidente, y su opción baja Trust (nunca bajo 1), quita segundos a la próxima
## consulta de un amigo y hiere (nunca mata). Mientras la historia cuenta algo, la próxima ola espera. Además, cada
## criatura nueva de la noche sale al menos una vez, y con los 3 juntos nadie dice que está solo (docs/21 §1 y §2).
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
## En el tutorial, hay que mostrar el chat del amigo `friend_index` (Plan 9.5): León se despide ahí.
signal tutorial_chat_requested(friend_index: int)
## Una línea de la historia en la llamada grupal, dicha por el amigo `speaker_index` (Plan 9.7).
signal call_message_added(speaker_index: int, message: ChatMessage)
## Empezó una ola (`finale`: la final). El escritorio toca un golpe de sonido (Plan 9.8).
signal wave_started(finale: bool)

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
const StoryRunner := preload("res://scripts/core/story_runner.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")

## La historia nunca hace perder (decisión de Benja, S21l): Trust no baja de esto por ella.
const STORY_TRUST_FLOOR := 1.0
## Los segundos que la historia le quita a la próxima consulta de un amigo nunca la dejan con menos de esto.
const STORY_MIN_DECISION_TIME := 10.0

## En el tutorial, León escribe sus líneas de a una: cada una espera lo que tarda en escribirse la anterior (las letras
## por segundo del chat) y una pausa para leerla.
const TUTORIAL_CHARS_PER_SECOND := 60.0
## El aviso de un amigo que empezó herido (ui.csv). Lleva {friend}, {health} y {max}.
const WOUNDED_START_KEY := "CHAT_WOUNDED_START"
const TUTORIAL_LINE_PAUSE := 1.0
## Después de un audio, León espera lo que dura y esto más, antes de comentarlo.
const TUTORIAL_AUDIO_PAUSE := 0.5

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
## El equilibrio de la noche: el de balance.tres con los castigos por error de la dificultad (Extremo: ×1,5; docs/30). Lo
## usan el estado de la noche y las consecuencias.
var balance: BalanceData
## Los amigos que empezaron la noche heridos (Extremo; idea de Benja, 12 de noviembre). Su chat lo avisa al empezar.
var wounded: Array[int] = []
## Ya se avisó en el chat qué amigos empezaron heridos.
var _wounded_announced := false

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
## En el tutorial, lo que parpadea y es lo único que se puede usar ahora (Plan 9.5).
var tutorial_focus := TutorialChat.Focus.NONE
## La historia de la noche en curso, o null si la noche no tiene (Plan 9.7).
var story: StoryRunner
## La noche espera que se abra la llamada para empezar (pedido de Benja, Plan 9.8): así la historia se lee en vivo.
## NightManager no avanza mientras tanto. Solo en las noches con historia que empiezan con los 3 juntos.
var waiting_for_call := false

## Segundos desde las 00:00, como la hora del estado de la noche: el director cuenta en esa hora.
var _elapsed := 0.0
## En el tutorial, la hora desde la que puede llegar la solicitud de León.
var _next_tutorial_at := 0.0
## El amigo que enseña en el tutorial (el guía), o -1.
var _tutorial_friend := -1
## El amigo de la demostración del tutorial (Gonzalo), o -1 hasta que llega su solicitud.
var _demo_friend := -1
## Lo que falta que haga el tutorial, en orden (TutorialChat.Item).
var _tutorial_items: Array[TutorialChat.Item] = []
## Segundos hasta lo próximo del tutorial.
var _tutorial_wait := 0.0
## Lo que ya se desbloqueó en el tutorial.
var _unlocked: Array[TutorialChat.Unlock] = []
## Los segundos que la historia le quita a la próxima consulta de cada amigo.
var _story_penalty: Array[float] = []
## Las entidades que ya llegaron esta noche, y cuántas consultas empezaron: para que cada criatura nueva salga.
var _seen_entities: Array[EntityData] = []
var _requests_started := 0


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	var current := current_difficulty()
	balance = current.balance_for(catalog.balance) if current != null else catalog.balance
	state = NightState.new(night(), balance, catalog.friends.size(), rng)
	# La historia está en el horario del director (Plan 9.8): le dice cuánto dura cada momento.
	var story_needs := {}
	if night().story != null and not night().is_tutorial():
		story_needs = StoryRunner.story_needs(night().story, tr, catalog.balance.incident_seconds)
	director = PacingDirector.new(night(), balance, rng, story_needs)
	tutorial_queue.assign(night().tutorial_requests)
	_next_tutorial_at = catalog.balance.first_request_delay
	if night().is_tutorial():
		tutorial_chat = TutorialChat.new()
	for index in catalog.friends.size():
		requests.append(null)
		incidents.append(null)
		_story_penalty.append(0.0)
		state.friends[index].signal_level = test_signal
	if night().story != null and not night().is_tutorial():
		story = StoryRunner.new(night().story, catalog.friends, tr, catalog.balance.incident_seconds)
		waiting_for_call = night().story.starts_together
	if current != null and not night().is_tutorial():
		_wound_friends(current.wounded_friends, current.wounded_health)


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


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes. En el primer paso
## avisa qué amigos empezaron heridos: el chat ya está conectado.
func advance(delta: float) -> void:
	if not _wounded_announced:
		_wounded_announced = true
		for friend_index: int in wounded:
			_add_wounded_notice(friend_index)
	_elapsed += delta
	for index in requests.size():
		var request := requests[index]
		if request == null:
			continue
		if request.advance(delta):
			request_changed.emit(index, request)
			if index == _tutorial_friend:
				_tutorial(tutorial_chat.identified())
		if request.is_out_of_time():
			if index == _demo_friend:
				_end_demo(index)
			else:
				_decide_alone(index)
	_advance_incidents(delta)
	_advance_chat_script(delta)
	if requests_arrive:
		if night().is_tutorial():
			_maybe_start_tutorial_request()
			_advance_tutorial(delta)
		else:
			_follow_director()
			_maybe_start_request()
			_maybe_start_incident()
	_advance_story(delta)


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o un accidente, si no está
## disponible (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la
## opción "Temporizadores ×1,5", más largo, pero nunca pasa de las 06:00. Si la historia le quitó segundos a la próxima
## consulta del amigo, se los quita a esta. Con los 3 juntos en la historia, el amigo no dice que está solo, y si quedan
## tantas consultas como criaturas nuevas que todavía no salieron, la entidad es una de ellas.
func start_request(friend_index: int) -> FriendRequest:
	if not _is_free(friend_index):
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng, state.trust, _together(),
			_forced_entities())
	if request == null:
		return null
	request.time_left = minf(request.time_left * timer_scale, maxf(state.length - _elapsed, 0.0))
	if _story_penalty[friend_index] > 0.0:
		request.time_left = minf(request.time_left,
				maxf(request.time_left - _story_penalty[friend_index], STORY_MIN_DECISION_TIME))
		_story_penalty[friend_index] = 0.0
	_requests_started += 1
	if not _seen_entities.has(request.entity):
		_seen_entities.append(request.entity)
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
	if incident.decision != null:
		_resolve_decision(friend_index, incident.decision.options[option], true)
		return true
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
	if request == null or friend_index == _demo_friend or not state.friends[friend_index].is_online() \
			or not request.can_ask_about(category) or not request.pay_question():
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
	if request == null or action == null or friend_index == _demo_friend or not state.friends[friend_index].is_online():
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
		# En el tutorial, León ya dijo que mantengas apretada la barra: no repite que mandó un video.
		if not night().is_tutorial():
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
			if incident.decision != null:
				_resolve_decision(index, incident.decision.no_answer, false)
			else:
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
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, balance, rng,
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


## Hiere a `count` amigos distintos, al azar: empiezan la noche con `health` de vida (Extremo; docs/30).
func _wound_friends(count: int, health: int) -> void:
	if count <= 0:
		return
	var friends: Array = RequestGenerator.shuffled(range(catalog.friends.size()), rng)
	for friend_index: int in friends.slice(0, count):
		state.friends[friend_index].health = mini(health, state.friends[friend_index].max_health)
		wounded.append(friend_index)


## El amigo empezó herido: su chat lo avisa en rojo, con la vida que le queda.
func _add_wounded_notice(friend_index: int) -> void:
	var friend := state.friends[friend_index]
	var values := {"friend": tr(catalog.friends[friend_index].name_key), "health": friend.health,
			"max": friend.max_health}
	message_added.emit(friend_index, MessageBuilder.notice(WOUNDED_START_KEY, values, ChatMessage.Tone.DANGER, tr))


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
	director.story_hold = story != null and story.holds()
	var beat := director.advance(_elapsed, active_count())
	if beat.wave_started >= 0:
		wave_started.emit(beat.finale_started)
	var friend_count := catalog.friends.size()
	for time: float in beat.interferences:
		state.interferences.add(rng.randi_range(0, friend_count - 1), time)
	for time: float in beat.videos:
		state.videos.release(rng.randi_range(0, friend_count - 1), time)


## Se abrió la llamada: la noche empieza (Plan 9.8).
func call_opened() -> void:
	waiting_for_call = false


## La llamada grupal se ve: la historia tiene a los 3 juntos y no hay nada que jugar (docs/21 §2).
func call_active() -> bool:
	return _together() and _nothing_to_play()


## Los 3 amigos están juntos en la historia.
func _together() -> bool:
	return story != null and story.together


## Hay consultas, accidentes o decisiones abiertas.
func _story_busy() -> bool:
	return active_count() > 0 or incidents.any(func(incident: FriendIncident) -> bool: return incident != null)


## No hay consultas, accidentes, decisiones, videos por descargar ni un chat guionado que espera la respuesta de Matías: la
## llamada se puede ver.
func _nothing_to_play() -> bool:
	if _story_busy() or (chat_script != null and chat_script.pending_reply() != null):
		return false
	for index in catalog.friends.size():
		if state.videos.offer_for(index) != null:
			return false
	return true


## Las criaturas nuevas de la noche que todavía no salieron, si quedan tantas consultas como ellas; si no, ninguna (y la
## entidad sale al azar entre las conocidas).
func _forced_entities() -> Array[EntityData]:
	var missing: Array[EntityData] = []
	for entity: EntityData in night().new_entities:
		if not _seen_entities.has(entity):
			missing.append(entity)
	if missing.is_empty() or night().total_requests() - _requests_started > missing.size():
		missing.clear()
	return missing


## Avanza la historia y cumple lo que pide. Un amigo puede decidir si está libre, despierto y con señal.
func _advance_story(delta: float) -> void:
	if story == null:
		return
	var can_decide := func(friend_index: int) -> bool:
		return _is_free(friend_index) and state.friends[friend_index].is_online()
	for item: StoryRunner.Item in story.advance(delta, _elapsed, director, _story_busy(), _nothing_to_play(), can_decide):
		_do_story(item)


## Una línea en el chat de un amigo o en la llamada (con la estática de quien habla), o una decisión, que llega como un
## accidente: la pregunta en el chat del amigo y sus opciones en las respuestas.
func _do_story(item: StoryRunner.Item) -> void:
	match item.command:
		StoryRunner.Command.LINE:
			_add_friend_message(item.friend, MessageBuilder.line(ChatMessage.Sender.FRIEND, item.key, tr))
		StoryRunner.Command.CALL_LINE:
			var message := MessageBuilder.line(ChatMessage.Sender.FRIEND, item.key, tr)
			ChatStatic.apply(message, state.friends[item.friend].signal_level, rng)
			call_message_added.emit(item.friend, message)
		StoryRunner.Command.DECISION:
			incidents[item.friend] = FriendIncident.for_decision(item.decision, item.friend,
					catalog.balance.incident_seconds * timer_scale) as FriendIncident
			# La pregunta pide ayuda, como un accidente (Plan 9.8).
			var question := MessageBuilder.line(ChatMessage.Sender.FRIEND, item.key, tr)
			question.urgent = true
			question.opens_help = true
			_add_friend_message(item.friend, question)


## Terminó una decisión de la historia con `option`: Matías la respondió (`answered`) o se acabó el tiempo. El amigo
## contesta y se aplica la opción.
func _resolve_decision(friend_index: int, option: StoryOptionData, answered: bool) -> void:
	incidents[friend_index] = null
	if answered:
		message_added.emit(friend_index, MessageBuilder.line(ChatMessage.Sender.PLAYER, option.label_key, tr))
	if story != null:
		for item: StoryRunner.Item in story.decided(option):
			_do_story(item)
	_apply_story_option(option)


## Lo que hace una opción de la historia: Trust (nunca bajo 1), los segundos que pierde la próxima consulta de cada
## castigado y el daño, al que tenga más vida entre los candidatos y solo si sobrevive, con su aviso (decisiones de
## Benja, S21b y S21l).
func _apply_story_option(option: StoryOptionData) -> void:
	if option == null:
		return
	state.trust = clampf(state.trust + option.trust_change, minf(state.trust, STORY_TRUST_FLOOR), NightState.METER_MAX)
	for friend: FriendData in option.penalized:
		var index := catalog.friends.find(friend)
		if index >= 0:
			_story_penalty[index] += option.penalty_seconds
	var hurt := _story_damage_target(option)
	if hurt < 0:
		return
	var friend_state := state.friends[hurt]
	friend_state.hurt(option.damage, balance.stun_seconds)
	director.friend_hurt()
	message_added.emit(hurt, MessageBuilder.damage_notice(null, tr(catalog.friends[hurt].name_key), friend_state.health,
			friend_state.max_health, tr))


## A quién hiere la opción: el que tenga más vida entre los candidatos (el primero, si empatan), y solo si sobrevive; si
## nadie sobrevive al daño, a nadie (-1).
func _story_damage_target(option: StoryOptionData) -> int:
	if option.damage <= 0:
		return -1
	var best := -1
	for friend: FriendData in option.damage_candidates:
		var index := catalog.friends.find(friend)
		if index < 0 or state.friends[index].health <= option.damage:
			continue
		if best < 0 or state.friends[index].health > state.friends[best].health:
			best = index
	return best


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
	if tutorial_chat != null and _tutorial_friend >= 0:
		_tutorial(tutorial_chat.page_opened())


## En el tutorial, el jugador está mirando el chat de `friend_index` (-1: ninguno). El escritorio lo dice en cada cuadro,
## y solo cuenta cuando el tutorial no tiene nada pendiente: así el chat de Gonzalo echa a andar su tiempo y, después,
## el de León sigue con la estática.
func tutorial_view(friend_index: int) -> void:
	if tutorial_chat == null or friend_index < 0 or tutorial_busy():
		return
	if friend_index == _demo_friend:
		_tutorial(tutorial_chat.chat_opened(true))
	elif friend_index == _tutorial_friend:
		_tutorial(tutorial_chat.chat_opened(false))


## En el tutorial, se escuchó el audio `stream` que mandó el amigo `friend_index`: León espera a que termine antes de
## comentarlo.
func tutorial_audio_played(friend_index: int, stream: AudioStream) -> void:
	if tutorial_chat == null or friend_index != _tutorial_friend:
		return
	var reply := tutorial_chat.audio_played()
	if not reply.items.is_empty() and stream != null:
		_tutorial_wait = maxf(_tutorial_wait, stream.get_length() + TUTORIAL_AUDIO_PAUSE)
	_tutorial(reply)


## El tutorial todavía tiene algo pendiente: León escribe o falta una orden.
func tutorial_busy() -> bool:
	return not _tutorial_items.is_empty()


## En el tutorial, `focus` es lo que hay que apretar ahora y León ya terminó: parpadea y se puede usar.
func tutorial_wants(focus: TutorialChat.Focus) -> bool:
	return tutorial_chat != null and tutorial_focus == focus and not tutorial_busy()


## Está en la noche 0 (el tutorial): el chat y el escritorio solo dejan usar lo que se va enseñando.
func is_tutorial() -> bool:
	return tutorial_chat != null


## Se puede usar `unlock`: fuera del tutorial, siempre; en él, desde que se desbloquea.
func is_unlocked(unlock: TutorialChat.Unlock) -> bool:
	return tutorial_chat == null or _unlocked.has(unlock)


## El amigo que enseña en el tutorial (el guía) y el de la demostración, o -1.
func tutorial_guide() -> int:
	return _tutorial_friend


func tutorial_demo_friend() -> int:
	return _demo_friend


## En el tutorial, el amigo de la demostración ya puede usarse: su entrada y su pestaña.
func is_friend_unlocked(friend_index: int) -> bool:
	if tutorial_chat == null:
		return true
	if friend_index == _tutorial_friend or (_tutorial_friend < 0 and friend_index == _guide_index()):
		return true
	return friend_index == _demo_index() and is_unlocked(TutorialChat.Unlock.DEMO_FRIEND)


## El amigo del guía y el de la demostración, según las solicitudes fijas de la noche, aunque todavía no lleguen.
func _guide_index() -> int:
	var data := night().tutorial_requests
	return catalog.friends.find(data[0].friend) if not data.is_empty() else -1


func _demo_index() -> int:
	for data: TutorialRequestData in night().tutorial_requests:
		if data.demo_seconds > 0.0:
			return catalog.friends.find(data.friend)
	return -1


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


## Encola lo que hace el tutorial después de algo que hizo Matías. Lo que vale enseguida se hace ahora: echar a andar el
## tiempo de la demostración.
func _tutorial(reply: TutorialChat.Reply) -> void:
	_tutorial_items.append_array(reply.items)
	if reply.run_demo and _demo_friend >= 0 and requests[_demo_friend] != null:
		requests[_demo_friend].timer_paused = false


## El tutorial hace lo que le toca, de a una cosa: las líneas esperan lo que tarda en escribirse la anterior.
func _advance_tutorial(delta: float) -> void:
	_tutorial_wait -= delta
	while _tutorial_wait <= 0.0 and not _tutorial_items.is_empty():
		_do_tutorial(_tutorial_items.pop_front())


func _do_tutorial(item: TutorialChat.Item) -> void:
	match item.command:
		TutorialChat.Command.LINE:
			_tutorial_line(_tutorial_friend, item.value, false)
		TutorialChat.Command.STATIC_LINE:
			_tutorial_line(_tutorial_friend, item.value, true)
		TutorialChat.Command.DEMO_LINE:
			_tutorial_line(_demo_friend, item.value, false)
		TutorialChat.Command.FOCUS:
			tutorial_focus = item.value
		TutorialChat.Command.UNLOCK:
			if not _unlocked.has(item.value):
				_unlocked.append(item.value)
		TutorialChat.Command.SEND_VIDEO:
			state.videos.add_extra(_tutorial_friend, _elapsed)
		TutorialChat.Command.START_DEMO:
			_start_demo()
		TutorialChat.Command.DEMO_HURT:
			var friend := state.friends[_demo_friend]
			var friend_name := tr(catalog.friends[_demo_friend].name_key)
			# Sin efecto: el aviso muestra un punto menos, pero la vida no cambia (decisión de Benja, D6).
			message_added.emit(_demo_friend, MessageBuilder.damage_notice(null, friend_name, friend.health - 1,
					friend.max_health, tr))
		TutorialChat.Command.SET_SIGNAL:
			state.friends[_tutorial_friend].signal_level = item.value
		TutorialChat.Command.CUT_SIGNAL:
			state.friends[_tutorial_friend].signal_level = 0.0
		TutorialChat.Command.OPEN_GUIDE_CHAT:
			tutorial_chat_requested.emit(_tutorial_friend)
		TutorialChat.Command.PAUSE:
			_tutorial_wait = item.value
		TutorialChat.Command.FINISH:
			tutorial_finished.emit()


## Una línea del tutorial en el chat de `friend_index`. Sin estática al azar, para que se lea; la de `fixed_static`, con
## una de cada 3 palabras tapadas, siempre igual (docs/26 §4.3).
func _tutorial_line(friend_index: int, key: String, fixed_static: bool) -> void:
	var message := MessageBuilder.line(ChatMessage.Sender.FRIEND, key, tr)
	if fixed_static:
		ChatStatic.apply_fixed(message)
	message_added.emit(friend_index, message)
	_tutorial_wait = tr(key).length() / TUTORIAL_CHARS_PER_SECOND + TUTORIAL_LINE_PAUSE


## Llega la solicitud de la demostración (la siguiente fija), con su tiempo en espera hasta que se abra su chat. El
## amigo pide ayuda con su línea, sin el mensaje inicial de siempre.
func _start_demo() -> void:
	if tutorial_queue.is_empty():
		return
	var data: TutorialRequestData = tutorial_queue.pop_front()
	var request := RequestGenerator.generate_tutorial(catalog, night(), data, rng)
	request.time_left = data.demo_seconds
	requests[request.friend_index] = request
	_demo_friend = request.friend_index
	request_started.emit(request.friend_index, request)
	_tutorial_line(_demo_friend, TutorialChat.GONZALO_HELP_KEY, false)


## Se le acabó el tiempo a la demostración: la solicitud termina sin consecuencias, y el tutorial cuenta qué pasó.
func _end_demo(friend_index: int) -> void:
	var request := requests[friend_index]
	request.finished = true
	requests[friend_index] = null
	request_finished.emit(friend_index, request)
	_tutorial(tutorial_chat.demo_timed_out())
