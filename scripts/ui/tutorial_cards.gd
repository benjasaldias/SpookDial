extends Control
## Las tarjetas del final de la noche 0 (pedido de Benja, 11 de noviembre): cuando León se despide, cada tarjeta muestra
## un video del juego en bucle (los medidores, el celular, la ventana y la Mano), su título y unas frases cortas.
## "Siguiente" pasa a la próxima y, en la última, empieza la noche 1; "Saltar" termina de una vez.

## Se vieron todas o se saltaron.
signal finished

## Los textos de los botones y del número de tarjeta (ui.csv). TUTORIAL_CARDS_PAGE lleva {page} y {total}.
const NEXT_KEY := "TUTORIAL_CARDS_NEXT"
const START_KEY := "TUTORIAL_CARDS_START"
const SKIP_KEY := "TUTORIAL_CARDS_SKIP"
const PAGE_KEY := "TUTORIAL_CARDS_PAGE"

## La tarjeta que se ve.
var index := 0

var _cards: Array[TutorialCardData] = []

@onready var _video: VideoStreamPlayer = $Center/Box/Row/VideoBox/Video
@onready var _title: Label = $Center/Box/Row/Side/Title
@onready var _text: Label = $Center/Box/Row/Side/Text
@onready var _page: Label = $Center/Box/Row/Side/Page
@onready var _next: Button = $Center/Box/Row/Side/Buttons/Next
@onready var _skip: Button = $Center/Box/Row/Side/Buttons/Skip


func _ready() -> void:
	hide()
	_skip.text = tr(SKIP_KEY)
	_next.pressed.connect(next)
	_skip.pressed.connect(finish)
	# Los videos se repiten mientras la tarjeta esté a la vista.
	_video.finished.connect(_video.play)


## Aparece en la primera de `cards`.
func open(cards: Array[TutorialCardData]) -> void:
	_cards = cards
	index = 0
	show()
	_show_card()


## La tarjeta siguiente o, después de la última, termina.
func next() -> void:
	if index + 1 >= _cards.size():
		finish()
		return
	index += 1
	_show_card()


func finish() -> void:
	_video.stop()
	hide()
	finished.emit()


func _show_card() -> void:
	var card := _cards[index]
	_title.text = tr(card.title_key)
	_text.text = tr(card.text_key)
	_page.text = tr(PAGE_KEY).format({"page": index + 1, "total": _cards.size()})
	_next.text = tr(START_KEY if index == _cards.size() - 1 else NEXT_KEY)
	_video.stream = card.video
	_video.play()
