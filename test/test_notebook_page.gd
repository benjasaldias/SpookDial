extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const NotebookPage := preload("res://scripts/core/notebook_page.gd")

const FORMATS := {
	"NOTEBOOK_CLUE_LINE": "{clue} ({question})",
	"NOTEBOOK_RULE_ACTIONS": "→ {correct} · riesgo: {risky}",
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


func test_nombre_de_una_caracteristica() -> bool:
	var trait_data := Fixtures.make_trait(&"little_man")
	check_eq(NotebookPage.trait_label(trait_data, _translate), "little_man", "la frase entre asteriscos")
	var without_mark := func(_key: String) -> String: return "Un olor raro"
	check_eq(NotebookPage.trait_label(trait_data, without_mark), "Un olor raro", "sin asteriscos, el texto completo")
	return true


func test_pagina_completa() -> bool:
	var entity := Fixtures.make_entity()
	entity.observations[1].category = ClueCategory.Kind.SOUND
	var expected := "\n".join([
		"K_beast_LORE",
		"",
		"NOTEBOOK_TRAITS",
		"• beast_trait_1 (QUESTION_SIGHT)",
		"• beast_trait_2 (QUESTION_SIGHT)",
		"",
		"NOTEBOOK_OBSERVATIONS",
		"• K_beast_O1_Q (QUESTION_SIGHT)",
		"• K_beast_O2_Q (QUESTION_SOUND)",
		"",
		"NOTEBOOK_RULES",
		"1. K_RULE",
		"→ K_beast_A1 · riesgo: K_beast_A2",
		"2. K_RULE",
		"→ K_beast_A3 · riesgo: K_beast_A4",
		"3. K_RULE",
		"→ K_beast_A2 · riesgo: K_beast_A3",
		"",
		"NOTEBOOK_ACTIONS",
		"• K_beast_A1",
		"• K_beast_A2",
		"• K_beast_A3",
		"• K_beast_A4",
	])
	check_eq(_plain(NotebookPage.bbcode(entity, _translate)), expected, "página")
	return true


func test_la_correcta_y_la_de_mayor_riesgo_se_distinguen() -> bool:
	var page := NotebookPage.bbcode(Fixtures.make_entity(), _translate)
	check(page.contains("[color=#%s]K_beast_A1[/color]" % NotebookPage.CORRECT_COLOR), "la correcta, en su color")
	check(page.contains("[color=#%s]K_beast_A2[/color]" % NotebookPage.RISKY_COLOR), "la de mayor riesgo, en el suyo")
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
	for key: String in [NotebookPage.TRAITS_KEY, NotebookPage.OBSERVATIONS_KEY, NotebookPage.RULES_KEY,
			NotebookPage.ACTIONS_KEY, NotebookPage.CLUE_LINE_KEY, NotebookPage.RULE_ACTIONS_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en notebook.csv" % key)
	var clue_line := String(TranslationServer.translate(NotebookPage.CLUE_LINE_KEY))
	check(clue_line.contains("{clue}") and clue_line.contains("{question}"),
			"NOTEBOOK_CLUE_LINE debe tener {clue} y {question}")
	var rule_actions := String(TranslationServer.translate(NotebookPage.RULE_ACTIONS_KEY))
	check(rule_actions.contains("{correct}") and rule_actions.contains("{risky}"),
			"NOTEBOOK_RULE_ACTIONS debe tener {correct} y {risky}")
	TranslationServer.set_locale(previous)
	return true
