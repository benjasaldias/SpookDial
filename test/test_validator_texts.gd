extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


## Traducción falsa: cada clave tiene un texto con una frase entre asteriscos, salvo las de `missing`.
func _translate_except(missing: Array) -> Callable:
	return func(key: String) -> String:
		return key if missing.has(key) else "Texto de *%s*" % key


func test_textos_completos() -> bool:
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), _translate_except([]))
	check(errors.is_empty(), str(errors))
	return true


func test_clave_que_no_esta_en_el_csv() -> bool:
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), _translate_except(["K_beast_LORE"]))
	check_contains(errors, "Entidad 'beast', folclore: la clave 'K_beast_LORE' no está en ningún CSV")
	return true


func test_clave_vacia() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.friends[0].name_key = ""
	var errors := ContentValidator.validate_texts(catalog, _translate_except([]))
	check_contains(errors, "Amigo 'leon': falta la clave de texto")
	return true


func test_caracteristica_sin_una_frase_entre_asteriscos() -> bool:
	var texts := {
		"K_TRAIT_beast_trait_1": "vio un hombrecito",
		"K_TRAIT_beast_trait_2": "vio un *hombrecito* con *ropa*",
	}
	var translate := func(key: String) -> String: return texts.get(key, "Texto de *%s*" % key)
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), translate)
	check_contains(errors, "Característica 'beast_trait_1': su texto debe tener una sola frase entre asteriscos")
	check_contains(errors, "Característica 'beast_trait_2': su texto debe tener una sola frase entre asteriscos")
	return true
