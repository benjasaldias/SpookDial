extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager


## Panel conectado a un manager con el catálogo de prueba (noche 1, sin solicitudes que lleguen solas).
func _make_panel() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.night_number = 1
	_manager.random_seed = 4
	_manager.requests_arrive = false
	root.add_child(_manager)
	var panel := PANEL.instantiate()
	root.add_child(panel)
	panel.setup(_manager, _manager.catalog.friends)
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


func test_esc_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	panel._unhandled_input(escape)
	check(not panel.visible, "oculto tras Esc")
	_free(panel)
	return true


func test_clic_izquierdo_fuera_lo_cierra_y_dentro_no() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._unhandled_input(_click_at(MOUSE_BUTTON_LEFT, Vector2(100, 100)))
	check(panel.visible, "sigue visible tras un clic dentro")
	panel._unhandled_input(_click_at(MOUSE_BUTTON_LEFT, Vector2(800, 300)))
	check(not panel.visible, "oculto tras un clic fuera")
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
	_free(panel)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.PROGRESS_KEY, panel_script.THINKING_KEY, panel_script.OPEN_NOTEBOOK_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var progress := String(TranslationServer.translate(panel_script.PROGRESS_KEY))
	check(progress.contains("{marked}") and progress.contains("{total}"), "IDENTIFY_PROGRESS debe tener {marked} y {total}")
	TranslationServer.set_locale(previous)
	return true
