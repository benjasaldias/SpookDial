class_name TutorialRequestData
extends Resource
## Una solicitud fija de la noche 0, el tutorial (decisión de Benja): quién la pide, qué entidad es y qué
## observa el amigo, para que cada paso enseñe lo que tiene que enseñar. El lugar y los señuelos salen al azar.

## Quién la pide: uno de los amigos del catálogo.
@export var friend: FriendData
## Tiene que estar en las páginas de la noche 0 (las de la noche 1).
@export var entity: EntityData
## Valor de cada observación: id de la observación → id del valor. Las que falten se eligen al azar.
@export var situation: Dictionary[StringName, StringName] = {}
## El mensaje inicial trae una pista: una de las 2 características.
@export var with_hint := true
## Al terminar, el amigo manda un video, para enseñar a descargarlo (decisión de Benja).
@export var sends_video := false
