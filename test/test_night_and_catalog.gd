extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")


func _ids(entities: Array[EntityData]) -> Array:
	return entities.map(func(entity: EntityData) -> StringName: return entity.id)


func test_pista_inicial_y_senuelos_por_defecto() -> bool:
	var night := NightData.new()
	check_eq(night.first_hint_chance, 1.0, "el mensaje inicial trae su pista, salvo que la noche diga otra cosa")
	check_eq(night.decoys_per_request, 1, "un señuelo por solicitud")
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
