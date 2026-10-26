extends RefCounted
## Conversión pura del valor de un medidor (0..1) al ángulo de la aguja.


static func value_to_degrees(value: float, min_degrees: float, max_degrees: float) -> float:
	return lerpf(min_degrees, max_degrees, clampf(value, 0.0, 1.0))
