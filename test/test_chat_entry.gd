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


## Las barras llenas de la señal, de la más baja a la más alta.
func _filled_bars(entry: Node2D) -> Array:
	return entry.get_node("Signal").get_children().map(func(bar: Panel) -> bool:
		return (bar.get_theme_stylebox(&"panel") as StyleBoxFlat).draw_center)


func test_barras_de_senal() -> bool:
	var entry := _make_entry()
	entry.set_signal(100.0)
	check_eq(_filled_bars(entry), [true, true, true, true, true], "señal llena: 5 barras")
	entry.set_signal(45.0)
	check_eq(_filled_bars(entry), [true, true, true, false, false], "una barra por cada 20: 3 llenas y 2 vacías")
	entry.set_signal(0.0)
	check_eq(_filled_bars(entry), [false, false, false, false, false], "sin señal, todas vacías")
	check_eq(entry.get_node("Signal").get_child_count(), 5, "se rehacen, no se acumulan")
	entry.free()
	return true


func test_titila_si_viene_una_interferencia() -> bool:
	var entry := _make_entry()
	entry.set_interference_warning(true)
	entry._process(0.05)
	check(entry.modulate.a < 1.0, "se apaga")
	entry._process(0.12)
	check_eq(entry.modulate.a, 1.0, "y se vuelve a encender")
	entry._process(0.12)
	check(entry.modulate.a < 1.0, "titila")
	entry.set_interference_warning(false)
	check_eq(entry.modulate.a, 1.0, "al pasar, queda encendida")
	entry.free()
	return true


func test_video_y_sin_senal() -> bool:
	var entry := _make_entry()
	var timer := entry.get_node("TimerLabel") as Label
	entry.show_video(12)
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_VIDEO")).format({"seconds": 12}), "el video")
	check(timer.text.contains("12"), "con los segundos")
	entry.show_offline()
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_OFFLINE")), "sin señal")
	check(timer.text != "ENTRY_OFFLINE", "el texto está en ui.csv")
	entry.free()
	return true
