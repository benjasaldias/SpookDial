extends "res://test/test_case.gd"
## El parpadeo (docs/26 §2.3): un borde que avisa qué apretar, y que queda fijo con "Reducir destellos".

const Highlight := preload("res://scripts/ui/highlight.gd")


func test_parpadea() -> bool:
	check(Highlight.is_lit(0.0, false), "empieza encendido")
	check(Highlight.is_lit(0.39, false), "encendido hasta los 0,4 s")
	check(not Highlight.is_lit(0.41, false), "después se apaga")
	check(not Highlight.is_lit(0.79, false), "hasta los 0,8 s")
	check(Highlight.is_lit(0.81, false), "y vuelve a encenderse")
	return true


func test_con_reducir_destellos_queda_fijo() -> bool:
	for time: float in [0.0, 0.5, 1.3]:
		check(Highlight.is_lit(time, true), "fijo a los %.1f s" % time)
	var highlight := Highlight.new()
	highlight.active = true
	highlight.reduce_flashes = true
	highlight._process(0.5)
	check(highlight.is_showing(), "pasado el medio segundo, sigue a la vista")
	highlight.free()
	return true


func test_el_borde_rodea_al_control() -> bool:
	var button := Button.new()
	button.size = Vector2(30, 28)
	var highlight := Highlight.new()
	button.add_child(highlight)
	check_eq(highlight.border_rect(), Rect2(-4, -4, 38, 36), "2 px de grosor, 2 px por fuera del botón")
	check_eq(highlight.z_index, 1, "por encima de sus vecinos")
	button.free()
	return true


func test_inactivo_no_se_ve() -> bool:
	var highlight := Highlight.new()
	check(not highlight.active, "empieza sin activar")
	check(not highlight.is_showing(), "sin activar no se ve")
	highlight.active = true
	check(highlight.is_showing(), "activado, se ve")
	highlight._process(0.5)
	check(not highlight.is_showing(), "a los 0,5 s está apagado")
	highlight.active = false
	highlight.active = true
	check(highlight.is_showing(), "al volver a activarlo empieza encendido")
	highlight.free()
	return true


## También rodea un nodo 2D, como una entrada del PC, con el tamaño que se le dé (Plan 9.5).
func test_rodea_un_nodo_2d() -> bool:
	var target := Node2D.new()
	var highlight := Highlight.new()
	highlight.target_size = Vector2(243, 26)
	target.add_child(highlight)
	check_eq(highlight.border_rect(), Rect2(Vector2.ZERO, Vector2(243, 26)).grow(Highlight.MARGIN + Highlight.WIDTH),
			"el tamaño dado, agrandado")
	target.free()
	return true
