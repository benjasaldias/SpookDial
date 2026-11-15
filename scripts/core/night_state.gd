extends RefCounted
## El estado de una noche en curso (diseño §5, §9 y §10): la hora, Sanity, Trust, cómo está cada amigo
## y su señal, las interferencias y los videos. Lógica pura: RequestManager lo crea, NightManager lo avanza
## y el escritorio lo muestra.

const Consequence := preload("res://scripts/core/consequence.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")

## Los diales que puede agarrar la Mano (decisión de Benja, 11 de noviembre).
enum Dial { CONNECTION, SANITY, TRUST }
## Cómo termina la noche. NONE: todavía no termina.
enum Ending { NONE, WON, FRIEND_DIED, SANITY, TRUST, CONNECTION, QUOTA }

## Las 6 horas del reloj, de las 00:00 a las 06:00, duran night_seconds (70 s por hora). Desde el Plan 9.9 la noche no
## termina a una hora: el reloj sigue hasta que se completa.
const NIGHT_HOURS := 6
## Sanity, Trust y la señal van de 0 a 100.
const METER_MAX := 100.0


## Lo que pasó en un paso de la noche, para avisarlo en el chat.
class Events:
	## Los videos que llegaron, se recibieron o se perdieron.
	var videos: VideoSchedule.Changes
	## Amigos que se quedaron sin señal en este paso.
	var disconnected: Array[int] = []


var night: NightData
var balance: BalanceData
## Segundos desde las 00:00.
var elapsed := 0.0
var sanity := METER_MAX
var trust := METER_MAX
## La batería del celular (0–100). Se gasta solo mientras Matías scrollea y no se recarga (decisión de Benja, 7 de
## noviembre).
var battery := METER_MAX
## Las cortinas están cerradas: el cuarto se oscurece y Sanity baja de a poco (decisión de Benja, 7 de noviembre).
var curtains_closed := false
## La criatura está afuera: con las cortinas abiertas, Sanity baja rápido (decisión de Benja, 7 de noviembre).
var creature_outside := false
var friends: Array[FriendState] = []
var videos: VideoSchedule
## El amigo cuya descarga mantiene presionada Matías en el chat, o -1 (decisión de Benja).
var holding_download := -1
## Cuántas solicitudes esperan más de la cuenta: cada una hace bajar Trust (decisión de Benja, 4 de noviembre).
## Lo pone NightManager antes de cada paso.
var impatient := 0
var interferences: InterferenceSchedule
## Los pedidos de ayuda abiertos (consultas, accidentes y decisiones de la historia): lo pone NightManager antes de cada
## paso, como impatient. Mientras están abiertos, suman a la espera de la nota (Plan 9.9).
var waiting := 0
## Los segundos que esperaron los pedidos de ayuda, sumados: dos abiertos a la vez suman el doble.
var waited := 0.0
## Cuántos pedidos de ayuda llegaron en la noche. Los cuenta RequestManager al empezar cada uno.
var asked := 0
## La meta de espera por pedido de la dificultad (DifficultyData.wait_goal), con la que la nota compara average_wait().
## La pone RequestManager.
var wait_goal := 15.0
## La noche se completó hace end_pause s: la ola final se resolvió, no queda nada abierto ni videos por recibir y la
## historia terminó (Plan 9.9). Lo pone RequestManager. Desde ahí se gana o, sin la cuota, se pierde.
var finished := false

## Segundos que todavía cuentan como scroll del celular.
var _scroll_left := 0.0


func _init(night_data: NightData, balance_data: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	night = night_data
	balance = balance_data
	for _index in friend_count:
		var friend := FriendState.new(balance.friend_health)
		if night.signal_decays:
			# Cada amigo pierde señal a su propio ritmo (diseño §10.1).
			friend.signal_decay_interval = rng.randf_range(night.signal_decay_interval.x, night.signal_decay_interval.y)
		friends.append(friend)
	videos = VideoSchedule.new(night.content_quota, balance)
	if night.is_tutorial():
		# En el tutorial, el video lo manda el amigo de una solicitud, y espera a que Matías lo descargue.
		videos.unreleased = 0
		videos.patient = true
	interferences = InterferenceSchedule.new()


## Avanza `delta` segundos: la hora, los amigos y su señal, las interferencias, Sanity, Trust y los videos.
## Devuelve lo que pasó, para avisarlo en el chat.
func advance(delta: float) -> Events:
	var events := Events.new()
	elapsed += delta
	waited += delta * waiting
	var online: Array[bool] = []
	for friend: FriendState in friends:
		online.append(friend.is_online())
		friend.advance(delta)
	for friend_index: int in interferences.take_due(elapsed):
		friends[friend_index].interfere(balance.interference_damage)
	for index in friends.size():
		if online[index] and not friends[index].is_online():
			events.disconnected.append(index)
	_advance_sanity(delta)
	_advance_trust(delta)
	events.videos = videos.advance(elapsed, delta, friends, holding_download)
	# Un video perdido baja Trust: el amigo arriesgó para grabarlo (decisión de Benja, 11 de noviembre).
	trust = maxf(trust + balance.lost_video_trust * events.videos.lost.size(), 0.0)
	return events


## Aplica la consecuencia de una solicitud del amigo `friend_index`: la vida, el aturdimiento, Trust y,
## si fue la acción de mayor riesgo y el amigo sobrevivió, el video extra.
func apply(friend_index: int, consequence: Consequence) -> void:
	var friend := friends[friend_index]
	if consequence.is_hurt():
		friend.hurt(consequence.damage, balance.stun_seconds)
	trust = clampf(trust + consequence.trust_change, 0.0, METER_MAX)
	if consequence.risky and friend.is_alive():
		videos.add_extra(friend_index, elapsed)


## Un accidente hirió al amigo `friend_index`: pierde vida y queda aturdido, sin que baje Trust.
func injure(friend_index: int) -> void:
	friends[friend_index].hurt(balance.incident_damage, balance.stun_seconds)


## Puede recibir solicitudes: está vivo y no está aturdido.
func is_available(friend_index: int) -> bool:
	return friends[friend_index].is_available()


## Un screamer asustó a Matías: Sanity baja `amount` de golpe (diseño §10.2).
func scare(amount: float) -> void:
	sanity = maxf(sanity - amount, 0.0)


## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2). Sin batería, no pasa nada.
func scroll() -> void:
	if has_battery():
		_scroll_left = balance.scroll_grace


## Cuánta Sanity se pierde por segundo: lo de la noche, más lo de las cortinas cerradas o, si están abiertas, lo de
## la criatura. Cerradas, la criatura no se ve (decisión de Benja, 7 de noviembre).
func sanity_drain_per_second() -> float:
	var drain := 1.0 / night.sanity_drain_interval
	if curtains_closed:
		drain += balance.closed_curtains_sanity
	elif creature_outside:
		drain += balance.creature_sanity
	return drain


## Al celular le queda batería.
func has_battery() -> bool:
	return battery > 0.0


## Matías prende el flash del celular: gasta flash_cost de la batería, haya o no una Mano (decisión de Benja, 11 de
## noviembre). Sin batería no prende y devuelve false.
func flash() -> bool:
	if not has_battery():
		return false
	battery = maxf(battery - balance.flash_cost, 0.0)
	return true


## La Mano tiene agarrado el dial `dial` durante `delta` segundos: lo baja hand_drain por segundo hasta hand_floor,
## nunca a 0. En Connection baja las 3 señales parejo, así que también sube la estática.
func hand_pull(dial: Dial, delta: float) -> void:
	var amount := balance.hand_drain * delta
	match dial:
		Dial.CONNECTION:
			for friend: FriendState in friends:
				friend.signal_level = _pulled(friend.signal_level, amount)
		Dial.SANITY:
			sanity = _pulled(sanity, amount)
		Dial.TRUST:
			trust = _pulled(trust, amount)


## Lo que muestra el dial `dial`, de 0 a 100.
func dial_value(dial: Dial) -> float:
	match dial:
		Dial.CONNECTION:
			return connection()
		Dial.SANITY:
			return sanity
	return trust


## `value` bajado `amount` sin pasar de hand_floor. Si ya estaba bajo el mínimo, queda igual.
func _pulled(value: float, amount: float) -> float:
	if value <= balance.hand_floor:
		return value
	return maxf(value - amount, balance.hand_floor)


## Al amigo `friend_index` le va a golpear una interferencia: su entrada titila y suena estática.
func interference_warning(friend_index: int) -> bool:
	return interferences.is_warning(friend_index, elapsed, balance.interference_warning)


## Cuántos amigos están sin señal.
func offline_count() -> int:
	return friends.filter(func(friend: FriendState) -> bool: return not friend.is_online()).size()


## El dial de Connection: el promedio de las señales de los amigos (diseño §10.1).
func connection() -> float:
	var total := 0.0
	for friend: FriendState in friends:
		total += friend.signal_level
	return total / friends.size()


## Cuánto esperó en promedio cada pedido de ayuda, en segundos (0 si no hubo ninguno).
func average_wait() -> float:
	return waited / asked if asked > 0 else 0.0


## Las vidas que perdieron los amigos en la noche, sin la herida con que empieza uno en Extremo.
func lives_lost() -> int:
	var lost := 0
	for friend: FriendState in friends:
		lost += friend.health_lost
	return lost


## La hora del celular: night_seconds son 6 horas, y después de las 06:00 sigue (Plan 9.9).
func clock_text() -> String:
	var minutes := int(elapsed / balance.night_seconds * NIGHT_HOURS * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


## Cuánto se oscurece la vista, de 0 a 1: nada desde vignette_start de Sanity hacia arriba, y todo en 0.
func vignette_strength() -> float:
	return clampf((balance.vignette_start - sanity) / balance.vignette_start, 0.0, 1.0)


## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0. Cuando la noche se
## completó (finished), se gana si se cumplió la cuota (Plan 9.9; antes, a las 06:00). El tutorial no termina solo:
## termina cuando León se despide (decisión de Benja).
func ending() -> Ending:
	if night.is_tutorial():
		return Ending.NONE
	for friend: FriendState in friends:
		if not friend.is_alive():
			return Ending.FRIEND_DIED
	if sanity <= 0.0:
		return Ending.SANITY
	if trust <= 0.0:
		return Ending.TRUST
	if connection() <= 0.0:
		return Ending.CONNECTION
	if finished:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
	return Ending.NONE


## Sanity baja con el tiempo y sube mientras Matías scrollea el celular, hasta que se acaba la batería.
func _advance_sanity(delta: float) -> void:
	var battery_left := battery / METER_MAX * balance.phone_battery_seconds
	var scrolling := minf(minf(_scroll_left, delta), battery_left)
	_scroll_left = maxf(_scroll_left - delta, 0.0)
	battery = maxf(battery - scrolling / balance.phone_battery_seconds * METER_MAX, 0.0)
	sanity = clampf(sanity - delta * sanity_drain_per_second() + scrolling * balance.scroll_sanity_per_second,
			0.0, METER_MAX)


## Trust baja por cada amigo sin señal y por cada solicitud que espera demasiado, y no se recupera durante la noche
## (decisiones de Benja, 4 y 11 de noviembre).
func _advance_trust(delta: float) -> void:
	var drain := delta * offline_count() / balance.offline_trust_interval \
			+ delta * impatient * balance.slow_answer_trust
	trust = maxf(trust - drain, 0.0)
