extends RefCounted
## Arma la página de una entidad en el cuaderno (diseño §12) como BBCode para un RichTextLabel: el folclore, las
## características con su nombre, las reglas en una tabla y las 4 acciones numeradas (pedido de Benja, 11 de
## noviembre). La tabla tiene una fila por regla, en orden, con su condición y una marca por acción: ✓ la correcta,
## una calavera la de mayor riesgo y ✗ las otras. Las marcas son íconos, porque la fuente no tiene esos símbolos.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

## Cómo marca la tabla cada acción de una regla.
enum Mark { CORRECT, RISKY, WRONG }

## Títulos y textos de la página (notebook.csv).
const TRAITS_KEY := "NOTEBOOK_TRAITS"
const RULES_KEY := "NOTEBOOK_RULES"
const ACTIONS_KEY := "NOTEBOOK_ACTIONS"
## El encabezado de la primera columna de la tabla.
const CONDITION_KEY := "NOTEBOOK_CONDITION"
## Bajo la tabla: qué significa la calavera.
const RISK_LEGEND_KEY := "NOTEBOOK_RISK_LEGEND"
## Los íconos de las marcas (art/ui/, pixel art de Claude que genera tools/make_ui_art.py).
const MARK_TEXTURES := {
	Mark.CORRECT: "res://art/ui/mark_check.png",
	Mark.RISKY: "res://art/ui/mark_risk.png",
	Mark.WRONG: "res://art/ui/mark_cross.png",
}
## El lado de los íconos en el arte, en píxeles.
const MARK_PIXELS := 9
## Colores de lápiz pasta sobre la hoja cuadriculada: azul para los encabezados.
const HEADING_COLOR := "234a8c"
## El espacio de cada celda: a los lados y arriba y abajo. El borde lo pone el tema del cuaderno (table_border).
const CELL_PADDING := "5,1,5,1"


## La página de `entity`, sin el nombre: el panel lo muestra como título. Los íconos de la tabla miden `icon_size`
## (el panel lo ajusta al tamaño de la letra, para que se vean nítidos).
static func bbcode(entity: EntityData, translate: Callable, icon_size := MARK_PIXELS) -> String:
	var lines := PackedStringArray([_escape(_text(translate, entity.lore_key))])
	lines.append(_heading(translate, TRAITS_KEY))
	for trait_data: TraitData in entity.traits:
		lines.append("• " + _escape(trait_label(trait_data, translate)))
	lines.append(_heading(translate, RULES_KEY))
	lines.append(_table(entity, translate, icon_size))
	lines.append("%s %s" % [_icon(Mark.RISKY, icon_size), _escape(_text(translate, RISK_LEGEND_KEY))])
	lines.append(_heading(translate, ACTIONS_KEY))
	for index in entity.actions.size():
		lines.append("%d. %s" % [index + 1, _escape(_text(translate, entity.actions[index].label_key))])
	return "\n".join(lines)


## Las marcas de `rule`, una por acción de `entity`, en orden.
static func marks(entity: EntityData, rule: RuleData) -> Array[Mark]:
	var result: Array[Mark] = []
	for action: ActionData in entity.actions:
		if action.id == rule.correct_action_id:
			result.append(Mark.CORRECT)
		elif action.id == rule.risky_action_id:
			result.append(Mark.RISKY)
		else:
			result.append(Mark.WRONG)
	return result


## El nombre de una característica en el cuaderno: su label_key, siempre el mismo aunque el amigo la diga con otras
## palabras (decisión de Benja, 11 de noviembre). Sin él, la frase entre asteriscos de su texto, y si el texto no tiene
## asteriscos, el texto completo.
static func trait_label(trait_data: TraitData, translate: Callable) -> String:
	if not trait_data.label_key.is_empty():
		return _text(translate, trait_data.label_key)
	var text := _text(translate, trait_data.text_key)
	var start := text.find("*")
	var end := text.find("*", start + 1)
	if start == -1 or end == -1:
		return text.replace("*", "")
	return text.substr(start + 1, end - start - 1)


## La tabla de reglas: un encabezado (la condición y el número de cada acción) y una fila por regla.
static func _table(entity: EntityData, translate: Callable, icon_size: int) -> String:
	var cells := PackedStringArray([_cell(_colored(_escape(_text(translate, CONDITION_KEY)), HEADING_COLOR), 6)])
	for index in entity.actions.size():
		cells.append(_cell(_colored(str(index + 1), HEADING_COLOR), 1))
	for rule: RuleData in entity.rules:
		cells.append(_cell(_escape(_text(translate, rule.text_key)), 6))
		for mark: Mark in marks(entity, rule):
			cells.append(_cell(_icon(mark, icon_size), 1))
	return "[table=%d]%s[/table]" % [entity.actions.size() + 1, "".join(cells)]


static func _cell(content: String, ratio: int) -> String:
	return "[cell expand=%d padding=%s]%s[/cell]" % [ratio, CELL_PADDING, content]


static func _icon(mark: Mark, icon_size: int) -> String:
	return "[img=%dx%d]%s[/img]" % [icon_size, icon_size, MARK_TEXTURES[mark]]


static func _heading(translate: Callable, key: String) -> String:
	return "\n" + _colored(_escape(_text(translate, key)), HEADING_COLOR)


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]


## [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
