extends "res://test/test_case.gd"

const ContentValidator := preload("res://scripts/core/content_validator.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TRAUCO_PATH := "res://data/entities/trauco.tres"


func test_el_trauco_es_valido() -> bool:
	var entity: EntityData = load(TRAUCO_PATH)
	check(entity != null, "se carga")
	var errors := ContentValidator.validate_entity(entity)
	check(errors.is_empty(), str(errors))
	return true


## Las reglas del ejemplo de docs/02 §8.
func test_reglas_del_ejemplo() -> bool:
	var entity: EntityData = load(TRAUCO_PATH)
	check(entity != null, "se carga")
	if entity == null:
		return true
	_check_rule(entity, {&"saw_first": &"friend", &"axe_in_hand": &"yes", &"chopping_sounds": &"yes"},
			&"stare", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"yes", &"chopping_sounds": &"no"},
			&"turn_back", &"stare")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"yes"},
			&"hide_behind_tree", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"no"},
			&"turn_back", &"follow_closely")
	return true


func _check_rule(entity: EntityData, situation: Dictionary, correct: StringName, risky: StringName) -> void:
	var rule := RuleEvaluator.applicable_rule(entity, situation)
	check(rule != null, "ninguna regla se aplica en %s" % situation)
	if rule == null:
		return
	check_eq(rule.correct_action_id, correct, "correcta en %s" % situation)
	check_eq(rule.risky_action_id, risky, "mayor riesgo en %s" % situation)
