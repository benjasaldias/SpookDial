extends PanelContainer
## El aviso de la noche 0, el tutorial (decisión de Benja): arriba de la pantalla, entre el chat y el cuaderno,
## dice qué hacer ahora. Su botón salta el tutorial. Es provisional hasta el arte (docs/06 §3).

signal skip_pressed
## Matías presionó "Entendido".
signal ok_pressed

const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")

@onready var _title: Label = $Box/Title
@onready var _body: Label = $Box/Body
@onready var _ok: Button = $Box/Ok
@onready var _skip: Button = $Box/Skip


func _ready() -> void:
	_title.text = tr(TutorialGuide.TITLE_KEY)
	_skip.text = tr(TutorialGuide.SKIP_KEY)
	_skip.pressed.connect(skip_pressed.emit)
	_ok.text = tr(TutorialGuide.DIALS_OK_KEY)
	_ok.pressed.connect(ok_pressed.emit)


## Muestra `text`, con el botón "Entendido" si `with_ok`. Sin texto, solo quedan el título y el botón de saltar.
func show_text(text: String, with_ok := false) -> void:
	_body.text = text
	_body.visible = not text.is_empty()
	_ok.visible = with_ok
