extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const MIXER := preload("res://scenes/ui/mixer_view.tscn")
const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager


## Mixer conectado a un manager con el catálogo de prueba, en la noche 2 con Audio Sync de 4 tiempos.
func _make_mixer() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.catalog.nights()[1].audio_sync_beats = 4
	_manager.night_number = 2
	_manager.random_seed = 3
	_manager.requests_arrive = false
	root.add_child(_manager)
	var mixer := MIXER.instantiate()
	root.add_child(mixer)
	mixer.setup(_manager, _manager.catalog.friends)
	return mixer


func _free(mixer: Control) -> void:
	mixer.free()
	_manager.free()


func _click(button: MouseButton, position: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = position
	return click


func _space() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key


## Avanza el mixer hasta `time` segundos desde que empezó su ronda.
func _advance_to(mixer: Control, time: float) -> void:
	mixer._process(time - mixer.sync_round.elapsed)


## Golpea en cada aplauso del patrón de la ronda, a su hora.
func _tap_pattern(mixer: Control) -> void:
	var sync_round: AudioSyncRound = mixer.sync_round
	for call_step: int in sync_round.pattern.duplicate():
		_advance_to(mixer, sync_round.response_start() + call_step * sync_round.step_seconds)
		mixer.tap()


func test_se_abre_en_el_canal_con_menos_senal() -> bool:
	var mixer := _make_mixer()
	check(not mixer.visible, "oculto al inicio")
	_manager.state.friends[2].signal_level = 30.0
	mixer.open()
	check(mixer.visible, "se abre")
	check_eq(mixer.selected_friend, 2, "en el canal de Agustín, el de menos señal")
	check(mixer.sync_round == null, "sin ronda hasta que Matías la empiece")
	check_eq(mixer.status_text(), tr("MIXER_PICK"), "pide elegir un canal")
	_free(mixer)
	return true


func test_clic_en_un_canal_empieza_la_ronda() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer._gui_input(_click(MOUSE_BUTTON_LEFT, mixer.channel_rect(1).get_center()))
	check_eq(mixer.selected_friend, 1, "el canal de Gonzalo")
	check(mixer.sync_round != null and mixer.sync_round.beats == 4, "una ronda de 4 aplausos, la de la noche 2")
	check_eq(mixer.status_text(), tr("MIXER_COUNT_IN"), "empieza con la cuenta")
	_free(mixer)
	return true


func test_suenan_la_base_y_los_aplausos() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(0)
	mixer._process(0.01)
	check((mixer.get_node("Kick") as AudioStreamPlayer).playing, "la base empieza con la cuenta")
	_advance_to(mixer, mixer.sync_round.call_start() + 0.01)
	check((mixer.get_node("Clap") as AudioStreamPlayer).playing, "el amigo aplaude al comenzar su parte")
	check_eq(mixer.friend_level, 1.0, "su VU-metro, el de la derecha, se levanta")
	check_eq(mixer.player_level, 0.0, "el de Matías, no")
	check_eq(mixer.status_text(), tr("MIXER_LISTEN").format({"friend": tr(_manager.catalog.friends[0].name_key)}),
			"pide escuchar")
	mixer._process(0.2)
	check(mixer.friend_level < 1.0, "y la aguja vuelve a bajar")
	_free(mixer)
	return true


func test_si_repite_el_ritmo_la_senal_vuelve_a_100() -> bool:
	var mixer := _make_mixer()
	_manager.state.friends[1].signal_level = 0.0
	var notices := []
	_manager.message_added.connect(func(friend_index: int, _message: RefCounted) -> void: notices.append(friend_index))
	mixer.open()
	mixer.start_round(1)
	_tap_pattern(mixer)
	check(mixer.sync_round.succeeded, "salió bien")
	check_eq(_manager.state.friends[1].signal_level, 100.0, "la señal de Gonzalo vuelve a 100")
	check_eq(notices, [1], "y el chat avisa que volvió")
	check((mixer.get_node("Success") as AudioStreamPlayer).playing, "suena el acierto")
	check_eq(mixer.status_text(), tr("MIXER_SUCCESS").format({"friend": tr(_manager.catalog.friends[1].name_key)}), "lo dice")
	_free(mixer)
	return true


func test_fuera_de_ritmo_se_reintenta() -> bool:
	var mixer := _make_mixer()
	_manager.state.friends[0].signal_level = 40.0
	mixer.open()
	mixer.start_round(0)
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check(mixer.sync_round.failed, "no golpeó: sale mal")
	check_eq(_manager.state.friends[0].signal_level, 40.0, "la señal sigue igual")
	check((mixer.get_node("Fail") as AudioStreamPlayer).playing, "suena el error")
	check_eq(mixer.status_text(), tr("MIXER_FAIL"), "lo dice")
	mixer._unhandled_input(_space())
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con la barra espaciadora, otra ronda")
	_free(mixer)
	return true


func test_espacio_y_clic_marcan_el_ritmo() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(2)
	_advance_to(mixer, mixer.sync_round.response_start())
	mixer._unhandled_input(_space())
	check_eq(mixer.sync_round.hits().size(), 1, "la barra espaciadora acertó el primer aplauso")
	check_eq(mixer.player_level, 1.0, "el VU-metro de Matías, el de la izquierda, se levanta")
	check((mixer.get_node("Tap") as AudioStreamPlayer).playing, "suena su golpe")
	mixer._gui_input(_click(MOUSE_BUTTON_LEFT, Vector2(30, 30)))
	check(mixer.sync_round.failed, "un clic en el mixer también golpea: aquí sobró")
	_free(mixer)
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(0)
	mixer._gui_input(_click(MOUSE_BUTTON_RIGHT, Vector2(30, 30)))
	check(not mixer.visible, "cerrado")
	check(mixer.sync_round == null, "la ronda se corta")
	_free(mixer)
	return true


func test_sin_audio_sync_esa_noche() -> bool:
	var mixer := _make_mixer()
	_manager.night_number = 1
	mixer.open()
	mixer.start_round(0)
	check(mixer.sync_round == null, "en la noche 1 no hay rondas")
	check_eq(mixer.status_text(), tr("MIXER_NO_SYNC"), "y lo dice")
	_free(mixer)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var mixer_script := preload("res://scripts/ui/mixer_view.gd")
	for key: String in [mixer_script.TITLE_KEY, mixer_script.YOU_KEY, mixer_script.PICK_KEY, mixer_script.COUNT_IN_KEY,
			mixer_script.LISTEN_KEY, mixer_script.YOUR_TURN_KEY, mixer_script.SUCCESS_KEY, mixer_script.FAIL_KEY,
			mixer_script.HINT_KEY, mixer_script.NO_SYNC_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	for key: String in [mixer_script.LISTEN_KEY, mixer_script.SUCCESS_KEY]:
		check(String(TranslationServer.translate(key)).contains("{friend}"), "%s debe tener {friend}" % key)
	TranslationServer.set_locale(previous)
	return true


func test_se_abre_en_el_canal_de_un_amigo() -> bool:
	var mixer := _make_mixer()
	mixer.open_for(1)
	check(mixer.visible, "se abre")
	check_eq(mixer.selected_friend, 1, "en el canal de Gonzalo, aunque no sea el de menos señal")
	check(mixer.sync_round != null, "con la ronda empezada")
	_free(mixer)
	return true


## "Reducir destellos" (diseño §19): el LED de una interferencia queda encendido, sin parpadear.
func test_reducir_destellos() -> bool:
	var mixer := _make_mixer()
	mixer._blink = 0.18
	check_eq(mixer.warning_led(), 0.0, "parpadea: en este momento, apagado")
	mixer.reduce_flashes = true
	check_eq(mixer.warning_led(), 1.0, "fijo")
	_free(mixer)
	return true


## El mixer de la noche 2 con 8 aplausos: 2 rondas de 4 (decisión de Benja, 4 de noviembre).
func _make_two_round_mixer() -> Control:
	var mixer := _make_mixer()
	_manager.catalog.nights()[1].audio_sync_beats = 8
	return mixer


func test_8_aplausos_son_2_rondas_de_4() -> bool:
	var mixer := _make_two_round_mixer()
	check_eq(mixer.rounds_total(), 2, "2 rondas")
	_manager.state.friends[1].signal_level = 20.0
	mixer.open()
	mixer.start_round(1)
	check_eq(mixer.sync_round.beats, 4, "la primera, de 4 aplausos")
	check_eq(mixer.round_index, 0, "ronda 1")
	check(mixer.status_text().begins_with(tr("MIXER_ROUND").format({"round": 1, "total": 2})), "el mixer dice la ronda")
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "acertada la 1, pasa sola a la 2")
	check_eq(mixer.sync_round.beats, 4, "la segunda, también de 4")
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con su propia cuenta")
	check_eq(_manager.state.friends[1].signal_level, 20.0, "la señal todavía no vuelve")
	_tap_pattern(mixer)
	check(mixer.sync_round.succeeded, "salió bien la 2")
	check_eq(_manager.state.friends[1].signal_level, 100.0, "al terminar las 2, la señal vuelve a 100")
	_free(mixer)
	return true


func test_si_falla_la_segunda_vuelve_a_la_primera() -> bool:
	var mixer := _make_two_round_mixer()
	_manager.state.friends[0].signal_level = 40.0
	mixer.open()
	mixer.start_round(0)
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "va en la 2")
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check(mixer.sync_round.failed, "no golpeó: sale mal")
	check_eq(mixer.status_text(), tr("MIXER_FAIL_RESTART"), "dice que vuelve a la ronda 1")
	check_eq(_manager.state.friends[0].signal_level, 40.0, "la señal sigue igual")
	mixer._unhandled_input(_space())
	check_eq(mixer.round_index, 0, "vuelve a la ronda 1")
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con su cuenta")
	_free(mixer)
	return true


func test_si_falla_la_primera_se_reintenta_la_primera() -> bool:
	var mixer := _make_two_round_mixer()
	mixer.open()
	mixer.start_round(0)
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check_eq(mixer.status_text(), tr("MIXER_FAIL"), "el mensaje de siempre")
	mixer._unhandled_input(_space())
	check_eq(mixer.round_index, 0, "sigue en la ronda 1")
	_free(mixer)
	return true


func test_con_4_aplausos_hay_una_sola_ronda() -> bool:
	var mixer := _make_mixer()
	check_eq(mixer.rounds_total(), 1, "una ronda")
	mixer.open()
	mixer.start_round(0)
	check(not mixer.status_text().contains(tr("MIXER_ROUND").format({"round": 1, "total": 1})), "no dice 'ronda 1 de 1'")
	_free(mixer)
	return true


## La base de cada noche es la de NightData, y la segunda ronda va más rápida (decisión de Benja, 7 de noviembre).
func test_la_base_es_la_de_la_noche_y_la_segunda_ronda_va_mas_rapida() -> bool:
	var mixer := _make_two_round_mixer()
	_manager.catalog.nights()[1].audio_sync_bpm = 120.0
	mixer.open()
	mixer.start_round(0)
	check_eq(mixer.sync_round.step_seconds, 0.25, "la primera, a 120 golpes por minuto")
	_advance_to(mixer, mixer.sync_round.response_start())
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "pasó a la segunda")
	check(is_equal_approx(mixer.sync_round.step_seconds, 0.25 / 1.15), "la segunda, un 15 % más rápida")
	_free(mixer)
	return true


## La fila de luces muestra una ronda, no el total de aplausos: 16 luces hacían pensar en una secuencia de 16
## tiempos (decisión de Benja, 8 de noviembre).
func test_la_fila_de_luces_es_la_de_una_ronda() -> bool:
	var mixer := _make_mixer()
	check_eq(mixer.step_count(), 8, "4 aplausos: 8 luces")
	_manager.catalog.nights()[1].audio_sync_beats = 8
	check_eq(mixer.rounds_total(), 2, "8 aplausos son 2 rondas")
	check_eq(mixer.step_count(), 8, "y siguen siendo 8 luces")
	_manager.catalog.nights()[1].audio_sync_beats = 0
	check_eq(mixer.step_count(), 0, "sin Audio Sync, ninguna")
	_free(mixer)
	return true


## Una luz por ronda dice cuántas hay y cuáles se pasaron, antes de empezar (decisión de Benja, 9 de noviembre).
func test_las_luces_de_ronda_dicen_cuantas_hay_y_cuales_pasaron() -> bool:
	var mixer := _make_two_round_mixer()
	mixer.open()
	check_eq(mixer.round_light(0), mixer.LIGHT_OFF, "sin empezar, apagada")
	check_eq(mixer.round_light(1), mixer.LIGHT_OFF, "las 2")
	check(mixer.shows_round_lights(), "se ven antes de empezar")
	mixer.start_round(0)
	check_eq(mixer.round_light(0), mixer.CLAP_LIGHT, "la ronda en curso, azul")
	check_eq(mixer.round_light(1), mixer.LIGHT_OFF, "la que falta, apagada")
	_tap_pattern(mixer)
	check_eq(mixer.round_light(0), mixer.HIT_LIGHT, "la pasada, verde")
	check_eq(mixer.round_light(1), mixer.CLAP_LIGHT, "la siguiente, azul")
	_tap_pattern(mixer)
	check_eq(mixer.round_light(0), mixer.HIT_LIGHT, "al terminar, verde")
	check_eq(mixer.round_light(1), mixer.HIT_LIGHT, "las 2")
	_free(mixer)
	return true


## Al fallar la segunda se apagan: enseña que se vuelve a la primera.
func test_al_fallar_la_segunda_las_luces_de_ronda_se_apagan() -> bool:
	var mixer := _make_two_round_mixer()
	mixer.open()
	mixer.start_round(0)
	_tap_pattern(mixer)
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check(mixer.sync_round.failed, "no golpeó: sale mal")
	check_eq(mixer.round_light(0), mixer.LIGHT_OFF, "la primera se apaga")
	check_eq(mixer.round_light(1), mixer.LIGHT_OFF, "y la segunda también")
	_free(mixer)
	return true


func test_con_una_sola_ronda_no_hay_luces_de_ronda() -> bool:
	var mixer := _make_mixer()
	check(not mixer.shows_round_lights(), "no hay nada que contar")
	_free(mixer)
	return true
