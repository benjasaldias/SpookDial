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
## Sanity que se recupera por segundo mientras Matías scrollea el celular (docs/02 §6).
@export var scroll_sanity_per_second := 4.0
## Segundos que cuenta como scroll cada movimiento de la rueda del mouse: al dejar de scrollear, Sanity
## deja de subir.
@export var scroll_grace := 0.3

@export_group("Señal")
## Señal que le quita una interferencia a un amigo.
@export var interference_damage := 40.0
## Segundos que se anuncia una interferencia antes de golpear: la entrada del amigo titila y suena estática.
@export var interference_warning := 3.0
## Mientras haya amigos desconectados, Trust baja 1 punto cada tantos segundos por cada uno y no se
## recupera (decisión de Benja).
@export var offline_trust_interval := 4.0

@export_group("Audio Sync")
## Golpes por minuto de la base. El ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0
## Cuánto puede adelantarse o atrasarse cada golpe de Matías, en segundos (docs/02 §6).
@export var audio_sync_tolerance := 0.15

@export_group("Videos")
## Segundos para empezar a descargar un video que llegó. Si no empieza a tiempo, se pierde (decisión de Benja).
@export var video_accept_seconds := 15.0
## Segundos para terminar la descarga desde que empezó (decisión de Benja).
@export var video_finish_seconds := 20.0
## Segundos de descarga manteniendo presionado, con buena señal (decisión de Benja).
@export var download_seconds := 10.0
## Segundos de descarga cuando la señal del amigo está bajo download_slow_below (decisión de Benja).
## Con la señal en 0, la descarga no avanza.
@export var download_slow_seconds := 15.0
## Bajo esta señal, la descarga es lenta (diseño §10.1).
@export var download_slow_below := 50.0
