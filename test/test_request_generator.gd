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
	catalog.nights()[0].new_entities.assign(entities)
	catalog.nights()[1].new_entities.clear()
	for seed_value in 30:
		var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(seed_value))
		var pairs := RequestGenerator.distinguishing_pairs(request.entity, entities).map(_ids)
		check(pairs.has(_ids(request.traits)), "semilla %d: el par %s distingue" % [seed_value, _ids(request.traits)])
	return true


func test_situacion_lugar_y_amigo() -> bool:
	var catalog := Fixtures.make_catalog()
	var request := RequestGenerator.generate(catalog, catalog.nights()[1], 2, _rng(5))
	check_eq(request.friend_index, 2, "amigo")
	check(request.entity.place_keys.has(request.place_key), "uno de los lugares de la entidad")
	check_eq(request.situation.size(), 2, "un valor por observación")
	for observation: ObservationData in request.entity.observations:
		check(observation.has_value(request.situation[observation.id]), "valor de %s" % observation.id)
	return true


func test_senuelos_del_lugar_mezclados_con_las_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"elsewhere", ClueCategory.Kind.SIGHT, ["K_NOWHERE"]))
	catalog.nights()[0].decoys_per_request = 2
	var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(8))
	check_eq(request.decoys.size(), 2, "2 señuelos")
	for decoy: DecoyData in request.decoys:
		check(decoy.fits_place(request.place_key), "%s es de este lugar" % decoy.id)
	check_eq(request.clues.size(), 4, "2 características y 2 señuelos")
	for clue: TraitData in request.traits + request.decoys:
		check(request.clues.has(clue), "al preguntar, el amigo cuenta %s" % clue.id)
	return true


func test_la_pista_del_mensaje_inicial_es_opcional() -> bool:
	var catalog := Fixtures.make_catalog()
	var night: NightData = catalog.nights()[0]
	night.first_hint_chance = 1.0
	for seed_value in 20:
		var request := RequestGenerator.generate(catalog, night, 0, _rng(seed_value))
		check(request.hint != null and request.traits.has(request.hint), "semilla %d: la pista es una característica" % seed_value)
	night.first_hint_chance = 0.0
	for seed_value in 20:
		check_eq(RequestGenerator.generate(catalog, night, 0, _rng(seed_value)).hint, null, "sin pista")
	night.first_hint_chance = 0.5
	var with_hint := 0
	for seed_value in 200:
		if RequestGenerator.generate(catalog, night, 0, _rng(seed_value)).hint != null:
			with_hint += 1
	check(with_hint > 60 and with_hint < 140, "con 50 %%, más o menos la mitad trae pista: %d de 200" % with_hint)
	return true


func test_el_saludo_sale_del_catalogo() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.greeting_keys.assign(["K_CALL_1", "K_CALL_2", "K_CALL_3"])
	var seen := {}
	for seed_value in 40:
		var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(seed_value))
		check(catalog.greeting_keys.has(request.greeting_key), "el saludo es del catálogo: %s" % request.greeting_key)
		seen[request.greeting_key] = true
	check_eq(seen.size(), 3, "con varias semillas salen los 3")
	catalog.greeting_keys.clear()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).greeting_key, "", "sin saludos, sin saludo")
	return true


func test_preguntar_cuesta_lo_que_dice_el_equilibrio() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).question_cost, 5.0, "por defecto, 5 s")
	catalog.balance.question_cost = 8.0
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).question_cost, 8.0, "el de BalanceData")
	return true


## "Matías piensa" dura lo que dice el equilibrio: 2 s (decisión de Benja, 11 de noviembre).
func test_copia_el_tiempo_de_pensar() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).thinking_seconds, 2.0, "por defecto, 2 s")
	catalog.balance.thinking_seconds = 1.5
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).thinking_seconds, 1.5, "el de BalanceData")
	return true


func test_tiempo_para_responder() -> bool:
	var night := NightData.new()
	night.base_decision_time = 40.0
	check_eq(RequestGenerator.decision_time(night, 100.0), 40.0, "Trust 100")
	check_eq(RequestGenerator.decision_time(night, 50.0), 32.0, "Trust 50")
	check_eq(RequestGenerator.decision_time(night, 0.0), 24.0, "Trust 0")
	var catalog := Fixtures.make_catalog()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).time_left, 45.0, "temporizador de la noche 1")
	return true


func test_sin_entidades_conocidas_no_hay_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[0].new_entities.clear()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)), null, "noche sin entidades")
	return true


func test_misma_semilla_misma_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	var first := RequestGenerator.generate(catalog, catalog.nights()[1], 0, _rng(42))
	var second := RequestGenerator.generate(catalog, catalog.nights()[1], 0, _rng(42))
	check_eq(second.entity, first.entity, "entidad")
	check_eq(second.situation, first.situation, "situación")
	check_eq(_ids(second.clues), _ids(first.clues), "frases y su orden")
	check_eq(second.hint, first.hint, "pista")
	check_eq(second.greeting_key, first.greeting_key, "saludo")
	return true


## Las solicitudes del tutorial son fijas: su amigo, su entidad, su situación y si trae pista. El temporizador
## espera (decisión de Benja).
func test_las_solicitudes_del_tutorial_son_fijas() -> bool:
	var catalog := Fixtures.make_catalog()
	var tutorial := catalog.tutorial
	var first := RequestGenerator.generate_tutorial(catalog, tutorial, tutorial.tutorial_requests[0], _rng(1))
	check_eq(first.friend_index, 0, "la pide León")
	check_eq(first.entity.id, &"beast", "beast")
	check_eq(first.situation[&"o1"], &"yes", "o1 fijo")
	check(first.situation.has(&"o2"), "o2, al azar")
	check(first.hint == null, "sin pista")
	check(first.timer_paused, "el temporizador espera")
	check_eq(first.time_left, tutorial.base_decision_time, "con todo su tiempo")
	for trait_data: TraitData in first.traits:
		check_eq(first.text_key_for(trait_data), trait_data.text_key, "cada característica, con su forma de siempre")
	tutorial.tutorial_requests[0].with_hint = true
	var hinted := RequestGenerator.generate_tutorial(catalog, tutorial, tutorial.tutorial_requests[0], _rng(1))
	check(hinted.hint != null and hinted.traits.has(hinted.hint), "con pista, si la pide")
	return true


## La solicitud del tutorial puede traer señuelos fijos: el polerón rojo de Gonzalo (Plan 9.2).
func test_el_tutorial_con_senuelos_fijos() -> bool:
	var catalog := Fixtures.make_catalog()
	var data := catalog.tutorial.tutorial_requests[0]
	data.decoys.assign([Fixtures.make_decoy(&"hoodie")])
	var request := RequestGenerator.generate_tutorial(catalog, catalog.tutorial, data, _rng(4))
	check_eq(_ids(request.decoys), [&"hoodie"], "el señuelo fijo")
	check_eq(_ids(request.clues), [&"beast_trait_1", &"beast_trait_2", &"hoodie"], "en orden: las características y él")
	return true


## El mensaje inicial dice el lugar solo a veces (decisión de Benja, 11 de noviembre): según la noche.
func test_el_lugar_segun_la_probabilidad_de_la_noche() -> bool:
	var catalog := Fixtures.make_catalog()
	var night: NightData = catalog.nights()[0]
	night.place_chance = 1.0
	for seed_value in 20:
		check(RequestGenerator.generate(catalog, night, 0, _rng(seed_value)).says_place, "con 100 %%, siempre: %d" % seed_value)
	night.place_chance = 0.0
	for seed_value in 20:
		check(not RequestGenerator.generate(catalog, night, 0, _rng(seed_value)).says_place, "con 0 %%, nunca: %d" % seed_value)
	night.place_chance = 0.5
	var with_place := 0
	for seed_value in 200:
		if RequestGenerator.generate(catalog, night, 0, _rng(seed_value)).says_place:
			with_place += 1
	check(with_place > 60 and with_place < 140, "con 50 %%, más o menos la mitad: %d de 200" % with_place)
	return true


## Lo que le pasa al amigo sale del catálogo, y lo dice siempre (decisión de Benja, 11 de noviembre).
func test_siempre_dice_lo_que_le_pasa() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.predicament_keys.assign(["K_LOST", "K_FOLLOWED", "K_HEARD"])
	var seen := {}
	for seed_value in 40:
		var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(seed_value))
		check(catalog.predicament_keys.has(request.predicament_key), "es del catálogo: %s" % request.predicament_key)
		seen[request.predicament_key] = true
	check_eq(seen.size(), 3, "con varias semillas salen las 3")
	catalog.predicament_keys.clear()
	check_eq(RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(1)).predicament_key, "", "sin frases, nada")
	return true


## La noche 0 enseña: el lugar se dice siempre.
func test_en_el_tutorial_siempre_dice_el_lugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial.place_chance = 0.0
	for seed_value in 10:
		var request := RequestGenerator.generate_tutorial(catalog, catalog.tutorial,
				catalog.tutorial.tutorial_requests[0], _rng(seed_value))
		check(request.says_place, "semilla %d" % seed_value)
	return true


## Cada característica se dice con una de sus formas, al azar (decisión de Benja, 11 de noviembre).
func test_cada_caracteristica_con_una_de_sus_formas() -> bool:
	var catalog := Fixtures.make_catalog()
	var seen := {}
	for seed_value in 40:
		var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(seed_value))
		for trait_data: TraitData in request.traits:
			var key := request.text_key_for(trait_data)
			check(trait_data.text_keys().has(key), "semilla %d: %s es una forma de %s" % [seed_value, key, trait_data.id])
			seen[key] = true
		for decoy: DecoyData in request.decoys:
			check_eq(request.text_key_for(decoy), decoy.text_key, "un señuelo se dice siempre igual")
	check_eq(seen.size(), 6, "con varias semillas salen las 3 formas de las 2 características")
	return true


## La pista del mensaje inicial usa la misma forma que después cuenta el amigo.
func test_la_pista_usa_la_misma_forma() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[0].first_hint_chance = 1.0
	var request := RequestGenerator.generate(catalog, catalog.nights()[0], 0, _rng(3))
	check(request.trait_forms.has(request.hint.id), "la pista tiene su forma")
	return true
