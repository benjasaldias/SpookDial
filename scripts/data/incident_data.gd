class_name IncidentData
extends Resource
## Un accidente de un amigo: se tropieza, se corta o se cae al agua (decisión de Benja, 7 de noviembre). No tiene
## entidad ni cuaderno: se responde con sentido común, entre una buena idea y 1 o 2 malas.

@export var id: StringName
## Lo que escribe el amigo (messages.csv).
@export var message_key: String
## La respuesta que lo salva, en messages.csv.
@export var correct_key: String
## Las malas ideas, en messages.csv: 1 o 2.
@export var wrong_keys: Array[String] = []
