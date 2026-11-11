extends Node
## La Mano en el escritorio (idea de Benja, 11 de noviembre): el segundo enemigo del cuarto. Cuando el director la pide,
## asoma por el borde derecho y avanza a tirones hacia un dial al azar (HandVisit). En cada tirón tiembla un momento y
## cruje, sutil, para que se note aunque el cuaderno la tape. Si agarra el dial, lo baja hasta un mínimo y se queda
## hasta que la espanten: el flash del celular la hace desaparecer al instante, y cada flash gasta batería.
## Está en la pared, así que el chat, el cuaderno y el mixer la tapan (decisión de Benja). No llega mientras la criatura
## está en la ventana, y la criatura no se arma mientras ella está en la pared (ScreamerManager).
## En la noche 0 la larga el escritorio, cuando el guía del tutorial la pide.

## Llegó una visita.
signal hand_appeared
## El flash la espantó.
signal hand_scared

const HandVisit := preload("res://scripts/core/hand_visit.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## En cada tirón tiembla hasta tantos píxeles, durante tantos segundos: un movimiento forzado, a tirones.
const TREMBLE_PIXELS := 2
const TREMBLE_SECONDS := 0.1
## El crujido de cada tirón cambia un poco de altura, para que no suene siempre igual.
const CREAK_PITCH := Vector2(0.85, 1.12)
## El destello del flash: cuánto se aclara la pantalla (menos con "Reducir destellos") y en cuánto se apaga.
const FLASH_ALPHA := 0.8
const GENTLE_FLASH_ALPHA := 0.3
const FLASH_SECONDS := 0.3

## El brazo de Benja (art/sprites/hand_sprite.aseprite), en la pared, delante de los diales.
@export var sprite: AnimatedSprite2D
## El destello blanco del flash, sobre todo lo demás.
@export var flash_overlay: CanvasItem
## Los diales, en el orden de NightState.Dial: Connection, Sanity y Trust.
@export var dials: Array[Node2D] = []
## La opción "Reducir destellos" (diseño §19).
var reduce_flashes := false
## La visita en curso, o null.
var visit: HandVisit

var _requests: RequestManager
var _night: NightManager
var _screamers: Node
## Segundos que le quedan al temblor del último tirón, y hacia dónde tiembla.
var _tremble_left := 0.0
var _tremble := Vector2i.ZERO
var _flash_tween: Tween

@onready var _creak: AudioStreamPlayer2D = $CreakSound
@onready var _flash_sound: AudioStreamPlayer = $FlashSound


func setup(requests: RequestManager, night: NightManager, screamers: Node) -> void:
	_requests = requests
	_night = night
	_screamers = screamers
	sprite.hide()
	flash_overlay.modulate.a = 0.0


## Hay una Mano en la pared.
func is_present() -> bool:
	return visit != null


## Avanza `delta` segundos: si toca una visita y no hay criatura ni otra Mano, empieza; si hay una, da sus tirones y,
## agarrada, baja su dial.
func advance(delta: float) -> void:
	if _requests == null or _night.ended or _night.is_paused():
		return
	if visit == null:
		_maybe_arrive()
		return
	_tremble_left = maxf(_tremble_left - delta, 0.0)
	if visit.advance(delta):
		_jerk()
	if visit.is_grabbing():
		_requests.state.hand_pull(visit.dial, delta)
	_place()


## Empieza una visita hacia el dial `dial` (NightState.Dial), desde el borde derecho.
func start_visit(dial: int) -> void:
	visit = HandVisit.new(dial, _requests.catalog.balance, _requests.rng)
	_tremble_left = 0.0
	sprite.frame = visit.frame
	sprite.show()
	_place()
	hand_appeared.emit()


## El flash del celular: gasta batería, destella y, si hay una Mano, la hace desaparecer al instante. Sin batería no
## prende y devuelve false.
func flash() -> bool:
	if not _requests.state.flash():
		return false
	_flash_sound.play()
	if _flash_tween != null:
		_flash_tween.kill()
	flash_overlay.modulate.a = GENTLE_FLASH_ALPHA if reduce_flashes else FLASH_ALPHA
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_overlay, ^"modulate:a", 0.0, FLASH_SECONDS)
	if visit != null:
		visit = null
		sprite.hide()
		hand_scared.emit()
	return true


## Llega la visita que pide el director, a un dial al azar, si la criatura no está en la ventana.
func _maybe_arrive() -> void:
	var director := _requests.director
	if not director.hand_due(_requests.state.elapsed):
		return
	if _screamers.is_creature_near() or _screamers.is_warning():
		return
	director.hand_started()
	start_visit(_requests.rng.randi_range(0, dials.size() - 1))


## Un tirón: el cuadro nuevo, un temblor de 1 o 2 px y el crujido.
func _jerk() -> void:
	var rng := _requests.rng
	sprite.frame = visit.frame
	_tremble_left = TREMBLE_SECONDS
	_tremble = Vector2i(rng.randi_range(1, TREMBLE_PIXELS) * (1 if rng.randf() < 0.5 else -1),
			rng.randi_range(-1, 1))
	_creak.pitch_scale = rng.randf_range(CREAK_PITCH.x, CREAK_PITCH.y)
	_creak.play()


## La Mano donde dice su visita, con el temblor si todavía dura. Siempre en píxeles enteros (regla 10).
func _place() -> void:
	var position := visit.position(dials[visit.dial].position)
	if _tremble_left > 0.0:
		position += _tremble
	sprite.position = Vector2(position)
