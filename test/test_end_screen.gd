extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const SCREEN := preload("res://scenes/ui/end_screen.tscn")
const NightState := preload("res://scripts/core/night_state.gd")

const FRIENDS: Array[String] = ["León", "Gonzalo", "Agustín"]


func _make_screen() -> Control:
	var screen := SCREEN.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(screen)
	return screen


## Estado de la noche 1 del catálogo de prueba: cuota de 2 videos.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	return NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())


func _translated(key: String) -> String:
	return String(TranslationServer.translate(key))


func test_empieza_oculta_y_tapa_el_escritorio() -> bool:
	var screen := _make_screen()
	check(not screen.visible, "oculta mientras dura la noche")
	check_eq(screen.mouse_filter, Control.MOUSE_FILTER_STOP, "se queda con los clics: la noche terminó")
	screen.free()
	return true


func test_al_ganar() -> bool:
	var screen := _make_screen()
	var state := _make_state()
	state.videos.received = 2
	screen.show_ending(NightState.Ending.WON, state, null, FRIENDS)
	check(screen.visible, "aparece")
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_WON_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text,
			_translated("END_WON").format({"received": 2, "quota": 2}), "cuántos videos")
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_PLAY_AGAIN"), "jugar de nuevo")
	screen.free()
	return true


func test_al_perder() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.SANITY, _make_state(), null, FRIENDS)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_LOST_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text, _translated("END_SANITY"), "por qué")
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_RETRY"), "reintentar")
	screen.free()
	return true


func test_el_boton_pide_volver_a_empezar() -> bool:
	var screen := _make_screen()
	var pressed := []
	screen.retry_pressed.connect(func() -> void: pressed.append(true))
	(screen.get_node("Center/Box/Retry") as Button).pressed.emit()
	check_eq(pressed.size(), 1, "avisa una vez")
	screen.free()
	return true
