extends "res://test/test_case.gd"

const HallucinationClock := preload("res://scripts/core/hallucination_clock.gd")


func _clock() -> HallucinationClock:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return HallucinationClock.new(BalanceData.new(), rng)


## Cuántas alucinaciones suenan en `seconds` segundos, de a 1, con Sanity en `sanity`.
func _count(clock: HallucinationClock, seconds: int, sanity: float, allowed := true) -> int:
	var count := 0
	for _i in seconds:
		if clock.advance(1.0, sanity, allowed):
			count += 1
	return count


func test_con_sanity_alta_no_suenan() -> bool:
	check_eq(_count(_clock(), 300, 50.0), 0, "con Sanity en 50, ninguna")
	return true


func test_mas_seguidas_y_mas_fuertes_mientras_mas_baja() -> bool:
	var clock := _clock()
	check(is_equal_approx(clock.interval(50.0), 40.0), "justo bajo 50, cada 40 s")
	check(is_equal_approx(clock.interval(25.0), 25.0), "con 25, cada 25 s")
	check(is_equal_approx(clock.interval(0.0), 10.0), "con 0, cada 10 s")
	check(is_equal_approx(clock.volume_db(50.0), HallucinationClock.QUIET_DB), "justo bajo 50, suaves")
	check(is_equal_approx(clock.volume_db(0.0), HallucinationClock.LOUD_DB), "con 0, fuertes")
	return true


func test_suenan_cada_tanto() -> bool:
	# Con Sanity en 0, cada 10 s ± 25 %: en 120 s, entre 9 y 16.
	var count := _count(_clock(), 120, 0.0)
	check(count >= 9 and count <= 16, "suenan seguido: %d" % count)
	return true


func test_esperan_durante_audio_sync() -> bool:
	var clock := _clock()
	check_eq(_count(clock, 60, 0.0, false), 0, "durante una ronda, ninguna")
	check(clock.advance(1.0, 0.0, true), "al terminar la ronda, suena la que esperaba")
	return true
