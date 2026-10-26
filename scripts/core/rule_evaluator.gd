extends RefCounted
## Aplica las reglas de una entidad a una situación. Lógica pura, sin nodos.
## Una situación es un Dictionary: id de observación → valor en esta solicitud.

enum Outcome { CORRECT, RISKY, WRONG }


## La primera regla que se cumple, o null si ninguna (la entidad está mal armada).
static func applicable_rule(entity: EntityData, situation: Dictionary) -> RuleData:
	for rule: RuleData in entity.rules:
		if rule.matches(situation):
			return rule
	return null


## Resultado de responder `action`. Una acción de otra página es incorrecta aunque tenga el mismo id.
static func outcome(entity: EntityData, situation: Dictionary, action: ActionData) -> Outcome:
	var rule := applicable_rule(entity, situation)
	if rule == null or not entity.actions.has(action):
		return Outcome.WRONG
	if action.id == rule.correct_action_id:
		return Outcome.CORRECT
	if action.id == rule.risky_action_id:
		return Outcome.RISKY
	return Outcome.WRONG


## Todas las situaciones posibles: cada combinación de valores de las observaciones.
static func all_situations(entity: EntityData) -> Array[Dictionary]:
	var situations: Array[Dictionary] = [{}]
	for observation: ObservationData in entity.observations:
		var expanded: Array[Dictionary] = []
		for situation: Dictionary in situations:
			for value: StringName in observation.value_ids():
				var next := situation.duplicate()
				next[observation.id] = value
				expanded.append(next)
		situations = expanded
	return situations
