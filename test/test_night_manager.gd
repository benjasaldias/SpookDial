extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

var _requests: RequestManager


## Reloj de la noche 1 del catálogo de prueba (2 videos, a los 140 s y a los 280 s, como si los soltaran 2 calmas),
## sin solicitudes que lleguen solas.
func _make_night() -> NightManager:
	var root := (Engine.get_main_loop() as SceneTree).root
	_requests = RequestManager.new()
	_requests.catalog = Fixtures.make_catalog()
	_requests.night_number = 1
	_requests.random_seed = 9
	_requests.requests_arrive = false
	root.add_child(_requests)
	_requests.state.videos.release(0, 140.0)
	_requests.state.videos.release(1, 280.0)
	var night := NightManager.new()
	root.add_child(night)
	night.setup(_requests)
	return night


func _free(night: NightManager) -> void:
	night.free()
	_requests.free()


## Guarda en `endings` cada final de la noche, como [cómo terminó, solicitud fatal].
func _record_endings(night: NightManager, endings: Array) -> void:
	night.night_ended.connect(func(ending: NightState.Ending, request: FriendRequest) -> void:
		endings.append([ending, request]))


## Avanza `seconds` de a 1 segundo, como lo haría el juego.
func _advance(night: NightManager, seconds: int) -> void:
	for _i in seconds:
		night.advance(1.0)


## Avanza `seconds` de a 1 segundo, con Matías descargando cada video apenas llega.
func _advance_downloading(night: NightManager, seconds: int) -> void:
	for _i in seconds:
		var offers: Array = night.state().videos.offers
		night.state().holding_download = offers[0].friend_index if not offers.is_empty() else -1
		night.advance(1.0)


func test_avanza_las_solicitudes_y_el_estado() -> bool:
	var night := _make_night()
	check(not _requests.is_processing(), "el manager ya no avanza solo")
	var request := _requests.start_request(0)
	night.advance(10.0)
	check_eq(request.time_left, 35.0, "el temporizador avanzó")
	check_eq(night.state().elapsed, 10.0, "la hora avanzó")
	_free(night)
	return true


func test_avisa_cuando_se_recibe_un_video() -> bool:
	var night := _make_night()
	var received := []
	night.video_received.connect(func(friend_index: int) -> void: received.append(friend_index))
	_advance(night, 140)
	var offers: Array = night.state().videos.offers
	check_eq(offers.size(), 1, "a los 140 s llega el primero")
	check(received.is_empty(), "falta descargarlo")
	if offers.size() == 1:
		var friend_index: int = offers[0].friend_index
		night.state().holding_download = friend_index
		_advance(night, 10)
		check_eq(received, [friend_index], "descargado")
	_free(night)
	return true


## La noche termina cuando se completa (Plan 9.9): la ola final resuelta (aquí, a mano), nada abierto y los videos
## recibidos, y 3 s después. Con la cuota, se gana.
func test_al_completarse_con_la_cuota_se_gana() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_advance_downloading(night, 420)
	check(endings.is_empty(), "a las 06:00 sigue: la ola final no ha terminado")
	_requests.director.phase = PacingDirector.Phase.DONE
	_advance_downloading(night, 2)
	check(endings.is_empty(), "completa, espera 3 s")
	_advance_downloading(night, 1)
	check_eq(endings, [[NightState.Ending.WON, null]], "ganó")
	check(night.ended, "terminó")
	_free(night)
	return true


func test_al_completarse_sin_la_cuota_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().videos.pending.clear()
	_requests.director.phase = PacingDirector.Phase.DONE
	_advance(night, 3)
	check_eq(endings, [[NightState.Ending.QUOTA, null]], "faltó contenido")
	_free(night)
	return true


func test_si_muere_un_amigo_se_pierde_en_el_acto() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_requests.catalog.balance.wrong_hurt_chance = 1.0
	night.state().friends[0].health = 1
	var request := _requests.start_request(0)
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	var wrong := request.entity.actions.filter(func(action: ActionData) -> bool:
		return action.id != rule.correct_action_id and action.id != rule.risky_action_id)
	_requests.answer(0, wrong[0])
	check_eq(endings, [[NightState.Ending.FRIEND_DIED, request]], "murió León, con la solicitud que lo explica")
	_free(night)
	return true


func test_con_sanity_en_0_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().sanity = 0.5
	night.advance(10.0)
	check_eq(endings, [[NightState.Ending.SANITY, null]], "Sanity")
	_free(night)
	return true


func test_al_terminar_todo_se_detiene() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	var request := _requests.start_request(1)
	night.state().trust = 0.0
	night.advance(1.0)
	var time_left := request.time_left
	_advance(night, 30)
	check_eq(endings.size(), 1, "termina una sola vez")
	check_eq(night.state().elapsed, 1.0, "la hora se detuvo")
	check_eq(request.time_left, time_left, "los temporizadores se detuvieron")
	_free(night)
	return true


func test_los_avisos_de_la_noche_llegan_al_chat() -> bool:
	var night := _make_night()
	var senders := []
	_requests.message_added.connect(func(_friend_index: int, message: ChatMessage) -> void:
		senders.append(message.sender))
	_advance(night, 140)
	check_eq(senders, [ChatMessage.Sender.FRIEND], "el amigo avisa que mandó el video")
	_advance(night, 15)
	check_eq(senders, [ChatMessage.Sender.FRIEND, ChatMessage.Sender.SYSTEM, ChatMessage.Sender.SYSTEM],
			"sin descargarlo se pierde, y el juego avisa que se perdió y que ya no alcanzan")
	_free(night)
	return true


func test_el_jumpscare_pausa_la_noche() -> bool:
	var night := _make_night()
	var request := _requests.start_request(1)
	night.pause(1.5)
	check(night.is_paused(), "en pausa")
	night.advance(1.0)
	check_eq(night.state().elapsed, 0.0, "la hora no avanza")
	check_eq(request.time_left, 45.0, "el temporizador tampoco")
	night.advance(1.0)
	check(not night.is_paused(), "la pausa terminó")
	check_eq(night.state().elapsed, 0.5, "avanza lo que sobra después de la pausa")
	check_eq(request.time_left, 44.5, "el temporizador también")
	_free(night)
	return true


## El tutorial termina cuando el escritorio lo dice: al completarse.
func test_terminar_la_noche_desde_afuera() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.finish(NightState.Ending.WON)
	night.finish(NightState.Ending.SANITY)
	check_eq(endings, [[NightState.Ending.WON, null]], "termina una sola vez")
	check(night.ended, "terminó")
	_free(night)
	return true


## Una solicitud que espera más de 30 s baja Trust, y la noche lo aplica en cada paso (decisión de Benja, 4 de
## noviembre).
func test_trust_baja_si_tardas_en_contestar() -> bool:
	var night := _make_night()
	var request := _requests.start_request(0)
	check(request != null, "llegó una solicitud")
	if request == null:
		_free(night)
		return true
	request.time_left = 500.0
	night.advance(10.0)
	check_eq(_requests.state.trust, 100.0, "a los 10 s, Trust sigue entera")
	night.advance(30.0)
	check(_requests.state.trust < 100.0, "a los 40 s, Trust bajó: %s" % _requests.state.trust)
	var before := _requests.state.trust
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	_requests.answer(0, request.entity.find_action(rule.correct_action_id))
	night.advance(1.0)
	check_eq(_requests.state.trust, before, "respondida, deja de bajar")
	_free(night)
	return true


# --- La noche espera la llamada (pedido de Benja, Plan 9.8): para leer la historia en vivo.

func test_la_noche_espera_que_se_abra_la_llamada() -> bool:
	var root := (Engine.get_main_loop() as SceneTree).root
	_requests = RequestManager.new()
	_requests.catalog = Fixtures.make_catalog()
	_requests.night_number = 1
	_requests.requests_arrive = false
	_requests.night().story = Fixtures.make_story(_requests.catalog)
	root.add_child(_requests)
	var night := NightManager.new()
	root.add_child(night)
	night.setup(_requests)
	check(_requests.waiting_for_call, "empieza esperando la llamada")
	_advance(night, 10)
	check_eq(_requests.state.elapsed, 0.0, "la hora no corre")
	check_eq(_requests.state.sanity, 100.0, "Sanity no baja")
	check(night.is_paused(), "cuenta como pausada: la Mano y los screamers esperan")
	_requests.call_opened()
	check(not _requests.waiting_for_call, "se abrió")
	_advance(night, 10)
	check_eq(_requests.state.elapsed, 10.0, "ahora sí corre")
	check(not night.is_paused(), "ya no está pausada")
	_free(night)
	return true


func test_sin_historia_no_espera() -> bool:
	var night := _make_night()
	check(not _requests.waiting_for_call, "sin historia, la noche empieza sola")
	_advance(night, 5)
	check_eq(_requests.state.elapsed, 5.0, "corre")
	_free(night)
	return true
