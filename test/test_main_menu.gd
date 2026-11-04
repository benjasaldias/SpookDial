extends "res://test/test_case.gd"
## El menú principal (diseño §5): Continuar (solo con una partida guardada), Nueva partida, Opciones y Salir.

const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")


## El menú sin GameState: avisa con sus señales, y la prueba le dice qué partida hay.
func _make_menu(saved_night: int) -> Control:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	menu.setup(saved_night, GameSettings.new())
	return menu


func _button(menu: Control, button_name: String) -> Button:
	return menu.get_node("Center/Box/" + button_name) as Button


func _record(menu: Control, pressed: Array) -> void:
	for signal_name: String in ["continue_pressed", "new_game_pressed", "quit_pressed"]:
		menu.connect(signal_name, func() -> void: pressed.append(signal_name))


func test_sin_partida_no_se_continua() -> bool:
	var menu := _make_menu(-1)
	check(not _button(menu, "Continue").visible, "sin Continuar")
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	check_eq(pressed, ["new_game_pressed"], "empieza al tiro")
	menu.free()
	return true


func test_con_partida_se_continua() -> bool:
	var menu := _make_menu(2)
	var continue_button := _button(menu, "Continue")
	check(continue_button.visible, "con Continuar")
	check_eq(continue_button.text, String(TranslationServer.translate("MENU_CONTINUE")).format({"night": 2}), "noche 2")
	var pressed := []
	_record(menu, pressed)
	continue_button.pressed.emit()
	check_eq(pressed, ["continue_pressed"], "continúa")
	menu.free()
	menu = _make_menu(0)
	check_eq(_button(menu, "Continue").text, String(TranslationServer.translate("MENU_CONTINUE_TUTORIAL")), "el tutorial")
	menu.free()
	return true


## Con una partida guardada, empezar de nuevo pide confirmación: se pierde la partida.
func test_nueva_partida_pide_confirmar() -> bool:
	var menu := _make_menu(3)
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	var confirm := menu.get_node("Center/Box/Confirm") as Control
	check(confirm.visible, "pregunta")
	check_eq(pressed, [], "todavía no empieza")
	(confirm.get_node("Buttons/No") as Button).pressed.emit()
	check(not confirm.visible, "se cancela")
	_button(menu, "NewGame").pressed.emit()
	(confirm.get_node("Buttons/Yes") as Button).pressed.emit()
	check_eq(pressed, ["new_game_pressed"], "empieza de nuevo")
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
	menu.free()
	return true
