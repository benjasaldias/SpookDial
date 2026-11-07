extends RefCounted
## Las opciones del jugador (diseño §19): el volumen de cada canal de audio, reducir destellos, la cámara fija
## (sin parallax) y los temporizadores ×1,5, que alargan solo el tiempo para responder (decisión de Benja).
## Se guardan en su propio archivo, aparte de la partida. Lógica pura, salvo apply_audio(), que toca el
## AudioServer.

## Los canales de audio (default_bus_layout.tres): todo, el ambiente del cuarto y los efectos.
const BUSES: Array[StringName] = [&"Master", &"Ambience", &"Effects"]
## Cuánto alarga el tiempo para responder la opción "Temporizadores ×1,5".
const SLOW_TIMER_SCALE := 1.5
const SECTION := "options"

## El volumen de cada canal, de 0 (silencio) a 1.
var volumes := {&"Master": 1.0, &"Ambience": 1.0, &"Effects": 1.0}
## Suaviza los parpadeos rápidos: las entradas, los LED del mixer y los screamers (diseño §19).
var reduce_flashes := false
## La cámara queda fija, sin zoom ni desplazamiento hacia el mouse (desactivar el parallax, diseño §19).
var still_camera := false
## El tiempo para responder una solicitud es 1,5 veces más largo.
var slow_timers := false
## Los audios de los amigos muestran qué se oye, para quien no pueda oírlos.
var audio_captions := false


func timer_scale() -> float:
	return SLOW_TIMER_SCALE if slow_timers else 1.0


## Lee las opciones de `path`. Lo que falte (o si el archivo no existe) queda con su valor por defecto.
func read(path: String) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for bus: StringName in BUSES:
		volumes[bus] = clampf(float(file.get_value(SECTION, "volume_" + String(bus).to_lower(), 1.0)), 0.0, 1.0)
	reduce_flashes = bool(file.get_value(SECTION, "reduce_flashes", false))
	still_camera = bool(file.get_value(SECTION, "still_camera", false))
	slow_timers = bool(file.get_value(SECTION, "slow_timers", false))
	audio_captions = bool(file.get_value(SECTION, "audio_captions", false))


func write(path: String) -> Error:
	var file := ConfigFile.new()
	for bus: StringName in BUSES:
		file.set_value(SECTION, "volume_" + String(bus).to_lower(), volumes[bus])
	file.set_value(SECTION, "reduce_flashes", reduce_flashes)
	file.set_value(SECTION, "still_camera", still_camera)
	file.set_value(SECTION, "slow_timers", slow_timers)
	file.set_value(SECTION, "audio_captions", audio_captions)
	return file.save(path)


## Aplica el volumen de cada canal. Con 0, el canal queda en silencio.
func apply_audio() -> void:
	for bus: StringName in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var volume: float = volumes[bus]
		AudioServer.set_bus_mute(index, volume <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(volume) if volume > 0.0 else -80.0)
