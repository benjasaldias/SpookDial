extends RefCounted
## Estática del chat (docs/02 §4): con poca señal, algunas palabras del amigo llegan tapadas (▒▒▒).
## Una frase clickeable cuenta como una sola palabra: se tapa entera o no se tapa (decisión de Benja).

const ChatMessage := preload("res://scripts/core/chat_message.gd")

## [señal mínima, probabilidad de tapar cada palabra], de la señal más alta a la más baja.
const COVERAGE := [[70.0, 0.0], [50.0, 0.10], [30.0, 0.25], [0.0, 0.45]]


static func coverage_for_signal(signal_level: float) -> float:
	for band: Array in COVERAGE:
		if signal_level >= band[0]:
			return band[1]
	return COVERAGE[-1][1]


## Tapa al azar palabras de `message`, según la señal del amigo que lo envía.
static func apply(message: ChatMessage, signal_level: float, rng: RandomNumberGenerator) -> void:
	var chance := coverage_for_signal(signal_level)
	if chance <= 0.0:
		return
	for token: ChatMessage.Token in message.tokens:
		if token.can_be_covered() and rng.randf() < chance:
			token.covered = true
