extends RefCounted
## Un mensaje del chat, separado en piezas para la estática y las frases clickeables (docs/02 §3–4).
## Las piezas se muestran seguidas: los espacios y los signos también son piezas.

const FriendRequest := preload("res://scripts/core/friend_request.gd")

enum Sender { FRIEND, PLAYER }

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
var tokens: Array[Token] = []
## La solicitud a la que pertenece el mensaje: de ella salen el estado de cada frase clickeable.
var request: FriendRequest


func _init(message_sender: Sender, message_request: FriendRequest) -> void:
	sender = message_sender
	request = message_request


## Agrega una oración. Con `clue_id`, su frase entre asteriscos se vuelve clickeable;
## sin `clue_id`, los asteriscos se quitan y la frase queda como texto normal.
func add_fragment(text: String, clue_id: StringName = &"") -> void:
	if not tokens.is_empty():
		tokens.append(Token.new(" "))
	for piece: RegExMatch in RegEx.create_from_string(PIECE_PATTERN).search_all(text):
		var piece_text := piece.get_string()
		if piece_text.begins_with("*"):
			tokens.append(Token.new(piece_text.substr(1, piece_text.length() - 2), clue_id))
		else:
			tokens.append(Token.new(piece_text))


## El texto como se ve, con la estática.
func plain_text() -> String:
	var text := ""
	for token: Token in tokens:
		text += COVER_TEXT if token.covered else token.text
	return text
