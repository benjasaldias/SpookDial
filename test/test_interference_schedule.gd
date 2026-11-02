extends "res://test/test_case.gd"

const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")


func _schedule(count: int) -> InterferenceSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	return InterferenceSchedule.new(count, 420.0, 3, rng)


func test_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.pending.size(), 3, "3 interferencias")
	for index in schedule.pending.size():
		var interference: InterferenceSchedule.Interference = schedule.pending[index]
		# Una en cada tercio de la noche (140 s), lejos de sus bordes.
		check(interference.time >= 140.0 * index + 28.0 and interference.time <= 140.0 * index + 112.0,
				"la %d, en su tramo: %s" % [index + 1, interference.time])
		check(interference.friend_index >= 0 and interference.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_sin_interferencias() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "ninguna")
	check(not schedule.is_warning(0, 0.0, 3.0), "sin aviso")
	return true


func test_se_anuncia_unos_segundos_antes() -> bool:
	var schedule := _schedule(1)
	var interference: InterferenceSchedule.Interference = schedule.pending[0]
	var friend := interference.friend_index
	check(not schedule.is_warning(friend, interference.time - 3.5, 3.0), "3,5 s antes, todavía no")
	check(schedule.is_warning(friend, interference.time - 2.5, 3.0), "2,5 s antes, sí")
	check(not schedule.is_warning((friend + 1) % 3, interference.time - 1.0, 3.0), "solo en su amigo")
	return true


func test_golpea_a_su_hora_una_sola_vez() -> bool:
	var schedule := _schedule(1)
	var interference: InterferenceSchedule.Interference = schedule.pending[0]
	check_eq(schedule.take_due(interference.time - 0.1), [], "antes de su hora, nada")
	check_eq(schedule.take_due(interference.time), [interference.friend_index], "a su hora, golpea")
	check_eq(schedule.take_due(interference.time + 10.0), [], "no vuelve a golpear")
	check(not schedule.is_warning(interference.friend_index, interference.time, 3.0), "ya no se anuncia")
	return true
