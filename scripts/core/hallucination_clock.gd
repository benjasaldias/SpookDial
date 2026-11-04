extends RefCounted
## Los screamers auditivos falsos (diseño §10.2): con Sanity bajo hallucination_start suenan sonidos que no
## vienen de nada, más seguidos y más fuertes mientras más baja. No restan Sanity (decisión de Benja): son un
## síntoma, no una causa. Lógica pura: ScreamerManager la avanza y hace sonar uno al azar.

## Volumen de una alucinación, en decibeles, con Sanity justo bajo hallucination_start y con Sanity en 0.
const QUIET_DB := -18.0
const LOUD_DB := -3.0

var _balance: BalanceData
var _rng: RandomNumberGenerator
## Sanity está bajo el umbral y corre la espera.
var _active := false
## Segundos que faltan para la próxima.
var _wait_left := 0.0


func _init(balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	_rng = rng


## Cuánto bajó Sanity desde el umbral: 0 justo bajo hallucination_start y 1 en 0.
func depth(sanity: float) -> float:
	return clampf(1.0 - sanity / _balance.hallucination_start, 0.0, 1.0)


## Segundos entre dos alucinaciones con esta Sanity, sin el azar.
func interval(sanity: float) -> float:
	return lerpf(_balance.hallucination_slowest, _balance.hallucination_fastest, depth(sanity))


func volume_db(sanity: float) -> float:
	return lerpf(QUIET_DB, LOUD_DB, depth(sanity))


## Avanza `delta` segundos. Devuelve true si ahora suena una. Si no está permitida (hay una ronda de Audio Sync
## o un screamer), la que toca espera.
func advance(delta: float, sanity: float, allowed: bool) -> bool:
	if sanity >= _balance.hallucination_start:
		_active = false
		return false
	if not _active:
		_active = true
		_wait_left = _next_wait(sanity)
	_wait_left -= delta
	if _wait_left > 0.0 or not allowed:
		return false
	_wait_left = _next_wait(sanity)
	return true


## La próxima espera: el espacio de esta Sanity, ± 25 %.
func _next_wait(sanity: float) -> float:
	return interval(sanity) * _rng.randf_range(0.75, 1.25)
