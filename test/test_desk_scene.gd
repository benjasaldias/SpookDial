extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")

const POSITIONS := {
	"WallPlane/Background": Vector2(0, 0),
	"WallPlane/Window": Vector2(266, 114),
	"WallPlane/ExteriorClip/Exterior": Vector2(0, 0),
	"WallPlane/Enemy": Vector2(300, 172),
	"WallPlane/GlassPane": Vector2(273, 121),
	"WallPlane/Curtains": Vector2(219, 92),
	"WallPlane/DialConnection": Vector2(840, 89),
	"WallPlane/DialSanity": Vector2(840, 219),
	"WallPlane/DialTrust": Vector2(840, 348),
	"DeskPlane/DeskSurface": Vector2(0, 505),
	"DeskPlane/Notebook": Vector2(1017, 562),
	"DeskPlane/Microphone": Vector2(830, 571),
	"DeskPlane/Phone": Vector2(357, 618),
	"DeskPlane/Mixer": Vector2(130, 565),
	"DeskPlane/Cables": Vector2(241, 504),
	"DeskPlane/PC": Vector2(479, 433),
	"DeskPlane/Entries/EntryLeon": Vector2(518, 454),
	"DeskPlane/Entries/EntryGonzalo": Vector2(518, 494),
	"DeskPlane/Entries/EntryAgustin": Vector2(518, 534),
}


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func test_cada_objeto_en_su_posicion() -> bool:
	var desk := _make_desk()
	for path: String in POSITIONS:
		check_eq((desk.get_node(path) as Node2D).position, POSITIONS[path], path)
	desk.free()
	return true


func test_todo_el_arte_cargado() -> bool:
	var desk := _make_desk()
	for sprite in desk.find_children("*", "AnimatedSprite2D", true, false):
		check((sprite as AnimatedSprite2D).sprite_frames != null, "sin arte: %s" % desk.get_path_to(sprite))
	desk.free()
	return true


func test_clic_en_una_entrada_abre_el_chat() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	leon.pressed.emit()
	var panel := desk.get_node("UI/ChatPanel") as Control
	check(panel.visible, "panel visible")
	check_eq(panel.get("selected_friend"), 0, "en la conversación de León")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
	desk.free()
	return true


func test_el_chat_recibe_los_mensajes_de_las_solicitudes() -> bool:
	var desk := _make_desk()
	desk.get_node("RequestManager").start_request(2)
	check_eq(desk.get_node("UI/ChatPanel").message_views(2).size(), 1, "mensaje de Agustín en su conversación")
	desk.free()
	return true


func test_las_entradas_usan_los_nombres_del_catalogo() -> bool:
	var desk := _make_desk()
	var names := {"EntryLeon": "León", "EntryGonzalo": "Gonzalo", "EntryAgustin": "Agustín"}
	for entry_name: String in names:
		var label := desk.get_node("DeskPlane/Entries/%s/NameLabel" % entry_name) as Label
		check_eq(label.text, names[entry_name], entry_name)
	desk.free()
	return true


func test_una_solicitud_hace_parpadear_su_entrada() -> bool:
	var desk := _make_desk()
	var request: RefCounted = desk.get_node("RequestManager").start_request(1)
	check(request != null, "la noche del escritorio tiene entidades")
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "Gonzalo en alerta")
	var timer := gonzalo.get_node("TimerLabel") as Label
	check(timer.visible, "muestra el tiempo")
	if request != null:
		check_eq(timer.text, str(ceili(request.get("time_left"))), "segundos")
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").state, ChatEntry.State.IDLE, "León sin solicitud")
	desk.free()
	return true


func test_cerrar_el_chat_deselecciona() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	leon.pressed.emit()
	(desk.get_node("UI/ChatPanel") as Control).hide()
	check_eq(leon.state, ChatEntry.State.IDLE, "León vuelve a idle")
	desk.free()
	return true


func test_camara_con_zoom_leve_y_centrada() -> bool:
	var desk := _make_desk()
	var camera := desk.get_node_or_null("LookCamera") as Camera2D
	check(camera != null, "existe LookCamera")
	if camera:
		check(camera.has_method("_process") and camera.get("look_zoom") == 1.05, "tiene el script LookCamera cargado")
		check(camera.is_current(), "es la cámara activa")
		check(camera.zoom.is_equal_approx(Vector2(1.05, 1.05)), "zoom: %s" % camera.zoom)
		check_eq(camera.position, Vector2(640, 360), "centrada al inicio")
	check(desk.get_node_or_null("ParallaxRig") == null, "el parallax por planos ya no existe")
	desk.free()
	return true
