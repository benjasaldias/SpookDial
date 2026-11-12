extends "res://test/test_case.gd"
## Qué publicación va en cada lugar del feed de Snapgram: gatitos y, con poca Sanity, fotos perturbadoras
## (decisión de Benja, 9 de noviembre; desde Sanity 50, pedido del 12 de noviembre).

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


func test_sobre_50_solo_hay_gatitos_en_orden() -> bool:
	_prepare()
	for slot in 24:
		check_eq(_post(slot, 50.1), _posts[slot % 5], "lugar %d" % slot)
	return true


## Desde Sanity 50, 1 de cada 4, y va subiendo en escalones parejos hasta 4 de cada 4 con 10 o menos (pedido de Benja,
## 12 de noviembre).
func test_de_1_a_4_de_cada_4() -> bool:
	_prepare()
	check_eq(_count_disturbing(24, 50.0), 6, "con 50, 1 de cada 4")
	check_eq(_count_disturbing(24, 40.0), 6, "con 40, todavía 1")
	check_eq(_count_disturbing(24, 30.0), 12, "con 30, 2 de cada 4")
	check_eq(_count_disturbing(24, 20.0), 18, "con 20, 3 de cada 4")
	check_eq(_count_disturbing(24, 10.0), 24, "con 10, todas")
	check_eq(_count_disturbing(24, 0.0), 24, "con 0, todas")
	return true


## En cada grupo de 4 lugares seguidos sale la cantidad justa, no solo en el total.
func test_cada_grupo_de_4_tiene_su_cantidad() -> bool:
	_prepare()
	for group in 6:
		var count := 0
		for slot in range(group * 4, group * 4 + 4):
			if _disturbing.has(_post(slot, 30.0)):
				count += 1
		check_eq(count, 2, "grupo %d" % group)
	return true


## Un lugar perturbador lo sigue siendo si Sanity baja más: la foto no se "arregla" al empeorar.
func test_al_bajar_sanity_se_suman_lugares() -> bool:
	_prepare()
	for slot in 24:
		if _disturbing.has(_post(slot, 45.0)):
			check(_disturbing.has(_post(slot, 25.0)), "lugar %d sigue perturbador" % slot)
	return true


func test_el_mismo_lugar_sale_igual() -> bool:
	_prepare()
	for slot in 24:
		check_eq(_post(slot, 33.0), _post(slot, 33.0), "lugar %d" % slot)
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
	for slot in 16:
		var post := _post(slot, 45.0)
		if _disturbing.has(post):
			check(not seen.has(post), "no se repite antes de mostrar las 4")
			seen.append(post)
	check_eq(seen.size(), 4, "se ven las 4")
	for group in 3:
		var shown: Array[PhonePostData] = []
		for slot in range(group * 4, group * 4 + 4):
			var post := _post(slot, 0.0)
			check(not shown.has(post), "con todas perturbadoras, no se repiten en un grupo")
			shown.append(post)
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
	check_eq(balance.disturbing_post_start_sanity, 50.0, "desde qué Sanity empiezan")
	check_eq(balance.disturbing_post_full_sanity, 10.0, "con cuánta son todas")
	check_eq(balance.disturbing_post_group, 4, "de cada cuántas")
	return true
