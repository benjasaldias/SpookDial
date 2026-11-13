class_name NightData
extends Resource
## Parámetros de una noche. Los valores iniciales están en docs/02 §6 y se ajustan probando.
## La noche 0 es el tutorial (decisión de Benja): sus solicitudes son fijas y no se puede perder.

@export_range(0, 5) var number := 1
## Minutos de juego después de las 06:00: una noche con historia termina a las 06:30, para que la historia quepa sin
## regalar tiempo libre (decisión de Benja, Plan 9.8). El reloj sigue a la misma velocidad.
@export_range(0, 60) var overtime_minutes := 0
## Dónde están los amigos esa noche, en ui.csv (para el resumen entre noches).
@export var place_key: String
## Entidades que aparecen por primera vez esta noche. Las de noches anteriores siguen apareciendo.
@export var new_entities: Array[EntityData] = []

@export_group("Solicitudes")
@export var requests_total := 6
@export var max_simultaneous := 1
## Segundos para responder, antes del factor de Trust.
@export var base_decision_time := 45.0
## Probabilidad de que el mensaje inicial traiga una pista: una de las 2 características, que se puede
## clickear. Todo lo demás (características, señuelos y observaciones) sale al preguntar (decisión de Benja, 3-nov).
@export_range(0.0, 1.0) var first_hint_chance := 1.0
## Probabilidad de que el mensaje inicial diga dónde está el amigo (decisión de Benja, 11 de noviembre). Si no lo dice,
## solo saluda y cuenta qué le pasa: identificar rápido a la criatura es parte de la habilidad del jugador.
@export_range(0.0, 1.0) var place_chance := 1.0
## Señuelos de la solicitud: frases clickeables que camuflan sus 2 características cuando el amigo las cuenta.
@export var decoys_per_request := 1
## Solicitudes por ola común: llegan juntas, con pocos segundos de diferencia, y cuando se resuelven viene una calma
## (decisiones de Benja, 2 y 11 de noviembre).
@export var wave_size := 3
## Solicitudes de la ola final, la más grande, que llega lo más tarde posible (decisión de Benja, 11 de noviembre).
## Con 3, los 3 amigos piden ayuda a la vez.
@export var finale_size := 3
## Segundos de calma después de una ola común (mínimo y máximo, al azar). Con (0, 0), la de balance.tres (40 a 60 s). Extremo
## los acorta, para que las olas lleguen más seguidas (Plan 9.6, docs/30).
@export var wave_calm := Vector2.ZERO

## Accidentes de la noche: un amigo se tropieza o se corta, y se responde con sentido común (decisión de Benja, 7
## de noviembre).
@export var incident_count := 0

@export_group("Plan de olas")
## Olas armadas a mano, en orden; la última es la final (docs/26 §3.2: la noche 1 de Normal). Si está vacío, el director
## arma las olas solo, con los valores de arriba. **Con un plan, las solicitudes, las olas, los accidentes, las
## interferencias, la Mano y los screamers salen del plan**, y esos campos de la noche no se usan. Los videos del plan
## tienen que sumar la cuota.
@export var wave_plan: Array[WaveData] = []

@export_group("Señal")
@export var signal_decays := false
## Segundos por cada punto de señal perdido (mínimo y máximo; varía).
@export var signal_decay_interval := Vector2(3, 6)
@export var interference_count := 0
## Tiempos del Audio Sync (0 si esta noche no hay).
@export var audio_sync_beats := 0
## Golpes por minuto de la base del Audio Sync, que sube noche a noche (decisión de Benja, 7 de noviembre). El
## ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0

@export_group("Sanity y cuota")
## Segundos por cada punto de Sanity perdido.
@export var sanity_drain_interval := 6.0
## Videos que hay que recibir para ganar la noche (= envíos programados).
@export var content_quota := 2

@export_group("Screamers")
## Screamers de la noche, sin contar las alucinaciones ni el susto guionado. Llegan en cualquier momento,
## con las reglas de justicia (decisión de Benja).
@export var scare_count := 0
## Cuántos de esos screamers son la criatura que se asoma por la ventana (el antiguo jumpscare): desde la noche 2,
## y más seguido hacia el final (decisión de Benja, 7 de noviembre).
@export var creature_visits := 0
## Cuántas veces llega la Mano, en las olas comunes (decisión de Benja, 11 de noviembre). La noche 0 la enseña aparte.
@export var hand_visits := 0

@export_group("Guion")
## Segundos desde las 00:00 del susto guionado (0: no hay). Llega en el primer momento sin solicitudes.
@export var scripted_scare_time := 0.0
## Qué screamer es el susto guionado.
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE
## El chat guionado que sigue al susto guionado (decisión de Benja, sesión 16), o ninguno.
@export var scripted_chat: ChatScriptData

@export_group("Historia")
## La historia de la noche (decisiones de Benja en S21b, docs/21; Plan 9.7): lo que los amigos cuentan en el chat y en la
## llamada grupal. Es la misma en las 3 dificultades. Sin historia, la noche no cambia.
@export var story: StoryData

@export_group("Tutorial")
## Solo en la noche 0: las solicitudes fijas, en orden. León usa la primera para enseñar en su chat.
@export var tutorial_requests: Array[TutorialRequestData] = []
## Solo en la noche 0: las tarjetas con videos que aparecen cuando León se despide (pedido de Benja, 11 de noviembre).
@export var tutorial_cards: Array[TutorialCardData] = []


func is_tutorial() -> bool:
	return number == 0


## Cuánto dura la noche, en segundos reales: hasta las 06:00 (BalanceData.night_seconds) más sus minutos de más, a la
## misma velocidad del reloj.
func length(balance: BalanceData) -> float:
	return balance.night_seconds * (360.0 + overtime_minutes) / 360.0


## La noche tiene sus olas armadas a mano.
func has_wave_plan() -> bool:
	return not wave_plan.is_empty()


## Los totales de la noche: con un plan de olas, sumados del plan; sin plan, los de sus campos.
func total_requests() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.requests) if has_wave_plan() else requests_total


## Los screamers, sin contar las alucinaciones ni el susto guionado: los ambientales y la criatura.
func total_scares() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.calm_scares + wave.calm_creatures) if has_wave_plan() \
			else scare_count


func total_creatures() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.calm_creatures) if has_wave_plan() else creature_visits


func total_hands() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.hands) if has_wave_plan() else hand_visits


func total_interferences() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.interferences) if has_wave_plan() else interference_count


func total_incidents() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.incidents) if has_wave_plan() else incident_count


## Los videos que trae el plan de olas (sin plan, ninguno: los suelta el director en las calmas).
func total_videos() -> int:
	return _plan_sum(func(wave: WaveData) -> int: return wave.videos)


func _plan_sum(count: Callable) -> int:
	var total := 0
	for wave: WaveData in wave_plan:
		if wave != null:
			total += int(count.call(wave))
	return total
