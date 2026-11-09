extends "res://test/test_case.gd"
## La voz de un amigo mientras escribe: un sonido corto cada tantas letras, como en Undertale (decisión de Benja,
## 8 de noviembre).

const ChatVoice := preload("res://scripts/core/chat_voice.gd")


func _friend(every := 3, pitch := 1.0, spread := 0.1) -> FriendData:
	var friend := FriendData.new()
	friend.voice_every = every
	friend.voice_pitch = pitch
	friend.voice_spread = spread
	return friend


func test_suena_cada_tantas_letras_desde_la_primera() -> bool:
	var voice := ChatVoice.new(_friend(3))
	var sounded: Array = []
	for letter in "abcdefg":
		sounded.append(voice.next_pitch(letter) > 0.0)
	check_eq(sounded, [true, false, false, true, false, false, true], "la 1, la 4 y la 7")
	return true


func test_los_espacios_y_la_puntuacion_no_suenan_ni_cuentan() -> bool:
	var voice := ChatVoice.new(_friend(2))
	check(voice.next_pitch("a") > 0.0, "la primera letra suena")
	for silent in [" ", ".", "¡", "?", ",", "▒", "3"]:
		check_eq(voice.next_pitch(silent), 0.0, "'%s' no suena" % silent)
	check_eq(voice.next_pitch("b"), 0.0, "los silencios no contaron: toca callar")
	check(voice.next_pitch("c") > 0.0, "y vuelve a sonar")
	return true


func test_las_letras_con_acento_y_las_mayusculas_suenan() -> bool:
	for letter in ["é", "Ñ", "M"]:
		check(ChatVoice.new(_friend(1)).next_pitch(letter) > 0.0, letter + " suena")
	return true


## La misma letra siempre suena igual, así que una palabra repetida se oye igual.
func test_la_altura_depende_de_la_letra() -> bool:
	var voice := ChatVoice.new(_friend(1))
	check_eq(voice.next_pitch("a"), voice.next_pitch("a"), "la misma letra, la misma altura")
	check_eq(voice.next_pitch("a"), voice.next_pitch("A"), "con mayúscula, también")
	var pitches := {}
	for letter in "abcde":
		pitches[voice.next_pitch(letter)] = true
	check(pitches.size() > 1, "las letras varían")
	return true


func test_la_altura_queda_dentro_de_su_rango() -> bool:
	var voice := ChatVoice.new(_friend(1, 2.0, 0.1))
	for letter in "abcdefghijklmnopqrstuvwxyzáéíóúñ":
		var pitch := voice.next_pitch(letter)
		check(pitch >= 2.0 * 0.9 - 0.001 and pitch <= 2.0 * 1.1 + 0.001, "%s: %s" % [letter, pitch])
	return true
