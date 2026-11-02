extends "res://test/test_case.gd"

const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")


## Ronda de `beats` aplausos a 100 golpes por minuto (corcheas de 0,3 s), con ±0,15 s de tolerancia.
func _round(beats := 4, seed_value := 6) -> AudioSyncRound:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return AudioSyncRound.new(beats, 100.0, 0.15, rng)


## Avanza la ronda hasta `time` segundos desde que empezó. Devuelve las corcheas a las que llegó.
func _advance_to(sync_round: AudioSyncRound, time: float) -> Array[int]:
	return sync_round.advance(time - sync_round.elapsed)


## Golpea en cada aplauso del patrón, `offset` segundos después de su hora.
func _tap_pattern(sync_round: AudioSyncRound, offset: float) -> void:
	for call_step: int in sync_round.pattern:
		_advance_to(sync_round, sync_round.response_start() + call_step * sync_round.step_seconds + offset)
		sync_round.tap()


func test_el_patron() -> bool:
	for beats: int in [4, 8]:
		for seed_value in 20:
			var sync_round := _round(beats, seed_value)
			var unique := {}
			for step: int in sync_round.pattern:
				unique[step] = true
			check_eq(unique.size(), beats, "%d aplausos distintos" % beats)
			check_eq(sync_round.pattern[0], 0, "el primero, al comienzo")
			check(sync_round.pattern[-1] < beats * 2, "dentro de sus %d corcheas" % (beats * 2))
			var sorted := sync_round.pattern.duplicate()
			sorted.sort()
			check_eq(sync_round.pattern, sorted, "en orden")
	return true


func test_las_partes_de_la_ronda() -> bool:
	var sync_round := _round()
	check_eq(sync_round.step_seconds, 0.3, "una corchea a 100 golpes por minuto")
	check_eq(sync_round.total_steps(), 24, "la cuenta, el amigo y Matías: 8 corcheas cada uno")
	check_eq(sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "empieza con la cuenta")
	_advance_to(sync_round, 2.4)
	check_eq(sync_round.phase(), AudioSyncRound.Phase.CALL, "a los 2,4 s aplaude el amigo")
	_advance_to(sync_round, 4.7)
	check_eq(sync_round.phase(), AudioSyncRound.Phase.RESPONSE, "0,1 s antes de los 4,8 s, le toca a Matías")
	return true


func test_suenan_la_base_y_los_aplausos() -> bool:
	var sync_round := _round()
	check_eq(_advance_to(sync_round, 4.75), range(16), "las 16 corcheas de la cuenta y del amigo, en orden")
	check_eq(range(16).filter(sync_round.is_beat), [0, 2, 4, 6, 8, 10, 12, 14], "la base, en cada golpe")
	check_eq(range(24).filter(sync_round.is_accent), [0, 8, 16], "más fuerte al empezar cada compás")
	var claps := range(24).filter(sync_round.is_clap).map(func(step: int) -> int: return step - 8)
	check_eq(claps, sync_round.pattern, "el amigo aplaude su patrón, después de la cuenta")
	return true


func test_si_repite_el_ritmo_sale_bien() -> bool:
	var sync_round := _round()
	_tap_pattern(sync_round, 0.1)
	check(sync_round.succeeded, "con golpes 0,1 s tarde, sale bien")
	check_eq(sync_round.phase(), AudioSyncRound.Phase.DONE, "y termina")
	check_eq(sync_round.hits(), sync_round.pattern, "acertó todos")
	sync_round = _round()
	_tap_pattern(sync_round, -0.1)
	check(sync_round.succeeded, "0,1 s antes, también")
	return true


func test_un_golpe_de_mas_sale_mal() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, sync_round.response_start())
	check_eq(sync_round.tap(), AudioSyncRound.Tap.HIT, "el primero, a tiempo")
	check_eq(sync_round.tap(), AudioSyncRound.Tap.MISS, "otro golpe en el mismo aplauso sobra")
	check(sync_round.failed and sync_round.phase() == AudioSyncRound.Phase.DONE, "sale mal")
	return true


func test_si_se_le_pasa_un_aplauso_sale_mal() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, sync_round.response_start() + 0.16)
	check(sync_round.failed, "no golpeó el primero")
	check_eq(sync_round.advance(1.0), [], "terminó: ya no suena nada")
	return true


func test_los_golpes_antes_de_su_parte_no_cuentan() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, 1.0)
	check_eq(sync_round.tap(), AudioSyncRound.Tap.IGNORED, "en la cuenta")
	_advance_to(sync_round, 3.0)
	check_eq(sync_round.tap(), AudioSyncRound.Tap.IGNORED, "mientras aplaude el amigo")
	check(not sync_round.failed, "no sale mal")
	_tap_pattern(sync_round, 0.0)
	check(sync_round.succeeded, "y después puede repetirlo")
	return true


func test_con_8_aplausos_dura_dos_compases() -> bool:
	var sync_round := _round(8)
	check_eq(sync_round.steps, 16, "16 corcheas para el amigo")
	check(is_equal_approx(sync_round.response_start(), 7.2), "Matías empieza a los 7,2 s")
	_tap_pattern(sync_round, 0.05)
	check(sync_round.succeeded, "sale bien")
	return true
