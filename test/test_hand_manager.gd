extends "res://test/test_case.gd"
## La Mano en el escritorio (idea de Benja, 11 de noviembre): llega cuando el director la pide, avanza a tirones con un
## crujido, baja el dial que agarra y se espanta con el flash del celular.

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 3
	desk.get_node("RequestManager").random_seed = 13
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func _hands(desk: Node2D) -> Node:
	return desk.get_node("Hands")


func _sprite(desk: Node2D) -> AnimatedSprite2D:
	return desk.get_node("WallPlane/Hand") as AnimatedSprite2D


func _state(desk: Node2D) -> NightState:
	return desk.get_node("RequestManager").state


## Avanza el escritorio `seconds` segundos, de a 0,1.
func _process(desk: Node2D, seconds: float) -> void:
	for _step in roundi(seconds * 10.0):
		desk._process(0.1)


func test_la_mano_esta_escondida() -> bool:
	var desk := _make_desk()
	check(_sprite(desk) != null, "está en la pared")
	check(not _sprite(desk).visible, "escondida")
	check(not _hands(desk).is_present(), "sin visita")
	check_eq(_sprite(desk).sprite_frames.get_frame_count(&"default"), 3, "con los 3 cuadros de Benja")
	desk.free()
	return true


func test_llega_cuando_el_director_la_pide() -> bool:
	var desk := _make_desk()
	var appeared := []
	_hands(desk).hand_appeared.connect(func() -> void: appeared.append(true))
	desk.get_node("RequestManager").director.hand_times.assign([_state(desk).elapsed])
	desk._process(0.0)
	check(_hands(desk).is_present(), "llegó")
	check(_sprite(desk).visible, "se ve")
	check_eq(_sprite(desk).position.x, 1280.0, "asoma desde el borde derecho")
	check_eq(appeared.size(), 1, "avisa")
	check(desk.get_node("RequestManager").director.hand_times.is_empty(), "el director la descuenta")
	desk.free()
	return true


func test_no_llega_con_la_criatura_cerca() -> bool:
	var desk := _make_desk()
	var screamers := desk.get_node("Screamers")
	screamers.play(ScareKind.Kind.JUMPSCARE)
	desk.get_node("RequestManager").director.hand_times.assign([_state(desk).elapsed])
	desk._process(0.0)
	check(not _hands(desk).is_present(), "espera a que la criatura se vaya")
	desk._process(screamers.creature_stay + 0.1)
	check(_hands(desk).is_present(), "después, llega")
	desk.free()
	return true


func test_agarrada_baja_el_dial() -> bool:
	var desk := _make_desk()
	_hands(desk).start_visit(NightState.Dial.SANITY)
	_process(desk, 15.0)
	check(_hands(desk).visit.is_grabbing(), "llegó al dial")
	check_eq(Vector2i(_sprite(desk).position), Vector2i(836, 225), "agarra el dial de Sanity")
	check(_state(desk).sanity < 90.0, "Sanity baja: %s" % _state(desk).sanity)
	_process(desk, 30.0)
	check(_state(desk).sanity >= 14.0 and _state(desk).sanity <= 15.0, "hasta 15: %s" % _state(desk).sanity)
	desk.free()
	return true


func test_el_flash_la_espanta_y_gasta_bateria() -> bool:
	var desk := _make_desk()
	var scared := []
	_hands(desk).hand_scared.connect(func() -> void: scared.append(true))
	_hands(desk).start_visit(NightState.Dial.TRUST)
	_process(desk, 3.0)
	check(_hands(desk).flash(), "hay batería")
	check(not _hands(desk).is_present(), "desapareció al instante")
	check(not _sprite(desk).visible, "ya no se ve")
	check_eq(scared.size(), 1, "avisa")
	check_eq(_state(desk).battery, 90.0, "−10 %")
	check((desk.get_node("Overlay/Flash") as CanvasItem).modulate.a > 0.5, "la pantalla destella")
	check((desk.get_node("Hands/FlashSound") as AudioStreamPlayer).playing, "suena el flash")
	check(_hands(desk).flash(), "sin Mano, el flash también gasta")
	check_eq(_state(desk).battery, 80.0, "−10 % más")
	_state(desk).battery = 0.0
	check(not _hands(desk).flash(), "sin batería, nada")
	desk.free()
	return true


func test_el_celular_pide_el_flash() -> bool:
	var desk := _make_desk()
	_hands(desk).start_visit(NightState.Dial.CONNECTION)
	desk.open_phone()
	(desk.get_node("UI/PhoneView") as Control).flash_pressed.emit()
	check(not _hands(desk).is_present(), "la linterna del celular la espanta")
	desk.free()
	return true


func test_suena_en_cada_tiron() -> bool:
	var desk := _make_desk()
	var creak := desk.get_node("Hands/CreakSound") as AudioStreamPlayer2D
	_hands(desk).start_visit(NightState.Dial.SANITY)
	check(not creak.playing, "al asomar, todavía no")
	_process(desk, 0.8)
	check(creak.playing, "con el primer tirón, cruje")
	desk.free()
	return true


## Está en la pared: el chat, el cuaderno y el mixer la tapan (decisión de Benja, 11 de noviembre). Solo el crujido la
## delata.
func test_queda_detras_de_los_paneles() -> bool:
	var desk := _make_desk()
	check(_sprite(desk).get_canvas_layer_node() == null, "la Mano se dibuja con el cuarto")
	check((desk.get_node("UI") as CanvasLayer).layer > 0, "los paneles van encima")
	desk.free()
	return true


func test_reducir_destellos() -> bool:
	var desk := _make_desk()
	var settings := GameSettings.new()
	settings.reduce_flashes = true
	desk.apply_settings(settings)
	_hands(desk).flash()
	check((desk.get_node("Overlay/Flash") as CanvasItem).modulate.a <= 0.31, "un destello suave")
	desk.free()
	return true
