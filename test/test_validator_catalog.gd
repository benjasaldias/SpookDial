extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_catalogo_valido() -> bool:
	var errors := ContentValidator.validate_catalog(Fixtures.make_catalog())
	check(errors.is_empty(), str(errors))
	return true


func test_amigos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.friends[2].id = &"leon"
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "el id 'leon' está repetido en amigos")
	catalog.friends.pop_back()
	errors = ContentValidator.validate_catalog(catalog)
	check_contains(errors, "tiene 2 amigos y deben ser 3")
	return true


func test_noches_en_orden() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].number = 3
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "la noche en la posición 2 tiene el número 3")
	return true


func test_entidad_repetida() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[2].new_entities.append(catalog.nights[0].new_entities[0])
	check_contains(ContentValidator.validate_catalog(catalog), "aparece como nueva en más de una noche")
	catalog = Fixtures.make_catalog()
	catalog.nights[2].new_entities.append(Fixtures.make_entity(&"beast"))
	check_contains(ContentValidator.validate_catalog(catalog), "el id 'beast' está repetido en entidades")
	return true


func test_caracteristica_compartida_por_tres() -> bool:
	var catalog := Fixtures.make_catalog()
	var wraith := Fixtures.make_entity(&"wraith")
	catalog.nights[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1")
	wraith.traits[0] = Fixtures.make_trait(&"beast_trait_1")
	catalog.nights[2].new_entities.append(wraith)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': la usan 3 entidades")
	return true


func test_caracteristica_compartida_con_otra_categoria() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1", ClueCategory.Kind.SOUND)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': tiene otra categoría o texto en 'ghost'")
	return true


func test_mismas_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	var ghost: EntityData = catalog.nights[1].new_entities[0]
	ghost.traits[0] = Fixtures.make_trait(&"beast_trait_2")
	ghost.traits[1] = Fixtures.make_trait(&"beast_trait_1")
	check_contains(ContentValidator.validate_catalog(catalog), "'beast' y 'ghost': tienen las mismas características")
	return true


func test_incluye_los_errores_de_cada_entidad() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].new_entities[0].actions.pop_back()
	check_contains(ContentValidator.validate_catalog(catalog), "Entidad 'ghost': tiene 3 acciones")
	return true


func test_chat_guionado() -> bool:
	var catalog := Fixtures.make_catalog()
	var chat := ChatScriptData.new()
	chat.friend = FriendData.new()
	catalog.nights[0].scripted_chat = chat
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "Noche 1: el chat guionado no es de un amigo del catálogo")
	check_contains(errors, "Noche 1: el chat guionado no tiene líneas")
	return true


func test_sin_saludos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.greeting_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Catálogo: no tiene saludos para el mensaje inicial")
	return true


func test_tutorial() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial.number = 1
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: su número debe ser 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].friend = FriendData.new()
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: el amigo no es del catálogo")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[1].entity = catalog.nights[1].new_entities[0]
	check_contains(ContentValidator.validate_catalog(catalog),
			"Tutorial, solicitud 2: la entidad 'ghost' no está en las páginas de la noche 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o1"] = &"maybe"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: 'maybe' no es un valor de 'o1'")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o9"] = &"yes"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: la observación 'o9' no existe")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: hay un espacio vacío en 'tutorial_requests'")
	return true


func test_sin_tutorial_tambien_es_valido() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial = null
	check(ContentValidator.validate_catalog(catalog).is_empty(), "el tutorial es opcional para el validador")
	return true


func test_los_accidentes() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].incident_count = 1
	check_contains(ContentValidator.validate_catalog(catalog), "la noche 1 pide accidentes y el catálogo no tiene")
	catalog.incidents.append(Fixtures.make_incident())
	check(ContentValidator.validate_catalog(catalog).is_empty(), "con uno, está bien")
	catalog.incidents[0].wrong_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Accidente 'trip': necesita 1 o 2 malas ideas")
	catalog.incidents.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "hay un espacio vacío en 'incidents'")
	return true
