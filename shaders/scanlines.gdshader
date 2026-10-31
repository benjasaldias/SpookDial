shader_type canvas_item;
// Pantalla de monitor viejo sobre el chat: una línea oscura cada `period` píxeles y los bordes en sombra.
// Va en un ColorRect que cubre el interior del panel y no recibe clics.

// Alto del rectángulo, en píxeles del juego.
uniform float height = 654.0;
uniform float period = 3.0;
uniform float line_darkness : hint_range(0.0, 1.0) = 0.16;
uniform float edge_shadow : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float line = step(period - 1.0, mod(floor(UV.y * height), period)) * line_darkness;
	float edge = smoothstep(0.32, 0.75, length((UV - 0.5) * vec2(1.0, 0.65))) * edge_shadow;
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - (1.0 - line) * (1.0 - edge));
}
