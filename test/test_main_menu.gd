extends "res://test/test_case.gd"
## El menú principal (diseño §5): Continuar (solo con una partida guardada), Nueva partida, Opciones y Salir. Desde S21i,
## Nueva partida pide elegir la dificultad, y Continuar dice cuál es (docs/26 §3.5).

const MENU := preload("res://scenes/menu/main_menu.tscn")
const Fixtures := preload("res://test/content_fixtures.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")

var _catalog: ContentCatalog


## El menú sin GameState: avisa con sus señales, y la prueba le dice qué partida hay y qué dificultades están
## bloqueadas. Las dificultades son las del catálogo de prueba: Normal y Difícil.
func _make_menu(saved_night: int, saved_difficulty_id := &"normal", hard_locked := true) -> Control:
	_catalog = Fixtures.make_catalog()
	Fixtures.add_hard(_catalog)
	var menu := MENU.instantiate()
	menu.use_game_state = false
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var locked: Array[DifficultyData] = []
	if hard_locked:
		locked.append(_hard())
	menu.setup(saved_night, GameSettings.new(), _catalog.find_difficulty(saved_difficulty_id), _catalog.difficulties,
			locked)
	return menu


func _normal() -> DifficultyData:
	return _catalog.difficulties[0]


func _hard() -> DifficultyData:
	return _catalog.difficulties[1]


func _button(menu: Control, button_name: String) -> Button:
	return menu.get_node("Center/Box/" + button_name) as Button


func _choice(menu: Control) -> Control:
	return menu.get_node("Center/Box/Difficulty") as Control


## Los botones de las dificultades, en orden.
func _options(menu: Control) -> Array[Node]:
	return menu.get_node("Center/Box/Difficulty/Options").get_children().filter(func(node: Node) -> bool:
		return node is Button)


func _record(menu: Control, pressed: Array) -> void:
	for signal_name: String in ["continue_pressed", "quit_pressed"]:
		menu.connect(signal_name, func() -> void: pressed.append(signal_name))
	menu.new_game_pressed.connect(func(difficulty: DifficultyData) -> void:
		pressed.append(["new_game_pressed", difficulty.id]))


func test_sin_partida_no_se_continua() -> bool:
	var menu := _make_menu(-1)
	check(not _button(menu, "Continue").visible, "sin Continuar")
	menu.free()
	return true


func test_con_partida_se_continua() -> bool:
	var menu := _make_menu(2)
	var continue_button := _button(menu, "Continue")
	check(continue_button.visible, "con Continuar")
	var pressed := []
	_record(menu, pressed)
	continue_button.pressed.emit()
	check_eq(pressed, ["continue_pressed"], "continúa")
	menu.free()
	return true


## Continuar dice la noche y la dificultad de la partida guardada: "Continuar: noche 2 · Difícil".
func test_continuar_dice_la_dificultad() -> bool:
	var menu := _make_menu(2, &"hard", false)
	var expected := "%s · %s" % [String(tr("MENU_CONTINUE")).format({"night": 2}), tr(_hard().name_key)]
	check_eq(_button(menu, "Continue").text, expected, "la noche 2 en Difícil")
	menu.free()
	menu = _make_menu(0)
	check_eq(_button(menu, "Continue").text, "%s · %s" % [tr("MENU_CONTINUE_TUTORIAL"), tr(_normal().name_key)],
			"el tutorial, en Normal")
	menu.free()
	return true


## Nueva partida no empieza al tiro: pide elegir la dificultad, en lugar de los botones del menú.
func test_nueva_partida_pide_la_dificultad() -> bool:
	var menu := _make_menu(-1)
	var pressed := []
	_record(menu, pressed)
	check(not _choice(menu).visible, "la elección empieza escondida")
	_button(menu, "NewGame").pressed.emit()
	check(_choice(menu).visible, "aparece la elección")
	check(not _button(menu, "NewGame").visible and not _button(menu, "Quit").visible, "sin los botones del menú")
	check_eq(_options(menu).map(func(option: Button) -> String: return option.text),
			[tr(_normal().name_key), tr(_hard().name_key)], "Normal y Difícil")
	check_eq(pressed, [], "todavía no empieza")
	menu.free()
	return true


## Normal viene marcada, y "Empezar" la elige.
func test_normal_viene_marcada() -> bool:
	var menu := _make_menu(-1)
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	check((_options(menu)[0] as Button).button_pressed, "Normal, marcada")
	check(not (_options(menu)[1] as Button).button_pressed, "Difícil, no")
	var normal := _options(menu)[0] as Button
	check_eq(normal.get_theme_stylebox(&"pressed"), normal.get_theme_stylebox(&"hover"), "la marcada se ve iluminada")
	_button(menu, "Difficulty/Buttons/Start").pressed.emit()
	check_eq(pressed, [["new_game_pressed", &"normal"]], "empieza en Normal")
	menu.free()
	return true


## Mientras no se termine Normal, Difícil está bloqueada: no se puede elegir, lleva un candado y dice qué falta.
func test_dificil_bloqueada() -> bool:
	var menu := _make_menu(-1)
	_button(menu, "NewGame").pressed.emit()
	var hard := _options(menu)[1] as Button
	check(hard.disabled, "no se puede elegir")
	check(hard.icon != null, "con el candado")
	check(not (_options(menu)[0] as Button).disabled and (_options(menu)[0] as Button).icon == null, "Normal, libre")
	var lock_text := String(tr("MENU_LOCKED")).format({"difficulty": tr(_normal().name_key)})
	var labels := menu.get_node("Center/Box/Difficulty/Options").get_children().filter(func(node: Node) -> bool:
		return node is Label and (node as Label).text == lock_text)
	check_eq(labels.size(), 1, "dice que hay que terminar Normal")
	menu.free()
	return true


func test_dificil_desbloqueada() -> bool:
	var menu := _make_menu(-1, &"normal", false)
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	var hard := _options(menu)[1] as Button
	check(not hard.disabled and hard.icon == null, "se puede elegir, sin candado")
	hard.button_pressed = true
	check(not (_options(menu)[0] as Button).button_pressed, "una sola marcada")
	_button(menu, "Difficulty/Buttons/Start").pressed.emit()
	check_eq(pressed, [["new_game_pressed", &"hard"]], "empieza en Difícil")
	menu.free()
	return true


func test_volver_de_la_eleccion() -> bool:
	var menu := _make_menu(-1)
	_button(menu, "NewGame").pressed.emit()
	_button(menu, "Difficulty/Buttons/Back").pressed.emit()
	check(not _choice(menu).visible, "se esconde la elección")
	check(_button(menu, "NewGame").visible and _button(menu, "Options").visible, "vuelven los botones del menú")
	menu.free()
	return true


## Con una partida guardada, después de elegir pide confirmar, porque la borra.
func test_con_partida_se_confirma_despues_de_elegir() -> bool:
	var menu := _make_menu(3)
	var pressed := []
	_record(menu, pressed)
	var confirm := menu.get_node("Center/Box/Confirm") as Control
	_button(menu, "NewGame").pressed.emit()
	check(not confirm.visible, "primero se elige")
	_button(menu, "Difficulty/Buttons/Start").pressed.emit()
	check(confirm.visible and not _choice(menu).visible, "después pregunta")
	check_eq(pressed, [], "todavía no empieza")
	(confirm.get_node("Buttons/No") as Button).pressed.emit()
	check(not confirm.visible and _button(menu, "NewGame").visible, "se cancela y vuelve al menú")
	_button(menu, "NewGame").pressed.emit()
	_button(menu, "Difficulty/Buttons/Start").pressed.emit()
	(confirm.get_node("Buttons/Yes") as Button).pressed.emit()
	check_eq(pressed, [["new_game_pressed", &"normal"]], "empieza de nuevo, en Normal")
	menu.free()
	return true


func test_opciones_y_salir() -> bool:
	var menu := _make_menu(-1)
	_button(menu, "Options").pressed.emit()
	check((menu.get_node("OptionsPanel") as Control).visible, "abre las opciones")
	var pressed := []
	_record(menu, pressed)
	_button(menu, "Quit").pressed.emit()
	check_eq(pressed, ["quit_pressed"], "sale")
	menu.free()
	return true


func test_sus_textos_existen() -> bool:
	var menu := _make_menu(-1)
	for key: String in menu.TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	check(String(TranslationServer.translate("MENU_LOCKED")).contains("{difficulty}"), "MENU_LOCKED dice cuál terminar")
	menu.free()
	return true
