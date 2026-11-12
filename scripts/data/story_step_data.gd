class_name StoryStepData
extends Resource
## Un paso de un momento de la historia: una línea de un amigo, separarse, reunirse o una decisión. Con los 3 juntos, las
## líneas van a la llamada grupal; separados, al chat de quien habla.

enum Kind { LINE, SEPARATE, JOIN, DECISION }

@export var kind: Kind = Kind.LINE
## LINE: quién habla (un amigo del catálogo) y qué dice (messages.csv).
@export var speaker: FriendData
@export var text_key: String
## DECISION: la decisión que llega como un accidente.
@export var decision: StoryDecisionData

@export_group("Condición")
## El paso va solo si una decisión anterior dejó esta marca…
@export var requires_flag: StringName
## …o solo si no la dejó (vacío: siempre).
@export var unless_flag: StringName


## El paso va con estas marcas.
func applies(flags: Array[StringName]) -> bool:
	if not requires_flag.is_empty() and not flags.has(requires_flag):
		return false
	return unless_flag.is_empty() or not flags.has(unless_flag)
