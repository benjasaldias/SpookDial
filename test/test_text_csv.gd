extends "res://test/test_case.gd"
## Los textos van en data/text/*.csv con las columnas keys,es,en. Una coma sin comillas dentro de un texto
## parte la fila y corta el texto sin avisar (el resto cae en la columna siguiente): esta prueba lo vigila.

const TEXT_DIR := "res://data/text"


func test_cada_fila_tiene_las_3_columnas() -> bool:
	var found := 0
	for file_name: String in DirAccess.get_files_at(TEXT_DIR):
		if not file_name.ends_with(".csv"):
			continue
		found += 1
		var file := FileAccess.open(TEXT_DIR.path_join(file_name), FileAccess.READ)
		var header := file.get_csv_line()
		check_eq(header, PackedStringArray(["keys", "es", "en"]), "%s: encabezado" % file_name)
		var line_number := 1
		while not file.eof_reached():
			var row := file.get_csv_line()
			line_number += 1
			if row.size() == 1 and row[0].is_empty():
				continue
			check_eq(row.size(), 3, "%s, línea %d (%s): una coma sin comillas parte el texto" % [file_name, line_number, row[0]])
	check(found >= 4, "se encontraron los CSV de textos: %d" % found)
	return true
