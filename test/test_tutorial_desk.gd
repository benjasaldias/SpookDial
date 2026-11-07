extends "res://test/test_case.gd"
## La noche 0, el tutorial, en el escritorio (decisión de Benja): el aviso dice qué hacer en cada paso, el
## temporizador espera y la noche termina al cerrar el celular.

const DESK := preload("res://scenes/desk/desk.tscn")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")


func _make_desk(night_number := 0) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").random_seed = 21
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


## Avanza la noche y el escritorio `seconds` segundos, de a 1, como en el juego.
func _play(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk.get_node("NightManager").advance(1.0)
		desk._process(1.0)


func _hint_text(desk: Node2D) -> String:
	return (desk.get_node("Overlay/TutorialHint/Box/Body") as Label).text


## El texto del aviso `key`, con el nombre del amigo `friend_key`.
func _expected(key: String, friend_key := "") -> String:
	var friend_name := String(TranslationServer.translate(friend_key)) if not friend_key.is_empty() else ""
	return String(TranslationServer.translate(key)).format({"friend": friend_name})


func _correct(request: FriendRequest) -> ActionData:
	return request.entity.find_action(RuleEvaluator.applicable_rule(request.entity, request.situation).correct_action_id)


func test_en_una_noche_normal_no_hay_aviso() -> bool:
	var desk := _make_desk(3)
	check(not (desk.get_node("Overlay/TutorialHint") as Control).visible, "sin aviso")
	desk.free()
	return true


func test_el_boton_salta_el_tutorial() -> bool:
	var desk := _make_desk()
	var skipped := []
	desk.tutorial_skipped.connect(func() -> void: skipped.append(true))
	(desk.get_node("Overlay/TutorialHint/Box/Skip") as Button).pressed.emit()
	check_eq(skipped, [true], "avisa que se saltó")
	desk.free()
	return true


## De punta a punta: las 3 solicitudes, el video, el susto, el chat de Gonzalo y el celular.
func test_el_tutorial_de_punta_a_punta() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	var hint := desk.get_node("Overlay/TutorialHint") as Control
	check(hint.visible, "el aviso se ve")
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.DIALS_KEY), "primero, los diales")
	var ok := desk.get_node("Overlay/TutorialHint/Box/Ok") as Button
	check(ok.visible, "con su botón Entendido")
	ok.pressed.emit()
	desk._process(0.0)
	check(not ok.visible, "el botón se va")
	check_eq(_hint_text(desk), _expected(TutorialGuide.WELCOME_KEY), "bienvenida")
	# La solicitud de León: abrir el chat, preguntar, marcar, abrir la página y responder.
	_play(desk, 6)
	var request: FriendRequest = manager.requests[0]
	check(request != null, "llegó la solicitud de León")
	if request == null:
		desk.free()
		return true
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_LEON_NAME"), "abrir el chat")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.ASK_KEY, "FRIEND_LEON_NAME"), "preguntar")
	manager.ask(0, ClueCategory.Kind.SIGHT)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.MARK_KEY), "marcar")
	for trait_data: TraitData in request.traits:
		request.click_clue(trait_data.id)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_PAGE_KEY), "abrir la página")
	_play(desk, 30)
	check_eq(request.time_left, 85.0, "el temporizador esperó: solo bajó la pregunta")
	desk.get_node("UI/ChatPanel").entity_page_requested.emit(0, request.entity)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.ANSWER_KEY), "responder")
	manager.answer(0, _correct(request))
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.CORRECT_KEY, "FRIEND_LEON_NAME"), "le fue bien")
	# La de Agustín, con un video al terminar.
	_play(desk, 5)
	request = manager.requests[2]
	check(request != null, "llegó la solicitud de Agustín")
	if request == null:
		desk.free()
		return true
	manager.answer(2, _correct(request))
	_play(desk, 1)
	check_eq(_hint_text(desk), _expected(TutorialGuide.VIDEO_KEY, "FRIEND_AGUSTIN_NAME"), "el video")
	desk.get_node("DeskPlane/Entries/EntryAgustin").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.HOLD_KEY), "mantener presionado")
	manager.state.holding_download = 2
	_play(desk, 10)
	manager.state.holding_download = -1
	check_eq(manager.state.videos.received, 1, "se recibió")
	# La de Gonzalo, sin pista: una respuesta equivocada no lo hiere.
	_play(desk, 4)
	request = manager.requests[1]
	check(request != null, "llegó la solicitud de Gonzalo")
	if request == null:
		desk.free()
		return true
	check(request.hint == null, "sin pista")
	var wrong := request.entity.actions.filter(func(action: ActionData) -> bool:
		return RuleEvaluator.outcome(request.entity, request.situation, action) == RuleEvaluator.Outcome.WRONG)
	manager.answer(1, wrong[0])
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.WRONG_KEY, "FRIEND_GONZALO_NAME"), "le fue mal")
	check_eq(manager.state.friends[1].health, 3, "pero no salió herido")
	# El respiro, el susto guionado (con su señal previa y su pausa) y lo que tarda Gonzalo en escribir.
	_play(desk, 10)
	# La criatura enseña las cortinas: se cierran, se espera y se abren para revisar.
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	check_eq(_hint_text(desk), _expected(TutorialGuide.CLOSE_CURTAINS_KEY), "cerrar las cortinas")
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CURTAINS_KEY), "revisar")
	_play(desk, 25)
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_GONZALO_NAME"), "Gonzalo escribió")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.REPLY_KEY), "responderle")
	(desk.get_node("UI/ChatPanel/Panel/ScriptReply") as Button).pressed.emit()
	_play(desk, 3)
	check_eq(_hint_text(desk), _expected(TutorialGuide.PHONE_KEY), "el celular")
	desk.get_node("DeskPlane/Phone").clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.SCROLL_KEY), "scrollear")
	var endings := []
	desk.get_node("NightManager").night_ended.connect(func(ending: NightState.Ending, _request: FriendRequest) -> void:
		endings.append(ending))
	(desk.get_node("UI/PhoneView") as Control).close()
	desk._process(0.0)
	check_eq(endings, [NightState.Ending.WON], "al cerrar el celular, terminó el tutorial")
	check(not hint.visible, "el aviso se va con la pantalla final")
	desk.free()
	return true


## La criatura del susto guionado: el aviso pide cerrar las cortinas, y después abrirlas para revisar (decisión de
## Benja, 7 de noviembre).
func test_la_criatura_ensena_las_cortinas() -> bool:
	var desk := _make_desk()
	desk.get_node("RequestManager").tutorial_queue.clear()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	(desk.get_node("Overlay/TutorialHint/Box/Ok") as Button).pressed.emit()
	_play(desk, 6)
	check_eq(_hint_text(desk), _expected(TutorialGuide.CLOSE_CURTAINS_KEY), "pide cerrarlas")
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CURTAINS_KEY), "pide revisar")
	desk.free()
	return true
