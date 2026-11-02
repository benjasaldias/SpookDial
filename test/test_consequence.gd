extends "res://test/test_case.gd"

const Consequence := preload("res://scripts/core/consequence.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Equilibrio por defecto, pero con la probabilidad de herir fija: 1 (siempre) o 0 (nunca).
func _balance(hurt_chance: float) -> BalanceData:
	var balance := BalanceData.new()
	balance.risky_hurt_chance = hurt_chance
	balance.wrong_hurt_chance = hurt_chance
	return balance


func _roll(outcome: RuleEvaluator.Outcome, by_player: bool, hurt_chance: float) -> Consequence:
	return Consequence.new(outcome, by_player, _balance(hurt_chance), RandomNumberGenerator.new())


func test_la_accion_correcta_no_tiene_consecuencias() -> bool:
	var consequence := _roll(RuleEvaluator.Outcome.CORRECT, true, 1.0)
	check_eq(consequence.damage, 0, "sin daño")
	check_eq(consequence.trust_change, 0.0, "Trust igual")
	check(not consequence.risky and not consequence.is_hurt(), "ni riesgo ni herida")
	return true


func test_la_accion_de_mayor_riesgo() -> bool:
	var hurt := _roll(RuleEvaluator.Outcome.RISKY, true, 1.0)
	check_eq(hurt.damage, 2, "−2 PV")
	check(hurt.is_hurt(), "herido")
	check_eq(hurt.trust_change, -20.0, "Trust −20")
	check(hurt.risky, "da un video extra si sobrevive")
	var lucky := _roll(RuleEvaluator.Outcome.RISKY, true, 0.0)
	check_eq(lucky.damage, 0, "sin daño si tiene suerte")
	check_eq(lucky.trust_change, -20.0, "Trust baja según el riesgo, no según la suerte")
	return true


func test_una_accion_incorrecta() -> bool:
	var hurt := _roll(RuleEvaluator.Outcome.WRONG, true, 1.0)
	check_eq(hurt.damage, 1, "−1 PV")
	check_eq(hurt.trust_change, -10.0, "Trust −10")
	check(not hurt.risky, "no da video")
	check_eq(_roll(RuleEvaluator.Outcome.WRONG, true, 0.0).trust_change, -10.0, "Trust −10 aunque no lo hiera")
	return true


func test_sin_respuesta_trust_baja_ademas() -> bool:
	check_eq(_roll(RuleEvaluator.Outcome.CORRECT, false, 0.0).trust_change, -15.0, "acertó solo: −15")
	check_eq(_roll(RuleEvaluator.Outcome.WRONG, false, 0.0).trust_change, -25.0, "incorrecta y sin respuesta: −25")
	return true


## Con las probabilidades de docs/02 (70 % y 60 %), en 2000 tiradas.
func test_probabilidad_de_herir() -> bool:
	var balance := BalanceData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var hurt := {RuleEvaluator.Outcome.RISKY: 0, RuleEvaluator.Outcome.WRONG: 0}
	for _i in 2000:
		for outcome: RuleEvaluator.Outcome in hurt:
			if Consequence.new(outcome, true, balance, rng).is_hurt():
				hurt[outcome] += 1
	check(abs(hurt[RuleEvaluator.Outcome.RISKY] / 2000.0 - 0.7) < 0.04, "mayor riesgo cerca de 70 %%: %d" % hurt[RuleEvaluator.Outcome.RISKY])
	check(abs(hurt[RuleEvaluator.Outcome.WRONG] / 2000.0 - 0.6) < 0.04, "incorrecta cerca de 60 %%: %d" % hurt[RuleEvaluator.Outcome.WRONG])
	return true


## Si el amigo decidió solo y sin señal, su decisión no baja Trust, pero el daño es el de siempre
## (decisión de Benja).
func test_sin_senal_trust_no_baja() -> bool:
	var offline := Consequence.new(RuleEvaluator.Outcome.WRONG, false, _balance(1.0), RandomNumberGenerator.new(), true)
	check_eq(offline.trust_change, 0.0, "ni −10 ni −15")
	check_eq(offline.damage, 1, "el daño de siempre")
	return true
