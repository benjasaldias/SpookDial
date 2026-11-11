extends SceneTree
## Graba los videos de las tarjetas del tutorial (Plan 9.2) con el Movie Maker de Godot. No es una prueba: lo corre
## tools/make_tutorial_videos.sh, que después los recorta y los convierte a Theora.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" --write-movie <archivo.avi> --fixed-fps 30 -s res://test/record_tutorial_clips.gd -- <clip>
## Los clips: meters (los 3 medidores bajan), phone (el celular sube Sanity), window (la criatura, su sombra y la
## cortina) y hand (la Mano y el flash).

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _initialize() -> void:
	_record.call_deferred()


func _record() -> void:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 3
	desk.get_node("RequestManager").requests_arrive = false
	desk.get_node("RequestManager").random_seed = 9
	root.add_child(desk)
	# La cámara quieta: así el recorte cae siempre en el mismo lugar.
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	var state: NightState = desk.get_node("RequestManager").state
	match OS.get_cmdline_user_args()[0]:
		"meters":
			await _meters(desk, state)
		"phone":
			await _phone(desk, state)
		"window":
			await _window(desk)
		"hand":
			await _hand(desk)
	quit()


## Connection baja con una interferencia, Sanity con un susto y Trust con una respuesta incorrecta.
func _meters(desk: Node2D, state: NightState) -> void:
	await _wait(1.0)
	state.friends[0].interfere(60.0)
	state.friends[1].interfere(60.0)
	await _wait(2.0)
	desk.get_node("Screamers").play(ScareKind.Kind.LIGHTS)
	state.scare(25.0)
	await _wait(2.5)
	state.trust -= 30.0
	await _wait(2.5)


## Scrollear el celular sube Sanity y gasta batería.
func _phone(desk: Node2D, state: NightState) -> void:
	state.sanity = 35.0
	state.battery = 70.0
	desk.open_phone()
	await _wait(1.0)
	var phone := desk.get_node("UI/PhoneView")
	for _step in 40:
		phone.scroll_by(40.0)
		await _wait(0.1)
	await _wait(2.0)


## Llega la criatura y su sombra cae en el escritorio; la cortina se cierra y, al abrirla, sigue ahí.
func _window(desk: Node2D) -> void:
	await _wait(1.0)
	var screamers := desk.get_node("Screamers")
	screamers.play(ScareKind.Kind.JUMPSCARE)
	await _wait(2.5)
	screamers.toggle_curtains()
	await _wait(2.0)
	screamers.toggle_curtains()
	await _wait(1.5)
	screamers.toggle_curtains()
	await _wait(1.0)


## La Mano avanza hacia un dial; se abre el celular y el flash la espanta.
func _hand(desk: Node2D) -> void:
	var hands := desk.get_node("Hands")
	hands.start_visit(NightState.Dial.CONNECTION)
	hands.visit.step = hands.visit.steps - 9
	await _wait(5.5)
	desk.open_phone()
	await _wait(0.8)
	(desk.get_node("UI/PhoneView") as Control).flash_pressed.emit()
	await _wait(2.0)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
