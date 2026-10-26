extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")


func _ids(entities: Array[EntityData]) -> Array:
	return entities.map(func(entity: EntityData) -> StringName: return entity.id)


func test_observaciones_del_primer_mensaje() -> bool:
	var night := NightData.new()
	check_eq(night.observations_in_first_message(3), 3, "todas")
	night.first_message_observations = NightData.FirstMessageObservations.ALL_BUT_ONE
	check_eq(night.observations_in_first_message(3), 2, "todas menos 1, de 3")
	check_eq(night.observations_in_first_message(2), 1, "todas menos 1, de 2")
	night.first_message_observations = NightData.FirstMessageObservations.ONE
	check_eq(night.observations_in_first_message(3), 1, "una")
	return true


func test_entidades_conocidas_se_acumulan() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(_ids(catalog.known_entities(1)), [&"beast"], "noche 1")
	check_eq(_ids(catalog.known_entities(2)), [&"beast", &"ghost"], "noche 2")
	check_eq(_ids(catalog.known_entities(5)), [&"beast", &"ghost"], "noche 5")
	return true


func test_todas_las_entidades() -> bool:
	check_eq(_ids(Fixtures.make_catalog().all_entities()), [&"beast", &"ghost"], "todas")
	return true
