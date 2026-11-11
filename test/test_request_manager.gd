extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")


## Manager con el catálogo de prueba (u otro), en la noche 1 (solo "beast"), sin que las solicitudes lleguen
## solas.
func _make_manager(catalog: ContentCatalog = null) -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = catalog if catalog != null else Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## Guarda en `events` cada señal del manager, como [nombre, amigo, mensaje o solicitud].
func _record(manager: RequestManager, events: Array) -> void:
	for signal_name: String in ["message_added", "request_started", "request_changed", "request_finished"]:
		manager.connect(signal_name, func(friend_index: int, item: RefCounted) -> void:
			events.append([signal_name, friend_index, item]))


func _messages(events: Array) -> Array:
	return events.filter(func(entry: Array) -> bool: return entry[0] == "message_added") \
			.map(func(entry: Array) -> ChatMessage: return entry[2])


func test_empieza_sin_solicitudes() -> bool:
	var manager := _make_manager()
	check_eq(manager.requests, [null, null, null], "sin solicitudes")
	check_eq(manager.state.friends.map(func(friend: FriendState) -> float: return friend.signal_level),
			[100.0, 100.0, 100.0], "señal llena")
	check_eq(manager.state.trust, 100.0, "Trust lleno")
	check_eq(manager.active_count(), 0, "activas")
	manager.free()
	return true


func test_una_solicitud_llega_con_su_mensaje() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(1)
	check(request != null, "se crea")
	check_eq(manager.requests[1], request, "es la de Gonzalo")
	check_eq(request.time_left, 45.0, "tiempo base de la noche 1")
	check_eq(events.size(), 2, "dos señales")
	if events.size() == 2:
		check_eq(events[0], ["request_started", 1, request], "empezó")
		var message: ChatMessage = events[1][2]
		check_eq(events[1][0], "message_added", "mensaje")
		check_eq(message.request, request, "el mensaje es de la solicitud")
		check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo envía el amigo")
	check_eq(manager.start_request(1), null, "un amigo no recibe dos solicitudes a la vez")
	manager.free()
	return true


func test_preguntar_agrega_2_mensajes_y_cuesta_5_segundos() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	check(manager.ask(0, ClueCategory.Kind.SIGHT), "se pudo preguntar")
	var messages := _messages(events)
	check_eq(messages.size(), 2, "pregunta y respuesta")
	if messages.size() == 2:
		check_eq((messages[0] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "pregunta de Matías")
		check_eq((messages[1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "respuesta del amigo")
	check_eq(request.time_left, 40.0, "costó 5 s")
	check(not manager.ask(1, ClueCategory.Kind.SIGHT), "sin solicitud no se pregunta")
	manager.free()
	return true


func test_clic_en_las_caracteristicas_hasta_el_nombre() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(0)
	var message: ChatMessage = _messages(events)[0]
	events.clear()
	for trait_data: TraitData in request.traits:
		check_eq(manager.click_clue(message, trait_data.id), FriendRequest.ClueState.MARKED, "marca %s" % trait_data.id)
	check_eq(request.identification, FriendRequest.Identification.THINKING, "Matías piensa")
	check_eq(events.size(), 2, "un aviso por clic")
	events.clear()
	manager.advance(3.1)
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "apareció el nombre")
	check_eq(events, [["request_changed", 0, request]], "aviso del nombre")
	manager.free()
	return true


func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var manager := _make_manager()
	# Sin heridas: si quedara herido, llegaría además el aviso de daño.
	manager.catalog.balance.risky_hurt_chance = 0.0
	manager.catalog.balance.wrong_hurt_chance = 0.0
	var request := manager.start_request(2)
	var events := []
	_record(manager, events)
	manager.advance(request.time_left + 0.1)
	check_eq(manager.requests[2], null, "Agustín queda libre")
	check(request.finished and not request.answered_by_player, "decidió solo")
	check_eq(events.size(), 3, "lo que hizo, cómo le fue y fin")
	if events.size() == 3:
		check_eq(events[0][0], "message_added", "cuenta lo que hizo")
		check_eq(events[1][0], "message_added", "cuenta cómo le fue")
		check_eq(events[2], ["request_finished", 2, request], "terminó")
	check_eq(manager.click_clue(_messages(events)[0], request.traits[0].id), FriendRequest.ClueState.UNMARKED,
			"los mensajes de una solicitud terminada ya no se clickean")
	manager.free()
	return true


func test_responder_termina_la_solicitud() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	check(manager.answer(0, request.entity.find_action(rule.correct_action_id)), "se pudo responder")
	check(request.finished and request.answered_by_player, "respondió Matías")
	check_eq(request.outcome, RuleEvaluator.Outcome.CORRECT, "la acción correcta")
	check_eq(manager.requests[0], null, "León queda libre")
	check_eq(events.size(), 3, "respuesta, reacción y fin")
	if events.size() == 3:
		check_eq((events[0][2] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "responde Matías")
		check_eq((events[1][2] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "reacciona el amigo")
		check_eq(events[2], ["request_finished", 0, request], "terminó")
	check(not manager.answer(0, request.entity.actions[0]), "ya no espera respuesta")
	manager.free()
	return true


func test_responder_desde_otra_pagina_es_incorrecto() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(1)
	var other := Fixtures.make_entity(&"ghost")
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(1, other.find_action(rule.correct_action_id))
	check_eq(request.outcome, RuleEvaluator.Outcome.WRONG, "la misma acción, pero de otra página")
	manager.free()
	return true


## El primer minuto es de silencio, y después las solicitudes de una ola llegan juntas (decisión de Benja, 11 de
## noviembre).
func test_las_solicitudes_llegan_solas() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].max_simultaneous = 3
	catalog.nights[0].wave_size = 2
	var manager := _make_manager(catalog)
	manager.requests_arrive = true
	for _step in 599:
		manager.advance(0.1)
	check_eq(manager.active_count(), 0, "a los 59,9 s todavía no")
	manager.advance(0.2)
	check_eq(manager.active_count(), 1, "a los 60 s llega la primera")
	for _step in 85:
		manager.advance(0.1)
	check_eq(manager.active_count(), 2, "la segunda de la ola llega a los pocos segundos")
	manager.free()
	return true


func test_no_pasa_de_las_simultaneas() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	manager.advance(60.0)
	check_eq(manager.active_count(), 1, "llega la primera")
	for request: FriendRequest in manager.requests:
		if request != null:
			request.time_left = 1000.0
	for _step in 20:
		manager.advance(1.0)
	check_eq(manager.active_count(), 1, "la noche 1 del catálogo de prueba tiene 1 simultánea: la segunda espera")
	manager.free()
	return true


func test_no_pasa_del_total() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].requests_total = 2
	# Sin heridas: un amigo herido atrasaría la segunda hasta que ya no alcanza a terminar.
	catalog.balance.risky_hurt_chance = 0.0
	catalog.balance.wrong_hurt_chance = 0.0
	var manager := _make_manager(catalog)
	manager.requests_arrive = true
	var started := []
	manager.request_started.connect(func(friend_index: int, _request: FriendRequest) -> void:
		started.append(friend_index))
	for _i in 420:
		manager.advance(1.0)
	check_eq(started.size(), 2, "2 solicitudes en la noche")
	manager.free()
	return true


func test_un_amigo_herido_atrasa_las_solicitudes() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var planned := manager.director.next_at
	var request := manager.start_request(0)
	manager.answer(0, _wrong_action(request))
	check(request.consequence.is_hurt(), "quedó herido")
	check_eq(manager.director.next_at, planned + 10.0, "lo que falta, 10 s más tarde")
	manager.free()
	return true


## Las olas traen interferencias y las calmas, videos (decisión de Benja, 11 de noviembre): el manager se los da a
## amigos al azar.
func test_las_olas_traen_interferencias_y_las_calmas_videos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].interference_count = 2
	catalog.nights[0].content_quota = 1
	catalog.nights[0].max_simultaneous = 3
	catalog.nights[0].wave_size = 2
	# Una ola de 2 y la final: una interferencia en cada una.
	catalog.nights[0].requests_total = 5
	var manager := _make_manager(catalog)
	manager.requests_arrive = true
	manager.advance(60.5)
	check_eq(manager.state.interferences.pending.size(), 1, "la primera ola trae su interferencia")
	if manager.state.interferences.pending.size() == 1:
		var time: float = manager.state.interferences.pending[0].time
		check(time >= 63.0 and time <= 76.0, "unos segundos después de empezar la ola: %s" % time)
	check_eq(manager.state.videos.unreleased, 1, "el video espera la calma")
	for _step in 120:
		manager.advance(1.0)
	check_eq(manager.state.videos.unreleased, 0, "la calma lo soltó")
	manager.free()
	return true


## Con "Temporizadores ×1,5", una solicitud nunca pasa de las 06:00.
func test_con_temporizadores_lentos_no_pasa_de_las_06() -> bool:
	var manager := _make_manager()
	manager.timer_scale = 1.5
	manager.advance(400.0)
	var request := manager.start_request(0)
	check_eq(request.time_left, 20.0, "le quedan 20 s a la noche")
	manager.free()
	return true


func test_la_estatica_depende_de_la_senal() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	manager.state.friends[0].signal_level = 100.0
	manager.state.friends[1].signal_level = 1.0
	# Sin heridas: un amigo aturdido o muerto no recibiría más solicitudes.
	manager.catalog.balance.risky_hurt_chance = 0.0
	manager.catalog.balance.wrong_hurt_chance = 0.0
	for _i in 10:
		manager.start_request(0)
		manager.start_request(1)
		manager.advance(60.0)
	var covered := [0, 0]
	for entry: Array in events:
		if entry[0] == "message_added":
			for token: ChatMessage.Token in (entry[2] as ChatMessage).tokens:
				if token.covered:
					covered[entry[1]] += 1
	check_eq(covered[0], 0, "con señal 100 no hay estática")
	check(covered[1] > 0, "con señal 1 hay estática")
	manager.free()
	return true


## Una acción incorrecta para la situación de `request`: ni la correcta ni la de mayor riesgo.
func _wrong_action(request: FriendRequest) -> ActionData:
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	for action: ActionData in request.entity.actions:
		if action.id != rule.correct_action_id and action.id != rule.risky_action_id:
			return action
	return null


func test_responder_aplica_la_consecuencia() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	manager.answer(0, _wrong_action(request))
	check(request.consequence != null and request.consequence.is_hurt(), "quedó herido")
	check_eq(manager.state.friends[0].health, 2, "León pierde 1 PV")
	check(not manager.state.is_available(0), "y queda aturdido")
	check_eq(manager.state.trust, 85.0, "Trust −15")
	var messages := _messages(events)
	check_eq(messages.size(), 3, "la respuesta, la reacción y el aviso de daño")
	if messages.size() == 3:
		check_eq((messages[1] as ChatMessage).plain_text(), String(TranslationServer.translate("REACTION_WRONG_HURT")),
				"cuenta que quedó herido")
		var notice := messages[2] as ChatMessage
		var friend: FriendData = manager.catalog.friends[0]
		check_eq(notice.sender, ChatMessage.Sender.SYSTEM, "el aviso lo escribe el juego")
		check_eq(notice.plain_text(), String(TranslationServer.translate("CHAT_DAMAGE")).format(
				{"friend": String(TranslationServer.translate(friend.name_key)), "health": 2, "max": 3}),
				"con la vida que le queda")
	manager.free()
	return true


func test_un_amigo_aturdido_o_muerto_no_recibe_solicitudes() -> bool:
	var manager := _make_manager()
	manager.state.friends[0].hurt(1, 15.0)
	check_eq(manager.start_request(0), null, "León está aturdido")
	manager.state.friends[1].hurt(3, 15.0)
	check_eq(manager.start_request(1), null, "Gonzalo está muerto")
	manager.requests_arrive = true
	manager.advance(60.1)
	check(manager.requests[2] != null, "la solicitud le llega a Agustín")
	manager.free()
	return true


func test_con_trust_bajo_hay_menos_tiempo() -> bool:
	var manager := _make_manager()
	manager.state.trust = 50.0
	var request := manager.start_request(0)
	check(is_equal_approx(request.time_left, 36.0), "45 s × (0,6 + 0,4 × 0,5): %s" % request.time_left)
	manager.free()
	return true


func test_sin_respuesta_trust_baja_ademas() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	manager.advance(request.time_left + 0.1)
	check(request.consequence != null, "se resolvió igual")
	if request.consequence != null:
		check(request.consequence.trust_change <= -15.0, "−15 por no contestar, además de lo que eligió")
		check_eq(manager.state.trust, 100.0 + request.consequence.trust_change, "se aplicó")
	manager.free()
	return true


func test_si_decide_solo_y_queda_herido_tambien_hay_aviso() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.risky_hurt_chance = 1.0
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var request := manager.start_request(2)
	var events := []
	_record(manager, events)
	manager.advance(request.time_left + 0.1)
	var messages := _messages(events)
	var hurt := request.consequence.is_hurt()
	check_eq(messages.size(), 3 if hurt else 2, "lo que hizo, cómo le fue y, si quedó herido, el aviso")
	if not messages.is_empty():
		check_eq((messages[-1] as ChatMessage).sender == ChatMessage.Sender.SYSTEM, hurt, "el aviso, solo si quedó herido")
	manager.free()
	return true


func test_sin_senal_el_mensaje_llega_tapado_entero() -> bool:
	var manager := _make_manager()
	manager.state.friends[1].signal_level = 0.0
	var events := []
	_record(manager, events)
	manager.start_request(1)
	var message: ChatMessage = _messages(events)[0]
	for token: ChatMessage.Token in message.tokens:
		check(token.covered or not token.can_be_covered(), "tapado: %s" % token.text)
	manager.free()
	return true


func test_sin_senal_no_lee_preguntas_ni_respuestas() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	manager.state.friends[0].signal_level = 0.0
	check(not manager.ask(0, ClueCategory.Kind.SIGHT), "no puede preguntar")
	check(not manager.answer(0, request.entity.actions[0]), "no puede responder")
	check_eq(manager.requests[0], request, "la solicitud sigue esperando")
	manager.state.friends[0].restore_signal()
	check(manager.answer(0, request.entity.actions[0]), "reconectado, responde normal")
	manager.free()
	return true


func test_sin_senal_decide_mal_sin_bajar_trust() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	manager.state.friends[2].signal_level = 0.0
	manager.advance(request.time_left + 0.1)
	check(request.finished and request.decided_offline, "decidió solo, sin señal")
	check(request.outcome != RuleEvaluator.Outcome.CORRECT, "eligió mal")
	check_eq(manager.state.trust, 100.0, "su decisión no bajó Trust")
	manager.free()
	return true


## El texto de `key` en ui.csv, con sus datos.
func _ui(key: String, values: Dictionary) -> String:
	return String(TranslationServer.translate(key)).format(values)


func test_avisa_en_el_chat_los_videos_y_la_senal() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var night_events := NightState.Events.new()
	night_events.videos = VideoSchedule.Changes.new()
	night_events.disconnected.append(0)
	night_events.videos.offered.append(1)
	night_events.videos.received.append(2)
	night_events.videos.lost.append(1)
	manager.state.videos.received = 1
	manager.report(night_events)
	check_eq(events.map(func(entry: Array) -> int: return entry[1]), [0, 1, 2, 1], "cada aviso en el chat de su amigo")
	var messages := _messages(events)
	if messages.size() == 4:
		check_eq((messages[0] as ChatMessage).plain_text(), _ui("CHAT_SIGNAL_LOST", {"friend": "K_FRIEND_leon"}),
				"León se quedó sin señal")
		check_eq((messages[0] as ChatMessage).tone, ChatMessage.Tone.DANGER, "en rojo")
		check_eq((messages[1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "Gonzalo avisa que mandó un video")
		check_eq((messages[2] as ChatMessage).plain_text(),
				_ui("CHAT_VIDEO_RECEIVED", {"friend": "K_FRIEND_agustin", "received": 1, "quota": 2}), "con la cuota")
		check_eq((messages[2] as ChatMessage).tone, ChatMessage.Tone.GOOD, "el video recibido, en verde")
		check_eq((messages[3] as ChatMessage).plain_text(), _ui("CHAT_VIDEO_LOST", {"friend": "K_FRIEND_gonzalo"}),
				"el de Gonzalo se perdió")
		check_eq((messages[3] as ChatMessage).tone, ChatMessage.Tone.DANGER, "en rojo")
	manager.free()
	return true


## Cuando un video se pierde y los que quedan ya no alcanzan la cuota, el chat avisa que alguien tiene que arriesgarse
## (decisión de Benja, 11 de noviembre). Una vez por cada video perdido.
func test_avisa_cuando_los_videos_no_alcanzan() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var night_events := NightState.Events.new()
	night_events.videos = VideoSchedule.Changes.new()
	night_events.videos.lost.append(1)
	manager.report(night_events)
	check_eq(_messages(events).size(), 1, "si todavía alcanzan, solo el aviso del video perdido")
	events.clear()
	manager.state.videos.unreleased -= 1
	manager.report(night_events)
	var messages := _messages(events)
	check_eq(messages.size(), 2, "el video perdido y que ya no alcanzan")
	if messages.size() == 2:
		check_eq(events[1][1], 1, "en el chat de Gonzalo")
		check_eq((messages[1] as ChatMessage).plain_text(), _ui("CHAT_VIDEOS_SHORT", {"received": 0, "quota": 2}),
				"alguien tiene que arriesgarse")
		check_eq((messages[1] as ChatMessage).tone, ChatMessage.Tone.DANGER, "en rojo")
	check(tr("CHAT_VIDEOS_SHORT") != "CHAT_VIDEOS_SHORT", "el texto existe")
	manager.free()
	return true


func test_restaurar_la_senal_avisa_si_estaba_desconectado() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	manager.restore_signal(1)
	check(events.is_empty(), "si tenía señal, no hay aviso")
	manager.state.friends[1].signal_level = 0.0
	manager.restore_signal(1)
	check_eq(manager.state.friends[1].signal_level, 100.0, "señal al 100")
	var messages := _messages(events)
	check_eq(messages.size(), 1, "avisa que volvió")
	if messages.size() == 1:
		check_eq((messages[0] as ChatMessage).plain_text(), _ui("CHAT_SIGNAL_BACK", {"friend": "K_FRIEND_gonzalo"}),
				"Gonzalo volvió")
		check_eq((messages[0] as ChatMessage).tone, ChatMessage.Tone.GOOD, "en verde")
	manager.free()
	return true


## Decisión de Benja (3-nov): el amigo no cuenta nada de entrada. Sin pista, el mensaje inicial no trae frases
## clickeables ni observaciones; las características, los señuelos y las observaciones salen al preguntar.
func test_la_entidad_se_identifica_preguntando() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].first_hint_chance = 0.0
	var manager := _make_manager(catalog)
	var events := []
	_record(manager, events)
	var request := manager.start_request(0)
	var first: ChatMessage = _messages(events)[0]
	check_eq(first.plain_text(), "%s %s %s" % [TranslationServer.translate("K_CALL_1"), TranslationServer.translate("K_LOST"),
			TranslationServer.translate(request.place_key)], "solo el saludo, lo que le pasa y el lugar")
	events.clear()
	for category: ClueCategory.Kind in [ClueCategory.Kind.SIGHT, ClueCategory.Kind.SOUND]:
		check(manager.ask(0, category), "se puede preguntar %s" % category)
	var answers := " ".join(_messages(events).map(func(message: ChatMessage) -> String: return message.plain_text()))
	for trait_data: TraitData in request.traits:
		check(answers.contains("K_TRAIT_%s" % trait_data.id), "preguntando sale la característica %s" % trait_data.id)
	check_eq(request.time_left, 45.0 - 2.0 * 5.0, "cada pregunta costó 5 s")
	manager.free()
	return true


## El tutorial del catálogo de prueba (noche 0), con las solicitudes llegando solas.
func _make_tutorial_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 0
	manager.random_seed = 7
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## La acción correcta de la solicitud de `friend_index`.
func _correct_action(manager: RequestManager, friend_index: int) -> ActionData:
	var request := manager.requests[friend_index]
	return request.entity.find_action(RuleEvaluator.applicable_rule(request.entity, request.situation).correct_action_id)


## Avanza `seconds` de a 0,5 s.
func _run(manager: RequestManager, seconds: float) -> void:
	for _step in roundi(seconds * 2.0):
		manager.advance(0.5)


## Avanza `seconds` de a 0,5 s el manager y el estado de la noche, como NightManager.
func _run_night(manager: RequestManager, seconds: float) -> void:
	for _step in roundi(seconds * 2.0):
		manager.report(manager.state.advance(0.5))
		manager.advance(0.5)


## Los textos de los mensajes de León en `events`.
func _leon_lines(events: Array) -> Array:
	return _messages(events).filter(func(message: ChatMessage) -> bool: return message.sender == ChatMessage.Sender.FRIEND) \
			.map(func(message: ChatMessage) -> String: return message.plain_text())


func _line(key: String) -> String:
	return String(TranslationServer.translate(key))


## En el tutorial, León enseña en su chat (decisión de Benja, 11 de noviembre): su solicitud llega sin mensaje inicial y
## él escribe sus líneas de a una.
func test_en_el_tutorial_leon_escribe() -> bool:
	var manager := _make_tutorial_manager()
	var events := []
	_record(manager, events)
	manager.advance(4.9)
	check_eq(manager.active_count(), 0, "a los 4,9 s todavía no")
	manager.advance(0.2)
	var request := manager.requests[0]
	check(request != null and request.timer_paused, "la de León, con el temporizador en espera")
	check_eq(_leon_lines(events), [_line(TutorialChat.HELLO_KEY)], "saluda, sin el mensaje inicial de siempre")
	_run(manager, 6.0)
	check_eq(_leon_lines(events), [_line(TutorialChat.HELLO_KEY), _line(TutorialChat.GUESS_KEY)],
			"la segunda línea, después de la primera")
	manager.free()
	return true


## Hasta la mejor decisión y la peor: una respuesta que no cuenta no termina la solicitud, y nadie sale herido.
func test_en_el_tutorial_una_respuesta_que_no_cuenta() -> bool:
	var manager := _make_tutorial_manager()
	manager.advance(5.1)
	var request := manager.requests[0]
	manager.ask(0, ClueCategory.Kind.SIGHT)
	for trait_data: TraitData in request.traits:
		request.click_clue(trait_data.id)
	manager.tutorial_page_opened()
	_run(manager, 4.0)
	check_eq(manager.tutorial_chat.step, TutorialChat.Step.BEST, "León pide la mejor")
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	var wrong: ActionData = request.entity.actions.filter(func(action: ActionData) -> bool:
		return action.id != rule.correct_action_id and action.id != rule.risky_action_id)[0]
	var events := []
	_record(manager, events)
	manager.answer(0, wrong)
	check(manager.requests[0] == request and not request.finished, "una incorrecta no cuenta: sigue abierta")
	check_eq(_messages(events)[0].sender, ChatMessage.Sender.PLAYER, "se ve la respuesta de Matías")
	_run(manager, 20.0)
	check(_leon_lines(events).has(_line(TutorialChat.RETRY_KEY)), "León pide intentarlo de nuevo")
	manager.answer(0, request.entity.find_action(rule.correct_action_id))
	check(manager.requests[0] == request, "la mejor tampoco termina: ahora pide la peor")
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	check(manager.requests[0] == null and request.finished, "la peor termina la solicitud")
	check_eq(manager.state.friends[0].health, 3, "León sigue entero")
	check_eq(manager.state.trust, 100.0, "Trust igual")
	manager.free()
	return true


## Después de la peor, León manda el video; al descargarlo se le corta la señal y, al sincronizarlo, se despide.
func test_en_el_tutorial_el_video_y_la_senal() -> bool:
	var manager := _make_tutorial_manager()
	var finished := []
	manager.tutorial_finished.connect(func() -> void: finished.append(true))
	manager.advance(5.1)
	var request := manager.requests[0]
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	for trait_data: TraitData in request.traits:
		request.click_clue(trait_data.id)
	manager.tutorial_page_opened()
	_run(manager, 4.0)
	manager.answer(0, request.entity.find_action(rule.correct_action_id))
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	_run_night(manager, 30.0)
	check_eq(manager.state.videos.offers.size(), 1, "León mandó su video")
	manager.state.holding_download = 0
	_run_night(manager, 11.0)
	manager.state.holding_download = -1
	check_eq(manager.state.videos.received, 1, "descargado")
	_run_night(manager, 20.0)
	check(not manager.state.friends[0].is_online(), "a León se le cortó la señal")
	check(finished.is_empty(), "todavía no termina")
	manager.restore_signal(0)
	_run_night(manager, 15.0)
	check_eq(finished.size(), 1, "al volver la señal, se despide y termina")
	manager.free()
	return true


## El susto guionado espera las solicitudes fijas del tutorial que faltan.
func test_en_el_tutorial_lo_pendiente_hace_esperar_al_susto() -> bool:
	var manager := _make_tutorial_manager()
	check_eq(manager.pending_count(), 1, "al empezar falta la de León")
	manager.advance(5.1)
	check_eq(manager.pending_count(), 1, "llegó: ahora es una solicitud activa")
	manager.free()
	return true


## En una noche normal, lo pendiente son las solicitudes activas.
func test_lo_pendiente_en_una_noche_normal() -> bool:
	var manager := _make_manager()
	check_eq(manager.pending_count(), 0, "nada")
	manager.start_request(2)
	check_eq(manager.pending_count(), 1, "una solicitud")
	manager.free()
	return true


## La opción "Temporizadores ×1,5" (diseño §19) alarga el tiempo para responder (decisión de Benja: solo ese).
func test_temporizadores_mas_largos() -> bool:
	var manager := _make_manager()
	manager.timer_scale = 1.5
	var request := manager.start_request(0)
	check_eq(request.time_left, 67.5, "45 s × 1,5")
	manager.free()
	return true


## Una solicitud que espera más de 30 s hace bajar Trust; con "Temporizadores ×1,5", el plazo es de 45 s
## (decisión de Benja, 4 de noviembre).
func test_solicitudes_que_esperan_demasiado() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	check_eq(manager.impatient_count(), 0, "recién llegó")
	request.open_seconds = 31.0
	check_eq(manager.impatient_count(), 1, "lleva más de 30 s")
	manager.timer_scale = 1.5
	check_eq(manager.impatient_count(), 0, "con ×1,5, el plazo es de 45 s")
	manager.timer_scale = 1.0
	manager.state.friends[2].signal_level = 0.0
	check_eq(manager.impatient_count(), 0, "sin señal ya baja Trust por eso")
	manager.free()
	return true


## Manager de la noche 1 con un accidente en el catálogo.
func _make_incident_manager() -> RequestManager:
	var catalog := Fixtures.make_catalog()
	catalog.incidents.append(Fixtures.make_incident())
	return _make_manager(catalog)


## La opción correcta o una incorrecta del accidente del amigo `friend_index`.
func _option(manager: RequestManager, friend_index: int, correct: bool) -> int:
	var incident: RefCounted = manager.incidents[friend_index]
	for index in incident.options.size():
		if incident.is_correct(index) == correct:
			return index
	return -1


func test_un_accidente_llega_al_chat() -> bool:
	var manager := _make_incident_manager()
	var events := []
	_record(manager, events)
	var incident: RefCounted = manager.start_incident(1)
	check(incident != null, "empezó")
	check_eq(manager.incidents[1], incident, "es del amigo")
	check_eq(incident.time_left, 15.0, "15 s")
	check_eq(events.size(), 1, "un mensaje")
	if events.size() == 1:
		check_eq(events[0][0], "message_added", "del amigo")
		check_eq(events[0][2].sender, ChatMessage.Sender.FRIEND, "lo escribe el amigo")
	manager.free()
	return true


func test_la_buena_idea_lo_salva() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	check(manager.answer_incident(0, _option(manager, 0, true)), "respondió")
	check_eq(manager.incidents[0], null, "terminó")
	check_eq(manager.state.friends[0].health, 3, "no perdió vida")
	check(not manager.state.friends[0].is_stunned(), "ni quedó aturdido")
	manager.free()
	return true


func test_una_mala_idea_lo_hiere() -> bool:
	var manager := _make_incident_manager()
	var events := []
	manager.start_incident(0)
	_record(manager, events)
	manager.answer_incident(0, _option(manager, 0, false))
	check_eq(manager.state.friends[0].health, 2, "−1 PV")
	check(manager.state.friends[0].is_stunned(), "aturdido")
	check_eq(manager.state.trust, 100.0, "un accidente no baja Trust")
	var senders := events.map(func(event: Array) -> ChatMessage.Sender: return event[2].sender)
	check_eq(senders, [ChatMessage.Sender.PLAYER, ChatMessage.Sender.FRIEND, ChatMessage.Sender.SYSTEM],
			"Matías, el amigo y el aviso de daño")
	manager.free()
	return true


func test_si_nadie_responde_lo_hiere() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	manager.advance(16.0)
	check_eq(manager.incidents[0], null, "terminó")
	check_eq(manager.state.friends[0].health, 2, "−1 PV")
	manager.free()
	return true


## Con la opción "Temporizadores ×1,5", también hay más tiempo para responder un accidente.
func test_un_accidente_con_temporizadores_lentos() -> bool:
	var manager := _make_incident_manager()
	manager.timer_scale = 1.5
	check_eq(manager.start_incident(0).time_left, 22.5, "22,5 s")
	manager.free()
	return true


func test_un_amigo_ocupado_no_tiene_accidentes() -> bool:
	var manager := _make_incident_manager()
	manager.start_request(0)
	check_eq(manager.start_incident(0), null, "con una solicitud, no")
	check(manager.start_incident(1) != null, "otro amigo, sí")
	check_eq(manager.start_request(1), null, "y con un accidente, no le llegan solicitudes")
	manager.state.friends[2].health = 1
	check_eq(manager.start_incident(2), null, "un accidente nunca lo mata: con 1 PV no tiene")
	manager.free()
	return true


func test_sin_senal_no_responde() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	manager.state.friends[0].signal_level = 0.0
	check(not manager.answer_incident(0, 0), "no lee la respuesta")
	check(manager.incidents[0] != null, "sigue esperando")
	manager.free()
	return true


## El director reparte los accidentes, y uno llega solo si hay espacio: no se suman a una ola llena.
func test_llegan_a_su_hora_si_hay_espacio() -> bool:
	var manager := _make_incident_manager()
	manager.requests_arrive = true
	manager.director.waves.clear()
	manager.director.incident_times.assign([10.0])
	manager.night().max_simultaneous = 1
	manager.start_request(0)
	manager.advance(11.0)
	check(manager.incidents.all(func(incident: RefCounted) -> bool: return incident == null), "con la ola llena, espera")
	manager.answer(0, manager.requests[0].entity.actions[0])
	manager.advance(1.0)
	check_eq(manager.incidents.count(null), 2, "al desocuparse, llega")
	manager.free()
	return true
