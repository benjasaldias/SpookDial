extends MarginContainer
## Un mensaje del chat, como en un chat de texto: el nombre de quien escribe ("LEÓN:") y el mensaje, con
## una barra a la izquierda del color del amigo. Las frases clickeables son enlaces [url] de un
## RichTextLabel, y la estática se ve como ▒▒▒. El nombre aparece de una vez y el mensaje, de a poco.
## Características y señuelos se ven iguales hasta que se clickean: la característica queda marcada
## y el señuelo vibra y queda rojo. Los avisos del juego, como el de daño, van centrados y en rojo.
## Un audio es otro enlace: se escucha con un clic (decisión de Benja, 7 de noviembre).
## Lo decisivo va en azul (decisión de Benja, 11 de noviembre): las observaciones, que deciden la fila de la tabla y no se
## clickean, y el audio, que también es una observación. Las características y los señuelos siguen en amarillo.
## En Difícil no se destaca nada (decisión de Benja, D3): las frases y las observaciones van como el resto del texto, sin
## enlaces. Solo el audio sigue en azul y con su clic, porque es la forma de oírlo (decisión de Benja, S21i).
## Cada letra que aparece se avisa, para la voz del amigo (decisión de Benja, 8 de noviembre).
## En la noche 0 (Plan 9.5), el chat apaga los enlaces de las frases hasta que León pide marcarlas, y entonces las hace
## latir (subrayadas, con "Reducir destellos"); lo mismo con el audio, que después se puede volver a escuchar.

signal clue_clicked(view: Node, clue_id: StringName)
## Clic en el audio del mensaje.
signal audio_clicked(view: Node)
## Apareció una letra del mensaje.
signal letter_typed(letter: String)
## Terminó de escribirse (o se mostró completo de una vez).
signal typing_finished

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Velocidad de la escritura progresiva.
const CHARS_PER_SECOND := 60.0
## Cuánto vibra un señuelo al clickearlo.
const SHAKE_SECONDS := 0.6
## Lo que separa la burbuja del borde contrario: el amigo escribe a la izquierda y Matías a la derecha.
const INDENT := 48
## El enlace del audio, que no se confunde con el id de una frase clickeable.
const AUDIO_META := "__audio"
## Cómo late lo que hay que apretar en el tutorial: al ritmo del borde que parpadea (Highlight), hasta un cuarto de su
## brillo.
const ATTENTION_OPEN := "[pulse freq=1.25 color=#ffffff40 ease=-2.0]"
const ATTENTION_CLOSE := "[/pulse]"
## El azul de lo decisivo: más saturado que el de Gonzalo (80a6ff) y lejos del cian de Matías (40c2c9).
const OBSERVATION_COLOR := "4d9dff"
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
## Se muestra qué se oye en el audio: la opción "Subtítulos de los audios".
var show_caption := false
## Se destaca lo que importa (Normal): las características y los señuelos en amarillo y clickeables, y las observaciones
## en azul. Sin esto (Difícil), solo el audio.
var highlights := true
## Las frases sin marcar se pueden clickear.
var links_enabled := true
## Las frases sin marcar laten: hay que marcarlas.
var attention := false
## El audio se puede escuchar, y late.
var audio_enabled := true
var audio_attention := false
## La opción "Reducir destellos": lo que hay que apretar va subrayado en vez de latir.
var reduce_flashes := false

var _label: RichTextLabel
var _typing: Tween
## El mensaje anterior de la conversación: este empieza a escribirse cuando ese termina, como una cola (pedido de
## Benja, 11 de noviembre). Lo pone el panel antes de agregarlo.
var wait_for: Node
## Ya terminó de escribirse.
var _done := false
## Cuántas letras se ven ya, con el nombre.
var _typed := 0
var _shaking_clue := &""


func _init(chat_message: ChatMessage, speaker_name := "", color := Color.WHITE, caption := false,
		highlighted := true) -> void:
	message = chat_message
	speaker = speaker_name
	speaker_color = color
	show_caption = caption
	highlights = highlighted
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
		_done = true
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
	_typed = start
	if wait_for != null and is_instance_valid(wait_for) and not wait_for.is_done():
		wait_for.typing_finished.connect(_start_typing, CONNECT_ONE_SHOT)
	else:
		_start_typing()


## Ya terminó de escribirse.
func is_done() -> bool:
	return _done


func _start_typing() -> void:
	if _done or not is_inside_tree():
		return
	var total := _label.get_total_character_count()
	_typing = create_tween()
	_typing.tween_method(_type_to, float(_typed), float(total), (total - _typed) / CHARS_PER_SECOND)
	_typing.finished.connect(_mark_done)


func _mark_done() -> void:
	if _done:
		return
	_done = true
	typing_finished.emit()


## Deja ver hasta la letra `count` y avisa cada letra nueva.
func _type_to(count: float) -> void:
	var target := int(count)
	var text := _label.get_parsed_text()
	for index in range(_typed, mini(target, text.length())):
		letter_typed.emit(text[index])
	_typed = maxi(_typed, target)
	_label.visible_characters = target


## Muestra el mensaje completo de una vez.
func finish_typing() -> void:
	if _typing != null:
		_typing.kill()
	_label.visible_ratio = 1.0
	_mark_done()


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
	if token.is_audio:
		return _audio_bbcode(text)
	if not highlights:
		return text
	if token.is_observation:
		return _colored(text, OBSERVATION_COLOR)
	if not token.is_clue():
		return text
	match message.request.clue_state(token.clue_id):
		FriendRequest.ClueState.MARKED:
			return _colored(text, MARKED_COLOR)
		FriendRequest.ClueState.DECOY:
			var red := _colored(text, DECOY_COLOR)
			if token.clue_id != _shaking_clue:
				return red
			return "[shake rate=30 level=10]%s[/shake]" % red
	if message.request.finished:
		return _colored(text, CLUE_COLOR)
	var clue := _attention(_colored(text, CLUE_COLOR), attention)
	if not links_enabled:
		return clue
	return "[url=%s]%s[/url]" % [token.clue_id, clue]


## El audio se escucha con un clic, hasta que termina su solicitud. Con la opción, se lee qué se oye.
func _audio_bbcode(text: String) -> String:
	var bbcode := _attention(_colored(text, OBSERVATION_COLOR), audio_attention)
	if audio_enabled and (message.request == null or not message.request.finished):
		bbcode = "[url=%s]%s[/url]" % [AUDIO_META, bbcode]
	if show_caption:
		bbcode += " (%s)" % message.audio_caption.replace("[", "[lb]")
	return bbcode


## `bbcode` late si `wanted`, o va subrayado con "Reducir destellos".
func _attention(bbcode: String, wanted: bool) -> String:
	if not wanted:
		return bbcode
	if reduce_flashes:
		return "[u]%s[/u]" % bbcode
	return ATTENTION_OPEN + bbcode + ATTENTION_CLOSE


## Cuántas letras ocupa "LEÓN: ", que se ven antes de que empiece a escribir.
func _speaker_prefix_length() -> int:
	return 0 if speaker.is_empty() else speaker.length() + 2


func _on_meta_clicked(meta: Variant) -> void:
	if str(meta) == AUDIO_META:
		audio_clicked.emit(self)
	else:
		clue_clicked.emit(self, StringName(str(meta)))


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]
