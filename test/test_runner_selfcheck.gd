extends "res://test/test_case.gd"


func test_check_eq_registra_diferencias() -> bool:
	var probe: RefCounted = load("res://test/test_case.gd").new()
	probe.check_eq(1, 2, "uno contra dos")
	probe.check_eq(3, 3, "tres contra tres")
	check_eq(probe.errors.size(), 1, "errores registrados")
	return true
