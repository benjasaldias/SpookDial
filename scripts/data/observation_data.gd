class_name ObservationData
extends Resource
## Dato que cambia en cada situación y decide qué regla se aplica (por ejemplo, quién vio a quién primero).

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave de la pregunta en notebook.csv, por ejemplo "¿Quién vio a quién primero?".
@export var question_key: String
## Cada valor posible → clave de su fragmento en messages.csv. Se conserva el orden del Inspector.
@export var values: Dictionary[StringName, String] = {}
## Si tiene audios, el amigo manda el audio del valor en vez de contarlo (decisión de Benja, 7 de noviembre), y el
## texto de `values` queda de subtítulo. Solo en la categoría "¿Qué oyes?": un audio por valor.
@export var audio_values: Dictionary[StringName, AudioStream] = {}


func has_value(value: StringName) -> bool:
	return values.has(value)


## El audio de `value`, o null si esta observación se cuenta con texto.
func audio_for(value: StringName) -> AudioStream:
	return audio_values.get(value)


func value_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(values.keys())
	return ids
