extends MarginContainer
## Un mensaje del chat, como en un chat de texto: el nombre de quien escribe ("LEÓN:") y el mensaje, con
## una barra a la izquierda del color del amigo. Las frases clickeables son enlaces [url] de un
## RichTextLabel, y la estática se ve como ▒▒▒. El nombre aparece de una vez y el mensaje, de a poco.
## Características y señuelos se ven iguales hasta que se clickean: la característica queda marcada
## y el señuelo vibra y queda rojo. Los avisos del juego, como el de daño, van centrados y en rojo.

signal clue_clicked(view: Node, clue_id: StringName)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Velocidad de la escritura progresiva.
const CHARS_PER_SECOND := 60.0
## Cuánto vibra un señuelo al clickearlo.
const SHAKE_SECONDS := 0.6
## Lo que separa la burbuja del borde contrario: el amigo escribe a la izquierda y Matías a la derecha.
const INDENT := 48
const CLUE_COLOR := "ffb347"
const MARKED_COLOR := "7ee08a"
const DECOY_COLOR := "ff4d5e"
const STATIC_COLOR := "56637f"
## Los avisos del juego: los malos, como el de daño, y los buenos, como un video recibido.
const DANGER_COLOR := "ff4d5e"
const GOOD_COLOR := "7ee08a"

var message: ChatMessage
## Quién escribe, en mayúsculas ("LEÓN"), y su color. Sin nombre, el mensaje va sin etiqueta.
var speaker := ""
var speaker_color := Color.WHITE

var _label: RichTextLabel
var _typing: Tween
var _shaking_clue := &""


func _init(chat_message: ChatMessage, speaker_name := "", color := Color.WHITE) -> void:
	message = chat_message
	speaker = speaker_name
	speaker_color = color
	mouse_filter = Control.MOUSE_FILTER_PASS
	var from_player := message.sender == ChatMessage.Sender.PLAYER
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	if message.sender == ChatMessage.Sender.SYSTEM:
		# Los avisos del juego van de borde a borde, sin burbuja.
		bubble.theme_type_variation = &"SystemNotice"
	else:
		add_theme_constant_override(&"margin_left" if from_player else &"margin_right", INDENT)
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
	# Los avisos del juego aparecen de una vez; los mensajes se escriben de a poco.
	_label.visible_ratio = 1.0 if message.sender == ChatMessage.Sender.SYSTEM else 0.0


func _ready() -> void:
	if message.sender == ChatMessage.Sender.SYSTEM:
		return
	if message.sender == ChatMessage.Sender.FRIEND and not speaker.is_empty():
		# La barra de la izquierda, del color del amigo. Si la burbuja llega a ser una textura (el arte del
		# chat), se queda como está.
		var bubble := get_node("Bubble") as PanelContainer
		var style := bubble.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
		if style != null:
			style.border_color = speaker_color
			bubble.add_theme_stylebox_override(&"panel", style)
	# El nombre se ve de una vez; el mensaje se escribe de a poco.
	var start := _speaker_prefix_length()
	var total := _label.get_total_character_count()
	_label.visible_characters = start
	_typing = create_tween()
	_typing.tween_property(_label, ^"visible_characters", total, (total - start) / CHARS_PER_SECOND)


## Muestra el mensaje completo de una vez.
func finish_typing() -> void:
	if _typing != null:
		_typing.kill()
	_label.visible_ratio = 1.0


## Vuelve a armar el texto. Se llama cuando cambia el estado de una frase o termina la solicitud.
func refresh() -> void:
	if message.sender == ChatMessage.Sender.SYSTEM:
		var color := GOOD_COLOR if message.tone == ChatMessage.Tone.GOOD else DANGER_COLOR
		_label.text = "[center]%s[/center]" % _colored("── %s ──" % message.plain_text().replace("[", "[lb]"), color)
		return
	var parts := PackedStringArray()
	if not speaker.is_empty():
		parts.append(_colored(speaker + ":", speaker_color.to_html(false)) + " ")
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


## Cuántas letras ocupa "LEÓN: ", que se ven antes de que empiece a escribir.
func _speaker_prefix_length() -> int:
	return 0 if speaker.is_empty() else speaker.length() + 2


func _on_meta_clicked(meta: Variant) -> void:
	clue_clicked.emit(self, StringName(str(meta)))


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]
