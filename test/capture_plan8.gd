extends SceneTree
## Capturas del Plan 8 para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan8.gd -- /mnt/c/dev/capturas/plan8_menu.png /mnt/c/dev/capturas/plan8_tutorial.png /mnt/c/dev/capturas/plan8_summary.png /mnt/c/dev/capturas/plan8_pause.png
## 1. El menú principal, con una partida guardada en la noche 2.
## 2. La noche 0: la solicitud de León con su chat abierto y el aviso que pide preguntar.
## 3. El resumen al ganar la noche 1: los videos y las páginas nuevas de la noche 2.
## 4. El menú de pausa, con las opciones abiertas.

const DESK := preload("res://scenes/desk/desk.tscn")
const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	root.add_child(menu)
	menu.setup(2, GameSettings.new())
	await create_timer(0.2).timeout
	await _save(0)
	menu.free()
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 0
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	desk.get_node("NightManager").advance(5.5)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(1)
	desk.free()
	desk = DESK.instantiate()
	desk.get_node("RequestManager").night_number = 1
	desk.get_node("RequestManager").requests_arrive = false
	root.add_child(desk)
	var state: NightState = desk.get_node("RequestManager").state
	state.videos.received = state.videos.quota
	state.elapsed = 419.0
	desk.get_node("NightManager").advance(1.0)
	await create_timer(1.8).timeout
	await _save(2)
	desk.free()
	desk = DESK.instantiate()
	desk.get_node("RequestManager").requests_arrive = false
	root.add_child(desk)
	desk.pause()
	desk.get_node("Overlay/PauseMenu/Center/Box/Options").pressed.emit()
	await create_timer(0.2).timeout
	await _save(3)
	paused = false
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
