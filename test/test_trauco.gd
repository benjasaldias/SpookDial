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


## Las reglas: si sus pasos chapotean (se oye en el audio), seguirlo; si el Trauco lo vio primero, mirar al suelo; con
## el bastón, hablar fuerte; y si no, tirarle arena.
func test_reglas_de_la_propuesta() -> bool:
	var entity: EntityData = load(TRAUCO_PATH)
	check(entity != null, "se carga")
	if entity == null:
		return true
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"muddy"},
			&"follow_to_tree", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"dry"},
			&"look_down", &"follow_to_tree")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"cane", &"ground": &"dry"},
			&"talk_loud", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"axe", &"ground": &"dry"},
			&"throw_sand", &"follow_to_tree")
	return true


func _check_rule(entity: EntityData, situation: Dictionary, correct: StringName, risky: StringName) -> void:
	var rule := RuleEvaluator.applicable_rule(entity, situation)
	check(rule != null, "ninguna regla se aplica en %s" % situation)
	if rule == null:
		return
	check_eq(rule.correct_action_id, correct, "correcta en %s" % situation)
	check_eq(rule.risky_action_id, risky, "mayor riesgo en %s" % situation)
