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


func test_vida() -> bool:
	var entry := _make_entry()
	entry.set_health(2, 3)
	var pips := entry.get_node("Health").get_children()
	check_eq(pips.size(), 3, "una marca por punto de vida")
	var filled := pips.map(func(pip: Panel) -> bool: return (pip.get_theme_stylebox(&"panel") as StyleBoxFlat).draw_center)
	check_eq(filled, [true, true, false], "2 llenas y 1 vacía: no depende del color")
	for pip: Control in pips:
		check_eq(pip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no le quita el clic a la entrada")
	entry.set_health(0, 3)
	check_eq(entry.get_node("Health").get_child_count(), 3, "se rehacen, no se acumulan")
	entry.free()
	return true


func test_aturdido() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.set_state(ChatEntry.State.STUNNED)
	check_eq(background.animation, &"idle", "aturdido usa idle")
	check_eq(background.modulate, ChatEntry.STATE_MODULATE[ChatEntry.State.STUNNED], "más oscuro")
	entry.show_stun(12)
	var timer := entry.get_node("TimerLabel") as Label
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_STUNNED")).format({"seconds": 12}), "texto")
	check(timer.text.contains("12"), "con los segundos")
	entry.free()
	return true
