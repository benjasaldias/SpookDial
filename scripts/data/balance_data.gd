class_name BalanceData
extends Resource
## Valores de equilibrio que valen para todas las noches (docs/02 §5.2 y §6): cuánto dura la noche,
## la vida y el aturdimiento de los amigos, las consecuencias de cada acción y cómo se recupera Trust.
## Se ajustan probando, en el Inspector de data/balance.tres. Los que cambian por noche están en NightData.

## Segundos reales que dura una noche, de las 00:00 a las 06:00 (diseño §5).
@export var night_seconds := 420.0

@export_group("Amigos")
## Vida de cada amigo al empezar la noche. Con 0, muere y se pierde la noche.
@export var friend_health := 3
## Segundos que un amigo herido queda aturdido: no pide ayuda ni envía videos.
@export var stun_seconds := 15.0

@export_group("Consecuencias")
## Probabilidad de que la acción de mayor riesgo hiera al amigo.
@export_range(0.0, 1.0) var risky_hurt_chance := 0.7
## Vida que le quita la acción de mayor riesgo si lo hiere.
@export var risky_damage := 2
## Trust que se pierde por elegir la acción de mayor riesgo (negativo).
@export var risky_trust := -20.0
## Probabilidad de que una acción incorrecta hiera al amigo.
@export_range(0.0, 1.0) var wrong_hurt_chance := 0.6
## Vida que le quita una acción incorrecta si lo hiere.
@export var wrong_damage := 1
## Trust que se pierde por una acción incorrecta (negativo).
@export var wrong_trust := -10.0
## Trust que se pierde, además, cuando nadie responde a tiempo y el amigo decide solo (negativo).
@export var no_answer_trust := -15.0

@export_group("Trust")
## Trust sube 1 punto cada tantos segundos…
@export var trust_recovery_interval := 8.0
## …si no bajó en los últimos tantos segundos.
@export var trust_recovery_delay := 20.0

@export_group("Sanity")
## Bajo este valor de Sanity aparece la viñeta, que se oscurece más mientras más baja.
@export var vignette_start := 60.0
