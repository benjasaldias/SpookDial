class_name TraitData
extends Resource
## Característica fija de una entidad: aparece destacada en los mensajes y se clickea para identificarla.
## Dos entidades comparten una característica si usan el mismo id.

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave del fragmento en messages.csv. La frase clickeable va entre asteriscos: "vio un *hombrecito*".
@export var text_key: String
## Su nombre en el cuaderno (notebook.csv), siempre el mismo, aunque el amigo la diga con otras palabras (decisión de
## Benja, 11 de noviembre).
@export var label_key: String
## Otras formas de decirla, con sinónimos y paráfrasis (messages.csv), cada una con su frase entre asteriscos. La
## solicitud elige una al azar entre estas y text_key, así que hay que reconocerla de verdad.
@export var variant_keys: Array[String] = []


## Todas sus formas de decirse: text_key y sus variantes.
func text_keys() -> Array[String]:
	var keys: Array[String] = [text_key]
	keys.append_array(variant_keys)
	return keys
