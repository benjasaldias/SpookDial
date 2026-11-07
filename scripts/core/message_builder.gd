extends RefCounted
## Arma los mensajes del chat con los fragmentos de data/text/*.csv (docs/02 §9).
## Cada fragmento es una oración, y el mensaje las une con un espacio.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Botón y mensaje de Matías para cada pregunta (ui.csv).
const QUESTION_KEYS := {
	ClueCategory.Kind.SIGHT: "QUESTION_SIGHT",
	ClueCategory.Kind.SOUND: "QUESTION_SOUND",
	ClueCategory.Kind.ENVIRONMENT: "QUESTION_ENVIRONMENT",
	ClueCategory.Kind.TRACES: "QUESTION_TRACES",
}
## Respuesta del amigo cuando no hay nada de esa categoría: "nada" también es información (messages.csv).
const NOTHING_KEYS := {
	ClueCategory.Kind.SIGHT: "ANSWER_NOTHING_SIGHT",
	ClueCategory.Kind.SOUND: "ANSWER_NOTHING_SOUND",
	ClueCategory.Kind.ENVIRONMENT: "ANSWER_NOTHING_ENVIRONMENT",
	ClueCategory.Kind.TRACES: "ANSWER_NOTHING_TRACES",
}
## Lo que se ve en lugar de una observación que el amigo manda como audio (ui.csv).
const AUDIO_LABEL_KEY := "CHAT_AUDIO"
## El amigo decidió solo porque nadie respondió a tiempo. {action} es la acción que eligió (messages.csv).
const DECIDED_ALONE_KEY := "FRIEND_DECIDED_ALONE"
## Lo que cuenta el amigo después de la acción, según el resultado, si no quedó herido (messages.csv).
const REACTION_KEYS := {
	RuleEvaluator.Outcome.CORRECT: "REACTION_CORRECT",
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG",
}
## Lo que cuenta si quedó herido. La acción correcta nunca hiere (messages.csv).
const HURT_REACTION_KEYS := {
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY_HURT",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG_HURT",
}
## El aviso del juego cuando un amigo queda herido (ui.csv). Lleva {friend}, {health} y {max}.
const DAMAGE_KEY := "CHAT_DAMAGE"
## El amigo avisa que mandó un video (messages.csv).
const VIDEO_SENT_KEY := "FRIEND_VIDEO_SENT"
## Avisos del juego sobre los videos y la señal (ui.csv). Llevan {friend}; el del video recibido, también
## {received} y {quota}.
const VIDEO_RECEIVED_KEY := "CHAT_VIDEO_RECEIVED"
const VIDEO_LOST_KEY := "CHAT_VIDEO_LOST"
const SIGNAL_LOST_KEY := "CHAT_SIGNAL_LOST"
const SIGNAL_BACK_KEY := "CHAT_SIGNAL_BACK"


## Mensaje inicial (decisión de Benja, 3-nov): el saludo ("¡Mati, ayuda!!"), dónde está y, a veces, una pista
## (una de las 2 características, clickeable). Todo lo demás se pregunta.
static func first_message(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	if not request.greeting_key.is_empty():
		message.add_fragment(_text(translate, request.greeting_key))
	message.add_fragment(_text(translate, request.place_key))
	if request.hint != null:
		message.add_fragment(_text(translate, request.hint.text_key), request.hint.id)
	return message


## Respuesta a una pregunta: las características y los señuelos de esa categoría (con la pista del mensaje
## inicial, si es de esa categoría) y todas las observaciones de esa categoría. Es la única forma de saberlos.
## Una observación con audio llega como audio: hay que escucharla (decisión de Benja, 7 de noviembre).
static func answer(request: FriendRequest, category: ClueCategory.Kind, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	for clue: TraitData in request.clues:
		if clue.category == category:
			message.add_fragment(_text(translate, clue.text_key), clue.id)
	for observation: ObservationData in request.entity.observations:
		if observation.category != category:
			continue
		var stream := observation.audio_for(request.situation[observation.id])
		if stream != null:
			message.add_audio(stream, _text(translate, AUDIO_LABEL_KEY), _observation_text(request, observation, translate))
		else:
			message.add_fragment(_observation_text(request, observation, translate))
	if message.tokens.is_empty():
		message.add_fragment(_text(translate, NOTHING_KEYS[category]))
	return message


## La pregunta, como mensaje de Matías.
static func question(request: FriendRequest, category: ClueCategory.Kind, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.PLAYER, request)
	message.add_fragment(_text(translate, QUESTION_KEYS[category]))
	return message


## El amigo cuenta que decidió solo y qué hizo. La solicitud ya debe estar terminada.
static func decided_alone(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	var action := _text(translate, request.chosen_action.label_key)
	message.add_fragment(_text(translate, DECIDED_ALONE_KEY).format({"action": action}))
	return message


## La respuesta de Matías: la acción que eligió en el cuaderno. La solicitud ya debe estar terminada.
static func player_answer(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.PLAYER, request)
	message.add_fragment(_text(translate, request.chosen_action.label_key))
	return message


## Lo que cuenta el amigo después de la acción, la haya elegido Matías o él solo: según el resultado
## y si quedó herido. La solicitud ya debe estar terminada.
static func reaction(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	var hurt := request.consequence != null and request.consequence.is_hurt()
	var key: String = HURT_REACTION_KEYS[request.outcome] if hurt else REACTION_KEYS[request.outcome]
	message.add_fragment(_text(translate, key))
	return message


## El aviso del juego, centrado y en rojo, cuando un amigo queda herido: "León recibió daño: 2/3"
## (decisión de Benja). `health` es la vida que le queda.
static func damage_notice(request: FriendRequest, friend_name: String, health: int, max_health: int,
		translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, request)
	message.add_fragment(_text(translate, DAMAGE_KEY).format({"friend": friend_name, "health": health, "max": max_health}))
	return message


## El amigo avisa que mandó un video, que espera su descarga.
static func video_sent(translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment(_text(translate, VIDEO_SENT_KEY))
	return message


## Un aviso del juego, centrado: el texto de `key` con sus `values`. DANGER va en rojo y GOOD, en verde.
static func notice(key: String, values: Dictionary, tone: ChatMessage.Tone, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, null)
	message.tone = tone
	message.add_fragment(_text(translate, key).format(values))
	return message


## Una línea de un chat guionado, del amigo o de Matías, sin solicitud.
static func script_line(line: ChatLineData, translate: Callable) -> ChatMessage:
	var sender := ChatMessage.Sender.PLAYER if line.speaker == ChatLineData.Speaker.PLAYER else ChatMessage.Sender.FRIEND
	var message := ChatMessage.new(sender, null)
	message.add_fragment(_text(translate, line.text_key))
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
	return _text(translate, observation.values[request.situation[observation.id]])


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
