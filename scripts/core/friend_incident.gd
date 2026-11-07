extends RefCounted
## Un accidente en curso (decisión de Benja, 7 de noviembre): el amigo espera una respuesta de sentido común
## durante unos segundos. Lógica pura: RequestManager lo avanza y el chat muestra sus opciones.

var friend_index := 0
var data: IncidentData
## Las opciones, barajadas: claves de messages.csv.
var options: Array[String] = []
## Segundos que quedan para responder.
var time_left := 0.0


func _init(incident: IncidentData, friend: int, seconds: float, rng: RandomNumberGenerator) -> void:
	data = incident
	friend_index = friend
	time_left = seconds
	options.append(incident.correct_key)
	options.append_array(incident.wrong_keys)
	for index in range(options.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := options[index]
		options[index] = options[other]
		options[other] = swap


func advance(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)


func is_out_of_time() -> bool:
	return time_left <= 0.0


## La opción `index` es la buena idea.
func is_correct(index: int) -> bool:
	return options[index] == data.correct_key
