extends RefCounted
## Una visita de la Mano (idea de Benja, 11 de noviembre): un brazo negro y peludo que asoma por el borde derecho y avanza
## hacia un dial a tirones, lento y forzado, como algunas animaciones de Undertale. En cada tirón cambia de cuadro y
## avanza; al llegar agarra el dial con el cuadro 0 y sigue tironeando sin moverse. Se espanta con el flash del celular.
## Lógica pura: HandManager la avanza, la dibuja (con el temblor) y aplica el agarre en NightState.

## Dónde queda el sprite respecto del dial que agarra: en la maqueta, (836, 95) para el dial de Connection, en (840, 89).
const GRAB_OFFSET := Vector2i(-4, 6)
## Desde dónde asoma: el borde izquierdo del sprite en el borde derecho de la pantalla, fuera de la vista.
const START_X := 1280
## Cuántos cuadros tiene el sprite de Benja. El 0 es el que agarra.
const FRAMES := 3

## Qué dial agarra (NightState.Dial).
var dial := 0
## Cuántos tirones dio y cuántos necesita para llegar al dial.
var step := 0
var steps := 0
## El cuadro del sprite.
var frame := 0

var _balance: BalanceData
var _rng: RandomNumberGenerator
## Segundos hasta el próximo tirón.
var _next_jerk := 0.0


func _init(target_dial: int, balance: BalanceData, rng: RandomNumberGenerator) -> void:
	dial = target_dial
	_balance = balance
	_rng = rng
	var mean := (balance.hand_step_seconds.x + balance.hand_step_seconds.y) / 2.0
	steps = maxi(roundi(balance.hand_approach_seconds / mean), 1)
	_next_jerk = _jerk_seconds()


## Llegó al dial y lo tiene agarrado.
func is_grabbing() -> bool:
	return step >= steps


## Avanza `delta` segundos. Devuelve true si en este paso dio un tirón: avanzó y cambió de cuadro o, agarrada, tironeó
## del dial.
func advance(delta: float) -> bool:
	_next_jerk -= delta
	if _next_jerk > 0.0:
		return false
	_next_jerk += _jerk_seconds()
	if not is_grabbing():
		step += 1
		frame = 0 if is_grabbing() else (frame + 1) % FRAMES
	return true


## Dónde va el sprite, en píxeles enteros (regla 10), si el dial que agarra está en `dial_position`.
func position(dial_position: Vector2) -> Vector2i:
	var target := Vector2i(dial_position) + GRAB_OFFSET
	return Vector2i(roundi(lerpf(START_X, target.x, float(step) / steps)), target.y)


func _jerk_seconds() -> float:
	return _rng.randf_range(_balance.hand_step_seconds.x, _balance.hand_step_seconds.y)
