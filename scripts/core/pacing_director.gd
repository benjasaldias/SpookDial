extends RefCounted
## El director de ritmo (diseño §5 y §11; decisiones de Benja, 2 y 11 de noviembre): decide cuándo llega cada
## solicitud y qué pasa en cada momento de la noche.
## La noche empieza con un minuto de silencio. Después llegan olas: las solicitudes de una ola llegan juntas, con pocos
## segundos de diferencia, y cuando se resuelven todas viene una calma de verdad. Las olas están planeadas parejo hasta
## la ola final, la más grande, que llega lo más tarde posible para que se alcance a responder antes de las 06:00: es
## el clímax de la noche. Una ola que ya no cabe antes de la final se salta.
## Las interferencias, los accidentes y la Mano caen en las olas; los videos y los screamers, en las calmas, y una
## visita de la criatura, en la ola final. Un amigo herido atrasa lo que falta, y nunca empieza una solicitud que no
## alcanza a terminar antes de las 06:00.
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
	var size := 0
	var finale := false
	## A qué hora le toca, si la anterior se resolvió a tiempo.
	var planned := 0.0
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
## A qué hora llega la ola final.
var finale_at := 0.0
## Desde qué hora puede empezar la próxima solicitud de la ola o, en el silencio y en las calmas, la próxima ola.
var next_at := 0.0
## Las solicitudes de la ola en curso que todavía no empiezan.
var left_in_wave := 0
## Los videos que todavía no se sueltan.
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

var _balance: BalanceData
var _rng: RandomNumberGenerator


func _init(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	_rng = rng
	videos_left = night.content_quota
	next_at = balance.first_wave_at
	if night.scripted_scare_time > 0.0:
		scripted_scare_time = night.scripted_scare_time
	_plan(night)


## A qué hora llega la ola final: lo más tarde posible para que su última solicitud alcance a terminar antes de las
## 06:00, aunque lleguen con el mayor espacio y aunque un amigo quede herido antes.
static func finale_time(night: NightData, balance: BalanceData) -> float:
	var size := mini(night.finale_size, night.requests_total)
	return balance.night_seconds - night.base_decision_time - maxi(size - 1, 0) * balance.wave_spacing.y \
			- balance.hurt_respite


## Avanza hasta `now`, con `active` solicitudes abiertas. Empieza la ola que toca o, cuando se resuelve la ola en
## curso, su calma. Devuelve lo que empezó.
func advance(now: float, active: int) -> Beat:
	var beat := Beat.new()
	match phase:
		Phase.SILENCE, Phase.CALM:
			if wave_index < waves.size() and now >= next_at:
				_start_wave(now, beat)
		Phase.WAVE:
			if left_in_wave <= 0 and active == 0:
				_start_calm(now, beat)
			elif _has_finale() and now >= finale_at:
				# La final llega a su hora, aunque la ola no se haya resuelto.
				wave_index = waves.size() - 1
				_start_wave(now, beat)
		Phase.FINALE:
			if left_in_wave <= 0:
				phase = Phase.DONE
	return beat


## Toca empezar una solicitud de la ola en curso. Si ya no alcanza a terminar antes de las 06:00 (dura
## `decision_seconds`), la ola se corta.
func request_due(now: float, decision_seconds: float) -> bool:
	if not (phase == Phase.WAVE or phase == Phase.FINALE) or left_in_wave <= 0 or now < next_at:
		return false
	if now + decision_seconds > _balance.night_seconds:
		left_in_wave = 0
		return false
	return true


## Empezó la solicitud que tocaba: la siguiente de la ola llega unos segundos después.
func request_started(now: float) -> void:
	left_in_wave -= 1
	last_request = now
	next_at = now + _rng.randf_range(_balance.wave_spacing.x, _balance.wave_spacing.y)


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
	finale_at = finale_time(night, _balance)
	var span := (finale_at - _balance.first_wave_at) / maxi(regular_count, 1)
	for index in regular_count:
		var wave := Wave.new()
		wave.size = mini(wave_size, regular - index * wave_size)
		wave.planned = _balance.first_wave_at + index * span
		waves.append(wave)
	var regular_waves := waves.duplicate()
	if finale_size > 0:
		var finale := Wave.new()
		finale.size = finale_size
		finale.finale = true
		finale.planned = finale_at
		finale.creature = night.creature_visits > 0
		waves.append(finale)
	_spread(night.interference_count, waves, "interferences", true)
	_spread(night.incident_count, regular_waves, "incidents", false)
	_spread(night.hand_visits, regular_waves, "hands", true)
	var creatures_in_calms := maxi(night.creature_visits - (1 if finale_size > 0 else 0), 0)
	_spread(maxi(night.scare_count - night.creature_visits, 0), regular_waves, "calm_scares", false)
	_spread(creatures_in_calms, regular_waves, "calm_creatures", true)


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
	left_in_wave = wave.size
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


## La ola se resolvió: empieza su calma, con sus videos y sus screamers. La ola siguiente llega después de la calma o
## a la hora que tenía planeada, la que sea más tarde. Si ya no cabe antes de la final, se salta.
func _start_calm(now: float, beat: Beat) -> void:
	var finished := waves[wave_index]
	phase = Phase.CALM
	beat.calm_started = true
	wave_index += 1
	next_at = now + _rng.randf_range(_balance.wave_calm.x, _balance.wave_calm.y)
	if wave_index < waves.size() and not waves[wave_index].finale:
		next_at = maxf(next_at, waves[wave_index].planned)
		if _has_finale() and next_at > finale_at - _balance.wave_calm.x:
			wave_index = waves.size() - 1
	if wave_index < waves.size() and waves[wave_index].finale:
		next_at = finale_at
	elif wave_index >= waves.size():
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
