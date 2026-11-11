extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const StatBars := preload("res://scripts/ui/stat_bars.gd")


func _make_bars() -> Control:
	var bars := StatBars.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(bars)
	return bars


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func test_cada_barra_muestra_su_valor() -> bool:
	var bars := _make_bars()
	bars.set_values(40.0, 60.0, 80.0)
	check_eq(bars.fill(StatBars.Stat.CONNECTION), 0.4, "Connection")
	check_eq(bars.fill(StatBars.Stat.SANITY), 0.6, "Sanity")
	check_eq(bars.fill(StatBars.Stat.TRUST), 0.8, "Trust")
	bars.free()
	return true


func test_cada_barra_conserva_el_color_de_su_dial() -> bool:
	check(StatBars.COLORS[StatBars.Stat.CONNECTION].g > 0.7, "Connection, verde")
	check(StatBars.COLORS[StatBars.Stat.SANITY].r > 0.8 and StatBars.COLORS[StatBars.Stat.SANITY].g < 0.5, "Sanity, roja")
	check(StatBars.COLORS[StatBars.Stat.TRUST].r > 0.8 and StatBars.COLORS[StatBars.Stat.TRUST].g > 0.7, "Trust, amarilla")
	return true


func test_titila_si_baja_de_golpe_y_no_si_baja_de_a_poco() -> bool:
	var bars := _make_bars()
	bars.set_values(100.0, 100.0, 100.0)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "el primer valor no cuenta como una baja")
	bars.set_values(100.0, 99.9, 100.0)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "de a poco no titila")
	bars.set_values(100.0, 91.9, 100.0)
	check(bars.is_flashing(StatBars.Stat.SANITY), "un susto la hace titilar")
	check(not bars.is_flashing(StatBars.Stat.TRUST), "las otras, no")
	bars._process(StatBars.FLASH_SECONDS + 0.1)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "deja de titilar")
	bars.free()
	return true


func test_avisa_bajo_25() -> bool:
	var bars := _make_bars()
	bars.set_values(25.0, 24.0, 100.0)
	check(not bars.is_alert(StatBars.Stat.CONNECTION), "con 25, todavía no")
	check(bars.is_alert(StatBars.Stat.SANITY), "con 24, sí")
	bars.free()
	return true


func test_con_reducir_destellos_la_luz_no_parpadea() -> bool:
	var bars := _make_bars()
	bars.set_values(100.0, 10.0, 100.0)
	bars.reduce_flashes = true
	for step in 8:
		bars._process(0.1)
		check_eq(bars.alert_light(), 1.0, "queda fija")
	bars.free()
	return true


## Van arriba, en el hueco entre el chat y el cuaderno, y no reciben clics.
func test_estan_en_el_hueco_entre_el_chat_y_el_cuaderno() -> bool:
	var desk := _make_desk()
	var bars := desk.get_node("Overlay/StatBars") as Control
	var chat_right: float = desk.get_node("UI/ChatPanel/Panel").get_global_rect().end.x
	var notebook_left: float = desk.get_node("UI/NotebookPanel/Page").get_global_rect().position.x
	var rect := bars.get_global_rect()
	check(rect.position.x >= chat_right, "el chat no las tapa")
	check(rect.end.x <= notebook_left, "el cuaderno no las tapa")
	check(rect.end.y <= 92.0, "quedan sobre la barra de las cortinas")
	check_eq(bars.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no reciben clics")
	desk.free()
	return true


func test_muestran_el_estado_de_la_noche() -> bool:
	var desk := _make_desk()
	var state: RefCounted = desk.get_node("RequestManager").state
	state.sanity = 50.0
	state.trust = 30.0
	desk._process(0.0)
	var bars := desk.get_node("Overlay/StatBars") as Control
	check_eq(bars.fill(StatBars.Stat.SANITY), 0.5, "Sanity")
	check_eq(bars.fill(StatBars.Stat.TRUST), 0.3, "Trust")
	desk.free()
	return true
