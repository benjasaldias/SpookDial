extends Control
## Pantalla del final de la noche (Plan 5): dice si se ganó o se perdió y por qué. Si murió un amigo,
## explica la solicitud (EndingText). Aparece de a poco, para que se alcance a ver cómo quedó el
## escritorio, y tapa todo porque la noche ya terminó. Su botón vuelve a empezar la noche.
## Es provisional hasta el arte de las pantallas de victoria y derrota (docs/06 §3). El Plan 8 agrega
## el resumen entre noches y el paso a la noche siguiente.

## Se eligió volver a jugar: el escritorio reinicia la noche.
signal retry_pressed

const EndingText := preload("res://scripts/core/ending_text.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")

## El botón (ui.csv): "Reintentar" al perder y "Jugar de nuevo" al ganar.
const RETRY_KEY := "END_RETRY"
const PLAY_AGAIN_KEY := "END_PLAY_AGAIN"
## Segundos que tarda en aparecer.
const FADE_SECONDS := 1.5

@onready var _title: Label = $Center/Box/Title
@onready var _body: RichTextLabel = $Center/Box/Body
@onready var _button: Button = $Center/Box/Retry


func _ready() -> void:
	hide()
	_button.pressed.connect(retry_pressed.emit)


## Muestra cómo terminó la noche. `friend_names` son los nombres de los amigos, en orden.
func show_ending(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String]) -> void:
	_title.text = EndingText.title(ending, tr)
	_body.text = EndingText.body(ending, state, fatal_request, friend_names, tr)
	_button.text = tr(PLAY_AGAIN_KEY if ending == NightState.Ending.WON else RETRY_KEY)
	modulate.a = 0.0
	show()
	create_tween().tween_property(self, ^"modulate:a", 1.0, FADE_SECONDS)
