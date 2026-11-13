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


## Un video de una calma alcanza a descargarse antes de la ola siguiente: llega a más tardar 25 s antes (15 para
## empezar y 10 de descarga), o al empezar la calma, si es corta.
func test_el_video_no_llega_encima_de_la_ola() -> bool:
	var night := _night()
	var director := _director(night, 12)
	var balance := BalanceData.new()
	director.advance(60.0, 0)
	director.request_started(60.0)
	director.request_started(65.0)
	# La ola se resuelve tarde: la final llega 14 s después de que empieza la calma.
	var calm_start := director.finale_at - 14.0
	director.wave_index = director.waves.size() - 2
	var beat := director.advance(calm_start, 0)
	check(beat.calm_started, "empezó la calma")
	check_eq(beat.videos.size(), 2, "la última calma suelta los 2 videos")
	if beat.videos.size() == 2:
		check_eq(beat.videos[0], calm_start, "con la calma corta, el primero llega enseguida")
	var window := balance.video_accept_seconds + balance.download_seconds
	var long_calm := _run(_director(_night(), 4), _night(), 30.0)
	for index in long_calm["videos"].size():
		var next_wave: float = long_calm["waves"][index + 1][0]
		check(long_calm["videos"][index] <= next_wave - window + 0.5, "llega 25 s antes de la ola siguiente")
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


# --- El plan de olas (docs/26 §3.2): olas armadas a mano, como la noche 1 de Normal.

func _wave(requests: int, videos := 0, spacing := Vector2(30, 45), calm_before := Vector2(30, 45)) -> WaveData:
	var wave := WaveData.new()
	wave.requests = requests
	wave.videos = videos
	wave.spacing = spacing
	wave.calm_before = calm_before
	return wave


## La noche 1 de Normal: 90 s para responder; la ola 1 trae 1 consulta y su video, a los 45 s; la ola 2, 2 consultas
## separadas por 30 a 45 s, la Mano y 1 interferencia; y la final, consulta, video y consulta. Un screamer en cada calma.
func _plan_night() -> NightData:
	var night := NightData.new()
	night.base_decision_time = 90.0
	night.content_quota = 2
	var first := _wave(1, 1, Vector2(30, 45), Vector2(45, 45))
	first.calm_scares = 1
	var second := _wave(2)
	second.hands = 1
	second.interferences = 1
	second.calm_scares = 1
	night.wave_plan.assign([first, second, _wave(2, 1)])
	return night


func test_el_plan_reemplaza_las_olas_automaticas() -> bool:
	var director := _director(_plan_night())
	check_eq(director.waves.size(), 3, "las 3 olas del plan")
	check_eq(director.waves.map(func(wave: PacingDirector.Wave) -> Array: return wave.arrivals),
			[[false, true], [false, false], [false, true, false]], "consultas (false) y videos (true), en orden")
	check(director.waves[-1].finale, "la última es la final")
	check(not director.waves[0].finale and not director.waves[1].finale, "las otras, no")
	return true


func test_la_primera_ola_del_plan_llega_tras_su_calma() -> bool:
	for seed_value in 5:
		var result := _run(_director(_plan_night(), seed_value), _plan_night(), 20.0)
		check_eq(result["arrivals"][0], 45.0, "semilla %d: a los 45 s" % seed_value)
	return true


## Con la consulta abierta, el video llega cuando le quedan 30 s: 60 s después de que llegó.
func test_el_video_llega_cuando_a_la_consulta_le_quedan_30_s() -> bool:
	var result := _run(_director(_plan_night(), 1), _plan_night(), 80.0)
	check_eq(result["videos"][0], 105.0, "a los 45 + 60 s")
	return true


## Si la consulta ya se respondió, el video llega de 3 a 6 s después.
func test_el_video_llega_poco_despues_de_responder() -> bool:
	for seed_value in 5:
		var result := _run(_director(_plan_night(), seed_value), _plan_night(), 20.0)
		var delay: float = result["videos"][0] - 65.0
		check(delay >= 3.0 and delay <= 6.5, "semilla %d: %s s después de responder" % [seed_value, delay])
	return true


func test_las_consultas_de_una_ola_planeada_se_separan() -> bool:
	for seed_value in 5:
		var result := _run(_director(_plan_night(), seed_value), _plan_night(), 20.0)
		var gap: float = result["arrivals"][2] - result["arrivals"][1]
		check(gap >= 30.0 and gap <= 45.5, "semilla %d: la segunda de la ola 2, %s s después" % [seed_value, gap])
	return true


## La calma empieza cuando llegó todo lo de la ola y se respondió, y dura lo que dice la ola siguiente.
func test_la_calma_entre_olas_planeadas() -> bool:
	for seed_value in 5:
		var result := _run(_director(_plan_night(), seed_value), _plan_night(), 20.0)
		var calm: float = result["calms"][0]
		check_eq(calm, result["videos"][0], "semilla %d: la calma empieza con el video" % seed_value)
		var wait: float = result["arrivals"][1] - calm
		check(wait >= 30.0 and wait <= 45.5, "semilla %d: %s s de calma" % [seed_value, wait])
	return true


## La final llega lo más tarde posible: su última consulta llega a más tardar 60 + 45 s después de empezar (el video
## cuando a la primera le quedan 30 s, y la segunda 45 s después) y tiene 90 s, con 10 s de margen para un herido.
func test_la_final_del_plan_llega_lo_mas_tarde_posible() -> bool:
	var night := _plan_night()
	var finale_at := PacingDirector.finale_time(night, BalanceData.new())
	check_eq(finale_at, NIGHT_SECONDS - (60.0 + 45.0 + 90.0) - 10.0, "a las 03:04")
	for seed_value in 5:
		var result := _run(_director(night, seed_value), night, 20.0)
		var finale: Array = result["waves"][-1]
		check(finale[2], "semilla %d: es la final" % seed_value)
		check_eq(finale[0], finale_at, "semilla %d: a su hora" % seed_value)
		var arrivals: Array = result["arrivals"]
		check_eq(arrivals.size(), 5, "semilla %d: las 5 consultas" % seed_value)
		check(arrivals[-1] + 90.0 <= NIGHT_SECONDS, "semilla %d: la última alcanza a terminar" % seed_value)
	return true


## Con la consulta abierta, en la final el video llega a los 60 s y la segunda consulta, de 30 a 45 s después: nunca
## juntos.
func test_en_la_final_nada_llega_junto() -> bool:
	for seed_value in 5:
		var night := _plan_night()
		var result := _run(_director(night, seed_value), night, 80.0)
		var start: float = result["waves"][-1][0]
		var video: float = result["videos"][1]
		check_eq(video, start + 60.0, "semilla %d: el video, a los 60 s" % seed_value)
		var gap: float = result["arrivals"][-1] - video
		check(gap >= 30.0 and gap <= 45.5, "semilla %d: la segunda consulta, %s s después del video" % [seed_value, gap])
	return true


func test_la_mano_y_las_interferencias_de_una_ola_planeada() -> bool:
	var director := _director(_plan_night(), 3)
	var result := _run(director, _plan_night(), 20.0)
	var second: float = result["waves"][1][0]
	check_eq(director.hand_times.size(), 1, "una Mano")
	check_eq(result["interferences"].size(), 1, "una interferencia")
	for time: float in director.hand_times + result["interferences"]:
		check(time >= second + 3.0 and time <= second + 15.5, "%s llega con la ola 2" % time)
	return true


func test_screamers_en_la_calma_de_una_ola_planeada() -> bool:
	var director := _director(_plan_night(), 4)
	var result := _run(director, _plan_night(), 20.0)
	var calms: Array = result["calms"]
	var scares: Array = director.scare_times
	check_eq(scares.size(), 2, "los 2 screamers")
	check_eq(calms.size(), 2, "2 calmas")
	if scares.size() == 2 and calms.size() == 2:
		check(scares[0] >= calms[0] + 5.0 and scares[0] < result["waves"][1][0] + 25.0, "uno en la primera calma")
		check(scares[1] >= calms[1] + 5.0, "otro en la segunda")
	check(not director.scare_creature.has(true), "ninguno es la criatura")
	return true


## Un plan completo pone sus videos dentro de las olas: las calmas no sueltan ninguno.
func test_un_plan_no_suelta_videos_en_las_calmas() -> bool:
	var result := _run(_director(_plan_night(), 6), _plan_night(), 20.0)
	var videos: Array = result["videos"]
	check_eq(videos.size(), 2, "los 2 de la cuota")
	if videos.size() == 2:
		check(videos[0] < result["waves"][1][0], "uno en la ola 1")
		check(videos[1] > result["waves"][2][0], "otro en la final")
	return true


## Una noche puede traer su propia calma entre olas (Plan 9.6: Extremo, de 20 a 30 s), en vez de la de balance.tres. La
## ola se resuelve después de la hora planeada de la siguiente, para que mande la calma.
func test_la_noche_puede_traer_su_calma() -> bool:
	for seed_value in 10:
		var night := _night()
		night.requests_total = 13
		night.wave_calm = Vector2(20, 30)
		var calm := _calm_after_late_wave(night, seed_value)
		check(calm >= 20.0 and calm <= 30.0, "semilla %d: %.1f s de calma" % [seed_value, calm])
	return true


func test_sin_calma_propia_se_usa_la_del_equilibrio() -> bool:
	check_eq(NightData.new().wave_calm, Vector2.ZERO, "por defecto, sin calma propia")
	for seed_value in 10:
		var night := _night()
		night.requests_total = 13
		var calm := _calm_after_late_wave(night, seed_value)
		check(calm >= 40.0 and calm <= 60.0, "semilla %d: la de balance.tres, %.1f s" % [seed_value, calm])
	return true


## Los segundos de calma después de la primera ola, si se resuelve a las 02:00 (140 s), pasada la hora planeada de la
## siguiente.
func _calm_after_late_wave(night: NightData, seed_value: int) -> float:
	var director := _director(night, seed_value)
	director.advance(60.0, 0)
	director.request_started(60.0)
	director.request_started(65.0)
	var beat := director.advance(140.0, 0)
	check(beat.calm_started, "semilla %d: empieza la calma" % seed_value)
	return director.next_at - 140.0


# --- La historia (Plan 9.7, docs/31): el director cuenta sus olas y espera a que la historia termine lo que cuenta.

func test_cuenta_las_olas_y_las_calmas() -> bool:
	var night := _night()
	var director := _director(night)
	check_eq([director.waves_started, director.calms_started, director.finale_started()], [0, 0, false], "al empezar")
	_run(director, night, 10.0)
	check_eq([director.waves_started, director.calms_started, director.finale_started()], [3, 2, true],
			"2 olas comunes con sus calmas y la final")
	return true


func test_la_ultima_ola_comun() -> bool:
	var night := _night()
	var director := _director(night)
	check_eq([director.last_regular_index(), director.finale_index()], [1, 2], "2 olas comunes y la final")
	night.requests_total = 11
	director = _director(night)
	check_eq([director.last_regular_index(), director.finale_index()], [3, 4], "4 olas comunes (Extremo)")
	director = _director(_plan_night())
	check_eq([director.last_regular_index(), director.finale_index()], [1, 2], "con un plan de olas")
	night.finale_size = 0
	night.requests_total = 4
	director = _director(night)
	check_eq([director.last_regular_index(), director.finale_index()], [1, -1], "sin ola final")
	return true


func test_la_ola_espera_a_la_historia() -> bool:
	var director := _director(_night())
	director.story_hold = true
	check_eq(director.advance(60.0, 0).wave_started, -1, "a su hora, la historia todavía cuenta algo")
	check_eq(director.advance(80.0, 0).wave_started, -1, "sigue esperando")
	director.story_hold = false
	check_eq(director.advance(80.5, 0).wave_started, 0, "cuando la historia termina, llega")
	return true


## Benja: la ola espera a la historia a lo más 45 s (S21l).
func test_la_espera_dura_a_lo_mas_45_s() -> bool:
	var director := _director(_night())
	check_eq(BalanceData.new().story_hold_limit, 45.0, "45 s")
	director.story_hold = true
	var started := -1.0
	var time := 0.0
	while started < 0.0 and time < 200.0:
		if director.advance(time, 0).wave_started >= 0:
			started = time
		time += 0.5
	check_eq(started, 105.0, "la ola 1 llega 45 s tarde")
	return true


func test_la_final_espera_a_la_historia() -> bool:
	var night := _night()
	var director := _director(night)
	var time := 0.0
	# Las olas comunes se resuelven enseguida, hasta la calma antes de la final.
	while not (director.phase == PacingDirector.Phase.CALM and director.wave_index == director.finale_index()):
		director.advance(time, 0)
		while director.request_due(time, night.base_decision_time):
			director.request_started(time)
		time += 0.5
	var finale_at := director.finale_at
	director.story_hold = true
	check_eq(director.advance(finale_at, 0).wave_started, -1, "a su hora, espera")
	director.story_hold = false
	var beat := director.advance(finale_at + 20.0, 0)
	check(beat.wave_started == director.finale_index() and beat.finale_started, "llega cuando la historia termina")
	return true


# --- El horario (Plan 9.8): la noche con historia hasta las 06:30, y la final con 5 s de holgura (decisiones de Benja).

## Con historia, la final deja 5 s libres al final en vez de 10 (decisión de Benja: solo en las noches con historia).
func test_con_historia_la_final_deja_5_s() -> bool:
	var night := _night()
	var without := PacingDirector.finale_time(night, BalanceData.new())
	night.story = StoryData.new()
	check_eq(PacingDirector.finale_time(night, BalanceData.new()), without + 5.0, "5 s más tarde")
	return true


func test_en_una_noche_mas_larga_la_final_llega_despues() -> bool:
	var night := _night()
	var short := PacingDirector.finale_time(night, BalanceData.new())
	night.overtime_minutes = 30
	check_eq(PacingDirector.finale_time(night, BalanceData.new()), short + 35.0, "35 s más tarde")
	var director := _director(night)
	check_eq(director.finale_at, short + 35.0, "el director la planea ahí")
	return true


func test_no_empieza_una_consulta_que_no_alcanza_antes_del_final() -> bool:
	var night := _night()
	night.overtime_minutes = 30
	var director := _director(night)
	director.phase = PacingDirector.Phase.FINALE
	director.pending.assign([false])
	director.next_at = 0.0
	check(director.request_due(430.0, 20.0), "a las 06:00 todavía alcanza, porque termina a las 06:30")
	check(not director.request_due(440.0, 20.0), "pasadas las 06:30, no")
	return true
