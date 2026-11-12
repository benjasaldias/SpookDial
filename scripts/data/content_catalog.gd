class_name ContentCatalog
extends Resource
## Índice de todo el contenido (data/catalog.tres). Una entidad entra al juego
## cuando se agrega a las entidades nuevas de una noche.

@export var friends: Array[FriendData] = []
## Los modos de juego, cada uno con sus 5 noches (decisión de Benja, 11 de noviembre): Normal primero, que es la de por
## defecto, y después Difícil.
@export var difficulties: Array[DifficultyData] = []
## La noche 0: el tutorial (decisión de Benja), la misma para todas las dificultades. Usa las páginas de la noche 1.
@export var tutorial: NightData
## Frases clickeables que camuflan las características en los mensajes (DecoyData).
@export var decoys: Array[DecoyData] = []
## Con qué saludo pide ayuda un amigo al empezar una solicitud ("¡Mati, ayuda!!", "¿Estás ahí?"): claves de
## messages.csv, una al azar por solicitud (decisión de Benja, 3-nov). El mensaje inicial no describe nada más.
@export var greeting_keys: Array[String] = []
## Lo que le pasa al amigo ("Me perdí.", "Algo me viene siguiendo."): claves de messages.csv, una al azar por
## solicitud. Va después del saludo, y el lugar solo a veces (decisión de Benja, 11 de noviembre).
@export var predicament_keys: Array[String] = []
## Las de predicament_keys que solo dice un amigo que está solo ("Me perdí", "Me separé de los demás"): con los 3 juntos
## en la historia, no se usan (docs/21 §2).
@export var alone_predicament_keys: Array[String] = []
## Los accidentes que les pueden pasar a los amigos (decisión de Benja, 7 de noviembre).
@export var incidents: Array[IncidentData] = []
## Valores de equilibrio de todas las noches (data/balance.tres).
@export var balance: BalanceData
## Las publicaciones de gatitos que se scrollean en el celular (PhonePostData), en orden.
@export var phone_posts: Array[PhonePostData] = []
## Las fotos perturbadoras que aparecen entre ellas con poca Sanity (decisión de Benja, 9 de noviembre).
@export var phone_disturbing_posts: Array[PhonePostData] = []


## La dificultad de por defecto: la primera (Normal), o null si el catálogo no tiene.
func default_difficulty() -> DifficultyData:
	return null if difficulties.is_empty() else difficulties[0]


## La dificultad con ese id (el que guarda la partida) o, si no existe, la de por defecto.
func find_difficulty(difficulty_id: StringName) -> DifficultyData:
	for difficulty: DifficultyData in difficulties:
		if difficulty != null and difficulty.id == difficulty_id:
			return difficulty
	return default_difficulty()


## Las noches 1 a 5 de `difficulty` o, sin ella, las de la de por defecto.
func nights(difficulty: DifficultyData = null) -> Array[NightData]:
	var chosen := difficulty if difficulty != null else default_difficulty()
	if chosen == null:
		var none: Array[NightData] = []
		return none
	return chosen.nights


## La noche `number` de `difficulty` (o de la de por defecto): 0 es el tutorial, que es uno solo, y de 1 a 5, las de la
## dificultad.
func night(number: int, difficulty: DifficultyData = null) -> NightData:
	return tutorial if number == 0 else nights(difficulty)[number - 1]


## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores. El tutorial (noche 0) tiene sus
## propias páginas (la de Gonzalo, decisión de Benja, 11 de noviembre) y, si no tiene, usa las de la noche 1.
## Las entidades llegan en las mismas noches en todas las dificultades (lo revisa el validador).
func known_entities(night_number: int, difficulty: DifficultyData = null) -> Array[EntityData]:
	var known: Array[EntityData] = []
	if night_number == 0 and tutorial != null and not tutorial.new_entities.is_empty():
		known.append_array(tutorial.new_entities)
		return known
	for night_data: NightData in nights(difficulty):
		if night_data.number <= maxi(night_number, 1):
			known.append_array(night_data.new_entities)
	return known


## Las páginas que el cuaderno suma en la noche `night_number`: las entidades que la noche anterior no se
## conocían (para el resumen entre noches).
func new_pages(night_number: int, difficulty: DifficultyData = null) -> Array[EntityData]:
	var previous := known_entities(night_number - 1, difficulty)
	var pages: Array[EntityData] = []
	for entity: EntityData in known_entities(night_number, difficulty):
		if not previous.has(entity):
			pages.append(entity)
	return pages


## Todas las entidades, en el orden en que llegan (las de la dificultad de por defecto: son las mismas en todas).
func all_entities() -> Array[EntityData]:
	var entities: Array[EntityData] = []
	for night_data: NightData in nights():
		entities.append_array(night_data.new_entities)
	return entities


## Señuelos que pueden aparecer en un lugar: los de ese lugar y los que sirven en cualquiera.
func decoys_for_place(place_key: String) -> Array[DecoyData]:
	var fitting: Array[DecoyData] = []
	for decoy: DecoyData in decoys:
		if decoy != null and decoy.fits_place(place_key):
			fitting.append(decoy)
	return fitting
