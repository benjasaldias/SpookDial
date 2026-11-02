extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

var _requests: RequestManager


## Reloj de la noche 1 del catálogo de prueba (2 videos, a los 140 s y a los 280 s), sin solicitudes
## que lleguen solas.
func _make_night() -> NightManager:
	var root := (Engine.get_main_loop() as SceneTree).root
	_requests = RequestManager.new()
	_requests.catalog = Fixtures.make_catalog()
	_requests.night_number = 1
	_requests.random_seed = 9
	_requests.requests_arrive = false
	root.add_child(_requests)
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


func test_a_las_06_con_la_cuota_se_gana() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_advance_downloading(night, 419)
	check(endings.is_empty(), "a los 419 s sigue")
	_advance_downloading(night, 1)
	check_eq(endings, [[NightState.Ending.WON, null]], "ganó a las 06:00")
	check(night.ended, "terminó")
	_free(night)
	return true


func test_a_las_06_sin_la_cuota_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().videos.pending.clear()
	_advance(night, 420)
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
	check_eq(senders, [ChatMessage.Sender.FRIEND, ChatMessage.Sender.SYSTEM], "sin descargarlo se pierde, y el juego lo avisa")
	_free(night)
	return true
