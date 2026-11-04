extends "res://test/test_case.gd"
## Las opciones del jugador (diseño §19) y los canales de audio.

const GameSettings := preload("res://scripts/core/game_settings.gd")
const TEST_PATH := "user://test_settings.cfg"


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_valores_por_defecto() -> bool:
	var settings := GameSettings.new()
	for bus: StringName in GameSettings.BUSES:
		check_eq(settings.volumes[bus], 1.0, "volumen de %s" % bus)
	check(not settings.reduce_flashes and not settings.still_camera and not settings.slow_timers, "todo apagado")
	check_eq(settings.timer_scale(), 1.0, "temporizadores normales")
	settings.slow_timers = true
	check_eq(settings.timer_scale(), 1.5, "temporizadores ×1,5")
	return true


func test_se_guardan_y_se_leen() -> bool:
	_remove_test_file()
	var settings := GameSettings.new()
	settings.volumes[&"Effects"] = 0.25
	settings.reduce_flashes = true
	settings.still_camera = true
	settings.slow_timers = true
	check_eq(settings.write(TEST_PATH), OK, "se guardan")
	var read := GameSettings.new()
	read.read(TEST_PATH)
	check_eq(read.volumes[&"Effects"], 0.25, "volumen")
	check_eq(read.volumes[&"Master"], 1.0, "el resto igual")
	check(read.reduce_flashes and read.still_camera and read.slow_timers, "los interruptores")
	_remove_test_file()
	return true


func test_sin_archivo_quedan_los_valores_por_defecto() -> bool:
	_remove_test_file()
	var settings := GameSettings.new()
	settings.read(TEST_PATH)
	check_eq(settings.volumes[&"Master"], 1.0, "volumen")
	check(not settings.reduce_flashes, "destellos")
	return true


## Los 3 canales existen (default_bus_layout.tres) y el volumen de cada uno se aplica al AudioServer.
func test_el_volumen_de_cada_canal() -> bool:
	for bus: StringName in GameSettings.BUSES:
		check(AudioServer.get_bus_index(bus) >= 0, "existe el canal %s" % bus)
	var settings := GameSettings.new()
	settings.volumes[&"Ambience"] = 0.5
	settings.volumes[&"Effects"] = 0.0
	settings.apply_audio()
	var ambience := AudioServer.get_bus_index(&"Ambience")
	var effects := AudioServer.get_bus_index(&"Effects")
	check(is_equal_approx(AudioServer.get_bus_volume_db(ambience), linear_to_db(0.5)), "ambiente a la mitad")
	check(AudioServer.is_bus_mute(effects), "efectos en 0: silencio")
	GameSettings.new().apply_audio()
	check(not AudioServer.is_bus_mute(effects), "vuelve a sonar")
	check_eq(AudioServer.get_bus_volume_db(ambience), 0.0, "ambiente a tope")
	return true


## Cada sonido va a su canal: el ambiente del cuarto a Ambience, y todo lo demás a Effects.
func test_cada_sonido_en_su_canal() -> bool:
	for path: String in ["res://scenes/desk/desk.tscn", "res://scenes/ui/mixer_view.tscn"]:
		var scene := (load(path) as PackedScene).instantiate()
		var players := scene.find_children("*", "AudioStreamPlayer", true, false)
		players.append_array(scene.find_children("*", "AudioStreamPlayer2D", true, false))
		check(not players.is_empty(), "%s tiene sonidos" % path)
		for player: Node in players:
			var expected := &"Ambience" if player.name == &"Ambient" else &"Effects"
			check_eq(player.get("bus"), expected, "%s: %s" % [path.get_file(), player.name])
		scene.free()
	return true
