extends SceneTree
## Capturas de los screamers para revisarlos a ojo (Plan 7). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_screamers.gd -- /mnt/c/dev/capturas/window.png /mnt/c/dev/capturas/ink.png /mnt/c/dev/capturas/jumpscare.png /mnt/c/dev/capturas/script.png /mnt/c/dev/capturas/script_phone.png
## 1. Noche 3: la figura aparece en la ventana, con el escritorio a la vista.
## 2. El cuaderno, en la página de El Trauco, con la mancha de tinta.
## 3. La criatura asomada en la ventana.
## 4. Noche 0, después del susto guionado: el chat de Gonzalo, con el botón de la respuesta de Matías.
## 5. Después de responder: el chat cerrado y el celular del escritorio con su contorno encendido.

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := _make_desk(3)
	var screamers := desk.get_node("Screamers")
	screamers.play(ScareKind.Kind.WINDOW)
	await create_timer(0.3).timeout
	await _save(0)
	var manager := desk.get_node("RequestManager")
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	desk.notebook_memory.open_page(0, manager.catalog.known_entities(3)[0])
	screamers.play(ScareKind.Kind.INK)
	await create_timer(0.5).timeout
	await _save(1)
	desk.close_panels()
	screamers.play(ScareKind.Kind.JUMPSCARE)
	await create_timer(0.5).timeout
	await _save(2)
	desk.free()
	desk = _make_desk(0)
	desk.get_node("RequestManager").tutorial_queue.clear()
	# La señal previa, la criatura y lo que tarda Gonzalo en escribir (2,5 s).
	await create_timer(6.0).timeout
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	# Lo que tarda en escribirse su mensaje.
	await create_timer(1.5).timeout
	await _save(3)
	desk.get_node("UI/ChatPanel/%ScriptReply").pressed.emit()
	await create_timer(3.0).timeout
	desk.close_panels()
	var phone := desk.get_node("DeskPlane/Phone")
	phone.blinking = true
	await create_timer(0.1).timeout
	await _save(4)
	desk.free()
	# Los sonidos que quedaron sonando se liberan en el hilo de audio, como al terminar las pruebas.
	await create_timer(0.2).timeout
	quit()


## El escritorio en la noche `night_number`, sin solicitudes, interferencias ni videos que lleguen solos,
## y sin screamers del director: cada captura muestra el que pide.
func _make_desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = night_number
	manager.random_seed = 5
	manager.requests_arrive = false
	root.add_child(desk)
	var state: RefCounted = manager.state
	state.videos.pending.clear()
	state.interferences.pending.clear()
	manager.director.scare_times.clear()
	manager.director.scare_creature.clear()
	return desk


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
