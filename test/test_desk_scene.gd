extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

const POSITIONS := {
	"WallPlane/Background": Vector2(0, 0),
	"WallPlane/Window": Vector2(266, 114),
	"WallPlane/ExteriorClip/Exterior": Vector2(0, 0),
	"WallPlane/Enemy": Vector2(300, 172),
	"WallPlane/GlassPane": Vector2(273, 121),
	"WallPlane/Curtains": Vector2(219, 92),
	"WallPlane/DialConnection": Vector2(840, 89),
	"WallPlane/DialSanity": Vector2(840, 219),
	"WallPlane/DialTrust": Vector2(840, 348),
	"DeskPlane/DeskSurface": Vector2(0, 505),
	"DeskPlane/Notebook": Vector2(1017, 562),
	"DeskPlane/Microphone": Vector2(830, 571),
	"DeskPlane/Phone": Vector2(357, 618),
	"DeskPlane/Mixer": Vector2(130, 565),
	"DeskPlane/Cables": Vector2(241, 504),
	"DeskPlane/PC": Vector2(479, 433),
	"DeskPlane/Entries/EntryLeon": Vector2(518, 454),
	"DeskPlane/Entries/EntryGonzalo": Vector2(518, 494),
	"DeskPlane/Entries/EntryAgustin": Vector2(518, 534),
}


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func test_cada_objeto_en_su_posicion() -> bool:
	var desk := _make_desk()
	for path: String in POSITIONS:
		check_eq((desk.get_node(path) as Node2D).position, POSITIONS[path], path)
	desk.free()
	return true


func test_todo_el_arte_cargado() -> bool:
	var desk := _make_desk()
	for sprite in desk.find_children("*", "AnimatedSprite2D", true, false):
		check((sprite as AnimatedSprite2D).sprite_frames != null, "sin arte: %s" % desk.get_path_to(sprite))
	desk.free()
	return true


func test_clic_en_una_entrada_abre_el_chat() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	leon.pressed.emit()
	var panel := desk.get_node("UI/ChatPanel") as Control
	check(panel.visible, "panel visible")
	check_eq(panel.get("selected_friend"), 0, "en la conversación de León")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
	desk.free()
	return true


func test_el_chat_recibe_los_mensajes_de_las_solicitudes() -> bool:
	var desk := _make_desk()
	desk.get_node("RequestManager").start_request(2)
	check_eq(desk.get_node("UI/ChatPanel").message_views(2).size(), 1, "mensaje de Agustín en su conversación")
	desk.free()
	return true


func test_las_entradas_usan_los_nombres_del_catalogo() -> bool:
	var desk := _make_desk()
	var names := {"EntryLeon": "León", "EntryGonzalo": "Gonzalo", "EntryAgustin": "Agustín"}
	for entry_name: String in names:
		var label := desk.get_node("DeskPlane/Entries/%s/NameLabel" % entry_name) as Label
		check_eq(label.text, names[entry_name], entry_name)
	desk.free()
	return true


func test_una_solicitud_hace_parpadear_su_entrada() -> bool:
	var desk := _make_desk()
	var request: RefCounted = desk.get_node("RequestManager").start_request(1)
	check(request != null, "la noche del escritorio tiene entidades")
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "Gonzalo en alerta")
	var timer := gonzalo.get_node("TimerLabel") as Label
	check(timer.visible, "muestra el tiempo")
	if request != null:
		check_eq(timer.text, str(ceili(request.get("time_left"))), "segundos")
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").state, ChatEntry.State.IDLE, "León sin solicitud")
	desk.free()
	return true


func test_cerrar_el_chat_deselecciona() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	leon.pressed.emit()
	(desk.get_node("UI/ChatPanel") as Control).hide()
	check_eq(leon.state, ChatEntry.State.IDLE, "León vuelve a idle")
	desk.free()
	return true


## Abre el chat de León y, con un clic en el cuaderno del escritorio, el cuaderno.
func _open_panels(desk: Node2D) -> void:
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk.get_node("DeskPlane/Notebook").clicked.emit()


func _panels_closed(desk: Node2D) -> bool:
	return not (desk.get_node("UI/ChatPanel") as Control).visible \
			and not (desk.get_node("UI/NotebookPanel") as Control).visible


func _click(button: MouseButton) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = Vector2(1100, 300)
	return click


func test_el_cuaderno_y_el_chat_son_independientes() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel") as Control
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(notebook.visible and not chat.visible, "el cuaderno se abre solo")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	check(notebook.visible and chat.visible, "abrir el chat no cierra el cuaderno")
	check_eq(notebook.get("friend_index"), 1, "el cuaderno salta a la página de Gonzalo")
	notebook.hide()
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(notebook.visible and chat.visible, "abrir el cuaderno no cierra el chat")
	desk.free()
	return true


func test_esc_y_un_clic_fuera_cierran_los_paneles() -> bool:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	var events := {
		"Esc": escape,
		"clic derecho fuera": _click(MOUSE_BUTTON_RIGHT),
		"clic izquierdo fuera": _click(MOUSE_BUTTON_LEFT),
	}
	for event_name: String in events:
		var desk := _make_desk()
		_open_panels(desk)
		desk._unhandled_input(events[event_name])
		check(_panels_closed(desk), "cerrados con %s" % event_name)
		desk.free()
	return true


func test_clic_derecho_sobre_un_panel_cierra_solo_ese() -> bool:
	var desk := _make_desk()
	_open_panels(desk)
	var chat := desk.get_node("UI/ChatPanel") as Control
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	(notebook.get_node("Page") as Control).gui_input.emit(_click(MOUSE_BUTTON_RIGHT))
	check(not notebook.visible and chat.visible, "se cierra solo el cuaderno")
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	(chat.get_node("Panel") as Control).gui_input.emit(_click(MOUSE_BUTTON_RIGHT))
	check(not chat.visible and notebook.visible, "se cierra solo el chat")
	desk.free()
	return true


func test_el_celular_y_el_mixer_cierran_los_paneles() -> bool:
	for object_name: String in ["Phone", "Mixer"]:
		var desk := _make_desk()
		_open_panels(desk)
		desk.get_node("DeskPlane/" + object_name).clicked.emit()
		check(_panels_closed(desk), "cerrados con %s" % object_name)
		desk.free()
	return true


func test_el_nombre_de_la_entidad_abre_su_pagina() -> bool:
	var desk := _make_desk()
	var trauco: EntityData = desk.get_node("RequestManager").catalog.known_entities(3)[0]
	desk.get_node("UI/ChatPanel").entity_page_requested.emit(1, trauco)
	check_eq(desk.notebook_memory.page_for(1), trauco, "Gonzalo tiene abierta la página")
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	check(notebook.visible, "cuaderno abierto")
	check_eq(notebook.get("friend_index"), 1, "con la página de Gonzalo")
	desk.free()
	return true


func test_al_cambiar_de_chat_el_cuaderno_salta() -> bool:
	var desk := _make_desk()
	_open_panels(desk)
	desk.get_node("UI/ChatPanel").open_for(2)
	check_eq(desk.get_node("UI/NotebookPanel").get("friend_index"), 2, "salta a la página de Agustín")
	desk.free()
	return true


func test_una_solicitud_nueva_empieza_en_el_indice() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	desk.notebook_memory.open_page(2, manager.catalog.known_entities(3)[0])
	manager.start_request(2)
	check_eq(desk.notebook_memory.page_for(2), null, "Agustín vuelve al índice")
	desk.free()
	return true


func test_se_responde_desde_el_cuaderno() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	var request: RefCounted = manager.start_request(0)
	check(request != null, "la noche del escritorio tiene entidades")
	if request == null:
		desk.free()
		return true
	var entity: EntityData = request.get("entity")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	var panel := desk.get_node("UI/ChatPanel")
	panel.entity_page_requested.emit(0, entity)
	panel._process(0.0)
	var rule := RuleEvaluator.applicable_rule(entity, request.get("situation"))
	var correct := entity.actions.find(entity.find_action(rule.correct_action_id))
	(panel.get_node("Panel/Answers").get_child(correct) as Button).pressed.emit()
	check(request.get("finished"), "la solicitud terminó")
	check_eq(request.get("outcome"), RuleEvaluator.Outcome.CORRECT, "con la acción correcta")
	check_eq(manager.requests[0], null, "León queda libre")
	desk.free()
	return true


func test_camara_con_zoom_leve_y_centrada() -> bool:
	var desk := _make_desk()
	var camera := desk.get_node_or_null("LookCamera") as Camera2D
	check(camera != null, "existe LookCamera")
	if camera:
		check(camera.has_method("_process") and camera.get("look_zoom") == 1.05, "tiene el script LookCamera cargado")
		check(camera.is_current(), "es la cámara activa")
		check(camera.zoom.is_equal_approx(Vector2(1.05, 1.05)), "zoom: %s" % camera.zoom)
		check_eq(camera.position, Vector2(640, 360), "centrada al inicio")
	check(desk.get_node_or_null("ParallaxRig") == null, "el parallax por planos ya no existe")
	desk.free()
	return true


## El estado de la noche del escritorio (noche 3: cuota de 3 videos).
func _state(desk: Node2D) -> NightState:
	return desk.get_node("RequestManager").state


func test_la_noche_avanza_con_su_reloj() -> bool:
	var desk := _make_desk()
	check(not desk.get_node("RequestManager").is_processing(), "las solicitudes las avanza el reloj de la noche")
	desk.get_node("NightManager").advance(2.0)
	check_eq(_state(desk).elapsed, 2.0, "la hora avanzó")
	desk.free()
	return true


func test_los_diales_muestran_los_medidores() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.sanity = 40.0
	state.trust = 70.0
	for friend in state.friends:
		friend.signal_level = 50.0
	desk._process(0.0)
	check(is_equal_approx(desk.get_node("WallPlane/DialConnection").value, 0.5), "Connection: el promedio de las señales")
	check(is_equal_approx(desk.get_node("WallPlane/DialSanity").value, 0.4), "Sanity")
	check(is_equal_approx(desk.get_node("WallPlane/DialTrust").value, 0.7), "Trust")
	desk.free()
	return true


func test_el_celular_muestra_la_hora() -> bool:
	var desk := _make_desk()
	_state(desk).elapsed = 210.0
	desk._process(0.0)
	check_eq((desk.get_node("DeskPlane/Phone/Clock") as Label).text, "03:00", "a la mitad de la noche")
	desk.free()
	return true


func test_el_pc_cuenta_los_videos() -> bool:
	var desk := _make_desk()
	_state(desk).videos.received = 1
	desk._process(0.0)
	var expected := String(TranslationServer.translate("PC_VIDEOS")).format({"received": 1, "quota": 3})
	check_eq((desk.get_node("DeskPlane/PC/Videos") as Label).text, expected, "1 de 3")
	check(expected.contains("1") and expected.contains("3"), "el texto lleva {received} y {quota}")
	desk.free()
	return true


func test_la_vineta_sigue_a_sanity() -> bool:
	var desk := _make_desk()
	var vignette := desk.get_node("Overlay/Vignette") as ColorRect
	check_eq(vignette.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no tapa los clics")
	_state(desk).sanity = 30.0
	desk._process(0.0)
	var strength: float = (vignette.material as ShaderMaterial).get_shader_parameter(&"strength")
	check(is_equal_approx(strength, 0.5), "con Sanity 30, a la mitad: %s" % strength)
	desk.free()
	return true


func test_un_amigo_herido_se_ve_en_su_entrada() -> bool:
	var desk := _make_desk()
	_state(desk).friends[1].hurt(1, 15.0)
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.STUNNED, "aturdido")
	check_eq(gonzalo.health, 2, "con 2 PV")
	check((gonzalo.get_node("TimerLabel") as Label).text.contains("15"), "muestra cuánto le queda")
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").health, 3, "León, sano")
	desk.free()
	return true


func test_al_terminar_la_noche_aparece_la_pantalla() -> bool:
	var desk := _make_desk()
	var screen := desk.get_node("Overlay/EndScreen") as Control
	check(not screen.visible, "oculta mientras dura la noche")
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	check(screen.visible, "aparece al perder")
	check_eq((screen.get_node("Center/Box/Title") as Label).text, String(TranslationServer.translate("END_LOST_TITLE")),
			"perdió")
	desk.free()
	return true


func test_las_entradas_muestran_la_senal() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.friends[0].signal_level = 30.0
	state.friends[2].signal_level = 0.0
	desk._process(0.0)
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").signal_bars, 2, "León con 2 barras")
	var agustin := desk.get_node("DeskPlane/Entries/EntryAgustin")
	check_eq(agustin.state, ChatEntry.State.DISCONNECTED, "Agustín, sin señal")
	check_eq((agustin.get_node("TimerLabel") as Label).text, String(TranslationServer.translate("ENTRY_OFFLINE")), "lo dice")
	desk.free()
	return true


func test_un_video_hace_parpadear_la_entrada() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.videos.add_extra(1, 0.0)
	state.advance(0.1)
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "en alerta")
	check_eq((gonzalo.get_node("TimerLabel") as Label).text,
			String(TranslationServer.translate("ENTRY_VIDEO")).format({"seconds": 15}), "15 s para empezar a descargarlo")
	desk.free()
	return true


func test_la_entrada_titila_antes_de_una_interferencia() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.interferences.pending.clear()
	state.interferences.pending.append(InterferenceSchedule.Interference.new(2, state.elapsed + 2.0))
	desk._process(0.0)
	check(desk.get_node("DeskPlane/Entries/EntryAgustin").interference_warning, "Agustín titila")
	check(not desk.get_node("DeskPlane/Entries/EntryLeon").interference_warning, "León no")
	desk.free()
	return true


func test_el_mixer_y_el_celular_son_modos_exclusivos() -> bool:
	var desk := _make_desk()
	var mixer := desk.get_node("UI/MixerView") as Control
	var phone := desk.get_node("UI/PhoneView") as Control
	_open_panels(desk)
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	check(mixer.visible and not phone.visible and _panels_closed(desk), "el mixer, sin paneles")
	desk.get_node("DeskPlane/Phone").clicked.emit()
	check(phone.visible and not mixer.visible, "el celular cierra el mixer")
	check_eq(phone.post_at_top(), 0, "con las publicaciones del catálogo")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	check(not phone.visible and (desk.get_node("UI/ChatPanel") as Control).visible, "abrir el chat cierra el celular")
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(not mixer.visible and (desk.get_node("UI/NotebookPanel") as Control).visible, "abrir el cuaderno cierra el mixer")
	desk.free()
	return true


func test_esc_y_un_clic_fuera_cierran_el_mixer_y_el_celular() -> bool:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	for object_name: String in ["Mixer", "Phone"]:
		for event: InputEvent in [escape, _click(MOUSE_BUTTON_LEFT)]:
			var desk := _make_desk()
			desk.get_node("DeskPlane/" + object_name).clicked.emit()
			desk._unhandled_input(event)
			check(not (desk.get_node("UI/MixerView") as Control).visible and not (desk.get_node("UI/PhoneView") as Control).visible,
					"%s cerrado" % object_name)
			desk.free()
	return true


func test_la_estatica_suena_al_anunciarse_una_interferencia() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	var sound := desk.get_node("InterferenceSound") as AudioStreamPlayer
	state.interferences.pending.clear()
	desk._process(0.0)
	check(not sound.playing, "en silencio")
	state.interferences.pending.append(InterferenceSchedule.Interference.new(1, state.elapsed + 2.0))
	desk._process(0.0)
	check(sound.playing, "suena la estática")
	desk.free()
	return true


func test_al_terminar_la_noche_se_cierran_el_mixer_y_el_celular() -> bool:
	var desk := _make_desk()
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	check(not (desk.get_node("UI/MixerView") as Control).visible, "el mixer se cierra: su ronda no sigue sonando")
	desk.free()
	return true
