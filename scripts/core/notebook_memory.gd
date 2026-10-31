extends RefCounted
## Qué página del cuaderno tiene abierta cada amigo (diseño §12). El cuaderno salta a ella al cambiar
## de chat, y los botones de respuesta del chat muestran sus acciones (diseño §8.5).
## null significa que ese amigo está en el índice, sin página abierta.

signal page_changed(friend_index: int, entity: EntityData)

var _pages: Array[EntityData] = []


func _init(friend_count: int) -> void:
	_pages.resize(friend_count)


## La página abierta para un amigo, o null si está en el índice.
func page_for(friend_index: int) -> EntityData:
	return _pages[friend_index]


func open_page(friend_index: int, entity: EntityData) -> void:
	if _pages[friend_index] == entity:
		return
	_pages[friend_index] = entity
	page_changed.emit(friend_index, entity)


## Vuelve al índice: ese amigo queda sin página abierta.
func close_page(friend_index: int) -> void:
	open_page(friend_index, null)
