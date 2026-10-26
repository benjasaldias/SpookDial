extends RefCounted
## Desplazamiento entero de un plano según el mouse.
## Mouse al centro: (0, 0). Mouse en un borde: ±max_offset, en la misma dirección que el mouse.


static func offset_for(mouse_position: Vector2, viewport_size: Vector2, max_offset: Vector2) -> Vector2i:
	var half := viewport_size * 0.5
	var normalized := ((mouse_position - half) / half).clamp(Vector2(-1, -1), Vector2(1, 1))
	return Vector2i((normalized * max_offset).round())
