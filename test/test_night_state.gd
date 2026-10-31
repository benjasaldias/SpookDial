extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Estado de la noche 1 del catálogo de prueba: 3 amigos, cuota de 2 videos (a los 140 s y a los 280 s)
## y Sanity que baja 1 punto cada 6 s.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return NightState.new(catalog.nights[0], catalog.balance, catalog.friends.size(), rng)


## Una consecuencia con valores fijos, sin tirar dados.
func _consequence(damage: int, trust_change: float, risky := false) -> Consequence:
	var consequence := Consequence.new(RuleEvaluator.Outcome.CORRECT, true, BalanceData.new(), RandomNumberGenerator.new())
	consequence.damage = damage
	consequence.trust_change = trust_change
	consequence.risky = risky
	return consequence


## Avanza `seconds` de a 1 segundo, como lo haría el juego.
func _advance(state: NightState, seconds: int) -> void:
	for _i in seconds:
		state.advance(1.0)


func test_empieza_a_las_00_con_todo_lleno() -> bool:
	var state := _make_state()
	check_eq(state.clock_text(), "00:00", "hora")
	check_eq(state.sanity, 100.0, "Sanity")
	check_eq(state.trust, 100.0, "Trust")
	check_eq(state.connection(), 100.0, "Connection")
	check_eq(state.friends.size(), 3, "3 amigos")
	check_eq(state.friends[0].health, 3, "3 PV")
	check_eq(state.videos.quota, 2, "cuota de la noche")
	check_eq(state.ending(), NightState.Ending.NONE, "la noche sigue")
	return true


func test_el_reloj_va_de_00_a_06() -> bool:
	var state := _make_state()
	state.advance(210.0)
	check_eq(state.clock_text(), "03:00", "a la mitad")
	state.advance(1.2)
	check_eq(state.clock_text(), "03:01", "un minuto de juego son 1,17 s")
	state.advance(500.0)
	check_eq(state.clock_text(), "06:00", "no pasa de las 06:00")
	check_eq(state.elapsed, 420.0, "segundos")
	return true


func test_sanity_baja_con_el_tiempo() -> bool:
	var state := _make_state()
	state.advance(60.0)
	check(is_equal_approx(state.sanity, 90.0), "−1 cada 6 s: %s" % state.sanity)
	return true


func test_trust_baja_y_se_recupera_sin_errores() -> bool:
	var state := _make_state()
	state.apply(0, _consequence(0, -10.0))
	check_eq(state.trust, 90.0, "−10")
	_advance(state, 20)
	check(is_equal_approx(state.trust, 90.0), "durante 20 s no se recupera: %s" % state.trust)
	_advance(state, 8)
	check(is_equal_approx(state.trust, 91.0), "después, +1 cada 8 s: %s" % state.trust)
	state.apply(0, _consequence(0, -10.0))
	_advance(state, 19)
	check(is_equal_approx(state.trust, 81.0), "un error nuevo reinicia la espera: %s" % state.trust)
	_advance(state, 200)
	check_eq(state.trust, 100.0, "no pasa de 100")
	return true


func test_trust_no_baja_de_0() -> bool:
	var state := _make_state()
	state.trust = 15.0
	state.apply(0, _consequence(0, -20.0))
	check_eq(state.trust, 0.0, "Trust en 0")
	return true


func test_herido_queda_aturdido_y_no_esta_disponible() -> bool:
	var state := _make_state()
	state.apply(1, _consequence(1, -10.0))
	check_eq(state.friends[1].health, 2, "Gonzalo pierde 1 PV")
	check(not state.is_available(1), "aturdido")
	check(state.is_available(0), "León sigue disponible")
	_advance(state, 15)
	check(state.is_available(1), "a los 15 s vuelve")
	return true


func test_los_videos_programados_llegan() -> bool:
	var state := _make_state()
	var arrived: Array[int] = []
	for _i in 140:
		arrived.append_array(state.advance(1.0))
	check_eq(arrived.size(), 1, "el primero a los 140 s")
	check_eq(state.videos.received, 1, "recibido")
	return true


func test_la_accion_de_mayor_riesgo_da_un_video_extra() -> bool:
	var state := _make_state()
	state.apply(2, _consequence(0, -20.0, true))
	check_eq(state.advance(0.1), [2], "llega el video de Agustín")
	return true


func test_herido_envia_el_video_extra_al_recuperarse() -> bool:
	var state := _make_state()
	state.apply(2, _consequence(2, -20.0, true))
	_advance(state, 14)
	check_eq(state.videos.received, 0, "aturdido: todavía no")
	_advance(state, 1)
	check_eq(state.videos.received, 1, "al recuperarse")
	return true


func test_si_muere_se_pierde_la_noche_y_no_hay_video() -> bool:
	var state := _make_state()
	state.friends[0].health = 2
	state.apply(0, _consequence(2, -20.0, true))
	check_eq(state.ending(), NightState.Ending.FRIEND_DIED, "murió León")
	check(state.videos.pending.size() == 2, "sin video extra")
	return true


func test_cada_dial_en_0_pierde_la_noche() -> bool:
	var state := _make_state()
	state.sanity = 0.0
	check_eq(state.ending(), NightState.Ending.SANITY, "Sanity")
	state = _make_state()
	state.trust = 0.0
	check_eq(state.ending(), NightState.Ending.TRUST, "Trust")
	state = _make_state()
	state.friends[0].signal_level = 0.0
	check_eq(state.ending(), NightState.Ending.NONE, "con una señal en 0 no se pierde")
	for friend in state.friends:
		friend.signal_level = 0.0
	check_eq(state.ending(), NightState.Ending.CONNECTION, "con las 3 en 0, sí")
	return true


func test_a_las_06_gana_si_cumplio_la_cuota() -> bool:
	var state := _make_state()
	_advance(state, 420)
	check_eq(state.videos.received, 2, "llegaron los 2 envíos")
	check_eq(state.ending(), NightState.Ending.WON, "ganó")
	state = _make_state()
	state.videos.pending.clear()
	_advance(state, 420)
	check_eq(state.ending(), NightState.Ending.QUOTA, "sin videos, pierde por la cuota")
	return true


func test_la_muerte_se_explica_antes_que_lo_demas() -> bool:
	var state := _make_state()
	state.sanity = 0.0
	state.friends[1].health = 0
	check_eq(state.ending(), NightState.Ending.FRIEND_DIED, "primero la muerte")
	return true


func test_la_vineta_aparece_bajo_60() -> bool:
	var state := _make_state()
	var expected := {100.0: 0.0, 60.0: 0.0, 30.0: 0.5, 0.0: 1.0}
	for sanity: float in expected:
		state.sanity = sanity
		check(is_equal_approx(state.vignette_strength(), expected[sanity]), "Sanity %s" % sanity)
	return true
