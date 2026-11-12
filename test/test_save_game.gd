extends "res://test/test_case.gd"
## La partida guardada (diseño §5): la noche en la que va el jugador.

const SaveGame := preload("res://scripts/core/save_game.gd")
const TEST_PATH := "user://test_save.cfg"


func _make_save() -> SaveGame:
	var save := SaveGame.new(TEST_PATH)
	save.clear()
	return save


func test_sin_partida() -> bool:
	var save := _make_save()
	check(not save.has_game(), "no hay partida")
	check_eq(save.stored_night(), -1, "ninguna noche")
	return true


func test_guarda_la_noche_al_empezarla() -> bool:
	var save := _make_save()
	check_eq(save.store(0), OK, "se guarda el tutorial")
	check(save.has_game(), "hay partida")
	check_eq(save.stored_night(), 0, "en el tutorial")
	save.store(3)
	check_eq(SaveGame.new(TEST_PATH).stored_night(), 3, "otra lectura ve la noche 3")
	save.clear()
	check(not save.has_game(), "al borrarla ya no hay")
	return true


func test_una_noche_que_no_existe_no_cuenta() -> bool:
	var save := _make_save()
	var file := ConfigFile.new()
	file.set_value(SaveGame.SECTION, "night", 9)
	file.save(TEST_PATH)
	check(not save.has_game(), "la noche 9 no existe")
	save.clear()
	return true


## La partida guarda también su dificultad (docs/26 §3.1). Sin decirla, Normal.
func test_guarda_la_dificultad() -> bool:
	var save := _make_save()
	check_eq(save.store(3, &"hard"), OK, "se guarda")
	check_eq(SaveGame.new(TEST_PATH).stored_difficulty(), &"hard", "otra lectura ve Difícil")
	check_eq(save.stored_night(), 3, "y la noche 3")
	save.store(2)
	check_eq(save.stored_difficulty(), &"normal", "sin decirla, Normal")
	save.clear()
	return true


## Una partida guardada antes de que existieran las dificultades se lee como Normal.
func test_una_partida_vieja_es_normal() -> bool:
	var save := _make_save()
	check_eq(save.stored_difficulty(), &"normal", "sin partida, Normal")
	var file := ConfigFile.new()
	file.set_value(SaveGame.SECTION, "night", 2)
	file.save(TEST_PATH)
	check_eq(save.stored_night(), 2, "la noche se lee igual")
	check_eq(save.stored_difficulty(), &"normal", "la dificultad, Normal")
	save.clear()
	return true
