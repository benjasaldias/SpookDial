extends Node
## El juego de punta a punta (diseño §5), como autoload: el menú, las noches en orden desde la 0 (el tutorial),
## el guardado al comienzo de cada noche, el paso a la siguiente, reintentar una noche y volver al menú.
## También tiene las opciones del jugador (diseño §19), que se leen al empezar y se guardan al cambiarlas.

const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const DESK_SCENE := preload("res://scenes/desk/desk.tscn")

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const SAVE_PATH := "user://save.cfg"
const SETTINGS_PATH := "user://settings.cfg"
## Al ganar la última noche, el juego termina (diseño §5).
const LAST_NIGHT := 5

var settings := GameSettings.new()
var save := SaveGame.new(SAVE_PATH)
## La noche que se está jugando.
var night_number := 0


func _ready() -> void:
	settings.read(SETTINGS_PATH)
	settings.apply_audio()


## Nueva partida: empieza en la noche 0, el tutorial.
func new_game() -> void:
	start_night(0)


## Continuar: vuelve a empezar la noche guardada.
func continue_game() -> void:
	start_night(maxi(save.stored_night(), 0))


func start_night(number: int) -> void:
	_show(prepare_night(number))


## Reintentar: la noche empieza de nuevo y se vuelve a generar (diseño §5).
func retry() -> void:
	start_night(night_number)


## Empieza la noche siguiente o, después de la última, vuelve al menú.
func next_night() -> void:
	var next := next_night_number(night_number)
	if next < 0:
		go_to_menu()
	else:
		start_night(next)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func save_settings() -> void:
	settings.write(SETTINGS_PATH)


## La noche que sigue a `number`, o -1 si era la última.
func next_night_number(number: int) -> int:
	return number + 1 if number < LAST_NIGHT else -1


## Guarda la noche `number` (se guarda al comienzo, diseño §5) y arma su escritorio, con las opciones del
## jugador y sus botones conectados: saltar el tutorial, seguir, reintentar y volver al menú. Las opciones que
## se cambian en la pausa se guardan.
func prepare_night(number: int) -> Node:
	night_number = number
	save.store(number)
	var desk := DESK_SCENE.instantiate()
	desk.get_node("RequestManager").night_number = number
	desk.ready.connect(func() -> void: desk.apply_settings(settings), CONNECT_ONE_SHOT)
	desk.tutorial_skipped.connect(start_night.bind(1))
	desk.next_night_requested.connect(next_night)
	desk.retry_requested.connect(retry)
	desk.menu_requested.connect(go_to_menu)
	desk.settings_changed.connect(func(_changed: GameSettings) -> void: save_settings())
	desk.get_node("NightManager").night_ended.connect(_on_night_ended)
	return desk


## Al ganar la última noche, el juego terminó: la partida se borra.
func _on_night_ended(ending: NightState.Ending, _fatal_request: RefCounted) -> void:
	if ending == NightState.Ending.WON and night_number >= LAST_NIGHT:
		save.clear()


func _show(scene: Node) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_node(scene)
