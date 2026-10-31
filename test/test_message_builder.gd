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
## entre las dos, o1 (Vista) = yes y o2 (Sonido) = no; el mensaje inicial trae solo o2.
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
	request.first_clues.assign([entity.traits[0], request.decoys[0], entity.traits[1]])
	request.first_observations.assign([entity.observations[1]])
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
	check_eq(message.plain_text(), "K_PLACE. Hay K_TRAIT_beast_trait_1. Hay K_DECOY_decoy_sight. Hay K_TRAIT_beast_trait_2. K_beast_O2_NO.",
			"lugar, frases en su orden y la observación que trae")
	check_eq(_clue_ids(message), [&"beast_trait_1", &"decoy_sight", &"beast_trait_2"], "frases clickeables")
	return true


func test_respuesta_a_una_pregunta() -> bool:
	var request := _make_request()
	var sight := MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate)
	check_eq(sight.plain_text(), "Hay K_TRAIT_beast_trait_1. Hay K_DECOY_decoy_sight. K_beast_O1_YES.",
			"Vista: también la observación que el mensaje inicial no traía")
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
