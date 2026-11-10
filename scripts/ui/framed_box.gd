extends VBoxContainer
## La columna de un menú (el principal, la pausa o el final de la noche) con el marco de placa detrás: pixel art de
## Claude (art/ui/menu_frame.png), que trae el tema del menú como MenuFrame. El marco se dibuja `padding` píxeles
## por fuera de la columna, así que no cambia cómo se acomodan los botones ni las rutas de sus nodos.

## Cuánto sobresale el marco alrededor de la columna.
@export var padding := Vector2i(32, 28)


func _draw() -> void:
	var frame := get_theme_stylebox(&"panel", &"MenuFrame")
	draw_style_box(frame, Rect2(-Vector2(padding), size + Vector2(padding) * 2.0))
