extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")


func _ids(decoys: Array[DecoyData]) -> Array:
	return decoys.map(func(decoy: DecoyData) -> StringName: return decoy.id)


func test_un_senuelo_sin_lugares_sirve_en_cualquiera() -> bool:
	var decoy := Fixtures.make_decoy(&"cold")
	check(decoy.fits_place("K_PLACE"), "sin lugares: sirve en cualquiera")
	decoy.place_keys = ["PLACE_FOREST"]
	check(decoy.fits_place("PLACE_FOREST"), "sirve en su lugar")
	check(not decoy.fits_place("K_PLACE"), "no sirve en otro lugar")
	return true


func test_un_senuelo_se_arma_como_una_caracteristica() -> bool:
	var decoy := Fixtures.make_decoy(&"cold", ClueCategory.Kind.ENVIRONMENT)
	check(decoy is TraitData, "tiene id, categoría y texto, como una característica")
	check_eq(decoy.category, ClueCategory.Kind.ENVIRONMENT, "categoría")
	check_eq(decoy.text_key, "K_DECOY_cold", "clave del texto")
	return true


func test_senuelos_de_un_lugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"moss", ClueCategory.Kind.SIGHT, ["PLACE_FOREST"]))
	check_eq(_ids(catalog.decoys_for_place("PLACE_FOREST")), [&"decoy_sight", &"decoy_sound", &"moss"], "bosque")
	check_eq(_ids(catalog.decoys_for_place("K_PLACE")), [&"decoy_sight", &"decoy_sound"], "otro lugar")
	return true


func test_una_noche_pide_1_senuelo_por_defecto() -> bool:
	check_eq(NightData.new().decoys_in_first_message, 1, "señuelos por defecto")
	return true
