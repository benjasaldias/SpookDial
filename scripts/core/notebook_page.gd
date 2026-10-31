extends RefCounted
## Arma la página de una entidad en el cuaderno (diseño §12) como BBCode para un RichTextLabel:
## el folclore, las características y las observaciones (cada una con la pregunta que las trae),
## las reglas en orden con su acción correcta y su acción de mayor riesgo, y las 4 acciones.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const MessageBuilder := preload("res://scripts/core/message_builder.gd")

## Títulos de las secciones (notebook.csv).
const TRAITS_KEY := "NOTEBOOK_TRAITS"
const OBSERVATIONS_KEY := "NOTEBOOK_OBSERVATIONS"
const RULES_KEY := "NOTEBOOK_RULES"
const ACTIONS_KEY := "NOTEBOOK_ACTIONS"
## Una característica u observación y la pregunta que la trae. Lleva {clue} y {question} (notebook.csv).
const CLUE_LINE_KEY := "NOTEBOOK_CLUE_LINE"
## Las acciones de una regla. Lleva {correct} y {risky} (notebook.csv).
const RULE_ACTIONS_KEY := "NOTEBOOK_RULE_ACTIONS"
## Colores provisionales para papel claro, hasta el arte del cuaderno. La acción de mayor riesgo
## también se nombra en el texto: el color no es la única pista (diseño §19).
const HEADING_COLOR := "6b3a1f"
const CORRECT_COLOR := "1f5c2e"
const RISKY_COLOR := "9b2a1c"


## La página de `entity`, sin el nombre: el panel lo muestra como título.
static func bbcode(entity: EntityData, translate: Callable) -> String:
	var lines := PackedStringArray([_escape(_text(translate, entity.lore_key))])
	lines.append(_heading(translate, TRAITS_KEY))
	for trait_data: TraitData in entity.traits:
		lines.append(_clue_line(translate, trait_label(trait_data, translate), trait_data.category))
	lines.append(_heading(translate, OBSERVATIONS_KEY))
	for observation: ObservationData in entity.observations:
		lines.append(_clue_line(translate, _text(translate, observation.question_key), observation.category))
	lines.append(_heading(translate, RULES_KEY))
	for index in entity.rules.size():
		lines.append(_rule_lines(entity, index, translate))
	lines.append(_heading(translate, ACTIONS_KEY))
	for action: ActionData in entity.actions:
		lines.append("• " + _escape(_text(translate, action.label_key)))
	return "\n".join(lines)


## El nombre de una característica en el cuaderno: la frase entre asteriscos de su texto, la misma
## que se clickea en los mensajes. Si el texto no tiene asteriscos, el texto completo.
static func trait_label(trait_data: TraitData, translate: Callable) -> String:
	var text := _text(translate, trait_data.text_key)
	var start := text.find("*")
	var end := text.find("*", start + 1)
	if start == -1 or end == -1:
		return text.replace("*", "")
	return text.substr(start + 1, end - start - 1)


static func _heading(translate: Callable, key: String) -> String:
	return "\n" + _colored(_escape(_text(translate, key)), HEADING_COLOR)


## "• hombrecito (¿Qué ves?)": si la estática tapa la característica, se sabe qué preguntar.
static func _clue_line(translate: Callable, clue: String, category: ClueCategory.Kind) -> String:
	var question := _text(translate, MessageBuilder.QUESTION_KEYS[category])
	return "• " + _escape(_text(translate, CLUE_LINE_KEY)).format({"clue": _escape(clue), "question": _escape(question)})


## "1. Si el amigo lo vio primero" y, en la línea siguiente, la acción correcta y la de mayor riesgo.
static func _rule_lines(entity: EntityData, index: int, translate: Callable) -> String:
	var rule := entity.rules[index]
	var actions := _escape(_text(translate, RULE_ACTIONS_KEY)).format({
		"correct": _colored(_action_label(entity, rule.correct_action_id, translate), CORRECT_COLOR),
		"risky": _colored(_action_label(entity, rule.risky_action_id, translate), RISKY_COLOR),
	})
	return "%d. %s\n%s" % [index + 1, _escape(_text(translate, rule.text_key)), actions]


static func _action_label(entity: EntityData, action_id: StringName, translate: Callable) -> String:
	var action := entity.find_action(action_id)
	return _escape(_text(translate, action.label_key)) if action != null else String(action_id)


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]


## [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
