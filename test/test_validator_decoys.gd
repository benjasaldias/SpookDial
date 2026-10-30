extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_entidad_con_todas_sus_caracteristicas_en_otra() -> bool:
	var catalog := Fixtures.make_catalog()
	var ghost: EntityData = catalog.nights[1].new_entities[0]
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_1"))
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_2"))
	check_contains(ContentValidator.validate_catalog(catalog),
			"Entidad 'beast': todas sus características las tiene también 'ghost'")
	return true


func test_senuelo_vacio() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Catálogo: hay un espacio vacío en 'decoys'")
	return true


func test_ids_de_los_senuelos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"decoy_sight"))
	catalog.decoys.append(Fixtures.make_decoy(&"beast_trait_1"))
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "el id 'decoy_sight' está repetido en señuelos")
	check_contains(errors, "Señuelo 'beast_trait_1': usa el id de una característica")
	return true


func test_senuelo_de_un_lugar_que_no_existe() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys[0].place_keys = ["PLACE_NOWHERE"]
	check_contains(ContentValidator.validate_catalog(catalog),
			"Señuelo 'decoy_sight': el lugar 'PLACE_NOWHERE' no es de ninguna entidad")
	return true


func test_faltan_senuelos_para_un_lugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[2].decoys_in_first_message = 3
	check_contains(ContentValidator.validate_catalog(catalog),
			"Noche 3: el lugar 'K_PLACE' tiene 2 señuelos y la noche pide 3")
	return true


func test_textos_de_los_senuelos() -> bool:
	var texts := {"K_DECOY_decoy_sight": "hace frío", "K_DECOY_decoy_sound": "K_DECOY_decoy_sound"}
	var translate := func(key: String) -> String: return texts.get(key, "Texto de *%s*" % key)
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), translate)
	check_contains(errors, "Señuelo 'decoy_sight': su texto debe tener una sola frase entre asteriscos")
	check_contains(errors, "Señuelo 'decoy_sound': la clave 'K_DECOY_decoy_sound' no está en ningún CSV")
	return true
