class_name BalanceData
extends Resource
## Valores de equilibrio que valen para todas las noches (docs/02 §5.2 y §6): cuánto dura la noche,
## la vida y el aturdimiento de los amigos, las consecuencias de cada acción y cómo baja Trust.
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
## Trust que se pierde por una acción incorrecta (negativo). Desde el 11 de noviembre, Trust no se recupera en la
## noche, así que cada error pesa más.
@export var wrong_trust := -15.0
## Trust que se pierde, además, cuando nadie responde a tiempo y el amigo decide solo (negativo).
@export var no_answer_trust := -15.0
## Trust que se pierde cuando se pierde un video: el amigo arriesgó para grabarlo (decisión de Benja, 11 de noviembre).
@export var lost_video_trust := -10.0

@export_group("Accidentes")
## Segundos para responder un accidente (decisión de Benja, 7 de noviembre).
@export var incident_seconds := 15.0
## Vida que le quita al amigo una mala respuesta o no responder. No baja Trust: un accidente no es culpa de Matías.
@export var incident_damage := 1

@export_group("Trust")
## Trust no se recupera durante la noche (decisión de Benja, 11 de noviembre): vuelve a 100 al empezar cada una.
## Segundos que una solicitud puede esperar sin que Trust baje (decisión de Benja, 4 de noviembre)…
@export var slow_answer_grace := 30.0
## …y después, Trust baja tantos puntos por segundo por cada solicitud que sigue esperando.
@export var slow_answer_trust := 0.25

@export_group("Sanity")
## Bajo este valor de Sanity aparece la viñeta, que se oscurece más mientras más baja.
@export var vignette_start := 60.0
## Sanity que se recupera por segundo mientras Matías scrollea el celular (docs/02 §6).
@export var scroll_sanity_per_second := 4.0
## Segundos que cuenta como scroll cada movimiento de la rueda del mouse: al dejar de scrollear, Sanity
## deja de subir.
@export var scroll_grace := 0.3
## Segundos de scroll que dura la batería del celular, que vuelve a llenarse solo al empezar la noche (decisión de
## Benja, 7 de noviembre). Desde que el flash también la gasta, son 48 s (antes 38): con 38, la noche 5 no se podía
## ganar (decisión de Benja, 11 de noviembre).
@export var phone_battery_seconds := 48.0

## Bajo este valor de Sanity, algunas publicaciones del celular son fotos perturbadoras (decisión de Benja,
## 9 de noviembre)…
@export var disturbing_post_sanity := 30.0
## …una de cada tantas…
@export var disturbing_post_every := 6
## …y bajo este valor empeora…
@export var disturbing_post_worse_sanity := 15.0
## …a una de cada tantas.
@export var disturbing_post_worse_every := 3

## Sanity que se pierde por segundo con las cortinas cerradas: la pieza a oscuras también pesa (decisión de Benja,
## 7 de noviembre). Se suma a lo que baja con el tiempo.
@export var closed_curtains_sanity := 0.3
## Sanity que se pierde por segundo con la criatura afuera y las cortinas abiertas (decisión de Benja, 7 de
## noviembre). Se suma a lo que baja con el tiempo.
@export var creature_sanity := 2.0

@export_group("Señal")
## Señal que le quita una interferencia a un amigo.
@export var interference_damage := 40.0
## Segundos que se anuncia una interferencia antes de golpear: la entrada del amigo titila y suena estática.
@export var interference_warning := 3.0
## Mientras haya amigos desconectados, Trust baja 1 punto cada tantos segundos por cada uno y no se
## recupera (decisión de Benja).
@export var offline_trust_interval := 4.0

@export_group("Audio Sync")
## Cuánto más rápida es cada ronda que la anterior, en las noches de varias rondas (decisión de Benja, 7 de
## noviembre). La base de la primera es la de NightData.audio_sync_bpm.
@export var audio_sync_round_speedup := 1.15
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

@export_group("Identificación")
## Segundos del temporizador que cuesta una pregunta (docs/02 §3.2). Si a la solicitud le queda ese tiempo o
## menos, ya no se puede preguntar. Es la palanca principal de la identificación por preguntas (decisión de
## Benja, 3-nov).
@export var question_cost := 5.0
## Segundos que Matías piensa, después de marcar las 2 características, antes de que aparezca el nombre de la entidad
## (docs/02 §3.1). Eran 3; el primer testeo los encontró largos (decisión de Benja, 11 de noviembre).
@export var thinking_seconds := 2.0

@export_group("Director")
## Olas de verdad (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## cuando se resuelven y una ola final grande, lo más tarde posible.
## Segundos de silencio al empezar la noche: la primera ola llega a esta hora.
@export var first_wave_at := 60.0
## Segundos entre dos solicitudes de una misma ola (mínimo y máximo, al azar).
@export var wave_spacing := Vector2(4, 8)
## Segundos de calma sin solicitudes nuevas desde que se resuelve una ola (mínimo y máximo, al azar). Si la ola
## siguiente estaba planeada para más tarde, la calma dura hasta entonces.
@export var wave_calm := Vector2(40, 60)
## Cuántos segundos después de empezar una ola llegan sus interferencias, sus accidentes y la Mano.
@export var wave_event_delay := Vector2(3, 15)
## Cuántos segundos después de empezar una calma llegan sus videos y sus screamers.
@export var calm_event_delay := Vector2(5, 15)
## Segundos que se atrasan las solicitudes que faltan cuando un amigo queda herido (decisión de Benja).
@export var hurt_respite := 10.0
## Segundos hasta la primera solicitud de la noche 0, que no tiene olas.
@export var first_request_delay := 5.0

@export_group("Screamers")
## Segundos de la señal previa: las luces parpadean y baja el sonido ambiente (diseño §11).
@export var scare_warning := 1.0
## Un screamer nunca ocurre si a una decisión le quedan tantos segundos o menos (diseño §11).
@export var scare_margin := 5.0
## Segundos mínimos entre dos screamers.
@export var scare_min_gap := 25.0
## Sanity que resta un screamer ambiental o sobre el cuaderno (docs/02 §6).
@export var scare_sanity := 8.0
## Sanity que resta la criatura de la ventana, el antiguo jumpscare (docs/02 §6).
@export var jumpscare_sanity := 15.0
## Segundos que la criatura de la ventana se queda afuera, desde que llega, aunque se cierren las cortinas: hay que
## abrirlas para revisar si sigue ahí (decisión de Benja, 7 de noviembre). Cada visita se queda un tiempo al azar en
## este rango, para que revisar importe (decisión de Benja, 11 de noviembre). No tapa nada: la noche no se pausa.
@export var creature_stay := Vector2(15, 40)
## Segundos que la mancha de tinta tapa la página del cuaderno (diseño §11).
@export var ink_seconds := 5.0

@export_group("La Mano")
## La Mano (idea de Benja, 11 de noviembre): asoma por la derecha hacia un dial al azar y, si lo agarra, lo baja hasta
## un mínimo. Se espanta con el flash del celular.
## Porcentaje de la batería que gasta cada flash, haya o no una Mano.
@export var flash_cost := 10.0
## Segundos que tarda en llegar al dial desde el borde de la pantalla.
@export var hand_approach_seconds := 12.0
## Segundos de cada tirón (mínimo y máximo, al azar): avanza lento y forzado.
@export var hand_step_seconds := Vector2(0.5, 0.7)
## Puntos por segundo que baja el dial agarrado (en Connection, cada una de las 3 señales).
@export var hand_drain := 6.0
## Hasta dónde lo baja: nunca a 0.
@export var hand_floor := 15.0

@export_group("Alucinaciones")
## Bajo este valor de Sanity suenan screamers auditivos falsos (diseño §10.2).
@export var hallucination_start := 50.0
## Segundos entre dos alucinaciones con Sanity justo bajo hallucination_start…
@export var hallucination_slowest := 40.0
## …y con Sanity en 0. En el medio, el espacio se acorta parejo.
@export var hallucination_fastest := 10.0
