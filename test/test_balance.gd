extends "res://test/test_case.gd"

const BALANCE_PATH := "res://data/balance.tres"


## Los valores iniciales de docs/02 §5.2 y §6.
func test_valores_de_docs_02() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.night_seconds, 420.0, "una noche dura 7 minutos")
	check_eq(balance.friend_health, 3, "3 PV")
	check_eq(balance.stun_seconds, 15.0, "aturdido 15 s")
	check_eq(balance.risky_hurt_chance, 0.7, "mayor riesgo: 70 %")
	check_eq(balance.risky_damage, 2, "mayor riesgo: −2 PV")
	check_eq(balance.risky_trust, -20.0, "mayor riesgo: Trust −20")
	check_eq(balance.wrong_hurt_chance, 0.6, "incorrecta: 60 %")
	check_eq(balance.wrong_damage, 1, "incorrecta: −1 PV")
	check_eq(balance.wrong_trust, -10.0, "incorrecta: Trust −10")
	check_eq(balance.no_answer_trust, -15.0, "sin respuesta: Trust −15 extra")
	check_eq(balance.trust_recovery_interval, 8.0, "Trust +1 cada 8 s")
	check_eq(balance.trust_recovery_delay, 20.0, "si no hubo errores en 20 s")
	return true


## Las pruebas usan BalanceData.new(): sus valores por defecto deben ser los de data/balance.tres.
func test_los_valores_por_defecto_son_los_del_archivo() -> bool:
	var saved: BalanceData = load(BALANCE_PATH)
	var defaults := BalanceData.new()
	for property: Dictionary in defaults.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var property_name: String = property["name"]
			check_eq(saved.get(property_name), defaults.get(property_name), property_name)
	return true


func test_el_catalogo_usa_el_equilibrio() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check(catalog.balance != null, "catalog.tres tiene Balance")
	if catalog.balance != null:
		check_eq(catalog.balance.resource_path, BALANCE_PATH, "es data/balance.tres")
	return true
