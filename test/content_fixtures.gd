extends RefCounted
## Contenido mínimo y válido, armado en código, para probar el evaluador y el validador.
## No es contenido del juego.


## Entidad válida: 2 características, 4 acciones (a1 a a4), 2 observaciones (o1 y o2, con yes/no) y 3 reglas:
##   1. o1 = yes → correcta a1, mayor riesgo a2
##   2. o2 = yes → correcta a3, mayor riesgo a4
##   3. en cualquier otro caso → correcta a2, mayor riesgo a3
static func make_entity(entity_id: StringName = &"beast") -> EntityData:
	var entity := EntityData.new()
	entity.id = entity_id
	entity.name_key = "K_%s_NAME" % entity_id
	entity.lore_key = "K_%s_LORE" % entity_id
	entity.place_keys = ["K_PLACE"]
	for i in 2:
		entity.traits.append(make_trait(StringName("%s_trait_%d" % [entity_id, i + 1])))
	for i in 4:
		var action := ActionData.new()
		action.id = StringName("a%d" % (i + 1))
		action.label_key = "K_%s_A%d" % [entity_id, i + 1]
		entity.actions.append(action)
	for i in 2:
		var observation := ObservationData.new()
		observation.id = StringName("o%d" % (i + 1))
		observation.question_key = "K_%s_O%d_Q" % [entity_id, i + 1]
		observation.values = {
			&"yes": "K_%s_O%d_YES" % [entity_id, i + 1],
			&"no": "K_%s_O%d_NO" % [entity_id, i + 1],
		}
		entity.observations.append(observation)
	entity.rules.append(make_rule({&"o1": &"yes"}, &"a1", &"a2"))
	entity.rules.append(make_rule({&"o2": &"yes"}, &"a3", &"a4"))
	entity.rules.append(make_rule({}, &"a2", &"a3"))
	return entity


## Una característica con su nombre en el cuaderno ("K_LABEL_<id>") y 2 formas más de decirla
## ("K_TRAIT_<id>_2" y "K_TRAIT_<id>_3").
static func make_trait(trait_id: StringName, category := ClueCategory.Kind.SIGHT) -> TraitData:
	var trait_data := TraitData.new()
	trait_data.id = trait_id
	trait_data.category = category
	trait_data.text_key = "K_TRAIT_%s" % trait_id
	trait_data.label_key = "K_LABEL_%s" % trait_id
	trait_data.variant_keys.assign(["K_TRAIT_%s_2" % trait_id, "K_TRAIT_%s_3" % trait_id])
	return trait_data


static func make_rule(conditions: Dictionary, correct: StringName, risky: StringName) -> RuleData:
	var rule := RuleData.new()
	for observation_id: StringName in conditions:
		rule.conditions[observation_id] = conditions[observation_id]
	rule.correct_action_id = correct
	rule.risky_action_id = risky
	rule.text_key = "K_RULE"
	return rule


static func make_decoy(decoy_id: StringName, category := ClueCategory.Kind.SIGHT,
		place_keys: Array[String] = []) -> DecoyData:
	var decoy := DecoyData.new()
	decoy.id = decoy_id
	decoy.category = category
	decoy.text_key = "K_DECOY_%s" % decoy_id
	decoy.place_keys = place_keys
	return decoy


## Catálogo válido: 3 amigos, una dificultad (Normal, con sus 5 noches), 2 señuelos que sirven en cualquier lugar
## ("decoy_sight" y "decoy_sound"), un saludo ("K_CALL_1"), una frase de lo que le pasa ("K_LOST") y los valores de
## equilibrio por defecto; "beast" aparece la noche 1 y "ghost" la noche 2.
## La noche 0 (el tutorial) tiene 2 solicitudes de "beast": la de León (o1 = yes, con pista y con un video al
## terminar) y la de Gonzalo (o1 = no y o2 = yes, sin pista).
static func make_catalog() -> ContentCatalog:
	var catalog := ContentCatalog.new()
	catalog.balance = BalanceData.new()
	for friend_id: StringName in [&"leon", &"gonzalo", &"agustin"]:
		var friend := FriendData.new()
		friend.id = friend_id
		friend.name_key = "K_FRIEND_%s" % friend_id
		friend.voice = make_audio(0.05)
		catalog.friends.append(friend)
	var normal := DifficultyData.new()
	normal.id = &"normal"
	normal.name_key = "K_NORMAL"
	normal.description_key = "K_NORMAL_INFO"
	for number in range(1, 6):
		var night := NightData.new()
		night.number = number
		night.place_key = "K_NIGHT_%d" % number
		normal.nights.append(night)
	catalog.difficulties.append(normal)
	normal.nights[0].new_entities.append(make_entity(&"beast"))
	normal.nights[1].new_entities.append(make_entity(&"ghost"))
	catalog.decoys.append(make_decoy(&"decoy_sight"))
	catalog.decoys.append(make_decoy(&"decoy_sound", ClueCategory.Kind.SOUND))
	catalog.greeting_keys.assign(["K_CALL_1"])
	catalog.predicament_keys.assign(["K_LOST"])
	catalog.tutorial = make_tutorial(catalog)
	return catalog


## Agrega Difícil al catálogo de prueba: otras 5 noches, con las mismas entidades nuevas en cada una, que empiezan en
## la noche 1, se identifican leyendo y se desbloquean al terminar Normal.
static func add_hard(catalog: ContentCatalog) -> DifficultyData:
	var hard := DifficultyData.new()
	hard.id = &"hard"
	hard.name_key = "K_HARD"
	hard.description_key = "K_HARD_INFO"
	hard.first_night = 1
	hard.highlights = false
	hard.unlocked_by = catalog.difficulties[0]
	for normal_night: NightData in catalog.nights():
		var night := NightData.new()
		night.number = normal_night.number
		night.place_key = normal_night.place_key
		night.new_entities.assign(normal_night.new_entities)
		hard.nights.append(night)
	catalog.difficulties.append(hard)
	return hard


## La noche 0 del catálogo de prueba: una solicitud de "beast" para León (o1 = yes, sin pista), como la de León en el
## tutorial, con un video de cuota.
static func make_tutorial(catalog: ContentCatalog) -> NightData:
	var tutorial := NightData.new()
	tutorial.number = 0
	tutorial.place_key = "K_NIGHT_0"
	tutorial.content_quota = 1
	tutorial.audio_sync_beats = 4
	var beast: EntityData = catalog.nights()[0].new_entities[0]
	tutorial.tutorial_requests.append(make_tutorial_request(catalog.friends[0], beast, {&"o1": &"yes"}, false))
	return tutorial


static func make_tutorial_request(friend: FriendData, entity: EntityData, situation: Dictionary,
		with_hint: bool) -> TutorialRequestData:
	var data := TutorialRequestData.new()
	data.friend = friend
	data.entity = entity
	for observation_id: StringName in situation:
		data.situation[observation_id] = situation[observation_id]
	data.with_hint = with_hint
	return data


## Un audio de `seconds` segundos de silencio.
static func make_audio(seconds := 1.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data := PackedByteArray()
	data.resize(int(seconds * 44100) * 2)
	stream.data = data
	return stream


## Un accidente: "K_INCIDENT_<id>", una buena idea y 2 malas. No va en el catálogo de prueba: cada prueba lo agrega.
static func make_incident(incident_id: StringName = &"trip") -> IncidentData:
	var incident := IncidentData.new()
	incident.id = incident_id
	incident.message_key = "K_INCIDENT_%s" % incident_id
	incident.correct_key = "K_INCIDENT_%s_OK" % incident_id
	incident.wrong_keys.assign(["K_INCIDENT_%s_BAD_1" % incident_id, "K_INCIDENT_%s_BAD_2" % incident_id])
	return incident
