extends SceneTree
## Ejecuta todos los res://test/test_*.gd. Sale con código 1 si alguna prueba falla.
## Uso: ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd [-- test_parte_del_nombre ...]

const TEST_DIR := "res://test"

var _passed := 0
var _failed := 0


func _initialize() -> void:
	# _initialize corre antes de que la raíz entre al árbol: se difiere para que los nodos reciban _ready.
	_run_all.call_deferred()


func _run_all() -> void:
	var files := Array(DirAccess.get_files_at(TEST_DIR))
	files.sort()
	# Con nombres después de "--", solo las suites que los contienen: "-- test_chat_panel test_highlight".
	var only := Array(OS.get_cmdline_user_args())
	for file_name: String in files:
		if not only.is_empty() and not only.any(func(part: String) -> bool: return file_name.contains(part)):
			continue
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			_run_suite(TEST_DIR.path_join(file_name))
	print("\n%d pruebas OK, %d fallidas" % [_passed, _failed])
	# Los sonidos que las pruebas dejaron sonando se liberan en el hilo de audio: se le da un momento antes de
	# salir, para que no queden recursos en uso.
	await create_timer(0.2).timeout
	quit(1 if _failed > 0 else 0)


func _run_suite(path: String) -> void:
	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		_failed += 1
		print("FALLA  %s :: no se pudo cargar (revisa SCRIPT ERROR más arriba)" % path.get_file())
		return
	var suite: Object = script.new()
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		suite.call("reset_errors")
		var finished: Variant = suite.call(method_name)
		var errors: Array = suite.get("errors")
		if finished != true:
			errors.append("la prueba no terminó (revisa SCRIPT ERROR más arriba)")
		if errors.is_empty():
			_passed += 1
			print("OK     %s :: %s" % [path.get_file(), method_name])
		else:
			_failed += 1
			print("FALLA  %s :: %s" % [path.get_file(), method_name])
			for error: String in errors:
				print("         - " + error)
