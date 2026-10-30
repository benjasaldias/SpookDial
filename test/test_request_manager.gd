extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")


## Manager con el catálogo de prueba, en la noche 1 (solo "beast"), sin que las solicitudes lleguen solas.
func _make_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## Guarda en `events` cada señal del manager, como [nombre, amigo, mensaje o solicitud].
func _record(manager: RequestManager, events: Array) -> void:
	for signal_name: String in ["message_added", "request_started", "request_changed", "request_finished"]:
		manager.connect(signal_name, func(friend_index: int, item: RefCounted) -> void:
			events.append([signal_name, friend_index, item]))


func _messages(events: Array) -> Array:
	return events.filter(func(entry: Array) -> bool: return entry[0] == "message_added") \
			.map(func(entry: Array) -> ChatMessage: return entry[2])


func test_empieza_sin_solicitudes() -> bool:
	var manager := _make_manager()
	check_eq(manager.requests, [null, null, null], "sin solicitudes")
	check_eq(manager.signal_levels, [100.0, 100.0, 100.0], "señal llena")
	check_eq(manager.active_count(), 0, "activas")
	manager.free()
	return true


func test_una_solicitud_llega_con_su_mensaje() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(1)
	check(request != null, "se crea")
	check_eq(manager.requests[1], request, "es la de Gonzalo")
	check_eq(request.time_left, 45.0, "tiempo base de la noche 1")
	check_eq(events.size(), 2, "dos señales")
	if events.size() == 2:
		check_eq(events[0], ["request_started", 1, request], "empezó")
		var message: ChatMessage = events[1][2]
		check_eq(events[1][0], "message_added", "mensaje")
		check_eq(message.request, request, "el mensaje es de la solicitud")
		check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo envía el amigo")
	check_eq(manager.start_request(1), null, "un amigo no recibe dos solicitudes a la vez")
	manager.free()
	return true


func test_preguntar_agrega_2_mensajes_y_cuesta_5_segundos() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	check(manager.ask(0, ClueCategory.Kind.SIGHT), "se pudo preguntar")
	var messages := _messages(events)
	check_eq(messages.size(), 2, "pregunta y respuesta")
	if messages.size() == 2:
		check_eq((messages[0] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "pregunta de Matías")
		check_eq((messages[1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "respuesta del amigo")
	check_eq(request.time_left, 40.0, "costó 5 s")
	check(not manager.ask(1, ClueCategory.Kind.SIGHT), "sin solicitud no se pregunta")
	manager.free()
	return true


func test_clic_en_las_caracteristicas_hasta_el_nombre() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(0)
	var message: ChatMessage = _messages(events)[0]
	events.clear()
	for trait_data: TraitData in request.traits:
		check_eq(manager.click_clue(message, trait_data.id), FriendRequest.ClueState.MARKED, "marca %s" % trait_data.id)
	check_eq(request.identification, FriendRequest.Identification.THINKING, "Matías piensa")
	check_eq(events.size(), 2, "un aviso por clic")
	events.clear()
	manager.advance(3.1)
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "apareció el nombre")
	check_eq(events, [["request_changed", 0, request]], "aviso del nombre")
	manager.free()
	return true


func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	var events := []
	_record(manager, events)
	manager.advance(request.time_left + 0.1)
	check_eq(manager.requests[2], null, "Agustín queda libre")
	check(request.finished and not request.answered_by_player, "decidió solo")
	check_eq(events.size(), 2, "mensaje y fin")
	if events.size() == 2:
		check_eq(events[0][0], "message_added", "cuenta lo que hizo")
		check_eq(events[1], ["request_finished", 2, request], "terminó")
	check_eq(manager.click_clue(_messages(events)[0], request.traits[0].id), FriendRequest.ClueState.UNMARKED,
			"los mensajes de una solicitud terminada ya no se clickean")
	manager.free()
	return true


func test_las_solicitudes_llegan_solas() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	manager.advance(4.9)
	check_eq(manager.active_count(), 0, "a los 4,9 s todavía no")
	manager.advance(0.2)
	check_eq(manager.active_count(), 1, "a los 5,1 s llega la primera")
	# Noche 1: 6 solicitudes, así que llegan cada 70 s. La primera se acaba a los 45 s (a los 50,1 s del total).
	manager.advance(69.0)
	check_eq(manager.active_count(), 0, "la primera ya terminó")
	manager.advance(1.0)
	check_eq(manager.active_count(), 1, "70 s después de la primera llega la segunda")
	manager.free()
	return true


func test_no_pasa_de_las_simultaneas_ni_del_total() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	var night := manager.night()
	night.requests_total = 2
	night.max_simultaneous = 1
	night.base_decision_time = 100.0
	manager.advance(5.0)
	manager.advance(90.0)
	check_eq(manager.active_count(), 1, "no pasa de 1 simultánea")
	for _i in 20:
		manager.advance(30.0)
	check_eq(manager.active_count(), 0, "no pasa de 2 en la noche")
	manager.free()
	return true


func test_la_estatica_depende_de_la_senal() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	manager.signal_levels[0] = 100.0
	manager.signal_levels[1] = 1.0
	for _i in 10:
		manager.start_request(0)
		manager.start_request(1)
		manager.advance(60.0)
	var covered := [0, 0]
	for entry: Array in events:
		if entry[0] == "message_added":
			for token: ChatMessage.Token in (entry[2] as ChatMessage).tokens:
				if token.covered:
					covered[entry[1]] += 1
	check_eq(covered[0], 0, "con señal 100 no hay estática")
	check(covered[1] > 0, "con señal 1 hay estática")
	manager.free()
	return true
