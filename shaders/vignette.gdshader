shader_type canvas_item;
// Viñeta de Sanity (diseño §10.2): oscurece los bordes de la pantalla, más mientras más baja Sanity.
// Va en un ColorRect que cubre la pantalla. La oscuridad avanza en bandas, como el pixel art.

// 0: no se ve. 1: solo queda claro el centro.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Cuántos niveles de oscuridad hay entre el borde de la viñeta y la oscuridad máxima.
uniform float bands = 5.0;
// Oscuridad máxima, en los bordes de la pantalla.
uniform float max_darkness : hint_range(0.0, 1.0) = 0.92;

void fragment() {
	// Distancia al centro, corregida para que la viñeta sea redonda en una pantalla de 16:9.
	vec2 from_center = (UV - 0.5) * vec2(16.0 / 9.0, 1.0);
	// Con strength 0, el borde de la viñeta queda fuera de la pantalla; con 1, cerca del centro.
	float inner = mix(1.1, 0.1, strength);
	float darkness = smoothstep(inner, inner + 0.4, length(from_center));
	COLOR = vec4(0.0, 0.0, 0.0, floor(darkness * bands) / bands * max_darkness);
}
