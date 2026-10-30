class_name DecoyData
extends TraitData
## Señuelo: frase clickeable que no ayuda a identificar la entidad (decisión de Benja, 26-oct).
## Camufla las 2 características del mensaje. Al clickearlo vibra y se pone rojo.
## Describe el lugar, un olor, un sonido o algo que se ve. Vive en el catálogo, no en una entidad.

## Lugares donde puede aparecer (las mismas claves que place_keys de las entidades). Vacío: en cualquiera.
@export var place_keys: Array[String] = []


func fits_place(place_key: String) -> bool:
	return place_keys.is_empty() or place_keys.has(place_key)
