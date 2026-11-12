class_name FriendData
extends Resource
## Uno de los 3 amigos. Su personalidad es solo de sabor: no cambia las reglas.

@export var id: StringName
## Clave del nombre en ui.csv.
@export var name_key: String
@export var avatar: Texture2D
## Color de su nombre y de su pestaña en el chat.
@export var color := Color.WHITE

## El pitido de su entrada del PC mientras espera respuesta, una vez por segundo (pedido de Benja, 12 de noviembre). Cada
## amigo tiene su nota: las 3 juntas hacen un acorde disminuido.
@export var alarm: AudioStream

@export_group("Voice")
## El sonido corto que hace mientras escribe, como en Undertale (decisión de Benja, 8 de noviembre).
@export var voice: AudioStream
## Qué tan aguda es su voz: 1 es la altura del sonido, 2 una octava más arriba.
@export var voice_pitch := 1.0
## Cuánto cambia la altura de una letra a otra: 0,08 es hasta un 8 % hacia arriba o hacia abajo.
@export var voice_spread := 0.08
## Suena una de cada tantas letras: mientras menos, más rápido habla.
@export_range(1, 8) var voice_every := 3
