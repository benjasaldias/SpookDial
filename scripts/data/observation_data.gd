class_name ObservationData
extends Resource
## Dato que cambia en cada situación y decide qué regla se aplica (por ejemplo, quién vio a quién primero).

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave de la pregunta en notebook.csv, por ejemplo "¿Quién vio a quién primero?".
@export var question_key: String
## Cada valor posible → clave de su fragmento en messages.csv. Se conserva el orden del Inspector.
@export var values: Dictionary[StringName, String] = {}


func has_value(value: StringName) -> bool:
	return values.has(value)


func value_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(values.keys())
	return ids
