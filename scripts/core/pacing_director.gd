extends RefCounted
## El director de ritmo (diseño §5 y §11; decisiones de Benja, 2 y 11 de noviembre): decide cuándo llega cada
## solicitud y qué pasa en cada momento de la noche.
## La noche empieza con un minuto de silencio. Después llegan olas: las solicitudes de una ola llegan juntas, con pocos
## segundos de diferencia, y cuando se resuelven todas viene una calma de verdad.
## Desde el Plan 9.9 (docs/33; decisión de Benja, 14 de noviembre) las olas van en cadena: cada una, también la final
## (la más grande, el clímax), llega cuando pasa su calma desde que se resolvió la anterior. Ninguna se salta, y no hay
## hora de término: la noche se completa cuando se resuelve la final (RequestManager.night_complete), así que jugar
## rápido la acorta.
## Las interferencias, los accidentes y la Mano caen en las olas; los videos y los screamers, en las calmas, y una
## visita de la criatura, en la ola final. Un amigo herido atrasa lo que falta.
## Una noche puede traer sus olas armadas a mano (NightData.wave_plan, desde el Plan 9.4: la noche 1 de Normal). Cada ola
## dice cuántas consultas y videos trae, separados cuánto, y la calma que la precede. Sus videos llegan dentro de la ola:
## cuando a la consulta anterior le quedan unos segundos o, si ya se respondió, un poco después. La última es la final.
## Desde el Plan 9.7 (la historia, docs/31), cuenta las olas y las calmas que empezaron, para que la historia sepa en qué
## momento va, y una ola espera mientras la historia cuenta algo antes de ella (story_hold), a lo más story_hold_limit s.
## Desde el Plan 9.8, la historia está en el horario (story_needs): la primera ola llega cuando terminó lo de antes, y
## cada calma dura al menos lo que cuenta su historia. Así la espera queda solo de seguro.
## Lógica pura: RequestManager la avanza y le pregunta por las solicitudes y los accidentes; ScreamerManager, por los
## screamers, y HandManager, por la Mano. Las reglas de justicia de los screamers las revisa Screamer.

enum Phase { SILENCE, WAVE, CALM, FINALE, DONE }


## Lo que empezó en un paso de la noche.
class Beat:
	## La ola que empezó (su índice en `waves`), o -1.
	var wave_started := -1
	## La ola que empezó es la final.
	var finale_started := false
	var calm_started := false
	## Las horas de las interferencias que trae la ola que empezó.
	var interferences: Array[float] = []
	## Las horas de los videos que suelta la calma que empezó.
	var videos: Array[float] = []


## Una ola planeada y lo que trae.
class Wave:
	## Lo que llega, en orden: false es una consulta y true, un video (solo en las olas de un plan).
	var arrivals: Array[bool] = []
	var finale := false
	## Segundos entre dos llegadas seguidas.
	var spacing := Vector2.ZERO
	## Segundos de calma antes de la ola (solo en un plan; las automáticas usan BalanceData.wave_calm).
	var calm_before := Vector2.ZERO
	## Un video llega cuando a la consulta anterior le quedan tantos segundos o, si ya no hay consultas abiertas, tantos
	## segundos después.
	var video_time_left := 0.0
	var video_after_answer := Vector2.ZERO
	var interferences := 0
	var incidents := 0
	var hands := 0
	## Los screamers de la calma que la sigue: los ambientales y las visitas de la criatura.
	var calm_scares := 0
	var calm_creatures := 0
	## Una visita de la criatura llega en la ola misma (solo la final).
	var creature := false


var phase := Phase.SILENCE
## Las olas de la noche, en orden: las comunes y, al final, la final.
var waves: Array[Wave] = []
## La ola en curso o, en el silencio y en las calmas, la que sigue.
var wave_index := 0
## Desde qué hora puede llegar lo próximo de la ola o, en el silencio y en las calmas, la próxima ola.
var next_at := 0.0
## Lo que todavía no llega de la ola en curso, en orden: false es una consulta y true, un video.
var pending: Array[bool] = []
## Los videos de la cuota que todavía no se sueltan en una calma (los de un plan llegan en sus olas).
var videos_left := 0
## La hora en que empezó la última solicitud.
var last_request := -INF
## Las horas de los screamers que faltan, sin el guionado, en orden, y si cada uno es la criatura.
var scare_times: Array[float] = []
var scare_creature: Array[bool] = []
## La hora del susto guionado, o -1 si no hay o ya pasó.
var scripted_scare_time := -1.0
## La hora en que empezó el último screamer.
var last_scare := -INF
## Las horas de los accidentes que faltan, en orden.
var incident_times: Array[float] = []
## Las horas de las visitas de la Mano que faltan, en orden.
var hand_times: Array[float] = []
## Cuántas olas y cuántas calmas empezaron (la historia lee en qué momento va la noche).
var waves_started := 0
var calms_started := 0
## La historia está contando algo antes de la próxima ola: en el silencio y en las calmas, la ola espera a lo más
## story_hold_limit segundos desde su hora (decisión de Benja, S21l). RequestManager lo pone antes de cada paso.
var story_hold := false
## Cuánto dura la historia de cada momento (StoryBeatData.Moment → segundos; StoryRunner.story_needs): el director se lo
## deja en el horario. Vacío sin historia.
var story_needs := {}

var _balance: BalanceData
var _rng: RandomNumberGenerator
## Segundos para responder de la noche (sin el factor de Trust): un video de una ola llega antes de que se acaben.
var _decision_time := 0.0
## Ya no había consultas abiertas cuando el próximo video de la ola esperaba: llega un poco después.
var _answered := false
## La calma después de una ola: la de la noche o, si no trae, la de balance.tres.
var _wave_calm := Vector2.ZERO
## Ya empezó la ola final.
var _finale_started := false


func _init(night: NightData, balance: BalanceData, rng: RandomNumberGenerator, needs := {}) -> void:
	_balance = balance
	_rng = rng
	story_needs = needs
	_decision_time = night.base_decision_time
	_wave_calm = night.wave_calm if night.wave_calm != Vector2.ZERO else balance.wave_calm
	videos_left = night.content_quota
	next_at = balance.first_wave_at
	if night.scripted_scare_time > 0.0:
		scripted_scare_time = night.scripted_scare_time
	if night.has_wave_plan():
		_plan_from(night)
	else:
		_plan(night)
	# La primera ola llega cuando terminaron el comienzo y lo de antes de ella.
	next_at = maxf(next_at, _need(StoryBeatData.Moment.NIGHT_START) + _need(StoryBeatData.Moment.BEFORE_FIRST_WAVE))



## Avanza hasta `now`, con `active` solicitudes abiertas. Empieza la ola que toca o, cuando se resuelve la ola en
## curso, su calma. Devuelve lo que empezó.
func advance(now: float, active: int) -> Beat:
	var beat := Beat.new()
	match phase:
		Phase.SILENCE, Phase.CALM:
			if wave_index < waves.size() and now >= next_at and not _held_by_story(now):
				_start_wave(now, beat)
		Phase.WAVE:
			_advance_video(now, active, beat)
			if pending.is_empty() and active == 0:
				_start_calm(now, beat)
		Phase.FINALE:
			_advance_video(now, active, beat)
			if pending.is_empty():
				phase = Phase.DONE
	return beat


## La última ola común planeada (sin contar la final), o -1 si no hay: la "ola 2" de la historia (docs/21 §2).
func last_regular_index() -> int:
	return waves.size() - (2 if _has_finale() else 1)


## La ola final, o -1 si la noche no tiene.
func finale_index() -> int:
	return waves.size() - 1 if _has_finale() else -1


## Ya empezó la ola final.
func finale_started() -> bool:
	return _finale_started


## La historia está contando algo y la ola todavía no lleva story_hold_limit segundos de atraso.
func _held_by_story(now: float) -> bool:
	return story_hold and now < next_at + _balance.story_hold_limit


## Toca empezar una solicitud de la ola en curso: lo próximo que trae es una consulta y llegó su hora. Desde el Plan 9.9
## no hay hora de término, así que nunca se corta.
func request_due(now: float) -> bool:
	return (phase == Phase.WAVE or phase == Phase.FINALE) and not pending.is_empty() and not pending[0] \
			and now >= next_at


## Empezó la solicitud que tocaba. Lo siguiente de la ola llega unos segundos después o, si es un video, cuando a esta
## consulta le queden video_time_left segundos.
func request_started(now: float) -> void:
	if not pending.is_empty():
		pending.pop_front()
	last_request = now
	var wave := waves[mini(wave_index, waves.size() - 1)] if not waves.is_empty() else null
	if wave != null and not pending.is_empty() and pending[0]:
		next_at = now + maxf(_decision_time - wave.video_time_left, 0.0)
		_answered = false
	else:
		var spacing := wave.spacing if wave != null else _balance.wave_spacing
		next_at = now + _rng.randf_range(spacing.x, spacing.y)


## Un amigo quedó herido: lo que falta (la próxima solicitud o la próxima ola) se atrasa hurt_respite segundos
## (decisión de Benja).
func friend_hurt() -> void:
	next_at += _balance.hurt_respite


## Toca un screamer: llegó su hora y pasaron scare_min_gap segundos desde el anterior.
func scare_due(now: float) -> bool:
	return not scare_times.is_empty() and now >= scare_times[0] and now - last_scare >= _balance.scare_min_gap


## El próximo screamer es la criatura de la ventana (el antiguo jumpscare).
func next_is_jumpscare() -> bool:
	return not scare_creature.is_empty() and scare_creature[0]


## Empezó el screamer que tocaba.
func scare_started(now: float) -> void:
	if scare_times.is_empty():
		return
	scare_times.pop_front()
	scare_creature.pop_front()
	last_scare = now


## Toca un accidente: llegó su hora.
func incident_due(now: float) -> bool:
	return not incident_times.is_empty() and now >= incident_times[0]


## Empezó el accidente que tocaba.
func incident_started() -> void:
	incident_times.pop_front()


## Toca una visita de la Mano: llegó su hora.
func hand_due(now: float) -> bool:
	return not hand_times.is_empty() and now >= hand_times[0]


## Empezó la visita de la Mano que tocaba.
func hand_started() -> void:
	hand_times.pop_front()


## Toca el susto guionado: llegó su hora y no hay solicitudes activas.
func scripted_scare_due(now: float, active_requests: int) -> bool:
	return scripted_scare_time > 0.0 and now >= scripted_scare_time and active_requests == 0


## Empezó el susto guionado. Cuenta como screamer: el siguiente espera scare_min_gap segundos.
func scripted_scare_started(now: float) -> void:
	scripted_scare_time = -1.0
	last_scare = now


## Arma las olas y reparte lo que trae cada una: las interferencias en todas (las que sobran, hacia el final), los
## accidentes y la Mano en las comunes, y los screamers en las calmas. La criatura visita una vez la ola final.
func _plan(night: NightData) -> void:
	var total := maxi(night.requests_total, 0)
	var finale_size := clampi(night.finale_size, 0, total)
	var regular := total - finale_size
	var wave_size := maxi(night.wave_size, 1)
	var regular_count := ceili(regular / float(wave_size))
	for index in regular_count:
		waves.append(_requests_wave(mini(wave_size, regular - index * wave_size)))
	var regular_waves := waves.duplicate()
	if finale_size > 0:
		var finale := _requests_wave(finale_size)
		finale.finale = true
		finale.creature = night.creature_visits > 0
		waves.append(finale)
	_spread(night.interference_count, waves, "interferences", true)
	_spread(night.incident_count, regular_waves, "incidents", false)
	_spread(night.hand_visits, regular_waves, "hands", true)
	var creatures_in_calms := maxi(night.creature_visits - (1 if finale_size > 0 else 0), 0)
	_spread(maxi(night.scare_count - night.creature_visits, 0), regular_waves, "calm_scares", false)
	_spread(creatures_in_calms, regular_waves, "calm_creatures", true)


## Una ola automática: `size` consultas, separadas por wave_spacing.
func _requests_wave(size: int) -> Wave:
	var wave := Wave.new()
	for _index in size:
		wave.arrivals.append(false)
	wave.spacing = _balance.wave_spacing
	return wave


## Arma las olas del plan de la noche, tal como vienen. La última es la final; la primera llega a su calma
## previa, contada desde las 00:00. Los videos del plan llegan en sus olas, y las calmas sueltan solo los que falten
## para la cuota.
func _plan_from(night: NightData) -> void:
	for data: WaveData in night.wave_plan:
		var wave := Wave.new()
		wave.arrivals = data.arrivals()
		wave.spacing = data.spacing
		wave.calm_before = data.calm_before
		wave.video_time_left = data.video_time_left
		wave.video_after_answer = data.video_after_answer
		wave.interferences = data.interferences
		wave.incidents = data.incidents
		wave.hands = data.hands
		wave.calm_scares = data.calm_scares
		wave.calm_creatures = data.calm_creatures
		waves.append(wave)
	waves[-1].finale = true
	next_at = _rng.randf_range(waves[0].calm_before.x, waves[0].calm_before.y)
	videos_left = maxi(night.content_quota - night.total_videos(), 0)


## Reparte `count` entre `targets` lo más parejo posible, sumándolo a su campo `field`. Lo que sobra va a los últimos
## (`late`) o a los primeros.
static func _spread(count: int, targets: Array, field: String, late: bool) -> void:
	if targets.is_empty() or count <= 0:
		return
	var base := count / targets.size()
	var extra := count % targets.size()
	for index in targets.size():
		var gets_extra := index >= targets.size() - extra if late else index < extra
		var wave: Wave = targets[index]
		wave.set(field, int(wave.get(field)) + base + (1 if gets_extra else 0))


func _has_finale() -> bool:
	return not waves.is_empty() and waves[-1].finale


## Empieza la ola `wave_index`: sus solicitudes desde ahora, y sus interferencias, accidentes y visitas de la Mano unos
## segundos después. La final trae también a la criatura y suelta los videos que no alcanzaron a salir en una calma.
func _start_wave(now: float, beat: Beat) -> void:
	var wave := waves[wave_index]
	phase = Phase.FINALE if wave.finale else Phase.WAVE
	waves_started += 1
	_finale_started = _finale_started or wave.finale
	pending = wave.arrivals.duplicate()
	_answered = false
	next_at = now
	beat.wave_started = wave_index
	beat.finale_started = wave.finale
	for _index in wave.interferences:
		beat.interferences.append(now + _wave_delay())
	for _index in wave.incidents:
		_insert(incident_times, now + _wave_delay())
	for _index in wave.hands:
		_insert(hand_times, now + _wave_delay())
	if wave.creature:
		_queue_scare(now + _wave_delay(), true)
	if wave.finale:
		_release_videos(now, videos_left, beat)


## La ola se resolvió: empieza su calma, con sus videos y sus screamers. La ola siguiente, también la final, llega cuando
## pasa la calma o cuando termina lo que cuenta la historia, lo que sea más tarde (Plan 9.9: ninguna se salta).
func _start_calm(now: float, beat: Beat) -> void:
	var finished := waves[wave_index]
	phase = Phase.CALM
	calms_started += 1
	beat.calm_started = true
	wave_index += 1
	var calm := _wave_calm
	if wave_index < waves.size() and waves[wave_index].calm_before != Vector2.ZERO:
		calm = waves[wave_index].calm_before
	next_at = now + _rng.randf_range(calm.x, calm.y)
	if wave_index < waves.size():
		var need := _finale_story() if waves[wave_index].finale else _calm_story(wave_index)
		next_at = maxf(next_at, now + need)
	else:
		phase = Phase.DONE
	var calms_left := 1
	for index in range(wave_index, waves.size()):
		if not waves[index].finale:
			calms_left += 1
	_release_videos(now, ceili(videos_left / float(calms_left)), beat)
	var kinds: Array[bool] = []
	for _index in finished.calm_scares:
		kinds.append(false)
	for _index in finished.calm_creatures:
		kinds.append(true)
	var time := now + _calm_delay()
	for index in range(kinds.size() - 1, 0, -1):
		var other := _rng.randi_range(0, index)
		var swap := kinds[index]
		kinds[index] = kinds[other]
		kinds[other] = swap
	for creature: bool in kinds:
		_queue_scare(time, creature)
		time += _balance.scare_min_gap


## Lo que dura la historia de `moment`, o 0.
func _need(moment: StoryBeatData.Moment) -> float:
	return float(story_needs.get(moment, 0.0))


## Lo que cuenta la historia en la calma que empieza, antes de la ola común `next_index`: lo de después de la primera ola
## (si es la primera calma) y lo de antes de la última ola común (si es esa).
func _calm_story(next_index: int) -> float:
	var need := _need(StoryBeatData.Moment.AFTER_FIRST_WAVE) if calms_started == 1 else 0.0
	if next_index == last_regular_index():
		need += _need(StoryBeatData.Moment.BEFORE_LAST_WAVE)
	return need


## Lo que cuenta la historia en la calma antes de la final: la reunión y lo de antes de la final.
func _finale_story() -> float:
	return _need(StoryBeatData.Moment.AFTER_LAST_WAVE) + _need(StoryBeatData.Moment.BEFORE_FINALE)


## Suelta `count` videos desde `now`, uno cada video_accept_seconds. El primero llega a más tardar a tiempo para
## descargarlo antes de la ola siguiente (next_at), o enseguida si la calma es corta: un video nunca cae encima de una
## ola.
func _release_videos(now: float, count: int, beat: Beat) -> void:
	count = mini(count, videos_left)
	var latest := next_at - _balance.video_accept_seconds - _balance.download_seconds
	var time := clampf(now + _calm_delay(), now, maxf(latest, now))
	for _index in count:
		beat.videos.append(time)
		time += _balance.video_accept_seconds
	videos_left -= count


## Si lo próximo de la ola es un video, llega a su hora: cuando a la consulta anterior le quedan video_time_left
## segundos o, si ya no queda ninguna consulta abierta, video_after_answer segundos después. Lo que sigue llega unos
## segundos después del video.
func _advance_video(now: float, active: int, beat: Beat) -> void:
	if pending.is_empty() or not pending[0]:
		return
	var wave := waves[wave_index]
	if active == 0 and not _answered:
		_answered = true
		next_at = minf(next_at, now + _rng.randf_range(wave.video_after_answer.x, wave.video_after_answer.y))
	if now < next_at:
		return
	pending.pop_front()
	_answered = false
	beat.videos.append(now)
	next_at = now + _rng.randf_range(wave.spacing.x, wave.spacing.y)


func _queue_scare(time: float, creature: bool) -> void:
	var index := scare_times.bsearch(time, false)
	scare_times.insert(index, time)
	scare_creature.insert(index, creature)


static func _insert(times: Array[float], time: float) -> void:
	times.insert(times.bsearch(time, false), time)


func _wave_delay() -> float:
	return _rng.randf_range(_balance.wave_event_delay.x, _balance.wave_event_delay.y)


func _calm_delay() -> float:
	return _rng.randf_range(_balance.calm_event_delay.x, _balance.calm_event_delay.y)
