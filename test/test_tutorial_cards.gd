extends "res://test/test_case.gd"
## Las tarjetas con videos del final de la noche 0 (pedido de Benja, 11 de noviembre).

const CARDS := preload("res://scenes/ui/tutorial_cards.tscn")


func _cards_data() -> Array[TutorialCardData]:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	return catalog.tutorial.tutorial_cards


func _make_cards() -> Control:
	var cards := CARDS.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(cards)
	return cards


func _text(cards: Control, node_path: String) -> String:
	return (cards.get_node(node_path) as Control).get("text")


func _tr(key: String) -> String:
	return String(TranslationServer.translate(key))


func test_empieza_en_la_primera() -> bool:
	var cards := _make_cards()
	check(not cards.visible, "escondidas hasta que León se despide")
	var data := _cards_data()
	cards.open(data)
	check(cards.visible, "aparecen")
	check_eq(_text(cards, "Center/Box/Row/Side/Title"), _tr(data[0].title_key), "la primera")
	check_eq((cards.get_node("Center/Box/Row/VideoBox/Video") as VideoStreamPlayer).stream, data[0].video, "con su video")
	check_eq(_text(cards, "Center/Box/Row/Side/Page"), _tr("TUTORIAL_CARDS_PAGE").format({"page": 1, "total": 4}), "1 de 4")
	check_eq(_text(cards, "Center/Box/Row/Side/Buttons/Next"), _tr("TUTORIAL_CARDS_NEXT"), "Siguiente")
	cards.free()
	return true


func test_siguiente_hasta_la_ultima() -> bool:
	var cards := _make_cards()
	var done := []
	cards.finished.connect(func() -> void: done.append(true))
	var data := _cards_data()
	cards.open(data)
	var next := cards.get_node("Center/Box/Row/Side/Buttons/Next") as Button
	for _press in 3:
		next.pressed.emit()
	check_eq(_text(cards, "Center/Box/Row/Side/Title"), _tr(data[3].title_key), "la última")
	check_eq(next.text, _tr("TUTORIAL_CARDS_START"), "empieza la noche 1")
	check(done.is_empty(), "todavía no termina")
	next.pressed.emit()
	check_eq(done.size(), 1, "termina")
	check(not cards.visible, "y se esconden")
	cards.free()
	return true


func test_saltar_termina() -> bool:
	var cards := _make_cards()
	var done := []
	cards.finished.connect(func() -> void: done.append(true))
	cards.open(_cards_data())
	(cards.get_node("Center/Box/Row/Side/Buttons/Skip") as Button).pressed.emit()
	check_eq(done.size(), 1, "termina de una vez")
	cards.free()
	return true


func test_cada_tarjeta_tiene_su_video() -> bool:
	var data := _cards_data()
	check_eq(data.size(), 4, "los medidores, el celular, la ventana y la Mano")
	for card: TutorialCardData in data:
		check(card.video is VideoStreamTheora, "%s: con su video" % card.title_key)
		check(_tr(card.title_key) != card.title_key, "existe %s" % card.title_key)
		check(_tr(card.text_key) != card.text_key, "existe %s" % card.text_key)
	return true


func test_sus_textos_existen() -> bool:
	for key: String in ["TUTORIAL_CARDS_NEXT", "TUTORIAL_CARDS_START", "TUTORIAL_CARDS_SKIP", "TUTORIAL_CARDS_PAGE"]:
		check(_tr(key) != key, "falta %s en ui.csv" % key)
	return true


## Las tarjetas con colores y viñetas (observación 14 del primer testeo): Connection en verde, Sanity en rojo y Trust en
## amarillo, el color de su aguja, tomado de las barras; cada idea en una línea con "•", y ninguna marca sin reemplazar.
func test_los_medidores_van_con_su_color() -> bool:
	const StatBars := preload("res://scripts/ui/stat_bars.gd")
	var cards := _make_cards()
	cards.open(_cards_data())
	var text := cards.get_node("Center/Box/Row/Side/Text") as RichTextLabel
	check(text != null, "el texto admite colores")
	if text == null:
		cards.free()
		return true
	for stat in 3:
		var name := _tr(StatBars.LABEL_KEYS[stat])
		check(text.text.contains("[color=#%s]%s" % [StatBars.COLORS[stat].to_html(false), name]),
				"%s con el color de su aguja" % name)
	check(text.text.begins_with("[ul"), "en una lista con viñetas")
	for data: TutorialCardData in _cards_data():
		var shown: String = cards.card_bbcode(data)
		check(not shown.contains("{"), "%s sin marcas sin reemplazar" % data.text_key)
		check(_tr(data.text_key).begins_with("•"), "%s en viñetas" % data.text_key)
	cards.free()
	return true
