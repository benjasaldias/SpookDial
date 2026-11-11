extends "res://test/test_case.gd"
## Una visita de la Mano (idea de Benja, 11 de noviembre): asoma por la derecha y avanza a tirones hacia un dial.

const HandVisit := preload("res://scripts/core/hand_visit.gd")
const NightState := preload("res://scripts/core/night_state.gd")

## El dial de Connection, como en la escena.
const DIAL := Vector2(840, 89)


func _visit(seed_value := 1) -> HandVisit:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return HandVisit.new(NightState.Dial.CONNECTION, BalanceData.new(), rng)


## Avanza de a 0,05 s hasta que agarra el dial. Devuelve los segundos que tardó y cuántos tirones dio.
func _until_grab(visit: HandVisit) -> Vector2:
	var time := 0.0
	var jerks := 0
	while not visit.is_grabbing() and time < 60.0:
		if visit.advance(0.05):
			jerks += 1
		time += 0.05
	return Vector2(time, jerks)


func test_avanza_a_tirones() -> bool:
	var visit := _visit()
	var before := visit.position(DIAL)
	check(not visit.advance(0.4), "a los 0,4 s, todavía nada: cada tirón tarda de 0,5 a 0,7 s")
	check_eq(visit.position(DIAL), before, "sin tirón, no se mueve")
	check(visit.advance(0.35), "a los 0,75 s, ya dio el primero")
	check(visit.position(DIAL).x < before.x, "y avanzó hacia la izquierda")
	return true


func test_llega_al_dial_en_unos_12_s() -> bool:
	for seed_value in 10:
		var result := _until_grab(_visit(seed_value))
		check(result.x >= 10.0 and result.x <= 14.0, "semilla %d: en %s s" % [seed_value, result.x])
		check_eq(int(result.y), 20, "semilla %d: 20 tirones" % seed_value)
	var visit := _visit()
	_until_grab(visit)
	check_eq(visit.position(DIAL), Vector2i(836, 95), "agarrada, queda donde dice la maqueta")
	return true


## Pixel art: siempre en posiciones enteras (regla 10). Empieza fuera de la pantalla.
func test_las_posiciones_son_enteras() -> bool:
	var visit := _visit()
	check_eq(visit.position(DIAL).x, 1280, "empieza afuera, en el borde derecho")
	var xs := []
	while not visit.is_grabbing():
		if visit.advance(0.05):
			xs.append(visit.position(DIAL).x)
	for index in xs.size() - 1:
		check(xs[index + 1] < xs[index], "siempre avanza")
	check(typeof(visit.position(DIAL).x) == TYPE_INT, "enteras")
	return true


func test_los_cuadros_se_alternan() -> bool:
	var visit := _visit()
	var frames := [visit.frame]
	for _jerk in 4:
		while not visit.advance(0.05):
			pass
		frames.append(visit.frame)
	check_eq(frames, [0, 1, 2, 0, 1], "0, 1, 2, 0… en cada tirón")
	return true


func test_agarrada_sigue_tironeando_sin_avanzar() -> bool:
	var visit := _visit()
	_until_grab(visit)
	check_eq(visit.frame, 0, "agarra con el cuadro 0, el de la maqueta")
	var position := visit.position(DIAL)
	var jerks := 0
	for _step in 40:
		if visit.advance(0.05):
			jerks += 1
	check(jerks >= 2, "sigue tironeando: %d" % jerks)
	check_eq(visit.position(DIAL), position, "sin moverse del dial")
	check_eq(visit.frame, 0, "con el mismo cuadro")
	return true
