extends RefCounted
## Arma una solicitud nueva (docs/02 §2): la entidad, el lugar, la situación, las 2 características
## que la distinguen de las demás entidades conocidas, los señuelos que las camuflan y las
## observaciones del mensaje inicial.

const FriendRequest := preload("res://scripts/core/friend_request.gd")


## Solicitud de la noche `night` para el amigo `friend_index`, o null si la noche no tiene entidades conocidas.
## `trust` acorta el temporizador (Plan 5); mientras no exista, es 100.
static func generate(catalog: ContentCatalog, night: NightData, friend_index: int,
		rng: RandomNumberGenerator, trust := 100.0) -> FriendRequest:
	var known := catalog.known_entities(night.number)
	if known.is_empty():
		return null
	var request := FriendRequest.new()
	request.friend_index = friend_index
	request.entity = known[rng.randi_range(0, known.size() - 1)]
	var entity := request.entity
	request.place_key = entity.place_keys[rng.randi_range(0, entity.place_keys.size() - 1)]
	for observation: ObservationData in entity.observations:
		var values := observation.value_ids()
		request.situation[observation.id] = values[rng.randi_range(0, values.size() - 1)]
	var pairs := distinguishing_pairs(entity, known)
	if pairs.is_empty():
		# Solo pasa si el contenido tiene errores; test_catalog.gd los avisa.
		pairs.append(entity.traits.slice(0, 2))
	request.traits.assign(pairs[rng.randi_range(0, pairs.size() - 1)])
	var decoys := shuffled(catalog.decoys_for_place(request.place_key), rng)
	request.decoys.assign(decoys.slice(0, night.decoys_in_first_message))
	request.first_clues.assign(shuffled(request.traits + request.decoys, rng))
	var count := night.observations_in_first_message(entity.observations.size())
	var chosen := shuffled(entity.observations, rng).slice(0, count)
	for observation: ObservationData in entity.observations:
		if chosen.has(observation):
			request.first_observations.append(observation)
	request.time_left = decision_time(night, trust)
	return request


## Pares de características de `entity` que ninguna otra entidad de `known` tiene juntas.
static func distinguishing_pairs(entity: EntityData, known: Array[EntityData]) -> Array[Array]:
	var pairs: Array[Array] = []
	for i in entity.traits.size():
		for j in range(i + 1, entity.traits.size()):
			var pair := [entity.traits[i], entity.traits[j]]
			var shared := known.any(func(other: EntityData) -> bool: return other != entity and _has_all(other, pair))
			if not shared:
				pairs.append(pair)
	return pairs


## Segundos para responder: el tiempo base de la noche, más corto con Trust bajo (docs/02 §6).
static func decision_time(night: NightData, trust: float) -> float:
	return night.base_decision_time * (0.6 + 0.4 * clampf(trust, 0.0, 100.0) / 100.0)


## Copia de `items` en orden aleatorio, usando `rng` para que las pruebas se puedan repetir.
static func shuffled(items: Array, rng: RandomNumberGenerator) -> Array:
	var result := items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = result[i]
		result[i] = result[j]
		result[j] = swap
	return result


static func _has_all(entity: EntityData, wanted: Array) -> bool:
	for wanted_trait: TraitData in wanted:
		if not entity.traits.any(func(trait_data: TraitData) -> bool: return trait_data.id == wanted_trait.id):
			return false
	return true
