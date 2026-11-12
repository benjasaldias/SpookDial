class_name StoryDecisionData
extends Resource
## Una decisión de la historia (docs/21 §2): llega como un accidente, con alarma, el tiempo de un accidente y sus
## opciones en el chat del amigo que pregunta. No contestar cuenta como la peor. Puede tener más de una opción buena, cada
## una con su costo (la decisión de León en la noche 1).

## Quién pregunta: un amigo del catálogo.
@export var friend: FriendData
## Lo que pregunta (messages.csv).
@export var message_key: String
## Las opciones, en el orden en que se muestran: la historia se repite igual.
@export var options: Array[StoryOptionData] = []
## Lo que pasa si nadie contesta a tiempo.
@export var no_answer: StoryOptionData
