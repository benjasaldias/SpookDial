# Plan 8.1: Feedback de la primera prueba — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** aplicar el feedback que Benja dio el 4 de noviembre después de probar el Plan 8:

1. **La criatura se asoma por la ventana** en lugar del jumpscare, con respiración pesada y golpeteos (sonidos provisionales, anotados en `sonidos_pendiente.md`).
2. **Las noches 1 y 2 tienen más cosas que hacer:** más solicitudes, menos tiempo, mantenimiento desde la noche 1 y más screamers.
3. **Audio Sync de 8 aplausos pasa a 2 rondas de 4**; si se falla la segunda, se vuelve a la primera.
4. **Trust también baja si tardas en contestar.**
5. **Los diales se explican en la noche 0.**

**Arquitectura:**

- Datos: `data/balance.tres` (valores de Trust y de la criatura) y `data/nights/night_1.tres`, `night_2.tres`.
- Lógica pura: `FriendRequest` cuenta cuánto lleva abierta una solicitud, `NightState` baja Trust por las que esperan demasiado, `Screamer` elige la criatura solo detrás de un panel, y `TutorialGuide` explica los diales.
- Escritorio: `ScreamerManager` lleva a la criatura (lejos, detrás de un panel o a la vista), `MixerView` encadena las rondas de Audio Sync y `NightManager` le dice a `NightState` cuántas solicitudes esperan.
- Sonidos: `tools/make_placeholder_sounds.py` genera la respiración y los golpes.

**Stack:** Godot 4.7.2 (GDScript con tipado estático). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §10.3, §10.6, §11 y §13, y `docs/02_bucle_central.md` §6.

---

## Decisiones de este plan

### De Benja (4 de noviembre, después de probar el Plan 8)

Están en `CLAUDE.md` y en el diseño v2.

| Decisión | Detalle |
| --- | --- |
| **La criatura se asoma por la ventana en lugar del jumpscare.** | El screamer de pantalla completa estaba aburrido. Ahora la criatura (`enemy_sprite`, la del arte de Benja) se asoma por la ventana, con respiración pesada y golpes en el vidrio. Los otros 6 screamers no cambian. Sigue siendo 1 por noche desde la noche 2, y también es el susto guionado de la noche 0. |
| **Se arma solo cuando el chat o el mixer tapan la ventana, y está ahí al cerrarlos.** | Así se ahorra animarla: no tiene animación de entrada. Mientras el panel está abierto se oyen su respiración y sus golpes; apenas se cierra, la criatura ya está en la ventana. |
| **Los sonidos son provisionales.** | Claude los genera como relleno y Benja pone los reales. Quedan anotados en el documento nuevo `sonidos_pendiente.md`. |
| **Las noches 1 y 2 están fáciles y sin sucesos.** | N1 pasa de 4 a 5 solicitudes, de 1 a 2 a la vez y de 90 a 85 s; ahora la señal baja, hay 1 interferencia, Audio Sync de 4 aplausos y 2 screamers ambientales. N2 pasa de 6 a 7 solicitudes, de 2 a 3 interferencias y de 3 a 4 screamers. |
| **Audio Sync de 8 aplausos son 2 rondas de 4.** | Cada ronda tiene su cuenta y su patrón. Si se falla la segunda, se vuelve a la primera, con patrones nuevos al azar. Las noches de 4 aplausos siguen con 1 ronda. |
| **Trust también baja si tardas en contestar.** | Trust casi no se notaba. |
| **Los diales se explican en la noche 0.** | De las ayudas posibles, Benja eligió solo esta. No hay letreros al pasar el mouse ni avisos cuando un dial cambia. |

### Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| La criatura solo se arma con el chat o el mixer abiertos; el celular ampliado también tapa la ventana, pero no la arma. | Benja dijo "el mixer o un chat". Mientras se espera esa condición, el director no empieza otro screamer. |
| Si la criatura se arma detrás de un panel, espera hasta que se cierre, sin límite. Una vez a la vista, se queda 4 s y se retira. | Para que el susto siempre llegue. |
| En el susto guionado de la noche 0, que no depende de un panel, la criatura aparece enseguida si la ventana está a la vista. | Si no, el tutorial podría quedarse esperando a que el jugador abra un chat. |
| Trust: cada solicitud que lleva más de 30 s abierta le quita 0,25 por segundo, y mientras haya una así Trust no se recupera. Preguntar cuenta como tiempo abierto. Con "Temporizadores ×1,5" el plazo es de 45 s. Un amigo sin señal no cuenta, porque ya baja Trust por eso. | Responder rápido no cuesta nada; dejarla hasta los 60 s cuesta 7,5 y hasta el final de una noche 2, unos 12,5, más los 15 por no contestar. Son valores de partida en `balance.tres`. |
| Entre rondas de Audio Sync no hay pausa: acertar la primera pasa sola a la segunda con su cuenta. La señal solo vuelve a 100 al terminar las 2. | La cuenta de 2,4 s hace de respiro. |
| El aviso de los diales va primero en el tutorial, con un botón "Entendido" que hay que presionar para que sigan los demás avisos. | Es una lección que no depende de nada que pase en la noche. |
| El tutorial no enseña Audio Sync, que ahora aparece desde la noche 1. | Fuera de alcance. Si se nota que hace falta, es una tarea para S20. |
| Los textos nuevos (`TUTORIAL_DIALS*`, `MIXER_ROUND` y `MIXER_FAIL_RESTART`) son un borrador de Claude. | Regla 8 de `CLAUDE.md`. |

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`.
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | tail -1
  ```

  Esperado: `446 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar y probar.** Cada paso que corre las pruebas importa antes, porque Godot registra clases, `.uid` y audio nuevos:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | tr -d '\r' | grep -E "SCRIPT|Parse" ; echo "import listo"
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | grep -E "^FALLA|SCRIPT ERROR|pruebas OK"
```

En los pasos "Verificar que fallan", Esperado: las pruebas nuevas aparecen como `FALLA` (o su suite como "no se pudo cargar") y el resumen tiene fallidas.

**Commits.** Cada tarea termina en un commit. Benja autorizó los 7 commits de este plan directo en `main` al empezar (`CLAUDE.md`, regla 11). No hay `push`.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

**Tabuladores:** GDScript indenta con tabuladores. Los bloques de este plan los tienen y se aplican con un script, como en el Plan 8.

**Cómo leer los cambios:**

- "`ruta`:" seguido de un bloque: crear el archivo con ese contenido.
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo. Si hay varios seguidos para el mismo archivo, se aplican en orden.
- "Agregar al final de `ruta`:": en un `.gd`, dejar dos líneas en blanco antes del bloque; en un `.md`, una; en un `.csv`, agregar las líneas tal cual.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/balance_data.gd`, `data/balance.tres` | Valores de Trust por tardar y de la criatura |
| `data/nights/night_1.tres`, `night_2.tres` | Las noches 1 y 2 con más sucesos |
| `scripts/core/friend_request.gd`, `night_state.gd`, `scripts/desk/request_manager.gd`, `night_manager.gd` | Trust baja si tardas en contestar |
| `scripts/ui/mixer_view.gd`, `data/text/ui.csv` | Audio Sync en rondas |
| `tools/make_placeholder_sounds.py`, `audio/sfx/*.wav` | La respiración y los golpes de la criatura |
| `scripts/core/screamer.gd`, `scripts/desk/screamer_manager.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | La criatura de la ventana |
| `scripts/core/tutorial_guide.gd`, `scripts/ui/tutorial_hint.gd`, `scenes/ui/tutorial_hint.tscn` | El aviso de los diales |
| `sonidos_pendiente.md`, `CLAUDE.md`, `spook_dial_design.md`, `docs/02`, `docs/04`, `arte_pendiente.md`, `resumen.md`, `docs/00_log.md` | Documentos |
| `test/test_*.gd`, `test/capture_screamers.gd` | Pruebas y capturas |

---

### Tarea 1: Los valores: Trust por tardar y las noches 1 y 2

**Archivos:**

- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `data/nights/night_1.tres`, `data/nights/night_2.tres`, `test/test_balance.gd`

Solo datos: los valores de Trust por tardar (`slow_answer_grace` y `slow_answer_trust`, que usa la Tarea 2) y las noches 1 y 2 (decisión de Benja). La criatura (`creature_seconds`) entra en la Tarea 5.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
	var scare_counts := [0, 3, 4, 5, 6]
```

por:

```gdscript
	var scare_counts := [2, 4, 4, 5, 6]
```

En `test/test_balance.gd`, reemplazar:

```gdscript
	var requests := [4, 6, 7, 8, 10]
	var times := [90.0, 80.0, 75.0, 70.0, 65.0]
```

por:

```gdscript
	var requests := [5, 7, 7, 8, 10]
	var times := [85.0, 80.0, 75.0, 70.0, 65.0]
```

Agregar al final de `test/test_balance.gd`:

```gdscript
## El mantenimiento de cada noche (docs/02 §6; decisión de Benja, 4 de noviembre: las noches 1 y 2 estaban
## fáciles): la señal baja y hay Audio Sync desde la noche 1.
func test_mantenimiento_de_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var simultaneous := [2, 2, 2, 3, 3]
	var interferences := [1, 3, 3, 4, 6]
	var beats := [4, 4, 4, 8, 8]
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
		var who := "noche %d" % night.number
		check_eq(night.max_simultaneous, simultaneous[index], who + ": solicitudes a la vez")
		check(night.signal_decays, who + ": la señal baja")
		check_eq(night.interference_count, interferences[index], who + ": interferencias")
		check_eq(night.audio_sync_beats, beats[index], who + ": aplausos de Audio Sync")
	return true


## Trust también baja si tardas en contestar (decisión de Benja, 4 de noviembre).
func test_trust_por_tardar() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.slow_answer_grace, 30.0, "30 s de espera sin que Trust baje")
	check_eq(balance.slow_answer_trust, 0.25, "después, Trust baja 0,25 por segundo por solicitud")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `test_balance.gd` falla (no carga, porque `BalanceData` no tiene los campos nuevos).

- [ ] **Paso 3: Implementar**

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var trust_recovery_delay := 20.0
```

por:

```gdscript
@export var trust_recovery_delay := 20.0
## Segundos que una solicitud puede esperar sin que Trust baje (decisión de Benja, 4 de noviembre)…
@export var slow_answer_grace := 30.0
## …y después, Trust baja tantos puntos por segundo por cada solicitud que sigue esperando.
@export var slow_answer_trust := 0.25
```

En `data/balance.tres`, reemplazar:

```text
trust_recovery_delay = 20.0
```

por:

```text
trust_recovery_delay = 20.0
slow_answer_grace = 30.0
slow_answer_trust = 0.25
```

En `data/nights/night_1.tres`, reemplazar:

```text
requests_total = 4
max_simultaneous = 1
base_decision_time = 90.0
```

por:

```text
requests_total = 5
max_simultaneous = 2
base_decision_time = 85.0
```

En `data/nights/night_1.tres`, reemplazar:

```text
signal_decays = false
```

por:

```text
signal_decays = true
```

En `data/nights/night_1.tres`, reemplazar:

```text
interference_count = 0
audio_sync_beats = 0
```

por:

```text
interference_count = 1
audio_sync_beats = 4
```

En `data/nights/night_1.tres`, reemplazar:

```text
scare_count = 0
```

por:

```text
scare_count = 2
```

En `data/nights/night_2.tres`, reemplazar:

```text
requests_total = 6
```

por:

```text
requests_total = 7
```

En `data/nights/night_2.tres`, reemplazar:

```text
interference_count = 2
```

por:

```text
interference_count = 3
```

En `data/nights/night_2.tres`, reemplazar:

```text
scare_count = 3
```

por:

```text
scare_count = 4
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `0 fallidas`. Si falla otra suite que daba por hecho cómo era la noche 1 real (sin señal que baja, sin screamers), leer la falla antes de seguir: lo que cambió son los datos, no el código.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Las noches 1 y 2 con más sucesos y los valores de Trust por tardar" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: Trust baja si tardas en contestar

**Archivos:**

- Modificar: `scripts/core/friend_request.gd`, `scripts/core/night_state.gd`, `scripts/desk/request_manager.gd`, `scripts/desk/night_manager.gd`, `test/test_friend_request.gd`, `test/test_night_state.gd`, `test/test_request_manager.gd`, `test/test_night_manager.gd`

Cada solicitud cuenta cuánto lleva abierta (`open_seconds`, con lo que costaron las preguntas). `RequestManager.impatient_count()` dice cuántas llevan más de `slow_answer_grace` segundos (45 con "Temporizadores ×1,5") y tienen un amigo con señal. `NightManager` se lo pasa a `NightState` en cada paso, y Trust baja por cada una y no se recupera mientras haya alguna.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_friend_request.gd`:

```gdscript
## Una solicitud que espera demasiado hace bajar Trust (decisión de Benja, 4 de noviembre): cuenta el tiempo que
## lleva abierta, preguntas incluidas.
func test_una_solicitud_lenta() -> bool:
	var request := _make_request()
	request.situation = {&"o1": &"yes", &"o2": &"no"}
	request.advance(20.0)
	check_eq(request.open_seconds, 20.0, "20 s abierta")
	check(not request.is_slow(30.0), "todavía no")
	request.pay_question()
	check_eq(request.open_seconds, 25.0, "preguntar también cuenta")
	request.advance(5.0)
	check(not request.is_slow(30.0), "justo a los 30 s, todavía no")
	request.advance(0.5)
	check(request.is_slow(30.0), "pasados los 30 s, sí")
	request.finish(request.entity.find_action(&"a1"), true)
	check(not request.is_slow(30.0), "una solicitud terminada ya no espera")
	return true


## En el tutorial el temporizador espera, y la solicitud nunca es lenta.
func test_en_el_tutorial_nunca_es_lenta() -> bool:
	var request := _make_request()
	request.timer_paused = true
	request.advance(100.0)
	check_eq(request.open_seconds, 0.0, "no cuenta")
	check(not request.is_slow(30.0), "no es lenta")
	return true
```

Agregar al final de `test/test_night_state.gd`:

```gdscript
## Cada solicitud que espera demasiado le quita 0,25 de Trust por segundo, y mientras tanto Trust no se
## recupera (decisión de Benja, 4 de noviembre).
func test_la_espera_baja_trust() -> bool:
	var catalog := Fixtures.make_catalog()
	var state := NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())
	state.impatient = 2
	state.advance(10.0)
	check_eq(state.trust, 95.0, "2 solicitudes × 0,25 por segundo × 10 s")
	state.impatient = 0
	state.advance(20.0)
	check_eq(state.trust, 95.0, "recién deja de bajar: todavía no se recupera")
	state.advance(8.0)
	check_eq(state.trust, 96.0, "después de 20 s sin bajar, vuelve a subir")
	return true
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
## Una solicitud que espera más de 30 s hace bajar Trust; con "Temporizadores ×1,5", el plazo es de 45 s
## (decisión de Benja, 4 de noviembre).
func test_solicitudes_que_esperan_demasiado() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	check_eq(manager.impatient_count(), 0, "recién llegó")
	request.open_seconds = 31.0
	check_eq(manager.impatient_count(), 1, "lleva más de 30 s")
	manager.timer_scale = 1.5
	check_eq(manager.impatient_count(), 0, "con ×1,5, el plazo es de 45 s")
	manager.timer_scale = 1.0
	manager.state.friends[2].signal_level = 0.0
	check_eq(manager.impatient_count(), 0, "sin señal ya baja Trust por eso")
	manager.free()
	return true
```

Agregar al final de `test/test_night_manager.gd`:

```gdscript
## Una solicitud que espera más de 30 s baja Trust, y la noche lo aplica en cada paso (decisión de Benja, 4 de
## noviembre).
func test_trust_baja_si_tardas_en_contestar() -> bool:
	var night := _make_night()
	var request := _requests.start_request(0)
	check(request != null, "llegó una solicitud")
	if request == null:
		_free(night)
		return true
	request.time_left = 500.0
	night.advance(10.0)
	check_eq(_requests.state.trust, 100.0, "a los 10 s, Trust sigue entera")
	night.advance(30.0)
	check(_requests.state.trust < 100.0, "a los 40 s, Trust bajó: %s" % _requests.state.trust)
	var before := _requests.state.trust
	var rule := RuleEvaluator.applicable_rule(request.entity, request.situation)
	_requests.answer(0, request.entity.find_action(rule.correct_action_id))
	night.advance(1.0)
	check_eq(_requests.state.trust, before, "respondida, deja de bajar")
	_free(night)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: fallan las pruebas nuevas de esas 4 suites (`open_seconds`, `impatient` e `impatient_count` todavía no existen).

- [ ] **Paso 3: Implementar**

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
var questions_asked := 0
```

por:

```gdscript
var questions_asked := 0
## Segundos que lleva abierta, con lo que costaron las preguntas. Con el temporizador en espera (el tutorial)
## no corre.
var open_seconds := 0.0
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
	questions_asked += 1
```

por:

```gdscript
	questions_asked += 1
	open_seconds += question_cost
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
	if not timer_paused:
		time_left = maxf(time_left - delta, 0.0)
```

por:

```gdscript
	if not timer_paused:
		time_left = maxf(time_left - delta, 0.0)
		open_seconds += delta
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
func is_out_of_time() -> bool:
	return not finished and time_left <= 0.0
```

por:

```gdscript
func is_out_of_time() -> bool:
	return not finished and time_left <= 0.0


## Matías la deja esperando más de `grace` segundos, y Trust baja (decisión de Benja, 4 de noviembre). En el
## tutorial, con el temporizador en espera, nunca.
func is_slow(grace: float) -> bool:
	return not finished and not timer_paused and open_seconds > grace
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
var holding_download := -1
```

por:

```gdscript
var holding_download := -1
## Cuántas solicitudes esperan más de la cuenta: cada una hace bajar Trust (decisión de Benja, 4 de noviembre).
## Lo pone NightManager antes de cada paso.
var impatient := 0
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
## Trust se recupera si no bajó en un rato. Con amigos sin señal, baja por cada uno y no se recupera
## (decisión de Benja).
func _advance_trust(delta: float) -> void:
	var offline := offline_count()
	if offline > 0:
		_since_trust_loss = 0.0
		trust = maxf(trust - delta * offline / balance.offline_trust_interval, 0.0)
		return
```

por:

```gdscript
## Trust se recupera si no bajó en un rato. Con amigos sin señal o con solicitudes esperando demasiado, baja
## por cada uno y no se recupera (decisión de Benja).
func _advance_trust(delta: float) -> void:
	var drain := delta * offline_count() / balance.offline_trust_interval \
			+ delta * impatient * balance.slow_answer_trust
	if drain > 0.0:
		_since_trust_loss = 0.0
		trust = maxf(trust - drain, 0.0)
		return
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
```

por:

```gdscript
## Cuántas solicitudes esperan más de la cuenta y hacen bajar Trust (decisión de Benja, 4 de noviembre): las que
## llevan más de slow_answer_grace segundos abiertas (más con "Temporizadores ×1,5") y tienen un amigo con señal;
## sin señal, Trust ya baja por eso.
func impatient_count() -> int:
	var grace := catalog.balance.slow_answer_grace * timer_scale
	var count := 0
	for index in requests.size():
		var request := requests[index]
		if request != null and state.friends[index].is_online() and request.is_slow(grace):
			count += 1
	return count


## Avanza `delta` segundos: los temporizadores, la espera de identificación y la llegada de solicitudes.
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
	var events := requests.state.advance(delta)
```

por:

```gdscript
	requests.state.impatient = requests.impatient_count()
	var events := requests.state.advance(delta)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Trust baja si tardas en contestar" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: Audio Sync en rondas

**Archivos:**

- Modificar: `scripts/ui/mixer_view.gd`, `data/text/ui.csv`, `test/test_mixer_view.gd`

Una noche de 8 aplausos son 2 rondas de 4 seguidas (decisión de Benja). Cada ronda es una `AudioSyncRound` de 4 aplausos, con su cuenta y su patrón. Acertar una ronda que no es la última empieza la siguiente. Fallar cualquiera deja el resultado a la vista, y la próxima ronda que Matías empiece (clic o barra espaciadora) arranca en la primera, con un patrón nuevo. La señal del amigo vuelve a 100 solo al terminar la última. `AudioSyncRound` no cambia.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_mixer_view.gd`:

```gdscript
## El mixer de la noche 2 con 8 aplausos: 2 rondas de 4 (decisión de Benja, 4 de noviembre).
func _make_two_round_mixer() -> Control:
	var mixer := _make_mixer()
	_manager.catalog.nights[1].audio_sync_beats = 8
	return mixer


func test_8_aplausos_son_2_rondas_de_4() -> bool:
	var mixer := _make_two_round_mixer()
	check_eq(mixer.rounds_total(), 2, "2 rondas")
	_manager.state.friends[1].signal_level = 20.0
	mixer.open()
	mixer.start_round(1)
	check_eq(mixer.sync_round.beats, 4, "la primera, de 4 aplausos")
	check_eq(mixer.round_index, 0, "ronda 1")
	check(mixer.status_text().begins_with(tr("MIXER_ROUND").format({"round": 1, "total": 2})), "el mixer dice la ronda")
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "acertada la 1, pasa sola a la 2")
	check_eq(mixer.sync_round.beats, 4, "la segunda, también de 4")
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con su propia cuenta")
	check_eq(_manager.state.friends[1].signal_level, 20.0, "la señal todavía no vuelve")
	_tap_pattern(mixer)
	check(mixer.sync_round.succeeded, "salió bien la 2")
	check_eq(_manager.state.friends[1].signal_level, 100.0, "al terminar las 2, la señal vuelve a 100")
	_free(mixer)
	return true


func test_si_falla_la_segunda_vuelve_a_la_primera() -> bool:
	var mixer := _make_two_round_mixer()
	_manager.state.friends[0].signal_level = 40.0
	mixer.open()
	mixer.start_round(0)
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "va en la 2")
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check(mixer.sync_round.failed, "no golpeó: sale mal")
	check_eq(mixer.status_text(), tr("MIXER_FAIL_RESTART"), "dice que vuelve a la ronda 1")
	check_eq(_manager.state.friends[0].signal_level, 40.0, "la señal sigue igual")
	mixer._unhandled_input(_space())
	check_eq(mixer.round_index, 0, "vuelve a la ronda 1")
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con su cuenta")
	_free(mixer)
	return true


func test_si_falla_la_primera_se_reintenta_la_primera() -> bool:
	var mixer := _make_two_round_mixer()
	mixer.open()
	mixer.start_round(0)
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check_eq(mixer.status_text(), tr("MIXER_FAIL"), "el mensaje de siempre")
	mixer._unhandled_input(_space())
	check_eq(mixer.round_index, 0, "sigue en la ronda 1")
	_free(mixer)
	return true


func test_con_4_aplausos_hay_una_sola_ronda() -> bool:
	var mixer := _make_mixer()
	check_eq(mixer.rounds_total(), 1, "una ronda")
	mixer.open()
	mixer.start_round(0)
	check(not mixer.status_text().contains(tr("MIXER_ROUND").format({"round": 1, "total": 1})), "no dice 'ronda 1 de 1'")
	_free(mixer)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: fallan `test_8_aplausos_son_2_rondas_de_4`, `test_si_falla_la_segunda_vuelve_a_la_primera`, `test_si_falla_la_primera_se_reintenta_la_primera` y `test_con_4_aplausos_hay_una_sola_ronda` (no existen `rounds_total()` ni `round_index`).

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
MIXER_ROUND,Ronda {round} de {total},
MIXER_FAIL_RESTART,Fuera de ritmo: vuelves a la ronda 1. Espacio para reintentar,
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
const NO_SYNC_KEY := "MIXER_NO_SYNC"
```

por:

```gdscript
const NO_SYNC_KEY := "MIXER_NO_SYNC"
## MIXER_ROUND lleva {round} y {total}.
const ROUND_KEY := "MIXER_ROUND"
const FAIL_RESTART_KEY := "MIXER_FAIL_RESTART"
## Aplausos de cada ronda. Una noche de 8 aplausos son 2 rondas de 4 seguidas (decisión de Benja, 4 de noviembre).
const ROUND_BEATS := 4
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
var sync_round: AudioSyncRound
```

por:

```gdscript
var sync_round: AudioSyncRound
## Cuál de las rondas va, desde 0.
var round_index := 0
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
func beats() -> int:
	return _manager.night().audio_sync_beats
```

por:

```gdscript
func beats() -> int:
	return _manager.night().audio_sync_beats


## Cuántas rondas seguidas tiene el Audio Sync de esta noche: 0 si no hay.
func rounds_total() -> int:
	return ceili(beats() / float(ROUND_BEATS))
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
	var balance := _manager.catalog.balance
	sync_round = AudioSyncRound.new(beats(), balance.audio_sync_bpm, balance.audio_sync_tolerance, _manager.rng)
	_round_finished = false
	_lights.clear()
	_playhead = -1
```

por:

```gdscript
	round_index = 0
	_begin_round()


## Arma la ronda `round_index`, con su cuenta y su patrón al azar.
func _begin_round() -> void:
	var balance := _manager.catalog.balance
	sync_round = AudioSyncRound.new(mini(beats(), ROUND_BEATS), balance.audio_sync_bpm, balance.audio_sync_tolerance,
			_manager.rng)
	_round_finished = false
	_lights.clear()
	_playhead = -1
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
	match sync_round.phase():
		AudioSyncRound.Phase.COUNT_IN:
			return tr(COUNT_IN_KEY)
		AudioSyncRound.Phase.CALL:
			return tr(LISTEN_KEY).format({"friend": friend})
		AudioSyncRound.Phase.RESPONSE:
			return tr(YOUR_TURN_KEY)
	return tr(SUCCESS_KEY if sync_round.succeeded else FAIL_KEY).format({"friend": friend})
```

por:

```gdscript
	var round_label := ""
	if rounds_total() > 1:
		round_label = tr(ROUND_KEY).format({"round": round_index + 1, "total": rounds_total()}) + " · "
	match sync_round.phase():
		AudioSyncRound.Phase.COUNT_IN:
			return round_label + tr(COUNT_IN_KEY)
		AudioSyncRound.Phase.CALL:
			return round_label + tr(LISTEN_KEY).format({"friend": friend})
		AudioSyncRound.Phase.RESPONSE:
			return round_label + tr(YOUR_TURN_KEY)
	if sync_round.succeeded:
		return tr(SUCCESS_KEY).format({"friend": friend})
	return tr(FAIL_RESTART_KEY if round_index > 0 else FAIL_KEY)
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
	if sync_round.succeeded:
		_success.play()
		_manager.restore_signal(selected_friend)
	else:
		_fail.play()
```

por:

```gdscript
	if sync_round.succeeded:
		_success.play()
		if round_index + 1 < rounds_total():
			# Acertó una ronda de varias: sigue la siguiente. La señal vuelve al terminar la última.
			round_index += 1
			_begin_round()
		else:
			_manager.restore_signal(selected_friend)
	else:
		_fail.play()
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
## Al terminar la ronda, las luces muestran el ritmo: en verde lo que acertó Matías y en rojo lo que se le
## pasó. Si salió bien, la señal del amigo vuelve a 100 y el chat avisa si estaba desconectado.
```

por:

```gdscript
## Al terminar la ronda, las luces muestran el ritmo: en verde lo que acertó Matías y en rojo lo que se le
## pasó. Si salió bien y era la última, la señal del amigo vuelve a 100 y el chat avisa si estaba desconectado;
## si no era la última, empieza la siguiente. Si salió mal, la próxima vuelve a empezar en la primera.
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Audio Sync de 8 aplausos en 2 rondas de 4" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Los sonidos provisionales de la criatura

**Archivos:**

- Modificar: `tools/make_placeholder_sounds.py`, `test/test_placeholder_sounds.gd`
- Crear (los genera el script): `audio/sfx/scare_creature_breathing.wav`, `audio/sfx/scare_creature_knocks.wav`

La respiración (8 s) y los golpes en el vidrio (7 s, tres tandas cada vez más fuertes) son relleno, como los demás sonidos provisionales. Benja los reemplaza con los reales usando los mismos nombres (`sonidos_pendiente.md`, Tarea 7). El grito del jumpscare (`scare_jumpscare.wav`) sigue hasta la Tarea 5.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
	"scare_jumpscare": 1.5,
```

por:

```gdscript
	"scare_jumpscare": 1.5,
	"scare_creature_breathing": 8.0,
	"scare_creature_knocks": 7.0,
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: falla `test_placeholder_sounds.gd` (`scare_creature_*.wav` no existen).

- [ ] **Paso 3: Implementar**

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
- Plan 7: el sonido ambiente del cuarto, uno por screamer y los cuatro de las alucinaciones.
```

por:

```python
- Plan 7: el sonido ambiente del cuarto, uno por screamer y los cuatro de las alucinaciones;
- 4 de noviembre: la respiración y los golpes de la criatura de la ventana, que reemplazan al grito del jumpscare.
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
def kick():
```

por:

```python
def breathing():
    """La criatura de la ventana: 8 s de respiración pesada y ronca, tres inspiraciones y tres exhalaciones."""
    white, samples, low, lower, seconds = noise(31), [], 0.0, 0.0, 8.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.12 * (white() - low)
        lower += 0.25 * (low - lower)
        cycle = (t % 2.6) / 2.6
        # Inspira rápido y más agudo, y exhala lento y más grave.
        if cycle < 0.4:
            level = math.sin(math.pi * cycle / 0.4) ** 1.5
            tone = 5.0 * low
        else:
            level = 0.8 * math.sin(math.pi * (cycle - 0.4) / 0.6) ** 1.5
            tone = 8.0 * lower
        rasp = 0.7 + 0.3 * math.sin(2 * math.pi * 31 * t)
        fade = min(t / 0.3, 1.0, (seconds - t) / 0.4)
        samples.append(0.6 * tone * level * rasp * fade)
    return samples


def knocks():
    """La criatura golpea el vidrio: 7 s con tres tandas de golpes pesados, cada vez más fuertes."""
    white, samples, seconds = noise(32), [], 7.0
    hits = (0.6, 1.1, 2.9, 3.35, 3.8, 5.4, 5.8, 6.2, 6.5)
    volumes = (0.5, 0.5, 0.7, 0.7, 0.7, 1.0, 1.0, 1.0, 1.0)
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for start, volume in zip(hits, volumes):
            if t >= start:
                local = t - start
                value += volume * (math.sin(2 * math.pi * 95 * local) * math.exp(-local * 28)
                                   + 0.35 * math.sin(2 * math.pi * 640 * local) * math.exp(-local * 120)
                                   + 0.25 * white() * math.exp(-local * 160))
        samples.append(0.8 * value)
    return samples


def kick():
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    write("scare_jumpscare", scream())
```

por:

```python
    write("scare_jumpscare", scream())
    write("scare_creature_breathing", breathing())
    write("scare_creature_knocks", knocks())
```

Generar los sonidos, desde la carpeta del proyecto:

```bash
python3 -I tools/make_placeholder_sounds.py
git status --short audio/
```

Esperado: `Sonidos provisionales en …/audio/sfx` y dos archivos nuevos sin seguimiento (`scare_creature_breathing.wav` y `scare_creature_knocks.wav`); ningún otro cambia, porque el script siempre genera los mismos bytes.

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar"). El import crea los `.import` de los `.wav` nuevos.

Esperado: `0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add tools/ audio/ test/
git commit -m "Sonidos provisionales de la criatura de la ventana" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: La criatura se asoma por la ventana

**Archivos:**

- Modificar: `scripts/core/screamer.gd`, `scripts/desk/screamer_manager.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn`, `scripts/data/balance_data.gd`, `scripts/data/night_data.gd`, `scripts/data/scare_kind.gd`, `data/balance.tres`, `tools/make_placeholder_sounds.py`, `test/test_balance.gd`, `test/test_screamer.gd`, `test/test_screamer_manager.gd`, `test/test_placeholder_sounds.gd`, `test/capture_screamers.gd`
- Borrar: `audio/sfx/scare_jumpscare.wav` y su `.import`

El jumpscare (`ScareKind.Kind.JUMPSCARE`) pasa a ser la criatura que se asoma por la ventana (decisión de Benja). El nombre del tipo se queda, para no mover los datos de las noches. Cómo funciona:

- **Se arma** solo con el chat o el mixer abiertos (`Screamer.View.panel_open`): el director espera hasta que alguno lo esté.
- **Detrás del panel** (`Creature.HIDDEN`): suenan su respiración (más baja) y sus golpes en el vidrio. La figura (`WallPlane/Enemy`) no se ve, porque el panel tapa la ventana.
- **A la vista** (`Creature.SEEN`): apenas la ventana queda a la vista (se cerró el panel), la figura ya está ahí, sin animación, y la respiración sube. A los `creature_seconds` (4 s) se desvanece y se calla.
- Si la ventana ya está a la vista al llegar (el susto guionado de la noche 0), aparece enseguida.
- **No tapa nada y no pausa la noche.** Mientras esté cerca no empiezan otros screamers ni alucinaciones.
- Cuesta 15 de Sanity al llegar, como el jumpscare.

Se quitan la pantalla del jumpscare (`Overlay/Jumpscare`), su rojo parpadeante (`jumpscare_alphas()`), `jumpscare_seconds` y el sonido del grito.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
	check_eq(balance.jumpscare_seconds, 1.5, "el jumpscare dura 1,5 s")
```

por:

```gdscript
	check_eq(balance.creature_seconds, 4.0, "la criatura se queda 4 s a la vista")
```

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
	"scare_jumpscare": 1.5,
	"scare_creature_breathing": 8.0,
	"scare_creature_knocks": 7.0,
```

por:

```gdscript
	"scare_creature_breathing": 8.0,
	"scare_creature_knocks": 7.0,
```

En `test/test_screamer.gd`, reemplazar:

```gdscript
func _view(desk_visible: bool, notebook_open := false, notebook_page := false) -> Screamer.View:
```

por:

```gdscript
func _view(desk_visible: bool, notebook_open := false, notebook_page := false, panel_open := false) -> Screamer.View:
```

En `test/test_screamer.gd`, reemplazar:

```gdscript
	view.notebook_page = notebook_page
```

por:

```gdscript
	view.notebook_page = notebook_page
	view.panel_open = panel_open
```

En `test/test_screamer.gd`, reemplazar:

```gdscript
	check(Screamer.is_fair(ScareKind.Kind.JUMPSCARE, [6.5], balance), "el jumpscare pausa la noche")
```

por:

```gdscript
	check(Screamer.is_fair(ScareKind.Kind.JUMPSCARE, [6.5], balance), "la criatura no tapa nada")
```

En `test/test_screamer.gd`, reemplazar:

```gdscript
	check_eq(Screamer.pick(_view(true), true, [], balance, rng), ScareKind.Kind.JUMPSCARE, "si toca, el jumpscare")
```

por:

```gdscript
	check_eq(Screamer.pick(_view(false, false, false, true), true, [], balance, rng), ScareKind.Kind.JUMPSCARE,
			"si toca, la criatura, detrás de un panel")
	check_eq(Screamer.pick(_view(true), true, [], balance, rng), Screamer.NONE, "con la ventana a la vista, espera")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	check(not (desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura no está (decisión de Benja)")
	check(not (desk.get_node("Overlay/Jumpscare") as Control).visible, "sin jumpscare")
```

por:

```gdscript
	check(not (desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura no está (decisión de Benja)")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
func test_el_jumpscare_tapa_la_pantalla_y_pausa_la_noche() -> bool:
	var desk := _make_desk()
	var sanity := _state(desk).sanity
	_scare_now(desk, true)
	desk._process(0.0)
	desk._process(1.0)
	check((desk.get_node("Overlay/Jumpscare") as Control).visible, "tapa la pantalla")
	check(desk.get_node("NightManager").is_paused(), "la noche se pausa")
	check_eq(_state(desk).sanity, sanity - 15.0, "Sanity −15")
	desk.get_node("NightManager").advance(1.0)
	check_eq(_state(desk).elapsed, 0.0, "la hora no avanza durante el jumpscare")
	desk.free()
	return true
```

por:

```gdscript
## La criatura se arma detrás de un panel (el chat o el mixer) y está ahí al cerrarlo (decisión de Benja, 4 de
## noviembre), con la respiración y los golpes sonando mientras tanto, sin tapar la pantalla ni pausar la noche.
func test_la_criatura_se_arma_detras_de_un_panel() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var chat := desk.get_node("UI/ChatPanel") as Control
	var figure := desk.get_node("WallPlane/Enemy") as CanvasItem
	var sanity := _state(desk).sanity
	_scare_now(desk, true)
	desk._process(0.0)
	check(not screamers.is_warning(), "con la ventana a la vista, espera")
	chat.show()
	desk._process(0.0)
	check(screamers.is_warning(), "con el chat abierto, se anuncia")
	desk._process(1.0)
	check(screamers.is_creature_near(), "la criatura está cerca")
	check(not figure.visible, "pero no se ve: el chat tapa la ventana")
	check((screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "se oye su respiración")
	check((screamers.get_node("CreatureKnocks") as AudioStreamPlayer).playing, "y sus golpes en el vidrio")
	check_eq(_state(desk).sanity, sanity - 15.0, "Sanity −15")
	check(not desk.get_node("NightManager").is_paused(), "la noche no se pausa")
	chat.hide()
	desk._process(0.0)
	check(figure.visible, "al cerrar el chat, ya está ahí")
	check_eq(figure.modulate.a, 1.0, "sin animación de entrada")
	desk._process(3.9)
	check(figure.visible, "a los 3,9 s, todavía")
	desk._process(0.2)
	check(not screamers.is_creature_near(), "a los 4 s, se retira")
	check(not (screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "y se calla")
	desk.free()
	return true


## Con la ventana a la vista (el susto guionado de la noche 0), la criatura aparece enseguida.
func test_la_criatura_aparece_enseguida_con_la_ventana_a_la_vista() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	screamers.play(ScareKind.Kind.JUMPSCARE)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "se ve en la ventana")
	check(screamers.is_creature_near(), "está cerca")
	desk.free()
	return true


## Mientras la criatura está cerca no empieza otro screamer; cuando se retira, sí.
func test_con_la_criatura_cerca_no_empiezan_otros_screamers() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	_screamers(desk).play(ScareKind.Kind.JUMPSCARE)
	_scare_now(desk)
	_process(desk, 3)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "solo la criatura")
	_process(desk, 4)
	check(kinds.size() >= 2, "al retirarse, llega el otro: %s" % [kinds])
	desk.free()
	return true
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	# A los 5 s, sin nada pendiente: la señal previa y, 1 s después, el jumpscare.
```

por:

```gdscript
	# A los 5 s, sin nada pendiente: la señal previa y, 1 s después, la criatura de la ventana.
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	# La pausa del jumpscare (1,5 s) y lo que tarda Gonzalo en escribir (2,5 s).
```

por:

```gdscript
	# Lo que tarda Gonzalo en escribir (2,5 s).
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
## "Reducir destellos" (diseño §19): la señal previa, el apagón de las luces y el rojo del jumpscare se oscurecen
```

por:

```gdscript
## "Reducir destellos" (diseño §19): la señal previa y el apagón de las luces se oscurecen
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	check(_flashes(screamers.jumpscare_alphas()) > 0, "el rojo del jumpscare parpadea")
	screamers.reduce_flashes = true
	for alphas: Array[float] in [screamers.warning_alphas(), screamers.lights_alphas(), screamers.jumpscare_alphas()]:
```

por:

```gdscript
	screamers.reduce_flashes = true
	for alphas: Array[float] in [screamers.warning_alphas(), screamers.lights_alphas()]:
```

En `test/capture_screamers.gd`, reemplazar:

```gdscript
## 3. El jumpscare.
```

por:

```gdscript
## 3. La criatura asomada en la ventana.
```

En `test/capture_screamers.gd`, reemplazar:

```gdscript
	screamers.play(ScareKind.Kind.JUMPSCARE)
	await create_timer(0.2).timeout
```

por:

```gdscript
	screamers.play(ScareKind.Kind.JUMPSCARE)
	await create_timer(0.5).timeout
```

En `test/capture_screamers.gd`, reemplazar:

```gdscript
	# La señal previa, el jumpscare (1,5 s, con la noche en pausa) y lo que tarda Gonzalo en escribir (2,5 s).
```

por:

```gdscript
	# La señal previa, la criatura y lo que tarda Gonzalo en escribir (2,5 s).
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: fallan `test_balance.gd`, `test_screamer.gd` y `test_screamer_manager.gd` (no existen `creature_seconds`, `panel_open` ni `is_creature_near()`), y `test_placeholder_sounds.gd` sigue pasando.

- [ ] **Paso 3: Implementar**

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
## Sanity que resta el jumpscare (docs/02 §6).
@export var jumpscare_sanity := 15.0
## Segundos que dura el jumpscare. Tapa la pantalla, así que la noche se pausa (diseño §11).
@export var jumpscare_seconds := 1.5
```

por:

```gdscript
## Sanity que resta la criatura de la ventana, el antiguo jumpscare (docs/02 §6).
@export var jumpscare_sanity := 15.0
## Segundos que la criatura de la ventana se queda a la vista, desde que se ve (decisión de Benja, 4 de
## noviembre). No tapa nada: la noche no se pausa.
@export var creature_seconds := 4.0
```

En `data/balance.tres`, reemplazar:

```text
jumpscare_seconds = 1.5
```

por:

```text
creature_seconds = 4.0
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
## Uno de los screamers es el jumpscare de pantalla completa: como máximo uno por noche, desde la noche 2.
```

por:

```gdscript
## Uno de los screamers es la criatura que se asoma por la ventana (el antiguo jumpscare): como máximo uno por
## noche, desde la noche 2.
```

En `scripts/data/scare_kind.gd`, reemplazar:

```gdscript
## luces), dos sobre el cuaderno (se cierra de golpe o una mancha de tinta tapa la página) y el jumpscare de
## pantalla completa.
```

por:

```gdscript
## luces), dos sobre el cuaderno (se cierra de golpe o una mancha de tinta tapa la página) y JUMPSCARE, la
## criatura que se asoma por la ventana (decisión de Benja, 4 de noviembre; antes era de pantalla completa).
```

En `scripts/core/screamer.gd`, reemplazar:

```gdscript
	var notebook_page := false
```

por:

```gdscript
	var notebook_page := false
	## El chat o el mixer están abiertos: tapan la ventana, y la criatura se arma detrás (decisión de Benja, 4
	## de noviembre).
	var panel_open := false
```

En `scripts/core/screamer.gd`, reemplazar:

```gdscript
## Segundos que el screamer tapa algo mientras la noche sigue: la tinta tapa las reglas. El jumpscare tapa la
## pantalla, pero pausa la noche, así que no cuenta.
```

por:

```gdscript
## Segundos que el screamer tapa algo mientras la noche sigue: la tinta tapa las reglas. La criatura de la
## ventana no tapa nada.
```

En `scripts/core/screamer.gd`, reemplazar:

```gdscript
	var kinds: Array[ScareKind.Kind] = [ScareKind.Kind.JUMPSCARE]
	if not jumpscare:
		kinds = candidates(view)
```

por:

```gdscript
	var kinds: Array[ScareKind.Kind] = []
	if jumpscare:
		# La criatura solo se arma detrás de un panel (el chat o el mixer): se ve al cerrarlo.
		if view.panel_open:
			kinds.append(ScareKind.Kind.JUMPSCARE)
	else:
		kinds = candidates(view)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## ambiente) y se muestra con su sonido. Cada uno resta Sanity, y el jumpscare pausa la noche mientras tapa la
## pantalla. Después del susto guionado empieza su chat guionado (decisión de Benja).
```

por:

```gdscript
## ambiente) y se muestra con su sonido. Cada uno resta Sanity. El antiguo jumpscare es ahora la criatura que se
## asoma por la ventana, con respiración pesada y golpes (decisión de Benja, 4 de noviembre): se arma cuando el
## chat o el mixer tapan la ventana, y está ahí al cerrarlos. Después del susto guionado empieza su chat
## guionado (decisión de Benja).
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Con "Reducir destellos" (diseño §19), la señal previa, el apagón de las luces y el rojo del jumpscare se
## oscurecen una sola vez, más suave, en lugar de parpadear.
```

por:

```gdscript
## Con "Reducir destellos" (diseño §19), la señal previa y el apagón de las luces se oscurecen una sola vez,
## más suave, en lugar de parpadear.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	ScareKind.Kind.JUMPSCARE: "JumpscareSound",
```

por:

```gdscript
	ScareKind.Kind.JUMPSCARE: "CreatureBreathing",
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
const HALLUCINATION_SIDES: Array[Vector2] = [Vector2(-200, 360), Vector2(1480, 360)]
```

por:

```gdscript
const HALLUCINATION_SIDES: Array[Vector2] = [Vector2(-200, 360), Vector2(1480, 360)]
## Volumen de la respiración de la criatura mientras espera detrás de un panel, en decibeles.
const HIDDEN_BREATHING_DB := -9.0
## Segundos que tarda la criatura en desvanecerse al retirarse.
const LEAVE_SECONDS := 0.4

## Dónde está la criatura de la ventana: lejos, detrás de un panel que tapa la ventana, o a la vista.
enum Creature { AWAY, HIDDEN, SEEN }
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## La figura de la ventana: escondida, aparece en el screamer de la ventana (decisión de Benja).
```

por:

```gdscript
## La figura de la ventana: escondida. Aparece en el screamer de la ventana y es la criatura que se asoma
## (decisión de Benja).
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## La pantalla del jumpscare: la silueta de la figura a ×2 sobre un destello gris, provisional hasta el arte de
## Benja.
@export var jumpscare: Control
@export var notebook: Control
```

por:

```gdscript
@export var notebook: Control
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
var _phone_rest := Vector2.ZERO
```

por:

```gdscript
var _phone_rest := Vector2.ZERO
var _creature := Creature.AWAY
## Segundos que lleva a la vista la criatura.
var _creature_seen := 0.0
## La ventana está a la vista (ni un panel ni el celular la tapan), según el último avance.
var _window_visible := true
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
@onready var _hallucination: AudioStreamPlayer2D = $Hallucination
```

por:

```gdscript
@onready var _hallucination: AudioStreamPlayer2D = $Hallucination
@onready var _breathing: AudioStreamPlayer = $CreatureBreathing
@onready var _knocks: AudioStreamPlayer = $CreatureKnocks
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
func is_warning() -> bool:
	return _pending != Screamer.NONE
```

por:

```gdscript
func is_warning() -> bool:
	return _pending != Screamer.NONE


## La criatura de la ventana está cerca: detrás de un panel o a la vista.
func is_creature_near() -> bool:
	return _creature != Creature.AWAY
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	var calm := not busy and not is_warning() and not _night.is_paused()
```

por:

```gdscript
	_window_visible = view.desk_visible
	_advance_creature(delta)
	var calm := not busy and not is_warning() and not _night.is_paused() and not is_creature_near()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
		ScareKind.Kind.JUMPSCARE:
			_show_jumpscare(balance.jumpscare_seconds)
```

por:

```gdscript
		ScareKind.Kind.JUMPSCARE:
			_creature_arrives()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## El jumpscare tapa la pantalla `seconds` segundos, con parpadeos rojos, y la noche se pausa mientras tanto.
func _show_jumpscare(seconds: float) -> void:
	_night.pause(seconds)
	jumpscare.show()
	var red := jumpscare.get_node("Red") as ColorRect
	var alphas := jumpscare_alphas()
	_tween_alphas(red, ^"color:a", alphas, seconds / alphas.size()).tween_callback(jumpscare.hide)
```

por:

```gdscript
## La criatura llega a la ventana, con su respiración y sus golpes en el vidrio. Si la ventana está a la vista,
## aparece enseguida; si un panel la tapa, espera detrás, y al cerrarlo ya está ahí, sin animación de entrada.
func _creature_arrives() -> void:
	_knocks.play()
	if _window_visible:
		_show_creature()
	else:
		_creature = Creature.HIDDEN
		_breathing.volume_db = HIDDEN_BREATHING_DB


## La criatura se ve en la ventana, con la respiración más fuerte, durante creature_seconds.
func _show_creature() -> void:
	_creature = Creature.SEEN
	_creature_seen = 0.0
	figure.modulate.a = 1.0
	figure.show()
	_breathing.volume_db = 0.0
	if not _breathing.playing:
		_breathing.play()


## La criatura detrás de un panel se ve apenas la ventana queda a la vista; a la vista, se retira a los
## creature_seconds.
func _advance_creature(delta: float) -> void:
	match _creature:
		Creature.HIDDEN:
			if _window_visible:
				_show_creature()
		Creature.SEEN:
			_creature_seen += delta
			if _creature_seen >= _requests.catalog.balance.creature_seconds:
				_creature_leaves()


## La criatura se desvanece y se calla.
func _creature_leaves() -> void:
	_creature = Creature.AWAY
	_breathing.stop()
	_knocks.stop()
	var tween := create_tween()
	tween.tween_property(figure, ^"modulate:a", 0.0, LEAVE_SECONDS)
	tween.tween_callback(figure.hide)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## El rojo del jumpscare: tres parpadeos, o uno suave.
func jumpscare_alphas() -> Array[float]:
	if reduce_flashes:
		return [0.3, 0.3, 0.0]
	return [0.5, 0.0, 0.35, 0.0, 0.25, 0.0]


## Lleva `property` de `target` por cada opacidad de `alphas`, `step` segundos cada una.
```

por:

```gdscript
## Lleva `property` de `target` por cada opacidad de `alphas`, `step` segundos cada una.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	view.desk_visible = not (_chat_panel.visible or _mixer.visible or _phone.visible)
```

por:

```gdscript
	view.desk_visible = not (_chat_panel.visible or _mixer.visible or _phone.visible)
	view.panel_open = _chat_panel.visible or _mixer.visible
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
con el cuaderno y con el jumpscare.
```

por:

```gdscript
con el cuaderno y con la criatura de la ventana.
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[ext_resource type="AudioStream" path="res://audio/sfx/scare_jumpscare.wav" id="jumpscare_sound"]
```

por:

```text
[ext_resource type="AudioStream" path="res://audio/sfx/scare_creature_breathing.wav" id="breathing_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_creature_knocks.wav" id="knocks_sound"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="Screamers" type="Node" parent="." node_paths=PackedStringArray("curtains", "figure", "phone", "darkness", "jumpscare", "notebook", "ambient")]
```

por:

```text
[node name="Screamers" type="Node" parent="." node_paths=PackedStringArray("curtains", "figure", "phone", "darkness", "notebook", "ambient")]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
darkness = NodePath("../Darkness")
jumpscare = NodePath("../Overlay/Jumpscare")
notebook = NodePath("../UI/NotebookPanel")
```

por:

```text
darkness = NodePath("../Darkness")
notebook = NodePath("../UI/NotebookPanel")
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="JumpscareSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("jumpscare_sound")
bus = &"Effects"
```

por:

```text
[node name="CreatureBreathing" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("breathing_sound")
bus = &"Effects"

[node name="CreatureKnocks" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("knocks_sound")
bus = &"Effects"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="Jumpscare" type="Control" parent="Overlay"]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Flash" type="ColorRect" parent="Overlay/Jumpscare"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.45, 0.43, 0.48, 1)

[node name="Figure" type="AnimatedSprite2D" parent="Overlay/Jumpscare"]
position = Vector2(640, 380)
scale = Vector2(2, 2)
sprite_frames = ExtResource("enemy")

[node name="Red" type="ColorRect" parent="Overlay/Jumpscare"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0.55, 0, 0.04, 0)

[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

por:

```text
[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
def scream():
    """El jumpscare: un grito disonante y fuerte."""
    white, samples, phases, seconds = noise(18), [], [0.0, 0.0, 0.0], 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for index, base in enumerate((520, 555, 740)):
            phases[index] += 2 * math.pi * (base + 40 * math.sin(2 * math.pi * (6 + index) * t)) / RATE
            value += 2 * (phases[index] / (2 * math.pi) % 1.0) - 1
        envelope = min(t / 0.02, 1.0) * (1.0 if t < 1.0 else (seconds - t) / 0.5)
        samples.append((0.22 * value + 0.25 * white()) * envelope)
    return samples


def knock():
```

por:

```python
def knock():
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    write("scare_jumpscare", scream())
    write("scare_creature_breathing", breathing())
```

por:

```python
    write("scare_creature_breathing", breathing())
```

Borrar el sonido que ya no se usa:

```bash
git rm -q audio/sfx/scare_jumpscare.wav audio/sfx/scare_jumpscare.wav.import
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `0 fallidas`. Si `test_el_susto_guionado_ensena_el_celular` falla por tiempos, es porque ya no hay pausa de 1,5 s: leer la falla antes de cambiar nada.

- [ ] **Paso 5: Sacar la captura y revisarla**

Corre con ventana (sin `--headless`), y Godot tiene que estar cerrado:

```bash
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_screamers.gd -- /mnt/c/dev/capturas/window.png /mnt/c/dev/capturas/ink.png /mnt/c/dev/capturas/creature.png /mnt/c/dev/capturas/script.png /mnt/c/dev/capturas/script_phone.png 2>&1 | tr -d '\r' | grep -E "Captura|ERROR"
```

Esperado: 5 líneas `Captura guardada en …` y ningún `ERROR`. Abrir `creature.png` con Read: el escritorio completo, sin pantalla gris ni destello rojo, con la figura en la ventana, detrás del vidrio y de las cortinas.

- [ ] **Paso 6: Corregir lo que mostró la captura**

Al revisar `creature.png` (el primer intento), la figura no estaba: el desvanecimiento del screamer de la ventana, que todavía corría (la captura los pide uno tras otro), se llevaba también a la criatura. En el juego el hueco de 25 s entre screamers lo evita, pero es frágil: la criatura y el screamer de la ventana comparten la figura, así que cada uno corta el desvanecimiento del otro.

Agregar al final de `test/test_screamer_manager.gd`:

```gdscript
## El screamer de la ventana y la criatura comparten la figura: el desvanecimiento del uno no esconde al otro.
func test_la_criatura_corta_el_desvanecimiento_del_screamer_de_la_ventana() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	screamers.play(ScareKind.Kind.WINDOW)
	var window_tween: Tween = screamers._figure_tween
	check(window_tween.is_valid(), "el screamer de la ventana se desvanece solo")
	screamers.play(ScareKind.Kind.JUMPSCARE)
	check(not window_tween.is_valid(), "la criatura corta ese desvanecimiento")
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "y se queda a la vista")
	desk.free()
	return true
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
var _window_visible := true
```

por:

```gdscript
var _window_visible := true
## El desvanecimiento de la figura de la ventana, que comparten el screamer de la ventana y la criatura.
var _figure_tween: Tween
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	figure.modulate.a = 1.0
	figure.show()
	var tween := create_tween()
	tween.tween_interval(EFFECT_SECONDS * 0.6)
```

por:

```gdscript
	figure.modulate.a = 1.0
	figure.show()
	var tween := _new_figure_tween()
	tween.tween_interval(EFFECT_SECONDS * 0.6)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	_creature_seen = 0.0
	figure.modulate.a = 1.0
	figure.show()
```

por:

```gdscript
	_creature_seen = 0.0
	if _figure_tween != null:
		_figure_tween.kill()
	figure.modulate.a = 1.0
	figure.show()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	_knocks.stop()
	var tween := create_tween()
	tween.tween_property(figure, ^"modulate:a", 0.0, LEAVE_SECONDS)
	tween.tween_callback(figure.hide)
```

por:

```gdscript
	_knocks.stop()
	var tween := _new_figure_tween()
	tween.tween_property(figure, ^"modulate:a", 0.0, LEAVE_SECONDS)
	tween.tween_callback(figure.hide)


## Un tween nuevo para la figura de la ventana, que corta el anterior.
func _new_figure_tween() -> Tween:
	if _figure_tween != null:
		_figure_tween.kill()
	_figure_tween = create_tween()
	return _figure_tween
```

Importar y correr las pruebas (ver "Antes de empezar"), y volver a sacar la captura del Paso 5: ahora `creature.png` muestra la figura en la ventana.

Esperado: `0 fallidas`.

- [ ] **Paso 7: Commit**

```bash
git add scripts/ scenes/ data/ tools/ audio/ test/
git commit -m "La criatura se asoma por la ventana en lugar del jumpscare" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Los diales en la noche 0

**Archivos:**

- Modificar: `scripts/core/tutorial_guide.gd`, `scripts/ui/tutorial_hint.gd`, `scenes/ui/tutorial_hint.tscn`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_tutorial_guide.gd`, `test/test_tutorial_desk.gd`

Lo primero que dice el tutorial son los 3 diales, con un botón "Entendido" (decisión de Benja). El guía lo hace con `explain_dials`, que el escritorio enciende: los demás usos de `TutorialGuide` y sus pruebas no cambian.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_tutorial_guide.gd`:

```gdscript
## Lo primero que dice el tutorial son los diales (decisión de Benja, 4 de noviembre), con un botón Entendido.
func test_primero_los_diales() -> bool:
	var guide := TutorialGuide.new()
	guide.explain_dials = true
	var hint := guide.hint(_view())
	check_eq(hint.key, TutorialGuide.DIALS_KEY, "los diales")
	check(hint.needs_ok, "con su botón")
	guide.dials_understood()
	hint = guide.hint(_view())
	check_eq(hint.key, TutorialGuide.WELCOME_KEY, "después, la bienvenida")
	check(not hint.needs_ok, "sin botón")
	return true
```

En `test/test_tutorial_desk.gd`, reemplazar:

```gdscript
	check_eq(_hint_text(desk), _expected(TutorialGuide.WELCOME_KEY), "bienvenida")
```

por:

```gdscript
	check_eq(_hint_text(desk), _expected(TutorialGuide.DIALS_KEY), "primero, los diales")
	var ok := desk.get_node("Overlay/TutorialHint/Box/Ok") as Button
	check(ok.visible, "con su botón Entendido")
	ok.pressed.emit()
	desk._process(0.0)
	check(not ok.visible, "el botón se va")
	check_eq(_hint_text(desk), _expected(TutorialGuide.WELCOME_KEY), "bienvenida")
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: fallan `test_tutorial_guide.gd` (no existe `explain_dials`) y `test_tutorial_desk.gd`.

- [ ] **Paso 3: Implementar**

Agregar al final de `data/text/ui.csv`:

```csv
TUTORIAL_DIALS,"Los 3 diales de la pared: Conexión (verde) es la señal de tus amigos. Cordura (roja) baja con los sustos y sube con el celular. Confianza (amarilla) baja si respondes mal o tardas en contestar. Si uno llega a 0, se pierde la noche.",
TUTORIAL_DIALS_OK,Entendido,
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
const SCROLL_KEY := "TUTORIAL_SCROLL"
```

por:

```gdscript
const SCROLL_KEY := "TUTORIAL_SCROLL"
const DIALS_KEY := "TUTORIAL_DIALS"
const DIALS_OK_KEY := "TUTORIAL_DIALS_OK"
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
class Hint:
	var key := ""
	var friend_index := -1

	func _init(hint_key: String, hint_friend := -1) -> void:
		key = hint_key
		friend_index = hint_friend
```

por:

```gdscript
class Hint:
	var key := ""
	var friend_index := -1
	## El aviso lleva un botón "Entendido": sigue hasta que Matías lo presiona.
	var needs_ok := false

	func _init(hint_key: String, hint_friend := -1, with_ok := false) -> void:
		key = hint_key
		friend_index = hint_friend
		needs_ok = with_ok
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
var _phone := Phone.WAITING
```

por:

```gdscript
## Lo primero que dice el tutorial son los diales (decisión de Benja, 4 de noviembre). Lo enciende el escritorio.
var explain_dials := false
var _phone := Phone.WAITING
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
## Qué hacer ahora. Primero el celular, después el chat guionado, el video y la solicitud en curso.
func hint(view: View) -> Hint:
	match _phone:
```

por:

```gdscript
## Matías presionó "Entendido" en el aviso de los diales.
func dials_understood() -> void:
	explain_dials = false


## Qué hacer ahora. Primero los diales, después el celular, el chat guionado, el video y la solicitud en curso.
func hint(view: View) -> Hint:
	if explain_dials:
		return Hint.new(DIALS_KEY, -1, true)
	match _phone:
```

En `scripts/ui/tutorial_hint.gd`, reemplazar:

```gdscript
signal skip_pressed
```

por:

```gdscript
signal skip_pressed
## Matías presionó "Entendido".
signal ok_pressed
```

En `scripts/ui/tutorial_hint.gd`, reemplazar:

```gdscript
@onready var _skip: Button = $Box/Skip
```

por:

```gdscript
@onready var _ok: Button = $Box/Ok
@onready var _skip: Button = $Box/Skip
```

En `scripts/ui/tutorial_hint.gd`, reemplazar:

```gdscript
	_skip.pressed.connect(skip_pressed.emit)
```

por:

```gdscript
	_skip.pressed.connect(skip_pressed.emit)
	_ok.text = tr(TutorialGuide.DIALS_OK_KEY)
	_ok.pressed.connect(ok_pressed.emit)
```

En `scripts/ui/tutorial_hint.gd`, reemplazar:

```gdscript
## Muestra `text`. Sin texto, solo quedan el título y el botón.
func show_text(text: String) -> void:
	_body.text = text
	_body.visible = not text.is_empty()
```

por:

```gdscript
## Muestra `text`, con el botón "Entendido" si `with_ok`. Sin texto, solo quedan el título y el botón de saltar.
func show_text(text: String, with_ok := false) -> void:
	_body.text = text
	_body.visible = not text.is_empty()
	_ok.visible = with_ok
```

En `scenes/ui/tutorial_hint.tscn`, reemplazar:

```text
[node name="Skip" type="Button" parent="Box"]
```

por:

```text
[node name="Ok" type="Button" parent="Box"]
visible = false
layout_mode = 2
size_flags_horizontal = 8
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 11

[node name="Skip" type="Button" parent="Box"]
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
		_tutorial_hint.skip_pressed.connect(tutorial_skipped.emit)
```

por:

```gdscript
		_tutorial_hint.skip_pressed.connect(tutorial_skipped.emit)
		_guide.explain_dials = true
		_tutorial_hint.ok_pressed.connect(_guide.dials_understood)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_tutorial_hint.show_text(tr(hint.key).format({"friend": friend_name}) if not hint.key.is_empty() else "")
```

por:

```gdscript
	_tutorial_hint.show_text(tr(hint.key).format({"friend": friend_name}) if not hint.key.is_empty() else "",
			hint.needs_ok)
```

- [ ] **Paso 4: Verificar que pasan**

Importar y correr las pruebas (ver "Antes de empezar").

Esperado: `0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ data/ test/
git commit -m "Los diales se explican en la noche 0" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Documentos y cierre

**Archivos:**

- Crear: `sonidos_pendiente.md`
- Modificar: `CLAUDE.md`, `spook_dial_design.md`, `docs/02_bucle_central.md`, `docs/04_instrucciones_godot.md`, `arte_pendiente.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Crear `sonidos_pendiente.md`**

`sonidos_pendiente.md`:

````markdown
# Sonidos pendientes

Todos los sonidos del juego son **provisionales**: los generó Claude con `tools/make_placeholder_sounds.py` para que el juego suene mientras tanto. Benja pone los reales.

**Cómo reemplazar uno:** copia tu archivo a `audio/sfx/` con **el mismo nombre** del que reemplaza (`.wav`, mono o estéreo) y vuelve a abrir el proyecto en Godot. No hay que tocar nada más: la escena lo carga por nombre. Si el sonido nuevo dura distinto, avísale a Claude, porque `test/test_placeholder_sounds.gd` anota cuántos segundos dura cada uno. **No corras `make_placeholder_sounds.py` después de poner los tuyos:** vuelve a escribir los provisionales encima.

El sonido ambiente va en el canal `Ambience`, y todos los demás, en `Effects` (opciones del jugador, diseño §19).

---

## Primero: la criatura en la ventana (4 de noviembre)

Reemplazan al grito del jumpscare. La criatura se asoma por la ventana cuando el chat o el mixer la tapan, y se ve al cerrarlos.

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `scare_creature_breathing.wav` | 8 s | Desde que la criatura llega (bajito, detrás del panel) y más fuerte cuando se ve. Se corta a los 4 s de verse. | Respiración pesada y ronca, de algo grande al otro lado del vidrio. |
| `scare_creature_knocks.wav` | 7 s | Al llegar la criatura, mientras el panel está abierto. | Golpeteos en el vidrio, en tandas que se vuelven más fuertes. Los golpes caen en 0,6 s, 1,1 s, 2,9 s, 3,35 s, 3,8 s, 5,4 s, 5,8 s, 6,2 s y 6,5 s del archivo. |

## Screamers del escritorio

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `scare_curtains.wav` | 1,2 s | Las cortinas se mecen | Roce de tela |
| `scare_window.wav` | 1,5 s | La figura aparece un instante en la ventana (el screamer ambiental) | Un golpe grave y un chillido |
| `scare_phone.wav` | 1,2 s | El celular vibra solo | Tres zumbidos |
| `scare_lights.wav` | 1,5 s | Las luces parpadean | Zumbido eléctrico que se corta |
| `scare_slam.wav` | 0,5 s | El cuaderno se cierra de golpe | Un golpe seco |
| `scare_ink.wav` | 0,6 s | La mancha de tinta cae en la página | Algo húmedo que se aplasta |

## Ambiente y alucinaciones

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `ambient_room.wav` | 8 s | Siempre, en bucle | Viento grave y un zumbido eléctrico. Tiene que empalmar al repetirse. |
| `hallucination_knock.wav` | 1 s | Con Sanity bajo: golpes que no vienen de nada | Tres golpes en la ventana |
| `hallucination_steps.wav` | 2 s | Ídem | Pasos lentos sobre madera |
| `hallucination_whisper.wav` | 2 s | Ídem | Un susurro sin palabras |
| `hallucination_scratch.wav` | 1,5 s | Ídem | Rasguños en la pared |

Además, las alucinaciones reusan `interference_static.wav` y `scare_phone.wav`.

## Audio Sync, interferencias

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `sync_kick.wav` | 0,22 s | La base, en cada golpe fuerte | Un bombo |
| `sync_tick.wav` | 0,06 s | La base, en los golpes intermedios | Un platillo cerrado |
| `sync_clap.wav` | 0,25 s | Los aplausos del amigo | Un aplauso |
| `sync_tap.wav` | 0,12 s | El golpe de Matías | Un golpe de madera, distinto del aplauso |
| `sync_success.wav` | 0,4 s | Se acierta una ronda | Cuatro notas que suben |
| `sync_fail.wav` | 0,44 s | Se falla una ronda | Dos notas que bajan |
| `interference_static.wav` | 3 s | Avisa una interferencia | Estática con chasquidos |

---

## Faltan (todavía no existen, ni como relleno)

Son del Plan 9 (sonido y pulido):

- Cuando llega un video y cuando se recibe.
- Los clics del menú, de los botones y del chat.
- La música o el ambiente del menú principal.
- La pantalla final: ganar una noche, perderla y la victoria.
- Los pasos o la voz de los amigos, si los quieres.
````

- [ ] **Paso 2: Actualizar las decisiones y el diseño**

En `CLAUDE.md`, reemplazar:

```markdown
| 02-11-2026 | **La figura de la ventana** (`enemy_sprite`) está escondida: aparece como el screamer de la ventana y, a ×2, como jumpscare provisional hasta el arte. |
```

por:

```markdown
| 02-11-2026 | **La figura de la ventana** (`enemy_sprite`) está escondida: aparece como el screamer de la ventana y es la criatura que se asoma (decisión del 4-nov). |
| 04-11-2026 | **La criatura se asoma por la ventana en lugar del jumpscare** (era aburrido): con respiración pesada y golpes en el vidrio, sin tapar la pantalla ni pausar la noche. Se arma **solo cuando el chat o el mixer tapan la ventana**, y al cerrarlos ya está ahí (así no hace falta animarla); se queda 4 s a la vista. Los otros 6 screamers no cambian. Los sonidos son provisionales y están en `sonidos_pendiente.md`. |
| 04-11-2026 | **Las noches 1 y 2 tienen más sucesos:** la noche 1 pasa a 5 solicitudes, 2 a la vez y 85 s, con la señal que baja, 1 interferencia, Audio Sync de 4 aplausos y 2 screamers ambientales; la noche 2 pasa a 7 solicitudes, 3 interferencias y 4 screamers (`docs/02` §6). |
| 04-11-2026 | **Audio Sync de 8 aplausos son 2 rondas de 4**, cada una con su cuenta y su patrón: si se falla la segunda, se vuelve a la primera. La señal solo vuelve a 100 al terminar las 2. |
| 04-11-2026 | **Trust también baja si tardas en contestar:** cada solicitud que lleva más de 30 s abierta (45 con "Temporizadores ×1,5") le quita 0,25 por segundo, y mientras haya una Trust no se recupera. Preguntar cuenta como tiempo abierto. No aplica en la noche 0. |
| 04-11-2026 | **Los diales se explican en la noche 0:** el primer aviso del tutorial dice qué es cada uno, con un botón "Entendido". No hay letreros ni avisos de cambio por ahora. |
```

En `CLAUDE.md`, reemplazar:

```markdown
| `arte_pendiente.md` | **Todo el arte que falta**, por urgencia, con tamaños y lo que hay hoy en su lugar. |
```

por:

```markdown
| `arte_pendiente.md` | **Todo el arte que falta**, por urgencia, con tamaños y lo que hay hoy en su lugar. |
| `sonidos_pendiente.md` | **Todos los sonidos provisionales**: dónde suena cada uno, cómo tendría que sonar y cómo reemplazarlo. |
| `docs/16_plan_feedback_1.md` | Plan 8.1: el feedback de la primera prueba (la criatura en la ventana, las noches 1 y 2, Audio Sync en rondas, Trust y los diales). |
```

En `spook_dial_design.md`, reemplazar:

```markdown
  - jumpscare de pantalla completa: como máximo **uno por noche**, desde la noche 2.
```

por:

```markdown
  - **la criatura en la ventana** (antes, un jumpscare de pantalla completa; decisión de Benja, 4 de noviembre): como máximo **uno por noche**, desde la noche 2. Se asoma por la ventana con respiración pesada y golpes en el vidrio. Se arma solo cuando el chat o el mixer tapan la ventana, y al cerrarlos ya está ahí; se queda unos 4 segundos. No tapa la pantalla ni pausa la noche.
```

En `spook_dial_design.md`, reemplazar:

```markdown
- Una base marca el tiempo, y el amigo marca un ritmo de **4 u 8 aplausos**, según la noche. El mixer parpadea con el ritmo y suena (decisión de Benja, sesión 14).
```

por:

```markdown
- Una base marca el tiempo, y el amigo marca un ritmo de **4 aplausos**. El mixer parpadea con el ritmo y suena (decisión de Benja, sesión 14). Las noches de 8 aplausos son **2 rondas de 4 seguidas**, cada una con su cuenta y su patrón: si se falla la segunda, se vuelve a la primera (decisión de Benja, 4 de noviembre). La señal solo vuelve a 100 al terminar todas.
```

En `spook_dial_design.md`, reemplazar:

```markdown
- Baja al elegir acciones riesgosas (§9), al no contestar a tiempo y mientras haya amigos sin señal (§10.1).
```

por:

```markdown
- Baja al elegir acciones riesgosas (§9), al no contestar a tiempo y mientras haya amigos sin señal (§10.1).
- **También baja si tardas en contestar** (decisión de Benja, 4 de noviembre): cada solicitud que lleva más de 30 s abierta le quita 0,25 por segundo, y mientras haya una no se recupera. Preguntar cuenta como tiempo abierto. Responder rápido no cuesta nada.
```

En `spook_dial_design.md`, reemplazar:

```markdown
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust, ya sin ayuda. La señal no baja. El mensaje inicial siempre trae una pista. |
```

por:

```markdown
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust, ya sin ayuda. La señal baja un poco, con 1 interferencia y Audio Sync de 4 aplausos, y hay 2 screamers ambientales. El mensaje inicial siempre trae una pista. |
```

En `spook_dial_design.md`, reemplazar:

```markdown
| 4 | Casa abandonada y cueva | El Basilisco, El Imbunche | Audio Sync de 8 tiempos y varias solicitudes a la vez. |
```

por:

```markdown
| 4 | Casa abandonada y cueva | El Basilisco, El Imbunche | Audio Sync de 8 aplausos (2 rondas de 4) y varias solicitudes a la vez. |
```

- [ ] **Paso 3: Actualizar `docs/02` y `docs/04`**

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Solicitudes por noche (aprox.) | 4 | 6 | 7 | 8 | 10 |
| Solicitudes simultáneas máx. | 1 | 2 | 2 | 3 | 3 |
| Tiempo base para responder (s) | 90 | 80 | 75 | 70 | 65 |
```

por:

```markdown
| Solicitudes por noche (aprox.) | 5 | 7 | 7 | 8 | 10 |
| Solicitudes simultáneas máx. | 2 | 2 | 2 | 3 | 3 |
| Tiempo base para responder (s) | 85 | 80 | 75 | 70 | 65 |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| La señal baja | No | Sí | Sí | Sí | Sí |
| Interferencias (aprox. por noche) | 0 | 2 | 3 | 4 | 6 |
| Audio Sync (tiempos) | — | 4 | 4 | 8 | 8 |
```

por:

```markdown
| La señal baja | Sí | Sí | Sí | Sí | Sí |
| Interferencias (aprox. por noche) | 1 | 3 | 3 | 4 | 6 |
| Audio Sync (aplausos; 8 son 2 rondas de 4) | 4 | 4 | 4 | 8 | 8 |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Screamers (sin contar las alucinaciones) | 0 | 3 | 4 | 5 | 6 |
| Uno de ellos es el jumpscare | No | Sí | Sí | Sí | Sí |
```

por:

```markdown
| Screamers (sin contar las alucinaciones) | 2 | 4 | 4 | 5 | 6 |
| Uno de ellos es la criatura de la ventana (el antiguo jumpscare) | No | Sí | Sí | Sí | Sí |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Trust | 100 al empezar cada noche | Ver §5.2. Con amigos sin señal, −1 cada 4 s por cada uno (§4.1). |
```

por:

```markdown
| Trust | 100 al empezar cada noche | Ver §5.2. Con amigos sin señal, −1 cada 4 s por cada uno (§4.1). Cada solicitud abierta más de 30 s: −0,25 por segundo (45 s con "Temporizadores ×1,5"; decisión de Benja, 4 de noviembre). |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
- Audio Sync: una base de 100 golpes por minuto. Tras un compás de cuenta, el amigo aplaude 4 u 8 veces en corcheas (el primer aplauso al comienzo) y Matías lo repite en el compás siguiente (o en los 2 siguientes). Tolerancia de cada golpe: ±150 ms.
```

por:

```markdown
- Audio Sync: una base de 100 golpes por minuto. Tras un compás de cuenta, el amigo aplaude 4 veces en corcheas (el primer aplauso al comienzo) y Matías lo repite en el compás siguiente. Las noches de 8 aplausos son 2 rondas de 4 seguidas, cada una con su cuenta y su patrón; si se falla la segunda, se vuelve a la primera con patrones nuevos (decisión de Benja, 4 de noviembre). Tolerancia de cada golpe: ±150 ms.
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
  - el jumpscare dura 1,5 s y pausa la noche mientras tapa la pantalla.
```

por:

```markdown
  - la criatura de la ventana (el antiguo jumpscare) solo se arma con el chat o el mixer abiertos, que tapan la ventana; se ve apenas se cierran y se queda 4 s. No tapa nada ni pausa la noche (decisión de Benja, 4 de noviembre).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
   - Unos segundos después llega el susto (el jumpscare) y Gonzalo te escribe. Respóndele con el botón.
```

por:

```markdown
   - Unos segundos después, con la ventana a la vista, la criatura se asoma por la ventana, con respiración y golpes en el vidrio, y Gonzalo te escribe. Respóndele con el botón.
```

Agregar al final de `docs/04_instrucciones_godot.md`:

````markdown
---

## M. Probar el feedback de la primera prueba (Plan 8.1)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. **Los diales:** con **Nueva partida**, lo primero que dice el aviso de la noche 0 son los 3 diales, con un botón **Entendido**. Presiónalo: sigue el aviso de siempre.
2. **La criatura en la ventana:** en la noche 2 o más, deja el chat de un amigo abierto cuando llegue el susto (se nota por la señal previa: las luces parpadean y baja el ambiente). Se oyen una respiración y golpes en el vidrio, pero no se ve nada. Cierra el chat: la criatura ya está en la ventana, y se va a los 4 s. No tapa la pantalla.
3. **Las noches 1 y 2:** la noche 1 ahora tiene señal que baja, 1 interferencia, Audio Sync de 4 aplausos y 2 screamers (sin la criatura). ¿Pasa más? ¿Es muy difícil? Anota qué sientes.
4. **Audio Sync en 2 rondas:** en la noche 4 o 5, el mixer dice "Ronda 1 de 2". Si aciertas, pasa sola a la 2. Si fallas la 2, dice que vuelves a la ronda 1.
5. **Trust:** deja una solicitud sin responder más de 30 s y mira el dial amarillo: baja de a poco. Responde y deja de bajar.

**Verifica:** los pasos 1 a 5 se cumplen. Si algo falla, o los valores se sienten mal, anótalo: están en `data/balance.tres` (Trust y la criatura) y en `data/nights/night_N.tres`.

### Para ajustar

- **Trust por tardar:** `data/balance.tres`, `Slow Answer Grace` (30 s) y `Slow Answer Trust` (0,25 por segundo).
- **Cuánto se queda la criatura:** `Creature Seconds` (4 s).
- **Las noches 1 y 2:** `data/nights/night_1.tres` y `night_2.tres`, en el Inspector.
- **Los sonidos de la criatura:** `sonidos_pendiente.md`.
````

En `arte_pendiente.md`, reemplazar:

```markdown
Mientras tanto (Plan 7): la figura de la ventana (`enemy_sprite`) aparece como screamer y, a ×2 sobre un destello gris, como jumpscare; la mancha de tinta la dibuja Godot con círculos.
```

por:

```markdown
Mientras tanto (Plan 7): la figura de la ventana (`enemy_sprite`) aparece como screamer y, desde el 4 de noviembre, es la criatura que se asoma por la ventana (sin animación de entrada: se ve al cerrar el chat o el mixer); la mancha de tinta la dibuja Godot con círculos.
```

- [ ] **Paso 4: Cerrar la sesión**

- `resumen.md`: entrada de la sesión (arriba del todo) con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar:
  - **probar el feedback** (`docs/04`, M, unos 15 minutos), y decir cómo se sienten las noches 1 y 2, Trust y la criatura;
  - **poner los sonidos reales** (`sonidos_pendiente.md`), empezando por los de la criatura;
  - corregir los textos nuevos (`TUTORIAL_DIALS*`, `MIXER_ROUND` y `MIXER_FAIL_RESTART`, en `ui.csv`).
- Arrastrar los pendientes que sigan abiertos y anotar dos ideas que quedaron fuera: ayudas para los diales (letrero al pasar el mouse, aviso cuando uno cambia, nombres provisionales) si Trust sigue sin notarse, y enseñar Audio Sync en la noche 0.
- `docs/00_log.md`: anotar en "Cambios a la secuencia" que el feedback de Benja se aplicó en la misma sesión S19 (Plan 8.1, `docs/16`), y dejar S20 como siguiente.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md CLAUDE.md spook_dial_design.md arte_pendiente.md sonidos_pendiente.md test/
git commit -m "Plan 8.1 terminado: feedback de la primera prueba" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Fuera de este plan, a propósito

- **Ayudas para los diales** (letrero al pasar el mouse, aviso cuando uno cambia de golpe, nombres provisionales): Benja eligió solo explicarlos en la noche 0. Si Trust sigue sin notarse, es lo siguiente.
- **Enseñar Audio Sync en la noche 0:** ahora aparece en la noche 1, sin práctica. Si en las pruebas con personas no lo entienden, es una tarea de S20.
- **La criatura animada:** hoy no tiene animación de entrada, a propósito (decisión de Benja). Si Benja dibuja una, `enemy_sprite` ya tiene su lugar en la escena.
- **El equilibrio:** todos los valores de este plan son de partida y se ajustan en S20 con las pruebas.

## Autorrevisión del plan

- **Cobertura** (feedback de Benja):

  | Requisito | Tarea |
  | --- | --- |
  | La criatura se asoma por la ventana en lugar del jumpscare, con respiración y golpes | 4 y 5 |
  | Se arma solo con el chat o el mixer abiertos y está ahí al cerrarlos | 5 |
  | Sonidos provisionales y `sonidos_pendiente.md` | 4 y 7 |
  | Las noches 1 y 2 con más sucesos | 1 |
  | Audio Sync en 2 rondas de 4; fallar la segunda vuelve a la primera | 3 |
  | Trust baja si tardas en contestar | 1 y 2 |
  | Los diales se explican en la noche 0 | 6 |
  | Documentos al día | 7 |

- **Nombres consistentes:** `slow_answer_grace` y `slow_answer_trust` (Tareas 1 y 2), `open_seconds`, `is_slow()`, `impatient` e `impatient_count()` (Tarea 2), `rounds_total()`, `round_index`, `ROUND_BEATS` y `_begin_round()` (Tarea 3), `creature_seconds`, `panel_open`, `is_creature_near()`, `CreatureBreathing`, `CreatureKnocks` y `Creature.AWAY/HIDDEN/SEEN` (Tarea 5), y `explain_dials`, `dials_understood()` y `DIALS_KEY` (Tarea 6) coinciden entre el código y las pruebas.
