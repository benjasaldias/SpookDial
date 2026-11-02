extends RefCounted
## Los textos de la pantalla del final de la noche (diseño §5): si se ganó o se perdió, y por qué.
## Si murió un amigo, explica la solicitud: la entidad, lo que observaba el amigo, la regla que se
## aplicaba, la acción correcta y la que se eligió (docs/02 §2). El cuerpo es BBCode para un RichTextLabel.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Títulos (ui.csv).
const WON_TITLE_KEY := "END_WON_TITLE"
const LOST_TITLE_KEY := "END_LOST_TITLE"
## Por qué terminó la noche (ui.csv). END_WON y END_QUOTA llevan {received} y {quota};
## END_FRIEND_DIED lleva {friend}.
const REASON_KEYS := {
	NightState.Ending.WON: "END_WON",
	NightState.Ending.FRIEND_DIED: "END_FRIEND_DIED",
	NightState.Ending.SANITY: "END_SANITY",
	NightState.Ending.TRUST: "END_TRUST",
	NightState.Ending.CONNECTION: "END_CONNECTION",
	NightState.Ending.QUOTA: "END_QUOTA",
}
## La solicitud en la que murió el amigo (ui.csv). Llevan {entity}; {number} y {rule}; {action};
## y {friend} y {action}. CHOSEN_OFFLINE: el amigo decidió solo y sin señal.
const ENTITY_KEY := "END_ENTITY"
const SITUATION_KEY := "END_SITUATION"
const RULE_KEY := "END_RULE"
const CORRECT_KEY := "END_CORRECT"
const CHOSEN_BY_PLAYER_KEY := "END_CHOSEN_BY_PLAYER"
const CHOSEN_ALONE_KEY := "END_CHOSEN_ALONE"
const CHOSEN_OFFLINE_KEY := "END_CHOSEN_OFFLINE"
## Colores provisionales sobre fondo oscuro. Cada línea también dice qué acción es: el color no es
## la única pista (diseño §19).
const CORRECT_COLOR := "7ee08a"
const CHOSEN_COLOR := "ff6464"


static func title(ending: NightState.Ending, translate: Callable) -> String:
	return _text(translate, WON_TITLE_KEY if ending == NightState.Ending.WON else LOST_TITLE_KEY)


## Por qué terminó la noche y, si murió un amigo, qué pasó en `fatal_request`.
## `friend_names` son los nombres de los amigos, en orden.
static func body(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String], translate: Callable) -> String:
	var friend := _escape(friend_names[fatal_request.friend_index]) if fatal_request != null else ""
	var lines := PackedStringArray([_line(translate, REASON_KEYS[ending],
			{"received": state.videos.received, "quota": state.videos.quota, "friend": friend})])
	if fatal_request != null:
		lines.append("")
		lines.append_array(_request_lines(fatal_request, friend, translate))
	return "\n".join(lines)


## La entidad, lo que observaba el amigo, la regla que se aplicaba, la acción correcta y la elegida.
static func _request_lines(request: FriendRequest, friend: String, translate: Callable) -> PackedStringArray:
	var entity := request.entity
	var lines := PackedStringArray()
	lines.append(_line(translate, ENTITY_KEY, {"entity": _escape(_text(translate, entity.name_key))}))
	lines.append(_line(translate, SITUATION_KEY, {}))
	for observation: ObservationData in entity.observations:
		var value_key: String = observation.values[request.situation[observation.id]]
		lines.append("• %s — %s" % [_escape(_text(translate, observation.question_key)), _escape(_text(translate, value_key))])
	var rule := RuleEvaluator.applicable_rule(entity, request.situation)
	lines.append(_line(translate, RULE_KEY,
			{"number": entity.rules.find(rule) + 1, "rule": _escape(_text(translate, rule.text_key))}))
	var correct := entity.find_action(rule.correct_action_id)
	lines.append(_line(translate, CORRECT_KEY, {"action": _action(correct, CORRECT_COLOR, translate)}))
	var chosen := _action(request.chosen_action, CHOSEN_COLOR, translate)
	if request.answered_by_player:
		lines.append(_line(translate, CHOSEN_BY_PLAYER_KEY, {"action": chosen}))
	elif request.decided_offline:
		lines.append(_line(translate, CHOSEN_OFFLINE_KEY, {"friend": friend, "action": chosen}))
	else:
		lines.append(_line(translate, CHOSEN_ALONE_KEY, {"friend": friend, "action": chosen}))
	return lines


static func _action(action: ActionData, color: String, translate: Callable) -> String:
	return "[color=#%s]%s[/color]" % [color, _escape(_text(translate, action.label_key))]


## El formato de `key` con sus corchetes como texto, y los `values` ya preparados para BBCode.
static func _line(translate: Callable, key: String, values: Dictionary) -> String:
	return _escape(_text(translate, key)).format(values)


## [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
