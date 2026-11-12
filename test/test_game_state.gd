extends "res://test/test_case.gd"
## El juego de punta a punta (diseño §5): las noches en orden y el guardado. Usa su propia copia de GameState,
## con archivos de prueba, para no tocar la partida ni las opciones del jugador.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const GameProgress := preload("res://scripts/core/game_progress.gd")
const TEST_SAVE := "user://test_game_save.cfg"
const TEST_PROGRESS := "user://test_game_progress.cfg"


## GameState sin cambiar de escena: guarda el escritorio que iba a mostrar.
class ShownGame extends "res://scripts/autoload/game_state.gd":
	var shown: Node

	func _show(scene: Node) -> void:
		if shown != null:
			shown.free()
		shown = scene


func _make_game() -> Node:
	var game := ShownGame.new()
	game.save = SaveGame.new(TEST_SAVE)
	game.save.clear()
	game.progress = GameProgress.new(TEST_PROGRESS)
	game.progress.clear()
	return game


func _free(game: Node) -> void:
	game.save.clear()
	game.progress.clear()
	if game.shown != null:
		game.shown.free()
	game.free()


func test_la_noche_que_sigue() -> bool:
	var game := _make_game()
	check_eq(game.next_night_number(0), 1, "después del tutorial, la noche 1")
	check_eq(game.next_night_number(4), 5, "después de la 4, la 5")
	check_eq(game.next_night_number(5), -1, "después de la 5, se terminó el juego")
	_free(game)
	return true


## Cada noche se guarda al empezar (diseño §5), y el escritorio la juega con las opciones del jugador.
func test_preparar_una_noche_la_guarda() -> bool:
	var game := _make_game()
	game.settings.slow_timers = true
	var desk: Node = game.prepare_night(2)
	check_eq(game.night_number, 2, "la noche en curso")
	check_eq(game.save.stored_night(), 2, "guardada al empezar")
	check_eq(desk.get_node("RequestManager").night_number, 2, "el escritorio juega la noche 2")
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	check_eq(desk.get_node("RequestManager").timer_scale, 1.5, "con las opciones del jugador")
	check(desk.next_night_requested.is_connected(game.next_night), "seguir")
	check(desk.retry_requested.is_connected(game.retry), "reintentar")
	check(desk.menu_requested.is_connected(game.go_to_menu), "volver al menú")
	desk.free()
	_free(game)
	return true


## Al ganar la noche 5, el juego terminó: la partida se borra y "Continuar" desaparece del menú.
func test_al_ganar_la_ultima_noche_se_borra_la_partida() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(4)
	game._on_night_ended(NightState.Ending.WON, null)
	check_eq(game.save.stored_night(), 5, "la noche 4 no es la última: queda guardada la 5")
	desk.free()
	desk = game.prepare_night(5)
	game._on_night_ended(NightState.Ending.SANITY, null)
	check(game.save.has_game(), "perder la noche 5 no la borra")
	game._on_night_ended(NightState.Ending.WON, null)
	check(not game.save.has_game(), "ganarla, sí")
	desk.free()
	_free(game)
	return true


## Al ganar una noche se guarda la siguiente: si el jugador vuelve al menú, "Continuar" no repite la noche ganada
## (observación 11 del primer testeo). Perderla no cambia lo guardado.
func test_ganar_una_noche_guarda_la_siguiente() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(2)
	game._on_night_ended(NightState.Ending.TRUST, null)
	check_eq(game.save.stored_night(), 2, "perderla no cambia nada")
	game._on_night_ended(NightState.Ending.WON, null)
	check_eq(game.save.stored_night(), 3, "ganarla guarda la noche 3")
	desk.free()
	_free(game)
	return true


## Cuando León se despide en la noche 0, el tutorial terminó: se guarda la noche 1, para que salir en las tarjetas no
## obligue a repetirlo.
func test_al_despedirse_leon_se_guarda_la_noche_1() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(0)
	check_eq(game.save.stored_night(), 0, "el tutorial, al empezar")
	desk.get_node("RequestManager").tutorial_finished.emit()
	check_eq(game.save.stored_night(), 1, "la noche 1, al despedirse León")
	desk.free()
	_free(game)
	return true


## Las opciones cambiadas en la pausa se guardan.
func test_las_opciones_de_la_pausa_se_guardan() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(1)
	check_eq(desk.settings_changed.get_connections().size(), 1, "GameState las guarda")
	desk.free()
	_free(game)
	return true


## Una partida nueva empieza en la noche de su dificultad: Normal en el tutorial y Difícil en la noche 1 (D5).
func test_nueva_partida_empieza_en_la_noche_de_su_dificultad() -> bool:
	var game := _make_game()
	var hard: DifficultyData = game.catalog.find_difficulty(&"hard")
	game.new_game(hard)
	check_eq(game.difficulty, hard, "la partida es en Difícil")
	check_eq(game.night_number, 1, "Difícil empieza en la noche 1")
	var manager: Node = game.shown.get_node("RequestManager")
	check_eq(manager.night_number, 1, "el escritorio juega la noche 1")
	check_eq(manager.difficulty, hard, "en Difícil")
	game.new_game(game.catalog.find_difficulty(&"normal"))
	check_eq(game.night_number, 0, "Normal empieza en el tutorial")
	_free(game)
	return true


## Continuar vuelve a la noche y a la dificultad guardadas.
func test_continuar_vuelve_a_la_dificultad_guardada() -> bool:
	var game := _make_game()
	game.save.store(3, &"hard")
	game.continue_game()
	check_eq(game.difficulty.id, &"hard", "Difícil")
	check_eq(game.night_number, 3, "la noche 3")
	check_eq(game.shown.get_node("RequestManager").difficulty, game.difficulty, "el escritorio, en Difícil")
	_free(game)
	return true


## Cada noche se guarda con su dificultad.
func test_preparar_una_noche_guarda_su_dificultad() -> bool:
	var game := _make_game()
	game.difficulty = game.catalog.find_difficulty(&"hard")
	var desk: Node = game.prepare_night(2)
	check_eq(game.save.stored_difficulty(), &"hard", "guardada en Difícil")
	check_eq(desk.get_node("RequestManager").difficulty, game.difficulty, "el escritorio la juega")
	desk.free()
	game.difficulty = null
	desk = game.prepare_night(2)
	check_eq(game.save.stored_difficulty(), &"normal", "sin elegir, Normal")
	desk.free()
	_free(game)
	return true


## Al ganar la noche 5, la dificultad queda terminada: así se desbloquea Difícil (D1).
func test_ganar_la_noche_5_termina_la_dificultad() -> bool:
	var game := _make_game()
	game.difficulty = game.catalog.find_difficulty(&"normal")
	var desk: Node = game.prepare_night(4)
	game._on_night_ended(NightState.Ending.WON, null)
	check(not game.progress.has_finished(&"normal"), "la noche 4 no termina nada")
	desk.free()
	desk = game.prepare_night(5)
	game._on_night_ended(NightState.Ending.QUOTA, null)
	check(not game.progress.has_finished(&"normal"), "perder la noche 5, tampoco")
	game._on_night_ended(NightState.Ending.WON, null)
	check(game.progress.has_finished(&"normal"), "ganarla termina Normal")
	check(game.progress.is_unlocked(game.catalog.find_difficulty(&"hard")), "y desbloquea Difícil")
	desk.free()
	_free(game)
	return true


## El menú bloquea Difícil mientras no se termine Normal (D1).
func test_dificil_bloqueada_hasta_terminar_normal() -> bool:
	var game := _make_game()
	check_eq(game.locked_difficulties(), [game.catalog.find_difficulty(&"hard")], "Difícil, bloqueada")
	game.progress.mark_finished(&"normal")
	check_eq(game.locked_difficulties(), [], "al terminar Normal, ninguna")
	_free(game)
	return true


## La noche 5 de Normal desbloquea Difícil: el escritorio lo sabe, para avisarlo en el resumen (docs/26 §3.5).
func test_la_noche_5_de_normal_desbloquea_dificil() -> bool:
	var game := _make_game()
	game.difficulty = game.catalog.find_difficulty(&"normal")
	var desk: Node = game.prepare_night(5)
	check_eq(desk.unlocks_on_win, [game.catalog.find_difficulty(&"hard")], "ganarla desbloquea Difícil")
	desk.free()
	desk = game.prepare_night(4)
	check_eq(desk.unlocks_on_win, [], "la noche 4 no desbloquea nada")
	desk.free()
	game.difficulty = game.catalog.find_difficulty(&"hard")
	desk = game.prepare_night(5)
	check_eq(desk.unlocks_on_win, [], "terminar Difícil no desbloquea nada")
	desk.free()
	_free(game)
	return true


## Si Difícil ya estaba desbloqueada, volver a terminar Normal no lo avisa.
func test_si_ya_estaba_desbloqueada_no_avisa() -> bool:
	var game := _make_game()
	game.progress.mark_finished(&"normal")
	game.difficulty = game.catalog.find_difficulty(&"normal")
	var desk: Node = game.prepare_night(5)
	check_eq(desk.unlocks_on_win, [], "ya estaba desbloqueada")
	desk.free()
	_free(game)
	return true
