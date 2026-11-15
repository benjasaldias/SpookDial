extends SceneTree
## Guarda en JSON una noche simulada con quien juega bien (test/balance_model.gd), para dibujar su curva de olas con
## tools/plot_waves.py. No es una prueba.
## Uso: ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_waves.gd -- <noche> <semilla> <archivo.json> \
##     [dificultad]
## La dificultad es "normal" (por defecto), "hard" o "extreme".

const BalanceModel := preload("res://test/balance_model.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var difficulty := catalog.find_difficulty(StringName(args[3]) if args.size() > 3 else &"normal")
	var night: NightData = catalog.night(int(args[0]), difficulty)
	var result := BalanceModel.simulate(night, catalog.balance, int(args[1]), BalanceModel.attention_for(difficulty))
	result["night"] = night.number
	result["difficulty"] = String(difficulty.id)
	result["seed"] = int(args[1])
	# Lo que duró la noche (Plan 9.9: termina cuando se completa): tools/plot_waves.py dibuja hasta ahí.
	result["night_seconds"] = result["end"]
	result["battery"] = BalanceModel.battery_needed(night, catalog.balance, result["end"])
	result["free_time_needed"] = BalanceModel.free_time_needed(night, catalog.balance, result["end"])
	var file := FileAccess.open(args[2], FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("Noche %d (%s) guardada en %s" % [night.number, difficulty.id, args[2]])
	quit()
