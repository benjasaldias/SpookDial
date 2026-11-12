extends RefCounted
## El modelo de "jugar bien" para la prueba de equilibrio (Plan 9.1, docs/24): Benja pidió que toda noche se pueda
## ganar. No es contenido del juego.
## Quien juega bien ya conoce a las entidades: a cada solicitud le dedica 12 s de atención (14 s en Difícil, donde no
## marca ni espera a Matías, pero lee y busca la página en el índice; Plan 9.4) y le hace 2 preguntas, que le quitan
## 10 s al temporizador; un accidente le toma 4 s, espantar a la Mano 4 s (antes de que agarre) y descargar un
## video 10 s. Atiende de a una tarea, la que vence primero. Cuando llega la criatura, cierra la cortina a los 3 s y la
## revisa 2 veces, 1 s cada vez. Nunca se equivoca ni pierde un video, y quiere terminar con Sanity sobre 10.
## Los valores al azar se toman en su peor caso: la criatura se queda lo más posible.
## En Extremo (Plan 9.6, docs/30) solo llega quien terminó Difícil: un experto que resuelve cada consulta en 11 s.
## El modelo no cuenta como tareas las sincronizaciones ni el scroll del celular: la holgura (free_time_ratio) revisa que
## quepan en el tiempo libre de la noche.
## Desde el Plan 9.7 (docs/31), juega la historia de la noche con el StoryRunner real: leer las líneas no es una tarea
## (es opcional), pero cada decisión sí, como un accidente, y ocupa a su amigo. Quien juega bien elige la buena opción que
## más Trust cuesta, y su castigo vale: Trust y los segundos menos de la próxima consulta de cada castigado. Mientras la
## historia cuenta algo, la próxima ola espera, como en el juego.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
const StoryRunner := preload("res://scripts/core/story_runner.gd")

const REQUEST_ATTENTION := 12.0
## En Difícil se identifica leyendo (decisión de Benja, D3). Con 15 s, la noche 5 de Difícil ya no se puede ganar.
const READING_ATTENTION := 14.0
## En Extremo juega un experto (docs/30). Con 12 s, las noches 4 y 5 de Extremo ya no se pueden ganar.
const EXPERT_ATTENTION := 11.0
## Se sincroniza a un amigo cuando su señal baja de 30 (mucha estática), y se recupera hasta 100.
const SYNC_RECOVERY := 70.0
## Lo que toma abrir el mixer y empezar la ronda, además de la ronda.
const SYNC_OVERHEAD := 2.0
## Corcheas de una ronda de Audio Sync: la cuenta (8), los 4 aplausos del amigo (8) y la respuesta (8).
const SYNC_ROUND_STEPS := 24
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


## Los segundos por consulta de quien juega bien en `difficulty`: guiado (Normal), leyendo (Difícil) o un experto que
## lee (Extremo).
static func attention_for(difficulty: DifficultyData) -> float:
	if difficulty.highlights:
		return REQUEST_ATTENTION
	return EXPERT_ATTENTION if difficulty.id == &"extreme" else READING_ATTENTION


## Lo que dura sincronizar a un amigo: sus rondas de Audio Sync (4 aplausos cada una, cada ronda más rápida) más lo que
## toma abrir el mixer.
static func sync_seconds(night: NightData, balance: BalanceData) -> float:
	var total := SYNC_OVERHEAD
	for index in maxi(night.audio_sync_beats / 4, 1):
		var bpm := night.audio_sync_bpm * pow(balance.audio_sync_round_speedup, index)
		total += SYNC_ROUND_STEPS * 30.0 / bpm
	return total


## Los segundos que quien juega bien necesita fuera de las tareas: sincronizar a los amigos (lo que pierden de señal con
## el tiempo, a su ritmo promedio, y con las interferencias) y scrollear para reponer Sanity.
static func free_time_needed(night: NightData, balance: BalanceData) -> float:
	var loss := night.total_interferences() * balance.interference_damage
	if night.signal_decays:
		var decay := (night.signal_decay_interval.x + night.signal_decay_interval.y) / 2.0
		loss += FRIENDS * balance.night_seconds / decay
	var scroll := scroll_battery(night, balance) / 100.0 * balance.phone_battery_seconds
	return loss / SYNC_RECOVERY * sync_seconds(night, balance) + scroll


## La holgura de la noche con `attention` segundos por consulta: el menor tiempo libre (sin tareas abiertas, desde la
## primera ola) entre `seeds` semillas, dividido por lo que se necesita fuera de las tareas. Con 1 o más, cabe.
static func free_time_ratio(night: NightData, balance: BalanceData, attention: float, seeds: int) -> float:
	var free := INF
	for seed_value in seeds:
		var result := simulate(night, balance, seed_value + 1, attention)
		var first: float = result["waves"][0][0] if not result["waves"].is_empty() else 0.0
		var idle := 0.0
		for second in result["load"].size():
			if second >= first and result["load"][second] == 0:
				idle += 1.0
		free = minf(free, idle)
	var needed := free_time_needed(night, balance)
	return INF if needed <= 0.0 else free / needed


## La batería que gasta quien juega bien en la noche, en %: la que hace falta para reponer Sanity, más un flash por
## cada visita de la Mano. Tiene que ser 100 o menos.
static func battery_needed(night: NightData, balance: BalanceData) -> float:
	return scroll_battery(night, balance) + night.total_hands() * balance.flash_cost


## La batería que hace falta para reponer Sanity, en %.
static func scroll_battery(night: NightData, balance: BalanceData) -> float:
	var to_recover := maxf(sanity_loss(night, balance) - (100.0 - SANITY_MARGIN), 0.0)
	return to_recover / balance.scroll_sanity_per_second / balance.phone_battery_seconds * 100.0


## Cuánta Sanity pierde quien juega bien: con el tiempo, con los screamers y con la criatura (con la cortina abierta
## hasta cerrarla, cerrada mientras se queda y abierta en cada revisión).
static func sanity_loss(night: NightData, balance: BalanceData) -> float:
	var loss := balance.night_seconds / night.sanity_drain_interval
	loss += (night.total_scares() - night.total_creatures()) * balance.scare_sanity
	loss += night.total_creatures() * balance.jumpscare_sanity
	var open := (CREATURE_REACTION + CREATURE_CHECKS * CHECK_SECONDS) * balance.creature_sanity
	loss += night.total_creatures() * (open + balance.creature_stay.y * balance.closed_curtains_sanity)
	return loss


## Corre la noche con el director real y quien juega bien, que dedica `attention` segundos a cada consulta
## (attention_for). Devuelve "missed" (las tareas que vencieron sin atender),
## "trust" (Trust al final: baja por las solicitudes que esperan más de la cuenta y por las decisiones de la historia),
## "requests" (cuántas llegaron), "tasks" (cada una con su tipo, su llegada, su fin y su plazo), "waves" y "calms" (las
## horas en que empezó cada una), "interferences", "videos", "scares" ([hora, es la criatura]), "load" (cuántas tareas
## había abiertas, cada segundo), "story" (los índices de los momentos de la historia enteros, saltados y cortados:
## "finished", "skipped" y "cut") y "story_hold" (lo más que esperó una ola a la historia, en segundos).
## `friends`: los amigos del catálogo, para la historia (sin ellos, los de data/catalog.tres).
static func simulate(night: NightData, balance: BalanceData, seed_value: int,
		attention := REQUEST_ATTENTION, friends: Array[FriendData] = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var director := PacingDirector.new(night, balance, rng)
	var result := {"missed": 0, "trust": 100.0, "requests": 0, "tasks": [], "waves": [], "calms": [],
			"interferences": [], "videos": [], "scares": [], "load": [],
			"story": {"finished": [], "skipped": [], "cut": []}, "story_hold": 0.0}
	var previous_locale := TranslationServer.get_locale()
	var story: StoryRunner = null
	if night.story != null:
		if friends.is_empty():
			friends = (load("res://data/catalog.tres") as ContentCatalog).friends
		# Las líneas tardan lo que tarda en escribirse su texto en español.
		TranslationServer.set_locale("es")
		story = StoryRunner.new(night.story, friends, Callable(TranslationServer, "translate"))
	## Los segundos que la historia le quitó a la próxima consulta de cada amigo.
	var penalty: Array[float] = [0.0, 0.0, 0.0]
	var open: Array[Dictionary] = []
	var busy: Array[bool] = []
	busy.resize(FRIENDS)
	busy.fill(false)
	var pending_videos: Array[float] = []
	var time := 0.0
	var next_sample := 0.0
	while time < balance.night_seconds:
		var active := open.filter(func(task: Dictionary) -> bool: return task["kind"] == "request").size()
		if story != null:
			director.story_hold = story.holds()
			var waiting := director.phase in [PacingDirector.Phase.SILENCE, PacingDirector.Phase.CALM] \
					and director.wave_index < director.waves.size() and time >= director.next_at
			if director.story_hold and waiting:
				result["story_hold"] = maxf(result["story_hold"], time - director.next_at)
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
			deadline -= penalty[friend]
			penalty[friend] = 0.0
			open.append(_task("request", time, deadline, attention, friend))
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
		if story != null:
			_advance_story(story, open, busy, time, director)
		var closed_before: int = result["tasks"].size()
		_work(open, busy, result, balance, time)
		if story != null:
			_resolve_decisions(story, result, closed_before, friends, penalty)
		if time >= next_sample:
			result["load"].append(open.size())
			next_sample += 1.0
		time += STEP
	if story != null:
		TranslationServer.set_locale(previous_locale)
		result["story"] = {"finished": story.finished_beats, "skipped": story.skipped_beats, "cut": story.cut_beats}
	return result


## La historia avanza: con consultas, accidentes o decisiones abiertas está ocupada; la llamada se ve sin eso y sin videos
## por descargar. Una decisión llega como un accidente (15 s, 4 s de atención) y ocupa a su amigo.
static func _advance_story(story: StoryRunner, open: Array[Dictionary], busy: Array[bool], time: float,
		director: PacingDirector) -> void:
	var playing := open.filter(func(task: Dictionary) -> bool: return task["kind"] != "hand")
	var engaged := playing.any(func(task: Dictionary) -> bool: return task["kind"] != "video")
	var is_free := func(friend: int) -> bool: return not busy[friend]
	for item: StoryRunner.Item in story.advance(STEP, time, director, engaged, playing.is_empty(), is_free):
		if item.command != StoryRunner.Command.DECISION:
			continue
		busy[item.friend] = true
		var task := _task("decision", time, time + BalanceData.new().incident_seconds, INCIDENT_ATTENTION, item.friend)
		task["decision"] = item.decision
		open.append(task)


## Las decisiones que terminaron en este paso: quien juega bien eligió la buena opción que más Trust cuesta; si venció,
## la de sin respuesta. Su castigo vale (Trust nunca baja de 1 por la historia), y la historia sigue.
static func _resolve_decisions(story: StoryRunner, result: Dictionary, closed_before: int, friends: Array[FriendData],
		penalty: Array[float]) -> void:
	for task: Dictionary in result["tasks"].slice(closed_before):
		if task["kind"] != "decision":
			continue
		var decision: StoryDecisionData = task["decision"]
		var option := decision.no_answer if task["work"] > 0.0 else worst_good_option(decision)
		var trust: float = result["trust"]
		result["trust"] = clampf(trust + option.trust_change, minf(trust, 1.0), 100.0)
		for friend: FriendData in option.penalized:
			var index := friends.find(friend)
			if index >= 0:
				penalty[index] += option.penalty_seconds
		story.decided(option)


## La buena opción de una decisión que más Trust cuesta (la peor de las buenas): quien juega bien no se equivoca, pero se
## prueba lo más caro que puede elegir.
static func worst_good_option(decision: StoryDecisionData) -> StoryOptionData:
	var worst: StoryOptionData = null
	for option: StoryOptionData in decision.options:
		if option.good and (worst == null or option.trust_change < worst.trust_change):
			worst = option
	return worst


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
