class_name StoryOptionData
extends Resource
## Una opción de una decisión de la historia, o lo que pasa sin respuesta: lo que responde Matías, lo que contesta el amigo
## y su efecto. La historia nunca mata ni hace perder: el daño no le quita vida a quien tiene 1, y Trust no baja de 1
## (decisiones de Benja, S21b y S21l).

## Lo que responde Matías (messages.csv). Vacío en la de sin respuesta.
@export var label_key: String
## Es una buena decisión. Quien juega bien elige una de estas (test/balance_model.gd).
@export var good := false
## Lo que escribe el amigo después, en orden (messages.csv).
@export var reply_keys: Array[String] = []
## Cuánto cambia Trust (negativo: baja).
@export var trust_change := 0.0
## La próxima consulta de cada uno de estos amigos llega con tantos segundos menos.
@export var penalty_seconds := 0.0
@export var penalized: Array[FriendData] = []
## Vida que pierde el que tenga más vida entre los candidatos, si sobrevive (queda aturdido, como en un accidente).
@export var damage := 0
@export var damage_candidates: Array[FriendData] = []
## La marca que deja: la leen los pasos que siguen (StoryStepData).
@export var sets_flag: StringName
