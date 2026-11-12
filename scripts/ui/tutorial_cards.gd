extends Control
## Las tarjetas del final de la noche 0 (pedido de Benja, 11 de noviembre): cuando León se despide, cada tarjeta muestra
## un video del juego en bucle (los medidores, el celular, la ventana y la Mano), su título y unas frases cortas.
## "Siguiente" pasa a la próxima y, en la última, empieza la noche 1; "Saltar" termina de una vez.
## Desde el Plan 9.5 (observación 14 del primer testeo), el texto va en viñetas, con los medidores en el color de su
## aguja: en el CSV se escriben {connection}, {sanity} y {trust}, y el color sale de las barras (StatBars), un solo
## lugar. Lo importante va en [b]…[/b], destacado.

## Se vieron todas o se saltaron.
signal finished

## Los textos de los botones y del número de tarjeta (ui.csv). TUTORIAL_CARDS_PAGE lleva {page} y {total}.
const NEXT_KEY := "TUTORIAL_CARDS_NEXT"
const START_KEY := "TUTORIAL_CARDS_START"
const SKIP_KEY := "TUTORIAL_CARDS_SKIP"
const PAGE_KEY := "TUTORIAL_CARDS_PAGE"
const StatBars := preload("res://scripts/ui/stat_bars.gd")
## Las marcas de cada medidor en el texto, en el orden de StatBars.Stat.
const METER_TAGS: Array[String] = ["connection", "sanity", "trust"]
## Lo destacado ([b]…[/b]): en el ámbar de lo que se puede apretar, porque Departure Mono no tiene negrita.
const STRONG_COLOR := "ffb347"
## Cómo empieza cada idea en el CSV.
const BULLET := "• "

## La tarjeta que se ve.
var index := 0

var _cards: Array[TutorialCardData] = []

@onready var _video: VideoStreamPlayer = $Center/Box/Row/VideoBox/Video
@onready var _title: Label = $Center/Box/Row/Side/Title
@onready var _text: RichTextLabel = $Center/Box/Row/Side/Text
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


## El texto de `card` listo para mostrar: los medidores con su nombre en su color y lo destacado en ámbar.
func card_bbcode(card: TutorialCardData) -> String:
	var values := {}
	for stat in METER_TAGS.size():
		values[METER_TAGS[stat]] = "[color=#%s]%s[/color]" % [StatBars.COLORS[stat].to_html(false),
				tr(StatBars.LABEL_KEYS[stat])]
	var text := tr(card.text_key).format(values)
	text = text.replace("[b]", "[color=#%s]" % STRONG_COLOR).replace("[/b]", "[/color]")
	# Las líneas con "•" van en una lista, para que lo que no cabe en una línea quede alineado bajo su texto.
	var items := PackedStringArray()
	for line: String in text.split("\n"):
		items.append(line.trim_prefix(BULLET).strip_edges())
	return "[ul bullet=%s]%s[/ul]" % [BULLET.strip_edges(), "\n".join(items)]


func finish() -> void:
	_video.stop()
	hide()
	finished.emit()


func _show_card() -> void:
	var card := _cards[index]
	_title.text = tr(card.title_key)
	_text.text = card_bbcode(card)
	_page.text = tr(PAGE_KEY).format({"page": index + 1, "total": _cards.size()})
	_next.text = tr(START_KEY if index == _cards.size() - 1 else NEXT_KEY)
	_video.stream = card.video
	_video.play()
