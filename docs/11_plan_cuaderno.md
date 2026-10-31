# Plan 4: Cuaderno — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que el jugador responda las solicitudes desde el cuaderno:

- el cuaderno, con un índice (una pestaña por entidad conocida) y la página de la entidad elegida: folclore, boceto, características, observaciones, reglas y acciones;
- la memoria por amigo: el cuaderno recuerda la página abierta de cada amigo, salta a ella al cambiar de chat y vuelve al índice cuando al amigo le llega una solicitud nueva;
- los botones de respuesta del chat, con las 4 acciones de la página abierta para ese amigo;
- la respuesta: Matías envía la acción, la solicitud termina con su resultado y el amigo reacciona (provisional hasta el Plan 5);
- el cuaderno a la derecha, como espejo del chat e independiente de él. El escritorio decide cuándo se cierran los paneles.

**Arquitectura:**

- `scripts/core/` (lógica pura): `NotebookMemory` (la página abierta de cada amigo, con una señal cuando cambia) y `NotebookPage` (arma la página de una entidad en BBCode). Se prueban sin escena.
- `MessageBuilder` agrega la respuesta de Matías y la reacción del amigo, y `RequestManager` agrega `answer()`.
- `scripts/ui/notebook_panel.gd` y `scenes/ui/notebook_panel.tscn`: el panel del cuaderno, con un tema provisional de papel.
- `ChatPanel` agrega los botones de respuesta y avisa qué amigo se eligió. El escritorio (`desk.gd`) crea la memoria, conecta el chat con el cuaderno y cierra los paneles con `Esc` o con un clic fuera de ellos.

**Stack:** Godot 4.7.2 (GDScript con tipado estático; `RichTextLabel` con BBCode para la página). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §7, §8.5 y §12, y `docs/02_bucle_central.md` §5.1 y §9.

---

## Decisiones de este plan

### De Benja (sesión 10, 30 y 31 de octubre)

Ya están en `CLAUDE.md`, en el diseño v2 (§7 y §12) y en `docs/02` (§5.1).

| Decisión | Detalle |
| --- | --- |
| **Una solicitud nueva vuelve al índice.** | Cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice. La página de la solicitud anterior casi nunca sirve, y así no se responde por accidente desde ella. |
| **El chat y el cuaderno son independientes.** | Abrir uno no abre ni cierra el otro, y son los únicos paneles que pueden estar abiertos a la vez. El celular (redes sociales) y el mixer (Audio Sync) son modos exclusivos, sin ningún panel abierto. |
| **El cuaderno va a la derecha, como espejo del chat.** | Tiene el mismo tamaño que el chat (449×696) y va en x 820–1269. Mientras está abierto tapa los diales, y el PC queda visible entre los dos paneles. |
| **El clic derecho sobre un panel cierra solo ese panel.** | `Esc`, o un clic en el escritorio fuera de los paneles, cierra los dos. |
| **Mientras no haya consecuencias, el amigo reacciona según el resultado.** | Matías envía la acción y el amigo responde con un texto `[PROTO]` según si fue la correcta, la de mayor riesgo o una incorrecta. En el Plan 5, la reacción también va a depender de si el amigo quedó herido. |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| `NotebookMemory` (lógica pura) guarda la página abierta de cada amigo y avisa con `page_changed`. La crea el escritorio, y la usan el cuaderno y el chat. | Hay una sola fuente de verdad: el cuaderno muestra la página, y el chat arma los botones de respuesta con la misma memoria. |
| `NotebookPage` arma la página en BBCode y recibe la traducción como un `Callable`, igual que `MessageBuilder`. | Se prueba sin escena y con una traducción falsa. Los corchetes se escriben `[lb]`, así que `[PROTO]` se ve como texto. |
| El nombre de una característica en el cuaderno es **su frase entre asteriscos**, la misma que se clickea en los mensajes. | No hace falta otra clave de texto, y el jugador reconoce en el cuaderno exactamente lo que ve en el chat. Por eso la frase tiene que entenderse sola (`docs/02` §9). |
| Cada característica y cada observación muestran **la pregunta que las trae**, como en "hombrecito (¿Qué ves?)". | Si la estática tapa una, se sabe qué preguntar (diseño §12). |
| Cada regla ocupa dos líneas: "1. Si el amigo lo vio primero" y "→ Mirarlo fijo · Mayor riesgo: Seguirlo de cerca". La correcta va en verde y la de mayor riesgo, en rojo. | La acción de mayor riesgo también se nombra en el texto: el color no es la única pista (diseño §19). |
| Los botones de respuesta van en el chat, bajo las preguntas: 4 botones en 2 columnas, con el texto en varias líneas si no cabe. Encima dice "Acciones de El Trauco". Sin página abierta, dice "Abre el cuaderno para responder". | Así lo pide el diseño (§8.5). La conversación se achica de 448 a 370 px para hacerles lugar. El título dice de qué página son las acciones, porque responder desde la página equivocada es un error. |
| Sin solicitud activa, los botones de respuesta se ven pero están desactivados, como las preguntas. | El jugador puede estudiar la página antes de que llegue la solicitud. |
| `RequestManager.answer()` termina la solicitud con `FriendRequest.finish(acción, true)`. | El resultado lo decide `RuleEvaluator`: una acción de la página de otra entidad es incorrecta aunque tenga el mismo id (`docs/02` §5.2). `request_finished` ya lleva todo lo que necesita el Plan 5. |
| **El escritorio cierra los paneles.** Lo que hacía el chat con `Esc` y con un clic fuera (Plan 3) pasa a `desk.gd`, y cada panel conserva su clic derecho. | Con dos paneles, el chat no puede saber si un clic fuera de él cayó en el cuaderno del escritorio, que no debe cerrarlo. El escritorio es el último nodo que recibe la entrada (`_unhandled_input`): solo le llega lo que no atendieron las entradas del PC, los objetos del escritorio ni los paneles. |
| Un clic en el celular o en el mixer cierra los paneles. | Son modos exclusivos (decisión de Benja). Sus vistas llegan en el Plan 6. |
| El tema `scenes/ui/notebook_theme.tres` es provisional: papel claro, texto oscuro y pestañas simples. | Sirve hasta que llegue el arte del cuaderno (`docs/06` §3): la página (449×696, como `screen_sprite`), las pestañas del índice y los bocetos. |
| El cuaderno recibe las entidades conocidas de la noche al empezar (`setup`). | Alcanza para una noche. El Plan 8, que cambia de noche, lo vuelve a configurar. |
| Los textos con datos usan marcadores con nombre: `{clue}`, `{question}`, `{correct}`, `{risky}`, `{friend}` y `{entity}`. | Benja puede mover los marcadores sin romper nada. Las pruebas avisan si falta alguno. |

**Verificado en Godot 4.7.2**, en copias aparte del proyecto, ya borradas:

- todo el código de este plan se ejecutó: 177 pruebas OK, sin errores al correr, y una captura del cuaderno abierto junto al chat, ya revisada;
- después, el plan **tal como está escrito** se aplicó a una copia limpia del proyecto: los conteos de pruebas que dice coinciden, incluidas las fallas esperadas, y el código resultante es idéntico al probado.

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `148 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar.** Al importar, Godot crea los `.uid` de los scripts nuevos y regenera las traducciones de los CSV. Cada tarea importa antes de correr las pruebas:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "SCRIPT|Parse" ; echo "import listo"
```

Esperado: solo `import listo`. Si aparece `SCRIPT ERROR`, el script tiene un error de sintaxis: corregirlo y volver a importar.

**Pruebas.** Para ver solo las fallas y el resumen:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

**Commits.** Cada tarea termina en un commit, pero Claude **pregunta a Benja antes de cada uno**, salvo que Benja autorice de una vez todos los commits del plan al empezar (`CLAUDE.md`, regla 11). La línea `Co-Authored-By` nombra al modelo que ejecuta: los comandos dicen Sonnet 5.5, como propone `docs/00_log.md`; si ejecuta otro, se cambia el nombre. El push solo se hace con autorización.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

**Tabuladores:** GDScript indenta con tabuladores. Los bloques de este plan los tienen: al copiarlos, no hay que convertirlos en espacios.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/core/notebook_memory.gd` | `NotebookMemory`: la página del cuaderno que tiene abierta cada amigo |
| `scripts/core/notebook_page.gd` | `NotebookPage`: la página de una entidad, en BBCode |
| `scripts/core/message_builder.gd` | Se agregan la respuesta de Matías y la reacción del amigo |
| `scripts/desk/request_manager.gd` | Se agrega `answer()`: Matías responde y la solicitud termina |
| `scripts/ui/notebook_panel.gd`, `scenes/ui/notebook_panel.tscn` | Panel del cuaderno: el índice, la página y a qué amigo ayuda |
| `scenes/ui/notebook_theme.tres` | Tema provisional del cuaderno |
| `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn` | Se agregan los botones de respuesta y la señal `friend_selected`. El cierre con `Esc` y con un clic fuera pasa al escritorio |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | Se agrega el cuaderno. El escritorio conecta los paneles y los cierra |
| `data/text/notebook.csv`, `data/text/ui.csv`, `data/text/messages.csv` | Títulos y formatos de la página, textos de los paneles y reacciones `[PROTO]` |
| `test/test_*.gd` | Pruebas de cada tarea |
| `test/capture_notebook.gd` | Captura del cuaderno para revisarlo a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
desk.gd (escritorio): crea NotebookMemory y se la pasa al chat y al cuaderno
  clic en el cuaderno del escritorio ───▶ NotebookPanel.open_for(amigo del chat)
  ChatPanel.entity_page_requested ──────▶ memoria.open_page(amigo, entidad) y NotebookPanel.open_for(amigo)
  ChatPanel.friend_selected ────────────▶ NotebookPanel.select_friend(amigo)
  RequestManager.request_started ───────▶ memoria.close_page(amigo): vuelve al índice
  Esc o un clic fuera de los paneles ───▶ cierra los dos

NotebookPanel   pestaña del índice ─▶ memoria.open_page(amigo, entidad) ─page_changed─▶ página (NotebookPage)
ChatPanel       botones de respuesta = acciones de memoria.page_for(amigo) ─▶ RequestManager.answer()
RequestManager  answer(): FriendRequest.finish() ─▶ respuesta y reacción (MessageBuilder) ─▶ request_finished
```

---

### Tarea 1: Memoria de páginas por amigo

**Archivos:**

- Crear: `scripts/core/notebook_memory.gd`, `test/test_notebook_memory.gd`

`NotebookMemory` es lógica pura: guarda qué página tiene abierta cada amigo (`null` es el índice) y avisa cuando cambia.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_notebook_memory.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")


func test_cada_amigo_empieza_en_el_indice() -> bool:
	var memory := NotebookMemory.new(3)
	for friend_index in 3:
		check_eq(memory.page_for(friend_index), null, "amigo %d" % friend_index)
	return true


func test_cada_amigo_recuerda_su_pagina() -> bool:
	var memory := NotebookMemory.new(3)
	var beast := Fixtures.make_entity(&"beast")
	var ghost := Fixtures.make_entity(&"ghost")
	memory.open_page(0, beast)
	memory.open_page(2, ghost)
	check_eq(memory.page_for(0), beast, "León")
	check_eq(memory.page_for(1), null, "Gonzalo sigue en el índice")
	check_eq(memory.page_for(2), ghost, "Agustín")
	memory.close_page(0)
	check_eq(memory.page_for(0), null, "León vuelve al índice")
	return true


func test_avisa_solo_cuando_cambia() -> bool:
	var memory := NotebookMemory.new(3)
	var beast := Fixtures.make_entity(&"beast")
	var changes := []
	memory.page_changed.connect(func(friend_index: int, entity: EntityData) -> void:
		changes.append([friend_index, entity]))
	memory.open_page(1, beast)
	memory.open_page(1, beast)
	memory.close_page(1)
	memory.close_page(1)
	check_eq(changes, [[1, beast], [1, null]], "un aviso por cambio")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_notebook_memory.gd :: no se pudo cargar` y `148 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir `NotebookMemory`**

`scripts/core/notebook_memory.gd`:

```gdscript
extends RefCounted
## Qué página del cuaderno tiene abierta cada amigo (diseño §12). El cuaderno salta a ella al cambiar
## de chat, y los botones de respuesta del chat muestran sus acciones (diseño §8.5).
## null significa que ese amigo está en el índice, sin página abierta.

signal page_changed(friend_index: int, entity: EntityData)

var _pages: Array[EntityData] = []


func _init(friend_count: int) -> void:
	_pages.resize(friend_count)


## La página abierta para un amigo, o null si está en el índice.
func page_for(friend_index: int) -> EntityData:
	return _pages[friend_index]


func open_page(friend_index: int, entity: EntityData) -> void:
	if _pages[friend_index] == entity:
		return
	_pages[friend_index] = entity
	page_changed.emit(friend_index, entity)


## Vuelve al índice: ese amigo queda sin página abierta.
func close_page(friend_index: int) -> void:
	open_page(friend_index, null)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `151 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Memoria de páginas del cuaderno por amigo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: La página de una entidad

**Archivos:**

- Crear: `scripts/core/notebook_page.gd`, `test/test_notebook_page.gd`
- Modificar: `data/text/notebook.csv`

`NotebookPage` arma la página en BBCode, sin el nombre, que el panel muestra como título. El orden es el del diseño (§12): el folclore, las características, las observaciones, las reglas y las acciones.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_notebook_page.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const NotebookPage := preload("res://scripts/core/notebook_page.gd")

const FORMATS := {
	"NOTEBOOK_CLUE_LINE": "{clue} ({question})",
	"NOTEBOOK_RULE_ACTIONS": "→ {correct} · riesgo: {risky}",
}


## Traducción falsa: los formatos de FORMATS, cada característica con su id entre asteriscos,
## y cualquier otra clave tal cual.
func _translate(key: String) -> String:
	if FORMATS.has(key):
		return FORMATS[key]
	if key.begins_with("K_TRAIT_"):
		return "Hay *%s* cerca." % key.trim_prefix("K_TRAIT_")
	return key


## El texto como se ve: sin etiquetas BBCode y con [lb] convertido en corchete.
func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[(?!lb\\])[^\\]]*\\]").sub(bbcode, "", true).replace("[lb]", "[")


func test_nombre_de_una_caracteristica() -> bool:
	var trait_data := Fixtures.make_trait(&"little_man")
	check_eq(NotebookPage.trait_label(trait_data, _translate), "little_man", "la frase entre asteriscos")
	var without_mark := func(_key: String) -> String: return "Un olor raro"
	check_eq(NotebookPage.trait_label(trait_data, without_mark), "Un olor raro", "sin asteriscos, el texto completo")
	return true


func test_pagina_completa() -> bool:
	var entity := Fixtures.make_entity()
	entity.observations[1].category = ClueCategory.Kind.SOUND
	var expected := "\n".join([
		"K_beast_LORE",
		"",
		"NOTEBOOK_TRAITS",
		"• beast_trait_1 (QUESTION_SIGHT)",
		"• beast_trait_2 (QUESTION_SIGHT)",
		"",
		"NOTEBOOK_OBSERVATIONS",
		"• K_beast_O1_Q (QUESTION_SIGHT)",
		"• K_beast_O2_Q (QUESTION_SOUND)",
		"",
		"NOTEBOOK_RULES",
		"1. K_RULE",
		"→ K_beast_A1 · riesgo: K_beast_A2",
		"2. K_RULE",
		"→ K_beast_A3 · riesgo: K_beast_A4",
		"3. K_RULE",
		"→ K_beast_A2 · riesgo: K_beast_A3",
		"",
		"NOTEBOOK_ACTIONS",
		"• K_beast_A1",
		"• K_beast_A2",
		"• K_beast_A3",
		"• K_beast_A4",
	])
	check_eq(_plain(NotebookPage.bbcode(entity, _translate)), expected, "página")
	return true


func test_la_correcta_y_la_de_mayor_riesgo_se_distinguen() -> bool:
	var page := NotebookPage.bbcode(Fixtures.make_entity(), _translate)
	check(page.contains("[color=#%s]K_beast_A1[/color]" % NotebookPage.CORRECT_COLOR), "la correcta, en su color")
	check(page.contains("[color=#%s]K_beast_A2[/color]" % NotebookPage.RISKY_COLOR), "la de mayor riesgo, en el suyo")
	return true


func test_los_corchetes_se_ven() -> bool:
	var proto := func(key: String) -> String: return "[PROTO] " + _translate(key)
	var page := NotebookPage.bbcode(Fixtures.make_entity(), proto)
	check(_plain(page).begins_with("[PROTO] K_beast_LORE"), "[PROTO] se ve como texto")
	check(not page.contains("[PROTO]"), "se escribe con [lb]")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	for key: String in [NotebookPage.TRAITS_KEY, NotebookPage.OBSERVATIONS_KEY, NotebookPage.RULES_KEY,
			NotebookPage.ACTIONS_KEY, NotebookPage.CLUE_LINE_KEY, NotebookPage.RULE_ACTIONS_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en notebook.csv" % key)
	var clue_line := String(TranslationServer.translate(NotebookPage.CLUE_LINE_KEY))
	check(clue_line.contains("{clue}") and clue_line.contains("{question}"),
			"NOTEBOOK_CLUE_LINE debe tener {clue} y {question}")
	var rule_actions := String(TranslationServer.translate(NotebookPage.RULE_ACTIONS_KEY))
	check(rule_actions.contains("{correct}") and rule_actions.contains("{risky}"),
			"NOTEBOOK_RULE_ACTIONS debe tener {correct} y {risky}")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_notebook_page.gd :: no se pudo cargar` y `151 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir `NotebookPage`**

`scripts/core/notebook_page.gd`:

```gdscript
extends RefCounted
## Arma la página de una entidad en el cuaderno (diseño §12) como BBCode para un RichTextLabel:
## el folclore, las características y las observaciones (cada una con la pregunta que las trae),
## las reglas en orden con su acción correcta y su acción de mayor riesgo, y las 4 acciones.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const MessageBuilder := preload("res://scripts/core/message_builder.gd")

## Títulos de las secciones (notebook.csv).
const TRAITS_KEY := "NOTEBOOK_TRAITS"
const OBSERVATIONS_KEY := "NOTEBOOK_OBSERVATIONS"
const RULES_KEY := "NOTEBOOK_RULES"
const ACTIONS_KEY := "NOTEBOOK_ACTIONS"
## Una característica u observación y la pregunta que la trae. Lleva {clue} y {question} (notebook.csv).
const CLUE_LINE_KEY := "NOTEBOOK_CLUE_LINE"
## Las acciones de una regla. Lleva {correct} y {risky} (notebook.csv).
const RULE_ACTIONS_KEY := "NOTEBOOK_RULE_ACTIONS"
## Colores provisionales para papel claro, hasta el arte del cuaderno. La acción de mayor riesgo
## también se nombra en el texto: el color no es la única pista (diseño §19).
const HEADING_COLOR := "6b3a1f"
const CORRECT_COLOR := "1f5c2e"
const RISKY_COLOR := "9b2a1c"


## La página de `entity`, sin el nombre: el panel lo muestra como título.
static func bbcode(entity: EntityData, translate: Callable) -> String:
	var lines := PackedStringArray([_escape(_text(translate, entity.lore_key))])
	lines.append(_heading(translate, TRAITS_KEY))
	for trait_data: TraitData in entity.traits:
		lines.append(_clue_line(translate, trait_label(trait_data, translate), trait_data.category))
	lines.append(_heading(translate, OBSERVATIONS_KEY))
	for observation: ObservationData in entity.observations:
		lines.append(_clue_line(translate, _text(translate, observation.question_key), observation.category))
	lines.append(_heading(translate, RULES_KEY))
	for index in entity.rules.size():
		lines.append(_rule_lines(entity, index, translate))
	lines.append(_heading(translate, ACTIONS_KEY))
	for action: ActionData in entity.actions:
		lines.append("• " + _escape(_text(translate, action.label_key)))
	return "\n".join(lines)


## El nombre de una característica en el cuaderno: la frase entre asteriscos de su texto, la misma
## que se clickea en los mensajes. Si el texto no tiene asteriscos, el texto completo.
static func trait_label(trait_data: TraitData, translate: Callable) -> String:
	var text := _text(translate, trait_data.text_key)
	var start := text.find("*")
	var end := text.find("*", start + 1)
	if start == -1 or end == -1:
		return text.replace("*", "")
	return text.substr(start + 1, end - start - 1)


static func _heading(translate: Callable, key: String) -> String:
	return "\n" + _colored(_escape(_text(translate, key)), HEADING_COLOR)


## "• hombrecito (¿Qué ves?)": si la estática tapa la característica, se sabe qué preguntar.
static func _clue_line(translate: Callable, clue: String, category: ClueCategory.Kind) -> String:
	var question := _text(translate, MessageBuilder.QUESTION_KEYS[category])
	return "• " + _escape(_text(translate, CLUE_LINE_KEY)).format({"clue": _escape(clue), "question": _escape(question)})


## "1. Si el amigo lo vio primero" y, en la línea siguiente, la acción correcta y la de mayor riesgo.
static func _rule_lines(entity: EntityData, index: int, translate: Callable) -> String:
	var rule := entity.rules[index]
	var actions := _escape(_text(translate, RULE_ACTIONS_KEY)).format({
		"correct": _colored(_action_label(entity, rule.correct_action_id, translate), CORRECT_COLOR),
		"risky": _colored(_action_label(entity, rule.risky_action_id, translate), RISKY_COLOR),
	})
	return "%d. %s\n%s" % [index + 1, _escape(_text(translate, rule.text_key)), actions]


static func _action_label(entity: EntityData, action_id: StringName, translate: Callable) -> String:
	var action := entity.find_action(action_id)
	return _escape(_text(translate, action.label_key)) if action != null else String(action_id)


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]


## [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
```

- [ ] **Paso 4: Agregar los textos de la página**

Los títulos y los formatos son de la interfaz del cuaderno, no diálogos, así que van sin `[PROTO]`.

Agregar al final de `data/text/notebook.csv`:

```csv
NOTEBOOK_TRAITS,Características,
NOTEBOOK_OBSERVATIONS,Observaciones,
NOTEBOOK_RULES,Reglas: se aplica la primera que se cumple,
NOTEBOOK_ACTIONS,Acciones,
NOTEBOOK_CLUE_LINE,{clue} ({question}),
NOTEBOOK_RULE_ACTIONS,→ {correct} · Mayor riesgo: {risky},
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `156 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/core/ test/ data/text/
git commit -m "Página de una entidad en el cuaderno" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: La respuesta de Matías y la reacción del amigo

**Archivos:**

- Modificar: `scripts/core/message_builder.gd`, `test/test_message_builder.gd`, `data/text/messages.csv`

La respuesta de Matías es la acción que eligió, como mensaje suyo. La reacción del amigo depende del resultado: correcta, de mayor riesgo o incorrecta.

- [ ] **Paso 1: Escribir las pruebas**

Son 2 cambios en `test/test_message_builder.gd`.

**1. Las claves de las reacciones también deben existir.** En `test/test_message_builder.gd`, reemplazar:

```gdscript
	var keys: Array = MessageBuilder.QUESTION_KEYS.values() + MessageBuilder.NOTHING_KEYS.values()
```

por:

```gdscript
	var keys: Array = MessageBuilder.QUESTION_KEYS.values() + MessageBuilder.NOTHING_KEYS.values() \
			+ MessageBuilder.REACTION_KEYS.values()
```

**2. Las pruebas nuevas.** En `test/test_message_builder.gd`, reemplazar:

```gdscript
func test_sus_textos_existen() -> bool:
```

por:

```gdscript
func test_la_respuesta_de_matias() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a1"), true)
	var message := MessageBuilder.player_answer(request, _translate)
	check_eq(message.sender, ChatMessage.Sender.PLAYER, "la envía Matías")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "K_beast_A1.", "la acción que eligió")
	return true


func test_la_reaccion_depende_del_resultado() -> bool:
	# o1 = yes: se aplica la regla 1 (correcta a1, mayor riesgo a2), y a3 es incorrecta.
	var expected := {&"a1": "REACTION_CORRECT.", &"a2": "REACTION_RISKY.", &"a3": "REACTION_WRONG."}
	for action_id: StringName in expected:
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		var message := MessageBuilder.reaction(request, _translate)
		check_eq(message.sender, ChatMessage.Sender.FRIEND, "la envía el amigo")
		check_eq(message.plain_text(), expected[action_id], "reacción a %s" % action_id)
	return true


func test_sus_textos_existen() -> bool:
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_message_builder.gd :: no se pudo cargar` y `150 pruebas OK, 1 fallidas`. Mientras el archivo no carga, sus 6 pruebas anteriores no corren.

- [ ] **Paso 3: Agregar la respuesta y la reacción**

Son 3 cambios en `scripts/core/message_builder.gd`.

**1. El evaluador de reglas.** En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
const FriendRequest := preload("res://scripts/core/friend_request.gd")
```

por:

```gdscript
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

**2. Las claves de las reacciones.** En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
const DECIDED_ALONE_KEY := "FRIEND_DECIDED_ALONE"
```

por:

```gdscript
const DECIDED_ALONE_KEY := "FRIEND_DECIDED_ALONE"
## Lo que cuenta el amigo después de hacer lo que dijo Matías, según el resultado (messages.csv).
## Es provisional: en el Plan 5 la reacción también depende de si el amigo quedó herido.
const REACTION_KEYS := {
	RuleEvaluator.Outcome.CORRECT: "REACTION_CORRECT",
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG",
}
```

**3. Los mensajes.** En `scripts/core/message_builder.gd`, reemplazar el final de `decided_alone()`:

```gdscript
	message.add_fragment(_text(translate, DECIDED_ALONE_KEY).format({"action": action}))
	return message
```

por:

```gdscript
	message.add_fragment(_text(translate, DECIDED_ALONE_KEY).format({"action": action}))
	return message


## La respuesta de Matías: la acción que eligió en el cuaderno. La solicitud ya debe estar terminada.
static func player_answer(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.PLAYER, request)
	message.add_fragment(_text(translate, request.chosen_action.label_key))
	return message


## Lo que cuenta el amigo después de hacer lo que dijo Matías. La solicitud ya debe estar terminada.
static func reaction(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment(_text(translate, REACTION_KEYS[request.outcome]))
	return message
```

- [ ] **Paso 4: Agregar las reacciones**

Las reacciones son diálogo, así que van como `[PROTO]` y las reescribe Benja (`CLAUDE.md`, regla 8).

Agregar al final de `data/text/messages.csv`:

```csv
REACTION_CORRECT,[PROTO] El amigo hizo lo que dijo Matías y funcionó: cuenta que la entidad lo dejó tranquilo,
REACTION_RISKY,[PROTO] El amigo hizo lo más arriesgado: cuenta que estuvo muy cerca de la entidad,
REACTION_WRONG,[PROTO] El amigo hizo lo que dijo Matías y salió mal: cuenta que la entidad se puso agresiva,
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `158 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/core/ test/ data/text/
git commit -m "Respuesta de Matías y reacción del amigo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Responder una solicitud

**Archivos:**

- Modificar: `scripts/desk/request_manager.gd`, `test/test_request_manager.gd`

`answer()` termina la solicitud con la acción que eligió Matías. El amigo queda libre, y llegan al chat la respuesta y la reacción.

- [ ] **Paso 1: Escribir las pruebas**

Son 2 cambios en `test/test_request_manager.gd`.

**1. El evaluador de reglas.** En `test/test_request_manager.gd`, reemplazar:

```gdscript
const RequestManager := preload("res://scripts/desk/request_manager.gd")
```

por:

```gdscript
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

**2. Las pruebas nuevas.** En `test/test_request_manager.gd`, reemplazar:

```gdscript
func test_las_solicitudes_llegan_solas() -> bool:
```

por:

```gdscript
func test_responder_termina_la_solicitud() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	check(manager.answer(0, request.entity.find_action(rule.correct_action_id)), "se pudo responder")
	check(request.finished and request.answered_by_player, "respondió Matías")
	check_eq(request.outcome, RuleEvaluator.Outcome.CORRECT, "la acción correcta")
	check_eq(manager.requests[0], null, "León queda libre")
	check_eq(events.size(), 3, "respuesta, reacción y fin")
	if events.size() == 3:
		check_eq((events[0][2] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "responde Matías")
		check_eq((events[1][2] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "reacciona el amigo")
		check_eq(events[2], ["request_finished", 0, request], "terminó")
	check(not manager.answer(0, request.entity.actions[0]), "ya no espera respuesta")
	manager.free()
	return true


func test_responder_desde_otra_pagina_es_incorrecto() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(1)
	var other := Fixtures.make_entity(&"ghost")
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(1, other.find_action(rule.correct_action_id))
	check_eq(request.outcome, RuleEvaluator.Outcome.WRONG, "la misma acción, pero de otra página")
	manager.free()
	return true


func test_las_solicitudes_llegan_solas() -> bool:
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: fallan las 2 pruebas nuevas de `test_request_manager.gd` (`test_responder_termina_la_solicitud` y `test_responder_desde_otra_pagina_es_incorrecto`), con `158 pruebas OK, 2 fallidas`.

- [ ] **Paso 3: Agregar `answer()`**

Son 2 cambios en `scripts/desk/request_manager.gd`.

**1. El comentario del script.** En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Las solicitudes de la noche (Plan 3): las genera, avanza sus temporizadores, recibe las preguntas
## y los clics del chat, y arma los mensajes con estática.
```

por:

```gdscript
## Las solicitudes de la noche (planes 3 y 4): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, y arma los mensajes con estática.
```

**2. La respuesta.** En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
func _decide_alone(friend_index: int) -> void:
```

por:

```gdscript
## Matías responde con `action`, desde la página abierta en el cuaderno, y la solicitud termina.
## Una acción de la página de otra entidad es incorrecta (docs/02 §5.2).
## Devuelve false si el amigo no espera respuesta.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null:
		return false
	request.finish(action, true)
	requests[friend_index] = null
	message_added.emit(friend_index, MessageBuilder.player_answer(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	request_finished.emit(friend_index, request)
	return true


func _decide_alone(friend_index: int) -> void:
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `160 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/ test/
git commit -m "Responder una solicitud" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Panel del cuaderno

**Archivos:**

- Crear: `scenes/ui/notebook_theme.tres`, `scenes/ui/notebook_panel.tscn`, `scripts/ui/notebook_panel.gd`, `test/test_notebook_panel.gd`
- Modificar: `data/text/ui.csv`

El panel va a la derecha, como espejo del chat: mide 449×696 y empieza en (820, 11). De arriba abajo tiene:

- a qué amigo ayuda;
- el índice: una pestaña por entidad, en varias filas si no caben;
- la página, en un `ScrollContainer`: el nombre, el boceto (si la entidad tiene, a ×1 y sin escalar) y el texto de `NotebookPage`.

Todavía no está en el escritorio: se agrega en la Tarea 6.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_notebook_panel.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/notebook_panel.tscn")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")

var _memory: NotebookMemory
var _entities: Array[EntityData] = []


## Cuaderno con las 2 entidades conocidas en la noche 2 del catálogo de prueba ("beast" y "ghost")
## y la memoria de páginas de los 3 amigos.
func _make_panel() -> Control:
	var catalog := Fixtures.make_catalog()
	_entities = catalog.known_entities(2)
	_memory = NotebookMemory.new(catalog.friends.size())
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	panel.setup(_memory, _entities, catalog.friends)
	return panel


func _tabs(panel: Control) -> Array[Node]:
	return panel.get_node("Page/Layout/Index").get_children()


func _title(panel: Control) -> Label:
	return panel.get_node("Page/Layout/Scroll/Content/Title") as Label


func _body(panel: Control) -> RichTextLabel:
	return panel.get_node("Page/Layout/Scroll/Content/Body") as RichTextLabel


func test_empieza_oculto_y_en_el_indice() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for(1)
	check(panel.visible, "visible tras abrir")
	check_eq(panel.friend_index, 1, "amigo")
	check_eq(_tabs(panel).size(), 2, "una pestaña por entidad conocida")
	check(not _title(panel).visible, "sin página no hay título")
	check_eq(_body(panel).text, tr(panel.PICK_ENTITY_KEY), "pide elegir una entidad")
	panel.free()
	return true


func test_una_pestana_abre_su_pagina_para_ese_amigo() -> bool:
	var panel := _make_panel()
	panel.open_for(2)
	(_tabs(panel)[1] as Button).pressed.emit()
	check_eq(_memory.page_for(2), _entities[1], "Agustín tiene abierta la página de ghost")
	check_eq(_memory.page_for(0), null, "León sigue en el índice")
	check(_title(panel).visible, "título visible")
	check_eq(_title(panel).text, tr(_entities[1].name_key), "nombre de la entidad")
	check(_body(panel).text.contains(_entities[1].lore_key), "su página")
	check((_tabs(panel)[1] as Button).button_pressed, "su pestaña queda marcada")
	panel.free()
	return true


func test_al_cambiar_de_amigo_salta_a_su_pagina() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _entities[0])
	panel.open_for(1)
	check(not _title(panel).visible, "Gonzalo está en el índice")
	panel.select_friend(0)
	check_eq(_title(panel).text, tr(_entities[0].name_key), "León está en la página de beast")
	check((_tabs(panel)[0] as Button).button_pressed and not (_tabs(panel)[1] as Button).button_pressed,
			"pestaña de beast")
	panel.free()
	return true


func test_se_actualiza_si_cambia_la_memoria() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _entities[1])
	check_eq(_title(panel).text, tr(_entities[1].name_key), "abre la página")
	_memory.close_page(0)
	check(not _title(panel).visible, "vuelve al índice")
	_memory.open_page(1, _entities[0])
	check(not _title(panel).visible, "la página de otro amigo no cambia lo que se ve")
	panel.free()
	return true


func test_dice_a_que_amigo_ayuda() -> bool:
	var panel := _make_panel()
	panel.open_for(2)
	check_eq((panel.get_node("Page/Layout/Friend") as Label).text,
			tr(panel.FOR_FRIEND_KEY).format({"friend": tr("K_FRIEND_agustin")}), "Agustín")
	panel.free()
	return true


func test_boceto_solo_si_la_entidad_tiene() -> bool:
	var panel := _make_panel()
	var sketch := panel.get_node("Page/Layout/Scroll/Content/Sketch") as TextureRect
	_memory.open_page(0, _entities[0])
	check(not sketch.visible, "sin boceto")
	_entities[1].sketch = ImageTexture.create_from_image(Image.create(96, 96, false, Image.FORMAT_RGBA8))
	_memory.open_page(0, _entities[1])
	check(sketch.visible, "con boceto")
	check_eq(sketch.texture, _entities[1].sketch, "su boceto")
	panel.free()
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	(panel.get_node("Page") as Control).gui_input.emit(click)
	check(not panel.visible, "oculto tras clic derecho")
	panel.free()
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/notebook_panel.gd")
	for key: String in [panel_script.PICK_ENTITY_KEY, panel_script.FOR_FRIEND_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	check(String(TranslationServer.translate(panel_script.FOR_FRIEND_KEY)).contains("{friend}"),
			"NOTEBOOK_FOR_FRIEND debe tener {friend}")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_notebook_panel.gd :: no se pudo cargar` y `160 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir el tema provisional**

`scenes/ui/notebook_theme.tres`:

```ini
[gd_resource type="Theme" format=3]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_page"]
content_margin_left = 14.0
content_margin_top = 12.0
content_margin_right = 14.0
content_margin_bottom = 12.0
bg_color = Color(0.87, 0.82, 0.7, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.36, 0.25, 0.16, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tab_normal"]
content_margin_left = 8.0
content_margin_top = 3.0
content_margin_right = 8.0
content_margin_bottom = 3.0
bg_color = Color(0.76, 0.69, 0.55, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.45, 0.33, 0.22, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tab_hover"]
content_margin_left = 8.0
content_margin_top = 3.0
content_margin_right = 8.0
content_margin_bottom = 3.0
bg_color = Color(0.82, 0.76, 0.62, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.36, 0.25, 0.16, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tab_pressed"]
content_margin_left = 8.0
content_margin_top = 3.0
content_margin_right = 8.0
content_margin_bottom = 3.0
bg_color = Color(0.95, 0.91, 0.81, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.36, 0.25, 0.16, 1)

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]

[sub_resource type="StyleBoxLine" id="StyleBoxLine_separator"]
color = Color(0.45, 0.33, 0.22, 1)

[resource]
default_font_size = 15
Button/colors/font_color = Color(0.2, 0.14, 0.09, 1)
Button/colors/font_focus_color = Color(0.2, 0.14, 0.09, 1)
Button/colors/font_hover_color = Color(0.12, 0.08, 0.05, 1)
Button/colors/font_hover_pressed_color = Color(0.12, 0.08, 0.05, 1)
Button/colors/font_pressed_color = Color(0.12, 0.08, 0.05, 1)
Button/styles/focus = SubResource("StyleBoxEmpty_focus")
Button/styles/hover = SubResource("StyleBoxFlat_tab_hover")
Button/styles/normal = SubResource("StyleBoxFlat_tab_normal")
Button/styles/pressed = SubResource("StyleBoxFlat_tab_pressed")
HSeparator/styles/separator = SubResource("StyleBoxLine_separator")
Label/colors/font_color = Color(0.2, 0.14, 0.09, 1)
NotebookPage/base_type = &"PanelContainer"
NotebookPage/styles/panel = SubResource("StyleBoxFlat_page")
RichTextLabel/colors/default_color = Color(0.2, 0.14, 0.09, 1)
```

- [ ] **Paso 4: Escribir la escena del panel**

`scenes/ui/notebook_panel.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/notebook_panel.gd" id="panel_script"]
[ext_resource type="Theme" path="res://scenes/ui/notebook_theme.tres" id="notebook_theme"]

[node name="NotebookPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
theme = ExtResource("notebook_theme")
script = ExtResource("panel_script")

[node name="Page" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 820.0
offset_top = 11.0
offset_right = 1269.0
offset_bottom = 707.0
mouse_filter = 0
theme_type_variation = &"NotebookPage"

[node name="Layout" type="VBoxContainer" parent="Page"]
layout_mode = 2

[node name="Friend" type="Label" parent="Page/Layout"]
layout_mode = 2
theme_override_font_sizes/font_size = 13
horizontal_alignment = 2

[node name="Index" type="HFlowContainer" parent="Page/Layout"]
layout_mode = 2

[node name="Separator" type="HSeparator" parent="Page/Layout"]
layout_mode = 2

[node name="Scroll" type="ScrollContainer" parent="Page/Layout"]
layout_mode = 2
size_flags_vertical = 3
horizontal_scroll_mode = 0

[node name="Content" type="VBoxContainer" parent="Page/Layout/Scroll"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="Page/Layout/Scroll/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 22
autowrap_mode = 3

[node name="Sketch" type="TextureRect" parent="Page/Layout/Scroll/Content"]
visible = false
layout_mode = 2
size_flags_horizontal = 4

[node name="Body" type="RichTextLabel" parent="Page/Layout/Scroll/Content"]
layout_mode = 2
mouse_filter = 1
bbcode_enabled = true
fit_content = true
scroll_active = false
```

- [ ] **Paso 5: Escribir el script del panel**

`scripts/ui/notebook_panel.gd`:

```gdscript
extends Control
## Cuaderno (Plan 4, diseño §12): un índice con una pestaña por entidad conocida y la página de la elegida.
## Muestra la página que tiene abierta el amigo del chat (NotebookMemory) y salta a la de otro amigo
## al cambiar de chat. Elegir una pestaña abre esa página para ese amigo, y el chat muestra sus acciones
## para responder. Va a la derecha, como espejo del chat, y es independiente de él (decisión de Benja).
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const NotebookPage := preload("res://scripts/core/notebook_page.gd")

## Textos del panel (ui.csv). NOTEBOOK_FOR_FRIEND lleva {friend}.
const PICK_ENTITY_KEY := "NOTEBOOK_PICK_ENTITY"
const FOR_FRIEND_KEY := "NOTEBOOK_FOR_FRIEND"

## El amigo cuya página se muestra: el del chat.
var friend_index := 0

var _memory: NotebookMemory
var _entities: Array[EntityData] = []
var _friend_names: Array[String] = []
var _tabs: Array[Button] = []
## La entidad cuya página se ve ahora: al cambiar de página, la página vuelve arriba.
var _shown_entity: EntityData

@onready var _page: PanelContainer = $Page
@onready var _friend_label: Label = $Page/Layout/Friend
@onready var _index: HFlowContainer = $Page/Layout/Index
@onready var _scroll: ScrollContainer = $Page/Layout/Scroll
@onready var _title: Label = $Page/Layout/Scroll/Content/Title
@onready var _sketch: TextureRect = $Page/Layout/Scroll/Content/Sketch
@onready var _body: RichTextLabel = $Page/Layout/Scroll/Content/Body


func _ready() -> void:
	hide()
	_page.gui_input.connect(_on_page_gui_input)


## Conecta el cuaderno a la memoria de páginas. Crea una pestaña por cada entidad de `entities`
## (las conocidas en la noche), en orden.
func setup(memory: NotebookMemory, entities: Array[EntityData], friends: Array[FriendData]) -> void:
	_memory = memory
	_entities = entities
	for friend: FriendData in friends:
		_friend_names.append(tr(friend.name_key))
	var tab_group := ButtonGroup.new()
	for entity: EntityData in entities:
		var tab := Button.new()
		tab.text = tr(entity.name_key)
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.pressed.connect(_on_tab_pressed.bind(entity))
		_index.add_child(tab)
		_tabs.append(tab)
	memory.page_changed.connect(_on_page_changed)
	_refresh()


## Abre el cuaderno en la página del amigo `index`.
func open_for(index: int) -> void:
	select_friend(index)
	show()


## Muestra la página del amigo `index`, sin abrir ni cerrar el cuaderno. Se llama al cambiar de chat.
func select_friend(index: int) -> void:
	friend_index = index
	_refresh()


func _refresh() -> void:
	if _memory == null:
		return
	var entity := _memory.page_for(friend_index)
	_friend_label.text = tr(FOR_FRIEND_KEY).format({"friend": _friend_names[friend_index]})
	for index in _tabs.size():
		_tabs[index].set_pressed_no_signal(_entities[index] == entity)
	if entity != _shown_entity:
		_shown_entity = entity
		_scroll.scroll_vertical = 0
	_title.visible = entity != null
	_sketch.visible = entity != null and entity.sketch != null
	if entity == null:
		_body.text = tr(PICK_ENTITY_KEY)
		return
	_title.text = tr(entity.name_key)
	_sketch.texture = entity.sketch
	_body.text = NotebookPage.bbcode(entity, tr)


func _on_tab_pressed(entity: EntityData) -> void:
	_memory.open_page(friend_index, entity)


func _on_page_changed(index: int, _entity: EntityData) -> void:
	if index == friend_index:
		_refresh()


## El cuaderno tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_page_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_page.accept_event()
```

- [ ] **Paso 6: Agregar los textos del panel**

Agregar al final de `data/text/ui.csv`:

```csv
NOTEBOOK_PICK_ENTITY,Elige una entidad en el índice,
NOTEBOOK_FOR_FRIEND,Ayudando a {friend},
```

- [ ] **Paso 7: Importar y verificar que pasan**

Esperado: `168 pruebas OK, 0 fallidas`.

- [ ] **Paso 8: Commit**

```bash
git add scenes/ui/ scripts/ui/ test/ data/text/
git commit -m "Panel del cuaderno" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Responder desde el chat, con el cuaderno en el escritorio

**Archivos:**

- Reescribir: `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scripts/desk/desk.gd`, `test/test_chat_panel.gd`
- Modificar: `scenes/desk/desk.tscn`, `test/test_desk_scene.gd`, `data/text/ui.csv`

El chat agrega los botones de respuesta y la señal `friend_selected`, y deja de cerrarse solo con `Esc` o con un clic fuera: eso pasa al escritorio. El escritorio agrega el cuaderno y conecta los dos paneles. Las pruebas de `Esc` y del clic fuera pasan de `test_chat_panel.gd` a `test_desk_scene.gd`.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_panel.gd` (archivo completo; reemplaza las pruebas de `Esc` y del clic izquierdo fuera, y agrega las de las respuestas):

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager
var _memory: NotebookMemory


## Panel conectado a un manager con el catálogo de prueba (noche 1, sin solicitudes que lleguen solas)
## y a la memoria del cuaderno de los 3 amigos.
func _make_panel() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.night_number = 1
	_manager.random_seed = 4
	_manager.requests_arrive = false
	root.add_child(_manager)
	_memory = NotebookMemory.new(_manager.catalog.friends.size())
	var panel := PANEL.instantiate()
	root.add_child(panel)
	panel.setup(_manager, _manager.catalog.friends, _memory)
	return panel


func _free(panel: Control) -> void:
	panel.free()
	_manager.free()


func _click_at(button: MouseButton, position: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = position
	return click


func _question_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("Panel/Questions").get_children()


func _answer_buttons(panel: Control) -> Array[Node]:
	return panel.get_node("Panel/Answers").get_children()


## La única entidad de la noche 1 del catálogo de prueba.
func _beast() -> EntityData:
	return _manager.catalog.nights[0].new_entities[0]


func test_empieza_oculto_y_se_abre_en_un_amigo() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for(1)
	check(panel.visible, "visible tras abrir")
	check_eq(panel.selected_friend, 1, "amigo elegido")
	var tabs := panel.get_node("Panel/Tabs").get_children()
	check_eq(tabs.size(), 3, "una pestaña por amigo")
	check((tabs[1] as Button).button_pressed and not (tabs[0] as Button).button_pressed, "pestaña de Gonzalo")
	var conversations := panel.get_node("Panel/Conversations").get_children()
	check((conversations[1] as Control).visible and not (conversations[0] as Control).visible, "su conversación")
	_free(panel)
	return true


func test_avisa_al_elegir_un_amigo() -> bool:
	var panel := _make_panel()
	var selected := []
	panel.friend_selected.connect(func(friend_index: int) -> void: selected.append(friend_index))
	panel.open_for(2)
	(panel.get_node("Panel/Tabs").get_child(1) as Button).pressed.emit()
	check_eq(selected, [2, 1], "Agustín y después Gonzalo")
	_free(panel)
	return true


func test_clic_derecho_sobre_el_panel_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	(panel.get_node("Panel") as Control).gui_input.emit(_click_at(MOUSE_BUTTON_RIGHT, Vector2(100, 100)))
	check(not panel.visible, "oculto tras clic derecho")
	_free(panel)
	return true


func test_cada_mensaje_va_a_la_conversacion_de_su_amigo() -> bool:
	var panel := _make_panel()
	_manager.start_request(2)
	check_eq(panel.message_views(2).size(), 1, "mensaje de Agustín")
	check_eq(panel.message_views(0).size(), 0, "León sin mensajes")
	_free(panel)
	return true


func test_pestana_con_tiempo_y_aviso() -> bool:
	var panel := _make_panel()
	_manager.start_request(2)
	panel._process(0.0)
	var tab := panel.get_node("Panel/Tabs").get_child(2) as Button
	check(tab.text.contains("45"), "muestra el tiempo: %s" % tab.text)
	check(tab.text.contains(panel.UNREAD_MARK), "avisa del mensaje nuevo: %s" % tab.text)
	panel.open_for(2)
	check(not tab.text.contains(panel.UNREAD_MARK), "al abrirla, el aviso se va: %s" % tab.text)
	_free(panel)
	return true


func test_preguntas() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	check_eq(_question_buttons(panel).size(), 4, "4 preguntas")
	check((_question_buttons(panel)[0] as Button).disabled, "sin solicitud no se pregunta")
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (_question_buttons(panel)[0] as Button).disabled, "con solicitud se pregunta")
	(_question_buttons(panel)[0] as Button).pressed.emit()
	check_eq(panel.message_views(0).size(), 3, "mensaje, pregunta y respuesta")
	check_eq(request.time_left, 40.0, "costó 5 s")
	request.time_left = 5.0
	panel._process(0.0)
	check((_question_buttons(panel)[0] as Button).disabled, "con 5 s o menos no se pregunta")
	_free(panel)
	return true


func test_barra_de_identificacion() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var progress := panel.get_node("Panel/IdentifyBar/Progress") as Label
	var entity_button := panel.get_node("Panel/IdentifyBar/EntityName") as Button
	check(not progress.visible and not entity_button.visible, "sin solicitud, la barra está vacía")
	var request := _manager.start_request(0)
	panel._process(0.0)
	check_eq(progress.text, tr(panel.PROGRESS_KEY).format({"marked": 0, "total": 2}), "0 de 2")
	var message: ChatMessage = (panel.message_views(0)[0] as ChatMessageView).message
	for trait_data: TraitData in request.traits:
		_manager.click_clue(message, trait_data.id)
	panel._process(0.0)
	check_eq(progress.text, tr(panel.THINKING_KEY), "Matías piensa")
	_manager.advance(3.1)
	panel._process(0.0)
	check(entity_button.visible and not progress.visible, "aparece el nombre")
	check_eq(entity_button.text, tr(request.entity.name_key), "nombre de la entidad")
	var opened := []
	panel.entity_page_requested.connect(func(friend_index: int, entity: EntityData) -> void:
		opened.append([friend_index, entity]))
	entity_button.pressed.emit()
	check_eq(opened, [[0, request.entity]], "pide abrir su página")
	_free(panel)
	return true


func test_clic_en_un_senuelo_lo_hace_vibrar() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var request := _manager.start_request(0)
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment("Hay *algo*", request.decoys[0].id)
	_manager.message_added.emit(0, message)
	var view: ChatMessageView = panel.message_views(0)[-1]
	view.clue_clicked.emit(view, request.decoys[0].id)
	check_eq(request.clue_state(request.decoys[0].id), FriendRequest.ClueState.DECOY, "queda en rojo")
	check((view.get_node("Bubble/Text") as RichTextLabel).text.contains("[shake"), "vibra")
	_free(panel)
	return true


func test_pide_abrir_el_cuaderno_para_responder() -> bool:
	var panel := _make_panel()
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text, tr(panel.OPEN_NOTEBOOK_KEY), "aviso")
	check(not (panel.get_node("Panel/Answers") as Control).visible, "sin página no hay botones de respuesta")
	_free(panel)
	return true


func test_responde_con_las_acciones_de_la_pagina_abierta() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	panel._process(0.0)
	check((panel.get_node("Panel/Answers") as Control).visible, "botones de respuesta visibles")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text,
			tr(panel.ANSWER_FROM_PAGE_KEY).format({"entity": tr(_beast().name_key)}), "de qué página son")
	var buttons := _answer_buttons(panel)
	check_eq(buttons.map(func(button: Button) -> String: return button.text),
			_beast().actions.map(func(action: ActionData) -> String: return tr(action.label_key)), "las 4 acciones")
	check((buttons[0] as Button).disabled, "sin solicitud no se responde")
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (buttons[0] as Button).disabled, "con solicitud se responde")
	(buttons[2] as Button).pressed.emit()
	check(request.finished and request.answered_by_player, "respondió Matías")
	check_eq(request.chosen_action, _beast().actions[2], "con la tercera acción de la página")
	check_eq(panel.message_views(0).size(), 3, "mensaje, respuesta y reacción")
	_free(panel)
	return true


func test_cada_amigo_responde_desde_su_pagina() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _beast())
	panel.open_for(1)
	check(not (panel.get_node("Panel/Answers") as Control).visible, "Gonzalo no tiene página abierta")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text, tr(panel.OPEN_NOTEBOOK_KEY), "pide abrir el cuaderno")
	_free(panel)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.PROGRESS_KEY, panel_script.THINKING_KEY, panel_script.OPEN_NOTEBOOK_KEY,
			panel_script.ANSWER_FROM_PAGE_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var progress := String(TranslationServer.translate(panel_script.PROGRESS_KEY))
	check(progress.contains("{marked}") and progress.contains("{total}"), "IDENTIFY_PROGRESS debe tener {marked} y {total}")
	check(String(TranslationServer.translate(panel_script.ANSWER_FROM_PAGE_KEY)).contains("{entity}"),
			"ANSWER_FROM_PAGE debe tener {entity}")
	TranslationServer.set_locale(previous)
	return true
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
```

por:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
func test_camara_con_zoom_leve_y_centrada() -> bool:
```

por:

```gdscript
## Abre el chat de León y, con un clic en el cuaderno del escritorio, el cuaderno.
func _open_panels(desk: Node2D) -> void:
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk.get_node("DeskPlane/Notebook").clicked.emit()


func _panels_closed(desk: Node2D) -> bool:
	return not (desk.get_node("UI/ChatPanel") as Control).visible \
			and not (desk.get_node("UI/NotebookPanel") as Control).visible


func _click(button: MouseButton) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = Vector2(1100, 300)
	return click


func test_el_cuaderno_y_el_chat_son_independientes() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel") as Control
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(notebook.visible and not chat.visible, "el cuaderno se abre solo")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	check(notebook.visible and chat.visible, "abrir el chat no cierra el cuaderno")
	check_eq(notebook.get("friend_index"), 1, "el cuaderno salta a la página de Gonzalo")
	notebook.hide()
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(notebook.visible and chat.visible, "abrir el cuaderno no cierra el chat")
	desk.free()
	return true


func test_esc_y_un_clic_fuera_cierran_los_paneles() -> bool:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	var events := {
		"Esc": escape,
		"clic derecho fuera": _click(MOUSE_BUTTON_RIGHT),
		"clic izquierdo fuera": _click(MOUSE_BUTTON_LEFT),
	}
	for event_name: String in events:
		var desk := _make_desk()
		_open_panels(desk)
		desk._unhandled_input(events[event_name])
		check(_panels_closed(desk), "cerrados con %s" % event_name)
		desk.free()
	return true


func test_clic_derecho_sobre_un_panel_cierra_solo_ese() -> bool:
	var desk := _make_desk()
	_open_panels(desk)
	var chat := desk.get_node("UI/ChatPanel") as Control
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	(notebook.get_node("Page") as Control).gui_input.emit(_click(MOUSE_BUTTON_RIGHT))
	check(not notebook.visible and chat.visible, "se cierra solo el cuaderno")
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	(chat.get_node("Panel") as Control).gui_input.emit(_click(MOUSE_BUTTON_RIGHT))
	check(not chat.visible and notebook.visible, "se cierra solo el chat")
	desk.free()
	return true


func test_el_celular_y_el_mixer_cierran_los_paneles() -> bool:
	for object_name: String in ["Phone", "Mixer"]:
		var desk := _make_desk()
		_open_panels(desk)
		desk.get_node("DeskPlane/" + object_name).clicked.emit()
		check(_panels_closed(desk), "cerrados con %s" % object_name)
		desk.free()
	return true


func test_el_nombre_de_la_entidad_abre_su_pagina() -> bool:
	var desk := _make_desk()
	var trauco: EntityData = desk.get_node("RequestManager").catalog.known_entities(3)[0]
	desk.get_node("UI/ChatPanel").entity_page_requested.emit(1, trauco)
	check_eq(desk.notebook_memory.page_for(1), trauco, "Gonzalo tiene abierta la página")
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	check(notebook.visible, "cuaderno abierto")
	check_eq(notebook.get("friend_index"), 1, "con la página de Gonzalo")
	desk.free()
	return true


func test_al_cambiar_de_chat_el_cuaderno_salta() -> bool:
	var desk := _make_desk()
	_open_panels(desk)
	desk.get_node("UI/ChatPanel").open_for(2)
	check_eq(desk.get_node("UI/NotebookPanel").get("friend_index"), 2, "salta a la página de Agustín")
	desk.free()
	return true


func test_una_solicitud_nueva_empieza_en_el_indice() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	desk.notebook_memory.open_page(2, manager.catalog.known_entities(3)[0])
	manager.start_request(2)
	check_eq(desk.notebook_memory.page_for(2), null, "Agustín vuelve al índice")
	desk.free()
	return true


func test_se_responde_desde_el_cuaderno() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	var request: RefCounted = manager.start_request(0)
	check(request != null, "la noche del escritorio tiene entidades")
	if request == null:
		desk.free()
		return true
	var entity: EntityData = request.get("entity")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	var panel := desk.get_node("UI/ChatPanel")
	panel.entity_page_requested.emit(0, entity)
	panel._process(0.0)
	var rule := RuleEvaluator.applicable_rule(entity, request.get("situation"))
	var correct := entity.actions.find(entity.find_action(rule.correct_action_id))
	(panel.get_node("Panel/Answers").get_child(correct) as Button).pressed.emit()
	check(request.get("finished"), "la solicitud terminó")
	check_eq(request.get("outcome"), RuleEvaluator.Outcome.CORRECT, "con la acción correcta")
	check_eq(manager.requests[0], null, "León queda libre")
	desk.free()
	return true


func test_camara_con_zoom_leve_y_centrada() -> bool:
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: fallan las 12 pruebas de `test_chat_panel.gd` y las 8 nuevas de `test_desk_scene.gd`, con `157 pruebas OK, 20 fallidas`. El chat del Plan 3 recibe solo 2 argumentos en `setup()`, y el escritorio todavía no tiene el cuaderno.

- [ ] **Paso 3: Hacer lugar para las respuestas en la escena del chat**

La conversación se achica de 448 a 370 px. Debajo van la barra de identificación, las preguntas, el título de las respuestas y los 4 botones.

`scenes/ui/chat_panel.tscn` (archivo completo):

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/chat_panel.gd" id="panel_script"]
[ext_resource type="Texture2D" path="res://art/sprites/screen_sprite.aseprite" id="panel_texture"]
[ext_resource type="Theme" path="res://scenes/ui/chat_theme.tres" id="chat_theme"]

[node name="ChatPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
theme = ExtResource("chat_theme")
script = ExtResource("panel_script")

[node name="Panel" type="TextureRect" parent="."]
layout_mode = 0
offset_left = 11.0
offset_top = 11.0
offset_right = 460.0
offset_bottom = 707.0
mouse_filter = 0
texture = ExtResource("panel_texture")

[node name="Tabs" type="HBoxContainer" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 25.0
offset_right = 423.0
offset_bottom = 55.0

[node name="Conversations" type="Control" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 61.0
offset_right = 423.0
offset_bottom = 431.0
mouse_filter = 2

[node name="IdentifyBar" type="HBoxContainer" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 437.0
offset_right = 423.0
offset_bottom = 465.0

[node name="Progress" type="Label" parent="Panel/IdentifyBar"]
layout_mode = 2
size_flags_horizontal = 3
horizontal_alignment = 1
vertical_alignment = 1

[node name="EntityName" type="Button" parent="Panel/IdentifyBar"]
visible = false
layout_mode = 2
size_flags_horizontal = 3

[node name="Questions" type="GridContainer" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 471.0
offset_right = 423.0
offset_bottom = 535.0
columns = 2

[node name="AnswerHint" type="Label" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 541.0
offset_right = 423.0
offset_bottom = 561.0
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3

[node name="Answers" type="GridContainer" parent="Panel"]
visible = false
layout_mode = 0
offset_left = 25.0
offset_top = 565.0
offset_right = 423.0
offset_bottom = 671.0
columns = 2
```

- [ ] **Paso 4: Escribir el script del chat**

`scripts/ui/chat_panel.gd` (archivo completo):

```gdscript
extends Control
## Panel del chat (planes 3 y 4): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la barra de identificación, las preguntas y las respuestas. Los botones de respuesta
## son las acciones de la página que el cuaderno tiene abierta para ese amigo (diseño §8.5).
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

## Clic en el nombre de la entidad: el cuaderno abre su página.
signal entity_page_requested(friend_index: int, entity: EntityData)
## Se eligió la conversación de un amigo: el cuaderno salta a su página.
signal friend_selected(friend_index: int)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}; ANSWER_FROM_PAGE lleva {entity}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
const ANSWER_FROM_PAGE_KEY := "ANSWER_FROM_PAGE"
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"
## Un botón de respuesta por acción: cada entidad tiene 4 (docs/02 §5.1).
const ANSWER_COUNT := 4

var selected_friend := 0

var _manager: RequestManager
var _memory: NotebookMemory
var _friend_names: Array[String] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []
var _answer_buttons: Array[Button] = []

@onready var _panel: TextureRect = $Panel
@onready var _tab_bar: HBoxContainer = $Panel/Tabs
@onready var _conversation_area: Control = $Panel/Conversations
@onready var _progress: Label = $Panel/IdentifyBar/Progress
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _questions: GridContainer = $Panel/Questions
@onready var _answer_hint: Label = $Panel/AnswerHint
@onready var _answers: GridContainer = $Panel/Answers


func _ready() -> void:
	hide()
	_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
	for category: ClueCategory.Kind in MessageBuilder.QUESTION_KEYS:
		var button := Button.new()
		button.text = tr(MessageBuilder.QUESTION_KEYS[category])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
	for index in ANSWER_COUNT:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Las acciones pueden ser largas: el botón crece hacia abajo en vez de salirse del panel.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_answer_pressed.bind(index))
		_answers.add_child(button)
		_answer_buttons.append(button)
	_entity_button.pressed.connect(_on_entity_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)


## Conecta el panel a las solicitudes y a la memoria del cuaderno. Crea una pestaña y una conversación
## por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData], memory: NotebookMemory) -> void:
	_manager = manager
	_memory = memory
	var tab_group := ButtonGroup.new()
	for index in friends.size():
		_friend_names.append(tr(friends[index].name_key))
		_unread.append(false)
		var tab := Button.new()
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(open_for.bind(index))
		_tab_bar.add_child(tab)
		_tabs.append(tab)
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override(&"separation", 6)
		scroll.add_child(list)
		# Cuando la conversación crece (mensaje nuevo o escritura progresiva), baja hasta el final.
		scroll.get_v_scroll_bar().changed.connect(_scroll_to_bottom.bind(scroll))
		_conversation_area.add_child(scroll)
		_scrolls.append(scroll)
		_lists.append(list)
	manager.message_added.connect(_on_message_added)
	manager.request_changed.connect(_on_request_changed)
	manager.request_finished.connect(_on_request_changed)
	_select(selected_friend)


## Abre el panel en la conversación del amigo `friend_index`.
func open_for(friend_index: int) -> void:
	_select(friend_index)
	show()


## Mensajes de un amigo, en orden.
func message_views(friend_index: int) -> Array[Node]:
	return _lists[friend_index].get_children()


func _process(_delta: float) -> void:
	_update_status()


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación, las preguntas y las respuestas.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	_update_questions()
	_update_answers()


func _select(friend_index: int) -> void:
	selected_friend = friend_index
	_unread[friend_index] = false
	for index in _scrolls.size():
		_scrolls[index].visible = index == friend_index
		_tabs[index].set_pressed_no_signal(index == friend_index)
	_update_status()
	friend_selected.emit(friend_index)


func _tab_text(index: int) -> String:
	var text := _friend_names[index]
	var request := _manager.requests[index]
	if request != null:
		text += "  %d" % ceili(request.time_left)
	if _unread[index]:
		text += "  " + UNREAD_MARK
	return text


## Sobre las preguntas: cuántas características van marcadas, "Matías piensa…" o el nombre de la entidad.
func _update_identify_bar() -> void:
	var request := _manager.requests[selected_friend]
	var revealed := request != null and request.identification == FriendRequest.Identification.REVEALED
	_progress.visible = request != null and not revealed
	_entity_button.visible = revealed
	if request == null:
		return
	match request.identification:
		FriendRequest.Identification.PENDING:
			_progress.text = tr(PROGRESS_KEY).format({"marked": request.marked_count(), "total": request.traits.size()})
		FriendRequest.Identification.THINKING:
			_progress.text = tr(THINKING_KEY)
		FriendRequest.Identification.REVEALED:
			_entity_button.text = tr(request.entity.name_key)


## Con 5 s o menos, o sin solicitud, no se puede preguntar.
func _update_questions() -> void:
	var request := _manager.requests[selected_friend]
	var can_ask := request != null and request.can_ask()
	for button: Button in _questions.get_children():
		button.disabled = not can_ask


## Las acciones de la página que el cuaderno tiene abierta para este amigo. Sin página, el aviso
## "Abre el cuaderno para responder". Sin solicitud, los botones se ven pero no responden.
func _update_answers() -> void:
	var page := _memory.page_for(selected_friend)
	_answers.visible = page != null
	if page == null:
		_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
		return
	_answer_hint.text = tr(ANSWER_FROM_PAGE_KEY).format({"entity": tr(page.name_key)})
	var waiting := _manager.requests[selected_friend] != null
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < page.actions.size()
		if button.visible:
			button.text = tr(page.actions[index].label_key)
		button.disabled = not waiting


func _on_message_added(friend_index: int, message: ChatMessage) -> void:
	var view := ChatMessageView.new(message)
	view.clue_clicked.connect(_on_clue_clicked)
	_lists[friend_index].add_child(view)
	if message.sender == ChatMessage.Sender.FRIEND and not (visible and friend_index == selected_friend):
		_unread[friend_index] = true


func _on_clue_clicked(view: ChatMessageView, clue_id: StringName) -> void:
	if _manager.click_clue(view.message, clue_id) == FriendRequest.ClueState.DECOY:
		view.shake(clue_id)


## Vuelve a armar los mensajes de esa solicitud: frases marcadas, en rojo o sin enlaces si terminó.
func _on_request_changed(friend_index: int, request: FriendRequest) -> void:
	for view: ChatMessageView in message_views(friend_index):
		if view.message.request == request:
			view.refresh()


func _on_question_pressed(category: ClueCategory.Kind) -> void:
	_manager.ask(selected_friend, category)


## Responde con la acción `index` de la página abierta para este amigo.
func _on_answer_pressed(index: int) -> void:
	var page := _memory.page_for(selected_friend)
	if page != null and index < page.actions.size():
		_manager.answer(selected_friend, page.actions[index])


func _on_entity_pressed() -> void:
	var request := _manager.requests[selected_friend]
	if request != null:
		entity_page_requested.emit(selected_friend, request.entity)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## El panel tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_panel_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_panel.accept_event()
```

- [ ] **Paso 5: Agregar el título de las respuestas**

Agregar al final de `data/text/ui.csv`:

```csv
ANSWER_FROM_PAGE,Acciones de {entity},
```

- [ ] **Paso 6: Agregar el cuaderno al escritorio**

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="Resource" path="res://data/catalog.tres" id="catalog"]
```

por:

```ini
[ext_resource type="Resource" path="res://data/catalog.tres" id="catalog"]
[ext_resource type="PackedScene" path="res://scenes/ui/notebook_panel.tscn" id="notebook_panel"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="ChatPanel" parent="UI" instance=ExtResource("chat_panel")]
```

por:

```ini
[node name="ChatPanel" parent="UI" instance=ExtResource("chat_panel")]

[node name="NotebookPanel" parent="UI" instance=ExtResource("notebook_panel")]
```

`scripts/desk/desk.gd` (archivo completo):

```gdscript
extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo (parpadean
## y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación. El cuaderno se abre
## con un clic en él o en el nombre de la entidad, y muestra la página del amigo del chat. El chat y el
## cuaderno son independientes y pueden estar abiertos a la vez (decisión de Benja). Cada uno se cierra
## con clic derecho sobre él; Esc o un clic fuera de los paneles cierra los dos.
## Un clic en el celular o el mixer cierra los paneles y por ahora solo se registra (sus vistas, en el Plan 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
var notebook_memory: NotebookMemory

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _notebook_panel: Control = $UI/NotebookPanel
@onready var _requests: RequestManager = $RequestManager


func _ready() -> void:
	var friends := _requests.catalog.friends
	notebook_memory = NotebookMemory.new(friends.size())
	_chat_panel.setup(_requests, friends, notebook_memory)
	_notebook_panel.setup(notebook_memory, _requests.catalog.known_entities(_requests.night_number), friends)
	for index in _entries.size():
		_entries[index].display_name = tr(friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.friend_selected.connect(_notebook_panel.select_friend)
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
	_requests.request_started.connect(_on_request_started)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
	for clickable_name in ["Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void:
			close_panels()
			print("Clic en ", clickable_name))


func _process(_delta: float) -> void:
	_refresh_entries()


## Cierra el chat y el cuaderno. El celular y el mixer se usan sin ningún panel abierto (decisión de Benja).
func close_panels() -> void:
	_chat_panel.hide()
	_notebook_panel.hide()


## El escritorio es el último en recibir la entrada: aquí llega lo que nadie atendió. Las entradas del PC
## y los objetos del escritorio consumen sus clics, y los paneles, los que caen sobre ellos.
## Esc o un clic fuera de los paneles los cierra.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible):
		return
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	if event.is_action_pressed(&"ui_cancel") or click:
		close_panels()
		get_viewport().set_input_as_handled()


func _on_entry_pressed(index: int) -> void:
	_chat_panel.open_for(index)
	_refresh_entries()


## Abre el cuaderno en la página del amigo del chat. El chat queda como estaba: abierto o cerrado.
func _open_notebook() -> void:
	_notebook_panel.open_for(_chat_panel.selected_friend)


func _on_entity_page_requested(friend_index: int, entity: EntityData) -> void:
	notebook_memory.open_page(friend_index, entity)
	_notebook_panel.open_for(friend_index)


## Una solicitud nueva empieza en el índice: la página de la anterior casi nunca sirve (decisión de Benja).
func _on_request_started(friend_index: int, _request: FriendRequest) -> void:
	notebook_memory.close_page(friend_index)


## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta. El tiempo, mientras espera.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		if entry.state != state:
			entry.set_state(state)
		entry.set_seconds_left(ceili(request.time_left) if request != null else -1)
```

Que cada panel reciba los clics de su área, y que el escritorio reciba solo lo que nadie atendió, no tiene prueba automática: sin ventana, Godot no mueve el mouse. Se revisa a mano en la sección H de `docs/04` (Tarea 7).

- [ ] **Paso 7: Importar y verificar que pasan**

Esperado: `177 pruebas OK, 0 fallidas`.

- [ ] **Paso 8: Commit**

```bash
git add scenes/ scripts/ test/ data/text/
git commit -m "Responder desde el cuaderno" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_notebook.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `177 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Capturar el cuaderno y revisarlo**

`test/capture_notebook.gd` no empieza con `test_`, así que el ejecutor de pruebas no lo corre.

`test/capture_notebook.gd`:

```gdscript
extends SceneTree
## Captura del cuaderno para revisarlo a ojo (Plan 4). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_notebook.gd -- /mnt/c/dev/capturas/notebook.png
## León recibe una solicitud. Se marcan sus 2 características y, al clickear el nombre que aparece,
## el cuaderno se abre en la página de la entidad, con sus acciones en los botones de respuesta del chat.

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	var panel := desk.get_node("UI/ChatPanel")
	manager.requests_arrive = false
	manager.rng.seed = 5
	var request: RefCounted = manager.start_request(0)
	panel.open_for(0)
	await create_timer(2.0).timeout
	var view: Node = panel.message_views(0)[0]
	for trait_data: TraitData in request.get("traits"):
		view.clue_clicked.emit(view, trait_data.id)
	await create_timer(3.5).timeout
	(panel.get_node("Panel/IdentifyBar/EntityName") as Button).pressed.emit()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
	quit()
```

Se ejecuta **con ventana** (sin `--headless`): Godot abre una ventana unos 6 segundos y se cierra solo.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_notebook.gd -- /mnt/c/dev/capturas/notebook.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: `Captura guardada en C:\dev\capturas\notebook.png`. Abrir la imagen (con la herramienta Read) y comprobar:

- a la izquierda, el chat de León: el mensaje con las 2 características en verde, la barra con el nombre "El Trauco", las 4 preguntas, el título "Acciones de El Trauco" y 4 botones con las acciones;
- a la derecha, el cuaderno, en papel claro y del mismo tamaño que el chat:
  - arriba, "Ayudando a León" y la pestaña "El Trauco" marcada;
  - el título, el folclore, y las características y observaciones, cada una con su pregunta entre paréntesis;
  - las reglas, con la acción correcta en verde y, después de "Mayor riesgo:", la otra en rojo;
- al centro, el PC con la entrada de León seleccionada. Los diales quedan tapados por el cuaderno.

Si algo no coincide, revisarlo antes de seguir.

- [ ] **Paso 3: Actualizar las instrucciones de Godot (`docs/04_instrucciones_godot.md`)**

En la tabla **Estado**, agregar la fila `| **H.** Probar el cuaderno (Plan 4) | ⬜ Pendiente (unos 10 minutos) |` debajo de la de G.

Las secciones C y G mencionan lo que hacía el cuaderno antes del Plan 4. En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
   - **Clics:** al hacer clic en el cuaderno, el celular o el mixer, en el panel **Output** (Salida) de Godot aparece "Clic en Notebook", "Clic en Phone" o "Clic en Mixer".
```

por:

```markdown
   - **Clics:** al hacer clic en el celular o el mixer, en el panel **Output** (Salida) de Godot aparece "Clic en Phone" o "Clic en Mixer". Al hacer clic en el cuaderno, se abre su panel (Plan 4).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
   - Al clickear el nombre, en el panel **Output** (Salida) aparece "Abrir en el cuaderno la página de El Trauco (Plan 4)".
```

por:

```markdown
   - Al clickear el nombre, se abre el cuaderno en la página de El Trauco (se prueba en la sección H).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
6. **Sin respuesta:** si se acaba el tiempo, el amigo cuenta que decidió solo y su entrada deja de parpadear. Responder desde el cuaderno llega en el Plan 4.
```

por:

```markdown
6. **Sin respuesta:** si se acaba el tiempo, el amigo cuenta que decidió solo y su entrada deja de parpadear. Responder desde el cuaderno se prueba en la sección H.
```

Al final del archivo, agregar una línea en blanco y, después:

````markdown
---

## H. Probar el cuaderno (Plan 4)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Identifica y abre la página:** cuando una entrada del PC parpadee, haz clic en ella. En el chat, clickea las 2 características hasta que aparezca el nombre (El Trauco) y haz clic en él.
   - A la derecha se abre el cuaderno, del mismo tamaño que el chat, en la página de El Trauco. Arriba dice "Ayudando a" y el nombre del amigo.
   - La página tiene el folclore, las características y las observaciones (cada una con la pregunta que la trae, entre paréntesis), las reglas y las acciones. Se scrollea con la rueda del mouse.
   - En cada regla, la acción correcta va en verde y la de mayor riesgo, después de "Mayor riesgo:", en rojo.
3. **Responde:** en el chat, bajo las preguntas, dice "Acciones de El Trauco" y hay 4 botones. Aplica las reglas a lo que cuenta el amigo y haz clic en una acción.
   - Tu acción aparece a la derecha del chat, y el amigo reacciona con un texto `[PROTO]` según si fue la correcta, la de mayor riesgo o una incorrecta.
   - La entrada del amigo deja de parpadear.
4. **Los paneles son independientes:**
   - con los dos abiertos, haz clic derecho sobre el cuaderno: se cierra solo el cuaderno;
   - haz clic en el cuaderno del escritorio (sobre la mesa, a la derecha): se vuelve a abrir, y el chat no cambia;
   - haz clic derecho sobre el chat: se cierra solo el chat, y el cuaderno sigue abierto;
   - con el cuaderno abierto, haz clic en otra entrada del PC: se abre el chat de ese amigo, y el cuaderno salta a su página. Si no tiene una, dice "Elige una entidad en el índice".
5. **Memoria por amigo:** abre la página de El Trauco para un amigo y cambia de pestaña en el chat: el cuaderno muestra la página de cada amigo. Cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice.
6. **Cerrar todo:** con los dos paneles abiertos, presiona `Esc`: se cierran los dos. Ábrelos de nuevo y haz clic en una parte vacía de la escena, como la pared sobre el PC: también se cierran los dos.
7. **El celular y el mixer:** con solo el cuaderno abierto, haz clic en el mixer. El cuaderno se cierra, y en el panel **Output** (Salida) aparece "Clic en Mixer".
8. **El cuaderno tapa el escritorio:** con el cuaderno abierto, pasa el mouse por donde está el cuaderno del escritorio, detrás del panel. No debe resaltarse.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para más adelante

- **El arte del cuaderno:** la página (449×696, como `screen_sprite`), las pestañas del índice y los bocetos de las entidades (unos 96×96). Cuando estén, Claude los pone en `scenes/ui/notebook_theme.tres` y en el **Sketch** de cada entidad.
````

- [ ] **Paso 4: Actualizar la hoja de ruta, el registro y el resumen**

- `docs/06_plan_v1.md`: en la línea del Plan 4, cambiar "(por ejecutar)" por "(ejecutado)".
- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos debe figurar la sección H de `docs/04`.
- `docs/00_log.md`:
  - S11 queda ✅;
  - S12 (escribir el Plan 5: consecuencias, medidores y noche) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/11` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/ scenes/
git commit -m "Plan 4 terminado: cuaderno" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 4, y diseño §7, §8.5 y §12):

  | Requisito | Tarea |
  | --- | --- |
  | Índice con una pestaña por entidad conocida | 5, y en el escritorio, 6 |
  | Página generada desde `EntityData`: folclore, boceto, características, observaciones con su pregunta, reglas con su acción correcta y su acción de mayor riesgo, y acciones | 2 y 5 |
  | Memoria de página por amigo, que salta al cambiar de chat | 1, 5 y 6 |
  | Una solicitud nueva vuelve al índice (decisión de Benja) | 6 |
  | Botones de respuesta con las acciones de la página abierta; sin página, "Abre el cuaderno para responder" | 6 |
  | Responder termina la solicitud, y desde otra página es incorrecto | 3 y 4 |
  | Reacción provisional según el resultado (decisión de Benja) | 3 y 4 |
  | Cuaderno a la derecha e independiente del chat; cierre por panel y de los dos (decisiones de Benja) | 5 y 6 |
  | "Se responde una solicitud desde el cuaderno" | 6 (`test_se_responde_desde_el_cuaderno`) y 7 (`docs/04`, H) |

- **Fuera de este plan, a propósito:**
  - **Consecuencias (Plan 5):** daño, aturdimiento, Trust y el video extra. `request_finished` ya lleva `chosen_action`, `answered_by_player` y `outcome`, y la reacción del amigo pasa a depender también de si quedó herido.
  - **Las vistas del celular y del mixer (Plan 6).** Por ahora, un clic en ellos cierra los paneles y se registra en Output.
  - **Screamers sobre el cuaderno (Plan 7).**
  - **Páginas nuevas entre noches y el resumen (Plan 8).** El cuaderno recibe las entidades conocidas cuando empieza la escena.
  - **Sonido** al abrir el cuaderno o al cambiar de página (Plan 9).
  - **Arte del cuaderno:** el tema es provisional.
  - **El desfase de un frame** entre las entradas del PC y las pestañas del chat (`resumen.md`, Sesión 9): no se nota al jugar.
- **Nombres consistentes:**
  - `NotebookMemory` (`page_for`, `open_page`, `close_page` y `page_changed`) se usa igual en el cuaderno, el chat, el escritorio y las pruebas;
  - `NotebookPage` (`bbcode`, `trait_label`, `CORRECT_COLOR`, `RISKY_COLOR` y las claves `*_KEY`) coincide con sus pruebas y con el panel;
  - `MessageBuilder` (`player_answer`, `reaction` y `REACTION_KEYS`) y `RequestManager.answer()` coinciden entre las tareas 3, 4 y 6;
  - `NotebookPanel` (`setup`, `open_for`, `select_friend`, `friend_index`, `PICK_ENTITY_KEY` y `FOR_FRIEND_KEY`) y `ChatPanel` (`setup` con la memoria, `friend_selected`, `ANSWER_FROM_PAGE_KEY` y `ANSWER_COUNT`) coinciden con sus pruebas y con `desk.gd`;
  - `desk.gd` (`notebook_memory` y `close_panels`) es lo que usan las pruebas del escritorio.
- **Conteo de pruebas acumulado:** 148 → 151, 156, 158, 160, 168 y 177.
