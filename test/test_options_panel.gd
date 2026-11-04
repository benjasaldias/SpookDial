extends "res://test/test_case.gd"
## Las opciones (diseño §19), en el panel que usan el menú principal y el de pausa.

const PANEL := preload("res://scenes/ui/options_panel.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")


func _make_panel() -> Control:
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	return panel


func test_empieza_oculto_y_muestra_las_opciones() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto")
	var settings := GameSettings.new()
	settings.volumes[&"Effects"] = 0.4
	settings.still_camera = true
	panel.open(settings)
	check(panel.visible, "se abre")
	check_eq((panel.get_node("Center/Box/Effects/Slider") as HSlider).value, 40.0, "volumen de los efectos")
	check_eq((panel.get_node("Center/Box/Master/Slider") as HSlider).value, 100.0, "volumen general")
	check((panel.get_node("Center/Box/Camera") as CheckBox).button_pressed, "cámara fija")
	check(not (panel.get_node("Center/Box/Flashes") as CheckBox).button_pressed, "destellos normales")
	panel.free()
	return true


## Cada cambio llega a las opciones al tiro, y el panel avisa para que se apliquen y se guarden.
func test_cada_cambio_se_aplica() -> bool:
	var panel := _make_panel()
	var settings := GameSettings.new()
	panel.open(settings)
	var changes := []
	panel.changed.connect(func(changed: GameSettings) -> void: changes.append(changed))
	(panel.get_node("Center/Box/Ambience/Slider") as HSlider).value = 25.0
	check_eq(settings.volumes[&"Ambience"], 0.25, "volumen del ambiente")
	(panel.get_node("Center/Box/Flashes") as CheckBox).button_pressed = true
	(panel.get_node("Center/Box/Camera") as CheckBox).button_pressed = true
	(panel.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
	check(settings.reduce_flashes and settings.still_camera and settings.slow_timers, "los interruptores")
	check_eq(changes.size(), 4, "avisa cada cambio")
	check(changes.all(func(changed: GameSettings) -> bool: return changed == settings), "con las opciones")
	GameSettings.new().apply_audio()
	panel.free()
	return true


func test_volver_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open(GameSettings.new())
	var closed := []
	panel.closed.connect(func() -> void: closed.append(true))
	(panel.get_node("Center/Box/Back") as Button).pressed.emit()
	check(not panel.visible, "se cierra")
	check_eq(closed, [true], "avisa")
	panel.free()
	return true


func test_sus_textos_existen() -> bool:
	var panel := _make_panel()
	for key: String in panel.TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	panel.free()
	return true
