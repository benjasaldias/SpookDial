extends "res://test/test_case.gd"

const BALANCE_PATH := "res://data/balance.tres"


## Las noches 1 a 5 de una dificultad del juego. Los valores de antes del primer testeo son los de Difícil.
func _nights(catalog: ContentCatalog, difficulty_id: StringName) -> Array[NightData]:
	return catalog.find_difficulty(difficulty_id).nights


## Los valores iniciales de docs/02 §5.2 y §6.
func test_valores_de_docs_02() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.night_seconds, 420.0, "una noche dura 7 minutos")
	check_eq(balance.friend_health, 3, "3 PV")
	check_eq(balance.stun_seconds, 15.0, "aturdido 15 s")
	check_eq(balance.risky_hurt_chance, 0.7, "mayor riesgo: 70 %")
	check_eq(balance.risky_damage, 2, "mayor riesgo: −2 PV")
	check_eq(balance.risky_trust, -20.0, "mayor riesgo: Trust −20")
	check_eq(balance.wrong_hurt_chance, 0.6, "incorrecta: 60 %")
	check_eq(balance.wrong_damage, 1, "incorrecta: −1 PV")
	check_eq(balance.wrong_trust, -15.0, "incorrecta: Trust −15 (11 de noviembre: Trust ya no se recupera)")
	check_eq(balance.no_answer_trust, -15.0, "sin respuesta: Trust −15 extra")
	check_eq(balance.lost_video_trust, -10.0, "video perdido: Trust −10")
	check(not "trust_recovery_interval" in balance, "Trust ya no se recupera durante la noche")
	return true


## Los valores del mantenimiento (docs/02 §6 y decisiones de Benja del 31 de octubre).
func test_valores_del_mantenimiento() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.scroll_sanity_per_second, 4.0, "scrollear: Sanity +4 por segundo")
	check_eq(balance.scroll_grace, 0.3, "cada movimiento de la rueda cuenta 0,3 s")
	check_eq(balance.interference_damage, 40.0, "interferencia: −40 de señal")
	check_eq(balance.interference_warning, 3.0, "anunciada 3 s antes")
	check_eq(balance.offline_trust_interval, 4.0, "desconectado: Trust −1 cada 4 s por amigo")
	check_eq(balance.audio_sync_round_speedup, 1.15, "cada ronda va un 15 % más rápido que la anterior")
	check_eq(balance.audio_sync_tolerance, 0.15, "tolerancia de ±150 ms")
	check_eq(balance.video_accept_seconds, 15.0, "15 s para empezar a descargar")
	check_eq(balance.video_finish_seconds, 20.0, "20 s para terminar")
	check_eq(balance.download_seconds, 10.0, "la descarga tarda 10 s")
	check_eq(balance.download_slow_seconds, 15.0, "con señal débil, 15 s")
	check_eq(balance.download_slow_below, 50.0, "señal débil: bajo 50")
	return true


## Las pruebas usan BalanceData.new(): sus valores por defecto deben ser los de data/balance.tres.
func test_los_valores_por_defecto_son_los_del_archivo() -> bool:
	var saved: BalanceData = load(BALANCE_PATH)
	var defaults := BalanceData.new()
	for property: Dictionary in defaults.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var property_name: String = property["name"]
			check_eq(saved.get(property_name), defaults.get(property_name), property_name)
	return true


func test_el_catalogo_usa_el_equilibrio() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check(catalog.balance != null, "catalog.tres tiene Balance")
	if catalog.balance != null:
		check_eq(catalog.balance.resource_path, BALANCE_PATH, "es data/balance.tres")
	return true


## Los valores del director, de los screamers y de las alucinaciones (docs/02 §6 y decisiones de Benja del
## 2 de noviembre).
func test_valores_del_director_y_los_screamers() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.first_request_delay, 5.0, "en la noche 0, la primera solicitud a los 5 s")
	check_eq(balance.first_wave_at, 60.0, "el primer minuto es de silencio (11 de noviembre)")
	check_eq(balance.wave_spacing, Vector2(4, 8), "en una ola, de 4 a 8 s entre una solicitud y otra")
	check_eq(balance.wave_calm, Vector2(40, 60), "calma de 40 a 60 s desde que se resuelve la ola")
	check_eq(balance.wave_event_delay, Vector2(3, 15), "lo de una ola llega de 3 a 15 s después de empezar")
	check_eq(balance.calm_event_delay, Vector2(5, 15), "lo de una calma llega de 5 a 15 s después de empezar")
	check_eq(balance.hurt_respite, 10.0, "un amigo herido atrasa las solicitudes 10 s")
	check_eq(balance.story_hold_limit, 45.0, "una ola espera a la historia a lo más 45 s (decisión de Benja, S21l)")
	check_eq(balance.end_pause, 3.0, "la noche termina 3 s después de completarse (Plan 9.9)")
	check_eq(balance.finale_margin, 5.0, "la ola final deja 5 s libres al final (decisión de Benja, Plan 9.8)")
	check_eq(balance.scare_warning, 1.0, "señal previa de 1 s")
	check_eq(balance.scare_margin, 5.0, "nunca en los últimos 5 s de una decisión")
	check_eq(balance.scare_min_gap, 25.0, "al menos 25 s entre dos screamers")
	check_eq(balance.scare_sanity, 8.0, "screamer: Sanity −8")
	check_eq(balance.jumpscare_sanity, 15.0, "jumpscare: Sanity −15")
	check_eq(balance.closed_curtains_sanity, 0.3, "con las cortinas cerradas, Sanity −0,3 por segundo")
	check_eq(balance.creature_sanity, 2.0, "con la criatura a cortina abierta, Sanity −2 por segundo")
	check_eq(balance.creature_stay, Vector2(15, 40), "la criatura se queda de 15 a 40 s afuera (11 de noviembre)")
	check_eq(balance.ink_seconds, 5.0, "la mancha de tinta dura 5 s")
	check_eq(balance.hallucination_start, 50.0, "alucinaciones con Sanity bajo 50")
	check_eq(balance.hallucination_slowest, 40.0, "una cada 40 s al empezar")
	check_eq(balance.hallucination_fastest, 10.0, "una cada 10 s con Sanity en 0")
	return true


## La meta de espera de la nota en cada modo (decisión de Benja, 14 de noviembre): lo que logra quien juega bien.
func test_la_meta_de_espera_de_cada_modo() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.find_difficulty(&"normal").wait_goal, 15.0, "Normal")
	check_eq(catalog.find_difficulty(&"hard").wait_goal, 20.0, "Difícil")
	check_eq(catalog.find_difficulty(&"extreme").wait_goal, 15.0, "Extremo")
	return true


## Las olas y los screamers de cada noche (docs/02 §6). Desde el 11 de noviembre, olas de 2 y una ola final de 3, con
## los 3 amigos a la vez, y la Mano desde la noche 1.
func test_olas_y_screamers_de_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var scare_counts := [2, 4, 4, 5, 6]
	var creature_visits := [0, 1, 2, 2, 3]
	var hand_visits := [1, 1, 2, 2, 3]
	var nights := _nights(catalog, &"hard")
	for index in nights.size():
		var night: NightData = nights[index]
		var who := "noche %d" % night.number
		check_eq(night.wave_size, 2, who + ": solicitudes por ola")
		check_eq(night.finale_size, 3, who + ": la ola final")
		check_eq(night.hand_visits, hand_visits[index], who + ": visitas de la Mano")
		check_eq(night.scare_count, scare_counts[index], who + ": screamers")
		check_eq(night.creature_visits, creature_visits[index], who + ": visitas de la criatura")
		check_eq(night.scripted_scare_time, 0.0, who + ": el susto guionado va en la noche 0")
	check_eq(catalog.tutorial.scripted_scare, ScareKind.Kind.JUMPSCARE, "el susto guionado es un jumpscare")
	check_eq(catalog.tutorial.hand_visits, 0, "la noche 0 enseña la Mano con su guía")
	return true


## La identificación por preguntas (decisión de Benja, 3 de noviembre): menos solicitudes por noche (la atención
## es en serie) y una pista opcional en el mensaje inicial. Desde el 7 de noviembre, el tiempo baja más rápido, no
## hay pista desde la noche 3 y hay más señuelos: acertar a tiempo era demasiado fácil.
func test_identificacion_por_preguntas() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.balance.question_cost, 5.0, "preguntar cuesta 5 s")
	check(catalog.greeting_keys.size() >= 5, "el amigo tiene varios saludos: %d" % catalog.greeting_keys.size())
	# Difícil 5 baja de 11 a 9 (decisión de Benja, 14 de noviembre): antes se saltaba una ola que no cabía, y con las olas
	# en cadena (Plan 9.9) llegarían las 11.
	var requests := [7, 7, 9, 9, 9]
	var times := [80.0, 65.0, 55.0, 50.0, 45.0]
	var hints := [1.0, 0.75, 0.0, 0.0, 0.0]
	var decoys := [1, 2, 3, 3, 4]
	var nights := _nights(catalog, &"hard")
	for index in nights.size():
		var night: NightData = nights[index]
		var who := "noche %d" % night.number
		check_eq(night.requests_total, requests[index], who + ": solicitudes")
		check_eq(night.base_decision_time, times[index], who + ": tiempo para responder")
		check_eq(night.first_hint_chance, hints[index], who + ": probabilidad de pista inicial")
		check_eq(night.decoys_per_request, decoys[index], who + ": señuelos")
	return true


## El mantenimiento de cada noche (docs/02 §6; decisión de Benja, 4 de noviembre: las noches 1 y 2 estaban
## fáciles): la señal baja y hay Audio Sync desde la noche 1.
func test_mantenimiento_de_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var simultaneous := [3, 3, 3, 3, 3]
	var interferences := [1, 3, 3, 4, 6]
	var beats := [4, 4, 4, 8, 8]
	var bpms := [90.0, 100.0, 115.0, 130.0, 145.0]
	var nights := _nights(catalog, &"hard")
	for index in nights.size():
		var night: NightData = nights[index]
		var who := "noche %d" % night.number
		check_eq(night.max_simultaneous, simultaneous[index], who + ": solicitudes a la vez")
		check(night.signal_decays, who + ": la señal baja")
		check_eq(night.interference_count, interferences[index], who + ": interferencias")
		check_eq(night.audio_sync_beats, beats[index], who + ": aplausos de Audio Sync")
		check_eq(night.audio_sync_bpm, bpms[index], who + ": golpes por minuto de Audio Sync")
	check_eq(nights.map(func(night: NightData) -> Vector2: return night.wave_calm),
			[Vector2.ZERO, Vector2(65, 85), Vector2.ZERO, Vector2.ZERO, Vector2(45, 65)],
			"las calmas de Difícil (Plan 9.9: la noche 2 terminaba muy temprano y la 5 se quedaba sin holgura)")
	return true


## Los accidentes de los amigos (decisión de Benja, 7 de noviembre).
func test_accidentes() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.balance.incident_seconds, 15.0, "15 s para responder un accidente")
	check_eq(catalog.balance.incident_damage, 1, "una mala respuesta: −1 PV")
	var counts := [1, 1, 2, 2, 3]
	var nights := _nights(catalog, &"hard")
	for index in nights.size():
		check_eq(nights[index].incident_count, counts[index], "noche %d: accidentes" % (index + 1))
	check_eq(catalog.tutorial.incident_count, 0, "en la noche 0 no hay")
	return true


## Trust también baja si tardas en contestar (decisión de Benja, 4 de noviembre).
func test_trust_por_tardar() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.slow_answer_grace, 30.0, "30 s de espera sin que Trust baje")
	check_eq(balance.slow_answer_trust, 0.25, "después, Trust baja 0,25 por segundo por solicitud")
	return true


## El mensaje inicial dice el lugar solo a veces (decisión de Benja, 11 de noviembre), y cada vez menos. La noche 0
## lo dice siempre, porque enseña.
func test_el_lugar_solo_a_veces() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var chances := [0.6, 0.55, 0.5, 0.45, 0.4]
	var nights := _nights(catalog, &"hard")
	for index in nights.size():
		check_eq(nights[index].place_chance, chances[index], "noche %d" % (index + 1))
	check_eq(catalog.tutorial.place_chance, 1.0, "noche 0")
	check(catalog.predicament_keys.size() >= 6, "varias frases de lo que le pasa: %d" % catalog.predicament_keys.size())
	return true


## "Matías piensa" dura 2 s (decisión de Benja, 11 de noviembre, tras el primer testeo). Los señuelos ya no cuestan.
func test_matias_piensa_2_s() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.thinking_seconds, 2.0, "2 s")
	check(not "decoy_cost" in balance, "el costo del señuelo ya no existe")
	return true


## La Mano (idea de Benja, 11 de noviembre): los valores de partida que confirmó Benja.
func test_la_mano() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.flash_cost, 10.0, "cada flash, 10 % de la batería")
	check_eq(balance.hand_approach_seconds, 12.0, "tarda unos 12 s en llegar al dial")
	check_eq(balance.hand_step_seconds, Vector2(0.5, 0.7), "a tirones de 0,5 a 0,7 s")
	check_eq(balance.hand_drain, 6.0, "agarrado, el dial baja 6 por segundo")
	check_eq(balance.hand_floor, 15.0, "hasta 15, nunca 0")
	check_eq(balance.phone_battery_seconds, 48.0, "la batería alcanza para 48 s de scroll (antes 38)")
	return true


# --- Toda noche se puede ganar (requisito de Benja, 11 de noviembre). El modelo de "jugar bien" está en
# test/balance_model.gd.

const BalanceModel := preload("res://test/balance_model.gd")
const StoryRunner := preload("res://scripts/core/story_runner.gd")
## Semillas por noche: el director y la criatura cambian con cada una.
const SEEDS := 20


## La batería de los flashes, más la que hace falta para reponer Sanity jugando bien, no pasa de 100 %, en las 5 noches
## de cada dificultad. Desde el Plan 9.9, la noche dura lo que tarda en completarse.
func test_la_bateria_alcanza_en_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var length := BalanceModel.night_length(night, catalog.balance, attention)
			var needed := BalanceModel.battery_needed(night, catalog.balance, length)
			check(needed <= 100.0, "%s, noche %d: pide %.1f %% de batería" % [difficulty.id, night.number, needed])
	return true


## Jugando bien, ninguna solicitud, accidente, video ni Mano vence sin atender, ni siquiera en la ola final. En Difícil,
## quien juega bien identifica leyendo.
func test_jugando_bien_nada_vence() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			for seed_value in SEEDS:
				var who := "%s, noche %d, semilla %d" % [difficulty.id, night.number, seed_value + 1]
				var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty))
				check_eq(result["missed"], 0, who + ": tareas vencidas")
				check_eq(result["requests"], night.total_requests(), who + ": llegan todas (Plan 9.9: ninguna ola se salta)")
	return true


## Jugando bien, Trust termina sobre 75: queda espacio para unos errores.
func test_jugando_bien_trust_queda_sobre_75() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			for seed_value in SEEDS:
				var trust: float = BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty))["trust"]
				check(trust >= 75.0, "%s, noche %d, semilla %d: Trust %.1f"
						% [difficulty.id, night.number, seed_value + 1, trust])
	return true


## Trust amenaza de verdad en Difícil: como ya no se recupera, 7 respuestas incorrectas bastan para perder cualquier
## noche, y cada noche tiene al menos esas solicitudes.
func test_trust_amenaza() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var wrong_to_lose := ceili(100.0 / -catalog.balance.wrong_trust)
	check(wrong_to_lose <= 7, "%d incorrectas pierden la noche" % wrong_to_lose)
	for night: NightData in _nights(catalog, &"hard"):
		check(night.total_requests() >= wrong_to_lose, "noche %d: %d solicitudes" % [night.number, night.total_requests()])
	return true


## En Normal hay menos consultas, y las incorrectas solas no alcanzan a vaciar Trust, pero no contestar ninguna pierde
## cualquier noche: cada una baja no_answer_trust más lo que tardó en vencer (con el temporizador más corto, el de Trust
## en 0).
func test_en_normal_sin_contestar_se_pierde() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var balance := catalog.balance
	for night: NightData in _nights(catalog, &"normal"):
		var shortest := night.base_decision_time * 0.6
		var each := -balance.no_answer_trust + maxf(shortest - balance.slow_answer_grace, 0.0) * balance.slow_answer_trust
		var lost := each * night.total_requests()
		check(lost >= 100.0, "noche %d: sin contestar baja %.1f de Trust" % [night.number, lost])
	return true


# --- Normal (decisiones de Benja, 11 de noviembre, tras el primer testeo; docs/26 §3).

## La noche 1 de Normal, armada a mano (docs/26 §3.2): la ola 1 trae 1 consulta y, un poco después, su video; la ola 2,
## 2 consultas separadas, la Mano y 1 interferencia; y la final, consulta, video y consulta, sin llegar juntos. Un
## screamer en cada calma y ningún accidente (D7).
func test_la_noche_1_de_normal() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var night := _nights(catalog, &"normal")[0]
	check(night.has_wave_plan(), "armada a mano")
	if not night.has_wave_plan():
		return true
	var plan := night.wave_plan
	check_eq(plan.map(func(wave: WaveData) -> Array: return wave.arrivals()),
			[[false, true], [false, false], [false, true, false]], "las llegadas de cada ola")
	check_eq(plan.map(func(wave: WaveData) -> int: return wave.hands), [0, 1, 0], "la Mano, en la ola 2")
	check_eq(plan.map(func(wave: WaveData) -> int: return wave.interferences), [0, 1, 0], "la interferencia, en la ola 2")
	check_eq(plan.map(func(wave: WaveData) -> int: return wave.calm_scares), [1, 1, 0], "un screamer en cada calma")
	check_eq(night.total_creatures(), 0, "sin la criatura")
	check_eq(night.total_incidents(), 0, "sin accidentes")
	check_eq(night.base_decision_time, 90.0, "90 s para responder")
	check_eq(night.content_quota, 2, "cuota de 2: los 2 videos del plan")
	check_eq(night.first_hint_chance, 1.0, "siempre con pista")
	check_eq(night.place_chance, 0.8, "el lugar, 80 %")
	check_eq(night.decoys_per_request, 1, "1 señuelo")
	check_eq([night.audio_sync_beats, night.audio_sync_bpm], [4, 90.0], "Audio Sync de 4 aplausos a 90")
	var first_at := 45.0
	if night.story != null:
		var previous := TranslationServer.get_locale()
		TranslationServer.set_locale("es")
		var needs := StoryRunner.story_needs(night.story, Callable(TranslationServer, "translate"),
				catalog.balance.incident_seconds)
		TranslationServer.set_locale(previous)
		first_at = maxf(first_at, needs[StoryBeatData.Moment.NIGHT_START] + needs[StoryBeatData.Moment.BEFORE_FIRST_WAVE])
	for seed_value in SEEDS:
		var who := "semilla %d" % (seed_value + 1)
		var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1)
		var requests: Array = result["tasks"].filter(func(task: Dictionary) -> bool: return task["kind"] == "request")
		requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["arrival"] < b["arrival"])
		var videos: Array = result["videos"]
		check_eq(requests.size(), 5, who + ": las 5 consultas")
		check_eq(videos.size(), 2, who + ": los 2 videos")
		if requests.size() != 5 or videos.size() != 2:
			continue
		# Con la historia en el horario (Plan 9.8), la primera llega a los 45 s o cuando terminan el saludo y el susto.
		check(absf(requests[0]["arrival"] - first_at) <= 0.1, "%s: la primera, a los %.1f s: %s" % [who, first_at,
				requests[0]["arrival"]])
		check(videos[0] >= requests[0]["end"] and videos[0] - requests[0]["arrival"] <= 60.5,
				who + ": el video de la ola 1 llega después de responder, y antes de que le queden 30 s")
		var second_wave: float = requests[2]["arrival"] - requests[1]["arrival"]
		check(second_wave >= 30.0 and second_wave <= 45.5, "%s: la ola 2, separadas %.1f s" % [who, second_wave])
		check(videos[1] >= requests[3]["end"], who + ": en la final, el video llega después de responder la primera")
		var after_video: float = requests[4]["arrival"] - videos[1]
		check(after_video >= 30.0 and after_video <= 45.5, "%s: la segunda, %.1f s después del video" % [who, after_video])
		check(requests[4]["arrival"] - requests[3]["arrival"] < night.base_decision_time,
				who + ": separadas por menos que el tiempo para responder")
	return true


## Las noches 2 a 5 de Normal (docs/26 §3.3): una curva suave, algo más fácil que Difícil. Los screamers no cambian: son
## el terror, no la dificultad.
func test_valores_de_normal() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var nights := _nights(catalog, &"normal")
	var expected := {
		"base_decision_time": [80.0, 70.0, 65.0, 60.0],
		"requests_total": [6, 7, 8, 9],
		"finale_size": [2, 2, 3, 3],
		"decoys_per_request": [1, 2, 2, 3],
		"first_hint_chance": [1.0, 0.75, 0.5, 0.35],
		"place_chance": [0.75, 0.7, 0.65, 0.6],
		"incident_count": [1, 1, 2, 2],
		"interference_count": [2, 2, 3, 4],
		"hand_visits": [1, 1, 2, 2],
		"creature_visits": [1, 1, 2, 2],
		"audio_sync_bpm": [95.0, 105.0, 115.0, 125.0],
		"audio_sync_beats": [4, 4, 4, 8],
		"content_quota": [2, 3, 3, 4],
		"scare_count": [4, 4, 5, 6],
		# Las noches que, en cadena, terminaban antes de las 04:30 (Plan 9.9): sus calmas son más largas.
		"wave_calm": [Vector2(75, 95), Vector2(45, 65), Vector2.ZERO, Vector2.ZERO],
	}
	for index in range(1, nights.size()):
		var night := nights[index]
		check(not night.has_wave_plan(), "noche %d: el director arma sus olas" % night.number)
		for property: String in expected:
			check_eq(night.get(property), expected[property][index - 1], "noche %d: %s" % [night.number, property])
		check_eq(night.wave_size, 2, "noche %d: olas de 2" % night.number)
		check_eq(night.max_simultaneous, 3, "noche %d: 3 a la vez" % night.number)
		check(night.signal_decays, "noche %d: la señal baja" % night.number)
	return true



# --- La holgura (Plan 9.6, docs/30): el modelo de "jugar bien" no cuenta las sincronizaciones ni el scroll como tareas.
# Esta prueba revisa que quepan en el tiempo libre de la noche.

## Cada modo con la atención de quien juega bien: 12 s por consulta en Normal (guiado), 14 en Difícil (leyendo) y 11 en
## Extremo, adonde solo llega un experto que terminó Difícil.
func test_la_atencion_de_cada_modo() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(BalanceModel.attention_for(catalog.find_difficulty(&"normal")), 12.0, "Normal")
	check_eq(BalanceModel.attention_for(catalog.find_difficulty(&"hard")), 14.0, "Difícil")
	var extreme := DifficultyData.new()
	extreme.id = &"extreme"
	extreme.highlights = false
	check_eq(BalanceModel.attention_for(extreme), 11.0, "Extremo: un experto")
	return true


## Lo que dura sincronizar a un amigo: sus rondas de Audio Sync (cuenta, aplausos y respuesta: 24 corcheas por ronda,
## cada una más rápida) más 2 s para abrir el mixer.
func test_lo_que_dura_sincronizar() -> bool:
	var balance := BalanceData.new()
	var night := NightData.new()
	night.audio_sync_beats = 4
	night.audio_sync_bpm = 120.0
	check(is_equal_approx(BalanceModel.sync_seconds(night, balance), 2.0 + 24 * 0.25), "una ronda a 120: 8 s")
	night.audio_sync_beats = 8
	var second_round := 24 * 30.0 / (120.0 * balance.audio_sync_round_speedup)
	check(is_equal_approx(BalanceModel.sync_seconds(night, balance), 2.0 + 24 * 0.25 + second_round), "dos rondas")
	return true


## En toda noche de los 3 modos, el tiempo libre (sin tareas abiertas, desde la primera ola) alcanza para sincronizar a
## los amigos y reponer Sanity con el celular.
func test_toda_noche_tiene_holgura() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var ratio := BalanceModel.free_time_ratio(night, catalog.balance, attention, SEEDS)
			check(ratio >= 1.0, "%s, noche %d: holgura %.2f" % [difficulty.id, night.number, ratio])
	return true


## Difícil 5 es la referencia: Benja la probó y es difícil pero ganable (12 de noviembre). Su holgura queda entre 1 y 1,5.
func test_dificil_5_es_la_referencia() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var hard := catalog.find_difficulty(&"hard")
	var ratio := BalanceModel.free_time_ratio(hard.nights[4], catalog.balance, BalanceModel.attention_for(hard), SEEDS)
	check(ratio >= 1.0 and ratio <= 1.5, "holgura de Difícil 5: %.2f" % ratio)
	return true



# --- Extremo (pedido de Benja, 12 de noviembre; docs/30).

## Los valores de Extremo: olas de 2 más seguidas (calma de 20 a 30 s), menos tiempo y más obstrucciones.
func test_valores_de_extremo() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	if catalog.find_difficulty(&"extreme").id != &"extreme":
		check(false, "no hay Extremo")
		return true
	var nights := _nights(catalog, &"extreme")
	var expected := {
		"requests_total": [11, 13, 13, 15, 15],
		"base_decision_time": [45.0, 42.0, 40.0, 40.0, 38.0],
		"interference_count": [4, 5, 6, 7, 8],
		"hand_visits": [2, 2, 2, 3, 3],
		"creature_visits": [1, 2, 2, 3, 3],
		"scare_count": [4, 5, 5, 6, 6],
		"incident_count": [2, 2, 3, 3, 4],
		"decoys_per_request": [3, 3, 4, 4, 4],
		"place_chance": [0.4, 0.35, 0.3, 0.25, 0.2],
		"audio_sync_bpm": [115.0, 125.0, 135.0, 145.0, 150.0],
		"content_quota": [3, 3, 4, 4, 4],
	}
	for index in nights.size():
		var night := nights[index]
		var who := "noche %d" % night.number
		for property: String in expected:
			check_eq(night.get(property), expected[property][index], "%s: %s" % [who, property])
		check_eq(night.wave_calm, Vector2(30, 40), who + ": calma de 30 a 40 s (Plan 9.9: sin el tiempo muerto del final hacía falta más holgura)")
		check_eq([night.wave_size, night.finale_size, night.max_simultaneous], [2, 3, 3], who + ": olas de 2, la final de 3")
		check_eq(night.first_hint_chance, 0.0, who + ": sin pista")
		check_eq(night.audio_sync_beats, 8, who + ": 8 aplausos")
		# La noche 1 tiene −1 cada 6,5 s (Plan 9.8, cuando duraba hasta las 06:30).
		check_eq(night.sanity_drain_interval, 6.5 if night.number == 1 else 6.0, who + ": Sanity −1 cada 6 s")
		check(night.signal_decays, who + ": la señal baja")
	return true


## Extremo es más duro que Difícil en cada noche: más consultas, menos tiempo para responder, calmas más cortas y más
## obstrucciones, y nunca más pista ni más lugar.
func test_extremo_es_mas_duro_que_dificil() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var hard := _nights(catalog, &"hard")
	var extreme := _nights(catalog, &"extreme")
	if extreme == hard:
		check(false, "no hay Extremo")
		return true
	var calm := catalog.balance.wave_calm
	for index in hard.size():
		var who := "noche %d" % (index + 1)
		for property: String in ["requests_total", "interference_count", "hand_visits", "creature_visits", "scare_count",
				"incident_count", "decoys_per_request", "audio_sync_bpm", "audio_sync_beats", "content_quota"]:
			check(extreme[index].get(property) >= hard[index].get(property), "%s: %s, al menos como Difícil" % [who, property])
		for property: String in ["base_decision_time", "first_hint_chance", "place_chance"]:
			check(extreme[index].get(property) <= hard[index].get(property), "%s: %s, a lo más como Difícil" % [who, property])
		check(extreme[index].base_decision_time < hard[index].base_decision_time, who + ": menos tiempo para responder")
		var hard_calm: Vector2 = hard[index].wave_calm if hard[index].wave_calm != Vector2.ZERO else calm
		check(extreme[index].wave_calm.x < hard_calm.x and extreme[index].wave_calm.y < hard_calm.y,
				who + ": calmas más cortas")
	return true



# --- La historia (Plan 9.7, docs/31): el modelo de "jugar bien" la juega, con sus decisiones como tareas.

## Jugando bien, la historia de cada noche que tiene llega entera en los 3 modos: ningún momento se salta ni se corta.
func test_jugando_bien_la_historia_llega_entera() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var nights := 0
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			if night.story == null:
				continue
			nights += 1
			for seed_value in SEEDS:
				var who := "%s, noche %d, semilla %d" % [difficulty.id, night.number, seed_value + 1]
				var story: Dictionary = BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty), catalog.friends)["story"]
				check_eq([story["skipped"], story["cut"]], [[], []], who + ": momentos saltados y cortados")
				check_eq(story["finished"].size(), night.story.beats.size(), who + ": momentos enteros")
	check(nights >= 3, "la noche 1 de los 3 modos tiene historia: %d noches" % nights)
	return true


## Jugando bien, una ola casi no espera a la historia: a lo más 10 s (el límite es 45).
func test_jugando_bien_la_final_casi_no_espera() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			if night.story == null:
				continue
			for seed_value in SEEDS:
				var hold: float = BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty), catalog.friends)["story_hold"]
				check(hold <= 10.0, "%s, noche %d, semilla %d: una ola esperó %.1f s" % [difficulty.id, night.number,
						seed_value + 1, hold])
	return true



# --- La noche termina cuando se acaba (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33).

## Jugando bien, la noche no deja tiempo muerto al final (el tester de la segunda prueba esperó 1:20 sin nada): termina
## end_pause s después de lo último que había que hacer o, con historia, de que terminan de despedirse.
func test_la_noche_termina_cuando_se_acaba() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			var outro := 0.0
			if night.story != null:
				var needs := StoryRunner.story_needs(night.story, Callable(TranslationServer, "translate"),
						catalog.balance.incident_seconds)
				outro = float(needs.get(StoryBeatData.Moment.AFTER_FINALE, 0.0))
			for seed_value in 5:
				var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty), catalog.friends)
				var last := 0.0
				for task: Dictionary in result["tasks"]:
					last = maxf(last, task["end"])
				var dead: float = result["end"] - last
				check(dead <= outro + catalog.balance.end_pause + 1.0, "%s, noche %d, semilla %d: %.1f s después de lo último"
						% [difficulty.id, night.number, seed_value + 1, dead])
	TranslationServer.set_locale(previous)
	return true


## Jugando bien, ninguna noche termina antes de las 04:30 en promedio (decisión de Benja, 14 de noviembre): donde las olas
## en cadena la dejaban muy corta, sus calmas son más largas.
func test_ninguna_noche_termina_antes_de_las_04_30() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var earliest := catalog.balance.night_seconds * 4.5 / 6.0
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var total := 0.0
			for seed_value in SEEDS:
				total += BalanceModel.simulate(night, catalog.balance, seed_value + 1, attention, catalog.friends)["end"]
			var average := total / SEEDS
			check(average >= earliest, "%s, noche %d: termina a las %s" % [difficulty.id, night.number,
					BalanceModel.clock(average, catalog.balance)])
	return true
