# Plan 9.7: la historia en el chat — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que la historia de cada noche se cuente en el chat (`docs/21`, decisiones de Benja en S21b) y que la noche 1 se juegue con su guion aprobado en Normal, Difícil y Extremo, sin cambiar qué criatura llega ni qué acción es la correcta, y con toda noche ganable.

1. **La historia es un dato de la noche:** sus momentos (al empezar, antes y después de las olas, y al cerrar), cada uno con sus líneas, separarse, reunirse y las decisiones.
2. **La llamada grupal:** con los 3 juntos y nada que jugar, el chat es una llamada con un ícono, sin pestañas, con las barritas de los 3. Si llega algo que jugar, se separa en los 3 chats; cuando ya no queda nada, vuelve.
3. **Las decisiones llegan como un accidente:** con alarma, 15 s y sus opciones, y pueden dar 2 aciertos con distinto costo, bajar Trust, quitarle segundos a la próxima consulta de un amigo y herir (sin matar).
4. **Cada criatura nueva de la noche sale al menos una vez,** forzada solo cuando hace falta.
5. **Con los 3 juntos, las consultas no dicen "Me perdí" ni "Me separé de los demás".**
6. **La prueba de equilibrio juega la historia,** con sus decisiones, en los 3 modos.

**Arquitectura:**

- **Los datos** (`scripts/data/story_*.gd`): `StoryData` (la historia de una noche) tiene momentos (`StoryBeatData`), cada uno con su disparador (`Moment`) y sus pasos (`StoryStepData`: una línea, separarse, reunirse o una decisión). Una decisión (`StoryDecisionData`) trae sus opciones (`StoryOptionData`) y lo que pasa sin respuesta. `NightData.story` apunta a la historia; las 3 noches 1 usan la misma (`data/story/night_1.tres`).
- **`StoryRunner`** (`scripts/core/story_runner.gd`, lógica pura, como `TutorialChat`): recorre los momentos en orden. Cada momento empieza cuando llega su disparador, que lee del director; si su ola ya empezó o ya pasó un momento posterior, se salta, pero se aplican sus cambios de estado (separarse o reunirse). Devuelve órdenes (`Item`): una línea en el chat de un amigo, una línea en la llamada o una decisión. Las líneas de la llamada esperan a que la llamada esté a la vista; una decisión espera a que su amigo esté libre y con señal. Lo usan `RequestManager` y el modelo de la prueba de equilibrio.
- **`PacingDirector`** cuenta las olas y las calmas que empezaron, sabe cuál es la última ola común y **espera a la historia** (`story_hold`): mientras la historia tiene algo que contar antes de la próxima ola, la ola espera, a lo más `BalanceData.story_hold_limit` (45 s, decisión de Benja en esta sesión).
- **`RequestManager`** crea el `StoryRunner`, cumple sus órdenes (las líneas con la estática de quien habla y las decisiones como accidentes) y aplica las opciones. Expone `call_active()` y la señal `call_message_added`. Además fuerza las criaturas nuevas y avisa al generador si están juntos.
- **`ChatPanel`** tiene una conversación más, la llamada, y la muestra con su encabezado y 3 botones de señal cuando `call_active()`. **`ChatEntry`** muestra el ícono de la llamada.
- **`test/balance_model.gd`** corre el `StoryRunner` real con el director real: las decisiones son tareas, como los accidentes, y quien juega bien elige la buena opción más cara.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`).

**Cómo se ejecuta:** se escribe y se ejecuta en la misma sesión (S21l), con un commit por tarea que Benja autorizó al empezar. **El código exacto de cada tarea está en su commit.**

**Punto de partida:** 763 pruebas OK (commit `0a4c2dd`, con los documentos de S21b).

---

## Decisiones de Benja

**De S21b (`docs/21`):** la historia habla de las criaturas pero las consultas no cambian; la llamada grupal; se repite igual al perder; igual en los 3 modos; el canal Acá Penan; las cinemáticas solo en la intro y el final; la regla 9 enmendada; y el guion de la noche 1, aprobado.

**De esta sesión (12 de noviembre):**

| Pregunta | Decisión |
| --- | --- |
| Si la reunión de la noche 1 no termina antes de la ola final | **La final espera** a la reunión y a sus 3 líneas previas, a lo más 45 s. Jugando bien nunca espera; si un jugador lento la atrasa, la final puede perder su última consulta (como ya pasa con un amigo herido). Si la final llega encima de la ola 2, las decisiones se saltan y se reúnen solos. |
| ¿La historia puede hacer perder por Trust? | **No:** Trust no baja de 1 por la historia, como la vida (la historia nunca mata ni hace perder). Sigue bajando por las consultas. |
| Commits | Todos los de la sesión, en `main`, sin push. |
| El editor | Cerrado durante la sesión: se puede reimportar. |

**Lo que se midió antes de decidir** (con el modelo de "jugar bien" y la noche 1 de hoy, 20 semillas): la calma antes de la final dura de 57 a 77 s en Normal, 95 s en Difícil y 46 s en Extremo. Con 15 s más por consulta: 27 a 47 s, 65 s y 32 a 36 s. Con 30 s más, en Normal la final llega encima de la ola 2 en 13 de 20 noches. La reunión toma de 25 a 50 s, según lo que tarden las decisiones, y las líneas antes de la final, unos 15 s.

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **Las líneas se escriben a 60 letras por segundo, con 1,2 s para leer** cada una (como el chat). | Es la velocidad a la que el chat ya escribe. Un momento de 7 líneas toma unos 12 s. |
| **El momento antes de la ola 1 empieza 25 s antes** (los demás "antes de", 15 s). | Son 7 líneas en la llamada y después 3 en los chats de cada uno: no caben en 15 s. |
| **En Extremo, la "ola 2" de la historia es la última ola común**, y las del medio no tienen historia. Si el director se salta olas, se salta lo que venía antes de ellas. | Lo dice `docs/21` §2. |
| **Las líneas de la llamada esperan a que la llamada se vea** (si hay un video por descargar, esperan a que termine); las de un chat de amigo, no. | Si no, se leerían después de la final, fuera de tiempo. |
| **Las opciones de una decisión van en el orden del guion,** sin barajar. | La historia se repite igual (decisión 3 de S21b). Es una elección de la historia, no una prueba de memoria. |
| **Los castigos de la historia son iguales en los 3 modos** (Extremo no los multiplica por 1,5). | La historia va igual en los 3 modos (decisión 4 de S21b). |
| **El daño de la historia hiere y aturde como un accidente** (y atrasa lo que falta, como cualquier amigo herido). | `docs/21` §2: "un daño de la historia, como el de un accidente". |
| **Los 10 s menos de la próxima consulta** se descuentan al empezar esa consulta, y nunca la dejan bajo 10 s. | Es la forma más simple de "la próxima consulta de Agustín, 10 s menos". |
| **Las respuestas de León a las 2 opciones malas** son borradores de Claude (el guion no las tenía): "Me escondí en el establo, pero algo entró. Salí corriendo a la cabaña, estoy agotado" y "Grité y algo me respondió desde el bosque. No era el Agus. Corrí a la cabaña". Las respuestas de Matías a Agustín son "Escóndete" y "Corre" (con León, "Escóndanse" y "Corran"). | Benja las corrige en `messages.csv`. |
| **Forzar las criaturas nuevas vale para todas las noches,** con o sin historia. | Lo decidió Benja como regla de las consultas (`docs/21` §1). |

---

## Tareas

### Tarea 1: La historia como datos

**Archivos:**

- Crear: `scripts/data/story_data.gd`, `story_beat_data.gd`, `story_step_data.gd`, `story_decision_data.gd` y `story_option_data.gd`.
- Modificar: `scripts/data/night_data.gd` (grupo "Historia": `story: StoryData`), `scripts/data/content_catalog.gd` (`alone_predicament_keys`) y `scripts/core/content_validator.gd`.
- Pruebas: `test/test_validator_catalog.gd` y `test/content_fixtures.gd` (`make_story()`).

**Los datos:**

- `StoryData`: `beats: Array[StoryBeatData]` y `starts_together := true`.
- `StoryBeatData`: `moment: Moment` (`NIGHT_START`, `BEFORE_FIRST_WAVE`, `AFTER_FIRST_WAVE`, `BEFORE_LAST_WAVE`, `AFTER_LAST_WAVE`, `BEFORE_FINALE` y `AFTER_FINALE`), `lead_seconds := 15.0` (para los "antes de") y `steps: Array[StoryStepData]`.
- `StoryStepData`: `kind: Kind` (`LINE`, `SEPARATE`, `JOIN` y `DECISION`), `speaker: FriendData`, `text_key: String`, `decision: StoryDecisionData`, y las condiciones `requires_flag` y `unless_flag` (`StringName`).
- `StoryDecisionData`: `friend: FriendData`, `message_key: String`, `options: Array[StoryOptionData]` y `no_answer: StoryOptionData`.
- `StoryOptionData`: `label_key` (lo que responde Matías; vacío en la de sin respuesta), `good := false`, `reply_keys: Array[String]`, `trust_change := 0.0`, `penalty_seconds := 0.0` con `penalized: Array[FriendData]`, `damage := 0` con `damage_candidates: Array[FriendData]`, y `sets_flag: StringName`.
- `ContentCatalog.alone_predicament_keys`: lo que le pasa a un amigo que está solo ("Me perdí", "Me separé de los demás").

**El validador** revisa la historia de cada noche que tenga: sin espacios vacíos; los que hablan y deciden son amigos del catálogo; cada línea tiene texto; cada decisión tiene al menos una opción buena, su opción sin respuesta y sus opciones con lo que responde Matías; los heridos y castigados son amigos del catálogo; y los momentos van en orden (no se puede poner uno antes de otro anterior). `alone_predicament_keys` tiene que estar dentro de `predicament_keys`. Las claves de texto de la historia entran en `_text_keys`.

- [ ] **Paso 1:** pruebas en `test_validator_catalog.gd`:
  - `test_una_historia_valida_no_tiene_errores`;
  - `test_la_historia_habla_con_amigos_del_catalogo`;
  - `test_una_decision_necesita_una_opcion_buena_y_su_sin_respuesta`;
  - `test_los_momentos_de_la_historia_van_en_orden`;
  - `test_lo_que_le_pasa_a_uno_solo_esta_en_las_frases`;
  - `test_las_claves_de_la_historia_se_revisan` (con `validate_texts`).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La historia de una noche como datos, con su validación".

### Tarea 2: El director cuenta las olas y espera a la historia

**Archivos:** `scripts/core/pacing_director.gd`, `scripts/data/balance_data.gd`, `data/balance.tres` y `test/test_pacing_director.gd`.

- `waves_started` y `calms_started` (cuántas empezaron), `finale_started()`, `last_regular_index()` (la última ola común planeada; -1 si no hay) y `finale_index()`.
- `story_hold := false`: en el silencio y en las calmas, la próxima ola no empieza mientras esté encendido, salvo que ya lleve `story_hold_limit` segundos de atraso (desde `next_at`). En una ola, la final llega a su hora como siempre.
- `BalanceData.story_hold_limit := 45.0` (decisión de Benja).

- [ ] **Paso 1:** pruebas:
  - `test_cuenta_las_olas_y_las_calmas`;
  - `test_la_ultima_ola_comun` (con olas automáticas, con un plan y sin final);
  - `test_la_ola_espera_a_la_historia`;
  - `test_la_espera_dura_a_lo_mas_45_s`;
  - `test_la_final_espera_a_la_historia`;
  - `test_balance.gd`: el valor nuevo en `test_valores_del_director_y_los_screamers`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El director cuenta sus olas y espera a la historia".

### Tarea 3: `StoryRunner`, la historia en curso

**Archivos:** crear `scripts/core/story_runner.gd` y `test/test_story_runner.gd`.

**Qué hace:**

- `_init(story, friends, translate)`: empieza juntos o separados según la historia.
- `advance(delta, now, director, busy, call_open, is_free) -> Array[Item]`: avanza el momento en curso.
  - **Cuándo llega cada momento** (con el director): `NIGHT_START`, enseguida; `BEFORE_FIRST_WAVE`, en el silencio, `lead_seconds` antes de la ola 0; `AFTER_FIRST_WAVE`, desde la primera calma; `BEFORE_LAST_WAVE`, en la calma antes de la última ola común, `lead_seconds` antes; `AFTER_LAST_WAVE`, en la calma antes de la final; `BEFORE_FINALE`, en esa calma, `lead_seconds` antes; y `AFTER_FINALE`, cuando llegó todo lo de la final y no hay nada abierto (`busy` en false).
  - **Cuándo se cierra:** el silencio, al empezar la ola 0; `AFTER_FIRST_WAVE`, al empezar la ola siguiente; `BEFORE_LAST_WAVE`, al empezar la última ola común o la final; los de la calma antes de la final, al empezar la final. `AFTER_FINALE` no se cierra.
  - **En orden:** un momento que llega, empieza; uno que se cerró, o que ya no puede llegar porque llegó uno posterior, se salta. Al saltarse o cerrarse, se aplican sus pasos de separarse y reunirse (sin líneas ni decisiones), y queda anotado (`skipped_beats` o `cut_beats`; los enteros, en `finished_beats`).
  - **Los pasos:** una línea espera lo que tarda en escribirse (60 letras por segundo, más 1,2 s); con los 3 juntos va a la llamada (`CALL_LINE`), y espera a que la llamada se vea (`call_open`); si no, al chat de quien habla (`LINE`). Una decisión espera a que su amigo esté libre (`is_free`) y, al empezar, espera la respuesta. Un paso con condición (`requires_flag` o `unless_flag`) se salta si no se cumple.
- `decided(option) -> Array[Item]`: la decisión terminó; deja su marca y devuelve lo que responde el amigo, en su chat.
- `holds() -> bool`: la historia está contando algo (un momento empezado): la próxima ola espera.
- `is_done() -> bool`.

- [ ] **Paso 1:** pruebas en `test_story_runner.gd` (con una historia de prueba y un director real de una noche con 2 olas comunes y la final):
  - `test_la_noche_empieza_con_la_llamada`;
  - `test_las_lineas_esperan_lo_que_tardan_en_escribirse`;
  - `test_antes_de_la_ola_llega_con_su_anticipacion`;
  - `test_separarse_lleva_las_lineas_a_cada_chat`;
  - `test_despues_de_la_primera_ola_en_la_primera_calma`;
  - `test_la_reunion_en_la_calma_antes_de_la_final`;
  - `test_en_extremo_las_olas_del_medio_no_tienen_historia` (4 olas comunes);
  - `test_si_se_salta_la_ultima_ola_se_salta_lo_de_antes` (la calma salta a la final);
  - `test_un_momento_que_se_cierra_corta_sus_lineas_pero_se_reunen`;
  - `test_si_la_final_llega_encima_se_saltan_las_decisiones_y_se_reunen`;
  - `test_la_llamada_espera_a_que_se_vea`;
  - `test_la_decision_espera_a_que_el_amigo_este_libre`;
  - `test_la_decision_espera_la_respuesta_y_trae_sus_lineas`;
  - `test_las_marcas_eligen_las_lineas_y_las_decisiones`;
  - `test_el_cierre_espera_a_que_no_quede_nada`;
  - `test_mientras_cuenta_algo_la_ola_espera`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La historia en curso: sus momentos, la llamada y las decisiones".

### Tarea 4: El manager cuenta la historia

**Archivos:** `scripts/desk/request_manager.gd`, `scripts/core/friend_incident.gd`, `scripts/core/request_generator.gd`, `test/test_request_manager.gd` y `test/test_request_generator.gd`.

- **`RequestManager`:**
  - `story: StoryRunner` en las noches con historia (no en el tutorial); señal `call_message_added(speaker_index, message)`;
  - antes de avanzar el director, `director.story_hold = story.holds()`; después, avanza la historia y cumple sus órdenes: `LINE` al chat del amigo (con su estática), `CALL_LINE` a la llamada (con la estática de quien habla) y `DECISION` como un accidente (`incidents[amigo]`), con su mensaje;
  - `answer_incident` y `_advance_incidents` resuelven también las decisiones: Matías responde con la opción (sin respuesta, la de `no_answer`), el amigo responde, y se aplica la opción: Trust (nunca bajo 1), los segundos de la próxima consulta de cada castigado y el daño al que tenga más vida entre los candidatos, solo si sobrevive (con su aviso y el respiro del director);
  - `call_active()`: juntos y sin consultas, accidentes, decisiones ni videos por descargar;
  - al empezar una consulta: descuenta los segundos pendientes del amigo (nunca bajo 10 s), avisa si están juntos y fuerza las criaturas nuevas que faltan cuando quedan tantas consultas como ellas.
- **`FriendIncident.for_decision(decision, friend, seconds)`**: un accidente con las opciones de la decisión, en orden; `decision` guarda de dónde viene.
- **`RequestGenerator.generate(..., together, candidates)`**: con `together`, no usa `alone_predicament_keys`; con `candidates`, elige la entidad entre ellas.

- [ ] **Paso 1:** pruebas:
  - `test_request_generator.gd`: `test_juntos_no_dice_que_esta_solo` y `test_puede_elegir_entre_algunas_entidades`;
  - `test_request_manager.gd`:
    - `test_sin_historia_no_hay_llamada`;
    - `test_la_historia_escribe_en_la_llamada` (con la estática de quien habla);
    - `test_separados_escribe_en_cada_chat`;
    - `test_la_llamada_se_corta_con_algo_que_jugar`;
    - `test_la_decision_llega_como_un_accidente`;
    - `test_responder_la_decision_aplica_su_opcion`;
    - `test_sin_respuesta_cuenta_como_la_peor`;
    - `test_la_historia_no_deja_trust_en_0`;
    - `test_la_proxima_consulta_tiene_menos_tiempo`;
    - `test_el_dano_es_para_el_que_tiene_mas_vida`;
    - `test_la_historia_nunca_mata`;
    - `test_cada_criatura_nueva_sale_al_menos_una_vez`;
    - `test_juntos_las_consultas_no_dicen_que_esta_solo`;
    - `test_la_ola_espera_a_la_historia` (con el director del manager).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El manager cuenta la historia: la llamada, las decisiones y las criaturas nuevas".

### Tarea 5: La llamada grupal en el chat y en el PC

**Archivos:** `scenes/ui/chat_panel.tscn`, `scripts/ui/chat_panel.gd`, `scripts/ui/chat_entry.gd`, `scripts/desk/desk.gd`, `tools/make_ui_art.py` (`art/ui/chat_call.png`, 11×11), `data/text/ui.csv`, `test/test_chat_panel.gd`, `test/test_chat_entry.gd` y `test/test_desk_scene.gd`.

- **El chat en llamada** (cuando `call_active()`):
  - en lugar de las pestañas, `%CallHeader`: el ícono y "LLAMADA GRUPAL" (`CHAT_CALL_TITLE`);
  - la conversación de la llamada, con el nombre de quien habla en su color y su voz;
  - en la barra de identificación, `%CallSync`: un botón por amigo con su nombre y sus barritas, que parpadea sin señal y abre el mixer en su canal (`CHAT_CALL_SYNC`, con {friend});
  - sin la descarga, las preguntas ni las respuestas.
  
  Al cortarse la llamada con el chat abierto, se elige el primer amigo con algo que jugar.
- **Las entradas del PC** muestran el ícono de la llamada (en lugar del temporizador) mientras dura, salvo un amigo sin señal o aturdido, que muestra lo de siempre. Cualquiera abre la llamada.

- [ ] **Paso 1:** pruebas:
  - `test_chat_panel.gd`: `test_en_llamada_no_hay_pestanas`, `test_la_llamada_muestra_quien_habla`, `test_en_llamada_hay_una_senal_por_amigo`, `test_la_llamada_se_corta_en_el_chat_del_que_juega` y `test_las_voces_de_la_llamada`;
  - `test_chat_entry.gd`: `test_en_llamada_muestra_el_icono`;
  - `test_desk_scene.gd`: `test_las_entradas_abren_la_llamada`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar, generar el ícono con `/usr/bin/python3 tools/make_ui_art.py` y reimportar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La llamada grupal en el chat y en las entradas del PC".

### Tarea 6: El guion de la noche 1

**Archivos:** crear `data/story/night_1.tres`; modificar `data/nights/normal/night_1.tres`, `hard/night_1.tres` y `extreme/night_1.tres` (`story`), `data/catalog.tres` (`alone_predicament_keys` = `PREDICAMENT_1` y `PREDICAMENT_4`), `data/text/messages.csv` (`STORY_N1_*`) y las pruebas `test/test_catalog.gd`.

El guion es el de `docs/21` §4, tal cual, en 7 momentos:

| Momento | Pasos |
| --- | --- |
| `NIGHT_START` | 5 líneas en la llamada (León, León, Gonzalo, Agustín y León). |
| `BEFORE_FIRST_WAVE` (25 s) | 7 líneas en la llamada; se separan; cada uno escribe dónde está (Gonzalo, León y Agustín). |
| `AFTER_FIRST_WAVE` | León (2), Gonzalo, Agustín y León (la semilla). |
| `BEFORE_LAST_WAVE` (15 s) | Gonzalo, León y Agustín. |
| `AFTER_LAST_WAVE` | Gonzalo (2); la decisión de León; la de Agustín, sola o con León (marca `leon_with_agustin`); se reúnen; 3 líneas en la llamada. |
| `BEFORE_FINALE` (15 s) | León, Gonzalo y Agustín, en la llamada. |
| `AFTER_FINALE` | León, Gonzalo, Agustín y León, en la llamada. |

**La decisión de León:** "Anda a la amarilla" (buena: Agustín, 10 s menos), "Anda a las blancas" (buena: León, 10 s menos, Trust −10 y la marca), "Vuelve al establo y espera ahí" y "Grita y ve de dónde responden" (malas: Trust −20 y los 3, 10 s menos); sin respuesta, como las malas. **La de Agustín:** "Escóndete" (buena) y "Corre" (mala: Trust −10 y 1 de daño a Agustín); con León, en plural y el daño para el que tenga más vida de los dos; sin respuesta, como la mala.

- [ ] **Paso 1:** pruebas en `test_catalog.gd`:
  - `test_la_noche_1_tiene_su_historia_en_los_3_modos` (la misma historia, 7 momentos en orden);
  - `test_la_historia_de_la_noche_1_empieza_juntos_y_se_separa_antes_de_la_ola_1`;
  - `test_las_decisiones_de_la_noche_1` (opciones, buenas, castigos y marca);
  - `test_lo_que_le_pasa_a_uno_solo`;
  - las del validador y de los textos ya corren sobre el catálogo real.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** escribir los textos y los recursos (con un script temporal que arma el `.tres` con `ResourceSaver` y se borra), y reimportar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El guion de la noche 1 en los 3 modos".

### Tarea 7: La prueba de equilibrio juega la historia

**Archivos:** `test/balance_model.gd`, `test/test_balance.gd` y `test/dump_waves.gd`.

- `simulate()` corre el `StoryRunner` real si la noche tiene historia: antes del director, `story_hold`; después, la historia. Una decisión es una tarea (4 s de atención y 15 s de plazo, y ocupa a su amigo); quien juega bien elige la buena opción que más Trust cuesta, y aplica sus castigos (Trust y los segundos de la próxima consulta). El resultado suma `story` (los momentos enteros, saltados y cortados) y `story_hold` (la mayor espera de una ola).
- `test_balance.gd`:
  - `test_jugando_bien_la_historia_llega_entera` (los 3 modos, 20 semillas: ningún momento saltado ni cortado);
  - `test_jugando_bien_la_final_casi_no_espera` (la espera más larga, bajo 10 s);
  - las de siempre (nada vence, Trust sobre 75 y la holgura) ya incluyen la historia.

- [ ] **Paso 1:** las pruebas.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar. Si una noche deja de ganarse, ajustar primero el momento (su anticipación) y después la noche, y anotarlo abajo.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La prueba de equilibrio juega la historia".

### Tarea 8: Revisión

**Archivos:** `test/capture_plan97.gd` (nuevo) y lo que haga falta corregir.

**Capturas a 1280×720 y 1920×1080:** la llamada al empezar (con las entradas del PC); los chats separados después de la ola 1; la decisión de León; la llamada al reunirse; el cierre.

- [ ] **Paso 1:** sacar las capturas, revisarlas y corregir lo que haga falta.
- [ ] **Paso 2:** correr todas las pruebas: OK. Abrir el juego sin errores nuevos.
- [ ] **Paso 3:** commit "Revisión de la historia de la noche 1".
- [ ] **Paso 4:** documentos: `CLAUDE.md`, el diseño v2, `docs/02`, `docs/04` (sección X, nueva), `docs/05`, `docs/21`, `arte_pendiente.md` (el ícono de la llamada), este plan con su resultado, `docs/00_log.md` y `resumen.md`. Commit "Documentos de la sesión S21l: la historia de la noche 1".

---

## Fuera de este plan

- **La noche 2,** cuando Benja apruebe su guion (`docs/21` §5): un amigo inconsciente, una decisión que daña a otro y cortar la señal a propósito.
- **Las noches 3 a 5** (`docs/21` §6), después de probar las noches 1 y 2.
- **Para Benja:** probar la noche 1 en los 3 modos (`docs/04`, X) y corregir los textos nuevos (`STORY_N1_*` en `messages.csv`, `CHAT_CALL_TITLE` y `CHAT_CALL_SYNC` en `ui.csv`).
