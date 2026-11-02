extends "res://test/test_case.gd"
## Los sonidos provisionales del Plan 6 (tools/make_placeholder_sounds.py), hasta los definitivos del Plan 9.

## Nombre de cada archivo de audio/sfx/ y cuántos segundos dura.
const SOUNDS := {
	"sync_kick": 0.22,
	"sync_tick": 0.06,
	"sync_clap": 0.25,
	"sync_tap": 0.12,
	"sync_success": 0.4,
	"sync_fail": 0.44,
	"interference_static": 3.0,
}


func test_los_sonidos_se_cargan() -> bool:
	for sound_name: String in SOUNDS:
		var stream: AudioStream = load("res://audio/sfx/%s.wav" % sound_name)
		check(stream is AudioStreamWAV, "se carga " + sound_name)
		if stream != null:
			check(absf(stream.get_length() - SOUNDS[sound_name]) < 0.01, "%s dura %s s: %s" % [sound_name,
					SOUNDS[sound_name], stream.get_length()])
	return true
