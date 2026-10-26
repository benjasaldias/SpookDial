extends Camera2D
## Cámara del escritorio: un leve zoom y un desplazamiento hacia donde apunta el mouse,
## como si el jugador mirara hacia ese lado (mirar a la derecha corre la escena a la izquierda).
## El desplazamiento máximo es el margen que deja el zoom, así que todo sigue siendo alcanzable.
## Con look_enabled = false, o con el argumento `-- --no-parallax` (para capturas), queda sin zoom y fija.

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")

@export var look_enabled := true
@export_range(1.0, 1.2, 0.01) var look_zoom := 1.05
## Qué tan rápido alcanza la cámara su destino. Más alto, más rápido.
@export var follow_speed := 8.0

var _center := Vector2.ZERO
var _mouse_moved := false


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--no-parallax"):
		look_enabled = false
	_center = get_viewport_rect().size * 0.5
	position = _center
	zoom = Vector2.ONE * (look_zoom if look_enabled else 1.0)
	make_current()


func _process(delta: float) -> void:
	# Hasta que el mouse se mueve, su posición no es confiable: la cámara queda al centro.
	if not look_enabled or not _mouse_moved:
		return
	var viewport := get_viewport()
	var target := _center + ParallaxMath.camera_offset_for(
			viewport.get_mouse_position(), viewport.get_visible_rect().size, look_zoom)
	position = position.lerp(target, 1.0 - exp(-follow_speed * delta))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_moved = true
