extends Control
## El menú de pausa (decisión de Benja, sesión 18): con Esc y sin paneles abiertos, la noche se pausa y aparece
## este menú: Continuar, Opciones y Volver al menú (la noche se pierde y, al continuar la partida, se juega desde
## su comienzo). Funciona con el juego en pausa. Es provisional hasta el arte.
## En la noche 0 suma "Saltar tutorial" (decisión de Benja, 11 de noviembre).

## Se eligió seguir la noche.
signal resumed
## Se eligió volver al menú principal.
signal menu_pressed
## Cambió una opción.
signal settings_changed(settings: GameSettings)
## Se eligió saltar el tutorial.
signal skip_tutorial_pressed

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo.
const TEXT_KEYS := {
	"Title": "PAUSE_TITLE",
	"Resume": "PAUSE_RESUME",
	"Options": "PAUSE_OPTIONS",
	"SkipTutorial": "PAUSE_SKIP_TUTORIAL",
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
	($Center/Box/SkipTutorial as Button).pressed.connect(skip_tutorial_pressed.emit)
	allow_skip_tutorial(false)
	_options.changed.connect(settings_changed.emit)


## Muestra "Saltar tutorial" solo en la noche 0.
func allow_skip_tutorial(allowed: bool) -> void:
	($Center/Box/SkipTutorial as Button).visible = allowed


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
