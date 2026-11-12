extends SceneTree
## Capturas del Plan 9.6 (Extremo) para revisarlas a ojo, a la resolución que se pida: la letra nítida depende de ella.
## No es una prueba: corre con ventana.
## Uso: timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan96.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan96_<ancho>_<nombre>.png:
## - choice_locked: la elección, con Difícil y Extremo bloqueados;
## - choice_hard: con Normal terminada (solo Extremo bloqueado);
## - choice: con las 3 libres y Extremo marcado;
## - wounded: el chat del amigo que empieza herido en una noche de Extremo, con su entrada en el PC.

const DESK := preload("res://scenes/desk/desk.tscn")
const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")

var _dir := ""
var _width := 1280
var _catalog: ContentCatalog = load("res://data/catalog.tres")


func _initialize() -> void:
	_capture.call_deferred()


## El menú sin GameState, sin partida guardada y con `locked` bloqueadas.
func _menu(locked_ids: Array) -> Control:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	root.add_child(menu)
	var locked: Array[DifficultyData] = []
	for difficulty_id: StringName in locked_ids:
		locked.append(_catalog.find_difficulty(difficulty_id))
	menu.setup(-1, GameSettings.new(), null, _catalog.difficulties, locked)
	(menu.get_node("Center/Box/NewGame") as Button).pressed.emit()
	return menu


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	var menu := _menu([&"hard", &"extreme"])
	await _save("choice_locked", 0.5)
	menu.free()
	menu = _menu([&"extreme"])
	await _save("choice_hard", 0.3)
	menu.free()
	menu = _menu([])
	var options := menu.get_node("Center/Box/Difficulty/Options").get_children().filter(func(node: Node) -> bool:
		return node is Button)
	(options[-1] as Button).button_pressed = true
	await _save("choice", 0.3)
	menu.free()
	# Una noche de Extremo: el amigo herido y su aviso.
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = 1
	manager.difficulty = _catalog.find_difficulty(&"extreme")
	manager.requests_arrive = false
	manager.random_seed = 21
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	await create_timer(0.2).timeout
	var wounded: int = manager.wounded[0]
	desk.get_node("DeskPlane/Entries").get_child(wounded).pressed.emit()
	await _save("wounded", 1.5)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan96_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
