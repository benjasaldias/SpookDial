extends RefCounted
## Un mensaje del chat, separado en piezas para la estática y las frases clickeables (docs/02 §3–4).
## Las piezas se muestran seguidas: los espacios y los signos también son piezas.

const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Quién escribe: un amigo, Matías o el juego (sus avisos, como el de daño).
enum Sender { FRIEND, PLAYER, SYSTEM }
## Un aviso del juego trae una mala noticia, en rojo, o una buena, en verde.
enum Tone { DANGER, GOOD }

## Lo que se ve en lugar de una palabra tapada. Siempre igual, para no revelar cuántas letras tenía.
const COVER_TEXT := "▒▒▒"
## Una frase entre asteriscos, un espacio o una palabra con sus signos pegados.
const PIECE_PATTERN := "\\*[^*]+\\*|\\s+|[^\\s*]+"


## Una pieza del mensaje: una palabra, un espacio o una frase clickeable.
class Token:
	var text: String
	## id de la característica o del señuelo; vacío si la pieza no se puede clickear.
	var clue_id: StringName
	var covered := false
	## Es el audio del mensaje: se clickea para escucharlo.
	var is_audio := false
	## Es parte de una observación, lo que decide la fila de la tabla: el chat la muestra en azul (decisión de Benja,
	## 11 de noviembre).
	var is_observation := false

	func _init(token_text: String, token_clue_id: StringName = &"") -> void:
		text = token_text
		clue_id = token_clue_id

	func is_clue() -> bool:
		return not clue_id.is_empty()

	## La estática tapa frases clickeables y palabras con letras o números, pero no espacios ni signos sueltos.
	func can_be_covered() -> bool:
		if is_clue():
			return true
		for character: String in text:
			if character.to_upper() != character.to_lower() or character.is_valid_int():
				return true
		return false


var sender: Sender
## Solo cuenta en los avisos del juego.
var tone := Tone.DANGER
var tokens: Array[Token] = []
## La solicitud a la que pertenece el mensaje: de ella salen el estado de cada frase clickeable.
var request: FriendRequest
## El audio que manda el amigo, o null (decisión de Benja, 7 de noviembre).
var audio: AudioStream
## Qué se oye en el audio, para la opción "Subtítulos de los audios".
var audio_caption := ""
## Pide ayuda (Plan 9.8): el mensaje inicial de una consulta, las respuestas, un accidente y la pregunta de una decisión.
## El chat lo marca con "▲" y la barra en rojo, para distinguirlo del vlog.
var urgent := false
## Es lo primero de una emergencia: el chat pone antes una línea "▲ LEÓN PIDE AYUDA".
var opens_help := false


func _init(message_sender: Sender, message_request: FriendRequest) -> void:
	sender = message_sender
	request = message_request


## Agrega una oración. Con `clue_id`, su frase entre asteriscos se vuelve clickeable;
## sin `clue_id`, los asteriscos se quitan y la frase queda como texto normal. Con `observation`, sus piezas quedan
## marcadas como una observación.
func add_fragment(text: String, clue_id: StringName = &"", observation := false) -> void:
	if not tokens.is_empty():
		tokens.append(Token.new(" "))
	for piece: RegExMatch in RegEx.create_from_string(PIECE_PATTERN).search_all(text):
		var piece_text := piece.get_string()
		var token: Token
		if piece_text.begins_with("*"):
			token = Token.new(piece_text.substr(1, piece_text.length() - 2), clue_id)
		else:
			token = Token.new(piece_text)
		token.is_observation = observation
		tokens.append(token)


## Agrega un audio: una sola pieza con `label`, que la estática tapa entera o no tapa.
func add_audio(stream: AudioStream, label: String, caption: String) -> void:
	audio = stream
	audio_caption = caption
	if not tokens.is_empty():
		tokens.append(Token.new(" "))
	var token := Token.new(label)
	token.is_audio = true
	tokens.append(token)


## La estática tapó algo que sirve: una frase clickeable, una palabra de una observación o el audio. Un mensaje sin nada
## de eso (la respuesta de "nada") pierde información con cualquier palabra tapada. Así se sabe si vale la pena volver a
## preguntar (decisión de Benja, 11 de noviembre).
func lost_information() -> bool:
	var informative := false
	for token: Token in tokens:
		if token.is_clue() or token.is_observation or token.is_audio:
			informative = true
			if token.covered:
				return true
	if informative:
		return false
	return tokens.any(func(token: Token) -> bool: return token.covered)


## El texto como se ve, con la estática.
func plain_text() -> String:
	var text := ""
	for token: Token in tokens:
		text += COVER_TEXT if token.covered else token.text
	return text
