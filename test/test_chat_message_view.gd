extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")


## Solicitud de "beast" con sus 2 características y el señuelo "decoy_sight".
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.time_left = 30.0
	return request


## Mensaje del amigo: "[PROTO] Hay un pelaje y frío.", con "pelaje" (beast_trait_1) y "frío" (decoy_sight) clickeables.
func _make_message(request: FriendRequest, sender := ChatMessage.Sender.FRIEND) -> ChatMessage:
	var message := ChatMessage.new(sender, request)
	message.add_fragment("[PROTO] Hay un *pelaje*", &"beast_trait_1")
	message.add_fragment("y *frío*.", &"decoy_sight")
	return message


func _make_view(message: ChatMessage) -> ChatMessageView:
	var view := ChatMessageView.new(message)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	return view


func _label(view: ChatMessageView) -> RichTextLabel:
	return view.get_node("Bubble/Text") as RichTextLabel


func test_texto_con_frases_clickeables() -> bool:
	var view := _make_view(_make_message(_make_request()))
	var label := _label(view)
	check_eq(label.get_parsed_text(), "[PROTO] Hay un pelaje y frío.", "texto visible, con el [PROTO]")
	check(label.text.contains("[url=beast_trait_1]"), "la característica es un enlace")
	check(label.text.contains("[url=decoy_sight]"), "el señuelo también, y se ve igual")
	view.free()
	return true


func test_la_estatica_no_se_puede_clickear() -> bool:
	var message := _make_message(_make_request())
	for token: ChatMessage.Token in message.tokens:
		token.covered = token.clue_id == &"beast_trait_1"
	var view := _make_view(message)
	check(not _label(view).text.contains("[url=beast_trait_1]"), "tapada: sin enlace")
	check(_label(view).get_parsed_text().contains(ChatMessage.COVER_TEXT), "se ve la estática")
	view.free()
	return true


func test_marcada_y_senuelo_dejan_de_ser_enlaces() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"decoy_sight")
	view.refresh()
	var text := _label(view).text
	check(not text.contains("[url"), "sin enlaces")
	check(text.contains(ChatMessageView.MARKED_COLOR), "característica marcada")
	check(text.contains(ChatMessageView.DECOY_COLOR), "señuelo en rojo")
	view.free()
	return true


func test_el_senuelo_vibra() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.click_clue(&"decoy_sight")
	view.shake(&"decoy_sight")
	check(_label(view).text.contains("[shake"), "vibra")
	view._stop_shaking()
	check(not _label(view).text.contains("[shake"), "deja de vibrar")
	view.free()
	return true


func test_solicitud_terminada_sin_enlaces() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.finish(request.entity.actions[0], true)
	view.refresh()
	check(not _label(view).text.contains("[url"), "ya no se clickea")
	view.free()
	return true


func test_escritura_progresiva() -> bool:
	var view := _make_view(_make_message(_make_request()))
	check_eq(_label(view).visible_ratio, 0.0, "empieza sin texto")
	view.finish_typing()
	check_eq(_label(view).visible_ratio, 1.0, "se muestra completo")
	view.free()
	return true


func test_clic_en_una_frase_avisa() -> bool:
	var view := _make_view(_make_message(_make_request()))
	var clicked := []
	view.clue_clicked.connect(func(source: Node, clue_id: StringName) -> void: clicked.append([source, clue_id]))
	_label(view).meta_clicked.emit("decoy_sight")
	check_eq(clicked, [[view, &"decoy_sight"]], "avisa qué frase")
	view.free()
	return true


func test_burbuja_del_amigo_y_de_matias() -> bool:
	var request := _make_request()
	var friend_view := _make_view(_make_message(request))
	var player_view := _make_view(_make_message(request, ChatMessage.Sender.PLAYER))
	check_eq((friend_view.get_node("Bubble") as PanelContainer).theme_type_variation, &"FriendBubble", "amigo")
	check_eq(friend_view.get_theme_constant(&"margin_right"), ChatMessageView.INDENT, "amigo a la izquierda")
	check_eq((player_view.get_node("Bubble") as PanelContainer).theme_type_variation, &"PlayerBubble", "Matías")
	check_eq(player_view.get_theme_constant(&"margin_left"), ChatMessageView.INDENT, "Matías a la derecha")
	friend_view.free()
	player_view.free()
	return true


func test_el_nombre_de_quien_escribe() -> bool:
	var color := Color(1, 0.56, 0.68)
	var view := ChatMessageView.new(_make_message(_make_request()), "LEÓN", color)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	var label := _label(view)
	check(label.get_parsed_text().begins_with("LEÓN: [PROTO] Hay un pelaje"), "el nombre antes del mensaje: %s" % label.get_parsed_text())
	check(label.text.begins_with("[color=#%s]LEÓN:[/color] " % color.to_html(false)), "en el color del amigo: %s" % label.text)
	check_eq(label.visible_characters, "LEÓN: ".length(), "el nombre se ve antes de que empiece a escribir")
	var style := (view.get_node("Bubble") as PanelContainer).get_theme_stylebox(&"panel") as StyleBoxFlat
	check(style != null and style.border_color == color, "la barra de la izquierda, del color del amigo")
	view.free()
	return true


func test_matias_tambien_lleva_su_nombre() -> bool:
	var request := _make_request()
	var view := ChatMessageView.new(_make_message(request, ChatMessage.Sender.PLAYER), "MATÍAS", Color(0.25, 0.76, 0.79))
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	check(_label(view).get_parsed_text().begins_with("MATÍAS: "), "su nombre: %s" % _label(view).get_parsed_text())
	view.free()
	return true


func test_el_aviso_de_dano_va_centrado_y_en_rojo() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, _make_request())
	message.add_fragment("León recibió daño: 2/3")
	var view := _make_view(message)
	var label := _label(view)
	check_eq(label.get_parsed_text(), "── León recibió daño: 2/3 ──", "entre líneas y sin nombre")
	check(label.text.begins_with("[center]"), "centrado")
	check(label.text.contains(ChatMessageView.DANGER_COLOR), "en rojo")
	check_eq(label.visible_ratio, 1.0, "aparece de una vez")
	check_eq((view.get_node("Bubble") as PanelContainer).theme_type_variation, &"SystemNotice", "sin burbuja")
	check_eq(view.get_theme_constant(&"margin_left"), 0, "de borde a borde, a la izquierda")
	check_eq(view.get_theme_constant(&"margin_right"), 0, "y a la derecha")
	view.free()
	return true


func test_un_aviso_bueno_va_en_verde() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, null)
	message.tone = ChatMessage.Tone.GOOD
	message.add_fragment("Video de León recibido: 1 de 3")
	var view := _make_view(message)
	var label := _label(view)
	check_eq(label.get_parsed_text(), "── Video de León recibido: 1 de 3 ──", "entre líneas")
	check(label.text.begins_with("[center]"), "centrado")
	check(label.text.contains(ChatMessageView.GOOD_COLOR), "en verde")
	check(not label.text.contains(ChatMessageView.DANGER_COLOR), "no en rojo")
	view.free()
	return true


## Un mensaje de la solicitud con un audio.
func _make_audio_message(request: FriendRequest) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_audio(Fixtures.make_audio(), "▶ Audio", "Gritó tres veces.")
	return message


func test_un_audio_es_un_enlace() -> bool:
	var view := _make_view(_make_audio_message(_make_request()))
	check(_label(view).text.contains("[url=%s]" % ChatMessageView.AUDIO_META), "se puede clickear")
	check(not _label(view).get_parsed_text().contains("Gritó"), "sin subtítulo")
	var clicked: Array = []
	view.audio_clicked.connect(func(clicked_view: Node) -> void: clicked.append(clicked_view))
	view._on_meta_clicked(ChatMessageView.AUDIO_META)
	check_eq(clicked, [view], "avisa que se clickeó")
	view.free()
	return true


func test_un_audio_tapado_no_se_puede_escuchar() -> bool:
	var message := _make_audio_message(_make_request())
	message.tokens[-1].covered = true
	var view := _make_view(message)
	check(not _label(view).text.contains("[url"), "sin enlace: hay que volver a preguntar")
	check(_label(view).get_parsed_text().contains(ChatMessage.COVER_TEXT), "se ve tapado")
	view.free()
	return true


func test_un_audio_de_una_solicitud_terminada_no_se_escucha() -> bool:
	var request := _make_request()
	var view := _make_view(_make_audio_message(request))
	request.finished = true
	view.refresh()
	check(not _label(view).text.contains("[url"), "sin enlace")
	view.free()
	return true


func test_el_subtitulo_del_audio() -> bool:
	var view := ChatMessageView.new(_make_audio_message(_make_request()), "", Color.WHITE, true)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	check(_label(view).get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	view.free()
	return true


## El mensaje avisa cada letra que aparece, para la voz del amigo (decisión de Benja, 8 de noviembre). El nombre
## se ve de una vez, así que no cuenta.
func test_avisa_cada_letra_que_se_escribe() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment("Hola")
	var view := ChatMessageView.new(message, "LEÓN", Color.WHITE)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	var letters: Array = []
	view.letter_typed.connect(func(letter: String) -> void: letters.append(letter))
	view._type_to(float(len("LEÓN: ") + 2))
	check_eq(letters, ["H", "o"], "las 2 primeras, sin el nombre")
	check_eq(_label(view).visible_characters, len("LEÓN: ") + 2, "y se ven")
	view._type_to(float(len("LEÓN: ") + 2))
	check_eq(letters.size(), 2, "una letra suena una sola vez")
	view._type_to(float(len("LEÓN: ") + 4))
	check_eq(letters, ["H", "o", "l", "a"], "todas, aunque aparezcan juntas")
	view.free()
	return true


## Las observaciones, lo que decide la fila de la tabla, van en azul y no se clickean; las características, en amarillo y
## clickeables (decisión de Benja, 11 de noviembre).
func test_las_observaciones_van_en_azul() -> bool:
	var request := _make_request()
	var message := _make_message(request)
	message.add_fragment("Está enojado.", &"", true)
	var view := _make_view(message)
	var text := _label(view).text
	check(text.contains("[color=#%s]enojado.[/color]" % ChatMessageView.OBSERVATION_COLOR), "la observación, en azul")
	check(not text.contains("[url=enojado"), "sin enlace")
	check(text.contains("[color=#%s]pelaje" % ChatMessageView.CLUE_COLOR), "la característica sigue en amarillo")
	check(ChatMessageView.OBSERVATION_COLOR != ChatMessageView.CLUE_COLOR, "dos colores distintos")
	view.free()
	return true


## Un audio es una observación: va en azul, y se sigue escuchando con un clic.
func test_el_audio_va_en_azul() -> bool:
	var view := _make_view(_make_audio_message(_make_request()))
	var text := _label(view).text
	check(text.contains("[url=%s][color=#%s]" % [ChatMessageView.AUDIO_META, ChatMessageView.OBSERVATION_COLOR]),
			"en azul y con su enlace: " + text)
	view.free()
	return true
