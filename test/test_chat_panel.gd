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
