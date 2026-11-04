extends PanelContainer
## El aviso de la noche 0, el tutorial (decisión de Benja): arriba de la pantalla, entre el chat y el cuaderno,
## dice qué hacer ahora. Su botón salta el tutorial. Es provisional hasta el arte (docs/06 §3).

signal skip_pressed

const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")

@onready var _title: Label = $Box/Title
@onready var _body: Label = $Box/Body
@onready var _skip: Button = $Box/Skip


func _ready() -> void:
	_title.text = tr(TutorialGuide.TITLE_KEY)
	_skip.text = tr(TutorialGuide.SKIP_KEY)
	_skip.pressed.connect(skip_pressed.emit)


## Muestra `text`. Sin texto, solo quedan el título y el botón.
func show_text(text: String) -> void:
	_body.text = text
	_body.visible = not text.is_empty()
