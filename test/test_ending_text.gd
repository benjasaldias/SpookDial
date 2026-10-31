extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const EndingText := preload("res://scripts/core/ending_text.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")

const FORMATS := {
	"END_WON": "Ganaste con {received} de {quota}.",
	"END_QUOTA": "Faltó: {received} de {quota}.",
	"END_FRIEND_DIED": "Murió {friend}.",
	"END_ENTITY": "Era {entity}.",
	"END_RULE": "Regla {number}: {rule}.",
	"END_CORRECT": "Correcta: {action}.",
	"END_CHOSEN_BY_PLAYER": "Respondiste: {action}.",
	"END_CHOSEN_ALONE": "{friend} eligió solo: {action}.",
}
const FRIENDS: Array[String] = ["León", "Gonzalo", "Agustín"]


## Traducción falsa: los formatos de FORMATS, y cualquier otra clave tal cual.
func _translate(key: String) -> String:
	return FORMATS.get(key, key)


## El texto como se ve: sin etiquetas BBCode y con [lb] convertido en corchete.
func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[(?!lb\\])[^\\]]*\\]").sub(bbcode, "", true).replace("[lb]", "[")


## Estado de la noche 1 del catálogo de prueba: cuota de 2 videos.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	return NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())


## Gonzalo y "beast", con o1 = no y o2 = yes: se aplica la regla 2 (correcta a3, mayor riesgo a4).
func _fatal_request(action_id: StringName, by_player: bool) -> FriendRequest:
	var request := FriendRequest.new()
	request.friend_index = 1
	request.entity = Fixtures.make_entity()
	request.situation = {&"o1": &"no", &"o2": &"yes"}
	request.finish(request.entity.find_action(action_id), by_player)
	return request


func test_titulos() -> bool:
	check_eq(EndingText.title(NightState.Ending.WON, _translate), "END_WON_TITLE", "ganó")
	for ending: NightState.Ending in [NightState.Ending.FRIEND_DIED, NightState.Ending.SANITY, NightState.Ending.QUOTA]:
		check_eq(EndingText.title(ending, _translate), "END_LOST_TITLE", "perdió (%d)" % ending)
	return true


func test_los_videos_al_ganar_o_al_faltar() -> bool:
	var state := _make_state()
	state.videos.received = 2
	check_eq(EndingText.body(NightState.Ending.WON, state, null, FRIENDS, _translate), "Ganaste con 2 de 2.", "ganó")
	state.videos.received = 1
	check_eq(EndingText.body(NightState.Ending.QUOTA, state, null, FRIENDS, _translate), "Faltó: 1 de 2.", "faltó")
	return true


func test_un_dial_en_0() -> bool:
	var state := _make_state()
	var expected := {
		NightState.Ending.SANITY: "END_SANITY",
		NightState.Ending.TRUST: "END_TRUST",
		NightState.Ending.CONNECTION: "END_CONNECTION",
	}
	for ending: NightState.Ending in expected:
		check_eq(EndingText.body(ending, state, null, FRIENDS, _translate), expected[ending], "dial %d" % ending)
	return true


func test_si_murio_un_amigo_explica_la_solicitud() -> bool:
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a4", true), FRIENDS, _translate)
	var expected := "\n".join([
		"Murió Gonzalo.",
		"",
		"Era K_beast_NAME.",
		"END_SITUATION",
		"• K_beast_O1_Q — K_beast_O1_NO",
		"• K_beast_O2_Q — K_beast_O2_YES",
		"Regla 2: K_RULE.",
		"Correcta: K_beast_A3.",
		"Respondiste: K_beast_A4.",
	])
	check_eq(_plain(body), expected, "la explicación")
	check(body.contains("[color=#%s]K_beast_A3[/color]" % EndingText.CORRECT_COLOR), "la correcta, en verde")
	check(body.contains("[color=#%s]K_beast_A4[/color]" % EndingText.CHOSEN_COLOR), "la elegida, en rojo")
	return true


func test_si_el_amigo_decidio_solo() -> bool:
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a1", false), FRIENDS, _translate)
	check(_plain(body).ends_with("Gonzalo eligió solo: K_beast_A1."), "dice que nadie respondió: %s" % _plain(body))
	return true


func test_los_corchetes_se_ven_como_texto() -> bool:
	var proto := func(key: String) -> String: return "[PROTO] " + _translate(key)
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a4", true), FRIENDS, proto)
	check(not body.contains("[PROTO]"), "[PROTO] no se lee como etiqueta")
	check(_plain(body).begins_with("[PROTO] Murió Gonzalo."), "se ve el corchete")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var keys: Array = [EndingText.WON_TITLE_KEY, EndingText.LOST_TITLE_KEY, EndingText.ENTITY_KEY, EndingText.SITUATION_KEY,
			EndingText.RULE_KEY, EndingText.CORRECT_KEY, EndingText.CHOSEN_BY_PLAYER_KEY, EndingText.CHOSEN_ALONE_KEY]
	keys.append_array(EndingText.REASON_KEYS.values())
	for key: String in keys:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var placeholders := {
		"END_WON": ["{received}", "{quota}"],
		"END_QUOTA": ["{received}", "{quota}"],
		"END_FRIEND_DIED": ["{friend}"],
		"END_ENTITY": ["{entity}"],
		"END_RULE": ["{number}", "{rule}"],
		"END_CORRECT": ["{action}"],
		"END_CHOSEN_BY_PLAYER": ["{action}"],
		"END_CHOSEN_ALONE": ["{friend}", "{action}"],
	}
	for key: String in placeholders:
		for placeholder: String in placeholders[key]:
			check(String(TranslationServer.translate(key)).contains(placeholder), "%s debe tener %s" % [key, placeholder])
	TranslationServer.set_locale(previous)
	return true
