class_name DifficultyData
extends Resource
## Un modo de juego, Normal o Difícil (decisiones de Benja, 11 de noviembre, tras el primer testeo; docs/26 §3): sus 5
## noches, en qué noche empieza, cómo se identifica a la criatura y qué hay que terminar para desbloquearlo.
## Todo lo que baja la dificultad va a Normal; el juego de antes del testeo pasó a ser Difícil.
## La dificultad se elige solo al empezar una partida nueva (data/difficulty/*.tres).

## Con qué se guarda en la partida: "normal" o "hard".
@export var id: StringName
## Su nombre (ui.csv).
@export var name_key: String
## Una línea que la describe en el menú (ui.csv).
@export var description_key: String
## Las noches 1 a 5, en orden. La noche 0 (el tutorial) es una sola, la del catálogo.
@export var nights: Array[NightData] = []
## En qué noche empieza una partida nueva: 0 en Normal (el tutorial) y 1 en Difícil (decisión de Benja, D5).
@export_range(0, 1) var first_night := 0
## La identificación es guiada: las características y los señuelos en amarillo y clickeables, las observaciones en azul
## y "Matías piensa" con el nombre de la entidad. Sin esto (Difícil), nada se destaca ni se clickea, salvo el audio:
## se reconoce a la criatura leyendo y se busca su página en el índice del cuaderno (decisión de Benja, D3).
@export var highlights := true
## La dificultad que hay que terminar (ganar su noche 5) para desbloquear esta, o ninguna: Difícil se desbloquea al
## terminar Normal (decisión de Benja, D1).
@export var unlocked_by: DifficultyData
