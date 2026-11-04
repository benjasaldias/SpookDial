class_name ChatScriptData
extends Resource
## Un chat guionado (decisión de Benja, sesión 16): un amigo y Matías conversan siguiendo un guion, fuera de
## las solicitudes. El primero es el que sigue al susto guionado y enseña el celular.

## Quién escribe: uno de los amigos del catálogo.
@export var friend: FriendData
## Las líneas, en orden. Las de Matías esperan su botón.
@export var lines: Array[ChatLineData] = []
## Al terminar, el celular del escritorio parpadea hasta que Matías lo abre.
@export var highlight_phone := false
