extends RefCounted
## Desplazamiento de la cámara del escritorio según el mouse.
## Mouse al centro: (0, 0). Mouse en un borde: el margen que deja el zoom, hacia el lado del mouse.
## Con ese máximo, el punto de la escena bajo el mouse coincide con la posición del mouse,
## así que todo lo que hay en la escena se puede alcanzar.


static func camera_offset_for(mouse_position: Vector2, viewport_size: Vector2, zoom: float) -> Vector2:
	var half := viewport_size * 0.5
	var normalized := ((mouse_position - half) / half).clamp(Vector2(-1, -1), Vector2(1, 1))
	return normalized * half * (1.0 - 1.0 / zoom)
