extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Solicitud de "beast" con o1 = yes y o2 = no (se aplica la regla 1: correcta a1, mayor riesgo a2),
## sus 2 características, el señuelo "decoy_sight" y 30 segundos para responder.
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.time_left = 30.0
	return request


func test_marcar_las_2_caracteristicas_hace_pensar_a_matias() -> bool:
	var request := _make_request()
	check_eq(request.click_clue(&"beast_trait_1"), FriendRequest.ClueState.MARKED, "primera característica")
	check_eq(request.marked_count(), 1, "marcadas")
	check_eq(request.identification, FriendRequest.Identification.PENDING, "todavía falta una")
	request.click_clue(&"beast_trait_2")
	check_eq(request.identification, FriendRequest.Identification.THINKING, "Matías piensa")
	check_eq(request.thinking_left, FriendRequest.THINKING_TIME, "espera de 3 s")
	return true


func test_el_nombre_aparece_tras_la_espera() -> bool:
	var request := _make_request()
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	check(not request.advance(2.9), "a los 2,9 s sigue pensando")
	check(request.advance(0.2), "a los 3,1 s aparece el nombre")
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "identificada")
	check(not request.advance(1.0), "aparece una sola vez")
	return true


func test_un_senuelo_queda_en_rojo_y_no_cuenta() -> bool:
	var request := _make_request()
	check_eq(request.click_clue(&"decoy_sight"), FriendRequest.ClueState.DECOY, "señuelo")
	check_eq(request.clue_state(&"decoy_sight"), FriendRequest.ClueState.DECOY, "queda en rojo")
	check_eq(request.marked_count(), 0, "no cuenta como característica")
	check_eq(request.click_clue(&"otra"), FriendRequest.ClueState.UNMARKED, "frase que no es de la solicitud")
	return true


func test_preguntar_cuesta_5_segundos() -> bool:
	var request := _make_request()
	check(request.pay_question(), "se puede preguntar")
	check_eq(request.time_left, 25.0, "quedan 25 s")
	return true


func test_con_5_segundos_o_menos_no_se_pregunta() -> bool:
	var request := _make_request()
	request.time_left = 5.1
	check(request.can_ask(), "con 5,1 s se puede")
	request.time_left = 5.0
	check(not request.can_ask(), "con 5 s no se puede")
	check(not request.pay_question(), "no cobra la pregunta")
	check_eq(request.time_left, 5.0, "el tiempo no cambia")
	return true


func test_el_temporizador_se_acaba() -> bool:
	var request := _make_request()
	request.advance(29.0)
	check_eq(request.time_left, 1.0, "queda 1 s")
	check(not request.is_out_of_time(), "todavía hay tiempo")
	request.advance(2.0)
	check_eq(request.time_left, 0.0, "no baja de 0")
	check(request.is_out_of_time(), "se acabó el tiempo")
	return true


func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var request := _make_request()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	request.decide_alone(rng)
	check(request.finished, "terminada")
	check(request.entity.actions.has(request.chosen_action), "eligió una de las 4 acciones")
	check(not request.answered_by_player, "decidió solo")
	check_eq(request.outcome, RuleEvaluator.outcome(request.entity, request.situation, request.chosen_action),
			"resultado de su elección")
	check(not request.is_out_of_time(), "una solicitud terminada no se acaba de nuevo")
	return true


func test_terminada_no_cambia() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a1"), true)
	check_eq(request.outcome, RuleEvaluator.Outcome.CORRECT, "a1 es la correcta con o1 = yes")
	check(request.answered_by_player, "respondió el jugador")
	check_eq(request.click_clue(&"beast_trait_1"), FriendRequest.ClueState.UNMARKED, "ya no se marca")
	check(not request.can_ask(), "ya no se pregunta")
	check(not request.advance(1.0), "el tiempo ya no corre")
	check_eq(request.time_left, 30.0, "el temporizador queda donde estaba")
	return true
