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
		# Las pruebas no dejan pasar cuadros: los mensajes se escriben con tweens, que se avanzan a mano.
		for tween: Tween in (Engine.get_main_loop() as SceneTree).get_processed_tweens():
			tween.custom_step(0.5)


## Aprieta o suelta el botón izquierdo sobre la barra de descarga, como el jugador: con el mouse encima.
func _hold_download(desk: Node2D, pressed: bool) -> void:
	# Las pruebas no dejan pasar cuadros: el chat muestra la barra y se acomoda a mano, para que la barra esté en su lugar.
	desk.get_node("UI/ChatPanel")._process(0.0)
	(desk.get_node("UI/ChatPanel/Panel/Layout") as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
	var bar := (desk.get_node("UI/ChatPanel/%Hold") as Control).get_global_rect().get_center()
	var root := (Engine.get_main_loop() as SceneTree).root
	var motion := InputEventMouseMotion.new()
	motion.position = bar
	root.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = bar
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(click, true)


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


## En la noche 0 solo se usa lo que León va enseñando (observación 4): al empezar, ni el celular, ni las cortinas, ni el
## cuaderno, ni el mixer, ni las entradas de Gonzalo y Agustín responden. Esc sigue pausando.
func test_al_empezar_casi_todo_esta_bloqueado() -> bool:
	var desk := _make_desk()
	_play(desk, 6.0)
	desk._process(0.0)
	for path: String in ["DeskPlane/Phone", "WallPlane/Curtains", "DeskPlane/Notebook", "DeskPlane/Mixer"]:
		check(not desk.get_node(path).enabled, "%s bloqueado" % path)
	check(desk.get_node("DeskPlane/Entries/EntryLeon").enabled, "León sí")
	check(not desk.get_node("DeskPlane/Entries/EntryGonzalo").enabled, "Gonzalo no")
	check(not desk.get_node("DeskPlane/Entries/EntryAgustin").enabled, "Agustín no")
	var chat := desk.get_node("UI/ChatPanel")
	check(not chat.is_tab_enabled(2), "tampoco su pestaña")
	check(chat.is_tab_enabled(0), "la de León sí")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	desk._unhandled_input(escape)
	check((Engine.get_main_loop() as SceneTree).paused, "Esc pausa: ahí está «Saltar tutorial»")
	(Engine.get_main_loop() as SceneTree).paused = false
	desk.free()
	return true


## Desde la noche 1, todo como siempre.
func test_en_la_noche_1_todo_responde() -> bool:
	var desk := _make_desk(1)
	desk._process(0.0)
	for path: String in ["DeskPlane/Phone", "WallPlane/Curtains", "DeskPlane/Notebook", "DeskPlane/Mixer",
			"DeskPlane/Entries/EntryAgustin"]:
		check(desk.get_node(path).enabled, "%s habilitado" % path)
	check(desk.get_node("UI/ChatPanel").is_tab_enabled(2), "las pestañas")
	desk.free()
	return true


## El botón de la pregunta `category` en el chat.
func _question(desk: Node2D, category: ClueCategory.Kind) -> Button:
	return desk.get_node("UI/ChatPanel")._question_buttons[category]


## En el chat de la noche 0 solo se usa lo que pide León, cuando terminó de escribir, y eso parpadea (Plan 9.5).
func test_en_el_chat_solo_lo_que_pide_leon() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	_play(desk, 5.5)
	check(_question(desk, ClueCategory.Kind.SIGHT).disabled, "mientras León escribe, nada")
	_play(desk, 8.0)
	var sight := _question(desk, ClueCategory.Kind.SIGHT)
	check(not sight.disabled, "terminó: «¿Qué ves?» se puede apretar")
	check(sight.get_node("Highlight").active, "y parpadea")
	check(_question(desk, ClueCategory.Kind.SOUND).disabled, "«¿Qué oyes?» todavía no")
	check(not _question(desk, ClueCategory.Kind.SOUND).get_node("Highlight").active, "ni parpadea")
	check((desk.get_node("UI/ChatPanel/%Sync") as Button).disabled, "las barritas, tampoco")
	sight.pressed.emit()
	desk.get_node("UI/ChatPanel")._process(0.0)
	var answer_view: Node = desk.get_node("UI/ChatPanel").message_views(0).filter(func(view: Node) -> bool:
		return view.message.plain_text().contains("lentes"))[0]
	check(not answer_view.links_enabled, "las frases no se clickean mientras León explica")
	_play(desk, 12.0)
	check(answer_view.links_enabled, "cuando pide marcar, sí")
	check(answer_view.attention, "y laten")
	check(not sight.get_node("Highlight").active, "la pregunta ya no parpadea")
	desk.free()
	return true


## Lo que escribió el amigo `friend_index` hasta ahora, en orden.
func _friend_lines(desk: Node2D, friend_index: int) -> Array:
	var lines := []
	for view: Node in desk.get_node("UI/ChatPanel").message_views(friend_index):
		if view.message.sender == ChatMessage.Sender.FRIEND:
			lines.append(view.message.plain_text())
	return lines


func _says(desk: Node2D, friend_index: int, key: String) -> bool:
	return _friend_lines(desk, friend_index).has(String(TranslationServer.translate(key)))


## De punta a punta (Plan 9.5): León saluda; se le pregunta qué ve, se marca (con el señuelo); explica lo azul; se le
## pregunta qué oye y se escucha el audio de las tripas; se pregunta el ambiente y se marca la otra; se abre la página;
## se elige mal, la mejor y la peor; se descarga el video; Gonzalo muestra qué pasa si nadie contesta; León escribe con
## estática, se le corta la señal, se sincroniza y se despide. Después, las tarjetas y la noche 1.
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
	_play(desk, 8.0)
	check(_said(desk, TutorialChat.COST_KEY), "explica lo que cuesta preguntar")
	manager.click_clue(answer, &"red_hoodie")
	manager.click_clue(answer, &"glasses")
	_play(desk, 12.0)
	check(_said(desk, TutorialChat.DECOY_KEY), "bromea con el señuelo")
	check(_said(desk, TutorialChat.BLUE_KEY), "explica lo azul")
	check(_said(desk, TutorialChat.ASK_SOUND_KEY), "pide preguntar qué oye")
	manager.ask(0, ClueCategory.Kind.SOUND)
	var audio: ChatMessage = messages[-1]
	check(audio.audio != null, "manda un audio: las tripas")
	_play(desk, 5.0)
	manager.tutorial_audio_played(0, audio.audio)
	_play(desk, 10.0)
	check(_said(desk, TutorialChat.HEARD_KEY), "son sus tripas")
	check(_said(desk, TutorialChat.AMBIENT_KEY), "pide preguntar por el ambiente")
	manager.ask(0, ClueCategory.Kind.ENVIRONMENT)
	manager.click_clue(messages[-1], &"bad_smell")
	_play(desk, 4.0)
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "apareció el nombre")
	_play(desk, 6.0)
	var chat := desk.get_node("UI/ChatPanel")
	check(desk.get_node("DeskPlane/Notebook").enabled, "el cuaderno se desbloqueó")
	check((chat.get_node("%EntityName/Highlight") as Node).active, "parpadea el nombre")
	(desk.get_node("UI/ChatPanel/%EntityName") as Button).pressed.emit()
	check((desk.get_node("UI/NotebookPanel") as Control).visible, "se abrió su página")
	_play(desk, 10.0)
	check(_said(desk, TutorialChat.BEST_KEY), "pide la mejor")
	check(chat._highlights[TutorialChat.Focus.ANSWERS].active, "parpadean las hojas")
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
	_play(desk, 1.0)
	check(chat._highlights[TutorialChat.Focus.DOWNLOAD].active, "parpadea la barra")
	_hold_download(desk, true)
	_play_until(desk, func() -> bool: return manager.state.videos.received == 1, 15.0)
	_hold_download(desk, false)
	check_eq(manager.state.videos.received, 1, "descargado")
	_play_until(desk, func() -> bool: return manager.requests[1] != null)
	var demo: FriendRequest = manager.requests[1]
	check(demo != null, "Gonzalo pide ayuda")
	check(_says(desk, 1, TutorialChat.GONZALO_HELP_KEY), "con su línea")
	_play(desk, 2.0)
	var gonzalo_entry := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check(gonzalo_entry.enabled, "su entrada se desbloqueó")
	check(gonzalo_entry.highlighted, "y parpadea")
	check_eq(demo.time_left, 10.0, "su tiempo espera a que se abra su chat")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	_play(desk, 1.0)
	for category: ClueCategory.Kind in [ClueCategory.Kind.SIGHT, ClueCategory.Kind.TRACES]:
		check(_question(desk, category).disabled, "en la demostración no se pregunta: %s" % category)
	check(not (chat.get_node("%Progress") as Control).visible, "ni hay nada que identificar")
	_play(desk, 10.0)
	check(manager.requests[1] == null, "se le acabó el tiempo")
	_play(desk, 6.0)
	check(_says(desk, 1, TutorialChat.GONZALO_ALONE_KEY), "cuenta qué hizo solo")
	check_eq(manager.state.friends[1].health, 3, "sin efecto real")
	check(desk.get_node("DeskPlane/Entries/EntryLeon").highlighted, "parpadea la entrada de León")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	_play_until(desk, func() -> bool: return not manager.state.friends[0].is_online(), 60.0)
	check(_said(desk, TutorialChat.NO_ANSWER_KEY), "León explica qué pasó")
	check(messages.any(func(message: ChatMessage) -> bool:
		return message.tokens.any(func(token: ChatMessage.Token) -> bool: return token.covered)), "una línea tapada")
	check(not manager.state.friends[0].is_online(), "se le cortó la señal")
	_play(desk, 1.0)
	check(desk.get_node("DeskPlane/Mixer").enabled, "el mixer se desbloqueó")
	check((chat.get_node("%Sync/Highlight") as Node).active, "parpadean las barritas")
	check(not desk.get_node("DeskPlane/Phone").enabled, "el celular sigue bloqueado")
	check(next.is_empty(), "todavía no termina")
	desk.open_mixer()
	check((desk.get_node("UI/MixerView") as Control).guide_rect().has_area(), "en el mixer, parpadea el canal de León")
	desk.open_mixer_for(0)
	manager.restore_signal(0)
	var cards := desk.get_node("Overlay/TutorialCards") as Control
	_play_until(desk, func() -> bool: return cards.visible)
	check(not (desk.get_node("UI/MixerView") as Control).visible, "el mixer se cerró")
	check(_said(desk, TutorialChat.READY_KEY), "se despide")
	check(cards.visible, "aparecen las tarjetas con videos")
	check(next.is_empty(), "la noche 1 espera las tarjetas")
	(cards.get_node("Center/Box/Row/Side/Buttons/Skip") as Button).pressed.emit()
	check_eq(next.size(), 1, "y después, la noche 1")
	check_eq(manager.state.friends[0].health, 3, "nadie salió herido")
	desk.free()
	return true
