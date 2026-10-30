extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")


func _message(text: String, clue_id: StringName = &"") -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment(text, clue_id)
	return message


func _texts(message: ChatMessage) -> Array:
	return message.tokens.map(func(token: ChatMessage.Token) -> String: return token.text)


func test_una_oracion_se_separa_en_palabras_y_espacios() -> bool:
	var message := _message("Hola,  mundo")
	check_eq(_texts(message), ["Hola,", "  ", "mundo"], "piezas")
	check_eq(message.plain_text(), "Hola,  mundo", "texto")
	return true


func test_la_frase_entre_asteriscos_es_clickeable() -> bool:
	var message := _message("Lleva *ropa de fibra vegetal*, como de paja", &"plant_fiber_clothes")
	check_eq(_texts(message), ["Lleva", " ", "ropa de fibra vegetal", ",", " ", "como", " ", "de", " ", "paja"], "piezas")
	var clue: ChatMessage.Token = message.tokens[2]
	check_eq(clue.clue_id, &"plant_fiber_clothes", "id de la frase")
	check(clue.is_clue(), "es clickeable")
	check(not (message.tokens[0] as ChatMessage.Token).is_clue(), "una palabra normal no lo es")
	check_eq(message.plain_text(), "Lleva ropa de fibra vegetal, como de paja", "sin asteriscos")
	return true


func test_sin_id_los_asteriscos_se_quitan() -> bool:
	var message := _message("Un *olor* raro")
	check_eq(message.plain_text(), "Un olor raro", "texto")
	for token: ChatMessage.Token in message.tokens:
		check(not token.is_clue(), "nada clickeable: <%s>" % token.text)
	return true


func test_las_oraciones_se_unen_con_un_espacio() -> bool:
	var message := _message("Estoy en el bosque.")
	message.add_fragment("Hay *neblina*.", &"fog")
	check_eq(message.plain_text(), "Estoy en el bosque. Hay neblina.", "texto")
	return true


func test_que_puede_tapar_la_estatica() -> bool:
	var message := _message("¿Árboles? 3 , ñandú *frase larga*", &"clue")
	var coverable := {}
	for token: ChatMessage.Token in message.tokens:
		coverable[token.text] = token.can_be_covered()
	check_eq(coverable, {"¿Árboles?": true, " ": false, "3": true, ",": false, "ñandú": true, "frase larga": true},
			"qué se puede tapar")
	return true


func test_lo_tapado_se_ve_como_estatica() -> bool:
	var message := _message("Vi un *hombrecito* raro", &"little_man")
	(message.tokens[4] as ChatMessage.Token).covered = true
	(message.tokens[6] as ChatMessage.Token).covered = true
	check_eq(message.plain_text(), "Vi un %s %s" % [ChatMessage.COVER_TEXT, ChatMessage.COVER_TEXT], "texto con estática")
	return true
