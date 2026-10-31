extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")


func test_cada_amigo_empieza_en_el_indice() -> bool:
	var memory := NotebookMemory.new(3)
	for friend_index in 3:
		check_eq(memory.page_for(friend_index), null, "amigo %d" % friend_index)
	return true


func test_cada_amigo_recuerda_su_pagina() -> bool:
	var memory := NotebookMemory.new(3)
	var beast := Fixtures.make_entity(&"beast")
	var ghost := Fixtures.make_entity(&"ghost")
	memory.open_page(0, beast)
	memory.open_page(2, ghost)
	check_eq(memory.page_for(0), beast, "León")
	check_eq(memory.page_for(1), null, "Gonzalo sigue en el índice")
	check_eq(memory.page_for(2), ghost, "Agustín")
	memory.close_page(0)
	check_eq(memory.page_for(0), null, "León vuelve al índice")
	return true


func test_avisa_solo_cuando_cambia() -> bool:
	var memory := NotebookMemory.new(3)
	var beast := Fixtures.make_entity(&"beast")
	var changes := []
	memory.page_changed.connect(func(friend_index: int, entity: EntityData) -> void:
		changes.append([friend_index, entity]))
	memory.open_page(1, beast)
	memory.open_page(1, beast)
	memory.close_page(1)
	memory.close_page(1)
	check_eq(changes, [[1, beast], [1, null]], "un aviso por cambio")
	return true
