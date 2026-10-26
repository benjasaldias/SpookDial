extends "res://test/test_case.gd"
## Revisa el contenido real del juego. Si falla después de editar un .tres o un CSV,
## el mensaje dice qué hay que arreglar.

const ContentValidator := preload("res://scripts/core/content_validator.gd")
const CATALOG_PATH := "res://data/catalog.tres"
const ENTITIES_DIR := "res://data/entities"


## Si el catálogo no carga, las pruebas fallan aquí en vez de pasar sin revisar nada.
func _load_catalog() -> ContentCatalog:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	check(catalog != null, "no se pudo cargar " + CATALOG_PATH)
	return catalog


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


func test_el_trauco_aparece_la_noche_3() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var trauco: EntityData = load("res://data/entities/trauco.tres")
	check(not catalog.known_entities(2).has(trauco), "no aparece antes de la noche 3")
	check(catalog.known_entities(3).has(trauco), "aparece la noche 3")
	return true
