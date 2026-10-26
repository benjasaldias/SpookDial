extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_entidad_valida_no_tiene_errores() -> bool:
	var errors := ContentValidator.validate_entity(Fixtures.make_entity())
	check(errors.is_empty(), str(errors))
	return true


func test_cantidades() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions.pop_back()
	entity.traits.pop_back()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "tiene 3 acciones y deben ser 4")
	check_contains(errors, "tiene 1 características y deben ser entre 2 y 4")
	return true


func test_la_regla_por_defecto_va_al_final() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules.reverse()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 3: la última regla debe ser")
	check_contains(errors, "regla 1: solo la última regla puede no tener condiciones")
	return true


func test_acciones_de_las_reglas() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules[0].correct_action_id = &"a9"
	entity.rules[1].risky_action_id = &"a3"
	entity.rules[2].risky_action_id = &""
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 1: la acción 'a9' no existe")
	check_contains(errors, "regla 2: la acción correcta y la de mayor riesgo son la misma")
	check_contains(errors, "regla 3: le falta la acción correcta o la de mayor riesgo")
	return true


func test_condiciones() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules[0].conditions = {&"o9": &"yes"}
	entity.rules[1].conditions = {&"o2": &"maybe"}
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 1: la observación 'o9' no existe")
	check_contains(errors, "regla 2: 'maybe' no es un valor de 'o2'")
	return true


func test_ids_repetidos_o_vacios() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions[1].id = &"a1"
	entity.traits[0].id = &""
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "el id 'a1' está repetido en acciones")
	check_contains(errors, "hay características sin id")
	return true


func test_regla_que_nunca_se_aplica() -> bool:
	var entity := Fixtures.make_entity()
	# Después de "o1 = yes", una regla "o1 = yes y o2 = no" nunca llega a aplicarse.
	entity.rules.insert(1, Fixtures.make_rule({&"o1": &"yes", &"o2": &"no"}, &"a1", &"a2"))
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 2: nunca se aplica")
	return true


func test_espacio_vacio_no_rompe_la_validacion() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions[2] = null
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "hay un espacio vacío en 'actions'")
	return true


func test_observacion_con_un_valor_y_sin_lugares() -> bool:
	var entity := Fixtures.make_entity()
	entity.observations[0].values.erase(&"no")
	entity.place_keys.clear()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "la observación 'o1' necesita al menos 2 valores")
	check_contains(errors, "no tiene lugares")
	return true
