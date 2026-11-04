extends RefCounted
## El director de ritmo (diseño §14 y decisiones de Benja, sesión 16): decide cuándo llega cada solicitud.
## Las solicitudes llegan en olas de NightData.wave_size, y después de cada ola hay un respiro sin solicitudes
## nuevas. Se aprietan hacia las 06:00. Si una llega tarde (no había a quién dársela) o un amigo queda herido,
## las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00.
## Lógica pura: RequestManager la consulta en cada paso.

## Las horas de las solicitudes que faltan, en segundos desde las 00:00 y en orden.
var request_times: Array[float] = []
## La hora en que empezó la última solicitud.
var last_request := -INF

var _balance: BalanceData


func _init(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	request_times = plan_requests(night, balance, rng)


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
