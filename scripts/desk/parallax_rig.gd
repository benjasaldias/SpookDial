extends Node
## Mueve planos de la escena según el mouse. Cada plano tiene su desplazamiento máximo en píxeles.
## Con el argumento de línea de comandos `-- --no-parallax` queda desactivado (para capturas).

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")

@export var enabled := true
@export var planes: Array[NodePath] = []
@export var max_offsets: Array[Vector2] = []

var _base_positions: Array[Vector2] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--no-parallax"):
		enabled = false
	for path in planes:
		_base_positions.append((get_node(path) as Node2D).position)


func _process(_delta: float) -> void:
	var viewport := get_viewport()
	var mouse := viewport.get_mouse_position()
	var size := viewport.get_visible_rect().size
	for i in planes.size():
		var offset := Vector2i.ZERO
		if enabled:
			offset = ParallaxMath.offset_for(mouse, size, max_offsets[i])
		(get_node(planes[i]) as Node2D).position = _base_positions[i] + Vector2(offset)
