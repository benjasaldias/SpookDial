extends "res://test/test_case.gd"
## El progreso (docs/26 §3.1): qué dificultades se terminaron. Va aparte de la partida, que se borra al ganar la noche 5.

const GameProgress := preload("res://scripts/core/game_progress.gd")
const Fixtures := preload("res://test/content_fixtures.gd")
const TEST_PATH := "user://test_progress.cfg"


func _make_progress() -> GameProgress:
	var progress := GameProgress.new(TEST_PATH)
	progress.clear()
	return progress


func test_sin_progreso() -> bool:
	var progress := _make_progress()
	check(not progress.has_finished(&"normal"), "no se terminó Normal")
	check(not progress.has_finished(&"hard"), "ni Difícil")
	return true


func test_terminar_una_dificultad() -> bool:
	var progress := _make_progress()
	check_eq(progress.mark_finished(&"normal"), OK, "se guarda")
	check(GameProgress.new(TEST_PATH).has_finished(&"normal"), "otra lectura ve Normal terminada")
	check(not progress.has_finished(&"hard"), "Difícil no")
	progress.mark_finished(&"normal")
	progress.mark_finished(&"hard")
	check(progress.has_finished(&"normal") and progress.has_finished(&"hard"), "las dos")
	progress.clear()
	check(not progress.has_finished(&"normal"), "al borrarlo, nada")
	return true


## Difícil se desbloquea al terminar Normal (decisión de Benja, D1). Normal está siempre disponible.
func test_dificil_se_desbloquea_al_terminar_normal() -> bool:
	var catalog := Fixtures.make_catalog()
	var normal := catalog.difficulties[0]
	var hard := Fixtures.add_hard(catalog)
	var progress := _make_progress()
	check(progress.is_unlocked(normal), "Normal, siempre")
	check(not progress.is_unlocked(hard), "Difícil, bloqueada")
	progress.mark_finished(&"normal")
	check(progress.is_unlocked(hard), "al terminar Normal, desbloqueada")
	progress.clear()
	return true
