extends SceneTree
## Captura del chat para revisarlo a ojo (Plan 3). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_chat.gd -- /mnt/c/dev/capturas/chat.png
## León recibe una solicitud con señal 40 (estática), Gonzalo otra;
## se pregunta "¿Qué ves?" y "¿Cómo está el ambiente?", y se clickean un señuelo y una característica.

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
	manager.state.friends[0].signal_level = 40.0
	manager.start_request(0)
	manager.start_request(1)
	panel.open_for(0)
	await create_timer(4.0).timeout
	# Primero el mensaje inicial (el saludo, el lugar y a veces una pista), y después las preguntas: las
	# características y los señuelos salen al preguntar (decisión de Benja, 3-nov).
	manager.ask(0, ClueCategory.Kind.SIGHT)
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	await create_timer(0.5).timeout
	# Se clickean las frases de la respuesta a "¿Qué ves?": las características se marcan y los señuelos vibran.
	var view: Node = panel.message_views(0)[2]
	for token in view.message.tokens:
		if token.is_clue() and not token.covered:
			view.clue_clicked.emit(view, token.clue_id)
	await create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
	quit()
