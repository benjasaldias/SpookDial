extends "res://test/test_case.gd"
## Qué publicación va en cada lugar del feed de Snapgram: gatitos y, con poca Sanity, fotos perturbadoras
## (decisión de Benja, 9 de noviembre).

const PhoneFeed := preload("res://scripts/core/phone_feed.gd")

var _posts: Array[PhonePostData] = []
var _disturbing: Array[PhonePostData] = []
var _balance := BalanceData.new()


func _make_posts(count: int) -> Array[PhonePostData]:
	var posts: Array[PhonePostData] = []
	for _index in count:
		posts.append(PhonePostData.new())
	return posts


func _prepare() -> void:
	_posts = _make_posts(5)
	_disturbing = _make_posts(4)


func _post(slot: int, sanity: float) -> PhonePostData:
	return PhoneFeed.post_for_slot(slot, sanity, _posts, _disturbing, _balance)


## Cuántas perturbadoras hay en los primeros `slots` lugares.
func _count_disturbing(slots: int, sanity: float) -> int:
	var count := 0
	for slot in slots:
		if _disturbing.has(_post(slot, sanity)):
			count += 1
	return count


func test_con_sanity_30_o_mas_solo_hay_gatitos_en_orden() -> bool:
	_prepare()
	for slot in 24:
		check_eq(_post(slot, 30.0), _posts[slot % 5], "lugar %d" % slot)
	return true


func test_bajo_30_es_perturbadora_una_de_cada_6() -> bool:
	_prepare()
	check_eq(_count_disturbing(24, 29.9), 4, "en 24 lugares")
	check_eq(_count_disturbing(24, 15.0), 4, "justo en 15, todavía una de cada 6")
	return true


func test_bajo_15_es_perturbadora_una_de_cada_3() -> bool:
	_prepare()
	check_eq(_count_disturbing(24, 14.9), 8, "en 24 lugares")
	check_eq(_count_disturbing(24, 0.0), 8, "con Sanity en 0")
	return true


## Las demás publicaciones siguen en su lugar: una perturbadora reemplaza a la que tocaba, no corre el resto.
func test_los_gatitos_no_se_corren() -> bool:
	_prepare()
	for slot in 24:
		var post := _post(slot, 10.0)
		if not _disturbing.has(post):
			check_eq(post, _posts[slot % 5], "lugar %d" % slot)
	return true


func test_las_perturbadoras_se_turnan() -> bool:
	_prepare()
	var seen: Array[PhonePostData] = []
	for slot in 12:
		var post := _post(slot, 10.0)
		if _disturbing.has(post):
			check(not seen.has(post), "no se repite antes de mostrar las 4")
			seen.append(post)
	check_eq(seen.size(), 4, "se ven las 4")
	return true


func test_sin_perturbadoras_solo_hay_gatitos() -> bool:
	_prepare()
	_disturbing = []
	for slot in 12:
		check_eq(_post(slot, 0.0), _posts[slot % 5], "lugar %d" % slot)
	return true


## El feed también se puede scrollear hacia arriba desde el comienzo.
func test_funciona_con_lugares_negativos() -> bool:
	_prepare()
	check_eq(_post(-1, 100.0), _posts[4], "el lugar -1 es la última")
	check(_disturbing.has(_post(-1, 10.0)) or _posts.has(_post(-1, 10.0)), "siempre devuelve una publicación")
	return true


func test_sin_publicaciones_no_devuelve_nada() -> bool:
	_prepare()
	_posts = []
	check(_post(0, 100.0) == null, "un feed vacío no tiene qué mostrar")
	return true


func test_los_valores_estan_en_balance() -> bool:
	var balance: BalanceData = load("res://data/balance.tres")
	check_eq(balance.disturbing_post_sanity, 30.0, "bajo qué Sanity empiezan")
	check_eq(balance.disturbing_post_every, 6, "una de cada cuántas")
	check_eq(balance.disturbing_post_worse_sanity, 15.0, "bajo qué Sanity empeoran")
	check_eq(balance.disturbing_post_worse_every, 3, "una de cada cuántas, después")
	return true
