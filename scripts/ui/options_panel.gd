extends Control
## Las opciones (diseño §19): el volumen de cada canal, reducir destellos, la cámara fija (sin parallax) y los
## temporizadores ×1,5. Cada cambio llega a las opciones al tiro y el panel avisa (`changed`), para que quien lo
## abrió las aplique y las guarde. Lo usan el menú principal y el menú de pausa. Es provisional hasta el arte.

## Cambió una opción.
signal changed(settings: GameSettings)
## Se cerró con "Volver".
signal closed

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo.
const TEXT_KEYS := {
	"Title": "OPTIONS_TITLE",
	"Master": "OPTIONS_VOLUME_MASTER",
	"Ambience": "OPTIONS_VOLUME_AMBIENCE",
	"Effects": "OPTIONS_VOLUME_EFFECTS",
	"Flashes": "OPTIONS_REDUCE_FLASHES",
	"Camera": "OPTIONS_STILL_CAMERA",
	"Timers": "OPTIONS_SLOW_TIMERS",
	"Back": "OPTIONS_BACK",
}

var settings: GameSettings

@onready var _box: VBoxContainer = $Center/Box
@onready var _flashes: CheckBox = $Center/Box/Flashes
@onready var _camera: CheckBox = $Center/Box/Camera
@onready var _timers: CheckBox = $Center/Box/Timers


func _ready() -> void:
	hide()
	(_box.get_node("Title") as Label).text = tr(TEXT_KEYS["Title"])
	for bus: StringName in GameSettings.BUSES:
		var row := _box.get_node(String(bus))
		(row.get_node("Label") as Label).text = tr(TEXT_KEYS[String(bus)])
		(row.get_node("Slider") as HSlider).value_changed.connect(_on_volume_changed.bind(bus))
	for check_name: String in ["Flashes", "Camera", "Timers"]:
		var check_box := _box.get_node(check_name) as CheckBox
		check_box.text = tr(TEXT_KEYS[check_name])
		check_box.toggled.connect(_on_toggled.bind(check_name))
	var back := _box.get_node("Back") as Button
	back.text = tr(TEXT_KEYS["Back"])
	back.pressed.connect(close)


## Muestra las opciones de `game_settings`, que se cambian ahí mismo.
func open(game_settings: GameSettings) -> void:
	settings = null
	for bus: StringName in GameSettings.BUSES:
		(_box.get_node(String(bus) + "/Slider") as HSlider).value = game_settings.volumes[bus] * 100.0
	_flashes.button_pressed = game_settings.reduce_flashes
	_camera.button_pressed = game_settings.still_camera
	_timers.button_pressed = game_settings.slow_timers
	# Recién ahora: así, mostrar los valores no cuenta como un cambio.
	settings = game_settings
	show()


func close() -> void:
	hide()
	closed.emit()


## Esc y el clic derecho cierran el panel.
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_volume_changed(value: float, bus: StringName) -> void:
	if settings == null:
		return
	settings.volumes[bus] = value / 100.0
	settings.apply_audio()
	changed.emit(settings)


func _on_toggled(on: bool, check_name: String) -> void:
	if settings == null:
		return
	match check_name:
		"Flashes":
			settings.reduce_flashes = on
		"Camera":
			settings.still_camera = on
		"Timers":
			settings.slow_timers = on
	changed.emit(settings)
