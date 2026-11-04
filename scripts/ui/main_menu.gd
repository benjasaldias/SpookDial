extends Control
## El menú principal (diseño §5): Continuar (solo si hay una partida guardada), Nueva partida, Opciones y Salir.
## Con una partida guardada, Nueva partida pide confirmar, porque la borra. Lo atiende GameState.
## Es provisional hasta el arte del menú y el logo (docs/06 §3).

signal continue_pressed
signal new_game_pressed
signal quit_pressed
## Cambió una opción: hay que guardarla.
signal settings_changed(settings: GameSettings)

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo. MENU_CONTINUE lleva {night}.
const TEXT_KEYS := {
	"Continue": "MENU_CONTINUE",
	"ContinueTutorial": "MENU_CONTINUE_TUTORIAL",
	"NewGame": "MENU_NEW_GAME",
	"Options": "MENU_OPTIONS",
	"Quit": "MENU_QUIT",
	"Question": "MENU_CONFIRM_NEW",
	"Yes": "MENU_YES",
	"No": "MENU_NO",
}

## Con false (en las pruebas), el menú no se conecta a GameState: solo avisa con sus señales.
@export var use_game_state := true

var _settings := GameSettings.new()

@onready var _continue: Button = $Center/Box/Continue
@onready var _new_game: Button = $Center/Box/NewGame
@onready var _options_button: Button = $Center/Box/Options
@onready var _quit: Button = $Center/Box/Quit
@onready var _confirm: Control = $Center/Box/Confirm
@onready var _options: Control = $OptionsPanel

## La noche guardada, o -1 si no hay partida.
var _saved_night := -1


func _ready() -> void:
	_new_game.text = tr(TEXT_KEYS["NewGame"])
	_options_button.text = tr(TEXT_KEYS["Options"])
	_quit.text = tr(TEXT_KEYS["Quit"])
	(_confirm.get_node("Question") as Label).text = tr(TEXT_KEYS["Question"])
	var yes := _confirm.get_node("Buttons/Yes") as Button
	var no := _confirm.get_node("Buttons/No") as Button
	yes.text = tr(TEXT_KEYS["Yes"])
	no.text = tr(TEXT_KEYS["No"])
	_confirm.hide()
	_continue.pressed.connect(continue_pressed.emit)
	_new_game.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(func() -> void: _options.open(_settings))
	_quit.pressed.connect(quit_pressed.emit)
	yes.pressed.connect(new_game_pressed.emit)
	no.pressed.connect(_confirm.hide)
	_options.changed.connect(settings_changed.emit)
	if use_game_state:
		var game := get_node("/root/GameState")
		setup(game.save.stored_night(), game.settings)
		continue_pressed.connect(game.continue_game)
		new_game_pressed.connect(game.new_game)
		quit_pressed.connect(get_tree().quit)
		settings_changed.connect(func(_settings_changed: GameSettings) -> void: game.save_settings())
	else:
		setup(-1, _settings)


## Muestra Continuar si hay una partida guardada (`saved_night`, o -1), y usa `settings` en las opciones.
func setup(saved_night: int, settings: GameSettings) -> void:
	_saved_night = saved_night
	_settings = settings
	_continue.visible = saved_night >= 0
	if saved_night == 0:
		_continue.text = tr(TEXT_KEYS["ContinueTutorial"])
	else:
		_continue.text = tr(TEXT_KEYS["Continue"]).format({"night": saved_night})


## Sin partida guardada, empieza al tiro; con una, primero pregunta.
func _on_new_game_pressed() -> void:
	if _saved_night < 0:
		new_game_pressed.emit()
	else:
		_confirm.show()
