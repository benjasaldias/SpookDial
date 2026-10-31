extends "res://test/test_case.gd"

const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


func _schedule(quota: int) -> VideoSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return VideoSchedule.new(quota, 420.0, 3, rng)


func _anyone(_friend_index: int) -> bool:
	return true


func _nobody(_friend_index: int) -> bool:
	return false


func test_los_envios_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.quota, 3, "cuota")
	check_eq(schedule.pending.map(func(delivery: VideoSchedule.Delivery) -> float: return delivery.time),
			[105.0, 210.0, 315.0], "a las 01:30, 03:00 y 04:30")
	for delivery: VideoSchedule.Delivery in schedule.pending:
		check(delivery.friend_index >= 0 and delivery.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_llegan_a_su_hora() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.receive_due(104.0, _anyone), [], "antes de tiempo, nada")
	var first: int = schedule.pending[0].friend_index
	check_eq(schedule.receive_due(105.0, _anyone), [first], "a los 105 s, el primero")
	check_eq(schedule.received, 1, "1 recibido")
	check(not schedule.is_quota_met(), "falta cuota")
	schedule.receive_due(400.0, _anyone)
	check_eq(schedule.received, 3, "todos")
	check(schedule.is_quota_met(), "cuota cumplida")
	return true


func test_si_el_amigo_no_puede_enviar_se_atrasa() -> bool:
	var schedule := _schedule(1)
	check_eq(schedule.receive_due(300.0, _nobody), [], "aturdido: todavía no")
	check_eq(schedule.pending.size(), 1, "sigue pendiente")
	check_eq(schedule.receive_due(301.0, _anyone).size(), 1, "llega cuando puede")
	return true


func test_el_video_extra_llega_apenas_puede() -> bool:
	var schedule := _schedule(2)
	schedule.add_extra(1, 50.0)
	check_eq(schedule.receive_due(50.0, _anyone), [1], "el extra de Gonzalo")
	check_eq(schedule.received, 1, "cuenta para la cuota")
	return true


func test_sin_cuota_ya_esta_cumplida() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "sin envíos")
	check(schedule.is_quota_met(), "cumplida")
	return true
