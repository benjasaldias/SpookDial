extends "res://test/test_case.gd"
## El juego de punta a punta (diseño §5): las noches en orden y el guardado. Usa su propia copia de GameState,
## con archivos de prueba, para no tocar la partida ni las opciones del jugador.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const TEST_SAVE := "user://test_game_save.cfg"


func _make_game() -> Node:
	var game := GameStateScript.new()
	game.save = SaveGame.new(TEST_SAVE)
	game.save.clear()
	return game


func _free(game: Node) -> void:
	game.save.clear()
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
