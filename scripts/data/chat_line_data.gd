class_name ChatLineData
extends Resource
## Una línea de un chat guionado (decisión de Benja, sesión 16): la escribe el amigo o la responde Matías
## con un botón.

enum Speaker { FRIEND, PLAYER }

@export var speaker: Speaker = Speaker.FRIEND
## El texto, en messages.csv.
@export var text_key: String
