extends "res://test/test_case.gd"
## La historia en curso (Plan 9.7, docs/31): sus momentos con el director real, la llamada, separarse y reunirse, y las
## decisiones.

const Fixtures := preload("res://test/content_fixtures.gd")
const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const StoryRunner := preload("res://scripts/core/story_runner.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")

const STEP := 0.5
## Cada texto de la traducción falsa tiene 60 letras y 10 palabras: se escribe en 1 s, se lee en 2 s (5 palabras por
## segundo) y espera 0,5 s más (Plan 9.10).
const LINE_TEXT := "xxxxx xxxxx xxxxx xxxxx xxxxx xxxxx xxxxx xxxxx xxxxx xxxxxx"
const LINE_SECONDS := 3.5


## La noche de los pasos de la historia: lo que pasa cada 0,5 s con el director real y un jugador que resuelve cada
## consulta `answer_after` segundos después de que llega.
class Sim:
	var director: PacingDirector
	var runner: StoryRunner
	var night: NightData
	var time := 0.0
	var answer_after := 10.0
	## Las horas en que terminan las consultas abiertas.
	var open: Array[float] = []
	## Lo que devolvió la historia: [hora, Item].
	var items: Array = []
	var wave_times: Array[float] = []
	var calm_times: Array[float] = []
	## La llamada se puede ver (sin nada que jugar) y cada amigo está libre.
	var call_free := true
	var free: Array[bool] = [true, true, true]
	## Hay algo abierto, además de las consultas.
	var busy_override := false

	func run_until(end: float) -> void:
		while time < end:
			open = open.filter(func(finish: float) -> bool: return finish > time)
			director.story_hold = runner.holds()
			var beat := director.advance(time, open.size())
			if beat.wave_started >= 0:
				wave_times.append(time)
			if beat.calm_started:
				calm_times.append(time)
			while director.request_due(time):
				director.request_started(time)
				open.append(time + answer_after)
			var busy := not open.is_empty() or busy_override
			var is_free := func(friend: int) -> bool: return free[friend]
			for item: StoryRunner.Item in runner.advance(STEP, time, director, busy, call_free and not busy, is_free):
				items.append([time, item])
			time += STEP

	## Las horas y las claves de las líneas, en orden.
	func lines() -> Array:
		return items.filter(func(entry: Array) -> bool: return entry[1].command != StoryRunner.Command.DECISION) \
				.map(func(entry: Array) -> Array: return [entry[0], entry[1].key])

	## La hora en que llegó la línea `key`, o -1.
	func time_of(key: String) -> float:
		for entry: Array in items:
			if entry[1].key == key:
				return entry[0]
		return -1.0

	func item_of(key: String) -> StoryRunner.Item:
		for entry: Array in items:
			if entry[1].key == key:
				return entry[1]
		return null


var _catalog: ContentCatalog = Fixtures.make_catalog()


## Una noche con 2 olas comunes de 2 y la final de 3, como Normal y Difícil (o `requests` consultas: 11 son 4 olas comunes,
## como Extremo).
func _night(requests := 7) -> NightData:
	var night := NightData.new()
	night.requests_total = requests
	night.wave_size = 2
	night.finale_size = 3
	night.base_decision_time = 60.0
	return night


func _sim(story: StoryData, night: NightData = null, seed_value := 3) -> Sim:
	var sim := Sim.new()
	sim.night = night if night != null else _night()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	sim.director = PacingDirector.new(sim.night, BalanceData.new(), rng)
	var translate := func(_key: String) -> String: return LINE_TEXT
	sim.runner = StoryRunner.new(story, _catalog.friends, translate)
	return sim


## Una historia de un solo momento con estos pasos.
func _story(moment: StoryBeatData.Moment, steps: Array, together := true, lead := 15.0) -> StoryData:
	var story := StoryData.new()
	story.starts_together = together
	story.beats.append(Fixtures.make_beat(moment, steps, lead))
	return story


func _line(friend: int, key: String) -> StoryStepData:
	return Fixtures.make_line(_catalog.friends[friend], key)


func _decision() -> StoryStepData:
	var step := Fixtures.make_step(StoryStepData.Kind.DECISION)
	step.decision = Fixtures.make_decision(_catalog.friends[0], _catalog.friends[2])
	return step


func test_la_noche_empieza_con_la_llamada() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	check(sim.runner.together, "empiezan juntos")
	sim.run_until(1.0)
	check_eq(sim.items.size(), 1, "una línea")
	if sim.items.size() == 1:
		var item: StoryRunner.Item = sim.items[0][1]
		check_eq([sim.items[0][0], item.command, item.friend, item.key], [0.0, StoryRunner.Command.CALL_LINE, 0,
				"K_STORY_HELLO"], "León saluda en la llamada al empezar")
	return true


func test_las_lineas_esperan_lo_que_tardan_en_escribirse() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_line(0, "K_A"), _line(1, "K_B"), _line(2, "K_C")]))
	sim.run_until(13.0)
	check_eq(sim.lines(), [[0.0, "K_A"], [LINE_SECONDS, "K_B"], [LINE_SECONDS * 2, "K_C"]], "una cada %s s" % LINE_SECONDS)
	check(sim.runner.is_done(), "terminó")
	return true


func test_antes_de_la_ola_llega_con_su_anticipacion() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	sim.run_until(70.0)
	check_eq(sim.time_of("K_STORY_SCARE"), 45.0, "15 s antes de la primera ola, que llega a los 60 s")
	var other := _sim(_story(StoryBeatData.Moment.BEFORE_FIRST_WAVE, [_line(1, "K_A")], true, 25.0))
	other.run_until(70.0)
	check_eq(other.time_of("K_A"), 35.0, "con 25 s de anticipación")
	return true


func test_separarse_lleva_las_lineas_a_cada_chat() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	sim.run_until(70.0)
	check_eq(sim.item_of("K_STORY_SCARE").command, StoryRunner.Command.CALL_LINE, "el grito, en la llamada")
	var alone := sim.item_of("K_STORY_ALONE")
	check(alone != null, "Agustín escribe")
	if alone != null:
		check_eq([alone.command, alone.friend], [StoryRunner.Command.LINE, 2], "en su propio chat")
		check_eq(sim.time_of("K_STORY_ALONE"), 45.0 + LINE_SECONDS, "después del grito")
	check(not sim.runner.together, "separados")
	return true


func test_despues_de_la_primera_ola_en_la_primera_calma() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.AFTER_FIRST_WAVE, [_line(0, "K_A")], false))
	sim.run_until(300.0)
	check(not sim.calm_times.is_empty(), "hubo una calma")
	if not sim.calm_times.is_empty():
		check_eq(sim.time_of("K_A"), sim.calm_times[0], "al empezar la primera calma")
	return true


func test_la_reunion_en_la_calma_antes_de_la_final() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	sim.run_until(420.0)
	var decisions := sim.items.filter(func(entry: Array) -> bool:
		return entry[1].command == StoryRunner.Command.DECISION)
	check_eq(decisions.size(), 1, "una decisión")
	check_eq(sim.calm_times.size(), 2, "2 calmas")
	if decisions.size() == 1 and sim.calm_times.size() == 2:
		var item: StoryRunner.Item = decisions[0][1]
		check_eq([decisions[0][0], item.friend, item.key], [sim.calm_times[1], 0, "K_STORY_ASK"],
				"León decide al empezar la calma antes de la final")
		check(item.decision != null, "con sus datos")
	check(sim.runner.deciding, "espera la respuesta")
	return true


## En Extremo, la "ola 2" de la historia es la última ola común: en las calmas del medio no hay historia (docs/21 §2).
func test_en_extremo_las_olas_del_medio_no_tienen_historia() -> bool:
	var night := _night(11)
	night.wave_calm = Vector2(20, 30)
	var story := StoryData.new()
	story.starts_together = false
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_FIRST_WAVE, [_line(0, "K_A")]))
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.BEFORE_LAST_WAVE, [_line(0, "K_B")]))
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_LAST_WAVE, [_line(0, "K_C")]))
	var sim := _sim(story, night)
	sim.run_until(420.0)
	check_eq(sim.wave_times.size(), 5, "4 olas comunes y la final")
	check_eq(sim.lines().size(), 3, "3 líneas: %s" % str(sim.lines()))
	if sim.wave_times.size() == 5 and sim.calm_times.size() >= 4:
		check_eq(sim.time_of("K_A"), sim.calm_times[0], "en la primera calma")
		var before := sim.wave_times[3] - sim.time_of("K_B")
		check(before >= 14.5 and before <= 15.5, "15 s antes de la cuarta ola: %.1f" % before)
		check_eq(sim.time_of("K_C"), sim.calm_times[3], "en la calma antes de la final")
	return true


## Con las olas en cadena (Plan 9.9), un jugador lento no se salta ninguna ola: lo de antes de la última ola común llega
## igual, y se reúnen ahí.
func test_un_jugador_lento_no_se_salta_la_historia() -> bool:
	var night := _night(11)
	var story := StoryData.new()
	story.starts_together = false
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.BEFORE_LAST_WAVE,
			[Fixtures.make_step(StoryStepData.Kind.JOIN), _line(0, "K_B")]))
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_LAST_WAVE, [_line(1, "K_C")]))
	var sim := _sim(story, night)
	sim.answer_after = 40.0
	sim.run_until(1200.0)
	check_eq(sim.wave_times.size(), 5, "las 5 olas: ninguna se salta")
	check(sim.time_of("K_B") >= 0.0, "lo de antes de la última ola común llega")
	check_eq(sim.runner.skipped_beats, [], "nada se salta")
	var after := sim.item_of("K_C")
	check(after != null and after.command == StoryRunner.Command.CALL_LINE, "se reunieron: la llamada en la calma antes de la final")
	return true


func test_un_momento_que_se_cierra_corta_sus_lineas_pero_se_reunen() -> bool:
	# 40 líneas (160 s): empiezan apenas empieza la noche y no alcanzan, ni con los 45 s de espera.
	var steps := []
	for index in 40:
		steps.append(_line(0, "K_%d" % index))
	steps.append(Fixtures.make_step(StoryStepData.Kind.JOIN))
	var sim := _sim(_story(StoryBeatData.Moment.BEFORE_FIRST_WAVE, steps, false, 2.0))
	sim.run_until(120.0)
	check_eq(sim.wave_times[0], 60.0 + 45.0, "la ola espera 45 s y llega")
	check(sim.lines().size() < 40, "las líneas que faltaban no llegan: %d" % sim.lines().size())
	check_eq(sim.runner.cut_beats, [0], "se cortó")
	check(sim.runner.together, "pero se reunieron")
	check(not sim.runner.holds(), "y ya no hace esperar")
	return true


## Con las olas en cadena (Plan 9.9), la final ya no llega encima de la ola 2: espera a que se resuelva. Aun un jugador
## muy lento recibe la reunión y su decisión (antes se saltaban; decisión de Benja en S21l).
func test_un_jugador_muy_lento_igual_recibe_la_decision() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	sim.answer_after = 200.0
	sim.run_until(1500.0)
	check_eq(sim.calm_times.size(), 2, "las 2 calmas")
	check_eq(sim.items.filter(func(entry: Array) -> bool: return entry[1].command == StoryRunner.Command.DECISION).size(),
			1, "la decisión llega")
	check(not sim.runner.skipped_beats.has(2), "la reunión no se salta")
	return true


func test_la_llamada_espera_a_que_se_vea() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_line(0, "K_A")]))
	sim.call_free = false
	sim.run_until(10.0)
	check(sim.items.is_empty(), "con algo que jugar, la llamada no se ve y la línea espera")
	check(sim.runner.holds(), "mientras tanto, la ola espera")
	sim.call_free = true
	sim.run_until(11.0)
	check_eq(sim.time_of("K_A"), 10.0, "llega cuando la llamada se ve")
	var separated := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_line(0, "K_A")], false))
	separated.call_free = false
	separated.run_until(1.0)
	check_eq(separated.time_of("K_A"), 0.0, "en su propio chat no espera")
	return true


func test_la_decision_espera_a_que_el_amigo_este_libre() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_decision()], false))
	sim.free[0] = false
	sim.run_until(10.0)
	check(sim.items.is_empty(), "León está ocupado, aturdido o sin señal: espera")
	check(sim.runner.holds(), "y la ola espera")
	sim.free[0] = true
	sim.run_until(11.0)
	check_eq(sim.items.size(), 1, "llega")
	if sim.items.size() == 1:
		check_eq([sim.items[0][0], sim.items[0][1].command], [10.0, StoryRunner.Command.DECISION], "cuando está libre")
	return true


func test_la_decision_espera_la_respuesta_y_trae_sus_lineas() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_decision(), _line(1, "K_AFTER")], false))
	sim.run_until(10.0)
	check_eq(sim.items.size(), 1, "solo la decisión")
	var decision: StoryDecisionData = sim.items[0][1].decision
	var replies := sim.runner.decided(decision.options[0])
	check(not sim.runner.deciding, "ya no espera")
	check_eq(replies.map(func(item: StoryRunner.Item) -> Array: return [item.command, item.friend, item.key]),
			[[StoryRunner.Command.LINE, 0, "K_STORY_GOOD_REPLY"]], "León responde en su chat")
	sim.run_until(20.0)
	# Matías respondió entre 2 pasos: el siguiente ya descuenta su medio segundo.
	check_eq(sim.time_of("K_AFTER"), 10.0 + LINE_SECONDS - STEP, "lo que sigue espera su respuesta")
	return true


func test_las_marcas_eligen_las_lineas_y_las_decisiones() -> bool:
	var solo := _line(2, "K_SOLO")
	solo.unless_flag = &"with_agustin"
	var duo := _line(2, "K_DUO")
	duo.requires_flag = &"with_agustin"
	for good: bool in [true, false]:
		var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, [_decision(), duo, solo], false))
		sim.run_until(1.0)
		var decision: StoryDecisionData = sim.items[0][1].decision
		sim.runner.decided(decision.options[0 if good else 1])
		sim.run_until(10.0)
		check_eq(sim.lines().map(func(line: Array) -> String: return line[1]), ["K_DUO"] if good else ["K_SOLO"],
				"la buena deja la marca" if good else "la mala no")
		check_eq(sim.runner.flags, [&"with_agustin"] if good else [], "las marcas")
	return true


func test_el_cierre_espera_a_que_no_quede_nada() -> bool:
	var sim := _sim(_story(StoryBeatData.Moment.AFTER_FINALE, [_line(0, "K_BYE")], true))
	sim.busy_override = true
	sim.run_until(400.0)
	check(sim.director.finale_started(), "empezó la final")
	check_eq(sim.time_of("K_BYE"), -1.0, "con algo abierto, no se despiden")
	sim.busy_override = false
	sim.run_until(410.0)
	check_eq(sim.time_of("K_BYE"), 400.0, "cuando no queda nada, sí")
	return true


func test_mientras_cuenta_algo_la_ola_espera() -> bool:
	var steps := []
	for index in 25:
		steps.append(_line(0, "K_%d" % index))
	var sim := _sim(_story(StoryBeatData.Moment.NIGHT_START, steps, false))
	sim.run_until(130.0)
	# La ola mira la historia antes de que avance: llega en el paso siguiente al que termina.
	check_eq(sim.wave_times[0], 25 * LINE_SECONDS + STEP, "la primera ola espera las 25 líneas (%s s)" % (25 * LINE_SECONDS))
	check(not sim.runner.holds(), "terminó y ya no hace esperar")
	return true


# --- La historia en el horario (Plan 9.8): el vlog al doble de lento y lo que dura cada momento.

## Una línea dura lo que tarda en escribirse (60 letras por segundo, como el chat), lo que se tarda en leer sus palabras
## (5 por segundo) y 0,5 s más, y nunca menos de 2 s (Plan 9.10: pedido de Benja, quedaba esperando después de leer).
func test_una_linea_dura_lo_que_se_tarda_en_leerla() -> bool:
	check_eq(StoryRunner.line_seconds(LINE_TEXT), LINE_SECONDS, "60 letras y 10 palabras: 1 + 2 + 0,5 s")
	var intro := "Hoy vamos a una cabaña en medio del campo, donde dicen que penan el Tue Tué y la Calchona"
	var expected := intro.length() / 60.0 + 19 / 5.0 + 0.5
	check(is_equal_approx(StoryRunner.line_seconds(intro), expected), "19 palabras: %.1f s" % StoryRunner.line_seconds(intro))
	check_eq(StoryRunner.line_seconds("hola"), 2.0, "una corta, 2 s")
	check_eq(StoryRunner.TYPING_CHARS_PER_SECOND, ChatMessageView.CHARS_PER_SECOND, "se escribe como en el chat")
	return true


## Lo que dura cada momento: sus líneas y, por decisión, la pregunta, su tiempo completo y la respuesta más larga. De 2
## pasos que se excluyen (uno con una marca y otro sin ella), cuenta el más largo. Un momento "antes de" suma 2 s.
func test_lo_que_dura_cada_momento() -> bool:
	var translate := func(_key: String) -> String: return LINE_TEXT
	var needs := StoryRunner.story_needs(Fixtures.make_story(_catalog), translate, 15.0)
	var moment := StoryBeatData.Moment
	check_eq(needs[moment.NIGHT_START], LINE_SECONDS, "el saludo")
	check_eq(needs[moment.BEFORE_FIRST_WAVE], 2 * LINE_SECONDS + 2.0, "2 líneas, más 2 s antes de la ola")
	# La pregunta, 15 s, la respuesta más larga, la línea de Agustín con la marca y la de Gonzalo.
	check_eq(needs[moment.AFTER_LAST_WAVE], LINE_SECONDS + 15.0 + LINE_SECONDS + LINE_SECONDS + LINE_SECONDS,
			"la decisión entera")
	check_eq(needs[moment.AFTER_FINALE], LINE_SECONDS, "el cierre")
	return true


## Un momento "antes de" que dura más que su anticipación empieza antes: lo que dura, más 2 s.
func test_un_momento_largo_empieza_antes() -> bool:
	var steps := []
	for index in 10:
		steps.append(_line(0, "K_%d" % index))
	var sim := _sim(_story(StoryBeatData.Moment.BEFORE_FIRST_WAVE, steps, false))
	sim.run_until(70.0)
	check_eq(sim.time_of("K_0"), 60.0 - 10 * LINE_SECONDS - 2.0, "42 s antes de la ola")
	check_eq(sim.wave_times[0], 60.0, "y la ola no espera")
	return true
