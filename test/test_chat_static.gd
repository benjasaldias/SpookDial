extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	return rng


## Un mensaje de `words` palabras, separadas por comas y espacios.
func _long_message(words: int) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	var text := PackedStringArray()
	for _i in words:
		text.append("palabra")
	message.add_fragment(" , ".join(text))
	return message


func _covered(message: ChatMessage) -> int:
	return message.tokens.filter(func(token: ChatMessage.Token) -> bool: return token.covered).size()


func test_probabilidad_segun_la_senal() -> bool:
	var expected := {100: 0.0, 70: 0.0, 69: 0.10, 50: 0.10, 49: 0.25, 30: 0.25, 29: 0.45, 1: 0.45}
	for signal_level: int in expected:
		check_eq(ChatStatic.coverage_for_signal(signal_level), expected[signal_level], "señal %d" % signal_level)
	return true


func test_con_senal_alta_no_tapa_nada() -> bool:
	var message := _long_message(200)
	ChatStatic.apply(message, 70.0, _rng())
	check_eq(_covered(message), 0, "palabras tapadas")
	return true


func test_con_senal_baja_tapa_cerca_del_45_por_ciento() -> bool:
	var message := _long_message(1000)
	ChatStatic.apply(message, 10.0, _rng())
	var covered := _covered(message)
	check(covered > 400 and covered < 500, "tapadas: %d de 1000" % covered)
	return true


func test_nunca_tapa_espacios_ni_signos() -> bool:
	var message := _long_message(300)
	ChatStatic.apply(message, 1.0, _rng())
	for token: ChatMessage.Token in message.tokens:
		if not token.can_be_covered():
			check(not token.covered, "tapó <%s>" % token.text)
	return true


func test_una_frase_se_tapa_entera() -> bool:
	var rng := _rng()
	var times_covered := 0
	for _i in 100:
		var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
		message.add_fragment("*ropa de fibra vegetal*", &"clothes")
		ChatStatic.apply(message, 1.0, rng)
		if message.plain_text() == ChatMessage.COVER_TEXT:
			times_covered += 1
		else:
			check_eq(message.plain_text(), "ropa de fibra vegetal", "se ve entera")
	check(times_covered > 20, "a veces se tapa: %d de 100" % times_covered)
	return true
