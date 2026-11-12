extends Node
## El juego de punta a punta (diseño §5), como autoload: el menú, las noches en orden desde la primera de la dificultad
## (la 0, el tutorial, en Normal; la 1 en Difícil), el guardado (al comienzo de cada noche, al ganarla y al terminar el
## tutorial), el paso a la siguiente, reintentar una noche y volver al menú.
## Desde S21i, la partida tiene su dificultad, Normal o Difícil, que se elige al empezarla. Al ganar la noche 5, la
## dificultad queda terminada en el progreso, y así se desbloquea Difícil (decisiones de Benja, 11 de noviembre).
## También tiene las opciones del jugador (diseño §19), que se leen al empezar y se guardan al cambiarlas.

const GameProgress := preload("res://scripts/core/game_progress.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const DESK_SCENE := preload("res://scenes/desk/desk.tscn")

const CATALOG_PATH := "res://data/catalog.tres"
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const SAVE_PATH := "user://save.cfg"
const PROGRESS_PATH := "user://progress.cfg"
const SETTINGS_PATH := "user://settings.cfg"
## Al ganar la última noche, el juego termina (diseño §5).
const LAST_NIGHT := 5

var settings := GameSettings.new()
var save := SaveGame.new(SAVE_PATH)
var progress := GameProgress.new(PROGRESS_PATH)
## Todo el contenido: de aquí salen las dificultades.
var catalog: ContentCatalog = load(CATALOG_PATH)
## La dificultad de la partida en curso, o null antes de elegirla (se usa la de por defecto).
var difficulty: DifficultyData
## La noche que se está jugando.
var night_number := 0


func _ready() -> void:
	settings.read(SETTINGS_PATH)
	settings.apply_audio()


## Nueva partida en `chosen` (sin elegir, la de por defecto): empieza en su primera noche, el tutorial en Normal y la
## noche 1 en Difícil (decisión de Benja, D5).
func new_game(chosen: DifficultyData = null) -> void:
	difficulty = chosen if chosen != null else catalog.default_difficulty()
	start_night(difficulty.first_night)


## Continuar: vuelve a empezar la noche guardada, en su dificultad.
func continue_game() -> void:
	difficulty = catalog.find_difficulty(save.stored_difficulty())
	start_night(maxi(save.stored_night(), difficulty.first_night))


## Las dificultades que todavía no se pueden elegir: Difícil, mientras no se termine Normal (decisión de Benja, D1).
func locked_difficulties() -> Array[DifficultyData]:
	var locked: Array[DifficultyData] = []
	for each: DifficultyData in catalog.difficulties:
		if not progress.is_unlocked(each):
			locked.append(each)
	return locked


## La dificultad de la partida: la elegida o, si todavía no se eligió, la de por defecto.
func current_difficulty() -> DifficultyData:
	return difficulty if difficulty != null else catalog.default_difficulty()


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


## Guarda la noche `number` con su dificultad (se guarda al comienzo, diseño §5) y arma su escritorio, con las
## opciones del jugador y sus botones conectados: saltar el tutorial, seguir, reintentar y volver al menú. Las opciones
## que se cambian en la pausa se guardan.
func prepare_night(number: int) -> Node:
	night_number = number
	save.store(number, current_difficulty().id)
	var desk := DESK_SCENE.instantiate()
	desk.get_node("RequestManager").night_number = number
	desk.get_node("RequestManager").difficulty = current_difficulty()
	desk.ready.connect(func() -> void: desk.apply_settings(settings), CONNECT_ONE_SHOT)
	desk.tutorial_skipped.connect(start_night.bind(1))
	desk.next_night_requested.connect(next_night)
	desk.retry_requested.connect(retry)
	desk.menu_requested.connect(go_to_menu)
	desk.settings_changed.connect(func(_changed: GameSettings) -> void: save_settings())
	desk.get_node("NightManager").night_ended.connect(_on_night_ended)
	if number == 0:
		desk.get_node("RequestManager").tutorial_finished.connect(_on_tutorial_finished)
	return desk


## Al ganar una noche se guarda la siguiente, para que "Continuar" no repita la noche ganada si el jugador vuelve al menú
## (observación 11 del primer testeo). Al ganar la última, el juego terminó: la partida se borra y la dificultad queda
## terminada en el progreso.
func _on_night_ended(ending: NightState.Ending, _fatal_request: RefCounted) -> void:
	if ending != NightState.Ending.WON:
		return
	var next := next_night_number(night_number)
	if next < 0:
		save.clear()
		progress.mark_finished(current_difficulty().id)
	else:
		save.store(next, current_difficulty().id)


## León se despidió en la noche 0: el tutorial terminó, y salir en las tarjetas ya no obliga a repetirlo.
func _on_tutorial_finished() -> void:
	save.store(next_night_number(0), current_difficulty().id)


func _show(scene: Node) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_node(scene)
