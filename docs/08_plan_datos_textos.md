# Plan 2: Datos y textos — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que el contenido del juego exista como datos editables en el Inspector, con sus textos en CSV:

- clases `Resource` para las partes de una entidad, los amigos, las noches y un catálogo que lo reúne todo;
- un evaluador de reglas que dice qué regla se aplica y si una respuesta es correcta, de mayor riesgo o incorrecta;
- un validador que revisa el contenido real cada vez que se corren las pruebas;
- las traducciones `data/text/*.csv` con textos `[PROTO]`;
- El Trauco de ejemplo, los 3 amigos y las 5 noches como `.tres`.

**Arquitectura:**

- `scripts/data/`: clases `Resource` con `class_name`, para que el Inspector ofrezca "New TraitData", etc., y los arrays tipados funcionen. Es la primera vez que el proyecto usa `class_name`: la lógica pura sigue el patrón del Plan 1 (`preload` en una constante).
- `scripts/core/`: lógica pura sin nodos: `rule_evaluator.gd` y `content_validator.gd`.
- `data/`: `catalog.tres` → amigos (`data/friends/`) y noches (`data/nights/`) → entidades nuevas de cada noche (`data/entities/`). Cada entidad es **un solo `.tres`**, con sus características, acciones, observaciones y reglas dentro.
- `data/text/`: `messages.csv`, `notebook.csv` y `ui.csv`, con columnas `keys,es,en`.

**Stack:**

- Godot 4.7.2 (GDScript con tipado estático, arrays y diccionarios tipados).
- Las pruebas usan el ejecutor propio del Plan 1 y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §8, §12–14 y §18; `docs/02_bucle_central.md` §6–10.

---

## Decisiones técnicas de este plan

Tomadas en la sesión 6. Las que cambian `docs/02` §9–10 ya están actualizadas allí.

| Decisión | Por qué |
| --- | --- |
| **La frase clickeable de una característica va entre asteriscos:** `vio un *hombrecito* entre los árboles` (decisión de Benja). | Los corchetes chocaban con el prefijo `[PROTO]` y con el BBCode del chat. |
| Las reglas nombran las acciones **por id** (`correct_action_id = &"stare"`), igual que las condiciones nombran observaciones y valores. | En el Inspector se escribe un texto en vez de enlazar el mismo sub-recurso, que es fácil de romper. El validador revisa que cada id exista. |
| Responder desde la página equivocada es incorrecto aunque la otra entidad tenga una acción con el mismo id. | `outcome()` exige que la acción sea un objeto de la entidad real. |
| `ObservationData.values` es un diccionario **valor → clave de texto**. | Así cada valor y su texto se definen juntos, sin dos listas paralelas que se puedan desalinear. |
| Las observaciones tienen `question_key` y las reglas `text_key`. | El cuaderno (Plan 4) necesita mostrarlas. |
| Las entidades no tienen `intro_night`: cada `NightData` lista sus `new_entities`, y las conocidas en una noche son las nuevas de esa noche y de las anteriores. | Una sola fuente de verdad. |
| Un `ContentCatalog` (`data/catalog.tres`) lista amigos y noches. | Es seguro en el juego exportado, a diferencia de recorrer carpetas. |
| La columna `en` queda vacía. | Verificado en Godot 4.7.2: una celda vacía muestra el texto en español. |
| **(Corregido en S7)** Solo se registran los `.es.translation`. | Godot 4.7.2 no genera el `.en.translation` si la columna `en` está **entera** vacía. El idioma de respaldo `es` cubre el inglés, y el `.en` se registra en el Plan 8 con la opción de idioma. Los pasos 4 y 5 de la Tarea 7 y `test_translations.gd` ya usan solo `es`. |
| Los `.translation` generados no se suben a git. | Godot los regenera al importar; el `.csv.import` sí se sube. |
| El validador corre como prueba sobre el contenido real. | Si Benja deja una regla que nunca se aplica, una acción inexistente o un texto sin su clave, las pruebas lo dicen en español. |

**Formato verificado:** una prueba aparte en Godot 4.7.2 confirmó cómo se escriben en un `.tres` los arrays tipados (`Array[ExtResource("…")]([…])`) y los diccionarios tipados (`Dictionary[StringName, String]({…})`). También confirmó que el CSV se importa a `data/text/<archivo>.<idioma>.translation` y que `TranslationServer` traduce en las pruebas sin interfaz.

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado: si dos Godot escriben `.godot/` a la vez, se corrompe la caché (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `36 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Clases nuevas y caché:** Godot solo reconoce un `class_name` nuevo después de actualizar su caché de clases. Por eso, cada tarea que crea una clase la importa antes de correr las pruebas:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "ERROR|SCRIPT" ; echo "import listo"
```

Esperado: solo `import listo`. Si aparece `SCRIPT ERROR`, el script tiene un error de sintaxis: corregirlo y volver a importar.

**Commits:** cada tarea termina en un commit, pero Claude **pregunta a Benja antes de cada uno**, salvo que Benja autorice de una vez todos los commits del plan al empezar (`CLAUDE.md`, regla 11). El push solo se hace con su autorización.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/clue_category.gd` | Enum `ClueCategory.Kind`: Vista, Sonido, Ambiente o Rastro |
| `scripts/data/trait_data.gd` | `TraitData`: característica fija y clickeable |
| `scripts/data/action_data.gd` | `ActionData`: una de las 4 acciones de una entidad |
| `scripts/data/observation_data.gd` | `ObservationData`: dato que cambia en cada situación |
| `scripts/data/rule_data.gd` | `RuleData`: condiciones y acciones correcta y de mayor riesgo |
| `scripts/data/entity_data.gd` | `EntityData`: una entidad y su página del cuaderno |
| `scripts/data/friend_data.gd` | `FriendData`: uno de los 3 amigos |
| `scripts/data/night_data.gd` | `NightData`: parámetros de una noche |
| `scripts/data/content_catalog.gd` | `ContentCatalog`: amigos y noches; entidades conocidas por noche |
| `scripts/core/rule_evaluator.gd` | Regla que se aplica, resultado de una respuesta y todas las situaciones posibles |
| `scripts/core/content_validator.gd` | Errores de diseño del contenido, en español |
| `test/content_fixtures.gd` | Entidad y catálogo mínimos armados en código, para las pruebas |
| `test/test_case.gd` | Se agrega `check_contains()` |
| `test/test_*.gd` | Pruebas de cada tarea |
| `data/text/messages.csv`, `notebook.csv`, `ui.csv` | Textos en español (y en inglés más adelante) |
| `project.godot` | Registro de las traducciones e idioma de respaldo |
| `.gitignore` | Ignorar los `.translation` generados |
| `data/entities/trauco.tres` | El Trauco de ejemplo (formato de `docs/02` §8) |
| `data/friends/*.tres`, `data/nights/night_*.tres`, `data/catalog.tres` | Amigos, noches y catálogo |

---

### Tarea 1: Las partes de una entidad

**Archivos:**

- Crear: `scripts/data/clue_category.gd`, `scripts/data/trait_data.gd`, `scripts/data/action_data.gd`, `scripts/data/observation_data.gd`, `scripts/data/rule_data.gd`
- Probar: `test/test_data_parts.gd`

- [ ] **Paso 1: Escribir las pruebas**

`test/test_data_parts.gd`:

```gdscript
extends "res://test/test_case.gd"


func _rule(conditions: Dictionary) -> RuleData:
	var rule := RuleData.new()
	for observation_id: StringName in conditions:
		rule.conditions[observation_id] = conditions[observation_id]
	return rule


func test_observacion_conserva_el_orden_de_sus_valores() -> bool:
	var observation := ObservationData.new()
	observation.values = {&"friend": "K_FRIEND", &"trauco": "K_TRAUCO"}
	var ids := observation.value_ids()
	check_eq(ids.size(), 2, "cantidad de valores")
	check_eq(ids[0], &"friend", "primer valor")
	check_eq(ids[1], &"trauco", "segundo valor")
	check(observation.has_value(&"trauco"), "tiene trauco")
	check(not observation.has_value(&"nobody"), "no tiene nobody")
	return true


func test_regla_se_cumple_con_todas_sus_condiciones() -> bool:
	var rule := _rule({&"saw_first": &"trauco", &"axe": &"yes"})
	check(rule.matches({&"saw_first": &"trauco", &"axe": &"yes", &"chopping": &"no"}),
			"se cumple; las demás observaciones no importan")
	return true


func test_regla_no_se_cumple_si_falta_o_difiere_un_valor() -> bool:
	var rule := _rule({&"saw_first": &"trauco", &"axe": &"yes"})
	check(not rule.matches({&"saw_first": &"trauco", &"axe": &"no"}), "difiere el hacha")
	check(not rule.matches({&"saw_first": &"trauco"}), "falta el hacha")
	return true


func test_regla_sin_condiciones_se_cumple_siempre() -> bool:
	var rule := RuleData.new()
	check(rule.is_default(), "es la regla por defecto")
	check(rule.matches({}), "situación vacía")
	check(rule.matches({&"axe": &"no"}), "cualquier situación")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_data_parts.gd :: no se pudo cargar` y `36 pruebas OK, 1 fallidas` (las clases todavía no existen).

- [ ] **Paso 3: Escribir las clases**

`scripts/data/clue_category.gd`:

```gdscript
class_name ClueCategory
extends RefCounted
## Categoría de una característica u observación. Cada una corresponde a una pregunta:
## Vista = "¿Qué ves?", Sonido = "¿Qué oyes?", Ambiente = "¿Cómo está el ambiente?", Rastro = "¿Hay rastros?".

enum Kind { SIGHT, SOUND, ENVIRONMENT, TRACES }
```

`scripts/data/trait_data.gd`:

```gdscript
class_name TraitData
extends Resource
## Característica fija de una entidad: aparece destacada en los mensajes y se clickea para identificarla.
## Dos entidades comparten una característica si usan el mismo id.

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave del fragmento en messages.csv. La frase clickeable va entre asteriscos: "vio un *hombrecito*".
@export var text_key: String
```

`scripts/data/action_data.gd`:

```gdscript
class_name ActionData
extends Resource
## Una de las 4 acciones propias de una entidad. Es un botón de respuesta del chat.

@export var id: StringName
## Clave del texto del botón en notebook.csv.
@export var label_key: String
```

`scripts/data/observation_data.gd`:

```gdscript
class_name ObservationData
extends Resource
## Dato que cambia en cada situación y decide qué regla se aplica (por ejemplo, quién vio a quién primero).

@export var id: StringName
@export var category: ClueCategory.Kind = ClueCategory.Kind.SIGHT
## Clave de la pregunta en notebook.csv, por ejemplo "¿Quién vio a quién primero?".
@export var question_key: String
## Cada valor posible → clave de su fragmento en messages.csv. Se conserva el orden del Inspector.
@export var values: Dictionary[StringName, String] = {}


func has_value(value: StringName) -> bool:
	return values.has(value)


func value_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(values.keys())
	return ids
```

`scripts/data/rule_data.gd`:

```gdscript
class_name RuleData
extends Resource
## Regla de una página del cuaderno. Se cumple si se cumplen todas sus condiciones.
## Sin condiciones es "en cualquier otro caso", y debe ser la última de la página.

## id de observación → valor que debe tener.
@export var conditions: Dictionary[StringName, StringName] = {}
## id de la acción correcta (una de las 4 de la entidad).
@export var correct_action_id: StringName
## id de la acción de mayor riesgo: da un video extra si el amigo sobrevive.
@export var risky_action_id: StringName
## Clave del texto de la regla en notebook.csv.
@export var text_key: String


func is_default() -> bool:
	return conditions.is_empty()


## `situation`: id de observación → valor en esta solicitud.
func matches(situation: Dictionary) -> bool:
	for observation_id: StringName in conditions:
		if situation.get(observation_id) != conditions[observation_id]:
			return false
	return true
```

- [ ] **Paso 4: Importar y correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "ERROR|SCRIPT" ; echo "import listo"
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `import listo` y `40 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/data test/test_data_parts.gd test/test_data_parts.gd.uid
git commit -m "Clases de datos: característica, acción, observación y regla" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: EntityData y evaluador de reglas

**Archivos:**

- Crear: `scripts/data/entity_data.gd`, `scripts/core/rule_evaluator.gd`, `test/content_fixtures.gd`
- Probar: `test/test_rule_evaluator.gd`

- [ ] **Paso 1: Escribir los datos de prueba**

`test/content_fixtures.gd` (el ejecutor no lo corre como suite, porque no empieza con `test_`):

```gdscript
extends RefCounted
## Contenido mínimo y válido, armado en código, para probar el evaluador y el validador.
## No es contenido del juego.


## Entidad válida: 2 características, 4 acciones (a1 a a4), 2 observaciones (o1 y o2, con yes/no) y 3 reglas:
##   1. o1 = yes → correcta a1, mayor riesgo a2
##   2. o2 = yes → correcta a3, mayor riesgo a4
##   3. en cualquier otro caso → correcta a2, mayor riesgo a3
static func make_entity(entity_id: StringName = &"beast") -> EntityData:
	var entity := EntityData.new()
	entity.id = entity_id
	entity.name_key = "K_%s_NAME" % entity_id
	entity.lore_key = "K_%s_LORE" % entity_id
	entity.place_keys = ["K_PLACE"]
	for i in 2:
		entity.traits.append(make_trait(StringName("%s_trait_%d" % [entity_id, i + 1])))
	for i in 4:
		var action := ActionData.new()
		action.id = StringName("a%d" % (i + 1))
		action.label_key = "K_%s_A%d" % [entity_id, i + 1]
		entity.actions.append(action)
	for i in 2:
		var observation := ObservationData.new()
		observation.id = StringName("o%d" % (i + 1))
		observation.question_key = "K_%s_O%d_Q" % [entity_id, i + 1]
		observation.values = {
			&"yes": "K_%s_O%d_YES" % [entity_id, i + 1],
			&"no": "K_%s_O%d_NO" % [entity_id, i + 1],
		}
		entity.observations.append(observation)
	entity.rules.append(make_rule({&"o1": &"yes"}, &"a1", &"a2"))
	entity.rules.append(make_rule({&"o2": &"yes"}, &"a3", &"a4"))
	entity.rules.append(make_rule({}, &"a2", &"a3"))
	return entity


static func make_trait(trait_id: StringName, category := ClueCategory.Kind.SIGHT) -> TraitData:
	var trait_data := TraitData.new()
	trait_data.id = trait_id
	trait_data.category = category
	trait_data.text_key = "K_TRAIT_%s" % trait_id
	return trait_data


static func make_rule(conditions: Dictionary, correct: StringName, risky: StringName) -> RuleData:
	var rule := RuleData.new()
	for observation_id: StringName in conditions:
		rule.conditions[observation_id] = conditions[observation_id]
	rule.correct_action_id = correct
	rule.risky_action_id = risky
	rule.text_key = "K_RULE"
	return rule
```

- [ ] **Paso 2: Escribir las pruebas**

`test/test_rule_evaluator.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


func test_se_aplica_la_primera_regla_que_se_cumple() -> bool:
	var entity := Fixtures.make_entity()
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"yes", &"o2": &"yes"}), entity.rules[0],
			"se cumplen la 1 y la 2: gana la 1")
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"yes"}), entity.rules[1], "solo la 2")
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"no"}), entity.rules[2],
			"en cualquier otro caso")
	return true


func test_sin_regla_que_se_cumpla_devuelve_null() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules.pop_back()
	check_eq(RuleEvaluator.applicable_rule(entity, {&"o1": &"no", &"o2": &"no"}), null, "sin regla por defecto")
	return true


func test_resultado_correcto_riesgoso_e_incorrecto() -> bool:
	var entity := Fixtures.make_entity()
	var situation := {&"o1": &"yes", &"o2": &"no"}
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a1")), RuleEvaluator.Outcome.CORRECT, "a1")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a2")), RuleEvaluator.Outcome.RISKY, "a2")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a3")), RuleEvaluator.Outcome.WRONG, "a3")
	check_eq(RuleEvaluator.outcome(entity, situation, entity.find_action(&"a4")), RuleEvaluator.Outcome.WRONG, "a4")
	check_eq(RuleEvaluator.outcome(entity, situation, null), RuleEvaluator.Outcome.WRONG, "sin acción")
	return true


func test_accion_de_otra_pagina_es_incorrecta() -> bool:
	var entity := Fixtures.make_entity(&"beast")
	var other_page := Fixtures.make_entity(&"ghost")
	# Las dos entidades tienen una acción "a1", pero responder desde la página de ghost es un error.
	var answer := other_page.find_action(&"a1")
	check_eq(RuleEvaluator.outcome(entity, {&"o1": &"yes", &"o2": &"no"}, answer), RuleEvaluator.Outcome.WRONG,
			"página equivocada")
	return true


func test_todas_las_situaciones() -> bool:
	var situations := RuleEvaluator.all_situations(Fixtures.make_entity())
	check_eq(situations.size(), 4, "2 observaciones × 2 valores")
	for expected: Dictionary in [
		{&"o1": &"yes", &"o2": &"yes"},
		{&"o1": &"yes", &"o2": &"no"},
		{&"o1": &"no", &"o2": &"yes"},
		{&"o1": &"no", &"o2": &"no"},
	]:
		check(situations.has(expected), "falta la situación %s" % expected)
	return true
```

- [ ] **Paso 3: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_rule_evaluator.gd :: no se pudo cargar` y `40 pruebas OK, 1 fallidas`.

- [ ] **Paso 4: Escribir `EntityData` y el evaluador**

`scripts/data/entity_data.gd`:

```gdscript
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
```

`scripts/core/rule_evaluator.gd`:

```gdscript
extends RefCounted
## Aplica las reglas de una entidad a una situación. Lógica pura, sin nodos.
## Una situación es un Dictionary: id de observación → valor en esta solicitud.

enum Outcome { CORRECT, RISKY, WRONG }


## La primera regla que se cumple, o null si ninguna (la entidad está mal armada).
static func applicable_rule(entity: EntityData, situation: Dictionary) -> RuleData:
	for rule: RuleData in entity.rules:
		if rule.matches(situation):
			return rule
	return null


## Resultado de responder `action`. Una acción de otra página es incorrecta aunque tenga el mismo id.
static func outcome(entity: EntityData, situation: Dictionary, action: ActionData) -> Outcome:
	var rule := applicable_rule(entity, situation)
	if rule == null or not entity.actions.has(action):
		return Outcome.WRONG
	if action.id == rule.correct_action_id:
		return Outcome.CORRECT
	if action.id == rule.risky_action_id:
		return Outcome.RISKY
	return Outcome.WRONG


## Todas las situaciones posibles: cada combinación de valores de las observaciones.
static func all_situations(entity: EntityData) -> Array[Dictionary]:
	var situations: Array[Dictionary] = [{}]
	for observation: ObservationData in entity.observations:
		var expanded: Array[Dictionary] = []
		for situation: Dictionary in situations:
			for value: StringName in observation.value_ids():
				var next := situation.duplicate()
				next[observation.id] = value
				expanded.append(next)
		situations = expanded
	return situations
```

- [ ] **Paso 5: Importar y correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "ERROR|SCRIPT" ; echo "import listo"
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `import listo` y `45 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/data scripts/core test/content_fixtures.gd* test/test_rule_evaluator.gd*
git commit -m "EntityData y evaluador de reglas" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: Amigos, noches y catálogo

**Archivos:**

- Crear: `scripts/data/friend_data.gd`, `scripts/data/night_data.gd`, `scripts/data/content_catalog.gd`
- Modificar: `test/content_fixtures.gd` (agregar `make_catalog()`)
- Probar: `test/test_night_and_catalog.gd`

- [ ] **Paso 1: Agregar el catálogo de prueba**

Al final de `test/content_fixtures.gd`:

```gdscript


## Catálogo válido: 3 amigos y 5 noches; "beast" aparece la noche 1 y "ghost" la noche 2.
static func make_catalog() -> ContentCatalog:
	var catalog := ContentCatalog.new()
	for friend_id: StringName in [&"leon", &"gonzalo", &"agustin"]:
		var friend := FriendData.new()
		friend.id = friend_id
		friend.name_key = "K_FRIEND_%s" % friend_id
		catalog.friends.append(friend)
	for number in range(1, 6):
		var night := NightData.new()
		night.number = number
		night.place_key = "K_NIGHT_%d" % number
		catalog.nights.append(night)
	catalog.nights[0].new_entities.append(make_entity(&"beast"))
	catalog.nights[1].new_entities.append(make_entity(&"ghost"))
	return catalog
```

- [ ] **Paso 2: Escribir las pruebas**

`test/test_night_and_catalog.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")


func _ids(entities: Array[EntityData]) -> Array:
	return entities.map(func(entity: EntityData) -> StringName: return entity.id)


func test_observaciones_del_primer_mensaje() -> bool:
	var night := NightData.new()
	check_eq(night.observations_in_first_message(3), 3, "todas")
	night.first_message_observations = NightData.FirstMessageObservations.ALL_BUT_ONE
	check_eq(night.observations_in_first_message(3), 2, "todas menos 1, de 3")
	check_eq(night.observations_in_first_message(2), 1, "todas menos 1, de 2")
	night.first_message_observations = NightData.FirstMessageObservations.ONE
	check_eq(night.observations_in_first_message(3), 1, "una")
	return true


func test_entidades_conocidas_se_acumulan() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(_ids(catalog.known_entities(1)), [&"beast"], "noche 1")
	check_eq(_ids(catalog.known_entities(2)), [&"beast", &"ghost"], "noche 2")
	check_eq(_ids(catalog.known_entities(5)), [&"beast", &"ghost"], "noche 5")
	return true


func test_todas_las_entidades() -> bool:
	check_eq(_ids(Fixtures.make_catalog().all_entities()), [&"beast", &"ghost"], "todas")
	return true
```

- [ ] **Paso 3: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `test_night_and_catalog.gd :: no se pudo cargar`. `test_rule_evaluator.gd` también puede fallar al cargar, porque `content_fixtures.gd` ya nombra clases que no existen.

- [ ] **Paso 4: Escribir las clases**

`scripts/data/friend_data.gd`:

```gdscript
class_name FriendData
extends Resource
## Uno de los 3 amigos. Su personalidad es solo de sabor: no cambia las reglas.

@export var id: StringName
## Clave del nombre en ui.csv.
@export var name_key: String
@export var avatar: Texture2D
## Color de su nombre y de su pestaña en el chat.
@export var color := Color.WHITE
```

`scripts/data/night_data.gd`:

```gdscript
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


## Cuántas observaciones trae el mensaje inicial de una entidad que tiene `total`.
func observations_in_first_message(total: int) -> int:
	match first_message_observations:
		FirstMessageObservations.ALL_BUT_ONE:
			return total - 1
		FirstMessageObservations.ONE:
			return 1
	return total
```

`scripts/data/content_catalog.gd`:

```gdscript
class_name ContentCatalog
extends Resource
## Índice de todo el contenido (data/catalog.tres). Una entidad entra al juego
## cuando se agrega a las entidades nuevas de una noche.

@export var friends: Array[FriendData] = []
## En orden, de la noche 1 a la 5.
@export var nights: Array[NightData] = []


## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores.
func known_entities(night_number: int) -> Array[EntityData]:
	var known: Array[EntityData] = []
	for night: NightData in nights:
		if night.number <= night_number:
			known.append_array(night.new_entities)
	return known


func all_entities() -> Array[EntityData]:
	var entities: Array[EntityData] = []
	for night: NightData in nights:
		entities.append_array(night.new_entities)
	return entities
```

- [ ] **Paso 5: Importar y correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "ERROR|SCRIPT" ; echo "import listo"
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `import listo` y `48 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/data test/content_fixtures.gd test/test_night_and_catalog.gd*
git commit -m "Amigos, noches y catálogo de contenido" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Validador de una entidad

**Archivos:**

- Crear: `scripts/core/content_validator.gd`
- Modificar: `test/test_case.gd` (agregar `check_contains()`)
- Probar: `test/test_validator_entity.gd`

- [ ] **Paso 1: Agregar `check_contains()` a la base de las pruebas**

Al final de `test/test_case.gd`:

```gdscript


## Pasa si algún texto de `texts` contiene `fragment`.
func check_contains(texts: Array, fragment: String) -> void:
	for text: String in texts:
		if text.contains(fragment):
			return
	errors.append("ningún texto contiene <%s>: %s" % [fragment, str(texts)])
```

- [ ] **Paso 2: Escribir las pruebas**

`test/test_validator_entity.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_entidad_valida_no_tiene_errores() -> bool:
	var errors := ContentValidator.validate_entity(Fixtures.make_entity())
	check(errors.is_empty(), str(errors))
	return true


func test_cantidades() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions.pop_back()
	entity.traits.pop_back()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "tiene 3 acciones y deben ser 4")
	check_contains(errors, "tiene 1 características y deben ser entre 2 y 4")
	return true


func test_la_regla_por_defecto_va_al_final() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules.reverse()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 3: la última regla debe ser")
	check_contains(errors, "regla 1: solo la última regla puede no tener condiciones")
	return true


func test_acciones_de_las_reglas() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules[0].correct_action_id = &"a9"
	entity.rules[1].risky_action_id = &"a3"
	entity.rules[2].risky_action_id = &""
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 1: la acción 'a9' no existe")
	check_contains(errors, "regla 2: la acción correcta y la de mayor riesgo son la misma")
	check_contains(errors, "regla 3: le falta la acción correcta o la de mayor riesgo")
	return true


func test_condiciones() -> bool:
	var entity := Fixtures.make_entity()
	entity.rules[0].conditions = {&"o9": &"yes"}
	entity.rules[1].conditions = {&"o2": &"maybe"}
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 1: la observación 'o9' no existe")
	check_contains(errors, "regla 2: 'maybe' no es un valor de 'o2'")
	return true


func test_ids_repetidos_o_vacios() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions[1].id = &"a1"
	entity.traits[0].id = &""
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "el id 'a1' está repetido en acciones")
	check_contains(errors, "hay características sin id")
	return true


func test_regla_que_nunca_se_aplica() -> bool:
	var entity := Fixtures.make_entity()
	# Después de "o1 = yes", una regla "o1 = yes y o2 = no" nunca llega a aplicarse.
	entity.rules.insert(1, Fixtures.make_rule({&"o1": &"yes", &"o2": &"no"}, &"a1", &"a2"))
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "regla 2: nunca se aplica")
	return true


func test_espacio_vacio_no_rompe_la_validacion() -> bool:
	var entity := Fixtures.make_entity()
	entity.actions[2] = null
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "hay un espacio vacío en 'actions'")
	return true


func test_observacion_con_un_valor_y_sin_lugares() -> bool:
	var entity := Fixtures.make_entity()
	entity.observations[0].values.erase(&"no")
	entity.place_keys.clear()
	var errors := ContentValidator.validate_entity(entity)
	check_contains(errors, "la observación 'o1' necesita al menos 2 valores")
	check_contains(errors, "no tiene lugares")
	return true
```

- [ ] **Paso 3: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_validator_entity.gd :: no se pudo cargar` y `48 pruebas OK, 1 fallidas`.

- [ ] **Paso 4: Escribir el validador**

`scripts/core/content_validator.gd`:

```gdscript
extends RefCounted
## Revisa que el contenido esté bien armado. Cada función devuelve los errores en español;
## una lista vacía significa que todo está bien. test_catalog.gd la usa sobre el contenido real,
## así que un error de diseño aparece al correr las pruebas.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Límites de la plantilla de docs/02 §7.
const TRAIT_COUNT := Vector2i(2, 4)
const ACTION_COUNT := Vector2i(4, 4)
const OBSERVATION_COUNT := Vector2i(2, 3)
const RULE_COUNT := Vector2i(2, 4)
const MIN_VALUES := 2


static func validate_entity(entity: EntityData) -> Array[String]:
	var errors: Array[String] = []
	var who := "Entidad '%s'" % entity.id
	if entity.id.is_empty():
		errors.append("Hay una entidad sin id")
	for list_name: String in ["traits", "actions", "observations", "rules"]:
		if (entity.get(list_name) as Array).has(null):
			errors.append("%s: hay un espacio vacío en '%s'" % [who, list_name])
	if not errors.is_empty():
		return errors
	if entity.place_keys.is_empty():
		errors.append("%s: no tiene lugares" % who)
	_check_count(errors, who, "características", entity.traits.size(), TRAIT_COUNT)
	_check_count(errors, who, "acciones", entity.actions.size(), ACTION_COUNT)
	_check_count(errors, who, "observaciones", entity.observations.size(), OBSERVATION_COUNT)
	_check_count(errors, who, "reglas", entity.rules.size(), RULE_COUNT)
	_check_unique_ids(errors, who, "características", entity.traits)
	_check_unique_ids(errors, who, "acciones", entity.actions)
	_check_unique_ids(errors, who, "observaciones", entity.observations)
	for observation: ObservationData in entity.observations:
		if observation.values.size() < MIN_VALUES:
			errors.append("%s: la observación '%s' necesita al menos %d valores" % [who, observation.id, MIN_VALUES])
	for index in entity.rules.size():
		_check_rule(errors, who, entity, index)
	# Buscar reglas que nunca se aplican solo tiene sentido si todo lo anterior está bien.
	if errors.is_empty():
		_check_reachable(errors, who, entity)
	return errors


static func _check_count(errors: Array[String], who: String, what: String, count: int, limits: Vector2i) -> void:
	if count >= limits.x and count <= limits.y:
		return
	var expected := str(limits.x) if limits.x == limits.y else "entre %d y %d" % [limits.x, limits.y]
	errors.append("%s: tiene %d %s y deben ser %s" % [who, count, what, expected])


static func _check_unique_ids(errors: Array[String], who: String, what: String, items: Array) -> void:
	var seen := {}
	for item: Resource in items:
		var item_id: StringName = item.get("id")
		if item_id.is_empty():
			errors.append("%s: hay %s sin id" % [who, what])
		elif seen.has(item_id):
			errors.append("%s: el id '%s' está repetido en %s" % [who, item_id, what])
		seen[item_id] = true


static func _check_rule(errors: Array[String], who: String, entity: EntityData, index: int) -> void:
	var rule: RuleData = entity.rules[index]
	var where := "%s, regla %d" % [who, index + 1]
	var is_last := index == entity.rules.size() - 1
	if is_last and not rule.is_default():
		errors.append("%s: la última regla debe ser 'en cualquier otro caso' (sin condiciones)" % where)
	if not is_last and rule.is_default():
		errors.append("%s: solo la última regla puede no tener condiciones" % where)
	if rule.correct_action_id.is_empty() or rule.risky_action_id.is_empty():
		errors.append("%s: le falta la acción correcta o la de mayor riesgo" % where)
	elif rule.correct_action_id == rule.risky_action_id:
		errors.append("%s: la acción correcta y la de mayor riesgo son la misma" % where)
	else:
		for action_id: StringName in [rule.correct_action_id, rule.risky_action_id]:
			if entity.find_action(action_id) == null:
				errors.append("%s: la acción '%s' no existe" % [where, action_id])
	for observation_id: StringName in rule.conditions:
		var observation := entity.find_observation(observation_id)
		var value: StringName = rule.conditions[observation_id]
		if observation == null:
			errors.append("%s: la observación '%s' no existe" % [where, observation_id])
		elif not observation.has_value(value):
			errors.append("%s: '%s' no es un valor de '%s'" % [where, value, observation_id])


## Una regla tapada por las anteriores en todas las situaciones posibles es un error de diseño.
static func _check_reachable(errors: Array[String], who: String, entity: EntityData) -> void:
	var applied := {}
	for situation: Dictionary in RuleEvaluator.all_situations(entity):
		applied[RuleEvaluator.applicable_rule(entity, situation)] = true
	for index in entity.rules.size() - 1:
		if not applied.has(entity.rules[index]):
			errors.append("%s, regla %d: nunca se aplica, porque las reglas anteriores cubren todos sus casos"
					% [who, index + 1])
```

- [ ] **Paso 5: Correr las pruebas**

`content_validator.gd` no tiene `class_name`, así que no hace falta importar.

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `57 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/core test/test_case.gd test/test_validator_entity.gd*
git commit -m "Validador de entidades" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Validador del catálogo

**Archivos:**

- Modificar: `scripts/core/content_validator.gd`
- Probar: `test/test_validator_catalog.gd`

- [ ] **Paso 1: Escribir las pruebas**

`test/test_validator_catalog.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_catalogo_valido() -> bool:
	var errors := ContentValidator.validate_catalog(Fixtures.make_catalog())
	check(errors.is_empty(), str(errors))
	return true


func test_amigos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.friends[2].id = &"leon"
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "el id 'leon' está repetido en amigos")
	catalog.friends.pop_back()
	errors = ContentValidator.validate_catalog(catalog)
	check_contains(errors, "tiene 2 amigos y deben ser 3")
	return true


func test_noches_en_orden() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].number = 3
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "la noche en la posición 2 tiene el número 3")
	return true


func test_entidad_repetida() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[2].new_entities.append(catalog.nights[0].new_entities[0])
	check_contains(ContentValidator.validate_catalog(catalog), "aparece como nueva en más de una noche")
	catalog = Fixtures.make_catalog()
	catalog.nights[2].new_entities.append(Fixtures.make_entity(&"beast"))
	check_contains(ContentValidator.validate_catalog(catalog), "el id 'beast' está repetido en entidades")
	return true


func test_caracteristica_compartida_por_tres() -> bool:
	var catalog := Fixtures.make_catalog()
	var wraith := Fixtures.make_entity(&"wraith")
	catalog.nights[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1")
	wraith.traits[0] = Fixtures.make_trait(&"beast_trait_1")
	catalog.nights[2].new_entities.append(wraith)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': la usan 3 entidades")
	return true


func test_caracteristica_compartida_con_otra_categoria() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].new_entities[0].traits[0] = Fixtures.make_trait(&"beast_trait_1", ClueCategory.Kind.SOUND)
	check_contains(ContentValidator.validate_catalog(catalog), "'beast_trait_1': tiene otra categoría o texto en 'ghost'")
	return true


func test_mismas_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	var ghost: EntityData = catalog.nights[1].new_entities[0]
	ghost.traits[0] = Fixtures.make_trait(&"beast_trait_2")
	ghost.traits[1] = Fixtures.make_trait(&"beast_trait_1")
	check_contains(ContentValidator.validate_catalog(catalog), "'beast' y 'ghost': tienen las mismas características")
	return true


func test_incluye_los_errores_de_cada_entidad() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[1].new_entities[0].actions.pop_back()
	check_contains(ContentValidator.validate_catalog(catalog), "Entidad 'ghost': tiene 3 acciones")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_validator_catalog.gd :: no se pudo cargar` (no existe `validate_catalog`) y `57 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Agregar `validate_catalog()`**

En `scripts/core/content_validator.gd`, debajo de `const MIN_VALUES := 2`:

```gdscript
const FRIEND_COUNT := Vector2i(3, 3)
const NIGHT_COUNT := Vector2i(5, 5)
## Una característica se comparte con otra entidad como máximo: lo que identifica es la combinación.
const MAX_ENTITIES_PER_TRAIT := 2
```

Y debajo de `validate_entity()` (antes de `_check_count`):

```gdscript


## Revisa amigos, noches y todas las entidades, también las relaciones entre entidades.
static func validate_catalog(catalog: ContentCatalog) -> Array[String]:
	var errors: Array[String] = []
	var who := "Catálogo"
	if catalog.friends.has(null) or catalog.nights.has(null):
		errors.append("%s: hay un espacio vacío en 'friends' o en 'nights'" % who)
		return errors
	_check_count(errors, who, "amigos", catalog.friends.size(), FRIEND_COUNT)
	_check_unique_ids(errors, who, "amigos", catalog.friends)
	_check_count(errors, who, "noches", catalog.nights.size(), NIGHT_COUNT)
	var entities: Array[EntityData] = []
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
		if night.number != index + 1:
			errors.append("%s: la noche en la posición %d tiene el número %d; deben ir en orden desde 1"
					% [who, index + 1, night.number])
		if night.new_entities.has(null):
			errors.append("Noche %d: hay un espacio vacío en 'new_entities'" % night.number)
			continue
		for entity: EntityData in night.new_entities:
			if entities.has(entity):
				errors.append("Entidad '%s': aparece como nueva en más de una noche" % entity.id)
			else:
				entities.append(entity)
	_check_unique_ids(errors, who, "entidades", entities)
	for entity: EntityData in entities:
		errors.append_array(validate_entity(entity))
	_check_shared_traits(errors, entities)
	return errors
```

Y al final del archivo:

```gdscript


## Una misma característica (mismo id) debe ser igual en todas sus entidades, la usan 2 como máximo,
## y dos entidades no pueden tener exactamente las mismas características.
static func _check_shared_traits(errors: Array[String], entities: Array[EntityData]) -> void:
	var first_seen := {}  # id de característica → TraitData de la primera entidad que la usa
	var users := {}  # id de característica → ids de las entidades que la usan
	var trait_sets := {}  # ids de características, ordenados y unidos → id de la entidad
	for entity: EntityData in entities:
		var ids := PackedStringArray()
		for trait_data: TraitData in entity.traits:
			if trait_data == null:
				continue
			ids.append(trait_data.id)
			if not users.has(trait_data.id):
				users[trait_data.id] = []
				first_seen[trait_data.id] = trait_data
			users[trait_data.id].append(entity.id)
			var first: TraitData = first_seen[trait_data.id]
			if first.category != trait_data.category or first.text_key != trait_data.text_key:
				errors.append("Característica '%s': tiene otra categoría o texto en '%s'" % [trait_data.id, entity.id])
		ids.sort()
		var key := ",".join(ids)
		if trait_sets.has(key):
			errors.append("Entidades '%s' y '%s': tienen las mismas características; no se pueden distinguir"
					% [trait_sets[key], entity.id])
		trait_sets[key] = entity.id
	for trait_id: StringName in users:
		if users[trait_id].size() > MAX_ENTITIES_PER_TRAIT:
			errors.append("Característica '%s': la usan %d entidades; el máximo es %d"
					% [trait_id, users[trait_id].size(), MAX_ENTITIES_PER_TRAIT])
```

- [ ] **Paso 4: Correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `65 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/content_validator.gd test/test_validator_catalog.gd*
git commit -m "Validador del catálogo y de las características compartidas" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Validador de textos

**Archivos:**

- Modificar: `scripts/core/content_validator.gd`
- Probar: `test/test_validator_texts.gd`

- [ ] **Paso 1: Escribir las pruebas**

`test/test_validator_texts.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


## Traducción falsa: cada clave tiene un texto con una frase entre asteriscos, salvo las de `missing`.
func _translate_except(missing: Array) -> Callable:
	return func(key: String) -> String:
		return key if missing.has(key) else "Texto de *%s*" % key


func test_textos_completos() -> bool:
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), _translate_except([]))
	check(errors.is_empty(), str(errors))
	return true


func test_clave_que_no_esta_en_el_csv() -> bool:
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), _translate_except(["K_beast_LORE"]))
	check_contains(errors, "Entidad 'beast', folclore: la clave 'K_beast_LORE' no está en ningún CSV")
	return true


func test_clave_vacia() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.friends[0].name_key = ""
	var errors := ContentValidator.validate_texts(catalog, _translate_except([]))
	check_contains(errors, "Amigo 'leon': falta la clave de texto")
	return true


func test_caracteristica_sin_una_frase_entre_asteriscos() -> bool:
	var texts := {
		"K_TRAIT_beast_trait_1": "vio un hombrecito",
		"K_TRAIT_beast_trait_2": "vio un *hombrecito* con *ropa*",
	}
	var translate := func(key: String) -> String: return texts.get(key, "Texto de *%s*" % key)
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), translate)
	check_contains(errors, "Característica 'beast_trait_1': su texto debe tener una sola frase entre asteriscos")
	check_contains(errors, "Característica 'beast_trait_2': su texto debe tener una sola frase entre asteriscos")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_validator_texts.gd :: no se pudo cargar` y `65 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Agregar `validate_texts()`**

En `scripts/core/content_validator.gd`, debajo de `const MAX_ENTITIES_PER_TRAIT := 2`:

```gdscript
## Marca de la frase clickeable de una característica: "vio un *hombrecito*".
const HIGHLIGHT_MARK := "*"
```

Y debajo de `validate_catalog()`:

```gdscript


## Revisa que cada clave de texto exista y que cada característica tenga una sola frase entre asteriscos.
## `translate` recibe una clave y devuelve su texto, o la misma clave si no existe
## (como TranslationServer.translate). Supone un catálogo sin errores en validate_catalog().
static func validate_texts(catalog: ContentCatalog, translate: Callable) -> Array[String]:
	var errors: Array[String] = []
	for entry: Array in _text_keys(catalog):
		var where: String = entry[0]
		var key: String = entry[1]
		if key.is_empty():
			errors.append("%s: falta la clave de texto" % where)
		elif String(translate.call(key)) == key:
			errors.append("%s: la clave '%s' no está en ningún CSV" % [where, key])
	for entity: EntityData in catalog.all_entities():
		for trait_data: TraitData in entity.traits:
			var text := String(translate.call(trait_data.text_key))
			if text != trait_data.text_key and text.count(HIGHLIGHT_MARK) != 2:
				errors.append("Característica '%s': su texto debe tener una sola frase entre asteriscos, como 'un *hombrecito*'"
						% trait_data.id)
	return errors


## Pares [dónde, clave] con todas las claves de texto del contenido.
static func _text_keys(catalog: ContentCatalog) -> Array[Array]:
	var keys: Array[Array] = []
	for friend: FriendData in catalog.friends:
		keys.append(["Amigo '%s'" % friend.id, friend.name_key])
	for night: NightData in catalog.nights:
		keys.append(["Noche %d" % night.number, night.place_key])
	for entity: EntityData in catalog.all_entities():
		var who := "Entidad '%s'" % entity.id
		keys.append([who + ", nombre", entity.name_key])
		keys.append([who + ", folclore", entity.lore_key])
		for place_key: String in entity.place_keys:
			keys.append([who + ", lugar", place_key])
		for trait_data: TraitData in entity.traits:
			keys.append(["%s, característica '%s'" % [who, trait_data.id], trait_data.text_key])
		for action: ActionData in entity.actions:
			keys.append(["%s, acción '%s'" % [who, action.id], action.label_key])
		for observation: ObservationData in entity.observations:
			keys.append(["%s, observación '%s'" % [who, observation.id], observation.question_key])
			for value: StringName in observation.values:
				keys.append(["%s, observación '%s' = '%s'" % [who, observation.id, value], observation.values[value]])
		for index in entity.rules.size():
			keys.append(["%s, regla %d" % [who, index + 1], entity.rules[index].text_key])
	return keys
```

- [ ] **Paso 4: Correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `69 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/content_validator.gd test/test_validator_texts.gd*
git commit -m "Validador de textos: claves y frases entre asteriscos" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Traducciones CSV

**Archivos:**

- Crear: `data/text/messages.csv`, `data/text/notebook.csv`, `data/text/ui.csv`
- Modificar: `project.godot`, `.gitignore`
- Probar: `test/test_translations.gd`

Los textos que empiezan con `[PROTO]` son de prototipo: **describen la intención** y Benja los reemplaza (`CLAUDE.md`, regla 8). Los que no lo llevan ya están decididos en el diseño (nombres y lugares de cada noche, §4, §13 y §14). La columna `en` queda vacía: el juego muestra el español.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_translations.gd`:

```gdscript
extends "res://test/test_case.gd"

const FILES := ["messages", "notebook", "ui"]
## Godot no genera el .translation de un idioma cuya columna está entera vacía. Mientras la
## columna "en" esté vacía, solo se registra el español; el inglés se agrega con la opción de idioma (Plan 8).
const LOCALES := ["es"]


func test_las_traducciones_estan_registradas() -> bool:
	var registered: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	for file_name: String in FILES:
		for locale: String in LOCALES:
			var path := "res://data/text/%s.%s.translation" % [file_name, locale]
			check(registered.has(path), "registrada: " + path)
			check(ResourceLoader.exists(path), "importada: " + path)
	check_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "es", "idioma de respaldo")
	return true


func test_traduce_al_espanol() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check_eq(String(TranslationServer.translate("FRIEND_LEON_NAME")), "León", "nombre de León")
	TranslationServer.set_locale(previous)
	return true


func test_sin_texto_en_ingles_se_muestra_el_espanol() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	check_eq(String(TranslationServer.translate("NIGHT_3_PLACE")), "Bosque", "celda en vacía")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: las tres pruebas de `test_translations.gd` fallan y `69 pruebas OK, 3 fallidas`.

- [ ] **Paso 3: Escribir los CSV**

Codificación UTF-8 sin BOM. Un texto con comas va entre comillas dobles.

`data/text/messages.csv` (fragmentos de los mensajes de los amigos):

```csv
keys,es,en
PLACE_FOREST,"[PROTO] El amigo dice que está en el bosque, entre los árboles",
TRAIT_LITTLE_MAN,[PROTO] Vio a un *hombrecito* entre los árboles,
TRAIT_PLANT_FIBER_CLOTHES,"[PROTO] Lleva *ropa de fibra vegetal*, como de paja",
TRAIT_DAMP_FOREST_SMELL,[PROTO] Todo *huele a bosque húmedo*,
OBS_TRAUCO_SAW_FIRST_FRIEND,[PROTO] El amigo lo vio antes de que el ser lo viera a él,
OBS_TRAUCO_SAW_FIRST_TRAUCO,[PROTO] El ser lo vio primero y lo está mirando,
OBS_TRAUCO_AXE_YES,[PROTO] Lleva un hacha de piedra en la mano,
OBS_TRAUCO_AXE_NO,[PROTO] No lleva nada en las manos,
OBS_TRAUCO_CHOPPING_YES,[PROTO] Se oyen hachazos en los árboles,
OBS_TRAUCO_CHOPPING_NO,[PROTO] No se oye nada más que el viento,
```

`data/text/notebook.csv` (páginas del cuaderno y botones de respuesta):

```csv
keys,es,en
RULE_OTHERWISE,En cualquier otro caso,
ENTITY_TRAUCO_NAME,El Trauco,
ENTITY_TRAUCO_LORE,"[PROTO] De 2 a 4 líneas de folclore: un ser pequeño del bosque de Chiloé, con hacha de piedra y una mirada que paraliza (sin los elementos no aptos, diseño §13)",
ACTION_TRAUCO_STARE,[PROTO] Mirarlo fijo,
ACTION_TRAUCO_TURN_BACK,[PROTO] Darle la espalda,
ACTION_TRAUCO_HIDE_BEHIND_TREE,[PROTO] Esconderse tras un árbol,
ACTION_TRAUCO_FOLLOW_CLOSELY,[PROTO] Seguirlo de cerca,
OBS_TRAUCO_SAW_FIRST_Q,[PROTO] ¿Quién vio a quién primero?,
OBS_TRAUCO_AXE_Q,[PROTO] ¿Lleva el hacha en la mano?,
OBS_TRAUCO_CHOPPING_Q,[PROTO] ¿Se oyen hachazos?,
RULE_TRAUCO_1,[PROTO] Si el amigo lo vio primero,
RULE_TRAUCO_2,[PROTO] Si el Trauco lo vio primero y lleva el hacha,
RULE_TRAUCO_3,[PROTO] Si se oyen hachazos,
```

`data/text/ui.csv` (interfaz):

```csv
keys,es,en
FRIEND_LEON_NAME,León,
FRIEND_GONZALO_NAME,Gonzalo,
FRIEND_AGUSTIN_NAME,Agustín,
NIGHT_1_PLACE,Alrededores de la cabaña,
NIGHT_2_PLACE,Camino y lago,
NIGHT_3_PLACE,Bosque,
NIGHT_4_PLACE,Casa abandonada y cueva,
NIGHT_5_PLACE,Todos los lugares,
```

- [ ] **Paso 4: Registrar las traducciones**

En `project.godot`, agregar esta sección (por ejemplo, después de `[editor_plugins]`; Godot puede reordenarla al importar):

```ini
[internationalization]

locale/translations=PackedStringArray("res://data/text/messages.es.translation", "res://data/text/notebook.es.translation", "res://data/text/ui.es.translation")
locale/fallback="es"
```

Al final de `.gitignore`:

```gitignore

# Traducciones generadas por Godot desde data/text/*.csv
data/text/*.translation
```

- [ ] **Paso 5: Importar y verificar**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "ERROR|SCRIPT" ; echo "import listo"
ls data/text/
```

Esperado: `import listo` y, para cada CSV, su `.csv.import` y su `.es.translation` (sin `.en`, porque la columna está vacía). Si falta alguno, revisar que el CSV empiece con `keys,es,en` y no tenga BOM (`head -c 3 data/text/ui.csv | xxd` no debe mostrar `efbbbf`).

- [ ] **Paso 6: Correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `72 pruebas OK, 0 fallidas`.

- [ ] **Paso 7: Commit**

`git status` no debe mostrar archivos `.translation`.

```bash
git add data/text/*.csv data/text/*.csv.import project.godot .gitignore test/test_translations.gd*
git commit -m "Traducciones CSV con textos [PROTO]" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: El Trauco de ejemplo

**Archivos:**

- Crear: `data/entities/trauco.tres`
- Probar: `test/test_trauco.gd`

Es el **ejemplo de formato** de `docs/02` §8, no el Trauco definitivo. Benja lo reemplaza con su diseño (plantilla de `docs/02` §7) antes de S8.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_trauco.gd`:

```gdscript
extends "res://test/test_case.gd"

const ContentValidator := preload("res://scripts/core/content_validator.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TRAUCO_PATH := "res://data/entities/trauco.tres"


func test_el_trauco_es_valido() -> bool:
	var entity: EntityData = load(TRAUCO_PATH)
	check(entity != null, "se carga")
	var errors := ContentValidator.validate_entity(entity)
	check(errors.is_empty(), str(errors))
	return true


## Las reglas del ejemplo de docs/02 §8.
func test_reglas_del_ejemplo() -> bool:
	var entity: EntityData = load(TRAUCO_PATH)
	_check_rule(entity, {&"saw_first": &"friend", &"axe_in_hand": &"yes", &"chopping_sounds": &"yes"},
			&"stare", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"yes", &"chopping_sounds": &"no"},
			&"turn_back", &"stare")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"yes"},
			&"hide_behind_tree", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"no"},
			&"turn_back", &"follow_closely")
	return true


func _check_rule(entity: EntityData, situation: Dictionary, correct: StringName, risky: StringName) -> void:
	var rule := RuleEvaluator.applicable_rule(entity, situation)
	check_eq(rule.correct_action_id, correct, "correcta en %s" % situation)
	check_eq(rule.risky_action_id, risky, "mayor riesgo en %s" % situation)
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: las dos pruebas de `test_trauco.gd` fallan (el archivo no existe) y `72 pruebas OK, 2 fallidas`.

- [ ] **Paso 3: Escribir el `.tres`**

`data/entities/trauco.tres` (categorías: 0 = Vista, 1 = Sonido, 2 = Ambiente, 3 = Rastro):

```ini
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_little_man"]
script = ExtResource("2_trait")
id = &"little_man"
category = 0
text_key = "TRAIT_LITTLE_MAN"

[sub_resource type="Resource" id="Trait_plant_fiber_clothes"]
script = ExtResource("2_trait")
id = &"plant_fiber_clothes"
category = 0
text_key = "TRAIT_PLANT_FIBER_CLOTHES"

[sub_resource type="Resource" id="Trait_damp_forest_smell"]
script = ExtResource("2_trait")
id = &"damp_forest_smell"
category = 2
text_key = "TRAIT_DAMP_FOREST_SMELL"

[sub_resource type="Resource" id="Action_stare"]
script = ExtResource("3_action")
id = &"stare"
label_key = "ACTION_TRAUCO_STARE"

[sub_resource type="Resource" id="Action_turn_back"]
script = ExtResource("3_action")
id = &"turn_back"
label_key = "ACTION_TRAUCO_TURN_BACK"

[sub_resource type="Resource" id="Action_hide_behind_tree"]
script = ExtResource("3_action")
id = &"hide_behind_tree"
label_key = "ACTION_TRAUCO_HIDE_BEHIND_TREE"

[sub_resource type="Resource" id="Action_follow_closely"]
script = ExtResource("3_action")
id = &"follow_closely"
label_key = "ACTION_TRAUCO_FOLLOW_CLOSELY"

[sub_resource type="Resource" id="Observation_saw_first"]
script = ExtResource("4_observation")
id = &"saw_first"
category = 0
question_key = "OBS_TRAUCO_SAW_FIRST_Q"
values = Dictionary[StringName, String]({
&"friend": "OBS_TRAUCO_SAW_FIRST_FRIEND",
&"trauco": "OBS_TRAUCO_SAW_FIRST_TRAUCO"
})

[sub_resource type="Resource" id="Observation_axe_in_hand"]
script = ExtResource("4_observation")
id = &"axe_in_hand"
category = 0
question_key = "OBS_TRAUCO_AXE_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_TRAUCO_AXE_YES",
&"no": "OBS_TRAUCO_AXE_NO"
})

[sub_resource type="Resource" id="Observation_chopping_sounds"]
script = ExtResource("4_observation")
id = &"chopping_sounds"
category = 1
question_key = "OBS_TRAUCO_CHOPPING_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_TRAUCO_CHOPPING_YES",
&"no": "OBS_TRAUCO_CHOPPING_NO"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"saw_first": &"friend"
})
correct_action_id = &"stare"
risky_action_id = &"follow_closely"
text_key = "RULE_TRAUCO_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"saw_first": &"trauco",
&"axe_in_hand": &"yes"
})
correct_action_id = &"turn_back"
risky_action_id = &"stare"
text_key = "RULE_TRAUCO_2"

[sub_resource type="Resource" id="Rule_3"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"chopping_sounds": &"yes"
})
correct_action_id = &"hide_behind_tree"
risky_action_id = &"follow_closely"
text_key = "RULE_TRAUCO_3"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"turn_back"
risky_action_id = &"follow_closely"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"trauco"
name_key = "ENTITY_TRAUCO_NAME"
lore_key = "ENTITY_TRAUCO_LORE"
place_keys = Array[String](["PLACE_FOREST"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_little_man"), SubResource("Trait_plant_fiber_clothes"), SubResource("Trait_damp_forest_smell")])
actions = Array[ExtResource("3_action")]([SubResource("Action_stare"), SubResource("Action_turn_back"), SubResource("Action_hide_behind_tree"), SubResource("Action_follow_closely")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_saw_first"), SubResource("Observation_axe_in_hand"), SubResource("Observation_chopping_sounds")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_3"), SubResource("Rule_otherwise")])
```

- [ ] **Paso 4: Correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "ERROR|FALLA|pruebas OK"
```

Esperado: `74 pruebas OK, 0 fallidas`, sin `ERROR`. Si Godot no puede leer el `.tres` (`Parse Error`), el mensaje trae la línea: comparar con el formato verificado (sección "Decisiones técnicas").

- [ ] **Paso 5: Commit**

```bash
git add data/entities/trauco.tres test/test_trauco.gd*
git commit -m "El Trauco de ejemplo como datos" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: Amigos, noches y catálogo reales

**Archivos:**

- Crear: `data/friends/leon.tres`, `data/friends/gonzalo.tres`, `data/friends/agustin.tres`, `data/nights/night_1.tres` a `night_5.tres`, `data/catalog.tres`
- Probar: `test/test_catalog.gd`

Los valores de las noches son los de `docs/02` §6. Los colores de los amigos son provisionales, y los avatares quedan vacíos hasta que exista su arte.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_catalog.gd`:

```gdscript
extends "res://test/test_case.gd"
## Revisa el contenido real del juego. Si falla después de editar un .tres o un CSV,
## el mensaje dice qué hay que arreglar.

const ContentValidator := preload("res://scripts/core/content_validator.gd")
const CATALOG_PATH := "res://data/catalog.tres"
const ENTITIES_DIR := "res://data/entities"


func test_el_catalogo_es_valido() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var errors := ContentValidator.validate_catalog(catalog)
	check(errors.is_empty(), "\n".join(PackedStringArray(errors)))
	return true


func test_todos_los_textos_existen() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var errors := ContentValidator.validate_texts(catalog, Callable(TranslationServer, "translate"))
	TranslationServer.set_locale(previous)
	check(errors.is_empty(), "\n".join(PackedStringArray(errors)))
	return true


func test_cada_entidad_esta_en_una_noche() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var paths := catalog.all_entities().map(func(entity: EntityData) -> String: return entity.resource_path)
	for file_name: String in DirAccess.get_files_at(ENTITIES_DIR):
		if file_name.ends_with(".tres"):
			check(paths.has(ENTITIES_DIR.path_join(file_name)),
					"%s no está en las entidades nuevas de ninguna noche" % file_name)
	return true


func test_el_trauco_aparece_la_noche_3() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var trauco: EntityData = load("res://data/entities/trauco.tres")
	check(not catalog.known_entities(2).has(trauco), "no aparece antes de la noche 3")
	check(catalog.known_entities(3).has(trauco), "aparece la noche 3")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: las 4 pruebas de `test_catalog.gd` fallan y `74 pruebas OK, 4 fallidas`.

- [ ] **Paso 3: Escribir los amigos**

`data/friends/leon.tres`:

```ini
[gd_resource type="Resource" script_class="FriendData" format=3]

[ext_resource type="Script" path="res://scripts/data/friend_data.gd" id="1_friend"]

[resource]
script = ExtResource("1_friend")
id = &"leon"
name_key = "FRIEND_LEON_NAME"
color = Color(0.95, 0.75, 0.35, 1)
```

`data/friends/gonzalo.tres`:

```ini
[gd_resource type="Resource" script_class="FriendData" format=3]

[ext_resource type="Script" path="res://scripts/data/friend_data.gd" id="1_friend"]

[resource]
script = ExtResource("1_friend")
id = &"gonzalo"
name_key = "FRIEND_GONZALO_NAME"
color = Color(0.45, 0.8, 0.95, 1)
```

`data/friends/agustin.tres`:

```ini
[gd_resource type="Resource" script_class="FriendData" format=3]

[ext_resource type="Script" path="res://scripts/data/friend_data.gd" id="1_friend"]

[resource]
script = ExtResource("1_friend")
id = &"agustin"
name_key = "FRIEND_AGUSTIN_NAME"
color = Color(0.6, 0.9, 0.5, 1)
```

- [ ] **Paso 4: Escribir las noches**

`first_message_observations`: 0 = todas, 1 = todas menos una, 2 = una.

`data/nights/night_1.tres`:

```ini
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]

[resource]
script = ExtResource("1_night")
number = 1
place_key = "NIGHT_1_PLACE"
new_entities = Array[ExtResource("2_entity")]([])
requests_total = 6
max_simultaneous = 1
base_decision_time = 45.0
first_message_observations = 0
signal_decays = false
signal_decay_interval = Vector2(3, 6)
interference_count = 0
audio_sync_beats = 0
sanity_drain_interval = 10.0
content_quota = 2
```

`data/nights/night_2.tres`:

```ini
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]

[resource]
script = ExtResource("1_night")
number = 2
place_key = "NIGHT_2_PLACE"
new_entities = Array[ExtResource("2_entity")]([])
requests_total = 9
max_simultaneous = 2
base_decision_time = 40.0
first_message_observations = 0
signal_decays = true
signal_decay_interval = Vector2(3, 6)
interference_count = 2
audio_sync_beats = 4
sanity_drain_interval = 6.0
content_quota = 3
```

`data/nights/night_3.tres`:

```ini
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
[ext_resource type="Resource" path="res://data/entities/trauco.tres" id="3_trauco"]

[resource]
script = ExtResource("1_night")
number = 3
place_key = "NIGHT_3_PLACE"
new_entities = Array[ExtResource("2_entity")]([ExtResource("3_trauco")])
requests_total = 12
max_simultaneous = 2
base_decision_time = 35.0
first_message_observations = 1
signal_decays = true
signal_decay_interval = Vector2(3, 6)
interference_count = 3
audio_sync_beats = 4
sanity_drain_interval = 6.0
content_quota = 3
```

`data/nights/night_4.tres`:

```ini
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]

[resource]
script = ExtResource("1_night")
number = 4
place_key = "NIGHT_4_PLACE"
new_entities = Array[ExtResource("2_entity")]([])
requests_total = 15
max_simultaneous = 3
base_decision_time = 32.0
first_message_observations = 2
signal_decays = true
signal_decay_interval = Vector2(3, 6)
interference_count = 4
audio_sync_beats = 8
sanity_drain_interval = 6.0
content_quota = 4
```

`data/nights/night_5.tres`:

```ini
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]

[resource]
script = ExtResource("1_night")
number = 5
place_key = "NIGHT_5_PLACE"
new_entities = Array[ExtResource("2_entity")]([])
requests_total = 18
max_simultaneous = 3
base_decision_time = 30.0
first_message_observations = 2
signal_decays = true
signal_decay_interval = Vector2(3, 6)
interference_count = 6
audio_sync_beats = 8
sanity_drain_interval = 6.0
content_quota = 4
```

- [ ] **Paso 5: Escribir el catálogo**

`data/catalog.tres`:

```ini
[gd_resource type="Resource" script_class="ContentCatalog" format=3]

[ext_resource type="Script" path="res://scripts/data/content_catalog.gd" id="1_catalog"]
[ext_resource type="Script" path="res://scripts/data/friend_data.gd" id="2_friend"]
[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="3_night"]
[ext_resource type="Resource" path="res://data/friends/leon.tres" id="4_leon"]
[ext_resource type="Resource" path="res://data/friends/gonzalo.tres" id="5_gonzalo"]
[ext_resource type="Resource" path="res://data/friends/agustin.tres" id="6_agustin"]
[ext_resource type="Resource" path="res://data/nights/night_1.tres" id="7_night_1"]
[ext_resource type="Resource" path="res://data/nights/night_2.tres" id="8_night_2"]
[ext_resource type="Resource" path="res://data/nights/night_3.tres" id="9_night_3"]
[ext_resource type="Resource" path="res://data/nights/night_4.tres" id="10_night_4"]
[ext_resource type="Resource" path="res://data/nights/night_5.tres" id="11_night_5"]

[resource]
script = ExtResource("1_catalog")
friends = Array[ExtResource("2_friend")]([ExtResource("4_leon"), ExtResource("5_gonzalo"), ExtResource("6_agustin")])
nights = Array[ExtResource("3_night")]([ExtResource("7_night_1"), ExtResource("8_night_2"), ExtResource("9_night_3"), ExtResource("10_night_4"), ExtResource("11_night_5")])
```

- [ ] **Paso 6: Correr las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "ERROR|FALLA|pruebas OK"
```

Esperado: `78 pruebas OK, 0 fallidas`, sin `ERROR`.

- [ ] **Paso 7: Commit**

```bash
git add data/friends data/nights data/catalog.tres test/test_catalog.gd*
git commit -m "Amigos, 5 noches y catálogo como datos" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: Revisión en el Inspector y cierre

- [ ] **Paso 1: Ejecutar todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `78 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Agregar la sección F a `docs/04_instrucciones_godot.md`**

En la tabla **Estado**, agregar la fila `| **F.** Revisar una entidad en el Inspector (Plan 2) | ⬜ Pendiente (unos 5 minutos) |`. Al final del archivo, agregar:

````markdown
---

## F. Revisar una entidad en el Inspector (Plan 2)

Cada entidad es un archivo `.tres` en `data/entities/`. Todo lo suyo (características, acciones, observaciones y reglas) vive dentro de ese archivo. Sus textos están en `data/text/*.csv`.

1. Abre Godot y el proyecto.
2. En el panel **FileSystem** (Sistema de archivos), abre `data` > `entities` y haz doble clic en `trauco.tres`.
3. En el **Inspector** (a la derecha) aparecen `Id`, `Name Key`, `Lore Key`, `Sketch`, `Place Keys`, `Traits`, `Actions`, `Observations` y `Rules`. Si dejas el mouse sobre un campo, aparece su explicación.
4. Despliega **Rules** y haz clic en el primer elemento (`RuleData`). Debe mostrar:
   - **Conditions**: `saw_first` → `friend`;
   - **Correct Action Id**: `stare`;
   - **Risky Action Id**: `follow_closely`;
   - **Text Key**: `RULE_TRAUCO_1`.
5. Despliega **Observations** > el primer elemento > **Values**: deben aparecer `friend` y `trauco`, cada uno con su clave de texto.
6. Abre `data/catalog.tres`: **Friends** debe tener 3 elementos y **Nights**, 5. Abre `data/nights/night_3.tres`: en **New Entities** está `trauco.tres`.
7. **No guardes cambios** en esta revisión. Si cambiaste algo sin querer, deshazlo con `Ctrl+Z`, o cierra la pestaña sin guardar.

**Verifica:** todos los campos se ven y se pueden editar. Si un campo aparece vacío o en rojo, avísale a Claude.

### Para más adelante: agregar una entidad

1. En **FileSystem**, haz clic derecho en `trauco.tres` > **Duplicate…** (Duplicar…) y ponle el nombre de la nueva entidad, por ejemplo `tue_tue.tres`. La copia trae sus partes por dentro, independientes del Trauco.
2. Cambia el `Id` y edita sus partes. En las reglas, las acciones se escriben con su id (`Correct Action Id`, `Risky Action Id`). Las condiciones se agregan en **Conditions** con *Add Key/Value Pair* (Agregar par clave/valor): a la izquierda el id de la observación y a la derecha el valor.
3. Abre la noche en que aparece (`data/nights/night_N.tres`) y arrastra el archivo a **New Entities**.
4. Agrega sus textos a los CSV. La frase clickeable de cada característica va entre asteriscos: `vio un *hombrecito*`.
5. Pídele a Claude que corra las pruebas: si algo quedó mal (una regla que nunca se aplica, un id que no existe, un texto que falta), el error lo dice en español.
````

- [ ] **Paso 3: Actualizar el registro**

- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos debe figurar la sección F de `docs/04`.
- `docs/00_log.md`:
  - S7 queda ✅;
  - S8 (escribir el Plan 3) queda como siguiente;
  - S8 necesita las 3 entidades diseñadas.

- [ ] **Paso 4: Commit final**

`scripts/` y `test/` entran para incluir los `.uid` que Godot generó en el último import (por ejemplo, el de `content_validator.gd`). Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/
git commit -m "Plan 2 terminado: datos y textos" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 2):

  | Requisito | Tarea |
  | --- | --- |
  | `TraitData`, `ObservationData`, `ActionData` y `RuleData` | 1 |
  | `EntityData` y evaluador de reglas | 2 |
  | `FriendData` y `NightData` | 3 y 9 |
  | Traducciones CSV con textos `[PROTO]` | 7 |
  | El Trauco de ejemplo como `.tres` | 8 |
  | "Las pruebas del evaluador pasan" | 2 y 8 |
  | "La entidad se edita en el Inspector" | 10 (`docs/04`, F) |
  | Plantilla de `docs/02` §7 (cantidades, características compartidas como máximo por 2 entidades, reglas que se aplican) | 4 y 5 |

- **Fuera de este plan, a propósito:**
  - las entradas del PC siguen con los nombres escritos en `desk.tscn`; se conectan a `FriendData` en el Plan 3;
  - las preguntas, las reacciones de los amigos y "Abre el cuaderno para responder" van a `ui.csv` y `messages.csv` en el Plan 3, junto con el código que las usa;
  - el armado de mensajes, la estática y la lectura de los `*asteriscos*` son del Plan 3, y la página del cuaderno del Plan 4;
  - `screamer_rate` se agrega a `NightData` en el Plan 7, cuando se definan sus unidades;
  - la opción de idioma va en el Plan 8. Hasta entonces, el juego muestra el español porque la columna `en` está vacía.
- **Nombres consistentes:**
  - `ClueCategory.Kind`, `value_ids`, `has_value`, `matches`, `is_default`, `find_action`, `find_observation`, `known_entities` y `all_entities` se usan igual en las clases, los datos de prueba y el validador;
  - `applicable_rule`, `outcome`, `Outcome` y `all_situations` se usan igual en el evaluador, el validador y las pruebas;
  - `validate_entity`, `validate_catalog`, `validate_texts`, `make_entity`, `make_trait`, `make_rule` y `make_catalog` coinciden entre tareas;
  - los ids del Trauco (`saw_first`, `axe_in_hand`, `chopping_sounds`, `stare`, `turn_back`, `hide_behind_tree` y `follow_closely`) coinciden entre el `.tres`, el CSV y `test_trauco.gd`.
- **Conteo de pruebas acumulado:** 36 → 40, 45, 48, 57, 65, 69, 72, 74 y 78.
