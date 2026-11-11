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


func test_el_costo_de_preguntar_es_un_dato() -> bool:
	var request := _make_request()
	request.question_cost = 8.0
	check(request.pay_question(), "se puede preguntar")
	check_eq(request.time_left, 22.0, "costó 8 s")
	request.time_left = 8.0
	check(not request.can_ask(), "con el costo de una pregunta o menos, ya no")
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


## Sin señal, el amigo elige mal: al azar entre las 3 acciones que no son la correcta (decisión de Benja).
func test_sin_senal_decide_mal() -> bool:
	var chosen := {}
	for seed_value in 40:
		var request := _make_request()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		request.decide_alone(rng, true)
		check(request.decided_offline, "decidió sin señal")
		check(request.outcome != RuleEvaluator.Outcome.CORRECT, "nunca la correcta")
		chosen[request.chosen_action.id] = true
	check_eq(chosen.size(), 3, "elige entre las otras 3")
	return true


## En el tutorial, el temporizador espera (decisión de Benja): solo las preguntas le quitan tiempo. Matías
## sigue pensando, y el nombre aparece igual.
func test_en_el_tutorial_el_temporizador_espera() -> bool:
	var request := _make_request()
	request.timer_paused = true
	request.advance(20.0)
	check_eq(request.time_left, 30.0, "el tiempo no corre")
	check(not request.is_out_of_time(), "no se acaba")
	check(request.pay_question(), "se puede preguntar")
	check_eq(request.time_left, 25.0, "la pregunta cuesta igual")
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	check(request.advance(FriendRequest.THINKING_TIME), "aparece el nombre")
	return true


## El tutorial necesita saber si Matías ya preguntó algo.
func test_cuenta_las_preguntas() -> bool:
	var request := _make_request()
	check_eq(request.questions_asked, 0, "al empezar")
	request.pay_question()
	request.pay_question()
	check_eq(request.questions_asked, 2, "dos preguntas")
	request.time_left = 5.0
	request.pay_question()
	check_eq(request.questions_asked, 2, "la que no se pudo hacer no cuenta")
	return true


## Una solicitud que espera demasiado hace bajar Trust (decisión de Benja, 4 de noviembre): cuenta el tiempo que
## lleva abierta, preguntas incluidas.
func test_una_solicitud_lenta() -> bool:
	var request := _make_request()
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.advance(20.0)
	check_eq(request.open_seconds, 20.0, "20 s abierta")
	check(not request.is_slow(30.0), "todavía no")
	request.pay_question()
	check_eq(request.open_seconds, 25.0, "preguntar también cuenta")
	request.advance(5.0)
	check(not request.is_slow(30.0), "justo a los 30 s, todavía no")
	request.advance(0.5)
	check(request.is_slow(30.0), "pasados los 30 s, sí")
	request.finish(request.entity.find_action(&"a1"), true)
	check(not request.is_slow(30.0), "una solicitud terminada ya no espera")
	return true


## En el tutorial el temporizador espera, y la solicitud nunca es lenta.
func test_en_el_tutorial_nunca_es_lenta() -> bool:
	var request := _make_request()
	request.timer_paused = true
	request.advance(100.0)
	check_eq(request.open_seconds, 0.0, "no cuenta")
	check(not request.is_slow(30.0), "no es lenta")
	return true


## Clickear un señuelo cuesta 1 s la primera vez (decisión de Benja, 11 de noviembre): ya no se puede clickear todo
## gratis. Cuenta como tiempo abierto, como las preguntas.
func test_un_senuelo_cuesta_1_s_la_primera_vez() -> bool:
	var request := _make_request()
	check_eq(request.decoy_cost, 1.0, "por defecto, 1 s")
	request.click_clue(&"decoy_sight")
	check_eq(request.time_left, 29.0, "costó 1 s")
	check_eq(request.open_seconds, 1.0, "cuenta como tiempo abierto")
	request.click_clue(&"decoy_sight")
	check_eq(request.time_left, 29.0, "la segunda vez no cuesta")
	request.click_clue(&"beast_trait_1")
	check_eq(request.time_left, 29.0, "una característica no cuesta")
	request = _make_request()
	request.time_left = 0.5
	request.click_clue(&"decoy_sight")
	check_eq(request.time_left, 0.0, "no baja de 0")
	request = _make_request()
	request.timer_paused = true
	request.click_clue(&"decoy_sight")
	check_eq(request.time_left, 29.0, "en el tutorial también cuesta: solo lo que hace Matías le quita tiempo")
	return true


## Una pregunta ya respondida no se repite: costaría 5 s por algo que ya se sabe (decisión de Benja, 11 de noviembre).
func test_una_pregunta_respondida_no_se_repite() -> bool:
	var request := _make_request()
	check(request.can_ask_about(ClueCategory.Kind.SIGHT), "al empezar se puede")
	check(not request.was_asked(ClueCategory.Kind.SIGHT), "no se ha preguntado")
	request.record_answer(ClueCategory.Kind.SIGHT, false)
	check(request.was_asked(ClueCategory.Kind.SIGHT), "ya se preguntó")
	check(not request.answer_covered(ClueCategory.Kind.SIGHT), "llegó entera")
	check(not request.can_ask_about(ClueCategory.Kind.SIGHT), "no se repite")
	check(request.can_ask_about(ClueCategory.Kind.SOUND), "las otras sí")
	request.time_left = 5.0
	check(not request.can_ask_about(ClueCategory.Kind.SOUND), "sin tiempo, ninguna")
	return true


## Si la estática tapó algo de la respuesta, hay que volver a preguntar para recuperarlo (decisión de Benja, 15 de
## octubre).
func test_con_la_respuesta_tapada_se_puede_repetir() -> bool:
	var request := _make_request()
	request.record_answer(ClueCategory.Kind.SIGHT, true)
	check(request.answer_covered(ClueCategory.Kind.SIGHT), "salió tapada")
	check(request.can_ask_about(ClueCategory.Kind.SIGHT), "se puede repetir")
	request.record_answer(ClueCategory.Kind.SIGHT, false)
	check(not request.can_ask_about(ClueCategory.Kind.SIGHT), "la segunda llegó entera: ya no")
	return true
