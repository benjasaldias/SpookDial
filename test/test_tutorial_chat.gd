extends "res://test/test_case.gd"
## La conversación de León en la noche 0 (pedido de Benja, 11 de noviembre): enseña a preguntar, marcar, abrir la página,
## elegir la mejor y la peor decisión, descargar el video y sincronizar, y se despide.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")


## Lleva la conversación hasta el paso de la mejor decisión.
func _until_best() -> TutorialChat:
	var chat := TutorialChat.new()
	chat.start()
	chat.question_asked(ClueCategory.Kind.SIGHT)
	chat.clue_marked(false, 1)
	chat.question_asked(ClueCategory.Kind.ENVIRONMENT)
	chat.identified(false)
	chat.page_opened()
	return chat


func test_saluda_y_pide_preguntar() -> bool:
	var chat := TutorialChat.new()
	var reply := chat.start()
	check_eq(reply.lines, [TutorialChat.HELLO_KEY, TutorialChat.GUESS_KEY], "saluda y pide que le pregunten")
	check_eq(chat.step, TutorialChat.Step.ASK_SIGHT, "espera «¿Qué ves?»")
	return true


func test_la_pregunta_correcta_avanza() -> bool:
	var chat := TutorialChat.new()
	chat.start()
	check_eq(chat.question_asked(ClueCategory.Kind.SOUND).lines, [TutorialChat.ASK_SIGHT_AGAIN_KEY],
			"otra pregunta: que pregunte qué ve")
	check_eq(chat.step, TutorialChat.Step.ASK_SIGHT, "sigue esperando")
	check_eq(chat.question_asked(ClueCategory.Kind.SIGHT).lines, [TutorialChat.MARK_KEY], "pide marcar")
	check_eq(chat.step, TutorialChat.Step.MARK, "espera una marca")
	return true


func test_falta_una_caracteristica() -> bool:
	var chat := TutorialChat.new()
	chat.start()
	chat.question_asked(ClueCategory.Kind.SIGHT)
	check_eq(chat.clue_marked(false, 1).lines, [TutorialChat.AMBIENT_KEY], "pide preguntar por el ambiente")
	check_eq(chat.step, TutorialChat.Step.ASK_AMBIENT, "espera la segunda")
	check_eq(chat.identified(false).lines, [TutorialChat.NAME_KEY], "con las 2, pide abrir la página")
	check_eq(chat.step, TutorialChat.Step.OPEN_PAGE, "espera la página")
	return true


## León bromea con el señuelo una sola vez.
func test_el_senuelo_una_sola_vez() -> bool:
	var chat := TutorialChat.new()
	chat.start()
	chat.question_asked(ClueCategory.Kind.SIGHT)
	check_eq(chat.clue_marked(true, 0).lines, [TutorialChat.DECOY_KEY], "la broma")
	check_eq(chat.clue_marked(true, 0).lines, [], "una sola vez")
	check_eq(chat.step, TutorialChat.Step.MARK, "un señuelo no cuenta como marca")
	return true


func test_abrir_la_pagina() -> bool:
	var chat := TutorialChat.new()
	chat.start()
	chat.identified(false)
	check_eq(chat.page_opened().lines, [TutorialChat.DECIDE_KEY, TutorialChat.BEST_KEY], "explica la tabla y pide la mejor")
	check_eq(chat.step, TutorialChat.Step.BEST, "espera la mejor")
	var early := TutorialChat.new()
	early.start()
	early.page_opened()
	check_eq(early.step, TutorialChat.Step.ASK_SIGHT, "la página abierta antes de tiempo no adelanta")
	check_eq(early.identified(true).lines, [TutorialChat.NAME_OPEN_KEY, TutorialChat.DECIDE_KEY, TutorialChat.BEST_KEY],
			"si ya estaba abierta, sigue directo a la tabla")
	check_eq(early.step, TutorialChat.Step.BEST, "espera la mejor")
	return true


## Si elige otra, León le dice que lo intente de nuevo, y la respuesta no cuenta.
func test_la_mejor_hasta_acertar() -> bool:
	var chat := _until_best()
	var wrong := chat.answered(RuleEvaluator.Outcome.WRONG)
	check_eq(wrong.lines, [TutorialChat.RETRY_KEY], "intenta de nuevo")
	check(not wrong.accept_answer, "no cuenta")
	check_eq(chat.answered(RuleEvaluator.Outcome.RISKY).lines, [TutorialChat.RETRY_KEY], "la de riesgo tampoco")
	var right := chat.answered(RuleEvaluator.Outcome.CORRECT)
	check_eq(right.lines, [TutorialChat.BEST_OK_KEY, TutorialChat.WORST_KEY], "acertó: ahora la peor")
	check(not right.accept_answer, "la solicitud sigue")
	check_eq(chat.step, TutorialChat.Step.WORST, "espera la peor")
	return true


func test_la_peor_manda_el_video() -> bool:
	var chat := _until_best()
	chat.answered(RuleEvaluator.Outcome.CORRECT)
	check_eq(chat.answered(RuleEvaluator.Outcome.CORRECT).lines, [TutorialChat.WORST_RETRY_KEY], "no es la calavera")
	var risky := chat.answered(RuleEvaluator.Outcome.RISKY)
	check_eq(risky.lines, [TutorialChat.WORST_OK_KEY, TutorialChat.DOWNLOAD_KEY], "le pegaron y manda el video")
	check(risky.accept_answer, "la solicitud termina")
	check(risky.send_video, "manda el video")
	check_eq(chat.step, TutorialChat.Step.DOWNLOAD, "espera la descarga")
	return true


func test_despues_del_video_se_corta_la_senal() -> bool:
	var chat := _until_best()
	chat.answered(RuleEvaluator.Outcome.CORRECT)
	chat.answered(RuleEvaluator.Outcome.RISKY)
	var reply := chat.video_received()
	check_eq(reply.lines, [TutorialChat.VIDEO_OK_KEY, TutorialChat.SIGNAL_WARN_KEY, TutorialChat.SIGNAL_CUT_KEY],
			"avisa que la señal es mala y se corta")
	check(reply.cut_signal, "corta la señal")
	check_eq(chat.step, TutorialChat.Step.SIGNAL, "espera Audio Sync")
	return true


func test_al_volver_la_senal_se_despide() -> bool:
	var chat := _until_best()
	chat.answered(RuleEvaluator.Outcome.CORRECT)
	chat.answered(RuleEvaluator.Outcome.RISKY)
	chat.video_received()
	var reply := chat.signal_restored()
	check_eq(reply.lines, [TutorialChat.BACK_KEY, TutorialChat.READY_KEY], "volvió y se despide")
	check(reply.finished, "termina")
	check_eq(chat.step, TutorialChat.Step.DONE, "listo")
	check_eq(chat.signal_restored().lines, [], "después, nada")
	return true


func test_sus_textos_existen() -> bool:
	for key: String in TutorialChat.ALL_KEYS:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	return true
