extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/notebook_panel.tscn")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")

var _memory: NotebookMemory
var _entities: Array[EntityData] = []


## Cuaderno con las 2 entidades conocidas en la noche 2 del catálogo de prueba ("beast" y "ghost")
## y la memoria de páginas de los 3 amigos.
func _make_panel() -> Control:
	var catalog := Fixtures.make_catalog()
	_entities = catalog.known_entities(2)
	_memory = NotebookMemory.new(catalog.friends.size())
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	panel.setup(_memory, _entities, catalog.friends)
	return panel


func _tabs(panel: Control) -> Array[Node]:
	return panel.get_node("Page/Layout/Index").get_children()


func _title(panel: Control) -> Label:
	return panel.get_node("Page/Layout/Scroll/Content/Title") as Label


func _body(panel: Control) -> RichTextLabel:
	return panel.get_node("Page/Layout/Scroll/Content/Body") as RichTextLabel


func test_empieza_oculto_y_en_el_indice() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for(1)
	check(panel.visible, "visible tras abrir")
	check_eq(panel.friend_index, 1, "amigo")
	check_eq(_tabs(panel).size(), 2, "una pestaña por entidad conocida")
	check(not _title(panel).visible, "sin página no hay título")
	check_eq(_body(panel).text, tr(panel.PICK_ENTITY_KEY), "pide elegir una entidad")
	panel.free()
	return true


func test_una_pestana_abre_su_pagina_para_ese_amigo() -> bool:
	var panel := _make_panel()
	panel.open_for(2)
	(_tabs(panel)[1] as Button).pressed.emit()
	check_eq(_memory.page_for(2), _entities[1], "Agustín tiene abierta la página de ghost")
	check_eq(_memory.page_for(0), null, "León sigue en el índice")
	check(_title(panel).visible, "título visible")
	check_eq(_title(panel).text, tr(_entities[1].name_key), "nombre de la entidad")
	check(_body(panel).text.contains(_entities[1].lore_key), "su página")
	check((_tabs(panel)[1] as Button).button_pressed, "su pestaña queda marcada")
	panel.free()
	return true


func test_al_cambiar_de_amigo_salta_a_su_pagina() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _entities[0])
	panel.open_for(1)
	check(not _title(panel).visible, "Gonzalo está en el índice")
	panel.select_friend(0)
	check_eq(_title(panel).text, tr(_entities[0].name_key), "León está en la página de beast")
	check((_tabs(panel)[0] as Button).button_pressed and not (_tabs(panel)[1] as Button).button_pressed,
			"pestaña de beast")
	panel.free()
	return true


func test_se_actualiza_si_cambia_la_memoria() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _entities[1])
	check_eq(_title(panel).text, tr(_entities[1].name_key), "abre la página")
	_memory.close_page(0)
	check(not _title(panel).visible, "vuelve al índice")
	_memory.open_page(1, _entities[0])
	check(not _title(panel).visible, "la página de otro amigo no cambia lo que se ve")
	panel.free()
	return true


func test_dice_a_que_amigo_ayuda() -> bool:
	var panel := _make_panel()
	panel.open_for(2)
	check_eq((panel.get_node("Page/Layout/Friend") as Label).text,
			tr(panel.FOR_FRIEND_KEY).format({"friend": tr("K_FRIEND_agustin")}), "Agustín")
	panel.free()
	return true


func test_boceto_solo_si_la_entidad_tiene() -> bool:
	var panel := _make_panel()
	var sketch := panel.get_node("Page/Layout/Scroll/Content/Sketch") as TextureRect
	_memory.open_page(0, _entities[0])
	check(not sketch.visible, "sin boceto")
	_entities[1].sketch = ImageTexture.create_from_image(Image.create(96, 96, false, Image.FORMAT_RGBA8))
	_memory.open_page(0, _entities[1])
	check(sketch.visible, "con boceto")
	check_eq(sketch.texture, _entities[1].sketch, "su boceto")
	panel.free()
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	(panel.get_node("Page") as Control).gui_input.emit(click)
	check(not panel.visible, "oculto tras clic derecho")
	panel.free()
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/notebook_panel.gd")
	for key: String in [panel_script.PICK_ENTITY_KEY, panel_script.FOR_FRIEND_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	check(String(TranslationServer.translate(panel_script.FOR_FRIEND_KEY)).contains("{friend}"),
			"NOTEBOOK_FOR_FRIEND debe tener {friend}")
	TranslationServer.set_locale(previous)
	return true
