extends "res://test/test_case.gd"
## El director de olas (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## de verdad cuando se resuelven y una ola final grande, lo más tarde posible.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")

const NIGHT_SECONDS := 420.0


## Una noche de prueba: 7 solicitudes (2 olas de 2 y la final de 3), 60 s para responder, 3 interferencias,
## 2 accidentes, 2 visitas de la Mano, 4 screamers (2 de ellos la criatura) y 2 videos de cuota.
func _night() -> NightData:
	var night := NightData.new()
	night.requests_total = 7
	night.wave_size = 2
	night.finale_size = 3
	night.base_decision_time = 60.0
	night.interference_count = 3
	night.incident_count = 2
	night.hand_visits = 2
	night.scare_count = 4
	night.creature_visits = 2
	night.content_quota = 2
	return night


func _director(night: NightData, seed_value := 1) -> PacingDirector:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PacingDirector.new(night, BalanceData.new(), rng)


## Corre la noche de a 0,5 s con un jugador que resuelve cada solicitud `answer_after` segundos después de que llega
## (con amigos de sobra). Devuelve "arrivals" (las horas de llegada), "waves" ([hora, índice, es la final]), "calms"
## (las horas en que empezó cada calma), "interferences" y "videos" (las horas que trajo cada una).
func _run(director: PacingDirector, night: NightData, answer_after: float) -> Dictionary:
	var result := {"arrivals": [], "waves": [], "calms": [], "interferences": [], "videos": []}
	var open: Array[float] = []
	var time := 0.0
	while time < NIGHT_SECONDS:
		open = open.filter(func(end: float) -> bool: return end > time)
		var beat := director.advance(time, open.size())
		if beat.wave_started >= 0:
			result["waves"].append([time, beat.wave_started, beat.finale_started])
		if beat.calm_started:
			result["calms"].append(time)
		result["interferences"].append_array(beat.interferences)
		result["videos"].append_array(beat.videos)
		while director.request_due(time, night.base_decision_time):
			director.request_started(time)
			result["arrivals"].append(time)
			open.append(time + answer_after)
		time += 0.5
	return result


func test_el_primer_minuto_es_de_silencio() -> bool:
	var night := _night()
	var director := _director(night)
	for second in 120:
		director.advance(second * 0.5, 0)
		check(not director.request_due(second * 0.5, 60.0), "a los %s s, nada" % (second * 0.5))
	director.advance(60.0, 0)
	check(director.request_due(60.0, 60.0), "a los 60 s llega la primera ola")
	return true


func test_las_solicitudes_de_una_ola_llegan_juntas() -> bool:
	for seed_value in 10:
		var result := _run(_director(_night(), seed_value), _night(), 30.0)
		var arrivals: Array = result["arrivals"]
		var gap: float = arrivals[1] - arrivals[0]
		check(gap >= 4.0 and gap <= 8.5, "semilla %d: la segunda llega entre 4 y 8 s después: %s" % [seed_value, gap])
	return true


## La calma se cuenta desde que se resuelve la ola, y dura entre 40 y 60 s (o más, si la ola siguiente estaba
## planeada para más tarde).
func test_la_calma_empieza_cuando_se_resuelve_la_ola() -> bool:
	for seed_value in 10:
		var result := _run(_director(_night(), seed_value), _night(), 30.0)
		var arrivals: Array = result["arrivals"]
		var calms: Array = result["calms"]
		var resolved: float = arrivals[1] + 30.0
		check(absf(calms[0] - resolved) <= 0.5, "semilla %d: la calma empieza al resolverse: %s" % [seed_value, calms[0]])
		var next: float = arrivals[2]
		check(next - calms[0] >= 40.0, "semilla %d: al menos 40 s de calma: %s" % [seed_value, next - calms[0]])
	return true


func test_la_ola_final_es_de_3_y_llega_al_final() -> bool:
	var night := _night()
	var finale_at := PacingDirector.finale_time(night, BalanceData.new())
	check_eq(finale_at, NIGHT_SECONDS - 60.0 - 2.0 * 8.0 - 10.0, "la última llega a tiempo, con margen para un herido")
	for seed_value in 10:
		var result := _run(_director(night, seed_value), night, 30.0)
		var arrivals: Array = result["arrivals"]
		var waves: Array = result["waves"]
		check_eq(arrivals.size(), 7, "semilla %d: las 7 solicitudes" % seed_value)
		var last_wave: Array = waves[-1]
		check(last_wave[2], "semilla %d: la última es la final" % seed_value)
		check(absf(last_wave[0] - finale_at) <= 0.5, "semilla %d: a su hora: %s" % [seed_value, last_wave[0]])
		var finale: Array = arrivals.slice(4)
		check_eq(finale.size(), 3, "semilla %d: 3 en la final" % seed_value)
		check(finale[-1] - finale[0] <= 17.0, "semilla %d: juntas" % seed_value)
		check(finale[-1] + 60.0 <= NIGHT_SECONDS, "semilla %d: la última alcanza a terminar" % seed_value)
	return true


## Si el jugador tarda, la ola que ya no cabe antes de la final se salta. La final llega igual.
func test_una_ola_que_no_cabe_se_salta() -> bool:
	var night := _night()
	night.requests_total = 11
	var result := _run(_director(night, 3), night, 60.0)
	var arrivals: Array = result["arrivals"]
	check(arrivals.size() < 11, "no llegan todas: %d" % arrivals.size())
	var waves: Array = result["waves"]
	check(waves[-1][2], "la final llega igual")
	check_eq(arrivals.size() % 2, 1, "las comunes de a 2 y la final de 3")
	return true


func test_nunca_empieza_una_que_no_alcanza() -> bool:
	var night := _night()
	var director := _director(night)
	director.advance(60.0, 0)
	check(not director.request_due(60.0, 361.0), "a los 60 s, una de 361 s no alcanza")
	check(not director.request_due(60.0, 30.0), "la ola se cortó")
	return true


func test_un_amigo_herido_atrasa() -> bool:
	var director := _director(_night())
	director.advance(60.0, 0)
	director.request_started(60.0)
	var next := director.next_at
	director.friend_hurt()
	check_eq(director.next_at, next + 10.0, "la que sigue, 10 s más tarde")
	return true


func test_interferencias_en_las_olas() -> bool:
	var result := _run(_director(_night(), 2), _night(), 30.0)
	var interferences: Array = result["interferences"]
	check_eq(interferences.size(), 3, "las 3 de la noche")
	var waves: Array = result["waves"]
	for time: float in interferences:
		var in_wave := waves.any(func(wave: Array) -> bool: return time >= wave[0] + 3.0 and time <= wave[0] + 15.0)
		check(in_wave, "%s cae entre 3 y 15 s después de empezar una ola" % time)
	var finale_start: float = waves[-1][0]
	check(interferences.any(func(time: float) -> bool: return time >= finale_start), "la final tiene la suya")
	return true


func test_videos_en_las_calmas() -> bool:
	var result := _run(_director(_night(), 4), _night(), 30.0)
	var videos: Array = result["videos"]
	var calms: Array = result["calms"]
	check_eq(videos.size(), 2, "los 2 de la cuota")
	check_eq(calms.size(), 2, "2 calmas, una por ola común")
	for index in videos.size():
		var delay: float = videos[index] - calms[index]
		check(delay >= 5.0 and delay <= 15.0, "el video %d llega 5 a 15 s después de empezar su calma: %s" % [index, delay])
	return true


## Si una calma es la última antes de la final, suelta todos los videos que faltan.
func test_la_ultima_calma_suelta_todos_los_videos() -> bool:
	var night := _night()
	night.requests_total = 5
	night.content_quota = 3
	var result := _run(_director(night, 5), night, 30.0)
	check_eq(result["calms"].size(), 1, "una sola calma")
	check_eq(result["videos"].size(), 3, "con los 3 videos")
	return true


func test_accidentes_en_las_olas_comunes() -> bool:
	var night := _night()
	var director := _director(night, 6)
	var result := _run(director, night, 30.0)
	check_eq(director.incident_times.size(), 2, "los 2, en la cola")
	var waves: Array = result["waves"]
	for time: float in director.incident_times:
		check(time < waves[-1][0], "%s, antes de la final" % time)
	check(director.incident_due(director.incident_times[0]), "a su hora")
	director.incident_started()
	check_eq(director.incident_times.size(), 1, "queda 1")
	return true


func test_la_mano_en_las_olas_comunes() -> bool:
	var night := _night()
	var director := _director(night, 7)
	var result := _run(director, night, 30.0)
	check_eq(director.hand_times.size(), 2, "las 2 visitas")
	var waves: Array = result["waves"]
	check(director.hand_times[0] >= waves[0][0] + 3.0, "llega con una ola")
	check(director.hand_times[-1] < waves[-1][0], "ninguna en la final, que es de la criatura")
	check(not director.hand_due(director.hand_times[0] - 1.0), "todavía no")
	check(director.hand_due(director.hand_times[0]), "a su hora")
	director.hand_started()
	check_eq(director.hand_times.size(), 1, "queda 1")
	return true


func test_screamers_en_las_calmas() -> bool:
	var night := _night()
	var director := _director(night, 8)
	var result := _run(director, night, 30.0)
	check_eq(director.scare_times.size(), 4, "los 4 screamers")
	check_eq(director.scare_creature.count(true), 2, "2 son la criatura")
	var calms: Array = result["calms"]
	var waves: Array = result["waves"]
	for index in director.scare_times.size():
		var time: float = director.scare_times[index]
		if time >= waves[-1][0]:
			check(director.scare_creature[index], "en la final solo llega la criatura")
		else:
			check(calms.any(func(calm: float) -> bool: return time >= calm + 5.0), "%s, en una calma" % time)
	return true


func test_la_criatura_llega_en_la_ola_final() -> bool:
	var night := _night()
	var director := _director(night, 9)
	var result := _run(director, night, 30.0)
	var finale_start: float = result["waves"][-1][0]
	var in_finale := []
	for index in director.scare_times.size():
		if director.scare_times[index] >= finale_start:
			in_finale.append(director.scare_creature[index])
	check_eq(in_finale, [true], "una visita de la criatura en la final")
	return true


func test_los_screamers_esperan_entre_uno_y_otro() -> bool:
	var director := _director(_night())
	director.scare_times.assign([100.0, 110.0])
	director.scare_creature.assign([false, true])
	check(not director.scare_due(99.0), "todavía no")
	check(director.scare_due(100.0), "a su hora")
	check(not director.next_is_jumpscare(), "el primero no es la criatura")
	director.scare_started(100.0)
	check(director.next_is_jumpscare(), "el segundo sí")
	check(not director.scare_due(110.0), "espera 25 s desde el anterior")
	check(director.scare_due(125.0), "a los 25 s, sí")
	return true


func test_el_susto_guionado_espera_un_momento_sin_solicitudes() -> bool:
	var night := _night()
	night.scripted_scare_time = 60.0
	var director := _director(night)
	check(not director.scripted_scare_due(59.0, 0), "todavía no")
	check(not director.scripted_scare_due(60.0, 1), "hay una solicitud: espera")
	check(director.scripted_scare_due(70.0, 0), "sin solicitudes, llega")
	director.scare_times.assign([75.0])
	director.scare_creature.assign([false])
	director.scripted_scare_started(70.0)
	check(not director.scripted_scare_due(80.0, 0), "llega una sola vez")
	check(not director.scare_due(80.0), "el siguiente screamer espera 25 s desde el guionado")
	check(director.scare_due(95.0), "a los 25 s, sí")
	check(not _director(_night()).scripted_scare_due(100.0, 0), "una noche sin susto guionado")
	return true


## La noche 0 no usa las olas: sus solicitudes son fijas.
func test_sin_solicitudes_no_hay_olas() -> bool:
	var night := _night()
	night.requests_total = 0
	var result := _run(_director(night), night, 30.0)
	check_eq(result["arrivals"].size(), 0, "ninguna")
	check_eq(result["waves"].size(), 0, "sin olas")
	return true
