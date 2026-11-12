class_name StoryData
extends Resource
## La historia de una noche (decisiones de Benja en S21b, docs/21): lo que los amigos le escriben a Matías y lo que dicen
## en la llamada grupal, en sus momentos. Nunca cambia qué criatura llega ni qué acción es la correcta, nunca mata y
## nunca hace perder (regla 9). La cuenta StoryRunner (Plan 9.7, docs/31).

## Los momentos de la noche, en el orden en que llegan (StoryBeatData.Moment).
@export var beats: Array[StoryBeatData] = []
## Los 3 amigos empiezan juntos: la noche abre con la llamada grupal.
@export var starts_together := true
