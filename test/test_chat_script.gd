extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatScript := preload("res://scripts/core/chat_script.gd")
const Fixtures := preload("res://test/content_fixtures.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")


## Un chat guionado de prueba: el amigo, Matías y el amigo otra vez.
func _chat_data(friend: FriendData) -> ChatScriptData:
	var data := ChatScriptData.new()
	data.friend = friend
	for entry: Array in [[ChatLineData.Speaker.FRIEND, "K_LINE_1"], [ChatLineData.Speaker.PLAYER, "K_LINE_2"],
			[ChatLineData.Speaker.FRIEND, "K_LINE_3"]]:
		var line := ChatLineData.new()
		line.speaker = entry[0]
		line.text_key = entry[1]
		data.lines.append(line)
	return data


func _make_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


func test_el_amigo_escribe_y_matias_responde_con_un_boton() -> bool:
	var chat := ChatScript.new(_chat_data(FriendData.new()), 1)
	check_eq(chat.advance(2.0), null, "el amigo está escribiendo")
	var first := chat.advance(0.5)
	check(first != null and first.text_key == "K_LINE_1", "a los 2,5 s llega su línea")
	var reply := chat.pending_reply()
	check(reply != null and reply.text_key == "K_LINE_2", "espera la respuesta de Matías")
	check_eq(chat.advance(30.0), null, "sin respuesta, el amigo espera")
	check_eq(chat.reply(), reply, "Matías responde")
	check_eq(chat.pending_reply(), null, "ya respondió")
	check_eq(chat.advance(2.0), null, "el amigo escribe")
	var last := chat.advance(0.5)
	check(last != null and last.text_key == "K_LINE_3", "llega la última")
	check(chat.is_done(), "terminó")
	check_eq(chat.reply(), null, "ya no hay nada que responder")
	return true


func test_el_manager_escribe_el_chat_guionado() -> bool:
	var manager := _make_manager()
	var events := []
	manager.message_added.connect(func(friend_index: int, message: ChatMessage) -> void:
		events.append([friend_index, message]))
	var finished := []
	manager.chat_script_finished.connect(func(chat: ChatScript) -> void: finished.append(chat))
	manager.start_chat_script(_chat_data(manager.catalog.friends[1]))
	manager.advance(2.5)
	check_eq(events.size(), 1, "Gonzalo escribe")
	if events.size() == 1:
		check_eq(events[0][0], 1, "en el chat de Gonzalo")
		check_eq((events[0][1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "lo escribe él")
		check_eq((events[0][1] as ChatMessage).plain_text(), String(TranslationServer.translate("K_LINE_1")), "su línea")
	check(manager.chat_script_reply(1) != null, "espera la respuesta de Matías")
	check_eq(manager.chat_script_reply(0), null, "en el chat de León, nada")
	check(manager.reply_chat_script(), "Matías responde")
	check_eq((events[-1][1] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "lo escribe Matías")
	check(not manager.reply_chat_script(), "no responde dos veces")
	manager.advance(2.5)
	check_eq(events.size(), 3, "llega la última línea")
	check_eq(finished.size(), 1, "terminó")
	check_eq(manager.chat_script, null, "ya no hay chat guionado")
	manager.free()
	return true


## El chat del susto ya no está en la noche 0 (decisión de Benja, 11 de noviembre): queda guardado para la historia.
func test_el_chat_del_susto_queda_guardado() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var chat: ChatScriptData = load("res://data/scripts/scare_chat.tres")
	check(chat != null, "existe")
	if chat == null:
		return true
	check_eq(chat.friend, catalog.friends[1], "lo escribe Gonzalo")
	check_eq(chat.lines.map(func(line: ChatLineData) -> int: return line.speaker),
			[ChatLineData.Speaker.FRIEND, ChatLineData.Speaker.PLAYER, ChatLineData.Speaker.FRIEND],
			"Gonzalo, Matías y Gonzalo")
	check(chat.highlight_phone, "después, el celular parpadea")
	return true
