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
	return NightState.new(catalog.nights()[0], catalog.balance, 3, RandomNumberGenerator.new())


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
	check((screen.get_node("Center/Box/Body") as RichTextLabel).text.begins_with(
			_translated("END_WON").format({"received": 2, "quota": 2})), "cuántos videos")
	var next := screen.get_node("Center/Box/Buttons/Next") as Button
	check(next.visible, "se sigue a la noche siguiente")
	check_eq(next.text, _translated("END_NEXT").format({"night": 2}), "empezar la noche 2")
	check(not (screen.get_node("Center/Box/Buttons/Retry") as Button).visible, "sin reintentar")
	check((screen.get_node("Center/Box/Buttons/Menu") as Button).visible, "o volver al menú")
	screen.free()
	return true


func test_al_perder() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.SANITY, _make_state(), null, FRIENDS)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_LOST_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text, _translated("END_SANITY"), "por qué")
	var retry := screen.get_node("Center/Box/Buttons/Retry") as Button
	check(retry.visible, "se reintenta")
	check_eq(retry.text, _translated("END_RETRY"), "reintentar")
	check(not (screen.get_node("Center/Box/Buttons/Next") as Button).visible, "no se sigue")
	check_eq((screen.get_node("Center/Box/Buttons/Menu") as Button).text, _translated("END_MENU"), "volver al menú")
	screen.free()
	return true


func test_cada_boton_avisa_lo_suyo() -> bool:
	var screen := _make_screen()
	var pressed := []
	for signal_name: String in ["retry_pressed", "next_pressed", "menu_pressed"]:
		screen.connect(signal_name, func() -> void: pressed.append(signal_name))
	for button: String in ["Retry", "Next", "Menu"]:
		(screen.get_node("Center/Box/Buttons/" + button) as Button).pressed.emit()
	check_eq(pressed, ["retry_pressed", "next_pressed", "menu_pressed"], "una vez cada uno")
	screen.free()
	return true


## El resumen entre noches (diseño §5): los videos y las páginas nuevas del cuaderno para la noche siguiente.
func test_el_resumen_dice_las_paginas_nuevas() -> bool:
	var screen := _make_screen()
	var state := _make_state()
	state.videos.received = 2
	var pages: Array[String] = ["El Cuero", "La Viuda"]
	screen.show_ending(NightState.Ending.WON, state, null, FRIENDS, 1, pages)
	var body := (screen.get_node("Center/Box/Body") as RichTextLabel).text
	check(body.contains(_translated("END_NEW_PAGES").format({"night": 2, "pages": "El Cuero, La Viuda"})), body)
	screen.free()
	return true


## Al terminar el tutorial, se sigue a la noche 1.
func test_al_terminar_el_tutorial() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 0)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_TUTORIAL_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Buttons/Next") as Button).text, _translated("END_NEXT").format({"night": 1}),
			"empezar la noche 1")
	screen.free()
	return true


## Al ganar la noche 5, el juego terminó (diseño §5): solo queda volver al menú.
func test_la_victoria_final() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 5)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_VICTORY_TITLE"), "título")
	check(not (screen.get_node("Center/Box/Buttons/Next") as Button).visible, "no hay noche 6")
	check(not (screen.get_node("Center/Box/Buttons/Retry") as Button).visible, "ni reintentar")
	check((screen.get_node("Center/Box/Buttons/Menu") as Button).visible, "volver al menú")
	screen.free()
	return true


## Al terminar Normal, la pantalla final avisa qué se desbloqueó (docs/26 §3.5).
func test_la_victoria_avisa_lo_desbloqueado() -> bool:
	var screen := _make_screen()
	var none: Array[String] = []
	var unlocked: Array[String] = ["Difícil"]
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 5, none, unlocked)
	var body := (screen.get_node("Center/Box/Body") as RichTextLabel).get_parsed_text()
	check(body.contains(String(tr("END_UNLOCKED")).format({"difficulty": "Difícil"})), "avisa: " + body)
	screen.free()
	return true
