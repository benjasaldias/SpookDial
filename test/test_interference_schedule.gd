extends "res://test/test_case.gd"

const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")


## `count` interferencias, a los 100, 200… segundos, para los amigos 0, 1, 2, 0…
func _schedule(count: int) -> InterferenceSchedule:
	var schedule := InterferenceSchedule.new()
	for index in count:
		schedule.add(index % 3, 100.0 * (index + 1))
	return schedule


## Llegan con las olas (decisión de Benja, 11 de noviembre): se agregan a medida que el director las pide, y quedan en
## orden.
func test_se_agregan_en_orden() -> bool:
	var schedule := InterferenceSchedule.new()
	schedule.add(2, 150.0)
	schedule.add(0, 90.0)
	schedule.add(1, 120.0)
	var times := schedule.pending.map(func(interference: InterferenceSchedule.Interference) -> float: return interference.time)
	check_eq(times, [90.0, 120.0, 150.0], "en orden")
	check_eq(schedule.pending[0].friend_index, 0, "cada una con su amigo")
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
