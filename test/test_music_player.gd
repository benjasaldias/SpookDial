extends "res://test/test_case.gd"
## La música por momento (pedido de Benja, Plan 9.8): una pista para las calmas y otra tensa para las olas, con un
## fundido al cambiar. Las pistas las consigue Benja.

const Fixtures := preload("res://test/content_fixtures.gd")
const MusicPlayer := preload("res://scripts/desk/music_player.gd")


func _make_player(with_tracks: bool) -> MusicPlayer:
	var player := MusicPlayer.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(player)
	if with_tracks:
		player.load_tracks(Fixtures.make_audio(5.0), Fixtures.make_audio(5.0))
	return player


func test_sin_pistas_no_suena_nada() -> bool:
	var player := _make_player(false)
	player.load_tracks(null, null)
	player.start()
	player.advance(3.0)
	check(not player.is_playing(), "mientras no estén las pistas, nada")
	player.free()
	return true


func test_la_calma_y_la_ola_con_un_fundido() -> bool:
	var player := _make_player(true)
	player.start()
	check(player.is_playing(), "suena")
	player.advance(MusicPlayer.FADE_SECONDS)
	check_eq([player.calm_level, player.wave_level], [1.0, 0.0], "empieza en calma")
	player.intense = true
	player.advance(MusicPlayer.FADE_SECONDS / 2.0)
	check(is_equal_approx(player.calm_level, 0.5) and is_equal_approx(player.wave_level, 0.5), "a la mitad del fundido")
	player.advance(MusicPlayer.FADE_SECONDS)
	check_eq([player.calm_level, player.wave_level], [0.0, 1.0], "en la ola, la tensa")
	check_eq(player.get_node("Calm").bus, &"Ambience", "en el volumen del ambiente")
	player.free()
	return true
