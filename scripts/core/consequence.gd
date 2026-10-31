extends RefCounted
## Lo que le pasa a un amigo después de una acción (diseño §9, docs/02 §5.2): cuánta vida pierde,
## cuánto baja Trust y si fue la acción de mayor riesgo, que da un video extra si el amigo sobrevive.
## Lógica pura: RequestManager la tira al terminar una solicitud y NightState la aplica.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Vida que pierde el amigo. Con más de 0 queda herido (y aturdido, si sobrevive).
var damage := 0
## Cuánto cambia Trust (0 o negativo). Baja según el riesgo de lo elegido, no según la suerte (diseño §9).
var trust_change := 0.0
## Fue la acción de mayor riesgo.
var risky := false


## Tira la consecuencia de `outcome` con las probabilidades de `balance`. `answered_by_player` es false
## si nadie respondió a tiempo y el amigo decidió solo: entonces Trust baja además.
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator) -> void:
	match outcome:
		RuleEvaluator.Outcome.RISKY:
			risky = true
			trust_change = balance.risky_trust
			if rng.randf() < balance.risky_hurt_chance:
				damage = balance.risky_damage
		RuleEvaluator.Outcome.WRONG:
			trust_change = balance.wrong_trust
			if rng.randf() < balance.wrong_hurt_chance:
				damage = balance.wrong_damage
	if not answered_by_player:
		trust_change += balance.no_answer_trust


func is_hurt() -> bool:
	return damage > 0
