class_name StoryBeatData
extends Resource
## Un momento de la historia de una noche (docs/21 §2): cuándo llega y lo que pasa, en orden. La historia llega al empezar,
## al terminar una ola, unos segundos antes de la siguiente y al cerrar, nunca en medio de una ola (salvo una decisión que
## no alcanzó a terminar). En Extremo, que tiene más olas, la "ola 2" de la historia es la última ola común: las del medio
## no tienen historia.

enum Moment {
	## Al empezar la noche, en el minuto de silencio.
	NIGHT_START,
	## Unos segundos antes de la primera ola (lead_seconds).
	BEFORE_FIRST_WAVE,
	## Al terminar la primera ola, en su calma.
	AFTER_FIRST_WAVE,
	## Unos segundos antes de la última ola común.
	BEFORE_LAST_WAVE,
	## Al terminar la última ola común: la calma antes de la ola final.
	AFTER_LAST_WAVE,
	## Unos segundos antes de la ola final.
	BEFORE_FINALE,
	## Cuando terminó la ola final y no queda nada abierto: el cierre.
	AFTER_FINALE,
}

@export var moment: Moment = Moment.NIGHT_START
## En los momentos "antes de", cuántos segundos antes de la ola empieza.
@export var lead_seconds := 15.0
## Lo que pasa, en orden.
@export var steps: Array[StoryStepData] = []


## Es un momento "antes de" una ola: usa lead_seconds.
func is_before_wave() -> bool:
	return moment in [Moment.BEFORE_FIRST_WAVE, Moment.BEFORE_LAST_WAVE, Moment.BEFORE_FINALE]
