extends "res://test/test_case.gd"
## La conversación de León en la noche 0 (Plan 9.5, docs/26 §4): enseña a preguntar (y lo que cuesta), a marcar, lo azul,
## los audios, a abrir la página, la mejor y la peor decisión y a descargar el video; Gonzalo muestra qué pasa si se
## acaba el tiempo, y León enseña la estática y a sincronizar antes de despedirse. Cada paso dice qué parpadea (Focus)
## y qué se desbloquea (Unlock).

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")


## Lleva la conversación hasta el paso `step`, haciendo lo que pide cada uno.
func _until(step: TutorialChat.Step) -> TutorialChat:
	var chat := TutorialChat.new()
	chat.start()
	var actions: Array[Callable] = [
		func() -> void: chat.question_asked(ClueCategory.Kind.SIGHT),
		func() -> void: chat.clue_marked(false, 1),
		func() -> void: chat.question_asked(ClueCategory.Kind.SOUND),
		func() -> void: chat.audio_played(),
		func() -> void: chat.question_asked(ClueCategory.Kind.ENVIRONMENT),
		func() -> void: chat.identified(),
		func() -> void: chat.page_opened(),
		func() -> void: chat.answered(RuleEvaluator.Outcome.CORRECT),
		func() -> void: chat.answered(RuleEvaluator.Outcome.RISKY),
		func() -> void: chat.video_received(),
		func() -> void: chat.chat_opened(true),
		func() -> void: chat.demo_timed_out(),
		func() -> void: chat.chat_opened(false),
	]
	for action: Callable in actions:
		if chat.step == step:
			break
		action.call()
	return chat


func test_saluda_y_pide_preguntar_que_ve() -> bool:
	var chat := TutorialChat.new()
	var reply := chat.start()
	check_eq(reply.lines(), [TutorialChat.HELLO_KEY, TutorialChat.GUESS_KEY], "saluda y pide que le pregunten")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.ASK_SIGHT, "parpadea «¿Qué ves?»")
	check_eq(chat.step, TutorialChat.Step.ASK_SIGHT, "espera la pregunta")
	return true


## Las líneas van antes del foco: lo que hay que apretar parpadea cuando León terminó de escribir.
func test_el_foco_va_despues_de_las_lineas() -> bool:
	var reply := TutorialChat.new().start()
	check_eq(reply.items[-1].command, TutorialChat.Command.FOCUS, "lo último es el foco")
	return true


## Después de la primera pregunta, León explica lo que cuesta preguntar (observación 2) y pide marcar.
func test_el_costo_de_preguntar_y_marcar() -> bool:
	var chat := _until(TutorialChat.Step.ASK_SIGHT)
	check_eq(chat.question_asked(ClueCategory.Kind.SOUND).items, [], "otra pregunta no cuenta")
	var reply := chat.question_asked(ClueCategory.Kind.SIGHT)
	check_eq(reply.lines(), [TutorialChat.COST_KEY, TutorialChat.MARK_KEY], "lo que cuesta y que marque")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.CLUES, "parpadean las frases")
	check_eq(chat.step, TutorialChat.Step.MARK, "espera una marca")
	return true


## León bromea con el señuelo una sola vez, y un señuelo no cuenta como marca.
func test_el_senuelo_una_sola_vez() -> bool:
	var chat := _until(TutorialChat.Step.MARK)
	check_eq(chat.clue_marked(true, 0).lines(), [TutorialChat.DECOY_KEY], "la broma")
	check_eq(chat.clue_marked(true, 0).lines(), [], "una sola vez")
	check_eq(chat.step, TutorialChat.Step.MARK, "sigue esperando una característica")
	return true


## Al marcar la primera, León explica lo azul (observación 7) y pide preguntar qué oye.
func test_lo_azul_y_que_oye() -> bool:
	var chat := _until(TutorialChat.Step.MARK)
	var reply := chat.clue_marked(false, 1)
	check_eq(reply.lines(), [TutorialChat.BLUE_KEY, TutorialChat.ASK_SOUND_KEY], "lo azul y «¿Qué oyes?»")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.ASK_SOUND, "parpadea «¿Qué oyes?»")
	check_eq(chat.step, TutorialChat.Step.ASK_SOUND, "espera la pregunta")
	return true


## El audio (observación 9): pide escucharlo y, cuando lo oye, explica que son sus tripas y pide el ambiente.
func test_el_audio() -> bool:
	var chat := _until(TutorialChat.Step.ASK_SOUND)
	var reply := chat.question_asked(ClueCategory.Kind.SOUND)
	check_eq(reply.lines(), [TutorialChat.LISTEN_KEY], "que lo escuche")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.AUDIO, "parpadea el audio")
	reply = chat.audio_played()
	check_eq(reply.lines(), [TutorialChat.HEARD_KEY, TutorialChat.AMBIENT_KEY], "son sus tripas, y el ambiente")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.ASK_ENVIRONMENT, "parpadea «¿Ambiente?»")
	check_eq(chat.audio_played().items, [], "oírlo de nuevo no hace nada")
	return true


## La segunda característica: parpadean las frases, Matías piensa y, con el nombre, se desbloquea el cuaderno.
func test_el_nombre_desbloquea_el_cuaderno() -> bool:
	var chat := _until(TutorialChat.Step.ASK_AMBIENT)
	var reply := chat.question_asked(ClueCategory.Kind.ENVIRONMENT)
	check_eq(reply.lines(), [], "sin líneas: ya sabe marcar")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.CLUES, "parpadean las frases")
	check_eq(chat.clue_marked(false, 2).value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.NONE,
			"con las 2 marcadas, Matías piensa: nada parpadea")
	reply = chat.identified()
	check_eq(reply.lines(), [TutorialChat.NAME_KEY], "pide abrir la página")
	check_eq(reply.value_of(TutorialChat.Command.UNLOCK), TutorialChat.Unlock.NOTEBOOK, "el cuaderno se desbloquea")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.ENTITY_NAME, "parpadea el nombre")
	check_eq(chat.step, TutorialChat.Step.OPEN_PAGE, "espera la página")
	return true


## La página antes de tiempo no adelanta nada.
func test_la_pagina_a_su_tiempo() -> bool:
	var early := TutorialChat.new()
	early.start()
	check_eq(early.page_opened().items, [], "antes de tiempo, nada")
	var chat := _until(TutorialChat.Step.OPEN_PAGE)
	var reply := chat.page_opened()
	check_eq(reply.lines(), [TutorialChat.DECIDE_KEY, TutorialChat.BEST_KEY], "explica la tabla y pide la mejor")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.ANSWERS, "parpadean las 4 hojas")
	return true


## Si elige otra, León le dice que lo intente de nuevo, y la respuesta no cuenta.
func test_la_mejor_hasta_acertar() -> bool:
	var chat := _until(TutorialChat.Step.BEST)
	var wrong := chat.answered(RuleEvaluator.Outcome.WRONG)
	check_eq(wrong.lines(), [TutorialChat.RETRY_KEY], "intenta de nuevo")
	check(not wrong.accept_answer, "no cuenta")
	check_eq(chat.answered(RuleEvaluator.Outcome.RISKY).lines(), [TutorialChat.RETRY_KEY], "la de riesgo tampoco")
	var right := chat.answered(RuleEvaluator.Outcome.CORRECT)
	check_eq(right.lines(), [TutorialChat.BEST_OK_KEY, TutorialChat.WORST_KEY], "acertó: ahora la peor")
	check(not right.accept_answer, "la solicitud sigue")
	check_eq(chat.step, TutorialChat.Step.WORST, "espera la peor")
	return true


func test_la_peor_manda_el_video() -> bool:
	var chat := _until(TutorialChat.Step.WORST)
	check_eq(chat.answered(RuleEvaluator.Outcome.CORRECT).lines(), [TutorialChat.WORST_RETRY_KEY], "no es la calavera")
	var risky := chat.answered(RuleEvaluator.Outcome.RISKY)
	check_eq(risky.lines(), [TutorialChat.WORST_OK_KEY, TutorialChat.DOWNLOAD_KEY], "le pegaron y manda el video")
	check(risky.accept_answer, "la solicitud termina")
	check(risky.has(TutorialChat.Command.SEND_VIDEO), "manda el video")
	check_eq(risky.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.DOWNLOAD, "parpadea la barra")
	check_eq(chat.step, TutorialChat.Step.DOWNLOAD, "espera la descarga")
	return true


## Gonzalo y el tiempo que se acaba (observación 3, D6): León avisa, llega la solicitud de Gonzalo y su entrada se
## desbloquea y parpadea. Su tiempo corre desde que se abre su chat.
func test_gonzalo_escribe() -> bool:
	var chat := _until(TutorialChat.Step.DOWNLOAD)
	var reply := chat.video_received()
	check_eq(reply.lines(), [TutorialChat.VIDEO_OK_KEY, TutorialChat.GONZALO_KEY], "Gonzalo te está escribiendo")
	check(reply.has(TutorialChat.Command.START_DEMO), "llega su solicitud")
	check_eq(reply.value_of(TutorialChat.Command.UNLOCK), TutorialChat.Unlock.DEMO_FRIEND, "Gonzalo se desbloquea")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.DEMO_ENTRY, "parpadea su entrada")
	check(not chat.chat_opened(false).run_demo, "el chat de León no lo echa a andar")
	var opened := chat.chat_opened(true)
	check(opened.run_demo, "al abrir su chat, corre su tiempo")
	check_eq(opened.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.NONE, "y nada parpadea: hay que mirar")
	check(not chat.chat_opened(true).run_demo, "una sola vez")
	return true


## Al llegar a 0, Gonzalo cuenta qué hizo solo y sale el aviso de daño, sin efecto; después parpadea la entrada de León.
func test_gonzalo_decide_solo() -> bool:
	var chat := _until(TutorialChat.Step.DEMO)
	var reply := chat.demo_timed_out()
	check_eq(reply.demo_lines(), [TutorialChat.GONZALO_ALONE_KEY, TutorialChat.GONZALO_HURT_KEY], "lo que hizo solo")
	check_eq(reply.lines(), [], "León no dice nada todavía")
	check(reply.has(TutorialChat.Command.DEMO_HURT), "el aviso de daño")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.GUIDE_ENTRY, "parpadea la entrada de León")
	check_eq(chat.demo_timed_out().items, [], "una sola vez")
	return true


## De vuelta con León: explica qué pasó, su señal baja, escribe una línea con estática fija (observación 16), la
## explica y se le corta la señal. El mixer se desbloquea y parpadean las barritas.
func test_la_estatica_y_la_senal() -> bool:
	var chat := _until(TutorialChat.Step.DEMO_DONE)
	check_eq(chat.chat_opened(true).items, [], "en el chat de Gonzalo, nada")
	var reply := chat.chat_opened(false)
	check_eq(reply.lines(), [TutorialChat.NO_ANSWER_KEY, TutorialChat.STATIC_KEY, TutorialChat.STATIC_EXPLAIN_KEY,
			TutorialChat.SIGNAL_WARN_KEY, TutorialChat.SIGNAL_CUT_KEY], "explica y se corta")
	check_eq(reply.value_of(TutorialChat.Command.SET_SIGNAL), TutorialChat.STATIC_SIGNAL, "su señal baja")
	check_eq(reply.value_of(TutorialChat.Command.STATIC_LINE), TutorialChat.STATIC_KEY, "la línea con estática fija")
	var commands := reply.items.map(func(item: TutorialChat.Item) -> TutorialChat.Command: return item.command)
	check(commands.find(TutorialChat.Command.SET_SIGNAL) < commands.find(TutorialChat.Command.STATIC_LINE),
			"la señal baja antes de la línea tapada")
	check(reply.has(TutorialChat.Command.CUT_SIGNAL), "se corta")
	check_eq(reply.value_of(TutorialChat.Command.UNLOCK), TutorialChat.Unlock.MIXER, "el mixer se desbloquea")
	check_eq(reply.value_of(TutorialChat.Command.FOCUS), TutorialChat.Focus.SYNC, "parpadean las barritas")
	check_eq(chat.step, TutorialChat.Step.SIGNAL, "espera Audio Sync")
	return true


## Al volver la señal se abre su chat, se despide y termina.
func test_al_volver_la_senal_se_despide() -> bool:
	var chat := _until(TutorialChat.Step.SIGNAL)
	var reply := chat.signal_restored()
	check_eq(reply.lines(), [TutorialChat.BACK_KEY, TutorialChat.READY_KEY], "volvió y se despide")
	var commands := reply.items.map(func(item: TutorialChat.Item) -> TutorialChat.Command: return item.command)
	check(commands.find(TutorialChat.Command.OPEN_GUIDE_CHAT) < commands.find(TutorialChat.Command.LINE),
			"primero se abre su chat")
	check_eq(commands[-1], TutorialChat.Command.FINISH, "termina")
	check_eq(chat.step, TutorialChat.Step.DONE, "listo")
	check_eq(chat.signal_restored().items, [], "después, nada")
	return true


## Lo que llega fuera de su paso no hace nada.
func test_fuera_de_su_paso_nada() -> bool:
	var chat := _until(TutorialChat.Step.ASK_SIGHT)
	check_eq(chat.answered(RuleEvaluator.Outcome.CORRECT).items, [], "responder antes de tiempo")
	check_eq(chat.video_received().items, [], "un video")
	check_eq(chat.signal_restored().items, [], "la señal")
	check_eq(chat.demo_timed_out().items, [], "Gonzalo")
	check_eq(chat.identified().items, [], "el nombre, sin haber preguntado")
	return true


func test_sus_textos_existen() -> bool:
	for key: String in TutorialChat.ALL_KEYS:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	return true
