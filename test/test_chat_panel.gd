extends "res://test/test_case.gd"

const PANEL := preload("res://scenes/ui/chat_panel.tscn")


func _make_panel() -> Control:
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	return panel


func test_empieza_oculto_y_se_abre_con_el_nombre() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for("Gonzalo")
	check(panel.visible, "visible tras abrir")
	check_eq((panel.get_node("Panel/Title") as Label).text, "Gonzalo", "título")
	panel.free()
	return true


func test_esc_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for("Gonzalo")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	panel._unhandled_input(escape)
	check(not panel.visible, "oculto tras Esc")
	panel.free()
	return true


func _left_click_at(position: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = position
	return click


func test_clic_fuera_del_panel_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for("Gonzalo")
	panel._unhandled_input(_left_click_at(Vector2(800, 300)))
	check(not panel.visible, "oculto tras clic fuera")
	panel.free()
	return true


func test_clic_dentro_del_panel_no_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for("Gonzalo")
	panel._unhandled_input(_left_click_at(Vector2(100, 100)))
	check(panel.visible, "sigue visible tras clic dentro")
	panel.free()
	return true
