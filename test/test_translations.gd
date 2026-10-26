extends "res://test/test_case.gd"

const FILES := ["messages", "notebook", "ui"]
## Godot no genera el .translation de un idioma cuya columna está entera vacía. Mientras la
## columna "en" esté vacía, solo se registra el español; el inglés se agrega con la opción de idioma (Plan 8).
const LOCALES := ["es"]


func test_las_traducciones_estan_registradas() -> bool:
	var registered: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	for file_name: String in FILES:
		for locale: String in LOCALES:
			var path := "res://data/text/%s.%s.translation" % [file_name, locale]
			check(registered.has(path), "registrada: " + path)
			check(ResourceLoader.exists(path), "importada: " + path)
	check_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "es", "idioma de respaldo")
	return true


func test_traduce_al_espanol() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check_eq(String(TranslationServer.translate("FRIEND_LEON_NAME")), "León", "nombre de León")
	TranslationServer.set_locale(previous)
	return true


func test_sin_texto_en_ingles_se_muestra_el_espanol() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	check_eq(String(TranslationServer.translate("NIGHT_3_PLACE")), "Bosque", "celda en vacía")
	TranslationServer.set_locale(previous)
	return true
