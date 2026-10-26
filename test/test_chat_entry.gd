extends "res://test/test_case.gd"

const ENTRY := preload("res://scenes/ui/chat_entry.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")


func _make_entry() -> Node2D:
	var entry := ENTRY.instantiate()
	entry.display_name = "León"
	(Engine.get_main_loop() as SceneTree).root.add_child(entry)
	return entry


func test_nombre_y_estado_inicial() -> bool:
	var entry := _make_entry()
	check_eq((entry.get_node("NameLabel") as Label).text, "León", "nombre")
	check_eq((entry.get_node("Background") as AnimatedSprite2D).animation, &"idle", "animación inicial")
	check(not (entry.get_node("TimerLabel") as Label).visible, "sin temporizador al inicio")
	entry.free()
	return true


func test_estados() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.set_state(ChatEntry.State.WARNING)
	check_eq(background.animation, &"warning", "alerta")
	entry.set_state(ChatEntry.State.DISCONNECTED)
	check_eq(background.animation, &"idle", "desconectado usa idle")
	check_eq(background.modulate, Color(0.45, 0.45, 0.5), "desconectado en gris")
	entry.free()
	return true


func test_temporizador() -> bool:
	var entry := _make_entry()
	var timer := entry.get_node("TimerLabel") as Label
	entry.set_seconds_left(12)
	check(timer.visible, "visible con segundos")
	check_eq(timer.text, "12", "texto")
	entry.set_seconds_left(-1)
	check(not timer.visible, "oculto con -1")
	entry.free()
	return true
