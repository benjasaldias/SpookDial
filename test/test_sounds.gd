extends "res://test/test_case.gd"
## Los efectos de sonido y los audios de los amigos (tools/make_sounds.py, sesión del 10 de noviembre).

## Nombre de cada archivo de audio/sfx/ y cuántos segundos dura.
const SOUNDS := {
	"sync_kick": 0.22,
	"sync_tick": 0.06,
	"sync_clap": 0.25,
	"sync_tap": 0.12,
	"sync_success": 0.4,
	"sync_fail": 0.44,
	"interference_static": 3.0,
	"ambient_room": 24.0,
	"scare_curtains": 1.2,
	"scare_window": 1.5,
	"scare_phone": 1.2,
	"scare_lights": 1.5,
	"scare_slam": 0.5,
	"scare_ink": 0.6,
	"scare_creature_breathing": 8.0,
	"scare_creature_knocks": 7.0,
	"hallucination_knock": 1.0,
	"hallucination_steps": 2.0,
	"hallucination_whisper": 2.0,
	"hallucination_scratch": 1.5,
	"hand_creak": 0.45,
	"phone_flash": 0.5,
	"voice_leon": 0.05,
	"voice_gonzalo": 0.066,
	"voice_agustin": 0.034,
}

## Los sonidos que se repiten sin pausa: su importación los deja en bucle (edit/loop_mode).
const LOOPING_SOUNDS: Array[String] = ["ambient_room", "scare_creature_breathing"]

## Los audios que mandan los amigos, en audio/clues/ (decisión de Benja, 7 de noviembre). Duran 3 s.
const CLUE_SOUNDS: Array[String] = [
	"tue_tue_cries_one", "tue_tue_cries_three", "tue_tue_cries_none",
	"calchona_bleat_tone_weeping", "calchona_bleat_tone_snorting",
	"cuero_whistle_yes", "cuero_whistle_no",
	"viuda_heels_slow", "viuda_heels_fast",
	"trauco_ground_muddy", "trauco_ground_dry",
	"basilisco_crows_once", "basilisco_crows_twice",
	"imbunche_baby_cry_yes", "imbunche_baby_cry_no",
]
const CLUE_SECONDS := 3.0


func test_los_audios_de_los_amigos_se_cargan() -> bool:
	for sound_name: String in CLUE_SOUNDS:
		var stream: AudioStream = load("res://audio/clues/%s.wav" % sound_name)
		check(stream is AudioStreamWAV, "se carga " + sound_name)
		if stream != null:
			check(absf(stream.get_length() - CLUE_SECONDS) < 0.01, "%s dura %s s" % [sound_name, stream.get_length()])
	return true


func test_los_sonidos_se_cargan() -> bool:
	for sound_name: String in SOUNDS:
		var stream: AudioStream = load("res://audio/sfx/%s.wav" % sound_name)
		check(stream is AudioStreamWAV, "se carga " + sound_name)
		if stream != null:
			check(absf(stream.get_length() - SOUNDS[sound_name]) < 0.01, "%s dura %s s: %s" % [sound_name,
					SOUNDS[sound_name], stream.get_length()])
	return true


func test_el_ambiente_y_la_respiracion_van_en_bucle() -> bool:
	for sound_name: String in LOOPING_SOUNDS:
		var stream: AudioStreamWAV = load("res://audio/sfx/%s.wav" % sound_name)
		check(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, sound_name + " va en bucle")
	return true
