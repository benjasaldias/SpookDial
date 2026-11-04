# Plan 8: Noches, menú, guardado y opciones — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que el juego se pueda terminar, de punta a punta:

- **la noche 0, una noche de práctica guiada:** tres solicitudes fijas, una de cada amigo, con El Tue Tué y La Calchona. Un aviso arriba de la pantalla dice qué hacer en cada paso: abrir el chat, preguntar, marcar las características, abrir la página, responder y descargar un video. El tiempo para responder no corre solo y nadie sale herido. Termina con el susto guionado, el chat de Gonzalo y el celular, que se mueven desde la noche 1. Se puede saltar;
- **las 7 entidades** como datos, un borrador de Claude que Benja corrige: las 3 de `docs/09` y 4 nuevas (El Cuero, La Viuda, El Basilisco y El Imbunche), cada una en su noche;
- **el menú principal** (Continuar, Nueva partida, Opciones y Salir), **el guardado** al comienzo de cada noche, **el resumen entre noches** (videos y páginas nuevas del cuaderno), **la victoria final** al ganar la noche 5 y **un menú de pausa** con Esc;
- **las opciones** (diseño §19): el volumen de 3 canales, reducir destellos, la cámara fija y los temporizadores ×1,5.

**Arquitectura:**

- Lógica pura en `scripts/core/`: `TutorialGuide` (qué dice el aviso del tutorial), `GameSettings` (las opciones y su archivo) y `SaveGame` (la noche guardada). `FriendRequest`, `Consequence`, `VideoSchedule`, `NightState` y `RequestGenerator` aprenden lo que cambia en el tutorial.
- Datos: la noche 0 es una `NightData` con el número 0, aparte de las 5 noches (`ContentCatalog.tutorial`), con sus solicitudes fijas (`TutorialRequestData`). Las entidades son `.tres` en `data/entities/` y sus textos van en los CSV, como El Trauco.
- `RequestManager` da las solicitudes fijas del tutorial; el escritorio muestra el aviso (`scenes/ui/tutorial_hint.tscn`), aplica las opciones, pausa la noche (`scenes/ui/pause_menu.tscn`) y convierte los botones de la pantalla final en pedidos. La pantalla final es también el resumen entre noches.
- `GameState` (`scripts/autoload/game_state.gd`, un autoload) lleva el juego: el menú (`scenes/menu/main_menu.tscn`, la escena principal), las noches en orden, el guardado y las opciones. Las opciones se cambian en `scenes/ui/options_panel.tscn`, desde el menú y desde la pausa.
- Los canales de audio están en `default_bus_layout.tres`: `Master`, `Ambience` y `Effects`.

**Stack:** Godot 4.7.2 (GDScript con tipado estático, `ConfigFile`, `AudioServer`, `SceneTree.paused` y `change_scene_to_node()`). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §5, §13, §14 y §19, y `docs/02_bucle_central.md` §6, §7 y §10.

---

## Decisiones de este plan

### De Benja (sesión 18, 4 de noviembre)

Están en `CLAUDE.md` y en el diseño v2.

| Decisión | Detalle |
| --- | --- |
| **La noche 0 es guiada y no se pierde.** | Unos 3 o 4 minutos. Tres solicitudes fijas, una de cada amigo, con El Tue Tué y La Calchona. Un aviso arriba de la pantalla dice qué hacer en cada paso. El temporizador espera mientras tanto (solo las preguntas le quitan tiempo), nadie sale herido y Trust no baja. Termina con el susto guionado, el chat de Gonzalo y el celular. |
| **Enseña también a descargar un video.** | Después de la segunda solicitud, Agustín manda un video. Sus plazos esperan hasta que se descarga. |
| **Se puede saltar.** | "Nueva partida" siempre empieza en la noche 0, y el aviso tiene un botón "Saltar tutorial" que pasa a la noche 1. |
| **Las 7 entidades son un borrador de Claude.** | Las 3 de `docs/09` y 4 nuevas, como `.tres` y CSV. Benja las corrige en el Inspector y en los CSV antes del congelamiento del contenido (25 de noviembre). |
| **"Temporizadores ×1,5" alarga solo el tiempo para responder.** | Los plazos de los videos y el margen de justicia de los screamers no cambian. |
| **Menú de pausa con Esc.** | Sin ningún panel abierto, Esc pausa la noche: Continuar, Opciones y Volver al menú. Volver al menú pierde la noche, que se retoma desde su comienzo, como al reintentar. Con un panel abierto, Esc lo cierra, como antes. |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| La noche 0 es una `NightData` con el número 0, en `ContentCatalog.tutorial`, aparte de las 5 noches (`nights`). `ContentCatalog.night(n)` devuelve cualquiera, y la noche 0 usa las páginas de la noche 1. | Las 5 noches, su validación y sus pruebas no cambian. Como el tutorial ya muestra El Tue Tué y La Calchona, la noche 1 no suma páginas nuevas. |
| Sus solicitudes son datos (`TutorialRequestData`): el amigo, la entidad, lo que observa el amigo (lo que falte sale al azar), si trae pista y si al terminar manda un video. El lugar y los señuelos salen al azar. Llegan en orden, de a una, con 4 s de respiro y esperando el video. | Así cada paso enseña lo que tiene que enseñar, y Benja lo ajusta en el Inspector. |
| El aviso lo decide `TutorialGuide`, que mira el estado de la noche (la solicitud, el chat abierto, la página, el video, el chat guionado) en lugar de seguir una lista de pasos. | Si el jugador se adelanta (marca la pista antes de preguntar, abre la página desde el índice), el aviso salta al paso que corresponde, sin trabarse. |
| Las preguntas del tutorial cuestan sus 5 s, aunque el tiempo no corre solo. | Así se ve que preguntar cuesta, sin presión. |
| Una acción equivocada en el tutorial no hiere: el aviso dice qué habría pasado en una noche de verdad. | "Sin perder", y aun así se aprende la diferencia entre la correcta, la de mayor riesgo y las incorrectas. |
| El susto guionado de la noche 0 espera lo pendiente (`RequestManager.pending_count()`): las solicitudes que faltan, el respiro y el video. Después del chat de Gonzalo, el celular parpadea, y el tutorial termina cuando Matías lo cierra (`NightManager.finish()`). | El susto llega al final de la práctica, y cerrar el celular es la última lección. |
| La partida guarda solo la noche (`user://save.cfg`), al comenzar cada una, y se borra al ganar la noche 5. Las opciones van aparte (`user://settings.cfg`). | Diseño §5: "Guardado al comienzo de cada noche". Las opciones no se pierden al empezar una partida nueva. |
| Tres canales de audio: `Master`, `Ambience` (el ambiente del cuarto) y `Effects` (todo lo demás). | Lo mínimo para "volumen por canal". El Plan 9 puede separar más (screamers, voces) sin cambiar las opciones. |
| "Reducir destellos" deja fija la alerta de las entradas, atenúa sin titilar el aviso de una interferencia, deja encendido el LED del mixer y oscurece una sola vez la señal previa, el apagón y el rojo del jumpscare. El contorno del celular sigue parpadeando. | Son los parpadeos de más de 3 veces por segundo (el arte de la alerta parpadea 5). El contorno del celular parpadea una vez cada 0,8 s. |
| "Cámara fija" deja la cámara sin zoom y centrada. | Es "desactivar el parallax" (diseño §19), que hoy es la cámara que mira hacia el mouse. |
| `GameState` es un autoload que arma el escritorio (`prepare_night()`): le pone la noche antes de que entre al árbol, le aplica las opciones al estar listo y atiende sus pedidos (`tutorial_skipped`, `next_night_requested`, `retry_requested`, `menu_requested` y `settings_changed`). El escritorio no conoce a `GameState`. | El escritorio sigue funcionando solo, en las pruebas y con F6 desde el editor. Las pruebas de `GameState` usan su propia copia y un archivo de prueba. |
| La pantalla final es también el resumen entre noches y la victoria final. | Ya mostraba los videos y el porqué; solo faltaban las páginas nuevas y los botones. La cinemática entre noches (prioridad 2) iría después de ella. |
| La pausa usa `get_tree().paused`: se detienen la noche, los temporizadores y los sonidos. El menú de pausa funciona en pausa. | Es la pausa de Godot: no hay que tocar cada pieza. |
| El menú principal es la escena principal del proyecto. `RequestManager.night_number` sigue en 3 para las pruebas y para abrir el escritorio solo. | Desde el Plan 8, la noche la elige `GameState`. |

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `382 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.
- [ ] **Datos y textos de Benja:** este plan reemplaza los textos del Trauco de prueba en `messages.csv` y `notebook.csv`, y el Trauco en `data/entities/trauco.tres`, por los de la propuesta de `docs/09`. Si Benja los editó después de la sesión 18, un bloque a reemplazar no va a aparecer: revisar el archivo y preguntarle antes de seguir. En lo demás, los CSV solo cambian por líneas que se agregan al final.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar.** Al importar, Godot registra las clases nuevas (`class_name`), crea los `.uid` de los scripts nuevos y regenera las traducciones de los CSV. Cada paso que corre las pruebas importa antes:

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
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo, y son líneas completas. Si hay varios seguidos para el mismo archivo, se aplican en orden.
- "Agregar al final de `ruta`:": en un `.gd`, dejar dos líneas en blanco antes del bloque; en un `.md`, una línea en blanco; en un `.csv`, agregar las líneas tal cual.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/night_data.gd`, `scripts/data/tutorial_request_data.gd`, `scripts/data/content_catalog.gd` | La noche 0 y sus solicitudes fijas; `night()` y `new_pages()` |
| `scripts/core/content_validator.gd` | La revisión de la noche 0 |
| `scripts/core/friend_request.gd`, `consequence.gd`, `video_schedule.gd`, `night_state.gd`, `request_generator.gd` | El tutorial: el tiempo espera, sin consecuencias, el video espera, la noche no termina sola y las solicitudes fijas |
| `scripts/desk/request_manager.gd`, `scripts/desk/screamer_manager.gd` | Las solicitudes fijas de a una, lo pendiente antes del susto y los temporizadores ×1,5 |
| `scripts/core/tutorial_guide.gd` | `TutorialGuide`: qué dice el aviso del tutorial |
| `data/entities/*.tres`, `data/nights/night_0.tres` a `night_4.tres`, `data/catalog.tres`, `data/text/*.csv` | Las 7 entidades, la noche 0, los señuelos nuevos y los textos |
| `scripts/ui/tutorial_hint.gd`, `scenes/ui/tutorial_hint.tscn` | El aviso del tutorial, con su botón para saltarlo |
| `scripts/core/game_settings.gd`, `default_bus_layout.tres` | Las opciones del jugador y los canales de audio |
| `scripts/core/save_game.gd` | La noche guardada |
| `scripts/ui/chat_entry.gd`, `scripts/ui/mixer_view.gd`, `scripts/desk/look_camera.gd` | Reducir destellos y la cámara fija |
| `scripts/core/ending_text.gd`, `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn` | El resumen entre noches, el final del tutorial y la victoria |
| `scripts/ui/options_panel.gd`, `scenes/ui/options_panel.tscn` | El panel de opciones |
| `scripts/autoload/game_state.gd`, `project.godot` | `GameState`: el juego de punta a punta; el autoload y la escena principal |
| `scripts/ui/main_menu.gd`, `scenes/menu/main_menu.tscn` | El menú principal |
| `scripts/ui/pause_menu.gd`, `scenes/ui/pause_menu.tscn` | El menú de pausa |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn`, `scripts/desk/night_manager.gd` | El aviso del tutorial, las opciones, la pausa, los pedidos al juego y terminar la noche desde afuera |
| `test/test_*.gd`, `test/content_fixtures.gd` | Pruebas de cada tarea; el catálogo de prueba suma una noche 0 |
| `test/capture_plan8.gd` | Capturas para revisar a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
F5 ──▶ menú principal (main_menu.tscn) ──▶ GameState
  Nueva partida ──▶ start_night(0)      Continuar ──▶ start_night(noche guardada)
  start_night(n): SaveGame.store(n) ──▶ prepare_night(n): escritorio con RequestManager.night_number = n,
                  las opciones (apply_settings) y sus pedidos conectados ──▶ change_scene_to_node()

Escritorio, noche 0 (el tutorial)
  RequestManager: las solicitudes fijas de a una (TutorialRequestData) ──▶ sin consecuencias, el tiempo espera
  desk._process ──▶ TutorialGuide.hint(lo que se ve) ──▶ el aviso (TutorialHint)
  susto guionado (cuando pending_count() es 0) ──▶ chat de Gonzalo ──▶ el celular parpadea
  ──▶ Matías lo abre y lo cierra ──▶ NightManager.finish(WON)

Fin de la noche ──▶ pantalla final (EndScreen)
  ganó: el resumen (videos y ContentCatalog.new_pages) ──▶ "Empezar la noche N" ──▶ GameState.next_night()
        la noche 5: la victoria ──▶ SaveGame.clear() ──▶ "Volver al menú"
  perdió: el porqué ──▶ "Reintentar" ──▶ GameState.retry()

Esc sin nada abierto ──▶ pausa (SceneTree.paused) ──▶ PauseMenu: Continuar, Opciones (OptionsPanel) o Volver al menú
Opciones ──▶ GameSettings: el volumen (AudioServer), los destellos, la cámara y el tiempo ──▶ GameState las guarda
```

---

### Tarea 1: La noche 0 en los datos

**Archivos:**

- Crear: `scripts/data/tutorial_request_data.gd`
- Modificar: `scripts/core/content_validator.gd`, `scripts/data/content_catalog.gd`, `scripts/data/night_data.gd`, `scripts/desk/request_manager.gd`, `test/content_fixtures.gd`, `test/test_night_and_catalog.gd`, `test/test_validator_catalog.gd`

La noche 0, el tutorial, es una `NightData` más, con el número 0, pero va aparte de las 5 noches del catálogo (`ContentCatalog.tutorial`): así las pruebas y el validador de las noches 1 a 5 no cambian. Sus solicitudes son fijas (`TutorialRequestData`: quién la pide, qué entidad es, qué observa el amigo, si trae pista y si al terminar manda un video). El tutorial usa las páginas de la noche 1, así que la noche 1 no suma páginas nuevas (`new_pages()`, para el resumen entre noches). `RequestManager` pide la noche al catálogo con `night()`, que entiende el 0.

- [ ] **Paso 1: Escribir las pruebas**

En `test/content_fixtures.gd`, reemplazar:

```gdscript
static func make_catalog() -> ContentCatalog:
```

por:

```gdscript
## La noche 0 (el tutorial) tiene 2 solicitudes de "beast": la de León (o1 = yes, con pista y con un video al
## terminar) y la de Gonzalo (o1 = no y o2 = yes, sin pista).
static func make_catalog() -> ContentCatalog:
```

En `test/content_fixtures.gd`, reemplazar:

```gdscript
	return catalog
```

por:

```gdscript
	catalog.tutorial = make_tutorial(catalog)
	return catalog


## La noche 0 del catálogo de prueba: 2 solicitudes de "beast", con un video de 1 de cuota.
static func make_tutorial(catalog: ContentCatalog) -> NightData:
	var tutorial := NightData.new()
	tutorial.number = 0
	tutorial.place_key = "K_NIGHT_0"
	tutorial.content_quota = 1
	var beast: EntityData = catalog.nights[0].new_entities[0]
	tutorial.tutorial_requests.append(make_tutorial_request(catalog.friends[0], beast, {&"o1": &"yes"}, true, true))
	tutorial.tutorial_requests.append(make_tutorial_request(catalog.friends[1], beast, {&"o1": &"no", &"o2": &"yes"},
			false, false))
	return tutorial


static func make_tutorial_request(friend: FriendData, entity: EntityData, situation: Dictionary, with_hint: bool,
		sends_video: bool) -> TutorialRequestData:
	var data := TutorialRequestData.new()
	data.friend = friend
	data.entity = entity
	for observation_id: StringName in situation:
		data.situation[observation_id] = situation[observation_id]
	data.with_hint = with_hint
	data.sends_video = sends_video
	return data
```

Agregar al final de `test/test_night_and_catalog.gd`:

```gdscript
## La noche 0 es el tutorial (decisión de Benja): está aparte de las 5 noches del catálogo.
func test_la_noche_0_es_el_tutorial() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(catalog.night(0), catalog.tutorial, "la noche 0")
	check_eq(catalog.night(1), catalog.nights[0], "la noche 1")
	check_eq(catalog.night(5), catalog.nights[4], "la noche 5")
	check(catalog.night(0).is_tutorial(), "la noche 0 es el tutorial")
	check(not catalog.night(1).is_tutorial(), "la noche 1 no")
	return true


## El tutorial usa las páginas de la noche 1: así, la noche 1 no suma páginas nuevas.
func test_el_tutorial_usa_las_paginas_de_la_noche_1() -> bool:
	var catalog := Fixtures.make_catalog()
	check_eq(_ids(catalog.known_entities(0)), [&"beast"], "noche 0")
	check_eq(_ids(catalog.new_pages(1)), [], "la noche 1, después del tutorial")
	check_eq(_ids(catalog.new_pages(2)), [&"ghost"], "la noche 2")
	check_eq(_ids(catalog.new_pages(3)), [], "la noche 3")
	return true
```

Agregar al final de `test/test_validator_catalog.gd`:

```gdscript
func test_tutorial() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial.number = 1
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: su número debe ser 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].friend = FriendData.new()
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: el amigo no es del catálogo")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[1].entity = catalog.nights[1].new_entities[0]
	check_contains(ContentValidator.validate_catalog(catalog),
			"Tutorial, solicitud 2: la entidad 'ghost' no está en las páginas de la noche 0")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o1"] = &"maybe"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: 'maybe' no es un valor de 'o1'")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests[0].situation[&"o9"] = &"yes"
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial, solicitud 1: la observación 'o9' no existe")
	catalog = Fixtures.make_catalog()
	catalog.tutorial.tutorial_requests.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "Tutorial: hay un espacio vacío en 'tutorial_requests'")
	return true


func test_sin_tutorial_tambien_es_valido() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.tutorial = null
	check(ContentValidator.validate_catalog(catalog).is_empty(), "el tutorial es opcional para el validador")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `196 pruebas OK, 190 fallidas`. Fallan muchas suites porque `content_fixtures.gd` usa `TutorialRequestData`, que todavía no existe: no cargan.

- [ ] **Paso 3: Implementar**

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	_check_unique_ids(errors, who, "entidades", entities)
```

por:

```gdscript
	_check_tutorial(errors, catalog)
	_check_unique_ids(errors, who, "entidades", entities)
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	for night: NightData in catalog.nights:
		keys.append(["Noche %d" % night.number, night.place_key])
```

por:

```gdscript
	var nights := catalog.nights.duplicate()
	if catalog.tutorial != null:
		nights.append(catalog.tutorial)
	for night: NightData in nights:
		keys.append(["Noche %d" % night.number, night.place_key])
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	return keys
```

por:

```gdscript
	return keys


## La noche 0, si el catálogo la tiene: su número es 0, y cada solicitud es de un amigo del catálogo, con una
## entidad de sus páginas y una situación que existe.
static func _check_tutorial(errors: Array[String], catalog: ContentCatalog) -> void:
	var tutorial := catalog.tutorial
	if tutorial == null:
		return
	if tutorial.number != 0:
		errors.append("Tutorial: su número debe ser 0")
	_check_scripted_chat(errors, catalog, tutorial)
	if tutorial.tutorial_requests.has(null):
		errors.append("Tutorial: hay un espacio vacío en 'tutorial_requests'")
		return
	var known := catalog.known_entities(0)
	for index in tutorial.tutorial_requests.size():
		var data := tutorial.tutorial_requests[index]
		var where := "Tutorial, solicitud %d" % (index + 1)
		if not catalog.friends.has(data.friend):
			errors.append(where + ": el amigo no es del catálogo")
		if data.entity == null or not known.has(data.entity):
			var entity_id: StringName = data.entity.id if data.entity != null else &""
			errors.append("%s: la entidad '%s' no está en las páginas de la noche 0" % [where, entity_id])
			continue
		for observation_id: StringName in data.situation:
			var observation := data.entity.find_observation(observation_id)
			var value: StringName = data.situation[observation_id]
			if observation == null:
				errors.append("%s: la observación '%s' no existe" % [where, observation_id])
			elif not observation.has_value(value):
				errors.append("%s: '%s' no es un valor de '%s'" % [where, value, observation_id])
```

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
## Frases clickeables que camuflan las características en los mensajes (DecoyData).
```

por:

```gdscript
## La noche 0: el tutorial (decisión de Benja). Usa las páginas de la noche 1.
@export var tutorial: NightData
## Frases clickeables que camuflan las características en los mensajes (DecoyData).
```

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores.
func known_entities(night_number: int) -> Array[EntityData]:
	var known: Array[EntityData] = []
	for night: NightData in nights:
		if night.number <= night_number:
			known.append_array(night.new_entities)
	return known
```

por:

```gdscript
## La noche `number`: 0 es el tutorial, y de 1 a 5, las del catálogo.
func night(number: int) -> NightData:
	return tutorial if number == 0 else nights[number - 1]


## Entidades conocidas en una noche: las nuevas de esa noche y de todas las anteriores. El tutorial (noche 0)
## usa las de la noche 1.
func known_entities(night_number: int) -> Array[EntityData]:
	var known: Array[EntityData] = []
	for night_data: NightData in nights:
		if night_data.number <= maxi(night_number, 1):
			known.append_array(night_data.new_entities)
	return known


## Las páginas que el cuaderno suma en la noche `night_number`: las entidades que la noche anterior no se
## conocían (para el resumen entre noches).
func new_pages(night_number: int) -> Array[EntityData]:
	var previous := known_entities(night_number - 1)
	var pages: Array[EntityData] = []
	for entity: EntityData in known_entities(night_number):
		if not previous.has(entity):
			pages.append(entity)
	return pages
```

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
	for night: NightData in nights:
		entities.append_array(night.new_entities)
```

por:

```gdscript
	for night_data: NightData in nights:
		entities.append_array(night_data.new_entities)
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
## Parámetros de una noche. Los valores iniciales están en docs/02 §6 y se ajustan probando.

@export_range(1, 5) var number := 1
```

por:

```gdscript
## Parámetros de una noche. Los valores iniciales están en docs/02 §6 y se ajustan probando.
## La noche 0 es el tutorial (decisión de Benja): sus solicitudes son fijas y no se puede perder.

@export_range(0, 5) var number := 1
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var scripted_chat: ChatScriptData
```

por:

```gdscript
@export var scripted_chat: ChatScriptData

@export_group("Tutorial")
## Solo en la noche 0: las solicitudes fijas, en orden. Llegan de a una, cuando termina la anterior.
@export var tutorial_requests: Array[TutorialRequestData] = []


func is_tutorial() -> bool:
	return number == 0
```

`scripts/data/tutorial_request_data.gd`:

```gdscript
class_name TutorialRequestData
extends Resource
## Una solicitud fija de la noche 0, el tutorial (decisión de Benja): quién la pide, qué entidad es y qué
## observa el amigo, para que cada paso enseñe lo que tiene que enseñar. El lugar y los señuelos salen al azar.

## Quién la pide: uno de los amigos del catálogo.
@export var friend: FriendData
## Tiene que estar en las páginas de la noche 0 (las de la noche 1).
@export var entity: EntityData
## Valor de cada observación: id de la observación → id del valor. Las que falten se eligen al azar.
@export var situation: Dictionary[StringName, StringName] = {}
## El mensaje inicial trae una pista: una de las 2 características.
@export var with_hint := true
## Al terminar, el amigo manda un video, para enseñar a descargarlo (decisión de Benja).
@export var sends_video := false
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Noche que se juega. Por ahora la 3, la única con una entidad (El Trauco).
@export_range(1, 5) var night_number := 3
```

por:

```gdscript
## Noche que se juega (0: el tutorial). En el juego la elige GameState; este valor es el de las pruebas y el de
## abrir el escritorio solo, desde el editor.
@export_range(0, 5) var night_number := 3
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	return catalog.nights[night_number - 1]
```

por:

```gdscript
	return catalog.night(night_number)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `386 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ test/
git commit -m "La noche 0 en los datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: El tutorial sin consecuencias

**Archivos:**

- Modificar: `scripts/core/consequence.gd`, `scripts/core/friend_request.gd`, `scripts/core/night_state.gd`, `scripts/core/request_generator.gd`, `scripts/core/video_schedule.gd`, `test/test_consequence.gd`, `test/test_friend_request.gd`, `test/test_night_state.gd`, `test/test_request_generator.gd`, `test/test_video_schedule.gd`

Las piezas de lógica pura aprenden lo que cambia en el tutorial (decisión de Benja: guiado y sin perder):

- el temporizador de una solicitud puede esperar (`FriendRequest.timer_paused`): solo las preguntas le quitan tiempo, y Matías sigue pensando. `questions_asked` cuenta las preguntas, para el aviso;
- `Consequence` sin consecuencias (`harmless`): nadie sale herido, Trust no baja y la acción de mayor riesgo no da un video extra;
- los plazos de un video pueden esperar (`VideoSchedule.patient`);
- `RequestGenerator.generate_tutorial()` arma una solicitud fija. `generate()` ahora elige la entidad y llama a `build()`, que arma la solicitud con los mismos números al azar y en el mismo orden que antes: las pruebas con semilla no cambian;
- `NightState` del tutorial: el video no llega solo (lo manda un amigo al terminar su solicitud) y la noche no termina sola.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_consequence.gd`:

```gdscript
## En el tutorial no se puede perder (decisión de Benja): nadie sale herido, Trust no baja y la acción de mayor
## riesgo no da un video extra.
func test_en_el_tutorial_no_hay_consecuencias() -> bool:
	for outcome: RuleEvaluator.Outcome in [RuleEvaluator.Outcome.RISKY, RuleEvaluator.Outcome.WRONG]:
		for by_player: bool in [true, false]:
			var consequence := Consequence.new(outcome, by_player, _balance(1.0), RandomNumberGenerator.new(), false, true)
			check_eq(consequence.damage, 0, "sin daño")
			check_eq(consequence.trust_change, 0.0, "Trust igual")
			check(not consequence.risky, "sin video extra")
	return true
```

Agregar al final de `test/test_friend_request.gd`:

```gdscript
## En el tutorial, el temporizador espera (decisión de Benja): solo las preguntas le quitan tiempo. Matías
## sigue pensando, y el nombre aparece igual.
func test_en_el_tutorial_el_temporizador_espera() -> bool:
	var request := _make_request()
	request.timer_paused = true
	request.advance(20.0)
	check_eq(request.time_left, 30.0, "el tiempo no corre")
	check(not request.is_out_of_time(), "no se acaba")
	check(request.pay_question(), "se puede preguntar")
	check_eq(request.time_left, 25.0, "la pregunta cuesta igual")
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	check(request.advance(FriendRequest.THINKING_TIME), "aparece el nombre")
	return true


## El tutorial necesita saber si Matías ya preguntó algo.
func test_cuenta_las_preguntas() -> bool:
	var request := _make_request()
	check_eq(request.questions_asked, 0, "al empezar")
	request.pay_question()
	request.pay_question()
	check_eq(request.questions_asked, 2, "dos preguntas")
	request.time_left = 5.0
	request.pay_question()
	check_eq(request.questions_asked, 2, "la que no se pudo hacer no cuenta")
	return true
```

Agregar al final de `test/test_night_state.gd`:

```gdscript
## El tutorial (decisión de Benja): no se puede perder, ni siquiera con un dial en 0, y su video no llega solo:
## lo manda el amigo de una solicitud. Su plazo espera.
func test_en_el_tutorial_no_se_pierde() -> bool:
	var catalog := Fixtures.make_catalog()
	var state := NightState.new(catalog.tutorial, catalog.balance, 3, RandomNumberGenerator.new())
	check_eq(state.videos.quota, 1, "un video de cuota")
	check_eq(state.videos.pending.size(), 0, "ninguno programado")
	check(state.videos.patient, "su plazo espera")
	state.sanity = 0.0
	state.trust = 0.0
	state.elapsed = catalog.balance.night_seconds
	check_eq(state.ending(), NightState.Ending.NONE, "no termina solo")
	return true
```

Agregar al final de `test/test_request_generator.gd`:

```gdscript
## Las solicitudes del tutorial son fijas: su amigo, su entidad, su situación y si trae pista. El temporizador
## espera (decisión de Benja).
func test_las_solicitudes_del_tutorial_son_fijas() -> bool:
	var catalog := Fixtures.make_catalog()
	var tutorial := catalog.tutorial
	var first := RequestGenerator.generate_tutorial(catalog, tutorial, tutorial.tutorial_requests[0], _rng(1))
	check_eq(first.friend_index, 0, "la pide León")
	check_eq(first.entity.id, &"beast", "beast")
	check_eq(first.situation[&"o1"], &"yes", "o1 fijo")
	check(first.situation.has(&"o2"), "o2, al azar")
	check(first.hint != null and first.traits.has(first.hint), "con pista")
	check(first.timer_paused, "el temporizador espera")
	check_eq(first.time_left, tutorial.base_decision_time, "con todo su tiempo")
	var second := RequestGenerator.generate_tutorial(catalog, tutorial, tutorial.tutorial_requests[1], _rng(1))
	check_eq(second.friend_index, 1, "la pide Gonzalo")
	check_eq(second.situation, {&"o1": &"no", &"o2": &"yes"}, "situación fija")
	check(second.hint == null, "sin pista")
	return true
```

Agregar al final de `test/test_video_schedule.gd`:

```gdscript
## En el tutorial, el video espera a que Matías lo descargue: sus plazos no corren (decisión de Benja).
func test_en_el_tutorial_el_video_espera() -> bool:
	var schedule := _schedule(0)
	schedule.patient = true
	var friends := _friends()
	schedule.add_extra(1, 10.0)
	var changes := _advance(schedule, friends, 10.0, 60, -1)
	check_eq(changes.offered, [1], "llegó el video de Gonzalo")
	check_eq(changes.lost, [], "no se pierde aunque pase el tiempo")
	changes = _advance(schedule, friends, 70.0, 5, 1)
	check_eq(schedule.offer_for(1).progress, 0.5, "la descarga avanza igual")
	changes = _advance(schedule, friends, 75.0, 30, -1)
	check_eq(changes.lost, [], "en pausa tampoco se pierde")
	changes = _advance(schedule, friends, 105.0, 5, 1)
	check_eq(changes.received, [1], "se recibe")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `369 pruebas OK, 6 fallidas`.

- [ ] **Paso 3: Implementar**

En `scripts/core/consequence.gd`, reemplazar:

```gdscript
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator, offline := false) -> void:
```

por:

```gdscript
## En el tutorial (`harmless`) no hay consecuencias: no se puede perder (decisión de Benja).
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator, offline := false, harmless := false) -> void:
	if harmless:
		return
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
var identification := Identification.PENDING
```

por:

```gdscript
## En el tutorial, el temporizador espera: solo las preguntas le quitan tiempo (decisión de Benja).
var timer_paused := false
## Cuántas preguntas hizo Matías (el tutorial dice qué hacer según esto).
var questions_asked := 0
var identification := Identification.PENDING
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
	time_left -= question_cost
```

por:

```gdscript
	time_left -= question_cost
	questions_asked += 1
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
## Avanza `delta` segundos. Devuelve true si en este paso apareció el nombre de la entidad.
```

por:

```gdscript
## Avanza `delta` segundos. Devuelve true si en este paso apareció el nombre de la entidad. Con el
## temporizador en espera, solo avanza lo que piensa Matías.
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
	time_left = maxf(time_left - delta, 0.0)
```

por:

```gdscript
	if not timer_paused:
		time_left = maxf(time_left - delta, 0.0)
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	interferences = InterferenceSchedule.new(night.interference_count, balance.night_seconds, friend_count, rng)
```

por:

```gdscript
	if night.is_tutorial():
		# En el tutorial, el video lo manda el amigo de una solicitud, y espera a que Matías lo descargue.
		videos.pending.clear()
		videos.patient = true
	interferences = InterferenceSchedule.new(night.interference_count, balance.night_seconds, friend_count, rng)
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
## A las 06:00 se gana si se cumplió la cuota (diseño §5).
func ending() -> Ending:
```

por:

```gdscript
## A las 06:00 se gana si se cumplió la cuota (diseño §5). El tutorial no termina solo: termina cuando se
## completa (decisión de Benja).
func ending() -> Ending:
	if night.is_tutorial():
		return Ending.NONE
```

En `scripts/core/request_generator.gd`, reemplazar:

```gdscript
	var request := FriendRequest.new()
	request.friend_index = friend_index
	request.entity = known[rng.randi_range(0, known.size() - 1)]
	var entity := request.entity
```

por:

```gdscript
	return build(catalog, night, friend_index, known[rng.randi_range(0, known.size() - 1)], rng, trust)


## La solicitud fija `data` del tutorial (decisión de Benja): su amigo, su entidad, su situación (lo que falte,
## al azar) y la pista si la pide. El temporizador espera.
static func generate_tutorial(catalog: ContentCatalog, night: NightData, data: TutorialRequestData,
		rng: RandomNumberGenerator) -> FriendRequest:
	var request := build(catalog, night, catalog.friends.find(data.friend), data.entity, rng)
	for observation_id: StringName in data.situation:
		request.situation[observation_id] = data.situation[observation_id]
	request.hint = request.traits[0] if data.with_hint else null
	request.timer_paused = true
	return request


## Arma la solicitud de `entity` para el amigo `friend_index`.
static func build(catalog: ContentCatalog, night: NightData, friend_index: int, entity: EntityData,
		rng: RandomNumberGenerator, trust := 100.0) -> FriendRequest:
	var known := catalog.known_entities(night.number)
	var request := FriendRequest.new()
	request.friend_index = friend_index
	request.entity = entity
```

En `scripts/core/video_schedule.gd`, reemplazar:

```gdscript
var offers: Array[Offer] = []
```

por:

```gdscript
var offers: Array[Offer] = []
## En el tutorial, los plazos de los videos no corren: esperan a que Matías los descargue (decisión de Benja).
var patient := false
```

En `scripts/core/video_schedule.gd`, reemplazar:

```gdscript
		offer.time_left -= delta
```

por:

```gdscript
		if not patient:
			offer.time_left -= delta
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `392 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ test/
git commit -m "El tutorial sin consecuencias" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: Las solicitudes fijas del tutorial

**Archivos:**

- Modificar: `scripts/desk/request_manager.gd`, `scripts/desk/screamer_manager.gd`, `test/test_request_manager.gd`

En la noche 0, `RequestManager` no usa el director: da las solicitudes fijas en orden, de a una. La siguiente espera a que termine la anterior, un respiro de 4 s (para leer cómo le fue al amigo) y el video, si el amigo mandó uno. `pending_count()` es lo que hace esperar al susto guionado: en una noche normal, las solicitudes activas, como antes; en el tutorial, también las que faltan, el respiro y el video. Así el susto llega al final de la práctica.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_request_manager.gd`:

```gdscript
## El tutorial del catálogo de prueba (noche 0), con las solicitudes llegando solas.
func _make_tutorial_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 0
	manager.random_seed = 7
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


## La acción correcta de la solicitud de `friend_index`.
func _correct_action(manager: RequestManager, friend_index: int) -> ActionData:
	var request := manager.requests[friend_index]
	return request.entity.find_action(RuleEvaluator.applicable_rule(request.entity, request.situation).correct_action_id)


## En el tutorial, las solicitudes son las fijas de la noche 0 y llegan de a una (decisión de Benja). La
## siguiente espera a que termine la anterior, un respiro de 4 s y el video, si el amigo mandó uno.
func test_en_el_tutorial_las_solicitudes_llegan_de_a_una() -> bool:
	var manager := _make_tutorial_manager()
	manager.advance(4.9)
	check_eq(manager.active_count(), 0, "a los 4,9 s todavía no")
	manager.advance(0.2)
	var first := manager.requests[0]
	check(first != null, "la primera es de León")
	if first == null:
		manager.free()
		return true
	check_eq(first.situation[&"o1"], &"yes", "con su situación fija")
	check(first.timer_paused, "su temporizador espera")
	manager.advance(100.0)
	check(manager.requests[1] == null and manager.requests[2] == null, "no llega otra mientras tanto")
	check_eq(manager.tutorial_queue.size(), 1, "falta una")
	manager.answer(0, _correct_action(manager, 0))
	check_eq(manager.state.videos.pending.size(), 1, "León manda su video")
	manager.advance(10.0)
	check_eq(manager.active_count(), 0, "la siguiente espera el video")
	manager.state.videos.pending.clear()
	manager.advance(1.0)
	check(manager.requests[1] != null, "recibido el video, llega la de Gonzalo")
	check_eq(manager.tutorial_queue.size(), 0, "no falta ninguna")
	manager.free()
	return true


## En el tutorial nadie sale herido y Trust no baja (decisión de Benja).
func test_en_el_tutorial_no_hay_consecuencias() -> bool:
	var manager := _make_tutorial_manager()
	manager.advance(5.1)
	var request := manager.requests[0]
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	manager.answer(0, request.entity.find_action(rule.risky_action_id))
	check_eq(request.outcome, RuleEvaluator.Outcome.RISKY, "la de mayor riesgo")
	check_eq(manager.state.friends[0].health, 3, "León sigue entero")
	check_eq(manager.state.trust, 100.0, "Trust igual")
	manager.free()
	return true


## El susto guionado espera a que termine el tutorial: mientras falten solicitudes, el respiro o el video, hay algo
## pendiente.
func test_en_el_tutorial_lo_pendiente_hace_esperar_al_susto() -> bool:
	var manager := _make_tutorial_manager()
	check(manager.pending_count() > 0, "al empezar faltan las solicitudes")
	manager.tutorial_queue.clear()
	check_eq(manager.pending_count(), 1, "falta el respiro antes de la primera")
	manager.advance(5.0)
	check_eq(manager.pending_count(), 0, "sin solicitudes, ni respiro, ni video")
	manager.state.videos.add_extra(2, 5.0)
	check_eq(manager.pending_count(), 1, "un video que espera")
	manager.free()
	return true


## En una noche normal, lo pendiente son las solicitudes activas.
func test_lo_pendiente_en_una_noche_normal() -> bool:
	var manager := _make_manager()
	check_eq(manager.pending_count(), 0, "nada")
	manager.start_request(2)
	check_eq(manager.pending_count(), 1, "una solicitud")
	manager.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `392 pruebas OK, 4 fallidas`.

- [ ] **Paso 3: Implementar**

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## En el escritorio lo avanza NightManager, junto con el estado de la noche.
```

por:

```gdscript
## Desde el Plan 8, en la noche 0 (el tutorial) llegan las solicitudes fijas de la noche, de a una, y nadie sale
## herido (decisión de Benja).
## En el escritorio lo avanza NightManager, junto con el estado de la noche.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
```

por:

```gdscript
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Segundos que pasan entre una solicitud del tutorial y la siguiente, para leer lo que pasó.
const TUTORIAL_GAP := 4.0
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
var chat_script: ChatScript
```

por:

```gdscript
var chat_script: ChatScript
## En el tutorial, las solicitudes fijas que todavía no llegan, en orden.
var tutorial_queue: Array[TutorialRequestData] = []
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
var _elapsed := 0.0
```

por:

```gdscript
var _elapsed := 0.0
## En el tutorial, la hora desde la que puede llegar la próxima solicitud fija.
var _next_tutorial_at := 0.0
## La solicitud fija en curso en el tutorial, o null.
var _tutorial_current: TutorialRequestData
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	for index in catalog.friends.size():
```

por:

```gdscript
	tutorial_queue.assign(night().tutorial_requests)
	_next_tutorial_at = catalog.balance.first_request_delay
	for index in catalog.friends.size():
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
```

por:

```gdscript
## Lo que hace esperar al susto guionado: las solicitudes activas y, en el tutorial, las fijas que faltan, el
## respiro antes de la próxima y el video que espera.
func pending_count() -> int:
	var count := active_count()
	if night().is_tutorial():
		count += tutorial_queue.size()
		if _elapsed < _next_tutorial_at or not (state.videos.pending.is_empty() and state.videos.offers.is_empty()):
			count += 1
	return count


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	if requests_arrive:
```

por:

```gdscript
	if not requests_arrive:
		return
	if night().is_tutorial():
		_maybe_start_tutorial_request()
	else:
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
func _resolve(request: FriendRequest) -> void:
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng,
			request.decided_offline)
```

por:

```gdscript
## En el tutorial no hay consecuencias.
func _resolve(request: FriendRequest) -> void:
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng,
			request.decided_offline, night().is_tutorial())
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		director.friend_hurt()
```

por:

```gdscript
		director.friend_hurt()
	if _tutorial_current != null:
		_finish_tutorial_request(request.friend_index)
```

Agregar al final de `scripts/desk/request_manager.gd`:

```gdscript
## En el tutorial, la próxima solicitud fija llega cuando no hay otra, pasó el respiro y no hay un video
## esperando.
func _maybe_start_tutorial_request() -> void:
	if tutorial_queue.is_empty() or active_count() > 0 or _elapsed < _next_tutorial_at:
		return
	if not (state.videos.pending.is_empty() and state.videos.offers.is_empty()):
		return
	var data: TutorialRequestData = tutorial_queue.pop_front()
	var request := RequestGenerator.generate_tutorial(catalog, night(), data, rng)
	requests[request.friend_index] = request
	_tutorial_current = data
	request_started.emit(request.friend_index, request)
	_add_friend_message(request.friend_index, MessageBuilder.first_message(request, tr))


## Terminó la solicitud fija en curso: empieza el respiro y, si la solicitud lo pide, el amigo manda un video.
func _finish_tutorial_request(friend_index: int) -> void:
	if _tutorial_current.sends_video:
		state.videos.add_extra(friend_index, _elapsed)
	_tutorial_current = null
	_next_tutorial_at = _elapsed + TUTORIAL_GAP
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	if director.scripted_scare_due(now, _requests.active_count()):
```

por:

```gdscript
	if director.scripted_scare_due(now, _requests.pending_count()):
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `396 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ test/
git commit -m "Las solicitudes fijas del tutorial" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: El guía del tutorial

**Archivos:**

- Crear: `scripts/core/tutorial_guide.gd`, `test/test_tutorial_guide.gd`
- Modificar: `data/text/ui.csv`

`TutorialGuide` (lógica pura) decide qué dice el aviso del tutorial según lo que se ve (`View`): la solicitud en curso, el chat abierto, la página del cuaderno, el video que espera y el chat guionado. Enseña, en orden: abrir el chat, preguntar, marcar las características, abrir la página, responder, cómo le fue al amigo, descargar el video, responderle al amigo después del susto y usar el celular. Cuando Matías cierra el celular, el tutorial terminó. Los textos del aviso van en `ui.csv` (`TUTORIAL_*`), como borrador de Claude.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_tutorial_guide.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")


## Solicitud de "beast" para Gonzalo (amigo 1), con o1 = yes (correcta a1, mayor riesgo a2).
func _make_request() -> FriendRequest:
	var entity := Fixtures.make_entity()
	var request := FriendRequest.new()
	request.friend_index = 1
	request.entity = entity
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.traits.assign(entity.traits)
	request.time_left = 90.0
	return request


func _view(request: FriendRequest = null, chat_friend := -1, page: EntityData = null) -> TutorialGuide.View:
	var view := TutorialGuide.View.new()
	view.request = request
	view.chat_friend = chat_friend
	view.page = page
	return view


func _check_hint(guide: TutorialGuide, view: TutorialGuide.View, key: String, friend_index := -1) -> void:
	var hint := guide.hint(view)
	check_eq(hint.key, key, "aviso")
	check_eq(hint.friend_index, friend_index, "de quién habla el aviso " + key)


## Paso a paso por una solicitud: abrir el chat, preguntar, marcar, abrir la página y responder.
func test_paso_a_paso_por_una_solicitud() -> bool:
	var guide := TutorialGuide.new()
	_check_hint(guide, _view(), TutorialGuide.WELCOME_KEY)
	var request := _make_request()
	_check_hint(guide, _view(request), TutorialGuide.OPEN_CHAT_KEY, 1)
	_check_hint(guide, _view(request, 0), TutorialGuide.OPEN_CHAT_KEY, 1)
	_check_hint(guide, _view(request, 1), TutorialGuide.ASK_KEY, 1)
	request.pay_question()
	_check_hint(guide, _view(request, 1), TutorialGuide.MARK_KEY)
	request.click_clue(&"beast_trait_1")
	request.click_clue(&"beast_trait_2")
	_check_hint(guide, _view(request, 1), TutorialGuide.OPEN_PAGE_KEY)
	request.advance(FriendRequest.THINKING_TIME)
	_check_hint(guide, _view(request, 1), TutorialGuide.OPEN_PAGE_KEY)
	_check_hint(guide, _view(request, 1, Fixtures.make_entity(&"ghost")), TutorialGuide.OPEN_PAGE_KEY)
	_check_hint(guide, _view(request, 1, request.entity), TutorialGuide.ANSWER_KEY)
	_check_hint(guide, _view(request, -1, request.entity), TutorialGuide.OPEN_CHAT_KEY, 1)
	return true


## Después de responder, el aviso dice cómo le fue: en una noche de verdad, la acción equivocada hiere.
func test_dice_como_le_fue() -> bool:
	var keys := {
		&"a1": TutorialGuide.CORRECT_KEY,
		&"a2": TutorialGuide.RISKY_KEY,
		&"a3": TutorialGuide.WRONG_KEY,
	}
	for action_id: StringName in keys:
		var guide := TutorialGuide.new()
		var request := _make_request()
		request.finish(request.entity.find_action(action_id), true)
		guide.request_finished(request)
		_check_hint(guide, _view(), keys[action_id], 1)
	return true


## Un video que espera: primero abrir su chat y después mantener presionada la barra.
func test_el_video() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.video_friend = 2
	_check_hint(guide, view, TutorialGuide.VIDEO_KEY, 2)
	view.chat_friend = 2
	_check_hint(guide, view, TutorialGuide.HOLD_KEY)
	return true


## Después del susto: responderle al amigo, abrir el celular y scrollear. Al cerrarlo, termina el tutorial.
func test_el_chat_guionado_y_el_celular() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.script_friend = 1
	_check_hint(guide, view, TutorialGuide.OPEN_CHAT_KEY, 1)
	view.chat_friend = 1
	_check_hint(guide, view, TutorialGuide.REPLY_KEY)
	guide.phone_opened()
	guide.phone_closed()
	check(not guide.is_done(), "abrir el celular antes de tiempo no cuenta")
	guide.phone_highlighted()
	_check_hint(guide, _view(), TutorialGuide.PHONE_KEY)
	guide.phone_closed()
	check(not guide.is_done(), "todavía no lo abre")
	guide.phone_opened()
	_check_hint(guide, _view(), TutorialGuide.SCROLL_KEY)
	check(not guide.is_done(), "mientras lo usa, sigue")
	guide.phone_closed()
	check(guide.is_done(), "al cerrarlo, termina")
	check_eq(guide.hint(_view()).key, "", "sin aviso")
	return true


func test_sus_textos_existen() -> bool:
	for key: String in [TutorialGuide.TITLE_KEY, TutorialGuide.SKIP_KEY, TutorialGuide.WELCOME_KEY,
			TutorialGuide.OPEN_CHAT_KEY, TutorialGuide.ASK_KEY, TutorialGuide.MARK_KEY, TutorialGuide.OPEN_PAGE_KEY,
			TutorialGuide.ANSWER_KEY, TutorialGuide.CORRECT_KEY, TutorialGuide.RISKY_KEY, TutorialGuide.WRONG_KEY,
			TutorialGuide.VIDEO_KEY, TutorialGuide.HOLD_KEY, TutorialGuide.REPLY_KEY, TutorialGuide.PHONE_KEY,
			TutorialGuide.SCROLL_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `396 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
TUTORIAL_TITLE,Noche de práctica,
TUTORIAL_SKIP,Saltar tutorial,
TUTORIAL_WELCOME,"Esta noche es de práctica: nadie sale herido. Espera a que un amigo te escriba.",
TUTORIAL_OPEN_CHAT,{friend} te escribió. Haz clic en su entrada del PC para abrir su chat.,
TUTORIAL_ASK,"{friend} no sabe qué está viendo. Pregúntale con los botones del chat: cada pregunta le quita 5 s.",
TUTORIAL_MARK,"Haz clic en las frases destacadas que describen a la criatura: necesitas 2. Si una vibra en rojo, no sirve. Si te falta una, pregunta otra cosa.",
TUTORIAL_OPEN_PAGE,"Cuando aparezca el nombre de la criatura, haz clic en él: se abre su página en el cuaderno.",
TUTORIAL_ANSWER,"Lee las reglas en orden: vale la primera que se cumple. Si te falta un dato, pregúntalo. Después responde con su acción, desde el chat.",
TUTORIAL_CORRECT,¡Bien! {friend} está a salvo.,
TUTORIAL_RISKY,"Esa era la de mayor riesgo: da un video extra, pero en una noche de verdad {friend} pudo salir herido.",
TUTORIAL_WRONG,"Esa no era la correcta: en una noche de verdad, {friend} habría salido herido.",
TUTORIAL_VIDEO,{friend} te mandó un video. Abre su chat para descargarlo.,
TUTORIAL_HOLD,Mantén presionada la barra del video hasta que se descargue. Los videos cumplen la cuota de la noche.,
TUTORIAL_REPLY,Respóndele con el botón del chat.,
TUTORIAL_PHONE,"El susto bajó tu Sanity, el dial rojo. Haz clic en el celular del escritorio.",
TUTORIAL_SCROLL,"Scrollea con la rueda del mouse: mientras scrolleas, Sanity sube. Ciérralo con clic derecho para terminar.",
```

`scripts/core/tutorial_guide.gd`:

```gdscript
extends RefCounted
## El guía de la noche 0, el tutorial (decisión de Benja): mira cómo va la noche y dice qué hacer ahora, en un
## aviso arriba de la pantalla. Enseña a abrir el chat, preguntar, marcar las características, abrir la página
## de la entidad, responder desde el cuaderno y descargar un video. Después del susto guionado, a responderle al
## amigo y a usar el celular. El tutorial termina cuando Matías cierra el celular.
## Lógica pura: el escritorio le cuenta lo que se ve (View) y muestra el aviso (Hint).

const FriendRequest := preload("res://scripts/core/friend_request.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")

## Los textos del aviso (ui.csv). Los que hablan de un amigo llevan {friend}.
const TITLE_KEY := "TUTORIAL_TITLE"
const SKIP_KEY := "TUTORIAL_SKIP"
const WELCOME_KEY := "TUTORIAL_WELCOME"
const OPEN_CHAT_KEY := "TUTORIAL_OPEN_CHAT"
const ASK_KEY := "TUTORIAL_ASK"
const MARK_KEY := "TUTORIAL_MARK"
const OPEN_PAGE_KEY := "TUTORIAL_OPEN_PAGE"
const ANSWER_KEY := "TUTORIAL_ANSWER"
const CORRECT_KEY := "TUTORIAL_CORRECT"
const RISKY_KEY := "TUTORIAL_RISKY"
const WRONG_KEY := "TUTORIAL_WRONG"
const VIDEO_KEY := "TUTORIAL_VIDEO"
const HOLD_KEY := "TUTORIAL_HOLD"
const REPLY_KEY := "TUTORIAL_REPLY"
const PHONE_KEY := "TUTORIAL_PHONE"
const SCROLL_KEY := "TUTORIAL_SCROLL"
## Cómo le fue al amigo con la última respuesta.
const OUTCOME_KEYS := {
	RuleEvaluator.Outcome.CORRECT: CORRECT_KEY,
	RuleEvaluator.Outcome.RISKY: RISKY_KEY,
	RuleEvaluator.Outcome.WRONG: WRONG_KEY,
}

## Lo que se ve en el escritorio.
class View:
	## La solicitud del tutorial en curso, o null.
	var request: FriendRequest
	## El amigo cuyo chat está abierto, o -1 con el chat cerrado.
	var chat_friend := -1
	## La página del cuaderno abierta para el amigo de la solicitud, o null.
	var page: EntityData
	## El amigo cuyo video espera su descarga, o -1.
	var video_friend := -1
	## El amigo del chat guionado que espera la respuesta de Matías, o -1.
	var script_friend := -1


## El aviso: su clave en ui.csv (vacía: sin aviso) y el amigo del que habla, o -1.
class Hint:
	var key := ""
	var friend_index := -1

	func _init(hint_key: String, hint_friend := -1) -> void:
		key = hint_key
		friend_index = hint_friend


## La lección del celular, después del chat guionado.
enum Phone { WAITING, HIGHLIGHTED, OPEN, DONE }

var _phone := Phone.WAITING
var _last_request: FriendRequest


## Terminó una solicitud: el aviso dice cómo le fue al amigo.
func request_finished(request: FriendRequest) -> void:
	_last_request = request


## El celular empezó a parpadear: el amigo le dijo a Matías que lo use.
func phone_highlighted() -> void:
	_phone = Phone.HIGHLIGHTED


func phone_opened() -> void:
	if _phone == Phone.HIGHLIGHTED:
		_phone = Phone.OPEN


func phone_closed() -> void:
	if _phone == Phone.OPEN:
		_phone = Phone.DONE


## Matías usó el celular: el tutorial terminó.
func is_done() -> bool:
	return _phone == Phone.DONE


## Qué hacer ahora. Primero el celular, después el chat guionado, el video y la solicitud en curso.
func hint(view: View) -> Hint:
	match _phone:
		Phone.HIGHLIGHTED:
			return Hint.new(PHONE_KEY)
		Phone.OPEN:
			return Hint.new(SCROLL_KEY)
		Phone.DONE:
			return Hint.new("")
	if view.script_friend >= 0:
		return Hint.new(REPLY_KEY) if view.chat_friend == view.script_friend else Hint.new(OPEN_CHAT_KEY, view.script_friend)
	if view.video_friend >= 0:
		return Hint.new(HOLD_KEY) if view.chat_friend == view.video_friend else Hint.new(VIDEO_KEY, view.video_friend)
	var request := view.request
	if request == null:
		if _last_request == null:
			return Hint.new(WELCOME_KEY)
		return Hint.new(OUTCOME_KEYS[_last_request.outcome], _last_request.friend_index)
	if view.chat_friend != request.friend_index:
		return Hint.new(OPEN_CHAT_KEY, request.friend_index)
	if request.identification == FriendRequest.Identification.PENDING:
		return Hint.new(ASK_KEY, request.friend_index) if request.questions_asked == 0 else Hint.new(MARK_KEY)
	if view.page != request.entity:
		return Hint.new(OPEN_PAGE_KEY)
	return Hint.new(ANSWER_KEY)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `401 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ data/ test/
git commit -m "El guía del tutorial" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Las 7 entidades y la noche 0

**Archivos:**

- Crear: `data/entities/basilisco.tres`, `data/entities/calchona.tres`, `data/entities/cuero.tres`, `data/entities/imbunche.tres`, `data/entities/tue_tue.tres`, `data/entities/viuda.tres`, `data/nights/night_0.tres`
- Modificar: `data/catalog.tres`, `data/entities/trauco.tres`, `data/nights/night_1.tres`, `data/nights/night_2.tres`, `data/nights/night_4.tres`, `data/text/messages.csv`, `data/text/notebook.csv`, `data/text/ui.csv`, `test/capture_screamers.gd`, `test/test_balance.gd`, `test/test_catalog.gd`, `test/test_chat_script.gd`, `test/test_screamer_manager.gd`, `test/test_trauco.gd`

El contenido, como borrador de Claude que Benja corrige (decisión de Benja, sesión 18):

- **las 7 entidades** en `data/entities/`: El Tue Tué y La Calchona (noche 1), El Cuero y La Viuda (2), El Trauco (3), El Basilisco y El Imbunche (4). El Tue Tué, La Calchona y El Trauco son los de `docs/09` (al Trauco le falta el sombrero, para que sus características salgan en 3 preguntas distintas). Las otras 4 son nuevas. Cada una reparte sus características en categorías distintas, y comparte una con otra entidad: el olor a ungüento (Tue Tué y Calchona), las hebras en las ramas (Calchona y Trauco), la neblina helada (Cuero y Viuda) y el aire viciado (Basilisco e Imbunche);
- sus textos, en `messages.csv` y `notebook.csv`: los del Trauco de prueba se reemplazan, y 7 señuelos nuevos, de lugares y de cualquier lugar, se agregan a `catalog.tres`;
- **la noche 0** (`data/nights/night_0.tres`): 3 solicitudes fijas, una de cada amigo (León con El Tue Tué y pista; Agustín con La Calchona, pista y un video; Gonzalo con El Tue Tué y sin pista), sin señal que baje ni screamers, con Sanity que baja lento, 1 video de cuota y el susto guionado con el chat de Gonzalo, que se mueven desde la noche 1.

La prueba del susto guionado (`test_screamer_manager.gd`) y la captura del Plan 7 (`capture_screamers.gd`) pasan a la noche 0.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
		check_eq(night.scripted_scare_time, 60.0 if night.number == 1 else 0.0, who + ": susto guionado")
	check_eq(catalog.nights[0].scripted_scare, ScareKind.Kind.JUMPSCARE, "el susto guionado es un jumpscare")
```

por:

```gdscript
		check_eq(night.scripted_scare_time, 0.0, who + ": el susto guionado va en la noche 0")
	check_eq(catalog.tutorial.scripted_scare, ScareKind.Kind.JUMPSCARE, "el susto guionado es un jumpscare")
```

En `test/test_catalog.gd`, reemplazar:

```gdscript
func test_el_trauco_aparece_la_noche_3() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var trauco: EntityData = load("res://data/entities/trauco.tres")
	check(not catalog.known_entities(2).has(trauco), "no aparece antes de la noche 3")
	check(catalog.known_entities(3).has(trauco), "aparece la noche 3")
```

por:

```gdscript
## Las 7 entidades y la noche en que aparecen (diseño §13).
func test_las_7_entidades_y_su_noche() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var expected := [[&"tue_tue", &"calchona"], [&"cuero", &"viuda"], [&"trauco"], [&"basilisco", &"imbunche"], []]
	for index in catalog.nights.size():
		var ids := catalog.nights[index].new_entities.map(func(entity: EntityData) -> StringName: return entity.id)
		check_eq(ids, expected[index], "noche %d" % (index + 1))
	check_eq(catalog.all_entities().size(), 7, "7 entidades")
	return true


## Las características de cada entidad salen en 2 preguntas distintas o más: así, identificarla nunca cuesta
## una sola pregunta (decisión de Benja, 3-nov).
func test_las_caracteristicas_de_cada_entidad_salen_en_2_preguntas() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for entity: EntityData in catalog.all_entities():
		var categories := {}
		for trait_data: TraitData in entity.traits:
			categories[trait_data.category] = true
		check(categories.size() >= 2, "'%s' tiene todas sus características en una sola categoría" % entity.id)
	return true


## La noche 0, el tutorial (decisión de Benja): 3 solicitudes fijas, una de cada amigo, con El Tue Tué y La
## Calchona; un video, y el susto guionado con el chat de Gonzalo, que enseña el celular.
func test_el_tutorial() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	var tutorial := catalog.tutorial
	check(tutorial != null, "existe")
	if tutorial == null:
		return true
	check_eq(tutorial.number, 0, "es la noche 0")
	check_eq(tutorial.tutorial_requests.size(), 3, "3 solicitudes")
	var friends := tutorial.tutorial_requests.map(func(data: TutorialRequestData) -> StringName: return data.friend.id)
	check_eq(friends, [&"leon", &"agustin", &"gonzalo"], "una de cada amigo")
	var videos := tutorial.tutorial_requests.filter(func(data: TutorialRequestData) -> bool: return data.sends_video)
	check_eq(videos.size(), 1, "un video")
	check_eq(tutorial.content_quota, 1, "su cuota")
	check(tutorial.scripted_scare_time > 0.0, "el susto guionado")
	check(tutorial.scripted_chat != null and tutorial.scripted_chat.highlight_phone, "su chat enseña el celular")
	check_eq(catalog.known_entities(0), catalog.known_entities(1), "las páginas de la noche 1")
```

En `test/test_chat_script.gd`, reemplazar:

```gdscript
func test_la_noche_1_tiene_el_chat_del_susto() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var chat := catalog.nights[0].scripted_chat
	check(chat != null, "la noche 1 tiene un chat guionado")
```

por:

```gdscript
func test_la_noche_0_tiene_el_chat_del_susto() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check(catalog.tutorial != null, "existe la noche 0")
	if catalog.tutorial == null:
		return true
	var chat := catalog.tutorial.scripted_chat
	check(chat != null, "la noche 0 tiene un chat guionado")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	var desk := _make_desk(1)
```

por:

```gdscript
	var desk := _make_desk(0)
	# Sin las solicitudes del tutorial: el susto guionado las espera.
	desk.get_node("RequestManager").tutorial_queue.clear()
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	# A los 60 s, sin solicitudes: la señal previa y, 1 s después, el jumpscare.
	_play(desk, 61)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "el susto guionado de la noche 1")
```

por:

```gdscript
	# A los 5 s, sin nada pendiente: la señal previa y, 1 s después, el jumpscare.
	_play(desk, 6)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "el susto guionado de la noche 0")
```

En `test/test_trauco.gd`, reemplazar:

```gdscript
## Las reglas del ejemplo de docs/02 §8.
func test_reglas_del_ejemplo() -> bool:
```

por:

```gdscript
## Las reglas de la propuesta de docs/09: si el Trauco lo vio primero, mirar al suelo; con el bastón, hablar fuerte;
## en el barro, seguirlo (el giro); y si no, tirarle arena.
func test_reglas_de_la_propuesta() -> bool:
```

En `test/test_trauco.gd`, reemplazar:

```gdscript
	_check_rule(entity, {&"saw_first": &"friend", &"axe_in_hand": &"yes", &"chopping_sounds": &"yes"},
			&"stare", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"yes", &"chopping_sounds": &"no"},
			&"turn_back", &"stare")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"yes"},
			&"hide_behind_tree", &"follow_closely")
	_check_rule(entity, {&"saw_first": &"trauco", &"axe_in_hand": &"no", &"chopping_sounds": &"no"},
			&"turn_back", &"follow_closely")
```

por:

```gdscript
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"muddy"},
			&"look_down", &"follow_to_tree")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"cane", &"ground": &"muddy"},
			&"talk_loud", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"axe", &"ground": &"muddy"},
			&"follow_to_tree", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"axe", &"ground": &"dry"},
			&"throw_sand", &"follow_to_tree")
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `397 pruebas OK, 6 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/catalog.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/phone_post_data.gd" id="14_post"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/phone_post_data.gd" id="14_post"]
[ext_resource type="Resource" path="res://data/nights/night_0.tres" id="15_night_0"]
```

En `data/catalog.tres`, reemplazar:

```text
text_key = "DECOY_CREAKING_BRANCHES"
place_keys = Array[String](["PLACE_FOREST"])
```

por:

```text
text_key = "DECOY_CREAKING_BRANCHES"
place_keys = Array[String](["PLACE_FOREST"])

[sub_resource type="Resource" id="Decoy_hanging_laundry"]
script = ExtResource("12_decoy")
id = &"hanging_laundry"
text_key = "DECOY_HANGING_LAUNDRY"
place_keys = Array[String](["PLACE_YARD"])

[sub_resource type="Resource" id="Decoy_barbed_fence"]
script = ExtResource("12_decoy")
id = &"barbed_fence"
text_key = "DECOY_BARBED_FENCE"
place_keys = Array[String](["PLACE_DIRT_ROAD", "PLACE_PASTURE"])

[sub_resource type="Resource" id="Decoy_lapping_water"]
script = ExtResource("12_decoy")
id = &"lapping_water"
category = 1
text_key = "DECOY_LAPPING_WATER"
place_keys = Array[String](["PLACE_LAKE_SHORE", "PLACE_DOCK", "PLACE_BRIDGE"])

[sub_resource type="Resource" id="Decoy_creaking_door"]
script = ExtResource("12_decoy")
id = &"creaking_door"
category = 1
text_key = "DECOY_CREAKING_DOOR"
place_keys = Array[String](["PLACE_ABANDONED_HOUSE", "PLACE_HENHOUSE"])

[sub_resource type="Resource" id="Decoy_dripping_water"]
script = ExtResource("12_decoy")
id = &"dripping_water"
category = 1
text_key = "DECOY_DRIPPING_WATER"
place_keys = Array[String](["PLACE_CAVE", "PLACE_CLIFF"])

[sub_resource type="Resource" id="Decoy_dog_prints"]
script = ExtResource("12_decoy")
id = &"dog_prints"
category = 3
text_key = "DECOY_DOG_PRINTS"

[sub_resource type="Resource" id="Decoy_smoke_smell"]
script = ExtResource("12_decoy")
id = &"smoke_smell"
category = 2
text_key = "DECOY_SMOKE_SMELL"
```

En `data/catalog.tres`, reemplazar:

```text
decoys = Array[ExtResource("12_decoy")]([SubResource("Decoy_cold_breath"), SubResource("Decoy_distant_dog"), SubResource("Decoy_flickering_light"), SubResource("Decoy_wet_grass"), SubResource("Decoy_trunk_moss"), SubResource("Decoy_creaking_branches")])
```

por:

```text
decoys = Array[ExtResource("12_decoy")]([SubResource("Decoy_cold_breath"), SubResource("Decoy_distant_dog"), SubResource("Decoy_flickering_light"), SubResource("Decoy_wet_grass"), SubResource("Decoy_trunk_moss"), SubResource("Decoy_creaking_branches"), SubResource("Decoy_hanging_laundry"), SubResource("Decoy_barbed_fence"), SubResource("Decoy_lapping_water"), SubResource("Decoy_creaking_door"), SubResource("Decoy_dripping_water"), SubResource("Decoy_dog_prints"), SubResource("Decoy_smoke_smell")])
tutorial = ExtResource("15_night_0")
```

`data/entities/basilisco.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_crow_underfloor"]
script = ExtResource("2_trait")
id = &"crow_underfloor"
category = 1
text_key = "TRAIT_CROW_UNDERFLOOR"

[sub_resource type="Resource" id="Trait_shed_skin"]
script = ExtResource("2_trait")
id = &"shed_skin"
category = 3
text_key = "TRAIT_SHED_SKIN"

[sub_resource type="Resource" id="Trait_stale_air"]
script = ExtResource("2_trait")
id = &"stale_air"
category = 2
text_key = "TRAIT_STALE_AIR"

[sub_resource type="Resource" id="Action_burn_egg"]
script = ExtResource("3_action")
id = &"burn_egg"
label_key = "ACTION_BASILISCO_BURN_EGG"

[sub_resource type="Resource" id="Action_leave_house"]
script = ExtResource("3_action")
id = &"leave_house"
label_key = "ACTION_BASILISCO_LEAVE_HOUSE"

[sub_resource type="Resource" id="Action_cover_mouth"]
script = ExtResource("3_action")
id = &"cover_mouth"
label_key = "ACTION_BASILISCO_COVER_MOUTH"

[sub_resource type="Resource" id="Action_lift_board"]
script = ExtResource("3_action")
id = &"lift_board"
label_key = "ACTION_BASILISCO_LIFT_BOARD"

[sub_resource type="Resource" id="Observation_egg"]
script = ExtResource("4_observation")
id = &"egg"
question_key = "OBS_BASILISCO_EGG_Q"
values = Dictionary[StringName, String]({
&"small": "OBS_BASILISCO_EGG_SMALL",
&"none": "OBS_BASILISCO_EGG_NONE"
})

[sub_resource type="Resource" id="Observation_floor"]
script = ExtResource("4_observation")
id = &"floor"
question_key = "OBS_BASILISCO_FLOOR_Q"
values = Dictionary[StringName, String]({
&"raised": "OBS_BASILISCO_FLOOR_RAISED",
&"intact": "OBS_BASILISCO_FLOOR_INTACT"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"egg": &"small"
})
correct_action_id = &"burn_egg"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"floor": &"raised"
})
correct_action_id = &"leave_house"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_2"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"cover_mouth"
risky_action_id = &"burn_egg"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"basilisco"
name_key = "ENTITY_BASILISCO_NAME"
lore_key = "ENTITY_BASILISCO_LORE"
place_keys = Array[String](["PLACE_ABANDONED_HOUSE", "PLACE_HENHOUSE"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_crow_underfloor"), SubResource("Trait_shed_skin"), SubResource("Trait_stale_air")])
actions = Array[ExtResource("3_action")]([SubResource("Action_burn_egg"), SubResource("Action_leave_house"), SubResource("Action_cover_mouth"), SubResource("Action_lift_board")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_egg"), SubResource("Observation_floor")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

`data/entities/calchona.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_lone_bleat"]
script = ExtResource("2_trait")
id = &"lone_bleat"
category = 1
text_key = "TRAIT_LONE_BLEAT"

[sub_resource type="Resource" id="Trait_long_tangled_hair"]
script = ExtResource("2_trait")
id = &"long_tangled_hair"
text_key = "TRAIT_LONG_TANGLED_HAIR"

[sub_resource type="Resource" id="Trait_ointment_smell"]
script = ExtResource("2_trait")
id = &"ointment_smell"
category = 2
text_key = "TRAIT_OINTMENT_SMELL"

[sub_resource type="Resource" id="Trait_snagged_threads"]
script = ExtResource("2_trait")
id = &"snagged_threads"
category = 3
text_key = "TRAIT_SNAGGED_THREADS"

[sub_resource type="Resource" id="Action_leave_food"]
script = ExtResource("3_action")
id = &"leave_food"
label_key = "ACTION_CALCHONA_LEAVE_FOOD"

[sub_resource type="Resource" id="Action_back_away"]
script = ExtResource("3_action")
id = &"back_away"
label_key = "ACTION_CALCHONA_BACK_AWAY"

[sub_resource type="Resource" id="Action_walk_past"]
script = ExtResource("3_action")
id = &"walk_past"
label_key = "ACTION_CALCHONA_WALK_PAST"

[sub_resource type="Resource" id="Action_see_her_face"]
script = ExtResource("3_action")
id = &"see_her_face"
label_key = "ACTION_CALCHONA_SEE_HER_FACE"

[sub_resource type="Resource" id="Observation_bleat_tone"]
script = ExtResource("4_observation")
id = &"bleat_tone"
category = 1
question_key = "OBS_CALCHONA_BLEAT_TONE_Q"
values = Dictionary[StringName, String]({
&"weeping": "OBS_CALCHONA_BLEAT_TONE_WEEPING",
&"snorting": "OBS_CALCHONA_BLEAT_TONE_SNORTING"
})

[sub_resource type="Resource" id="Observation_approaching"]
script = ExtResource("4_observation")
id = &"approaching"
question_key = "OBS_CALCHONA_APPROACHING_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_CALCHONA_APPROACHING_YES",
&"no": "OBS_CALCHONA_APPROACHING_NO"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"bleat_tone": &"snorting",
&"approaching": &"yes"
})
correct_action_id = &"back_away"
risky_action_id = &"see_her_face"
text_key = "RULE_CALCHONA_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"bleat_tone": &"weeping"
})
correct_action_id = &"leave_food"
risky_action_id = &"see_her_face"
text_key = "RULE_CALCHONA_2"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"walk_past"
risky_action_id = &"leave_food"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"calchona"
name_key = "ENTITY_CALCHONA_NAME"
lore_key = "ENTITY_CALCHONA_LORE"
place_keys = Array[String](["PLACE_DIRT_ROAD", "PLACE_PASTURE"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_lone_bleat"), SubResource("Trait_long_tangled_hair"), SubResource("Trait_ointment_smell"), SubResource("Trait_snagged_threads")])
actions = Array[ExtResource("3_action")]([SubResource("Action_leave_food"), SubResource("Action_back_away"), SubResource("Action_walk_past"), SubResource("Action_see_her_face")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_bleat_tone"), SubResource("Observation_approaching")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

`data/entities/cuero.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_floating_hide"]
script = ExtResource("2_trait")
id = &"floating_hide"
text_key = "TRAIT_FLOATING_HIDE"

[sub_resource type="Resource" id="Trait_icy_mist"]
script = ExtResource("2_trait")
id = &"icy_mist"
category = 2
text_key = "TRAIT_ICY_MIST"

[sub_resource type="Resource" id="Trait_drag_marks"]
script = ExtResource("2_trait")
id = &"drag_marks"
category = 3
text_key = "TRAIT_DRAG_MARKS"

[sub_resource type="Resource" id="Action_throw_thorns"]
script = ExtResource("3_action")
id = &"throw_thorns"
label_key = "ACTION_CUERO_THROW_THORNS"

[sub_resource type="Resource" id="Action_stay_still"]
script = ExtResource("3_action")
id = &"stay_still"
label_key = "ACTION_CUERO_STAY_STILL"

[sub_resource type="Resource" id="Action_leave_shore"]
script = ExtResource("3_action")
id = &"leave_shore"
label_key = "ACTION_CUERO_LEAVE_SHORE"

[sub_resource type="Resource" id="Action_poke_hide"]
script = ExtResource("3_action")
id = &"poke_hide"
label_key = "ACTION_CUERO_POKE_HIDE"

[sub_resource type="Resource" id="Observation_position"]
script = ExtResource("4_observation")
id = &"position"
question_key = "OBS_CUERO_POSITION_Q"
values = Dictionary[StringName, String]({
&"on_shore": "OBS_CUERO_POSITION_ON_SHORE",
&"in_water": "OBS_CUERO_POSITION_IN_WATER"
})

[sub_resource type="Resource" id="Observation_whistle"]
script = ExtResource("4_observation")
id = &"whistle"
category = 1
question_key = "OBS_CUERO_WHISTLE_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_CUERO_WHISTLE_YES",
&"no": "OBS_CUERO_WHISTLE_NO"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"position": &"on_shore"
})
correct_action_id = &"throw_thorns"
risky_action_id = &"poke_hide"
text_key = "RULE_CUERO_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"whistle": &"yes"
})
correct_action_id = &"stay_still"
risky_action_id = &"poke_hide"
text_key = "RULE_CUERO_2"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"leave_shore"
risky_action_id = &"throw_thorns"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"cuero"
name_key = "ENTITY_CUERO_NAME"
lore_key = "ENTITY_CUERO_LORE"
place_keys = Array[String](["PLACE_LAKE_SHORE", "PLACE_DOCK"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_floating_hide"), SubResource("Trait_icy_mist"), SubResource("Trait_drag_marks")])
actions = Array[ExtResource("3_action")]([SubResource("Action_throw_thorns"), SubResource("Action_stay_still"), SubResource("Action_leave_shore"), SubResource("Action_poke_hide")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_position"), SubResource("Observation_whistle")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

`data/entities/imbunche.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_one_leg_hop"]
script = ExtResource("2_trait")
id = &"one_leg_hop"
text_key = "TRAIT_ONE_LEG_HOP"

[sub_resource type="Resource" id="Trait_hoarse_grunts"]
script = ExtResource("2_trait")
id = &"hoarse_grunts"
category = 1
text_key = "TRAIT_HOARSE_GRUNTS"

[sub_resource type="Resource" id="Trait_stale_air"]
script = ExtResource("2_trait")
id = &"stale_air"
category = 2
text_key = "TRAIT_STALE_AIR"

[sub_resource type="Resource" id="Action_back_out"]
script = ExtResource("3_action")
id = &"back_out"
label_key = "ACTION_IMBUNCHE_BACK_OUT"

[sub_resource type="Resource" id="Action_stay_outside"]
script = ExtResource("3_action")
id = &"stay_outside"
label_key = "ACTION_IMBUNCHE_STAY_OUTSIDE"

[sub_resource type="Resource" id="Action_offer_bread"]
script = ExtResource("3_action")
id = &"offer_bread"
label_key = "ACTION_IMBUNCHE_OFFER_BREAD"

[sub_resource type="Resource" id="Action_go_deeper"]
script = ExtResource("3_action")
id = &"go_deeper"
label_key = "ACTION_IMBUNCHE_GO_DEEPER"

[sub_resource type="Resource" id="Observation_called_name"]
script = ExtResource("4_observation")
id = &"called_name"
category = 1
question_key = "OBS_IMBUNCHE_CALLED_NAME_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_IMBUNCHE_CALLED_NAME_YES",
&"no": "OBS_IMBUNCHE_CALLED_NAME_NO"
})

[sub_resource type="Resource" id="Observation_torches"]
script = ExtResource("4_observation")
id = &"torches"
question_key = "OBS_IMBUNCHE_TORCHES_Q"
values = Dictionary[StringName, String]({
&"lit": "OBS_IMBUNCHE_TORCHES_LIT",
&"dark": "OBS_IMBUNCHE_TORCHES_DARK"
})

[sub_resource type="Resource" id="Observation_entrance"]
script = ExtResource("4_observation")
id = &"entrance"
category = 3
question_key = "OBS_IMBUNCHE_ENTRANCE_Q"
values = Dictionary[StringName, String]({
&"blocked": "OBS_IMBUNCHE_ENTRANCE_BLOCKED",
&"open": "OBS_IMBUNCHE_ENTRANCE_OPEN"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"called_name": &"yes"
})
correct_action_id = &"back_out"
risky_action_id = &"go_deeper"
text_key = "RULE_IMBUNCHE_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"torches": &"lit"
})
correct_action_id = &"stay_outside"
risky_action_id = &"go_deeper"
text_key = "RULE_IMBUNCHE_2"

[sub_resource type="Resource" id="Rule_3"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"entrance": &"blocked"
})
correct_action_id = &"back_out"
risky_action_id = &"offer_bread"
text_key = "RULE_IMBUNCHE_3"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"offer_bread"
risky_action_id = &"go_deeper"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"imbunche"
name_key = "ENTITY_IMBUNCHE_NAME"
lore_key = "ENTITY_IMBUNCHE_LORE"
place_keys = Array[String](["PLACE_CAVE", "PLACE_CLIFF"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_one_leg_hop"), SubResource("Trait_hoarse_grunts"), SubResource("Trait_stale_air")])
actions = Array[ExtResource("3_action")]([SubResource("Action_back_out"), SubResource("Action_stay_outside"), SubResource("Action_offer_bread"), SubResource("Action_go_deeper")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_called_name"), SubResource("Observation_torches"), SubResource("Observation_entrance")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_3"), SubResource("Rule_otherwise")])
```

En `data/entities/trauco.tres`, reemplazar:

```text
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
```

por:

```text
text_key = "TRAIT_LITTLE_MAN"

[sub_resource type="Resource" id="Trait_three_blows"]
script = ExtResource("2_trait")
id = &"three_blows"
category = 1
text_key = "TRAIT_THREE_BLOWS"

[sub_resource type="Resource" id="Trait_snagged_threads"]
script = ExtResource("2_trait")
id = &"snagged_threads"
category = 3
text_key = "TRAIT_SNAGGED_THREADS"

[sub_resource type="Resource" id="Action_look_down"]
script = ExtResource("3_action")
id = &"look_down"
label_key = "ACTION_TRAUCO_LOOK_DOWN"

[sub_resource type="Resource" id="Action_talk_loud"]
script = ExtResource("3_action")
id = &"talk_loud"
label_key = "ACTION_TRAUCO_TALK_LOUD"

[sub_resource type="Resource" id="Action_throw_sand"]
script = ExtResource("3_action")
id = &"throw_sand"
label_key = "ACTION_TRAUCO_THROW_SAND"

[sub_resource type="Resource" id="Action_follow_to_tree"]
script = ExtResource("3_action")
id = &"follow_to_tree"
label_key = "ACTION_TRAUCO_FOLLOW_TO_TREE"
```

En `data/entities/trauco.tres`, reemplazar:

```text
category = 0
question_key = "OBS_TRAUCO_SAW_FIRST_Q"
```

por:

```text
question_key = "OBS_TRAUCO_SAW_FIRST_Q"
```

En `data/entities/trauco.tres`, reemplazar:

```text
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
```

por:

```text
[sub_resource type="Resource" id="Observation_in_hand"]
script = ExtResource("4_observation")
id = &"in_hand"
question_key = "OBS_TRAUCO_IN_HAND_Q"
values = Dictionary[StringName, String]({
&"axe": "OBS_TRAUCO_IN_HAND_AXE",
&"cane": "OBS_TRAUCO_IN_HAND_CANE"
})

[sub_resource type="Resource" id="Observation_ground"]
script = ExtResource("4_observation")
id = &"ground"
category = 3
question_key = "OBS_TRAUCO_GROUND_Q"
values = Dictionary[StringName, String]({
&"muddy": "OBS_TRAUCO_GROUND_MUDDY",
&"dry": "OBS_TRAUCO_GROUND_DRY"
```

En `data/entities/trauco.tres`, reemplazar:

```text
&"saw_first": &"friend"
})
correct_action_id = &"stare"
risky_action_id = &"follow_closely"
```

por:

```text
&"saw_first": &"trauco"
})
correct_action_id = &"look_down"
risky_action_id = &"follow_to_tree"
```

En `data/entities/trauco.tres`, reemplazar:

```text
&"saw_first": &"trauco",
&"axe_in_hand": &"yes"
})
correct_action_id = &"turn_back"
risky_action_id = &"stare"
```

por:

```text
&"in_hand": &"cane"
})
correct_action_id = &"talk_loud"
risky_action_id = &"throw_sand"
```

En `data/entities/trauco.tres`, reemplazar:

```text
&"chopping_sounds": &"yes"
})
correct_action_id = &"hide_behind_tree"
risky_action_id = &"follow_closely"
```

por:

```text
&"ground": &"muddy"
})
correct_action_id = &"follow_to_tree"
risky_action_id = &"throw_sand"
```

En `data/entities/trauco.tres`, reemplazar:

```text
correct_action_id = &"turn_back"
risky_action_id = &"follow_closely"
```

por:

```text
correct_action_id = &"throw_sand"
risky_action_id = &"follow_to_tree"
```

En `data/entities/trauco.tres`, reemplazar:

```text
place_keys = Array[String](["PLACE_FOREST"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_little_man"), SubResource("Trait_plant_fiber_clothes"), SubResource("Trait_damp_forest_smell")])
actions = Array[ExtResource("3_action")]([SubResource("Action_stare"), SubResource("Action_turn_back"), SubResource("Action_hide_behind_tree"), SubResource("Action_follow_closely")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_saw_first"), SubResource("Observation_axe_in_hand"), SubResource("Observation_chopping_sounds")])
```

por:

```text
place_keys = Array[String](["PLACE_FOREST", "PLACE_CLEARING"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_little_man"), SubResource("Trait_three_blows"), SubResource("Trait_snagged_threads")])
actions = Array[ExtResource("3_action")]([SubResource("Action_look_down"), SubResource("Action_talk_loud"), SubResource("Action_throw_sand"), SubResource("Action_follow_to_tree")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_saw_first"), SubResource("Observation_in_hand"), SubResource("Observation_ground")])
```

`data/entities/tue_tue.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_bird_with_face"]
script = ExtResource("2_trait")
id = &"bird_with_face"
text_key = "TRAIT_BIRD_WITH_FACE"

[sub_resource type="Resource" id="Trait_two_note_cry"]
script = ExtResource("2_trait")
id = &"two_note_cry"
category = 1
text_key = "TRAIT_TWO_NOTE_CRY"

[sub_resource type="Resource" id="Trait_ointment_smell"]
script = ExtResource("2_trait")
id = &"ointment_smell"
category = 2
text_key = "TRAIT_OINTMENT_SMELL"

[sub_resource type="Resource" id="Action_cross_scissors"]
script = ExtResource("3_action")
id = &"cross_scissors"
label_key = "ACTION_TUE_TUE_CROSS_SCISSORS"

[sub_resource type="Resource" id="Action_stay_silent"]
script = ExtResource("3_action")
id = &"stay_silent"
label_key = "ACTION_TUE_TUE_STAY_SILENT"

[sub_resource type="Resource" id="Action_offer_salt"]
script = ExtResource("3_action")
id = &"offer_salt"
label_key = "ACTION_TUE_TUE_OFFER_SALT"

[sub_resource type="Resource" id="Action_mimic_cry"]
script = ExtResource("3_action")
id = &"mimic_cry"
label_key = "ACTION_TUE_TUE_MIMIC_CRY"

[sub_resource type="Resource" id="Observation_circling"]
script = ExtResource("4_observation")
id = &"circling"
question_key = "OBS_TUE_TUE_CIRCLING_Q"
values = Dictionary[StringName, String]({
&"over_house": "OBS_TUE_TUE_CIRCLING_OVER_HOUSE",
&"passing": "OBS_TUE_TUE_CIRCLING_PASSING"
})

[sub_resource type="Resource" id="Observation_cried_three_times"]
script = ExtResource("4_observation")
id = &"cried_three_times"
category = 1
question_key = "OBS_TUE_TUE_CRIED_THREE_TIMES_Q"
values = Dictionary[StringName, String]({
&"yes": "OBS_TUE_TUE_CRIED_THREE_TIMES_YES",
&"no": "OBS_TUE_TUE_CRIED_THREE_TIMES_NO"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"circling": &"over_house"
})
correct_action_id = &"cross_scissors"
risky_action_id = &"mimic_cry"
text_key = "RULE_TUE_TUE_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"cried_three_times": &"yes"
})
correct_action_id = &"stay_silent"
risky_action_id = &"offer_salt"
text_key = "RULE_TUE_TUE_2"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"offer_salt"
risky_action_id = &"mimic_cry"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"tue_tue"
name_key = "ENTITY_TUE_TUE_NAME"
lore_key = "ENTITY_TUE_TUE_LORE"
place_keys = Array[String](["PLACE_YARD", "PLACE_WOODSHED"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_bird_with_face"), SubResource("Trait_two_note_cry"), SubResource("Trait_ointment_smell")])
actions = Array[ExtResource("3_action")]([SubResource("Action_cross_scissors"), SubResource("Action_stay_silent"), SubResource("Action_offer_salt"), SubResource("Action_mimic_cry")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_circling"), SubResource("Observation_cried_three_times")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

`data/entities/viuda.tres`:

```text
[gd_resource type="Resource" script_class="EntityData" format=3]

[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="1_entity"]
[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="2_trait"]
[ext_resource type="Script" path="res://scripts/data/action_data.gd" id="3_action"]
[ext_resource type="Script" path="res://scripts/data/observation_data.gd" id="4_observation"]
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]

[sub_resource type="Resource" id="Trait_black_veil"]
script = ExtResource("2_trait")
id = &"black_veil"
text_key = "TRAIT_BLACK_VEIL"

[sub_resource type="Resource" id="Trait_heel_steps"]
script = ExtResource("2_trait")
id = &"heel_steps"
category = 1
text_key = "TRAIT_HEEL_STEPS"

[sub_resource type="Resource" id="Trait_icy_mist"]
script = ExtResource("2_trait")
id = &"icy_mist"
category = 2
text_key = "TRAIT_ICY_MIST"

[sub_resource type="Resource" id="Action_pray"]
script = ExtResource("3_action")
id = &"pray"
label_key = "ACTION_VIUDA_PRAY"

[sub_resource type="Resource" id="Action_keep_walking"]
script = ExtResource("3_action")
id = &"keep_walking"
label_key = "ACTION_VIUDA_KEEP_WALKING"

[sub_resource type="Resource" id="Action_greet"]
script = ExtResource("3_action")
id = &"greet"
label_key = "ACTION_VIUDA_GREET"

[sub_resource type="Resource" id="Action_carry_her"]
script = ExtResource("3_action")
id = &"carry_her"
label_key = "ACTION_VIUDA_CARRY_HER"

[sub_resource type="Resource" id="Observation_request"]
script = ExtResource("4_observation")
id = &"request"
category = 1
question_key = "OBS_VIUDA_REQUEST_Q"
values = Dictionary[StringName, String]({
&"cross": "OBS_VIUDA_REQUEST_CROSS",
&"nothing": "OBS_VIUDA_REQUEST_NOTHING"
})

[sub_resource type="Resource" id="Observation_footprints"]
script = ExtResource("4_observation")
id = &"footprints"
category = 3
question_key = "OBS_VIUDA_FOOTPRINTS_Q"
values = Dictionary[StringName, String]({
&"none": "OBS_VIUDA_FOOTPRINTS_NONE",
&"normal": "OBS_VIUDA_FOOTPRINTS_NORMAL"
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"request": &"cross"
})
correct_action_id = &"keep_walking"
risky_action_id = &"carry_her"
text_key = "RULE_VIUDA_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"footprints": &"none"
})
correct_action_id = &"pray"
risky_action_id = &"greet"
text_key = "RULE_VIUDA_2"

[sub_resource type="Resource" id="Rule_otherwise"]
script = ExtResource("5_rule")
correct_action_id = &"greet"
risky_action_id = &"carry_her"
text_key = "RULE_OTHERWISE"

[resource]
script = ExtResource("1_entity")
id = &"viuda"
name_key = "ENTITY_VIUDA_NAME"
lore_key = "ENTITY_VIUDA_LORE"
place_keys = Array[String](["PLACE_DIRT_ROAD", "PLACE_BRIDGE"])
traits = Array[ExtResource("2_trait")]([SubResource("Trait_black_veil"), SubResource("Trait_heel_steps"), SubResource("Trait_icy_mist")])
actions = Array[ExtResource("3_action")]([SubResource("Action_pray"), SubResource("Action_keep_walking"), SubResource("Action_greet"), SubResource("Action_carry_her")])
observations = Array[ExtResource("4_observation")]([SubResource("Observation_request"), SubResource("Observation_footprints")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

`data/nights/night_0.tres`:

```text
[gd_resource type="Resource" script_class="NightData" format=3]

[ext_resource type="Script" path="res://scripts/data/night_data.gd" id="1_night"]
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
[ext_resource type="Script" path="res://scripts/data/chat_script_data.gd" id="3_chat"]
[ext_resource type="Script" path="res://scripts/data/chat_line_data.gd" id="4_line"]
[ext_resource type="Resource" path="res://data/friends/gonzalo.tres" id="5_gonzalo"]
[ext_resource type="Script" path="res://scripts/data/tutorial_request_data.gd" id="6_tutorial"]
[ext_resource type="Resource" path="res://data/friends/leon.tres" id="7_leon"]
[ext_resource type="Resource" path="res://data/friends/agustin.tres" id="8_agustin"]
[ext_resource type="Resource" path="res://data/entities/tue_tue.tres" id="9_tue_tue"]
[ext_resource type="Resource" path="res://data/entities/calchona.tres" id="10_calchona"]

[sub_resource type="Resource" id="Line_ask"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_ASK"

[sub_resource type="Resource" id="Line_reply"]
script = ExtResource("4_line")
speaker = 1
text_key = "SCRIPT_SCARE_REPLY"

[sub_resource type="Resource" id="Line_phone"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_PHONE"

[sub_resource type="Resource" id="Chat_scare"]
script = ExtResource("3_chat")
friend = ExtResource("5_gonzalo")
lines = Array[ExtResource("4_line")]([SubResource("Line_ask"), SubResource("Line_reply"), SubResource("Line_phone")])
highlight_phone = true

[sub_resource type="Resource" id="Tutorial_1"]
script = ExtResource("6_tutorial")
friend = ExtResource("7_leon")
entity = ExtResource("9_tue_tue")
situation = Dictionary[StringName, StringName]({
&"circling": &"over_house",
&"cried_three_times": &"no"
})

[sub_resource type="Resource" id="Tutorial_2"]
script = ExtResource("6_tutorial")
friend = ExtResource("8_agustin")
entity = ExtResource("10_calchona")
situation = Dictionary[StringName, StringName]({
&"bleat_tone": &"weeping",
&"approaching": &"no"
})
sends_video = true

[sub_resource type="Resource" id="Tutorial_3"]
script = ExtResource("6_tutorial")
friend = ExtResource("5_gonzalo")
entity = ExtResource("9_tue_tue")
situation = Dictionary[StringName, StringName]({
&"circling": &"passing",
&"cried_three_times": &"yes"
})
with_hint = false

[resource]
script = ExtResource("1_night")
number = 0
place_key = "NIGHT_0_PLACE"
new_entities = Array[ExtResource("2_entity")]([])
requests_total = 0
max_simultaneous = 1
base_decision_time = 90.0
first_hint_chance = 1.0
decoys_per_request = 1
wave_size = 1
signal_decays = false
interference_count = 0
audio_sync_beats = 0
sanity_drain_interval = 20.0
content_quota = 1
scare_count = 0
has_jumpscare = false
scripted_scare_time = 5.0
scripted_chat = SubResource("Chat_scare")
tutorial_requests = Array[ExtResource("6_tutorial")]([SubResource("Tutorial_1"), SubResource("Tutorial_2"), SubResource("Tutorial_3")])
```

En `data/nights/night_1.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/chat_script_data.gd" id="3_chat"]
[ext_resource type="Script" path="res://scripts/data/chat_line_data.gd" id="4_line"]
[ext_resource type="Resource" path="res://data/friends/gonzalo.tres" id="5_gonzalo"]

[sub_resource type="Resource" id="Line_ask"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_ASK"

[sub_resource type="Resource" id="Line_reply"]
script = ExtResource("4_line")
speaker = 1
text_key = "SCRIPT_SCARE_REPLY"

[sub_resource type="Resource" id="Line_phone"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_PHONE"

[sub_resource type="Resource" id="Chat_scare"]
script = ExtResource("3_chat")
friend = ExtResource("5_gonzalo")
lines = Array[ExtResource("4_line")]([SubResource("Line_ask"), SubResource("Line_reply"), SubResource("Line_phone")])
highlight_phone = true
```

por:

```text
[ext_resource type="Resource" path="res://data/entities/tue_tue.tres" id="3_tue_tue"]
[ext_resource type="Resource" path="res://data/entities/calchona.tres" id="4_calchona"]
```

En `data/nights/night_1.tres`, reemplazar:

```text
new_entities = Array[ExtResource("2_entity")]([])
```

por:

```text
new_entities = Array[ExtResource("2_entity")]([ExtResource("3_tue_tue"), ExtResource("4_calchona")])
```

En `data/nights/night_1.tres`, reemplazar:

```text
has_jumpscare = false
scripted_scare_time = 60.0
scripted_chat = SubResource("Chat_scare")
```

por:

```text
has_jumpscare = false
```

En `data/nights/night_2.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
[ext_resource type="Resource" path="res://data/entities/cuero.tres" id="3_cuero"]
[ext_resource type="Resource" path="res://data/entities/viuda.tres" id="4_viuda"]
```

En `data/nights/night_2.tres`, reemplazar:

```text
new_entities = Array[ExtResource("2_entity")]([])
```

por:

```text
new_entities = Array[ExtResource("2_entity")]([ExtResource("3_cuero"), ExtResource("4_viuda")])
```

En `data/nights/night_4.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
[ext_resource type="Resource" path="res://data/entities/basilisco.tres" id="3_basilisco"]
[ext_resource type="Resource" path="res://data/entities/imbunche.tres" id="4_imbunche"]
```

En `data/nights/night_4.tres`, reemplazar:

```text
new_entities = Array[ExtResource("2_entity")]([])
```

por:

```text
new_entities = Array[ExtResource("2_entity")]([ExtResource("3_basilisco"), ExtResource("4_imbunche")])
```

En `data/text/messages.csv`, reemplazar:

```csv
TRAIT_LITTLE_MAN,Hay un *hombrecito* entre los árboles.,
TRAIT_PLANT_FIBER_CLOTHES,"Hay alguien con *ropa de fibra vegetal*, como de paja.",
TRAIT_DAMP_FOREST_SMELL,Todo *huele a bosque húmedo*.,
OBS_TRAUCO_SAW_FIRST_FRIEND,Lo vi antes de que me viera.,
OBS_TRAUCO_SAW_FIRST_TRAUCO,Me vio primero. Me está mirando.,
OBS_TRAUCO_AXE_YES,Tiene un hacha de piedra en la mano.,
OBS_TRAUCO_AXE_NO,No tiene nada en las manos.,
OBS_TRAUCO_CHOPPING_YES,Se oyen hachazos.,
OBS_TRAUCO_CHOPPING_NO,"No se oyen hachazos, solo el viento.",
```

por:

```csv
PLACE_YARD,Estoy en el patio de la cabaña.,
PLACE_WOODSHED,Estoy junto a la leñera.,
TRAIT_BIRD_WITH_FACE,Hay un pájaro con *cara de persona*.,
TRAIT_TWO_NOTE_CRY,"Se oye un *grito de dos notas*, como de queltehue.",
TRAIT_OINTMENT_SMELL,Hay un *olor dulzón a ungüento*.,
OBS_TUE_TUE_CIRCLING_OVER_HOUSE,Está dando vueltas sobre la casa del vecino.,
OBS_TUE_TUE_CIRCLING_PASSING,Pasa volando de árbol en árbol.,
OBS_TUE_TUE_CRIED_THREE_TIMES_YES,Gritó tres veces seguidas.,
OBS_TUE_TUE_CRIED_THREE_TIMES_NO,Gritó una vez y se calló.,
PLACE_DIRT_ROAD,Voy por el camino de tierra.,
PLACE_PASTURE,"Estoy en el potrero, cerca de la cabaña.",
TRAIT_LONE_BLEAT,"Hay una *oveja balando sola*, sin rebaño.",
TRAIT_LONG_TANGLED_HAIR,"Tiene *pelo largo y enredado*, como de mujer.",
TRAIT_SNAGGED_THREADS,Hay *hebras enganchadas* en las ramas.,
OBS_CALCHONA_BLEAT_TONE_WEEPING,Bala como si estuviera llorando.,
OBS_CALCHONA_BLEAT_TONE_SNORTING,"Bufa fuerte, como enojada.",
OBS_CALCHONA_APPROACHING_YES,Viene hacia mí.,
OBS_CALCHONA_APPROACHING_NO,Se queda quieta donde está.,
PLACE_LAKE_SHORE,Estoy en la orilla del lago.,
PLACE_DOCK,Estoy en el muelle viejo.,
TRAIT_FLOATING_HIDE,Hay algo como un *cuero de vaca estirado*.,
TRAIT_ICY_MIST,Se levanta una *neblina helada*.,
TRAIT_DRAG_MARKS,Hay *marcas de arrastre* hacia el agua.,
OBS_CUERO_POSITION_ON_SHORE,"Está en la orilla, estirado sobre una piedra.",
OBS_CUERO_POSITION_IN_WATER,Está flotando en el agua.,
OBS_CUERO_WHISTLE_YES,"Se oye un silbido agudo, como si alguien me llamara.",
OBS_CUERO_WHISTLE_NO,No se oye ningún silbido.,
PLACE_BRIDGE,Estoy en el puente del estero.,
TRAIT_BLACK_VEIL,Hay una mujer con un *velo negro* sobre la cara.,
TRAIT_HEEL_STEPS,Se oyen *pasos de tacos* en la tierra.,
OBS_VIUDA_REQUEST_CROSS,Me pidió que la ayude a cruzar el estero.,
OBS_VIUDA_REQUEST_NOTHING,"No me ha dicho nada, solo me mira.",
OBS_VIUDA_FOOTPRINTS_NONE,No deja huellas en el barro.,
OBS_VIUDA_FOOTPRINTS_NORMAL,Deja huellas como cualquier persona.,
PLACE_CLEARING,Estoy en un claro del bosque.,
TRAIT_LITTLE_MAN,Hay un *hombrecito* de menos de un metro.,
TRAIT_THREE_BLOWS,Se oyen *tres golpes secos* y un árbol que cae.,
OBS_TRAUCO_SAW_FIRST_FRIEND,Lo vi antes de que me viera.,
OBS_TRAUCO_SAW_FIRST_TRAUCO,Me vio primero. Me está mirando.,
OBS_TRAUCO_IN_HAND_AXE,Lleva un hacha de piedra.,
OBS_TRAUCO_IN_HAND_CANE,Se apoya en un bastón retorcido.,
OBS_TRAUCO_GROUND_MUDDY,El suelo está todo embarrado.,
OBS_TRAUCO_GROUND_DRY,El suelo está seco.,
PLACE_ABANDONED_HOUSE,Estoy adentro de la casa abandonada.,
PLACE_HENHOUSE,Estoy en el gallinero de la casa abandonada.,
TRAIT_CROW_UNDERFLOOR,Se oye un *canto de gallo bajo el piso*.,
TRAIT_SHED_SKIN,Hay una *piel de culebra mudada* junto a la pared.,
TRAIT_STALE_AIR,El aire está *viciado y pesado*.,
OBS_BASILISCO_EGG_SMALL,Hay un huevo chiquito y arrugado en un rincón.,
OBS_BASILISCO_EGG_NONE,No veo ningún huevo.,
OBS_BASILISCO_FLOOR_RAISED,Hay una tabla del piso levantada.,
OBS_BASILISCO_FLOOR_INTACT,El piso está entero.,
PLACE_CAVE,Estoy en la entrada de la cueva.,
PLACE_CLIFF,"Estoy en el acantilado, sobre la cueva.",
TRAIT_ONE_LEG_HOP,Algo *salta en una sola pierna*.,
TRAIT_HOARSE_GRUNTS,Se oyen *gruñidos roncos*.,
OBS_IMBUNCHE_CALLED_NAME_YES,Entre los gruñidos se oye mi nombre.,
OBS_IMBUNCHE_CALLED_NAME_NO,"Solo gruñe, no se entiende nada.",
OBS_IMBUNCHE_TORCHES_LIT,Al fondo hay antorchas encendidas.,
OBS_IMBUNCHE_TORCHES_DARK,Adentro está todo oscuro.,
OBS_IMBUNCHE_ENTRANCE_BLOCKED,La entrada está tapada con ramas.,
OBS_IMBUNCHE_ENTRANCE_OPEN,La entrada está despejada.,
```

Agregar al final de `data/text/messages.csv`:

```csv
DECOY_HANGING_LAUNDRY,*La ropa tendida* se mueve con el viento.,
DECOY_BARBED_FENCE,Hay un *cerco de alambre de púas*.,
DECOY_LAPPING_WATER,*El agua golpea las piedras*.,
DECOY_CREAKING_DOOR,*Una puerta rechina* con el viento.,
DECOY_DRIPPING_WATER,*Gotea agua* desde arriba.,
DECOY_DOG_PRINTS,Hay *huellas de perro* en el barro.,
DECOY_SMOKE_SMELL,Se siente *olor a humo de leña*.,
```

En `data/text/notebook.csv`, reemplazar:

```csv
ENTITY_TRAUCO_NAME,El Trauco,
ENTITY_TRAUCO_LORE,"Ser pequeño y deforme de los bosques de Chiloé. Viste ropa tejida con fibra vegetal y lleva un hacha de piedra, con la que golpea los árboles. Su mirada puede dejar paralizado a quien se cruza con él.",
ACTION_TRAUCO_STARE,Mirarlo fijo,
ACTION_TRAUCO_TURN_BACK,Darle la espalda,
ACTION_TRAUCO_HIDE_BEHIND_TREE,Esconderse tras un árbol,
ACTION_TRAUCO_FOLLOW_CLOSELY,Seguirlo de cerca,
OBS_TRAUCO_SAW_FIRST_Q,¿Quién vio a quién primero?,
OBS_TRAUCO_AXE_Q,¿Lleva el hacha en la mano?,
OBS_TRAUCO_CHOPPING_Q,¿Se oyen hachazos?,
RULE_TRAUCO_1,Si el amigo lo vio primero,
RULE_TRAUCO_2,Si el Trauco lo vio primero y lleva el hacha,
RULE_TRAUCO_3,Si se oyen hachazos,
```

por:

```csv
ENTITY_TUE_TUE_NAME,El Tue Tué,
ENTITY_TUE_TUE_LORE,"Un brujo que se unta la garganta con un ungüento: su cabeza se desprende y sale a volar de noche, con las orejas como alas y la cara cubierta de plumas. Su grito de dos notas anuncia una muerte. En el campo le ofrecen sal: dicen que al otro día el brujo llega en persona a pedirla.",
ACTION_TUE_TUE_CROSS_SCISSORS,Abrir unas tijeras en cruz,
ACTION_TUE_TUE_STAY_SILENT,Quedarse callado y no mirar arriba,
ACTION_TUE_TUE_OFFER_SALT,Ofrecerle sal,
ACTION_TUE_TUE_MIMIC_CRY,Imitarle el grito,
OBS_TUE_TUE_CIRCLING_Q,¿Da vueltas sobre una casa?,
OBS_TUE_TUE_CRIED_THREE_TIMES_Q,¿Gritó tres veces seguidas?,
RULE_TUE_TUE_1,Si da vueltas sobre una casa,
RULE_TUE_TUE_2,Si gritó tres veces seguidas,
ENTITY_CALCHONA_NAME,La Calchona,
ENTITY_CALCHONA_LORE,"Una mujer del campo que tomaba pociones a escondidas para volverse oveja y salir de noche. Su marido encontró los frascos y los tiró al río: ella quedó para siempre como una oveja negra, con el pelo de mujer. Vaga sola, balando. Dicen que basta con dejarle un plato de comida, pero no perdona a quien se acerca a burlarse.",
ACTION_CALCHONA_LEAVE_FOOD,Dejarle un plato de comida,
ACTION_CALCHONA_BACK_AWAY,Retroceder sin darle la espalda,
ACTION_CALCHONA_WALK_PAST,Seguir de largo sin mirarla,
ACTION_CALCHONA_SEE_HER_FACE,Acercarse a verle la cara,
OBS_CALCHONA_BLEAT_TONE_Q,¿Cómo bala?,
OBS_CALCHONA_APPROACHING_Q,¿Se está acercando?,
RULE_CALCHONA_1,Si bufa y se está acercando,
RULE_CALCHONA_2,Si bala como llorando,
ENTITY_CUERO_NAME,El Cuero,
ENTITY_CUERO_LORE,"Vive en los lagos y pozones. Parece un cuero de vaca estirado, con garras en los bordes y ojos por encima. Sale a secarse en las piedras de la orilla y, si alguien se acerca, lo envuelve y lo arrastra al fondo. Dicen que les teme a las ramas con espinas.",
ACTION_CUERO_THROW_THORNS,Tirarle ramas con espinas,
ACTION_CUERO_STAY_STILL,Quedarse quieto y callado,
ACTION_CUERO_LEAVE_SHORE,Alejarse de la orilla,
ACTION_CUERO_POKE_HIDE,Tocarlo con un palo,
OBS_CUERO_POSITION_Q,¿Dónde está?,
OBS_CUERO_WHISTLE_Q,¿Se oye un silbido?,
RULE_CUERO_1,Si está en la orilla,
RULE_CUERO_2,Si se oye un silbido,
ENTITY_VIUDA_NAME,La Viuda,
ENTITY_VIUDA_LORE,"Una mujer altísima, vestida de negro y con la cara tapada, que se aparece de noche en los caminos solitarios. A veces pide que la ayuden a cruzar un estero, y quien la carga ya no vuelve a ser el mismo. Dicen que se aleja con oraciones.",
ACTION_VIUDA_PRAY,Rezar en voz alta,
ACTION_VIUDA_KEEP_WALKING,Seguir caminando sin mirar atrás,
ACTION_VIUDA_GREET,Saludarla con respeto,
ACTION_VIUDA_CARRY_HER,Ayudarla a cruzar,
OBS_VIUDA_REQUEST_Q,¿Te pidió algo?,
OBS_VIUDA_FOOTPRINTS_Q,¿Deja huellas?,
RULE_VIUDA_1,Si pidió ayuda para cruzar,
RULE_VIUDA_2,Si no deja huellas,
ENTITY_TRAUCO_NAME,El Trauco,
ENTITY_TRAUCO_LORE,"Un hombrecito de los bosques de Chiloé, de menos de un metro, con traje y sombrero de quilineja. Se apoya en un bastón retorcido, y con su hacha de piedra derriba un árbol en tres golpes. Su mirada tuerce la cara de quien la recibe. Nunca actúa frente a testigos, y si le tiras arena se queda contando los granos.",
ACTION_TRAUCO_LOOK_DOWN,"Mirar al suelo, nunca a los ojos",
ACTION_TRAUCO_TALK_LOUD,"Hablar fuerte, como si vinieran más",
ACTION_TRAUCO_THROW_SAND,Tirarle un puñado de arena,
ACTION_TRAUCO_FOLLOW_TO_TREE,Seguirlo hasta su tronco hueco,
OBS_TRAUCO_SAW_FIRST_Q,¿Quién vio a quién primero?,
OBS_TRAUCO_IN_HAND_Q,¿Qué lleva en la mano?,
OBS_TRAUCO_GROUND_Q,¿Cómo está el suelo?,
RULE_TRAUCO_1,Si el Trauco lo vio primero,
RULE_TRAUCO_2,Si lleva el bastón,
RULE_TRAUCO_3,Si el suelo está embarrado,
ENTITY_BASILISCO_NAME,El Basilisco,
ENTITY_BASILISCO_LORE,"Nace de un huevo chico y arrugado que pone un gallo viejo. Es una culebra con cabeza de gallo que se esconde bajo el piso de las casas y se alimenta del aliento de quienes duermen arriba, que se secan de a poco. Hay que encontrar el huevo y quemarlo antes de que nazca.",
ACTION_BASILISCO_BURN_EGG,Quemar el huevo,
ACTION_BASILISCO_LEAVE_HOUSE,Salir de la casa sin correr,
ACTION_BASILISCO_COVER_MOUTH,Taparse la boca y la nariz,
ACTION_BASILISCO_LIFT_BOARD,Levantar la tabla para grabarlo,
OBS_BASILISCO_EGG_Q,¿Ves un huevo?,
OBS_BASILISCO_FLOOR_Q,¿Cómo está el piso?,
RULE_BASILISCO_1,Si hay un huevo chico y arrugado,
RULE_BASILISCO_2,Si hay una tabla levantada,
ENTITY_IMBUNCHE_NAME,El Imbunche,
ENTITY_IMBUNCHE_LORE,El guardián de la cueva donde se reúnen los brujos de Chiloé. Es un ser deforme que avanza saltando en una sola pierna y no habla: solo gruñe. Nadie entra a la cueva sin que él lo sepa. Dicen que se le deja pan en la entrada para tenerlo tranquilo.,
ACTION_IMBUNCHE_BACK_OUT,"Salir retrocediendo, sin darle la espalda",
ACTION_IMBUNCHE_STAY_OUTSIDE,Quedarse afuera y no entrar,
ACTION_IMBUNCHE_OFFER_BREAD,Dejarle pan en la entrada,
ACTION_IMBUNCHE_GO_DEEPER,Entrar a grabar el fondo de la cueva,
OBS_IMBUNCHE_CALLED_NAME_Q,¿Dijo tu nombre?,
OBS_IMBUNCHE_TORCHES_Q,¿Hay luces en la cueva?,
OBS_IMBUNCHE_ENTRANCE_Q,¿Cómo está la entrada?,
RULE_IMBUNCHE_1,Si dijo tu nombre,
RULE_IMBUNCHE_2,Si hay antorchas encendidas,
RULE_IMBUNCHE_3,Si la entrada está tapada,
```

Agregar al final de `data/text/ui.csv`:

```csv
NIGHT_0_PLACE,Alrededores de la cabaña,
```

En `test/capture_screamers.gd`, reemplazar:

```gdscript
## 4. Noche 1, después del susto guionado: el chat de Gonzalo, con el botón de la respuesta de Matías.
```

por:

```gdscript
## 4. Noche 0, después del susto guionado: el chat de Gonzalo, con el botón de la respuesta de Matías.
```

En `test/capture_screamers.gd`, reemplazar:

```gdscript
	desk = _make_desk(1)
	desk.get_node("RequestManager").state.elapsed = 59.5
```

por:

```gdscript
	desk = _make_desk(0)
	desk.get_node("RequestManager").tutorial_queue.clear()
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `403 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add data/ test/
git commit -m "Las 7 entidades y la noche 0" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: El tutorial en el escritorio

**Archivos:**

- Crear: `scenes/ui/tutorial_hint.tscn`, `scripts/ui/tutorial_hint.gd`, `test/test_tutorial_desk.gd`
- Modificar: `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `scripts/desk/night_manager.gd`, `test/test_night_manager.gd`

En la noche 0, el escritorio muestra el aviso del tutorial (`scenes/ui/tutorial_hint.tscn`) arriba, entre el chat y los diales, con el título "Noche de práctica" y el botón "Saltar tutorial". En cada frame le cuenta al guía lo que se ve y escribe el aviso con el nombre del amigo. Cuando el guía termina (Matías cerró el celular), el escritorio termina la noche con `NightManager.finish()`, ganada. El botón avisa con `tutorial_skipped`, que atiende `GameState` (Tarea 12). En las demás noches, el aviso no está.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_night_manager.gd`:

```gdscript
## El tutorial termina cuando el escritorio lo dice: al completarse.
func test_terminar_la_noche_desde_afuera() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.finish(NightState.Ending.WON)
	night.finish(NightState.Ending.SANITY)
	check_eq(endings, [[NightState.Ending.WON, null]], "termina una sola vez")
	check(night.ended, "terminó")
	_free(night)
	return true
```

`test/test_tutorial_desk.gd`:

```gdscript
extends "res://test/test_case.gd"
## La noche 0, el tutorial, en el escritorio (decisión de Benja): el aviso dice qué hacer en cada paso, el
## temporizador espera y la noche termina al cerrar el celular.

const DESK := preload("res://scenes/desk/desk.tscn")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")


func _make_desk(night_number := 0) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").random_seed = 21
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


## Avanza la noche y el escritorio `seconds` segundos, de a 1, como en el juego.
func _play(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk.get_node("NightManager").advance(1.0)
		desk._process(1.0)


func _hint_text(desk: Node2D) -> String:
	return (desk.get_node("Overlay/TutorialHint/Box/Body") as Label).text


## El texto del aviso `key`, con el nombre del amigo `friend_key`.
func _expected(key: String, friend_key := "") -> String:
	var friend_name := String(TranslationServer.translate(friend_key)) if not friend_key.is_empty() else ""
	return String(TranslationServer.translate(key)).format({"friend": friend_name})


func _correct(request: FriendRequest) -> ActionData:
	return request.entity.find_action(RuleEvaluator.applicable_rule(request.entity, request.situation).correct_action_id)


func test_en_una_noche_normal_no_hay_aviso() -> bool:
	var desk := _make_desk(3)
	check(not (desk.get_node("Overlay/TutorialHint") as Control).visible, "sin aviso")
	desk.free()
	return true


func test_el_boton_salta_el_tutorial() -> bool:
	var desk := _make_desk()
	var skipped := []
	desk.tutorial_skipped.connect(func() -> void: skipped.append(true))
	(desk.get_node("Overlay/TutorialHint/Box/Skip") as Button).pressed.emit()
	check_eq(skipped, [true], "avisa que se saltó")
	desk.free()
	return true


## De punta a punta: las 3 solicitudes, el video, el susto, el chat de Gonzalo y el celular.
func test_el_tutorial_de_punta_a_punta() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	var hint := desk.get_node("Overlay/TutorialHint") as Control
	check(hint.visible, "el aviso se ve")
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.WELCOME_KEY), "bienvenida")
	# La solicitud de León: abrir el chat, preguntar, marcar, abrir la página y responder.
	_play(desk, 6)
	var request: FriendRequest = manager.requests[0]
	check(request != null, "llegó la solicitud de León")
	if request == null:
		desk.free()
		return true
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_LEON_NAME"), "abrir el chat")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.ASK_KEY, "FRIEND_LEON_NAME"), "preguntar")
	manager.ask(0, ClueCategory.Kind.SIGHT)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.MARK_KEY), "marcar")
	for trait_data: TraitData in request.traits:
		request.click_clue(trait_data.id)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_PAGE_KEY), "abrir la página")
	_play(desk, 30)
	check_eq(request.time_left, 85.0, "el temporizador esperó: solo bajó la pregunta")
	desk.get_node("UI/ChatPanel").entity_page_requested.emit(0, request.entity)
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.ANSWER_KEY), "responder")
	manager.answer(0, _correct(request))
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.CORRECT_KEY, "FRIEND_LEON_NAME"), "le fue bien")
	# La de Agustín, con un video al terminar.
	_play(desk, 5)
	request = manager.requests[2]
	check(request != null, "llegó la solicitud de Agustín")
	if request == null:
		desk.free()
		return true
	manager.answer(2, _correct(request))
	_play(desk, 1)
	check_eq(_hint_text(desk), _expected(TutorialGuide.VIDEO_KEY, "FRIEND_AGUSTIN_NAME"), "el video")
	desk.get_node("DeskPlane/Entries/EntryAgustin").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.HOLD_KEY), "mantener presionado")
	manager.state.holding_download = 2
	_play(desk, 10)
	manager.state.holding_download = -1
	check_eq(manager.state.videos.received, 1, "se recibió")
	# La de Gonzalo, sin pista: una respuesta equivocada no lo hiere.
	_play(desk, 4)
	request = manager.requests[1]
	check(request != null, "llegó la solicitud de Gonzalo")
	if request == null:
		desk.free()
		return true
	check(request.hint == null, "sin pista")
	var wrong := request.entity.actions.filter(func(action: ActionData) -> bool:
		return RuleEvaluator.outcome(request.entity, request.situation, action) == RuleEvaluator.Outcome.WRONG)
	manager.answer(1, wrong[0])
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.WRONG_KEY, "FRIEND_GONZALO_NAME"), "le fue mal")
	check_eq(manager.state.friends[1].health, 3, "pero no salió herido")
	# El respiro, el susto guionado (con su señal previa y su pausa) y lo que tarda Gonzalo en escribir.
	_play(desk, 10)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_GONZALO_NAME"), "Gonzalo escribió")
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.REPLY_KEY), "responderle")
	(desk.get_node("UI/ChatPanel/Panel/ScriptReply") as Button).pressed.emit()
	_play(desk, 3)
	check_eq(_hint_text(desk), _expected(TutorialGuide.PHONE_KEY), "el celular")
	desk.get_node("DeskPlane/Phone").clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.SCROLL_KEY), "scrollear")
	var endings := []
	desk.get_node("NightManager").night_ended.connect(func(ending: NightState.Ending, _request: FriendRequest) -> void:
		endings.append(ending))
	(desk.get_node("UI/PhoneView") as Control).close()
	desk._process(0.0)
	check_eq(endings, [NightState.Ending.WON], "al cerrar el celular, terminó el tutorial")
	check(not hint.visible, "el aviso se va con la pantalla final")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `403 pruebas OK, 4 fallidas`.

- [ ] **Paso 3: Implementar**

En `scenes/desk/desk.tscn`, reemplazar:

```text
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

por:

```text
[ext_resource type="PackedScene" path="res://scenes/ui/tutorial_hint.tscn" id="tutorial_hint"]
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="Jumpscare" type="Control" parent="Overlay"]
```

por:

```text
[node name="TutorialHint" parent="Overlay" instance=ExtResource("tutorial_hint")]
visible = false

[node name="Jumpscare" type="Control" parent="Overlay"]
```

`scenes/ui/tutorial_hint.tscn`:

```text
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/tutorial_hint.gd" id="hint_script"]
[ext_resource type="FontFile" path="res://fonts/departure_mono/DepartureMono-Regular.otf" id="pixel_font"]
[ext_resource type="Theme" path="res://scenes/ui/chat_theme.tres" id="chat_theme"]

[sub_resource type="StyleBoxFlat" id="hint_style"]
content_margin_left = 11.0
content_margin_top = 8.0
content_margin_right = 11.0
content_margin_bottom = 8.0
bg_color = Color(0.03, 0.05, 0.09, 0.92)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.95, 0.72, 0.3, 1)

[node name="TutorialHint" type="PanelContainer"]
custom_minimum_size = Vector2(340, 0)
offset_left = 470.0
offset_top = 12.0
offset_right = 810.0
offset_bottom = 12.0
theme = ExtResource("chat_theme")
theme_override_styles/panel = SubResource("hint_style")
script = ExtResource("hint_script")

[node name="Box" type="VBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Title" type="Label" parent="Box"]
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.72, 0.3, 1)
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11

[node name="Body" type="Label" parent="Box"]
layout_mode = 2
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11
autowrap_mode = 3

[node name="Skip" type="Button" parent="Box"]
layout_mode = 2
size_flags_horizontal = 8
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## espera la respuesta de Matías, y si el guion lo pide, el celular parpadea hasta que Matías lo abre.
```

por:

```gdscript
## espera la respuesta de Matías, y si el guion lo pide, el celular parpadea hasta que Matías lo abre.
## Desde el Plan 8, en la noche 0 (el tutorial) un aviso arriba de la pantalla dice qué hacer en cada paso
## (TutorialGuide), y la noche termina al cerrar el celular. El aviso tiene un botón para saltar el tutorial.

## Se apretó "Saltar tutorial": el juego pasa a la noche 1.
signal tutorial_skipped
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
const ScreamerManager := preload("res://scripts/desk/screamer_manager.gd")
```

por:

```gdscript
const ScreamerManager := preload("res://scripts/desk/screamer_manager.gd")
const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _phone_sprite: AnimatedSprite2D = $DeskPlane/Phone
```

por:

```gdscript
@onready var _phone_sprite: AnimatedSprite2D = $DeskPlane/Phone
@onready var _tutorial_hint: Control = $Overlay/TutorialHint

## El guía del tutorial en la noche 0, o null en las demás.
var _guide: TutorialGuide
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	$DeskPlane/Phone.clicked.connect(open_phone)
```

por:

```gdscript
	$DeskPlane/Phone.clicked.connect(open_phone)
	if _requests.night().is_tutorial():
		_guide = TutorialGuide.new()
		_requests.request_finished.connect(func(_friend_index: int, request: FriendRequest) -> void:
			_guide.request_finished(request))
		_phone.visibility_changed.connect(_on_phone_visibility_changed)
		_tutorial_hint.skip_pressed.connect(tutorial_skipped.emit)
	_tutorial_hint.visible = _guide != null
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_screamers.advance(delta, _scare_view(), _mixer.is_playing())
```

por:

```gdscript
	_screamers.advance(delta, _scare_view(), _mixer.is_playing())
	if _guide != null:
		_refresh_tutorial()
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_phone.open()
```

por:

```gdscript
	_phone.open()
	if _guide != null:
		_guide.phone_opened()
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
		_phone_sprite.blinking = true
```

por:

```gdscript
		_phone_sprite.blinking = true
		if _guide != null:
			_guide.phone_highlighted()
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	var names: Array[String] = []
```

por:

```gdscript
	_tutorial_hint.hide()
	var names: Array[String] = []
```

Agregar al final de `scripts/desk/desk.gd`:

```gdscript
## El aviso del tutorial: qué hacer ahora. Cuando Matías termina de usar el celular, el tutorial se gana.
func _refresh_tutorial() -> void:
	if _night.ended:
		return
	var hint := _guide.hint(_tutorial_view())
	var friend_name := ""
	if hint.friend_index >= 0:
		friend_name = tr(_requests.catalog.friends[hint.friend_index].name_key)
	_tutorial_hint.show_text(tr(hint.key).format({"friend": friend_name}) if not hint.key.is_empty() else "")
	if _guide.is_done():
		_night.finish(NightState.Ending.WON)


## Lo que el guía necesita ver: la solicitud en curso, el chat abierto, la página de ese amigo, el video que
## espera y el chat guionado.
func _tutorial_view() -> TutorialGuide.View:
	var view := TutorialGuide.View.new()
	var state := _requests.state
	view.chat_friend = _chat_panel.selected_friend if _chat_panel.visible else -1
	for index in _requests.requests.size():
		if _requests.requests[index] != null:
			view.request = _requests.requests[index]
			view.page = notebook_memory.page_for(index)
		if _requests.chat_script_reply(index) != null:
			view.script_friend = index
	if not state.videos.offers.is_empty():
		view.video_friend = state.videos.offers[0].friend_index
	return view


func _on_phone_visibility_changed() -> void:
	if not _phone.visible:
		_guide.phone_closed()
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
func _check_ending(request: FriendRequest) -> void:
```

por:

```gdscript
## Termina la noche ahora con `ending`, si no había terminado: así termina el tutorial, al completarse.
func finish(ending: NightState.Ending) -> void:
	if ended:
		return
	ended = true
	night_ended.emit(ending, null)


func _check_ending(request: FriendRequest) -> void:
```

`scripts/ui/tutorial_hint.gd`:

```gdscript
extends PanelContainer
## El aviso de la noche 0, el tutorial (decisión de Benja): arriba de la pantalla, entre el chat y el cuaderno,
## dice qué hacer ahora. Su botón salta el tutorial. Es provisional hasta el arte (docs/06 §3).

signal skip_pressed

const TutorialGuide := preload("res://scripts/core/tutorial_guide.gd")

@onready var _title: Label = $Box/Title
@onready var _body: Label = $Box/Body
@onready var _skip: Button = $Box/Skip


func _ready() -> void:
	_title.text = tr(TutorialGuide.TITLE_KEY)
	_skip.text = tr(TutorialGuide.SKIP_KEY)
	_skip.pressed.connect(skip_pressed.emit)


## Muestra `text`. Sin texto, solo quedan el título y el botón.
func show_text(text: String) -> void:
	_body.text = text
	_body.visible = not text.is_empty()
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `407 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ scenes/ test/
git commit -m "El tutorial en el escritorio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Las opciones y los canales de audio

**Archivos:**

- Crear: `default_bus_layout.tres`, `scripts/core/game_settings.gd`, `test/test_game_settings.gd`
- Modificar: `scenes/desk/desk.tscn`, `scenes/ui/mixer_view.tscn`, `scripts/desk/request_manager.gd`, `test/test_request_manager.gd`

`GameSettings` (lógica pura) guarda las opciones del jugador (diseño §19) en su propio archivo: el volumen de 3 canales (general, ambiente y efectos), reducir destellos, la cámara fija y los temporizadores ×1,5, que alargan solo el tiempo para responder (decisión de Benja). Los canales se crean en `default_bus_layout.tres`, que Godot carga solo, y cada sonido va al suyo: el ambiente del cuarto a `Ambience` y todo lo demás a `Effects`. `RequestManager.timer_scale` alarga el tiempo de las solicitudes nuevas.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_game_settings.gd`:

```gdscript
extends "res://test/test_case.gd"
## Las opciones del jugador (diseño §19) y los canales de audio.

const GameSettings := preload("res://scripts/core/game_settings.gd")
const TEST_PATH := "user://test_settings.cfg"


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_valores_por_defecto() -> bool:
	var settings := GameSettings.new()
	for bus: StringName in GameSettings.BUSES:
		check_eq(settings.volumes[bus], 1.0, "volumen de %s" % bus)
	check(not settings.reduce_flashes and not settings.still_camera and not settings.slow_timers, "todo apagado")
	check_eq(settings.timer_scale(), 1.0, "temporizadores normales")
	settings.slow_timers = true
	check_eq(settings.timer_scale(), 1.5, "temporizadores ×1,5")
	return true


func test_se_guardan_y_se_leen() -> bool:
	_remove_test_file()
	var settings := GameSettings.new()
	settings.volumes[&"Effects"] = 0.25
	settings.reduce_flashes = true
	settings.still_camera = true
	settings.slow_timers = true
	check_eq(settings.write(TEST_PATH), OK, "se guardan")
	var read := GameSettings.new()
	read.read(TEST_PATH)
	check_eq(read.volumes[&"Effects"], 0.25, "volumen")
	check_eq(read.volumes[&"Master"], 1.0, "el resto igual")
	check(read.reduce_flashes and read.still_camera and read.slow_timers, "los interruptores")
	_remove_test_file()
	return true


func test_sin_archivo_quedan_los_valores_por_defecto() -> bool:
	_remove_test_file()
	var settings := GameSettings.new()
	settings.read(TEST_PATH)
	check_eq(settings.volumes[&"Master"], 1.0, "volumen")
	check(not settings.reduce_flashes, "destellos")
	return true


## Los 3 canales existen (default_bus_layout.tres) y el volumen de cada uno se aplica al AudioServer.
func test_el_volumen_de_cada_canal() -> bool:
	for bus: StringName in GameSettings.BUSES:
		check(AudioServer.get_bus_index(bus) >= 0, "existe el canal %s" % bus)
	var settings := GameSettings.new()
	settings.volumes[&"Ambience"] = 0.5
	settings.volumes[&"Effects"] = 0.0
	settings.apply_audio()
	var ambience := AudioServer.get_bus_index(&"Ambience")
	var effects := AudioServer.get_bus_index(&"Effects")
	check(is_equal_approx(AudioServer.get_bus_volume_db(ambience), linear_to_db(0.5)), "ambiente a la mitad")
	check(AudioServer.is_bus_mute(effects), "efectos en 0: silencio")
	GameSettings.new().apply_audio()
	check(not AudioServer.is_bus_mute(effects), "vuelve a sonar")
	check_eq(AudioServer.get_bus_volume_db(ambience), 0.0, "ambiente a tope")
	return true


## Cada sonido va a su canal: el ambiente del cuarto a Ambience, y todo lo demás a Effects.
func test_cada_sonido_en_su_canal() -> bool:
	for path: String in ["res://scenes/desk/desk.tscn", "res://scenes/ui/mixer_view.tscn"]:
		var scene := (load(path) as PackedScene).instantiate()
		var players := scene.find_children("*", "AudioStreamPlayer", true, false)
		players.append_array(scene.find_children("*", "AudioStreamPlayer2D", true, false))
		check(not players.is_empty(), "%s tiene sonidos" % path)
		for player: Node in players:
			var expected := &"Ambience" if player.name == &"Ambient" else &"Effects"
			check_eq(player.get("bus"), expected, "%s: %s" % [path.get_file(), player.name])
		scene.free()
	return true
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
## La opción "Temporizadores ×1,5" (diseño §19) alarga el tiempo para responder (decisión de Benja: solo ese).
func test_temporizadores_mas_largos() -> bool:
	var manager := _make_manager()
	manager.timer_scale = 1.5
	var request := manager.start_request(0)
	check_eq(request.time_left, 67.5, "45 s × 1,5")
	manager.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `407 pruebas OK, 2 fallidas`.

- [ ] **Paso 3: Implementar**

`default_bus_layout.tres`:

```text
[gd_resource type="AudioBusLayout" format=3]

[resource]
bus/1/name = &"Ambience"
bus/1/solo = false
bus/1/mute = false
bus/1/bypass_fx = false
bus/1/volume_db = 0.0
bus/1/send = &"Master"
bus/2/name = &"Effects"
bus/2/solo = false
bus/2/mute = false
bus/2/bypass_fx = false
bus/2/volume_db = 0.0
bus/2/send = &"Master"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
volume_db = -6.0
```

por:

```text
volume_db = -6.0
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
autoplay = true
```

por:

```text
autoplay = true
bus = &"Ambience"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("curtains_sound")
```

por:

```text
stream = ExtResource("curtains_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("window_sound")
```

por:

```text
stream = ExtResource("window_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("phone_sound")
```

por:

```text
stream = ExtResource("phone_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("lights_sound")
```

por:

```text
stream = ExtResource("lights_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("slam_sound")
```

por:

```text
stream = ExtResource("slam_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("ink_sound")
```

por:

```text
stream = ExtResource("ink_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
stream = ExtResource("jumpscare_sound")

[node name="Hallucination" type="AudioStreamPlayer2D" parent="Screamers"]
```

por:

```text
stream = ExtResource("jumpscare_sound")
bus = &"Effects"

[node name="Hallucination" type="AudioStreamPlayer2D" parent="Screamers"]
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
stream = ExtResource("kick")
```

por:

```text
stream = ExtResource("kick")
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
volume_db = -8.0
```

por:

```text
volume_db = -8.0
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
stream = ExtResource("clap")
```

por:

```text
stream = ExtResource("clap")
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
volume_db = -4.0
```

por:

```text
volume_db = -4.0
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
stream = ExtResource("success")
volume_db = -6.0
```

por:

```text
stream = ExtResource("success")
volume_db = -6.0
bus = &"Effects"
```

En `scenes/ui/mixer_view.tscn`, reemplazar:

```text
stream = ExtResource("fail")
volume_db = -6.0
```

por:

```text
stream = ExtResource("fail")
volume_db = -6.0
bus = &"Effects"
```

`scripts/core/game_settings.gd`:

```gdscript
extends RefCounted
## Las opciones del jugador (diseño §19): el volumen de cada canal de audio, reducir destellos, la cámara fija
## (sin parallax) y los temporizadores ×1,5, que alargan solo el tiempo para responder (decisión de Benja).
## Se guardan en su propio archivo, aparte de la partida. Lógica pura, salvo apply_audio(), que toca el
## AudioServer.

## Los canales de audio (default_bus_layout.tres): todo, el ambiente del cuarto y los efectos.
const BUSES: Array[StringName] = [&"Master", &"Ambience", &"Effects"]
## Cuánto alarga el tiempo para responder la opción "Temporizadores ×1,5".
const SLOW_TIMER_SCALE := 1.5
const SECTION := "options"

## El volumen de cada canal, de 0 (silencio) a 1.
var volumes := {&"Master": 1.0, &"Ambience": 1.0, &"Effects": 1.0}
## Suaviza los parpadeos rápidos: las entradas, los LED del mixer y los screamers (diseño §19).
var reduce_flashes := false
## La cámara queda fija, sin zoom ni desplazamiento hacia el mouse (desactivar el parallax, diseño §19).
var still_camera := false
## El tiempo para responder una solicitud es 1,5 veces más largo.
var slow_timers := false


func timer_scale() -> float:
	return SLOW_TIMER_SCALE if slow_timers else 1.0


## Lee las opciones de `path`. Lo que falte (o si el archivo no existe) queda con su valor por defecto.
func read(path: String) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for bus: StringName in BUSES:
		volumes[bus] = clampf(float(file.get_value(SECTION, "volume_" + String(bus).to_lower(), 1.0)), 0.0, 1.0)
	reduce_flashes = bool(file.get_value(SECTION, "reduce_flashes", false))
	still_camera = bool(file.get_value(SECTION, "still_camera", false))
	slow_timers = bool(file.get_value(SECTION, "slow_timers", false))


func write(path: String) -> Error:
	var file := ConfigFile.new()
	for bus: StringName in BUSES:
		file.set_value(SECTION, "volume_" + String(bus).to_lower(), volumes[bus])
	file.set_value(SECTION, "reduce_flashes", reduce_flashes)
	file.set_value(SECTION, "still_camera", still_camera)
	file.set_value(SECTION, "slow_timers", slow_timers)
	return file.save(path)


## Aplica el volumen de cada canal. Con 0, el canal queda en silencio.
func apply_audio() -> void:
	for bus: StringName in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var volume: float = volumes[bus]
		AudioServer.set_bus_mute(index, volume <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(volume) if volume > 0.0 else -80.0)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
@export var random_seed := 0
```

por:

```gdscript
@export var random_seed := 0
## Cuánto se alarga el tiempo para responder: 1,5 con la opción "Temporizadores ×1,5" (diseño §19).
var timer_scale := 1.0
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto.
```

por:

```gdscript
## (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la opción
## "Temporizadores ×1,5", más largo.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	requests[friend_index] = request
```

por:

```gdscript
	request.time_left *= timer_scale
	requests[friend_index] = request
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust)):
```

por:

```gdscript
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust) * timer_scale):
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `413 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add default_bus_layout.tres scripts/ scenes/ test/
git commit -m "Las opciones y los canales de audio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: La partida guardada

**Archivos:**

- Crear: `scripts/core/save_game.gd`, `test/test_save_game.gd`

`SaveGame` guarda la noche en la que va el jugador, de 0 a 5. Se guarda al comienzo de cada noche (diseño §5), así que "Continuar" vuelve a empezar esa noche, y al ganar la noche 5 se borra.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_save_game.gd`:

```gdscript
extends "res://test/test_case.gd"
## La partida guardada (diseño §5): la noche en la que va el jugador.

const SaveGame := preload("res://scripts/core/save_game.gd")
const TEST_PATH := "user://test_save.cfg"


func _make_save() -> SaveGame:
	var save := SaveGame.new(TEST_PATH)
	save.clear()
	return save


func test_sin_partida() -> bool:
	var save := _make_save()
	check(not save.has_game(), "no hay partida")
	check_eq(save.stored_night(), -1, "ninguna noche")
	return true


func test_guarda_la_noche_al_empezarla() -> bool:
	var save := _make_save()
	check_eq(save.store(0), OK, "se guarda el tutorial")
	check(save.has_game(), "hay partida")
	check_eq(save.stored_night(), 0, "en el tutorial")
	save.store(3)
	check_eq(SaveGame.new(TEST_PATH).stored_night(), 3, "otra lectura ve la noche 3")
	save.clear()
	check(not save.has_game(), "al borrarla ya no hay")
	return true


func test_una_noche_que_no_existe_no_cuenta() -> bool:
	var save := _make_save()
	var file := ConfigFile.new()
	file.set_value(SaveGame.SECTION, "night", 9)
	file.save(TEST_PATH)
	check(not save.has_game(), "la noche 9 no existe")
	save.clear()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `413 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Implementar**

`scripts/core/save_game.gd`:

```gdscript
extends RefCounted
## La partida guardada (diseño §5): la noche en la que va el jugador, de 0 (el tutorial) a 5. Se guarda al
## comienzo de cada noche, así que "Continuar" vuelve a empezar esa noche. Al ganar la noche 5 se borra:
## el juego terminó.

const SECTION := "game"
const LAST_NIGHT := 5

var path := ""


func _init(save_path: String) -> void:
	path = save_path


func has_game() -> bool:
	return stored_night() >= 0


## La noche guardada, o -1 si no hay partida (o si el archivo no tiene una noche que exista).
func stored_night() -> int:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return -1
	var night := int(file.get_value(SECTION, "night", -1))
	return night if night >= 0 and night <= LAST_NIGHT else -1


func store(night: int) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "night", night)
	return file.save(path)


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `416 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ test/
git commit -m "La partida guardada" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: Reducir destellos y la cámara fija

**Archivos:**

- Modificar: `scripts/desk/desk.gd`, `scripts/desk/look_camera.gd`, `scripts/desk/screamer_manager.gd`, `scripts/ui/chat_entry.gd`, `scripts/ui/mixer_view.gd`, `test/test_chat_entry.gd`, `test/test_desk_scene.gd`, `test/test_mixer_view.gd`, `test/test_screamer_manager.gd`

"Reducir destellos" (diseño §19) apaga los parpadeos rápidos, como pedía el pendiente del Plan 7:

- la entrada en alerta queda fija en el cuadro de la alerta (el arte la hace parpadear 5 veces por segundo), y el aviso de una interferencia la atenúa sin titilar;
- el LED de una interferencia en el mixer queda encendido;
- la señal previa de un screamer, el apagón de las luces y el rojo del jumpscare se oscurecen una sola vez, más lento. Sus secuencias de opacidad son funciones (`warning_alphas()`, `lights_alphas()` y `jumpscare_alphas()`) para poder probarlas.

El contorno del celular que parpadea (una vez cada 0,8 s) no cambia: es lento. "Cámara fija" deja `LookCamera` sin zoom y centrada (`set_look()`). `desk.apply_settings()` reparte las opciones a cada pieza.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_entry.gd`:

```gdscript
## "Reducir destellos" (diseño §19): la alerta queda fija en lugar de parpadear, y el aviso de una interferencia
## atenúa la entrada en lugar de hacerla titilar.
func test_reducir_destellos() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.reduce_flashes = true
	entry.set_state(ChatEntry.State.WARNING)
	check_eq(background.animation, &"warning", "alerta")
	check(not background.is_playing(), "sin parpadear")
	check_eq(background.frame, 0, "en el cuadro de la alerta")
	entry.set_interference_warning(true)
	for _i in 4:
		entry._process(0.06)
		check(is_equal_approx(entry.modulate.a, ChatEntry.DIM_ALPHA), "atenuada, sin titilar: %s" % entry.modulate.a)
	entry.reduce_flashes = false
	check(background.is_playing(), "al apagar la opción, vuelve a parpadear")
	entry.free()
	return true
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
```

por:

```gdscript
const GameSettings := preload("res://scripts/core/game_settings.gd")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
## Las opciones del jugador (diseño §19) llegan a cada parte del escritorio.
func test_aplica_las_opciones() -> bool:
	var desk := _make_desk()
	var settings := GameSettings.new()
	settings.reduce_flashes = true
	settings.still_camera = true
	settings.slow_timers = true
	desk.apply_settings(settings)
	var camera := desk.get_node("LookCamera") as Camera2D
	check_eq(camera.zoom, Vector2.ONE, "cámara sin zoom")
	check_eq(camera.position, Vector2(640, 360), "y centrada")
	check(not camera.get("look_enabled"), "fija")
	check(desk.get_node("DeskPlane/Entries/EntryLeon").reduce_flashes, "entradas sin destellos")
	check(desk.get_node("UI/MixerView").reduce_flashes, "mixer sin destellos")
	check(desk.get_node("Screamers").reduce_flashes, "screamers sin destellos")
	check_eq(desk.get_node("RequestManager").timer_scale, 1.5, "temporizadores ×1,5")
	desk.apply_settings(GameSettings.new())
	check(camera.get("look_enabled"), "la cámara vuelve a mirar hacia el mouse")
	check_eq(camera.zoom, Vector2(1.05, 1.05), "con su zoom")
	desk.free()
	return true
```

Agregar al final de `test/test_mixer_view.gd`:

```gdscript
## "Reducir destellos" (diseño §19): el LED de una interferencia queda encendido, sin parpadear.
func test_reducir_destellos() -> bool:
	var mixer := _make_mixer()
	mixer._blink = 0.18
	check_eq(mixer.warning_led(), 0.0, "parpadea: en este momento, apagado")
	mixer.reduce_flashes = true
	check_eq(mixer.warning_led(), 1.0, "fijo")
	_free(mixer)
	return true
```

Agregar al final de `test/test_screamer_manager.gd`:

```gdscript
## Cuántas veces vuelve a oscurecerse una secuencia de opacidades: cada vuelta es un destello.
func _flashes(alphas: Array[float]) -> int:
	var count := 0
	var previous := 0.0
	var falling := false
	for alpha: float in alphas:
		if alpha < previous:
			falling = true
		elif alpha > previous and falling:
			count += 1
		previous = alpha
	return count


## "Reducir destellos" (diseño §19): la señal previa, el apagón de las luces y el rojo del jumpscare se oscurecen
## una sola vez, más suave, en lugar de parpadear.
func test_reducir_destellos() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	check(_flashes(screamers.warning_alphas()) > 0, "la señal previa parpadea")
	check(_flashes(screamers.lights_alphas()) > 0, "las luces parpadean")
	check(_flashes(screamers.jumpscare_alphas()) > 0, "el rojo del jumpscare parpadea")
	screamers.reduce_flashes = true
	for alphas: Array[float] in [screamers.warning_alphas(), screamers.lights_alphas(), screamers.jumpscare_alphas()]:
		check_eq(_flashes(alphas), 0, "sin destellos: %s" % [alphas])
		check(alphas.max() <= 0.85, "sin pasar de la oscuridad de las luces: %s" % [alphas])
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `408 pruebas OK, 4 fallidas`.

- [ ] **Paso 3: Implementar**

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
const NightManager := preload("res://scripts/desk/night_manager.gd")
```

por:

```gdscript
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	view.notebook_page = _notebook_panel.shows_page()
	return view
```

por:

```gdscript
	view.notebook_page = _notebook_panel.shows_page()
	return view


## Aplica las opciones del jugador (diseño §19): menos destellos, la cámara fija y más tiempo para responder.
func apply_settings(settings: GameSettings) -> void:
	for entry: Node in _entries:
		entry.reduce_flashes = settings.reduce_flashes
	_mixer.reduce_flashes = settings.reduce_flashes
	_screamers.reduce_flashes = settings.reduce_flashes
	$LookCamera.set_look(not settings.still_camera)
	_requests.timer_scale = settings.timer_scale()
```

En `scripts/desk/look_camera.gd`, reemplazar:

```gdscript
## Con look_enabled = false, o con el argumento `-- --no-parallax` (para capturas), queda sin zoom y fija.
```

por:

```gdscript
## Con look_enabled = false, o con el argumento `-- --no-parallax` (para capturas), queda sin zoom y fija.
## La opción "Cámara fija" (desactivar el parallax, diseño §19) la deja así con set_look().
```

En `scripts/desk/look_camera.gd`, reemplazar:

```gdscript
	position = _center
	zoom = Vector2.ONE * (look_zoom if look_enabled else 1.0)
	make_current()
```

por:

```gdscript
	set_look(look_enabled)
	make_current()


## Con `enabled`, mira hacia el mouse con su zoom; si no, queda sin zoom, fija y centrada.
func set_look(enabled: bool) -> void:
	look_enabled = enabled
	position = _center
	zoom = Vector2.ONE * (look_zoom if look_enabled else 1.0)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Hasta el arte de Benja (docs/06 §3), los screamers usan las piezas del escritorio y la figura de la ventana.
```

por:

```gdscript
## Hasta el arte de Benja (docs/06 §3), los screamers usan las piezas del escritorio y la figura de la ventana.
## Con "Reducir destellos" (diseño §19), la señal previa, el apagón de las luces y el rojo del jumpscare se
## oscurecen una sola vez, más suave, en lugar de parpadear.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Desde dónde suena una alucinación: fuera de la pantalla, a la izquierda o a la derecha.
```

por:

```gdscript
## Segundos de cada paso de un oscurecer suave, con "Reducir destellos".
const GENTLE_STEP := 0.4
## Desde dónde suena una alucinación: fuera de la pantalla, a la izquierda o a la derecha.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
@export var hallucination_sounds: Array[AudioStream] = []
```

por:

```gdscript
@export var hallucination_sounds: Array[AudioStream] = []
## La opción "Reducir destellos" (diseño §19).
var reduce_flashes := false
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	var flicker := create_tween()
	for alpha: float in [0.6, 0.0, 0.75, 0.0]:
		flicker.tween_property(darkness, ^"modulate:a", alpha, 0.08)
```

por:

```gdscript
	_tween_alphas(darkness, ^"modulate:a", warning_alphas(), GENTLE_STEP if reduce_flashes else 0.08)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	var tween := create_tween()
	for alpha: float in [DARK, 0.2, DARK, 0.0, DARK, DARK, 0.3, 0.0]:
		tween.tween_property(darkness, ^"modulate:a", alpha, EFFECT_SECONDS / 8.0)
```

por:

```gdscript
	var alphas := lights_alphas()
	_tween_alphas(darkness, ^"modulate:a", alphas, EFFECT_SECONDS / alphas.size())
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	var tween := create_tween()
	for alpha: float in [0.5, 0.0, 0.35, 0.0, 0.25, 0.0]:
		tween.tween_property(red, ^"color:a", alpha, seconds / 6.0)
	tween.tween_callback(jumpscare.hide)
```

por:

```gdscript
	var alphas := jumpscare_alphas()
	_tween_alphas(red, ^"color:a", alphas, seconds / alphas.size()).tween_callback(jumpscare.hide)
```

Agregar al final de `scripts/desk/screamer_manager.gd`:

```gdscript
## La oscuridad durante la señal previa: dos parpadeos, o un oscurecer suave.
func warning_alphas() -> Array[float]:
	if reduce_flashes:
		return [0.35, 0.0]
	return [0.6, 0.0, 0.75, 0.0]


## La oscuridad del apagón de las luces: se apagan y se prenden varias veces, o se apagan una sola vez.
func lights_alphas() -> Array[float]:
	if reduce_flashes:
		return [DARK, DARK, 0.0]
	return [DARK, 0.2, DARK, 0.0, DARK, DARK, 0.3, 0.0]


## El rojo del jumpscare: tres parpadeos, o uno suave.
func jumpscare_alphas() -> Array[float]:
	if reduce_flashes:
		return [0.3, 0.3, 0.0]
	return [0.5, 0.0, 0.35, 0.0, 0.25, 0.0]


## Lleva `property` de `target` por cada opacidad de `alphas`, `step` segundos cada una.
func _tween_alphas(target: Object, property: NodePath, alphas: Array[float], step: float) -> Tween:
	var tween := create_tween()
	for alpha: float in alphas:
		tween.tween_property(target, property, alpha, step)
	return tween
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
## Titila mientras se anuncia una interferencia (diseño §10.1).
```

por:

```gdscript
## Titila mientras se anuncia una interferencia (diseño §10.1). Con "Reducir destellos" (diseño §19), la alerta
## queda fija en lugar de parpadear, y el aviso de una interferencia atenúa la entrada en lugar de hacerla titilar.
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
const FLICKER_SECONDS := 0.12
```

por:

```gdscript
const FLICKER_SECONDS := 0.12
## Qué tan atenuada queda la entrada al titilar, o mientras dura el aviso si se reducen los destellos.
const DIM_ALPHA := 0.35
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
var interference_warning := false
```

por:

```gdscript
var interference_warning := false
## La opción "Reducir destellos" (diseño §19).
var reduce_flashes := false:
	set(value):
		reduce_flashes = value
		if is_node_ready():
			set_state(state)
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
	modulate.a = 0.35 if fmod(_flicker_time, FLICKER_SECONDS * 2.0) < FLICKER_SECONDS else 1.0
```

por:

```gdscript
	var dim := reduce_flashes or fmod(_flicker_time, FLICKER_SECONDS * 2.0) < FLICKER_SECONDS
	modulate.a = DIM_ALPHA if dim else 1.0
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
	_background.modulate = STATE_MODULATE[new_state]
```

por:

```gdscript
	if reduce_flashes and new_state == State.WARNING:
		# Fija en el cuadro de la alerta, sin parpadear.
		_background.pause()
		_background.frame = 0
	_background.modulate = STATE_MODULATE[new_state]
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
var _rest_position := Vector2.ZERO
```

por:

```gdscript
## La opción "Reducir destellos" (diseño §19): el LED de una interferencia no parpadea.
var reduce_flashes := false
var _rest_position := Vector2.ZERO
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
		lit = 1.0 if fmod(_blink, 0.24) < 0.12 else 0.0
```

por:

```gdscript
		lit = warning_led()
```

Agregar al final de `scripts/ui/mixer_view.gd`:

```gdscript
## Cuánto brilla el LED de un canal al que le viene una interferencia: parpadea, o queda fijo si se reducen los
## destellos.
func warning_led() -> float:
	return 1.0 if reduce_flashes or fmod(_blink, 0.24) < 0.12 else 0.0
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `420 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ test/
git commit -m "Reducir destellos y la cámara fija" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: El resumen entre noches y la victoria

**Archivos:**

- Modificar: `data/text/ui.csv`, `scenes/ui/end_screen.tscn`, `scripts/core/ending_text.gd`, `scripts/desk/desk.gd`, `scripts/ui/end_screen.gd`, `test/test_desk_scene.gd`, `test/test_end_screen.gd`, `test/test_ending_text.gd`

La pantalla final pasa a ser también el resumen entre noches (diseño §5):

- al ganar una noche: los videos y las páginas que suma el cuaderno la noche siguiente, con "Empezar la noche N" y "Volver al menú";
- al terminar el tutorial: "Práctica terminada" y "Empezar la noche 1";
- al ganar la noche 5: la victoria final, solo con "Volver al menú";
- al perder: el porqué, como antes, con "Reintentar" y "Volver al menú".

El escritorio convierte los botones en pedidos (`next_night_requested`, `retry_requested` y `menu_requested`), que atiende `GameState`. Si nadie atiende "Reintentar" (el escritorio abierto solo desde el editor), recarga la escena como antes. `END_PLAY_AGAIN` ya no se usa y sale de `ui.csv`.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
## Los botones de la pantalla final llegan al juego (GameState) como pedidos del escritorio.
func test_la_pantalla_final_pide_seguir_reintentar_o_volver_al_menu() -> bool:
	var desk := _make_desk()
	var requested := []
	for signal_name: String in ["next_night_requested", "retry_requested", "menu_requested"]:
		desk.connect(signal_name, func() -> void: requested.append(signal_name))
	var screen := desk.get_node("Overlay/EndScreen")
	screen.next_pressed.emit()
	screen.retry_pressed.emit()
	screen.menu_pressed.emit()
	check_eq(requested, ["next_night_requested", "retry_requested", "menu_requested"], "uno por botón")
	desk.free()
	return true


## Al ganar, el resumen dice qué páginas suma el cuaderno la noche siguiente.
func test_al_ganar_el_resumen_dice_las_paginas_nuevas() -> bool:
	var desk := _make_desk()
	_state(desk).videos.received = _state(desk).videos.quota
	_state(desk).elapsed = 419.5
	desk.get_node("NightManager").advance(1.0)
	var body := (desk.get_node("Overlay/EndScreen/Center/Box/Body") as RichTextLabel).text
	var pages := ", ".join(PackedStringArray([TranslationServer.translate("ENTITY_BASILISCO_NAME"),
			TranslationServer.translate("ENTITY_IMBUNCHE_NAME")]))
	check(body.contains(pages), "la noche 4 suma El Basilisco y El Imbunche: " + body)
	desk.free()
	return true
```

En `test/test_end_screen.gd`, reemplazar:

```gdscript
	check_eq((screen.get_node("Center/Box/Body") as RichTextLabel).text,
			_translated("END_WON").format({"received": 2, "quota": 2}), "cuántos videos")
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_PLAY_AGAIN"), "jugar de nuevo")
```

por:

```gdscript
	check((screen.get_node("Center/Box/Body") as RichTextLabel).text.begins_with(
			_translated("END_WON").format({"received": 2, "quota": 2})), "cuántos videos")
	var next := screen.get_node("Center/Box/Buttons/Next") as Button
	check(next.visible, "se sigue a la noche siguiente")
	check_eq(next.text, _translated("END_NEXT").format({"night": 2}), "empezar la noche 2")
	check(not (screen.get_node("Center/Box/Buttons/Retry") as Button).visible, "sin reintentar")
	check((screen.get_node("Center/Box/Buttons/Menu") as Button).visible, "o volver al menú")
```

En `test/test_end_screen.gd`, reemplazar:

```gdscript
	check_eq((screen.get_node("Center/Box/Retry") as Button).text, _translated("END_RETRY"), "reintentar")
```

por:

```gdscript
	var retry := screen.get_node("Center/Box/Buttons/Retry") as Button
	check(retry.visible, "se reintenta")
	check_eq(retry.text, _translated("END_RETRY"), "reintentar")
	check(not (screen.get_node("Center/Box/Buttons/Next") as Button).visible, "no se sigue")
	check_eq((screen.get_node("Center/Box/Buttons/Menu") as Button).text, _translated("END_MENU"), "volver al menú")
```

En `test/test_end_screen.gd`, reemplazar:

```gdscript
func test_el_boton_pide_volver_a_empezar() -> bool:
	var screen := _make_screen()
	var pressed := []
	screen.retry_pressed.connect(func() -> void: pressed.append(true))
	(screen.get_node("Center/Box/Retry") as Button).pressed.emit()
	check_eq(pressed.size(), 1, "avisa una vez")
```

por:

```gdscript
func test_cada_boton_avisa_lo_suyo() -> bool:
	var screen := _make_screen()
	var pressed := []
	for signal_name: String in ["retry_pressed", "next_pressed", "menu_pressed"]:
		screen.connect(signal_name, func() -> void: pressed.append(signal_name))
	for button: String in ["Retry", "Next", "Menu"]:
		(screen.get_node("Center/Box/Buttons/" + button) as Button).pressed.emit()
	check_eq(pressed, ["retry_pressed", "next_pressed", "menu_pressed"], "una vez cada uno")
```

Agregar al final de `test/test_end_screen.gd`:

```gdscript
## El resumen entre noches (diseño §5): los videos y las páginas nuevas del cuaderno para la noche siguiente.
func test_el_resumen_dice_las_paginas_nuevas() -> bool:
	var screen := _make_screen()
	var state := _make_state()
	state.videos.received = 2
	var pages: Array[String] = ["El Cuero", "La Viuda"]
	screen.show_ending(NightState.Ending.WON, state, null, FRIENDS, 1, pages)
	var body := (screen.get_node("Center/Box/Body") as RichTextLabel).text
	check(body.contains(_translated("END_NEW_PAGES").format({"night": 2, "pages": "El Cuero, La Viuda"})), body)
	screen.free()
	return true


## Al terminar el tutorial, se sigue a la noche 1.
func test_al_terminar_el_tutorial() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 0)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_TUTORIAL_TITLE"), "título")
	check_eq((screen.get_node("Center/Box/Buttons/Next") as Button).text, _translated("END_NEXT").format({"night": 1}),
			"empezar la noche 1")
	screen.free()
	return true


## Al ganar la noche 5, el juego terminó (diseño §5): solo queda volver al menú.
func test_la_victoria_final() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 5)
	check_eq((screen.get_node("Center/Box/Title") as Label).text, _translated("END_VICTORY_TITLE"), "título")
	check(not (screen.get_node("Center/Box/Buttons/Next") as Button).visible, "no hay noche 6")
	check(not (screen.get_node("Center/Box/Buttons/Retry") as Button).visible, "ni reintentar")
	check((screen.get_node("Center/Box/Buttons/Menu") as Button).visible, "volver al menú")
	screen.free()
	return true
```

En `test/test_ending_text.gd`, reemplazar:

```gdscript
	"END_QUOTA": "Faltó: {received} de {quota}.",
```

por:

```gdscript
	"END_NEW_PAGES": "Noche {night}: {pages}.",
	"END_NO_NEW_PAGES": "Noche {night}: nada.",
	"END_QUOTA": "Faltó: {received} de {quota}.",
```

En `test/test_ending_text.gd`, reemplazar:

```gdscript
			EndingText.CHOSEN_OFFLINE_KEY]
```

por:

```gdscript
			EndingText.CHOSEN_OFFLINE_KEY, EndingText.TUTORIAL_TITLE_KEY, EndingText.VICTORY_TITLE_KEY,
			EndingText.TUTORIAL_KEY, EndingText.VICTORY_KEY, EndingText.NEW_PAGES_KEY, EndingText.NO_NEW_PAGES_KEY,
			"END_NEXT", "END_MENU"]
```

Agregar al final de `test/test_ending_text.gd`:

```gdscript
## Los títulos al ganar: el tutorial, una noche y la última (diseño §5).
func test_titulos_al_ganar() -> bool:
	check_eq(EndingText.won_title(0, _translate), "END_TUTORIAL_TITLE", "tutorial")
	check_eq(EndingText.won_title(3, _translate), "END_WON_TITLE", "una noche")
	check_eq(EndingText.won_title(EndingText.LAST_NIGHT, _translate), "END_VICTORY_TITLE", "la última")
	return true


## El resumen entre noches: los videos y las páginas nuevas del cuaderno para la noche siguiente.
func test_el_resumen_entre_noches() -> bool:
	var state := _make_state()
	state.videos.received = 2
	var pages: Array[String] = ["El [Cuero]", "La Viuda"]
	check_eq(_plain(EndingText.summary(2, state, pages, _translate)), "Ganaste con 2 de 2.\n\nNoche 3: El [Cuero], La Viuda.",
			"con páginas nuevas")
	var none: Array[String] = []
	check_eq(EndingText.summary(4, state, none, _translate), "Ganaste con 2 de 2.\n\nNoche 5: nada.", "sin páginas")
	check_eq(EndingText.summary(0, state, none, _translate), "END_TUTORIAL", "el tutorial")
	check_eq(EndingText.summary(EndingText.LAST_NIGHT, state, none, _translate), "Ganaste con 2 de 2.\n\nEND_VICTORY",
			"la victoria final")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `409 pruebas OK, 9 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/text/ui.csv`, reemplazar:

```csv
END_PLAY_AGAIN,Jugar de nuevo,
END_CHOSEN_OFFLINE,{friend} estaba sin señal y eligió: {action}.,
```

por:

```csv
END_CHOSEN_OFFLINE,{friend} estaba sin señal y eligió: {action}.,
```

Agregar al final de `data/text/ui.csv`:

```csv
END_TUTORIAL_TITLE,Práctica terminada,
END_TUTORIAL,"Ya sabes cómo ayudar a tus amigos. Desde ahora, cada error puede costarles caro.",
END_VICTORY_TITLE,Sobreviviste las 5 noches,
END_VICTORY,"Tus amigos volvieron a la cabaña con todo el material. Esta vez, nadie se quedó atrás.",
END_NEW_PAGES,"Para la noche {night}, el cuaderno suma: {pages}.",
END_NO_NEW_PAGES,"Para la noche {night}, el cuaderno no suma páginas.",
END_NEXT,Empezar la noche {night},
END_MENU,Volver al menú,
```

En `scenes/ui/end_screen.tscn`, reemplazar:

```text
[node name="Retry" type="Button" parent="Center/Box"]
layout_mode = 2
size_flags_horizontal = 4
```

por:

```text
[node name="Buttons" type="HBoxContainer" parent="Center/Box"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 22

[node name="Retry" type="Button" parent="Center/Box/Buttons"]
layout_mode = 2
```

En `scenes/ui/end_screen.tscn`, reemplazar:

```text
theme_override_font_sizes/font_size = 22
```

por:

```text
theme_override_font_sizes/font_size = 22

[node name="Next" type="Button" parent="Center/Box/Buttons"]
layout_mode = 2
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 22

[node name="Menu" type="Button" parent="Center/Box/Buttons"]
layout_mode = 2
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 22
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.
```

por:

```gdscript
## Desde el Plan 8, al ganar es el resumen entre noches (diseño §5): los videos y las páginas nuevas del cuaderno
## para la noche siguiente. Al terminar el tutorial y al ganar la última noche tiene sus propios textos.
## `translate` recibe una clave y devuelve su texto, como TranslationServer.translate.
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
## Por qué terminó la noche (ui.csv). END_WON y END_QUOTA llevan {received} y {quota};
```

por:

```gdscript
const TUTORIAL_TITLE_KEY := "END_TUTORIAL_TITLE"
const VICTORY_TITLE_KEY := "END_VICTORY_TITLE"
## El resumen al ganar (ui.csv). END_NEW_PAGES lleva {night} y {pages}; END_NO_NEW_PAGES, {night}.
const TUTORIAL_KEY := "END_TUTORIAL"
const VICTORY_KEY := "END_VICTORY"
const NEW_PAGES_KEY := "END_NEW_PAGES"
const NO_NEW_PAGES_KEY := "END_NO_NEW_PAGES"
## La última noche: al ganarla, el juego termina (diseño §5).
const LAST_NIGHT := 5
## Por qué terminó la noche (ui.csv). END_WON y END_QUOTA llevan {received} y {quota};
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
	return _text(translate, WON_TITLE_KEY if ending == NightState.Ending.WON else LOST_TITLE_KEY)
```

por:

```gdscript
	return _text(translate, WON_TITLE_KEY if ending == NightState.Ending.WON else LOST_TITLE_KEY)


## El título al ganar la noche `night_number`: el del tutorial, el de una noche o el de la victoria final.
static func won_title(night_number: int, translate: Callable) -> String:
	if night_number == 0:
		return _text(translate, TUTORIAL_TITLE_KEY)
	return _text(translate, VICTORY_TITLE_KEY if night_number >= LAST_NIGHT else WON_TITLE_KEY)


## El resumen al ganar la noche `night_number`: los videos y las páginas nuevas del cuaderno para la noche
## siguiente (`new_pages`, sus nombres). Al terminar el tutorial, un texto propio; al ganar la última, la victoria.
static func summary(night_number: int, state: NightState, new_pages: Array[String], translate: Callable) -> String:
	if night_number == 0:
		return _line(translate, TUTORIAL_KEY, {})
	var lines := PackedStringArray([_line(translate, REASON_KEYS[NightState.Ending.WON],
			{"received": state.videos.received, "quota": state.videos.quota}), ""])
	if night_number >= LAST_NIGHT:
		lines.append(_line(translate, VICTORY_KEY, {}))
	elif new_pages.is_empty():
		lines.append(_line(translate, NO_NEW_PAGES_KEY, {"night": night_number + 1}))
	else:
		var pages := ", ".join(PackedStringArray(new_pages.map(_escape)))
		lines.append(_line(translate, NEW_PAGES_KEY, {"night": night_number + 1, "pages": pages}))
	return "\n".join(lines)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
signal tutorial_skipped
```

por:

```gdscript
signal tutorial_skipped
## Los botones de la pantalla final: empezar la noche siguiente, reintentar la noche o volver al menú.
## Los atiende GameState.
signal next_night_requested
signal retry_requested
signal menu_requested
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
```

por:

```gdscript
	_end_screen.next_pressed.connect(next_night_requested.emit)
	_end_screen.menu_pressed.connect(menu_requested.emit)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_end_screen.show_ending(ending, _requests.state, fatal_request, names)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5).
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
```

por:

```gdscript
	var night_number := _requests.night_number
	var pages: Array[String] = []
	if ending == NightState.Ending.WON and night_number < _requests.catalog.nights.size():
		for entity: EntityData in _requests.catalog.new_pages(night_number + 1):
			pages.append(tr(entity.name_key))
	_end_screen.show_ending(ending, _requests.state, fatal_request, names, night_number, pages)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5). La reinicia
## GameState; si el escritorio se abrió solo, desde el editor, se recarga la escena.
func _on_retry_pressed() -> void:
	if retry_requested.get_connections().is_empty():
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()
```

En `scripts/ui/end_screen.gd`, reemplazar:

```gdscript
## escritorio, y tapa todo porque la noche ya terminó. Su botón vuelve a empezar la noche.
## Es provisional hasta el arte de las pantallas de victoria y derrota (docs/06 §3). El Plan 8 agrega
## el resumen entre noches y el paso a la noche siguiente.

## Se eligió volver a jugar: el escritorio reinicia la noche.
signal retry_pressed
```

por:

```gdscript
## escritorio, y tapa todo porque la noche ya terminó.
## Desde el Plan 8, al ganar es el resumen entre noches (diseño §5) y su botón empieza la noche siguiente; al
## perder, se reintenta la noche. Siempre se puede volver al menú. Al ganar la noche 5, solo queda el menú.
## Es provisional hasta el arte de las pantallas de victoria y derrota (docs/06 §3).

## Se eligió volver a jugar la noche.
signal retry_pressed
## Se eligió empezar la noche siguiente.
signal next_pressed
## Se eligió volver al menú principal.
signal menu_pressed
```

En `scripts/ui/end_screen.gd`, reemplazar:

```gdscript
## El botón (ui.csv): "Reintentar" al perder y "Jugar de nuevo" al ganar.
const RETRY_KEY := "END_RETRY"
const PLAY_AGAIN_KEY := "END_PLAY_AGAIN"
```

por:

```gdscript
## Los botones (ui.csv). END_NEXT lleva {night}.
const RETRY_KEY := "END_RETRY"
const NEXT_KEY := "END_NEXT"
const MENU_KEY := "END_MENU"
```

En `scripts/ui/end_screen.gd`, reemplazar:

```gdscript
@onready var _button: Button = $Center/Box/Retry
```

por:

```gdscript
@onready var _retry: Button = $Center/Box/Buttons/Retry
@onready var _next: Button = $Center/Box/Buttons/Next
@onready var _menu: Button = $Center/Box/Buttons/Menu
```

En `scripts/ui/end_screen.gd`, reemplazar:

```gdscript
	_button.pressed.connect(retry_pressed.emit)


## Muestra cómo terminó la noche. `friend_names` son los nombres de los amigos, en orden.
func show_ending(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String]) -> void:
	_title.text = EndingText.title(ending, tr)
	_body.text = EndingText.body(ending, state, fatal_request, friend_names, tr)
	_button.text = tr(PLAY_AGAIN_KEY if ending == NightState.Ending.WON else RETRY_KEY)
```

por:

```gdscript
	_retry.text = tr(RETRY_KEY)
	_menu.text = tr(MENU_KEY)
	_retry.pressed.connect(retry_pressed.emit)
	_next.pressed.connect(next_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)


## Muestra cómo terminó la noche `night_number`. `friend_names` son los nombres de los amigos, en orden, y
## `new_pages`, los nombres de las páginas que el cuaderno suma la noche siguiente.
func show_ending(ending: NightState.Ending, state: NightState, fatal_request: FriendRequest,
		friend_names: Array[String], night_number := 1, new_pages: Array[String] = []) -> void:
	var won := ending == NightState.Ending.WON
	if won:
		_title.text = EndingText.won_title(night_number, tr)
		_body.text = EndingText.summary(night_number, state, new_pages, tr)
	else:
		_title.text = EndingText.title(ending, tr)
		_body.text = EndingText.body(ending, state, fatal_request, friend_names, tr)
	_retry.visible = not won
	_next.visible = won and night_number < EndingText.LAST_NIGHT
	_next.text = tr(NEXT_KEY).format({"night": night_number + 1})
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `427 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ scenes/ data/ test/
git commit -m "El resumen entre noches y la victoria" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: El panel de opciones

**Archivos:**

- Crear: `scenes/ui/options_panel.tscn`, `scripts/ui/options_panel.gd`, `test/test_options_panel.gd`
- Modificar: `data/text/ui.csv`

`scenes/ui/options_panel.tscn`: los 3 volúmenes (deslizadores de 0 a 100) y las 3 opciones (casillas). Cada cambio llega a las opciones al tiro y el panel avisa (`changed`); quien lo abrió las guarda. El volumen se aplica al tiro. Lo usan el menú principal y el de pausa. Es provisional hasta el arte, con el tema del chat.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_options_panel.gd`:

```gdscript
extends "res://test/test_case.gd"
## Las opciones (diseño §19), en el panel que usan el menú principal y el de pausa.

const PANEL := preload("res://scenes/ui/options_panel.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")


func _make_panel() -> Control:
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	return panel


func test_empieza_oculto_y_muestra_las_opciones() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto")
	var settings := GameSettings.new()
	settings.volumes[&"Effects"] = 0.4
	settings.still_camera = true
	panel.open(settings)
	check(panel.visible, "se abre")
	check_eq((panel.get_node("Center/Box/Effects/Slider") as HSlider).value, 40.0, "volumen de los efectos")
	check_eq((panel.get_node("Center/Box/Master/Slider") as HSlider).value, 100.0, "volumen general")
	check((panel.get_node("Center/Box/Camera") as CheckBox).button_pressed, "cámara fija")
	check(not (panel.get_node("Center/Box/Flashes") as CheckBox).button_pressed, "destellos normales")
	panel.free()
	return true


## Cada cambio llega a las opciones al tiro, y el panel avisa para que se apliquen y se guarden.
func test_cada_cambio_se_aplica() -> bool:
	var panel := _make_panel()
	var settings := GameSettings.new()
	panel.open(settings)
	var changes := []
	panel.changed.connect(func(changed: GameSettings) -> void: changes.append(changed))
	(panel.get_node("Center/Box/Ambience/Slider") as HSlider).value = 25.0
	check_eq(settings.volumes[&"Ambience"], 0.25, "volumen del ambiente")
	(panel.get_node("Center/Box/Flashes") as CheckBox).button_pressed = true
	(panel.get_node("Center/Box/Camera") as CheckBox).button_pressed = true
	(panel.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
	check(settings.reduce_flashes and settings.still_camera and settings.slow_timers, "los interruptores")
	check_eq(changes.size(), 4, "avisa cada cambio")
	check(changes.all(func(changed: GameSettings) -> bool: return changed == settings), "con las opciones")
	GameSettings.new().apply_audio()
	panel.free()
	return true


func test_volver_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open(GameSettings.new())
	var closed := []
	panel.closed.connect(func() -> void: closed.append(true))
	(panel.get_node("Center/Box/Back") as Button).pressed.emit()
	check(not panel.visible, "se cierra")
	check_eq(closed, [true], "avisa")
	panel.free()
	return true


func test_sus_textos_existen() -> bool:
	var panel := _make_panel()
	for key: String in panel.TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	panel.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `427 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
OPTIONS_TITLE,Opciones,
OPTIONS_VOLUME_MASTER,Volumen general,
OPTIONS_VOLUME_AMBIENCE,Ambiente,
OPTIONS_VOLUME_EFFECTS,Efectos,
OPTIONS_REDUCE_FLASHES,Reducir destellos,
OPTIONS_STILL_CAMERA,Cámara fija (sin parallax),
OPTIONS_SLOW_TIMERS,"Temporizadores ×1,5 (más tiempo para responder)",
OPTIONS_BACK,Volver,
```

`scenes/ui/options_panel.tscn`:

```text
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/options_panel.gd" id="options_script"]
[ext_resource type="Theme" path="res://scenes/ui/chat_theme.tres" id="chat_theme"]

[node name="OptionsPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource("chat_theme")
script = ExtResource("options_script")

[node name="Shade" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.012, 0.024, 0.043, 0.95)

[node name="Center" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Box" type="VBoxContainer" parent="Center"]
custom_minimum_size = Vector2(480, 0)
layout_mode = 2
theme_override_constants/separation = 14

[node name="Title" type="Label" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 33
horizontal_alignment = 1

[node name="Master" type="HBoxContainer" parent="Center/Box"]
layout_mode = 2
theme_override_constants/separation = 22

[node name="Label" type="Label" parent="Center/Box/Master"]
custom_minimum_size = Vector2(220, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Slider" type="HSlider" parent="Center/Box/Master"]
custom_minimum_size = Vector2(220, 22)
layout_mode = 2
size_flags_vertical = 4
step = 5.0
value = 100.0

[node name="Ambience" type="HBoxContainer" parent="Center/Box"]
layout_mode = 2
theme_override_constants/separation = 22

[node name="Label" type="Label" parent="Center/Box/Ambience"]
custom_minimum_size = Vector2(220, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Slider" type="HSlider" parent="Center/Box/Ambience"]
custom_minimum_size = Vector2(220, 22)
layout_mode = 2
size_flags_vertical = 4
step = 5.0
value = 100.0

[node name="Effects" type="HBoxContainer" parent="Center/Box"]
layout_mode = 2
theme_override_constants/separation = 22

[node name="Label" type="Label" parent="Center/Box/Effects"]
custom_minimum_size = Vector2(220, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Slider" type="HSlider" parent="Center/Box/Effects"]
custom_minimum_size = Vector2(220, 22)
layout_mode = 2
size_flags_vertical = 4
step = 5.0
value = 100.0

[node name="Flashes" type="CheckBox" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Camera" type="CheckBox" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Timers" type="CheckBox" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Back" type="Button" parent="Center/Box"]
layout_mode = 2
size_flags_horizontal = 4
theme_override_font_sizes/font_size = 22
```

`scripts/ui/options_panel.gd`:

```gdscript
extends Control
## Las opciones (diseño §19): el volumen de cada canal, reducir destellos, la cámara fija (sin parallax) y los
## temporizadores ×1,5. Cada cambio llega a las opciones al tiro y el panel avisa (`changed`), para que quien lo
## abrió las aplique y las guarde. Lo usan el menú principal y el menú de pausa. Es provisional hasta el arte.

## Cambió una opción.
signal changed(settings: GameSettings)
## Se cerró con "Volver".
signal closed

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo.
const TEXT_KEYS := {
	"Title": "OPTIONS_TITLE",
	"Master": "OPTIONS_VOLUME_MASTER",
	"Ambience": "OPTIONS_VOLUME_AMBIENCE",
	"Effects": "OPTIONS_VOLUME_EFFECTS",
	"Flashes": "OPTIONS_REDUCE_FLASHES",
	"Camera": "OPTIONS_STILL_CAMERA",
	"Timers": "OPTIONS_SLOW_TIMERS",
	"Back": "OPTIONS_BACK",
}

var settings: GameSettings

@onready var _box: VBoxContainer = $Center/Box
@onready var _flashes: CheckBox = $Center/Box/Flashes
@onready var _camera: CheckBox = $Center/Box/Camera
@onready var _timers: CheckBox = $Center/Box/Timers


func _ready() -> void:
	hide()
	(_box.get_node("Title") as Label).text = tr(TEXT_KEYS["Title"])
	for bus: StringName in GameSettings.BUSES:
		var row := _box.get_node(String(bus))
		(row.get_node("Label") as Label).text = tr(TEXT_KEYS[String(bus)])
		(row.get_node("Slider") as HSlider).value_changed.connect(_on_volume_changed.bind(bus))
	for check_name: String in ["Flashes", "Camera", "Timers"]:
		var check_box := _box.get_node(check_name) as CheckBox
		check_box.text = tr(TEXT_KEYS[check_name])
		check_box.toggled.connect(_on_toggled.bind(check_name))
	var back := _box.get_node("Back") as Button
	back.text = tr(TEXT_KEYS["Back"])
	back.pressed.connect(close)


## Muestra las opciones de `game_settings`, que se cambian ahí mismo.
func open(game_settings: GameSettings) -> void:
	settings = null
	for bus: StringName in GameSettings.BUSES:
		(_box.get_node(String(bus) + "/Slider") as HSlider).value = game_settings.volumes[bus] * 100.0
	_flashes.button_pressed = game_settings.reduce_flashes
	_camera.button_pressed = game_settings.still_camera
	_timers.button_pressed = game_settings.slow_timers
	# Recién ahora: así, mostrar los valores no cuenta como un cambio.
	settings = game_settings
	show()


func close() -> void:
	hide()
	closed.emit()


## Esc y el clic derecho cierran el panel.
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_volume_changed(value: float, bus: StringName) -> void:
	if settings == null:
		return
	settings.volumes[bus] = value / 100.0
	settings.apply_audio()
	changed.emit(settings)


func _on_toggled(on: bool, check_name: String) -> void:
	if settings == null:
		return
	match check_name:
		"Flashes":
			settings.reduce_flashes = on
		"Camera":
			settings.still_camera = on
		"Timers":
			settings.slow_timers = on
	changed.emit(settings)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `431 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ scenes/ data/ test/
git commit -m "El panel de opciones" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: El menú principal y GameState

**Archivos:**

- Crear: `scenes/menu/main_menu.tscn`, `scripts/autoload/game_state.gd`, `scripts/ui/main_menu.gd`, `test/test_game_state.gd`, `test/test_main_menu.gd`
- Modificar: `data/text/ui.csv`, `project.godot`, `test/test_project_settings.gd`

`GameState` (autoload, `scripts/autoload/game_state.gd`) lleva el juego de punta a punta: Nueva partida empieza en la noche 0; Continuar, en la noche guardada; cada noche se guarda al empezar; "Empezar la noche N", "Reintentar", "Volver al menú" y "Saltar tutorial" llegan desde el escritorio. Arma el escritorio con `prepare_night()` (la noche, las opciones del jugador y sus señales) y lo muestra con `change_scene_to_node()`. Al ganar la noche 5 borra la partida. Lee las opciones al empezar el juego y las guarda cuando cambian.

El menú principal (`scenes/menu/main_menu.tscn`, diseño §5): el título, Continuar (solo con una partida guardada: "Continuar: noche N"), Nueva partida (con una partida guardada, pide confirmar), Opciones y Salir. Es la escena principal del proyecto. Es provisional hasta el arte del menú y el logo.

Las pruebas usan su propia copia de `GameState`, con un archivo de prueba, para no tocar la partida del jugador, y no cambian de escena.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_game_state.gd`:

```gdscript
extends "res://test/test_case.gd"
## El juego de punta a punta (diseño §5): las noches en orden y el guardado. Usa su propia copia de GameState,
## con archivos de prueba, para no tocar la partida ni las opciones del jugador.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const TEST_SAVE := "user://test_game_save.cfg"


func _make_game() -> Node:
	var game := GameStateScript.new()
	game.save = SaveGame.new(TEST_SAVE)
	game.save.clear()
	return game


func _free(game: Node) -> void:
	game.save.clear()
	game.free()


func test_la_noche_que_sigue() -> bool:
	var game := _make_game()
	check_eq(game.next_night_number(0), 1, "después del tutorial, la noche 1")
	check_eq(game.next_night_number(4), 5, "después de la 4, la 5")
	check_eq(game.next_night_number(5), -1, "después de la 5, se terminó el juego")
	_free(game)
	return true


## Cada noche se guarda al empezar (diseño §5), y el escritorio la juega con las opciones del jugador.
func test_preparar_una_noche_la_guarda() -> bool:
	var game := _make_game()
	game.settings.slow_timers = true
	var desk: Node = game.prepare_night(2)
	check_eq(game.night_number, 2, "la noche en curso")
	check_eq(game.save.stored_night(), 2, "guardada al empezar")
	check_eq(desk.get_node("RequestManager").night_number, 2, "el escritorio juega la noche 2")
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	check_eq(desk.get_node("RequestManager").timer_scale, 1.5, "con las opciones del jugador")
	check(desk.next_night_requested.is_connected(game.next_night), "seguir")
	check(desk.retry_requested.is_connected(game.retry), "reintentar")
	check(desk.menu_requested.is_connected(game.go_to_menu), "volver al menú")
	desk.free()
	_free(game)
	return true


## Al ganar la noche 5, el juego terminó: la partida se borra y "Continuar" desaparece del menú.
func test_al_ganar_la_ultima_noche_se_borra_la_partida() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(4)
	game._on_night_ended(NightState.Ending.WON, null)
	check_eq(game.save.stored_night(), 4, "la noche 4 no es la última")
	desk.free()
	desk = game.prepare_night(5)
	game._on_night_ended(NightState.Ending.SANITY, null)
	check(game.save.has_game(), "perder la noche 5 no la borra")
	game._on_night_ended(NightState.Ending.WON, null)
	check(not game.save.has_game(), "ganarla, sí")
	desk.free()
	_free(game)
	return true
```

`test/test_main_menu.gd`:

```gdscript
extends "res://test/test_case.gd"
## El menú principal (diseño §5): Continuar (solo con una partida guardada), Nueva partida, Opciones y Salir.

const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")


## El menú sin GameState: avisa con sus señales, y la prueba le dice qué partida hay.
func _make_menu(saved_night: int) -> Control:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	menu.setup(saved_night, GameSettings.new())
	return menu


func _button(menu: Control, button_name: String) -> Button:
	return menu.get_node("Center/Box/" + button_name) as Button


func _record(menu: Control, pressed: Array) -> void:
	for signal_name: String in ["continue_pressed", "new_game_pressed", "quit_pressed"]:
		menu.connect(signal_name, func() -> void: pressed.append(signal_name))


func test_sin_partida_no_se_continua() -> bool:
	var menu := _make_menu(-1)
	check(not _button(menu, "Continue").visible, "sin Continuar")
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	check_eq(pressed, ["new_game_pressed"], "empieza al tiro")
	menu.free()
	return true


func test_con_partida_se_continua() -> bool:
	var menu := _make_menu(2)
	var continue_button := _button(menu, "Continue")
	check(continue_button.visible, "con Continuar")
	check_eq(continue_button.text, String(TranslationServer.translate("MENU_CONTINUE")).format({"night": 2}), "noche 2")
	var pressed := []
	_record(menu, pressed)
	continue_button.pressed.emit()
	check_eq(pressed, ["continue_pressed"], "continúa")
	menu.free()
	menu = _make_menu(0)
	check_eq(_button(menu, "Continue").text, String(TranslationServer.translate("MENU_CONTINUE_TUTORIAL")), "el tutorial")
	menu.free()
	return true


## Con una partida guardada, empezar de nuevo pide confirmación: se pierde la partida.
func test_nueva_partida_pide_confirmar() -> bool:
	var menu := _make_menu(3)
	var pressed := []
	_record(menu, pressed)
	_button(menu, "NewGame").pressed.emit()
	var confirm := menu.get_node("Center/Box/Confirm") as Control
	check(confirm.visible, "pregunta")
	check_eq(pressed, [], "todavía no empieza")
	(confirm.get_node("Buttons/No") as Button).pressed.emit()
	check(not confirm.visible, "se cancela")
	_button(menu, "NewGame").pressed.emit()
	(confirm.get_node("Buttons/Yes") as Button).pressed.emit()
	check_eq(pressed, ["new_game_pressed"], "empieza de nuevo")
	menu.free()
	return true


func test_opciones_y_salir() -> bool:
	var menu := _make_menu(-1)
	_button(menu, "Options").pressed.emit()
	check((menu.get_node("OptionsPanel") as Control).visible, "abre las opciones")
	var pressed := []
	_record(menu, pressed)
	_button(menu, "Quit").pressed.emit()
	check_eq(pressed, ["quit_pressed"], "sale")
	menu.free()
	return true


func test_sus_textos_existen() -> bool:
	var menu := _make_menu(-1)
	for key: String in menu.TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	menu.free()
	return true
```

En `test/test_project_settings.gd`, reemplazar:

```gdscript
func test_escena_principal_es_el_escritorio() -> bool:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/desk/desk.tscn", "escena principal")
```

por:

```gdscript
## Desde el Plan 8, el juego empieza en el menú principal, y GameState lo lleva de noche en noche.
func test_escena_principal_es_el_menu() -> bool:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/menu/main_menu.tscn", "escena principal")
	check_eq(ProjectSettings.get_setting("autoload/GameState"), "*res://scripts/autoload/game_state.gd", "autoload")
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `430 pruebas OK, 3 fallidas`. `test_project_settings.gd` falla porque la escena principal todavía es el escritorio.

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
MENU_CONTINUE,Continuar: noche {night},
MENU_CONTINUE_TUTORIAL,Continuar: noche de práctica,
MENU_NEW_GAME,Nueva partida,
MENU_OPTIONS,Opciones,
MENU_QUIT,Salir,
MENU_CONFIRM_NEW,Se va a borrar la partida guardada. ¿Empezar de nuevo?,
MENU_YES,"Sí, empezar",
MENU_NO,Cancelar,
```

En `project.godot`, reemplazar:

```text
run/main_scene="res://scenes/desk/desk.tscn"
```

por:

```text
run/main_scene="res://scenes/menu/main_menu.tscn"
```

En `project.godot`, reemplazar:

```text
import/import_plugin/default_automatic_importer="SpriteFrames"
```

por:

```text
import/import_plugin/default_automatic_importer="SpriteFrames"

[autoload]

GameState="*res://scripts/autoload/game_state.gd"
```

`scenes/menu/main_menu.tscn`:

```text
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/main_menu.gd" id="menu_script"]
[ext_resource type="Theme" path="res://scenes/ui/chat_theme.tres" id="chat_theme"]
[ext_resource type="PackedScene" path="res://scenes/ui/options_panel.tscn" id="options_panel"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource("chat_theme")
script = ExtResource("menu_script")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.012, 0.024, 0.043, 1)

[node name="Center" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Box" type="VBoxContainer" parent="Center"]
custom_minimum_size = Vector2(440, 0)
layout_mode = 2
theme_override_constants/separation = 14

[node name="Title" type="Label" parent="Center/Box"]
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.72, 0.3, 1)
theme_override_font_sizes/font_size = 66
text = "SPOOK DIAL"
horizontal_alignment = 1

[node name="Space" type="Control" parent="Center/Box"]
custom_minimum_size = Vector2(0, 22)
layout_mode = 2

[node name="Continue" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="NewGame" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Options" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Quit" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Confirm" type="VBoxContainer" parent="Center/Box"]
visible = false
layout_mode = 2
theme_override_constants/separation = 11

[node name="Question" type="Label" parent="Center/Box/Confirm"]
custom_minimum_size = Vector2(440, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
horizontal_alignment = 1
autowrap_mode = 3

[node name="Buttons" type="HBoxContainer" parent="Center/Box/Confirm"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 22

[node name="Yes" type="Button" parent="Center/Box/Confirm/Buttons"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="No" type="Button" parent="Center/Box/Confirm/Buttons"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="OptionsPanel" parent="." instance=ExtResource("options_panel")]
layout_mode = 1
```

`scripts/autoload/game_state.gd`:

```gdscript
extends Node
## El juego de punta a punta (diseño §5), como autoload: el menú, las noches en orden desde la 0 (el tutorial),
## el guardado al comienzo de cada noche, el paso a la siguiente, reintentar una noche y volver al menú.
## También tiene las opciones del jugador (diseño §19), que se leen al empezar y se guardan al cambiarlas.

const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const SaveGame := preload("res://scripts/core/save_game.gd")
const DESK_SCENE := preload("res://scenes/desk/desk.tscn")

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const SAVE_PATH := "user://save.cfg"
const SETTINGS_PATH := "user://settings.cfg"
## Al ganar la última noche, el juego termina (diseño §5).
const LAST_NIGHT := 5

var settings := GameSettings.new()
var save := SaveGame.new(SAVE_PATH)
## La noche que se está jugando.
var night_number := 0


func _ready() -> void:
	settings.read(SETTINGS_PATH)
	settings.apply_audio()


## Nueva partida: empieza en la noche 0, el tutorial.
func new_game() -> void:
	start_night(0)


## Continuar: vuelve a empezar la noche guardada.
func continue_game() -> void:
	start_night(maxi(save.stored_night(), 0))


func start_night(number: int) -> void:
	_show(prepare_night(number))


## Reintentar: la noche empieza de nuevo y se vuelve a generar (diseño §5).
func retry() -> void:
	start_night(night_number)


## Empieza la noche siguiente o, después de la última, vuelve al menú.
func next_night() -> void:
	var next := next_night_number(night_number)
	if next < 0:
		go_to_menu()
	else:
		start_night(next)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func save_settings() -> void:
	settings.write(SETTINGS_PATH)


## La noche que sigue a `number`, o -1 si era la última.
func next_night_number(number: int) -> int:
	return number + 1 if number < LAST_NIGHT else -1


## Guarda la noche `number` (se guarda al comienzo, diseño §5) y arma su escritorio, con las opciones del
## jugador y sus botones conectados: saltar el tutorial, seguir, reintentar y volver al menú.
func prepare_night(number: int) -> Node:
	night_number = number
	save.store(number)
	var desk := DESK_SCENE.instantiate()
	desk.get_node("RequestManager").night_number = number
	desk.ready.connect(func() -> void: desk.apply_settings(settings), CONNECT_ONE_SHOT)
	desk.tutorial_skipped.connect(start_night.bind(1))
	desk.next_night_requested.connect(next_night)
	desk.retry_requested.connect(retry)
	desk.menu_requested.connect(go_to_menu)
	desk.get_node("NightManager").night_ended.connect(_on_night_ended)
	return desk


## Al ganar la última noche, el juego terminó: la partida se borra.
func _on_night_ended(ending: NightState.Ending, _fatal_request: RefCounted) -> void:
	if ending == NightState.Ending.WON and night_number >= LAST_NIGHT:
		save.clear()


func _show(scene: Node) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_node(scene)
```

`scripts/ui/main_menu.gd`:

```gdscript
extends Control
## El menú principal (diseño §5): Continuar (solo si hay una partida guardada), Nueva partida, Opciones y Salir.
## Con una partida guardada, Nueva partida pide confirmar, porque la borra. Lo atiende GameState.
## Es provisional hasta el arte del menú y el logo (docs/06 §3).

signal continue_pressed
signal new_game_pressed
signal quit_pressed
## Cambió una opción: hay que guardarla.
signal settings_changed(settings: GameSettings)

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo. MENU_CONTINUE lleva {night}.
const TEXT_KEYS := {
	"Continue": "MENU_CONTINUE",
	"ContinueTutorial": "MENU_CONTINUE_TUTORIAL",
	"NewGame": "MENU_NEW_GAME",
	"Options": "MENU_OPTIONS",
	"Quit": "MENU_QUIT",
	"Question": "MENU_CONFIRM_NEW",
	"Yes": "MENU_YES",
	"No": "MENU_NO",
}

## Con false (en las pruebas), el menú no se conecta a GameState: solo avisa con sus señales.
@export var use_game_state := true

var _settings := GameSettings.new()

@onready var _continue: Button = $Center/Box/Continue
@onready var _new_game: Button = $Center/Box/NewGame
@onready var _options_button: Button = $Center/Box/Options
@onready var _quit: Button = $Center/Box/Quit
@onready var _confirm: Control = $Center/Box/Confirm
@onready var _options: Control = $OptionsPanel

## La noche guardada, o -1 si no hay partida.
var _saved_night := -1


func _ready() -> void:
	_new_game.text = tr(TEXT_KEYS["NewGame"])
	_options_button.text = tr(TEXT_KEYS["Options"])
	_quit.text = tr(TEXT_KEYS["Quit"])
	(_confirm.get_node("Question") as Label).text = tr(TEXT_KEYS["Question"])
	var yes := _confirm.get_node("Buttons/Yes") as Button
	var no := _confirm.get_node("Buttons/No") as Button
	yes.text = tr(TEXT_KEYS["Yes"])
	no.text = tr(TEXT_KEYS["No"])
	_confirm.hide()
	_continue.pressed.connect(continue_pressed.emit)
	_new_game.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(func() -> void: _options.open(_settings))
	_quit.pressed.connect(quit_pressed.emit)
	yes.pressed.connect(new_game_pressed.emit)
	no.pressed.connect(_confirm.hide)
	_options.changed.connect(settings_changed.emit)
	if use_game_state:
		var game := get_node("/root/GameState")
		setup(game.save.stored_night(), game.settings)
		continue_pressed.connect(game.continue_game)
		new_game_pressed.connect(game.new_game)
		quit_pressed.connect(get_tree().quit)
		settings_changed.connect(func(_settings_changed: GameSettings) -> void: game.save_settings())
	else:
		setup(-1, _settings)


## Muestra Continuar si hay una partida guardada (`saved_night`, o -1), y usa `settings` en las opciones.
func setup(saved_night: int, settings: GameSettings) -> void:
	_saved_night = saved_night
	_settings = settings
	_continue.visible = saved_night >= 0
	if saved_night == 0:
		_continue.text = tr(TEXT_KEYS["ContinueTutorial"])
	else:
		_continue.text = tr(TEXT_KEYS["Continue"]).format({"night": saved_night})


## Sin partida guardada, empieza al tiro; con una, primero pregunta.
func _on_new_game_pressed() -> void:
	if _saved_night < 0:
		new_game_pressed.emit()
	else:
		_confirm.show()
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `439 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add project.godot scripts/ scenes/ data/ test/
git commit -m "El menú principal y GameState" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 13: El menú de pausa

**Archivos:**

- Crear: `scenes/ui/pause_menu.tscn`, `scripts/ui/pause_menu.gd`, `test/test_pause_menu.gd`
- Modificar: `data/text/ui.csv`, `scenes/desk/desk.tscn`, `scripts/autoload/game_state.gd`, `scripts/desk/desk.gd`, `test/test_game_state.gd`

Con Esc y sin nada abierto, la noche se pausa (`get_tree().paused`) y aparece el menú de pausa (decisión de Benja, sesión 18): Continuar, Opciones y Volver al menú. Funciona en pausa (`process_mode` siempre). Con un panel abierto, Esc solo lo cierra, como antes, y una noche que terminó no se pausa. Las opciones cambiadas en la pausa se aplican al escritorio y `GameState` las guarda. Volver al menú pierde la noche: Continuar la empieza desde su comienzo, porque se guardó al empezar.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_game_state.gd`:

```gdscript
## Las opciones cambiadas en la pausa se guardan.
func test_las_opciones_de_la_pausa_se_guardan() -> bool:
	var game := _make_game()
	var desk: Node = game.prepare_night(1)
	check_eq(desk.settings_changed.get_connections().size(), 1, "GameState las guarda")
	desk.free()
	_free(game)
	return true
```

`test/test_pause_menu.gd`:

```gdscript
extends "res://test/test_case.gd"
## El menú de pausa (decisión de Benja, sesión 18): con Esc y sin paneles abiertos, la noche se pausa. Desde ahí
## se sigue, se cambian las opciones o se vuelve al menú principal.

const DESK := preload("res://scenes/desk/desk.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func _escape() -> InputEventAction:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	return escape


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _pause_menu(desk: Node2D) -> Control:
	return desk.get_node("Overlay/PauseMenu") as Control


func test_esc_pausa_y_continuar_sigue() -> bool:
	var desk := _make_desk()
	var menu := _pause_menu(desk)
	check(not menu.visible, "oculto")
	desk._unhandled_input(_escape())
	check(_tree().paused, "la noche se pausa")
	check(menu.visible, "aparece el menú de pausa")
	check_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "funciona en pausa")
	(menu.get_node("Center/Box/Resume") as Button).pressed.emit()
	check(not _tree().paused, "sigue la noche")
	check(not menu.visible, "se va")
	_tree().paused = false
	desk.free()
	return true


func test_con_un_panel_abierto_esc_solo_lo_cierra() -> bool:
	var desk := _make_desk()
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk._unhandled_input(_escape())
	check(not (desk.get_node("UI/ChatPanel") as Control).visible, "se cerró el chat")
	check(not _tree().paused, "sin pausa")
	_tree().paused = false
	desk.free()
	return true


func test_al_terminar_la_noche_no_se_pausa() -> bool:
	var desk := _make_desk()
	desk.get_node("NightManager").finish(NightState.Ending.SANITY)
	desk._unhandled_input(_escape())
	check(not _tree().paused, "sin pausa")
	_tree().paused = false
	desk.free()
	return true


func test_volver_al_menu() -> bool:
	var desk := _make_desk()
	var requested := []
	desk.menu_requested.connect(func() -> void: requested.append(true))
	desk._unhandled_input(_escape())
	(_pause_menu(desk).get_node("Center/Box/Menu") as Button).pressed.emit()
	check_eq(requested, [true], "pide volver al menú")
	_tree().paused = false
	desk.free()
	return true


## Las opciones cambiadas en la pausa se aplican al escritorio y se avisan, para guardarlas.
func test_las_opciones_de_la_pausa() -> bool:
	var desk := _make_desk()
	var settings := GameSettings.new()
	desk.apply_settings(settings)
	var saved := []
	desk.settings_changed.connect(func(changed: GameSettings) -> void: saved.append(changed))
	desk._unhandled_input(_escape())
	var menu := _pause_menu(desk)
	(menu.get_node("Center/Box/Options") as Button).pressed.emit()
	var options := menu.get_node("OptionsPanel") as Control
	check(options.visible, "se abren las opciones")
	(options.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
	check_eq(desk.get_node("RequestManager").timer_scale, 1.5, "se aplican al escritorio")
	check_eq(saved, [settings], "y se avisan")
	_tree().paused = false
	desk.free()
	return true


func test_sus_textos_existen() -> bool:
	var desk := _make_desk()
	for key: String in _pause_menu(desk).TEXT_KEYS.values():
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `441 pruebas OK, 5 fallidas`.

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
PAUSE_TITLE,Pausa,
PAUSE_RESUME,Continuar,
PAUSE_OPTIONS,Opciones,
PAUSE_MENU,Volver al menú,
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

por:

```text
[ext_resource type="PackedScene" path="res://scenes/ui/pause_menu.tscn" id="pause_menu"]
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

por:

```text
[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]

[node name="PauseMenu" parent="Overlay" instance=ExtResource("pause_menu")]
```

`scenes/ui/pause_menu.tscn`:

```text
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/pause_menu.gd" id="pause_script"]
[ext_resource type="Theme" path="res://scenes/ui/chat_theme.tres" id="chat_theme"]
[ext_resource type="PackedScene" path="res://scenes/ui/options_panel.tscn" id="options_panel"]

[node name="PauseMenu" type="Control"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource("chat_theme")
script = ExtResource("pause_script")

[node name="Shade" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.012, 0.024, 0.043, 0.85)

[node name="Center" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Box" type="VBoxContainer" parent="Center"]
custom_minimum_size = Vector2(320, 0)
layout_mode = 2
theme_override_constants/separation = 14

[node name="Title" type="Label" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 33
horizontal_alignment = 1

[node name="Resume" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Options" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Menu" type="Button" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="OptionsPanel" parent="." instance=ExtResource("options_panel")]
layout_mode = 1
```

En `scripts/autoload/game_state.gd`, reemplazar:

```gdscript
## jugador y sus botones conectados: saltar el tutorial, seguir, reintentar y volver al menú.
```

por:

```gdscript
## jugador y sus botones conectados: saltar el tutorial, seguir, reintentar y volver al menú. Las opciones que
## se cambian en la pausa se guardan.
```

En `scripts/autoload/game_state.gd`, reemplazar:

```gdscript
	desk.get_node("NightManager").night_ended.connect(_on_night_ended)
```

por:

```gdscript
	desk.settings_changed.connect(func(_changed: GameSettings) -> void: save_settings())
	desk.get_node("NightManager").night_ended.connect(_on_night_ended)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## (TutorialGuide), y la noche termina al cerrar el celular. El aviso tiene un botón para saltar el tutorial.
```

por:

```gdscript
## (TutorialGuide), y la noche termina al cerrar el celular. El aviso tiene un botón para saltar el tutorial.
## Con Esc y sin nada abierto, la noche se pausa y aparece el menú de pausa (decisión de Benja, sesión 18).
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
signal menu_requested
```

por:

```gdscript
signal menu_requested
## Cambió una opción desde el menú de pausa: GameState la guarda.
signal settings_changed(settings: GameSettings)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _tutorial_hint: Control = $Overlay/TutorialHint
```

por:

```gdscript
@onready var _tutorial_hint: Control = $Overlay/TutorialHint
@onready var _pause_menu: Control = $Overlay/PauseMenu

## Las opciones del jugador que se aplicaron; el menú de pausa las cambia.
var _settings := GameSettings.new()
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_tutorial_hint.visible = _guide != null
```

por:

```gdscript
	_tutorial_hint.visible = _guide != null
	_pause_menu.resumed.connect(func() -> void: get_tree().paused = false)
	_pause_menu.menu_pressed.connect(menu_requested.emit)
	_pause_menu.settings_changed.connect(_on_pause_settings_changed)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	for entry: Node in _entries:
```

por:

```gdscript
	_settings = settings
	for entry: Node in _entries:
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_requests.timer_scale = settings.timer_scale()
```

por:

```gdscript
	_requests.timer_scale = settings.timer_scale()


## Pausa la noche y abre el menú de pausa. Una noche que terminó no se pausa.
func pause() -> void:
	if _night.ended:
		return
	get_tree().paused = true
	_pause_menu.open(_settings)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## ellos. Esc o un clic fuera de ellos los cierra.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible or _mixer.visible or _phone.visible):
```

por:

```gdscript
## ellos. Esc o un clic fuera de ellos los cierra. Sin nada abierto, Esc pausa la noche.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible or _mixer.visible or _phone.visible):
		if event.is_action_pressed(&"ui_cancel"):
			pause()
			get_viewport().set_input_as_handled()
```

Agregar al final de `scripts/desk/desk.gd`:

```gdscript
func _on_pause_settings_changed(settings: GameSettings) -> void:
	apply_settings(settings)
	settings_changed.emit(settings)
```

`scripts/ui/pause_menu.gd`:

```gdscript
extends Control
## El menú de pausa (decisión de Benja, sesión 18): con Esc y sin paneles abiertos, la noche se pausa y aparece
## este menú: Continuar, Opciones y Volver al menú (la noche se pierde y, al continuar la partida, se juega desde
## su comienzo). Funciona con el juego en pausa. Es provisional hasta el arte.

## Se eligió seguir la noche.
signal resumed
## Se eligió volver al menú principal.
signal menu_pressed
## Cambió una opción.
signal settings_changed(settings: GameSettings)

const GameSettings := preload("res://scripts/core/game_settings.gd")

## Los textos (ui.csv), por el nombre de su nodo.
const TEXT_KEYS := {
	"Title": "PAUSE_TITLE",
	"Resume": "PAUSE_RESUME",
	"Options": "PAUSE_OPTIONS",
	"Menu": "PAUSE_MENU",
}

var _settings := GameSettings.new()

@onready var _options: Control = $OptionsPanel


func _ready() -> void:
	hide()
	for node_name: String in TEXT_KEYS:
		get_node("Center/Box/" + node_name).text = tr(TEXT_KEYS[node_name])
	($Center/Box/Resume as Button).pressed.connect(resume)
	($Center/Box/Options as Button).pressed.connect(func() -> void: _options.open(_settings))
	($Center/Box/Menu as Button).pressed.connect(menu_pressed.emit)
	_options.changed.connect(settings_changed.emit)


## Aparece, con `settings` para sus opciones.
func open(settings: GameSettings) -> void:
	_settings = settings
	show()


func resume() -> void:
	_options.hide()
	hide()
	resumed.emit()


## Esc sigue la noche. Con las opciones abiertas, Esc las cierra primero (OptionsPanel lo atiende antes).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		resume()
		get_viewport().set_input_as_handled()
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `446 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.uid` que Godot creó al importar.

```bash
git add scripts/ scenes/ data/ test/
git commit -m "El menú de pausa" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 14: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_plan8.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/02_bucle_central.md`, `resumen.md`, `docs/00_log.md`

Las pruebas cubren la lógica y la escena; las capturas confirman que el menú, el aviso del tutorial, el resumen y las opciones se ven bien. Después, `docs/04` recibe la sección L, para que Benja pruebe el juego de punta a punta.

- [ ] **Paso 1: Crear el script de capturas**

`test/capture_plan8.gd`:

```gdscript
extends SceneTree
## Capturas del Plan 8 para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan8.gd -- /mnt/c/dev/capturas/plan8_menu.png /mnt/c/dev/capturas/plan8_tutorial.png /mnt/c/dev/capturas/plan8_summary.png /mnt/c/dev/capturas/plan8_pause.png
## 1. El menú principal, con una partida guardada en la noche 2.
## 2. La noche 0: la solicitud de León con su chat abierto y el aviso que pide preguntar.
## 3. El resumen al ganar la noche 1: los videos y las páginas nuevas de la noche 2.
## 4. El menú de pausa, con las opciones abiertas.

const DESK := preload("res://scenes/desk/desk.tscn")
const MENU := preload("res://scenes/menu/main_menu.tscn")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var menu := MENU.instantiate()
	menu.use_game_state = false
	root.add_child(menu)
	menu.setup(2, GameSettings.new())
	await create_timer(0.2).timeout
	await _save(0)
	menu.free()
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 0
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	desk.get_node("NightManager").advance(5.5)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(1)
	desk.free()
	desk = DESK.instantiate()
	desk.get_node("RequestManager").night_number = 1
	desk.get_node("RequestManager").requests_arrive = false
	root.add_child(desk)
	var state: NightState = desk.get_node("RequestManager").state
	state.videos.received = state.videos.quota
	state.elapsed = 419.0
	desk.get_node("NightManager").advance(1.0)
	await create_timer(1.8).timeout
	await _save(2)
	desk.free()
	desk = DESK.instantiate()
	desk.get_node("RequestManager").requests_arrive = false
	root.add_child(desk)
	desk.pause()
	desk.get_node("Overlay/PauseMenu/Center/Box/Options").pressed.emit()
	await create_timer(0.2).timeout
	await _save(3)
	paused = false
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

- [ ] **Paso 2: Sacar las capturas y revisarlas**

Corre con ventana (sin `--headless`), y Godot tiene que estar cerrado:

```bash
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan8.gd -- /mnt/c/dev/capturas/plan8_menu.png /mnt/c/dev/capturas/plan8_tutorial.png /mnt/c/dev/capturas/plan8_summary.png /mnt/c/dev/capturas/plan8_pause.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: 4 líneas `Captura guardada en …` y ningún `ERROR`. Abrir cada imagen con Read y revisar:

- `plan8_menu.png`: "SPOOK DIAL" en ámbar, centrado, y debajo 4 botones: "Continuar: noche 2", "Nueva partida", "Opciones" y "Salir".
- `plan8_tutorial.png`: el escritorio con el chat de León abierto a la izquierda y su mensaje ("¡Mati, ayuda!!", el lugar y una pista subrayada). Arriba, entre el chat y los diales, el aviso con borde ámbar: "Noche de práctica", el texto que pide preguntar y el botón "Saltar tutorial". El PC dice "Videos: 0 de 1".
- `plan8_summary.png`: la pantalla final sobre el escritorio oscurecido: "Llegaste a las 06:00", los videos ("2 de 2"), "Para la noche 2, el cuaderno suma: El Cuero, La Viuda." y los botones "Empezar la noche 2" y "Volver al menú".
- `plan8_pause.png`: el panel de opciones sobre el menú de pausa: "Opciones", 3 deslizadores (volumen general, ambiente y efectos) y 3 casillas ("Reducir destellos", "Cámara fija (sin parallax)" y "Temporizadores ×1,5 (más tiempo para responder)"), y "Volver".

Si algo no coincide, corregirlo antes de seguir.

- [ ] **Paso 3: Instrucciones para Benja y documentos**

En `docs/04_instrucciones_godot.md`, reemplazar:

````markdown
| **K.** Probar los screamers y el director (Plan 7) | ⬜ Pendiente (unos 20 minutos) |
````

por:

````markdown
| **K.** Probar los screamers y el director (Plan 7) | ⬜ Pendiente (unos 20 minutos) |
| **L.** Probar las noches, el menú, el guardado y las opciones (Plan 8) | ⬜ Pendiente (unos 25 minutos) |
````

En `docs/04_instrucciones_godot.md`, reemplazar:

````markdown
6. **El susto guionado:** en el panel **Scene**, selecciona el nodo `RequestManager` y, en el **Inspector**, cambia **Night Number** de 3 a 1. Presiona **F5**. La noche 1 todavía no tiene entidades, así que no llegan solicitudes.
   - Al minuto (cerca de las 00:51), las luces parpadean y llega el jumpscare.
   - Unos segundos después, la entrada de Gonzalo parpadea. Abre su chat: "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar". Abajo, en lugar de las respuestas, hay un botón con la respuesta de Matías. Presiónalo.
   - Gonzalo contesta "Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar". Cierra el chat: el borde del celular parpadea. Haz clic en el celular: se abre y deja de parpadear.
   - **Al terminar, vuelve Night Number a 3.**
````

por:

````markdown
6. **El susto guionado:** desde el Plan 8 está en la noche 0, la noche de práctica (sección L, paso 2).
````

Agregar al final de `docs/04_instrucciones_godot.md`:

````markdown
---

## L. Probar las noches, el menú, el guardado y las opciones (Plan 8)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto, y presiona **F5**. Ahora el juego empieza en el **menú principal**: "SPOOK DIAL", **Nueva partida**, **Opciones** y **Salir**. La primera vez no está **Continuar**, porque no hay una partida guardada.
2. **La noche 0, la noche de práctica:** presiona **Nueva partida**. Arriba, entre el chat y los diales, un aviso dice qué hacer en cada paso. En esta noche el tiempo para responder no corre solo (solo lo gastan las preguntas) y nadie sale herido. Síguelo:
   - León te escribe: abre su chat con su entrada del PC, pregunta, marca las 2 características, haz clic en el nombre de la criatura y responde con la acción de la primera regla que se cumple.
   - Agustín: lo mismo. Al terminar te manda un video: abre su chat y mantén presionada la barra hasta que se descargue. La siguiente solicitud espera el video.
   - Gonzalo: su mensaje no trae pista. Prueba a responder con una acción equivocada: el aviso dice que, en una noche de verdad, habría salido herido.
   - Unos segundos después llega el susto (el jumpscare) y Gonzalo te escribe. Respóndele con el botón. Después, el borde del celular parpadea: ábrelo, scrollea con la rueda y ciérralo con clic derecho. Ahí termina la práctica.
3. **El final de la práctica:** la pantalla dice "Práctica terminada". Presiona **Empezar la noche 1**.
4. **La noche 1 y el resumen:** aparecen El Tue Tué y La Calchona. Si pierdes, **Reintentar** vuelve a empezar la noche. Si llegas a las 06:00 con la cuota, el resumen dice cuántos videos conseguiste y qué páginas suma el cuaderno la noche siguiente (después de la noche 1: El Cuero y La Viuda), con **Empezar la noche 2** y **Volver al menú**.
5. **La pausa y el guardado:** en una noche, sin ningún panel abierto, presiona **Esc**: la noche se detiene y aparece el menú de pausa (**Continuar**, **Opciones** y **Volver al menú**). Con un panel abierto, **Esc** solo cierra los paneles, como antes. Presiona **Volver al menú**: ahora el menú tiene **Continuar: noche 1**, que empieza la noche desde su comienzo. Cierra el juego, presiona **F5** otra vez: **Continuar** sigue ahí.
6. **Nueva partida con una partida guardada:** el menú pregunta si quieres borrarla. **Cancelar** no hace nada.
7. **Las opciones** (desde el menú o desde la pausa):
   - los 3 volúmenes (general, ambiente y efectos) cambian el sonido al tiro;
   - **Reducir destellos:** las entradas en alerta quedan fijas en lugar de parpadear, el aviso de una interferencia atenúa la entrada sin titilar, el LED del mixer no parpadea, y la señal previa de un screamer, el apagón de las luces y el rojo del jumpscare se oscurecen una sola vez;
   - **Cámara fija:** la escena deja de moverse con el mouse;
   - **Temporizadores ×1,5:** las solicitudes nuevas dan 1,5 veces más tiempo para responder (los plazos de los videos no cambian).
   - Cierra y vuelve a abrir el juego: las opciones se mantienen.
8. **Saltar la práctica:** con **Nueva partida**, el botón **Saltar tutorial** del aviso pasa directo a la noche 1.

**Verifica:** los pasos 1 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

**Para probar una noche sin pasar por las anteriores:** abre `scenes/desk/desk.tscn`, selecciona el nodo `RequestManager` en el panel **Scene** y cambia **Night Number** (de 0 a 5) en el **Inspector**. Presiona **F6**, que ejecuta solo la escena abierta, sin el menú: así no se guarda nada. Al terminar, vuelve a dejar 3.

### Para ajustar

- **La noche 0** está en `data/nights/night_0.tres`. En el grupo **Tutorial**, **Tutorial Requests** tiene las 3 solicitudes fijas, en orden: quién la pide (**Friend**), qué entidad es (**Entity**), qué observa el amigo (**Situation**: el id de cada observación y su valor; lo que falte sale al azar), si el mensaje inicial trae una pista (**With Hint**) y si al terminar el amigo manda un video (**Sends Video**). El susto y su chat están en el grupo **Guion**, como antes: en la noche 0, el susto llega cuando ya no queda nada pendiente.
- **Los textos nuevos** están en `data/text/ui.csv`: el aviso de la práctica (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el final y el resumen (`END_*`).
- **Las 7 entidades** están en `data/entities/`, un `.tres` cada una, y sus textos en `data/text/messages.csv` y `data/text/notebook.csv`. Son un borrador de Claude: corrígelas en el **Inspector** (como en la sección F) y en los CSV. Las pruebas avisan si algo no cumple la plantilla.
- **La partida y las opciones** se guardan en `%APPDATA%\Godot\app_userdata\Spook Dial\` (`save.cfg` y `settings.cfg`). Para empezar de cero, borra `save.cfg`.
````

En `docs/06_plan_v1.md`, reemplazar:

````markdown
- Cada plan siguiente se escribe en detalle al comenzar su sesión, con el mismo formato (skill `superpowers:writing-plans`).
````

por:

````markdown
- El **Plan 8** está escrito paso a paso en `docs/15_plan_noches_menu.md` (ejecutado).
- Cada plan siguiente se escribe en detalle al comenzar su sesión, con el mismo formato (skill `superpowers:writing-plans`).
````

En `docs/02_bucle_central.md`, reemplazar:

````markdown
                 scripted_scare_time, scripted_scare (ScareKind), scripted_chat (ChatScriptData)
````

por:

````markdown
                 scripted_scare_time, scripted_scare (ScareKind), scripted_chat (ChatScriptData),
                 tutorial_requests[] (solo la noche 0)
TutorialRequestData  una solicitud fija de la noche 0: friend, entity, situation {observación → valor},
                 with_hint, sends_video
````

En `docs/02_bucle_central.md`, reemplazar:

````markdown
ContentCatalog   friends[3], nights[5], decoys[], greeting_keys[] (saludos), balance, phone_posts[] (data/catalog.tres)
````

por:

````markdown
ContentCatalog   friends[3], nights[5], tutorial (la noche 0), decoys[], greeting_keys[] (saludos), balance,
                 phone_posts[] (data/catalog.tres)
````

En `docs/02_bucle_central.md`, reemplazar:

````markdown
- Las entidades conocidas en una noche son las `new_entities` de esa noche y de las anteriores (ya no existe `intro_night`).
````

por:

````markdown
- Las entidades conocidas en una noche son las `new_entities` de esa noche y de las anteriores (ya no existe `intro_night`). La noche 0 (el tutorial) usa las de la noche 1.
````

- [ ] **Paso 4: Cerrar la sesión**

- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar:
  - la sección L de `docs/04`;
  - las 7 entidades, que son un borrador de Claude: corregirlas en el Inspector (`data/entities/`) y en los CSV antes del congelamiento del contenido (25 de noviembre);
  - entre los textos que Benja corrige: el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`), el resumen y la victoria (`END_TUTORIAL*`, `END_VICTORY*`, `END_NEW_PAGES`, `END_NO_NEW_PAGES`, `END_NEXT` y `END_MENU`), en `ui.csv`; y en `messages.csv` y `notebook.csv`, los textos de las 7 entidades y los 7 señuelos nuevos;
  - el arte del menú y el logo (ver "Fuera de este plan").
- En los Pendientes Código, marcar como hechos los del Plan 8 que arrastraba `resumen.md` (la noche 0, "Reducir destellos", "Temporizadores ×1,5", las entidades en `.tres` y el Night Number de `RequestManager`, que ahora elige `GameState`), y dejar abierto el registro de los `.en.translation`.
- `docs/00_log.md`:
  - S19 queda ✅;
  - S20 (correcciones tras las pruebas con personas) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/15` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md test/
git commit -m "Plan 8 terminado: noches, menú, guardado y opciones" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Fuera de este plan, a propósito

- **El arte de Benja** (`arte_pendiente.md` y `docs/06` §3): el menú principal y el logo, las pantallas de victoria y derrota, y, si las quiere, el aviso del tutorial, la pausa y las opciones. Hoy son provisionales, con el tema del chat y Departure Mono. Cuando llegue el arte, Claude lo integra sin cambiar la lógica ni las pruebas de comportamiento.
- **Las cinemáticas** (prioridad 2, `docs/05` #12): la de introducción iría antes de la noche 0, y la de entre noches, después del resumen. El resumen ya es el punto donde se pasa de una noche a otra.
- **La traducción al inglés** (prioridad 2): registrar los `.en.translation` cuando la columna `en` tenga textos (pendiente que sigue abierto). Si hace falta, una opción de idioma iría en el panel de opciones.
- **Plan 9 (sonido):** los sonidos van a los canales que crea este plan (`Ambience` y `Effects`). Si se separan más canales (screamers, voces), se agregan a `GameSettings.BUSES` y al panel de opciones. Los sonidos del menú y de los botones también son del Plan 9.
- **El equilibrio de las 5 noches** (`docs/02` §6) no cambia en este plan: con las 7 entidades ya se puede probar de verdad, y se ajusta en S20 con las pruebas con personas.
- **El largo de la noche 0:** si en las pruebas con personas resulta larga o corta, se ajusta en `data/nights/night_0.tres` (cuántas solicitudes y cuáles), sin código.
- **Abrir el escritorio solo** (F6 desde el editor): "Reintentar" recarga la escena, pero "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`. El juego se prueba desde el menú (F5).
- **Después de la v1** (`docs/05`): la progresión guionada entre los amigos. Los chats guionados ya son datos de una noche.

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 8; diseño §5, §13, §14 y §19; decisiones de Benja):

  | Requisito | Tarea |
  | --- | --- |
  | La noche 0, guiada y sin perder: solicitudes fijas, el aviso con cada paso, el tiempo que espera y nadie herido (decisión de Benja) | 1, 2, 3, 4, 5 y 6 |
  | La noche 0 enseña a preguntar (pendiente del 3-nov), a identificar, a responder desde el cuaderno y a descargar un video | 4, 5 y 6 |
  | El susto guionado y su chat pasan a la noche 0 y enseñan el celular | 3, 5 y 6 |
  | Se puede saltar la noche 0 | 6 y 12 |
  | Las 5 noches como datos, con las 7 entidades en su noche (diseño §13) | 5 |
  | Menú principal: Continuar (solo con partida), Nueva partida, Opciones y Salir | 12 |
  | Guardado al comienzo de cada noche | 8 y 12 |
  | Resumen entre noches: el contenido obtenido y las páginas nuevas del cuaderno | 1 y 10 |
  | Victoria final al ganar la noche 5 | 10 y 12 |
  | Opciones: volumen por canal, reducir destellos, desactivar el parallax y temporizadores ×1,5 (solo el tiempo para responder, decisión de Benja) | 7, 9 y 11 |
  | Menú de pausa con Esc (decisión de Benja) | 13 |
  | "El juego se puede terminar" | 12, 13 y 14 (`docs/04`, L) |

- **Nombres consistentes:**
  - `NightData` (`number` de 0 a 5, `is_tutorial()` y `tutorial_requests`), `TutorialRequestData` (`friend`, `entity`, `situation`, `with_hint` y `sends_video`) y `ContentCatalog` (`tutorial`, `night()`, `known_entities()` y `new_pages()`) coinciden entre las tareas 1, 3, 5, 6 y 10;
  - `FriendRequest` (`timer_paused` y `questions_asked`), `Consequence` (`harmless`), `VideoSchedule.patient` y `RequestGenerator` (`generate_tutorial()` y `build()`) coinciden entre las tareas 2 y 3;
  - `RequestManager` (`TUTORIAL_GAP`, `tutorial_queue`, `pending_count()` y `timer_scale`) coincide entre las tareas 3, 5, 6, 7 y 9;
  - `TutorialGuide` (`View`, `Hint`, las claves `*_KEY`, `request_finished()`, `phone_highlighted()`, `phone_opened()`, `phone_closed()`, `is_done()` y `hint()`) coincide entre las tareas 4 y 6;
  - `GameSettings` (`BUSES`, `volumes`, `reduce_flashes`, `still_camera`, `slow_timers`, `timer_scale()`, `read()`, `write()` y `apply_audio()`) y `SaveGame` (`has_game()`, `stored_night()`, `store()` y `clear()`) coinciden entre las tareas 7, 8, 9, 11, 12 y 13;
  - `reduce_flashes` de `ChatEntry`, `MixerView` y `ScreamerManager`, `LookCamera.set_look()` y `desk.apply_settings()` coinciden entre las tareas 9, 12 y 13;
  - `EndingText` (`won_title()`, `summary()` y `LAST_NIGHT`), `EndScreen` (`show_ending()`, `retry_pressed`, `next_pressed` y `menu_pressed`) y las señales del escritorio (`tutorial_skipped`, `next_night_requested`, `retry_requested`, `menu_requested` y `settings_changed`) coinciden con `GameState` (`prepare_night()`, `start_night()`, `next_night()`, `retry()`, `go_to_menu()` y `save_settings()`);
  - los nodos nuevos (`Overlay/TutorialHint` con `Box/Title`, `Box/Body` y `Box/Skip`; `Overlay/PauseMenu`; `Center/Box/Buttons/Retry`, `Next` y `Menu` de la pantalla final; y los del menú, la pausa y las opciones) son los que usan los scripts y las pruebas.
- **Conteo de pruebas acumulado:** 382 → 386, 392, 396, 401, 403, 407, 413, 416, 420, 427, 431, 439 y 446.
