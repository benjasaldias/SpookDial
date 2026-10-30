extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")


## Traducción falsa: cada característica y señuelo tiene su clave como frase clickeable.
func _translate(key: String) -> String:
	if key.begins_with("K_TRAIT_") or key.begins_with("K_DECOY_"):
		return "Hay *%s*." % key
	if key == MessageBuilder.DECIDED_ALONE_KEY:
		return "Decidí solo: {action}"
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


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var keys: Array = MessageBuilder.QUESTION_KEYS.values() + MessageBuilder.NOTHING_KEYS.values()
	keys.append(MessageBuilder.DECIDED_ALONE_KEY)
	for key: String in keys:
		check(String(TranslationServer.translate(key)) != key, "falta %s en los CSV" % key)
	check(String(TranslationServer.translate(MessageBuilder.DECIDED_ALONE_KEY)).contains("{action}"),
			"FRIEND_DECIDED_ALONE debe tener {action}")
	TranslationServer.set_locale(previous)
	return true
