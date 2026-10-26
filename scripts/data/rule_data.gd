class_name RuleData
extends Resource
## Regla de una página del cuaderno. Se cumple si se cumplen todas sus condiciones.
## Sin condiciones es "en cualquier otro caso", y debe ser la última de la página.

## id de observación → valor que debe tener.
@export var conditions: Dictionary[StringName, StringName] = {}
## id de la acción correcta (una de las 4 de la entidad).
@export var correct_action_id: StringName
## id de la acción de mayor riesgo: da un video extra si el amigo sobrevive.
@export var risky_action_id: StringName
## Clave del texto de la regla en notebook.csv.
@export var text_key: String


func is_default() -> bool:
	return conditions.is_empty()


## `situation`: id de observación → valor en esta solicitud.
func matches(situation: Dictionary) -> bool:
	for observation_id: StringName in conditions:
		if situation.get(observation_id) != conditions[observation_id]:
			return false
	return true
