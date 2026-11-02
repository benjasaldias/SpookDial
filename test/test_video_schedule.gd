extends "res://test/test_case.gd"

const FriendState := preload("res://scripts/core/friend_state.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


## Envíos de una noche de 420 s con `quota` videos entre 3 amigos, con los valores de docs/02 §6:
## 15 s para empezar la descarga, 20 s para terminarla y 10 s de descarga.
func _schedule(quota: int) -> VideoSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return VideoSchedule.new(quota, BalanceData.new(), 3, rng)


func _friends() -> Array[FriendState]:
	var friends: Array[FriendState] = []
	for _i in 3:
		friends.append(FriendState.new(3))
	return friends


## Avanza `seconds` de a 1 segundo desde `start`, con Matías manteniendo presionada la descarga del amigo
## `holding` (-1: ninguna). Junta los cambios de todos los pasos.
func _advance(schedule: VideoSchedule, friends: Array[FriendState], start: float, seconds: int,
		holding: int) -> VideoSchedule.Changes:
	var all := VideoSchedule.Changes.new()
	for step in seconds:
		var changes := schedule.advance(start + step + 1.0, 1.0, friends, holding)
		all.offered.append_array(changes.offered)
		all.received.append_array(changes.received)
		all.lost.append_array(changes.lost)
	return all


## Un video extra del amigo 1, ya ofrecido en el segundo 1.
func _offered_extra(friends: Array[FriendState]) -> VideoSchedule:
	var schedule := _schedule(0)
	schedule.add_extra(1, 0.0)
	_advance(schedule, friends, 0.0, 1, -1)
	return schedule


func test_los_envios_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.quota, 3, "cuota")
	check_eq(schedule.pending.map(func(delivery: VideoSchedule.Delivery) -> float: return delivery.time),
			[105.0, 210.0, 315.0], "a las 01:30, 03:00 y 04:30")
	for delivery: VideoSchedule.Delivery in schedule.pending:
		check(delivery.friend_index >= 0 and delivery.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_a_su_hora_llega_como_oferta() -> bool:
	var schedule := _schedule(3)
	var friends := _friends()
	var first: int = schedule.pending[0].friend_index
	check_eq(_advance(schedule, friends, 0.0, 104, -1).offered, [], "antes de tiempo, nada")
	check_eq(_advance(schedule, friends, 104.0, 1, -1).offered, [first], "a los 105 s llega el primero")
	var offer := schedule.offer_for(first)
	check(offer != null and not offer.started, "espera que Matías empiece la descarga")
	if offer != null:
		check_eq(offer.time_left, 15.0, "15 s para empezar")
	check_eq(schedule.received, 0, "todavía no cuenta")
	return true


func test_sin_empezar_a_tiempo_se_pierde() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 14, -1)
	check(schedule.offer_for(1) != null, "a los 14 s sigue esperando")
	check_eq(_advance(schedule, friends, 15.0, 1, -1).lost, [1], "a los 15 s se pierde")
	check(schedule.offers.is_empty(), "ya no espera")
	check_eq(schedule.lost, 1, "perdidos")
	return true


func test_manteniendo_presionado_se_descarga_en_10_s() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 9, 1)
	var offer := schedule.offer_for(1)
	check(offer != null and offer.started, "empezó")
	if offer != null:
		check(is_equal_approx(offer.progress, 0.9), "a los 9 s, 90 %%: %s" % offer.progress)
		check_eq(offer.time_left, 11.0, "desde que empezó hay 20 s para terminar")
	check_eq(_advance(schedule, friends, 10.0, 1, 1).received, [1], "a los 10 s se recibe")
	check_eq(schedule.received, 1, "cuenta para la cuota")
	return true


func test_al_soltar_se_pausa() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 5, 1)
	_advance(schedule, friends, 6.0, 10, -1)
	var offer := schedule.offer_for(1)
	check(offer != null, "sigue esperando")
	if offer != null:
		check(is_equal_approx(offer.progress, 0.5), "conserva lo descargado: %s" % offer.progress)
		check_eq(offer.time_left, 5.0, "pero el tiempo corre")
	check_eq(_advance(schedule, friends, 16.0, 5, 1).received, [1], "terminó justo a los 20 s")
	return true


func test_hay_20_s_para_terminar() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 5, 1)
	check_eq(_advance(schedule, friends, 6.0, 15, -1).lost, [1], "a los 20 s de empezar se pierde")
	return true


func test_la_velocidad_depende_de_la_senal() -> bool:
	var friends := _friends()
	friends[1].signal_level = 40.0
	var schedule := _offered_extra(friends)
	check(_advance(schedule, friends, 1.0, 14, 1).received.is_empty(), "con señal 40 no alcanza en 14 s")
	check_eq(_advance(schedule, friends, 15.0, 1, 1).received, [1], "tarda 15 s")
	friends = _friends()
	schedule = _offered_extra(friends)
	friends[1].signal_level = 0.0
	_advance(schedule, friends, 1.0, 5, 1)
	check_eq(schedule.offer_for(1).progress, 0.0, "sin señal no avanza")
	return true


func test_si_el_amigo_no_puede_enviar_se_atrasa() -> bool:
	var schedule := _schedule(0)
	var friends := _friends()
	schedule.add_extra(1, 0.0)
	friends[1].hurt(1, 15.0)
	check(_advance(schedule, friends, 0.0, 5, -1).offered.is_empty(), "aturdido: todavía no")
	friends[1].stun_left = 0.0
	friends[1].signal_level = 0.0
	check(_advance(schedule, friends, 5.0, 5, -1).offered.is_empty(), "sin señal: todavía no")
	friends[1].restore_signal()
	check_eq(_advance(schedule, friends, 10.0, 1, -1).offered, [1], "llega cuando puede")
	return true


func test_un_video_por_amigo_a_la_vez() -> bool:
	var schedule := _schedule(0)
	var friends := _friends()
	schedule.add_extra(1, 0.0)
	schedule.add_extra(1, 0.0)
	check_eq(_advance(schedule, friends, 0.0, 1, -1).offered, [1], "llega uno")
	check_eq(schedule.pending.size(), 1, "el otro espera")
	var changes := _advance(schedule, friends, 1.0, 10, 1)
	check_eq(changes.received, [1], "se descarga el primero")
	check_eq(changes.offered, [1], "y después llega el segundo")
	return true


func test_sin_cuota_ya_esta_cumplida() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "sin envíos")
	check(schedule.is_quota_met(), "cumplida")
	return true
