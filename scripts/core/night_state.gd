extends RefCounted
## El estado de una noche en curso (diseño §5, §9 y §10): la hora, Sanity, Trust, cómo está cada amigo
## y los videos. Lógica pura: RequestManager lo crea, NightManager lo avanza y el escritorio lo muestra.

const Consequence := preload("res://scripts/core/consequence.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
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

## Segundos desde la última vez que bajó Trust.
var _since_trust_loss := 0.0


func _init(night_data: NightData, balance_data: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	night = night_data
	balance = balance_data
	for _index in friend_count:
		friends.append(FriendState.new(balance.friend_health))
	videos = VideoSchedule.new(night.content_quota, balance, friend_count, rng)


## Avanza `delta` segundos: la hora, Sanity, Trust, los amigos y los videos. Devuelve lo que pasó.
func advance(delta: float) -> Events:
	elapsed = minf(elapsed + delta, balance.night_seconds)
	sanity = maxf(sanity - delta / night.sanity_drain_interval, 0.0)
	_since_trust_loss += delta
	# Solo cuenta la parte del paso que cae después de la espera sin errores.
	var calm := clampf(_since_trust_loss - balance.trust_recovery_delay, 0.0, delta)
	trust = minf(trust + calm / balance.trust_recovery_interval, METER_MAX)
	for friend: FriendState in friends:
		friend.advance(delta)
	var events := Events.new()
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
