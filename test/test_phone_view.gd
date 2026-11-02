extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PHONE := preload("res://scenes/ui/phone_view.tscn")
const NightState := preload("res://scripts/core/night_state.gd")
const PhoneView := preload("res://scripts/ui/phone_view.gd")

var _state: NightState


## Celular con el estado de la noche 1 del catálogo de prueba y 3 publicaciones.
func _make_phone() -> Control:
	var catalog := Fixtures.make_catalog()
	_state = NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())
	var posts: Array[PhonePostData] = []
	for index in 3:
		var post := PhonePostData.new()
		post.author_key = "K_AUTHOR_%d" % index
		post.text_key = "K_TEXT_%d" % index
		posts.append(post)
	var phone := PHONE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(phone)
	phone.setup(_state, posts)
	return phone


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_empieza_oculto_y_se_abre() -> bool:
	var phone := _make_phone()
	check(not phone.visible, "oculto al inicio")
	phone.open()
	check(phone.visible, "se abre")
	phone.free()
	return true


func test_la_rueda_scrollea_y_recupera_sanity() -> bool:
	var phone := _make_phone()
	phone.open()
	_state.sanity = 50.0
	phone._gui_input(_mouse(MOUSE_BUTTON_WHEEL_DOWN))
	_state.advance(0.3)
	check(_state.sanity > 50.0, "Sanity sube mientras scrollea: %s" % _state.sanity)
	phone._process(1.0)
	check_eq(phone.scroll, PhoneView.WHEEL_STEP, "las publicaciones suben")
	var calm := _state.sanity
	_state.advance(1.0)
	check(_state.sanity < calm, "al dejar de scrollear, Sanity vuelve a bajar")
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(0, 2)
	phone._gui_input(pan)
	_state.advance(0.3)
	check(_state.sanity > calm - 1.0 / 6.0, "el touchpad también scrollea")
	phone.free()
	return true


func test_las_publicaciones_se_repiten_sin_fin() -> bool:
	var phone := _make_phone()
	phone.open()
	check_eq(phone.post_at_top(), 0, "empieza en la primera")
	for _i in 40:
		phone.scroll_by(PhoneView.WHEEL_STEP)
	phone._process(1.0)
	check_eq(phone.scroll, 2400.0, "40 movimientos de la rueda")
	check_eq(phone.post_at_top(), 1, "después de 3 publicaciones vuelve a empezar: arriba está la segunda")
	phone.scroll_by(-3000.0)
	phone._process(1.0)
	check(phone.post_at_top() >= 0 and phone.post_at_top() < 3, "también hacia arriba")
	phone.free()
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var phone := _make_phone()
	phone.open()
	phone._gui_input(_mouse(MOUSE_BUTTON_RIGHT))
	check(not phone.visible, "cerrado")
	phone.free()
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check(String(TranslationServer.translate(PhoneView.APP_NAME_KEY)) != PhoneView.APP_NAME_KEY, "falta PHONE_APP_NAME en phone.csv")
	TranslationServer.set_locale(previous)
	return true
