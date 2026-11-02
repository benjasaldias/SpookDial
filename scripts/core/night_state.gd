extends RefCounted
## El estado de una noche en curso (diseño §5, §9 y §10): la hora, Sanity, Trust, cómo está cada amigo
## y su señal, las interferencias y los videos. Lógica pura: RequestManager lo crea, NightManager lo avanza
## y el escritorio lo muestra.

const Consequence := preload("res://scripts/core/consequence.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")

## Cómo termina la noche. NONE: todavía no termina.
enum Ending { NONE, WON, FRIEND_DIED, SANITY, TRUST, CONNECTION, QUOTA }

## La noche va de las 00:00 a las 06:00.
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
var friends: Array[FriendState] = []
var videos: VideoSchedule
## El amigo cuya descarga mantiene presionada Matías en el chat, o -1 (decisión de Benja).
var holding_download := -1
var interferences: InterferenceSchedule

## Segundos desde la última vez que bajó Trust.
var _since_trust_loss := 0.0
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
	videos = VideoSchedule.new(night.content_quota, balance, friend_count, rng)
	interferences = InterferenceSchedule.new(night.interference_count, balance.night_seconds, friend_count, rng)


## Avanza `delta` segundos: la hora, los amigos y su señal, las interferencias, Sanity, Trust y los videos.
## Devuelve lo que pasó, para avisarlo en el chat.
func advance(delta: float) -> Events:
	var events := Events.new()
	elapsed = minf(elapsed + delta, balance.night_seconds)
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
	return events


## Aplica la consecuencia de una solicitud del amigo `friend_index`: la vida, el aturdimiento, Trust y,
## si fue la acción de mayor riesgo y el amigo sobrevivió, el video extra.
func apply(friend_index: int, consequence: Consequence) -> void:
	var friend := friends[friend_index]
	if consequence.is_hurt():
		friend.hurt(consequence.damage, balance.stun_seconds)
	if consequence.trust_change < 0.0:
		_since_trust_loss = 0.0
	trust = clampf(trust + consequence.trust_change, 0.0, METER_MAX)
	if consequence.risky and friend.is_alive():
		videos.add_extra(friend_index, elapsed)


## Puede recibir solicitudes: está vivo y no está aturdido.
func is_available(friend_index: int) -> bool:
	return friends[friend_index].is_available()


## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2).
func scroll() -> void:
	_scroll_left = balance.scroll_grace


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


## La hora del celular, de "00:00" a "06:00".
func clock_text() -> String:
	var minutes := int(elapsed / balance.night_seconds * NIGHT_HOURS * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


## Cuánto se oscurece la vista, de 0 a 1: nada desde vignette_start de Sanity hacia arriba, y todo en 0.
func vignette_strength() -> float:
	return clampf((balance.vignette_start - sanity) / balance.vignette_start, 0.0, 1.0)


## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0.
## A las 06:00 se gana si se cumplió la cuota (diseño §5).
func ending() -> Ending:
	for friend: FriendState in friends:
		if not friend.is_alive():
			return Ending.FRIEND_DIED
	if sanity <= 0.0:
		return Ending.SANITY
	if trust <= 0.0:
		return Ending.TRUST
	if connection() <= 0.0:
		return Ending.CONNECTION
	if elapsed >= balance.night_seconds:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
	return Ending.NONE


## Sanity baja con el tiempo y sube mientras Matías scrollea el celular.
func _advance_sanity(delta: float) -> void:
	var scrolling := minf(_scroll_left, delta)
	_scroll_left = maxf(_scroll_left - delta, 0.0)
	sanity = clampf(sanity - delta / night.sanity_drain_interval + scrolling * balance.scroll_sanity_per_second,
			0.0, METER_MAX)


## Trust se recupera si no bajó en un rato. Con amigos sin señal, baja por cada uno y no se recupera
## (decisión de Benja).
func _advance_trust(delta: float) -> void:
	var offline := offline_count()
	if offline > 0:
		_since_trust_loss = 0.0
		trust = maxf(trust - delta * offline / balance.offline_trust_interval, 0.0)
		return
	_since_trust_loss += delta
	# Solo cuenta la parte del paso que cae después de la espera sin errores.
	var calm := clampf(_since_trust_loss - balance.trust_recovery_delay, 0.0, delta)
	trust = minf(trust + calm / balance.trust_recovery_interval, METER_MAX)
