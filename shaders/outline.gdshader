shader_type canvas_item;
// Contorno interior de 1 píxel para resaltar objetos clickeables.
// Pensado para sprites de un solo frame: su textura es exactamente el sprite (UV de 0 a 1).
// El muestreo va dentro de fragment(): GL Compatibility no acepta TEXTURE como argumento de una función.

uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);

void fragment() {
	if (enabled && COLOR.a > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		vec2 neighbor_offsets[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
		float neighbors = 1.0;
		for (int i = 0; i < 4; i++) {
			vec2 uv = UV + neighbor_offsets[i];
			bool inside = uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0;
			neighbors *= inside ? texture(TEXTURE, uv).a : 0.0;
		}
		if (neighbors == 0.0) {
			COLOR = outline_color;
		}
	}
}
