extends RefCounted
## Cómo está un amigo durante la noche (diseño §9 y §10.1): su vida, si está aturdido y su señal.
## Lógica pura: NightState tiene uno por amigo.

var health := 0
var max_health := 0
## Segundos de aturdimiento que quedan. Mientras dure, el amigo no pide ayuda ni envía videos.
var stun_left := 0.0
## Señal (0–100): decide la estática de sus mensajes. En el Plan 6 baja durante la noche.
var signal_level := 100.0


func _init(start_health: int) -> void:
	health = start_health
	max_health = start_health


func is_alive() -> bool:
	return health > 0


func is_stunned() -> bool:
	return stun_left > 0.0


## Puede recibir solicitudes y enviar videos: está vivo y no está aturdido.
func is_available() -> bool:
	return is_alive() and not is_stunned()


## Pierde `damage` de vida. Si sobrevive, queda aturdido `stun_seconds`.
func hurt(damage: int, stun_seconds: float) -> void:
	health = maxi(health - damage, 0)
	stun_left = stun_seconds if is_alive() else 0.0


func advance(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
