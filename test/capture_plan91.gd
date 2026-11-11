extends SceneTree
## Capturas del Plan 9.1 para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan91.gd -- /mnt/c/dev/capturas/plan91_mano_camino.png /mnt/c/dev/capturas/plan91_mano_dial.png /mnt/c/dev/capturas/plan91_flash.png /mnt/c/dev/capturas/plan91_sin_lugar.png /mnt/c/dev/capturas/plan91_variante.png /mnt/c/dev/capturas/plan91_videos.png
## 1. La Mano a mitad de camino, hacia el dial de Sanity.
## 2. La Mano agarrando el dial de Sanity, que baja.
## 3. El flash, con el celular abierto.
## 4. Un mensaje inicial sin lugar.
## 5. Una característica dicha con otras palabras, marcada, y su nombre en el cuaderno.
## 6. El aviso de que los videos ya no alcanzan, en el chat y en el PC.
## La curva de olas sale de test/dump_waves.gd y tools/plot_waves.py.

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").requests_arrive = false
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	return desk


func _capture() -> void:
	# 1 y 2: la Mano a mitad de camino y agarrando el dial de Sanity.
	var desk := _desk(3)
	var hands := desk.get_node("Hands")
	hands.start_visit(NightState.Dial.SANITY)
	hands.visit.step = hands.visit.steps / 2
	await create_timer(0.3).timeout
	await _save(0)
	hands.visit.step = hands.visit.steps
	hands.visit.frame = 0
	await create_timer(2.0).timeout
	await _save(1)
	desk.free()
	# 3: el flash con el celular abierto.
	desk = _desk(3)
	hands = desk.get_node("Hands")
	hands.start_visit(NightState.Dial.TRUST)
	hands.visit.step = hands.visit.steps - 3
	desk.open_phone()
	await create_timer(0.4).timeout
	(desk.get_node("UI/PhoneView") as Control).flash_pressed.emit()
	await _save(2)
	desk.free()
	# 4: un mensaje inicial sin lugar.
	desk = _desk(3)
	var manager := desk.get_node("RequestManager")
	manager.night().place_chance = 0.0
	manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(3)
	manager.night().place_chance = 0.5
	desk.free()
	# 5: una característica con otras palabras, marcada, y su nombre en el cuaderno.
	desk = _desk(3)
	manager = desk.get_node("RequestManager")
	var request: RefCounted = manager.start_request(0)
	var shown: TraitData = request.traits[0]
	request.trait_forms[shown.id] = shown.variant_keys[0]
	var messages := []
	manager.message_added.connect(func(_friend: int, message: ChatMessage) -> void: messages.append(message))
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, shown.category)
	manager.click_clue(messages[-1], shown.id)
	desk._on_entity_page_requested(0, request.entity)
	await create_timer(1.5).timeout
	await _save(4)
	desk.free()
	# 6: el aviso de los videos, en el chat de León y en el PC.
	desk = _desk(3)
	manager = desk.get_node("RequestManager")
	var state: NightState = manager.state
	state.videos.received = 1
	state.videos.unreleased = 1
	var events := NightState.Events.new()
	events.videos = VideoSchedule.Changes.new()
	events.videos.lost.append(0)
	manager.report(events)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(5)
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
