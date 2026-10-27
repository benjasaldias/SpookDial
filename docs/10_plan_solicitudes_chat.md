# Plan 3: Solicitudes y chat — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que los amigos envíen solicitudes al chat y que el jugador pueda identificar la entidad y hacer preguntas:

- un generador de solicitudes que elige la entidad, el lugar, la situación, las 2 características que la distinguen y los señuelos que las camuflan;
- mensajes armados con los textos de los CSV, con frases clickeables y con estática según la señal;
- una solicitud con temporizador, preguntas que cuestan 5 s, identificación por clics con 3 s de espera, y el amigo que decide solo si se acaba el tiempo;
- el panel del chat: una pestaña por amigo, escritura progresiva, barra de identificación, preguntas y el aviso "Abre el cuaderno para responder";
- las entradas del PC conectadas a las solicitudes: parpadean y muestran el tiempo mientras el amigo espera.

**Arquitectura:**

- `scripts/core/` (lógica pura, sin nodos): `FriendRequest` (una solicitud y su estado), `ChatMessage` (un mensaje separado en piezas), `ChatStatic` (la estática), `RequestGenerator` (arma solicitudes) y `MessageBuilder` (arma los mensajes con los textos). Se prueban sin escena.
- `scripts/desk/request_manager.gd`: un nodo de `desk.tscn` que maneja las solicitudes de la noche. Las genera con un ritmo provisional, avanza los temporizadores, recibe las preguntas y los clics, y avisa con señales.
- `scripts/ui/`: `ChatMessageView` (la burbuja de un mensaje) y `ChatPanel`, reescrito. El panel solo muestra y reenvía los clics: el estado vive en la solicitud.
- Datos: `DecoyData` (un señuelo) en `data/catalog.tres`, y en cada `NightData` cuántos señuelos trae el mensaje inicial.

**Stack:** Godot 4.7.2 (GDScript con tipado estático; `RichTextLabel` con BBCode para los mensajes). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §7–8, y `docs/02_bucle_central.md` §2–4, §6, §9 y §10.

---

## Decisiones de este plan

### De Benja (sesión 8, 26 y 27 de octubre)

Ya están en `CLAUDE.md`, en el diseño v2 y en `docs/02`.

| Decisión | Detalle |
| --- | --- |
| **El mensaje inicial trae 2 características camufladas entre señuelos.** | Las 2 distinguen a la entidad de las demás conocidas. Los señuelos son frases clickeables que no ayudan a identificar: describen el lugar, un olor, un sonido o algo que se ve. Al clickear un señuelo, vibra y se pone rojo. |
| **Señuelos por noche: 1, 1, 2, 2 y 3.** | Se ajustan en el Inspector de cada noche. |
| **Clickear un señuelo no cuesta nada**, aparte del tiempo del clic. | |
| **Barra fija con el avance de la identificación.** | Sobre las preguntas dice "Características marcadas: 1 de 2", luego "Matías piensa…" (3 s) y por último el nombre, que se puede clickear. Si la estática tapó una característica, se nota que falta. |
| **La estática tapa una frase clickeable entera o nada.** | Una frase de varias palabras cuenta como una sola palabra. |
| **Con 5 s o menos no se puede preguntar.** | Los botones de pregunta se desactivan. |
| **Las respuestas repiten solo lo del mensaje inicial**, sin señuelos nuevos. | Si ningún señuelo es de la categoría preguntada, la respuesta delata cuáles son las características. Se prueba así; si se nota demasiado, se agregan señuelos a las respuestas. |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| Los señuelos son `DecoyData`, una subclase de `TraitData` con `place_keys` (vacío: sirven en cualquier lugar), y viven en `ContentCatalog.decoys`. | Un señuelo tiene lo mismo que una característica (id, categoría y texto con asteriscos), pero no pertenece a una entidad. Con los lugares, puede haber señuelos propios del bosque, del camino, etc. |
| Cuántos señuelos trae el mensaje inicial es un dato de cada noche (`decoys_in_first_message`). | Es una palanca de dificultad que Benja ajusta en el Inspector (`docs/02` §6). |
| Las 2 características son un par que **ninguna otra entidad conocida tiene completo**, elegido al azar. | Así salen también las compartidas (como el olor a ungüento) y a veces hay que combinar dos pistas. |
| El validador exige que **ninguna entidad tenga todas sus características dentro de las de otra**. Antes solo prohibía que fueran iguales. | Con eso, y como cada característica la usan 2 entidades como máximo, siempre existe un par que distingue a cada entidad. |
| El validador revisa los señuelos: ids únicos y distintos de los de las características, lugares que existen y suficientes señuelos en cada lugar para lo que pide cada noche. | Un señuelo con el lugar mal escrito no aparecería nunca, y nadie se daría cuenta. |
| Para identificar hay que marcar **las 2 características del mensaje inicial**, en cualquier mensaje de esa solicitud. | Si la estática tapó una, se recupera preguntando por su categoría y se marca en la respuesta. |
| La respuesta a una pregunta repite las características y los señuelos del mensaje inicial que son de esa categoría, y **todas** las observaciones de esa categoría. | Así se recupera lo tapado y lo que el mensaje inicial no traía (noches 3 a 5). Si no hay nada, responde "nada" (un texto por categoría). |
| Un mensaje es una sola burbuja. Sus fragmentos (oraciones) se unen con un espacio, en este orden: el lugar, las características y los señuelos mezclados, y las observaciones. | Benja escribe cada fragmento como una oración completa, con su puntuación (`docs/02` §9). |
| `ChatMessage` guarda piezas (`Token`): palabras, espacios y frases clickeables. La estática marca piezas como tapadas, y la burbuja arma el BBCode con ellas. | La estática y los clics trabajan sobre las mismas piezas, sin volver a analizar el texto. Los espacios y los signos sueltos nunca se tapan. |
| Las frases clickeables son enlaces `[url]` de un `RichTextLabel`, y los corchetes del texto se escriben `[lb]`. | Así `[PROTO]` se ve como texto y no rompe el BBCode. Verificado en Godot 4.7.2. |
| El estado de cada frase (marcada o señuelo en rojo) vive en `FriendRequest`, y cada mensaje apunta a su solicitud. | Hay una sola fuente de verdad: si la frase aparece en dos mensajes, cambia en los dos. Los mensajes de una solicitud terminada ya no se pueden clickear. |
| `RequestManager` es un nodo de `desk.tscn` (no un autoload), con un `advance(delta)` público. | Las pruebas lo avanzan a mano, sin esperar frames. Los autoloads previstos (`GameState`, `EventBus`) llegarán cuando haga falta compartir estado entre escenas. |
| El ritmo es provisional: la primera solicitud llega a los 5 s y luego una cada 420 s ÷ solicitudes de la noche, sin pasar de las simultáneas ni del total. | Alcanza para probar. El director del Plan 7 lo reemplaza. |
| Si se acaba el tiempo, el amigo elige al azar una de las 4 acciones, la solicitud termina con su resultado y el amigo lo cuenta en el chat. | Las consecuencias (daño y Trust) son del Plan 5: `request_finished` ya lleva `chosen_action`, `answered_by_player` y `outcome`. |
| La señal de cada amigo es fija (`test_signal`, 100 por defecto) hasta el Plan 6. | Benja la baja en el Inspector para ver la estática. |
| El temporizador usa `base × (0,6 + 0,4 × Trust/100)`, con Trust = 100. | Es la fórmula de `docs/02` §6. El Plan 5 pasa el Trust real. |
| El panel del chat se queda con los clics de su área (`mouse_filter = STOP`), y los objetos del escritorio no se resaltan si el mouse está sobre un panel. | Antes, el clic atravesaba el panel y llegaba al mixer y al celular, que quedan debajo. El diseño (§7) pide cerrar el panel para usarlos. |
| El tema `scenes/ui/chat_theme.tres` y los colores de `chat_message_view.gd` son provisionales. | Sirven hasta que llegue el arte del chat (`docs/06` §3). El interior de `screen_sprite` es casi transparente (alfa 37/255), así que el tema es oscuro, con texto claro. |
| Los textos con datos usan marcadores con nombre: `{action}`, `{marked}` y `{total}`. | Si Benja reescribe el texto, puede mover los marcadores sin romper nada. Las pruebas avisan si falta alguno. |

**Verificado en Godot 4.7.2**, en copias aparte del proyecto, ya borradas:

- todo el código de este plan se ejecutó: 148 pruebas OK, sin errores ni advertencias al correr, y una captura del chat con estática, una característica marcada, un señuelo en rojo y una pregunta;
- después, el plan **tal como está escrito** se aplicó a una copia limpia del proyecto: los 25 conteos de pruebas que dice coinciden, incluidas las fallas esperadas, y el código resultante es idéntico al probado.

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `78 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar.** Al importar, Godot reconoce los `class_name` nuevos, crea los `.uid` de los scripts nuevos y regenera las traducciones de los CSV. Cada tarea importa antes de correr las pruebas:

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
| `scripts/data/decoy_data.gd` | `DecoyData`: un señuelo, una frase clickeable que no ayuda a identificar |
| `scripts/data/content_catalog.gd` | Se agregan `decoys` y `decoys_for_place()` |
| `scripts/data/night_data.gd` | Se agrega `decoys_in_first_message` |
| `scripts/core/content_validator.gd` | Se agregan las entidades que no se pueden distinguir, los señuelos y sus textos |
| `scripts/core/friend_request.gd` | `FriendRequest`: una solicitud, con su temporizador, las preguntas, las frases marcadas y la identificación |
| `scripts/core/chat_message.gd` | `ChatMessage`: un mensaje separado en piezas (`Token`) |
| `scripts/core/chat_static.gd` | Estática según la señal |
| `scripts/core/request_generator.gd` | Arma una solicitud: entidad, lugar, situación, par de características, señuelos y observaciones |
| `scripts/core/message_builder.gd` | Arma los mensajes con los textos: el inicial, las respuestas, las preguntas y "decidí solo" |
| `scripts/desk/request_manager.gd` | Nodo: las solicitudes de la noche, con el ritmo provisional, las preguntas, los clics y las señales |
| `scripts/ui/chat_message_view.gd` | Burbuja de un mensaje: BBCode, enlaces, escritura progresiva y vibración |
| `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn` | Panel del chat (reescrito): pestañas, conversación, barra de identificación y preguntas |
| `scenes/ui/chat_theme.tres` | Tema provisional del chat |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | Se agrega `RequestManager`; las entradas del PC muestran las solicitudes |
| `scripts/desk/clickable_sprite.gd` | No se resalta si el mouse está sobre un panel |
| `data/catalog.tres`, `data/nights/night_*.tres` | 6 señuelos `[PROTO]` y los señuelos por noche |
| `data/text/messages.csv`, `data/text/ui.csv` | Textos de los señuelos, de las respuestas, de las preguntas y del panel |
| `test/content_fixtures.gd` | Se agregan `make_decoy()` y 2 señuelos al catálogo de prueba |
| `test/test_*.gd` | Pruebas de cada tarea |
| `test/capture_chat.gd` | Captura del chat para revisarlo a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
RequestManager (nodo de desk.tscn)               ChatPanel (interfaz)
  advance(delta), cada frame ─────────────────▶  pestañas: tiempo y aviso (cada frame)
  start_request()
    RequestGenerator → MessageBuilder → ChatStatic ─▶ message_added ─▶ ChatMessageView (burbuja)
  ask() ◀────────────────────────────────────────  botones de pregunta
  click_clue() ◀─────────────────────────────────  clic en un enlace [url] de una burbuja
    FriendRequest.click_clue() ─▶ request_changed ─▶ refresh() de las burbujas de esa solicitud
  sin tiempo: FriendRequest.decide_alone() ─▶ request_finished (consecuencias: Plan 5)

desk.gd: entradas del PC ◀── requests[] (alerta y tiempo, cada frame)
```

---

### Tarea 1: Señuelos como datos

**Archivos:**

- Crear: `scripts/data/decoy_data.gd`, `test/test_decoys.gd`
- Modificar: `scripts/data/content_catalog.gd`, `scripts/data/night_data.gd`, `test/content_fixtures.gd`

- [ ] **Paso 1: Escribir las pruebas**

`test/test_decoys.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")


func _ids(decoys: Array[DecoyData]) -> Array:
	return decoys.map(func(decoy: DecoyData) -> StringName: return decoy.id)


func test_un_senuelo_sin_lugares_sirve_en_cualquiera() -> bool:
	var decoy := Fixtures.make_decoy(&"cold")
	check(decoy.fits_place("K_PLACE"), "sin lugares: sirve en cualquiera")
	decoy.place_keys = ["PLACE_FOREST"]
	check(decoy.fits_place("PLACE_FOREST"), "sirve en su lugar")
	check(not decoy.fits_place("K_PLACE"), "no sirve en otro lugar")
	return true


func test_un_senuelo_se_arma_como_una_caracteristica() -> bool:
	var decoy := Fixtures.make_decoy(&"cold", ClueCategory.Kind.ENVIRONMENT)
	check(decoy is TraitData, "tiene id, categoría y texto, como una característica")
	check_eq(decoy.category, ClueCategory.Kind.ENVIRONMENT, "categoría")
	check_eq(decoy.text_key, "K_DECOY_cold", "clave del texto")
	return true


func test_senuelos_de_un_lugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"moss", ClueCategory.Kind.SIGHT, ["PLACE_FOREST"]))
	check_eq(_ids(catalog.decoys_for_place("PLACE_FOREST")), [&"decoy_sight", &"decoy_sound", &"moss"], "bosque")
	check_eq(_ids(catalog.decoys_for_place("K_PLACE")), [&"decoy_sight", &"decoy_sound"], "otro lugar")
	return true


func test_una_noche_pide_1_senuelo_por_defecto() -> bool:
	check_eq(NightData.new().decoys_in_first_message, 1, "señuelos por defecto")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_decoys.gd :: no se pudo cargar` y `78 pruebas OK, 1 fallidas` (no existen `DecoyData` ni `make_decoy`).

- [ ] **Paso 3: Crear `DecoyData`**

`scripts/data/decoy_data.gd`:

```gdscript
class_name DecoyData
extends TraitData
## Señuelo: frase clickeable que no ayuda a identificar la entidad (decisión de Benja, 26-oct).
## Camufla las 2 características del mensaje. Al clickearlo vibra y se pone rojo.
## Describe el lugar, un olor, un sonido o algo que se ve. Vive en el catálogo, no en una entidad.

## Lugares donde puede aparecer (las mismas claves que place_keys de las entidades). Vacío: en cualquiera.
@export var place_keys: Array[String] = []


func fits_place(place_key: String) -> bool:
	return place_keys.is_empty() or place_keys.has(place_key)
```

- [ ] **Paso 4: Agregar los señuelos al catálogo, a las noches y a los datos de prueba**

`scripts/data/content_catalog.gd` (archivo completo):

```gdscript
class_name ContentCatalog
extends Resource
## Índice de todo el contenido (data/catalog.tres). Una entidad entra al juego
## cuando se agrega a las entidades nuevas de una noche.

@export var friends: Array[FriendData] = []
## En orden, de la noche 1 a la 5.
@export var nights: Array[NightData] = []
## Frases clickeables que camuflan las características en los mensajes (DecoyData).
@export var decoys: Array[DecoyData] = []


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


## Señuelos que pueden aparecer en un lugar: los de ese lugar y los que sirven en cualquiera.
func decoys_for_place(place_key: String) -> Array[DecoyData]:
	var fitting: Array[DecoyData] = []
	for decoy: DecoyData in decoys:
		if decoy != null and decoy.fits_place(place_key):
			fitting.append(decoy)
	return fitting
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var first_message_observations: FirstMessageObservations = FirstMessageObservations.ALL
```

por:

```gdscript
@export var first_message_observations: FirstMessageObservations = FirstMessageObservations.ALL
## Señuelos del mensaje inicial: frases clickeables que camuflan sus 2 características.
@export var decoys_in_first_message := 1
```

`test/content_fixtures.gd` (archivo completo; se agregan `make_decoy()` y 2 señuelos al catálogo de prueba):

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


static func make_decoy(decoy_id: StringName, category := ClueCategory.Kind.SIGHT,
		place_keys: Array[String] = []) -> DecoyData:
	var decoy := DecoyData.new()
	decoy.id = decoy_id
	decoy.category = category
	decoy.text_key = "K_DECOY_%s" % decoy_id
	decoy.place_keys = place_keys
	return decoy


## Catálogo válido: 3 amigos, 5 noches y 2 señuelos que sirven en cualquier lugar
## ("decoy_sight" y "decoy_sound"); "beast" aparece la noche 1 y "ghost" la noche 2.
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
	catalog.decoys.append(make_decoy(&"decoy_sight"))
	catalog.decoys.append(make_decoy(&"decoy_sound", ClueCategory.Kind.SOUND))
	return catalog
```

- [ ] **Paso 5: Importar y verificar que pasan**

Importar (comando de "Antes de empezar") y correr las pruebas.

Esperado: `82 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/data/ test/
git commit -m "Señuelos como datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: Validador de señuelos y señuelos de prototipo

**Archivos:**

- Modificar: `scripts/core/content_validator.gd`, `data/catalog.tres`, `data/nights/night_1.tres` a `night_5.tres`, `data/text/messages.csv`
- Crear: `test/test_validator_decoys.gd`

- [ ] **Paso 1: Escribir las pruebas**

`test/test_validator_decoys.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ContentValidator := preload("res://scripts/core/content_validator.gd")


func test_entidad_con_todas_sus_caracteristicas_en_otra() -> bool:
	var catalog := Fixtures.make_catalog()
	var ghost: EntityData = catalog.nights[1].new_entities[0]
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_1"))
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_2"))
	check_contains(ContentValidator.validate_catalog(catalog),
			"Entidad 'beast': todas sus características las tiene también 'ghost'")
	return true


func test_senuelo_vacio() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Catálogo: hay un espacio vacío en 'decoys'")
	return true


func test_ids_de_los_senuelos() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"decoy_sight"))
	catalog.decoys.append(Fixtures.make_decoy(&"beast_trait_1"))
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "el id 'decoy_sight' está repetido en señuelos")
	check_contains(errors, "Señuelo 'beast_trait_1': usa el id de una característica")
	return true


func test_senuelo_de_un_lugar_que_no_existe() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys[0].place_keys = ["PLACE_NOWHERE"]
	check_contains(ContentValidator.validate_catalog(catalog),
			"Señuelo 'decoy_sight': el lugar 'PLACE_NOWHERE' no es de ninguna entidad")
	return true


func test_faltan_senuelos_para_un_lugar() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[2].decoys_in_first_message = 3
	check_contains(ContentValidator.validate_catalog(catalog),
			"Noche 3: el lugar 'K_PLACE' tiene 2 señuelos y la noche pide 3")
	return true


func test_textos_de_los_senuelos() -> bool:
	var texts := {"K_DECOY_decoy_sight": "hace frío", "K_DECOY_decoy_sound": "K_DECOY_decoy_sound"}
	var translate := func(key: String) -> String: return texts.get(key, "Texto de *%s*" % key)
	var errors := ContentValidator.validate_texts(Fixtures.make_catalog(), translate)
	check_contains(errors, "Señuelo 'decoy_sight': su texto debe tener una sola frase entre asteriscos")
	check_contains(errors, "Señuelo 'decoy_sound': la clave 'K_DECOY_decoy_sound' no está en ningún CSV")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: las 6 pruebas de `test_validator_decoys.gd` fallan y `82 pruebas OK, 6 fallidas`.

- [ ] **Paso 3: Ampliar el validador**

Son 4 cambios en `scripts/core/content_validator.gd`.

**1. Revisar los señuelos del catálogo.** En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	_check_shared_traits(errors, entities)
	return errors
```

por:

```gdscript
	_check_shared_traits(errors, entities)
	_check_decoys(errors, catalog, entities)
	return errors
```

**2. Revisar la frase entre asteriscos también en los señuelos.** En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	for entity: EntityData in catalog.all_entities():
		for trait_data: TraitData in entity.traits:
			var text := String(translate.call(trait_data.text_key))
			if text != trait_data.text_key and text.count(HIGHLIGHT_MARK) != 2:
				errors.append("Característica '%s': su texto debe tener una sola frase entre asteriscos, como 'un *hombrecito*'"
						% trait_data.id)
	return errors
```

por:

```gdscript
	for entity: EntityData in catalog.all_entities():
		for trait_data: TraitData in entity.traits:
			_check_highlight(errors, "Característica '%s'" % trait_data.id, trait_data.text_key, translate)
	for decoy: DecoyData in catalog.decoys:
		_check_highlight(errors, "Señuelo '%s'" % decoy.id, decoy.text_key, translate)
	return errors


## Una característica o un señuelo necesita exactamente una frase clickeable entre asteriscos.
static func _check_highlight(errors: Array[String], who: String, key: String, translate: Callable) -> void:
	var text := String(translate.call(key))
	if text != key and text.count(HIGHLIGHT_MARK) != 2:
		errors.append("%s: su texto debe tener una sola frase entre asteriscos, como 'un *hombrecito*'" % who)
```

**3. Las claves de texto de los señuelos.** En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
		for index in entity.rules.size():
			keys.append(["%s, regla %d" % [who, index + 1], entity.rules[index].text_key])
	return keys
```

por:

```gdscript
		for index in entity.rules.size():
			keys.append(["%s, regla %d" % [who, index + 1], entity.rules[index].text_key])
	for decoy: DecoyData in catalog.decoys:
		keys.append(["Señuelo '%s'" % decoy.id, decoy.text_key])
	return keys
```

**4. Entidades que no se pueden distinguir, y la revisión de los señuelos.** En `scripts/core/content_validator.gd`, reemplazar la función `_check_shared_traits` completa (con su comentario), que es la última del archivo:

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

por:

```gdscript
## Una misma característica (mismo id) debe ser igual en todas sus entidades, la usan 2 como máximo,
## y ninguna entidad puede tener todas sus características dentro de las de otra: el mensaje
## trae 2 características que la distinguen, y así no habría ningún par.
static func _check_shared_traits(errors: Array[String], entities: Array[EntityData]) -> void:
	var first_seen := {}  # id de característica → TraitData de la primera entidad que la usa
	var users := {}  # id de característica → ids de las entidades que la usan
	var trait_ids: Array[PackedStringArray] = []  # ids de las características de cada entidad
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
		trait_ids.append(ids)
	for trait_id: StringName in users:
		if users[trait_id].size() > MAX_ENTITIES_PER_TRAIT:
			errors.append("Característica '%s': la usan %d entidades; el máximo es %d"
					% [trait_id, users[trait_id].size(), MAX_ENTITIES_PER_TRAIT])
	for i in entities.size():
		for j in range(i + 1, entities.size()):
			var first_in_second := _contains_all(trait_ids[j], trait_ids[i])
			var second_in_first := _contains_all(trait_ids[i], trait_ids[j])
			if first_in_second and second_in_first:
				errors.append("Entidades '%s' y '%s': tienen las mismas características; no se pueden distinguir"
						% [entities[i].id, entities[j].id])
			elif first_in_second:
				_append_contained(errors, entities[i], entities[j])
			elif second_in_first:
				_append_contained(errors, entities[j], entities[i])


static func _contains_all(container: PackedStringArray, items: PackedStringArray) -> bool:
	for item: String in items:
		if not container.has(item):
			return false
	return true


static func _append_contained(errors: Array[String], contained: EntityData, container: EntityData) -> void:
	errors.append("Entidad '%s': todas sus características las tiene también '%s'; ningún mensaje podría distinguirla"
			% [contained.id, container.id])


## Los señuelos tienen ids únicos y distintos de los de las características, sus lugares existen,
## y en cada noche cada lugar tiene los señuelos que la noche pide.
static func _check_decoys(errors: Array[String], catalog: ContentCatalog, entities: Array[EntityData]) -> void:
	if catalog.decoys.has(null):
		errors.append("Catálogo: hay un espacio vacío en 'decoys'")
		return
	_check_unique_ids(errors, "Catálogo", "señuelos", catalog.decoys)
	var trait_ids := {}
	var places := {}
	for entity: EntityData in entities:
		for trait_data: TraitData in entity.traits:
			if trait_data != null:
				trait_ids[trait_data.id] = true
		for place_key: String in entity.place_keys:
			places[place_key] = true
	for decoy: DecoyData in catalog.decoys:
		if trait_ids.has(decoy.id):
			errors.append("Señuelo '%s': usa el id de una característica; debe ser distinto" % decoy.id)
		for place_key: String in decoy.place_keys:
			if not places.has(place_key):
				errors.append("Señuelo '%s': el lugar '%s' no es de ninguna entidad" % [decoy.id, place_key])
	var known_places := {}  # lugares de las entidades conocidas hasta la noche que se revisa
	for night: NightData in catalog.nights:
		for entity: EntityData in night.new_entities:
			if entity != null:
				for place_key: String in entity.place_keys:
					known_places[place_key] = true
		for place_key: String in known_places:
			var count := catalog.decoys_for_place(place_key).size()
			if count < night.decoys_in_first_message:
				errors.append("Noche %d: el lugar '%s' tiene %d señuelos y la noche pide %d"
						% [night.number, place_key, count, night.decoys_in_first_message])
```

- [ ] **Paso 4: Verificar que el validador encuentra lo que falta**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK|^\s+-"
```

Esperado: `87 pruebas OK, 1 fallidas`. La que falla es `test_catalog.gd :: test_el_catalogo_es_valido`, con el error `Noche 3: el lugar 'PLACE_FOREST' tiene 0 señuelos y la noche pide 1`: el catálogo real todavía no tiene señuelos. Es lo esperado, y se arregla en el paso siguiente.

- [ ] **Paso 5: Agregar los señuelos de prototipo**

Son 6 señuelos `[PROTO]`: 4 sirven en cualquier lugar (uno por categoría) y 2 son del bosque. Benja los reemplaza por los suyos.

`data/catalog.tres` (archivo completo; categorías: 0 = Vista, 1 = Sonido, 2 = Ambiente, 3 = Rastro):

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
[ext_resource type="Script" path="res://scripts/data/decoy_data.gd" id="12_decoy"]

[sub_resource type="Resource" id="Decoy_cold_breath"]
script = ExtResource("12_decoy")
id = &"cold_breath"
category = 2
text_key = "DECOY_COLD_BREATH"

[sub_resource type="Resource" id="Decoy_distant_dog"]
script = ExtResource("12_decoy")
id = &"distant_dog"
category = 1
text_key = "DECOY_DISTANT_DOG"

[sub_resource type="Resource" id="Decoy_flickering_light"]
script = ExtResource("12_decoy")
id = &"flickering_light"
category = 0
text_key = "DECOY_FLICKERING_LIGHT"

[sub_resource type="Resource" id="Decoy_wet_grass"]
script = ExtResource("12_decoy")
id = &"wet_grass"
category = 3
text_key = "DECOY_WET_GRASS"

[sub_resource type="Resource" id="Decoy_trunk_moss"]
script = ExtResource("12_decoy")
id = &"trunk_moss"
category = 0
text_key = "DECOY_TRUNK_MOSS"
place_keys = Array[String](["PLACE_FOREST"])

[sub_resource type="Resource" id="Decoy_creaking_branches"]
script = ExtResource("12_decoy")
id = &"creaking_branches"
category = 1
text_key = "DECOY_CREAKING_BRANCHES"
place_keys = Array[String](["PLACE_FOREST"])

[resource]
script = ExtResource("1_catalog")
friends = Array[ExtResource("2_friend")]([ExtResource("4_leon"), ExtResource("5_gonzalo"), ExtResource("6_agustin")])
nights = Array[ExtResource("3_night")]([ExtResource("7_night_1"), ExtResource("8_night_2"), ExtResource("9_night_3"), ExtResource("10_night_4"), ExtResource("11_night_5")])
decoys = Array[ExtResource("12_decoy")]([SubResource("Decoy_cold_breath"), SubResource("Decoy_distant_dog"), SubResource("Decoy_flickering_light"), SubResource("Decoy_wet_grass"), SubResource("Decoy_trunk_moss"), SubResource("Decoy_creaking_branches")])
```

Señuelos por noche (`docs/02` §6). Este comando agrega `decoys_in_first_message` debajo de `first_message_observations` en cada noche:

```bash
for pair in "1 1" "2 1" "3 2" "4 2" "5 3"; do set -- $pair; sed -i "s/^first_message_observations = \(.*\)$/first_message_observations = \1\ndecoys_in_first_message = $2/" data/nights/night_$1.tres; done
grep -H "decoys_in_first_message" data/nights/night_*.tres
```

Esperado:

```text
data/nights/night_1.tres:decoys_in_first_message = 1
data/nights/night_2.tres:decoys_in_first_message = 1
data/nights/night_3.tres:decoys_in_first_message = 2
data/nights/night_4.tres:decoys_in_first_message = 2
data/nights/night_5.tres:decoys_in_first_message = 3
```

Agregar al final de `data/text/messages.csv`:

```csv
DECOY_COLD_BREATH,[PROTO] Un detalle del frío que no ayuda a identificar: *se le ve el aliento*,
DECOY_DISTANT_DOG,[PROTO] Un sonido común de la noche: *un perro ladra a lo lejos*,
DECOY_FLICKERING_LIGHT,[PROTO] Algo que ve y que no importa: *la linterna parpadea*,
DECOY_WET_GRASS,[PROTO] Un rastro común: *el pasto está mojado*,
DECOY_TRUNK_MOSS,[PROTO] Algo del bosque sin importancia: *musgo en los troncos*,
DECOY_CREAKING_BRANCHES,[PROTO] Un sonido del bosque: *crujen las ramas con el viento*,
```

- [ ] **Paso 6: Importar y verificar que pasan**

Importar y correr las pruebas.

Esperado: `88 pruebas OK, 0 fallidas`.

- [ ] **Paso 7: Commit**

```bash
git add scripts/core/content_validator.gd test/ data/
git commit -m "Validador de señuelos y señuelos [PROTO]" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: La solicitud de un amigo

**Archivos:**

- Crear: `scripts/core/friend_request.gd`, `test/test_friend_request.gd`

`FriendRequest` es lógica pura: no sabe de nodos ni de textos. `RequestManager` (Tarea 8) la avanza en el tiempo.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_friend_request.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Solicitud de "beast" con o1 = yes y o2 = no (se aplica la regla 1: correcta a1, mayor riesgo a2),
## sus 2 características, el señuelo "decoy_sight" y 30 segundos para responder.
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.time_left = 30.0
	return request


func test_marcar_las_2_caracteristicas_hace_pensar_a_matias() -> bool:
	var request := _make_request()
	check_eq(request.click_clue(&"beast_trait_1"), FriendRequest.ClueState.MARKED, "primera característica")
	check_eq(request.marked_count(), 1, "marcadas")
	check_eq(request.identification, FriendRequest.Identification.PENDING, "todavía falta una")
	request.click_clue(&"beast_trait_2")
	check_eq(request.identification, FriendRequest.Identification.THINKING, "Matías piensa")
	check_eq(request.thinking_left, FriendRequest.THINKING_TIME, "espera de 3 s")
	return true


func test_el_nombre_aparece_tras_la_espera() -> bool:
	var request := _make_request()
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	check(not request.advance(2.9), "a los 2,9 s sigue pensando")
	check(request.advance(0.2), "a los 3,1 s aparece el nombre")
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "identificada")
	check(not request.advance(1.0), "aparece una sola vez")
	return true


func test_un_senuelo_queda_en_rojo_y_no_cuenta() -> bool:
	var request := _make_request()
	check_eq(request.click_clue(&"decoy_sight"), FriendRequest.ClueState.DECOY, "señuelo")
	check_eq(request.clue_state(&"decoy_sight"), FriendRequest.ClueState.DECOY, "queda en rojo")
	check_eq(request.marked_count(), 0, "no cuenta como característica")
	check_eq(request.click_clue(&"otra"), FriendRequest.ClueState.UNMARKED, "frase que no es de la solicitud")
	return true


func test_preguntar_cuesta_5_segundos() -> bool:
	var request := _make_request()
	check(request.pay_question(), "se puede preguntar")
	check_eq(request.time_left, 25.0, "quedan 25 s")
	return true


func test_con_5_segundos_o_menos_no_se_pregunta() -> bool:
	var request := _make_request()
	request.time_left = 5.1
	check(request.can_ask(), "con 5,1 s se puede")
	request.time_left = 5.0
	check(not request.can_ask(), "con 5 s no se puede")
	check(not request.pay_question(), "no cobra la pregunta")
	check_eq(request.time_left, 5.0, "el tiempo no cambia")
	return true


func test_el_temporizador_se_acaba() -> bool:
	var request := _make_request()
	request.advance(29.0)
	check_eq(request.time_left, 1.0, "queda 1 s")
	check(not request.is_out_of_time(), "todavía hay tiempo")
	request.advance(2.0)
	check_eq(request.time_left, 0.0, "no baja de 0")
	check(request.is_out_of_time(), "se acabó el tiempo")
	return true


func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var request := _make_request()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	request.decide_alone(rng)
	check(request.finished, "terminada")
	check(request.entity.actions.has(request.chosen_action), "eligió una de las 4 acciones")
	check(not request.answered_by_player, "decidió solo")
	check_eq(request.outcome, RuleEvaluator.outcome(request.entity, request.situation, request.chosen_action),
			"resultado de su elección")
	check(not request.is_out_of_time(), "una solicitud terminada no se acaba de nuevo")
	return true


func test_terminada_no_cambia() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a1"), true)
	check_eq(request.outcome, RuleEvaluator.Outcome.CORRECT, "a1 es la correcta con o1 = yes")
	check(request.answered_by_player, "respondió el jugador")
	check_eq(request.click_clue(&"beast_trait_1"), FriendRequest.ClueState.UNMARKED, "ya no se marca")
	check(not request.can_ask(), "ya no se pregunta")
	check(not request.advance(1.0), "el tiempo ya no corre")
	check_eq(request.time_left, 30.0, "el temporizador queda donde estaba")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_friend_request.gd :: no se pudo cargar` y `88 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir `FriendRequest`**

`scripts/core/friend_request.gd`:

```gdscript
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
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `96 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Solicitud de un amigo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Mensajes separados en piezas

**Archivos:**

- Crear: `scripts/core/chat_message.gd`, `test/test_chat_message.gd`

Un mensaje es una lista de piezas: palabras (con sus signos pegados), espacios y frases clickeables. La frase entre asteriscos de una característica o de un señuelo es una sola pieza, con su id.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_message.gd`:

```gdscript
extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")


func _message(text: String, clue_id: StringName = &"") -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment(text, clue_id)
	return message


func _texts(message: ChatMessage) -> Array:
	return message.tokens.map(func(token: ChatMessage.Token) -> String: return token.text)


func test_una_oracion_se_separa_en_palabras_y_espacios() -> bool:
	var message := _message("Hola,  mundo")
	check_eq(_texts(message), ["Hola,", "  ", "mundo"], "piezas")
	check_eq(message.plain_text(), "Hola,  mundo", "texto")
	return true


func test_la_frase_entre_asteriscos_es_clickeable() -> bool:
	var message := _message("Lleva *ropa de fibra vegetal*, como de paja", &"plant_fiber_clothes")
	check_eq(_texts(message), ["Lleva", " ", "ropa de fibra vegetal", ",", " ", "como", " ", "de", " ", "paja"], "piezas")
	var clue: ChatMessage.Token = message.tokens[2]
	check_eq(clue.clue_id, &"plant_fiber_clothes", "id de la frase")
	check(clue.is_clue(), "es clickeable")
	check(not (message.tokens[0] as ChatMessage.Token).is_clue(), "una palabra normal no lo es")
	check_eq(message.plain_text(), "Lleva ropa de fibra vegetal, como de paja", "sin asteriscos")
	return true


func test_sin_id_los_asteriscos_se_quitan() -> bool:
	var message := _message("Un *olor* raro")
	check_eq(message.plain_text(), "Un olor raro", "texto")
	for token: ChatMessage.Token in message.tokens:
		check(not token.is_clue(), "nada clickeable: <%s>" % token.text)
	return true


func test_las_oraciones_se_unen_con_un_espacio() -> bool:
	var message := _message("Estoy en el bosque.")
	message.add_fragment("Hay *neblina*.", &"fog")
	check_eq(message.plain_text(), "Estoy en el bosque. Hay neblina.", "texto")
	return true


func test_que_puede_tapar_la_estatica() -> bool:
	var message := _message("¿Árboles? 3 , ñandú *frase larga*", &"clue")
	var coverable := {}
	for token: ChatMessage.Token in message.tokens:
		coverable[token.text] = token.can_be_covered()
	check_eq(coverable, {"¿Árboles?": true, " ": false, "3": true, ",": false, "ñandú": true, "frase larga": true},
			"qué se puede tapar")
	return true


func test_lo_tapado_se_ve_como_estatica() -> bool:
	var message := _message("Vi un *hombrecito* raro", &"little_man")
	(message.tokens[4] as ChatMessage.Token).covered = true
	(message.tokens[6] as ChatMessage.Token).covered = true
	check_eq(message.plain_text(), "Vi un %s %s" % [ChatMessage.COVER_TEXT, ChatMessage.COVER_TEXT], "texto con estática")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_chat_message.gd :: no se pudo cargar` y `96 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir `ChatMessage`**

`scripts/core/chat_message.gd`:

```gdscript
extends RefCounted
## Un mensaje del chat, separado en piezas para la estática y las frases clickeables (docs/02 §3–4).
## Las piezas se muestran seguidas: los espacios y los signos también son piezas.

const FriendRequest := preload("res://scripts/core/friend_request.gd")

enum Sender { FRIEND, PLAYER }

## Lo que se ve en lugar de una palabra tapada. Siempre igual, para no revelar cuántas letras tenía.
const COVER_TEXT := "▒▒▒"
## Una frase entre asteriscos, un espacio o una palabra con sus signos pegados.
const PIECE_PATTERN := "\\*[^*]+\\*|\\s+|[^\\s*]+"


## Una pieza del mensaje: una palabra, un espacio o una frase clickeable.
class Token:
	var text: String
	## id de la característica o del señuelo; vacío si la pieza no se puede clickear.
	var clue_id: StringName
	var covered := false

	func _init(token_text: String, token_clue_id: StringName = &"") -> void:
		text = token_text
		clue_id = token_clue_id

	func is_clue() -> bool:
		return not clue_id.is_empty()

	## La estática tapa frases clickeables y palabras con letras o números, pero no espacios ni signos sueltos.
	func can_be_covered() -> bool:
		if is_clue():
			return true
		for character: String in text:
			if character.to_upper() != character.to_lower() or character.is_valid_int():
				return true
		return false


var sender: Sender
var tokens: Array[Token] = []
## La solicitud a la que pertenece el mensaje: de ella salen el estado de cada frase clickeable.
var request: FriendRequest


func _init(message_sender: Sender, message_request: FriendRequest) -> void:
	sender = message_sender
	request = message_request


## Agrega una oración. Con `clue_id`, su frase entre asteriscos se vuelve clickeable;
## sin `clue_id`, los asteriscos se quitan y la frase queda como texto normal.
func add_fragment(text: String, clue_id: StringName = &"") -> void:
	if not tokens.is_empty():
		tokens.append(Token.new(" "))
	for piece: RegExMatch in RegEx.create_from_string(PIECE_PATTERN).search_all(text):
		var piece_text := piece.get_string()
		if piece_text.begins_with("*"):
			tokens.append(Token.new(piece_text.substr(1, piece_text.length() - 2), clue_id))
		else:
			tokens.append(Token.new(piece_text))


## El texto como se ve, con la estática.
func plain_text() -> String:
	var text := ""
	for token: Token in tokens:
		text += COVER_TEXT if token.covered else token.text
	return text
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `102 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Mensajes del chat separados en piezas" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Estática

**Archivos:**

- Crear: `scripts/core/chat_static.gd`, `test/test_chat_static.gd`

Tabla de `docs/02` §4: con 70 o más de señal no hay estática; de 50 a 69 se tapa el 10 % de las palabras, de 30 a 49 el 25 %, y de 1 a 29 el 45 %.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_static.gd`:

```gdscript
extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	return rng


## Un mensaje de `words` palabras, separadas por comas y espacios.
func _long_message(words: int) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	var text := PackedStringArray()
	for _i in words:
		text.append("palabra")
	message.add_fragment(" , ".join(text))
	return message


func _covered(message: ChatMessage) -> int:
	return message.tokens.filter(func(token: ChatMessage.Token) -> bool: return token.covered).size()


func test_probabilidad_segun_la_senal() -> bool:
	var expected := {100: 0.0, 70: 0.0, 69: 0.10, 50: 0.10, 49: 0.25, 30: 0.25, 29: 0.45, 1: 0.45}
	for signal_level: int in expected:
		check_eq(ChatStatic.coverage_for_signal(signal_level), expected[signal_level], "señal %d" % signal_level)
	return true


func test_con_senal_alta_no_tapa_nada() -> bool:
	var message := _long_message(200)
	ChatStatic.apply(message, 70.0, _rng())
	check_eq(_covered(message), 0, "palabras tapadas")
	return true


func test_con_senal_baja_tapa_cerca_del_45_por_ciento() -> bool:
	var message := _long_message(1000)
	ChatStatic.apply(message, 10.0, _rng())
	var covered := _covered(message)
	check(covered > 400 and covered < 500, "tapadas: %d de 1000" % covered)
	return true


func test_nunca_tapa_espacios_ni_signos() -> bool:
	var message := _long_message(300)
	ChatStatic.apply(message, 1.0, _rng())
	for token: ChatMessage.Token in message.tokens:
		if not token.can_be_covered():
			check(not token.covered, "tapó <%s>" % token.text)
	return true


func test_una_frase_se_tapa_entera() -> bool:
	var rng := _rng()
	var times_covered := 0
	for _i in 100:
		var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
		message.add_fragment("*ropa de fibra vegetal*", &"clothes")
		ChatStatic.apply(message, 1.0, rng)
		if message.plain_text() == ChatMessage.COVER_TEXT:
			times_covered += 1
		else:
			check_eq(message.plain_text(), "ropa de fibra vegetal", "se ve entera")
	check(times_covered > 20, "a veces se tapa: %d de 100" % times_covered)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_chat_static.gd :: no se pudo cargar` y `102 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir la estática**

`scripts/core/chat_static.gd`:

```gdscript
extends RefCounted
## Estática del chat (docs/02 §4): con poca señal, algunas palabras del amigo llegan tapadas (▒▒▒).
## Una frase clickeable cuenta como una sola palabra: se tapa entera o no se tapa (decisión de Benja).

const ChatMessage := preload("res://scripts/core/chat_message.gd")

## [señal mínima, probabilidad de tapar cada palabra], de la señal más alta a la más baja.
const COVERAGE := [[70.0, 0.0], [50.0, 0.10], [30.0, 0.25], [0.0, 0.45]]


static func coverage_for_signal(signal_level: float) -> float:
	for band: Array in COVERAGE:
		if signal_level >= band[0]:
			return band[1]
	return COVERAGE[-1][1]


## Tapa al azar palabras de `message`, según la señal del amigo que lo envía.
static func apply(message: ChatMessage, signal_level: float, rng: RandomNumberGenerator) -> void:
	var chance := coverage_for_signal(signal_level)
	if chance <= 0.0:
		return
	for token: ChatMessage.Token in message.tokens:
		if token.can_be_covered() and rng.randf() < chance:
			token.covered = true
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `107 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Estática del chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Generador de solicitudes

**Archivos:**

- Crear: `scripts/core/request_generator.gd`, `test/test_request_generator.gd`

Todo lo aleatorio usa el `RandomNumberGenerator` que recibe, así que con la misma semilla sale la misma solicitud. Por eso no usa `Array.shuffle()`, que va con el generador global.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_request_generator.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids(items: Array) -> Array:
	return items.map(func(item: Resource) -> StringName: return item.get("id"))


## "beast" con 3 características; "ghost" comparte las 2 primeras con "beast".
func _entities_with_shared_traits() -> Array[EntityData]:
	var beast := Fixtures.make_entity(&"beast")
	beast.traits.append(Fixtures.make_trait(&"beast_trait_3"))
	var ghost := Fixtures.make_entity(&"ghost")
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_1"))
	ghost.traits.append(Fixtures.make_trait(&"beast_trait_2"))
	var entities: Array[EntityData] = [beast, ghost]
	return entities


func test_pares_que_distinguen() -> bool:
	var entities := _entities_with_shared_traits()
	var pairs := RequestGenerator.distinguishing_pairs(entities[0], entities)
	check_eq(pairs.map(_ids), [[&"beast_trait_1", &"beast_trait_3"], [&"beast_trait_2", &"beast_trait_3"]],
			"el par 1 y 2 también lo tiene ghost")
	return true


func test_sin_otras_entidades_cualquier_par_sirve() -> bool:
	var entities := _entities_with_shared_traits()
	var alone: Array[EntityData] = [entities[0]]
	check_eq(RequestGenerator.distinguishing_pairs(entities[0], alone).size(), 3, "3 pares de 3 características")
	return true


func test_la_solicitud_trae_2_caracteristicas_que_distinguen() -> bool:
	var catalog := Fixtures.make_catalog()
	var entities := _entities_with_shared_traits()
	catalog.nights[0].new_entities.assign(entities)
	catalog.nights[1].new_entities.clear()
	for seed_value in 30:
		var request := RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(seed_value))
		var pairs := RequestGenerator.distinguishing_pairs(request.entity, entities).map(_ids)
		check(pairs.has(_ids(request.traits)), "semilla %d: el par %s distingue" % [seed_value, _ids(request.traits)])
	return true


func test_situacion_lugar_y_amigo() -> bool:
	var catalog := Fixtures.make_catalog()
	var request := RequestGenerator.generate(catalog, catalog.nights[1], 2, _rng(5))
	check_eq(request.friend_index, 2, "amigo")
	check(request.entity.place_keys.has(request.place_key), "uno de los lugares de la entidad")
	check_eq(request.situation.size(), 2, "un valor por observación")
	for observation: ObservationData in request.entity.observations:
		check(observation.has_value(request.situation[observation.id]), "valor de %s" % observation.id)
	return true


func test_senuelos_del_lugar_mezclados_con_las_caracteristicas() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.decoys.append(Fixtures.make_decoy(&"elsewhere", ClueCategory.Kind.SIGHT, ["K_NOWHERE"]))
	catalog.nights[0].decoys_in_first_message = 2
	var request := RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(8))
	check_eq(request.decoys.size(), 2, "2 señuelos")
	for decoy: DecoyData in request.decoys:
		check(decoy.fits_place(request.place_key), "%s es de este lugar" % decoy.id)
	check_eq(request.first_clues.size(), 4, "2 características y 2 señuelos")
	for clue: TraitData in request.traits + request.decoys:
		check(request.first_clues.has(clue), "el mensaje trae %s" % clue.id)
	return true


func test_observaciones_del_mensaje_inicial() -> bool:
	var catalog := Fixtures.make_catalog()
	var night: NightData = catalog.nights[0]
	var request := RequestGenerator.generate(catalog, night, 0, _rng(1))
	check_eq(request.first_observations, request.entity.observations, "todas")
	night.first_message_observations = NightData.FirstMessageObservations.ONE
	request = RequestGenerator.generate(catalog, night, 0, _rng(1))
	check_eq(request.first_observations.size(), 1, "una")
	return true


func test_tiempo_para_responder() -> bool:
	var night := NightData.new()
	night.base_decision_time = 40.0
	check_eq(RequestGenerator.decision_time(night, 100.0), 40.0, "Trust 100")
	check_eq(RequestGenerator.decision_time(night, 50.0), 32.0, "Trust 50")
	check_eq(RequestGenerator.decision_time(night, 0.0), 24.0, "Trust 0")
	var catalog := Fixtures.make_catalog()
	check_eq(RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(1)).time_left, 45.0, "temporizador de la noche 1")
	return true


func test_sin_entidades_conocidas_no_hay_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].new_entities.clear()
	check_eq(RequestGenerator.generate(catalog, catalog.nights[0], 0, _rng(1)), null, "noche sin entidades")
	return true


func test_misma_semilla_misma_solicitud() -> bool:
	var catalog := Fixtures.make_catalog()
	var first := RequestGenerator.generate(catalog, catalog.nights[1], 0, _rng(42))
	var second := RequestGenerator.generate(catalog, catalog.nights[1], 0, _rng(42))
	check_eq(second.entity, first.entity, "entidad")
	check_eq(second.situation, first.situation, "situación")
	check_eq(_ids(second.first_clues), _ids(first.first_clues), "frases y su orden")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_request_generator.gd :: no se pudo cargar` y `107 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir el generador**

`scripts/core/request_generator.gd`:

```gdscript
extends RefCounted
## Arma una solicitud nueva (docs/02 §2): la entidad, el lugar, la situación, las 2 características
## que la distinguen de las demás entidades conocidas, los señuelos que las camuflan y las
## observaciones del mensaje inicial.

const FriendRequest := preload("res://scripts/core/friend_request.gd")


## Solicitud de la noche `night` para el amigo `friend_index`, o null si la noche no tiene entidades conocidas.
## `trust` acorta el temporizador (Plan 5); mientras no exista, es 100.
static func generate(catalog: ContentCatalog, night: NightData, friend_index: int,
		rng: RandomNumberGenerator, trust := 100.0) -> FriendRequest:
	var known := catalog.known_entities(night.number)
	if known.is_empty():
		return null
	var request := FriendRequest.new()
	request.friend_index = friend_index
	request.entity = known[rng.randi_range(0, known.size() - 1)]
	var entity := request.entity
	request.place_key = entity.place_keys[rng.randi_range(0, entity.place_keys.size() - 1)]
	for observation: ObservationData in entity.observations:
		var values := observation.value_ids()
		request.situation[observation.id] = values[rng.randi_range(0, values.size() - 1)]
	var pairs := distinguishing_pairs(entity, known)
	if pairs.is_empty():
		# Solo pasa si el contenido tiene errores; test_catalog.gd los avisa.
		pairs.append(entity.traits.slice(0, 2))
	request.traits.assign(pairs[rng.randi_range(0, pairs.size() - 1)])
	var decoys := shuffled(catalog.decoys_for_place(request.place_key), rng)
	request.decoys.assign(decoys.slice(0, night.decoys_in_first_message))
	request.first_clues.assign(shuffled(request.traits + request.decoys, rng))
	var count := night.observations_in_first_message(entity.observations.size())
	var chosen := shuffled(entity.observations, rng).slice(0, count)
	for observation: ObservationData in entity.observations:
		if chosen.has(observation):
			request.first_observations.append(observation)
	request.time_left = decision_time(night, trust)
	return request


## Pares de características de `entity` que ninguna otra entidad de `known` tiene juntas.
static func distinguishing_pairs(entity: EntityData, known: Array[EntityData]) -> Array[Array]:
	var pairs: Array[Array] = []
	for i in entity.traits.size():
		for j in range(i + 1, entity.traits.size()):
			var pair := [entity.traits[i], entity.traits[j]]
			var shared := known.any(func(other: EntityData) -> bool: return other != entity and _has_all(other, pair))
			if not shared:
				pairs.append(pair)
	return pairs


## Segundos para responder: el tiempo base de la noche, más corto con Trust bajo (docs/02 §6).
static func decision_time(night: NightData, trust: float) -> float:
	return night.base_decision_time * (0.6 + 0.4 * clampf(trust, 0.0, 100.0) / 100.0)


## Copia de `items` en orden aleatorio, usando `rng` para que las pruebas se puedan repetir.
static func shuffled(items: Array, rng: RandomNumberGenerator) -> Array:
	var result := items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = result[i]
		result[i] = result[j]
		result[j] = swap
	return result


static func _has_all(entity: EntityData, wanted: Array) -> bool:
	for wanted_trait: TraitData in wanted:
		if not entity.traits.any(func(trait_data: TraitData) -> bool: return trait_data.id == wanted_trait.id):
			return false
	return true
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `116 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Generador de solicitudes" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Armado de mensajes

**Archivos:**

- Crear: `scripts/core/message_builder.gd`, `test/test_message_builder.gd`
- Modificar: `data/text/messages.csv`, `data/text/ui.csv`

`MessageBuilder` recibe la traducción como un `Callable`, igual que el validador de textos. Así las pruebas usan una traducción falsa y predecible, y el juego usa la real (`tr`).

- [ ] **Paso 1: Escribir las pruebas**

`test/test_message_builder.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")


## Traducción falsa: cada característica y señuelo tiene su clave como frase clickeable.
func _translate(key: String) -> String:
	if key.begins_with("K_TRAIT_") or key.begins_with("K_DECOY_"):
		return "Hay *%s*." % key
	if key == MessageBuilder.DECIDED_ALONE_KEY:
		return "Decidí solo: {action}"
	return key + "."


## Solicitud de "beast": beast_trait_1 (Vista) y beast_trait_2 (Sonido), el señuelo "decoy_sight" (Vista)
## entre las dos, o1 (Vista) = yes y o2 (Sonido) = no; el mensaje inicial trae solo o2.
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	entity.traits[1].category = ClueCategory.Kind.SOUND
	entity.observations[1].category = ClueCategory.Kind.SOUND
	var request := FriendRequest.new()
	request.entity = entity
	request.place_key = "K_PLACE"
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.first_clues.assign([entity.traits[0], request.decoys[0], entity.traits[1]])
	request.first_observations.assign([entity.observations[1]])
	request.time_left = 30.0
	return request


func _clue_ids(message: ChatMessage) -> Array:
	return message.tokens.filter(func(token: ChatMessage.Token) -> bool: return token.is_clue()) \
			.map(func(token: ChatMessage.Token) -> StringName: return token.clue_id)


func test_mensaje_inicial() -> bool:
	var request := _make_request()
	var message := MessageBuilder.first_message(request, _translate)
	check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo envía el amigo")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "K_PLACE. Hay K_TRAIT_beast_trait_1. Hay K_DECOY_decoy_sight. Hay K_TRAIT_beast_trait_2. K_beast_O2_NO.",
			"lugar, frases en su orden y la observación que trae")
	check_eq(_clue_ids(message), [&"beast_trait_1", &"decoy_sight", &"beast_trait_2"], "frases clickeables")
	return true


func test_respuesta_a_una_pregunta() -> bool:
	var request := _make_request()
	var sight := MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate)
	check_eq(sight.plain_text(), "Hay K_TRAIT_beast_trait_1. Hay K_DECOY_decoy_sight. K_beast_O1_YES.",
			"Vista: también la observación que el mensaje inicial no traía")
	check_eq(_clue_ids(sight), [&"beast_trait_1", &"decoy_sight"], "frases de Vista")
	var sound := MessageBuilder.answer(request, ClueCategory.Kind.SOUND, _translate)
	check_eq(sound.plain_text(), "Hay K_TRAIT_beast_trait_2. K_beast_O2_NO.", "Sonido")
	return true


func test_si_no_hay_nada_responde_nada() -> bool:
	var message := MessageBuilder.answer(_make_request(), ClueCategory.Kind.TRACES, _translate)
	check_eq(message.plain_text(), "ANSWER_NOTHING_TRACES.", "nada en Rastro")
	return true


func test_la_pregunta_de_matias() -> bool:
	var request := _make_request()
	var message := MessageBuilder.question(request, ClueCategory.Kind.ENVIRONMENT, _translate)
	check_eq(message.sender, ChatMessage.Sender.PLAYER, "la envía Matías")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "QUESTION_ENVIRONMENT.", "texto")
	return true


func test_el_amigo_decidio_solo() -> bool:
	var request := _make_request()
	request.finish(request.entity.find_action(&"a3"), false)
	var message := MessageBuilder.decided_alone(request, _translate)
	check_eq(message.plain_text(), "Decidí solo: K_beast_A3.", "con la acción que eligió")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var keys: Array = MessageBuilder.QUESTION_KEYS.values() + MessageBuilder.NOTHING_KEYS.values()
	keys.append(MessageBuilder.DECIDED_ALONE_KEY)
	for key: String in keys:
		check(String(TranslationServer.translate(key)) != key, "falta %s en los CSV" % key)
	check(String(TranslationServer.translate(MessageBuilder.DECIDED_ALONE_KEY)).contains("{action}"),
			"FRIEND_DECIDED_ALONE debe tener {action}")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_message_builder.gd :: no se pudo cargar` y `116 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir el armado de mensajes**

`scripts/core/message_builder.gd`:

```gdscript
extends RefCounted
## Arma los mensajes del chat con los fragmentos de data/text/*.csv (docs/02 §9).
## Cada fragmento es una oración, y el mensaje las une con un espacio.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Botón y mensaje de Matías para cada pregunta (ui.csv).
const QUESTION_KEYS := {
	ClueCategory.Kind.SIGHT: "QUESTION_SIGHT",
	ClueCategory.Kind.SOUND: "QUESTION_SOUND",
	ClueCategory.Kind.ENVIRONMENT: "QUESTION_ENVIRONMENT",
	ClueCategory.Kind.TRACES: "QUESTION_TRACES",
}
## Respuesta del amigo cuando no hay nada de esa categoría: "nada" también es información (messages.csv).
const NOTHING_KEYS := {
	ClueCategory.Kind.SIGHT: "ANSWER_NOTHING_SIGHT",
	ClueCategory.Kind.SOUND: "ANSWER_NOTHING_SOUND",
	ClueCategory.Kind.ENVIRONMENT: "ANSWER_NOTHING_ENVIRONMENT",
	ClueCategory.Kind.TRACES: "ANSWER_NOTHING_TRACES",
}
## El amigo decidió solo porque nadie respondió a tiempo. {action} es la acción que eligió (messages.csv).
const DECIDED_ALONE_KEY := "FRIEND_DECIDED_ALONE"


## Mensaje inicial: dónde está, las características y los señuelos mezclados, y sus observaciones.
static func first_message(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment(_text(translate, request.place_key))
	for clue: TraitData in request.first_clues:
		message.add_fragment(_text(translate, clue.text_key), clue.id)
	for observation: ObservationData in request.first_observations:
		message.add_fragment(_observation_text(request, observation, translate))
	return message


## Respuesta a una pregunta: repite las características y los señuelos del mensaje inicial que son
## de esa categoría, y todas las observaciones de esa categoría, también las que no traía.
static func answer(request: FriendRequest, category: ClueCategory.Kind, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	for clue: TraitData in request.first_clues:
		if clue.category == category:
			message.add_fragment(_text(translate, clue.text_key), clue.id)
	for observation: ObservationData in request.entity.observations:
		if observation.category == category:
			message.add_fragment(_observation_text(request, observation, translate))
	if message.tokens.is_empty():
		message.add_fragment(_text(translate, NOTHING_KEYS[category]))
	return message


## La pregunta, como mensaje de Matías.
static func question(request: FriendRequest, category: ClueCategory.Kind, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.PLAYER, request)
	message.add_fragment(_text(translate, QUESTION_KEYS[category]))
	return message


## El amigo cuenta que decidió solo y qué hizo. La solicitud ya debe estar terminada.
static func decided_alone(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	var action := _text(translate, request.chosen_action.label_key)
	message.add_fragment(_text(translate, DECIDED_ALONE_KEY).format({"action": action}))
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
	return _text(translate, observation.values[request.situation[observation.id]])


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
```

- [ ] **Paso 4: Agregar sus textos**

Las respuestas "nada" y "decidí solo" son diálogo, así que van como `[PROTO]` y las reescribe Benja (`CLAUDE.md`, regla 8). Las preguntas son las del diseño (§8.4).

Agregar al final de `data/text/messages.csv`:

```csv
ANSWER_NOTHING_SIGHT,[PROTO] El amigo dice que no ve nada fuera de lo común,
ANSWER_NOTHING_SOUND,[PROTO] El amigo dice que no se oye nada fuera de lo común,
ANSWER_NOTHING_ENVIRONMENT,[PROTO] El amigo dice que el ambiente está normal,
ANSWER_NOTHING_TRACES,[PROTO] El amigo dice que no ve rastros,
FRIEND_DECIDED_ALONE,"[PROTO] Como Matías no respondió a tiempo, el amigo cuenta que decidió solo: {action}",
```

Agregar al final de `data/text/ui.csv`:

```csv
QUESTION_SIGHT,¿Qué ves?,
QUESTION_SOUND,¿Qué oyes?,
QUESTION_ENVIRONMENT,¿Cómo está el ambiente?,
QUESTION_TRACES,¿Hay rastros?,
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `122 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/core/ test/ data/text/
git commit -m "Armado de mensajes con sus textos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: Las solicitudes de la noche

**Archivos:**

- Crear: `scripts/desk/request_manager.gd`, `test/test_request_manager.gd`

`RequestManager` junta las piezas anteriores. Las pruebas lo agregan al árbol para que corra `_ready`, apagan `requests_arrive` y lo avanzan con `advance()`.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_request_manager.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")


## Manager con el catálogo de prueba, en la noche 1 (solo "beast"), sin que las solicitudes lleguen solas.
func _make_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## Guarda en `events` cada señal del manager, como [nombre, amigo, mensaje o solicitud].
func _record(manager: RequestManager, events: Array) -> void:
	for signal_name: String in ["message_added", "request_started", "request_changed", "request_finished"]:
		manager.connect(signal_name, func(friend_index: int, item: RefCounted) -> void:
			events.append([signal_name, friend_index, item]))


func _messages(events: Array) -> Array:
	return events.filter(func(entry: Array) -> bool: return entry[0] == "message_added") \
			.map(func(entry: Array) -> ChatMessage: return entry[2])


func test_empieza_sin_solicitudes() -> bool:
	var manager := _make_manager()
	check_eq(manager.requests, [null, null, null], "sin solicitudes")
	check_eq(manager.signal_levels, [100.0, 100.0, 100.0], "señal llena")
	check_eq(manager.active_count(), 0, "activas")
	manager.free()
	return true


func test_una_solicitud_llega_con_su_mensaje() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(1)
	check(request != null, "se crea")
	check_eq(manager.requests[1], request, "es la de Gonzalo")
	check_eq(request.time_left, 45.0, "tiempo base de la noche 1")
	check_eq(events.size(), 2, "dos señales")
	if events.size() == 2:
		check_eq(events[0], ["request_started", 1, request], "empezó")
		var message: ChatMessage = events[1][2]
		check_eq(events[1][0], "message_added", "mensaje")
		check_eq(message.request, request, "el mensaje es de la solicitud")
		check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo envía el amigo")
	check_eq(manager.start_request(1), null, "un amigo no recibe dos solicitudes a la vez")
	manager.free()
	return true


func test_preguntar_agrega_2_mensajes_y_cuesta_5_segundos() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	check(manager.ask(0, ClueCategory.Kind.SIGHT), "se pudo preguntar")
	var messages := _messages(events)
	check_eq(messages.size(), 2, "pregunta y respuesta")
	if messages.size() == 2:
		check_eq((messages[0] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "pregunta de Matías")
		check_eq((messages[1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "respuesta del amigo")
	check_eq(request.time_left, 40.0, "costó 5 s")
	check(not manager.ask(1, ClueCategory.Kind.SIGHT), "sin solicitud no se pregunta")
	manager.free()
	return true


func test_clic_en_las_caracteristicas_hasta_el_nombre() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var request := manager.start_request(0)
	var message: ChatMessage = _messages(events)[0]
	events.clear()
	for trait_data: TraitData in request.traits:
		check_eq(manager.click_clue(message, trait_data.id), FriendRequest.ClueState.MARKED, "marca %s" % trait_data.id)
	check_eq(request.identification, FriendRequest.Identification.THINKING, "Matías piensa")
	check_eq(events.size(), 2, "un aviso por clic")
	events.clear()
	manager.advance(3.1)
	check_eq(request.identification, FriendRequest.Identification.REVEALED, "apareció el nombre")
	check_eq(events, [["request_changed", 0, request]], "aviso del nombre")
	manager.free()
	return true


func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	var events := []
	_record(manager, events)
	manager.advance(request.time_left + 0.1)
	check_eq(manager.requests[2], null, "Agustín queda libre")
	check(request.finished and not request.answered_by_player, "decidió solo")
	check_eq(events.size(), 2, "mensaje y fin")
	if events.size() == 2:
		check_eq(events[0][0], "message_added", "cuenta lo que hizo")
		check_eq(events[1], ["request_finished", 2, request], "terminó")
	check_eq(manager.click_clue(_messages(events)[0], request.traits[0].id), FriendRequest.ClueState.UNMARKED,
			"los mensajes de una solicitud terminada ya no se clickean")
	manager.free()
	return true


func test_las_solicitudes_llegan_solas() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	manager.advance(4.9)
	check_eq(manager.active_count(), 0, "a los 4,9 s todavía no")
	manager.advance(0.2)
	check_eq(manager.active_count(), 1, "a los 5,1 s llega la primera")
	# Noche 1: 6 solicitudes, así que llegan cada 70 s. La primera se acaba a los 45 s (a los 50,1 s del total).
	manager.advance(69.0)
	check_eq(manager.active_count(), 0, "la primera ya terminó")
	manager.advance(1.0)
	check_eq(manager.active_count(), 1, "70 s después de la primera llega la segunda")
	manager.free()
	return true


func test_no_pasa_de_las_simultaneas_ni_del_total() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	var night := manager.night()
	night.requests_total = 2
	night.max_simultaneous = 1
	night.base_decision_time = 100.0
	manager.advance(5.0)
	manager.advance(90.0)
	check_eq(manager.active_count(), 1, "no pasa de 1 simultánea")
	for _i in 20:
		manager.advance(30.0)
	check_eq(manager.active_count(), 0, "no pasa de 2 en la noche")
	manager.free()
	return true


func test_la_estatica_depende_de_la_senal() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	manager.signal_levels[0] = 100.0
	manager.signal_levels[1] = 1.0
	for _i in 10:
		manager.start_request(0)
		manager.start_request(1)
		manager.advance(60.0)
	var covered := [0, 0]
	for entry: Array in events:
		if entry[0] == "message_added":
			for token: ChatMessage.Token in (entry[2] as ChatMessage).tokens:
				if token.covered:
					covered[entry[1]] += 1
	check_eq(covered[0], 0, "con señal 100 no hay estática")
	check(covered[1] > 0, "con señal 1 hay estática")
	manager.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_request_manager.gd :: no se pudo cargar` y `122 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir `RequestManager`**

`scripts/desk/request_manager.gd`:

```gdscript
extends Node
## Las solicitudes de la noche (Plan 3): las genera, avanza sus temporizadores, recibe las preguntas
## y los clics del chat, y arma los mensajes con estática.
## El ritmo es provisional, hasta el director del Plan 7: llega una solicitud cada
## (duración de la noche ÷ solicitudes de la noche) segundos, sin pasar de las simultáneas.

signal message_added(friend_index: int, message: ChatMessage)
signal request_started(friend_index: int, request: FriendRequest)
## Cambió algo que se ve: una frase marcada o en rojo, Matías pensando, el nombre o el tiempo tras preguntar.
signal request_changed(friend_index: int, request: FriendRequest)
signal request_finished(friend_index: int, request: FriendRequest)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Duración de una noche en segundos reales (diseño §5).
const NIGHT_SECONDS := 420.0
## Segundos hasta la primera solicitud.
const FIRST_REQUEST_DELAY := 5.0

@export var catalog: ContentCatalog
## Noche que se juega. Por ahora la 3, la única con una entidad (El Trauco).
@export_range(1, 5) var night_number := 3
## Señal de los 3 amigos mientras no exista la del Plan 6. Bájala para ver la estática.
@export_range(1, 100) var test_signal := 100
## Si está apagado, las solicitudes no llegan solas (para las pruebas).
@export var requests_arrive := true
## 0: cada partida es distinta. Otro número repite la misma secuencia.
@export var random_seed := 0

var rng := RandomNumberGenerator.new()
## La solicitud activa de cada amigo, o null si no tiene.
var requests: Array[FriendRequest] = []
## Señal de cada amigo (0–100).
var signal_levels: Array[float] = []

var _since_last_request := 0.0
var _started_count := 0


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	for _friend: FriendData in catalog.friends:
		requests.append(null)
		signal_levels.append(float(test_signal))


func _process(delta: float) -> void:
	advance(delta)


func night() -> NightData:
	return catalog.nights[night_number - 1]


func active_count() -> int:
	return requests.size() - requests.count(null)


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
func advance(delta: float) -> void:
	for index in requests.size():
		var request := requests[index]
		if request == null:
			continue
		if request.advance(delta):
			request_changed.emit(index, request)
		if request.is_out_of_time():
			_decide_alone(index)
	if requests_arrive:
		_maybe_start_request(delta)


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o si no hay entidades.
func start_request(friend_index: int) -> FriendRequest:
	if requests[friend_index] != null:
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng)
	if request == null:
		return null
	requests[friend_index] = request
	_started_count += 1
	request_started.emit(friend_index, request)
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request


## Matías pregunta por una categoría: cuesta 5 s y el amigo responde. false si no se pudo preguntar.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not request.pay_question():
		return false
	message_added.emit(friend_index, MessageBuilder.question(request, category, tr))
	_add_friend_message(friend_index, MessageBuilder.answer(request, category, tr))
	request_changed.emit(friend_index, request)
	return true


## Clic en una frase de `message`. Solo cuenta si su solicitud sigue activa. Devuelve el estado de la frase.
func click_clue(message: ChatMessage, clue_id: StringName) -> FriendRequest.ClueState:
	var request := message.request
	if request == null or request.finished:
		return FriendRequest.ClueState.UNMARKED
	var state := request.click_clue(clue_id)
	request_changed.emit(request.friend_index, request)
	return state


func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng)
	requests[friend_index] = null
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	request_finished.emit(friend_index, request)


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
	ChatStatic.apply(message, signal_levels[friend_index], rng)
	message_added.emit(friend_index, message)


func _maybe_start_request(delta: float) -> void:
	_since_last_request += delta
	var current := night()
	var wait := FIRST_REQUEST_DELAY if _started_count == 0 else NIGHT_SECONDS / current.requests_total
	if _since_last_request < wait or _started_count >= current.requests_total:
		return
	if active_count() >= current.max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if requests[index] == null:
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_request(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		_since_last_request = 0.0
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `130 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/ test/
git commit -m "Solicitudes de la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: Burbuja de un mensaje

**Archivos:**

- Crear: `scripts/ui/chat_message_view.gd`, `test/test_chat_message_view.gd`

La burbuja se arma por código: un `MarginContainer` (margen del lado contrario al que escribe), un `PanelContainer` (la burbuja, con su estilo del tema) y un `RichTextLabel` (el texto). Los tres dejan pasar la rueda del mouse (`MOUSE_FILTER_PASS`) para que la conversación se pueda scrollear con el mouse sobre un mensaje.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_message_view.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")


## Solicitud de "beast" con sus 2 características y el señuelo "decoy_sight".
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.decoys.assign([Fixtures.make_decoy(&"decoy_sight")])
	request.time_left = 30.0
	return request


## Mensaje del amigo: "[PROTO] Hay un pelaje y frío.", con "pelaje" (beast_trait_1) y "frío" (decoy_sight) clickeables.
func _make_message(request: FriendRequest, sender := ChatMessage.Sender.FRIEND) -> ChatMessage:
	var message := ChatMessage.new(sender, request)
	message.add_fragment("[PROTO] Hay un *pelaje*", &"beast_trait_1")
	message.add_fragment("y *frío*.", &"decoy_sight")
	return message


func _make_view(message: ChatMessage) -> ChatMessageView:
	var view := ChatMessageView.new(message)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	return view


func _label(view: ChatMessageView) -> RichTextLabel:
	return view.get_node("Bubble/Text") as RichTextLabel


func test_texto_con_frases_clickeables() -> bool:
	var view := _make_view(_make_message(_make_request()))
	var label := _label(view)
	check_eq(label.get_parsed_text(), "[PROTO] Hay un pelaje y frío.", "texto visible, con el [PROTO]")
	check(label.text.contains("[url=beast_trait_1]"), "la característica es un enlace")
	check(label.text.contains("[url=decoy_sight]"), "el señuelo también, y se ve igual")
	view.free()
	return true


func test_la_estatica_no_se_puede_clickear() -> bool:
	var message := _make_message(_make_request())
	for token: ChatMessage.Token in message.tokens:
		token.covered = token.clue_id == &"beast_trait_1"
	var view := _make_view(message)
	check(not _label(view).text.contains("[url=beast_trait_1]"), "tapada: sin enlace")
	check(_label(view).get_parsed_text().contains(ChatMessage.COVER_TEXT), "se ve la estática")
	view.free()
	return true


func test_marcada_y_senuelo_dejan_de_ser_enlaces() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"decoy_sight")
	view.refresh()
	var text := _label(view).text
	check(not text.contains("[url"), "sin enlaces")
	check(text.contains(ChatMessageView.MARKED_COLOR), "característica marcada")
	check(text.contains(ChatMessageView.DECOY_COLOR), "señuelo en rojo")
	view.free()
	return true


func test_el_senuelo_vibra() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.click_clue(&"decoy_sight")
	view.shake(&"decoy_sight")
	check(_label(view).text.contains("[shake"), "vibra")
	view._stop_shaking()
	check(not _label(view).text.contains("[shake"), "deja de vibrar")
	view.free()
	return true


func test_solicitud_terminada_sin_enlaces() -> bool:
	var request := _make_request()
	var view := _make_view(_make_message(request))
	request.finish(request.entity.actions[0], true)
	view.refresh()
	check(not _label(view).text.contains("[url"), "ya no se clickea")
	view.free()
	return true


func test_escritura_progresiva() -> bool:
	var view := _make_view(_make_message(_make_request()))
	check_eq(_label(view).visible_ratio, 0.0, "empieza sin texto")
	view.finish_typing()
	check_eq(_label(view).visible_ratio, 1.0, "se muestra completo")
	view.free()
	return true


func test_clic_en_una_frase_avisa() -> bool:
	var view := _make_view(_make_message(_make_request()))
	var clicked := []
	view.clue_clicked.connect(func(source: Node, clue_id: StringName) -> void: clicked.append([source, clue_id]))
	_label(view).meta_clicked.emit("decoy_sight")
	check_eq(clicked, [[view, &"decoy_sight"]], "avisa qué frase")
	view.free()
	return true


func test_burbuja_del_amigo_y_de_matias() -> bool:
	var request := _make_request()
	var friend_view := _make_view(_make_message(request))
	var player_view := _make_view(_make_message(request, ChatMessage.Sender.PLAYER))
	check_eq((friend_view.get_node("Bubble") as PanelContainer).theme_type_variation, &"FriendBubble", "amigo")
	check_eq(friend_view.get_theme_constant(&"margin_right"), ChatMessageView.INDENT, "amigo a la izquierda")
	check_eq((player_view.get_node("Bubble") as PanelContainer).theme_type_variation, &"PlayerBubble", "Matías")
	check_eq(player_view.get_theme_constant(&"margin_left"), ChatMessageView.INDENT, "Matías a la derecha")
	friend_view.free()
	player_view.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_chat_message_view.gd :: no se pudo cargar` y `130 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir la burbuja**

`scripts/ui/chat_message_view.gd`:

```gdscript
extends MarginContainer
## Burbuja de un mensaje del chat (Plan 3). Las frases clickeables son enlaces [url] de un RichTextLabel,
## y la estática se ve como ▒▒▒. El texto aparece escrito de a poco.
## Características y señuelos se ven iguales hasta que se clickean: la característica queda marcada
## y el señuelo vibra y queda rojo. Los colores son provisionales hasta el arte del chat.

signal clue_clicked(view: Node, clue_id: StringName)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")

## Velocidad de la escritura progresiva.
const CHARS_PER_SECOND := 60.0
## Cuánto vibra un señuelo al clickearlo.
const SHAKE_SECONDS := 0.6
## Lo que separa la burbuja del borde contrario: el amigo escribe a la izquierda y Matías a la derecha.
const INDENT := 48
const CLUE_COLOR := "f2b84b"
const MARKED_COLOR := "7ee08a"
const DECOY_COLOR := "ff6464"
const STATIC_COLOR := "8792a2"

var message: ChatMessage

var _label: RichTextLabel
var _typing: Tween
var _shaking_clue := &""


func _init(chat_message: ChatMessage) -> void:
	message = chat_message
	mouse_filter = Control.MOUSE_FILTER_PASS
	var from_player := message.sender == ChatMessage.Sender.PLAYER
	add_theme_constant_override(&"margin_left" if from_player else &"margin_right", INDENT)
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	bubble.theme_type_variation = &"PlayerBubble" if from_player else &"FriendBubble"
	# PASS deja que la rueda del mouse llegue al ScrollContainer de la conversación.
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bubble)
	_label = RichTextLabel.new()
	_label.name = "Text"
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.meta_clicked.connect(_on_meta_clicked)
	bubble.add_child(_label)
	refresh()
	_label.visible_ratio = 0.0


func _ready() -> void:
	var seconds := _label.get_total_character_count() / CHARS_PER_SECOND
	_typing = create_tween()
	_typing.tween_property(_label, ^"visible_ratio", 1.0, seconds)


## Muestra el mensaje completo de una vez.
func finish_typing() -> void:
	if _typing != null:
		_typing.kill()
	_label.visible_ratio = 1.0


## Vuelve a armar el texto. Se llama cuando cambia el estado de una frase o termina la solicitud.
func refresh() -> void:
	var parts := PackedStringArray()
	for token: ChatMessage.Token in message.tokens:
		parts.append(_token_bbcode(token))
	_label.text = "".join(parts)


## El señuelo clickeado vibra un momento; después queda rojo.
func shake(clue_id: StringName) -> void:
	_shaking_clue = clue_id
	refresh()
	create_tween().tween_callback(_stop_shaking).set_delay(SHAKE_SECONDS)


func _stop_shaking() -> void:
	_shaking_clue = &""
	refresh()


func _token_bbcode(token: ChatMessage.Token) -> String:
	if token.covered:
		return _colored(ChatMessage.COVER_TEXT, STATIC_COLOR)
	# [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
	var text := token.text.replace("[", "[lb]")
	if not token.is_clue():
		return text
	match message.request.clue_state(token.clue_id):
		FriendRequest.ClueState.MARKED:
			return _colored(text, MARKED_COLOR)
		FriendRequest.ClueState.DECOY:
			var red := _colored(text, DECOY_COLOR)
			return "[shake rate=30 level=10]%s[/shake]" % red if token.clue_id == _shaking_clue else red
	if message.request.finished:
		return _colored(text, CLUE_COLOR)
	return "[url=%s]%s[/url]" % [token.clue_id, _colored(text, CLUE_COLOR)]


func _on_meta_clicked(meta: Variant) -> void:
	clue_clicked.emit(self, StringName(str(meta)))


static func _colored(text: String, color: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `138 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ui/ test/
git commit -m "Burbuja de un mensaje del chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: Las entradas del PC muestran las solicitudes

**Archivos:**

- Modificar: `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `test/test_desk_scene.gd`

El escritorio recibe su `RequestManager`, que juega la noche 3 (la única con una entidad, El Trauco). Las entradas toman los nombres del catálogo y, mientras el amigo espera, parpadean y muestran el tiempo. El panel del chat todavía es el del Plan 1: se reemplaza en la Tarea 11.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
func test_cerrar_el_chat_deselecciona() -> bool:
```

por:

```gdscript
func test_las_entradas_usan_los_nombres_del_catalogo() -> bool:
	var desk := _make_desk()
	var names := {"EntryLeon": "León", "EntryGonzalo": "Gonzalo", "EntryAgustin": "Agustín"}
	for entry_name: String in names:
		var label := desk.get_node("DeskPlane/Entries/%s/NameLabel" % entry_name) as Label
		check_eq(label.text, names[entry_name], entry_name)
	desk.free()
	return true


func test_una_solicitud_hace_parpadear_su_entrada() -> bool:
	var desk := _make_desk()
	var request: RefCounted = desk.get_node("RequestManager").start_request(1)
	check(request != null, "la noche del escritorio tiene entidades")
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "Gonzalo en alerta")
	var timer := gonzalo.get_node("TimerLabel") as Label
	check(timer.visible, "muestra el tiempo")
	if request != null:
		check_eq(timer.text, str(ceili(request.get("time_left"))), "segundos")
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").state, ChatEntry.State.IDLE, "León sin solicitud")
	desk.free()
	return true


func test_cerrar_el_chat_deselecciona() -> bool:
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: `FALLA  test_desk_scene.gd :: test_una_solicitud_hace_parpadear_su_entrada` (todavía no existe `RequestManager` en la escena) y `139 pruebas OK, 1 fallidas`. La de los nombres ya pasa, porque la escena escribe los mismos nombres; desde ahora protege que vengan del catálogo.

- [ ] **Paso 3: Agregar `RequestManager` a la escena**

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="PackedScene" path="res://scenes/ui/chat_panel.tscn" id="chat_panel"]
```

por:

```ini
[ext_resource type="PackedScene" path="res://scenes/ui/chat_panel.tscn" id="chat_panel"]
[ext_resource type="Script" path="res://scripts/desk/request_manager.gd" id="requests_script"]
[ext_resource type="Resource" path="res://data/catalog.tres" id="catalog"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="UI" type="CanvasLayer" parent="."]
```

por:

```ini
[node name="RequestManager" type="Node" parent="."]
script = ExtResource("requests_script")
catalog = ExtResource("catalog")

[node name="UI" type="CanvasLayer" parent="."]
```

- [ ] **Paso 4: Conectar las entradas**

`scripts/desk/desk.gd` (archivo completo):

```gdscript
extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo
## (parpadean y muestran su tiempo mientras esperan respuesta) y abren el panel del chat.
## Los clics en el cuaderno, el celular y el mixer solo se registran (sus paneles llegan en los planes 4 y 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _selected_entry := -1

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _requests: RequestManager = $RequestManager


func _ready() -> void:
	for index in _entries.size():
		_entries[index].display_name = tr(_requests.catalog.friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	for clickable_name in ["Notebook", "Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void: print("Clic en ", clickable_name))


func _process(_delta: float) -> void:
	_refresh_entries()


func _on_entry_pressed(index: int) -> void:
	_selected_entry = index
	_chat_panel.open_for(_entries[index].display_name)
	_refresh_entries()


## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta. El tiempo, mientras espera.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _selected_entry:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		if entry.state != state:
			entry.set_state(state)
		entry.set_seconds_left(ceili(request.time_left) if request != null else -1)
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `140 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scenes/desk/desk.tscn scripts/desk/ test/
git commit -m "Las entradas del PC muestran las solicitudes" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: Panel del chat

**Archivos:**

- Crear: `scenes/ui/chat_theme.tres`
- Reescribir: `scenes/ui/chat_panel.tscn`, `scripts/ui/chat_panel.gd`, `test/test_chat_panel.gd`
- Modificar: `scripts/desk/desk.gd`, `scripts/desk/clickable_sprite.gd`, `data/text/ui.csv`, `test/test_desk_scene.gd`

El área útil de `screen_sprite` va de (21, 21) a (427, 674), medida en el archivo. Dentro, de arriba abajo: las pestañas, la conversación, la barra de identificación, las 4 preguntas y el lugar de las respuestas. Las pestañas y las conversaciones se crean por código en `setup()`, una por amigo del catálogo.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_panel.gd` (archivo completo; reemplaza las 4 pruebas del Plan 1):

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PANEL := preload("res://scenes/ui/chat_panel.tscn")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager


## Panel conectado a un manager con el catálogo de prueba (noche 1, sin solicitudes que lleguen solas).
func _make_panel() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.night_number = 1
	_manager.random_seed = 4
	_manager.requests_arrive = false
	root.add_child(_manager)
	var panel := PANEL.instantiate()
	root.add_child(panel)
	panel.setup(_manager, _manager.catalog.friends)
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


func test_esc_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	panel._unhandled_input(escape)
	check(not panel.visible, "oculto tras Esc")
	_free(panel)
	return true


func test_clic_izquierdo_fuera_lo_cierra_y_dentro_no() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._unhandled_input(_click_at(MOUSE_BUTTON_LEFT, Vector2(100, 100)))
	check(panel.visible, "sigue visible tras un clic dentro")
	panel._unhandled_input(_click_at(MOUSE_BUTTON_LEFT, Vector2(800, 300)))
	check(not panel.visible, "oculto tras un clic fuera")
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
	_free(panel)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.PROGRESS_KEY, panel_script.THINKING_KEY, panel_script.OPEN_NOTEBOOK_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var progress := String(TranslationServer.translate(panel_script.PROGRESS_KEY))
	check(progress.contains("{marked}") and progress.contains("{total}"), "IDENTIFY_PROGRESS debe tener {marked} y {total}")
	TranslationServer.set_locale(previous)
	return true
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
	leon.pressed.emit()
	check((desk.get_node("UI/ChatPanel") as Control).visible, "panel visible")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
	desk.free()
	return true
```

por:

```gdscript
	leon.pressed.emit()
	var panel := desk.get_node("UI/ChatPanel") as Control
	check(panel.visible, "panel visible")
	check_eq(panel.get("selected_friend"), 0, "en la conversación de León")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
	desk.free()
	return true


func test_el_chat_recibe_los_mensajes_de_las_solicitudes() -> bool:
	var desk := _make_desk()
	desk.get_node("RequestManager").start_request(2)
	check_eq(desk.get_node("UI/ChatPanel").message_views(2).size(), 1, "mensaje de Agustín en su conversación")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

Esperado: fallan las 11 pruebas de `test_chat_panel.gd` y 2 de `test_desk_scene.gd`, con `135 pruebas OK, 13 fallidas` (el panel del Plan 1 no tiene `setup()` ni pestañas).

- [ ] **Paso 3: Escribir el tema provisional**

`scenes/ui/chat_theme.tres`:

```ini
[gd_resource type="Theme" format=3]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_friend"]
content_margin_left = 8.0
content_margin_top = 6.0
content_margin_right = 8.0
content_margin_bottom = 6.0
bg_color = Color(0.07, 0.11, 0.18, 0.92)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.2, 0.3, 0.45, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_player"]
content_margin_left = 8.0
content_margin_top = 6.0
content_margin_right = 8.0
content_margin_bottom = 6.0
bg_color = Color(0.09, 0.25, 0.3, 0.92)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.2, 0.45, 0.52, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_normal"]
content_margin_left = 8.0
content_margin_top = 4.0
content_margin_right = 8.0
content_margin_bottom = 4.0
bg_color = Color(0.06, 0.09, 0.16, 0.9)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.22, 0.32, 0.5, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_hover"]
content_margin_left = 8.0
content_margin_top = 4.0
content_margin_right = 8.0
content_margin_bottom = 4.0
bg_color = Color(0.1, 0.16, 0.27, 0.95)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.4, 0.55, 0.8, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_pressed"]
content_margin_left = 8.0
content_margin_top = 4.0
content_margin_right = 8.0
content_margin_bottom = 4.0
bg_color = Color(0.09, 0.25, 0.3, 0.95)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.3, 0.6, 0.68, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_disabled"]
content_margin_left = 8.0
content_margin_top = 4.0
content_margin_right = 8.0
content_margin_bottom = 4.0
bg_color = Color(0.05, 0.07, 0.11, 0.6)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.14, 0.18, 0.26, 1)

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]

[resource]
default_font_size = 15
Button/colors/font_color = Color(0.9, 0.93, 0.96, 1)
Button/colors/font_disabled_color = Color(0.5, 0.55, 0.62, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_hover_pressed_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(1, 1, 1, 1)
Button/styles/disabled = SubResource("StyleBoxFlat_button_disabled")
Button/styles/focus = SubResource("StyleBoxEmpty_focus")
Button/styles/hover = SubResource("StyleBoxFlat_button_hover")
Button/styles/normal = SubResource("StyleBoxFlat_button_normal")
Button/styles/pressed = SubResource("StyleBoxFlat_button_pressed")
FriendBubble/base_type = &"PanelContainer"
FriendBubble/styles/panel = SubResource("StyleBoxFlat_friend")
Label/colors/font_color = Color(0.9, 0.93, 0.96, 1)
PlayerBubble/base_type = &"PanelContainer"
PlayerBubble/styles/panel = SubResource("StyleBoxFlat_player")
RichTextLabel/colors/default_color = Color(0.9, 0.93, 0.96, 1)
```

- [ ] **Paso 4: Escribir la escena del panel**

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
offset_bottom = 509.0
mouse_filter = 2

[node name="IdentifyBar" type="HBoxContainer" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 515.0
offset_right = 423.0
offset_bottom = 543.0

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
offset_top = 549.0
offset_right = 423.0
offset_bottom = 613.0
columns = 2

[node name="AnswerHint" type="Label" parent="Panel"]
layout_mode = 0
offset_left = 25.0
offset_top = 619.0
offset_right = 423.0
offset_bottom = 670.0
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3
```

- [ ] **Paso 5: Escribir el script del panel**

`scripts/ui/chat_panel.gd` (archivo completo):

```gdscript
extends Control
## Panel del chat (Plan 3): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la barra de identificación, las preguntas y el lugar de las respuestas (Plan 4).
## Se cierra con Esc, con clic derecho o con un clic izquierdo fuera del panel.

## Clic en el nombre de la entidad: el cuaderno abre su página (Plan 4).
signal entity_page_requested(friend_index: int, entity: EntityData)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"

var selected_friend := 0

var _manager: RequestManager
var _friend_names: Array[String] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []

@onready var _panel: TextureRect = $Panel
@onready var _tab_bar: HBoxContainer = $Panel/Tabs
@onready var _conversation_area: Control = $Panel/Conversations
@onready var _progress: Label = $Panel/IdentifyBar/Progress
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _questions: GridContainer = $Panel/Questions
@onready var _answer_hint: Label = $Panel/AnswerHint


func _ready() -> void:
	hide()
	_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
	for category: ClueCategory.Kind in MessageBuilder.QUESTION_KEYS:
		var button := Button.new()
		button.text = tr(MessageBuilder.QUESTION_KEYS[category])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
	_entity_button.pressed.connect(_on_entity_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)


## Conecta el panel a las solicitudes. Crea una pestaña y una conversación por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData]) -> void:
	_manager = manager
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


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación y las preguntas.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	_update_questions()


func _select(friend_index: int) -> void:
	selected_friend = friend_index
	_unread[friend_index] = false
	for index in _scrolls.size():
		_scrolls[index].visible = index == friend_index
		_tabs[index].set_pressed_no_signal(index == friend_index)
	_update_status()


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


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		get_viewport().set_input_as_handled()
	elif mouse.button_index == MOUSE_BUTTON_LEFT and not _panel.get_global_rect().has_point(mouse.position):
		# No se consume el clic: si cae en otra entrada del PC, abre el chat de ese amigo.
		hide()
```

- [ ] **Paso 6: Agregar los textos del panel**

Agregar al final de `data/text/ui.csv`:

```csv
CHAT_OPEN_NOTEBOOK,Abre el cuaderno para responder,
IDENTIFY_PROGRESS,Características marcadas: {marked} de {total},
IDENTIFY_THINKING,Matías piensa…,
```

- [ ] **Paso 7: Conectar el panel al escritorio**

`scripts/desk/desk.gd` (archivo completo):

```gdscript
extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo
## (parpadean y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación.
## Los clics en el cuaderno, el celular y el mixer solo se registran (sus paneles llegan en los planes 4 y 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _requests: RequestManager = $RequestManager


func _ready() -> void:
	_chat_panel.setup(_requests, _requests.catalog.friends)
	for index in _entries.size():
		_entries[index].display_name = tr(_requests.catalog.friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.entity_page_requested.connect(func(_friend_index: int, entity: EntityData) -> void:
		print("Abrir en el cuaderno la página de ", tr(entity.name_key), " (Plan 4)"))
	for clickable_name in ["Notebook", "Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void: print("Clic en ", clickable_name))


func _process(_delta: float) -> void:
	_refresh_entries()


func _on_entry_pressed(index: int) -> void:
	_chat_panel.open_for(index)
	_refresh_entries()


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

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
func _process(_delta: float) -> void:
	hovered = is_visible_in_tree() and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)
```

por:

```gdscript
func _process(_delta: float) -> void:
	# Si un panel abierto (como el chat) tapa el objeto, el mouse está sobre el panel: no se resalta.
	hovered = is_visible_in_tree() and get_viewport().gui_get_hovered_control() == null \
			and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)
```

Este cambio no tiene prueba automática: sin ventana, Godot no mueve el mouse. Se revisa a mano en la sección G de `docs/04` (Tarea 12).

- [ ] **Paso 8: Importar y verificar que pasan**

Esperado: `148 pruebas OK, 0 fallidas`.

- [ ] **Paso 9: Commit**

```bash
git add scenes/ scripts/ test/ data/text/
git commit -m "Panel del chat con pestañas, identificación y preguntas" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_chat.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `148 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Capturar el chat y revisarlo**

`test/capture_chat.gd` no empieza con `test_`, así que el ejecutor de pruebas no lo corre.

`test/capture_chat.gd`:

```gdscript
extends SceneTree
## Captura del chat para revisarlo a ojo (Plan 3). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_chat.gd -- /mnt/c/dev/capturas/chat.png
## León recibe una solicitud con señal 40 (estática), Gonzalo otra; se marca una característica,
## se clickea un señuelo y se pregunta "¿Qué ves?".

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
	manager.signal_levels[0] = 40.0
	var request: RefCounted = manager.start_request(0)
	manager.start_request(1)
	panel.open_for(0)
	await create_timer(4.0).timeout
	var view: Node = panel.message_views(0)[0]
	var decoys: Array = request.get("decoys")
	var traits: Array = request.get("traits")
	view.clue_clicked.emit(view, (decoys[0] as TraitData).id)
	view.clue_clicked.emit(view, (traits[0] as TraitData).id)
	manager.ask(0, ClueCategory.Kind.SIGHT)
	await create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
	quit()
```

Se ejecuta **con ventana** (sin `--headless`): Godot abre una ventana unos 8 segundos y se cierra solo.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_chat.gd -- /mnt/c/dev/capturas/chat.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: `Captura guardada en C:\dev\capturas\chat.png`. Abrir la imagen (con la herramienta Read) y comprobar:

- arriba, las pestañas "León" (seleccionada, con su tiempo), "Gonzalo" (con su tiempo y `•`) y "Agustín";
- el mensaje de León tiene palabras tapadas (`▒▒▒`), frases en ámbar subrayadas, una característica en verde y un señuelo en rojo;
- debajo, la pregunta de Matías ("¿Qué ves?") a la derecha y la respuesta del amigo;
- la barra dice "Características marcadas: 1 de 2", y se ven los 4 botones de pregunta y "Abre el cuaderno para responder";
- en el PC, la entrada de León aparece seleccionada y la de Gonzalo en alerta, cada una con su tiempo.

Si algo no coincide, revisar antes de seguir. Si `▒` se ve como un cuadrado vacío, falta el glifo en la fuente: avisar a Benja (pasa a "Errores encontrados").

- [ ] **Paso 3: Agregar la sección G a `docs/04_instrucciones_godot.md`**

En la tabla **Estado**, agregar la fila `| **G.** Probar las solicitudes y el chat (Plan 3) | ⬜ Pendiente (unos 10 minutos) |`. Al final del archivo, agregar:

````markdown
---

## G. Probar las solicitudes y el chat (Plan 3)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Llega una solicitud:** a los 5 segundos, una entrada del PC parpadea y muestra los segundos que le quedan al amigo.
3. **Abre el chat:** haz clic en esa entrada. A la izquierda se abre el chat en la conversación de ese amigo:
   - arriba hay una pestaña por amigo, con su tiempo y un `•` si tiene mensajes sin leer;
   - el mensaje aparece escrito de a poco;
   - las frases en ámbar y subrayadas se pueden clickear.
4. **Identifica:** clickea las frases en ámbar.
   - Las características reales se ponen verdes y la barra cuenta "Características marcadas: 1 de 2".
   - Los señuelos vibran y se ponen rojos.
   - Con las 2 marcadas, la barra dice "Matías piensa…" y a los 3 segundos aparece el nombre (El Trauco).
   - Al clickear el nombre, en el panel **Output** (Salida) aparece "Abrir en el cuaderno la página de El Trauco (Plan 4)".
5. **Pregunta:** cada botón (¿Qué ves?, ¿Qué oyes?…) resta 5 segundos, y el amigo responde con lo de esa categoría. Con 5 segundos o menos, los botones se desactivan.
6. **Sin respuesta:** si se acaba el tiempo, el amigo cuenta que decidió solo y su entrada deja de parpadear. Responder desde el cuaderno llega en el Plan 4.
7. **Estática:**
   - en el panel **Scene**, selecciona el nodo `RequestManager`;
   - en el **Inspector**, baja **Test Signal** a 40 (se tapa el 25 % de las palabras) o a 20 (el 45 %);
   - vuelve a probar con **F5**: algunas palabras aparecen como `▒▒▒`. Una frase tapada no se puede clickear: pregunta por su categoría para recuperarla.
8. **El panel tapa el escritorio:** con el chat abierto, pasa el mouse por donde están el mixer y el celular, detrás del panel. No deben resaltarse, y un clic no debe escribir "Clic en Mixer" en **Output**. Cierra el chat (`Esc` o clic derecho) y vuelve a probar: ahora sí se resaltan.
9. **Al terminar, deja Test Signal en 100**, o cierra la escena sin guardar.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Noche que se juega:** **Night Number**, en el Inspector de `RequestManager`. Por ahora solo la noche 3 tiene una entidad. Cuando agregues El Tue Tué y La Calchona a la noche 1, cámbialo a 1.
- **Señuelos por noche:** `data/nights/night_N.tres` > **Decoys In First Message**.
- **Los señuelos:** `data/catalog.tres` > **Decoys**. Cada uno tiene `Id`, `Category`, `Text Key` y `Place Keys` (vacío: sirve en cualquier lugar; si no, las claves de sus lugares, como `PLACE_FOREST`). Su texto va en `data/text/messages.csv`, con la frase clickeable entre asteriscos.
- Después de cambiar datos, pídele a Claude que corra las pruebas: el validador avisa en español si falta algo, como un lugar sin suficientes señuelos.
````

- [ ] **Paso 4: Actualizar la hoja de ruta, el registro y el resumen**

- `docs/06_plan_v1.md`: en la línea del Plan 3, cambiar "(por ejecutar)" por "(ejecutado)".
- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos debe figurar la sección G de `docs/04`.
- `docs/00_log.md`:
  - S9 queda ✅;
  - S10 (escribir el Plan 4: cuaderno) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/10` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/ scenes/
git commit -m "Plan 3 terminado: solicitudes y chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 3):

  | Requisito | Tarea |
  | --- | --- |
  | Generador de solicitudes | 6, con el ritmo provisional en la 8 |
  | Armado de mensajes con características marcadas | 4 y 7 |
  | Señuelos (decisión de Benja) | 1, 2, 6, 7, 9 y 11 |
  | Estática, con la frase entera o nada | 5, aplicada en la 8 |
  | Preguntas (5 s; desactivadas con 5 s o menos) | 3, 7, 8 y 11 |
  | Panel del chat: pestañas, mensajes y escritura progresiva | 9 y 11 |
  | Identificación por clic con 3 s de espera y barra de avance | 3, 8, 9 y 11 |
  | Temporizadores y el amigo que decide solo | 3, 6, 8, 10 y 11 |
  | "Llegan solicitudes; se identifican clickeando; se pregunta" | 8, 10, 11 y 12 (`docs/04`, G) |

- **Fuera de este plan, a propósito:**
  - **Responder desde el cuaderno (Plan 4).** El panel muestra "Abre el cuaderno para responder". `FriendRequest.finish(action, true)` ya existe, y `entity_page_requested` avisa qué página abrir.
  - **Consecuencias (Plan 5).** Cuando el amigo decide solo, la solicitud termina con su resultado, pero no hay daño ni baja Trust. `request_finished` lleva todo lo necesario.
  - **Señal que baja e interferencias (Plan 6).** Mientras tanto, `test_signal`.
  - **Director de ritmo (Plan 7).** El ritmo de `RequestManager` es provisional.
  - **Sonido** de cada mensaje y alarma (Plan 9).
  - **Arte del chat:** el tema y los colores son provisionales; tampoco hay avatares ni "escribiendo…".
  - **La tipografía pixel** que se elija debe tener `▒` (U+2592); si no, se cambia `ChatMessage.COVER_TEXT`.
  - **Señuelos en las respuestas:** por decisión de Benja, se prueba primero sin ellos.
  - **El Tue Tué y La Calchona** entran a la noche 1 como datos cuando Benja los termine (`docs/04`, F).
- **Nombres consistentes:**
  - `DecoyData`, `fits_place`, `decoys`, `decoys_for_place` y `decoys_in_first_message` coinciden entre las clases, los datos, las pruebas y el validador;
  - `FriendRequest` (`Identification`, `ClueState`, `QUESTION_COST`, `THINKING_TIME`, `traits`, `decoys`, `first_clues`, `first_observations`, `click_clue`, `clue_state`, `marked_count`, `can_ask`, `pay_question`, `advance`, `is_out_of_time`, `finish` y `decide_alone`) se usa igual en el generador, el armado de mensajes, el manager, la burbuja y el panel;
  - `ChatMessage` (`Sender`, `Token`, `COVER_TEXT`, `add_fragment`, `plain_text` y `request`) y `ChatStatic` (`coverage_for_signal` y `apply`) coinciden con sus pruebas;
  - `RequestGenerator` (`generate`, `distinguishing_pairs`, `decision_time` y `shuffled`) y `MessageBuilder` (`first_message`, `answer`, `question`, `decided_alone`, `QUESTION_KEYS`, `NOTHING_KEYS` y `DECIDED_ALONE_KEY`) coinciden entre tareas;
  - las señales de `RequestManager` (`message_added`, `request_started`, `request_changed` y `request_finished`) y sus métodos y variables (`start_request`, `ask`, `click_clue`, `advance`, `active_count`, `night`, `requests` y `signal_levels`) son los que usan el panel, el escritorio y las pruebas;
  - `ChatPanel` (`setup`, `open_for`, `selected_friend`, `message_views`, `entity_page_requested`, `PROGRESS_KEY`, `THINKING_KEY`, `OPEN_NOTEBOOK_KEY` y `UNREAD_MARK`) y `ChatMessageView` (`clue_clicked`, `refresh`, `shake`, `finish_typing`, `INDENT` y los colores) coinciden con sus pruebas y con `desk.gd`.
- **Conteo de pruebas acumulado:** 78 → 82, 88, 96, 102, 107, 116, 122, 130, 138, 140 y 148.
