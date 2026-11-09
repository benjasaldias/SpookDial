extends SceneTree
## Capturas de Snapgram para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_snapgram.gd -- /mnt/c/dev/capturas/snapgram_feed.png /mnt/c/dev/capturas/snapgram_disturbing.png /mnt/c/dev/capturas/snapgram_no_battery.png
## 1. El feed de gatitos, recién abierto.
## 2. Una foto perturbadora, con Sanity en 10.
## 3. Sin batería.

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")
const PhoneView := preload("res://scripts/ui/phone_view.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _desk() -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 1
	desk.get_node("RequestManager").requests_arrive = false
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	return desk


func _capture() -> void:
	var desk := _desk()
	desk.open_phone()
	await create_timer(0.4).timeout
	await _save(0)
	desk.free()
	desk = _desk()
	var state: NightState = desk.get_node("RequestManager").state
	state.sanity = 10.0
	desk.open_phone()
	desk.get_node("UI/PhoneView").scroll_by(2 * PhoneView.POST_HEIGHT)
	await create_timer(0.8).timeout
	await _save(1)
	desk.free()
	desk = _desk()
	state = desk.get_node("RequestManager").state
	state.battery = 0.0
	desk.open_phone()
	await create_timer(0.4).timeout
	await _save(2)
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
