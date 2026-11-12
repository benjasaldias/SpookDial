class_name DifficultyData
extends Resource
## Un modo de juego, Normal, Difícil o Extremo (decisiones de Benja, 11 y 12 de noviembre; docs/26 §3 y docs/30): sus 5
## noches, en qué noche empieza, cómo se identifica a la criatura, qué hay que terminar para desbloquearlo y sus castigos.
## Todo lo que baja la dificultad va a Normal; el juego de antes del testeo pasó a ser Difícil.
## La dificultad se elige solo al empezar una partida nueva (data/difficulty/*.tres).

## Con qué se guarda en la partida: "normal", "hard" o "extreme".
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
## terminar Normal (decisión de Benja, D1), y Extremo al terminar Difícil (decisión de Benja, 12 de noviembre).
@export var unlocked_by: DifficultyData

@export_group("Castigos")
## Cuánto más baja Trust por un error: una respuesta incorrecta, la de mayor riesgo, sin respuesta y un video perdido. En
## Extremo, ×1,5 (decisión de Benja, 12 de noviembre). Tardar en contestar no cambia.
@export_range(1.0, 3.0, 0.05) var error_trust_scale := 1.0
## Cuántos amigos, al azar, empiezan cada noche heridos (Extremo: 1; idea de Benja, 12 de noviembre)…
@export_range(0, 3) var wounded_friends := 0
## …y con cuánta vida. La vida máxima sigue siendo la de balance.tres.
@export_range(1, 3) var wounded_health := 1

## Los castigos por error que escala error_trust_scale (BalanceData).
const ERROR_TRUST := ["wrong_trust", "risky_trust", "no_answer_trust", "lost_video_trust"]


## El equilibrio de esta dificultad: `base` (balance.tres) o, si los errores cuestan más, una copia con esos castigos
## escalados. El original no cambia.
func balance_for(base: BalanceData) -> BalanceData:
	if is_equal_approx(error_trust_scale, 1.0):
		return base
	var scaled := base.duplicate() as BalanceData
	for property: String in ERROR_TRUST:
		scaled.set(property, float(base.get(property)) * error_trust_scale)
	return scaled
