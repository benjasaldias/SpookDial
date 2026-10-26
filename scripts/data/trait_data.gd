class_name TraitData
extends Resource
## Característica fija de una entidad: aparece destacada en los mensajes y se clickea para identificarla.
## Dos entidades comparten una característica si usan el mismo id.

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave del fragmento en messages.csv. La frase clickeable va entre asteriscos: "vio un *hombrecito*".
@export var text_key: String
