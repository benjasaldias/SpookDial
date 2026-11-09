extends "res://test/test_case.gd"
## Revisa el contenido real del juego. Si falla después de editar un .tres o un CSV,
## el mensaje dice qué hay que arreglar.

const ContentValidator := preload("res://scripts/core/content_validator.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
const CATALOG_PATH := "res://data/catalog.tres"
const ENTITIES_DIR := "res://data/entities"


## Si el catálogo no carga, las pruebas fallan aquí en vez de pasar sin revisar nada.
func _load_catalog() -> ContentCatalog:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	check(catalog != null, "no se pudo cargar " + CATALOG_PATH)
	return catalog


## Los 3 amigos se distinguen de oído: cada uno tiene su sonido, su altura y su ritmo (decisión de Benja, 8 de
## noviembre).
func test_cada_amigo_tiene_su_voz() -> bool:
	var catalog := _load_catalog()
	var streams := {}
	var cadences := {}
	for friend: FriendData in catalog.friends:
		check(friend.voice is AudioStreamWAV, "%s tiene voz" % friend.id)
		streams[friend.voice] = true
		cadences[friend.voice_every] = true
	check_eq(streams.size(), catalog.friends.size(), "un sonido por amigo")
	check_eq(cadences.size(), catalog.friends.size(), "un ritmo por amigo")
	return true


func test_el_catalogo_es_valido() -> bool:
	var catalog := _load_catalog()
	if catalog == null:
		return true
	var errors := ContentValidator.validate_catalog(catalog)
	check(errors.is_empty(), "\n".join(PackedStringArray(errors)))
	return true


func test_todos_los_textos_existen() -> bool:
	var catalog := _load_catalog()
	if catalog == null:
		return true
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var errors := ContentValidator.validate_texts(catalog, Callable(TranslationServer, "translate"))
	TranslationServer.set_locale(previous)
	check(errors.is_empty(), "\n".join(PackedStringArray(errors)))
	return true


func test_cada_entidad_esta_en_una_noche() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var paths := catalog.all_entities().map(func(entity: EntityData) -> String: return entity.resource_path)
	for file_name: String in DirAccess.get_files_at(ENTITIES_DIR):
		if file_name.ends_with(".tres"):
			check(paths.has(ENTITIES_DIR.path_join(file_name)),
					"%s no está en las entidades nuevas de ninguna noche" % file_name)
	return true


## Las 7 entidades y la noche en que aparecen (diseño §13).
func test_las_7_entidades_y_su_noche() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var expected := [[&"tue_tue", &"calchona"], [&"cuero", &"viuda"], [&"trauco"], [&"basilisco", &"imbunche"], []]
	for index in catalog.nights.size():
		var ids := catalog.nights[index].new_entities.map(func(entity: EntityData) -> StringName: return entity.id)
		check_eq(ids, expected[index], "noche %d" % (index + 1))
	check_eq(catalog.all_entities().size(), 7, "7 entidades")
	return true


## Las características de cada entidad salen en 2 preguntas distintas o más: así, identificarla nunca cuesta
## una sola pregunta (decisión de Benja, 3-nov).
func test_las_caracteristicas_de_cada_entidad_salen_en_2_preguntas() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for entity: EntityData in catalog.all_entities():
		var categories := {}
		for trait_data: TraitData in entity.traits:
			categories[trait_data.category] = true
		check(categories.size() >= 2, "'%s' tiene todas sus características en una sola categoría" % entity.id)
	return true


## La noche 0, el tutorial (decisión de Benja): 3 solicitudes fijas, una de cada amigo, con El Tue Tué y La
## Calchona; un video, y el susto guionado con el chat de Gonzalo, que enseña el celular.
func test_el_tutorial() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var tutorial := catalog.tutorial
	check(tutorial != null, "existe")
	if tutorial == null:
		return true
	check_eq(tutorial.number, 0, "es la noche 0")
	check_eq(tutorial.tutorial_requests.size(), 3, "3 solicitudes")
	var friends := tutorial.tutorial_requests.map(func(data: TutorialRequestData) -> StringName: return data.friend.id)
	check_eq(friends, [&"leon", &"agustin", &"gonzalo"], "una de cada amigo")
	var videos := tutorial.tutorial_requests.filter(func(data: TutorialRequestData) -> bool: return data.sends_video)
	check_eq(videos.size(), 1, "un video")
	check_eq(tutorial.content_quota, 1, "su cuota")
	check(tutorial.scripted_scare_time > 0.0, "el susto guionado")
	check(tutorial.scripted_chat != null and tutorial.scripted_chat.highlight_phone, "su chat enseña el celular")
	check_eq(catalog.known_entities(0), catalog.known_entities(1), "las páginas de la noche 1")
	return true


func test_el_celular_tiene_publicaciones() -> bool:
	var catalog := _load_catalog()
	if catalog == null:
		return true
	check_eq(catalog.phone_posts.size(), 12, "unas 12 publicaciones (docs/06 §3)")
	for post: PhonePostData in catalog.phone_posts:
		check(not post.author_key.is_empty() and not post.text_key.is_empty(), "cada una con su autor y su texto")
	return true


func test_hay_accidentes() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	check(catalog.incidents.size() >= 5, "varios accidentes: %d" % catalog.incidents.size())
	return true


## Desde la noche 3 hay entidades que se confunden: comparten 2 características, y solo se distinguen por otra
## (decisión de Benja, 7 de noviembre).
func test_entidades_que_comparten_2_caracteristicas() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for pair: Array in [[&"trauco", &"calchona"], [&"imbunche", &"basilisco"]]:
		var first := _entity(catalog, pair[0])
		var second := _entity(catalog, pair[1])
		var shared := 0
		for trait_data: TraitData in first.traits:
			if second.traits.any(func(other: TraitData) -> bool: return other.id == trait_data.id):
				shared += 1
		check_eq(shared, 2, "%s y %s comparten 2" % pair)
		var known := catalog.all_entities()
		check(not RequestGenerator.distinguishing_pairs(first, known).is_empty(), "%s se puede distinguir" % pair[0])
		check(not RequestGenerator.distinguishing_pairs(second, known).is_empty(), "%s se puede distinguir" % pair[1])
	return true


func _entity(catalog: ContentCatalog, entity_id: StringName) -> EntityData:
	for entity: EntityData in catalog.all_entities():
		if entity.id == entity_id:
			return entity
	return null


## Cada entidad tiene una observación que el amigo manda como audio, y lo que se oye cambia la acción correcta: 1
## grito no es lo mismo que 3 (decisión de Benja, 7 de noviembre).
func test_cada_entidad_tiene_un_audio_que_cambia_la_accion() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for entity: EntityData in catalog.all_entities():
		var with_audio := entity.observations.filter(func(observation: ObservationData) -> bool:
			return not observation.audio_values.is_empty())
		check_eq(with_audio.size(), 1, "'%s' tiene una observación con audio" % entity.id)
		if with_audio.size() == 1:
			check(_audio_changes_the_action(entity, with_audio[0]), "en '%s', el audio no cambia nada" % entity.id)
	return true


## Hay dos situaciones que solo difieren en `observation` y que piden acciones distintas.
func _audio_changes_the_action(entity: EntityData, observation: ObservationData) -> bool:
	for situation: Dictionary in RuleEvaluator.all_situations(entity):
		var correct := RuleEvaluator.applicable_rule(entity, situation).correct_action_id
		for value: StringName in observation.value_ids():
			var other := situation.duplicate()
			other[observation.id] = value
			if RuleEvaluator.applicable_rule(entity, other).correct_action_id != correct:
				return true
	return false
