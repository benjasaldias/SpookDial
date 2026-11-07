extends RefCounted
## Qué screamer toca, cuánto resta y si es justo (diseño §11). Los ambientales asustan con un objeto del
## escritorio, así que solo se eligen si ese objeto está a la vista, y los del cuaderno, si está abierto. Las
## luces se ven siempre. Lógica pura: ScreamerManager elige con ella, y el escritorio dice qué se ve.

## pick() no encontró ninguno justo: hay que esperar.
const NONE := -1


## Lo que se ve del escritorio cuando toca un screamer.
class View:
	## La cortina, la ventana y el celular del escritorio: los tapan el chat, el mixer y el celular ampliado.
	var desk_visible := true
	var notebook_open := false
	## El cuaderno muestra la página de una entidad, no el índice: la tinta tiene reglas que tapar.
	var notebook_page := false
	## El chat o el mixer están abiertos: tapan la ventana, y la criatura se arma detrás (decisión de Benja, 4
	## de noviembre).
	var panel_open := false
	## Las cortinas tapan la ventana: no se ve nada afuera.
	var curtains_closed := false


## Los screamers que se pueden elegir con lo que se ve. El jumpscare va aparte: lo decide el director.
static func candidates(view: View) -> Array[ScareKind.Kind]:
	var kinds: Array[ScareKind.Kind] = [ScareKind.Kind.LIGHTS]
	if view.desk_visible:
		kinds.append(ScareKind.Kind.CURTAINS)
		if not view.curtains_closed:
			kinds.append(ScareKind.Kind.WINDOW)
		kinds.append(ScareKind.Kind.PHONE)
	if view.notebook_open:
		kinds.append(ScareKind.Kind.NOTEBOOK_SLAM)
		if view.notebook_page:
			kinds.append(ScareKind.Kind.INK)
	return kinds


## Sanity que resta: el jumpscare, más que los demás (docs/02 §6).
static func sanity_cost(kind: ScareKind.Kind, balance: BalanceData) -> float:
	return balance.jumpscare_sanity if kind == ScareKind.Kind.JUMPSCARE else balance.scare_sanity


## Segundos que el screamer tapa algo mientras la noche sigue: la tinta tapa las reglas. La criatura de la
## ventana no tapa nada.
static func blocking_seconds(kind: ScareKind.Kind, balance: BalanceData) -> float:
	return balance.ink_seconds if kind == ScareKind.Kind.INK else 0.0


## Es justo si a ninguna decisión en curso (`time_lefts`) le quedan scare_margin segundos o menos cuando
## terminen la señal previa y lo que el screamer tapa (diseño §11).
static func is_fair(kind: ScareKind.Kind, time_lefts: Array, balance: BalanceData) -> bool:
	var needed := balance.scare_margin + balance.scare_warning + blocking_seconds(kind, balance)
	for time_left: float in time_lefts:
		if time_left <= needed:
			return false
	return true


## Un screamer al azar entre los que se ven y son justos; si toca el jumpscare, solo él. NONE si ninguno es
## justo.
static func pick(view: View, jumpscare: bool, time_lefts: Array, balance: BalanceData,
		rng: RandomNumberGenerator) -> int:
	var kinds: Array[ScareKind.Kind] = []
	if jumpscare:
		# La criatura solo se arma detrás de un panel (el chat o el mixer): se ve al cerrarlo.
		if view.panel_open:
			kinds.append(ScareKind.Kind.JUMPSCARE)
	else:
		kinds = candidates(view)
	var fair := kinds.filter(func(kind: ScareKind.Kind) -> bool: return is_fair(kind, time_lefts, balance))
	if fair.is_empty():
		return NONE
	return fair[rng.randi_range(0, fair.size() - 1)]
