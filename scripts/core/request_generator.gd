extends RefCounted
## Arma una solicitud nueva (docs/02 §2): la entidad, el lugar, la situación, las 2 características
## que la distinguen de las demás entidades conocidas, los señuelos que las camuflan, el saludo, lo que le pasa al
## amigo, si dice el lugar y, a veces, una pista para el mensaje inicial. Las observaciones no se eligen aquí: salen
## al preguntar su categoría.

const FriendRequest := preload("res://scripts/core/friend_request.gd")


## Solicitud de la noche `night` para el amigo `friend_index`, o null si la noche no tiene entidades conocidas.
## `trust` acorta el temporizador (Plan 5); mientras no exista, es 100.
static func generate(catalog: ContentCatalog, night: NightData, friend_index: int,
		rng: RandomNumberGenerator, trust := 100.0) -> FriendRequest:
	var known := catalog.known_entities(night.number)
	if known.is_empty():
		return null
	return build(catalog, night, friend_index, known[rng.randi_range(0, known.size() - 1)], rng, trust)


## La solicitud fija `data` del tutorial (decisión de Benja): su amigo, su entidad, su situación (lo que falte,
## al azar) y la pista si la pide. El temporizador espera.
static func generate_tutorial(catalog: ContentCatalog, night: NightData, data: TutorialRequestData,
		rng: RandomNumberGenerator) -> FriendRequest:
	var request := build(catalog, night, catalog.friends.find(data.friend), data.entity, rng)
	for observation_id: StringName in data.situation:
		request.situation[observation_id] = data.situation[observation_id]
	request.hint = request.traits[0] if data.with_hint else null
	# La noche 0 enseña: el lugar se dice siempre, y cada característica, con su forma de siempre.
	request.says_place = true
	for trait_data: TraitData in request.traits:
		request.trait_forms[trait_data.id] = trait_data.text_key
	if not data.decoys.is_empty():
		request.decoys.assign(data.decoys)
		request.clues.assign(request.traits + request.decoys)
	request.timer_paused = true
	return request


## Arma la solicitud de `entity` para el amigo `friend_index`.
static func build(catalog: ContentCatalog, night: NightData, friend_index: int, entity: EntityData,
		rng: RandomNumberGenerator, trust := 100.0) -> FriendRequest:
	var known := catalog.known_entities(night.number)
	var request := FriendRequest.new()
	request.friend_index = friend_index
	request.entity = entity
	if not catalog.greeting_keys.is_empty():
		request.greeting_key = catalog.greeting_keys[rng.randi_range(0, catalog.greeting_keys.size() - 1)]
	request.place_key = entity.place_keys[rng.randi_range(0, entity.place_keys.size() - 1)]
	for observation: ObservationData in entity.observations:
		var values := observation.value_ids()
		request.situation[observation.id] = values[rng.randi_range(0, values.size() - 1)]
	var pairs := distinguishing_pairs(entity, known)
	if pairs.is_empty():
		# Solo pasa si el contenido tiene errores; test_catalog.gd los avisa.
		pairs.append(entity.traits.slice(0, 2))
	request.traits.assign(pairs[rng.randi_range(0, pairs.size() - 1)])
	# Cada característica se dice con una de sus formas, al azar (decisión de Benja, 11 de noviembre).
	for trait_data: TraitData in request.traits:
		var forms := trait_data.text_keys()
		request.trait_forms[trait_data.id] = forms[rng.randi_range(0, forms.size() - 1)]
	var decoys := shuffled(catalog.decoys_for_place(request.place_key), rng)
	request.decoys.assign(decoys.slice(0, night.decoys_per_request))
	request.clues.assign(shuffled(request.traits + request.decoys, rng))
	# Siempre se tira el azar, para que la secuencia de una semilla no dependa de la probabilidad de la noche.
	var hint_roll := rng.randf()
	var hint_index := rng.randi_range(0, request.traits.size() - 1)
	if hint_roll < night.first_hint_chance:
		request.hint = request.traits[hint_index]
	request.says_place = rng.randf() < night.place_chance
	if not catalog.predicament_keys.is_empty():
		request.predicament_key = catalog.predicament_keys[rng.randi_range(0, catalog.predicament_keys.size() - 1)]
	request.question_cost = catalog.balance.question_cost
	request.decoy_cost = catalog.balance.decoy_cost
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
