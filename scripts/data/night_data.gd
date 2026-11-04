class_name NightData
extends Resource
## Parámetros de una noche. Los valores iniciales están en docs/02 §6 y se ajustan probando.

enum FirstMessageObservations { ALL, ALL_BUT_ONE, ONE }

@export_range(1, 5) var number := 1
## Dónde están los amigos esa noche, en ui.csv (para el resumen entre noches).
@export var place_key: String
## Entidades que aparecen por primera vez esta noche. Las de noches anteriores siguen apareciendo.
@export var new_entities: Array[EntityData] = []

@export_group("Solicitudes")
@export var requests_total := 6
@export var max_simultaneous := 1
## Segundos para responder, antes del factor de Trust.
@export var base_decision_time := 45.0
## Cuántas observaciones trae el mensaje inicial; las demás hay que preguntarlas.
@export var first_message_observations: FirstMessageObservations = FirstMessageObservations.ALL
## Señuelos del mensaje inicial: frases clickeables que camuflan sus 2 características.
@export var decoys_in_first_message := 1
## Solicitudes por ola: llegan seguidas y, después de cada ola, hay un respiro (decisión de Benja).
@export var wave_size := 3

@export_group("Señal")
@export var signal_decays := false
## Segundos por cada punto de señal perdido (mínimo y máximo; varía).
@export var signal_decay_interval := Vector2(3, 6)
@export var interference_count := 0
## Tiempos del Audio Sync (0 si esta noche no hay).
@export var audio_sync_beats := 0

@export_group("Sanity y cuota")
## Segundos por cada punto de Sanity perdido.
@export var sanity_drain_interval := 6.0
## Videos que hay que recibir para ganar la noche (= envíos programados).
@export var content_quota := 2

@export_group("Screamers")
## Screamers de la noche, sin contar las alucinaciones ni el susto guionado. Llegan en cualquier momento,
## con las reglas de justicia (decisión de Benja).
@export var scare_count := 0
## Uno de los screamers es el jumpscare de pantalla completa: como máximo uno por noche, desde la noche 2.
@export var has_jumpscare := false

@export_group("Guion")
## Segundos desde las 00:00 del susto guionado (0: no hay). Llega en el primer momento sin solicitudes.
@export var scripted_scare_time := 0.0
## Qué screamer es el susto guionado.
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE
## El chat guionado que sigue al susto guionado (decisión de Benja, sesión 16), o ninguno.
@export var scripted_chat: ChatScriptData


## Cuántas observaciones trae el mensaje inicial de una entidad que tiene `total`.
func observations_in_first_message(total: int) -> int:
	match first_message_observations:
		FirstMessageObservations.ALL_BUT_ONE:
			return total - 1
		FirstMessageObservations.ONE:
			return 1
	return total
