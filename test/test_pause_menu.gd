extends "res://test/test_case.gd"
## El menú de pausa (decisión de Benja, sesión 18): con Esc y sin paneles abiertos, la noche se pausa. Desde ahí
## se sigue, se cambian las opciones o se vuelve al menú principal.

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func _escape() -> InputEventAction:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	return escape


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _pause_menu(desk: Node2D) -> Control:
	return desk.get_node("Overlay/PauseMenu") as Control


func test_esc_pausa_y_continuar_sigue() -> bool:
	var desk := _make_desk()
	var menu := _pause_menu(desk)
	check(not menu.visible, "oculto")
	desk._unhandled_input(_escape())
	check(_tree().paused, "la noche se pausa")
	check(menu.visible, "aparece el menú de pausa")
	check_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "funciona en pausa")
	(menu.get_node("Center/Box/Resume") as Button).pressed.emit()
	check(not _tree().paused, "sigue la noche")
	check(not menu.visible, "se va")
	_tree().paused = false
	desk.free()
	return true


func test_con_un_panel_abierto_esc_solo_lo_cierra() -> bool:
	var desk := _make_desk()
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk._unhandled_input(_escape())
	check(not (desk.get_node("UI/ChatPanel") as Control).visible, "se cerró el chat")
	check(not _tree().paused, "sin pausa")
	_tree().paused = false
	desk.free()
	return true


func test_al_terminar_la_noche_no_se_pausa() -> bool:
	var desk := _make_desk()
	desk.get_node("NightManager").finish(NightState.Ending.SANITY)
	desk._unhandled_input(_escape())
	check(not _tree().paused, "sin pausa")
	_tree().paused = false
	desk.free()
	return true


func test_volver_al_menu() -> bool:
	var desk := _make_desk()
	var requested := []
	desk.menu_requested.connect(func() -> void: requested.append(true))
	desk._unhandled_input(_escape())
	(_pause_menu(desk).get_node("Center/Box/Menu") as Button).pressed.emit()
	check_eq(requested, [true], "pide volver al menú")
	_tree().paused = false
	desk.free()
	return true


## Las opciones cambiadas en la pausa se aplican al escritorio y se avisan, para guardarlas.
func test_las_opciones_de_la_pausa() -> bool:
	var desk := _make_desk()
	var settings := GameSettings.new()
	desk.apply_settings(settings)
	var saved := []
	desk.settings_changed.connect(func(changed: GameSettings) -> void: saved.append(changed))
	desk._unhandled_input(_escape())
	var menu := _pause_menu(desk)
	(menu.get_node("Center/Box/Options") as Button).pressed.emit()
	var options := menu.get_node("OptionsPanel") as Control
	check(options.visible, "se abren las opciones")
	(options.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
	check_eq(desk.get_node("RequestManager").timer_scale, 1.5, "se aplican al escritorio")
	check_eq(saved, [settings], "y se avisan")
	_tree().paused = false
	desk.free()
	return true


func test_sus_textos_existen() -> bool:
	var desk := _make_desk()
	for key: String in _pause_menu(desk).TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	desk.free()
	return true
