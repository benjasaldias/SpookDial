extends SceneTree
## Capturas del Plan 9.9 (la nota) para revisarlas a ojo, a la resolución que se pida. No es una prueba: corre con
## ventana.
## Uso: timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan99.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan99_<ancho>_<nombre>.png:
## - grade: el resumen de la noche 1 ganada a las 04:42, con nota A (19 s por pedido y una vida perdida);
## - victory: la victoria de la noche 5, con nota S (12 s por pedido y ninguna vida perdida).

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")

var _dir := ""
var _width := 1280


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = 1
	manager.requests_arrive = false
	manager.random_seed = 5
	root.add_child(desk)
	desk.get_node("NightManager").set_process(false)
	var state: NightState = manager.state
	state.videos.received = state.videos.quota
	state.asked = 7
	state.waited = 7 * 19.0
	state.friends[1].hurt(1, 0.0)
	state.elapsed = 330.0
	desk._on_night_ended(NightState.Ending.WON, null)
	await _save("grade", 2.0)
	desk.get_node("Overlay/EndScreen").hide()
	manager.night_number = 5
	state.waited = 7 * 12.0
	state.friends[1].health_lost = 0
	desk._on_night_ended(NightState.Ending.WON, null)
	await _save("victory", 2.0)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan99_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
