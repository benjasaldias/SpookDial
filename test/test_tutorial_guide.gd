extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")


## Solicitud de "beast" para Gonzalo (amigo 1), con o1 = yes (correcta a1, mayor riesgo a2).
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.friend_index = 1
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.time_left = 90.0
	return request


func _view(request: FriendRequest = null, chat_friend := -1, page: EntityData = null) -> TutorialGuide.View:
	var view := TutorialGuide.View.new()
	view.request = request
	view.chat_friend = chat_friend
	view.page = page
	return view


func _check_hint(guide: TutorialGuide, view: TutorialGuide.View, key: String, friend_index := -1) -> void:
	var hint := guide.hint(view)
	check_eq(hint.key, key, "aviso")
	check_eq(hint.friend_index, friend_index, "de quién habla el aviso " + key)


## Paso a paso por una solicitud: abrir el chat, preguntar, marcar, abrir la página y responder.
func test_paso_a_paso_por_una_solicitud() -> bool:
	var guide := TutorialGuide.new()
	_check_hint(guide, _view(), TutorialGuide.WELCOME_KEY)
	var request := _make_request()
	_check_hint(guide, _view(request), TutorialGuide.OPEN_CHAT_KEY, 1)
	_check_hint(guide, _view(request, 0), TutorialGuide.OPEN_CHAT_KEY, 1)
	_check_hint(guide, _view(request, 1), TutorialGuide.ASK_KEY, 1)
	request.pay_question()
	_check_hint(guide, _view(request, 1), TutorialGuide.MARK_KEY)
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	_check_hint(guide, _view(request, 1), TutorialGuide.OPEN_PAGE_KEY)
	request.advance(FriendRequest.THINKING_TIME)
	_check_hint(guide, _view(request, 1), TutorialGuide.OPEN_PAGE_KEY)
	_check_hint(guide, _view(request, 1, Fixtures.make_entity(&"ghost")), TutorialGuide.OPEN_PAGE_KEY)
	_check_hint(guide, _view(request, 1, request.entity), TutorialGuide.ANSWER_KEY)
	_check_hint(guide, _view(request, -1, request.entity), TutorialGuide.OPEN_CHAT_KEY, 1)
	return true


## Después de responder, el aviso dice cómo le fue: en una noche de verdad, la acción equivocada hiere.
func test_dice_como_le_fue() -> bool:
	var keys := {
		&"a1": TutorialGuide.CORRECT_KEY,
		&"a2": TutorialGuide.RISKY_KEY,
		&"a3": TutorialGuide.WRONG_KEY,
	}
	for action_id: StringName in keys:
		var guide := TutorialGuide.new()
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		guide.request_finished(request)
		_check_hint(guide, _view(), keys[action_id], 1)
	return true


## Un video que espera: primero abrir su chat y después mantener presionada la barra.
func test_el_video() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.video_friend = 2
	_check_hint(guide, view, TutorialGuide.VIDEO_KEY, 2)
	view.chat_friend = 2
	_check_hint(guide, view, TutorialGuide.HOLD_KEY)
	return true


## Después del susto: responderle al amigo, abrir el celular y scrollear. Al cerrarlo, termina el tutorial.
func test_el_chat_guionado_y_el_celular() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.script_friend = 1
	_check_hint(guide, view, TutorialGuide.OPEN_CHAT_KEY, 1)
	view.chat_friend = 1
	_check_hint(guide, view, TutorialGuide.REPLY_KEY)
	guide.phone_opened()
	guide.phone_closed()
	check(not guide.is_done(), "abrir el celular antes de tiempo no cuenta")
	guide.phone_highlighted()
	_check_hint(guide, _view(), TutorialGuide.PHONE_KEY)
	guide.phone_closed()
	check(not guide.is_done(), "todavía no lo abre")
	guide.phone_opened()
	_check_hint(guide, _view(), TutorialGuide.SCROLL_KEY)
	check(not guide.is_done(), "mientras lo usa, sigue")
	guide.phone_closed()
	check(guide.is_done(), "al cerrarlo, termina")
	check_eq(guide.hint(_view()).key, "", "sin aviso")
	return true


## La criatura del susto guionado enseña las cortinas (decisión de Benja, 7 de noviembre).
func test_las_cortinas() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.creature_at_window = true
	_check_hint(guide, view, TutorialGuide.CLOSE_CURTAINS_KEY)
	view.creature_at_window = false
	view.curtains_closed = true
	_check_hint(guide, view, TutorialGuide.OPEN_CURTAINS_KEY)
	view.curtains_closed = false
	_check_hint(guide, view, TutorialGuide.WELCOME_KEY)
	return true


func test_sus_textos_existen() -> bool:
	for key: String in [TutorialGuide.TITLE_KEY, TutorialGuide.SKIP_KEY, TutorialGuide.WELCOME_KEY,
			TutorialGuide.OPEN_CHAT_KEY, TutorialGuide.ASK_KEY, TutorialGuide.MARK_KEY, TutorialGuide.OPEN_PAGE_KEY,
			TutorialGuide.ANSWER_KEY, TutorialGuide.CORRECT_KEY, TutorialGuide.RISKY_KEY, TutorialGuide.WRONG_KEY,
			TutorialGuide.VIDEO_KEY, TutorialGuide.HOLD_KEY, TutorialGuide.REPLY_KEY, TutorialGuide.PHONE_KEY,
			TutorialGuide.SCROLL_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	return true


## Lo primero que dice el tutorial son los diales (decisión de Benja, 4 de noviembre), con un botón Entendido.
func test_primero_los_diales() -> bool:
	var guide := TutorialGuide.new()
	guide.explain_dials = true
	var hint := guide.hint(_view())
	check_eq(hint.key, TutorialGuide.DIALS_KEY, "los diales")
	check(hint.needs_ok, "con su botón")
	guide.dials_understood()
	hint = guide.hint(_view())
	check_eq(hint.key, TutorialGuide.WELCOME_KEY, "después, la bienvenida")
	check(not hint.needs_ok, "sin botón")
	return true
