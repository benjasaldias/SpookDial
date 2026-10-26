class_name EntityData
extends Resource
## Una entidad del folclore y su página del cuaderno. Todo lo de la entidad vive en este .tres.
## Las reglas van en orden: se aplica la primera que se cumple, y la última no tiene condiciones.

@export var id: StringName
## Clave del nombre en notebook.csv. Los amigos nunca lo dicen; aparece al identificarla.
@export var name_key: String
## Clave del folclore (2 a 4 líneas) en notebook.csv.
@export var lore_key: String
@export var sketch: Texture2D
## Claves de los lugares donde aparece, en messages.csv.
@export var place_keys: Array[String] = []
## Entre 2 y 4.
@export var traits: Array[TraitData] = []
## Exactamente 4.
@export var actions: Array[ActionData] = []
## 2 o 3.
@export var observations: Array[ObservationData] = []
## Hasta 3 con condiciones, más "en cualquier otro caso" al final.
@export var rules: Array[RuleData] = []


func find_action(action_id: StringName) -> ActionData:
	for action: ActionData in actions:
		if action != null and action.id == action_id:
			return action
	return null


func find_observation(observation_id: StringName) -> ObservationData:
	for observation: ObservationData in observations:
		if observation != null and observation.id == observation_id:
			return observation
	return null
