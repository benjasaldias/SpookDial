extends SceneTree
## Capturas del Plan 9.5 para revisarlas a ojo: cada paso de la noche 0, las tarjetas, el celular con el botón del flash
## y una prueba de negrita. No es una prueba: corre con ventana, a la resolución que se pida.
## Uso: timeout 400 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan95.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan95_<ancho>_<nombre>.png.

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")
const MixerView := preload("res://scripts/ui/mixer_view.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## El tiempo pasa más rápido entre capturas, para no esperar los minutos del tutorial.
const SPEED := 4.0

var _dir := ""
var _width := 1280
var _messages: Array = []


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	await _tutorial()
	await _phone()
	await _bold_test()
	quit()


func _desk(night_number: int, reduce_flashes: bool) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").random_seed = 21
	desk.get_node("RequestManager").requests_arrive = night_number == 0
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	# Con "Reducir destellos" los bordes quedan fijos: así se ven en la captura.
	settings.reduce_flashes = reduce_flashes
	desk.apply_settings(settings)
	return desk


## La noche 0 de punta a punta, con una captura en cada paso.
func _tutorial() -> void:
	var desk := _desk(0, true)
	var manager: Node = desk.get_node("RequestManager")
	var chat: Control = desk.get_node("UI/ChatPanel")
	manager.message_added.connect(func(_friend: int, message: ChatMessage) -> void: _messages.append(message))
	Engine.time_scale = SPEED
	await _until(func() -> bool: return manager.requests[0] != null)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await _until(func() -> bool: return _idle(manager, chat))
	await _save("01_preguntar")
	var request: RefCounted = manager.requests[0]
	chat._question_buttons[ClueCategory.Kind.SIGHT].pressed.emit()
	var sight: ChatMessage = _messages.filter(func(m: ChatMessage) -> bool: return m.request == request)[-1]
	await _until(func() -> bool: return _idle(manager, chat))
	await _save("02_marcar")
	manager.click_clue(sight, &"red_hoodie")
	manager.click_clue(sight, &"glasses")
	await _until(func() -> bool: return _idle(manager, chat))
	await _save("03_azul_y_que_oye")
	chat._question_buttons[ClueCategory.Kind.SOUND].pressed.emit()
	var audio: ChatMessage = _messages.filter(func(m: ChatMessage) -> bool: return m.request == request)[-1]
	await _until(func() -> bool: return _idle(manager, chat))
	await _save("04_audio")
	manager.tutorial_audio_played(0, audio.audio)
	await _until(func() -> bool: return _idle(manager, chat))
	chat._question_buttons[ClueCategory.Kind.ENVIRONMENT].pressed.emit()
	var smell: ChatMessage = _messages.filter(func(m: ChatMessage) -> bool: return m.request == request)[-1]
	await _until(func() -> bool: return _idle(manager, chat))
	manager.click_clue(smell, &"bad_smell")
	await _until(func() -> bool: return _idle(manager, chat) and manager.tutorial_wants(TutorialChat.Focus.ENTITY_NAME))
	await _save("05_nombre")
	(chat.get_node("%EntityName") as Button).pressed.emit()
	await _until(func() -> bool: return _idle(manager, chat))
	await _save("06_hojas")
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(0, request.entity.find_action(rule.correct_action_id))
	await _until(func() -> bool: return _idle(manager, chat))
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	await _until(func() -> bool: return _idle(manager, chat) and manager.state.videos.offer_for(0) != null)
	await _save("07_descarga")
	manager.state.videos.offer_for(0).progress = 1.0
	await _until(func() -> bool: return manager.requests[1] != null and _idle(manager, chat))
	desk.close_panels()
	await _save("08_entrada_de_gonzalo")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	await create_timer(4.0).timeout
	await _save("09_gonzalo_espera")
	await _until(func() -> bool: return manager.requests[1] == null and not manager.tutorial_busy())
	await create_timer(2.0).timeout
	await _save("10_gonzalo_decide_solo")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await _until(func() -> bool: return not manager.state.friends[0].is_online() and _idle(manager, chat), 120.0)
	await _save("11_estatica_y_barritas")
	Engine.time_scale = 1.0
	(chat.get_node("%Sync") as Button).pressed.emit()
	var mixer: Control = desk.get_node("UI/MixerView")
	await _until(func() -> bool: return mixer.guide_rect().size == MixerView.METER_PLAYER.size)
	await _save("12_mixer_tu_turno", 0.1)
	Engine.time_scale = SPEED
	manager.restore_signal(0)
	var cards: Control = desk.get_node("Overlay/TutorialCards")
	await _until(func() -> bool: return manager.tutorial_chat.step == TutorialChat.Step.DONE \
			and (desk.get_node("UI/ChatPanel") as Control).visible)
	await create_timer(3.0).timeout
	await _save("13_despedida")
	await _until(func() -> bool: return cards.visible)
	Engine.time_scale = 1.0
	for index in 4:
		await _save("14_tarjeta_%d" % (index + 1), 1.0)
		cards.next()
	desk.free()


## El celular con el botón del flash, normal y hundido.
func _phone() -> void:
	var desk := _desk(3, false)
	desk.open_phone()
	await _save("15_celular", 0.6)
	var phone: Control = desk.get_node("UI/PhoneView")
	phone._flash_pressed_left = 10.0
	await _save("16_flash_hundido", 0.2)
	desk.free()


## ¿Departure Mono con negrita falsa se ve nítida? Arriba la letra normal, abajo con embolden.
func _bold_test() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(40, 40)
	root.add_child(box)
	var variation := FontVariation.new()
	variation.base_font = FONT
	variation.variation_embolden = 0.6
	for font: Font in [FONT, variation]:
		var label := Label.new()
		label.text = "Si uno llega a 0, pierdes la noche. ABC 123"
		label.add_theme_font_override(&"font", font)
		label.add_theme_font_size_override(&"font_size", 15)
		box.add_child(label)
	await _save("17_negrita", 0.3)
	box.free()


## León terminó y el último mensaje se terminó de escribir.
func _idle(manager: Node, chat: Control) -> bool:
	if manager.tutorial_busy():
		return false
	var views: Array = chat.message_views(chat.selected_friend)
	return views.is_empty() or views[-1].is_done()


func _until(done: Callable, seconds := 90.0) -> void:
	var waited := 0.0
	while not done.call() and waited < seconds:
		await process_frame
		waited += 1.0 / 60.0
	if not done.call():
		push_error("Captura: no se cumplió la condición a tiempo")


func _save(capture_name: String, wait := 0.5) -> void:
	await create_timer(wait * Engine.time_scale, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan95_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
