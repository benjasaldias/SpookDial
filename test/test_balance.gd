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
	var requests := [7, 7, 9, 9, 11]
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
## Semillas por noche: el director y la criatura cambian con cada una.
const SEEDS := 20


## La batería de los flashes, más la que hace falta para reponer Sanity jugando bien, no pasa de 100 %, en las 5 noches
## de cada dificultad.
func test_la_bateria_alcanza_en_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			var needed := BalanceModel.battery_needed(night, catalog.balance)
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
				var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1, difficulty.highlights)
				check_eq(result["missed"], 0, who + ": tareas vencidas")
				check(result["requests"] >= night.total_requests() - 2, "%s: llegan casi todas: %d"
						% [who, result["requests"]])
	return true


## Jugando bien, Trust termina sobre 75: queda espacio para unos errores.
func test_jugando_bien_trust_queda_sobre_75() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			for seed_value in SEEDS:
				var trust: float = BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						difficulty.highlights)["trust"]
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
