extends "res://test/test_case.gd"

const DialMath := preload("res://scripts/desk/dial_math.gd")


func test_valor_cero_y_uno_dan_los_extremos() -> bool:
	check_eq(DialMath.value_to_degrees(0.0, -120.0, 120.0), -120.0, "valor 0")
	check_eq(DialMath.value_to_degrees(1.0, -120.0, 120.0), 120.0, "valor 1")
	return true


func test_valor_medio_apunta_arriba() -> bool:
	check_eq(DialMath.value_to_degrees(0.5, -120.0, 120.0), 0.0, "valor 0,5")
	return true


func test_valores_fuera_de_rango_se_limitan() -> bool:
	check_eq(DialMath.value_to_degrees(-0.3, -120.0, 120.0), -120.0, "bajo 0")
	check_eq(DialMath.value_to_degrees(1.7, -120.0, 120.0), 120.0, "sobre 1")
	return true
