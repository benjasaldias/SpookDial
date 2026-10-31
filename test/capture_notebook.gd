extends SceneTree
## Captura del cuaderno para revisarlo a ojo (Plan 4). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_notebook.gd -- /mnt/c/dev/capturas/notebook.png
## León recibe una solicitud. Se marcan sus 2 características y, al clickear el nombre que aparece,
## el cuaderno se abre en la página de la entidad, con sus acciones en los botones de respuesta del chat.

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
	var request: RefCounted = manager.start_request(0)
	panel.open_for(0)
	await create_timer(2.0).timeout
	var view: Node = panel.message_views(0)[0]
	for trait_data: TraitData in request.get("traits"):
		view.clue_clicked.emit(view, trait_data.id)
	await create_timer(3.5).timeout
	(panel.get_node("Panel/IdentifyBar/EntityName") as Button).pressed.emit()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
	quit()
