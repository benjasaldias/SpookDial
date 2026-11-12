extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_catalogo_valido() -> bool:
	var errors := ContentValidator.validate_catalog(Fixtures.make_catalog())
	check(errors.is_empty(), str(errors))
	return true


func test_amigos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.friends[2].id = &"leon"
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "el id 'leon' está repetido en amigos")
	catalog.friends.pop_back()
	errors = ContentValidator.validate_catalog(catalog)
	check_contains(errors, "tiene 2 amigos y deben ser 3")
	return true


func test_noches_en_orden() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[1].number = 3
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "la noche en la posición 2 tiene el número 3")
	return true


## Normal y Difícil (docs/26 §3.1).
func test_sin_dificultades() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.difficulties.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "no tiene dificultades")
	catalog = Fixtures.make_catalog()
	Fixtures.add_hard(catalog).id = &"normal"
	check_contains(ContentValidator.validate_catalog(catalog), "el id 'normal' está repetido en dificultades")
	return true


func test_una_dificultad_con_4_noches() -> bool:
	var catalog := Fixtures.make_catalog()
	Fixtures.add_hard(catalog).nights.pop_back()
	check_contains(ContentValidator.validate_catalog(catalog), "Dificultad 'hard': tiene 4 noches y deben ser 5")
	return true


func test_la_noche_de_inicio() -> bool:
	var catalog := Fixtures.make_catalog()
	check(ContentValidator.validate_catalog(catalog).is_empty(), "Normal empieza en la noche 0")
	Fixtures.add_hard(catalog).first_night = 2
	check_contains(ContentValidator.validate_catalog(catalog), "Dificultad 'hard': debe empezar en la noche 0 o en la 1")
	return true


## Las entidades llegan en las mismas noches en todas las dificultades: el cuaderno es uno solo.
func test_las_entidades_llegan_en_las_mismas_noches() -> bool:
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	check(ContentValidator.validate_catalog(catalog).is_empty(), str(ContentValidator.validate_catalog(catalog)))
	var ghost: EntityData = hard.nights[1].new_entities[0]
	hard.nights[1].new_entities.clear()
	hard.nights[2].new_entities.append(ghost)
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "Dificultad 'hard': la noche 2 no trae las mismas entidades nuevas que en 'normal'")
	check_contains(errors, "Dificultad 'hard': la noche 3 no trae las mismas entidades nuevas que en 'normal'")
	return true


func test_desbloqueada_por_una_dificultad_de_afuera() -> bool:
	var catalog := Fixtures.make_catalog()
	Fixtures.add_hard(catalog).unlocked_by = DifficultyData.new()
	check_contains(ContentValidator.validate_catalog(catalog),
			"Dificultad 'hard': se desbloquea con una dificultad que no está en el catálogo")
	return true


func test_entidad_repetida() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[2].new_entities.append(catalog.nights()[0].new_entities[0])
	check_contains(ContentValidator.validate_catalog(catalog), "aparece como nueva en más de una noche")
	catalog = Fixtures.make_catalog()
	catalog.nights()[2].new_entities.append(Fixtures.make_entity(&"beast"))
	check_contains(ContentValidator.validate_catalog(catalog), "el id 'beast' está repetido en entidades")
	return true


func test_caracteristica_compartida_por_tres() -> bool:
	var catalog := Fixtures.make_catalog()
	var wraith := Fixtures.make_entity(&"wraith")
	catalog.nights()[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1")
	wraith.traits[0] = Fixtures.make_trait(&"beast_trait_1")
	catalog.nights()[2].new_entities.append(wraith)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': la usan 3 entidades")
	return true


func test_caracteristica_compartida_con_otra_categoria() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1", ClueCategory.Kind.SOUND)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': tiene otra categoría o texto en 'ghost'")
	return true


func test_mismas_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	var ghost: EntityData = catalog.nights()[1].new_entities[0]
	ghost.traits[0] = Fixtures.make_trait(&"beast_trait_2")
	ghost.traits[1] = Fixtures.make_trait(&"beast_trait_1")
	check_contains(ContentValidator.validate_catalog(catalog), "'beast' y 'ghost': tienen las mismas características")
	return true


func test_incluye_los_errores_de_cada_entidad() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[1].new_entities[0].actions.pop_back()
	check_contains(ContentValidator.validate_catalog(catalog), "Entidad 'ghost': tiene 3 acciones")
	return true


func test_chat_guionado() -> bool:
	var catalog := Fixtures.make_catalog()
	var chat := ChatScriptData.new()
	chat.friend = FriendData.new()
	catalog.nights()[0].scripted_chat = chat
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "Noche 1: el chat guionado no es de un amigo del catálogo")
	check_contains(errors, "Noche 1: el chat guionado no tiene líneas")
	return true


func test_sin_saludos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.greeting_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Catálogo: no tiene saludos para el mensaje inicial")
	return true


func test_sin_frases_de_lo_que_le_pasa() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.predicament_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Catálogo: no tiene frases de lo que le pasa al amigo")
	return true


func test_tutorial() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial.number = 1
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: su número debe ser 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].friend = FriendData.new()
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: el amigo no es del catálogo")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].entity = catalog.nights()[1].new_entities[0]
	check_contains(ContentValidator.validate_catalog(catalog),
			"Tutorial, solicitud 1: la entidad 'ghost' no está en las páginas de la noche 0")
	# Con páginas propias, la noche 0 solo conoce esas (la de Gonzalo, decisión de Benja, 11 de noviembre).
	catalog = Fixtures.make_catalog()
	catalog.tutorial.new_entities.append(Fixtures.make_entity(&"page"))
	check_contains(ContentValidator.validate_catalog(catalog),
			"Tutorial, solicitud 1: la entidad 'beast' no está en las páginas de la noche 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o1"] = &"maybe"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: 'maybe' no es un valor de 'o1'")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o9"] = &"yes"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: la observación 'o9' no existe")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: hay un espacio vacío en 'tutorial_requests'")
	return true


func test_sin_tutorial_tambien_es_valido() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial = null
	check(ContentValidator.validate_catalog(catalog).is_empty(), "el tutorial es opcional para el validador")
	return true


func test_los_accidentes() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights()[0].incident_count = 1
	check_contains(ContentValidator.validate_catalog(catalog), "la noche 1 pide accidentes y el catálogo no tiene")
	catalog.incidents.append(Fixtures.make_incident())
	check(ContentValidator.validate_catalog(catalog).is_empty(), "con uno, está bien")
	catalog.incidents[0].wrong_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Accidente 'trip': necesita 1 o 2 malas ideas")
	catalog.incidents.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "hay un espacio vacío en 'incidents'")
	return true


func test_publicaciones_del_celular_sin_foto() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.phone_posts.append(PhonePostData.new())
	check_contains(ContentValidator.validate_catalog(catalog), "Publicación 1 del celular: no tiene foto")
	catalog.phone_posts.clear()
	catalog.phone_disturbing_posts.append(PhonePostData.new())
	check_contains(ContentValidator.validate_catalog(catalog), "Publicación perturbadora 1 del celular: no tiene foto")
	catalog.phone_disturbing_posts[0] = null
	check_contains(ContentValidator.validate_catalog(catalog), "Publicación perturbadora 1 del celular: está vacía")
	return true


## Una característica compartida se dice igual en sus 2 entidades: mismo nombre y mismas formas.
func test_las_compartidas_tienen_las_mismas_variantes() -> bool:
	var catalog := Fixtures.make_catalog()
	var shared := Fixtures.make_trait(&"beast_trait_1")
	shared.variant_keys.assign(["K_OTHER_2", "K_OTHER_3"])
	catalog.nights()[1].new_entities[0].traits[0] = shared
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': tiene otro nombre o se dice distinto en 'ghost'")
	return true


## El plan de olas de una noche (docs/26 §3.2): sus videos son los de la cuota, y cada ola trae al menos una consulta.
func test_los_videos_del_plan_suman_la_cuota() -> bool:
	var catalog := Fixtures.make_catalog()
	var night := catalog.nights()[0]
	night.content_quota = 2
	var wave := WaveData.new()
	wave.videos = 1
	night.wave_plan.append(wave)
	check_contains(ContentValidator.validate_catalog(catalog),
			"Dificultad 'normal', noche 1: los videos del plan de olas suman 1 y la cuota es 2")
	wave.videos = 2
	check(ContentValidator.validate_catalog(catalog).is_empty(), str(ContentValidator.validate_catalog(catalog)))
	return true


func test_una_ola_sin_consultas() -> bool:
	var catalog := Fixtures.make_catalog()
	var night := catalog.nights()[0]
	night.content_quota = 0
	var empty := WaveData.new()
	empty.requests = 0
	night.wave_plan.assign([WaveData.new(), empty])
	check_contains(ContentValidator.validate_catalog(catalog), "Dificultad 'normal', noche 1: la ola 2 del plan no tiene consultas")
	night.wave_plan.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Dificultad 'normal', noche 1: hay un espacio vacío en el plan de olas")
	return true
