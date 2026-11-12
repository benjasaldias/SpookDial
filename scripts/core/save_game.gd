extends RefCounted
## La partida guardada (diseño §5): la noche en la que va el jugador, de 0 (el tutorial) a 5, y su dificultad. Se guarda
## al comienzo de cada noche, así que "Continuar" vuelve a empezar esa noche, y también al ganarla (la siguiente) y al
## terminar el tutorial (la 1). Al ganar la noche 5 se borra: el juego terminó.
## Una partida guardada antes de que existieran las dificultades (S21i) no tiene la suya, y se lee como Normal.

const SECTION := "game"
const LAST_NIGHT := 5
## La dificultad de una partida que no dice cuál es.
const DEFAULT_DIFFICULTY := &"normal"

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


## La dificultad de la partida guardada (su id), o Normal si no hay partida o no lo dice.
func stored_difficulty() -> StringName:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return DEFAULT_DIFFICULTY
	var difficulty := String(file.get_value(SECTION, "difficulty", ""))
	return DEFAULT_DIFFICULTY if difficulty.is_empty() else StringName(difficulty)


## Guarda la noche `night` de una partida en la dificultad `difficulty_id`. Se guarda como texto, para que el archivo
## sea solo datos.
func store(night: int, difficulty_id := DEFAULT_DIFFICULTY) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "night", night)
	file.set_value(SECTION, "difficulty", String(difficulty_id))
	return file.save(path)


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
