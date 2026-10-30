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


static func make_trait(trait_id: StringName, category := ClueCategory.Kind.SIGHT) -> TraitData:
	var trait_data := TraitData.new()
	trait_data.id = trait_id
	trait_data.category = category
	trait_data.text_key = "K_TRAIT_%s" % trait_id
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


## Catálogo válido: 3 amigos, 5 noches y 2 señuelos que sirven en cualquier lugar
## ("decoy_sight" y "decoy_sound"); "beast" aparece la noche 1 y "ghost" la noche 2.
static func make_catalog() -> ContentCatalog:
	var catalog := ContentCatalog.new()
	for friend_id: StringName in [&"leon", &"gonzalo", &"agustin"]:
		var friend := FriendData.new()
		friend.id = friend_id
		friend.name_key = "K_FRIEND_%s" % friend_id
		catalog.friends.append(friend)
	for number in range(1, 6):
		var night := NightData.new()
		night.number = number
		night.place_key = "K_NIGHT_%d" % number
		catalog.nights.append(night)
	catalog.nights[0].new_entities.append(make_entity(&"beast"))
	catalog.nights[1].new_entities.append(make_entity(&"ghost"))
	catalog.decoys.append(make_decoy(&"decoy_sight"))
	catalog.decoys.append(make_decoy(&"decoy_sound", ClueCategory.Kind.SOUND))
	return catalog
