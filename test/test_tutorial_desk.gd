extends "res://test/test_case.gd"
## La noche 0, el tutorial, en el escritorio (decisión de Benja, 11 de noviembre): León enseña en su chat, describiendo a
## Gonzalo, sin aviso arriba de la pantalla. El cuaderno solo tiene la página de Gonzalo.

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialChat := preload("res://scripts/core/tutorial_chat.gd")


func _make_desk(night_number := 0) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").random_seed = 21
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


## Avanza la noche, el escritorio y el chat `seconds` segundos, de a 0,5, como en el juego.
func _play(desk: Node2D, seconds: float) -> void:
	for _step in roundi(seconds * 2.0):
		desk.get_node("UI/ChatPanel")._process(0.5)
		desk.get_node("NightManager").advance(0.5)
		desk._process(0.5)


## Avanza hasta que `done` se cumpla, como mucho `seconds` segundos.
func _play_until(desk: Node2D, done: Callable, seconds := 40.0) -> void:
	for _step in roundi(seconds * 2.0):
		if done.call():
			return
		_play(desk, 0.5)


## Lo que escribió León hasta ahora, en orden.
func _leon_lines(desk: Node2D) -> Array:
	var lines := []
	for view: Node in desk.get_node("UI/ChatPanel").message_views(0):
		if view.message.sender == ChatMessage.Sender.FRIEND:
			lines.append(view.message.plain_text())
	return lines


func _said(desk: Node2D, key: String) -> bool:
	return _leon_lines(desk).has(String(TranslationServer.translate(key)))


func test_sin_aviso_arriba() -> bool:
	var desk := _make_desk()
	check(desk.get_node_or_null("Overlay/TutorialHint") == null, "ya no hay aviso arriba de la pantalla")
	desk.free()
	return true


func test_el_cuaderno_solo_tiene_a_gonzalo() -> bool:
	var desk := _make_desk()
	var tabs := desk.get_node("UI/NotebookPanel/Page/Layout/Index").get_children()
	check_eq(tabs.map(func(tab: Button) -> String: return tab.text), [String(TranslationServer.translate("TUTORIAL_PAGE_NAME"))],
			"una sola página")
	desk.free()
	return true


## De punta a punta: León saluda, se le pregunta, se marca (con el señuelo), se abre la página, se elige mal, la mejor y
## la peor, se descarga el video, se sincroniza y León se despide. Después, la noche 1.
func test_el_tutorial_de_punta_a_punta() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	var next := []
	desk.next_night_requested.connect(func() -> void: next.append(true))
	_play(desk, 9.0)
	var request: FriendRequest = manager.requests[0]
	check(request != null, "llegó la solicitud de León")
	if request == null:
		desk.free()
		return true
	check(_said(desk, TutorialChat.GUESS_KEY), "León pide que le pregunten qué ve")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	var messages := []
	manager.message_added.connect(func(_friend: int, message: ChatMessage) -> void: messages.append(message))
	manager.ask(0, ClueCategory.Kind.SIGHT)
	var answer: ChatMessage = messages[-1]
	check(answer.plain_text().contains("lentes") and answer.plain_text().contains("polerón"), "lo que ve: " + answer.plain_text())
	manager.click_clue(answer, &"red_hoodie")
	manager.click_clue(answer, &"glasses")
	_play(desk, 8.0)
	check(_said(desk, TutorialChat.DECOY_KEY), "bromea con el señuelo")
	check(_said(desk, TutorialChat.AMBIENT_KEY), "pide preguntar por el ambiente")
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	manager.click_clue(messages[-1], &"bad_smell")
	_play(desk, 4.0)
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "apareció el nombre")
	(desk.get_node("UI/ChatPanel/Panel/IdentifyBar/EntityName") as Button).pressed.emit()
	check((desk.get_node("UI/NotebookPanel") as Control).visible, "se abrió su página")
	_play(desk, 10.0)
	check(_said(desk, TutorialChat.BEST_KEY), "pide la mejor")
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(0, request.entity.find_action(&"pizza"))
	_play(desk, 4.0)
	check(_said(desk, TutorialChat.RETRY_KEY), "la de la pizza no: enojado gana, porque es la primera fila")
	manager.answer(0, request.entity.find_action(rule.correct_action_id))
	_play(desk, 8.0)
	check(_said(desk, TutorialChat.WORST_KEY), "pide la peor")
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	_play_until(desk, func() -> bool: return manager.state.videos.offer_for(0) != null)
	check(manager.state.videos.offer_for(0) != null, "mandó el video")
	var hold := desk.get_node("UI/ChatPanel/Panel/Download/Hold") as Button
	hold.button_down.emit()
	_play_until(desk, func() -> bool: return manager.state.videos.received == 1, 15.0)
	hold.button_up.emit()
	check_eq(manager.state.videos.received, 1, "descargado")
	_play_until(desk, func() -> bool: return not manager.state.friends[0].is_online())
	check(not manager.state.friends[0].is_online(), "se le cortó la señal")
	check(next.is_empty(), "todavía no termina")
	manager.restore_signal(0)
	var cards := desk.get_node("Overlay/TutorialCards") as Control
	_play_until(desk, func() -> bool: return cards.visible)
	check(_said(desk, TutorialChat.READY_KEY), "se despide")
	check(cards.visible, "aparecen las tarjetas con videos")
	check(next.is_empty(), "la noche 1 espera las tarjetas")
	(cards.get_node("Center/Box/Row/Side/Buttons/Skip") as Button).pressed.emit()
	check_eq(next.size(), 1, "y después, la noche 1")
	check_eq(manager.state.friends[0].health, 3, "nadie salió herido")
	desk.free()
	return true
