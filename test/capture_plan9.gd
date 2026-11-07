extends SceneTree
## Capturas del Plan 9 para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan9.gd -- /mnt/c/dev/capturas/plan9_hud.png /mnt/c/dev/capturas/plan9_audio.png /mnt/c/dev/capturas/plan9_curtains.png /mnt/c/dev/capturas/plan9_phone.png /mnt/c/dev/capturas/plan9_incident.png
## 1. Las barras con el cuaderno abierto: Sanity y Trust bajas.
## 2. El chat de León con un audio en la respuesta a "¿Qué oyes?".
## 3. Las cortinas cerradas, con el cuarto oscurecido.
## 4. El celular abierto con poca batería.
## 5. Un accidente en el chat, con sus opciones.

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")


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
	var desk := _desk(1)
	var state: NightState = desk.get_node("RequestManager").state
	state.sanity = 45.0
	state.trust = 20.0
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	await create_timer(0.3).timeout
	await _save(0)
	desk.free()
	desk = _desk(1)
	var manager := desk.get_node("RequestManager")
	manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SOUND)
	await create_timer(1.5).timeout
	await _save(1)
	desk.free()
	desk = _desk(2)
	desk.get_node("WallPlane/Curtains").clicked.emit()
	await create_timer(0.3).timeout
	await _save(2)
	desk.free()
	desk = _desk(1)
	state = desk.get_node("RequestManager").state
	state.battery = 15.0
	desk.open_phone()
	await create_timer(0.4).timeout
	await _save(3)
	desk.free()
	desk = _desk(1)
	manager = desk.get_node("RequestManager")
	manager.start_incident(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(4)
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
