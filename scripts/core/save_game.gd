extends RefCounted
## La partida guardada (diseño §5): la noche en la que va el jugador, de 0 (el tutorial) a 5. Se guarda al
## comienzo de cada noche, así que "Continuar" vuelve a empezar esa noche. Al ganar la noche 5 se borra:
## el juego terminó.

const SECTION := "game"
const LAST_NIGHT := 5

var path := ""


func _init(save_path: String) -> void:
	path = save_path


func has_game() -> bool:
	return stored_night() >= 0


## La noche guardada, o -1 si no hay partida (o si el archivo no tiene una noche que exista).
func stored_night() -> int:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return -1
	var night := int(file.get_value(SECTION, "night", -1))
	return night if night >= 0 and night <= LAST_NIGHT else -1


func store(night: int) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "night", night)
	return file.save(path)


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
