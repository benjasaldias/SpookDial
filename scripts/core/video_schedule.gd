extends RefCounted
## Los videos de la noche (diseño §10.4): los envíos programados, que son justo los que pide la cuota,
## y los videos extra de la acción de mayor riesgo. Si al amigo le toca enviar y no puede (está
## aturdido), su video llega cuando se recupera (decisión de Benja).
## Por ahora los videos se reciben solos al llegar: aceptarlos y descargarlos llega en el Plan 6.


## Un video que un amigo va a enviar.
class Delivery:
	var friend_index: int
	## Segundos desde las 00:00.
	var time: float

	func _init(delivery_friend: int, delivery_time: float) -> void:
		friend_index = delivery_friend
		time = delivery_time


## Videos que hay que recibir para ganar la noche.
var quota := 0
var received := 0
## Los envíos que todavía no llegan.
var pending: Array[Delivery] = []


## Programa `night_quota` envíos repartidos parejo en la noche, cada uno de un amigo al azar.
func _init(night_quota: int, night_seconds: float, friend_count: int, rng: RandomNumberGenerator) -> void:
	quota = night_quota
	for index in night_quota:
		var time := night_seconds * (index + 1) / (night_quota + 1)
		pending.append(Delivery.new(rng.randi_range(0, friend_count - 1), time))


## La acción de mayor riesgo y el amigo sobrevivió: envía un video extra apenas pueda.
func add_extra(friend_index: int, now: float) -> void:
	pending.append(Delivery.new(friend_index, now))


## Recibe los envíos que ya tocan y cuyo amigo puede enviar (`can_send` recibe el índice del amigo).
## Devuelve de qué amigo es cada video que llegó.
func receive_due(now: float, can_send: Callable) -> Array[int]:
	var arrived: Array[int] = []
	for delivery: Delivery in pending.duplicate():
		if delivery.time <= now and can_send.call(delivery.friend_index):
			pending.erase(delivery)
			arrived.append(delivery.friend_index)
	received += arrived.size()
	return arrived


func is_quota_met() -> bool:
	return received >= quota
