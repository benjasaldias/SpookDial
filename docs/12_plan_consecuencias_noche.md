# Plan 5: Consecuencias, medidores y noche — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que una noche completa se gane o se pierda:

- cada respuesta tiene consecuencias: el amigo puede quedar herido y aturdido, Trust baja según el riesgo de lo elegido, y la acción de mayor riesgo da un video extra si el amigo sobrevive;
- cuando un amigo queda herido, grita en el chat ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y el juego avisa en rojo, centrado, cuánta vida le queda: "León recibió daño: 2/3";
- los medidores funcionan: Sanity baja con el tiempo y oscurece la vista con una viñeta, Trust se recupera sin errores y acorta los temporizadores cuando baja, y Connection es el promedio de las señales;
- los diales de la pared, la hora en el celular, los videos en el PC y la vida de cada amigo en su entrada muestran el estado de la noche;
- la noche dura de las 00:00 a las 06:00: se gana con la cuota cumplida y se pierde si muere un amigo, si un dial llega a 0 o si falta contenido. Una pantalla explica qué pasó y permite reintentar.

**Arquitectura:**

- `data/balance.tres` (`BalanceData`): los valores de equilibrio que valen para todas las noches, editables en el Inspector.
- `scripts/core/` (lógica pura, se prueba sin escena): `Consequence` (la consecuencia de una acción), `FriendState` (vida, aturdimiento y señal de un amigo), `VideoSchedule` (los envíos y la cuota), `NightState` (la hora, Sanity, Trust, los amigos, los videos y cómo termina la noche) y `EndingText` (los textos de la pantalla final).
- `RequestManager` crea el `NightState`, aplica las consecuencias y no da solicitudes a un amigo aturdido. Si el amigo queda herido, agrega al chat el aviso de daño, un mensaje del juego (`ChatMessage.Sender.SYSTEM`). `NightManager` (un nodo nuevo) es el reloj de la noche: avanza las solicitudes y el estado, y avisa cuando la noche termina.
- El escritorio muestra los medidores y, al terminar la noche, la pantalla final (`scenes/ui/end_screen.tscn`).

**Stack:** Godot 4.7.2 (GDScript con tipado estático, un shader `canvas_item` para la viñeta). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §5, §6, §9 y §10, y `docs/02_bucle_central.md` §2, §5.2 y §6.

---

## Decisiones de este plan

### De Benja (sesión 12, 31 de octubre)

Están en `CLAUDE.md`, en el diseño v2 y en `docs/02`, salvo la primera, que es provisional y está en `docs/06` §2.

| Decisión | Detalle |
| --- | --- |
| **Los videos se reciben solos hasta el Plan 6.** | Este plan trae la cuota, el contador del PC y los envíos programados, que cuentan apenas llegan. El video extra de la acción de mayor riesgo también. En el Plan 6 llegan con un aviso: hay que aceptarlos en 10 s y descargarlos manteniendo presionado. Así, una noche ya se gana o se pierde con este plan. |
| **El video de un amigo aturdido se atrasa.** | Si a un amigo le toca enviar un video mientras está aturdido, lo envía apenas se recupera. Pasa lo mismo con el video extra cuando la acción de mayor riesgo lo hirió. |
| **Cada dial conserva su color.** | Connection va en verde, Sanity en rojo y Trust en amarillo, como en el Plan 1. El valor lo muestra el ángulo de la aguja. |
| **El aviso de daño en el chat.** | Cuando un amigo queda herido, su reacción es un grito en primera persona ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y, debajo, el juego avisa en rojo y centrado cuánta vida le queda: "León recibió daño: 2/3". La vida sigue siendo de 3 puntos. |
| **Los textos son reales, en primera persona.** | Ya no se usa `[PROTO]`: Claude escribe un borrador real de cada texto, y Benja lo corrige después. Las 2 reacciones nuevas van así. |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| `BalanceData` (`data/balance.tres`) guarda los valores de equilibrio que valen para todas las noches: la duración de la noche, la vida, el aturdimiento, las consecuencias, cómo se recupera Trust y desde dónde aparece la viñeta. El catálogo lo referencia. | El contenido es datos (regla 7): Benja ajusta los valores en el Inspector al probar, sin tocar código. Los que cambian por noche siguen en `NightData`. Las pruebas usan `BalanceData.new()`, y una prueba verifica que sus valores por defecto sean los del archivo. |
| Lógica pura en `scripts/core/`: `Consequence`, `FriendState`, `VideoSchedule`, `NightState` y `EndingText`. | Como en los planes anteriores: cada clase tiene una sola responsabilidad y se prueba sin escena. |
| `RequestManager` crea el `NightState`. | Tiene el catálogo, la noche y el generador de números al azar. Así, sus pruebas y las del chat se siguen armando igual. |
| La señal de cada amigo pasa de `RequestManager.signal_levels` a `FriendState.signal_level`. **Test Signal** sigue en el Inspector de `RequestManager`. | La señal es del amigo, como su vida. El Plan 6 la hace bajar ahí. |
| `RequestManager` tira la consecuencia y la aplica **antes** de armar la reacción del amigo. `request_finished` sale con la consecuencia ya aplicada, en `request.consequence`. | La reacción depende de si el amigo quedó herido. |
| Sin respuesta, el amigo cuenta qué hizo y, en otro mensaje, cómo le fue. | Las reacciones son las mismas que cuando responde Matías, así que sus textos sirven para los dos casos. |
| Un amigo aturdido o muerto no recibe solicitudes. | Diseño §9: mientras está aturdido, no pide ayuda. |
| `NightManager`, un nodo nuevo del escritorio, es el reloj de la noche. En cada frame avanza las solicitudes, después el estado de la noche, y revisa si terminó. `RequestManager` ya no avanza solo. | Un solo nodo mueve el tiempo, así que al terminar la noche todo se detiene junto. Los screamers del Plan 7 van a pausar los temporizadores en el mismo lugar. |
| La noche se pierde **en el acto** si muere un amigo o un dial llega a 0. A las 06:00 se gana con la cuota cumplida, y se pierde sin ella. Si pasan dos cosas a la vez, se explica primero la muerte. | Diseño §5. La muerte es lo que más necesita explicación (`docs/02` §2, paso 9). |
| Los envíos programados se reparten parejo en la noche, cada uno de un amigo al azar. Con 3 videos llegan a las 01:30, 03:00 y 04:30. | Es simple y deja tiempo para aceptar y descargar cada video cuando llegue el Plan 6. El director del Plan 7 puede cambiarlo. |
| Trust se recupera de forma exacta: solo cuenta la parte de cada paso que cae después de 20 s sin errores. | El resultado no depende de cuántos frames por segundo tenga el juego, y las pruebas pueden avanzar varios segundos de una vez. |
| La hora va en el celular: un `Label` sobre un parche del color de la pantalla, que tapa el "00:00" dibujado. | Es provisional hasta el arte: `phone_sprite` sin la hora y una tira de dígitos LCD (`docs/06` §3). |
| Los videos van en la franja negra de arriba de la pantalla del PC: "Videos: 1 de 3". | Diseño §6: el PC muestra el contador de contenido de la noche. Es el único espacio libre en la pantalla. |
| La vida va en la entrada del PC: una marca por punto, llena si lo tiene o vacía (solo el borde) si lo perdió. Mientras el amigo está aturdido, su entrada se oscurece y el temporizador dice "Aturdido 12". | No depende solo del color (diseño §19). Las marcas son provisionales hasta el arte de las entradas. |
| La viñeta es un shader sobre toda la pantalla, también sobre el chat y el cuaderno. Aparece bajo 60 de Sanity y avanza hacia el centro en 5 bandas. | Diseño §10.2: la visión se oscurece. Las bandas se ven como pixel art. El umbral está en `BalanceData`, y la forma, en el material del shader. |
| La pantalla final aparece de a poco (1,5 s) y tapa todo. Al perder dice por qué. Si murió un amigo, explica la solicitud: la entidad, lo que observaba, la regla que se aplicaba, la acción correcta y la elegida. Su botón recarga la escena. | Diseño §5 y `docs/02` §2, paso 9. Al recargar, la noche se genera de nuevo, así que no se repite de memoria. El resumen entre noches y el paso a la noche siguiente son del Plan 8. |
| Los textos de la pantalla final, del PC, de la entrada y del aviso de daño van en `ui.csv`. Las 2 reacciones nuevas van en `messages.csv`. | Los primeros son interfaz; las reacciones son lo que dicen los amigos. Todos son borradores reales que Benja corrige (regla 8). |
| El aviso de daño es un mensaje del juego (`ChatMessage.Sender.SYSTEM`): va centrado y en rojo, sin nombre ni burbuja, aparece de una vez y no pasa por la estática. Marca la pestaña del amigo como mensaje nuevo. | No lo escribe el amigo, así que no lleva su nombre ni le afecta la señal. Es lo más importante que puede pasar en el chat. |
| La hora del celular, los videos del PC y la pantalla final usan Departure Mono, la fuente del chat y de las entradas del PC, en múltiplos de 11 px. | Así se ven como parte de la misma pantalla. En múltiplos de 11 px, la fuente se ve nítida. |

**Verificado en Godot 4.7.2**, en copias aparte del proyecto, ya borradas:

- todo el código de este plan se ejecutó: 251 pruebas OK, sin errores al correr, y dos capturas revisadas a ojo (el escritorio a las 03:00 con la viñeta, y la pantalla de derrota con el aviso de daño detrás);
- después, el plan **tal como está escrito** se aplicó a una copia limpia del proyecto: los conteos de pruebas que dice coinciden, incluidas las fallas esperadas, y el código resultante es idéntico al probado;
- se validó dos veces: al escribirlo (sesión 12) y después de agregar el aviso de daño y el estilo nuevo del chat (también en la sesión 12).

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `185 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.
- [ ] **Textos de Benja:** los textos de los CSV pueden tener cambios de Benja. Este plan no los reemplaza: solo agrega líneas al final.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar.** Al importar, Godot registra las clases nuevas (`class_name`), crea los `.uid` de los scripts nuevos y regenera las traducciones de los CSV. Cada tarea importa antes de correr las pruebas:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "SCRIPT|Parse" ; echo "import listo"
```

Esperado: solo `import listo`. Si aparece `SCRIPT ERROR`, el script tiene un error de sintaxis: corregirlo y volver a importar. En los pasos "Verificar que fallan", el import puede no mostrar nada aunque una prueba nueva no cargue: el error aparece al correr las pruebas.

**Pruebas.** Para ver solo las fallas y el resumen:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

**Commits.** Cada tarea termina en un commit, pero Claude **pregunta a Benja antes de cada uno**, salvo que Benja autorice de una vez todos los commits del plan al empezar (`CLAUDE.md`, regla 11). La línea `Co-Authored-By` nombra al modelo que ejecuta: los comandos dicen Sonnet 5.5, como propone `docs/00_log.md`; si ejecuta otro, se cambia el nombre. El push solo se hace con autorización.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

**Tabuladores:** GDScript indenta con tabuladores. Los bloques de este plan los tienen: al copiarlos, no hay que convertirlos en espacios. Lo más seguro es copiar cada bloque con un script, como en los planes anteriores.

**Cómo leer los cambios:**

- "`ruta`:" seguido de un bloque: crear el archivo con ese contenido.
- "`ruta` (archivo completo):": reemplazar todo el contenido del archivo.
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo.
- "Agregar al final de `ruta`:": en un `.gd`, dejar dos líneas en blanco antes de la primera función agregada; en un `.tscn` o un `.md`, una línea en blanco; en un `.csv`, agregar las líneas tal cual.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/balance_data.gd`, `data/balance.tres` | `BalanceData`: los valores de equilibrio de todas las noches |
| `scripts/data/content_catalog.gd`, `data/catalog.tres` | Se agrega `balance` |
| `scripts/core/consequence.gd` | `Consequence`: el daño, el cambio de Trust y si fue la acción de mayor riesgo |
| `scripts/core/friend_state.gd` | `FriendState`: la vida, el aturdimiento y la señal de un amigo |
| `scripts/core/video_schedule.gd` | `VideoSchedule`: los envíos programados, los videos extra y la cuota |
| `scripts/core/night_state.gd` | `NightState`: la hora, Sanity, Trust, los amigos, los videos y cómo termina la noche |
| `scripts/core/ending_text.gd` | `EndingText`: el título y la explicación de la pantalla final, en BBCode |
| `scripts/core/friend_request.gd` | Se agrega `consequence` |
| `scripts/core/chat_message.gd` | Se agrega `Sender.SYSTEM`: los avisos del juego |
| `scripts/core/message_builder.gd` | La reacción depende también de si el amigo quedó herido, y se agrega el aviso de daño |
| `scripts/desk/request_manager.gd` | Crea el `NightState`, aplica las consecuencias y no da solicitudes a un amigo aturdido |
| `scripts/desk/night_manager.gd` | `NightManager`: el reloj de la noche y cuándo termina |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | Los diales, la hora, los videos, la vida en las entradas, la viñeta y la pantalla final |
| `shaders/vignette.gdshader` | La viñeta de Sanity |
| `scripts/ui/chat_entry.gd`, `scenes/ui/chat_entry.tscn` | Las marcas de vida y el aturdimiento en la entrada del PC |
| `scripts/ui/chat_message_view.gd`, `scripts/ui/chat_panel.gd`, `scenes/ui/chat_theme.tres` | El aviso de daño: centrado, en rojo y sin nombre |
| `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn` | La pantalla del final de la noche |
| `data/text/ui.csv`, `data/text/messages.csv` | Textos del PC, de la entrada, del aviso de daño y de la pantalla final; las reacciones de un amigo herido |
| `test/content_fixtures.gd` | El catálogo de prueba incluye `BalanceData` |
| `test/test_*.gd` | Pruebas de cada tarea |
| `test/capture_night.gd` | Capturas de la noche para revisarla a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
NightManager.advance(delta), en cada frame mientras la noche no termine
  1. RequestManager.advance(delta): temporizadores; sin respuesta, el amigo decide solo
  2. NightState.advance(delta): hora, Sanity, Trust, aturdimiento y videos ──▶ video_received
  3. NightState.ending() ──▶ night_ended(cómo terminó, solicitud en la que murió un amigo)

RequestManager.answer() o _decide_alone()
  FriendRequest.finish() ─▶ Consequence (daño, Trust, mayor riesgo) ─▶ NightState.apply()
  ─▶ reacción del amigo (herido o no) ─▶ aviso de daño, si quedó herido
  ─▶ request_finished ─▶ NightManager revisa si terminó

desk.gd (escritorio), en cada frame
  diales ◀ NightState (connection, sanity y trust)     celular ◀ clock_text()
  PC ◀ videos (recibidos y cuota)                       entradas ◀ FriendState (vida y aturdimiento)
  viñeta ◀ vignette_strength()
  night_ended ─▶ EndScreen.show_ending() ─ retry_pressed ─▶ recarga la escena
```

---

### Tarea 1: Valores de equilibrio como datos

**Archivos:**

- Crear: `scripts/data/balance_data.gd`, `data/balance.tres`, `test/test_balance.gd`
- Modificar: `scripts/data/content_catalog.gd`, `data/catalog.tres`, `test/content_fixtures.gd`

`BalanceData` guarda los valores de `docs/02` §5.2 y §6 que valen para todas las noches. El catálogo lo referencia, y el catálogo de prueba usa sus valores por defecto.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_balance.gd`:

```gdscript
extends "res://test/test_case.gd"

const BALANCE_PATH := "res://data/balance.tres"


## Los valores iniciales de docs/02 §5.2 y §6.
func test_valores_de_docs_02() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.night_seconds, 420.0, "una noche dura 7 minutos")
	check_eq(balance.friend_health, 3, "3 PV")
	check_eq(balance.stun_seconds, 15.0, "aturdido 15 s")
	check_eq(balance.risky_hurt_chance, 0.7, "mayor riesgo: 70 %")
	check_eq(balance.risky_damage, 2, "mayor riesgo: −2 PV")
	check_eq(balance.risky_trust, -20.0, "mayor riesgo: Trust −20")
	check_eq(balance.wrong_hurt_chance, 0.6, "incorrecta: 60 %")
	check_eq(balance.wrong_damage, 1, "incorrecta: −1 PV")
	check_eq(balance.wrong_trust, -10.0, "incorrecta: Trust −10")
	check_eq(balance.no_answer_trust, -15.0, "sin respuesta: Trust −15 extra")
	check_eq(balance.trust_recovery_interval, 8.0, "Trust +1 cada 8 s")
	check_eq(balance.trust_recovery_delay, 20.0, "si no hubo errores en 20 s")
	return true


## Las pruebas usan BalanceData.new(): sus valores por defecto deben ser los de data/balance.tres.
func test_los_valores_por_defecto_son_los_del_archivo() -> bool:
	var saved: BalanceData = load(BALANCE_PATH)
	var defaults := BalanceData.new()
	for property: Dictionary in defaults.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var property_name: String = property["name"]
			check_eq(saved.get(property_name), defaults.get(property_name), property_name)
	return true


func test_el_catalogo_usa_el_equilibrio() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check(catalog.balance != null, "catalog.tres tiene Balance")
	if catalog.balance != null:
		check_eq(catalog.balance.resource_path, BALANCE_PATH, "es data/balance.tres")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `185 pruebas OK, 1 fallidas`. La falla es `test_balance.gd :: no se pudo cargar`, porque la clase `BalanceData` no existe.

- [ ] **Paso 3: Crear `BalanceData` y su archivo**

`scripts/data/balance_data.gd`:

```gdscript
class_name BalanceData
extends Resource
## Valores de equilibrio que valen para todas las noches (docs/02 §5.2 y §6): cuánto dura la noche,
## la vida y el aturdimiento de los amigos, las consecuencias de cada acción y cómo se recupera Trust.
## Se ajustan probando, en el Inspector de data/balance.tres. Los que cambian por noche están en NightData.

## Segundos reales que dura una noche, de las 00:00 a las 06:00 (diseño §5).
@export var night_seconds := 420.0

@export_group("Amigos")
## Vida de cada amigo al empezar la noche. Con 0, muere y se pierde la noche.
@export var friend_health := 3
## Segundos que un amigo herido queda aturdido: no pide ayuda ni envía videos.
@export var stun_seconds := 15.0

@export_group("Consecuencias")
## Probabilidad de que la acción de mayor riesgo hiera al amigo.
@export_range(0.0, 1.0) var risky_hurt_chance := 0.7
## Vida que le quita la acción de mayor riesgo si lo hiere.
@export var risky_damage := 2
## Trust que se pierde por elegir la acción de mayor riesgo (negativo).
@export var risky_trust := -20.0
## Probabilidad de que una acción incorrecta hiera al amigo.
@export_range(0.0, 1.0) var wrong_hurt_chance := 0.6
## Vida que le quita una acción incorrecta si lo hiere.
@export var wrong_damage := 1
## Trust que se pierde por una acción incorrecta (negativo).
@export var wrong_trust := -10.0
## Trust que se pierde, además, cuando nadie responde a tiempo y el amigo decide solo (negativo).
@export var no_answer_trust := -15.0

@export_group("Trust")
## Trust sube 1 punto cada tantos segundos…
@export var trust_recovery_interval := 8.0
## …si no bajó en los últimos tantos segundos.
@export var trust_recovery_delay := 20.0

@export_group("Sanity")
## Bajo este valor de Sanity aparece la viñeta, que se oscurece más mientras más baja.
@export var vignette_start := 60.0
```

`data/balance.tres`:

```ini
[gd_resource type="Resource" script_class="BalanceData" format=3]

[ext_resource type="Script" path="res://scripts/data/balance_data.gd" id="1_balance"]

[resource]
script = ExtResource("1_balance")
night_seconds = 420.0
friend_health = 3
stun_seconds = 15.0
risky_hurt_chance = 0.7
risky_damage = 2
risky_trust = -20.0
wrong_hurt_chance = 0.6
wrong_damage = 1
wrong_trust = -10.0
no_answer_trust = -15.0
trust_recovery_interval = 8.0
trust_recovery_delay = 20.0
vignette_start = 60.0
```

- [ ] **Paso 4: Conectar el catálogo**

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
@export var decoys: Array[DecoyData] = []
```

por:

```gdscript
@export var decoys: Array[DecoyData] = []
## Valores de equilibrio de todas las noches (data/balance.tres).
@export var balance: BalanceData
```

En `data/catalog.tres`, reemplazar:

```ini
[ext_resource type="Script" path="res://scripts/data/decoy_data.gd" id="12_decoy"]
```

por:

```ini
[ext_resource type="Script" path="res://scripts/data/decoy_data.gd" id="12_decoy"]
[ext_resource type="Resource" path="res://data/balance.tres" id="13_balance"]
```

En `data/catalog.tres`, reemplazar:

```ini
decoys = Array[ExtResource("12_decoy")]([SubResource("Decoy_cold_breath"), SubResource("Decoy_distant_dog"), SubResource("Decoy_flickering_light"), SubResource("Decoy_wet_grass"), SubResource("Decoy_trunk_moss"), SubResource("Decoy_creaking_branches")])
```

por:

```ini
decoys = Array[ExtResource("12_decoy")]([SubResource("Decoy_cold_breath"), SubResource("Decoy_distant_dog"), SubResource("Decoy_flickering_light"), SubResource("Decoy_wet_grass"), SubResource("Decoy_trunk_moss"), SubResource("Decoy_creaking_branches")])
balance = ExtResource("13_balance")
```

En `test/content_fixtures.gd`, reemplazar:

```gdscript
## Catálogo válido: 3 amigos, 5 noches y 2 señuelos que sirven en cualquier lugar
## ("decoy_sight" y "decoy_sound"); "beast" aparece la noche 1 y "ghost" la noche 2.
static func make_catalog() -> ContentCatalog:
	var catalog := ContentCatalog.new()
```

por:

```gdscript
## Catálogo válido: 3 amigos, 5 noches, 2 señuelos que sirven en cualquier lugar ("decoy_sight" y
## "decoy_sound") y los valores de equilibrio por defecto; "beast" aparece la noche 1 y "ghost" la noche 2.
static func make_catalog() -> ContentCatalog:
	var catalog := ContentCatalog.new()
	catalog.balance = BalanceData.new()
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `188 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/data/ data/ test/
git commit -m "Valores de equilibrio como datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: La consecuencia de una acción

**Archivos:**

- Crear: `scripts/core/consequence.gd`, `test/test_consequence.gd`

`Consequence` tira la consecuencia de un resultado con las probabilidades de `BalanceData` (`docs/02` §5.2). Trust baja según el riesgo de lo elegido, aunque el amigo no quede herido.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_consequence.gd`:

```gdscript
extends "res://test/test_case.gd"

const Consequence := preload("res://scripts/core/consequence.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Equilibrio por defecto, pero con la probabilidad de herir fija: 1 (siempre) o 0 (nunca).
func _balance(hurt_chance: float) -> BalanceData:
	var balance := BalanceData.new()
	balance.risky_hurt_chance = hurt_chance
	balance.wrong_hurt_chance = hurt_chance
	return balance


func _roll(outcome: RuleEvaluator.Outcome, by_player: bool, hurt_chance: float) -> Consequence:
	return Consequence.new(outcome, by_player, _balance(hurt_chance), RandomNumberGenerator.new())


func test_la_accion_correcta_no_tiene_consecuencias() -> bool:
	var consequence := _roll(RuleEvaluator.Outcome.CORRECT, true, 1.0)
	check_eq(consequence.damage, 0, "sin daño")
	check_eq(consequence.trust_change, 0.0, "Trust igual")
	check(not consequence.risky and not consequence.is_hurt(), "ni riesgo ni herida")
	return true


func test_la_accion_de_mayor_riesgo() -> bool:
	var hurt := _roll(RuleEvaluator.Outcome.RISKY, true, 1.0)
	check_eq(hurt.damage, 2, "−2 PV")
	check(hurt.is_hurt(), "herido")
	check_eq(hurt.trust_change, -20.0, "Trust −20")
	check(hurt.risky, "da un video extra si sobrevive")
	var lucky := _roll(RuleEvaluator.Outcome.RISKY, true, 0.0)
	check_eq(lucky.damage, 0, "sin daño si tiene suerte")
	check_eq(lucky.trust_change, -20.0, "Trust baja según el riesgo, no según la suerte")
	return true


func test_una_accion_incorrecta() -> bool:
	var hurt := _roll(RuleEvaluator.Outcome.WRONG, true, 1.0)
	check_eq(hurt.damage, 1, "−1 PV")
	check_eq(hurt.trust_change, -10.0, "Trust −10")
	check(not hurt.risky, "no da video")
	check_eq(_roll(RuleEvaluator.Outcome.WRONG, true, 0.0).trust_change, -10.0, "Trust −10 aunque no lo hiera")
	return true


func test_sin_respuesta_trust_baja_ademas() -> bool:
	check_eq(_roll(RuleEvaluator.Outcome.CORRECT, false, 0.0).trust_change, -15.0, "acertó solo: −15")
	check_eq(_roll(RuleEvaluator.Outcome.WRONG, false, 0.0).trust_change, -25.0, "incorrecta y sin respuesta: −25")
	return true


## Con las probabilidades de docs/02 (70 % y 60 %), en 2000 tiradas.
func test_probabilidad_de_herir() -> bool:
	var balance := BalanceData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var hurt := {RuleEvaluator.Outcome.RISKY: 0, RuleEvaluator.Outcome.WRONG: 0}
	for _i in 2000:
		for outcome: RuleEvaluator.Outcome in hurt:
			if Consequence.new(outcome, true, balance, rng).is_hurt():
				hurt[outcome] += 1
	check(abs(hurt[RuleEvaluator.Outcome.RISKY] / 2000.0 - 0.7) < 0.04, "mayor riesgo cerca de 70 %%: %d" % hurt[RuleEvaluator.Outcome.RISKY])
	check(abs(hurt[RuleEvaluator.Outcome.WRONG] / 2000.0 - 0.6) < 0.04, "incorrecta cerca de 60 %%: %d" % hurt[RuleEvaluator.Outcome.WRONG])
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `188 pruebas OK, 1 fallidas`. La falla es `test_consequence.gd :: no se pudo cargar`, porque `consequence.gd` no existe.

- [ ] **Paso 3: Crear `Consequence`**

`scripts/core/consequence.gd`:

```gdscript
extends RefCounted
## Lo que le pasa a un amigo después de una acción (diseño §9, docs/02 §5.2): cuánta vida pierde,
## cuánto baja Trust y si fue la acción de mayor riesgo, que da un video extra si el amigo sobrevive.
## Lógica pura: RequestManager la tira al terminar una solicitud y NightState la aplica.

const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Vida que pierde el amigo. Con más de 0 queda herido (y aturdido, si sobrevive).
var damage := 0
## Cuánto cambia Trust (0 o negativo). Baja según el riesgo de lo elegido, no según la suerte (diseño §9).
var trust_change := 0.0
## Fue la acción de mayor riesgo.
var risky := false


## Tira la consecuencia de `outcome` con las probabilidades de `balance`. `answered_by_player` es false
## si nadie respondió a tiempo y el amigo decidió solo: entonces Trust baja además.
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator) -> void:
	match outcome:
		RuleEvaluator.Outcome.RISKY:
			risky = true
			trust_change = balance.risky_trust
			if rng.randf() < balance.risky_hurt_chance:
				damage = balance.risky_damage
		RuleEvaluator.Outcome.WRONG:
			trust_change = balance.wrong_trust
			if rng.randf() < balance.wrong_hurt_chance:
				damage = balance.wrong_damage
	if not answered_by_player:
		trust_change += balance.no_answer_trust


func is_hurt() -> bool:
	return damage > 0
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `193 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Consecuencia de una acción" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: El estado de cada amigo

**Archivos:**

- Crear: `scripts/core/friend_state.gd`, `test/test_friend_state.gd`

`FriendState` guarda la vida, el aturdimiento y la señal de un amigo. Herido, queda aturdido y no está disponible; con 0 PV, muere.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_friend_state.gd`:

```gdscript
extends "res://test/test_case.gd"

const FriendState := preload("res://scripts/core/friend_state.gd")


func test_empieza_sano_y_disponible() -> bool:
	var friend := FriendState.new(3)
	check_eq(friend.health, 3, "vida")
	check_eq(friend.max_health, 3, "vida máxima")
	check_eq(friend.signal_level, 100.0, "señal llena")
	check(friend.is_alive() and not friend.is_stunned() and friend.is_available(), "vivo, despierto y disponible")
	return true


func test_herido_queda_aturdido() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(1, 15.0)
	check_eq(friend.health, 2, "pierde 1 PV")
	check(friend.is_stunned() and not friend.is_available(), "aturdido: no está disponible")
	friend.advance(14.9)
	check(friend.is_stunned(), "a los 14,9 s sigue aturdido")
	friend.advance(0.2)
	check(not friend.is_stunned() and friend.is_available(), "a los 15 s vuelve")
	return true


func test_con_0_pv_muere() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(2, 15.0)
	friend.hurt(2, 15.0)
	check_eq(friend.health, 0, "la vida no baja de 0")
	check(not friend.is_alive() and not friend.is_available(), "muerto")
	check(not friend.is_stunned(), "un amigo muerto no queda aturdido")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `193 pruebas OK, 1 fallidas`. La falla es `test_friend_state.gd :: no se pudo cargar`.

- [ ] **Paso 3: Crear `FriendState`**

`scripts/core/friend_state.gd`:

```gdscript
extends RefCounted
## Cómo está un amigo durante la noche (diseño §9 y §10.1): su vida, si está aturdido y su señal.
## Lógica pura: NightState tiene uno por amigo.

var health := 0
var max_health := 0
## Segundos de aturdimiento que quedan. Mientras dure, el amigo no pide ayuda ni envía videos.
var stun_left := 0.0
## Señal (0–100): decide la estática de sus mensajes. En el Plan 6 baja durante la noche.
var signal_level := 100.0


func _init(start_health: int) -> void:
	health = start_health
	max_health = start_health


func is_alive() -> bool:
	return health > 0


func is_stunned() -> bool:
	return stun_left > 0.0


## Puede recibir solicitudes y enviar videos: está vivo y no está aturdido.
func is_available() -> bool:
	return is_alive() and not is_stunned()


## Pierde `damage` de vida. Si sobrevive, queda aturdido `stun_seconds`.
func hurt(damage: int, stun_seconds: float) -> void:
	health = maxi(health - damage, 0)
	stun_left = stun_seconds if is_alive() else 0.0


func advance(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `196 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Estado de cada amigo durante la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Los envíos de videos

**Archivos:**

- Crear: `scripts/core/video_schedule.gd`, `test/test_video_schedule.gd`

`VideoSchedule` programa los envíos de la noche (tantos como la cuota) y recibe los que ya tocan. Si el amigo no puede enviar, su video espera (decisión de Benja). Por ahora los videos cuentan apenas llegan.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_video_schedule.gd`:

```gdscript
extends "res://test/test_case.gd"

const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


func _schedule(quota: int) -> VideoSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return VideoSchedule.new(quota, 420.0, 3, rng)


func _anyone(_friend_index: int) -> bool:
	return true


func _nobody(_friend_index: int) -> bool:
	return false


func test_los_envios_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.quota, 3, "cuota")
	check_eq(schedule.pending.map(func(delivery: VideoSchedule.Delivery) -> float: return delivery.time),
			[105.0, 210.0, 315.0], "a las 01:30, 03:00 y 04:30")
	for delivery: VideoSchedule.Delivery in schedule.pending:
		check(delivery.friend_index >= 0 and delivery.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_llegan_a_su_hora() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.receive_due(104.0, _anyone), [], "antes de tiempo, nada")
	var first: int = schedule.pending[0].friend_index
	check_eq(schedule.receive_due(105.0, _anyone), [first], "a los 105 s, el primero")
	check_eq(schedule.received, 1, "1 recibido")
	check(not schedule.is_quota_met(), "falta cuota")
	schedule.receive_due(400.0, _anyone)
	check_eq(schedule.received, 3, "todos")
	check(schedule.is_quota_met(), "cuota cumplida")
	return true


func test_si_el_amigo_no_puede_enviar_se_atrasa() -> bool:
	var schedule := _schedule(1)
	check_eq(schedule.receive_due(300.0, _nobody), [], "aturdido: todavía no")
	check_eq(schedule.pending.size(), 1, "sigue pendiente")
	check_eq(schedule.receive_due(301.0, _anyone).size(), 1, "llega cuando puede")
	return true


func test_el_video_extra_llega_apenas_puede() -> bool:
	var schedule := _schedule(2)
	schedule.add_extra(1, 50.0)
	check_eq(schedule.receive_due(50.0, _anyone), [1], "el extra de Gonzalo")
	check_eq(schedule.received, 1, "cuenta para la cuota")
	return true


func test_sin_cuota_ya_esta_cumplida() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "sin envíos")
	check(schedule.is_quota_met(), "cumplida")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `196 pruebas OK, 1 fallidas`. La falla es `test_video_schedule.gd :: no se pudo cargar`.

- [ ] **Paso 3: Crear `VideoSchedule`**

`scripts/core/video_schedule.gd`:

```gdscript
extends RefCounted
## Los videos de la noche (diseño §10.4): los envíos programados, que son justo los que pide la cuota,
## y los videos extra de la acción de mayor riesgo. Si al amigo le toca enviar y no puede (está
## aturdido), su video llega cuando se recupera (decisión de Benja).
## Por ahora los videos se reciben solos al llegar: aceptarlos y descargarlos llega en el Plan 6.


## Un video que un amigo va a enviar.
class Delivery:
	var friend_index: int
	## Segundos desde las 00:00.
	var time: float

	func _init(delivery_friend: int, delivery_time: float) -> void:
		friend_index = delivery_friend
		time = delivery_time


## Videos que hay que recibir para ganar la noche.
var quota := 0
var received := 0
## Los envíos que todavía no llegan.
var pending: Array[Delivery] = []


## Programa `night_quota` envíos repartidos parejo en la noche, cada uno de un amigo al azar.
func _init(night_quota: int, night_seconds: float, friend_count: int, rng: RandomNumberGenerator) -> void:
	quota = night_quota
	for index in night_quota:
		var time := night_seconds * (index + 1) / (night_quota + 1)
		pending.append(Delivery.new(rng.randi_range(0, friend_count - 1), time))


## La acción de mayor riesgo y el amigo sobrevivió: envía un video extra apenas pueda.
func add_extra(friend_index: int, now: float) -> void:
	pending.append(Delivery.new(friend_index, now))


## Recibe los envíos que ya tocan y cuyo amigo puede enviar (`can_send` recibe el índice del amigo).
## Devuelve de qué amigo es cada video que llegó.
func receive_due(now: float, can_send: Callable) -> Array[int]:
	var arrived: Array[int] = []
	for delivery: Delivery in pending.duplicate():
		if delivery.time <= now and can_send.call(delivery.friend_index):
			pending.erase(delivery)
			arrived.append(delivery.friend_index)
	received += arrived.size()
	return arrived


func is_quota_met() -> bool:
	return received >= quota
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `201 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Envíos de videos y cuota" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: El estado de la noche

**Archivos:**

- Crear: `scripts/core/night_state.gd`, `test/test_night_state.gd`

`NightState` junta todo lo que cambia durante la noche: la hora, Sanity, Trust, un `FriendState` por amigo y los videos. Aplica las consecuencias y dice cómo termina la noche.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_night_state.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


## Estado de la noche 1 del catálogo de prueba: 3 amigos, cuota de 2 videos (a los 140 s y a los 280 s)
## y Sanity que baja 1 punto cada 6 s.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return NightState.new(catalog.nights[0], catalog.balance, catalog.friends.size(), rng)


## Una consecuencia con valores fijos, sin tirar dados.
func _consequence(damage: int, trust_change: float, risky := false) -> Consequence:
	var consequence := Consequence.new(RuleEvaluator.Outcome.CORRECT, true, BalanceData.new(), RandomNumberGenerator.new())
	consequence.damage = damage
	consequence.trust_change = trust_change
	consequence.risky = risky
	return consequence


## Avanza `seconds` de a 1 segundo, como lo haría el juego.
func _advance(state: NightState, seconds: int) -> void:
	for _i in seconds:
		state.advance(1.0)


func test_empieza_a_las_00_con_todo_lleno() -> bool:
	var state := _make_state()
	check_eq(state.clock_text(), "00:00", "hora")
	check_eq(state.sanity, 100.0, "Sanity")
	check_eq(state.trust, 100.0, "Trust")
	check_eq(state.connection(), 100.0, "Connection")
	check_eq(state.friends.size(), 3, "3 amigos")
	check_eq(state.friends[0].health, 3, "3 PV")
	check_eq(state.videos.quota, 2, "cuota de la noche")
	check_eq(state.ending(), NightState.Ending.NONE, "la noche sigue")
	return true


func test_el_reloj_va_de_00_a_06() -> bool:
	var state := _make_state()
	state.advance(210.0)
	check_eq(state.clock_text(), "03:00", "a la mitad")
	state.advance(1.2)
	check_eq(state.clock_text(), "03:01", "un minuto de juego son 1,17 s")
	state.advance(500.0)
	check_eq(state.clock_text(), "06:00", "no pasa de las 06:00")
	check_eq(state.elapsed, 420.0, "segundos")
	return true


func test_sanity_baja_con_el_tiempo() -> bool:
	var state := _make_state()
	state.advance(60.0)
	check(is_equal_approx(state.sanity, 90.0), "−1 cada 6 s: %s" % state.sanity)
	return true


func test_trust_baja_y_se_recupera_sin_errores() -> bool:
	var state := _make_state()
	state.apply(0, _consequence(0, -10.0))
	check_eq(state.trust, 90.0, "−10")
	_advance(state, 20)
	check(is_equal_approx(state.trust, 90.0), "durante 20 s no se recupera: %s" % state.trust)
	_advance(state, 8)
	check(is_equal_approx(state.trust, 91.0), "después, +1 cada 8 s: %s" % state.trust)
	state.apply(0, _consequence(0, -10.0))
	_advance(state, 19)
	check(is_equal_approx(state.trust, 81.0), "un error nuevo reinicia la espera: %s" % state.trust)
	_advance(state, 200)
	check_eq(state.trust, 100.0, "no pasa de 100")
	return true


func test_trust_no_baja_de_0() -> bool:
	var state := _make_state()
	state.trust = 15.0
	state.apply(0, _consequence(0, -20.0))
	check_eq(state.trust, 0.0, "Trust en 0")
	return true


func test_herido_queda_aturdido_y_no_esta_disponible() -> bool:
	var state := _make_state()
	state.apply(1, _consequence(1, -10.0))
	check_eq(state.friends[1].health, 2, "Gonzalo pierde 1 PV")
	check(not state.is_available(1), "aturdido")
	check(state.is_available(0), "León sigue disponible")
	_advance(state, 15)
	check(state.is_available(1), "a los 15 s vuelve")
	return true


func test_los_videos_programados_llegan() -> bool:
	var state := _make_state()
	var arrived: Array[int] = []
	for _i in 140:
		arrived.append_array(state.advance(1.0))
	check_eq(arrived.size(), 1, "el primero a los 140 s")
	check_eq(state.videos.received, 1, "recibido")
	return true


func test_la_accion_de_mayor_riesgo_da_un_video_extra() -> bool:
	var state := _make_state()
	state.apply(2, _consequence(0, -20.0, true))
	check_eq(state.advance(0.1), [2], "llega el video de Agustín")
	return true


func test_herido_envia_el_video_extra_al_recuperarse() -> bool:
	var state := _make_state()
	state.apply(2, _consequence(2, -20.0, true))
	_advance(state, 14)
	check_eq(state.videos.received, 0, "aturdido: todavía no")
	_advance(state, 1)
	check_eq(state.videos.received, 1, "al recuperarse")
	return true


func test_si_muere_se_pierde_la_noche_y_no_hay_video() -> bool:
	var state := _make_state()
	state.friends[0].health = 2
	state.apply(0, _consequence(2, -20.0, true))
	check_eq(state.ending(), NightState.Ending.FRIEND_DIED, "murió León")
	check(state.videos.pending.size() == 2, "sin video extra")
	return true


func test_cada_dial_en_0_pierde_la_noche() -> bool:
	var state := _make_state()
	state.sanity = 0.0
	check_eq(state.ending(), NightState.Ending.SANITY, "Sanity")
	state = _make_state()
	state.trust = 0.0
	check_eq(state.ending(), NightState.Ending.TRUST, "Trust")
	state = _make_state()
	state.friends[0].signal_level = 0.0
	check_eq(state.ending(), NightState.Ending.NONE, "con una señal en 0 no se pierde")
	for friend in state.friends:
		friend.signal_level = 0.0
	check_eq(state.ending(), NightState.Ending.CONNECTION, "con las 3 en 0, sí")
	return true


func test_a_las_06_gana_si_cumplio_la_cuota() -> bool:
	var state := _make_state()
	_advance(state, 420)
	check_eq(state.videos.received, 2, "llegaron los 2 envíos")
	check_eq(state.ending(), NightState.Ending.WON, "ganó")
	state = _make_state()
	state.videos.pending.clear()
	_advance(state, 420)
	check_eq(state.ending(), NightState.Ending.QUOTA, "sin videos, pierde por la cuota")
	return true


func test_la_muerte_se_explica_antes_que_lo_demas() -> bool:
	var state := _make_state()
	state.sanity = 0.0
	state.friends[1].health = 0
	check_eq(state.ending(), NightState.Ending.FRIEND_DIED, "primero la muerte")
	return true


func test_la_vineta_aparece_bajo_60() -> bool:
	var state := _make_state()
	var expected := {100.0: 0.0, 60.0: 0.0, 30.0: 0.5, 0.0: 1.0}
	for sanity: float in expected:
		state.sanity = sanity
		check(is_equal_approx(state.vignette_strength(), expected[sanity]), "Sanity %s" % sanity)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `201 pruebas OK, 1 fallidas`. La falla es `test_night_state.gd :: no se pudo cargar`.

- [ ] **Paso 3: Crear `NightState`**

`scripts/core/night_state.gd`:

```gdscript
extends RefCounted
## El estado de una noche en curso (diseño §5, §9 y §10): la hora, Sanity, Trust, cómo está cada amigo
## y los videos. Lógica pura: RequestManager lo crea, NightManager lo avanza y el escritorio lo muestra.

const Consequence := preload("res://scripts/core/consequence.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")

## Cómo termina la noche. NONE: todavía no termina.
enum Ending { NONE, WON, FRIEND_DIED, SANITY, TRUST, CONNECTION, QUOTA }

## La noche va de las 00:00 a las 06:00.
const NIGHT_HOURS := 6
## Sanity, Trust y la señal van de 0 a 100.
const METER_MAX := 100.0

var night: NightData
var balance: BalanceData
## Segundos desde las 00:00.
var elapsed := 0.0
var sanity := METER_MAX
var trust := METER_MAX
var friends: Array[FriendState] = []
var videos: VideoSchedule

## Segundos desde la última vez que bajó Trust.
var _since_trust_loss := 0.0


func _init(night_data: NightData, balance_data: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	night = night_data
	balance = balance_data
	for _index in friend_count:
		friends.append(FriendState.new(balance.friend_health))
	videos = VideoSchedule.new(night.content_quota, balance.night_seconds, friend_count, rng)


## Avanza `delta` segundos: la hora, Sanity, Trust, el aturdimiento y los videos.
## Devuelve de qué amigo es cada video que llegó en este paso.
func advance(delta: float) -> Array[int]:
	elapsed = minf(elapsed + delta, balance.night_seconds)
	sanity = maxf(sanity - delta / night.sanity_drain_interval, 0.0)
	_since_trust_loss += delta
	# Solo cuenta la parte del paso que cae después de la espera sin errores.
	var calm := clampf(_since_trust_loss - balance.trust_recovery_delay, 0.0, delta)
	trust = minf(trust + calm / balance.trust_recovery_interval, METER_MAX)
	for friend: FriendState in friends:
		friend.advance(delta)
	return videos.receive_due(elapsed, is_available)


## Aplica la consecuencia de una solicitud del amigo `friend_index`: la vida, el aturdimiento, Trust y,
## si fue la acción de mayor riesgo y el amigo sobrevivió, el video extra.
func apply(friend_index: int, consequence: Consequence) -> void:
	var friend := friends[friend_index]
	if consequence.is_hurt():
		friend.hurt(consequence.damage, balance.stun_seconds)
	if consequence.trust_change < 0.0:
		_since_trust_loss = 0.0
	trust = clampf(trust + consequence.trust_change, 0.0, METER_MAX)
	if consequence.risky and friend.is_alive():
		videos.add_extra(friend_index, elapsed)


## Puede recibir solicitudes y enviar videos.
func is_available(friend_index: int) -> bool:
	return friends[friend_index].is_available()


## El dial de Connection: el promedio de las señales de los amigos (diseño §10.1).
func connection() -> float:
	var total := 0.0
	for friend: FriendState in friends:
		total += friend.signal_level
	return total / friends.size()


## La hora del celular, de "00:00" a "06:00".
func clock_text() -> String:
	var minutes := int(elapsed / balance.night_seconds * NIGHT_HOURS * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


## Cuánto se oscurece la vista, de 0 a 1: nada desde vignette_start de Sanity hacia arriba, y todo en 0.
func vignette_strength() -> float:
	return clampf((balance.vignette_start - sanity) / balance.vignette_start, 0.0, 1.0)


## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0.
## A las 06:00 se gana si se cumplió la cuota (diseño §5).
func ending() -> Ending:
	for friend: FriendState in friends:
		if not friend.is_alive():
			return Ending.FRIEND_DIED
	if sanity <= 0.0:
		return Ending.SANITY
	if trust <= 0.0:
		return Ending.TRUST
	if connection() <= 0.0:
		return Ending.CONNECTION
	if elapsed >= balance.night_seconds:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
	return Ending.NONE
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `215 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ test/
git commit -m "Estado de la noche: hora, Sanity, Trust y final" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Las solicitudes aplican sus consecuencias

**Archivos:**

- Modificar: `scripts/core/friend_request.gd`, `scripts/core/message_builder.gd`, `scripts/desk/request_manager.gd`, `data/text/messages.csv`, `test/capture_chat.gd`, `test/test_message_builder.gd`, `test/test_request_manager.gd`

`RequestManager` crea el estado de la noche y, al terminar cada solicitud, tira la consecuencia y la aplica. La reacción del amigo depende de si quedó herido. Un amigo aturdido o muerto no recibe solicitudes, y con Trust bajo hay menos tiempo para responder.

- [ ] **Paso 1: Escribir las pruebas**

Son 3 cambios en `test/test_message_builder.gd` y 5 en `test/test_request_manager.gd`.

En `test/test_message_builder.gd`, reemplazar:

```gdscript
const ChatMessage := preload("res://scripts/core/chat_message.gd")
```

por:

```gdscript
const ChatMessage := preload("res://scripts/core/chat_message.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
```

En `test/test_message_builder.gd`, reemplazar:

```gdscript
func test_sus_textos_existen() -> bool:
```

por:

```gdscript
func test_si_quedo_herido_la_reaccion_cambia() -> bool:
	# o1 = yes: a2 es la de mayor riesgo y a3, incorrecta. Con probabilidad 1, siempre hieren.
	var balance := BalanceData.new()
	balance.risky_hurt_chance = 1.0
	balance.wrong_hurt_chance = 1.0
	var expected := {&"a2": "REACTION_RISKY_HURT.", &"a3": "REACTION_WRONG_HURT."}
	for action_id: StringName in expected:
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		request.consequence = Consequence.new(request.outcome, true, balance, RandomNumberGenerator.new())
		check_eq(MessageBuilder.reaction(request, _translate).plain_text(), expected[action_id], "reacción a %s" % action_id)
	return true


func test_sus_textos_existen() -> bool:
```

En `test/test_message_builder.gd`, reemplazar:

```gdscript
			+ MessageBuilder.REACTION_KEYS.values()
```

por:

```gdscript
			+ MessageBuilder.REACTION_KEYS.values() + MessageBuilder.HURT_REACTION_KEYS.values()
```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
const FriendRequest := preload("res://scripts/core/friend_request.gd")
```

por:

```gdscript
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
	check_eq(manager.signal_levels, [100.0, 100.0, 100.0], "señal llena")
```

por:

```gdscript
	check_eq(manager.state.friends.map(func(friend: FriendState) -> float: return friend.signal_level),
			[100.0, 100.0, 100.0], "señal llena")
	check_eq(manager.state.trust, 100.0, "Trust lleno")
```

Sin respuesta, ahora llegan dos mensajes: qué hizo el amigo y cómo le fue. En `test/test_request_manager.gd`, reemplazar:

```gdscript
	check_eq(events.size(), 2, "mensaje y fin")
	if events.size() == 2:
		check_eq(events[0][0], "message_added", "cuenta lo que hizo")
		check_eq(events[1], ["request_finished", 2, request], "terminó")
```

por:

```gdscript
	check_eq(events.size(), 3, "lo que hizo, cómo le fue y fin")
	if events.size() == 3:
		check_eq(events[0][0], "message_added", "cuenta lo que hizo")
		check_eq(events[1][0], "message_added", "cuenta cómo le fue")
		check_eq(events[2], ["request_finished", 2, request], "terminó")
```

La prueba de la estática repite solicitudes sin respuesta: sin heridas, para que ningún amigo quede aturdido. En `test/test_request_manager.gd`, reemplazar:

```gdscript
	manager.signal_levels[0] = 100.0
	manager.signal_levels[1] = 1.0
```

por:

```gdscript
	manager.state.friends[0].signal_level = 100.0
	manager.state.friends[1].signal_level = 1.0
	# Sin heridas: un amigo aturdido o muerto no recibiría más solicitudes.
	manager.catalog.balance.risky_hurt_chance = 0.0
	manager.catalog.balance.wrong_hurt_chance = 0.0
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
## Una acción incorrecta para la situación de `request`: ni la correcta ni la de mayor riesgo.
func _wrong_action(request: FriendRequest) -> ActionData:
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	for action: ActionData in request.entity.actions:
		if action.id != rule.correct_action_id and action.id != rule.risky_action_id:
			return action
	return null


func test_responder_aplica_la_consecuencia() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var request := manager.start_request(0)
	var events := []
	_record(manager, events)
	manager.answer(0, _wrong_action(request))
	check(request.consequence != null and request.consequence.is_hurt(), "quedó herido")
	check_eq(manager.state.friends[0].health, 2, "León pierde 1 PV")
	check(not manager.state.is_available(0), "y queda aturdido")
	check_eq(manager.state.trust, 90.0, "Trust −10")
	var messages := _messages(events)
	if messages.size() == 2:
		check_eq((messages[1] as ChatMessage).plain_text(), String(TranslationServer.translate("REACTION_WRONG_HURT")),
				"cuenta que quedó herido")
	manager.free()
	return true


func test_un_amigo_aturdido_o_muerto_no_recibe_solicitudes() -> bool:
	var manager := _make_manager()
	manager.state.friends[0].hurt(1, 15.0)
	check_eq(manager.start_request(0), null, "León está aturdido")
	manager.state.friends[1].hurt(3, 15.0)
	check_eq(manager.start_request(1), null, "Gonzalo está muerto")
	manager.requests_arrive = true
	manager.advance(5.1)
	check(manager.requests[2] != null, "la solicitud le llega a Agustín")
	manager.free()
	return true


func test_con_trust_bajo_hay_menos_tiempo() -> bool:
	var manager := _make_manager()
	manager.state.trust = 50.0
	var request := manager.start_request(0)
	check(is_equal_approx(request.time_left, 36.0), "45 s × (0,6 + 0,4 × 0,5): %s" % request.time_left)
	manager.free()
	return true


func test_sin_respuesta_trust_baja_ademas() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	manager.advance(request.time_left + 0.1)
	check(request.consequence != null, "se resolvió igual")
	if request.consequence != null:
		check(request.consequence.trust_change <= -15.0, "−15 por no contestar, además de lo que eligió")
		check_eq(manager.state.trust, 100.0 + request.consequence.trust_change, "se aplicó")
	manager.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `204 pruebas OK, 8 fallidas`:

- `test_message_builder.gd :: no se pudo cargar`, porque `FriendRequest` todavía no tiene `consequence`;
- 7 pruebas de `test_request_manager.gd`, porque `RequestManager` todavía no tiene `state`: `test_empieza_sin_solicitudes`, `test_sin_respuesta_el_amigo_decide_solo`, `test_la_estatica_depende_de_la_senal`, `test_responder_aplica_la_consecuencia`, `test_un_amigo_aturdido_o_muerto_no_recibe_solicitudes`, `test_con_trust_bajo_hay_menos_tiempo` y `test_sin_respuesta_trust_baja_ademas`.

- [ ] **Paso 3: La consecuencia en la solicitud y la reacción**

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

por:

```gdscript
const Consequence := preload("res://scripts/core/consequence.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
var outcome := RuleEvaluator.Outcome.WRONG
```

por:

```gdscript
var outcome := RuleEvaluator.Outcome.WRONG
## Lo que le pasó al amigo (Plan 5). Es null hasta que RequestManager la resuelve, al terminar.
var consequence: Consequence
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
## Lo que cuenta el amigo después de hacer lo que dijo Matías, según el resultado (messages.csv).
## Es provisional: en el Plan 5 la reacción también depende de si el amigo quedó herido.
const REACTION_KEYS := {
	RuleEvaluator.Outcome.CORRECT: "REACTION_CORRECT",
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG",
}
```

por:

```gdscript
## Lo que cuenta el amigo después de la acción, según el resultado, si no quedó herido (messages.csv).
const REACTION_KEYS := {
	RuleEvaluator.Outcome.CORRECT: "REACTION_CORRECT",
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG",
}
## Lo que cuenta si quedó herido. La acción correcta nunca hiere (messages.csv).
const HURT_REACTION_KEYS := {
	RuleEvaluator.Outcome.RISKY: "REACTION_RISKY_HURT",
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG_HURT",
}
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
## Lo que cuenta el amigo después de hacer lo que dijo Matías. La solicitud ya debe estar terminada.
static func reaction(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_fragment(_text(translate, REACTION_KEYS[request.outcome]))
	return message
```

por:

```gdscript
## Lo que cuenta el amigo después de la acción, la haya elegido Matías o él solo: según el resultado
## y si quedó herido. La solicitud ya debe estar terminada.
static func reaction(request: FriendRequest, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	var hurt := request.consequence != null and request.consequence.is_hurt()
	var key: String = HURT_REACTION_KEYS[request.outcome] if hurt else REACTION_KEYS[request.outcome]
	message.add_fragment(_text(translate, key))
	return message
```

- [ ] **Paso 4: Las reacciones de un amigo herido**

Las 3 reacciones de `data/text/messages.csv` ya sirven para cuando el amigo no queda herido, también cuando decidió solo. Se agregan las 2 de cuando queda herido: son borradores en primera persona que Benja corrige.

Agregar al final de `data/text/messages.csv`:

```csv
REACTION_RISKY_HURT,"¡ME ATACÓ! Pero lo grabé todo. Concéntrate, Mati.",
REACTION_WRONG_HURT,"¡ME ATACÓ! CONCÉNTRATE, MATI.",
```

- [ ] **Paso 5: `RequestManager` con el estado de la noche**

`scripts/desk/request_manager.gd` (archivo completo):

```gdscript
extends Node
## Las solicitudes de la noche (planes 3 a 5): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## El ritmo es provisional, hasta el director del Plan 7: llega una solicitud cada
## (duración de la noche ÷ solicitudes de la noche) segundos, sin pasar de las simultáneas.
## En el escritorio lo avanza NightManager, junto con el estado de la noche.

signal message_added(friend_index: int, message: ChatMessage)
signal request_started(friend_index: int, request: FriendRequest)
## Cambió algo que se ve: una frase marcada o en rojo, Matías pensando, el nombre o el tiempo tras preguntar.
signal request_changed(friend_index: int, request: FriendRequest)
## Terminó una solicitud, con su consecuencia ya aplicada al estado de la noche.
signal request_finished(friend_index: int, request: FriendRequest)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatStatic := preload("res://scripts/core/chat_static.gd")
const Consequence := preload("res://scripts/core/consequence.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

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
## El estado de la noche: la hora, Sanity, Trust, cómo está cada amigo y los videos. Lo crea el manager,
## que tiene el catálogo y la noche; NightManager lo avanza.
var state: NightState

var _since_last_request := 0.0
var _started_count := 0


func _ready() -> void:
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
	for index in catalog.friends.size():
		requests.append(null)
		state.friends[index].signal_level = test_signal


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


## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una, si no está disponible
## (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto.
func start_request(friend_index: int) -> FriendRequest:
	if requests[friend_index] != null or not state.is_available(friend_index):
		return null
	var request := RequestGenerator.generate(catalog, night(), friend_index, rng, state.trust)
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
	var clue_state := request.click_clue(clue_id)
	request_changed.emit(request.friend_index, request)
	return clue_state


## Matías responde con `action`, desde la página abierta en el cuaderno, y la solicitud termina.
## Una acción de la página de otra entidad es incorrecta (docs/02 §5.2).
## Devuelve false si el amigo no espera respuesta.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null:
		return false
	request.finish(action, true)
	_resolve(request)
	requests[friend_index] = null
	message_added.emit(friend_index, MessageBuilder.player_answer(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	request_finished.emit(friend_index, request)
	return true


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue.
func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng)
	_resolve(request)
	requests[friend_index] = null
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	request_finished.emit(friend_index, request)


## Tira la consecuencia y la aplica al estado de la noche. Va antes de la reacción del amigo, que
## depende de si quedó herido.
func _resolve(request: FriendRequest) -> void:
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng)
	state.apply(request.friend_index, request.consequence)


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
	ChatStatic.apply(message, state.friends[friend_index].signal_level, rng)
	message_added.emit(friend_index, message)


func _maybe_start_request(delta: float) -> void:
	_since_last_request += delta
	var current := night()
	var wait := FIRST_REQUEST_DELAY if _started_count == 0 else catalog.balance.night_seconds / current.requests_total
	if _since_last_request < wait or _started_count >= current.requests_total:
		return
	if active_count() >= current.max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if requests[index] == null and state.is_available(index):
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_request(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		_since_last_request = 0.0
```

La captura del chat (Plan 3) bajaba la señal en `signal_levels`, que ya no existe. En `test/capture_chat.gd`, reemplazar:

```gdscript
	manager.signal_levels[0] = 40.0
```

por:

```gdscript
	manager.state.friends[0].signal_level = 40.0
```

- [ ] **Paso 6: Importar y verificar que pasan**

Esperado: `220 pruebas OK, 0 fallidas`.

- [ ] **Paso 7: Commit**

```bash
git add scripts/ data/text/ test/
git commit -m "Las solicitudes aplican sus consecuencias" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: El aviso de daño en el chat

**Archivos:**

- Modificar: `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/desk/request_manager.gd`, `scripts/ui/chat_message_view.gd`, `scripts/ui/chat_panel.gd`, `scenes/ui/chat_theme.tres`, `data/text/ui.csv`, `test/test_message_builder.gd`, `test/test_request_manager.gd`, `test/test_chat_message_view.gd`, `test/test_chat_panel.gd`

Cuando un amigo queda herido, el juego lo avisa en el chat, debajo de la reacción del amigo: "León recibió daño: 2/3", con la vida que le queda (decisión de Benja). Es un mensaje del juego (`ChatMessage.Sender.SYSTEM`), no del amigo: va centrado y en rojo, sin nombre ni burbuja, aparece de una vez y no pasa por la estática.

- [ ] **Paso 1: Escribir las pruebas**

Son 3 cambios en `test/test_message_builder.gd`, 3 en `test/test_request_manager.gd`, 1 en `test/test_chat_message_view.gd` y 2 en `test/test_chat_panel.gd`.

La traducción falsa de las pruebas del armado de mensajes conoce el formato del aviso. En `test/test_message_builder.gd`, reemplazar:

```gdscript
	if key == MessageBuilder.DECIDED_ALONE_KEY:
		return "Decidí solo: {action}"
	return key + "."
```

por:

```gdscript
	if key == MessageBuilder.DECIDED_ALONE_KEY:
		return "Decidí solo: {action}"
	if key == MessageBuilder.DAMAGE_KEY:
		return "{friend} recibió daño: {health}/{max}"
	return key + "."
```

En `test/test_message_builder.gd`, reemplazar:

```gdscript
func test_sus_textos_existen() -> bool:
```

por:

```gdscript
func test_el_aviso_de_dano() -> bool:
	var request := _make_request()
	var message := MessageBuilder.damage_notice(request, "León", 2, 3, _translate)
	check_eq(message.sender, ChatMessage.Sender.SYSTEM, "lo escribe el juego, no el amigo")
	check_eq(message.request, request, "es de la solicitud")
	check_eq(message.plain_text(), "León recibió daño: 2/3", "con la vida que le queda")
	return true


func test_sus_textos_existen() -> bool:
```

En `test/test_message_builder.gd`, reemplazar:

```gdscript
	keys.append(MessageBuilder.DECIDED_ALONE_KEY)
```

por:

```gdscript
	keys.append(MessageBuilder.DECIDED_ALONE_KEY)
	keys.append(MessageBuilder.DAMAGE_KEY)
	for placeholder: String in ["{friend}", "{health}", "{max}"]:
		check(String(TranslationServer.translate(MessageBuilder.DAMAGE_KEY)).contains(placeholder),
				"CHAT_DAMAGE debe tener %s" % placeholder)
```

Después de una respuesta que hiere, llegan 3 mensajes: la respuesta, la reacción y el aviso. En `test/test_request_manager.gd`, reemplazar:

```gdscript
	var messages := _messages(events)
	if messages.size() == 2:
		check_eq((messages[1] as ChatMessage).plain_text(), String(TranslationServer.translate("REACTION_WRONG_HURT")),
				"cuenta que quedó herido")
```

por:

```gdscript
	var messages := _messages(events)
	check_eq(messages.size(), 3, "la respuesta, la reacción y el aviso de daño")
	if messages.size() == 3:
		check_eq((messages[1] as ChatMessage).plain_text(), String(TranslationServer.translate("REACTION_WRONG_HURT")),
				"cuenta que quedó herido")
		var notice := messages[2] as ChatMessage
		var friend: FriendData = manager.catalog.friends[0]
		check_eq(notice.sender, ChatMessage.Sender.SYSTEM, "el aviso lo escribe el juego")
		check_eq(notice.plain_text(), String(TranslationServer.translate("CHAT_DAMAGE")).format(
				{"friend": String(TranslationServer.translate(friend.name_key)), "health": 2, "max": 3}),
				"con la vida que le queda")
```

La prueba de la decisión del amigo cuenta los mensajes: sin heridas, para que no llegue además el aviso. En `test/test_request_manager.gd`, reemplazar:

```gdscript
func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
```

por:

```gdscript
func test_sin_respuesta_el_amigo_decide_solo() -> bool:
	var manager := _make_manager()
	# Sin heridas: si quedara herido, llegaría además el aviso de daño.
	manager.catalog.balance.risky_hurt_chance = 0.0
	manager.catalog.balance.wrong_hurt_chance = 0.0
	var request := manager.start_request(2)
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
func test_si_decide_solo_y_queda_herido_tambien_hay_aviso() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.risky_hurt_chance = 1.0
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var request := manager.start_request(2)
	var events := []
	_record(manager, events)
	manager.advance(request.time_left + 0.1)
	var messages := _messages(events)
	var hurt := request.consequence.is_hurt()
	check_eq(messages.size(), 3 if hurt else 2, "lo que hizo, cómo le fue y, si quedó herido, el aviso")
	if not messages.is_empty():
		check_eq((messages[-1] as ChatMessage).sender == ChatMessage.Sender.SYSTEM, hurt, "el aviso, solo si quedó herido")
	manager.free()
	return true
```

Agregar al final de `test/test_chat_message_view.gd`:

```gdscript
func test_el_aviso_de_dano_va_centrado_y_en_rojo() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, _make_request())
	message.add_fragment("León recibió daño: 2/3")
	var view := _make_view(message)
	var label := _label(view)
	check_eq(label.get_parsed_text(), "── León recibió daño: 2/3 ──", "entre líneas y sin nombre")
	check(label.text.begins_with("[center]"), "centrado")
	check(label.text.contains(ChatMessageView.DANGER_COLOR), "en rojo")
	check_eq(label.visible_ratio, 1.0, "aparece de una vez")
	check_eq((view.get_node("Bubble") as PanelContainer).theme_type_variation, &"SystemNotice", "sin burbuja")
	check_eq(view.get_theme_constant(&"margin_left"), 0, "de borde a borde, a la izquierda")
	check_eq(view.get_theme_constant(&"margin_right"), 0, "y a la derecha")
	view.free()
	return true
```

La prueba que responde desde la página elige la tercera acción, que según la situación puede herir al amigo: se deja sin heridas, para que siempre lleguen 3 mensajes. En `test/test_chat_panel.gd`, reemplazar:

```gdscript
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (buttons[0] as Button).disabled, "con solicitud se responde")
```

por:

```gdscript
	# Sin heridas: si quedara herido, llegaría además el aviso de daño.
	_manager.catalog.balance.risky_hurt_chance = 0.0
	_manager.catalog.balance.wrong_hurt_chance = 0.0
	var request := _manager.start_request(0)
	panel._process(0.0)
	check(not (buttons[0] as Button).disabled, "con solicitud se responde")
```

Agregar al final de `test/test_chat_panel.gd`:

```gdscript
func test_el_aviso_de_dano_no_lleva_nombre_y_marca_la_pestana() -> bool:
	var panel := _make_panel()
	var request := _manager.start_request(0)
	panel.open_for(0)
	panel.open_for(1)
	var notice := ChatMessage.new(ChatMessage.Sender.SYSTEM, request)
	notice.add_fragment("León recibió daño: 2/3")
	_manager.message_added.emit(0, notice)
	var views: Array[Node] = panel.message_views(0)
	check_eq(views[-1].speaker, "", "lo escribe el juego: sin nombre")
	panel._process(0.0)
	check((panel.get_node("Panel/Tabs").get_child(0) as Button).text.contains(panel.UNREAD_MARK), "la pestaña de León avisa")
	_free(panel)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `173 pruebas OK, 4 fallidas`. Son `test_chat_message_view.gd`, `test_chat_panel.gd`, `test_message_builder.gd` y `test_request_manager.gd :: no se pudo cargar`, porque `ChatMessage.Sender.SYSTEM` todavía no existe. Las otras pruebas de esos 4 archivos vuelven en el paso 5.

- [ ] **Paso 3: El aviso**

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript
enum Sender { FRIEND, PLAYER }
```

por:

```gdscript
## Quién escribe: un amigo, Matías o el juego (sus avisos, como el de daño).
enum Sender { FRIEND, PLAYER, SYSTEM }
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG_HURT",
}
```

por:

```gdscript
	RuleEvaluator.Outcome.WRONG: "REACTION_WRONG_HURT",
}
## El aviso del juego cuando un amigo queda herido (ui.csv). Lleva {friend}, {health} y {max}.
const DAMAGE_KEY := "CHAT_DAMAGE"
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

por:

```gdscript
## El aviso del juego, centrado y en rojo, cuando un amigo queda herido: "León recibió daño: 2/3"
## (decisión de Benja). `health` es la vida que le queda.
static func damage_notice(request: FriendRequest, friend_name: String, health: int, max_health: int,
		translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, request)
	message.add_fragment(_text(translate, DAMAGE_KEY).format({"friend": friend_name, "health": health, "max": max_health}))
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

El aviso va después de la reacción, tanto si respondió Matías como si el amigo decidió solo. En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	message_added.emit(friend_index, MessageBuilder.player_answer(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
```

por:

```gdscript
	message_added.emit(friend_index, MessageBuilder.player_answer(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	_add_damage_notice(friend_index, request)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
```

por:

```gdscript
	_add_friend_message(friend_index, MessageBuilder.decided_alone(request, tr))
	_add_friend_message(friend_index, MessageBuilder.reaction(request, tr))
	_add_damage_notice(friend_index, request)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
```

por:

```gdscript
## Si el amigo quedó herido, el juego lo avisa en el chat con la vida que le queda. El aviso no pasa
## por la estática.
func _add_damage_notice(friend_index: int, request: FriendRequest) -> void:
	if not request.consequence.is_hurt():
		return
	var friend := state.friends[friend_index]
	var friend_name := tr(catalog.friends[friend_index].name_key)
	message_added.emit(friend_index, MessageBuilder.damage_notice(request, friend_name, friend.health, friend.max_health, tr))


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
```

Agregar al final de `data/text/ui.csv`:

```csv
CHAT_DAMAGE,{friend} recibió daño: {health}/{max},
```

- [ ] **Paso 4: Cómo se ve el aviso**

Son 6 cambios en `scripts/ui/chat_message_view.gd`, 2 en `scripts/ui/chat_panel.gd` y 2 en `scenes/ui/chat_theme.tres`.

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
## y el señuelo vibra y queda rojo.
```

por:

```gdscript
## y el señuelo vibra y queda rojo. Los avisos del juego, como el de daño, van centrados y en rojo.
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
const STATIC_COLOR := "56637f"
```

por:

```gdscript
const STATIC_COLOR := "56637f"
## Los avisos del juego, como el de daño.
const DANGER_COLOR := "ff4d5e"
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
	var from_player := message.sender == ChatMessage.Sender.PLAYER
	add_theme_constant_override(&"margin_left" if from_player else &"margin_right", INDENT)
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	bubble.theme_type_variation = &"PlayerBubble" if from_player else &"FriendBubble"
```

por:

```gdscript
	var from_player := message.sender == ChatMessage.Sender.PLAYER
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	if message.sender == ChatMessage.Sender.SYSTEM:
		# Los avisos del juego van de borde a borde, sin burbuja.
		bubble.theme_type_variation = &"SystemNotice"
	else:
		add_theme_constant_override(&"margin_left" if from_player else &"margin_right", INDENT)
		bubble.theme_type_variation = &"PlayerBubble" if from_player else &"FriendBubble"
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
	refresh()
	_label.visible_ratio = 0.0
```

por:

```gdscript
	refresh()
	# Los avisos del juego aparecen de una vez; los mensajes se escriben de a poco.
	_label.visible_ratio = 1.0 if message.sender == ChatMessage.Sender.SYSTEM else 0.0
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
func _ready() -> void:
	if message.sender == ChatMessage.Sender.FRIEND and not speaker.is_empty():
```

por:

```gdscript
func _ready() -> void:
	if message.sender == ChatMessage.Sender.SYSTEM:
		return
	if message.sender == ChatMessage.Sender.FRIEND and not speaker.is_empty():
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
func refresh() -> void:
	var parts := PackedStringArray()
```

por:

```gdscript
func refresh() -> void:
	if message.sender == ChatMessage.Sender.SYSTEM:
		_label.text = "[center]%s[/center]" % _colored("── %s ──" % message.plain_text().replace("[", "[lb]"), DANGER_COLOR)
		return
	var parts := PackedStringArray()
```

El aviso no lleva nombre y marca la pestaña del amigo como mensaje nuevo. En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	# Quién escribe, en mayúsculas y con su color: el amigo o Matías.
```

por:

```gdscript
	# Quién escribe, en mayúsculas y con su color: el amigo o Matías. Los avisos del juego van sin nombre.
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	if message.sender == ChatMessage.Sender.FRIEND and not (visible and friend_index == selected_friend):
```

por:

```gdscript
	if message.sender != ChatMessage.Sender.PLAYER and not (visible and friend_index == selected_friend):
```

En `scenes/ui/chat_theme.tres`, reemplazar:

```ini
[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]
```

por:

```ini
[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_notice"]
content_margin_top = 4.0
content_margin_bottom = 4.0
```

En `scenes/ui/chat_theme.tres`, reemplazar:

```ini
PlayerBubble/styles/panel = SubResource("StyleBoxFlat_player")
```

por:

```ini
PlayerBubble/styles/panel = SubResource("StyleBoxFlat_player")
SystemNotice/base_type = &"PanelContainer"
SystemNotice/styles/panel = SubResource("StyleBoxEmpty_notice")
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `224 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/ scenes/ui/ data/text/ test/
git commit -m "Aviso de daño en el chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: El reloj de la noche

**Archivos:**

- Crear: `scripts/desk/night_manager.gd`, `test/test_night_manager.gd`

`NightManager` toma el control del tiempo: en cada frame avanza las solicitudes, después el estado de la noche, y revisa si la noche terminó. Al terminar, avisa una sola vez y todo se detiene.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_night_manager.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

var _requests: RequestManager


## Reloj de la noche 1 del catálogo de prueba (2 videos, a los 140 s y a los 280 s), sin solicitudes
## que lleguen solas.
func _make_night() -> NightManager:
	var root := (Engine.get_main_loop() as SceneTree).root
	_requests = RequestManager.new()
	_requests.catalog = Fixtures.make_catalog()
	_requests.night_number = 1
	_requests.random_seed = 9
	_requests.requests_arrive = false
	root.add_child(_requests)
	var night := NightManager.new()
	root.add_child(night)
	night.setup(_requests)
	return night


func _free(night: NightManager) -> void:
	night.free()
	_requests.free()


## Guarda en `endings` cada final de la noche, como [cómo terminó, solicitud fatal].
func _record_endings(night: NightManager, endings: Array) -> void:
	night.night_ended.connect(func(ending: NightState.Ending, request: FriendRequest) -> void:
		endings.append([ending, request]))


## Avanza `seconds` de a 1 segundo, como lo haría el juego.
func _advance(night: NightManager, seconds: int) -> void:
	for _i in seconds:
		night.advance(1.0)


func test_avanza_las_solicitudes_y_el_estado() -> bool:
	var night := _make_night()
	check(not _requests.is_processing(), "el manager ya no avanza solo")
	var request := _requests.start_request(0)
	night.advance(10.0)
	check_eq(request.time_left, 35.0, "el temporizador avanzó")
	check_eq(night.state().elapsed, 10.0, "la hora avanzó")
	_free(night)
	return true


func test_avisa_cuando_llega_un_video() -> bool:
	var night := _make_night()
	var arrived := []
	night.video_received.connect(func(friend_index: int) -> void: arrived.append(friend_index))
	_advance(night, 139)
	check(arrived.is_empty(), "todavía no")
	_advance(night, 1)
	check_eq(arrived.size(), 1, "a los 140 s llega el primero")
	_free(night)
	return true


func test_a_las_06_con_la_cuota_se_gana() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_advance(night, 419)
	check(endings.is_empty(), "a los 419 s sigue")
	_advance(night, 1)
	check_eq(endings, [[NightState.Ending.WON, null]], "ganó a las 06:00")
	check(night.ended, "terminó")
	_free(night)
	return true


func test_a_las_06_sin_la_cuota_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().videos.pending.clear()
	_advance(night, 420)
	check_eq(endings, [[NightState.Ending.QUOTA, null]], "faltó contenido")
	_free(night)
	return true


func test_si_muere_un_amigo_se_pierde_en_el_acto() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_requests.catalog.balance.wrong_hurt_chance = 1.0
	night.state().friends[0].health = 1
	var request := _requests.start_request(0)
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	var wrong := request.entity.actions.filter(func(action: ActionData) -> bool:
		return action.id != rule.correct_action_id and action.id != rule.risky_action_id)
	_requests.answer(0, wrong[0])
	check_eq(endings, [[NightState.Ending.FRIEND_DIED, request]], "murió León, con la solicitud que lo explica")
	_free(night)
	return true


func test_con_sanity_en_0_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().sanity = 0.5
	night.advance(10.0)
	check_eq(endings, [[NightState.Ending.SANITY, null]], "Sanity")
	_free(night)
	return true


func test_al_terminar_todo_se_detiene() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	var request := _requests.start_request(1)
	night.state().trust = 0.0
	night.advance(1.0)
	var time_left := request.time_left
	_advance(night, 30)
	check_eq(endings.size(), 1, "termina una sola vez")
	check_eq(night.state().elapsed, 1.0, "la hora se detuvo")
	check_eq(request.time_left, time_left, "los temporizadores se detuvieron")
	_free(night)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `224 pruebas OK, 1 fallidas`. La falla es `test_night_manager.gd :: no se pudo cargar`.

- [ ] **Paso 3: Crear `NightManager`**

`scripts/desk/night_manager.gd`:

```gdscript
extends Node
## El reloj de la noche (Plan 5): avanza las solicitudes y el estado de la noche, en ese orden, y decide
## cuándo termina. Se gana a las 06:00 con la cuota cumplida. Se pierde apenas muere un amigo o
## Sanity, Trust o Connection llegan a 0, o a las 06:00 si falta contenido (diseño §5).
## Al terminar, todo se detiene: los temporizadores, la hora y los medidores.

## Llegó un video del amigo `friend_index`. Por ahora se recibe solo: aceptarlo llega en el Plan 6.
signal video_received(friend_index: int)
## La noche terminó. `fatal_request` es la solicitud en la que murió un amigo; si nadie murió, null.
signal night_ended(ending: NightState.Ending, fatal_request: FriendRequest)

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var requests: RequestManager
var ended := false


## Toma el control del tiempo de `manager`: desde ahora, las solicitudes avanzan solo cuando avanza la noche.
func setup(manager: RequestManager) -> void:
	requests = manager
	manager.set_process(false)
	manager.request_finished.connect(_on_request_finished)


func state() -> NightState:
	return requests.state


func _process(delta: float) -> void:
	advance(delta)


## Avanza la noche `delta` segundos. Cuando termina, ya no avanza más.
func advance(delta: float) -> void:
	if ended or requests == null:
		return
	requests.advance(delta)
	if ended:
		return
	for friend_index: int in requests.state.advance(delta):
		video_received.emit(friend_index)
	_check_ending(null)


## Una solicitud terminada puede matar al amigo, y entonces es la que explica la derrota.
func _on_request_finished(_friend_index: int, request: FriendRequest) -> void:
	_check_ending(request)


func _check_ending(request: FriendRequest) -> void:
	if ended:
		return
	var ending := requests.state.ending()
	if ending == NightState.Ending.NONE:
		return
	ended = true
	night_ended.emit(ending, request if ending == NightState.Ending.FRIEND_DIED else null)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `231 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/ test/
git commit -m "Reloj de la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: Los medidores en el escritorio

**Archivos:**

- Crear: `shaders/vignette.gdshader`
- Modificar: `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_desk_scene.gd`

El escritorio agrega `NightManager` y muestra el estado de la noche: los diales, la hora en el celular, los videos en el PC y la viñeta de Sanity.

Posiciones (`docs/03`: 1 píxel de arte = 1 unidad):

- **La hora:** dentro de `Phone` (357, 618). El parche `ClockCover` cubre las filas 6 a 17 de la pantalla del celular, donde está dibujado "00:00", con su mismo color (76, 107, 167). La pantalla está inclinada, así que el parche es un paralelogramo.
- **Los videos:** dentro de `PC` (479, 433), en la franja negra de la pantalla sobre las entradas: de (39, 7) a (282, 21).
- **La viñeta:** en una capa nueva, `Overlay` (layer 2), sobre el chat y el cuaderno. No recibe clics.

La hora y los videos usan Departure Mono, la fuente del chat y de las entradas del PC, a 11 px.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
```

por:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const NightState := preload("res://scripts/core/night_state.gd")
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
## El estado de la noche del escritorio (noche 3: cuota de 3 videos).
func _state(desk: Node2D) -> NightState:
	return desk.get_node("RequestManager").state


func test_la_noche_avanza_con_su_reloj() -> bool:
	var desk := _make_desk()
	check(not desk.get_node("RequestManager").is_processing(), "las solicitudes las avanza el reloj de la noche")
	desk.get_node("NightManager").advance(2.0)
	check_eq(_state(desk).elapsed, 2.0, "la hora avanzó")
	desk.free()
	return true


func test_los_diales_muestran_los_medidores() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.sanity = 40.0
	state.trust = 70.0
	for friend in state.friends:
		friend.signal_level = 50.0
	desk._process(0.0)
	check(is_equal_approx(desk.get_node("WallPlane/DialConnection").value, 0.5), "Connection: el promedio de las señales")
	check(is_equal_approx(desk.get_node("WallPlane/DialSanity").value, 0.4), "Sanity")
	check(is_equal_approx(desk.get_node("WallPlane/DialTrust").value, 0.7), "Trust")
	desk.free()
	return true


func test_el_celular_muestra_la_hora() -> bool:
	var desk := _make_desk()
	_state(desk).elapsed = 210.0
	desk._process(0.0)
	check_eq((desk.get_node("DeskPlane/Phone/Clock") as Label).text, "03:00", "a la mitad de la noche")
	desk.free()
	return true


func test_el_pc_cuenta_los_videos() -> bool:
	var desk := _make_desk()
	_state(desk).videos.received = 1
	desk._process(0.0)
	var expected := String(TranslationServer.translate("PC_VIDEOS")).format({"received": 1, "quota": 3})
	check_eq((desk.get_node("DeskPlane/PC/Videos") as Label).text, expected, "1 de 3")
	check(expected.contains("1") and expected.contains("3"), "el texto lleva {received} y {quota}")
	desk.free()
	return true


func test_la_vineta_sigue_a_sanity() -> bool:
	var desk := _make_desk()
	var vignette := desk.get_node("Overlay/Vignette") as ColorRect
	check_eq(vignette.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no tapa los clics")
	_state(desk).sanity = 30.0
	desk._process(0.0)
	var strength: float = (vignette.material as ShaderMaterial).get_shader_parameter(&"strength")
	check(is_equal_approx(strength, 0.5), "con Sanity 30, a la mitad: %s" % strength)
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `231 pruebas OK, 5 fallidas`. Son las 5 pruebas nuevas de `test_desk_scene.gd`: el escritorio todavía no tiene `NightManager`, la hora, los videos ni la viñeta.

- [ ] **Paso 3: El shader de la viñeta**

`shaders/vignette.gdshader`:

```glsl
shader_type canvas_item;
// Viñeta de Sanity (diseño §10.2): oscurece los bordes de la pantalla, más mientras más baja Sanity.
// Va en un ColorRect que cubre la pantalla. La oscuridad avanza en bandas, como el pixel art.

// 0: no se ve. 1: solo queda claro el centro.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Cuántos niveles de oscuridad hay entre el borde de la viñeta y la oscuridad máxima.
uniform float bands = 5.0;
// Oscuridad máxima, en los bordes de la pantalla.
uniform float max_darkness : hint_range(0.0, 1.0) = 0.92;

void fragment() {
	// Distancia al centro, corregida para que la viñeta sea redonda en una pantalla de 16:9.
	vec2 from_center = (UV - 0.5) * vec2(16.0 / 9.0, 1.0);
	// Con strength 0, el borde de la viñeta queda fuera de la pantalla; con 1, cerca del centro.
	float inner = mix(1.1, 0.1, strength);
	float darkness = smoothstep(inner, inner + 0.4, length(from_center));
	COLOR = vec4(0.0, 0.0, 0.0, floor(darkness * bands) / bands * max_darkness);
}
```

- [ ] **Paso 4: El texto de los videos**

Agregar al final de `data/text/ui.csv`:

```csv
PC_VIDEOS,Videos: {received} de {quota},
```

- [ ] **Paso 5: La escena del escritorio**

Son 5 cambios en `scenes/desk/desk.tscn`.

**1. Los recursos.** En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="PackedScene" path="res://scenes/ui/notebook_panel.tscn" id="notebook_panel"]
```

por:

```ini
[ext_resource type="PackedScene" path="res://scenes/ui/notebook_panel.tscn" id="notebook_panel"]
[ext_resource type="Script" path="res://scripts/desk/night_manager.gd" id="night_script"]
[ext_resource type="Shader" path="res://shaders/vignette.gdshader" id="vignette_shader"]
[ext_resource type="FontFile" path="res://fonts/departure_mono/DepartureMono-Regular.otf" id="pixel_font"]

[sub_resource type="ShaderMaterial" id="vignette_material"]
shader = ExtResource("vignette_shader")
shader_parameter/strength = 0.0
shader_parameter/bands = 5.0
shader_parameter/max_darkness = 0.92
```

**2. La hora en el celular.** En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="Phone" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(357, 618)
sprite_frames = ExtResource("phone")
centered = false
script = ExtResource("clickable_script")
```

por:

```ini
[node name="Phone" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(357, 618)
sprite_frames = ExtResource("phone")
centered = false
script = ExtResource("clickable_script")

[node name="ClockCover" type="Polygon2D" parent="DeskPlane/Phone"]
color = Color(0.298, 0.42, 0.655, 1)
polygon = PackedVector2Array(30, 6, 80, 6, 76, 18, 25, 18)

[node name="Clock" type="Label" parent="DeskPlane/Phone"]
offset_left = 26.0
offset_top = 4.0
offset_right = 80.0
offset_bottom = 20.0
theme_override_colors/font_color = Color(0.76, 0.835, 0.929, 1)
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11
text = "00:00"
horizontal_alignment = 1
vertical_alignment = 1
```

**3. Los videos en el PC.** En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="PC" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(479, 433)
sprite_frames = ExtResource("pc")
centered = false
```

por:

```ini
[node name="PC" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(479, 433)
sprite_frames = ExtResource("pc")
centered = false

[node name="Videos" type="Label" parent="DeskPlane/PC"]
offset_left = 39.0
offset_top = 7.0
offset_right = 282.0
offset_bottom = 21.0
theme_override_colors/font_color = Color(0.75, 0.8, 0.9, 1)
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11
horizontal_alignment = 2
vertical_alignment = 1
```

**4. El reloj de la noche.** Va después de `RequestManager`. En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="RequestManager" type="Node" parent="."]
script = ExtResource("requests_script")
catalog = ExtResource("catalog")
```

por:

```ini
[node name="RequestManager" type="Node" parent="."]
script = ExtResource("requests_script")
catalog = ExtResource("catalog")

[node name="NightManager" type="Node" parent="."]
script = ExtResource("night_script")
```

**5. La viñeta.** Agregar al final de `scenes/desk/desk.tscn`:

```ini
[node name="Overlay" type="CanvasLayer" parent="."]
layer = 2

[node name="Vignette" type="ColorRect" parent="Overlay"]
material = SubResource("vignette_material")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
```

- [ ] **Paso 6: El script del escritorio**

`scripts/desk/desk.gd` (archivo completo):

```gdscript
extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo (parpadean
## y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación. El cuaderno se abre
## con un clic en él o en el nombre de la entidad, y muestra la página del amigo del chat. El chat y el
## cuaderno son independientes y pueden estar abiertos a la vez (decisión de Benja). Cada uno se cierra
## con clic derecho sobre él; Esc o un clic fuera de los paneles cierra los dos.
## Un clic en el celular o el mixer cierra los paneles y por ahora solo se registra (sus vistas, en el Plan 6).
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, y la viñeta oscurece
## la vista cuando baja Sanity.

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const DialGauge := preload("res://scripts/desk/dial_gauge.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Videos recibidos, en el PC (ui.csv). Lleva {received} y {quota}.
const VIDEOS_KEY := "PC_VIDEOS"

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
var notebook_memory: NotebookMemory

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _notebook_panel: Control = $UI/NotebookPanel
@onready var _requests: RequestManager = $RequestManager
@onready var _night: NightManager = $NightManager
@onready var _dial_connection: DialGauge = $WallPlane/DialConnection
@onready var _dial_sanity: DialGauge = $WallPlane/DialSanity
@onready var _dial_trust: DialGauge = $WallPlane/DialTrust
@onready var _clock: Label = $DeskPlane/Phone/Clock
@onready var _videos: Label = $DeskPlane/PC/Videos
@onready var _vignette: ColorRect = $Overlay/Vignette


func _ready() -> void:
	var friends := _requests.catalog.friends
	notebook_memory = NotebookMemory.new(friends.size())
	_night.setup(_requests)
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
	_refresh_meters()


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


## Los diales (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del PC
## y la viñeta de Sanity.
func _refresh_meters() -> void:
	var state := _requests.state
	_dial_connection.value = state.connection() / NightState.METER_MAX
	_dial_sanity.value = state.sanity / NightState.METER_MAX
	_dial_trust.value = state.trust / NightState.METER_MAX
	_clock.text = state.clock_text()
	_videos.text = tr(VIDEOS_KEY).format({"received": state.videos.received, "quota": state.videos.quota})
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", state.vignette_strength())
```

- [ ] **Paso 7: Importar y verificar que pasan**

Esperado: `236 pruebas OK, 0 fallidas`.

- [ ] **Paso 8: Commit**

```bash
git add shaders/ scenes/desk/ scripts/desk/ data/text/ test/
git commit -m "Diales, hora, videos y viñeta en el escritorio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: La vida y el aturdimiento en las entradas del PC

**Archivos:**

- Modificar: `scenes/ui/chat_entry.tscn`, `scripts/ui/chat_entry.gd`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_chat_entry.gd`, `test/test_desk_scene.gd`

Cada entrada muestra una marca por punto de vida, entre el nombre y el temporizador. Mientras el amigo está aturdido, la entrada se oscurece y el temporizador dice "Aturdido" con los segundos que faltan. Para hacer lugar, el nombre se achica (hasta x 120) y el temporizador se agranda (de x 150 a 236).

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_entry.gd`:

```gdscript
func test_vida() -> bool:
	var entry := _make_entry()
	entry.set_health(2, 3)
	var pips := entry.get_node("Health").get_children()
	check_eq(pips.size(), 3, "una marca por punto de vida")
	var filled := pips.map(func(pip: Panel) -> bool: return (pip.get_theme_stylebox(&"panel") as StyleBoxFlat).draw_center)
	check_eq(filled, [true, true, false], "2 llenas y 1 vacía: no depende del color")
	for pip: Control in pips:
		check_eq(pip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no le quita el clic a la entrada")
	entry.set_health(0, 3)
	check_eq(entry.get_node("Health").get_child_count(), 3, "se rehacen, no se acumulan")
	entry.free()
	return true


func test_aturdido() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.set_state(ChatEntry.State.STUNNED)
	check_eq(background.animation, &"idle", "aturdido usa idle")
	check_eq(background.modulate, ChatEntry.STATE_MODULATE[ChatEntry.State.STUNNED], "más oscuro")
	entry.show_stun(12)
	var timer := entry.get_node("TimerLabel") as Label
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_STUNNED")).format({"seconds": 12}), "texto")
	check(timer.text.contains("12"), "con los segundos")
	entry.free()
	return true
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
func test_un_amigo_herido_se_ve_en_su_entrada() -> bool:
	var desk := _make_desk()
	_state(desk).friends[1].hurt(1, 15.0)
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.STUNNED, "aturdido")
	check_eq(gonzalo.health, 2, "con 2 PV")
	check((gonzalo.get_node("TimerLabel") as Label).text.contains("15"), "muestra cuánto le queda")
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").health, 3, "León, sano")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `212 pruebas OK, 2 fallidas`. Son `test_chat_entry.gd :: no se pudo cargar` y `test_desk_scene.gd :: no se pudo cargar`, porque `ChatEntry.State.STUNNED` no existe. Las otras pruebas de esos dos archivos vuelven en el paso 5.

- [ ] **Paso 3: La entrada**

Agregar al final de `data/text/ui.csv`:

```csv
ENTRY_STUNNED,Aturdido {seconds},
```

En `scenes/ui/chat_entry.tscn`, reemplazar:

```ini
[node name="NameLabel" type="Label" parent="."]
offset_left = 6.0
offset_top = 3.0
offset_right = 180.0
```

por:

```ini
[node name="NameLabel" type="Label" parent="."]
offset_left = 6.0
offset_top = 3.0
offset_right = 120.0
```

En `scenes/ui/chat_entry.tscn`, reemplazar:

```ini
[node name="TimerLabel" type="Label" parent="."]
offset_left = 186.0
offset_top = 3.0
offset_right = 224.0
```

por:

```ini
[node name="Health" type="HBoxContainer" parent="."]
offset_left = 124.0
offset_top = 8.0
offset_right = 150.0
offset_bottom = 18.0
mouse_filter = 2
theme_override_constants/separation = 3

[node name="TimerLabel" type="Label" parent="."]
offset_left = 150.0
offset_top = 3.0
offset_right = 236.0
```

`scripts/ui/chat_entry.gd` (archivo completo):

```gdscript
extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, la vida, el estado y el temporizador.

signal pressed

enum State { IDLE, WARNING, DISCONNECTED, SELECTED, STUNNED }

const SIZE := Vector2(243, 26)
const STATE_MODULATE := {
	State.IDLE: Color(1, 1, 1),
	State.WARNING: Color(1, 1, 1),
	State.DISCONNECTED: Color(0.45, 0.45, 0.5),
	State.SELECTED: Color(1.3, 1.3, 1.3),
	State.STUNNED: Color(0.7, 0.6, 0.6),
}
## Lo que dice el temporizador mientras el amigo está aturdido (ui.csv). Lleva {seconds}.
const STUNNED_KEY := "ENTRY_STUNNED"
## Las marcas de vida son provisionales, hasta el arte de las entradas.
const HEALTH_PIP_SIZE := Vector2(6, 10)
const HEALTH_COLOR := Color(0.85, 0.9, 0.95)

@export var display_name := "":
	set(value):
		display_name = value
		if is_node_ready():
			_name_label.text = value

var state: State = State.IDLE
## La vida que muestra, de `max_health`. -1 hasta la primera vez.
var health := -1
var max_health := -1

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _health_box: HBoxContainer = $Health
@onready var _timer_label: Label = $TimerLabel


func _ready() -> void:
	_name_label.text = display_name
	set_state(State.IDLE)
	set_seconds_left(-1)


func set_state(new_state: State) -> void:
	state = new_state
	_background.play(&"warning" if new_state == State.WARNING else &"idle")
	_background.modulate = STATE_MODULATE[new_state]


## Muestra los segundos restantes. Con un valor negativo, oculta el temporizador.
func set_seconds_left(seconds: int) -> void:
	_timer_label.visible = seconds >= 0
	_timer_label.text = str(seconds)


## Muestra cuánto le queda de aturdimiento, en lugar del temporizador.
func show_stun(seconds: int) -> void:
	_timer_label.visible = true
	_timer_label.text = tr(STUNNED_KEY).format({"seconds": seconds})


## Una marca por punto de vida: llena si lo tiene y vacía (solo el borde) si lo perdió, para que no
## dependa del color (diseño §19). Solo se rehacen si la vida cambió.
func set_health(current: int, maximum: int) -> void:
	if current == health and maximum == max_health:
		return
	health = current
	max_health = maximum
	for pip: Node in _health_box.get_children():
		_health_box.remove_child(pip)
		pip.queue_free()
	for index in maximum:
		var pip := Panel.new()
		pip.custom_minimum_size = HEALTH_PIP_SIZE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.add_theme_stylebox_override(&"panel", _pip_style(index < current))
		_health_box.add_child(pip)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and Rect2(Vector2.ZERO, SIZE).has_point(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()


static func _pip_style(full: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEALTH_COLOR
	style.draw_center = full
	style.border_color = HEALTH_COLOR
	style.set_border_width_all(1)
	return style
```

- [ ] **Paso 4: El escritorio actualiza las entradas**

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
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

por:

```gdscript
## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta, o más oscura si el amigo
## está aturdido. El tiempo que le queda para responder o para recuperarse, y su vida.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := _requests.state.friends[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			state = ChatEntry.State.STUNNED
		if entry.state != state:
			entry.set_state(state)
		entry.set_health(friend.health, friend.max_health)
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		else:
			entry.set_seconds_left(-1)
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `239 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scenes/ui/ scripts/ data/text/ test/
git commit -m "Vida y aturdimiento en las entradas del PC" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: Los textos del final de la noche

**Archivos:**

- Crear: `scripts/core/ending_text.gd`, `test/test_ending_text.gd`
- Modificar: `data/text/ui.csv`

`EndingText` arma el título y la explicación de la pantalla final. Si murió un amigo, explica la solicitud: la entidad, lo que observaba el amigo, la regla que se aplicaba, la acción correcta y la elegida (por Matías o por el amigo, si nadie respondió).

- [ ] **Paso 1: Escribir las pruebas**

`test/test_ending_text.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const EndingText := preload("res://scripts/core/ending_text.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")

const FORMATS := {
	"END_WON": "Ganaste con {received} de {quota}.",
	"END_QUOTA": "Faltó: {received} de {quota}.",
	"END_FRIEND_DIED": "Murió {friend}.",
	"END_ENTITY": "Era {entity}.",
	"END_RULE": "Regla {number}: {rule}.",
	"END_CORRECT": "Correcta: {action}.",
	"END_CHOSEN_BY_PLAYER": "Respondiste: {action}.",
	"END_CHOSEN_ALONE": "{friend} eligió solo: {action}.",
}
const FRIENDS: Array[String] = ["León", "Gonzalo", "Agustín"]


## Traducción falsa: los formatos de FORMATS, y cualquier otra clave tal cual.
func _translate(key: String) -> String:
	return FORMATS.get(key, key)


## El texto como se ve: sin etiquetas BBCode y con [lb] convertido en corchete.
func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[(?!lb\\])[^\\]]*\\]").sub(bbcode, "", true).replace("[lb]", "[")


## Estado de la noche 1 del catálogo de prueba: cuota de 2 videos.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	return NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())


## Gonzalo y "beast", con o1 = no y o2 = yes: se aplica la regla 2 (correcta a3, mayor riesgo a4).
func _fatal_request(action_id: StringName, by_player: bool) -> FriendRequest:
	var request := FriendRequest.new()
	request.friend_index = 1
	request.entity = Fixtures.make_entity()
	request.situation = {&"o1": &"no", &"o2": &"yes"}
	request.finish(request.entity.find_action(action_id), by_player)
	return request


func test_titulos() -> bool:
	check_eq(EndingText.title(NightState.Ending.WON, _translate), "END_WON_TITLE", "ganó")
	for ending: NightState.Ending in [NightState.Ending.FRIEND_DIED, NightState.Ending.SANITY, NightState.Ending.QUOTA]:
		check_eq(EndingText.title(ending, _translate), "END_LOST_TITLE", "perdió (%d)" % ending)
	return true


func test_los_videos_al_ganar_o_al_faltar() -> bool:
	var state := _make_state()
	state.videos.received = 2
	check_eq(EndingText.body(NightState.Ending.WON, state, null, FRIENDS, _translate), "Ganaste con 2 de 2.", "ganó")
	state.videos.received = 1
	check_eq(EndingText.body(NightState.Ending.QUOTA, state, null, FRIENDS, _translate), "Faltó: 1 de 2.", "faltó")
	return true


func test_un_dial_en_0() -> bool:
	var state := _make_state()
	var expected := {
		NightState.Ending.SANITY: "END_SANITY",
		NightState.Ending.TRUST: "END_TRUST",
		NightState.Ending.CONNECTION: "END_CONNECTION",
	}
	for ending: NightState.Ending in expected:
		check_eq(EndingText.body(ending, state, null, FRIENDS, _translate), expected[ending], "dial %d" % ending)
	return true


func test_si_murio_un_amigo_explica_la_solicitud() -> bool:
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a4", true), FRIENDS, _translate)
	var expected := "\n".join([
		"Murió Gonzalo.",
		"",
		"Era K_beast_NAME.",
		"END_SITUATION",
		"• K_beast_O1_Q — K_beast_O1_NO",
		"• K_beast_O2_Q — K_beast_O2_YES",
		"Regla 2: K_RULE.",
		"Correcta: K_beast_A3.",
		"Respondiste: K_beast_A4.",
	])
	check_eq(_plain(body), expected, "la explicación")
	check(body.contains("[color=#%s]K_beast_A3[/color]" % EndingText.CORRECT_COLOR), "la correcta, en verde")
	check(body.contains("[color=#%s]K_beast_A4[/color]" % EndingText.CHOSEN_COLOR), "la elegida, en rojo")
	return true


func test_si_el_amigo_decidio_solo() -> bool:
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a1", false), FRIENDS, _translate)
	check(_plain(body).ends_with("Gonzalo eligió solo: K_beast_A1."), "dice que nadie respondió: %s" % _plain(body))
	return true


func test_los_corchetes_se_ven_como_texto() -> bool:
	var proto := func(key: String) -> String: return "[PROTO] " + _translate(key)
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), _fatal_request(&"a4", true), FRIENDS, proto)
	check(not body.contains("[PROTO]"), "[PROTO] no se lee como etiqueta")
	check(_plain(body).begins_with("[PROTO] Murió Gonzalo."), "se ve el corchete")
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var keys: Array = [EndingText.WON_TITLE_KEY, EndingText.LOST_TITLE_KEY, EndingText.ENTITY_KEY, EndingText.SITUATION_KEY,
			EndingText.RULE_KEY, EndingText.CORRECT_KEY, EndingText.CHOSEN_BY_PLAYER_KEY, EndingText.CHOSEN_ALONE_KEY]
	keys.append_array(EndingText.REASON_KEYS.values())
	for key: String in keys:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	var placeholders := {
		"END_WON": ["{received}", "{quota}"],
		"END_QUOTA": ["{received}", "{quota}"],
		"END_FRIEND_DIED": ["{friend}"],
		"END_ENTITY": ["{entity}"],
		"END_RULE": ["{number}", "{rule}"],
		"END_CORRECT": ["{action}"],
		"END_CHOSEN_BY_PLAYER": ["{action}"],
		"END_CHOSEN_ALONE": ["{friend}", "{action}"],
	}
	for key: String in placeholders:
		for placeholder: String in placeholders[key]:
			check(String(TranslationServer.translate(key)).contains(placeholder), "%s debe tener %s" % [key, placeholder])
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `239 pruebas OK, 1 fallidas`. La falla es `test_ending_text.gd :: no se pudo cargar`.

- [ ] **Paso 3: Crear `EndingText` y sus textos**

`scripts/core/ending_text.gd`:

```gdscript
extends RefCounted
## Los textos de la pantalla del final de la noche (diseño §5): si se ganó o se perdió, y por qué.
## Si murió un amigo, explica la solicitud: la entidad, lo que observaba el amigo, la regla que se
## aplicaba, la acción correcta y la que se eligió (docs/02 §2). El cuerpo es BBCode para un RichTextLabel.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Títulos (ui.csv).
const WON_TITLE_KEY := "END_WON_TITLE"
const LOST_TITLE_KEY := "END_LOST_TITLE"
## Por qué terminó la noche (ui.csv). END_WON y END_QUOTA llevan {received} y {quota};
## END_FRIEND_DIED lleva {friend}.
const REASON_KEYS := {
	NightState.Ending.WON: "END_WON",
	NightState.Ending.FRIEND_DIED: "END_FRIEND_DIED",
	NightState.Ending.SANITY: "END_SANITY",
	NightState.Ending.TRUST: "END_TRUST",
	NightState.Ending.CONNECTION: "END_CONNECTION",
	NightState.Ending.QUOTA: "END_QUOTA",
}
## La solicitud en la que murió el amigo (ui.csv). Llevan {entity}; {number} y {rule}; {action};
## y {friend} y {action}.
const ENTITY_KEY := "END_ENTITY"
const SITUATION_KEY := "END_SITUATION"
const RULE_KEY := "END_RULE"
const CORRECT_KEY := "END_CORRECT"
const CHOSEN_BY_PLAYER_KEY := "END_CHOSEN_BY_PLAYER"
const CHOSEN_ALONE_KEY := "END_CHOSEN_ALONE"
## Colores provisionales sobre fondo oscuro. Cada línea también dice qué acción es: el color no es
## la única pista (diseño §19).
const CORRECT_COLOR := "7ee08a"
const CHOSEN_COLOR := "ff6464"


static func title(ending: NightState.Ending, translate: Callable) -> String:
	return _text(translate, WON_TITLE_KEY if ending == NightState.Ending.WON else LOST_TITLE_KEY)


## Por qué terminó la noche y, si murió un amigo, qué pasó en `fatal_request`.
## `friend_names` son los nombres de los amigos, en orden.
static func body(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String], translate: Callable) -> String:
	var friend := _escape(friend_names[fatal_request.friend_index]) if fatal_request != null else ""
	var lines := PackedStringArray([_line(translate, REASON_KEYS[ending],
			{"received": state.videos.received, "quota": state.videos.quota, "friend": friend})])
	if fatal_request != null:
		lines.append("")
		lines.append_array(_request_lines(fatal_request, friend, translate))
	return "\n".join(lines)


## La entidad, lo que observaba el amigo, la regla que se aplicaba, la acción correcta y la elegida.
static func _request_lines(request: FriendRequest, friend: String, translate: Callable) -> PackedStringArray:
	var entity := request.entity
	var lines := PackedStringArray()
	lines.append(_line(translate, ENTITY_KEY, {"entity": _escape(_text(translate, entity.name_key))}))
	lines.append(_line(translate, SITUATION_KEY, {}))
	for observation: ObservationData in entity.observations:
		var value_key: String = observation.values[request.situation[observation.id]]
		lines.append("• %s — %s" % [_escape(_text(translate, observation.question_key)), _escape(_text(translate, value_key))])
	var rule := RuleEvaluator.applicable_rule(entity, request.situation)
	lines.append(_line(translate, RULE_KEY,
			{"number": entity.rules.find(rule) + 1, "rule": _escape(_text(translate, rule.text_key))}))
	var correct := entity.find_action(rule.correct_action_id)
	lines.append(_line(translate, CORRECT_KEY, {"action": _action(correct, CORRECT_COLOR, translate)}))
	var chosen := _action(request.chosen_action, CHOSEN_COLOR, translate)
	if request.answered_by_player:
		lines.append(_line(translate, CHOSEN_BY_PLAYER_KEY, {"action": chosen}))
	else:
		lines.append(_line(translate, CHOSEN_ALONE_KEY, {"friend": friend, "action": chosen}))
	return lines


static func _action(action: ActionData, color: String, translate: Callable) -> String:
	return "[color=#%s]%s[/color]" % [color, _escape(_text(translate, action.label_key))]


## El formato de `key` con sus corchetes como texto, y los `values` ya preparados para BBCode.
static func _line(translate: Callable, key: String, values: Dictionary) -> String:
	return _escape(_text(translate, key)).format(values)


## [lb] escribe un corchete literal: así "[PROTO]" no se lee como etiqueta.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _text(translate: Callable, key: String) -> String:
	return String(translate.call(key))
```

Agregar al final de `data/text/ui.csv`. Son textos de interfaz: borradores que Benja puede cambiar, conservando los marcadores entre llaves:

```csv
END_WON_TITLE,Llegaste a las 06:00,
END_LOST_TITLE,Perdiste la noche,
END_WON,Tus amigos sobrevivieron la noche y consiguieron {received} de {quota} videos.,
END_FRIEND_DIED,{friend} murió.,
END_SANITY,Matías entró en pánico: su Sanity llegó a 0.,
END_TRUST,Tus amigos dejaron de confiar en ti: Trust llegó a 0.,
END_CONNECTION,Se perdió la conexión con los tres amigos.,
END_QUOTA,Llegaron las 06:00 con {received} de {quota} videos: faltó contenido.,
END_ENTITY,Era {entity}.,
END_SITUATION,Lo que observaba:,
END_RULE,Se aplicaba la regla {number}: {rule}.,
END_CORRECT,La acción correcta era: {action}.,
END_CHOSEN_BY_PLAYER,Respondiste: {action}.,
END_CHOSEN_ALONE,"Nadie respondió a tiempo, y {friend} eligió: {action}.",
END_RETRY,Reintentar,
END_PLAY_AGAIN,Jugar de nuevo,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `246 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/core/ data/text/ test/
git commit -m "Textos del final de la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: La pantalla del final de la noche

**Archivos:**

- Crear: `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn`, `test/test_end_screen.gd`
- Modificar: `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `test/test_desk_scene.gd`

La pantalla final va en `Overlay`, sobre la viñeta. Aparece de a poco cuando `NightManager` avisa que la noche terminó, y se queda con todos los clics. Su botón ("Reintentar" o "Jugar de nuevo") recarga la escena: la noche empieza de nuevo y se vuelve a generar. Usa Departure Mono, como el chat: el título a 33 px, la explicación a 11 y el botón a 22.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_end_screen.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const SCREEN := preload("res://scenes/ui/end_screen.tscn")
const NightState := preload("res://scripts/core/night_state.gd")

const FRIENDS: Array[String] = ["León", "Gonzalo", "Agustín"]


func _make_screen() -> Control:
	var screen := SCREEN.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(screen)
	return screen


## Estado de la noche 1 del catálogo de prueba: cuota de 2 videos.
func _make_state() -> NightState:
	var catalog := Fixtures.make_catalog()
	return NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())


func _translated(key: String) -> String:
	return String(TranslationServer.translate(key))


func test_empieza_oculta_y_tapa_el_escritorio() -> bool:
	var screen := _make_screen()
	check(not screen.visible, "oculta mientras dura la noche")
	check_eq(screen.mouse_filter, Control.MOUSE_FILTER_STOP, "se queda con los clics: la noche terminó")
	screen.free()
	return true


func test_al_ganar() -> bool:
	var screen := _make_screen()
	var state := _make_state()
	state.videos.received = 2
	screen.show_ending(NightState.Ending.WON, state, null, FRIENDS)
	check(screen.visible, "aparece")
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_WON_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text,
			_translated("END_WON").format({"received": 2, "quota": 2}), "cuántos videos")
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_PLAY_AGAIN"), "jugar de nuevo")
	screen.free()
	return true


func test_al_perder() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.SANITY, _make_state(), null, FRIENDS)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_LOST_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text, _translated("END_SANITY"), "por qué")
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_RETRY"), "reintentar")
	screen.free()
	return true


func test_el_boton_pide_volver_a_empezar() -> bool:
	var screen := _make_screen()
	var pressed := []
	screen.retry_pressed.connect(func() -> void: pressed.append(true))
	(screen.get_node("Center/Box/Retry") as Button).pressed.emit()
	check_eq(pressed.size(), 1, "avisa una vez")
	screen.free()
	return true
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
func test_al_terminar_la_noche_aparece_la_pantalla() -> bool:
	var desk := _make_desk()
	var screen := desk.get_node("Overlay/EndScreen") as Control
	check(not screen.visible, "oculta mientras dura la noche")
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	check(screen.visible, "aparece al perder")
	check_eq((screen.get_node("Center/Box/Title") as Label).text, String(TranslationServer.translate("END_LOST_TITLE")),
			"perdió")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `246 pruebas OK, 2 fallidas`. Son `test_end_screen.gd :: no se pudo cargar` (la escena no existe) y `test_desk_scene.gd :: test_al_terminar_la_noche_aparece_la_pantalla`.

- [ ] **Paso 3: La pantalla**

`scripts/ui/end_screen.gd`:

```gdscript
extends Control
## Pantalla del final de la noche (Plan 5): dice si se ganó o se perdió y por qué. Si murió un amigo,
## explica la solicitud (EndingText). Aparece de a poco, para que se alcance a ver cómo quedó el
## escritorio, y tapa todo porque la noche ya terminó. Su botón vuelve a empezar la noche.
## Es provisional hasta el arte de las pantallas de victoria y derrota (docs/06 §3). El Plan 8 agrega
## el resumen entre noches y el paso a la noche siguiente.

## Se eligió volver a jugar: el escritorio reinicia la noche.
signal retry_pressed

const EndingText := preload("res://scripts/core/ending_text.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")

## El botón (ui.csv): "Reintentar" al perder y "Jugar de nuevo" al ganar.
const RETRY_KEY := "END_RETRY"
const PLAY_AGAIN_KEY := "END_PLAY_AGAIN"
## Segundos que tarda en aparecer.
const FADE_SECONDS := 1.5

@onready var _title: Label = $Center/Box/Title
@onready var _body: RichTextLabel = $Center/Box/Body
@onready var _button: Button = $Center/Box/Retry


func _ready() -> void:
	hide()
	_button.pressed.connect(retry_pressed.emit)


## Muestra cómo terminó la noche. `friend_names` son los nombres de los amigos, en orden.
func show_ending(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String]) -> void:
	_title.text = EndingText.title(ending, tr)
	_body.text = EndingText.body(ending, state, fatal_request, friend_names, tr)
	_button.text = tr(PLAY_AGAIN_KEY if ending == NightState.Ending.WON else RETRY_KEY)
	modulate.a = 0.0
	show()
	create_tween().tween_property(self, ^"modulate:a", 1.0, FADE_SECONDS)
```

`scenes/ui/end_screen.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/end_screen.gd" id="screen_script"]
[ext_resource type="FontFile" path="res://fonts/departure_mono/DepartureMono-Regular.otf" id="pixel_font"]

[node name="EndScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("screen_script")

[node name="Shade" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.012, 0.024, 0.043, 0.92)

[node name="Center" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Box" type="VBoxContainer" parent="Center"]
custom_minimum_size = Vector2(640, 0)
layout_mode = 2
theme_override_constants/separation = 18

[node name="Title" type="Label" parent="Center/Box"]
layout_mode = 2
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 33
horizontal_alignment = 1

[node name="Body" type="RichTextLabel" parent="Center/Box"]
layout_mode = 2
theme_override_fonts/normal_font = ExtResource("pixel_font")
theme_override_font_sizes/normal_font_size = 11
theme_override_constants/line_separation = 3
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="Retry" type="Button" parent="Center/Box"]
layout_mode = 2
size_flags_horizontal = 4
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 22
```

- [ ] **Paso 4: La pantalla en el escritorio**

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="Shader" path="res://shaders/vignette.gdshader" id="vignette_shader"]
```

por:

```ini
[ext_resource type="Shader" path="res://shaders/vignette.gdshader" id="vignette_shader"]
[ext_resource type="PackedScene" path="res://scenes/ui/end_screen.tscn" id="end_screen"]
```

Agregar al final de `scenes/desk/desk.tscn`:

```ini
[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

Son 4 cambios en `scripts/desk/desk.gd`.

**1. El comentario del script.** En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, y la viñeta oscurece
## la vista cuando baja Sanity.
```

por:

```gdscript
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, la viñeta oscurece
## la vista cuando baja Sanity, y al terminar la noche aparece una pantalla que explica qué pasó.
```

**2. El nodo.** En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _vignette: ColorRect = $Overlay/Vignette
```

por:

```gdscript
@onready var _vignette: ColorRect = $Overlay/Vignette
@onready var _end_screen: Control = $Overlay/EndScreen
```

**3. Las señales.** En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
```

por:

```gdscript
	_night.night_ended.connect(_on_night_ended)
	_end_screen.retry_pressed.connect(_on_retry_pressed)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
```

**4. Mostrar la pantalla y reintentar.** En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta, o más oscura si el amigo
```

por:

```gdscript
## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó.
func _on_night_ended(ending: NightState.Ending, fatal_request: FriendRequest) -> void:
	var names: Array[String] = []
	for friend: FriendData in _requests.catalog.friends:
		names.append(tr(friend.name_key))
	_end_screen.show_ending(ending, _requests.state, fatal_request, names)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5).
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta, o más oscura si el amigo
```

- [ ] **Paso 5: Importar y verificar que pasan**

Esperado: `251 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scenes/ scripts/ test/
git commit -m "Pantalla del final de la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 13: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_night.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `251 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Capturar la noche y revisarla**

`test/capture_night.gd` no empieza con `test_`, así que el ejecutor de pruebas no lo corre.

`test/capture_night.gd`:

```gdscript
extends SceneTree
## Capturas de la noche para revisarla a ojo (Plan 5). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_night.gd -- /mnt/c/dev/capturas/night.png /mnt/c/dev/capturas/night_lost.png
## 1. A las 03:00, con Sanity 25 (viñeta), Trust 55, 1 de 3 videos y León herido y aturdido. Gonzalo pide ayuda.
##    El chat está cerrado, así que se ven la hora del celular y las entradas del PC.
## 2. Se abre el chat de Gonzalo, que con 1 PV recibe una acción incorrecta y muere: la pantalla de derrota
##    explica la solicitud, y detrás, en el chat, quedan su grito y el aviso de daño.

const DESK := preload("res://scenes/desk/desk.tscn")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	manager.requests_arrive = false
	manager.rng.seed = 5
	var state: RefCounted = manager.state
	state.elapsed = 210.0
	state.sanity = 25.0
	state.trust = 55.0
	state.videos.pending.clear()
	state.videos.received = 1
	state.friends[0].hurt(2, 15.0)
	var request: RefCounted = manager.start_request(1)
	await create_timer(2.0).timeout
	await _save(0)
	desk.get_node("UI/ChatPanel").open_for(1)
	state.friends[1].health = 1
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var entity: EntityData = request.get("entity")
	var rule := RuleEvaluator.applicable_rule(entity, request.get("situation"))
	for action: ActionData in entity.actions:
		if action.id != rule.correct_action_id and action.id != rule.risky_action_id:
			manager.answer(1, action)
			break
	await create_timer(2.0).timeout
	await _save(1)
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

Se ejecuta **con ventana** (sin `--headless`): Godot abre una ventana unos 5 segundos y se cierra solo. La primera captura va con el chat cerrado, porque su pantalla tapa el celular.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_night.gd -- /mnt/c/dev/capturas/night.png /mnt/c/dev/capturas/night_lost.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: `Captura guardada en C:\dev\capturas\night.png` y `Captura guardada en C:\dev\capturas\night_lost.png`. Abrir las imágenes (con la herramienta Read) y comprobar.

En `night.png`:

- el celular dice 03:01 (o 03:02), sobre el parche azul, sin restos del "00:00" dibujado;
- arriba de la pantalla del PC, a la derecha, dice "Videos: 1 de 3";
- el chat está cerrado, y las entradas y los textos nuevos del PC usan la fuente pixel del chat;
- la entrada de León, más oscura, tiene 1 marca llena y 2 vacías y dice "Aturdido" con unos 13 o 14 segundos; la de Gonzalo, en alerta, muestra su tiempo; las 3 entradas tienen sus marcas entre el nombre y el temporizador;
- los diales: Connection con la aguja abajo a la derecha (100), Sanity hacia arriba a la izquierda (25) y Trust apenas a la derecha de las 12 (55);
- la viñeta: las esquinas y los bordes, más oscuros y en bandas; el centro, claro.

En `night_lost.png`:

- todo oscurecido detrás, y al centro "Perdiste la noche";
- "Gonzalo murió.", "Era El Trauco.", "Lo que observaba:" con las 3 observaciones (pregunta y valor), la regla que se aplicaba, la acción correcta en verde y "Respondiste:" con la elegida en rojo;
- el botón "Reintentar";
- detrás, en el chat de Gonzalo, su grito ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y el aviso rojo y centrado "Gonzalo recibió daño: 0/3".

Si algo no coincide, revisarlo antes de seguir.

- [ ] **Paso 3: Actualizar las instrucciones de Godot (`docs/04_instrucciones_godot.md`)**

En la tabla **Estado**, agregar la fila `| **I.** Probar la noche (Plan 5) | ⬜ Pendiente (unos 15 minutos) |` debajo de la de H.

Agregar al final de `docs/04_instrucciones_godot.md`:

````markdown
---

## I. Probar la noche (Plan 5)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Los medidores:**
   - el celular muestra la hora: empieza en 00:00 y avanza un minuto cada poco más de un segundo. La noche dura 7 minutos, hasta las 06:00;
   - arriba de la pantalla del PC dice "Videos: 0 de 3". A las 01:30, a las 03:00 y a las 04:30 llega un video, y el contador sube solo (por ahora no hay que aceptarlo);
   - en la pared, el dial del medio (Sanity, aguja roja) baja de a poco. El de abajo (Trust, aguja amarilla) baja cuando eliges mal. El de arriba (Connection, aguja verde) no se mueve hasta el Plan 6;
   - cada entrada del PC muestra 3 marcas de vida.
3. **Una acción incorrecta:** cuando llegue una solicitud, ábrela, identifica a la entidad y elige una acción que no sea la correcta ni la de mayor riesgo (míralo en las reglas del cuaderno). El amigo cuenta cómo le fue:
   - si quedó herido, grita en el chat ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y debajo aparece un aviso rojo y centrado con la vida que le queda ("León recibió daño: 2/3"). Pierde una marca de vida en su entrada del PC, que se oscurece y dice "Aturdido" con los segundos que faltan. Durante 15 segundos no le llegan solicitudes;
   - el dial de Trust baja. Si pasas 20 segundos sin errores, empieza a subir de a poco.
4. **La acción de mayor riesgo:** en otra solicitud, elige la de mayor riesgo. Si el amigo sobrevive, el contador de videos sube uno más; si quedó herido, el video llega cuando se recupera. Trust baja más que con una acción incorrecta.
5. **Sin respuesta:** deja que se acabe el tiempo de una solicitud. El amigo cuenta qué hizo y, en otro mensaje, cómo le fue. Trust baja más que si hubieras respondido.
6. **Perder:** sigue respondiendo mal al mismo amigo hasta que pierda sus 3 marcas. La pantalla se oscurece de a poco y dice "Perdiste la noche", que el amigo murió y por qué: la entidad, lo que observaba, la regla que se aplicaba, la acción correcta (en verde) y la que elegiste (en rojo). Haz clic en **Reintentar**: la noche empieza de nuevo, con otras solicitudes.
7. **La viñeta y Sanity:** para no esperar, acelera Sanity.
   - En el panel **FileSystem**, haz doble clic en `data/nights/night_3.tres`.
   - En el **Inspector**, dentro de **Sanity y cuota**, cambia **Sanity Drain Interval** de 6 a 1 y guarda con **Ctrl + S**.
   - Presiona **F5**. Hacia los 40 segundos, los bordes de la pantalla se oscurecen en bandas, cada vez más hacia el centro, también sobre el chat. A los 100 segundos, Sanity llega a 0 y se pierde la noche ("Matías entró en pánico").
   - **Al terminar, vuelve Sanity Drain Interval a 6** y guarda.
8. **Ganar:** juega una noche completa (7 minutos) sin que muera nadie. A las 06:00, si llegaron los 3 videos, aparece "Llegaste a las 06:00" con el botón **Jugar de nuevo**.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Los valores de equilibrio** están en `data/balance.tres`. Haz doble clic en él y cámbialos en el **Inspector**: la duración de la noche (**Night Seconds**), la vida y el aturdimiento (**Amigos**), la probabilidad de herir, el daño y lo que baja Trust en cada caso (**Consecuencias**), cómo se recupera Trust (**Trust**) y desde qué valor de Sanity aparece la viñeta (**Sanity**).
  - Para probar más rápido, baja **Night Seconds** a 120: la noche entera dura 2 minutos. Al terminar, vuélvelo a 420.
  - Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara el archivo con `docs/02`, y hay que actualizar los dos.
- **Por noche** (`data/nights/night_N.tres`): **Content Quota** (los videos de la cuota) y **Sanity Drain Interval** (los segundos por cada punto de Sanity).
- **La forma de la viñeta:** en `desk.tscn`, selecciona `Overlay/Vignette`. En el **Inspector**, en **Material** > **Shader Parameters**, cambia **Bands** (cuántos niveles de oscuridad hay) y **Max Darkness** (lo más oscuro, en los bordes).
````

- [ ] **Paso 4: Actualizar la hoja de ruta, el registro y el resumen**

- `docs/06_plan_v1.md`: en la línea del Plan 5, cambiar "(por ejecutar)" por "(ejecutado)".
- `docs/02_bucle_central.md`:
  - en §6, debajo del título, agregar: "Los valores que valen para todas las noches están en `data/balance.tres` (`BalanceData`), y los de cada noche, en `data/nights/night_N.tres` (`NightData`). Se ajustan en el Inspector.";
  - en §10, en el bloque del modelo de datos, agregar la línea `BalanceData      night_seconds, friend_health, stun_seconds, consecuencias (probabilidad, daño y Trust), recuperación de Trust, vignette_start` y, en la de `ContentCatalog`, agregar `balance`.
- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar la sección I de `docs/04` y, entre los textos que Benja corrige, las 2 reacciones nuevas, el aviso de daño y los de la pantalla final.
- `docs/00_log.md`:
  - S13 queda ✅;
  - S14 (escribir el Plan 6: mantenimiento) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/12` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/ scenes/ data/ shaders/
git commit -m "Plan 5 terminado: consecuencias, medidores y noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Fuera de este plan, a propósito

- **Plan 6 (mantenimiento):**
  - la señal de cada amigo baja, con interferencias. Un amigo desconectado no está disponible y decide solo **sin** el castigo de Trust: `FriendState.is_available()` va a pedir además que esté conectado, y `Consequence` va a saber si el amigo estaba desconectado;
  - los videos llegan con un aviso: hay que aceptarlos en 10 s y descargarlos manteniendo presionado. Ese cambio va en `VideoSchedule.receive_due()`;
  - scrollear el celular recupera Sanity, y el mixer hace Audio Sync.
- **Plan 7 (screamers y director):** los screamers (Sanity −8 y −15), los screamers auditivos falsos con Sanity baja, la pausa de los temporizadores mientras un screamer tapa la pantalla (en `NightManager`) y el director de ritmo, que reemplaza el ritmo provisional de `RequestManager`.
- **Plan 8 (noches, menú y guardado):** la noche siguiente, el resumen entre noches, el guardado al comenzar cada noche, la victoria final y la opción "Temporizadores ×1,5". La pantalla final pasará a llevar al resumen.
- **Plan 9:** los sonidos (alarma, herida, video recibido y derrota).
- **Arte:** el celular sin la hora y los dígitos LCD, los diales con cara de manómetro, ícono y LED de alerta, las marcas de vida y las pantallas de victoria y derrota (`docs/06` §3).
- **El avatar herido** (`docs/02` §6): todavía no hay avatares.
- **`QUESTION_COST`, `THINKING_TIME` y `FIRST_REQUEST_DELAY`** siguen en el código. Pasan a `BalanceData` si Benja quiere ajustarlos en el Inspector.
- **Varias versiones de cada reacción**, para que no se repitan: hoy hay una por caso. Se agregan si Benja las quiere.

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 5, y diseño §5, §6, §9 y §10):

  | Requisito | Tarea |
  | --- | --- |
  | Resolución de cada respuesta: daño con su probabilidad, Trust según el riesgo y video extra si sobrevive | 2, 5 y 6 |
  | Sin respuesta: el amigo decide solo, se resuelve igual y Trust baja 15 más | 2 y 6 |
  | 3 PV por noche; herido, aturdido 15 s sin pedir ayuda ni enviar videos; con 0 PV muere | 3, 5, 6 y 10 |
  | El amigo herido grita en el chat, y el juego avisa en rojo cuánta vida le queda (decisión de Benja) | 6 y 7 |
  | Trust: baja, se recupera sin errores, acorta los temporizadores y con 0 se pierde | 2, 5, 6 y 8 |
  | Sanity: baja con el tiempo, viñeta gradual y con 0 se pierde | 5, 8 y 9 |
  | Connection: el promedio de las señales, y con 0 se pierde | 5, 8 y 9 |
  | Diales conectados, cada uno con su color (decisión de Benja) | 9 |
  | Reloj en el celular, de 00:00 a 06:00 | 5 y 9 |
  | Cuota y envíos programados, que por ahora llegan solos (decisión de Benja); el de un amigo aturdido se atrasa (decisión de Benja) | 4, 5 y 9 |
  | Victoria a las 06:00 con la cuota; derrota en el acto | 5 y 8 |
  | Pantalla explicativa y reintentar con la noche generada de nuevo | 11 y 12 |
  | "Una noche completa se gana o se pierde" | 8 (`test_a_las_06_con_la_cuota_se_gana`, `test_si_muere_un_amigo_se_pierde_en_el_acto`), 12 y 13 (`docs/04`, I) |

- **Nombres consistentes:**
  - `BalanceData` (`night_seconds`, `friend_health`, `stun_seconds`, `risky_*`, `wrong_*`, `no_answer_trust`, `trust_recovery_*` y `vignette_start`) se usa igual en `Consequence`, `NightState`, `RequestManager` y las pruebas;
  - `Consequence` (`damage`, `trust_change`, `risky` e `is_hurt()`) coincide entre las tareas 2, 5, 6, 7 y 11;
  - `FriendState` (`health`, `max_health`, `stun_left`, `signal_level`, `is_alive()`, `is_stunned()`, `is_available()`, `hurt()` y `advance()`) coincide entre las tareas 3, 5, 6, 7 y 10;
  - `VideoSchedule` (`quota`, `received`, `pending`, `Delivery`, `add_extra()`, `receive_due()` e `is_quota_met()`) coincide entre las tareas 4, 5, 9 y 11;
  - `NightState` (`Ending`, `METER_MAX`, `elapsed`, `sanity`, `trust`, `friends`, `videos`, `advance()`, `apply()`, `is_available()`, `connection()`, `clock_text()`, `vignette_strength()` y `ending()`) coincide con `RequestManager`, `NightManager`, `EndingText`, `desk.gd` y las pruebas;
  - el aviso de daño (`ChatMessage.Sender.SYSTEM`, `MessageBuilder.damage_notice()` y `DAMAGE_KEY`, `ChatMessageView.DANGER_COLOR` y el estilo `SystemNotice`) coincide entre `RequestManager`, el chat, el tema y las pruebas de la tarea 7;
  - `RequestManager.state` y `NightManager` (`setup()`, `state()`, `advance()`, `ended`, `video_received` y `night_ended`) coinciden con `desk.gd` y las pruebas;
  - `ChatEntry` (`State.STUNNED`, `STATE_MODULATE`, `set_health()`, `health`, `max_health` y `show_stun()`) y `EndScreen` (`show_ending()` y `retry_pressed`) coinciden con `desk.gd` y sus pruebas;
  - los nodos nuevos del escritorio (`NightManager`, `DeskPlane/Phone/Clock`, `DeskPlane/PC/Videos`, `Overlay/Vignette` y `Overlay/EndScreen`) son los que usan `desk.gd` y las pruebas.
- **Conteo de pruebas acumulado:** 185 → 188, 193, 196, 201, 215, 220, 224, 231, 236, 239, 246 y 251.
