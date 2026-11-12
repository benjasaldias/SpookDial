extends "res://test/test_case.gd"
## La letra en pixel art, nítida en cualquier pantalla (pedido de Benja, 11 de noviembre).

const PixelText := preload("res://scripts/ui/pixel_text.gd")


## Cada tamaño base, a cada escala: queda nítido (múltiplo de 11 en píxeles reales) y la letra común crece un poco
## cuando se puede.
func test_tamanos_nitidos() -> bool:
	var expected := {
		1.0: {11: 11, 22: 22, 33: 33, 66: 66},
		1.5: {11: 15, 22: 22, 33: 37, 66: 66},
		2.0: {11: 11, 22: 22, 33: 33, 66: 66},
		3.0: {11: 11, 22: 22, 33: 33, 66: 66},
	}
	for scale: float in expected:
		for base: int in expected[scale]:
			check_eq(PixelText.crisp_size(base, scale), expected[scale][base], "a %s×, la letra de %d" % [scale, base])
	check_eq(PixelText.crisp_size(11, 0.5), 11, "una ventana más chica que 1280×720 cuenta como 1×")
	# Una ventana maximizada a 1080p, sin la barra de tareas: 1920×1009, escala 1,401.
	check_eq(PixelText.crisp_size(11, 1009.0 / 720.0), 16, "maximizada a 1080p, la letra también queda en 22 px reales")
	check_eq(int(PixelText.crisp_size(22, 1009.0 / 720.0) * 1009.0 / 720.0) % 11, 0, "y los títulos, nítidos")
	for scale: float in [1.0, 1.5, 2.0, 3.0, 1009.0 / 720.0, 1.25, 768.0 / 720.0]:
		for base: int in [11, 22, 33, 66]:
			var real := int(PixelText.crisp_size(base, scale) * scale)
			check_eq(real % 11, 0, "a %s×, %d px queda en %d px reales" % [scale, base, real])
	return true


func test_escala_de_la_ventana() -> bool:
	check_eq(PixelText.window_scale_for(Vector2(1280, 720)), 1.0, "1280×720")
	check_eq(PixelText.window_scale_for(Vector2(1920, 1080)), 1.5, "1080p")
	check_eq(PixelText.window_scale_for(Vector2(2560, 1440)), 2.0, "1440p")
	check_eq(PixelText.window_scale_for(Vector2(1920, 1200)), 1.5, "con franjas, manda el lado más corto")
	return true


## Aplica el tamaño nítido a un tema y a un Control con tamaño propio, y vuelve al original con la escala 1.
func test_aplica_a_temas_y_nodos() -> bool:
	var sizer := PixelText.new()
	var theme := Theme.new()
	theme.default_font_size = 11
	theme.set_font_size(&"font_size", &"Button", 22)
	sizer.track_theme(theme)
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", 11)
	sizer.apply(1.5)
	sizer.apply_to_control(label)
	check_eq(theme.default_font_size, 15, "el tema, a 1080p")
	check_eq(theme.get_font_size(&"font_size", &"Button"), 22, "el botón de 22 ya era nítido")
	check_eq(label.get_theme_font_size(&"font_size"), 15, "el Control con su tamaño")
	sizer.apply(1.0)
	sizer.apply_to_control(label)
	check_eq(theme.default_font_size, 11, "de vuelta a 1280×720")
	check_eq(label.get_theme_font_size(&"font_size"), 11, "el Control, también")
	label.free()
	sizer.free()
	return true


## Un ícono de pixel art junto a la letra crece con ella, para seguir nítido: a 1080p la letra pasa de 11 a 15 y un
## ícono de 9 px, a 12 (18 px reales, el doble exacto).
func test_el_icono_sigue_a_la_letra() -> bool:
	check_eq(PixelText.icon_size_for(9, 11), 9, "a 1280×720 queda igual")
	check_eq(PixelText.icon_size_for(9, 15), 12, "a 1080p, 12")
	check_eq(PixelText.icon_size_for(11, 15), 15, "el cuaderno de 11, 15")
	check_eq(PixelText.icon_size_for(15, 15), 20, "la señal de 15, 20")
	return true
