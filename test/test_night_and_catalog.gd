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
	check_eq(catalog.night(1), catalog.nights()[0], "la noche 1")
	check_eq(catalog.night(5), catalog.nights()[4], "la noche 5")
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


## Normal y Difícil (docs/26 §3.1): cada dificultad tiene sus noches, y la noche 0 es la misma para todas.
func test_cada_dificultad_tiene_sus_noches() -> bool:
	var catalog := Fixtures.make_catalog()
	var normal := catalog.difficulties[0]
	var hard := Fixtures.add_hard(catalog)
	check_eq(catalog.night(2, hard), hard.nights[1], "la noche 2 de Difícil")
	check_eq(catalog.night(2, normal), normal.nights[1], "la noche 2 de Normal")
	check(catalog.night(2, hard) != catalog.night(2, normal), "son noches distintas")
	check_eq(catalog.night(0, hard), catalog.tutorial, "la noche 0 es una sola")
	check_eq(catalog.nights(hard), hard.nights, "las noches de Difícil")
	check_eq(_ids(catalog.known_entities(2, hard)), [&"beast", &"ghost"], "las entidades de Difícil")
	check_eq(_ids(catalog.new_pages(2, hard)), [&"ghost"], "las páginas nuevas de Difícil")
	return true


## Sin decir la dificultad, se usa la de por defecto: la primera del catálogo (Normal).
func test_sin_dificultad_se_usa_la_de_por_defecto() -> bool:
	var catalog := Fixtures.make_catalog()
	Fixtures.add_hard(catalog)
	check_eq(catalog.default_difficulty(), catalog.difficulties[0], "la primera")
	check_eq(catalog.nights(), catalog.difficulties[0].nights, "sus noches")
	check_eq(catalog.night(3), catalog.difficulties[0].nights[2], "su noche 3")
	check(ContentCatalog.new().default_difficulty() == null, "un catálogo vacío no tiene")
	return true


## Una dificultad se busca por su id (el que guarda la partida). Si no existe, la de por defecto.
func test_buscar_una_dificultad() -> bool:
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	check_eq(catalog.find_difficulty(&"hard"), hard, "Difícil")
	check_eq(catalog.find_difficulty(&"normal"), catalog.difficulties[0], "Normal")
	check_eq(catalog.find_difficulty(&"imposible"), catalog.difficulties[0], "una que no existe: la de por defecto")
	return true


func test_una_dificultad_por_defecto() -> bool:
	var difficulty := DifficultyData.new()
	check_eq(difficulty.first_night, 0, "empieza en la noche 0")
	check(difficulty.highlights, "la identificación es guiada")
	check(difficulty.unlocked_by == null, "no pide nada para desbloquearse")
	return true
