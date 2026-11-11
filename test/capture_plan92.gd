extends SceneTree
## Capturas del Plan 9.2 para revisarlas a ojo, a la resolución que se pida (la letra nítida depende de ella). No es una
## prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan92.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan92_<ancho>_<nombre>.png: chat (el chat y el cuaderno en la noche 3), leon (el chat de León y la página de
## Gonzalo en la noche 0), card (una tarjeta), phone, mixer, menu, pause, options y end.

const DESK := preload("res://scenes/desk/desk.tscn")
const MENU := preload("res://scenes/menu/main_menu.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")

var _dir := ""
var _width := 1280


func _initialize() -> void:
	_capture.call_deferred()


func _desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").requests_arrive = night_number == 0
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	return desk


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	# El chat y el cuaderno en una noche normal.
	var desk := _desk(3)
	var manager := desk.get_node("RequestManager")
	var request: RefCounted = manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SIGHT)
	desk._on_entity_page_requested(0, request.entity)
	await _save("chat", 2.0)
	desk.free()
	# El chat de León en la noche 0, con la página de Gonzalo.
	desk = _desk(0)
	manager = desk.get_node("RequestManager")
	await create_timer(5.5).timeout
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	var messages := []
	manager.message_added.connect(func(_friend: int, message: ChatMessage) -> void: messages.append(message))
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.click_clue(messages[-1], &"red_hoodie")
	manager.click_clue(messages[-1], &"glasses")
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	manager.click_clue(messages[-1], &"bad_smell")
	desk._on_entity_page_requested(0, manager.requests[0].entity)
	await _save("leon", 14.0)
	# Una tarjeta.
	desk.close_panels()
	(desk.get_node("Overlay/TutorialCards") as Control).open(manager.night().tutorial_cards)
	await _save("card", 1.5)
	desk.free()
	# El celular y el mixer.
	desk = _desk(3)
	desk.open_phone()
	await _save("phone", 0.6)
	desk.open_mixer()
	await _save("mixer", 0.6)
	# La pausa, las opciones y la pantalla final.
	desk.close_modes()
	desk.pause()
	await _save("pause", 0.4)
	desk.get_node("Overlay/PauseMenu/OptionsPanel").open(GameSettings.new())
	await _save("options", 0.4)
	paused = false
	desk.get_node("Overlay/PauseMenu").resume()
	desk.get_node("NightManager").finish(NightState.Ending.SANITY)
	await _save("end", 2.5)
	desk.free()
	# El menú principal.
	var menu := MENU.instantiate()
	root.add_child(menu)
	await _save("menu", 1.0)
	menu.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan92_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
