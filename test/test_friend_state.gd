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
