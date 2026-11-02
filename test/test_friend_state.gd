extends "res://test/test_case.gd"

const FriendState := preload("res://scripts/core/friend_state.gd")


func test_empieza_sano_y_disponible() -> bool:
	var friend := FriendState.new(3)
	check_eq(friend.health, 3, "vida")
	check_eq(friend.max_health, 3, "vida máxima")
	check_eq(friend.signal_level, 100.0, "señal llena")
	check(friend.is_alive() and not friend.is_stunned() and friend.is_available(), "vivo, despierto y disponible")
	return true


func test_herido_queda_aturdido() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(1, 15.0)
	check_eq(friend.health, 2, "pierde 1 PV")
	check(friend.is_stunned() and not friend.is_available(), "aturdido: no está disponible")
	friend.advance(14.9)
	check(friend.is_stunned(), "a los 14,9 s sigue aturdido")
	friend.advance(0.2)
	check(not friend.is_stunned() and friend.is_available(), "a los 15 s vuelve")
	return true


func test_con_0_pv_muere() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(2, 15.0)
	friend.hurt(2, 15.0)
	check_eq(friend.health, 0, "la vida no baja de 0")
	check(not friend.is_alive() and not friend.is_available(), "muerto")
	check(not friend.is_stunned(), "un amigo muerto no queda aturdido")
	return true


func test_la_senal_baja_con_el_tiempo() -> bool:
	var friend := FriendState.new(3)
	friend.advance(30.0)
	check_eq(friend.signal_level, 100.0, "sin ritmo de bajada no baja, como en la noche 1")
	friend.signal_decay_interval = 5.0
	friend.advance(50.0)
	check(is_equal_approx(friend.signal_level, 90.0), "−1 cada 5 s: %s" % friend.signal_level)
	friend.advance(1000.0)
	check_eq(friend.signal_level, 0.0, "no baja de 0")
	return true


func test_sin_senal_esta_desconectado() -> bool:
	var friend := FriendState.new(3)
	check(friend.is_online() and friend.can_send(), "conectado: puede enviar videos")
	friend.interfere(40.0)
	check_eq(friend.signal_level, 60.0, "una interferencia le quita 40")
	friend.interfere(80.0)
	check_eq(friend.signal_level, 0.0, "no baja de 0")
	check(not friend.is_online(), "desconectado")
	check(friend.is_available(), "igual le llegan solicitudes (decisión de Benja)")
	check(not friend.can_send(), "pero no puede enviar videos")
	friend.restore_signal()
	check_eq(friend.signal_level, 100.0, "Audio Sync: vuelve a 100")
	check(friend.is_online(), "conectado otra vez")
	return true


func test_aturdido_no_envia_videos() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(1, 15.0)
	check(friend.is_online() and not friend.can_send(), "aturdido: no envía")
	return true
