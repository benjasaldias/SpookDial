extends "res://test/test_case.gd"

const PacingDirector := preload("res://scripts/core/pacing_director.gd")


## Una noche como la 3 (docs/02 §6): 12 solicitudes en olas de 3, con 35 s para responder.
func _night() -> NightData:
	var night := NightData.new()
	night.requests_total = 12
	night.wave_size = 3
	night.base_decision_time = 35.0
	return night


func _director(night: NightData, seed_value := 1) -> PacingDirector:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PacingDirector.new(night, BalanceData.new(), rng)


## Los espacios entre las horas de `times`.
func _gaps(times: Array[float]) -> Array[float]:
	var gaps: Array[float] = []
	for index in times.size() - 1:
		gaps.append(times[index + 1] - times[index])
	return gaps


func test_planifica_todas_las_solicitudes_de_la_noche() -> bool:
	for seed_value in range(1, 21):
		var times := _director(_night(), seed_value).request_times
		check_eq(times.size(), 12, "12 solicitudes")
		check_eq(times[0], 5.0, "la primera a los 5 s")
		check(is_equal_approx(times[-1], 385.0), "la última alcanza a terminar a las 06:00: %s" % times[-1])
		for gap: float in _gaps(times):
			check(gap > 0.0, "en orden")
	return true


func test_despues_de_cada_ola_hay_un_respiro() -> bool:
	for seed_value in range(1, 21):
		var gaps := _gaps(_director(_night(), seed_value).request_times)
		for index in gaps.size():
			if (index + 1) % 3 == 0:
				check(gaps[index] >= 25.0, "el respiro dura al menos 25 s: %s" % gaps[index])
				check(gaps[index] > gaps[index - 1], "el respiro es más largo que el espacio de la ola: %s" % [gaps])
	return true


func test_las_olas_se_aprietan_hacia_las_06() -> bool:
	for seed_value in range(1, 21):
		var gaps := _gaps(_director(_night(), seed_value).request_times)
		# Dentro de la primera ola y de la última: los espacios 0-1 y 9-10.
		var first := gaps[0] + gaps[1]
		var last := gaps[9] + gaps[10]
		check(last < first, "al final llegan más seguidas: %s" % [gaps])
	return true


func test_llega_a_su_hora_y_no_antes() -> bool:
	var director := _director(_night())
	check(not director.request_due(4.9, 35.0), "a los 4,9 s todavía no")
	check(director.request_due(5.0, 35.0), "a los 5 s, sí")
	director.request_started(5.0)
	var second := director.request_times[0]
	check(not director.request_due(second - 0.1, 35.0), "la segunda, todavía no")
	check(director.request_due(second, 35.0), "la segunda, a su hora")
	return true


func test_si_una_llega_tarde_las_demas_se_atrasan() -> bool:
	var director := _director(_night())
	director.request_started(5.0)
	var planned := director.request_times.duplicate()
	director.request_started(planned[0] + 7.0)
	check_eq(director.request_times.size(), planned.size() - 1, "quedan las demás")
	for index in director.request_times.size():
		check(is_equal_approx(director.request_times[index], planned[index + 1] + 7.0), "atrasada 7 s")
	return true


func test_al_menos_6_s_entre_dos_solicitudes() -> bool:
	var director := _director(_night())
	director.request_times.assign([10.0, 11.0, 30.0])
	director.request_started(10.0)
	check(not director.request_due(11.0, 35.0), "a 1 s de la anterior, no")
	check(director.request_due(16.0, 35.0), "a 6 s, sí")
	return true


func test_un_amigo_herido_atrasa_las_que_faltan() -> bool:
	var director := _director(_night())
	var planned := director.request_times.duplicate()
	director.friend_hurt()
	for index in planned.size():
		check(is_equal_approx(director.request_times[index], planned[index] + 10.0), "atrasada 10 s")
	return true


func test_no_empieza_una_que_no_alcanza_a_terminar() -> bool:
	var director := _director(_night())
	director.request_times.assign([400.0, 410.0])
	check(not director.request_due(400.0, 30.0), "a las 05:43 ya no alcanza a responder en 30 s")
	check(director.request_times.is_empty(), "no llegan más")
	return true
