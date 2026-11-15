extends SceneTree
## Mide las noches de los 3 modos con quien juega bien (test/balance_model.gd), para calibrar las calmas (Plan 9.9,
## docs/33, Tarea 5). No es una prueba.
## Uso: ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_night_lengths.gd 2>&1 | tr -d '\r' | grep noche
## Por noche: a qué hora termina en promedio (y la más temprana y la más tarde de 20 semillas), la holgura, la batería, la
## espera promedio por pedido de ayuda y la calma entre olas.

const BalanceModel := preload("res://test/balance_model.gd")
const SEEDS := 20


func _initialize() -> void:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var balance := catalog.balance
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var total := 0.0
			var earliest := INF
			var latest := 0.0
			var wait := 0.0
			for seed_value in SEEDS:
				var result := BalanceModel.simulate(night, balance, seed_value + 1, attention, catalog.friends)
				var end: float = result["end"]
				total += end
				earliest = minf(earliest, end)
				latest = maxf(latest, end)
				wait += BalanceModel.average_wait(result)
			var ratio := BalanceModel.free_time_ratio(night, balance, attention, SEEDS)
			var battery := BalanceModel.battery_needed(night, balance, latest)
			var calm := "plan" if night.has_wave_plan() else str(night.wave_calm if night.wave_calm != Vector2.ZERO
					else balance.wave_calm)
			print("%s noche %d | termina %s (%s a %s) | holgura %.2f | batería %.0f %% | espera %.1f s | calma %s" % [
					difficulty.id, night.number, BalanceModel.clock(total / SEEDS, balance),
					BalanceModel.clock(earliest, balance), BalanceModel.clock(latest, balance), ratio, battery,
					wait / SEEDS, calm])
	quit()
