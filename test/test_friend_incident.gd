extends "res://test/test_case.gd"
## Los accidentes de los amigos (decisión de Benja, 7 de noviembre).

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendIncident := preload("res://scripts/core/friend_incident.gd")


func _make_incident(seed_value := 1) -> FriendIncident:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FriendIncident.new(Fixtures.make_incident(), 2, 15.0, rng)


func test_tiene_la_buena_idea_y_las_malas() -> bool:
	var incident := _make_incident()
	check_eq(incident.friend_index, 2, "su amigo")
	check_eq(incident.options.size(), 3, "3 opciones")
	check(incident.options.has("K_INCIDENT_trip_OK"), "la buena")
	check(incident.options.has("K_INCIDENT_trip_BAD_1"), "una mala")
	return true


func test_la_buena_idea_no_siempre_va_primero() -> bool:
	var firsts := {}
	for seed_value in range(1, 21):
		firsts[_make_incident(seed_value).options[0]] = true
	check(firsts.size() > 1, "las opciones se barajan: %s" % [firsts.keys()])
	return true


func test_solo_la_buena_idea_es_correcta() -> bool:
	var incident := _make_incident()
	var correct := 0
	for index in incident.options.size():
		if incident.is_correct(index):
			correct += 1
			check_eq(incident.options[index], "K_INCIDENT_trip_OK", "es la buena")
	check_eq(correct, 1, "una sola")
	return true


func test_se_le_acaba_el_tiempo() -> bool:
	var incident := _make_incident()
	incident.advance(14.0)
	check(not incident.is_out_of_time(), "a los 14 s, todavía")
	incident.advance(2.0)
	check(incident.is_out_of_time(), "a los 15 s, se acabó")
	return true
