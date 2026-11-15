extends "res://test/test_case.gd"
## La nota de cada noche ganada (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33): la espera por pedido contra la
## meta de la dificultad y las vidas perdidas, de 0 a 3 puntos cada una. S con 5 o 6 puntos, A con 4, B con 2 o 3 y C con
## 0 o 1.

const Fixtures := preload("res://test/content_fixtures.gd")
const NightGrade := preload("res://scripts/core/night_grade.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func test_puntos_por_la_espera() -> bool:
	var balance := BalanceData.new()
	check_eq(NightGrade.wait_points(15.0, 15.0, balance), 3, "en la meta, 3")
	check_eq(NightGrade.wait_points(22.5, 15.0, balance), 2, "hasta 1,5 veces la meta, 2")
	check_eq(NightGrade.wait_points(30.0, 15.0, balance), 1, "hasta el doble, 1")
	check_eq(NightGrade.wait_points(30.1, 15.0, balance), 0, "más, 0")
	return true


func test_puntos_por_las_vidas() -> bool:
	check_eq([NightGrade.life_points(0), NightGrade.life_points(1), NightGrade.life_points(2), NightGrade.life_points(5)],
			[3, 2, 1, 0], "ninguna 3, una 2, dos 1, más 0")
	return true


func test_la_letra() -> bool:
	var balance := BalanceData.new()
	var letters := range(7).map(func(points: int) -> String: return NightGrade.letter(points, balance))
	check_eq(letters, ["C", "C", "B", "B", "A", "S", "S"], "de 0 a 6 puntos")
	return true


func test_la_nota_de_una_noche() -> bool:
	var catalog := Fixtures.make_catalog()
	var state := NightState.new(catalog.nights()[0], catalog.balance, 3, RandomNumberGenerator.new())
	state.asked = 4
	state.waited = 4 * 19.0
	state.friends[1].hurt(1, 0.0)
	check_eq(NightGrade.letter_for(state), "A", "19 s contra 15 (2) y una vida perdida (2): 4 puntos")
	state.wait_goal = 20.0
	check_eq(NightGrade.letter_for(state), "S", "con la meta de Difícil, 19 s da 3: 5 puntos")
	return true
