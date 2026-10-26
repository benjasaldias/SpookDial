@tool
extends Node2D
## Dial de la pared: cara fija y aguja que gira según `value` (0..1).
## El eje de la aguja es el centro del dial: (56, 56) dentro de dial_sprite.

const DialMath := preload("res://scripts/desk/dial_math.gd")

@export_range(0.0, 1.0) var value := 1.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		_update_needle()
@export var needle_color: StringName = &"green":
	set(new_color):
		needle_color = new_color
		_update_needle()
@export var min_degrees := -120.0
@export var max_degrees := 120.0

@onready var _needle: AnimatedSprite2D = $Needle


func _ready() -> void:
	_update_needle()


func _update_needle() -> void:
	if not is_node_ready():
		return
	_needle.animation = needle_color
	_needle.rotation_degrees = DialMath.value_to_degrees(value, min_degrees, max_degrees)
