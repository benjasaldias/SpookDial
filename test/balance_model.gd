extends RefCounted
## El modelo de "jugar bien" para la prueba de equilibrio (Plan 9.1, docs/24): Benja pidió que toda noche se pueda
## ganar. No es contenido del juego.
## Quien juega bien ya conoce a las entidades: a cada solicitud le dedica 12 s de atención y le hace 2 preguntas, que le
## quitan 10 s al temporizador; un accidente le toma 4 s, espantar a la Mano 4 s (antes de que agarre) y descargar un
## video 10 s. Atiende de a una tarea, la que vence primero. Cuando llega la criatura, cierra la cortina a los 3 s y la
## revisa 2 veces, 1 s cada vez. Nunca se equivoca ni pierde un video, y quiere terminar con Sanity sobre 10.
## Los valores al azar se toman en su peor caso: la criatura se queda lo más posible.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

const REQUEST_ATTENTION := 12.0
const QUESTIONS := 2
const INCIDENT_ATTENTION := 4.0
const HAND_ATTENTION := 4.0
const VIDEO_ATTENTION := 10.0
const CREATURE_REACTION := 3.0
const CREATURE_CHECKS := 2
const CHECK_SECONDS := 1.0
const SANITY_MARGIN := 10.0
const FRIENDS := 3
## Cada cuánto avanza la simulación.
const STEP := 0.1


## La batería que gasta quien juega bien en la noche, en %: la que hace falta para reponer Sanity, más un flash por
## cada visita de la Mano. Tiene que ser 100 o menos.
static func battery_needed(night: NightData, balance: BalanceData) -> float:
	return scroll_battery(night, balance) + night.hand_visits * balance.flash_cost


## La batería que hace falta para reponer Sanity, en %.
static func scroll_battery(night: NightData, balance: BalanceData) -> float:
	var to_recover := maxf(sanity_loss(night, balance) - (100.0 - SANITY_MARGIN), 0.0)
	return to_recover / balance.scroll_sanity_per_second / balance.phone_battery_seconds * 100.0


## Cuánta Sanity pierde quien juega bien: con el tiempo, con los screamers y con la criatura (con la cortina abierta
## hasta cerrarla, cerrada mientras se queda y abierta en cada revisión).
static func sanity_loss(night: NightData, balance: BalanceData) -> float:
	var loss := balance.night_seconds / night.sanity_drain_interval
	loss += (night.scare_count - night.creature_visits) * balance.scare_sanity
	loss += night.creature_visits * balance.jumpscare_sanity
	var open := (CREATURE_REACTION + CREATURE_CHECKS * CHECK_SECONDS) * balance.creature_sanity
	loss += night.creature_visits * (open + balance.creature_stay.y * balance.closed_curtains_sanity)
	return loss


## Corre la noche con el director real y quien juega bien. Devuelve "missed" (las tareas que vencieron sin atender),
## "trust" (Trust al final: solo baja por las solicitudes que esperan más de la cuenta), "requests" (cuántas llegaron),
## "tasks" (cada una con su tipo, su llegada, su fin y su plazo), "waves" y "calms" (las horas en que empezó cada una),
## "interferences", "videos", "scares" ([hora, es la criatura]) y "load" (cuántas tareas había abiertas, cada segundo).
static func simulate(night: NightData, balance: BalanceData, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var director := PacingDirector.new(night, balance, rng)
	var result := {"missed": 0, "trust": 100.0, "requests": 0, "tasks": [], "waves": [], "calms": [],
			"interferences": [], "videos": [], "scares": [], "load": []}
	var open: Array[Dictionary] = []
	var busy: Array[bool] = []
	busy.resize(FRIENDS)
	busy.fill(false)
	var pending_videos: Array[float] = []
	var time := 0.0
	var next_sample := 0.0
	while time < balance.night_seconds:
		var active := open.filter(func(task: Dictionary) -> bool: return task["kind"] == "request").size()
		var beat := director.advance(time, active)
		if beat.wave_started >= 0:
			result["waves"].append([time, beat.finale_started])
		if beat.calm_started:
			result["calms"].append(time)
		result["interferences"].append_array(beat.interferences)
		pending_videos.append_array(beat.videos)
		for video_time: float in pending_videos.duplicate():
			if video_time <= time:
				pending_videos.erase(video_time)
				result["videos"].append(video_time)
				open.append(_task("video", time, time + balance.video_accept_seconds + VIDEO_ATTENTION, VIDEO_ATTENTION, -1))
		var trust: float = result["trust"]
		while director.request_due(time, RequestGenerator.decision_time(night, trust)) and busy.has(false) \
				and active < night.max_simultaneous:
			director.request_started(time)
			var friend := busy.find(false)
			busy[friend] = true
			active += 1
			result["requests"] += 1
			var deadline := time + RequestGenerator.decision_time(night, trust) - QUESTIONS * balance.question_cost
			open.append(_task("request", time, deadline, REQUEST_ATTENTION, friend))
		if director.incident_due(time) and busy.has(false):
			director.incident_started()
			var friend := busy.find(false)
			busy[friend] = true
			open.append(_task("incident", time, time + balance.incident_seconds, INCIDENT_ATTENTION, friend))
		if director.hand_due(time):
			director.hand_started()
			open.append(_task("hand", time, time + balance.hand_approach_seconds, HAND_ATTENTION, -1))
		while director.scare_due(time):
			result["scares"].append([time, director.next_is_jumpscare()])
			director.scare_started(time)
		_work(open, busy, result, balance, time)
		if time >= next_sample:
			result["load"].append(open.size())
			next_sample += 1.0
		time += STEP
	return result


static func _task(kind: String, arrival: float, deadline: float, work: float, friend: int) -> Dictionary:
	return {"kind": kind, "arrival": arrival, "deadline": deadline, "work": work, "friend": friend, "end": -1.0}


## Atiende la tarea que vence primero. Las que vencen sin atender cuentan como perdidas.
static func _work(open: Array[Dictionary], busy: Array[bool], result: Dictionary, balance: BalanceData,
		time: float) -> void:
	if open.is_empty():
		return
	open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["deadline"] < b["deadline"])
	var task: Dictionary = open[0]
	task["work"] -= STEP
	if task["work"] <= 0.0:
		_close(task, open, busy, result, balance, time + STEP)
	for late: Dictionary in open.duplicate():
		if time > late["deadline"]:
			result["missed"] += 1
			_close(late, open, busy, result, balance, time)


static func _close(task: Dictionary, open: Array[Dictionary], busy: Array[bool], result: Dictionary,
		balance: BalanceData, time: float) -> void:
	task["end"] = time
	open.erase(task)
	if task["friend"] >= 0:
		busy[task["friend"]] = false
	result["tasks"].append(task)
	if task["kind"] != "request":
		return
	# Lo que esperó, con lo que le quitaron las preguntas: más allá del plazo de gracia, Trust baja.
	var waited: float = time - task["arrival"] + QUESTIONS * balance.question_cost
	var slow := maxf(waited - balance.slow_answer_grace, 0.0) * balance.slow_answer_trust
	result["trust"] = maxf(result["trust"] - slow, 0.0)
