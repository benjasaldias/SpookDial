extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager
var _memory: NotebookMemory


## Panel conectado a un manager con el catálogo de prueba (noche 1, sin solicitudes que lleguen solas)
## y a la memoria del cuaderno de los 3 amigos.
func _make_panel() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.night_number = 1
	_manager.random_seed = 4
	_manager.requests_arrive = false
	root.add_child(_manager)
	_memory = NotebookMemory.new(_manager.catalog.friends.size())
	var panel := PANEL.instantiate()
	root.add_child(panel)
	panel.setup(_manager, _manager.catalog.friends, _memory)
	return panel


func _free(panel: Control) -> void:
	panel.free()
	_manager.free()


func _click_at(button: MouseButton, position: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = position
	return click


func _question_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("Panel/Questions").get_children()


func _answer_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("Panel/Answers").get_children()


## La única entidad de la noche 1 del catálogo de prueba.
func _beast() -> EntityData:
	return _manager.catalog.nights[0].new_entities[0]


func test_empieza_oculto_y_se_abre_en_un_amigo() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for(1)
	check(panel.visible, "visible tras abrir")
	check_eq(panel.selected_friend, 1, "amigo elegido")
	var tabs := panel.get_node("Panel/Tabs").get_children()
	check_eq(tabs.size(), 3, "una pestaña por amigo")
	check((tabs[1] as Button).button_pressed and not (tabs[0] as Button).button_pressed, "pestaña de Gonzalo")
	var conversations := panel.get_node("Panel/Conversations").get_children()
	check((conversations[1] as Control).visible and not (conversations[0] as Control).visible, "su conversación")
	_free(panel)
	return true


func test_avisa_al_elegir_un_amigo() -> bool:
	var panel := _make_panel()
	var selected := []
	panel.friend_selected.connect(func(friend_index: int) -> void: selected.append(friend_index))
	panel.open_for(2)
	(panel.get_node("Panel/Tabs").get_child(1) as Button).pressed.emit()
	check_eq(selected, [2, 1], "Agustín y después Gonzalo")
	_free(panel)
	return true


func test_clic_derecho_sobre_el_panel_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	(panel.get_node("Panel") as Control).gui_input.emit(_click_at(MOUSE_BUTTON_RIGHT, Vector2(100, 100)))
	check(not panel.visible, "oculto tras clic derecho")
	_free(panel)
	return true


func test_cada_mensaje_va_a_la_conversacion_de_su_amigo() -> bool:
	var panel := _make_panel()
	_manager.start_request(2)
	check_eq(panel.message_views(2).size(), 1, "mensaje de Agustín")
	check_eq(panel.message_views(0).size(), 0, "León sin mensajes")
	_free(panel)
	return true


func test_pestana_con_tiempo_y_aviso() -> bool:
	var panel := _make_panel()
	_manager.start_request(2)
	panel._process(0.0)
	var tab := panel.get_node("Panel/Tabs").get_child(2) as Button
	check(tab.text.contains("45"), "muestra el tiempo: %s" % tab.text)
	check(tab.text.contains(panel.UNREAD_MARK), "avisa del mensaje nuevo: %s" % tab.text)
	panel.open_for(2)
	check(not tab.text.contains(panel.UNREAD_MARK), "al abrirla, el aviso se va: %s" % tab.text)
	_free(panel)
	return true


func test_preguntas() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	check_eq(_question_buttons(panel).size(), 4, "4 preguntas")
	check((_question_buttons(panel)[0] as Button).disabled, "sin solicitud no se pregunta")
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (_question_buttons(panel)[0] as Button).disabled, "con solicitud se pregunta")
	(_question_buttons(panel)[0] as Button).pressed.emit()
	check_eq(panel.message_views(0).size(), 3, "mensaje, pregunta y respuesta")
	check_eq(request.time_left, 40.0, "costó 5 s")
	request.time_left = 5.0
	panel._process(0.0)
	check((_question_buttons(panel)[0] as Button).disabled, "con 5 s o menos no se pregunta")
	_free(panel)
	return true


func test_barra_de_identificacion() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var progress := panel.get_node("Panel/IdentifyBar/Progress") as Label
	var entity_button := panel.get_node("Panel/IdentifyBar/EntityName") as Button
	check(not progress.visible and not entity_button.visible, "sin solicitud, la barra está vacía")
	var request := _manager.start_request(0)
	panel._process(0.0)
	check_eq(progress.text, tr(panel.PROGRESS_KEY).format({"marked": 0, "total": 2}), "0 de 2")
	var message: ChatMessage = (panel.message_views(0)[0] as ChatMessageView).message
	for trait_data: TraitData in request.traits:
		_manager.click_clue(message, trait_data.id)
	panel._process(0.0)
	check_eq(progress.text, tr(panel.THINKING_KEY), "Matías piensa")
	_manager.advance(3.1)
	panel._process(0.0)
	check(entity_button.visible and not progress.visible, "aparece el nombre")
	check_eq(entity_button.text, tr(request.entity.name_key), "nombre de la entidad")
	var opened := []
	panel.entity_page_requested.connect(func(friend_index: int, entity: EntityData) -> void:
		opened.append([friend_index, entity]))
	entity_button.pressed.emit()
	check_eq(opened, [[0, request.entity]], "pide abrir su página")
	_free(panel)
	return true


func test_clic_en_un_senuelo_lo_hace_vibrar() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var request := _manager.start_request(0)
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment("Hay *algo*", request.decoys[0].id)
	_manager.message_added.emit(0, message)
	var view: ChatMessageView = panel.message_views(0)[-1]
	view.clue_clicked.emit(view, request.decoys[0].id)
	check_eq(request.clue_state(request.decoys[0].id), FriendRequest.ClueState.DECOY, "queda en rojo")
	check((view.get_node("Bubble/Text") as RichTextLabel).text.contains("[shake"), "vibra")
	_free(panel)
	return true


func test_pide_abrir_el_cuaderno_para_responder() -> bool:
	var panel := _make_panel()
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text, tr(panel.OPEN_NOTEBOOK_KEY), "aviso")
	check(not (panel.get_node("Panel/Answers") as Control).visible, "sin página no hay botones de respuesta")
	_free(panel)
	return true


func test_responde_con_las_acciones_de_la_pagina_abierta() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	panel._process(0.0)
	check((panel.get_node("Panel/Answers") as Control).visible, "botones de respuesta visibles")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text,
			tr(panel.ANSWER_FROM_PAGE_KEY).format({"entity": tr(_beast().name_key)}), "de qué página son")
	var buttons := _answer_buttons(panel)
	check_eq(buttons.map(func(button: Button) -> String: return button.text),
			_beast().actions.map(func(action: ActionData) -> String: return tr(action.label_key)), "las 4 acciones")
	check((buttons[0] as Button).disabled, "sin solicitud no se responde")
	# Sin heridas: si quedara herido, llegaría además el aviso de daño.
	_manager.catalog.balance.risky_hurt_chance = 0.0
	_manager.catalog.balance.wrong_hurt_chance = 0.0
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (buttons[0] as Button).disabled, "con solicitud se responde")
	(buttons[2] as Button).pressed.emit()
	check(request.finished and request.answered_by_player, "respondió Matías")
	check_eq(request.chosen_action, _beast().actions[2], "con la tercera acción de la página")
	check_eq(panel.message_views(0).size(), 3, "mensaje, respuesta y reacción")
	_free(panel)
	return true


func test_cada_amigo_responde_desde_su_pagina() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _beast())
	panel.open_for(1)
	check(not (panel.get_node("Panel/Answers") as Control).visible, "Gonzalo no tiene página abierta")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text, tr(panel.OPEN_NOTEBOOK_KEY), "pide abrir el cuaderno")
	_free(panel)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.PROGRESS_KEY, panel_script.THINKING_KEY, panel_script.OPEN_NOTEBOOK_KEY,
			panel_script.ANSWER_FROM_PAGE_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var progress := String(TranslationServer.translate(panel_script.PROGRESS_KEY))
	check(progress.contains("{marked}") and progress.contains("{total}"), "IDENTIFY_PROGRESS debe tener {marked} y {total}")
	check(String(TranslationServer.translate(panel_script.ANSWER_FROM_PAGE_KEY)).contains("{entity}"),
			"ANSWER_FROM_PAGE debe tener {entity}")
	TranslationServer.set_locale(previous)
	return true


func test_cada_mensaje_lleva_el_nombre_de_quien_escribe() -> bool:
	var panel := _make_panel()
	_manager.start_request(1)
	_manager.ask(1, ClueCategory.Kind.SIGHT)
	var views: Array[Node] = panel.message_views(1)
	var friend: FriendData = _manager.catalog.friends[1]
	check_eq(views.size(), 3, "mensaje, pregunta y respuesta")
	if views.size() == 3:
		check_eq(views[0].speaker, tr(friend.name_key).to_upper(), "el amigo, en mayúsculas")
		check_eq(views[0].speaker_color, friend.color, "en su color")
		check_eq(views[1].speaker, String(TranslationServer.translate("CHAT_PLAYER_NAME")).to_upper(), "Matías")
		check_eq(views[1].speaker_color, panel.PLAYER_COLOR, "en el color de la terminal")
	_free(panel)
	return true


func test_pestanas_y_preguntas_como_en_una_terminal() -> bool:
	var panel := _make_panel()
	var tab := panel.get_node("Panel/Tabs").get_child(0) as Button
	var friend: FriendData = _manager.catalog.friends[0]
	check_eq(tab.theme_type_variation, &"ChatTab", "pestaña con su estilo")
	check_eq(tab.get_theme_color(&"font_pressed_color"), friend.color, "la elegida, en el color del amigo")
	check(tab.text.begins_with(tr(friend.name_key).to_upper()), "el nombre en mayúsculas: %s" % tab.text)
	check_eq((_question_buttons(panel)[0] as Button).text, String(TranslationServer.translate("QUESTION_SIGHT")).to_upper(),
			"las preguntas en mayúsculas")
	_free(panel)
	return true


func test_el_aviso_de_dano_no_lleva_nombre_y_marca_la_pestana() -> bool:
	var panel := _make_panel()
	var request := _manager.start_request(0)
	panel.open_for(0)
	panel.open_for(1)
	var notice := ChatMessage.new(ChatMessage.Sender.SYSTEM, request)
	notice.add_fragment("León recibió daño: 2/3")
	_manager.message_added.emit(0, notice)
	var views: Array[Node] = panel.message_views(0)
	check_eq(views[-1].speaker, "", "lo escribe el juego: sin nombre")
	panel._process(0.0)
	check((panel.get_node("Panel/Tabs").get_child(0) as Button).text.contains(panel.UNREAD_MARK), "la pestaña de León avisa")
	_free(panel)
	return true
