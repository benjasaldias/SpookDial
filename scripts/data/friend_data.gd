class_name FriendData
extends Resource
## Uno de los 3 amigos. Su personalidad es solo de sabor: no cambia las reglas.

@export var id: StringName
## Clave del nombre en ui.csv.
@export var name_key: String
@export var avatar: Texture2D
## Color de su nombre y de su pestaña en el chat.
@export var color := Color.WHITE
