extends Node
## El reloj de la noche (Plan 5): avanza las solicitudes y el estado de la noche, en ese orden, y decide
## cuándo termina. Se gana a las 06:00 con la cuota cumplida. Se pierde apenas muere un amigo o
## Sanity, Trust o Connection llegan a 0, o a las 06:00 si falta contenido (diseño §5).
## Al terminar, todo se detiene: los temporizadores, la hora y los medidores. Mientras el jumpscare tapa la
## pantalla, la noche se pausa (Plan 7, diseño §11).

## Se recibió un video del amigo `friend_index`: Matías terminó de descargarlo.
signal video_received(friend_index: int)
## La noche terminó. `fatal_request` es la solicitud en la que murió un amigo; si nadie murió, null.
signal night_ended(ending: NightState.Ending, fatal_request: FriendRequest)

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var requests: RequestManager
var ended := false

## Segundos que le quedan a la pausa.
var _pause_left := 0.0


## Toma el control del tiempo de `manager`: desde ahora, las solicitudes avanzan solo cuando avanza la noche.
func setup(manager: RequestManager) -> void:
	requests = manager
	manager.set_process(false)
	manager.request_finished.connect(_on_request_finished)


func state() -> NightState:
	return requests.state


func _process(delta: float) -> void:
	advance(delta)


## Pausa la noche `seconds` segundos: no avanzan los temporizadores, la hora ni los medidores (diseño §11).
func pause(seconds: float) -> void:
	_pause_left = maxf(_pause_left, seconds)


func is_paused() -> bool:
	return _pause_left > 0.0


## Avanza la noche `delta` segundos, menos lo que quede de pausa. Cuando termina, ya no avanza más.
func advance(delta: float) -> void:
	if ended or requests == null:
		return
	var paused := minf(_pause_left, delta)
	_pause_left -= paused
	delta -= paused
	if delta <= 0.0:
		return
	requests.advance(delta)
	if ended:
		return
	var events := requests.state.advance(delta)
	requests.report(events)
	for friend_index: int in events.videos.received:
		video_received.emit(friend_index)
	_check_ending(null)


## Una solicitud terminada puede matar al amigo, y entonces es la que explica la derrota.
func _on_request_finished(_friend_index: int, request: FriendRequest) -> void:
	_check_ending(request)


## Termina la noche ahora con `ending`, si no había terminado: así termina el tutorial, al completarse.
func finish(ending: NightState.Ending) -> void:
	if ended:
		return
	ended = true
	night_ended.emit(ending, null)


func _check_ending(request: FriendRequest) -> void:
	if ended:
		return
	var ending := requests.state.ending()
	if ending == NightState.Ending.NONE:
		return
	ended = true
	night_ended.emit(ending, request if ending == NightState.Ending.FRIEND_DIED else null)
