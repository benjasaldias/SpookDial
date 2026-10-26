extends "res://test/test_case.gd"


func _rule(conditions: Dictionary) -> RuleData:
	var rule := RuleData.new()
	for observation_id: StringName in conditions:
		rule.conditions[observation_id] = conditions[observation_id]
	return rule


func test_observacion_conserva_el_orden_de_sus_valores() -> bool:
	var observation := ObservationData.new()
	observation.values = {&"friend": "K_FRIEND", &"trauco": "K_TRAUCO"}
	var ids := observation.value_ids()
	check_eq(ids.size(), 2, "cantidad de valores")
	check_eq(ids[0], &"friend", "primer valor")
	check_eq(ids[1], &"trauco", "segundo valor")
	check(observation.has_value(&"trauco"), "tiene trauco")
	check(not observation.has_value(&"nobody"), "no tiene nobody")
	return true


func test_regla_se_cumple_con_todas_sus_condiciones() -> bool:
	var rule := _rule({&"saw_first": &"trauco", &"axe": &"yes"})
	check(rule.matches({&"saw_first": &"trauco", &"axe": &"yes", &"chopping": &"no"}),
			"se cumple; las demás observaciones no importan")
	return true


func test_regla_no_se_cumple_si_falta_o_difiere_un_valor() -> bool:
	var rule := _rule({&"saw_first": &"trauco", &"axe": &"yes"})
	check(not rule.matches({&"saw_first": &"trauco", &"axe": &"no"}), "difiere el hacha")
	check(not rule.matches({&"saw_first": &"trauco"}), "falta el hacha")
	return true


func test_regla_sin_condiciones_se_cumple_siempre() -> bool:
	var rule := RuleData.new()
	check(rule.is_default(), "es la regla por defecto")
	check(rule.matches({}), "situación vacía")
	check(rule.matches({&"axe": &"no"}), "cualquier situación")
	return true
