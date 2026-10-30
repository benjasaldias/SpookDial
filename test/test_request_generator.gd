extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids(items: Array) -> Array:
	return items.map(func(item: Resource) -> StringName: return item.get("id"))


## "beast" con 3 características; "ghost" comparte las 2 primeras con "beast".
func _entities_with_shared_traits() -> Array[EntityData]:
	var beast := Fixtures.make_entity(&"beast")
	beast.traits.append(Fixtures.make_trait(&"beast_trait_3"))
	var ghost := Fixtures.make_entity(&"ghost")
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_1"))
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_2"))
	var entities: Array[EntityData] = [beast, ghost]
	return entities


func test_pares_que_distinguen() -> bool:
	var entities := _entities_with_shared_traits()
	var pairs := RequestGenerator.distinguishing_pairs(entities[0], entities)
	check_eq(pairs.map(_ids), [[&"beast_trait_1", &"beast_trait_3"], [&"beast_trait_2", &"beast_trait_3"]],
			"el par 1 y 2 también lo tiene ghost")
	return true


func test_sin_otras_entidades_cualquier_par_sirve() -> bool:
	var entities := _entities_with_shared_traits()
	var alone: Array[EntityData] = [entities[0]]
	check_eq(RequestGenerator.distinguishing_pairs(entities[0], alone).size(), 3, "3 pares de 3 características")
	return true


func test_la_solicitud_trae_2_caracteristicas_que_distinguen() -> bool:
	var catalog := Fixtures.make_catalog()
	var entities := _entities_with_shared_traits()
	catalog.nights[0].new_entities.assign(entities)
	catalog.nights[1].new_entities.clear()
	for seed_value in 30:
		var request := RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(seed_value))
		var pairs := RequestGenerator.distinguishing_pairs(request.entity, entities).map(_ids)
		check(pairs.has(_ids(request.traits)), "semilla %d: el par %s distingue" % [seed_value, _ids(request.traits)])
	return true


func test_situacion_lugar_y_amigo() -> bool:
	var catalog := Fixtures.make_catalog()
	var request := RequestGenerator.generate(catalog, catalog.nights[1], 2, _rng(5))
	check_eq(request.friend_index, 2, "amigo")
	check(request.entity.place_keys.has(request.place_key), "uno de los lugares de la entidad")
	check_eq(request.situation.size(), 2, "un valor por observación")
	for observation: ObservationData in request.entity.observations:
		check(observation.has_value(request.situation[observation.id]), "valor de %s" % observation.id)
	return true


func test_senuelos_del_lugar_mezclados_con_las_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"elsewhere", ClueCategory.Kind.SIGHT, ["K_NOWHERE"]))
	catalog.nights[0].decoys_in_first_message = 2
	var request := RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(8))
	check_eq(request.decoys.size(), 2, "2 señuelos")
	for decoy: DecoyData in request.decoys:
		check(decoy.fits_place(request.place_key), "%s es de este lugar" % decoy.id)
	check_eq(request.first_clues.size(), 4, "2 características y 2 señuelos")
	for clue: TraitData in request.traits + request.decoys:
		check(request.first_clues.has(clue), "el mensaje trae %s" % clue.id)
	return true


func test_observaciones_del_mensaje_inicial() -> bool:
	var catalog := Fixtures.make_catalog()
	var night: NightData = catalog.nights[0]
	var request := RequestGenerator.generate(catalog, night, 0, _rng(1))
	check_eq(request.first_observations, request.entity.observations, "todas")
	night.first_message_observations = NightData.FirstMessageObservations.ONE
	request = RequestGenerator.generate(catalog, night, 0, _rng(1))
	check_eq(request.first_observations.size(), 1, "una")
	return true


func test_tiempo_para_responder() -> bool:
	var night := NightData.new()
	night.base_decision_time = 40.0
	check_eq(RequestGenerator.decision_time(night, 100.0), 40.0, "Trust 100")
	check_eq(RequestGenerator.decision_time(night, 50.0), 32.0, "Trust 50")
	check_eq(RequestGenerator.decision_time(night, 0.0), 24.0, "Trust 0")
	var catalog := Fixtures.make_catalog()
	check_eq(RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(1)).time_left, 45.0, "temporizador de la noche 1")
	return true


func test_sin_entidades_conocidas_no_hay_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].new_entities.clear()
	check_eq(RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(1)), null, "noche sin entidades")
	return true


func test_misma_semilla_misma_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	var first := RequestGenerator.generate(catalog, catalog.nights[1], 0, _rng(42))
	var second := RequestGenerator.generate(catalog, catalog.nights[1], 0, _rng(42))
	check_eq(second.entity, first.entity, "entidad")
	check_eq(second.situation, first.situation, "situación")
	check_eq(_ids(second.first_clues), _ids(first.first_clues), "frases y su orden")
	return true
