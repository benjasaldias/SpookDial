extends RefCounted
## Qué publicación va en cada lugar del feed de Snapgram. Normalmente son los gatitos, en orden y repetidos sin
## fin. Con poca Sanity, algunos lugares muestran una foto perturbadora, cada vez más seguido (decisión de Benja,
## 9 de noviembre): desde Sanity 50, 1 de cada 4, y en escalones parejos hasta 4 de cada 4 con 10 o menos (pedido de
## Benja, 12 de noviembre). Solo es un susto: no resta Sanity.


## La publicación del lugar `slot`, que puede ser negativo: el feed también se scrollea hacia arriba.
## Una perturbadora reemplaza a la que tocaba, sin correr a las demás.
static func post_for_slot(slot: int, sanity: float, posts: Array[PhonePostData], disturbing: Array[PhonePostData],
		balance: BalanceData) -> PhonePostData:
	if posts.is_empty():
		return null
	var group_size := maxi(balance.disturbing_post_group, 1)
	var count := disturbing_count(sanity, balance)
	if count > 0 and not disturbing.is_empty():
		var group := floori(float(slot) / group_size)
		var rank := _rank_in_group(group, posmod(slot, group_size), group_size)
		if rank < count:
			return disturbing[posmod(group * count + rank, disturbing.size())]
	return posts[posmod(slot, posts.size())]


## Cuántas de cada grupo de publicaciones seguidas son perturbadoras con esta Sanity: ninguna sobre el comienzo, todas
## desde el valor de "todas" hacia abajo y, entre los dos, en escalones parejos desde 1.
static func disturbing_count(sanity: float, balance: BalanceData) -> int:
	var group_size := maxi(balance.disturbing_post_group, 1)
	var start := balance.disturbing_post_start_sanity
	var full := balance.disturbing_post_full_sanity
	if sanity > start:
		return 0
	if sanity <= full or group_size == 1:
		return group_size
	var step := (start - full) / (group_size - 1)
	return clampi(1 + floori((start - sanity) / step), 1, group_size - 1)


## El orden en que el lugar `position` de un grupo se vuelve perturbador: los grupos se barajan con su número, así que
## un lugar perturbador lo sigue siendo si Sanity baja más.
static func _rank_in_group(group: int, position: int, group_size: int) -> int:
	var order: Array[int] = []
	for index in group_size:
		order.append(index)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(group) + 7919
	for index in range(group_size - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var kept := order[index]
		order[index] = order[other]
		order[other] = kept
	return order.find(position)
