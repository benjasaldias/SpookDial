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


## Una noche con `count` screamers y, si `jumpscare`, uno de ellos es el jumpscare.
func _scary_night(count: int, jumpscare: bool) -> NightData:
	var night := _night()
	night.scare_count = count
	night.has_jumpscare = jumpscare
	return night


func test_reparte_los_screamers_en_la_noche() -> bool:
	for seed_value in range(1, 21):
		var times := _director(_scary_night(6, true), seed_value).scare_times
		check_eq(times.size(), 6, "6 screamers")
		check(times[0] >= 30.0, "ninguno en los primeros 30 s: %s" % times[0])
		check(times[-1] <= 420.0, "todos antes de las 06:00")
		for gap: float in _gaps(times):
			check(gap >= 25.0, "al menos 25 s entre dos: %s" % [times])
	return true


func test_uno_es_el_jumpscare_si_la_noche_lo_tiene() -> bool:
	for jumpscare: bool in [true, false]:
		for seed_value in range(1, 11):
			var director := _director(_scary_night(4, jumpscare), seed_value)
			var found := 0
			while not director.scare_times.is_empty():
				if director.next_is_jumpscare():
					found += 1
				director.scare_started(director.scare_times[0])
			check_eq(found, 1 if jumpscare else 0, "jumpscares en una noche %s jumpscare" % ("con" if jumpscare else "sin"))
	return true


func test_un_screamer_llega_a_su_hora_y_espaciado() -> bool:
	var director := _director(_scary_night(0, false))
	director.scare_times.assign([40.0, 50.0])
	check(not director.scare_due(39.0), "todavía no")
	check(director.scare_due(40.0), "a su hora")
	director.scare_started(40.0)
	check(not director.scare_due(50.0), "a 10 s del anterior, espera")
	check(director.scare_due(65.0), "a 25 s, sí")
	return true


func test_el_susto_guionado_espera_un_momento_sin_solicitudes() -> bool:
	var night := _night()
	night.scripted_scare_time = 60.0
	var director := _director(night)
	check(not director.scripted_scare_due(59.0, 0), "todavía no")
	check(not director.scripted_scare_due(60.0, 1), "hay una solicitud: espera")
	check(director.scripted_scare_due(70.0, 0), "sin solicitudes, llega")
	director.scare_times.assign([75.0])
	director.scripted_scare_started(70.0)
	check(not director.scripted_scare_due(80.0, 0), "llega una sola vez")
	check(not director.scare_due(80.0), "el siguiente screamer espera 25 s desde el guionado")
	check(director.scare_due(95.0), "a los 25 s, sí")
	check(not _director(_night()).scripted_scare_due(100.0, 0), "una noche sin susto guionado")
	return true
