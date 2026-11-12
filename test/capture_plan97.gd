extends SceneTree
## Capturas del Plan 9.7 (la historia de la noche 1) para revisarlas a ojo, a la resolución que se pida: la letra nítida
## depende de ella. No es una prueba: corre con ventana.
## Uso: timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan97.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan97_<ancho>_<nombre>.png:
## - call: la llamada grupal al empezar la noche, con las entradas del PC;
## - separated: el chat de Agustín después de separarse;
## - decision: la decisión de León, en su chat;
## - together: la llamada después de reunirse;
## - closing: el cierre del vlog.
## La noche no corre sola (requests_arrive en false): el script lleva al director y a la historia a cada momento.

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PacingDirector := preload("res://scripts/core/pacing_director.gd")

var _dir := ""
var _width := 1280
var _desk: Node2D
var _manager: Node
var _night: Node


func _initialize() -> void:
	_capture.call_deferred()


## Avanza la noche `seconds` segundos, de a poco, como si pasaran.
func _advance(seconds: float) -> void:
	var step := 0.1
	var time := 0.0
	while time < seconds:
		_night.advance(step)
		time += step


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	_desk = DESK.instantiate()
	_manager = _desk.get_node("RequestManager")
	_night = _desk.get_node("NightManager")
	_manager.night_number = 1
	_manager.requests_arrive = false
	_manager.random_seed = 5
	root.add_child(_desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	_desk.apply_settings(settings)
	_night.set_process(false)
	var chat := _desk.get_node("UI/ChatPanel")
	# La intro del vlog, en la llamada.
	_advance(12.0)
	_desk.get_node("DeskPlane/Entries").get_child(0).pressed.emit()
	await _save("call", 6.0)
	# 25 s antes de la primera ola (a los 60 s): el susto, se separan y cada uno escribe dónde está.
	_advance(48.0)
	chat.open_for(2)
	await _save("separated", 8.0)
	# La calma antes de la final: la reunión.
	var director: PacingDirector = _manager.director
	director.phase = PacingDirector.Phase.CALM
	director.waves_started = 2
	director.calms_started = 2
	director.wave_index = director.finale_index()
	director.next_at = _manager.state.elapsed + 90.0
	_manager.story.beat_index = 4
	_advance(10.0)
	chat.open_for(0)
	await _save("decision", 5.0)
	# León va a la amarilla; Agustín se esconde; se reúnen en la cabaña.
	_manager.answer_incident(0, 0)
	_advance(6.0)
	_manager.answer_incident(2, 0)
	_advance(20.0)
	chat.open_for(1)
	await _save("together", 6.0)
	# Después de la final, el cierre.
	director.phase = PacingDirector.Phase.DONE
	director.waves_started = 3
	director._finale_started = true
	_manager.story.beat_index = 6
	_manager.story.started = false
	_advance(12.0)
	await _save("closing", 6.0)
	_desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan97_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
