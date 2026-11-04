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


## La noche 0 es el tutorial (decisión de Benja): está aparte de las 5 noches del catálogo.
func test_la_noche_0_es_el_tutorial() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(catalog.night(0), catalog.tutorial, "la noche 0")
	check_eq(catalog.night(1), catalog.nights[0], "la noche 1")
	check_eq(catalog.night(5), catalog.nights[4], "la noche 5")
	check(catalog.night(0).is_tutorial(), "la noche 0 es el tutorial")
	check(not catalog.night(1).is_tutorial(), "la noche 1 no")
	return true


## El tutorial usa las páginas de la noche 1: así, la noche 1 no suma páginas nuevas.
func test_el_tutorial_usa_las_paginas_de_la_noche_1() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(_ids(catalog.known_entities(0)), [&"beast"], "noche 0")
	check_eq(_ids(catalog.new_pages(1)), [], "la noche 1, después del tutorial")
	check_eq(_ids(catalog.new_pages(2)), [&"ghost"], "la noche 2")
	check_eq(_ids(catalog.new_pages(3)), [], "la noche 3")
	return true
