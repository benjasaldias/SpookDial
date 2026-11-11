extends RefCounted
## Las interferencias de la noche (diseño §10.1): golpes de estática que le quitan señal a un amigo de una
## vez. Cada una se anuncia unos segundos antes: la entrada del amigo titila y suena estática. Llegan con las olas
## (decisión de Benja, 11 de noviembre): el director dice cuándo y RequestManager las agrega aquí.
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


## Agrega una interferencia para el amigo `friend_index` a la hora `time`, en orden.
func add(friend_index: int, time: float) -> void:
	var index := 0
	while index < pending.size() and pending[index].time <= time:
		index += 1
	pending.insert(index, Interference.new(friend_index, time))


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
