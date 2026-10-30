extends RefCounted
## Una solicitud de un amigo (docs/02 §2): la entidad, la situación y lo que el jugador va descubriendo.
## Lógica pura: RequestManager la avanza en el tiempo y el chat la muestra.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

enum Identification { PENDING, THINKING, REVEALED }
## Estado de una frase clickeable en esta solicitud.
enum ClueState { UNMARKED, MARKED, DECOY }

## Segundos del temporizador que cuesta una pregunta (docs/02 §3.2).
const QUESTION_COST := 5.0
## Segundos que Matías piensa antes de que aparezca el nombre de la entidad (docs/02 §3.1).
const THINKING_TIME := 3.0

var friend_index := 0
var entity: EntityData
var place_key := ""
## id de observación → valor en esta solicitud.
var situation: Dictionary = {}
## Las 2 características del mensaje inicial. Para identificar la entidad hay que marcar las dos.
var traits: Array[TraitData] = []
var decoys: Array[DecoyData] = []
## Las características y los señuelos, en el orden en que aparecen en el mensaje inicial.
var first_clues: Array[TraitData] = []
## Observaciones que trae el mensaje inicial; las demás hay que preguntarlas.
var first_observations: Array[ObservationData] = []
## Segundos que quedan para responder.
var time_left := 0.0
var identification := Identification.PENDING
var thinking_left := 0.0
var finished := false
## Al terminar: la acción elegida, si la eligió el jugador (false: el amigo decidió solo) y el resultado.
var chosen_action: ActionData
var answered_by_player := false
var outcome := RuleEvaluator.Outcome.WRONG

var _clue_states := {}  # id de una frase clickeable → ClueState


func clue_state(clue_id: StringName) -> ClueState:
	return _clue_states.get(clue_id, ClueState.UNMARKED)


func marked_count() -> int:
	var count := 0
	for trait_data: TraitData in traits:
		if clue_state(trait_data.id) == ClueState.MARKED:
			count += 1
	return count


## Clic en una frase: una característica queda marcada y un señuelo, en rojo.
## Al marcar las 2 características, Matías empieza a pensar. Devuelve el estado de la frase.
func click_clue(clue_id: StringName) -> ClueState:
	if finished:
		return clue_state(clue_id)
	if _has_clue(traits, clue_id):
		_clue_states[clue_id] = ClueState.MARKED
		if identification == Identification.PENDING and marked_count() == traits.size():
			identification = Identification.THINKING
			thinking_left = THINKING_TIME
	elif _has_clue(decoys, clue_id):
		_clue_states[clue_id] = ClueState.DECOY
	return clue_state(clue_id)


## Con 5 segundos o menos ya no se puede preguntar: el amigo no alcanza a mirar (decisión de Benja).
func can_ask() -> bool:
	return not finished and time_left > QUESTION_COST


## Descuenta el costo de una pregunta. Devuelve false si ya no se puede preguntar.
func pay_question() -> bool:
	if not can_ask():
		return false
	time_left -= QUESTION_COST
	return true


## Avanza `delta` segundos. Devuelve true si en este paso apareció el nombre de la entidad.
func advance(delta: float) -> bool:
	if finished:
		return false
	time_left = maxf(time_left - delta, 0.0)
	if identification != Identification.THINKING:
		return false
	thinking_left -= delta
	if thinking_left > 0.0:
		return false
	identification = Identification.REVEALED
	return true


func is_out_of_time() -> bool:
	return not finished and time_left <= 0.0


## Termina la solicitud con `action`. `by_player` es false si el amigo decidió solo.
func finish(action: ActionData, by_player: bool) -> void:
	finished = true
	chosen_action = action
	answered_by_player = by_player
	outcome = RuleEvaluator.outcome(entity, situation, action)


## Sin respuesta a tiempo, el amigo elige al azar entre las 4 acciones (docs/02 §2).
func decide_alone(rng: RandomNumberGenerator) -> void:
	finish(entity.actions[rng.randi_range(0, entity.actions.size() - 1)], false)


static func _has_clue(clues: Array, clue_id: StringName) -> bool:
	for clue: TraitData in clues:
		if clue.id == clue_id:
			return true
	return false
