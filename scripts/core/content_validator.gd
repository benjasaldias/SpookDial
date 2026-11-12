extends RefCounted
## Revisa que el contenido esté bien armado. Cada función devuelve los errores en español;
## una lista vacía significa que todo está bien. test_catalog.gd la usa sobre el contenido real,
## así que un error de diseño aparece al correr las pruebas.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Límites de la plantilla de docs/02 §7.
const TRAIT_COUNT := Vector2i(2, 4)
const ACTION_COUNT := Vector2i(4, 4)
const OBSERVATION_COUNT := Vector2i(2, 3)
const RULE_COUNT := Vector2i(2, 4)
const MIN_VALUES := 2
const FRIEND_COUNT := Vector2i(3, 3)
const NIGHT_COUNT := Vector2i(5, 5)
## Formas de decir una característica, además de text_key (decisión de Benja, 11 de noviembre).
const VARIANT_COUNT := Vector2i(2, 4)
## Una característica se comparte con otra entidad como máximo: lo que identifica es la combinación.
const MAX_ENTITIES_PER_TRAIT := 2
## Marca de la frase clickeable de una característica: "vio un *hombrecito*".
const HIGHLIGHT_MARK := "*"


static func validate_entity(entity: EntityData) -> Array[String]:
	var errors: Array[String] = []
	var who := "Entidad '%s'" % entity.id
	if entity.id.is_empty():
		errors.append("Hay una entidad sin id")
	for list_name: String in ["traits", "actions", "observations", "rules"]:
		if (entity.get(list_name) as Array).has(null):
			errors.append("%s: hay un espacio vacío en '%s'" % [who, list_name])
	if not errors.is_empty():
		return errors
	if entity.place_keys.is_empty():
		errors.append("%s: no tiene lugares" % who)
	_check_count(errors, who, "características", entity.traits.size(), TRAIT_COUNT)
	_check_count(errors, who, "acciones", entity.actions.size(), ACTION_COUNT)
	_check_count(errors, who, "observaciones", entity.observations.size(), OBSERVATION_COUNT)
	_check_count(errors, who, "reglas", entity.rules.size(), RULE_COUNT)
	_check_unique_ids(errors, who, "características", entity.traits)
	_check_unique_ids(errors, who, "acciones", entity.actions)
	_check_unique_ids(errors, who, "observaciones", entity.observations)
	for trait_data: TraitData in entity.traits:
		_check_variants(errors, who, trait_data)
	for observation: ObservationData in entity.observations:
		if observation.values.size() < MIN_VALUES:
			errors.append("%s: la observación '%s' necesita al menos %d valores" % [who, observation.id, MIN_VALUES])
		_check_audio(errors, who, observation)
	for index in entity.rules.size():
		_check_rule(errors, who, entity, index)
	# Buscar reglas que nunca se aplican solo tiene sentido si todo lo anterior está bien.
	if errors.is_empty():
		_check_reachable(errors, who, entity)
	return errors


## Revisa amigos, dificultades con sus noches y todas las entidades, también las relaciones entre entidades.
static func validate_catalog(catalog: ContentCatalog) -> Array[String]:
	var errors: Array[String] = []
	var who := "Catálogo"
	if catalog.friends.has(null) or catalog.difficulties.has(null):
		errors.append("%s: hay un espacio vacío en 'friends' o en 'difficulties'" % who)
		return errors
	_check_count(errors, who, "amigos", catalog.friends.size(), FRIEND_COUNT)
	_check_unique_ids(errors, who, "amigos", catalog.friends)
	if catalog.difficulties.is_empty():
		errors.append("%s: no tiene dificultades" % who)
		return errors
	_check_unique_ids(errors, who, "dificultades", catalog.difficulties)
	for difficulty: DifficultyData in catalog.difficulties:
		_check_difficulty(errors, catalog, difficulty)
	if catalog.greeting_keys.is_empty():
		errors.append("%s: no tiene saludos para el mensaje inicial" % who)
	if catalog.predicament_keys.is_empty():
		errors.append("%s: no tiene frases de lo que le pasa al amigo" % who)
	for key: String in catalog.alone_predicament_keys:
		if not catalog.predicament_keys.has(key):
			errors.append("%s: '%s' es de un amigo solo, pero no está en las frases de lo que le pasa" % [who, key])
	var entities: Array[EntityData] = []
	for night: NightData in catalog.nights():
		if night.new_entities.has(null):
			errors.append("Noche %d: hay un espacio vacío en 'new_entities'" % night.number)
			continue
		for entity: EntityData in night.new_entities:
			if entities.has(entity):
				errors.append("Entidad '%s': aparece como nueva en más de una noche" % entity.id)
			else:
				entities.append(entity)
	_check_tutorial(errors, catalog)
	_check_unique_ids(errors, who, "entidades", entities)
	for entity: EntityData in entities:
		errors.append_array(validate_entity(entity))
	_check_shared_traits(errors, entities)
	_check_decoys(errors, catalog, entities)
	_check_incidents(errors, catalog)
	_check_phone_posts(errors, "Publicación", catalog.phone_posts)
	_check_phone_posts(errors, "Publicación perturbadora", catalog.phone_disturbing_posts)
	return errors


## Una dificultad: 5 noches en orden desde la 1, empieza en la noche 0 o en la 1, se desbloquea con una dificultad del
## catálogo, y sus noches traen las mismas entidades nuevas que las de la dificultad de por defecto (el cuaderno es uno
## solo). Revisa también el chat guionado de cada noche.
static func _check_difficulty(errors: Array[String], catalog: ContentCatalog, difficulty: DifficultyData) -> void:
	var who := "Dificultad '%s'" % difficulty.id
	if difficulty.nights.has(null):
		errors.append("%s: hay un espacio vacío en 'nights'" % who)
		return
	_check_count(errors, who, "noches", difficulty.nights.size(), NIGHT_COUNT)
	if difficulty.first_night < 0 or difficulty.first_night > 1:
		errors.append("%s: debe empezar en la noche 0 o en la 1" % who)
	if difficulty.unlocked_by != null and not catalog.difficulties.has(difficulty.unlocked_by):
		errors.append("%s: se desbloquea con una dificultad que no está en el catálogo" % who)
	var reference := catalog.default_difficulty()
	for index in difficulty.nights.size():
		var night: NightData = difficulty.nights[index]
		if night.number != index + 1:
			errors.append("%s: la noche en la posición %d tiene el número %d; deben ir en orden desde 1"
					% [who, index + 1, night.number])
		_check_scripted_chat(errors, catalog, night)
		_check_wave_plan(errors, "%s, noche %d" % [who, night.number], night)
		_check_story(errors, catalog, "%s, noche %d, historia" % [who, night.number], night.story)
		if difficulty != reference and index < reference.nights.size() \
				and night.new_entities != reference.nights[index].new_entities:
			errors.append("%s: la noche %d no trae las mismas entidades nuevas que en '%s'"
					% [who, index + 1, reference.id])


## El plan de olas de una noche, si tiene: sin espacios vacíos, cada ola con al menos una consulta, y sus videos suman la
## cuota (son los envíos programados).
static func _check_wave_plan(errors: Array[String], who: String, night: NightData) -> void:
	if not night.has_wave_plan():
		return
	if night.wave_plan.has(null):
		errors.append("%s: hay un espacio vacío en el plan de olas" % who)
		return
	for index in night.wave_plan.size():
		if night.wave_plan[index].requests < 1:
			errors.append("%s: la ola %d del plan no tiene consultas" % [who, index + 1])
	if night.total_videos() != night.content_quota:
		errors.append("%s: los videos del plan de olas suman %d y la cuota es %d"
				% [who, night.total_videos(), night.content_quota])


## La historia de una noche, si tiene (Plan 9.7): sin espacios vacíos, con los momentos en orden, y cada paso bien armado.
static func _check_story(errors: Array[String], catalog: ContentCatalog, who: String, story: StoryData) -> void:
	if story == null:
		return
	if story.beats.has(null):
		errors.append("%s: hay un espacio vacío en 'beats'" % who)
		return
	for index in story.beats.size():
		var beat := story.beats[index]
		var where := "%s, momento %d" % [who, index + 1]
		if index > 0 and beat.moment < story.beats[index - 1].moment:
			errors.append("%s: el momento %d llega antes que el %d; deben ir en orden" % [who, index + 1, index])
		if beat.steps.has(null):
			errors.append("%s: hay un espacio vacío en 'steps'" % where)
			continue
		for step_index in beat.steps.size():
			_check_story_step(errors, catalog, "%s, paso %d" % [where, step_index + 1], beat.steps[step_index])


## Un paso de la historia: una línea la dice un amigo del catálogo, y una decisión tiene quien la pregunte, al menos una
## opción buena, lo que responde Matías en cada opción y lo que pasa sin respuesta.
static func _check_story_step(errors: Array[String], catalog: ContentCatalog, who: String, step: StoryStepData) -> void:
	match step.kind:
		StoryStepData.Kind.LINE:
			if not catalog.friends.has(step.speaker):
				errors.append(who + ": quien habla no es un amigo del catálogo")
		StoryStepData.Kind.DECISION:
			var decision := step.decision
			if decision == null:
				errors.append(who + ": es una decisión sin datos")
				return
			if not catalog.friends.has(decision.friend):
				errors.append(who + ": quien decide no es un amigo del catálogo")
			if decision.options.has(null):
				errors.append(who + ": hay un espacio vacío en 'options'")
				return
			if not decision.options.any(func(option: StoryOptionData) -> bool: return option.good):
				errors.append(who + ": la decisión no tiene ninguna opción buena")
			for index in decision.options.size():
				var option := decision.options[index]
				var where := "%s, opción %d" % [who, index + 1]
				if option.label_key.is_empty():
					errors.append(where + ": falta lo que responde Matías")
				_check_story_option(errors, catalog, where, option)
			if decision.no_answer == null:
				errors.append(who + ": falta lo que pasa sin respuesta")
			else:
				_check_story_option(errors, catalog, who + ", sin respuesta", decision.no_answer)


## Los castigados y los candidatos al daño de una opción son amigos del catálogo.
static func _check_story_option(errors: Array[String], catalog: ContentCatalog, who: String,
		option: StoryOptionData) -> void:
	for friend: FriendData in option.penalized:
		if not catalog.friends.has(friend):
			errors.append(who + ": castiga a alguien que no es un amigo del catálogo")
	for friend: FriendData in option.damage_candidates:
		if not catalog.friends.has(friend):
			errors.append(who + ": hiere a alguien que no es un amigo del catálogo")


## Todas las noches de todas las dificultades, sin el tutorial.
static func _all_nights(catalog: ContentCatalog) -> Array[NightData]:
	var all: Array[NightData] = []
	for difficulty: DifficultyData in catalog.difficulties:
		all.append_array(difficulty.nights)
	return all


## Cada publicación del celular tiene su foto: Godot no tiene con qué reemplazarla.
static func _check_phone_posts(errors: Array[String], who: String, posts: Array[PhonePostData]) -> void:
	for index in posts.size():
		if posts[index] == null:
			errors.append("%s %d del celular: está vacía" % [who, index + 1])
		elif posts[index].picture == null:
			errors.append("%s %d del celular: no tiene foto" % [who, index + 1])


## Los accidentes: ids únicos, una buena idea y 1 o 2 malas. Una noche que pide accidentes necesita que existan.
static func _check_incidents(errors: Array[String], catalog: ContentCatalog) -> void:
	if catalog.incidents.has(null):
		errors.append("Catálogo: hay un espacio vacío en 'incidents'")
		return
	_check_unique_ids(errors, "Catálogo", "accidentes", catalog.incidents)
	for incident: IncidentData in catalog.incidents:
		if incident.wrong_keys.size() < 1 or incident.wrong_keys.size() > 2:
			errors.append("Accidente '%s': necesita 1 o 2 malas ideas" % incident.id)
	if not catalog.incidents.is_empty():
		return
	for night: NightData in _all_nights(catalog):
		if night.incident_count > 0:
			errors.append("Catálogo: la noche %d pide accidentes y el catálogo no tiene" % night.number)


## Revisa que cada clave de texto exista y que cada característica tenga una sola frase entre asteriscos.
## `translate` recibe una clave y devuelve su texto, o la misma clave si no existe
## (como TranslationServer.translate). Supone un catálogo sin errores en validate_catalog().
static func validate_texts(catalog: ContentCatalog, translate: Callable) -> Array[String]:
	var errors: Array[String] = []
	for entry: Array in _text_keys(catalog):
		var where: String = entry[0]
		var key: String = entry[1]
		if key.is_empty():
			errors.append("%s: falta la clave de texto" % where)
		elif String(translate.call(key)) == key:
			errors.append("%s: la clave '%s' no está en ningún CSV" % [where, key])
	for entity: EntityData in _entities_with_tutorial(catalog):
		for trait_data: TraitData in entity.traits:
			_check_highlight(errors, "Característica '%s'" % trait_data.id, trait_data.text_key, translate)
			for variant_key: String in trait_data.variant_keys:
				_check_highlight(errors, "Característica '%s', forma '%s'" % [trait_data.id, variant_key], variant_key,
						translate)
	for decoy: DecoyData in catalog.decoys + _tutorial_decoys(catalog):
		_check_highlight(errors, "Señuelo '%s'" % decoy.id, decoy.text_key, translate)
	return errors


## Las entidades de las noches 1 a 5 y las páginas propias de la noche 0.
static func _entities_with_tutorial(catalog: ContentCatalog) -> Array[EntityData]:
	var entities := catalog.all_entities()
	if catalog.tutorial != null:
		for entity: EntityData in catalog.tutorial.new_entities:
			if entity != null and not entities.has(entity):
				entities.append(entity)
	return entities


## Los señuelos fijos de las solicitudes de la noche 0.
static func _tutorial_decoys(catalog: ContentCatalog) -> Array[DecoyData]:
	var decoys: Array[DecoyData] = []
	if catalog.tutorial == null:
		return decoys
	for data: TutorialRequestData in catalog.tutorial.tutorial_requests:
		if data != null:
			decoys.append_array(data.decoys)
	return decoys


## Una característica o un señuelo necesita exactamente una frase clickeable entre asteriscos.
static func _check_highlight(errors: Array[String], who: String, key: String, translate: Callable) -> void:
	var text := String(translate.call(key))
	if text != key and text.count(HIGHLIGHT_MARK) != 2:
		errors.append("%s: su texto debe tener una sola frase entre asteriscos, como 'un *hombrecito*'" % who)


## Pares [dónde, clave] con todas las claves de texto del contenido.
static func _text_keys(catalog: ContentCatalog) -> Array[Array]:
	var keys: Array[Array] = []
	for friend: FriendData in catalog.friends:
		keys.append(["Amigo '%s'" % friend.id, friend.name_key])
	for difficulty: DifficultyData in catalog.difficulties:
		keys.append(["Dificultad '%s', nombre" % difficulty.id, difficulty.name_key])
		keys.append(["Dificultad '%s', descripción" % difficulty.id, difficulty.description_key])
	var nights := _all_nights(catalog)
	if catalog.tutorial != null:
		nights.append(catalog.tutorial)
	for night: NightData in nights:
		keys.append(["Noche %d" % night.number, night.place_key])
		if night.scripted_chat != null:
			for index in night.scripted_chat.lines.size():
				var line := night.scripted_chat.lines[index]
				if line != null:
					keys.append(["Noche %d, chat guionado, línea %d" % [night.number, index + 1], line.text_key])
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			if night != null:
				_story_keys(keys, "Dificultad '%s', noche %d, historia" % [difficulty.id, night.number], night.story)
	for entity: EntityData in _entities_with_tutorial(catalog):
		var who := "Entidad '%s'" % entity.id
		keys.append([who + ", nombre", entity.name_key])
		keys.append([who + ", folclore", entity.lore_key])
		for place_key: String in entity.place_keys:
			keys.append([who + ", lugar", place_key])
		for trait_data: TraitData in entity.traits:
			var trait_who := "%s, característica '%s'" % [who, trait_data.id]
			keys.append([trait_who, trait_data.text_key])
			keys.append([trait_who + ", nombre", trait_data.label_key])
			for variant_key: String in trait_data.variant_keys:
				keys.append([trait_who + ", otra forma", variant_key])
		for action: ActionData in entity.actions:
			keys.append(["%s, acción '%s'" % [who, action.id], action.label_key])
		for observation: ObservationData in entity.observations:
			keys.append(["%s, observación '%s'" % [who, observation.id], observation.question_key])
			for value: StringName in observation.values:
				keys.append(["%s, observación '%s' = '%s'" % [who, observation.id, value], observation.values[value]])
		for index in entity.rules.size():
			keys.append(["%s, regla %d" % [who, index + 1], entity.rules[index].text_key])
	for decoy: DecoyData in catalog.decoys + _tutorial_decoys(catalog):
		keys.append(["Señuelo '%s'" % decoy.id, decoy.text_key])
	for index in catalog.greeting_keys.size():
		keys.append(["Saludo %d" % (index + 1), catalog.greeting_keys[index]])
	for index in catalog.predicament_keys.size():
		keys.append(["Lo que le pasa %d" % (index + 1), catalog.predicament_keys[index]])
	for incident: IncidentData in catalog.incidents:
		var where := "Accidente '%s'" % incident.id
		keys.append([where + ", mensaje", incident.message_key])
		keys.append([where + ", buena idea", incident.correct_key])
		for wrong_key: String in incident.wrong_keys:
			keys.append([where + ", mala idea", wrong_key])
	return keys


## Las claves de texto de una historia: sus líneas, sus preguntas, lo que responde Matías y lo que contesta el amigo.
static func _story_keys(keys: Array[Array], who: String, story: StoryData) -> void:
	if story == null or story.beats.has(null):
		return
	for index in story.beats.size():
		var steps := story.beats[index].steps
		for step_index in steps.size():
			var step := steps[step_index]
			var where := "%s, momento %d, paso %d" % [who, index + 1, step_index + 1]
			if step == null:
				continue
			if step.kind == StoryStepData.Kind.LINE:
				keys.append([where, step.text_key])
			elif step.kind == StoryStepData.Kind.DECISION and step.decision != null:
				keys.append([where + ", la pregunta", step.decision.message_key])
				for option_index in step.decision.options.size():
					var option := step.decision.options[option_index]
					if option != null:
						keys.append(["%s, opción %d" % [where, option_index + 1], option.label_key])
						_reply_keys(keys, "%s, opción %d" % [where, option_index + 1], option)
				if step.decision.no_answer != null:
					_reply_keys(keys, where + ", sin respuesta", step.decision.no_answer)


static func _reply_keys(keys: Array[Array], who: String, option: StoryOptionData) -> void:
	for index in option.reply_keys.size():
		keys.append(["%s, respuesta %d" % [who, index + 1], option.reply_keys[index]])


## La noche 0, si el catálogo la tiene: su número es 0, y cada solicitud es de un amigo del catálogo, con una
## entidad de sus páginas y una situación que existe.
static func _check_tutorial(errors: Array[String], catalog: ContentCatalog) -> void:
	var tutorial := catalog.tutorial
	if tutorial == null:
		return
	if tutorial.number != 0:
		errors.append("Tutorial: su número debe ser 0")
	_check_scripted_chat(errors, catalog, tutorial)
	if tutorial.tutorial_requests.has(null):
		errors.append("Tutorial: hay un espacio vacío en 'tutorial_requests'")
		return
	for entity: EntityData in tutorial.new_entities:
		if entity == null:
			errors.append("Tutorial: hay un espacio vacío en 'new_entities'")
		else:
			errors.append_array(validate_entity(entity))
	var known := catalog.known_entities(0)
	for index in tutorial.tutorial_requests.size():
		var data := tutorial.tutorial_requests[index]
		var where := "Tutorial, solicitud %d" % (index + 1)
		if not catalog.friends.has(data.friend):
			errors.append(where + ": el amigo no es del catálogo")
		if data.entity == null or not known.has(data.entity):
			var entity_id: StringName = data.entity.id if data.entity != null else &""
			errors.append("%s: la entidad '%s' no está en las páginas de la noche 0" % [where, entity_id])
			continue
		for observation_id: StringName in data.situation:
			var observation := data.entity.find_observation(observation_id)
			var value: StringName = data.situation[observation_id]
			if observation == null:
				errors.append("%s: la observación '%s' no existe" % [where, observation_id])
			elif not observation.has_value(value):
				errors.append("%s: '%s' no es un valor de '%s'" % [where, value, observation_id])


## El chat guionado de una noche, si tiene: de un amigo del catálogo y con líneas.
static func _check_scripted_chat(errors: Array[String], catalog: ContentCatalog, night: NightData) -> void:
	var chat := night.scripted_chat
	if chat == null:
		return
	var who := "Noche %d: el chat guionado" % night.number
	if not catalog.friends.has(chat.friend):
		errors.append(who + " no es de un amigo del catálogo")
	if chat.lines.is_empty():
		errors.append(who + " no tiene líneas")
	elif chat.lines.has(null):
		errors.append(who + " tiene un espacio vacío en 'lines'")


static func _check_count(errors: Array[String], who: String, what: String, count: int, limits: Vector2i) -> void:
	if count >= limits.x and count <= limits.y:
		return
	var expected := str(limits.x) if limits.x == limits.y else "entre %d y %d" % [limits.x, limits.y]
	errors.append("%s: tiene %d %s y deben ser %s" % [who, count, what, expected])


static func _check_unique_ids(errors: Array[String], who: String, what: String, items: Array) -> void:
	var seen := {}
	for item: Resource in items:
		var item_id: StringName = item.get("id")
		if item_id.is_empty():
			errors.append("%s: hay %s sin id" % [who, what])
		elif seen.has(item_id):
			errors.append("%s: el id '%s' está repetido en %s" % [who, item_id, what])
		seen[item_id] = true


## Una característica tiene su nombre en el cuaderno y entre 2 y 4 formas más de decirse.
static func _check_variants(errors: Array[String], who: String, trait_data: TraitData) -> void:
	var where := "%s, característica '%s'" % [who, trait_data.id]
	if trait_data.label_key.is_empty():
		errors.append("%s: le falta su nombre en el cuaderno (label_key)" % where)
	var count := trait_data.variant_keys.size()
	if count < VARIANT_COUNT.x or count > VARIANT_COUNT.y:
		errors.append("%s: tiene %d formas más de decirse y deben ser entre %d y %d"
				% [where, count, VARIANT_COUNT.x, VARIANT_COUNT.y])


## Una observación con audios los tiene en "¿Qué oyes?" y tiene uno por cada valor, ni más ni menos.
static func _check_audio(errors: Array[String], who: String, observation: ObservationData) -> void:
	if observation.audio_values.is_empty():
		return
	var where := "%s, observación '%s'" % [who, observation.id]
	if observation.category != ClueCategory.Kind.SOUND:
		errors.append("%s: los audios van en '¿Qué oyes?'" % where)
	for value: StringName in observation.values:
		if observation.audio_for(value) == null:
			errors.append("%s: le falta el audio de '%s'" % [where, value])
	for value: StringName in observation.audio_values:
		if not observation.has_value(value):
			errors.append("%s: el audio '%s' no es de ningún valor" % [where, value])


static func _check_rule(errors: Array[String], who: String, entity: EntityData, index: int) -> void:
	var rule: RuleData = entity.rules[index]
	var where := "%s, regla %d" % [who, index + 1]
	var is_last := index == entity.rules.size() - 1
	if is_last and not rule.is_default():
		errors.append("%s: la última regla debe ser 'en cualquier otro caso' (sin condiciones)" % where)
	if not is_last and rule.is_default():
		errors.append("%s: solo la última regla puede no tener condiciones" % where)
	if rule.correct_action_id.is_empty() or rule.risky_action_id.is_empty():
		errors.append("%s: le falta la acción correcta o la de mayor riesgo" % where)
	elif rule.correct_action_id == rule.risky_action_id:
		errors.append("%s: la acción correcta y la de mayor riesgo son la misma" % where)
	else:
		for action_id: StringName in [rule.correct_action_id, rule.risky_action_id]:
			if entity.find_action(action_id) == null:
				errors.append("%s: la acción '%s' no existe" % [where, action_id])
	for observation_id: StringName in rule.conditions:
		var observation := entity.find_observation(observation_id)
		var value: StringName = rule.conditions[observation_id]
		if observation == null:
			errors.append("%s: la observación '%s' no existe" % [where, observation_id])
		elif not observation.has_value(value):
			errors.append("%s: '%s' no es un valor de '%s'" % [where, value, observation_id])


## Una regla tapada por las anteriores en todas las situaciones posibles es un error de diseño.
static func _check_reachable(errors: Array[String], who: String, entity: EntityData) -> void:
	var applied := {}
	for situation: Dictionary in RuleEvaluator.all_situations(entity):
		applied[RuleEvaluator.applicable_rule(entity, situation)] = true
	for index in entity.rules.size() - 1:
		if not applied.has(entity.rules[index]):
			errors.append("%s, regla %d: nunca se aplica, porque las reglas anteriores cubren todos sus casos"
					% [who, index + 1])


## Una misma característica (mismo id) debe ser igual en todas sus entidades, la usan 2 como máximo,
## y ninguna entidad puede tener todas sus características dentro de las de otra: el mensaje
## trae 2 características que la distinguen, y así no habría ningún par.
static func _check_shared_traits(errors: Array[String], entities: Array[EntityData]) -> void:
	var first_seen := {}  # id de característica → TraitData de la primera entidad que la usa
	var users := {}  # id de característica → ids de las entidades que la usan
	var trait_ids: Array[PackedStringArray] = []  # ids de las características de cada entidad
	for entity: EntityData in entities:
		var ids := PackedStringArray()
		for trait_data: TraitData in entity.traits:
			if trait_data == null:
				continue
			ids.append(trait_data.id)
			if not users.has(trait_data.id):
				users[trait_data.id] = []
				first_seen[trait_data.id] = trait_data
			users[trait_data.id].append(entity.id)
			var first: TraitData = first_seen[trait_data.id]
			if first.category != trait_data.category or first.text_key != trait_data.text_key:
				errors.append("Característica '%s': tiene otra categoría o texto en '%s'" % [trait_data.id, entity.id])
			elif first.label_key != trait_data.label_key or first.variant_keys != trait_data.variant_keys:
				errors.append("Característica '%s': tiene otro nombre o se dice distinto en '%s'" % [trait_data.id, entity.id])
		trait_ids.append(ids)
	for trait_id: StringName in users:
		if users[trait_id].size() > MAX_ENTITIES_PER_TRAIT:
			errors.append("Característica '%s': la usan %d entidades; el máximo es %d"
					% [trait_id, users[trait_id].size(), MAX_ENTITIES_PER_TRAIT])
	for i in entities.size():
		for j in range(i + 1, entities.size()):
			var first_in_second := _contains_all(trait_ids[j], trait_ids[i])
			var second_in_first := _contains_all(trait_ids[i], trait_ids[j])
			if first_in_second and second_in_first:
				errors.append("Entidades '%s' y '%s': tienen las mismas características; no se pueden distinguir"
						% [entities[i].id, entities[j].id])
			elif first_in_second:
				_append_contained(errors, entities[i], entities[j])
			elif second_in_first:
				_append_contained(errors, entities[j], entities[i])


static func _contains_all(container: PackedStringArray, items: PackedStringArray) -> bool:
	for item: String in items:
		if not container.has(item):
			return false
	return true


static func _append_contained(errors: Array[String], contained: EntityData, container: EntityData) -> void:
	errors.append("Entidad '%s': todas sus características las tiene también '%s'; ningún mensaje podría distinguirla"
			% [contained.id, container.id])


## Los señuelos tienen ids únicos y distintos de los de las características, sus lugares existen,
## y en cada noche cada lugar tiene los señuelos que la noche pide.
static func _check_decoys(errors: Array[String], catalog: ContentCatalog, entities: Array[EntityData]) -> void:
	if catalog.decoys.has(null):
		errors.append("Catálogo: hay un espacio vacío en 'decoys'")
		return
	_check_unique_ids(errors, "Catálogo", "señuelos", catalog.decoys)
	var trait_ids := {}
	var places := {}
	for entity: EntityData in entities:
		for trait_data: TraitData in entity.traits:
			if trait_data != null:
				trait_ids[trait_data.id] = true
		for place_key: String in entity.place_keys:
			places[place_key] = true
	for decoy: DecoyData in catalog.decoys:
		if trait_ids.has(decoy.id):
			errors.append("Señuelo '%s': usa el id de una característica; debe ser distinto" % decoy.id)
		for place_key: String in decoy.place_keys:
			if not places.has(place_key):
				errors.append("Señuelo '%s': el lugar '%s' no es de ninguna entidad" % [decoy.id, place_key])
	for difficulty: DifficultyData in catalog.difficulties:
		var known_places := {}  # lugares de las entidades conocidas hasta la noche que se revisa
		for night: NightData in difficulty.nights:
			for entity: EntityData in night.new_entities:
				if entity != null:
					for place_key: String in entity.place_keys:
						known_places[place_key] = true
			for place_key: String in known_places:
				var count := catalog.decoys_for_place(place_key).size()
				if count < night.decoys_per_request:
					errors.append("Dificultad '%s', noche %d: el lugar '%s' tiene %d señuelos y la noche pide %d"
							% [difficulty.id, night.number, place_key, count, night.decoys_per_request])
