extends "res://test/test_case.gd"
## El arte de interfaz que dibuja Claude (art/ui/, lo genera tools/make_ui_art.py). Godot lo usa con estos tamaños.

## El arte del chat (Plan 9.3): los íconos de las preguntas y de sus estados, el cuaderno del nombre, la señal del botón
## de sincronizar (5 cuadros de 15×12, en 3 filas de color) y las hojas de las respuestas (9-slice de 19×19).
const CHAT_ART := {
	"chat_icon_sight": Vector2(9, 9),
	"chat_icon_sound": Vector2(9, 9),
	"chat_icon_environment": Vector2(9, 9),
	"chat_icon_traces": Vector2(9, 9),
	"chat_icon_check": Vector2(9, 9),
	"chat_icon_static": Vector2(9, 9),
	"chat_icon_notebook": Vector2(11, 11),
	"chat_signal": Vector2(75, 36),
	"chat_answer_normal": Vector2(19, 19),
	"chat_answer_hover": Vector2(19, 19),
	"chat_answer_pressed": Vector2(19, 19),
	"chat_answer_disabled": Vector2(19, 19),
}


func test_el_arte_del_chat_existe() -> bool:
	for art_name: String in CHAT_ART:
		var texture: Variant = load("res://art/ui/%s.png" % art_name)
		check(texture is Texture2D, "%s se importa como textura" % art_name)
		if texture is Texture2D:
			check_eq((texture as Texture2D).get_size(), CHAT_ART[art_name], art_name)
	return true
