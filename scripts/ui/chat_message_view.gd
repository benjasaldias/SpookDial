extends MarginContainer
## Burbuja de un mensaje del chat (Plan 3). Las frases clickeables son enlaces [url] de un RichTextLabel,
## y la estática se ve como ▒▒▒. El texto aparece escrito de a poco.
## Características y señuelos se ven iguales hasta que se clickean: la característica queda marcada
## y el señuelo vibra y queda rojo. Los colores son provisionales hasta el arte del chat.

signal clue_clicked(view: Node, clue_id: StringName)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Velocidad de la escritura progresiva.
const CHARS_PER_SECOND := 60.0
## Cuánto vibra un señuelo al clickearlo.
const SHAKE_SECONDS := 0.6
## Lo que separa la burbuja del borde contrario: el amigo escribe a la izquierda y Matías a la derecha.
const INDENT := 48
const CLUE_COLOR := "f2b84b"
const MARKED_COLOR := "7ee08a"
const DECOY_COLOR := "ff6464"
const STATIC_COLOR := "8792a2"

var message: ChatMessage

var _label: RichTextLabel
var _typing: Tween
var _shaking_clue := &""


func _init(chat_message: ChatMessage) -> void:
	message = chat_message
	mouse_filter = Control.MOUSE_FILTER_PASS
	var from_player := message.sender == ChatMessage.Sender.PLAYER
	add_theme_constant_override(&"margin_left" if from_player else &"margin_right", INDENT)
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	bubble.theme_type_variation = &"PlayerBubble" if from_player else &"FriendBubble"
	# PASS deja que la rueda del mouse llegue al ScrollContainer de la conversación.
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bubble)
	_label = RichTextLabel.new()
	_label.name = "Text"
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.meta_clicked.connect(_on_meta_clicked)
	bubble.add_child(_label)
	refresh()
	_label.visible_ratio = 0.0


func _ready() -> void:
	var seconds := _label.get_total_character_count() / CHARS_PER_SECOND
	_typing = create_tween()
	_typing.tween_property(_label, ^"visible_ratio", 1.0, seconds)


## Muestra el mensaje completo de una vez.
func finish_typing() -> void:
	if _typing != null:
		_typing.kill()
	_label.visible_ratio = 1.0


## Vuelve a armar el texto. Se llama cuando cambia el estado de una frase o termina la solicitud.
func refresh() -> void:
	var parts := PackedStringArray()
	for token: ChatMessage.Token in message.tokens:
		parts.append(_token_bbcode(token))
	_label.text = "".join(parts)


## El señuelo clickeado vibra un momento; después queda rojo.
func shake(clue_id: StringName) -> void:
	_shaking_clue = clue_id
	refresh()
	create_tween().tween_callback(_stop_shaking).set_delay(SHAKE_SECONDS)


func _stop_shaking() -> void:
	_shaking_clue = &""
	refresh()


func _token_bbcode(token: ChatMessage.Token) -> String:
	if token.covered:
		return _colored(ChatMessage.COVER_TEXT, STATIC_COLOR)
	# [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
	var text := token.text.replace("[", "[lb]")
	if not token.is_clue():
		return text
	match message.request.clue_state(token.clue_id):
		FriendRequest.ClueState.MARKED:
			return _colored(text, MARKED_COLOR)
		FriendRequest.ClueState.DECOY:
			var red := _colored(text, DECOY_COLOR)
			return "[shake rate=30 level=10]%s[/shake]" % red if token.clue_id == _shaking_clue else red
	if message.request.finished:
		return _colored(text, CLUE_COLOR)
	return "[url=%s]%s[/url]" % [token.clue_id, _colored(text, CLUE_COLOR)]


func _on_meta_clicked(meta: Variant) -> void:
	clue_clicked.emit(self, StringName(str(meta)))


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]
