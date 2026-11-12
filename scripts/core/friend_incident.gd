extends RefCounted
## Un accidente en curso (decisión de Benja, 7 de noviembre): el amigo espera una respuesta de sentido común
## durante unos segundos. Lógica pura: RequestManager lo avanza y el chat muestra sus opciones.
## Desde el Plan 9.7, una decisión de la historia llega igual que un accidente (docs/21 §2): con sus opciones en el orden del
## guion, y `decision` dice de dónde viene.

var friend_index := 0
var data: IncidentData
## La decisión de la historia, si el accidente es una (y entonces `data` es null).
var decision: StoryDecisionData
## Las opciones, barajadas: claves de messages.csv.
var options: Array[String] = []
## Segundos que quedan para responder.
var time_left := 0.0


func _init(incident: IncidentData, friend: int, seconds: float, rng: RandomNumberGenerator) -> void:
	data = incident
	friend_index = friend
	time_left = seconds
	if incident == null:
		return
	options.append(incident.correct_key)
	options.append_array(incident.wrong_keys)
	for index in range(options.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := options[index]
		options[index] = options[other]
		options[other] = swap


## La decisión `story_decision` del amigo `friend`, con `seconds` para responder. Sus opciones no se barajan: la historia se
## repite igual (Plan 9.7).
static func for_decision(story_decision: StoryDecisionData, friend: int, seconds: float) -> RefCounted:
	var incident: RefCounted = new(null, friend, seconds, null)
	incident.decision = story_decision
	for option: StoryOptionData in story_decision.options:
		incident.options.append(option.label_key)
	return incident


func advance(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)


func is_out_of_time() -> bool:
	return time_left <= 0.0


## La opción `index` es la buena idea (en una decisión, una buena opción).
func is_correct(index: int) -> bool:
	if decision != null:
		return decision.options[index].good
	return options[index] == data.correct_key
