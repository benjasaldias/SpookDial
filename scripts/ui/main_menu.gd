extends Control
## El menú principal (diseño §5): Continuar (solo si hay una partida guardada), Nueva partida, Opciones y Salir.
## Desde S21i, Nueva partida pide elegir la dificultad (docs/26 §3.5): Normal viene marcada, y Difícil sale con un candado
## mientras no se termine Normal. Con una partida guardada, después de elegir pide confirmar, porque la borra. Continuar
## dice la noche y la dificultad de la partida guardada. Lo atiende GameState.
## Es provisional hasta el arte del menú y el logo (docs/06 §3).

signal continue_pressed
## Se eligió empezar una partida nueva en `difficulty`.
signal new_game_pressed(difficulty: DifficultyData)
signal quit_pressed
## Cambió una opción: hay que guardarla.
signal settings_changed(settings: GameSettings)

const GameSettings := preload("res://scripts/core/game_settings.gd")
const PixelText := preload("res://scripts/ui/pixel_text.gd")

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
	"DifficultyTitle": "MENU_DIFFICULTY_TITLE",
	"Locked": "MENU_LOCKED",
	"Start": "MENU_START",
	"Back": "MENU_BACK",
}
## Lo que separa la noche de la dificultad en Continuar: "Continuar: noche 3 · Normal".
const DIFFICULTY_SEPARATOR := " · "
## El candado de una dificultad bloqueada (art/ui/, pixel art de Claude), del tamaño que lo deja nítido junto a su letra.
const LOCK_ICON := preload("res://art/ui/menu_lock.png")
const LOCK_PIXELS := 11
const OPTION_FONT_SIZE := 22
const INFO_FONT_SIZE := 11
## La descripción de una dificultad bloqueada dice qué falta, en ámbar.
const LOCKED_COLOR := Color(0.95, 0.72, 0.3, 1)

## Con false (en las pruebas), el menú no se conecta a GameState: solo avisa con sus señales.
@export var use_game_state := true

var _settings := GameSettings.new()

@onready var _continue: Button = $Center/Box/Continue
@onready var _new_game: Button = $Center/Box/NewGame
@onready var _options_button: Button = $Center/Box/Options
@onready var _quit: Button = $Center/Box/Quit
@onready var _confirm: Control = $Center/Box/Confirm
@onready var _choice: Control = $Center/Box/Difficulty
@onready var _choice_options: VBoxContainer = $Center/Box/Difficulty/Options
@onready var _options: Control = $OptionsPanel

## La noche guardada, o -1 si no hay partida.
var _saved_night := -1
## Las dificultades que se pueden elegir, con su botón, en orden.
var _difficulties: Array[DifficultyData] = []
var _difficulty_buttons: Array[Button] = []
var _group := ButtonGroup.new()
## La dificultad elegida, que espera la confirmación.
var _chosen: DifficultyData


func _ready() -> void:
	_new_game.text = tr(TEXT_KEYS["NewGame"])
	_options_button.text = tr(TEXT_KEYS["Options"])
	_quit.text = tr(TEXT_KEYS["Quit"])
	(_confirm.get_node("Question") as Label).text = tr(TEXT_KEYS["Question"])
	var yes := _confirm.get_node("Buttons/Yes") as Button
	var no := _confirm.get_node("Buttons/No") as Button
	yes.text = tr(TEXT_KEYS["Yes"])
	no.text = tr(TEXT_KEYS["No"])
	(_choice.get_node("Title") as Label).text = tr(TEXT_KEYS["DifficultyTitle"])
	var start := _choice.get_node("Buttons/Start") as Button
	var back := _choice.get_node("Buttons/Back") as Button
	start.text = tr(TEXT_KEYS["Start"])
	back.text = tr(TEXT_KEYS["Back"])
	_confirm.hide()
	_choice.hide()
	_continue.pressed.connect(continue_pressed.emit)
	_new_game.pressed.connect(_show_choice)
	_options_button.pressed.connect(func() -> void: _options.open(_settings))
	_quit.pressed.connect(quit_pressed.emit)
	start.pressed.connect(_on_start_pressed)
	back.pressed.connect(_show_main)
	yes.pressed.connect(func() -> void: new_game_pressed.emit(_chosen))
	no.pressed.connect(_show_main)
	_options.changed.connect(settings_changed.emit)
	if use_game_state:
		var game := get_node("/root/GameState")
		setup(game.save.stored_night(), game.settings, game.catalog.find_difficulty(game.save.stored_difficulty()),
				game.catalog.difficulties, game.locked_difficulties())
		continue_pressed.connect(game.continue_game)
		new_game_pressed.connect(game.new_game)
		quit_pressed.connect(get_tree().quit)
		settings_changed.connect(func(_settings_changed: GameSettings) -> void: game.save_settings())
	else:
		setup(-1, _settings)


## Muestra Continuar si hay una partida guardada (`saved_night`, o -1, en `saved_difficulty`), usa `settings` en las
## opciones y arma la elección con `difficulties`, de las que `locked` todavía no se pueden elegir.
func setup(saved_night: int, settings: GameSettings, saved_difficulty: DifficultyData = null,
		difficulties: Array[DifficultyData] = [], locked: Array[DifficultyData] = []) -> void:
	_saved_night = saved_night
	_settings = settings
	_continue.visible = saved_night >= 0
	if saved_night == 0:
		_continue.text = tr(TEXT_KEYS["ContinueTutorial"])
	else:
		_continue.text = tr(TEXT_KEYS["Continue"]).format({"night": saved_night})
	if saved_difficulty != null:
		_continue.text += DIFFICULTY_SEPARATOR + tr(saved_difficulty.name_key)
	_build_choice(difficulties, locked)


## Una opción por dificultad, con su descripción debajo. La marcada se ve iluminada (como al pasar el mouse), y una
## bloqueada, hundida: no se puede elegir, lleva el candado y dice, en ámbar, qué dificultad hay que terminar.
func _build_choice(difficulties: Array[DifficultyData], locked: Array[DifficultyData]) -> void:
	for child: Node in _choice_options.get_children():
		_choice_options.remove_child(child)
		child.queue_free()
	_difficulties = difficulties.duplicate()
	_difficulty_buttons.clear()
	var icon_side := PixelText.icon_size_for(LOCK_PIXELS, PixelText.size(OPTION_FONT_SIZE))
	var marked := get_theme_stylebox(&"hover", &"Button")
	var marked_color := get_theme_color(&"font_hover_color", &"Button")
	for difficulty: DifficultyData in difficulties:
		var is_locked := locked.has(difficulty)
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _group
		button.text = tr(difficulty.name_key)
		button.disabled = is_locked
		button.add_theme_font_size_override(&"font_size", OPTION_FONT_SIZE)
		for state: StringName in [&"pressed", &"hover_pressed"]:
			button.add_theme_stylebox_override(state, marked)
		for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
			button.add_theme_color_override(state, marked_color)
		if is_locked:
			button.icon = LOCK_ICON
			button.expand_icon = true
			button.add_theme_constant_override(&"icon_max_width", icon_side)
		_choice_options.add_child(button)
		_difficulty_buttons.append(button)
		var info := Label.new()
		info.text = tr(difficulty.description_key)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(440, 0)
		info.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
		_choice_options.add_child(info)
		if is_locked and difficulty.unlocked_by != null:
			var lock := info.duplicate() as Label
			lock.text = tr(TEXT_KEYS["Locked"]).format({"difficulty": tr(difficulty.unlocked_by.name_key)})
			lock.add_theme_color_override(&"font_color", LOCKED_COLOR)
			_choice_options.add_child(lock)


## Nueva partida: esconde los botones del menú y muestra la elección, con la primera dificultad libre marcada (Normal).
func _show_choice() -> void:
	_set_main_visible(false)
	_confirm.hide()
	_choice.show()
	for button: Button in _difficulty_buttons:
		if not button.disabled:
			button.button_pressed = true
			button.grab_focus()
			break


## Vuelve a los botones del menú, desde la elección o desde la confirmación.
func _show_main() -> void:
	_choice.hide()
	_confirm.hide()
	_set_main_visible(true)
	_continue.visible = _saved_night >= 0


func _set_main_visible(shown: bool) -> void:
	for button: Button in [_continue, _new_game, _options_button, _quit]:
		button.visible = shown


## Empezar con la dificultad marcada: sin partida guardada, al tiro; con una, primero pregunta, porque se borra.
func _on_start_pressed() -> void:
	_chosen = _marked_difficulty()
	if _chosen == null:
		return
	if _saved_night < 0:
		new_game_pressed.emit(_chosen)
	else:
		_choice.hide()
		_confirm.show()


func _marked_difficulty() -> DifficultyData:
	for index in _difficulty_buttons.size():
		if _difficulty_buttons[index].button_pressed:
			return _difficulties[index]
	return null
