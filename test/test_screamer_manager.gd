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
	director.jumpscare_slots.assign([0] if jumpscare else [])


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


## La criatura se arma detrás de un panel (el chat o el mixer) y está ahí al cerrarlo (decisión de Benja, 4 de
## noviembre), con la respiración y los golpes sonando mientras tanto, sin tapar la pantalla ni pausar la noche.
func test_la_criatura_se_arma_detras_de_un_panel() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var chat := desk.get_node("UI/ChatPanel") as Control
	var figure := desk.get_node("WallPlane/Enemy") as CanvasItem
	var sanity := _state(desk).sanity
	_scare_now(desk, true)
	desk._process(0.0)
	check(not screamers.is_warning(), "con la ventana a la vista, espera")
	chat.show()
	desk._process(0.0)
	check(screamers.is_warning(), "con el chat abierto, se anuncia")
	desk._process(1.0)
	check(screamers.is_creature_near(), "la criatura está cerca")
	check(not figure.visible, "pero no se ve: el chat tapa la ventana")
	check((screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "se oye su respiración")
	check((screamers.get_node("CreatureKnocks") as AudioStreamPlayer).playing, "y sus golpes en el vidrio")
	check_eq(_state(desk).sanity, sanity - 15.0, "Sanity −15")
	check(not desk.get_node("NightManager").is_paused(), "la noche no se pausa")
	chat.hide()
	desk._process(0.0)
	check(figure.visible, "al cerrar el chat, ya está ahí")
	check_eq(figure.modulate.a, 1.0, "sin animación de entrada")
	desk._process(24.9)
	check(figure.visible, "a los 24,9 s de llegar, todavía")
	desk._process(0.2)
	check(not screamers.is_creature_near(), "a los 25 s, se va")
	check(not (screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "y se calla")
	desk.free()
	return true


## Hace llegar a la criatura detrás del chat y cierra el chat: queda a la vista.
func _creature_at_window(desk: Node2D) -> void:
	var chat := desk.get_node("UI/ChatPanel") as Control
	_scare_now(desk, true)
	chat.show()
	desk._process(0.0)
	desk._process(1.0)
	chat.hide()
	desk._process(0.0)


## Mientras la criatura está afuera, la cortina abierta baja Sanity rápido (decisión de Benja, 7 de noviembre).
func test_la_criatura_afuera_baja_sanity() -> bool:
	var desk := _make_desk()
	_creature_at_window(desk)
	check(_state(desk).creature_outside, "la noche sabe que está afuera")
	desk._process(25.0)
	check(not _state(desk).creature_outside, "cuando se va, ya no")
	desk.free()
	return true


## Si la cortina estaba cerrada, la criatura la abre al llegar (idea de Benja, 7 de noviembre).
func test_la_criatura_abre_la_cortina_cerrada() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	curtains.clicked.emit()
	check_eq(curtains.animation, &"Closed", "cerrada")
	_creature_at_window(desk)
	check_eq(curtains.animation, &"Open", "la criatura la abrió")
	check(not _state(desk).curtains_closed, "y la noche lo sabe")
	desk.free()
	return true


## Se queda un tiempo fijo, aunque se cierre la cortina: hay que abrirla para ver si sigue ahí. Con la cortina
## cerrada no se oye, para que haya que revisar (decisión de Benja, 7 de noviembre).
func test_cerrar_la_cortina_no_la_espanta() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	var breathing := screamers.get_node("CreatureBreathing") as AudioStreamPlayer
	var knocks := screamers.get_node("CreatureKnocks") as AudioStreamPlayer
	_creature_at_window(desk)
	curtains.clicked.emit()
	desk._process(0.5)
	check(screamers.is_creature_near(), "sigue ahí")
	check(not breathing.playing and not knocks.playing, "pero no se oye")
	curtains.clicked.emit()
	desk._process(0.0)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "al abrir la cortina, se ve")
	check(breathing.playing, "y se oye")
	curtains.clicked.emit()
	desk._process(24.6)
	check(not screamers.is_creature_near(), "se fue sola, a su hora")
	check(not _state(desk).creature_outside, "y al abrir la cortina ya no baja Sanity rápido")
	desk.free()
	return true


## Detrás de un panel, sus golpes se repiten: son el aviso de que hay que ir a la ventana.
func test_detras_de_un_panel_los_golpes_se_repiten() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel") as Control
	var knocks := _screamers(desk).get_node("CreatureKnocks") as AudioStreamPlayer
	_scare_now(desk, true)
	chat.show()
	desk._process(0.0)
	desk._process(1.0)
	knocks.stop()
	desk._process(0.1)
	check(knocks.playing, "vuelven a sonar")
	desk.free()
	return true


## Con la ventana a la vista (el susto guionado de la noche 0), la criatura aparece enseguida.
func test_la_criatura_aparece_enseguida_con_la_ventana_a_la_vista() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	screamers.play(ScareKind.Kind.JUMPSCARE)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "se ve en la ventana")
	check(screamers.is_creature_near(), "está cerca")
	desk.free()
	return true


## Mientras la criatura está cerca no empieza otro screamer; cuando se retira, sí.
func test_con_la_criatura_cerca_no_empiezan_otros_screamers() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	_screamers(desk).play(ScareKind.Kind.JUMPSCARE)
	_scare_now(desk)
	_process(desk, 3)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "solo la criatura")
	_process(desk, 24)
	check(kinds.size() >= 2, "al irse, llega el otro: %s" % [kinds])
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
	var desk := _make_desk(0)
	# Sin las solicitudes del tutorial: el susto guionado las espera.
	desk.get_node("RequestManager").tutorial_queue.clear()
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	var phone := desk.get_node("DeskPlane/Phone")
	var kinds := []
	_record(desk, kinds)
	# A los 5 s, sin nada pendiente: la señal previa y, 1 s después, la criatura de la ventana.
	_play(desk, 6)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "el susto guionado de la noche 0")
	# Lo que tarda Gonzalo en escribir (2,5 s).
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


## Cuántas veces vuelve a oscurecerse una secuencia de opacidades: cada vuelta es un destello.
func _flashes(alphas: Array[float]) -> int:
	var count := 0
	var previous := 0.0
	var falling := false
	for alpha: float in alphas:
		if alpha < previous:
			falling = true
		elif alpha > previous and falling:
			count += 1
		previous = alpha
	return count


## "Reducir destellos" (diseño §19): la señal previa y el apagón de las luces se oscurecen
## una sola vez, más suave, en lugar de parpadear.
func test_reducir_destellos() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	check(_flashes(screamers.warning_alphas()) > 0, "la señal previa parpadea")
	check(_flashes(screamers.lights_alphas()) > 0, "las luces parpadean")
	screamers.reduce_flashes = true
	for alphas: Array[float] in [screamers.warning_alphas(), screamers.lights_alphas()]:
		check_eq(_flashes(alphas), 0, "sin destellos: %s" % [alphas])
		check(alphas.max() <= 0.85, "sin pasar de la oscuridad de las luces: %s" % [alphas])
	desk.free()
	return true


## El screamer de la ventana y la criatura comparten la figura: el desvanecimiento del uno no esconde al otro.
func test_la_criatura_corta_el_desvanecimiento_del_screamer_de_la_ventana() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	screamers.play(ScareKind.Kind.WINDOW)
	var window_tween: Tween = screamers._figure_tween
	check(window_tween.is_valid(), "el screamer de la ventana se desvanece solo")
	screamers.play(ScareKind.Kind.JUMPSCARE)
	check(not window_tween.is_valid(), "la criatura corta ese desvanecimiento")
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "y se queda a la vista")
	desk.free()
	return true


## El screamer de la cortina ya no la mece: se abre o se cierra sola (decisión de Benja, 7 de noviembre).
func test_la_cortina_se_abre_o_se_cierra_sola() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	_screamers(desk).play(ScareKind.Kind.CURTAINS)
	check_eq(curtains.animation, &"Closed", "abierta, se cierra sola")
	check(_state(desk).curtains_closed, "y la noche lo sabe")
	_screamers(desk).play(ScareKind.Kind.CURTAINS)
	check_eq(curtains.animation, &"Open", "cerrada, se abre sola")
	desk.free()
	return true


func test_nunca_en_los_ultimos_5_s_de_un_accidente() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	manager.start_incident(0)
	manager.incidents[0].time_left = 4.0
	_scare_now(desk)
	desk._process(0.0)
	check(not _screamers(desk).is_warning(), "espera a que el jugador responda")
	desk.free()
	return true


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
func test_nada_mientras_suena_un_audio() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel")
	chat.open_for(0)
	var clip := chat.get_node("AudioClip") as AudioStreamPlayer
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var data := PackedByteArray()
	data.resize(44100 * 20)
	stream.data = data
	clip.stream = stream
	clip.play()
	_scare_now(desk)
	_state(desk).elapsed = 100.0
	_process(desk, 3)
	check(not _screamers(desk).is_warning(), "no se anuncia nada")
	desk.free()
	return true


func _desk_surface(desk: Node2D) -> AnimatedSprite2D:
	return desk.get_node("DeskPlane/DeskSurface") as AnimatedSprite2D


## La sombra sobre el escritorio solo está cuando algo se asoma por la ventana (decisión de Benja, 8 de noviembre).
func test_sin_nadie_en_la_ventana_no_hay_sombra() -> bool:
	var desk := _make_desk()
	check_eq(_desk_surface(desk).animation, &"NoEnemy", "el escritorio empieza limpio")
	desk.free()
	return true


func test_la_criatura_hace_sombra_hasta_que_se_va() -> bool:
	var desk := _make_desk()
	_screamers(desk).play(ScareKind.Kind.JUMPSCARE)
	check_eq(_desk_surface(desk).animation, &"Enemy", "se asoma: hay sombra")
	desk._process(25.0)
	check_eq(_desk_surface(desk).animation, &"NoEnemy", "se fue: ya no")
	desk.free()
	return true


## Con la cortina cerrada no hay sombra: si no, delataría a la criatura y no haría falta abrir para revisar.
func test_la_cortina_cerrada_tapa_la_sombra() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	_screamers(desk).play(ScareKind.Kind.JUMPSCARE)
	curtains.clicked.emit()
	check_eq(_desk_surface(desk).animation, &"NoEnemy", "cerrada, no se nota")
	curtains.clicked.emit()
	check_eq(_desk_surface(desk).animation, &"Enemy", "al abrirla, se ve otra vez")
	desk.free()
	return true


## Detrás de un panel la criatura todavía no se ve: la sombra aparece junto con ella.
func test_detras_de_un_panel_la_sombra_espera() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel") as Control
	chat.show()
	desk._process(0.0)
	_screamers(desk).play(ScareKind.Kind.JUMPSCARE)
	check_eq(_desk_surface(desk).animation, &"NoEnemy", "tapada, sin sombra")
	chat.hide()
	desk._process(0.1)
	check_eq(_desk_surface(desk).animation, &"Enemy", "al cerrar el chat, con sombra")
	desk.free()
	return true


## El screamer de la ventana usa la misma figura, así que también hace sombra mientras se ve.
func test_el_screamer_de_la_ventana_hace_sombra() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	screamers.play(ScareKind.Kind.WINDOW)
	check_eq(_desk_surface(desk).animation, &"Enemy", "aparece con sombra")
	screamers._figure_tween.custom_step(10.0)
	check_eq(_desk_surface(desk).animation, &"NoEnemy", "se desvanece sin sombra")
	desk.free()
	return true
