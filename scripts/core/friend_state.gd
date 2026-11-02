extends RefCounted
## Cómo está un amigo durante la noche (diseño §9 y §10.1): su vida, si está aturdido y su señal.
## Lógica pura: NightState tiene uno por amigo.

## La señal va de 0 a 100. Con 0, el amigo está desconectado.
const SIGNAL_MAX := 100.0

var health := 0
var max_health := 0
## Segundos de aturdimiento que quedan. Mientras dure, el amigo no pide ayuda ni envía videos.
var stun_left := 0.0
## Señal (0–100): decide la estática de sus mensajes y la velocidad de sus descargas. Con 0 está desconectado.
var signal_level := SIGNAL_MAX
## Segundos por cada punto de señal que pierde con el tiempo. Con 0, la señal no baja (noche 1).
var signal_decay_interval := 0.0


func _init(start_health: int) -> void:
	health = start_health
	max_health = start_health


func is_alive() -> bool:
	return health > 0


func is_stunned() -> bool:
	return stun_left > 0.0


## Tiene señal. Desconectado, no lee las preguntas ni las respuestas de Matías, y no envía videos.
func is_online() -> bool:
	return signal_level > 0.0


## Puede recibir solicitudes: está vivo y no está aturdido. Desconectado también le llegan, pero no lee
## las respuestas de Matías (decisión de Benja).
func is_available() -> bool:
	return is_alive() and not is_stunned()


## Puede enviar un video: está disponible y tiene señal.
func can_send() -> bool:
	return is_available() and is_online()


## Pierde `damage` de vida. Si sobrevive, queda aturdido `stun_seconds`.
func hurt(damage: int, stun_seconds: float) -> void:
	health = maxi(health - damage, 0)
	stun_left = stun_seconds if is_alive() else 0.0


## Una interferencia le quita `amount` de señal.
func interfere(amount: float) -> void:
	signal_level = maxf(signal_level - amount, 0.0)


## Audio Sync salió bien: la señal vuelve a 100.
func restore_signal() -> void:
	signal_level = SIGNAL_MAX


## Avanza `delta` segundos: el aturdimiento y, si la noche lo pide, la señal.
func advance(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
	if signal_decay_interval > 0.0:
		signal_level = maxf(signal_level - delta / signal_decay_interval, 0.0)
