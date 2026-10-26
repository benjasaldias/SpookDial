class_name ContentCatalog
extends Resource
## Índice de todo el contenido (data/catalog.tres). Una entidad entra al juego
## cuando se agrega a las entidades nuevas de una noche.

@export var friends: Array[FriendData] = []
## En orden, de la noche 1 a la 5.
@export var nights: Array[NightData] = []


## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores.
func known_entities(night_number: int) -> Array[EntityData]:
	var known: Array[EntityData] = []
	for night: NightData in nights:
		if night.number <= night_number:
			known.append_array(night.new_entities)
	return known


func all_entities() -> Array[EntityData]:
	var entities: Array[EntityData] = []
	for night: NightData in nights:
		entities.append_array(night.new_entities)
	return entities
