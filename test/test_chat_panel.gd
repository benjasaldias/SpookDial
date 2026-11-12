extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const QuestionButton := preload("res://scripts/ui/question_button.gd")
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


## Un título del chat, como se ve: "RESPONDER · EL TRAUCO".
func _title(key: String, detail := "") -> String:
	return (tr(key) if detail.is_empty() else "%s · %s" % [tr(key), detail]).to_upper()


## Acomoda el chat como en un cuadro del juego: run_tests.gd no deja pasar cuadros entre pruebas.
func _layout(panel: Control) -> void:
	(panel.get_node("Panel/Layout") as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)


const ChatPanelScript := preload("res://scripts/ui/chat_panel.gd")


func _question_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("%Questions").get_children()


func _answer_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("%Answers").get_children()


## La única entidad de la noche 1 del catálogo de prueba.
func _beast() -> EntityData:
	return _manager.catalog.nights()[0].new_entities[0]


func test_empieza_oculto_y_se_abre_en_un_amigo() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for(1)
	check(panel.visible, "visible tras abrir")
	check_eq(panel.selected_friend, 1, "amigo elegido")
	var tabs := panel.get_node("%Tabs").get_children()
	check_eq(tabs.size(), 3, "una pestaña por amigo")
	check((tabs[1] as Button).button_pressed and not (tabs[0] as Button).button_pressed, "pestaña de Gonzalo")
	var conversations := panel.get_node("%Conversations").get_children()
	check((conversations[1] as Control).visible and not (conversations[0] as Control).visible, "su conversación")
	_free(panel)
	return true


func test_avisa_al_elegir_un_amigo() -> bool:
	var panel := _make_panel()
	var selected := []
	panel.friend_selected.connect(func(friend_index: int) -> void: selected.append(friend_index))
	panel.open_for(2)
	(panel.get_node("%Tabs").get_child(1) as Button).pressed.emit()
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
	var tab := panel.get_node("%Tabs").get_child(2) as Button
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
	var progress := panel.get_node("%Progress") as Label
	var entity_button := panel.get_node("%EntityName") as Button
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


## Un señuelo solo vibra y se pone rojo, sin mostrar un costo (decisión de Benja, 11 de noviembre, tras el primer testeo).
func test_el_senuelo_vibra_sin_costo() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var request := _manager.start_request(0)
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment("Hay *algo*", request.decoys[0].id)
	_manager.message_added.emit(0, message)
	var view: ChatMessageView = panel.message_views(0)[-1]
	var time_left := request.time_left
	view.clue_clicked.emit(view, request.decoys[0].id)
	var text := (view.get_node("Bubble/Text") as RichTextLabel).text
	check(text.contains("[shake"), "vibra")
	check(not text.contains("−"), "sin costo: %s" % text)
	check_eq(request.time_left, time_left, "no quita tiempo")
	_free(panel)
	return true


func test_pide_abrir_el_cuaderno_para_responder() -> bool:
	var panel := _make_panel()
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE", tr("CHAT_OPEN_NOTEBOOK")),
			"el título lo pide")
	check(not (panel.get_node("%Answers") as Control).visible, "sin página no hay botones de respuesta")
	_free(panel)
	return true


func test_responde_con_las_acciones_de_la_pagina_abierta() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	panel._process(0.0)
	check((panel.get_node("%Answers") as Control).visible, "botones de respuesta visibles")
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE", tr(_beast().name_key)),
			"de qué página son")
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
	check(not (panel.get_node("%Answers") as Control).visible, "Gonzalo no tiene página abierta")
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE", tr("CHAT_OPEN_NOTEBOOK")),
			"pide abrir el cuaderno")
	_free(panel)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.PROGRESS_KEY, panel_script.THINKING_KEY, panel_script.OPEN_NOTEBOOK_KEY,
			panel_script.ASK_TITLE_KEY, panel_script.ANSWER_TITLE_KEY, panel_script.NO_TIME_KEY, panel_script.NO_SIGNAL_KEY,
			panel_script.OFFLINE_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var progress := String(TranslationServer.translate(panel_script.PROGRESS_KEY))
	check(progress.contains("{marked}") and progress.contains("{total}"), "IDENTIFY_PROGRESS debe tener {marked} y {total}")
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
	var tab := panel.get_node("%Tabs").get_child(0) as Button
	var friend: FriendData = _manager.catalog.friends[0]
	check_eq(tab.theme_type_variation, &"ChatTab", "pestaña con su estilo")
	check_eq(tab.get_theme_color(&"font_pressed_color"), friend.color, "la elegida, en el color del amigo")
	check(tab.text.begins_with(tr(friend.name_key).to_upper()), "el nombre en mayúsculas: %s" % tab.text)
	check_eq((_question_buttons(panel)[0] as Button).text,
			String(TranslationServer.translate("QUESTION_SIGHT_SHORT")).to_upper(), "las preguntas, cortas y en mayúsculas")
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
	check((panel.get_node("%Tabs").get_child(0) as Button).text.contains(panel.UNREAD_MARK), "la pestaña de León avisa")
	_free(panel)
	return true


## León mandó un video, que espera su descarga.
func _offer_video_from_leon() -> void:
	_manager.state.videos.add_extra(0, 0.0)
	_manager.state.advance(0.1)


func _download_text(panel: Control) -> String:
	return (panel.get_node("%Download/Text") as Label).text


func test_la_descarga_aparece_con_el_video() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._process(0.0)
	var download := panel.get_node("%Download") as Control
	check(not download.visible, "sin video no hay barra")
	_offer_video_from_leon()
	panel._process(0.0)
	check(download.visible, "llegó el video de León")
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_START").format({"seconds": 15, "percent": 0}).to_upper(),
			"pide mantener presionado, con el tiempo para empezar")
	panel.open_for(1)
	check(not download.visible, "Gonzalo no mandó nada")
	_free(panel)
	return true


## Simula el mouse de verdad, en la ventana del juego: lo mueve a `position`.
func _mouse_motion(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	(Engine.get_main_loop() as SceneTree).root.push_input(motion, true)


## Simula el botón izquierdo en `position`: lo aprieta o lo suelta.
func _mouse_button(position: Vector2, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = position
	click.global_position = position
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	(Engine.get_main_loop() as SceneTree).root.push_input(click, true)


## El centro de la barra de descarga, en la ventana del juego, con el chat ya acomodado.
func _bar_center(panel: Control) -> Vector2:
	_layout(panel)
	return (panel.get_node("%Hold") as Control).get_global_rect().get_center()


## El tester apretó justo cuando aparecía la barra: ese clic lo recibe la conversación, no la barra, y aun así tiene que
## descargar mientras lo mantenga encima (observación 10 del primer testeo; docs/27, tarea 3).
func test_apretar_justo_antes_de_que_aparezca_la_barra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	# Dónde va a aparecer la barra: con un video que después se va.
	_offer_video_from_leon()
	panel._process(0.0)
	var bar := _bar_center(panel)
	_manager.state.videos.offers.clear()
	panel._process(0.0)
	_layout(panel)
	check(not (panel.get_node("%Download") as Control).visible, "todavía no hay barra")
	_mouse_motion(bar)
	_mouse_button(bar, true)
	_offer_video_from_leon()
	panel._process(0.0)
	_layout(panel)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, 0, "descarga el video de León")
	_mouse_button(bar, false)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al soltar, se pausa")
	_free(panel)
	return true


func test_mantener_presionado_descarga() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_offer_video_from_leon()
	panel._process(0.0)
	var bar := _bar_center(panel)
	_mouse_motion(bar)
	_mouse_button(bar, true)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, 0, "descarga el video de León")
	_manager.state.advance(1.0)
	panel._process(0.0)
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_ACTIVE").format({"seconds": 19, "percent": 10}).to_upper(),
			"10 % en 1 s, con 20 s para terminar")
	check(is_equal_approx((panel.get_node("%Download/Bar") as ProgressBar).value, 10.0), "la barra avanza")
	_mouse_button(bar, false)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al soltar se pausa")
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_PAUSED").format({"seconds": 19, "percent": 10}).to_upper(),
			"en pausa")
	_free(panel)
	return true


## Lo que cuenta es el botón apretado con el mouse sobre la barra: fuera de ella no descarga, y al salir se pausa.
func test_fuera_de_la_barra_no_descarga() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_offer_video_from_leon()
	panel._process(0.0)
	var bar := _bar_center(panel)
	var above := bar - Vector2(0, 100)
	_mouse_motion(above)
	_mouse_button(above, true)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "apretado en la conversación, no")
	_mouse_motion(bar)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, 0, "al llegar a la barra con el botón apretado, sí")
	_mouse_motion(above)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al salir de la barra se pausa")
	_mouse_button(above, false)
	_free(panel)
	return true


func test_cerrar_el_chat_suelta_la_descarga() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_offer_video_from_leon()
	panel._process(0.0)
	var bar := _bar_center(panel)
	_mouse_motion(bar)
	_mouse_button(bar, true)
	panel._process(0.0)
	panel.hide()
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "con el chat cerrado no se descarga")
	_mouse_button(bar, false)
	panel.open_for(0)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al volver hay que presionar de nuevo")
	_free(panel)
	return true


func test_sin_senal_no_se_pregunta_ni_responde() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	_manager.start_request(0)
	_manager.state.friends[0].signal_level = 0.0
	panel._process(0.0)
	for button: Button in _question_buttons(panel):
		check(button.disabled, "no se puede preguntar")
	for button: Button in _answer_buttons(panel):
		check(button.disabled, "ni responder")
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE", tr("CHAT_OFFLINE")),
			"pide sincronizarlo")
	_free(panel)
	return true


func test_los_textos_de_la_descarga_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.DOWNLOAD_START_KEY, panel_script.DOWNLOAD_ACTIVE_KEY, panel_script.DOWNLOAD_SLOW_KEY,
			panel_script.DOWNLOAD_PAUSED_KEY, panel_script.DOWNLOAD_OFFLINE_KEY]:
		check(String(TranslationServer.translate(key)).contains("{seconds}"), "%s debe estar en ui.csv con {seconds}" % key)
	for key: String in [panel_script.DOWNLOAD_ACTIVE_KEY, panel_script.DOWNLOAD_SLOW_KEY, panel_script.DOWNLOAD_PAUSED_KEY]:
		check(String(TranslationServer.translate(key)).contains("{percent}"), "%s debe tener {percent}" % key)
	TranslationServer.set_locale(previous)
	return true


## Sincronizar es un botón cuadrado con la señal del amigo en barritas (docs/26 §2.3), y "Sincronizar" como ayuda.
func test_el_boton_sincronizar() -> bool:
	var panel := _make_panel()
	panel.open_for(1)
	panel._process(0.0)
	var sync := panel.get_node("%Sync") as Button
	check(not sync.visible, "en la noche 1 del catálogo de prueba no hay Audio Sync")
	_manager.catalog.nights()[0].audio_sync_beats = 4
	panel._process(0.0)
	check(sync.visible, "con Audio Sync, se ve")
	check_eq(sync.text, "", "sin texto: el ícono de la señal")
	check_eq((sync.icon as AtlasTexture).region, Rect2(60, 0, 15, 12), "la señal llena: 4 barritas verdes")
	_manager.state.friends[1].signal_level = 40.0
	panel._process(0.0)
	check_eq((sync.icon as AtlasTexture).region, Rect2(30, 12, 15, 12), "con 40: 2 barritas ámbar")
	check_eq(sync.tooltip_text, tr("CHAT_SYNC"), "la ayuda dice qué hace")
	check(sync.tooltip_text != "CHAT_SYNC", "el texto está en ui.csv")
	var requested := []
	panel.sync_requested.connect(func(friend_index: int) -> void: requested.append(friend_index))
	sync.pressed.emit()
	check_eq(requested, [1], "pide sincronizar a Gonzalo, el del chat")
	_free(panel)
	return true


func test_el_chat_guionado_se_responde_con_un_boton() -> bool:
	var panel := _make_panel()
	var data := ChatScriptData.new()
	data.friend = _manager.catalog.friends[1]
	for speaker: ChatLineData.Speaker in [ChatLineData.Speaker.FRIEND, ChatLineData.Speaker.PLAYER]:
		var line := ChatLineData.new()
		line.speaker = speaker
		line.text_key = "K_LINE_%d" % speaker
		data.lines.append(line)
	_manager.start_chat_script(data)
	_manager.advance(2.5)
	panel.open_for(1)
	var reply := panel.get_node("%ScriptReply") as Button
	check(reply.visible, "el botón de Matías")
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE"), "sin el aviso del cuaderno")
	check_eq(reply.text, String(TranslationServer.translate("K_LINE_1")), "con su línea")
	panel.open_for(0)
	check(not reply.visible, "solo en el chat de Gonzalo")
	panel.open_for(1)
	reply.pressed.emit()
	panel._process(0.0)
	check(not reply.visible, "ya respondió")
	check_eq(panel.message_views(1).size(), 2, "la línea de Gonzalo y la respuesta de Matías")
	_free(panel)
	return true


## Abre el chat del amigo 0 con un mensaje con audio.
func _send_audio(panel: Control) -> ChatMessage:
	panel.open_for(0)
	var request := _manager.start_request(0)
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_audio(Fixtures.make_audio(), "▶ Audio", "Gritó tres veces.")
	_manager.message_added.emit(0, message)
	return message


func test_clic_en_un_audio_lo_hace_sonar() -> bool:
	var panel := _make_panel()
	var message := _send_audio(panel)
	check(not panel.is_audio_playing(), "todavía no")
	panel.message_views(0)[-1]._on_meta_clicked(ChatMessageView.AUDIO_META)
	check(panel.is_audio_playing(), "suena")
	check_eq((panel.get_node("AudioClip") as AudioStreamPlayer).stream, message.audio, "el audio del mensaje")
	_free(panel)
	return true


func test_al_cerrar_el_chat_el_audio_se_corta() -> bool:
	var panel := _make_panel()
	_send_audio(panel)
	panel.message_views(0)[-1]._on_meta_clicked(ChatMessageView.AUDIO_META)
	panel.hide()
	check(not panel.is_audio_playing(), "se corta")
	_free(panel)
	return true


func test_con_subtitulos_el_audio_se_lee() -> bool:
	var panel := _make_panel()
	panel.audio_captions = true
	_send_audio(panel)
	var label := panel.message_views(0)[-1].get_node("Bubble/Text") as RichTextLabel
	check(label.get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	_free(panel)
	return true


func test_un_accidente_se_responde_desde_el_chat() -> bool:
	var panel := _make_panel()
	_manager.catalog.incidents.append(Fixtures.make_incident())
	panel.open_for(0)
	var incident: RefCounted = _manager.start_incident(0)
	panel._process(0.0)
	check((panel.get_node("%Answers") as Control).visible, "se ven las opciones, sin cuaderno")
	var buttons := _answer_buttons(panel)
	for index in incident.options.size():
		check((buttons[index] as Button).visible, "opción %d" % index)
		check_eq((buttons[index] as Button).text, tr(incident.options[index]), "su texto")
		check(not (buttons[index] as Button).disabled, "se puede elegir")
	check(not (buttons[3] as Button).visible, "la cuarta no se usa")
	for index in incident.options.size():
		check_eq((buttons[index] as Button).theme_type_variation, &"", "con sentido común, sin cuaderno: de terminal")
		check(not (buttons[index].get_node("Number") as Control).visible, "sin número de columna")
	check_eq((panel.get_node("%AnswerTitle") as Label).text, _title("CHAT_ANSWER_TITLE", tr(panel.INCIDENT_HINT_KEY)),
			"el título pregunta qué le dices")
	check(_question_buttons(panel).all(func(button: Button) -> bool: return button.disabled), "no se pregunta")
	check(panel._tab_text(0).contains("15"), "la pestaña muestra su tiempo")
	(buttons[0] as Button).pressed.emit()
	check_eq(_manager.incidents[0], null, "al elegir, termina")
	_free(panel)
	return true


## Agrega al chat del amigo `friend_index` un mensaje suyo y devuelve su vista.
func _friend_view(panel: Control, friend_index: int, sender := ChatMessage.Sender.FRIEND) -> ChatMessageView:
	var message := ChatMessage.new(sender, null)
	message.add_fragment("Hola")
	_manager.message_added.emit(friend_index, message)
	return panel.message_views(friend_index)[-1]


## Los amigos suenan mientras escriben, cada uno con su voz (decisión de Benja, 8 de noviembre).
func test_el_amigo_suena_al_escribir() -> bool:
	var panel := _make_panel()
	var voice := panel.get_node("Voice") as AudioStreamPlayer
	panel.open_for(1)
	_friend_view(panel, 1).letter_typed.emit("H")
	check(voice.playing, "suena")
	check_eq(voice.stream, _manager.catalog.friends[1].voice, "con la voz de ese amigo")
	_free(panel)
	return true


func test_solo_suena_el_chat_que_se_esta_viendo() -> bool:
	var panel := _make_panel()
	var voice := panel.get_node("Voice") as AudioStreamPlayer
	var other := _friend_view(panel, 1)
	other.letter_typed.emit("H")
	check(not voice.playing, "con el chat cerrado, no")
	panel.open_for(0)
	other.letter_typed.emit("H")
	check(not voice.playing, "con otra pestaña abierta, no")
	_free(panel)
	return true


func test_matias_y_los_avisos_no_suenan() -> bool:
	var panel := _make_panel()
	var voice := panel.get_node("Voice") as AudioStreamPlayer
	panel.open_for(0)
	_friend_view(panel, 0, ChatMessage.Sender.PLAYER).letter_typed.emit("H")
	check(not voice.playing, "Matías no tiene voz")
	_free(panel)
	return true


## La voz no tapa un audio: el jugador tiene que oír qué se oye.
func test_mientras_suena_un_audio_el_amigo_no_suena() -> bool:
	var panel := _make_panel()
	var voice := panel.get_node("Voice") as AudioStreamPlayer
	_send_audio(panel)
	panel.message_views(0)[-1]._on_meta_clicked(ChatMessageView.AUDIO_META)
	_friend_view(panel, 0).letter_typed.emit("H")
	check(not voice.playing, "no se oye encima del audio")
	_free(panel)
	return true


## Si llegan dos mensajes juntos, se escriben en cola: el segundo empieza cuando termina el primero (pedido de Benja,
## 11 de noviembre).
func test_los_mensajes_se_escriben_en_cola() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var first := _friend_view(panel, 0)
	var second := _friend_view(panel, 0)
	var other := _friend_view(panel, 1)
	check(not first.is_done() and not second.is_done(), "ninguno terminó")
	check_eq(second.wait_for, first, "el segundo espera al primero")
	check(other.wait_for == null, "otra conversación no espera")
	var label := second.get_node("Bubble/Text") as RichTextLabel
	var shown := label.visible_characters
	first.finish_typing()
	check(first.is_done(), "terminó el primero")
	check(second._typing != null, "y el segundo empezó a escribirse")
	check_eq(label.visible_characters, shown, "desde donde estaba: el nombre")
	_free(panel)
	return true


## Cada bloque con su título, que dice por qué no se puede usar (docs/26 §2.3): los avisos ya no son frases sueltas.
func test_los_titulos_de_cada_bloque() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._process(0.0)
	var ask := panel.get_node("%AskTitle") as Label
	var answer := panel.get_node("%AnswerTitle") as Label
	check_eq(ask.text, _title("CHAT_ASK_TITLE"), "sin solicitud: PREGUNTAR")
	check_eq(answer.text, _title("CHAT_ANSWER_TITLE", tr("CHAT_OPEN_NOTEBOOK")), "sin página: abrir el cuaderno")
	var request := _manager.start_request(0)
	_memory.open_page(0, _beast())
	panel._process(0.0)
	check_eq(ask.text, _title("CHAT_ASK_TITLE"), "con tiempo, sin más")
	check_eq(answer.text, _title("CHAT_ANSWER_TITLE", tr(_beast().name_key)), "con página: su nombre")
	request.time_left = 5.0
	panel._process(0.0)
	check_eq(ask.text, _title("CHAT_ASK_TITLE", tr("CHAT_NO_TIME")), "sin tiempo")
	_manager.state.friends[0].signal_level = 0.0
	panel._process(0.0)
	check_eq(ask.text, _title("CHAT_ASK_TITLE", tr("CHAT_NO_SIGNAL")), "sin señal no se pregunta")
	check_eq(answer.text, _title("CHAT_ANSWER_TITLE", tr("CHAT_OFFLINE")), "ni se responde: hay que sincronizar")
	_free(panel)
	return true


## La descarga acorta la conversación, y lo de abajo no se mueve (docs/27, tarea 7).
func test_la_descarga_acorta_la_conversacion() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._process(0.0)
	_layout(panel)
	var conversations := panel.get_node("%Conversations") as Control
	var identify := panel.get_node("%IdentifyBar") as Control
	var tall := conversations.size.y
	var identify_y := identify.position.y
	_offer_video_from_leon()
	panel._process(0.0)
	_layout(panel)
	check(conversations.size.y < tall, "la conversación se acorta: %s < %s" % [conversations.size.y, tall])
	check_eq(identify.position.y, identify_y, "la barra de identificación no se mueve")
	_free(panel)
	return true


## Abrir la página no mueve las preguntas: las respuestas tienen su espacio reservado, el que piden las acciones más
## largas de la noche.
func test_abrir_la_pagina_no_mueve_las_preguntas() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_manager.start_request(0)
	panel._process(0.0)
	_layout(panel)
	var questions := panel.get_node("%Questions") as Control
	var y := questions.position.y
	_memory.open_page(0, _beast())
	panel._process(0.0)
	_layout(panel)
	check_eq(questions.position.y, y, "las preguntas siguen en su lugar")
	check((panel.get_node("%AnswerArea") as Control).custom_minimum_size.y > 0.0, "las respuestas tienen su espacio")
	_free(panel)
	return true


## Lo que cuesta una pregunta, como se ve: "−5 s".
func _cost(seconds: int) -> String:
	return tr("CHAT_QUESTION_COST").format({"seconds": seconds})


## Cada pregunta muestra lo que cuesta, para que se entienda que preguntar quita tiempo (observación 1 del primer testeo).
func test_cada_pregunta_muestra_su_costo() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_manager.start_request(0)
	panel._process(0.0)
	var keys := ["QUESTION_SIGHT_SHORT", "QUESTION_SOUND_SHORT", "QUESTION_ENVIRONMENT_SHORT", "QUESTION_TRACES_SHORT"]
	var buttons := _question_buttons(panel)
	for index in buttons.size():
		var button: Button = buttons[index]
		check_eq(button.text, tr(keys[index]).to_upper(), "su etiqueta corta")
		check(button.icon != null, "con el ícono de su categoría")
		check_eq(button.get("cost_text"), _cost(5), "muestra lo que cuesta")
		check(not button.disabled, "se puede preguntar")
	check(tr("CHAT_QUESTION_COST") != "CHAT_QUESTION_COST", "el texto del costo está en ui.csv")
	_free(panel)
	return true


## Una pregunta ya respondida queda marcada (✓, más tenue) y no se repite (docs/26 §2.1).
func test_la_pregunta_respondida_queda_marcada() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_manager.start_request(0)
	(_question_buttons(panel)[0] as Button).pressed.emit()
	panel._process(0.0)
	var sight: Button = _question_buttons(panel)[0]
	check(sight.disabled, "no se repite")
	check_eq(sight.get("mark"), QuestionButton.Mark.ASKED, "queda con su ✓")
	check(not (_question_buttons(panel)[1] as Button).disabled, "las otras siguen")
	check_eq((_question_buttons(panel)[1] as Button).get("mark"), QuestionButton.Mark.NONE, "sin marca")
	_free(panel)
	return true


## Si la estática tapó algo de la respuesta, la pregunta vuelve, con el ícono de la estática (docs/26 §2.1).
func test_con_estatica_la_pregunta_vuelve() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var request := _manager.start_request(0)
	request.record_answer(ClueCategory.Kind.SIGHT, true)
	panel._process(0.0)
	var sight: Button = _question_buttons(panel)[0]
	check(not sight.disabled, "se puede repetir")
	check_eq(sight.get("mark"), QuestionButton.Mark.STATIC, "con el ícono de la estática")
	_manager.state.friends[0].signal_level = 0.0
	panel._process(0.0)
	check(sight.disabled, "sin señal, no")
	check_eq(sight.get("mark"), QuestionButton.Mark.STATIC, "pero sigue avisando que llegó tapada")
	_free(panel)
	return true


## Al preguntar, debajo de la pestaña del amigo aparece lo que costó: un "−5 s" que sube y se desvanece.
func test_al_preguntar_la_pestana_muestra_el_costo() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_manager.start_request(0)
	(_question_buttons(panel)[0] as Button).pressed.emit()
	var popups := panel.find_children("CostPopup*", "Label", true, false)
	check_eq(popups.size(), 1, "aparece una vez")
	if popups.size() == 1:
		check_eq((popups[0] as Label).text, _cost(5), "con lo que costó")
	(_question_buttons(panel)[0] as Button).pressed.emit()
	check_eq(panel.find_children("CostPopup*", "Label", true, false).size(), 1, "una pregunta que no se hizo no cuesta")
	_free(panel)
	return true


## Las respuestas son hojas del cuaderno, con el número de su columna de la tabla en una nota adhesiva (docs/26 §2.3).
func test_las_respuestas_son_hojas_numeradas() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	panel._process(0.0)
	var buttons := _answer_buttons(panel)
	for index in buttons.size():
		var button: Button = buttons[index]
		check_eq(button.theme_type_variation, &"AnswerSheet", "la hoja %d" % (index + 1))
		var number := button.get_node("Number") as Control
		check(number.visible, "con su nota adhesiva")
		check_eq((number.get_node("Label") as Label).text, str(index + 1), "con el número de su columna")
	_free(panel)
	return true


## Una barrita por cada 25 de señal; verdes con 70 o más (sin estática), ámbar desde 30 y rojas bajo 30, como los tramos
## de la estática.
func test_la_senal_en_barritas() -> bool:
	var frames := {0.0: Vector2i(0, 2), 10.0: Vector2i(1, 2), 30.0: Vector2i(2, 1), 69.0: Vector2i(3, 1),
			70.0: Vector2i(3, 0), 100.0: Vector2i(4, 0)}
	for level: float in frames:
		check_eq(ChatPanelScript.signal_frame(level), frames[level], "señal %d" % level)
	return true


## Sin señal, el botón de sincronizar parpadea con un borde rojo; con "Reducir destellos", el borde queda fijo.
func test_sin_senal_el_boton_parpadea() -> bool:
	var panel := _make_panel()
	_manager.catalog.nights()[0].audio_sync_beats = 4
	panel.open_for(0)
	panel._process(0.0)
	var highlight := panel.get_node("%Sync/Highlight")
	check(not highlight.active, "con señal, no")
	_manager.state.friends[0].signal_level = 0.0
	panel._process(0.0)
	check(highlight.active, "sin señal, parpadea")
	check(not highlight.reduce_flashes, "parpadeando")
	panel.reduce_flashes = true
	check(highlight.reduce_flashes, "con Reducir destellos, el borde queda fijo")
	panel.open_for(1)
	check(not highlight.active, "Gonzalo tiene señal")
	_free(panel)
	return true


## El nombre de la entidad lleva el ícono del cuaderno: se entiende que abre su página (docs/26 §2.3).
func test_el_nombre_lleva_el_cuaderno() -> bool:
	var panel := _make_panel()
	check((panel.get_node("%EntityName") as Button).icon != null, "con el ícono del cuaderno")
	_free(panel)
	return true
