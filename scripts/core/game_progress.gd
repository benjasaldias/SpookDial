extends RefCounted
## El progreso del jugador (docs/26 §3.1): qué dificultades terminó, es decir, en cuáles ganó la noche 5. Va en su propio
## archivo porque la partida (save.cfg) se borra al terminar el juego. Difícil se desbloquea al terminar Normal (decisión
## de Benja, D1). Sin archivo, no se terminó nada.

const SECTION := "progress"
const FINISHED_KEY := "finished"

var path := ""


func _init(progress_path: String) -> void:
	path = progress_path


## Se ganó la noche 5 en la dificultad `difficulty_id`.
func has_finished(difficulty_id: StringName) -> bool:
	return _finished().has(String(difficulty_id))


## Guarda que se terminó la dificultad `difficulty_id`.
func mark_finished(difficulty_id: StringName) -> Error:
	var finished := _finished()
	if not finished.has(String(difficulty_id)):
		finished.append(String(difficulty_id))
	var file := ConfigFile.new()
	file.set_value(SECTION, FINISHED_KEY, finished)
	return file.save(path)


## Se puede elegir `difficulty`: no pide nada o ya se terminó la que pide.
func is_unlocked(difficulty: DifficultyData) -> bool:
	return difficulty.unlocked_by == null or has_finished(difficulty.unlocked_by.id)


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Los ids de las dificultades terminadas, como texto.
func _finished() -> PackedStringArray:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return PackedStringArray()
	return PackedStringArray(file.get_value(SECTION, FINISHED_KEY, PackedStringArray()))
