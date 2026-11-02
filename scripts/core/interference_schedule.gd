extends RefCounted
## Las interferencias de la noche (diseño §10.1): golpes de estática que le quitan señal a un amigo de una
## vez. Cada una se anuncia unos segundos antes: la entrada del amigo titila y suena estática.
## Lógica pura: NightState la avanza y la aplica.


## Una interferencia que va a golpear a un amigo.
class Interference:
	var friend_index: int
	## Segundos desde las 00:00.
	var time: float

	func _init(interference_friend: int, interference_time: float) -> void:
		friend_index = interference_friend
		time = interference_time


## Las que todavía no golpean, en orden.
var pending: Array[Interference] = []


## Reparte `count` interferencias en la noche: una por tramo igual, a una hora al azar lejos de los bordes
## del tramo, cada una para un amigo al azar.
func _init(count: int, night_seconds: float, friend_count: int, rng: RandomNumberGenerator) -> void:
	if count <= 0:
		return
	var span := night_seconds / count
	for index in count:
		var time := span * (index + rng.randf_range(0.2, 0.8))
		pending.append(Interference.new(rng.randi_range(0, friend_count - 1), time))


## Al amigo `friend_index` le golpea una interferencia dentro de `warning` segundos o menos.
func is_warning(friend_index: int, now: float, warning: float) -> bool:
	for interference: Interference in pending:
		if interference.friend_index == friend_index and interference.time - now <= warning:
			return true
	return false


## Quita las interferencias que ya golpearon y devuelve a qué amigo le tocó cada una.
func take_due(now: float) -> Array[int]:
	var hit: Array[int] = []
	for interference: Interference in pending.duplicate():
		if interference.time <= now:
			pending.erase(interference)
			hit.append(interference.friend_index)
	return hit
