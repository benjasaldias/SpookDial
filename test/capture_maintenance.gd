extends SceneTree
## Capturas del mantenimiento para revisarlo a ojo (Plan 6). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_maintenance.gd -- /mnt/c/dev/capturas/mixer.png /mnt/c/dev/capturas/download.png /mnt/c/dev/capturas/phone.png
## 1. Las 02:00. León tiene 72 de señal, Gonzalo 18 y Agustín 0 (sin señal). En el mixer, una ronda con
##    Gonzalo, mientras el amigo aplaude.
## 2. El chat de León, que mandó un video: Matías lo descarga manteniendo presionada la barra. Agustín, sin
##    señal, pidió ayuda: su entrada muestra el tiempo.
## 3. El celular, scrolleado.

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	manager.requests_arrive = false
	manager.rng.seed = 5
	var state: RefCounted = manager.state
	state.elapsed = 140.0
	state.videos.pending.clear()
	state.interferences.pending.clear()
	var signals := [72.0, 18.0, 0.0]
	for index in 3:
		state.friends[index].signal_decay_interval = 0.0
		state.friends[index].signal_level = signals[index]
	desk.open_mixer()
	desk.get_node("UI/MixerView").start_round(1)
	await create_timer(3.4).timeout
	await _save(0)
	desk.close_modes()
	manager.start_request(2)
	state.videos.add_extra(0, state.elapsed)
	await create_timer(0.2).timeout
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk.get_node("UI/ChatPanel/Panel/Download/Hold").button_down.emit()
	await create_timer(4.0).timeout
	await _save(1)
	desk.get_node("UI/ChatPanel/Panel/Download/Hold").button_up.emit()
	desk.open_phone()
	desk.get_node("UI/PhoneView").scroll_by(400.0)
	await create_timer(1.0).timeout
	await _save(2)
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
