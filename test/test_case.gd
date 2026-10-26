extends RefCounted
## Base mínima para las pruebas. Cada método test_* usa check()/check_eq()
## y termina con `return true` (si una prueba se cae a la mitad, devuelve null y cuenta como falla).

var errors: Array[String] = []


func reset_errors() -> void:
	errors.clear()


func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		errors.append("%s: esperado <%s>, obtenido <%s>" % [message, str(expected), str(actual)])
