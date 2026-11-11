extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PHONE := preload("res://scenes/ui/phone_view.tscn")
const NightState := preload("res://scripts/core/night_state.gd")
const PhoneView := preload("res://scripts/ui/phone_view.gd")

var _state: NightState


var _posts: Array[PhonePostData] = []
var _disturbing: Array[PhonePostData] = []


func _make_posts(count: int) -> Array[PhonePostData]:
	var posts: Array[PhonePostData] = []
	for _index in count:
		posts.append(PhonePostData.new())
	return posts


## Celular con el estado de la noche 1 del catálogo de prueba, 3 publicaciones y 2 perturbadoras.
func _make_phone() -> Control:
	var catalog := Fixtures.make_catalog()
	_state = NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())
	_posts = _make_posts(3)
	_disturbing = _make_posts(2)
	var phone := PHONE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(phone)
	phone.setup(_state, _posts, _disturbing)
	return phone


## Lleva el feed hasta que el lugar `slot` quede arriba.
func _scroll_to_slot(phone: Control, slot: int) -> void:
	phone.scroll_by(slot * PhoneView.POST_HEIGHT - phone.scroll)
	phone._process(1.0)


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


## Bajo Sanity 15 es perturbadora una de cada 3: la del lugar 2, entre otras. Una foto a la vista nunca cambia.
func test_una_foto_a_la_vista_no_cambia() -> bool:
	var phone := _make_phone()
	phone.open()
	_scroll_to_slot(phone, 2)
	check_eq(phone.post_in_slot(2), _posts[2], "con Sanity alta es un gatito")
	_state.sanity = 10.0
	phone._process(1.0)
	check_eq(phone.post_in_slot(2), _posts[2], "baja Sanity y sigue el mismo gatito")
	phone.free()
	return true


func test_al_salir_de_la_pantalla_se_vuelve_a_decidir() -> bool:
	var phone := _make_phone()
	phone.open()
	_scroll_to_slot(phone, 2)
	_state.sanity = 10.0
	phone._process(1.0)
	_scroll_to_slot(phone, 7)
	check(phone.post_in_slot(2) == null, "el lugar 2 ya no está a la vista")
	_scroll_to_slot(phone, 2)
	check(_disturbing.has(phone.post_in_slot(2)), "al volver es perturbadora")
	phone.free()
	return true


func test_al_cerrar_y_abrir_se_vuelve_a_decidir() -> bool:
	var phone := _make_phone()
	phone.open()
	_scroll_to_slot(phone, 2)
	_state.sanity = 10.0
	phone.close()
	phone.open()
	phone._process(1.0)
	check(_disturbing.has(phone.post_in_slot(2)), "cerrado no se ve el cambio, así que puede cambiar")
	phone.free()
	return true


## Las fotos se muestran sin escalar, a todo el ancho, y cabe una publicación entera.
func test_la_foto_cabe_sin_escalar() -> bool:
	var phone := _make_phone()
	var feed := phone.get_node("Feed") as Control
	check_eq(feed.size.x, float(PhoneView.PHOTO_SIZE), "la foto va a todo el ancho")
	check(PhoneView.POST_HEIGHT <= feed.size.y, "cabe una publicación entera")
	phone.free()
	return true


func test_sin_bateria_el_feed_no_avanza() -> bool:
	var phone := _make_phone()
	_state.battery = 0.0
	phone.scroll_by(120.0)
	for _frame in 60:
		phone._process(0.05)
	check_eq(phone.scroll, 0.0, "el feed no se mueve")
	phone.free()
	return true


## Un clic izquierdo en la linterna de la barra superior pide el flash (decisión de Benja, 11 de noviembre).
func test_la_linterna_avisa() -> bool:
	var phone := _make_phone()
	var flashes := []
	phone.flash_pressed.connect(func() -> void: flashes.append(true))
	var click := _mouse(MOUSE_BUTTON_LEFT)
	click.position = PhoneView.FLASH_RECT.get_center()
	phone._gui_input(click)
	check_eq(flashes.size(), 1, "pidió el flash")
	click.position = Vector2(130, 300)
	phone._gui_input(click)
	check_eq(flashes.size(), 1, "un clic en el feed no")
	check(String(phone._get_tooltip(PhoneView.FLASH_RECT.get_center())) != "", "tiene su nombre al pasar el mouse")
	phone.free()
	return true


func test_sin_bateria_la_linterna_no_prende() -> bool:
	var phone := _make_phone()
	_state.battery = 0.0
	var flashes := []
	phone.flash_pressed.connect(func() -> void: flashes.append(true))
	var click := _mouse(MOUSE_BUTTON_LEFT)
	click.position = PhoneView.FLASH_RECT.get_center()
	phone._gui_input(click)
	check(flashes.is_empty(), "sin batería no pide nada")
	phone.free()
	return true
