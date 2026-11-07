extends RefCounted
## El director de ritmo (diseño §11 y §14, y decisiones de Benja, sesión 16): decide cuándo llega cada
## solicitud y cada screamer.
## Las solicitudes llegan en olas de NightData.wave_size, y después de cada ola hay un respiro sin solicitudes
## nuevas. Se aprietan hacia las 06:00. Si una llega tarde (no había a quién dársela) o un amigo queda herido,
## las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00.
## Los screamers llegan en cualquier momento, repartidos en la noche, y algunos son el jumpscare. El susto
## guionado espera un momento sin solicitudes. Las reglas de justicia las revisa Screamer al elegir cuál.
## Los accidentes también se reparten en la noche (decisión de Benja, 7 de noviembre).
## Lógica pura: RequestManager la consulta para las solicitudes y ScreamerManager, para los screamers.

## Las horas de las solicitudes que faltan, en segundos desde las 00:00 y en orden.
var request_times: Array[float] = []
## La hora en que empezó la última solicitud.
var last_request := -INF
## Las horas de los screamers que faltan, sin el guionado, en orden.
var scare_times: Array[float] = []
## Cuáles de los screamers que faltan son el jumpscare, contados desde el próximo (0).
var jumpscare_slots: Array[int] = []
## La hora del susto guionado, o -1 si no hay o ya pasó.
var scripted_scare_time := -1.0
## La hora en que empezó el último screamer.
var last_scare := -INF
## Las horas de los accidentes que faltan, en orden.
var incident_times: Array[float] = []

var _balance: BalanceData


func _init(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	request_times = plan_requests(night, balance, rng)
	scare_times = plan_scares(night.scare_count, balance, rng)
	jumpscare_slots = plan_jumpscares(night.creature_visits, scare_times.size(), rng)
	if night.scripted_scare_time > 0.0:
		scripted_scare_time = night.scripted_scare_time
	incident_times = plan_scares(night.incident_count, balance, rng)


## Las horas de las solicitudes de la noche. La primera llega a los first_request_delay segundos y la última,
## justo a tiempo para responderla antes de las 06:00. Entre ellas, los espacios se acortan parejo hasta
## (1 − wave_tightening) del primero, con algo de azar, y después de cada ola se suma un respiro.
static func plan_requests(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> Array[float]:
	var times: Array[float] = []
	var count := night.requests_total
	if count <= 0:
		return times
	var start := balance.first_request_delay
	times.append(start)
	var wave_size := maxi(night.wave_size, 1)
	var gaps: Array[float] = []
	var total := 0.0
	var respites := 0
	for index in count - 1:
		var gap := (1.0 - balance.wave_tightening * index / maxf(count - 2, 1)) * rng.randf_range(0.85, 1.15)
		gaps.append(gap)
		total += gap
		if (index + 1) % wave_size == 0:
			respites += 1
	var end := balance.night_seconds - night.base_decision_time
	var free := maxf(end - start - respites * balance.wave_respite, 0.0)
	var time := start
	for index in gaps.size():
		time += gaps[index] / total * free
		if (index + 1) % wave_size == 0:
			time += balance.wave_respite
		times.append(time)
	return times


## Toca empezar una solicitud: llegó su hora y pasaron request_min_gap segundos desde la anterior. Si ya no
## alcanza a terminar antes de las 06:00 (dura `decision_seconds`), no llegan más.
func request_due(now: float, decision_seconds: float) -> bool:
	if request_times.is_empty() or now < request_times[0] or now - last_request < _balance.request_min_gap:
		return false
	if now + decision_seconds > _balance.night_seconds:
		request_times.clear()
		return false
	return true


## Empezó la solicitud que tocaba. Si llegó tarde, las que faltan se atrasan lo mismo: así no se juntan.
func request_started(now: float) -> void:
	if request_times.is_empty():
		return
	var late := maxf(now - request_times.pop_front(), 0.0)
	last_request = now
	delay(late)


## Un amigo quedó herido: las solicitudes que faltan se atrasan hurt_respite segundos (decisión de Benja).
func friend_hurt() -> void:
	delay(_balance.hurt_respite)


## Atrasa `seconds` las solicitudes que faltan.
func delay(seconds: float) -> void:
	for index in request_times.size():
		request_times[index] += seconds


## Las horas de `count` screamers: uno por tramo igual de la noche, después de first_scare_after, a una hora al
## azar lejos de los bordes del tramo. Así llegan en cualquier momento (decisión de Benja), pero nunca
## demasiado seguidos.
static func plan_scares(count: int, balance: BalanceData, rng: RandomNumberGenerator) -> Array[float]:
	var times: Array[float] = []
	if count <= 0:
		return times
	var span := (balance.night_seconds - balance.first_scare_after) / count
	for index in count:
		times.append(balance.first_scare_after + span * (index + rng.randf_range(0.2, 0.8)))
	return times


## Cuáles de `scare_count` screamers son el jumpscare: `visits` al azar, sin pasar de los que hay.
static func plan_jumpscares(visits: int, scare_count: int, rng: RandomNumberGenerator) -> Array[int]:
	var slots: Array[int] = []
	for index in scare_count:
		slots.append(index)
	for index in range(slots.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := slots[index]
		slots[index] = slots[other]
		slots[other] = swap
	return slots.slice(0, mini(visits, scare_count))


## Toca un screamer: llegó su hora y pasaron scare_min_gap segundos desde el anterior.
func scare_due(now: float) -> bool:
	return not scare_times.is_empty() and now >= scare_times[0] and now - last_scare >= _balance.scare_min_gap


## El próximo screamer es el jumpscare.
func next_is_jumpscare() -> bool:
	return jumpscare_slots.has(0)


## Empezó el screamer que tocaba.
func scare_started(now: float) -> void:
	if scare_times.is_empty():
		return
	scare_times.pop_front()
	var slots: Array[int] = []
	for slot: int in jumpscare_slots:
		if slot > 0:
			slots.append(slot - 1)
	jumpscare_slots = slots
	last_scare = now


## Toca un accidente: llegó su hora.
func incident_due(now: float) -> bool:
	return not incident_times.is_empty() and now >= incident_times[0]


## Empezó el accidente que tocaba.
func incident_started() -> void:
	incident_times.pop_front()


## Toca el susto guionado: llegó su hora y no hay solicitudes activas.
func scripted_scare_due(now: float, active_requests: int) -> bool:
	return scripted_scare_time > 0.0 and now >= scripted_scare_time and active_requests == 0


## Empezó el susto guionado. Cuenta como screamer: el siguiente espera scare_min_gap segundos.
func scripted_scare_started(now: float) -> void:
	scripted_scare_time = -1.0
	last_scare = now
