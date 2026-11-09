extends RefCounted
## Qué publicación va en cada lugar del feed de Snapgram. Normalmente son los gatitos, en orden y repetidos sin
## fin. Con poca Sanity, algunos lugares muestran una foto perturbadora, cada vez más seguido (decisión de Benja,
## 9 de noviembre). Solo es un susto: no resta Sanity.


## La publicación del lugar `slot`, que puede ser negativo: el feed también se scrollea hacia arriba.
## Una perturbadora reemplaza a la que tocaba, sin correr a las demás.
static func post_for_slot(slot: int, sanity: float, posts: Array[PhonePostData], disturbing: Array[PhonePostData],
		balance: BalanceData) -> PhonePostData:
	if posts.is_empty():
		return null
	var every := _disturbing_every(sanity, balance)
	if every > 0 and not disturbing.is_empty() and posmod(slot + 1, every) == 0:
		var turn := floori(float(slot + 1) / every) - 1
		return disturbing[posmod(turn, disturbing.size())]
	return posts[posmod(slot, posts.size())]


## Una de cada cuántas publicaciones es perturbadora con esta Sanity; 0 si no hay ninguna.
static func _disturbing_every(sanity: float, balance: BalanceData) -> int:
	if sanity < balance.disturbing_post_worse_sanity:
		return balance.disturbing_post_worse_every
	if sanity < balance.disturbing_post_sanity:
		return balance.disturbing_post_every
	return 0
