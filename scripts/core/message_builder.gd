extends RefCounted
## Arma los mensajes del chat con los fragmentos de data/text/*.csv (docs/02 §9).
## Cada fragmento es una oración, y el mensaje las une con un espacio.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

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
## El amigo decidió solo porque nadie respondió a tiempo. {action} es la acción que eligió (messages.csv).
const DECIDED_ALONE_KEY := "FRIEND_DECIDED_ALONE"


## Mensaje inicial: dónde está, las características y los señuelos mezclados, y sus observaciones.
static func first_message(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment(_text(translate, request.place_key))
	for clue: TraitData in request.first_clues:
		message.add_fragment(_text(translate, clue.text_key), clue.id)
	for observation: ObservationData in request.first_observations:
		message.add_fragment(_observation_text(request, observation, translate))
	return message


## Respuesta a una pregunta: repite las características y los señuelos del mensaje inicial que son
## de esa categoría, y todas las observaciones de esa categoría, también las que no traía.
static func answer(request: FriendRequest, category: ClueCategory.Kind, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	for clue: TraitData in request.first_clues:
		if clue.category == category:
			message.add_fragment(_text(translate, clue.text_key), clue.id)
	for observation: ObservationData in request.entity.observations:
		if observation.category == category:
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


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
	return _text(translate, observation.values[request.situation[observation.id]])


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
