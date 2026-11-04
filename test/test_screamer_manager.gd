extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const NightState := preload("res://scripts/core/night_state.gd")


## El escritorio en la noche `night_number`, con un azar fijo. Nada avanza solo: las pruebas llaman a
## desk._process().
func _make_desk(night_number := 3) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").random_seed = 11
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func _screamers(desk: Node2D) -> Node:
	return desk.get_node_or_null("Screamers")


func _state(desk: Node2D) -> NightState:
	return desk.get_node("RequestManager").state


## El próximo screamer del director toca ahora. Si `jumpscare`, es el jumpscare.
func _scare_now(desk: Node2D, jumpscare := false) -> void:
	var director: RefCounted = desk.get_node("RequestManager").director
	director.scare_times.assign([_state(desk).elapsed])
	director.jumpscare_at = 0 if jumpscare else -1


## Guarda en `kinds` cada screamer que empieza.
func _record(desk: Node2D, kinds: Array) -> void:
	_screamers(desk).scare_started.connect(func(kind: ScareKind.Kind) -> void: kinds.append(kind))


## Avanza el escritorio `seconds` segundos, de a 1.
func _process(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk._process(1.0)


func test_la_figura_de_la_ventana_esta_escondida() -> bool:
	var desk := _make_desk()
	check(not (desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura no está (decisión de Benja)")
	check(not (desk.get_node("Overlay/Jumpscare") as Control).visible, "sin jumpscare")
	check((desk.get_node("Ambient") as AudioStreamPlayer).playing, "suena el ambiente del cuarto")
	desk.free()
	return true


func test_un_screamer_se_anuncia_y_resta_sanity() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	var sanity := _state(desk).sanity
	_scare_now(desk)
	desk._process(0.0)
	check(_screamers(desk).is_warning(), "primero, la señal previa")
	check(kinds.is_empty(), "todavía no asusta")
	desk._process(1.0)
	check_eq(kinds.size(), 1, "después de 1 s, el screamer")
	if kinds.size() == 1:
		check(kinds[0] in [ScareKind.Kind.LIGHTS, ScareKind.Kind.CURTAINS, ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE],
				"con el escritorio a la vista, uno ambiental: %s" % kinds[0])
	check_eq(_state(desk).sanity, sanity - 8.0, "Sanity −8")
	desk.free()
	return true


func test_el_jumpscare_tapa_la_pantalla_y_pausa_la_noche() -> bool:
	var desk := _make_desk()
	var sanity := _state(desk).sanity
	_scare_now(desk, true)
	desk._process(0.0)
	desk._process(1.0)
	check((desk.get_node("Overlay/Jumpscare") as Control).visible, "tapa la pantalla")
	check(desk.get_node("NightManager").is_paused(), "la noche se pausa")
	check_eq(_state(desk).sanity, sanity - 15.0, "Sanity −15")
	desk.get_node("NightManager").advance(1.0)
	check_eq(_state(desk).elapsed, 0.0, "la hora no avanza durante el jumpscare")
	desk.free()
	return true


func test_cada_screamer_hace_lo_suyo() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	screamers.play(ScareKind.Kind.WINDOW)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura aparece en la ventana")
	for kind: ScareKind.Kind in [ScareKind.Kind.CURTAINS, ScareKind.Kind.PHONE, ScareKind.Kind.LIGHTS]:
		screamers.play(kind)
		check((screamers.get_node(screamers.SOUND_NODES[kind]) as AudioStreamPlayer).playing, "suena: %s" % kind)
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	screamers.play(ScareKind.Kind.INK)
	check((notebook.get_node("InkBlot") as Control).visible, "la tinta tapa la página")
	screamers.play(ScareKind.Kind.NOTEBOOK_SLAM)
	check(not notebook.visible, "el cuaderno se cierra de golpe")
	desk.free()
	return true


func test_nunca_en_los_ultimos_5_s_de_una_decision() -> bool:
	var desk := _make_desk()
	var request: RefCounted = desk.get_node("RequestManager").start_request(0)
	request.time_left = 6.0
	_scare_now(desk)
	desk._process(0.0)
	check(not _screamers(desk).is_warning(), "a la decisión le quedan 6 s: espera")
	request.time_left = 20.0
	desk._process(0.0)
	check(_screamers(desk).is_warning(), "con tiempo de sobra, sí")
	desk.free()
	return true


func test_nada_durante_audio_sync() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	var sounds := []
	_screamers(desk).hallucinated.connect(func(sound: AudioStream) -> void: sounds.append(sound))
	desk.open_mixer_for(0)
	_state(desk).sanity = 1.0
	_scare_now(desk)
	_process(desk, 30)
	check(kinds.is_empty(), "ningún screamer durante la ronda")
	check(sounds.is_empty(), "ninguna alucinación durante la ronda")
	desk.close_modes()
	_process(desk, 2)
	check_eq(kinds.size(), 1, "al terminar, llega el que esperaba")
	desk.free()
	return true


func test_alucinaciones_con_sanity_bajo() -> bool:
	var desk := _make_desk()
	var sounds := []
	var screamers := _screamers(desk)
	screamers.hallucinated.connect(func(sound: AudioStream) -> void: sounds.append(sound))
	_process(desk, 60)
	check(sounds.is_empty(), "con Sanity llena, ninguna")
	_state(desk).sanity = 1.0
	_process(desk, 60)
	check(sounds.size() >= 4, "con Sanity en 1, varias: %d" % sounds.size())
	var allowed: Array = screamers.hallucination_sounds
	check_eq(allowed.size(), 6, "golpes, pasos, susurros, rasguños, la estática y el celular")
	check(sounds.all(func(sound: AudioStream) -> bool: return allowed.has(sound)), "solo esos")
	desk.free()
	return true


func test_al_terminar_la_noche_no_hay_mas_screamers() -> bool:
	var desk := _make_desk()
	check(_screamers(desk) != null, "el escritorio tiene sus screamers")
	var kinds := []
	_record(desk, kinds)
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	_scare_now(desk)
	_process(desk, 2)
	check(kinds.is_empty(), "la noche terminó")
	desk.free()
	return true


## Avanza la noche y el escritorio `seconds` segundos, de a 1, como en el juego.
func _play(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk.get_node("NightManager").advance(1.0)
		desk._process(1.0)


func test_el_susto_guionado_ensena_el_celular() -> bool:
	var desk := _make_desk(1)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	var phone := desk.get_node("DeskPlane/Phone")
	var kinds := []
	_record(desk, kinds)
	# A los 60 s, sin solicitudes: la señal previa y, 1 s después, el jumpscare.
	_play(desk, 61)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "el susto guionado de la noche 1")
	# La pausa del jumpscare (1,5 s) y lo que tarda Gonzalo en escribir (2,5 s).
	_play(desk, 4)
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "Gonzalo escribió y espera la respuesta de Matías")
	gonzalo.pressed.emit()
	var reply := desk.get_node("UI/ChatPanel/Panel/ScriptReply") as Button
	check(reply.visible, "el botón con la respuesta de Matías")
	check_eq(reply.text, String(TranslationServer.translate("SCRIPT_SCARE_REPLY")), "su línea")
	reply.pressed.emit()
	_play(desk, 3)
	check_eq(desk.get_node("UI/ChatPanel").message_views(1).size(), 3, "las 3 líneas del chat guionado")
	check(phone.blinking, "Gonzalo le dijo que use el celular, y el celular parpadea")
	phone.clicked.emit()
	check(not phone.blinking, "al abrirlo, deja de parpadear")
	check((desk.get_node("UI/PhoneView") as Control).visible, "se abrió el celular")
	desk.free()
	return true
