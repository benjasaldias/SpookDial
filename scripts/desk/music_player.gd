extends Node
## La música por momento (pedido de Benja, Plan 9.8): una pista eerie para el silencio y las calmas, y una tensa para las
## olas, con un fundido de FADE_SECONDS al cambiar. Ayuda a distinguir cuándo los amigos solo graban el vlog y cuándo
## piden ayuda. Las pistas las consigue Benja (audio/music/calm.ogg y wave.ogg, en bucle); mientras no estén, no suena
## nada. Van en el bus del ambiente, así que las controla el volumen "Ambiente" de las opciones.
## El escritorio dice cuándo es una ola (`intense`).

const CALM_PATH := "res://audio/music/calm.ogg"
const WAVE_PATH := "res://audio/music/wave.ogg"
## Lo que tarda el fundido entre las 2 pistas.
const FADE_SECONDS := 2.0
const BUS := &"Ambience"

## Es una ola: suena la pista tensa.
var intense := false
## El volumen de cada pista, de 0 a 1.
var calm_level := 0.0
var wave_level := 0.0

var _calm: AudioStreamPlayer
var _wave: AudioStreamPlayer


func _ready() -> void:
	_calm = _make_player("Calm")
	_wave = _make_player("Wave")
	load_tracks(_load(CALM_PATH), _load(WAVE_PATH))


func _process(delta: float) -> void:
	advance(delta)


## Usa estas pistas (null: sin pista). Se repiten sin pausa.
func load_tracks(calm: AudioStream, wave: AudioStream) -> void:
	for pair: Array in [[_calm, calm], [_wave, wave]]:
		var player: AudioStreamPlayer = pair[0]
		var stream: AudioStream = pair[1]
		if stream != null and "loop" in stream:
			stream.set("loop", true)
		player.stop()
		player.stream = stream


## Empiezan las 2 pistas, en silencio: el fundido sube la que corresponde.
func start() -> void:
	for player: AudioStreamPlayer in [_calm, _wave]:
		if player.stream != null:
			player.play()


func is_playing() -> bool:
	return _calm.playing or _wave.playing


## Avanza el fundido `delta` segundos: la pista del momento sube y la otra baja.
func advance(delta: float) -> void:
	var step := delta / FADE_SECONDS
	calm_level = move_toward(calm_level, 0.0 if intense else 1.0, step)
	wave_level = move_toward(wave_level, 1.0 if intense else 0.0, step)
	_calm.volume_db = linear_to_db(maxf(calm_level, 0.001))
	_wave.volume_db = linear_to_db(maxf(wave_level, 0.001))


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	player.volume_db = linear_to_db(0.001)
	add_child(player)
	return player


static func _load(path: String) -> AudioStream:
	return load(path) as AudioStream if ResourceLoader.exists(path) else null
