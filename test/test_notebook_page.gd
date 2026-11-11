extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const NotebookPage := preload("res://scripts/core/notebook_page.gd")

const FORMATS := {
}


## Traducción falsa: los formatos de FORMATS, cada característica con su id entre asteriscos,
## y cualquier otra clave tal cual.
func _translate(key: String) -> String:
	if FORMATS.has(key):
		return FORMATS[key]
	if key.begins_with("K_TRAIT_"):
		return "Hay *%s* cerca." % key.trim_prefix("K_TRAIT_")
	return key


## El texto como se ve: sin etiquetas BBCode y con [lb] convertido en corchete.
func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[(?!lb\\])[^\\]]*\\]").sub(bbcode, "", true).replace("[lb]", "[")


## El cuaderno muestra un nombre fijo, aunque el amigo la diga con otras palabras (decisión de Benja, 11 de noviembre).
func test_el_nombre_de_la_caracteristica_es_su_etiqueta() -> bool:
	var trait_data := Fixtures.make_trait(&"little_man")
	check_eq(NotebookPage.trait_label(trait_data, _translate), "K_LABEL_little_man", "su nombre en notebook.csv")
	return true


## Sin nombre propio, la frase entre asteriscos de su texto, como antes.
func test_nombre_de_una_caracteristica() -> bool:
	var trait_data := Fixtures.make_trait(&"little_man")
	trait_data.label_key = ""
	check_eq(NotebookPage.trait_label(trait_data, _translate), "little_man", "la frase entre asteriscos")
	var without_mark := func(_key: String) -> String: return "Un olor raro"
	check_eq(NotebookPage.trait_label(trait_data, without_mark), "Un olor raro", "sin asteriscos, el texto completo")
	return true


## La página (pedido de Benja, 11 de noviembre): el folclore, las características con su nombre y nada más, las reglas
## en una tabla con una marca por acción y las acciones numeradas.
func test_pagina_completa() -> bool:
	var page := _plain(NotebookPage.bbcode(Fixtures.make_entity(), _translate))
	check(page.begins_with("K_beast_LORE\n\nNOTEBOOK_TRAITS\n• K_LABEL_beast_trait_1\n• K_LABEL_beast_trait_2\n"),
			"folclore y características: " + page)
	check(page.contains("NOTEBOOK_RULES"), "el título de las reglas")
	check(page.contains("NOTEBOOK_RISK_LEGEND"), "la leyenda de la calavera")
	check(page.ends_with("NOTEBOOK_ACTIONS\n1. K_beast_A1\n2. K_beast_A2\n3. K_beast_A3\n4. K_beast_A4"),
			"las acciones, numeradas: " + page)
	return true


## Sin las preguntas entre paréntesis ni la lista de observaciones (pedido de Benja, 11 de noviembre).
func test_sin_preguntas_ni_observaciones() -> bool:
	var page := _plain(NotebookPage.bbcode(Fixtures.make_entity(), _translate))
	check(not page.contains("QUESTION_"), "ninguna pregunta")
	check(not page.contains("K_beast_O1_Q") and not page.contains("K_beast_O2_Q"), "ninguna observación")
	return true


## Cada fila de la tabla tiene una marca por acción: ✓ la correcta, una calavera la de mayor riesgo y ✗ las otras.
func test_la_tabla_marca_cada_accion() -> bool:
	var entity := Fixtures.make_entity()
	check_eq(NotebookPage.marks(entity, entity.rules[0]),
			[NotebookPage.Mark.CORRECT, NotebookPage.Mark.RISKY, NotebookPage.Mark.WRONG, NotebookPage.Mark.WRONG],
			"regla 1: correcta a1 y riesgo a2")
	check_eq(NotebookPage.marks(entity, entity.rules[2]),
			[NotebookPage.Mark.WRONG, NotebookPage.Mark.CORRECT, NotebookPage.Mark.RISKY, NotebookPage.Mark.WRONG],
			"regla 3: correcta a2 y riesgo a3")
	var page := NotebookPage.bbcode(entity, _translate, 12)
	check(page.contains("[table=5]"), "es una tabla de 5 columnas")
	var first_row := "[img=12x12]%s[/img]" % NotebookPage.MARK_TEXTURES[NotebookPage.Mark.CORRECT]
	check(page.contains(first_row), "las marcas son íconos del tamaño pedido")
	check_eq(page.count("[img=12x12]"), 3 * 4 + 1, "una por acción en cada regla, y la de la leyenda")
	for texture_path: String in NotebookPage.MARK_TEXTURES.values():
		check(ResourceLoader.exists(texture_path), "existe %s" % texture_path)
	return true


func test_los_corchetes_se_ven() -> bool:
	var proto := func(key: String) -> String: return "[PROTO] " + _translate(key)
	var page := NotebookPage.bbcode(Fixtures.make_entity(), proto)
	check(_plain(page).begins_with("[PROTO] K_beast_LORE"), "[PROTO] se ve como texto")
	check(not page.contains("[PROTO]"), "se escribe con [lb]")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	for key: String in [NotebookPage.TRAITS_KEY, NotebookPage.RULES_KEY, NotebookPage.ACTIONS_KEY,
			NotebookPage.CONDITION_KEY, NotebookPage.RISK_LEGEND_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en notebook.csv" % key)
	TranslationServer.set_locale(previous)
	return true