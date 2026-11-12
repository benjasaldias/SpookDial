# Plan 9.4: Normal y Difícil — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** la segunda de las 3 sesiones con el feedback del primer testeo (`docs/26` §3, sesión S21i):

1. **Dos modos, Normal y Difícil,** cada uno con sus 5 noches. Normal empieza en la noche 0 (el tutorial) y Difícil en la noche 1. Difícil se desbloquea al terminar Normal (D1, D2 y D5).
2. **La noche 1 de Normal, armada a mano** con un plan de olas: 1 consulta y su video; 2 consultas separadas, con la Mano y 1 interferencia; y la final con consulta, video y consulta. No tiene accidente (observación 12 y D7).
3. **Las noches 2 a 5 de Normal,** algo más fáciles que hoy (`docs/26` §3.3).
4. **Difícil se identifica leyendo:** el chat no destaca nada, no se marca nada y Matías no piensa. La página se busca en el índice del cuaderno (D3).
5. **El menú:** "Nueva partida" pide elegir la dificultad, y "Continuar" muestra la de la partida guardada. Al terminar Normal, el resumen avisa que se desbloqueó Difícil.

**Arquitectura:**

- **`DifficultyData`** (`scripts/data/difficulty_data.gd`, recurso nuevo): `data/difficulty/normal.tres` y `hard.tres`. Cada una tiene sus noches (`data/nights/normal/` y `data/nights/hard/`). La noche 0 sigue siendo una sola (`data/nights/night_0.tres`).
- **`ContentCatalog.difficulties`** reemplaza a `nights`. Normal va primero y es la de por defecto. `nights()`, `night()`, `known_entities()` y `new_pages()` reciben la dificultad (o usan la de por defecto).
- **`RequestManager.difficulty`**: la elige `GameState`. Sin dificultad, la de por defecto.
- **El plan de olas:**
  - `WaveData` (`scripts/data/wave_data.gd`, recurso nuevo) describe una ola armada a mano;
  - `NightData.wave_plan` es opcional, y si está vacío, `PacingDirector` arma las olas solo, como hoy;
  - con un plan, los videos también llegan dentro de las olas.
- **El progreso** se guarda en su propio archivo (`GameProgress`, `user://progress.cfg`), porque `save.cfg` se borra al ganar la noche 5. **La partida** (`save.cfg`) guarda también la dificultad.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`). El arte, con Python (Pillow y numpy).

**Cómo se ejecuta:** como los Planes 9.1 a 9.3. Se escribe y se ejecuta en la misma sesión (S21i), con un commit por tarea que Benja autorizó al empezar. **El código exacto de cada tarea está en su commit.**

**Punto de partida:** 661 pruebas OK.

**Resultado (11-nov, S21i):** ejecutado completo, en 11 commits. **715 pruebas OK.** Las capturas se revisaron a 1280×720 y a 1920×1080 (`C:\dev\capturas\plan94_*.png`, con la curva de la noche 1 de Normal en `plan94_curva_normal_1.png`), y el juego abre sin errores nuevos.

| Tarea | Commit | Pruebas |
| --- | --- | --- |
| 1. Las dificultades y el catálogo | `1082abf` | 671 |
| 2. La dificultad en la partida y el progreso | `d102b47` | 680 |
| 3. El plan de olas | `2fb4458` | 695 |
| 4. El modelo de "jugar bien" en los 2 modos | `51062e5` | 696 |
| 5. La noche 1 de Normal | `d2adb99` | 697 |
| 6. Las noches 2 a 5 de Normal | `5a87b0a` | 698 |
| 7. Difícil se identifica leyendo | `7c7743d` | 703 |
| 8. El candado | `c9f76b3` | 704 |
| 9. El menú con la dificultad | `f48e51a` | 711 |
| 10. El aviso de Difícil desbloqueado | `f4c1d34` | 715 |
| 11. Revisión con capturas | `79f9d6c` | 715 |

**Lo que cambió al ejecutar:**

- **14 s y no 15 en Difícil:** antes de escribir el plan se probó el modelo con 13, 14 y 15 s por consulta. Con 15, la noche 5 de Difícil deja de poder ganarse en 9 de 20 semillas: la ola final de 3, con 45 s para responder, no alcanza.
- **La prueba de Difícil sin clics** quedó en `test_chat_panel.gd` (`test_en_dificil_se_responde_sin_marcar_nada`) y no en `test_request_manager.gd`: así recorre el chat de verdad (las preguntas, el mensaje sin enlaces, la página abierta desde la memoria del cuaderno y la hoja de respuesta). `test_request_manager.gd` revisa que la dificultad diga las noches y si se destaca.
- **"Continuar" arma su texto en el código:** "Continuar: noche 3" (`MENU_CONTINUE`, como antes) más " · " y el nombre del modo, igual que los títulos del chat ("RESPONDER · EL TRAUCO"). `MENU_CONTINUE` no cambió.
- **La línea del candado va aparte,** en ámbar, debajo de la descripción del modo, que queda del color normal.
- **La opción marcada usa el estilo de "pasar el mouse"** (azul claro con borde celeste): con el de "apretado" se confundía con Difícil bloqueada, que también se ve hundida.
- **El candado va al doble** (`expand_icon`): sin eso se veía de 11 px junto a la letra de 22.
- **Normal y Difícil se ven en `GameState.locked_difficulties()`,** que también usa el menú, y `unlocked_by_winning()` dice qué desbloquea la última noche.
- **El script de capturas se colgó una vez** por asignar una lista sin tipo a `unlocks_on_win`. Ahora se corre con `timeout 150`.

---

## Decisiones de Benja (S21g y S21i, 11 de noviembre)

| Decisión | Detalle |
| --- | --- |
| **D1: dónde se elige** | Solo al empezar una partida nueva. Difícil se desbloquea al ganar la noche 5 en Normal. "Continuar" muestra la dificultad de la partida guardada. |
| **D2: Normal es una curva suave** | La noche 1 armada a mano (`docs/26` §3.2) y las noches 2 a 5 algo más fáciles que hoy (§3.3). `test_balance` comprueba los 2 modos. |
| **D3: Difícil se identifica leyendo** | Ni amarillo ni azul, nada se clickea y Matías no piensa. La página se busca en el índice del cuaderno. |
| **D5: Difícil empieza en la noche 1** | Sin tutorial. |
| **D7: la noche 1 de Normal** | Sin accidente, 1 interferencia en la segunda ola y los 2 screamers en las calmas. Los accidentes empiezan en la noche 2 de Normal. |
| **El audio en Difícil** (pregunta de S21i) | Se clickea para oírlo y **queda en azul**, como en Normal: es la forma de oírlo. |
| **El cuaderno en Difícil** (pregunta de S21i) | No cambia: es el manual, y conserva el azul y el amarillo. |
| **La ola final de la noche 1 de Normal** (pregunta de S21i) | Llegan una consulta, el video y otra consulta, en ese orden. |
| **Commits** | Benja autorizó todos los de la sesión, en `main` y sin push. |

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **El modelo de "jugar bien" en Difícil dedica 14 s a cada consulta** (12 en Normal). | No hay que marcar ni esperar a Matías, pero hay que leer y buscar la página en el índice: 2 s más en total. **Con 15 s, la noche 5 de Difícil deja de poder ganarse** (la ola final de 3 con 45 s), así que en Difícil esa noche queda justo en el límite. |
| **Un video del plan de olas llega cuando a la consulta anterior le quedan 30 s**, o 3 a 6 s después de que no quede ninguna consulta abierta. | Es lo que pidió Benja ("cuando a la consulta le queda poco tiempo"), sin dejar al jugador esperando si respondió rápido. |
| **Las llegadas de una ola armada a mano se alternan:** consulta, video, consulta y así. Entre dos consultas, o después de un video, pasan los segundos de `spacing`. | Así una ola no trae nada junto. |
| **La última ola del plan es la final** y llega lo más tarde posible para que su última consulta termine antes de las 06:00, como hoy. En la noche 1 de Normal es hacia las 03:04. | La regla de la ola final (11 de noviembre) vale igual con un plan. |
| **Lo demás de una ola armada a mano funciona como en las automáticas:** la Mano y las interferencias llegan de 3 a 15 s después de que empieza; la final llega a su hora aunque la ola anterior no se haya resuelto, y una ola que ya no cabe antes de la final se salta. | Son las reglas de siempre del director. |
| **Con un plan de olas, los totales de la noche** (solicitudes, screamers, la criatura, la Mano, las interferencias y los accidentes) **salen del plan.** Los campos de `NightData` se ignoran y el Inspector lo dice. | Así Benja puede dejar la ola 2 en 1 consulta cambiando un solo número. |
| **La elección de dificultad es una lista con Normal marcado**, con una línea que describe cada una, y los botones "Empezar" y "Volver". Si hay una partida guardada, después de elegir se pide confirmar que se borra. | Evita empezar por un clic de más, y "Normal (marcado)" es lo que pide `docs/26` §3.5. |
| **El aviso de Difícil desbloqueado sale solo la primera vez** que se gana la noche 5 en Normal. | La segunda vez ya estaba desbloqueada. |
| **Una partida guardada antes de S21i se lee como Normal**, y un archivo de progreso que no existe significa que no se terminó nada. | Una partida vieja empezó con el juego de entonces, y Normal es lo de por defecto. |
| **`balance.tres` sigue siendo uno solo.** En la noche 1 de Normal, el silencio de 45 s lo pone su plan; las demás noches de Normal usan los 60 s de siempre. | No hizo falta cambiar otro valor global para que la curva Normal pase `test_balance`. |
| **En Normal, Trust amenaza de otra forma:** con 5 a 9 consultas, las respuestas incorrectas solas no alcanzan a vaciarlo, pero sin contestar ninguna sí. | La prueba de que 7 incorrectas pierden una noche queda solo para Difícil. |

---

## Tareas

### Tarea 1: Las dificultades y el catálogo

**Archivos:**

- `scripts/data/difficulty_data.gd` (nuevo), `data/difficulty/normal.tres` y `hard.tres` (nuevos);
- `data/nights/hard/night_1.tres` a `night_5.tres` (los de hoy, movidos con `git mv`), y `data/nights/normal/night_1.tres` a `night_5.tres` (por ahora, copias de los de Difícil);
- `scripts/data/content_catalog.gd`, `data/catalog.tres`, `scripts/core/content_validator.gd`, `scripts/desk/request_manager.gd`, `desk.gd` y `scripts/ui/chat_panel.gd`;
- las pruebas: `test/content_fixtures.gd`, `test_night_and_catalog.gd`, `test_validator_catalog.gd`, `test_catalog.gd` y las que usan `catalog.nights`.

**`DifficultyData`:**

- `id` (`&"normal"` o `&"hard"`), `name_key` y `description_key`, en `ui.csv`;
- `nights: Array[NightData]`: las noches 1 a 5;
- `first_night`: 0 en Normal (el tutorial) y 1 en Difícil;
- `highlights`: con `true`, la identificación es guiada (amarillo, azul, clics y "Matías piensa"); con `false`, se lee;
- `unlocked_by: DifficultyData`: la que hay que terminar para desbloquearla (Difícil → Normal; en Normal, ninguna).

**`ContentCatalog`:**

- `difficulties: Array[DifficultyData]` reemplaza a `nights`, con Normal primero;
- `default_difficulty()` y `find_difficulty(id)`, que entrega la de por defecto si no la encuentra;
- `nights(difficulty = null)`, `night(number, difficulty = null)`, `known_entities(night_number, difficulty = null)` y `new_pages(night_number, difficulty = null)`;
- `all_entities()` usa la de por defecto.

**El validador:**

- revisa que el catálogo tenga dificultades, sin espacios vacíos y con ids únicos;
- revisa cada dificultad: 5 noches en orden, `first_night` en 0 o 1, y `unlocked_by` del catálogo;
- **las entidades llegan en las mismas noches en todas las dificultades;**
- los chats guionados, los señuelos por lugar y los accidentes se revisan en las noches de cada dificultad.

**El resto del código:**

- `RequestManager` tiene `@export var difficulty: DifficultyData` (sin dificultad, la de por defecto), y `night()` la usa;
- `highlights()` dice si la identificación es guiada;
- el escritorio y el chat le pasan la dificultad a `known_entities()` y `new_pages()`.

**Las pruebas:**

- `catalog.nights` pasa a `catalog.nights()`;
- `Fixtures.make_catalog()` arma una dificultad Normal con sus 5 noches;
- `Fixtures.add_hard(catalog)` agrega Difícil, con otras noches y las mismas entidades.

- [x] **Paso 1:** pruebas:
  - `test_night_and_catalog.gd`: `test_cada_dificultad_tiene_sus_noches`, `test_sin_dificultad_se_usa_la_de_por_defecto` y `test_buscar_una_dificultad`;
  - `test_validator_catalog.gd`: `test_sin_dificultades`, `test_una_dificultad_con_4_noches`, `test_las_entidades_llegan_en_las_mismas_noches` y `test_desbloqueada_por_una_dificultad_de_afuera`;
  - `test_catalog.gd`: `test_normal_y_dificil`, con Normal primero, Difícil desbloqueada por Normal, noche de inicio 0 y 1, y `highlights` en `true` y `false`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar, mover las noches y armar los `.tres` (`--import` con el editor cerrado).
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Normal y Difícil: cada dificultad con sus noches".

### Tarea 2: La dificultad en la partida y el progreso

**Archivos:** `scripts/core/save_game.gd`, `scripts/core/game_progress.gd` (nuevo), `scripts/autoload/game_state.gd` y sus pruebas (`test_save_game.gd`, `test_game_progress.gd` (nuevo) y `test_game_state.gd`).

- **`SaveGame`:**
  - `store(night, difficulty_id := &"normal")`;
  - `stored_difficulty() -> StringName`: sin el valor (una partida vieja), `&"normal"`.
- **`GameProgress`** (`user://progress.cfg`):
  - `has_finished(id)`;
  - `mark_finished(id)`;
  - `is_unlocked(difficulty)`: no pide nada o ya se terminó la que pide.
- **`GameState`:**
  - carga el catálogo (`res://data/catalog.tres`);
  - `difficulty` es la dificultad de la partida en curso;
  - `new_game(chosen)` empieza en su `first_night`;
  - `continue_game()` lee la noche y la dificultad guardadas;
  - `prepare_night()` le pasa la dificultad al escritorio y la guarda con la noche;
  - al ganar la noche 5, borra la partida y marca la dificultad como terminada;
  - "Saltar tutorial" sigue en la misma dificultad.

- [x] **Paso 1:** pruebas:
  - `test_save_game.gd`: `test_guarda_la_dificultad` y `test_una_partida_vieja_es_normal`;
  - `test_game_progress.gd`: `test_sin_progreso`, `test_terminar_una_dificultad` y `test_dificil_se_desbloquea_al_terminar_normal`;
  - `test_game_state.gd`: `test_nueva_partida_empieza_en_la_noche_de_su_dificultad`, `test_continuar_vuelve_a_la_dificultad_guardada`, `test_preparar_una_noche_guarda_su_dificultad` y `test_ganar_la_noche_5_termina_la_dificultad`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "La partida guarda su dificultad, y el progreso dice qué dificultades se terminaron".

### Tarea 3: El plan de olas (lógica)

**Archivos:** `scripts/data/wave_data.gd` (nuevo), `night_data.gd`, `scripts/core/pacing_director.gd`, `content_validator.gd` y sus pruebas (`test_pacing_director.gd`, `test_night_and_catalog.gd` y `test_validator_catalog.gd`).

**`WaveData`:**

- **Llegadas:**
  - `requests := 1` y `videos := 0`;
  - `spacing := Vector2(4, 8)`: los segundos entre una llegada y la siguiente;
  - `video_time_left := 30.0` y `video_after_answer := Vector2(3, 6)`;
  - `calm_before := Vector2(40, 60)`: los segundos de calma antes de la ola (la primera, desde las 00:00; la final no lo usa);
  - `arrivals() -> Array[bool]`: el orden de las llegadas (consulta, video, consulta…), con `true` para un video.
- **En la ola:** `interferences`, `incidents` y `hands`.
- **En la calma que sigue:** `calm_scares` y `calm_creatures`.

**`NightData`:**

- `@export var wave_plan: Array[WaveData] = []`;
- `has_wave_plan()`, `total_requests()`, `total_scares()`, `total_creatures()`, `total_hands()`, `total_interferences()` y `total_incidents()`: con un plan, sumados del plan; si no, los campos de siempre.

**`PacingDirector`:**

- cada `Wave` tiene sus llegadas, su separación, su calma previa y los segundos de sus videos. Las automáticas son solo consultas, con `wave_spacing` y `wave_calm`;
- con un plan:
  - la primera ola llega a su `calm_before` y las demás, a su `calm_before` después de resolverse la anterior;
  - la última ola es la final;
- `request_due()` solo responde `true` si la próxima llegada es una consulta. Una ola que se corta pierde sus consultas, no sus videos;
- después de una consulta seguida de un video, el video toca a `base_decision_time − video_time_left`, o a `video_after_answer` segundos de que no quede ninguna consulta abierta. Llega en `Beat.videos`;
- si la final llega a su hora con videos pendientes en la ola anterior, los suelta en ese momento;
- `finale_time()` mide la ola final por sus llegadas (en la peor demora) y deja `hurt_respite` de margen. Con solo consultas da lo mismo que hoy;
- los videos de las calmas son los que no puso el plan (en un plan completo, ninguno).

**El validador:**

- en una noche con plan, los videos del plan suman la cuota;
- cada ola tiene al menos una consulta.

- [x] **Paso 1:** pruebas:
  - `test_night_and_catalog.gd`: `test_los_totales_salen_del_plan`;
  - `test_pacing_director.gd`:
    - `test_el_plan_reemplaza_las_olas_automaticas`;
    - `test_la_primera_ola_del_plan_llega_tras_su_calma`;
    - `test_el_video_llega_cuando_a_la_consulta_le_quedan_30_s`;
    - `test_el_video_llega_poco_despues_de_responder`;
    - `test_las_consultas_de_una_ola_planeada_se_separan`;
    - `test_la_calma_entre_olas_planeadas`;
    - `test_la_final_del_plan_llega_lo_mas_tarde_posible`;
    - `test_la_mano_y_las_interferencias_de_una_ola_planeada`;
    - `test_screamers_en_la_calma_de_una_ola_planeada`;
    - `test_un_plan_no_suelta_videos_en_las_calmas`;
  - `test_validator_catalog.gd`: `test_los_videos_del_plan_suman_la_cuota` y `test_una_ola_sin_consultas`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "El plan de olas: olas armadas a mano, con videos dentro de la ola".

### Tarea 4: El modelo de "jugar bien" en los 2 modos

**Archivos:** `test/balance_model.gd`, `test_balance.gd`, `test/dump_waves.gd` y `tools/plot_waves.py`.

- **`BalanceModel`:**
  - usa los totales de `NightData` (`total_scares()`, `total_creatures()` y `total_hands()`);
  - `simulate(night, balance, seed, guided := true)`: 12 s por consulta guiada y 14 s leyendo (`READING_ATTENTION`).
- **`test_balance.gd`:**
  - los valores de hoy pasan a ser los de Difícil (`catalog.find_difficulty(&"hard")`);
  - la batería, "nada vence" y "Trust sobre 75" se corren en las 5 noches de cada dificultad, con su forma de identificar;
  - `test_trust_amenaza` queda para Difícil, y Normal tiene `test_en_normal_sin_contestar_se_pierde`.
- **`dump_waves.gd`** recibe la dificultad como cuarto argumento (por defecto, `normal`).
- **`plot_waves.py`** dice la dificultad en el título.

- [x] **Paso 1:** cambiar las pruebas y verlas fallar donde corresponde.
- [x] **Paso 2:** implementar.
- [x] **Paso 3:** correr todas las pruebas: OK.
- [x] **Paso 4:** commit "La prueba de equilibrio corre en Normal y en Difícil".

### Tarea 5: La noche 1 de Normal, armada a mano

**Archivos:** `data/nights/normal/night_1.tres` y `test/test_balance.gd`.

**Los valores:**

- 90 s para responder, pista 100 %, lugar 80 %, 1 señuelo, sin accidente, Audio Sync de 4 aplausos a 90 golpes por minuto y cuota de 2;
- **el plan:**

| Ola | Llegadas | Separación | Calma antes | En la ola | Screamers en la calma que sigue |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 consulta y 1 video | — | 45 s (desde las 00:00) | — | 1 |
| 2 | 2 consultas | 30 a 45 s | 30 a 45 s | 1 Mano y 1 interferencia | 1 |
| Final | consulta, video, consulta | 30 a 45 s | — | — | — |

- Los totales de la noche se dejan iguales a los del plan, aunque no se usen: 5 solicitudes, 2 screamers, 1 Mano y 1 interferencia.

**La prueba:** `test_la_noche_1_de_normal`. Revisa el plan (1 + 2 + 2 consultas, 2 videos, sin accidentes, la Mano y la interferencia en la ola 2 y 1 screamer en cada calma). Además, en 20 semillas, con quien juega bien comprueba que:

- la primera consulta llega a los 45 s;
- el primer video llega antes de 60 s después de la primera consulta;
- las 2 consultas de la ola 2 llegan con 30 a 45 s de diferencia;
- en la final, video y consultas nunca llegan a menos de 20 s.

- [x] **Paso 1:** la prueba, y verla fallar.
- [x] **Paso 2:** armar el plan en el `.tres`.
- [x] **Paso 3:** correr todas las pruebas: OK.
- [x] **Paso 4:** la curva: `dump_waves.gd -- 1 1 … normal` y `plot_waves.py`. Revisarla contra `docs/26` §3.2.
- [x] **Paso 5:** commit "La noche 1 de Normal, armada a mano".

### Tarea 6: Las noches 2 a 5 de Normal

**Archivos:** `data/nights/normal/night_2.tres` a `night_5.tres` y `test/test_balance.gd`.

| Valor | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- |
| Segundos para responder | 80 | 70 | 65 | 60 |
| Consultas | 6 | 7 | 8 | 9 |
| Ola final | 2 | 2 | 3 | 3 |
| Señuelos | 1 | 2 | 2 | 3 |
| Pista | 100 % | 75 % | 50 % | 35 % |
| Lugar | 75 % | 70 % | 65 % | 60 % |
| Accidentes | 1 | 1 | 2 | 2 |
| Interferencias | 2 | 2 | 3 | 4 |
| La Mano | 1 | 1 | 2 | 2 |
| La criatura | 1 | 1 | 2 | 2 |
| Audio Sync (golpes por minuto) | 95 | 105 | 115 | 125 |
| Audio Sync (aplausos) | 4 | 4 | 4 | 8 |
| Cuota | 2 | 3 | 3 | 4 |
| Screamers | 4 | 4 | 5 | 6 |

Lo demás (olas de 2, 3 a la vez y la señal que baja) queda como en Difícil.

- [x] **Paso 1:** `test_valores_de_normal`, con la tabla, y verla fallar.
- [x] **Paso 2:** los valores en los `.tres`.
- [x] **Paso 3:** correr todas las pruebas: OK. Si una noche no pasa `test_balance`, preguntarle a Benja antes de cambiar la tabla.
- [x] **Paso 4:** commit "Las noches 2 a 5 de Normal, algo más fáciles".

### Tarea 7: Difícil se identifica leyendo

**Archivos:** `scripts/ui/chat_message_view.gd`, `chat_panel.gd` y sus pruebas (`test_chat_message_view.gd`, `test_chat_panel.gd` y `test_request_manager.gd`).

- **`ChatMessageView`** recibe `highlights := true`. Con `false`:
  - las características, los señuelos y la pista van sin color y sin enlace;
  - las observaciones, sin azul;
  - **el audio sigue en azul y se clickea** (decisión de Benja).
- **El chat**, con `RequestManager.highlights()` en `false`:
  - no muestra el avance de la identificación, "Matías piensa" ni el nombre de la entidad;
  - el botón de sincronizar sigue en su lugar.
- **El cuaderno** no cambia: la página se abre desde su índice, y las respuestas ya dependen de la página abierta.

- [x] **Paso 1:** pruebas:
  - `test_chat_message_view.gd`: `test_en_dificil_no_se_destaca_nada` (sin `[url` ni colores en las frases y en las observaciones) y `test_en_dificil_el_audio_se_oye` (en azul y con su enlace);
  - `test_chat_panel.gd`: `test_en_dificil_no_hay_barra_de_identificacion`;
  - `test_chat_panel.gd`: `test_en_dificil_se_responde_sin_marcar_nada`. Pregunta, abre la página desde la memoria del cuaderno (como el índice) y responde sin marcar nada: la solicitud termina con la acción correcta (al ejecutar se movió aquí desde `test_request_manager.gd`, que revisa `test_la_dificultad_dice_las_noches_y_si_se_destaca`).
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "En Difícil se identifica leyendo: nada se destaca ni se marca".

### Tarea 8: El candado

**Archivos:** `tools/make_ui_art.py`, `art/ui/menu_lock.png` (nuevo) y `test/test_ui_art.gd`.

- Un candado de 11×11, con la paleta de los sprites (el metal de los botones del menú y un ojo de la cerradura oscuro), para el botón de Difícil bloqueado.
- [x] **Paso 1:** generarlo (`/usr/bin/python3 tools/make_ui_art.py`), importarlo y sumarlo a `test_ui_art.gd`.
- [x] **Paso 2:** correr todas las pruebas: OK.
- [x] **Paso 3:** commit "El candado de la dificultad bloqueada".

### Tarea 9: El menú con la dificultad

**Archivos:** `scenes/menu/main_menu.tscn`, `scripts/ui/main_menu.gd`, `scripts/autoload/game_state.gd`, `data/text/ui.csv` y `test/test_main_menu.gd`.

- **"Nueva partida"** esconde los botones del menú y muestra la elección (`Center/Box/Difficulty`):
  - el título "Elige la dificultad";
  - una opción por dificultad, con Normal marcado y una línea que la describe;
  - Difícil bloqueada: desactivada, con el candado y "Termina Normal para desbloquearla.";
  - "Empezar" y "Volver".
- **"Empezar":**
  - sin partida guardada, empieza al tiro (`new_game_pressed(difficulty)`);
  - con una, primero pregunta, como hoy.
- **"Continuar"** dice "Continuar: noche 3 · Normal" (y "Continuar: noche de práctica · Normal").
- **`setup(saved_night, saved_difficulty, settings, difficulties, locked)`**: `GameState` le pasa todo, y el menú no conoce los archivos.
- **Textos nuevos en `ui.csv`:** `DIFFICULTY_NORMAL`, `DIFFICULTY_HARD`, `DIFFICULTY_NORMAL_INFO`, `DIFFICULTY_HARD_INFO`, `MENU_DIFFICULTY_TITLE`, `MENU_LOCKED`, `MENU_START` y `MENU_BACK`. "Continuar" agrega " · " y el nombre del modo en el código, así que `MENU_CONTINUE` y `MENU_CONTINUE_TUTORIAL` no cambian.

- [x] **Paso 1:** pruebas en `test_main_menu.gd`:
  - `test_nueva_partida_pide_la_dificultad`;
  - `test_normal_viene_marcada`;
  - `test_dificil_bloqueada`;
  - `test_dificil_desbloqueada`;
  - `test_volver_de_la_eleccion`;
  - `test_con_partida_se_confirma_despues_de_elegir`;
  - `test_continuar_dice_la_dificultad`;
  - las de hoy, adaptadas.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y reimportar los textos.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "El menú: elegir la dificultad, y Continuar dice cuál es".

### Tarea 10: El aviso de Difícil desbloqueado

**Archivos:** `scripts/core/ending_text.gd`, `scripts/ui/end_screen.gd`, `scripts/desk/desk.gd`, `scripts/autoload/game_state.gd`, `data/text/ui.csv` y sus pruebas (`test_ending_text.gd`, `test_end_screen.gd` y `test_game_state.gd`).

- `EndingText.summary(…, unlocked: Array[String] = [])` agrega, después de la victoria, "Desbloqueaste el modo {difficulty}." (`END_UNLOCKED`).
- **De dónde sale el aviso:**
  - `GameState.prepare_night()` le dice al escritorio qué dificultades desbloquea ganar esa noche (`desk.unlocks_on_win`). Solo pasa en la última noche y si todavía estaban bloqueadas;
  - el escritorio se lo pasa a la pantalla final.

- [x] **Paso 1:** pruebas:
  - `test_ending_text.gd`: `test_la_victoria_avisa_lo_desbloqueado`;
  - `test_game_state.gd`: `test_la_noche_5_de_normal_desbloquea_dificil` y `test_si_ya_estaba_desbloqueada_no_avisa`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Al terminar Normal, el resumen avisa que se desbloqueó Difícil".

### Tarea 11: Revisión con capturas

**Archivos:** `test/capture_plan94.gd` (nuevo) y lo que haga falta corregir.

- **Capturas a 1280×720 y a 1920×1080,** en `C:\dev\capturas\plan94_*.png`:
  - el menú con una partida guardada;
  - la elección con Difícil bloqueada y desbloqueada;
  - la confirmación;
  - el chat de Difícil con una pregunta respondida y una página abierta;
  - la victoria de Normal con el aviso.
- **Qué se revisa:**
  - la letra sigue nítida;
  - nada se sale de su caja;
  - el candado se ve parejo;
  - el chat de Difícil no deja nada destacado salvo el audio.

- [x] **Paso 1:** escribir el script y sacar las capturas.
- [x] **Paso 2:** revisarlas y corregir lo que haga falta.
- [x] **Paso 3:** correr todas las pruebas: OK. Abrir el juego sin errores nuevos.
- [x] **Paso 4:** commit "Revisión del menú y de Difícil con capturas".

---

## Fuera de este plan

- **S21j:** el tutorial (`docs/26` §4), que solo se juega en Normal.
- **S22:** Benja ajusta los valores de Normal y Difícil con las pruebas con personas. `test_balance` avisa si una noche deja de poder ganarse.
- **Para Benja:**
  - corregir los textos nuevos y las descripciones de cada dificultad;
  - redibujar el candado si quiere (`arte_pendiente.md`);
  - probar la noche 1 de Normal (`docs/04`, U).
