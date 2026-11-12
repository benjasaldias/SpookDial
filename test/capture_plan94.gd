extends SceneTree
## Capturas del Plan 9.4 (Normal y Difícil) para revisarlas a ojo, a la resolución que se pida: la letra nítida depende de
## ella. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan94.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan94_<ancho>_<nombre>.png:
## - menu: el menú con una partida guardada (Continuar dice la noche y la dificultad);
## - choice_locked y choice: la elección de la dificultad, con Difícil bloqueada y desbloqueada;
## - confirm: la confirmación, con una partida guardada;
## - hard_chat: el chat de Difícil, con las preguntas hechas y la página abierta desde el índice;
## - victory: el resumen de la noche 5 de Normal, con el aviso de Difícil desbloqueada.

const DESK := preload("res://scenes/desk/desk.tscn")
const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")

var _dir := ""
var _width := 1280
var _catalog: ContentCatalog = load("res://data/catalog.tres")


func _initialize() -> void:
	_capture.call_deferred()


## El menú sin GameState, con una partida en la noche 3 de Normal y Difícil bloqueada o no.
func _menu(hard_locked: bool) -> Control:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	root.add_child(menu)
	var locked: Array[DifficultyData] = []
	if hard_locked:
		locked.append(_catalog.find_difficulty(&"hard"))
	menu.setup(3, GameSettings.new(), _catalog.find_difficulty(&"normal"), _catalog.difficulties, locked)
	return menu


## Un escritorio en la noche `night_number` de `difficulty_id`, con la cámara fija y sin la señal que baja sola,
## interferencias ni videos del director.
func _desk(night_number: int, difficulty_id: StringName) -> Node2D:
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = night_number
	manager.difficulty = manager.catalog.find_difficulty(difficulty_id)
	manager.requests_arrive = false
	manager.random_seed = 21
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	for friend: RefCounted in manager.state.friends:
		friend.signal_decay_interval = 0.0
	manager.state.interferences.pending.clear()
	manager.state.videos.pending.clear()
	return desk


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	var menu := _menu(true)
	await _save("menu", 0.5)
	(menu.get_node("Center/Box/NewGame") as Button).pressed.emit()
	await _save("choice_locked", 0.3)
	(menu.get_node("Center/Box/Difficulty/Buttons/Start") as Button).pressed.emit()
	await _save("confirm", 0.3)
	menu.free()
	menu = _menu(false)
	(menu.get_node("Center/Box/NewGame") as Button).pressed.emit()
	await _save("choice", 0.3)
	menu.free()
	# El chat de Difícil: se pregunta, se lee y la página se abre desde el índice del cuaderno.
	var desk := _desk(3, &"hard")
	var manager := desk.get_node("RequestManager")
	var request: RefCounted = manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.ask(0, ClueCategory.Kind.SOUND)
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	await create_timer(1.0).timeout
	desk._on_entity_page_requested(0, request.entity)
	await _save("hard_chat", 5.0)
	desk.free()
	# La victoria de Normal, con Difícil desbloqueada.
	desk = _desk(5, &"normal")
	desk.unlocks_on_win.assign([_catalog.find_difficulty(&"hard")])
	desk.get_node("RequestManager").state.videos.received = 4
	desk._on_night_ended(NightState.Ending.WON, null)
	await _save("victory", 2.0)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan94_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
