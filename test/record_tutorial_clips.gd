extends SceneTree
## Graba los videos de las tarjetas del tutorial (Plan 9.2) con el Movie Maker de Godot. No es una prueba: lo corre
## tools/make_tutorial_videos.sh, que después los recorta y los convierte a Theora.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" --write-movie <archivo.avi> --fixed-fps 30 -s res://test/record_tutorial_clips.gd -- <clip>
## Los clips: meters (los 3 medidores bajan), phone (el celular sube Sanity), window (la criatura, su sombra y la
## cortina) y hand (la Mano, el celular y un cursor que aprieta FLASH).

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")

## En el clip de la Mano: dónde sube el celular y desde dónde parte el cursor, en el escritorio de 1280×720.
const PHONE_IN_CLIP := Vector2(990, 250)
const CURSOR_START := Vector2(900, 470)
## La flecha del cursor: # el borde y o el relleno.
const CURSOR: Array[String] = [
	"#",
	"##",
	"#o#",
	"#oo#",
	"#ooo#",
	"#oooo#",
	"#ooooo#",
	"#oooooo#",
	"#ooooooo#",
	"#oooo#####",
	"#oo#oo#",
	"#o# #oo#",
	"##  #oo#",
	"#    #oo#",
	"     #oo#",
	"      ##",
]


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


## La Mano avanza hacia un dial; se abre el celular, un cursor va al botón FLASH, lo aprieta y el flash la espanta (Plan
## 9.5, observación 13 del primer testeo). Para que todo quepa en el recorte, el celular sube a la derecha, bajo los
## diales, y no en su lugar de siempre.
func _hand(desk: Node2D) -> void:
	var hands := desk.get_node("Hands")
	hands.start_visit(NightState.Dial.CONNECTION)
	hands.visit.step = hands.visit.steps - 9
	var phone := desk.get_node("UI/PhoneView") as Control
	phone._rest_position = PHONE_IN_CLIP
	var cursor := _cursor(desk)
	cursor.position = CURSOR_START
	await _wait(4.0)
	desk.open_phone()
	cursor.visible = true
	await _wait(0.7)
	var target: Vector2 = phone.global_position + phone.flash_rect().get_center()
	var move := create_tween()
	move.tween_property(cursor, ^"position", target, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await move.finished
	var motion := InputEventMouseMotion.new()
	motion.position = phone.flash_rect().get_center()
	phone._gui_input(motion)
	await _wait(0.3)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = phone.flash_rect().get_center()
	phone._gui_input(click)
	await _wait(2.2)


## Un cursor de mentira, porque el Movie Maker no graba el del sistema: una flecha blanca con borde negro, arriba de todo.
func _cursor(desk: Node2D) -> Sprite2D:
	var image := Image.create(CURSOR.size() + 1, CURSOR.size(), false, Image.FORMAT_RGBA8)
	for row in CURSOR.size():
		for column in CURSOR[row].length():
			match CURSOR[row][column]:
				"#":
					image.set_pixel(column, row, Color.BLACK)
				"o":
					image.set_pixel(column, row, Color.WHITE)
	var layer := CanvasLayer.new()
	layer.layer = 100
	desk.add_child(layer)
	var cursor := Sprite2D.new()
	cursor.texture = ImageTexture.create_from_image(image)
	cursor.centered = false
	cursor.visible = false
	layer.add_child(cursor)
	return cursor


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
