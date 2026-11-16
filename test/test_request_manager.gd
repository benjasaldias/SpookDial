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
const PacingDirector := preload("res://scripts/core/pacing_director.gd")


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
	catalog.nights()[0].max_simultaneous = 3
	catalog.nights()[0].wave_size = 2
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
	catalog.nights()[0].requests_total = 2
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
	catalog.nights()[0].interference_count = 2
	catalog.nights()[0].content_quota = 1
	catalog.nights()[0].max_simultaneous = 3
	catalog.nights()[0].wave_size = 2
	# Una ola de 2 y la final: una interferencia en cada una.
	catalog.nights()[0].requests_total = 5
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


## Con "Temporizadores ×1,5", una solicitud dura 1,5 veces, también tarde en la noche: ya no hay hora de término (Plan
## 9.9).
func test_con_temporizadores_lentos_la_consulta_dura_mas() -> bool:
	var manager := _make_manager()
	manager.timer_scale = 1.5
	manager.advance(400.0)
	var request := manager.start_request(0)
	check_eq(request.time_left, 67.5, "45 s × 1,5")
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
	catalog.nights()[0].first_hint_chance = 0.0
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


## Avanza el tutorial hasta que León termine lo pendiente, como mucho `seconds` segundos.
func _until_idle(manager: RequestManager, seconds := 40.0) -> void:
	for _step in roundi(seconds * 2.0):
		if not manager.tutorial_busy():
			return
		_run_night(manager, 0.5)


## Un clic en la frase `clue_id` de la solicitud del amigo `friend_index`, como desde su mensaje.
func _click(manager: RequestManager, friend_index: int, clue_id: StringName) -> void:
	manager.click_clue(ChatMessage.new(ChatMessage.Sender.FRIEND, manager.requests[friend_index]), clue_id)


## Lleva el tutorial hasta la mejor decisión, haciendo lo que pide León en cada paso.
func _tutorial_until_best(manager: RequestManager) -> FriendRequest:
	_run_night(manager, 5.5)
	var request := manager.requests[0]
	manager.ask(0, ClueCategory.Kind.SIGHT)
	_click(manager, 0, request.traits[0].id)
	manager.ask(0, ClueCategory.Kind.SOUND)
	manager.tutorial_audio_played(0, Fixtures.make_audio(1.0))
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	_click(manager, 0, request.traits[1].id)
	_run_night(manager, 3.0)
	manager.tutorial_page_opened()
	_until_idle(manager)
	return request


## Lleva el tutorial hasta que Gonzalo pide ayuda: la mejor, la peor y el video descargado.
func _tutorial_until_demo(manager: RequestManager) -> void:
	var request := _tutorial_until_best(manager)
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(0, request.entity.find_action(rule.correct_action_id))
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	_run_night(manager, 30.0)
	manager.state.holding_download = 0
	_run_night(manager, 11.0)
	manager.state.holding_download = -1
	_run_night(manager, 15.0)


## Lo que hay que apretar se puede usar cuando León terminó de escribir, y nada del escritorio está desbloqueado al
## empezar (Plan 9.5).
func test_en_el_tutorial_el_foco_llega_cuando_leon_termina() -> bool:
	var manager := _make_tutorial_manager()
	manager.advance(5.1)
	check(manager.tutorial_busy(), "León escribe")
	check(not manager.tutorial_wants(TutorialChat.Focus.ASK_SIGHT), "todavía no se puede preguntar")
	_until_idle(manager)
	check(manager.tutorial_wants(TutorialChat.Focus.ASK_SIGHT), "terminó: «¿Qué ves?»")
	check(not manager.tutorial_wants(TutorialChat.Focus.ASK_SOUND), "solo esa")
	check(manager.is_tutorial(), "es el tutorial")
	check(not manager.is_unlocked(TutorialChat.Unlock.NOTEBOOK), "el cuaderno, bloqueado")
	check(manager.is_friend_unlocked(0), "León sí")
	check(not manager.is_friend_unlocked(1), "Gonzalo no")
	check(not manager.is_friend_unlocked(2), "Agustín no")
	manager.free()
	return true


## Fuera del tutorial no hay foco ni bloqueos.
func test_fuera_del_tutorial_todo_se_usa() -> bool:
	var manager := _make_manager()
	check(not manager.is_tutorial(), "no es el tutorial")
	check(manager.is_unlocked(TutorialChat.Unlock.NOTEBOOK), "el cuaderno")
	check(manager.is_friend_unlocked(2), "Agustín")
	manager.free()
	return true


## El audio: León espera a que termine antes de comentarlo.
func test_en_el_tutorial_leon_espera_el_audio() -> bool:
	var manager := _make_tutorial_manager()
	manager.advance(5.1)
	var request := manager.requests[0]
	manager.ask(0, ClueCategory.Kind.SIGHT)
	_click(manager, 0, request.traits[0].id)
	manager.ask(0, ClueCategory.Kind.SOUND)
	_until_idle(manager)
	var events := []
	_record(manager, events)
	manager.tutorial_audio_played(0, Fixtures.make_audio(3.0))
	_run(manager, 3.0)
	check(not _leon_lines(events).has(_line(TutorialChat.HEARD_KEY)), "mientras suena, nada")
	_run(manager, 1.0)
	check(_leon_lines(events).has(_line(TutorialChat.HEARD_KEY)), "después lo comenta")
	manager.free()
	return true


## Hasta la mejor decisión y la peor: una respuesta que no cuenta no termina la solicitud, y nadie sale herido.
func test_en_el_tutorial_una_respuesta_que_no_cuenta() -> bool:
	var manager := _make_tutorial_manager()
	var request := _tutorial_until_best(manager)
	check_eq(manager.tutorial_chat.step, TutorialChat.Step.BEST, "León pide la mejor")
	check(manager.is_unlocked(TutorialChat.Unlock.NOTEBOOK), "el cuaderno se desbloqueó con el nombre")
	check(manager.tutorial_wants(TutorialChat.Focus.ANSWERS), "parpadean las hojas")
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


## La demostración de Gonzalo (D6): llega con el video descargado, su tiempo corre desde que se abre su chat, no se
## puede preguntar ni responder y, a los 15 s, cuenta qué hizo y sale el aviso de daño, sin efecto.
func test_en_el_tutorial_gonzalo_muestra_que_pasa_sin_respuesta() -> bool:
	var manager := _make_tutorial_manager()
	_tutorial_until_demo(manager)
	var demo := manager.requests[1]
	check(demo != null, "llegó la solicitud de Gonzalo")
	if demo == null:
		manager.free()
		return true
	check(manager.is_friend_unlocked(1), "Gonzalo se desbloqueó")
	check(manager.tutorial_wants(TutorialChat.Focus.DEMO_ENTRY), "parpadea su entrada")
	check_eq(demo.time_left, 10.0, "su tiempo espera")
	check(not manager.ask(1, ClueCategory.Kind.SIGHT), "no se le puede preguntar")
	check(not manager.answer(1, demo.entity.actions[0]), "ni responder")
	var events := []
	_record(manager, events)
	manager.tutorial_view(0)
	_run(manager, 2.0)
	check_eq(demo.time_left, 10.0, "mirar a León no lo echa a andar")
	manager.tutorial_view(1)
	_run(manager, 5.0)
	check_eq(demo.time_left, 5.0, "desde que se abre su chat, corre")
	_run(manager, 6.0)
	check(manager.requests[1] == null, "a los 15 s, terminó")
	_until_idle(manager)
	var notices := _messages(events).filter(func(message: ChatMessage) -> bool: return message.sender == ChatMessage.Sender.SYSTEM)
	check_eq(notices.size(), 1, "el aviso de daño")
	if notices.size() == 1:
		check(notices[0].plain_text().contains("2/3"), "con un punto menos: " + notices[0].plain_text())
	check_eq(manager.state.friends[1].health, 3, "pero sin efecto")
	check(manager.tutorial_wants(TutorialChat.Focus.GUIDE_ENTRY), "parpadea la entrada de León")
	manager.free()
	return true


## De vuelta con León: su señal baja, una línea llega con estática fija y las demás limpias; se le corta la señal, el
## mixer se desbloquea y, al sincronizarlo, se abre su chat y se despide.
func test_en_el_tutorial_la_estatica_y_la_senal() -> bool:
	var manager := _make_tutorial_manager()
	var finished := []
	var shown := []
	manager.tutorial_finished.connect(func() -> void: finished.append(true))
	manager.tutorial_chat_requested.connect(func(friend_index: int) -> void: shown.append(friend_index))
	_tutorial_until_demo(manager)
	manager.tutorial_view(1)
	_run(manager, 16.0)
	_until_idle(manager)
	var events := []
	_record(manager, events)
	manager.tutorial_view(0)
	_run(manager, 1.0)
	check_eq(manager.state.friends[0].signal_level, 100.0, "primero explica, con señal")
	_until_idle(manager, 60.0)
	var tapped := _messages(events).filter(func(message: ChatMessage) -> bool:
		return message.tokens.any(func(token: ChatMessage.Token) -> bool: return token.covered))
	check_eq(tapped.size(), 1, "solo una línea con estática: las demás se leen")
	if tapped.size() == 1:
		var words: Array = tapped[0].tokens.map(func(token: ChatMessage.Token) -> String: return token.text)
		check_eq("".join(words), _line(TutorialChat.STATIC_KEY), "es la de la estática")
	check(not manager.state.friends[0].is_online(), "se le cortó la señal")
	check(manager.is_unlocked(TutorialChat.Unlock.MIXER), "el mixer se desbloqueó")
	check(manager.tutorial_wants(TutorialChat.Focus.SYNC), "parpadean las barritas")
	check(finished.is_empty(), "todavía no termina")
	manager.restore_signal(0)
	_run_night(manager, 15.0)
	check_eq(shown, [0], "se abre el chat de León")
	check_eq(finished.size(), 1, "al volver la señal, se despide y termina")
	manager.free()
	return true


## El susto guionado espera las solicitudes fijas del tutorial que faltan.
func test_en_el_tutorial_lo_pendiente_hace_esperar_al_susto() -> bool:
	var manager := _make_tutorial_manager()
	check_eq(manager.pending_count(), 2, "al empezar faltan la de León y la de Gonzalo")
	manager.advance(5.1)
	check_eq(manager.pending_count(), 2, "llegó la de León: ahora es una solicitud activa")
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


## Una pregunta ya respondida no se repite (decisión de Benja, 11 de noviembre): no agrega mensajes ni cuesta tiempo.
func test_no_se_repite_una_pregunta() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	check(manager.ask(0, ClueCategory.Kind.SIGHT), "la primera vez")
	var events := []
	_record(manager, events)
	check(not manager.ask(0, ClueCategory.Kind.SIGHT), "la segunda no")
	check_eq(events, [], "sin mensajes")
	check_eq(request.time_left, 40.0, "y sin costo")
	check(manager.ask(0, ClueCategory.Kind.SOUND), "otra categoría sí")
	manager.free()
	return true


## La solicitud guarda si la estática tapó algo de cada respuesta: entonces esa pregunta se puede repetir.
func test_guarda_si_la_respuesta_salio_tapada() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	manager.state.friends[0].signal_level = 1.0
	var events := []
	_record(manager, events)
	for category: ClueCategory.Kind in [ClueCategory.Kind.SIGHT, ClueCategory.Kind.SOUND, ClueCategory.Kind.ENVIRONMENT,
			ClueCategory.Kind.TRACES]:
		check(manager.ask(0, category), "se pregunta %d" % category)
		var answer: ChatMessage = _messages(events)[-1]
		check_eq(request.answer_covered(category), answer.lost_information(), "lo guarda: %d" % category)
		check_eq(request.can_ask_about(category), answer.lost_information(), "se repite solo si salió tapada: %d" % category)
	manager.free()
	return true


## La dificultad de la partida (docs/26 §3): de ella salen las noches y si la identificación es guiada. Sin elegirla, la
## de por defecto (Normal).
func test_la_dificultad_dice_las_noches_y_si_se_destaca() -> bool:
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	var manager := _make_manager(catalog)
	check_eq(manager.current_difficulty(), catalog.difficulties[0], "sin elegir, Normal")
	check(manager.highlights(), "en Normal se destaca")
	check_eq(manager.night(), catalog.difficulties[0].nights[0], "la noche 1 de Normal")
	manager.difficulty = hard
	check(not manager.highlights(), "en Difícil, no")
	check_eq(manager.night(), hard.nights[0], "la noche 1 de Difícil")
	manager.free()
	return true



# --- Los castigos de la dificultad (Plan 9.6, docs/30).

## Un manager en la noche 1 de una dificultad de prueba ("hard"), con sus castigos.
func _make_punished_manager(scale: float, wounded: int, seed_value := 7) -> RequestManager:
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	hard.error_trust_scale = scale
	hard.wounded_friends = wounded
	var manager := RequestManager.new()
	manager.catalog = catalog
	manager.difficulty = hard
	manager.night_number = 1
	manager.random_seed = seed_value
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## Los amigos que empiezan heridos.
func _wounded(manager: RequestManager) -> Array:
	return range(manager.state.friends.size()).filter(func(index: int) -> bool:
		return manager.state.friends[index].health < manager.state.friends[index].max_health)


func test_en_extremo_un_error_cuesta_mas_trust() -> bool:
	var manager := _make_punished_manager(1.5, 0)
	var request := manager.start_request(0)
	var wrong: ActionData = null
	for action: ActionData in request.entity.actions:
		if RuleEvaluator.outcome(request.entity, request.situation, action) == RuleEvaluator.Outcome.WRONG:
			wrong = action
	manager.answer(0, wrong)
	check_eq(manager.state.trust, 100.0 - 22.5, "una incorrecta: −22,5")
	check_eq(manager.catalog.balance.wrong_trust, -15.0, "el equilibrio del catálogo no cambia")
	manager.free()
	return true


## En Extremo, un amigo al azar empieza la noche con 1 de vida (de 3), y su chat lo avisa al empezar.
func test_un_amigo_empieza_herido() -> bool:
	var manager := _make_punished_manager(1.0, 1)
	var wounded := _wounded(manager)
	check_eq(wounded.size(), 1, "uno solo")
	if wounded.size() != 1:
		manager.free()
		return true
	var friend: FriendState = manager.state.friends[wounded[0]]
	check_eq([friend.health, friend.max_health], [1, 3], "con 1 de 3")
	var events := []
	_record(manager, events)
	manager.advance(0.1)
	var notices := _messages(events).filter(func(message: ChatMessage) -> bool:
		return message.sender == ChatMessage.Sender.SYSTEM)
	check_eq(notices.size(), 1, "un aviso")
	if notices.size() == 1:
		check_eq(events[0][1], wounded[0], "en su chat")
		check_eq(notices[0].tone, ChatMessage.Tone.DANGER, "en rojo")
		check(notices[0].plain_text().contains(tr(manager.catalog.friends[wounded[0]].name_key)), "con su nombre")
	manager.advance(0.1)
	check_eq(_messages(events).size(), 1, "una sola vez")
	manager.free()
	return true


func test_el_herido_cambia_de_noche_en_noche() -> bool:
	var seen := {}
	for seed_value in range(1, 13):
		var manager := _make_punished_manager(1.0, 1, seed_value)
		for index: int in _wounded(manager):
			seen[index] = true
		manager.free()
	check(seen.size() >= 2, "le toca a distintos amigos: %s" % str(seen.keys()))
	return true


func test_sin_heridos_en_normal() -> bool:
	var manager := _make_manager()
	check_eq(_wounded(manager), [], "nadie herido")
	var events := []
	_record(manager, events)
	manager.advance(0.1)
	check_eq(_messages(events), [], "sin aviso")
	manager.free()
	return true


## Un accidente nunca mata a un amigo: al herido no le tocan.
func test_el_herido_no_tiene_accidentes() -> bool:
	var manager := _make_punished_manager(1.0, 1)
	manager.catalog.incidents.append(Fixtures.make_incident())
	var wounded: int = _wounded(manager)[0]
	check(manager.start_incident(wounded) == null, "el herido, no")
	check(manager.start_incident((wounded + 1) % 3) != null, "otro, sí")
	manager.free()
	return true


# --- La historia (Plan 9.7, docs/31).

const StoryRunner := preload("res://scripts/core/story_runner.gd")


## Manager con una historia de un solo momento, al empezar la noche, con estos pasos.
func _story_manager(steps: Array, together := true, catalog: ContentCatalog = null) -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = catalog if catalog != null else Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	var story := StoryData.new()
	story.starts_together = together
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.NIGHT_START, steps))
	manager.night().story = story
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## Una decisión de León, como la de Fixtures.make_decision: la buena quita 10 s a la próxima consulta de Agustín; la
## mala y sin respuesta bajan Trust 20 y hieren a Agustín.
func _decision_step(catalog: ContentCatalog) -> StoryStepData:
	var step := Fixtures.make_step(StoryStepData.Kind.DECISION)
	step.decision = Fixtures.make_decision(catalog.friends[0], catalog.friends[2])
	return step


func _record_call(manager: RequestManager, events: Array) -> void:
	manager.call_message_added.connect(func(speaker: int, message: ChatMessage) -> void: events.append([speaker, message]))


func _texts(messages: Array) -> Array:
	return messages.map(func(message: ChatMessage) -> String: return message.plain_text())


func test_sin_historia_no_hay_llamada() -> bool:
	var manager := _make_manager()
	check(manager.story == null, "la noche no tiene historia")
	check(not manager.call_active(), "sin llamada")
	manager.free()
	return true


func test_la_historia_escribe_en_la_llamada() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[1], "K_A"),
			Fixtures.make_line(catalog.friends[0], "K_B")], true, catalog)
	manager.state.friends[0].signal_level = 0.0
	var calls := []
	_record_call(manager, calls)
	var events := []
	_record(manager, events)
	check(manager.call_active(), "juntos y sin nada que jugar: la llamada")
	manager.advance(0.1)
	manager.advance(5.0)
	check_eq(calls.size(), 2, "2 líneas en la llamada")
	check(_messages(events).is_empty(), "ninguna en los chats de cada uno")
	if calls.size() == 2:
		check_eq(calls[0][0], 1, "habla Gonzalo")
		check_eq((calls[0][1] as ChatMessage).plain_text(), tr("K_A"), "con señal, se lee")
		check_eq(calls[1][0], 0, "después León")
		check(not (calls[1][1] as ChatMessage).plain_text().contains(tr("K_B")), "sin señal, tapado")
	manager.free()
	return true


func test_separados_escribe_en_cada_chat() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[2], "K_A")], false, catalog)
	var events := []
	_record(manager, events)
	manager.advance(0.1)
	check(not manager.call_active(), "separados, sin llamada")
	var messages := events.filter(func(entry: Array) -> bool: return entry[0] == "message_added")
	check_eq(messages.size(), 1, "una línea")
	if messages.size() == 1:
		check_eq(messages[0][1], 2, "en el chat de Agustín")
		check_eq((messages[0][2] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "la escribe él")
	manager.free()
	return true


## Si llega una consulta, un accidente, una decisión o un video, la llamada se separa en los 3 chats (docs/21 §2).
func test_la_llamada_se_corta_con_algo_que_jugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.incidents.append(Fixtures.make_incident())
	var manager := _story_manager([], true, catalog)
	check(manager.call_active(), "la llamada")
	manager.start_request(0)
	check(not manager.call_active(), "con una consulta, se corta")
	manager.requests[0] = null
	check(manager.call_active(), "vuelve")
	manager.start_incident(1)
	check(not manager.call_active(), "con un accidente, se corta")
	manager.incidents[1] = null
	manager.state.videos.add_extra(2, 0.0)
	manager.state.advance(0.1)
	check(manager.state.videos.offer_for(2) != null, "un video espera su descarga")
	check(not manager.call_active(), "con un video, se corta")
	manager.free()
	return true


## Una historia con la llamada a la vista (empieza con los 3 juntos), que ya dijo todo lo suyo y dejó pasar el tiempo.
func _quiet_call_manager() -> RequestManager:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[1], "K_A")], true, catalog)
	manager.advance(0.1)
	manager.advance(10.0)
	return manager


## Pedido de Benja (noche 1): al resolver una consulta con la ola en curso, no se vuelve a la llamada, donde no hay nada
## nuevo, y se alcanza a leer cómo le fue al amigo.
func test_resolver_una_consulta_en_la_ola_no_vuelve_a_la_llamada() -> bool:
	var manager := _quiet_call_manager()
	check(manager.call_active(), "la llamada, con sus líneas")
	manager.director.phase = PacingDirector.Phase.FINALE
	var request := manager.start_request(0)
	manager.advance(0.1)
	check(not manager.call_active(), "con una consulta, se corta")
	manager.answer(0, _correct_action(manager, 0))
	check(request.finished, "se respondió")
	for step in 40:
		manager.advance(0.5)
	check(not manager.call_active(), "20 s después, con la ola en curso y nada nuevo, sigue en el chat del amigo")
	manager.free()
	return true


## Terminada la ola, tampoco vuelve si la historia no tiene nada más que decir en la llamada.
func test_sin_linea_nueva_no_vuelve_a_la_llamada() -> bool:
	var manager := _quiet_call_manager()
	manager.start_request(0)
	manager.advance(0.1)
	manager.answer(0, _correct_action(manager, 0))
	for step in 40:
		manager.advance(0.5)
	check(manager.director.phase == PacingDirector.Phase.SILENCE, "la ola ya terminó (no hay ola en curso)")
	check(not manager.call_active(), "la ola terminó pero no hay mensaje nuevo: no vuelve")
	manager.free()
	return true


## Con una línea nueva y la ola terminada, vuelve, pero no antes de call_delay segundos de leer cómo le fue al amigo.
func test_con_una_linea_nueva_vuelve_a_la_llamada_tras_la_espera() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[1], "K_A")], true, catalog)
	manager.night().story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_FIRST_WAVE,
			[Fixtures.make_line(catalog.friends[0], "K_B")]))
	manager.advance(0.1)
	manager.advance(10.0)
	manager.director.phase = PacingDirector.Phase.WAVE
	manager.start_request(2)
	manager.advance(0.1)
	check(not manager.call_active(), "con la consulta, se corta")
	manager.answer(2, _correct_action(manager, 2))
	manager.director.phase = PacingDirector.Phase.CALM
	manager.director.calms_started = 1
	var calls := []
	_record_call(manager, calls)
	manager.advance(0.1)
	manager.advance(0.1)
	check(calls.is_empty(), "la línea nueva espera a que Matías lea cómo le fue")
	check(not manager.call_active(), "sigue en el chat del amigo")
	var waited := 0.0
	while waited < 10.0 and not manager.call_active():
		manager.advance(0.25)
		waited += 0.25
	check(waited >= manager.balance.call_delay - 0.3, "no antes de call_delay: %.2f s" % waited)
	check(waited <= manager.balance.call_delay + 1.0, "y enseguida: %.2f s" % waited)
	check_eq(calls.size(), 1, "la línea nueva llegó")
	check(manager.call_active(), "ahora sí, la llamada")
	manager.free()
	return true


## Sin historia o con los amigos separados nunca hay llamada.
func test_la_llamada_no_vuelve_mientras_la_ola_no_termina() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[1], "K_A")], true, catalog)
	manager.night().story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_FIRST_WAVE,
			[Fixtures.make_line(catalog.friends[0], "K_B")]))
	manager.advance(0.1)
	manager.advance(10.0)
	manager.director.phase = PacingDirector.Phase.WAVE
	manager.director.calms_started = 1
	for step in 40:
		manager.advance(0.5)
	check(not manager.call_active(), "con la ola en curso, aunque no haya nada que jugar")
	manager.free()
	return true


## Las respuestas de una decisión de la historia sí se ven enseguida, sin la espera: son su resultado.
func test_las_respuestas_de_una_decision_se_ven_enseguida() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], true, catalog)
	manager.advance(0.1)
	check(manager.incidents[0] != null, "la decisión espera a Matías")
	manager.answer_incident(0, 0)
	manager.advance(0.1)
	check(manager.call_active(), "las respuestas del amigo, en la llamada, sin esperar")
	manager.free()
	return true


## Resolver bien un accidente avisa (suena el chime); resolverlo mal, no.
func test_resolver_bien_un_accidente_avisa() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.incidents.append(Fixtures.make_incident())
	var manager := _make_manager(catalog)
	var solved := []
	manager.incident_solved.connect(func(friend_index: int) -> void: solved.append(friend_index))
	var bad := manager.start_incident(1)
	var good := manager.start_incident(2)
	check(bad != null and good != null, "2 accidentes")
	var wrong := 0
	for index in bad.options.size():
		if not bad.is_correct(index):
			wrong = index
	manager.answer_incident(1, wrong)
	check(solved.is_empty(), "mal respondido, no avisa")
	var right := 0
	for index in good.options.size():
		if good.is_correct(index):
			right = index
	manager.answer_incident(2, right)
	check_eq(solved, [2], "bien respondido, avisa")
	manager.free()
	return true


## Una decisión llega como un accidente: en el chat de quien pregunta, con el tiempo de un accidente y sus opciones.
func test_la_decision_llega_como_un_accidente() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	var events := []
	_record(manager, events)
	manager.advance(0.1)
	var incident := manager.incidents[0]
	check(incident != null and incident.decision != null, "León tiene una decisión abierta")
	if incident != null:
		check_eq(incident.options, ["K_STORY_GOOD", "K_STORY_BAD"], "sus opciones, en el orden del guion")
		check_eq(incident.time_left, catalog.balance.incident_seconds, "15 s")
	check_eq(_texts(_messages(events)), [tr("K_STORY_ASK")], "León pregunta")
	check(manager.start_request(0) == null, "León está ocupado")
	manager.free()
	return true


func test_responder_la_decision_aplica_su_opcion() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	manager.advance(0.1)
	var events := []
	_record(manager, events)
	check(manager.answer_incident(0, 0), "Matías responde la buena")
	check(manager.incidents[0] == null, "la decisión terminó")
	var messages := _messages(events)
	check_eq(_texts(messages), [tr("K_STORY_GOOD"), tr("K_STORY_GOOD_REPLY")], "Matías responde y León contesta")
	if messages.size() == 2:
		check_eq((messages[0] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "la respuesta es de Matías")
	check_eq(manager.story.flags, [&"with_agustin"], "deja su marca")
	check_eq(manager.state.trust, 100.0, "la buena no baja Trust")
	manager.free()
	return true


func test_sin_respuesta_cuenta_como_la_peor() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	manager.advance(0.1)
	var events := []
	_record(manager, events)
	manager.advance(catalog.balance.incident_seconds + 0.1)
	check(manager.incidents[0] == null, "se acabó el tiempo")
	var agustin := events.filter(func(entry: Array) -> bool: return entry[0] == "message_added" and entry[1] == 2)
	check_eq(_texts(_messages(events)).slice(0, 1), [tr("K_STORY_NO_ANSWER")], "León cuenta qué pasó")
	check_eq(manager.state.trust, 80.0, "Trust −20")
	check_eq(manager.state.friends[2].health, 2, "Agustín herido")
	check(manager.state.friends[2].is_stunned(), "y aturdido, como en un accidente")
	check_eq(agustin.size(), 1, "el aviso de daño, en el chat de Agustín")
	manager.free()
	return true


## La historia nunca hace perder (decisión de Benja, S21l): Trust no baja de 1 por ella.
func test_la_historia_no_deja_trust_en_0() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	manager.advance(0.1)
	manager.state.trust = 10.0
	manager.answer_incident(0, 1)
	check_eq(manager.state.trust, 1.0, "queda en 1")
	manager.free()
	return true


func test_la_proxima_consulta_tiene_menos_tiempo() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	manager.advance(0.1)
	manager.answer_incident(0, 0)
	check_eq(manager.start_request(2).time_left, 35.0, "la próxima de Agustín, 10 s menos")
	manager.requests[2] = null
	check_eq(manager.start_request(2).time_left, 45.0, "la siguiente, completa")
	check_eq(manager.start_request(1).time_left, 45.0, "la de Gonzalo, completa")
	manager.free()
	return true


## Si están juntos, el daño es para el que tenga más vida; si los dos tienen 1, para ninguno (docs/21 §4).
func test_el_dano_es_para_el_que_tiene_mas_vida() -> bool:
	var catalog := Fixtures.make_catalog()
	var step := _decision_step(catalog)
	step.decision.options[1].damage_candidates.assign([catalog.friends[2], catalog.friends[0]])
	var manager := _story_manager([step], false, catalog)
	manager.advance(0.1)
	manager.state.friends[2].health = 2
	manager.answer_incident(0, 1)
	check_eq([manager.state.friends[0].health, manager.state.friends[2].health], [2, 2], "León tenía más: a él")
	manager.free()
	manager = _story_manager([step], false, catalog)
	manager.advance(0.1)
	manager.answer_incident(0, 1)
	check_eq([manager.state.friends[0].health, manager.state.friends[2].health], [3, 2], "empatados: al primero, Agustín")
	manager.free()
	return true


func test_la_historia_nunca_mata() -> bool:
	var catalog := Fixtures.make_catalog()
	var step := _decision_step(catalog)
	step.decision.options[1].damage_candidates.assign([catalog.friends[2], catalog.friends[0]])
	var manager := _story_manager([step], false, catalog)
	manager.advance(0.1)
	manager.state.friends[0].health = 1
	manager.state.friends[2].health = 1
	var events := []
	_record(manager, events)
	manager.answer_incident(0, 1)
	check_eq([manager.state.friends[0].health, manager.state.friends[2].health], [1, 1], "con 1 de vida, nadie")
	check(not _messages(events).any(func(message: ChatMessage) -> bool:
		return message.sender == ChatMessage.Sender.SYSTEM), "sin aviso de daño")
	manager.free()
	return true


## Cada criatura nueva de la noche sale al menos una vez: se fuerza solo cuando quedan tantas consultas como criaturas
## que faltan (docs/21 §1).
func test_cada_criatura_nueva_sale_al_menos_una_vez() -> bool:
	var seen := []
	for seed_value in 10:
		var manager := _make_manager()
		manager.night_number = 2
		manager.night().requests_total = 1
		manager.rng.seed = seed_value
		check_eq(manager.start_request(0).entity.id, &"ghost", "semilla %d: la única consulta es la nueva" % seed_value)
		manager.night().requests_total = 10
		manager.free()
		manager = _make_manager()
		manager.night_number = 2
		manager.rng.seed = seed_value
		seen.append(manager.start_request(0).entity.id)
		manager.free()
	check(seen.has(&"beast"), "con consultas de sobra, no se fuerza")
	return true


func test_juntos_las_consultas_no_dicen_que_esta_solo() -> bool:
	for together: bool in [true, false]:
		var said := []
		for seed_value in 10:
			var catalog := Fixtures.make_catalog()
			catalog.predicament_keys.assign(["K_LOST", "K_FINE"])
			catalog.alone_predicament_keys.assign(["K_LOST"])
			var manager := _story_manager([], together, catalog)
			manager.rng.seed = seed_value
			said.append(manager.start_request(0).predicament_key)
			manager.free()
		check_eq(said.has("K_LOST"), not together, "juntos, nunca 'Me perdí'" if together else "separados, a veces")
	return true


## Mientras la historia cuenta algo antes de la ola (aquí, una decisión sin responder), la ola espera.
func test_la_ola_espera_a_la_historia() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([_decision_step(catalog)], false, catalog)
	manager.requests_arrive = true
	manager.night().requests_total = 4
	manager.night().finale_size = 0
	manager.night().wave_size = 2
	manager.night().max_simultaneous = 3
	manager.director = PacingDirector.new(manager.night(), manager.balance, manager.rng)
	for step in 140:
		manager.advance(0.5)
		if manager.incidents[0] != null:
			manager.incidents[0].time_left = 99.0
	check_eq(manager.director.waves_started, 0, "a los 70 s, la primera ola todavía espera")
	manager.answer_incident(0, 0)
	for step in 10:
		manager.advance(0.5)
	check_eq(manager.director.waves_started, 1, "terminada la historia, llega")
	manager.free()
	return true


## Un chat guionado que espera la respuesta de Matías también es algo que jugar: la llamada se corta (su botón va en el
## chat del amigo).
func test_un_chat_guionado_corta_la_llamada() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([], true, catalog)
	var reply := ChatLineData.new()
	reply.speaker = ChatLineData.Speaker.PLAYER
	reply.text_key = "K_REPLY"
	var chat := ChatScriptData.new()
	chat.friend = catalog.friends[1]
	chat.lines.append(reply)
	check(manager.call_active(), "la llamada")
	manager.start_chat_script(chat)
	check(not manager.call_active(), "Matías tiene que responder en el chat de Gonzalo")
	manager.reply_chat_script()
	check(manager.call_active(), "respondió: vuelve")
	manager.free()
	return true



## El manager mide la historia y se la pasa al director, que le deja su tiempo (Plan 9.8).
func test_el_director_conoce_la_historia() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[0], "K_A")], true, catalog)
	var expected := StoryRunner.story_needs(manager.night().story, manager.tr, catalog.balance.incident_seconds)
	check_eq(manager.director.story_needs, expected, "lo que dura cada momento")
	check(not manager.director.story_needs.is_empty(), "con algo")
	manager.free()
	return true


## La pregunta de una decisión de la historia pide ayuda: abre la emergencia, como un accidente (Plan 9.8). Las líneas del
## vlog, no.
func test_la_decision_pide_ayuda_y_el_vlog_no() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[0], "K_A"), _decision_step(catalog)], false, catalog)
	var events := []
	_record(manager, events)
	manager.advance(0.1)
	manager.advance(5.0)
	var messages := _messages(events)
	check_eq(messages.size(), 2, "la línea y la pregunta")
	if messages.size() == 2:
		check(not (messages[0] as ChatMessage).urgent, "la línea del vlog no es urgente")
		check((messages[1] as ChatMessage).urgent and (messages[1] as ChatMessage).opens_help, "la pregunta, sí")
	manager.free()
	return true


# --- La noche termina cuando se completa, y los pedidos de ayuda de la nota (Plan 9.9, docs/33).

## La noche se completa cuando la ola final llegó entera, no queda nada abierto ni videos por recibir y la historia
## terminó. 3 s después (end_pause), termina.
func test_la_noche_se_completa_cuando_no_queda_nada() -> bool:
	var manager := _make_manager()
	manager.state.videos.unreleased = 0
	check(not manager.night_complete(), "con olas por llegar, no")
	manager.director.phase = PacingDirector.Phase.DONE
	check(manager.night_complete(), "sin nada pendiente, sí")
	var request := manager.start_request(0)
	check(not manager.night_complete(), "con una consulta abierta, no")
	manager.answer(0, request.entity.actions[0])
	manager.state.videos.release(1, 0.0)
	check(not manager.night_complete(), "con un video en camino, no")
	manager.state.videos.pending.clear()
	check(manager.night_complete(), "respondida y sin videos, sí")
	manager.advance(2.9)
	check(not manager.state.finished, "a los 2,9 s, todavía no termina")
	manager.advance(0.2)
	check(manager.state.finished, "a los 3 s, termina")
	manager.free()
	return true


## El tutorial termina cuando León se despide, nunca solo (decisión de Benja).
func test_el_tutorial_no_se_completa_solo() -> bool:
	var manager := _make_manager()
	manager.state.videos.unreleased = 0
	manager.director.phase = PacingDirector.Phase.DONE
	manager.night_number = 0
	check(not manager.night_complete(), "en la noche 0, no")
	manager.free()
	return true


## Con historia, la noche espera a que terminen de contarla: el cierre del vlog.
func test_con_historia_espera_que_terminen_de_contarla() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[0], "K_A")], false, catalog)
	manager.state.videos.unreleased = 0
	manager.director.phase = PacingDirector.Phase.DONE
	check(not manager.night_complete(), "la historia no ha terminado")
	for _step in 30:
		manager.advance(0.1)
	check(manager.story.is_done(), "terminaron de contarla")
	check(manager.night_complete(), "y la noche se completa")
	manager.free()
	return true


## Los pedidos de ayuda de la nota: consultas, accidentes y decisiones de la historia. Se cuentan al llegar, y los
## abiertos suman espera.
func test_cuenta_los_pedidos_de_ayuda() -> bool:
	var manager := _make_manager()
	manager.catalog.incidents.append(Fixtures.make_incident())
	check_eq(manager.waiting_count(), 0, "nada abierto")
	manager.start_request(0)
	manager.start_incident(1)
	check_eq(manager.waiting_count(), 2, "una consulta y un accidente")
	check_eq(manager.state.asked, 2, "2 pedidos")
	manager.free()
	var catalog := Fixtures.make_catalog()
	var story_manager := _story_manager([_decision_step(catalog)], false, catalog)
	story_manager.advance(0.1)
	check_eq([story_manager.waiting_count(), story_manager.state.asked], [1, 1], "la decisión de la historia, también")
	story_manager.free()
	return true


## La meta de espera de la nota es la de la dificultad.
func test_la_meta_de_espera_es_la_de_la_dificultad() -> bool:
	var manager := _make_manager()
	check_eq(manager.state.wait_goal, 15.0, "sin dificultad elegida, la de por defecto")
	manager.free()
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	hard.wait_goal = 20.0
	manager = RequestManager.new()
	manager.catalog = catalog
	manager.difficulty = hard
	manager.night_number = 1
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	check_eq(manager.state.wait_goal, 20.0, "la de Difícil")
	manager.free()
	return true
