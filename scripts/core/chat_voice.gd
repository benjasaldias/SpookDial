extends RefCounted
## La voz de un amigo mientras escribe (decisión de Benja, 8 de noviembre): un sonido corto cada tantas letras, como
## en Undertale. La altura depende de la letra, así que una misma palabra siempre suena igual. Lógica pura: el chat
## hace sonar lo que esto decide.

## Cuántas alturas distintas hay entre la más grave y la más aguda de la voz.
const PITCH_STEPS := 5

var _pitch: float
var _spread: float
var _every: int
## Cuántas letras lleva, sin contar espacios ni puntuación.
var _letters := 0


func _init(friend: FriendData) -> void:
	_pitch = friend.voice_pitch
	_spread = friend.voice_spread
	_every = maxi(friend.voice_every, 1)


## Cuenta `letter` y devuelve la altura a la que suena, o 0 si esta no suena. Los espacios, la puntuación, los
## números y la estática son silencio y no cuentan.
func next_pitch(letter: String) -> float:
	var lower := letter.to_lower()
	if lower == letter.to_upper():
		return 0.0
	_letters += 1
	if (_letters - 1) % _every != 0:
		return 0.0
	var step := lower.unicode_at(0) % PITCH_STEPS
	return _pitch * (1.0 + _spread * (step * 2.0 / (PITCH_STEPS - 1) - 1.0))
