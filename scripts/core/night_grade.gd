extends RefCounted
## La nota de una noche ganada (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33), como en Cuphead: S, A, B o C,
## según lo que esperaron los amigos y las vidas que perdieron esa noche.
## - **La espera** (0 a 3 puntos): el promedio de segundos que estuvo abierto cada pedido de ayuda (consulta, accidente o
##   decisión de la historia), contra la meta de la dificultad (DifficultyData.wait_goal). Hasta la meta, 3; hasta
##   grade_wait_factors.x veces la meta, 2; hasta grade_wait_factors.y veces, 1; más, 0.
## - **Las vidas** (0 a 3 puntos): ninguna perdida, 3; una, 2; dos, 1; más, 0. La herida con que empieza un amigo en
##   Extremo no cuenta.
## - **La letra:** S desde grade_s_points, A desde grade_a_points, B desde grade_b_points y, con menos, C (balance.tres).
## Lógica pura: la pantalla final la muestra.

const NightState := preload("res://scripts/core/night_state.gd")

## Lo más que da cada parte.
const MAX_POINTS := 3


## Los puntos de la espera: `average` segundos por pedido contra la meta `goal`.
static func wait_points(average: float, goal: float, balance: BalanceData) -> int:
	if average <= goal:
		return MAX_POINTS
	if average <= goal * balance.grade_wait_factors.x:
		return 2
	if average <= goal * balance.grade_wait_factors.y:
		return 1
	return 0


## Los puntos de las vidas: 3 menos las perdidas, nunca menos de 0.
static func life_points(lives_lost: int) -> int:
	return maxi(MAX_POINTS - lives_lost, 0)


## La letra de `points` puntos.
static func letter(points: int, balance: BalanceData) -> String:
	if points >= balance.grade_s_points:
		return "S"
	if points >= balance.grade_a_points:
		return "A"
	if points >= balance.grade_b_points:
		return "B"
	return "C"


## La nota de la noche de `state`.
static func letter_for(state: NightState) -> String:
	var points := wait_points(state.average_wait(), state.wait_goal, state.balance) + life_points(state.lives_lost())
	return letter(points, state.balance)
