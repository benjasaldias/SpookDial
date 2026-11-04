extends "res://test/test_case.gd"

const BALANCE_PATH := "res://data/balance.tres"


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
	check_eq(balance.wrong_trust, -10.0, "incorrecta: Trust −10")
	check_eq(balance.no_answer_trust, -15.0, "sin respuesta: Trust −15 extra")
	check_eq(balance.trust_recovery_interval, 8.0, "Trust +1 cada 8 s")
	check_eq(balance.trust_recovery_delay, 20.0, "si no hubo errores en 20 s")
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
	check_eq(balance.audio_sync_bpm, 100.0, "base de Audio Sync a 100 golpes por minuto")
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
	check_eq(balance.first_request_delay, 5.0, "la primera solicitud, a los 5 s")
	check_eq(balance.wave_respite, 25.0, "respiro de 25 s después de cada ola")
	check_eq(balance.wave_tightening, 0.5, "al final, las solicitudes llegan al doble de rápido")
	check_eq(balance.request_min_gap, 6.0, "al menos 6 s entre dos solicitudes")
	check_eq(balance.hurt_respite, 10.0, "un amigo herido atrasa las solicitudes 10 s")
	check_eq(balance.scare_warning, 1.0, "señal previa de 1 s")
	check_eq(balance.scare_margin, 5.0, "nunca en los últimos 5 s de una decisión")
	check_eq(balance.scare_min_gap, 25.0, "al menos 25 s entre dos screamers")
	check_eq(balance.first_scare_after, 30.0, "sin screamers en los primeros 30 s")
	check_eq(balance.scare_sanity, 8.0, "screamer: Sanity −8")
	check_eq(balance.jumpscare_sanity, 15.0, "jumpscare: Sanity −15")
	check_eq(balance.creature_seconds, 4.0, "la criatura se queda 4 s a la vista")
	check_eq(balance.ink_seconds, 5.0, "la mancha de tinta dura 5 s")
	check_eq(balance.hallucination_start, 50.0, "alucinaciones con Sanity bajo 50")
	check_eq(balance.hallucination_slowest, 40.0, "una cada 40 s al empezar")
	check_eq(balance.hallucination_fastest, 10.0, "una cada 10 s con Sanity en 0")
	return true


## Las olas y los screamers de cada noche (docs/02 §6).
func test_olas_y_screamers_de_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var wave_sizes := [2, 3, 3, 4, 4]
	var scare_counts := [2, 4, 4, 5, 6]
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
		var who := "noche %d" % night.number
		check_eq(night.wave_size, wave_sizes[index], who + ": solicitudes por ola")
		check_eq(night.scare_count, scare_counts[index], who + ": screamers")
		check_eq(night.has_jumpscare, night.number >= 2, who + ": un jumpscare desde la noche 2")
		check_eq(night.scripted_scare_time, 0.0, who + ": el susto guionado va en la noche 0")
	check_eq(catalog.tutorial.scripted_scare, ScareKind.Kind.JUMPSCARE, "el susto guionado es un jumpscare")
	return true


## La identificación por preguntas (decisión de Benja, 3 de noviembre): más tiempo por solicitud, menos
## solicitudes por noche (la atención es en serie) y una pista opcional en el mensaje inicial.
func test_identificacion_por_preguntas() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.balance.question_cost, 5.0, "preguntar cuesta 5 s")
	check(catalog.greeting_keys.size() >= 5, "el amigo tiene varios saludos: %d" % catalog.greeting_keys.size())
	var requests := [5, 7, 7, 8, 10]
	var times := [85.0, 80.0, 75.0, 70.0, 65.0]
	var hints := [1.0, 0.75, 0.5, 0.35, 0.2]
	var decoys := [1, 1, 2, 2, 3]
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
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
	var simultaneous := [2, 2, 2, 3, 3]
	var interferences := [1, 3, 3, 4, 6]
	var beats := [4, 4, 4, 8, 8]
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
		var who := "noche %d" % night.number
		check_eq(night.max_simultaneous, simultaneous[index], who + ": solicitudes a la vez")
		check(night.signal_decays, who + ": la señal baja")
		check_eq(night.interference_count, interferences[index], who + ": interferencias")
		check_eq(night.audio_sync_beats, beats[index], who + ": aplausos de Audio Sync")
	return true


## Trust también baja si tardas en contestar (decisión de Benja, 4 de noviembre).
func test_trust_por_tardar() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.slow_answer_grace, 30.0, "30 s de espera sin que Trust baje")
	check_eq(balance.slow_answer_trust, 0.25, "después, Trust baja 0,25 por segundo por solicitud")
	return true
