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
