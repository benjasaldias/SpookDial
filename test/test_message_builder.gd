extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")


## Traducción falsa: cada característica y señuelo tiene su clave como frase clickeable.
func _translate(key: String) -> String:
	if key.begins_with("K_TRAIT_") or key.begins_with("K_DECOY_"):
		return "Hay *%s*." % key
	if key == MessageBuilder.DECIDED_ALONE_KEY:
		return "Decidí solo: {action}"
	if key == MessageBuilder.DAMAGE_KEY:
		return "{friend} recibió daño: {health}/{max}"
	return key + "."


## Solicitud de "beast": beast_trait_1 (Vista) y beast_trait_2 (Sonido), el señuelo "decoy_sight" (Vista)
## entre las dos, o1 (Vista) = yes y o2 (Sonido) = no. El saludo es "K_CALL" y el mensaje inicial no trae
## pista: todo lo demás sale al preguntar.
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	entity.traits[1].category = ClueCategory.Kind.SOUND
	entity.observations[1].category = ClueCategory.Kind.SOUND
	var request := FriendRequest.new()
	request.entity = entity
	request.place_key = "K_PLACE"
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.clues.assign([entity.traits[0], request.decoys[0], entity.traits[1]])
	request.greeting_key = "K_CALL"
	request.time_left = 30.0
	return request


func _clue_ids(message: ChatMessage) -> Array:
	return message.tokens.filter(func(token: ChatMessage.Token) -> bool: return token.is_clue()) \
			.map(func(token: ChatMessage.Token) -> StringName: return token.clue_id)


func test_mensaje_inicial() -> bool:
	var request := _make_request()
	var message := MessageBuilder.first_message(request, _translate)
	check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo envía el amigo")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "K_CALL. K_PLACE.", "solo el saludo y el lugar: nada de descripciones")
	check_eq(_clue_ids(message), [], "sin frases clickeables ni observaciones")
	return true


func test_mensaje_inicial_con_pista() -> bool:
	var request := _make_request()
	request.hint = request.traits[1]
	var message := MessageBuilder.first_message(request, _translate)
	check_eq(message.plain_text(), "K_CALL. K_PLACE. Hay K_TRAIT_beast_trait_2.", "la pista, al final")
	check_eq(_clue_ids(message), [&"beast_trait_2"], "la pista se puede clickear")
	request.greeting_key = ""
	check_eq(MessageBuilder.first_message(request, _translate).plain_text(), "K_PLACE. Hay K_TRAIT_beast_trait_2.",
			"sin saludo en el catálogo, el mensaje empieza por el lugar")
	return true


## Saludo, lo que le pasa, el lugar si lo dice y la pista (decisión de Benja, 11 de noviembre).
func test_el_mensaje_inicial_dice_lo_que_le_pasa() -> bool:
	var request := _make_request()
	request.predicament_key = "K_LOST"
	request.hint = request.traits[0]
	check_eq(MessageBuilder.first_message(request, _translate).plain_text(),
			"K_CALL. K_LOST. K_PLACE. Hay K_TRAIT_beast_trait_1.", "en este orden")
	return true


func test_el_mensaje_inicial_sin_lugar() -> bool:
	var request := _make_request()
	request.predicament_key = "K_LOST"
	request.says_place = false
	check_eq(MessageBuilder.first_message(request, _translate).plain_text(), "K_CALL. K_LOST.", "sin el lugar")
	return true


func test_respuesta_a_una_pregunta() -> bool:
	var request := _make_request()
	var sight := MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate)
	check_eq(sight.plain_text(), "Hay K_TRAIT_beast_trait_1. Hay K_DECOY_decoy_sight. K_beast_O1_YES.",
			"Vista: las frases de la categoría y todas sus observaciones")
	check_eq(_clue_ids(sight), [&"beast_trait_1", &"decoy_sight"], "frases de Vista")
	var sound := MessageBuilder.answer(request, ClueCategory.Kind.SOUND, _translate)
	check_eq(sound.plain_text(), "Hay K_TRAIT_beast_trait_2. K_beast_O2_NO.", "Sonido")
	return true


func test_si_no_hay_nada_responde_nada() -> bool:
	var message := MessageBuilder.answer(_make_request(), ClueCategory.Kind.TRACES, _translate)
	check_eq(message.plain_text(), "ANSWER_NOTHING_TRACES.", "nada en Rastro")
	return true


func test_la_pregunta_de_matias() -> bool:
	var request := _make_request()
	var message := MessageBuilder.question(request, ClueCategory.Kind.ENVIRONMENT, _translate)
	check_eq(message.sender, ChatMessage.Sender.PLAYER, "la envía Matías")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "QUESTION_ENVIRONMENT.", "texto")
	return true


func test_el_amigo_decidio_solo() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a3"), false)
	var message := MessageBuilder.decided_alone(request, _translate)
	check_eq(message.plain_text(), "Decidí solo: K_beast_A3.", "con la acción que eligió")
	return true


func test_la_respuesta_de_matias() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a1"), true)
	var message := MessageBuilder.player_answer(request, _translate)
	check_eq(message.sender, ChatMessage.Sender.PLAYER, "la envía Matías")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "K_beast_A1.", "la acción que eligió")
	return true


func test_la_reaccion_depende_del_resultado() -> bool:
	# o1 = yes: se aplica la regla 1 (correcta a1, mayor riesgo a2), y a3 es incorrecta.
	var expected := {&"a1": "REACTION_CORRECT.", &"a2": "REACTION_RISKY.", &"a3": "REACTION_WRONG."}
	for action_id: StringName in expected:
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		var message := MessageBuilder.reaction(request, _translate)
		check_eq(message.sender, ChatMessage.Sender.FRIEND, "la envía el amigo")
		check_eq(message.plain_text(), expected[action_id], "reacción a %s" % action_id)
	return true


func test_si_quedo_herido_la_reaccion_cambia() -> bool:
	# o1 = yes: a2 es la de mayor riesgo y a3, incorrecta. Con probabilidad 1, siempre hieren.
	var balance := BalanceData.new()
	balance.risky_hurt_chance = 1.0
	balance.wrong_hurt_chance = 1.0
	var expected := {&"a2": "REACTION_RISKY_HURT.", &"a3": "REACTION_WRONG_HURT."}
	for action_id: StringName in expected:
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		request.consequence = Consequence.new(request.outcome, true, balance, RandomNumberGenerator.new())
		check_eq(MessageBuilder.reaction(request, _translate).plain_text(), expected[action_id], "reacción a %s" % action_id)
	return true


func test_el_aviso_de_dano() -> bool:
	var request := _make_request()
	var message := MessageBuilder.damage_notice(request, "León", 2, 3, _translate)
	check_eq(message.sender, ChatMessage.Sender.SYSTEM, "lo escribe el juego, no el amigo")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "León recibió daño: 2/3", "con la vida que le queda")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var keys: Array = MessageBuilder.QUESTION_KEYS.values() + MessageBuilder.NOTHING_KEYS.values() \
			+ MessageBuilder.REACTION_KEYS.values() + MessageBuilder.HURT_REACTION_KEYS.values()
	keys.append(MessageBuilder.DECIDED_ALONE_KEY)
	keys.append(MessageBuilder.DAMAGE_KEY)
	for placeholder: String in ["{friend}", "{health}", "{max}"]:
		check(String(TranslationServer.translate(MessageBuilder.DAMAGE_KEY)).contains(placeholder),
				"CHAT_DAMAGE debe tener %s" % placeholder)
	for key: String in keys:
		check(String(TranslationServer.translate(key)) != key, "falta %s en los CSV" % key)
	check(String(TranslationServer.translate(MessageBuilder.DECIDED_ALONE_KEY)).contains("{action}"),
			"FRIEND_DECIDED_ALONE debe tener {action}")
	TranslationServer.set_locale(previous)
	return true


func test_el_amigo_avisa_que_mando_un_video() -> bool:
	var message := MessageBuilder.video_sent(_translate)
	check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo escribe el amigo")
	check_eq(message.plain_text(), MessageBuilder.VIDEO_SENT_KEY + ".", "su texto")
	return true


func test_los_avisos_del_juego() -> bool:
	var translate := func(_key: String) -> String: return "{friend}: {received} de {quota}"
	var values := {"friend": "León", "received": 1, "quota": 3}
	var notice := MessageBuilder.notice("K_NOTICE", values, ChatMessage.Tone.GOOD, translate)
	check_eq(notice.sender, ChatMessage.Sender.SYSTEM, "lo escribe el juego")
	check_eq(notice.tone, ChatMessage.Tone.GOOD, "es una buena noticia")
	check_eq(notice.plain_text(), "León: 1 de 3", "con sus datos")
	return true


func test_los_textos_de_videos_y_senal_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check(String(TranslationServer.translate(MessageBuilder.VIDEO_SENT_KEY)) != MessageBuilder.VIDEO_SENT_KEY,
			"falta FRIEND_VIDEO_SENT en messages.csv")
	for key: String in [MessageBuilder.VIDEO_RECEIVED_KEY, MessageBuilder.VIDEO_LOST_KEY, MessageBuilder.SIGNAL_LOST_KEY,
			MessageBuilder.SIGNAL_BACK_KEY]:
		check(String(TranslationServer.translate(key)).contains("{friend}"), "%s debe estar en ui.csv con {friend}" % key)
	for placeholder: String in ["{received}", "{quota}"]:
		check(String(TranslationServer.translate(MessageBuilder.VIDEO_RECEIVED_KEY)).contains(placeholder),
				"CHAT_VIDEO_RECEIVED debe tener %s" % placeholder)
	TranslationServer.set_locale(previous)
	return true


## El amigo manda un audio en lugar de contar la observación (decisión de Benja, 7 de noviembre).
func test_una_observacion_con_audio_llega_como_audio() -> bool:
	var request := _make_request()
	var stream := Fixtures.make_audio()
	request.entity.observations[1].audio_values = {&"yes": Fixtures.make_audio(), &"no": stream}
	var message := MessageBuilder.answer(request, ClueCategory.Kind.SOUND, _translate)
	check_eq(message.audio, stream, "el audio del valor de esta solicitud")
	check_eq(message.audio_caption, "K_beast_O2_NO.", "su texto queda de subtítulo")
	check(not message.plain_text().contains("K_beast_O2_NO"), "el amigo no lo cuenta")
	check(message.plain_text().contains(MessageBuilder.AUDIO_LABEL_KEY), "se ve el audio: " + message.plain_text())
	check(_clue_ids(message).has(&"beast_trait_2"), "la característica sigue siendo clickeable")
	return true


func test_las_otras_categorias_no_traen_audio() -> bool:
	var request := _make_request()
	request.entity.observations[1].audio_values = {&"yes": Fixtures.make_audio(), &"no": Fixtures.make_audio()}
	check_eq(MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate).audio, null, "¿Qué ves?, sin audio")
	return true


## La característica llega con la forma que eligió la solicitud, en la pista y al preguntar, y se sigue clickeando
## igual.
func test_la_respuesta_usa_la_forma_de_la_solicitud() -> bool:
	var request := _make_request()
	request.trait_forms[&"beast_trait_1"] = "K_TRAIT_beast_trait_1_2"
	var answer := MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate)
	check(answer.plain_text().contains("K_TRAIT_beast_trait_1_2"), "con la otra forma: " + answer.plain_text())
	check_eq(_clue_ids(answer), [&"beast_trait_1", &"decoy_sight"], "se clickea igual")
	request.hint = request.traits[0]
	check(MessageBuilder.first_message(request, _translate).plain_text().contains("K_TRAIT_beast_trait_1_2"),
			"la pista también")
	return true


## Las observaciones llegan marcadas: el chat las muestra en azul, porque deciden la fila de la tabla (decisión de Benja,
## 11 de noviembre). Las características y los señuelos, no.
func test_la_respuesta_marca_las_observaciones() -> bool:
	var sight := MessageBuilder.answer(_make_request(), ClueCategory.Kind.SIGHT, _translate)
	var marked := sight.tokens.filter(func(token: ChatMessage.Token) -> bool: return token.is_observation) \
			.map(func(token: ChatMessage.Token) -> String: return token.text)
	check_eq(marked, ["K_beast_O1_YES."], "solo la observación")
	return true


# --- La emergencia marcada (Plan 9.8): lo que pide ayuda se distingue del vlog.

func test_lo_que_pide_ayuda_va_marcado() -> bool:
	var request := _make_request()
	var first := MessageBuilder.first_message(request, _translate)
	check(first.urgent and first.opens_help, "el mensaje inicial pide ayuda y abre la emergencia")
	var answer := MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate)
	check(answer.urgent and not answer.opens_help, "la respuesta a una pregunta, urgente")
	var incident := MessageBuilder.incident(Fixtures.make_incident(), _translate)
	check(incident.urgent and incident.opens_help, "un accidente abre la emergencia")
	var line := MessageBuilder.line(ChatMessage.Sender.FRIEND, "K_LINE", _translate)
	check(not line.urgent and not line.opens_help, "una línea del vlog, no")
	return true
