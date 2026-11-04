extends Control
## El menú de pausa (decisión de Benja, sesión 18): con Esc y sin paneles abiertos, la noche se pausa y aparece
## este menú: Continuar, Opciones y Volver al menú (la noche se pierde y, al continuar la partida, se juega desde
## su comienzo). Funciona con el juego en pausa. Es provisional hasta el arte.

## Se eligió seguir la noche.
signal resumed
## Se eligió volver al menú principal.
signal menu_pressed
## Cambió una opción.
signal settings_changed(settings: GameSettings)

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo.
const TEXT_KEYS := {
	"Title": "PAUSE_TITLE",
	"Resume": "PAUSE_RESUME",
	"Options": "PAUSE_OPTIONS",
	"Menu": "PAUSE_MENU",
}

var _settings := GameSettings.new()

@onready var _options: Control = $OptionsPanel


func _ready() -> void:
	hide()
	for node_name: String in TEXT_KEYS:
		get_node("Center/Box/" + node_name).text = tr(TEXT_KEYS[node_name])
	($Center/Box/Resume as Button).pressed.connect(resume)
	($Center/Box/Options as Button).pressed.connect(func() -> void: _options.open(_settings))
	($Center/Box/Menu as Button).pressed.connect(menu_pressed.emit)
	_options.changed.connect(settings_changed.emit)


## Aparece, con `settings` para sus opciones.
func open(settings: GameSettings) -> void:
	_settings = settings
	show()


func resume() -> void:
	_options.hide()
	hide()
	resumed.emit()


## Esc sigue la noche. Con las opciones abiertas, Esc las cierra primero (OptionsPanel lo atiende antes).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		resume()
		get_viewport().set_input_as_handled()
