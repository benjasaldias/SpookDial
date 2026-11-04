extends "res://test/test_case.gd"

const Screamer := preload("res://scripts/core/screamer.gd")


func _view(desk_visible: bool, notebook_open := false, notebook_page := false, panel_open := false) -> Screamer.View:
	var view := Screamer.View.new()
	view.desk_visible = desk_visible
	view.notebook_open = notebook_open
	view.notebook_page = notebook_page
	view.panel_open = panel_open
	return view


func test_las_luces_siempre_se_pueden() -> bool:
	check_eq(Screamer.candidates(_view(false)), [ScareKind.Kind.LIGHTS], "con todo tapado, solo las luces")
	return true


func test_con_el_escritorio_a_la_vista() -> bool:
	check_eq(Screamer.candidates(_view(true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.CURTAINS,
			ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE], "la cortina, la ventana y el celular")
	return true


func test_con_el_cuaderno_abierto() -> bool:
	check_eq(Screamer.candidates(_view(false, true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.NOTEBOOK_SLAM],
			"en el índice, se puede cerrar de golpe")
	check_eq(Screamer.candidates(_view(false, true, true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.NOTEBOOK_SLAM,
			ScareKind.Kind.INK], "en una página, también la tinta")
	return true


func test_cuanto_resta_cada_uno() -> bool:
	var balance := BalanceData.new()
	check_eq(Screamer.sanity_cost(ScareKind.Kind.CURTAINS, balance), 8.0, "ambiental: −8")
	check_eq(Screamer.sanity_cost(ScareKind.Kind.INK, balance), 8.0, "sobre el cuaderno: −8")
	check_eq(Screamer.sanity_cost(ScareKind.Kind.JUMPSCARE, balance), 15.0, "jumpscare: −15")
	return true


func test_nunca_en_los_ultimos_5_s_de_una_decision() -> bool:
	var balance := BalanceData.new()
	# Con la señal previa de 1 s, a la decisión le tienen que quedar más de 6 s; con la tinta, más de 11.
	check(Screamer.is_fair(ScareKind.Kind.LIGHTS, [], balance), "sin decisiones, siempre")
	check(not Screamer.is_fair(ScareKind.Kind.LIGHTS, [30.0, 6.0], balance), "a una le quedan 6 s")
	check(Screamer.is_fair(ScareKind.Kind.LIGHTS, [30.0, 6.5], balance), "a las dos les quedan más de 6 s")
	check(Screamer.is_fair(ScareKind.Kind.JUMPSCARE, [6.5], balance), "la criatura no tapa nada")
	check(not Screamer.is_fair(ScareKind.Kind.INK, [11.0], balance), "la tinta tapa las reglas 5 s")
	check(Screamer.is_fair(ScareKind.Kind.INK, [11.5], balance), "la tinta, con tiempo de sobra")
	return true


func test_elige_solo_entre_los_que_se_ven_y_son_justos() -> bool:
	var balance := BalanceData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var picked := {}
	for _i in 60:
		picked[Screamer.pick(_view(false, true, true), false, [8.0], balance, rng)] = true
	check_eq(picked.keys().size(), 2, "las luces y el golpe: %s" % [picked.keys()])
	check(not picked.has(ScareKind.Kind.INK), "la tinta no alcanza: a la decisión le quedan 8 s")
	check_eq(Screamer.pick(_view(false, false, false, true), true, [], balance, rng), ScareKind.Kind.JUMPSCARE,
			"si toca, la criatura, detrás de un panel")
	check_eq(Screamer.pick(_view(true), true, [], balance, rng), Screamer.NONE, "con la ventana a la vista, espera")
	check_eq(Screamer.pick(_view(true), false, [5.5], balance, rng), Screamer.NONE, "ninguno es justo: espera")
	return true
