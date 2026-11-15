extends Control
## Pantalla del final de la noche (Plan 5): dice si se ganó o se perdió y por qué. Si murió un amigo,
## explica la solicitud (EndingText). Aparece de a poco, para que se alcance a ver cómo quedó el
## escritorio, y tapa todo porque la noche ya terminó.
## Desde el Plan 8, al ganar es el resumen entre noches (diseño §5) y su botón empieza la noche siguiente; al
## perder, se reintenta la noche. Siempre se puede volver al menú. Al ganar la noche 5, solo queda el menú.
## Es provisional hasta el arte de las pantallas de victoria y derrota (docs/06 §3).
## Desde el Plan 9.9, al ganar una noche de la 1 a la 5 muestra su nota (NightGrade): la letra grande y, al final del
## resumen, la espera y las vidas perdidas.

## Se eligió volver a jugar la noche.
signal retry_pressed
## Se eligió empezar la noche siguiente.
signal next_pressed
## Se eligió volver al menú principal.
signal menu_pressed

const EndingText := preload("res://scripts/core/ending_text.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const NightGrade := preload("res://scripts/core/night_grade.gd")

## Los botones (ui.csv). END_NEXT lleva {night}.
const RETRY_KEY := "END_RETRY"
const NEXT_KEY := "END_NEXT"
const MENU_KEY := "END_MENU"
## Segundos que tarda en aparecer.
const FADE_SECONDS := 1.5

@onready var _title: Label = $Center/Box/Title
@onready var _grade: Label = $Center/Box/Grade
@onready var _body: RichTextLabel = $Center/Box/Body
@onready var _retry: Button = $Center/Box/Buttons/Retry
@onready var _next: Button = $Center/Box/Buttons/Next
@onready var _menu: Button = $Center/Box/Buttons/Menu


func _ready() -> void:
	hide()
	_retry.text = tr(RETRY_KEY)
	_menu.text = tr(MENU_KEY)
	_retry.pressed.connect(retry_pressed.emit)
	_next.pressed.connect(next_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)


## Muestra cómo terminó la noche `night_number`. `friend_names` son los nombres de los amigos, en orden, y
## `new_pages`, los nombres de las páginas que el cuaderno suma la noche siguiente, y `unlocked`, los de las dificultades
## que se desbloquean al ganar la última noche.
func show_ending(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String], night_number := 1, new_pages: Array[String] = [],
		unlocked: Array[String] = []) -> void:
	var won := ending == NightState.Ending.WON
	# La nota, solo al ganar una noche de la 1 a la 5 (Plan 9.9).
	var graded := won and night_number >= 1
	_grade.visible = graded
	if won:
		_title.text = EndingText.won_title(night_number, tr, state.clock_text())
		_body.text = EndingText.summary(night_number, state, new_pages, tr, unlocked)
		if graded:
			_grade.text = EndingText.grade_title(NightGrade.letter_for(state), tr)
			_body.text += "\n\n" + EndingText.grade_detail(state, tr)
	else:
		_title.text = EndingText.title(ending, tr)
		_body.text = EndingText.body(ending, state, fatal_request, friend_names, tr)
	_retry.visible = not won
	_next.visible = won and night_number < EndingText.LAST_NIGHT
	_next.text = tr(NEXT_KEY).format({"night": night_number + 1})
	modulate.a = 0.0
	show()
	create_tween().tween_property(self, ^"modulate:a", 1.0, FADE_SECONDS)
