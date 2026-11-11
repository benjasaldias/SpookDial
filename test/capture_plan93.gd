extends SceneTree
## Capturas del Plan 9.3 (el chat) para revisarlas a ojo, a la resolución que se pida: la letra nítida depende de ella.
## No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan93.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan93_<ancho>_<nombre>.png:
## - chat: preguntas hechas, el nombre, la página abierta (las hojas de respuesta) y un video por descargar;
## - static: con poca señal, una respuesta tapada y su pregunta que vuelve;
## - offline_1 y offline_2: sin señal, el botón de la señal parpadeando (dos momentos del parpadeo);
## - incident: un accidente, con sus opciones como botones de terminal;
## - leon: el chat de León en la noche 0.

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")

var _dir := ""
var _width := 1280


func _initialize() -> void:
	_capture.call_deferred()


## Un escritorio en la noche `night_number`, con la cámara fija y sin la señal que baja sola, interferencias ni videos
## del director: cada captura pone lo suyo.
func _desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = night_number
	manager.requests_arrive = night_number == 0
	manager.random_seed = 21
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	for friend: RefCounted in manager.state.friends:
		friend.signal_decay_interval = 0.0
	manager.state.interferences.pending.clear()
	manager.state.videos.pending.clear()
	return desk


## Los mensajes que llegan al chat de `manager`, en orden.
func _record(manager: Node) -> Array:
	var messages := []
	manager.message_added.connect(func(_friend: int, message: ChatMessage) -> void: messages.append(message))
	return messages


## Marca las características de `request` en los mensajes que las traen, como el jugador.
func _mark_traits(manager: Node, request: RefCounted, messages: Array) -> void:
	for message: ChatMessage in messages:
		for token: ChatMessage.Token in message.tokens:
			if token.is_clue() and not token.covered and request.traits.any(func(t: TraitData) -> bool: return t.id == token.clue_id):
				manager.click_clue(message, token.clue_id)


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	# El chat con preguntas, el nombre, la página abierta y un video.
	var desk := _desk(3)
	var manager := desk.get_node("RequestManager")
	var messages := _record(manager)
	var request: RefCounted = manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.ask(0, ClueCategory.Kind.SOUND)
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	_mark_traits(manager, request, messages)
	await create_timer(2.2).timeout
	desk._on_entity_page_requested(0, request.entity)
	manager.state.videos.add_extra(0, manager.state.elapsed)
	await _save("chat", 2.5)
	desk.free()
	# Con poca señal: una respuesta tapada, y su pregunta vuelve.
	desk = _desk(3)
	manager = desk.get_node("RequestManager")
	manager.start_request(0)
	manager.state.friends[0].signal_level = 25.0
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	await _save("static", 3.0)
	desk.free()
	# Sin señal: el botón de la señal parpadea, y los títulos dicen por qué no se puede.
	desk = _desk(3)
	manager = desk.get_node("RequestManager")
	manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.state.friends[0].signal_level = 0.0
	await _save("offline_1", 2.0)
	await _save("offline_2", 0.4)
	desk.free()
	# Un accidente: se responde con sentido común, con botones de terminal.
	desk = _desk(3)
	manager = desk.get_node("RequestManager")
	manager.start_incident(1)
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	await _save("incident", 2.0)
	desk.free()
	# El chat de León en la noche 0, con la página de Gonzalo.
	desk = _desk(0)
	manager = desk.get_node("RequestManager")
	await create_timer(5.5).timeout
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	messages = _record(manager)
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.click_clue(messages[-1], &"red_hoodie")
	manager.click_clue(messages[-1], &"glasses")
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	manager.click_clue(messages[-1], &"bad_smell")
	desk._on_entity_page_requested(0, manager.requests[0].entity)
	await _save("leon", 12.0)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan93_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
