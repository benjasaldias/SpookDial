extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


func test_se_aplica_la_primera_regla_que_se_cumple() -> bool:
	var entity := Fixtures.make_entity()
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"yes", &"o2": &"yes"}), entity.rules[0],
			"se cumplen la 1 y la 2: gana la 1")
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"yes"}), entity.rules[1], "solo la 2")
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"no"}), entity.rules[2],
			"en cualquier otro caso")
	return true


func test_sin_regla_que_se_cumpla_devuelve_null() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules.pop_back()
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"no"}), null, "sin regla por defecto")
	return true


func test_resultado_correcto_riesgoso_e_incorrecto() -> bool:
	var entity := Fixtures.make_entity()
	var situation := {&"o1": &"yes", &"o2": &"no"}
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a1")), RuleEvaluator.Outcome.CORRECT, "a1")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a2")), RuleEvaluator.Outcome.RISKY, "a2")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a3")), RuleEvaluator.Outcome.WRONG, "a3")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a4")), RuleEvaluator.Outcome.WRONG, "a4")
	check_eq(RuleEvaluator.outcome(entity, situation, null), RuleEvaluator.Outcome.WRONG, "sin acción")
	return true


func test_accion_de_otra_pagina_es_incorrecta() -> bool:
	var entity := Fixtures.make_entity(&"beast")
	var other_page := Fixtures.make_entity(&"ghost")
	# Las dos entidades tienen una acción "a1", pero responder desde la página de ghost es un error.
	var answer := other_page.find_action(&"a1")
	check_eq(RuleEvaluator.outcome(entity, {&"o1": &"yes", &"o2": &"no"}, answer), RuleEvaluator.Outcome.WRONG,
			"página equivocada")
	return true


func test_todas_las_situaciones() -> bool:
	var situations := RuleEvaluator.all_situations(Fixtures.make_entity())
	check_eq(situations.size(), 4, "2 observaciones × 2 valores")
	for expected: Dictionary in [
		{&"o1": &"yes", &"o2": &"yes"},
		{&"o1": &"yes", &"o2": &"no"},
		{&"o1": &"no", &"o2": &"yes"},
		{&"o1": &"no", &"o2": &"no"},
	]:
		check(situations.has(expected), "falta la situación %s" % expected)
	return true
