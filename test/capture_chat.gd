extends SceneTree
## Captura del chat para revisarlo a ojo (Plan 3). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_chat.gd -- /mnt/c/dev/capturas/chat.png
## León recibe una solicitud con señal 40 (estática), Gonzalo otra; se marca una característica,
## se clickea un señuelo y se pregunta "¿Qué ves?".

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	var panel := desk.get_node("UI/ChatPanel")
	manager.requests_arrive = false
	manager.rng.seed = 5
	manager.signal_levels[0] = 40.0
	var request: RefCounted = manager.start_request(0)
	manager.start_request(1)
	panel.open_for(0)
	await create_timer(4.0).timeout
	var view: Node = panel.message_views(0)[0]
	var decoys: Array = request.get("decoys")
	var traits: Array = request.get("traits")
	view.clue_clicked.emit(view, (decoys[0] as TraitData).id)
	view.clue_clicked.emit(view, (traits[0] as TraitData).id)
	manager.ask(0, ClueCategory.Kind.SIGHT)
	await create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
	quit()
