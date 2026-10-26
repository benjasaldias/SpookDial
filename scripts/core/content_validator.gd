extends RefCounted
## Revisa que el contenido esté bien armado. Cada función devuelve los errores en español;
## una lista vacía significa que todo está bien. test_catalog.gd la usa sobre el contenido real,
## así que un error de diseño aparece al correr las pruebas.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Límites de la plantilla de docs/02 §7.
const TRAIT_COUNT := Vector2i(2, 4)
const ACTION_COUNT := Vector2i(4, 4)
const OBSERVATION_COUNT := Vector2i(2, 3)
const RULE_COUNT := Vector2i(2, 4)
const MIN_VALUES := 2


static func validate_entity(entity: EntityData) -> Array[String]:
	var errors: Array[String] = []
	var who := "Entidad '%s'" % entity.id
	if entity.id.is_empty():
		errors.append("Hay una entidad sin id")
	for list_name: String in ["traits", "actions", "observations", "rules"]:
		if (entity.get(list_name) as Array).has(null):
			errors.append("%s: hay un espacio vacío en '%s'" % [who, list_name])
	if not errors.is_empty():
		return errors
	if entity.place_keys.is_empty():
		errors.append("%s: no tiene lugares" % who)
	_check_count(errors, who, "características", entity.traits.size(), TRAIT_COUNT)
	_check_count(errors, who, "acciones", entity.actions.size(), ACTION_COUNT)
	_check_count(errors, who, "observaciones", entity.observations.size(), OBSERVATION_COUNT)
	_check_count(errors, who, "reglas", entity.rules.size(), RULE_COUNT)
	_check_unique_ids(errors, who, "características", entity.traits)
	_check_unique_ids(errors, who, "acciones", entity.actions)
	_check_unique_ids(errors, who, "observaciones", entity.observations)
	for observation: ObservationData in entity.observations:
		if observation.values.size() < MIN_VALUES:
			errors.append("%s: la observación '%s' necesita al menos %d valores" % [who, observation.id, MIN_VALUES])
	for index in entity.rules.size():
		_check_rule(errors, who, entity, index)
	# Buscar reglas que nunca se aplican solo tiene sentido si todo lo anterior está bien.
	if errors.is_empty():
		_check_reachable(errors, who, entity)
	return errors


static func _check_count(errors: Array[String], who: String, what: String, count: int, limits: Vector2i) -> void:
	if count >= limits.x and count <= limits.y:
		return
	var expected := str(limits.x) if limits.x == limits.y else "entre %d y %d" % [limits.x, limits.y]
	errors.append("%s: tiene %d %s y deben ser %s" % [who, count, what, expected])


static func _check_unique_ids(errors: Array[String], who: String, what: String, items: Array) -> void:
	var seen := {}
	for item: Resource in items:
		var item_id: StringName = item.get("id")
		if item_id.is_empty():
			errors.append("%s: hay %s sin id" % [who, what])
		elif seen.has(item_id):
			errors.append("%s: el id '%s' está repetido en %s" % [who, item_id, what])
		seen[item_id] = true


static func _check_rule(errors: Array[String], who: String, entity: EntityData, index: int) -> void:
	var rule: RuleData = entity.rules[index]
	var where := "%s, regla %d" % [who, index + 1]
	var is_last := index == entity.rules.size() - 1
	if is_last and not rule.is_default():
		errors.append("%s: la última regla debe ser 'en cualquier otro caso' (sin condiciones)" % where)
	if not is_last and rule.is_default():
		errors.append("%s: solo la última regla puede no tener condiciones" % where)
	if rule.correct_action_id.is_empty() or rule.risky_action_id.is_empty():
		errors.append("%s: le falta la acción correcta o la de mayor riesgo" % where)
	elif rule.correct_action_id == rule.risky_action_id:
		errors.append("%s: la acción correcta y la de mayor riesgo son la misma" % where)
	else:
		for action_id: StringName in [rule.correct_action_id, rule.risky_action_id]:
			if entity.find_action(action_id) == null:
				errors.append("%s: la acción '%s' no existe" % [where, action_id])
	for observation_id: StringName in rule.conditions:
		var observation := entity.find_observation(observation_id)
		var value: StringName = rule.conditions[observation_id]
		if observation == null:
			errors.append("%s: la observación '%s' no existe" % [where, observation_id])
		elif not observation.has_value(value):
			errors.append("%s: '%s' no es un valor de '%s'" % [where, value, observation_id])


## Una regla tapada por las anteriores en todas las situaciones posibles es un error de diseño.
static func _check_reachable(errors: Array[String], who: String, entity: EntityData) -> void:
	var applied := {}
	for situation: Dictionary in RuleEvaluator.all_situations(entity):
		applied[RuleEvaluator.applicable_rule(entity, situation)] = true
	for index in entity.rules.size() - 1:
		if not applied.has(entity.rules[index]):
			errors.append("%s, regla %d: nunca se aplica, porque las reglas anteriores cubren todos sus casos"
					% [who, index + 1])
