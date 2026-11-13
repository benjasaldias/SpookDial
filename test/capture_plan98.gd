extends SceneTree
## Capturas del Plan 9.8 (vlog o emergencia) para revisarlas a ojo, a la resolución que se pida. No es una prueba: corre
## con ventana.
## Uso: timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan98.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan98_<ancho>_<nombre>.png:
## - waiting: la noche 1 congelada, esperando la llamada, con las entradas que parpadean;
## - unread: después del susto, con el chat cerrado: las entradas con su punto de no leído;
## - vlog: el chat de León después de separarse, con la línea de nuevos y la barra REC;
## - emergency: llega una consulta a León: la línea de ayuda, el mensaje marcado y las preguntas.
## La noche no corre sola (requests_arrive en false): el script la avanza.

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")

var _dir := ""
var _width := 1280
var _night: Node


func _initialize() -> void:
	_capture.call_deferred()


func _advance(seconds: float) -> void:
	var time := 0.0
	while time < seconds:
		_night.advance(0.1)
		time += 0.1


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	_night = desk.get_node("NightManager")
	manager.night_number = 1
	manager.requests_arrive = false
	manager.random_seed = 5
	root.add_child(desk)
	var settings := GameSettings.new()
	settings.still_camera = true
	desk.apply_settings(settings)
	_night.set_process(false)
	var chat := desk.get_node("UI/ChatPanel")
	await _save("waiting", 1.0)
	# Se abre la llamada: empieza la noche. El saludo y el susto se leen con el chat abierto, y después se cierra.
	desk.get_node("DeskPlane/Entries").get_child(0).pressed.emit()
	await create_timer(0.3).timeout
	_advance(20.0)
	chat.hide()
	_advance(40.0)
	await _save("unread", 6.0)
	chat.open_for(0)
	await _save("vlog", 4.0)
	manager.start_request(0)
	await _save("emergency", 4.0)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan98_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
