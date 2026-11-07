class_name NightData
extends Resource
## Parámetros de una noche. Los valores iniciales están en docs/02 §6 y se ajustan probando.
## La noche 0 es el tutorial (decisión de Benja): sus solicitudes son fijas y no se puede perder.

@export_range(0, 5) var number := 1
## Dónde están los amigos esa noche, en ui.csv (para el resumen entre noches).
@export var place_key: String
## Entidades que aparecen por primera vez esta noche. Las de noches anteriores siguen apareciendo.
@export var new_entities: Array[EntityData] = []

@export_group("Solicitudes")
@export var requests_total := 6
@export var max_simultaneous := 1
## Segundos para responder, antes del factor de Trust.
@export var base_decision_time := 45.0
## Probabilidad de que el mensaje inicial traiga una pista: una de las 2 características, que se puede
## clickear. Todo lo demás (características, señuelos y observaciones) sale al preguntar (decisión de Benja, 3-nov).
@export_range(0.0, 1.0) var first_hint_chance := 1.0
## Señuelos de la solicitud: frases clickeables que camuflan sus 2 características cuando el amigo las cuenta.
@export var decoys_per_request := 1
## Solicitudes por ola: llegan seguidas y, después de cada ola, hay un respiro (decisión de Benja).
@export var wave_size := 3

@export_group("Señal")
@export var signal_decays := false
## Segundos por cada punto de señal perdido (mínimo y máximo; varía).
@export var signal_decay_interval := Vector2(3, 6)
@export var interference_count := 0
## Tiempos del Audio Sync (0 si esta noche no hay).
@export var audio_sync_beats := 0
## Golpes por minuto de la base del Audio Sync, que sube noche a noche (decisión de Benja, 7 de noviembre). El
## ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0

@export_group("Sanity y cuota")
## Segundos por cada punto de Sanity perdido.
@export var sanity_drain_interval := 6.0
## Videos que hay que recibir para ganar la noche (= envíos programados).
@export var content_quota := 2

@export_group("Screamers")
## Screamers de la noche, sin contar las alucinaciones ni el susto guionado. Llegan en cualquier momento,
## con las reglas de justicia (decisión de Benja).
@export var scare_count := 0
## Uno de los screamers es la criatura que se asoma por la ventana (el antiguo jumpscare): como máximo uno por
## noche, desde la noche 2.
@export var has_jumpscare := false

@export_group("Guion")
## Segundos desde las 00:00 del susto guionado (0: no hay). Llega en el primer momento sin solicitudes.
@export var scripted_scare_time := 0.0
## Qué screamer es el susto guionado.
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE
## El chat guionado que sigue al susto guionado (decisión de Benja, sesión 16), o ninguno.
@export var scripted_chat: ChatScriptData

@export_group("Tutorial")
## Solo en la noche 0: las solicitudes fijas, en orden. Llegan de a una, cuando termina la anterior.
@export var tutorial_requests: Array[TutorialRequestData] = []


func is_tutorial() -> bool:
	return number == 0
