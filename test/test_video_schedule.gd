extends "res://test/test_case.gd"

const FriendState := preload("res://scripts/core/friend_state.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


## Envíos de una noche de 420 s con `quota` videos entre 3 amigos, con los valores de docs/02 §6:
## 15 s para empezar la descarga, 20 s para terminarla y 10 s de descarga.
func _schedule(quota: int) -> VideoSchedule:
	return VideoSchedule.new(quota, BalanceData.new())


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


## Los envíos programados llegan en las calmas (decisión de Benja, 11 de noviembre): el director los suelta.
func test_los_videos_se_sueltan_cuando_toca() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.quota, 3, "cuota")
	check(schedule.pending.is_empty(), "al empezar, ninguno en camino")
	check_eq(schedule.unreleased, 3, "los 3 esperan su calma")
	schedule.release(2, 100.0)
	check_eq(schedule.pending.size(), 1, "uno en camino")
	check_eq(schedule.pending[0].friend_index, 2, "lo manda Agustín")
	check_eq(schedule.pending[0].time, 100.0, "a su hora")
	check_eq(schedule.unreleased, 2, "faltan 2")
	check_eq(schedule.potential(), 3, "pueden llegar los 3")
	return true


func test_a_su_hora_llega_como_oferta() -> bool:
	var schedule := _schedule(3)
	var friends := _friends()
	schedule.release(1, 105.0)
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
	check(schedule.pending.is_empty() and schedule.unreleased == 0, "sin envíos")
	check(schedule.is_quota_met(), "cumplida")
	return true


## En el tutorial, el video espera a que Matías lo descargue: sus plazos no corren (decisión de Benja).
func test_en_el_tutorial_el_video_espera() -> bool:
	var schedule := _schedule(0)
	schedule.patient = true
	var friends := _friends()
	schedule.add_extra(1, 10.0)
	var changes := _advance(schedule, friends, 10.0, 60, -1)
	check_eq(changes.offered, [1], "llegó el video de Gonzalo")
	check_eq(changes.lost, [], "no se pierde aunque pase el tiempo")
	changes = _advance(schedule, friends, 70.0, 5, 1)
	check_eq(schedule.offer_for(1).progress, 0.5, "la descarga avanza igual")
	changes = _advance(schedule, friends, 75.0, 30, -1)
	check_eq(changes.lost, [], "en pausa tampoco se pierde")
	changes = _advance(schedule, friends, 105.0, 5, 1)
	check_eq(changes.received, [1], "se recibe")
	return true


## Cuántos videos todavía pueden llegar: los recibidos, los que esperan su descarga y los que faltan. Si no alcanzan la
## cuota, alguien tiene que arriesgarse (decisión de Benja, 11 de noviembre).
func test_cuantos_videos_pueden_llegar() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.potential(), 3, "al empezar, los 3 de la cuota")
	check(not schedule.is_short(), "alcanzan")
	schedule.unreleased -= 1
	schedule.lost += 1
	check_eq(schedule.potential(), 2, "se perdió uno")
	check(schedule.is_short(), "ya no alcanzan")
	schedule.add_extra(1, 100.0)
	check(not schedule.is_short(), "el video extra de la acción de mayor riesgo vuelve a alcanzar")
	schedule.pending.clear()
	schedule.unreleased = 0
	schedule.offers.append(VideoSchedule.Offer.new(0, 15.0))
	schedule.received = 2
	check_eq(schedule.potential(), 3, "2 recibidos y 1 esperando su descarga")
	return true


## En el tutorial el video llega cuando León lo manda: el PC no avisa que faltan (Plan 9.2).
func test_en_el_tutorial_nunca_faltan() -> bool:
	var schedule := _schedule(1)
	schedule.unreleased = 0
	schedule.patient = true
	check(not schedule.is_short(), "no avisa")
	return true
