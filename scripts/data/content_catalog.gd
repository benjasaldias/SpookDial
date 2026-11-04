class_name ContentCatalog
extends Resource
## Índice de todo el contenido (data/catalog.tres). Una entidad entra al juego
## cuando se agrega a las entidades nuevas de una noche.

@export var friends: Array[FriendData] = []
## En orden, de la noche 1 a la 5.
@export var nights: Array[NightData] = []
## La noche 0: el tutorial (decisión de Benja). Usa las páginas de la noche 1.
@export var tutorial: NightData
## Frases clickeables que camuflan las características en los mensajes (DecoyData).
@export var decoys: Array[DecoyData] = []
## Con qué saludo pide ayuda un amigo al empezar una solicitud ("¡Mati, ayuda!!", "¿Estás ahí?"): claves de
## messages.csv, una al azar por solicitud (decisión de Benja, 3-nov). El mensaje inicial no describe nada más.
@export var greeting_keys: Array[String] = []
## Valores de equilibrio de todas las noches (data/balance.tres).
@export var balance: BalanceData
## Las publicaciones que se scrollean en el celular (PhonePostData), en orden.
@export var phone_posts: Array[PhonePostData] = []


## La noche `number`: 0 es el tutorial, y de 1 a 5, las del catálogo.
func night(number: int) -> NightData:
	return tutorial if number == 0 else nights[number - 1]


## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores. El tutorial (noche 0)
## usa las de la noche 1.
func known_entities(night_number: int) -> Array[EntityData]:
	var known: Array[EntityData] = []
	for night_data: NightData in nights:
		if night_data.number <= maxi(night_number, 1):
			known.append_array(night_data.new_entities)
	return known


## Las páginas que el cuaderno suma en la noche `night_number`: las entidades que la noche anterior no se
## conocían (para el resumen entre noches).
func new_pages(night_number: int) -> Array[EntityData]:
	var previous := known_entities(night_number - 1)
	var pages: Array[EntityData] = []
	for entity: EntityData in known_entities(night_number):
		if not previous.has(entity):
			pages.append(entity)
	return pages


func all_entities() -> Array[EntityData]:
	var entities: Array[EntityData] = []
	for night_data: NightData in nights:
		entities.append_array(night_data.new_entities)
	return entities


## Señuelos que pueden aparecer en un lugar: los de ese lugar y los que sirven en cualquiera.
func decoys_for_place(place_key: String) -> Array[DecoyData]:
	var fitting: Array[DecoyData] = []
	for decoy: DecoyData in decoys:
		if decoy != null and decoy.fits_place(place_key):
			fitting.append(decoy)
	return fitting
