extends RefCounted
## Los videos de la noche (diseño §10.4 y §10.5): los envíos programados, que son justo los que pide la cuota,
## y los videos extra de la acción de mayor riesgo. Cuando a un amigo le toca enviar, el video llega como
## una oferta: hay que empezar a descargarlo a tiempo y terminar la descarga manteniendo presionado
## (decisión de Benja). Si el amigo no puede enviar (está aturdido o sin señal), su video llega cuando puede.
## Lógica pura: NightState la avanza y el chat muestra la descarga.

const FriendState := preload("res://scripts/core/friend_state.gd")


## Un video que un amigo va a enviar.
class Delivery:
	var friend_index: int
	## Segundos desde las 00:00.
	var time: float

	func _init(delivery_friend: int, delivery_time: float) -> void:
		friend_index = delivery_friend
		time = delivery_time


## Un video que llegó y espera su descarga.
class Offer:
	var friend_index: int
	## Ya empezó la descarga: desde ahí corre el tiempo para terminarla.
	var started := false
	## Segundos que quedan para empezar o, si ya empezó, para terminar.
	var time_left: float
	## Cuánto se descargó, de 0 a 1.
	var progress := 0.0

	func _init(offer_friend: int, accept_seconds: float) -> void:
		friend_index = offer_friend
		time_left = accept_seconds

	func is_complete() -> bool:
		return progress >= 1.0 or is_equal_approx(progress, 1.0)


## Lo que pasó con los videos en un paso: de qué amigo es cada uno.
class Changes:
	var offered: Array[int] = []
	var received: Array[int] = []
	var lost: Array[int] = []


## Videos que hay que recibir para ganar la noche.
var quota := 0
var received := 0
var lost := 0
## Los envíos que todavía no llegan.
var pending: Array[Delivery] = []
## Los videos que esperan su descarga: como máximo uno por amigo.
var offers: Array[Offer] = []

var _balance: BalanceData


## Programa `night_quota` envíos repartidos parejo en la noche, cada uno de un amigo al azar.
func _init(night_quota: int, balance: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	quota = night_quota
	_balance = balance
	for index in night_quota:
		var time := balance.night_seconds * (index + 1) / (night_quota + 1)
		pending.append(Delivery.new(rng.randi_range(0, friend_count - 1), time))


## La acción de mayor riesgo y el amigo sobrevivió: envía un video extra apenas pueda.
func add_extra(friend_index: int, now: float) -> void:
	pending.append(Delivery.new(friend_index, now))


## El video del amigo `friend_index` que espera su descarga, o null.
func offer_for(friend_index: int) -> Offer:
	for offer: Offer in offers:
		if offer.friend_index == friend_index:
			return offer
	return null


## Cuánto avanza la descarga por segundo, de 0 a 1, según la señal del amigo: más lenta bajo
## download_slow_below y detenida sin señal (diseño §10.1).
func download_rate(signal_level: float) -> float:
	if signal_level <= 0.0:
		return 0.0
	if signal_level < _balance.download_slow_below:
		return 1.0 / _balance.download_slow_seconds
	return 1.0 / _balance.download_seconds


## Avanza `delta` segundos, hasta `now`. `holding` es el amigo cuya descarga mantiene presionada Matías
## (-1: ninguno); si no había empezado, empieza. Después llegan como ofertas los envíos que tocan, si su
## amigo puede enviar y no tiene otro video esperando.
func advance(now: float, delta: float, friends: Array[FriendState], holding: int) -> Changes:
	var changes := Changes.new()
	for offer: Offer in offers.duplicate():
		if offer.friend_index == holding:
			if not offer.started:
				offer.started = true
				offer.time_left = _balance.video_finish_seconds
			offer.progress = minf(offer.progress + delta * download_rate(friends[holding].signal_level), 1.0)
		if offer.is_complete():
			offers.erase(offer)
			received += 1
			changes.received.append(offer.friend_index)
			continue
		offer.time_left -= delta
		if offer.time_left <= 0.0:
			offers.erase(offer)
			lost += 1
			changes.lost.append(offer.friend_index)
	for delivery: Delivery in pending.duplicate():
		var friend_index := delivery.friend_index
		if delivery.time <= now and friends[friend_index].can_send() and offer_for(friend_index) == null:
			pending.erase(delivery)
			offers.append(Offer.new(friend_index, _balance.video_accept_seconds))
			changes.offered.append(friend_index)
	return changes


func is_quota_met() -> bool:
	return received >= quota
