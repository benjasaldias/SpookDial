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
	check((desk.get_node("UI/ChatPanel") as Control).visible, "panel visible")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
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
