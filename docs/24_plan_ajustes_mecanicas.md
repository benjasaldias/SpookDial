# Plan 9.1: Ajustes de mecánicas y la Mano — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** aplicar lo que Benja eligió el 11 de noviembre del diagnóstico (`docs/22`) y sus 2 cambios propios, para que el juego deje de sentirse plano:

1. el mensaje inicial dice qué le pasa al amigo, y el lugar solo a veces;
2. los señuelos cuestan 1 s y las características se dicen con otras palabras;
3. olas de verdad, con calmas y un final fuerte;
4. un aviso cuando los videos ya no alcanzan;
5. la criatura se queda un tiempo al azar;
6. **la Mano**, que se espanta con el flash del celular;
7. **Trust sin recuperación**, y un video perdido baja Trust.

**Arquitectura:**

- **Datos:** `TraitData` suma `label_key` (el nombre en el cuaderno) y `variant_keys` (las otras formas de decirla). `NightData` suma `place_chance`, `finale_size` y `hand_visits`. `ContentCatalog` suma `predicament_keys`. `BalanceData` suma el costo del señuelo, las olas, el video perdido, la criatura y la Mano, y pierde la recuperación de Trust y los valores del director viejo.
- **Lógica pura:**
  - `PacingDirector` se reescribe: olas, calmas y ola final, y en cada una reparte lo que le toca (interferencias, accidentes, la Mano, videos y screamers).
  - `HandVisit` (nueva) lleva una visita de la Mano: los tirones, la posición y el agarre.
  - `NightState` pierde la recuperación de Trust y suma el flash, el agarre de la Mano y Trust por video perdido.
  - `VideoSchedule` suelta los videos cuando el director lo pide y dice si la cuota ya no alcanza.
  - `InterferenceSchedule` recibe las interferencias a medida que llegan las olas.
- **Escritorio:**
  - `RequestManager` conecta el director con la noche.
  - `HandManager` (nuevo) muestra la Mano, la hace sonar y aplica el flash.
  - `PhoneView` suma el ícono de la linterna.
  - `ChatPanel` muestra el "−1 s" del señuelo.
  - El PC muestra en rojo los videos que ya no alcanzan.
- **Sonidos:** `tools/make_sounds.py` genera el crujido de la Mano y el flash.

**Stack:** Godot 4.7.2 (GDScript con tipado estático). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `docs/22_diagnostico_mecanicas.md`, `docs/23_prompt_ajustes_mecanicas.md`, `spook_dial_design.md` §5, §8, §10 y §11, y `docs/02_bucle_central.md` §2, §3 y §6.

**Cómo se ejecuta:** este plan se escribió y se ejecutó en la misma sesión (S21f, Opus 5.5 · xhigh), tarea por tarea y con TDD en la lógica pura. Cada tarea tiene su commit (Benja autorizó todos), y **el código exacto de cada tarea está en su commit**. Si la sesión se corta, la siguiente sigue desde la primera casilla sin marcar, con las interfaces y las pruebas que describe cada tarea.

**Punto de partida:** 556 pruebas OK (11-nov, antes de la Tarea 1).

---

## Decisiones de este plan

### De Benja (11 de noviembre)

| # | Decisión | Valor de partida |
| --- | --- | --- |
| 1 | El mensaje inicial dice **qué le pasa** al amigo (está perdido, algo lo sigue o creyó escuchar algo) y **el lugar solo a veces**. | Lugar: 60, 55, 50, 45 y 40 % en las noches 1 a 5; en la noche 0, siempre. Orden: saludo, lo que le pasa, lugar y pista. 8 frases de lo que le pasa. |
| 2 | **Clickear un señuelo cuesta 1 s.** Cada característica **se dice de varias formas**, y el cuaderno muestra un **nombre fijo**. | 1 s, solo la primera vez que se clickea cada señuelo. 2 a 4 variantes por característica, más la forma de hoy. El nombre del cuaderno es la frase entre asteriscos de hoy. |
| 3 | **Olas de verdad y un final fuerte.** | Ver "El director de olas", abajo. |
| 4 | La cuota **no** sube. | Igual a los envíos programados. |
| 5 | **Aviso cuando los videos ya no alcanzan.** | En el PC, los videos en rojo y con "(faltan)". En el chat del amigo, un aviso rojo cada vez que se pierde un video y ya no alcanzan. |
| 6 | **La criatura se queda un tiempo al azar.** | Entre 15 y 40 s. |
| 7 | **La Mano** (idea de Benja). | Ver "La Mano", abajo. |
| 8 | **Trust no sube durante la noche** (vuelve a 100 al empezar cada una). **Un video perdido baja Trust** (pregunta 1). | Incorrecta: −15 (antes −10). Sin respuesta: −15 extra. Mayor riesgo: −20. Video perdido: −10. Tardar: −0,25 por segundo. |
| — | **Tiempo para responder:** noche 4, 45 → 50 s; noche 5, 40 → 45 s. | Con olas de verdad, 3 solicitudes a la vez no se alcanzan con 45 y 40 s (pregunta 6). |
| — | **Batería:** 38 → 48 s de scroll. | Con 38 s, la noche 5 pide 106 % de batería (pregunta 6). |

### El director de olas

- **Silencio** hasta los 60 s.
- **Olas de 2 solicitudes**, con 4 a 8 s entre una y otra.
- **Calma de 40 a 60 s, contada desde que se resuelve la ola** (todas sus solicitudes terminadas). Si a la ola siguiente le tocaba más tarde, espera su hora: las olas se reparten parejo entre los 60 s y la ola final.
- **Ola final de 3, todos a la vez**, que llega lo más tarde posible para que se alcance a responder antes de las 06:00: `noche − tiempo para responder − 2 × 8 s − 10 s` (entre las 04:29 y las 04:59). En las noches 2 a 5, una visita de la criatura llega en la ola final.
- **Una ola que ya no cabe antes de la final** (empezaría a menos de 40 s de ella) se salta, junto con las que siguen. Si la final llega con una ola sin resolver, empieza igual.
- **Solicitudes por noche:** 7, 7, 9, 9 y 11 (aproximado: depende de cuántas olas caben). **Simultáneas:** 3 en todas las noches, porque la final necesita a los 3 amigos.
- **Dónde va cada cosa:**
  - en las olas: las **interferencias** (los sobrantes, hacia el final), los **accidentes** (solo en las olas comunes, los sobrantes hacia el comienzo) y **la Mano** (solo en las olas comunes, los sobrantes hacia el final);
  - en las calmas: los **videos** (si una calma es la última, suelta todos los que falten) y los **screamers** (también la criatura, salvo la visita de la ola final).
- Se conserva: un amigo herido atrasa 10 s lo que falta; nunca empieza una solicitud que no alcanza a terminar antes de las 06:00, y con "Temporizadores ×1,5" el tiempo de una solicitud no pasa de las 06:00.

### La Mano

- **Llega** 1, 1, 2, 2 y 3 veces en las noches 1 a 5, y la noche 0 la enseña (pregunta 5). Asoma por el borde derecho hacia un dial al azar: Connection, Sanity o Trust, los 3 por igual (pregunta 4).
- **Cómo se mueve:** tarda 12 s en llegar al dial, a tirones de 0,5 a 0,7 s. En cada tirón cambia de cuadro (0, 1, 2, 0…), avanza a su posición siguiente (siempre entera) y tiembla 1 o 2 px durante 0,1 s. Agarrada, sigue tironeando sin avanzar, con el cuadro 0 (el de la maqueta).
- **Dónde agarra:** el sprite queda en el dial más (−4, +6): (836, 95) en Connection, como en la maqueta.
- **Qué hace:** agarrado, baja su dial 6 puntos por segundo hasta 15, nunca menos, y **se queda hasta que la espanten**. En Connection baja las 3 señales parejo, así que también sube la estática.
- **Dónde se dibuja:** en la pared, delante de los diales y **detrás de los paneles**. El cuaderno abierto la tapa (pregunta 3).
- **Cómo suena:** un crujido sutil de algo que se retuerce en cada tirón, a la derecha, con o sin el cuaderno (Benja lo pidió al responder la pregunta 3).
- **Cómo se espanta:** con el ícono de la linterna en la barra superior del celular abierto (pregunta 2). Cada flash gasta 10 % de la batería, aunque no haya Mano, y la hace desaparecer al instante. Sin batería, la linterna no prende.
- **No coincide con la criatura:** la Mano espera si la criatura está cerca, y la criatura no se arma mientras la Mano está en la pared.

### Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **"Jugar bien" para la prueba de equilibrio:** 12 s de atención por solicitud y 2 preguntas (10 s del temporizador); cierra las cortinas a los 3 s de llegar la criatura y la revisa 2 veces; espanta la Mano antes de que agarre; nunca pierde un video ni se equivoca. | Es un jugador que ya conoce las entidades. Las pruebas usan el peor caso de cada valor al azar. |
| El flash también gasta batería sin Mano. | Si no, no habría costo por apretarlo de más. |
| Los videos los envía un amigo al azar, como antes. | No cambia nada que Benja haya pedido. |
| En la noche 0, la Mano llega con el celular abierto, después de la criatura, y la noche termina al cerrar el celular después del flash. | Es el paso que Benja eligió (pregunta 5). |
| El "−1 s" del señuelo aparece junto a la frase mientras vibra. | Así se ve qué costó sin agregar otro elemento al chat. |

---

## Archivos

| Archivo | Qué cambia |
| --- | --- |
| `scripts/data/trait_data.gd` | `label_key`, `variant_keys` y `text_keys()` |
| `scripts/data/night_data.gd` | `place_chance`, `finale_size` y `hand_visits` |
| `scripts/data/balance_data.gd` | Valores nuevos y quitados (ver cada tarea) |
| `scripts/data/content_catalog.gd` | `predicament_keys` |
| `scripts/core/friend_request.gd` | Lo que le pasa, si dice el lugar, la forma de cada característica y el costo del señuelo |
| `scripts/core/request_generator.gd` | Sortea el lugar y las formas |
| `scripts/core/message_builder.gd` | El mensaje inicial nuevo y las formas de las características |
| `scripts/core/notebook_page.gd` | El nombre de la característica sale de `label_key` |
| `scripts/core/content_validator.gd` | Lo que le pasa, los nombres y las variantes |
| `scripts/core/night_state.gd` | Trust sin recuperación, el video perdido, el flash y la Mano |
| `scripts/core/video_schedule.gd` | `release()`, `potential()` e `is_short()` |
| `scripts/core/interference_schedule.gd` | `add()` |
| `scripts/core/pacing_director.gd` | Se reescribe: olas, calmas y ola final |
| `scripts/core/hand_visit.gd` | **Nuevo:** una visita de la Mano |
| `scripts/core/tutorial_guide.gd` | El paso de la Mano |
| `scripts/desk/request_manager.gd` | Conecta el director y avisa que faltan videos |
| `scripts/desk/screamer_manager.gd` | La criatura al azar y sin cruzarse con la Mano |
| `scripts/desk/hand_manager.gd` | **Nuevo:** la Mano en el escritorio |
| `scripts/desk/desk.gd` y `scenes/desk/desk.tscn` | La Mano, el flash, los videos en rojo y el tutorial |
| `scripts/ui/phone_view.gd` y `scripts/ui/phone_icons.gd` | La linterna |
| `scripts/ui/chat_panel.gd` y `scripts/ui/chat_message_view.gd` | El "−1 s" |
| `tools/make_sounds.py` | `hand_creak.wav` y `phone_flash.wav` |
| `data/*.tres` y `data/text/*.csv` | Valores y textos nuevos |
| `test/balance_model.gd` | **Nuevo:** el modelo de "jugar bien" para la prueba de equilibrio |
| `test/dump_waves.gd` y `tools/plot_waves.py` | **Nuevos:** el dibujo de la curva de olas |
| `test/capture_plan91.gd` | **Nuevo:** las capturas de este plan |

---

## Tareas

### Tarea 1: El mensaje inicial dice qué le pasa y, a veces, el lugar

**Archivos:** `night_data.gd`, `content_catalog.gd`, `friend_request.gd`, `request_generator.gd`, `message_builder.gd`, `content_validator.gd`, `data/catalog.tres`, `data/nights/night_0..5.tres`, `data/text/messages.csv`, `test/content_fixtures.gd`, `test/test_request_generator.gd`, `test/test_message_builder.gd`, `test/test_validator_catalog.gd`, `test/test_validator_texts.gd` y `test/test_balance.gd`.

- `NightData.place_chance: float` (0 a 1, grupo Solicitudes): probabilidad de que el mensaje inicial diga el lugar.
- `ContentCatalog.predicament_keys: Array[String]`: lo que le pasa al amigo (claves de `messages.csv`).
- `FriendRequest.predicament_key: String` y `says_place: bool`.
- `RequestGenerator.build()` sortea siempre los dos valores, para que la secuencia de una semilla no dependa de las probabilidades. En el tutorial, `says_place` es siempre verdadero.
- `MessageBuilder.first_message()` arma: saludo, lo que le pasa, el lugar si `says_place` y la pista.
- `ContentValidator`: el catálogo necesita frases de lo que le pasa, y sus claves tienen que existir.
- Textos (`messages.csv`): `PREDICAMENT_1` a `PREDICAMENT_8`.
- Valores: `place_chance` = 1, 0,6, 0,55, 0,5, 0,45 y 0,4 (noches 0 a 5).

- [ ] **Paso 1:** pruebas que fallan:
  - `test_request_generator.gd`: `test_el_lugar_segun_la_probabilidad_de_la_noche` (con 0 nunca, con 1 siempre), `test_siempre_dice_lo_que_le_pasa` y `test_en_el_tutorial_siempre_dice_el_lugar`;
  - `test_message_builder.gd`: `test_el_mensaje_inicial_sin_lugar` y el orden en `test_el_mensaje_inicial...`;
  - `test_validator_catalog.gd`: `test_sin_frases_de_lo_que_le_pasa`;
  - `test_balance.gd`: los valores de `place_chance`.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar y escribir los 8 textos.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El mensaje inicial dice qué le pasa al amigo y, a veces, el lugar".

### Tarea 2: Las características se dicen con otras palabras

**Archivos:** `trait_data.gd`, `friend_request.gd`, `request_generator.gd`, `message_builder.gd`, `notebook_page.gd`, `content_validator.gd`, los 7 `data/entities/*.tres`, `messages.csv`, `notebook.csv`, `content_fixtures.gd` y las pruebas del generador, el constructor de mensajes, la página del cuaderno y el validador.

- `TraitData.label_key: String` (el nombre en el cuaderno, en `notebook.csv`) y `variant_keys: Array[String]` (las otras formas, en `messages.csv`). `text_keys()` devuelve `[text_key] + variant_keys`.
- `FriendRequest.trait_forms: Dictionary` (id → clave de la forma elegida) y `text_key_for(clue: TraitData) -> String` (la forma elegida, o `text_key` si es un señuelo).
- `RequestGenerator.build()` elige una forma al azar para cada una de las 2 características. La pista usa esa misma forma.
- `MessageBuilder` usa `request.text_key_for()` en la pista y en las respuestas.
- `NotebookPage.trait_label()` usa `label_key`. Si está vacío, usa la frase entre asteriscos, como antes.
- `ContentValidator`:
  - cada característica tiene `label_key` y entre 2 y 4 variantes;
  - cada variante tiene exactamente una frase entre asteriscos;
  - una característica compartida tiene el mismo nombre y las mismas variantes en sus 2 entidades;
  - las claves existen.
- **Textos:** 18 nombres `TRAIT_*_LABEL` en `notebook.csv` (la frase de hoy) y de 2 a 4 variantes por característica, `TRAIT_*_2` a `TRAIT_*_5`, en `messages.csv`.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_request_generator.gd`: `test_cada_caracteristica_con_una_de_sus_formas` y `test_la_pista_usa_la_misma_forma`;
  - `test_message_builder.gd`: `test_la_respuesta_usa_la_forma_de_la_solicitud`;
  - `test_notebook_page.gd`: `test_el_nombre_de_la_caracteristica_es_su_etiqueta`;
  - `test_validator_entity.gd`: `test_variantes_de_las_caracteristicas` (sin nombre, con 1 variante, con 5) y `test_las_compartidas_tienen_las_mismas_variantes`;
  - `test_validator_texts.gd`: `test_cada_variante_con_una_frase_marcada`.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar, escribir los textos y llenar los 7 `.tres`.
- [ ] **Paso 4:** correr todas las pruebas: OK. `test_catalog.gd` revisa el contenido real.
- [ ] **Paso 5:** commit "Las características se dicen con otras palabras; el cuaderno muestra su nombre".

### Tarea 3: Los señuelos cuestan 1 s

**Archivos:** `balance_data.gd`, `balance.tres`, `friend_request.gd`, `request_generator.gd`, `chat_panel.gd`, `chat_message_view.gd`, `ui.csv` y las pruebas de la solicitud, el panel y el equilibrio.

- `BalanceData.decoy_cost := 1.0` (grupo Identificación). El generador lo copia a `FriendRequest.decoy_cost`.
- `FriendRequest.click_clue()`: la primera vez que un señuelo se pone rojo, descuenta `decoy_cost` de `time_left` (sin bajar de 0) y lo suma a `open_seconds`. Clickearlo de nuevo no cuesta. También cuesta en el tutorial, donde solo lo que hace el jugador quita tiempo.
- `ChatMessageView.shake(clue_id, penalty := "")`: mientras vibra, la frase lleva el texto en rojo detrás. El panel pasa `CHAT_DECOY_COST` ("−{seconds} s") solo si esta vez costó.
- `TUTORIAL_MARK`: suma que un señuelo quita 1 s.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_friend_request.gd`: `test_un_senuelo_cuesta_1_s_la_primera_vez`;
  - `test_chat_panel.gd`: `test_el_senuelo_muestra_lo_que_costo`;
  - `test_balance.gd`: el valor.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Clickear un señuelo cuesta 1 s".

### Tarea 4: Trust no se recupera y un video perdido lo baja

**Archivos:** `balance_data.gd`, `balance.tres`, `night_state.gd`, `ui.csv` (`TUTORIAL_DIALS`) y las pruebas de la noche y del equilibrio.

- Se quitan `trust_recovery_interval` y `trust_recovery_delay`. `NightState._advance_trust()` solo baja.
- `BalanceData.lost_video_trust := -10.0` (grupo Consecuencias). `NightState.advance()` lo aplica por cada video que se pierde, salvo en el tutorial.
- `wrong_trust` pasa de −10 a −15.
- `TUTORIAL_DIALS` dice que Trust no se recupera en la noche y que también baja si se pierde un video.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_night_state.gd`: `test_trust_no_se_recupera` (reemplaza a la prueba de la recuperación) y `test_un_video_perdido_baja_trust`;
  - `test_balance.gd`: los valores nuevos y los que se quitan.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Trust no se recupera en la noche, y un video perdido lo baja".

### Tarea 5: El aviso de que los videos ya no alcanzan

**Archivos:** `video_schedule.gd`, `request_manager.gd`, `desk.gd`, `ui.csv` y las pruebas de los videos, el manager y la escena.

- `VideoSchedule.potential() -> int`: recibidos, más los que esperan su descarga, más los que faltan llegar. `is_short() -> bool`: `potential() < quota`.
- `RequestManager.report()`: después de "Se perdió el video de León", si `is_short()`, avisa en rojo en ese mismo chat (`CHAT_VIDEOS_SHORT`). Es una vez por cada video que se pierde.
- El PC: con `is_short()`, el texto de los videos va en rojo y dice `PC_VIDEOS_SHORT` ("Videos: 1 de 3 (faltan)"). Vuelve a la normalidad si la cuota vuelve a alcanzar (por ejemplo, con el video extra de la acción de mayor riesgo).

- [ ] **Paso 1:** pruebas que fallan:
  - `test_video_schedule.gd`: `test_cuantos_videos_pueden_llegar`;
  - `test_request_manager.gd`: `test_avisa_cuando_los_videos_no_alcanzan`;
  - `test_desk_scene.gd`: `test_los_videos_que_faltan_en_rojo`.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Aviso cuando los videos ya no alcanzan la cuota".

### Tarea 6: El director de olas (lógica pura)

**Archivos:** `pacing_director.gd` (se reescribe), `night_data.gd`, `balance_data.gd`, `balance.tres`, `test/test_pacing_director.gd` (se reescribe) y `test_balance.gd`.

`PacingDirector.new(night, balance, rng)`:

- **Plan:**
  - olas comunes: `ceil((requests_total − finale_size) / wave_size)`;
  - `finale_at = night_seconds − base_decision_time − (finale_size − 1) × wave_spacing.y − hurt_respite`;
  - la ola común `k` está planeada para `first_wave_at + k × (finale_at − first_wave_at) / olas comunes`;
  - reparte entre las olas las interferencias, los accidentes y las visitas de la Mano, y entre las calmas los screamers.
- **`advance(now, active) -> Beat`:**
  - empieza las olas y las calmas;
  - `Beat` trae `wave_started` (índice o −1), `finale_started`, `calm_started`, y las horas de las interferencias (`interferences`) y de los videos (`videos`) que tocan.
  - Las horas de los accidentes, los screamers y la Mano las encola el director mismo: `incident_times`, `scare_times` con `scare_creature` y `hand_times`.
- **Solicitudes:**
  - `request_due(now, decision_seconds) -> bool`: hay solicitudes pendientes en la ola, ya es hora y alcanzan a terminar antes de las 06:00 (si no, la ola se corta);
  - `request_started(now)`: la siguiente de la ola, entre 4 y 8 s después.
- **`friend_hurt()`:** atrasa `hurt_respite` la próxima solicitud y la próxima ola.
- **Se mantienen, con las colas nuevas:** `scare_due`, `next_is_jumpscare`, `scare_started`, `incident_due`, `incident_started`, `scripted_scare_due` y `scripted_scare_started`. Se suman `hand_due(now)` y `hand_started()`.
- **`NightData`:** `finale_size := 3` y `hand_visits := 0` (grupos Solicitudes y Screamers).
- **`BalanceData`:**
  - suma `first_wave_at := 60.0`, `wave_spacing := Vector2(4, 8)` y `wave_calm := Vector2(40, 60)`;
  - quita `wave_respite`, `wave_tightening`, `request_min_gap` y `first_scare_after`;
  - `first_request_delay` queda solo para el tutorial.

- [ ] **Paso 1:** pruebas que fallan, en `test_pacing_director.gd`:
  - `test_el_primer_minuto_es_de_silencio`;
  - `test_las_solicitudes_de_una_ola_llegan_juntas`;
  - `test_la_calma_empieza_cuando_se_resuelve_la_ola`;
  - `test_la_ola_final_es_de_3_y_llega_al_final`;
  - `test_una_ola_que_no_cabe_se_salta`;
  - `test_nunca_empieza_una_que_no_alcanza`;
  - `test_un_amigo_herido_atrasa`;
  - `test_interferencias_en_las_olas`;
  - `test_videos_en_las_calmas`;
  - `test_la_ultima_calma_suelta_todos_los_videos`;
  - `test_accidentes_en_las_olas_comunes`;
  - `test_la_mano_en_las_olas_comunes`;
  - `test_screamers_en_las_calmas`;
  - `test_la_criatura_llega_en_la_ola_final`;
  - `test_el_susto_guionado_espera_sin_solicitudes`.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr `test_pacing_director.gd`: OK.
- [ ] **Paso 5:** sin commit: la Tarea 7 conecta el director y deja todo en verde.

### Tarea 7: El director en la noche

**Archivos:** `request_manager.gd`, `night_state.gd`, `interference_schedule.gd`, `video_schedule.gd`, `screamer_manager.gd`, `data/nights/night_1..5.tres`, `capture_screamers.gd` y las pruebas del manager, los screamers, las interferencias, los videos y el equilibrio.

- `InterferenceSchedule.new()` empieza vacía, y `add(friend_index, time)` la suma en orden.
- `VideoSchedule`:
  - ya no programa envíos al empezar: `unreleased = quota`;
  - `release(friend_index, time)` agrega un envío y descuenta de `unreleased`;
  - `potential()` cuenta `unreleased`;
  - en el tutorial, `unreleased = 0`.
- `RequestManager.advance()`:
  - en las noches comunes, `director.advance(_elapsed, active_count())`;
  - cada interferencia del `Beat` va a un amigo al azar, y cada video, a un amigo al azar.
- `RequestManager.start_request()`: con "Temporizadores ×1,5", el tiempo no pasa de las 06:00. `request_due` recibe el tiempo sin alargar.
- `ScreamerManager` usa la nueva cola de screamers (`scare_creature`).
- **Valores de las noches:**
  - solicitudes 7, 7, 9, 9 y 11;
  - simultáneas 3;
  - por ola 2;
  - ola final 3;
  - tiempo 80, 65, 55, 50 y 45;
  - Mano 1, 1, 2, 2 y 3;
  - en la noche 0, la Mano en 0: la enseña su guía (Tarea 11).

- [ ] **Paso 1:** pruebas que fallan:
  - `test_interference_schedule.gd`: `test_se_agregan_en_orden`;
  - `test_video_schedule.gd`: `test_los_videos_se_sueltan_cuando_toca`;
  - `test_request_manager.gd`: reescribir `test_las_solicitudes_llegan_solas`, `test_no_pasa_de_las_simultaneas`, `test_un_amigo_herido_atrasa_las_solicitudes` y `test_llegan_a_su_hora_si_hay_espacio`, y sumar `test_las_olas_traen_interferencias_y_las_calmas_videos` y `test_con_temporizadores_lentos_no_pasa_de_las_06`;
  - `test_screamer_manager.gd`: el ayudante `_scare_now` con la cola nueva;
  - `test_balance.gd`: los valores de las noches.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Olas de verdad: el director reparte olas, calmas y una ola final".

### Tarea 8: La criatura se queda un tiempo al azar

**Archivos:** `balance_data.gd`, `balance.tres`, `screamer_manager.gd`, `ui.csv` (`TUTORIAL_OPEN_CURTAINS`) y las pruebas de los screamers y del equilibrio.

- `creature_seconds` pasa a `creature_stay := Vector2(15, 40)`. `_creature_arrives()` sortea la estadía con el `rng` de la noche.
- `TUTORIAL_OPEN_CURTAINS` dice que cada vez se queda un rato distinto.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_screamer_manager.gd`: `test_la_criatura_se_queda_un_tiempo_al_azar` (entre 15 y 40 s, y no siempre el mismo);
  - `test_balance.gd`: el valor.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La criatura se queda un tiempo al azar".

### Tarea 9: La Mano (lógica pura)

**Archivos:** `scripts/core/hand_visit.gd` (nuevo), `night_state.gd`, `balance_data.gd`, `balance.tres`, `test/test_hand_visit.gd` (nuevo), `test_night_state.gd` y `test_balance.gd`.

- `HandVisit.new(dial: int, balance, rng)`:
  - `steps`: los tirones del camino, `round(hand_approach_seconds / promedio de hand_step_seconds)`;
  - `advance(delta) -> bool`: devuelve true si hubo un tirón;
  - `frame`, `step`, `is_grabbing()` y `position(dial_position: Vector2) -> Vector2i`: desde `x = 1280` hasta el dial más `HAND_GRAB_OFFSET` (−4, +6), en posiciones enteras.
- `NightState`:
  - `enum Dial { CONNECTION, SANITY, TRUST }`;
  - `flash() -> bool` gasta `flash_cost` (%) si hay batería;
  - `hand_pull(dial, delta)` baja ese dial `hand_drain` por segundo sin bajar de `hand_floor` (en Connection, las 3 señales);
  - `dial_value(dial)`.
- `BalanceData` (grupo "La Mano"): `flash_cost := 10.0`, `hand_approach_seconds := 12.0`, `hand_step_seconds := Vector2(0.5, 0.7)`, `hand_drain := 6.0` y `hand_floor := 15.0`. `phone_battery_seconds` pasa a 48.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_hand_visit.gd`: `test_avanza_a_tirones`, `test_llega_al_dial_en_unos_12_s`, `test_las_posiciones_son_enteras`, `test_los_cuadros_se_alternan` y `test_agarrada_sigue_tironeando_sin_avanzar`;
  - `test_night_state.gd`: `test_el_flash_gasta_bateria`, `test_sin_bateria_no_hay_flash`, `test_la_mano_baja_el_dial_hasta_el_minimo` (los 3 diales) y `test_en_connection_baja_las_3_senales`;
  - `test_balance.gd`: los valores.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La Mano: los tirones, el agarre y el flash (lógica)".

### Tarea 10: Los sonidos de la Mano y del flash

**Archivos:** `tools/make_sounds.py`, `audio/sfx/hand_creak.wav`, `audio/sfx/phone_flash.wav`, `test/test_sounds.gd` y `sonidos_pendiente.md`.

- `hand_creak()`: algo que se retuerce. Un crujido corto y grave de tendones y madera (la fricción de `creak()`, más grave), con 2 o 3 chasquidos de nudillos y un roce húmedo. Dura unos 0,45 s y es sutil (LUFS bajo).
- `phone_flash()`: el obturador de una cámara de celular (2 clics), un zumbido agudo de carga que sube y un golpe de aire. Dura unos 0,5 s.
- Ninguno dice palabras. Los picos quedan bajo −1 dBFS, como los demás.

- [ ] **Paso 1:** sumar los 2 sonidos a la lista de `test_sounds.gd` (que existan y carguen).
- [ ] **Paso 2:** correr la prueba y ver que falla.
- [ ] **Paso 3:** escribir las recetas, correr `/usr/bin/python3 tools/make_sounds.py` e importar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Sonidos de la Mano y del flash".

### Tarea 11: La Mano en el escritorio y en la noche 0

**Archivos:** `scripts/desk/hand_manager.gd` (nuevo), `desk.tscn`, `desk.gd`, `screamer_manager.gd`, `phone_view.gd`, `phone_icons.gd`, `tutorial_guide.gd`, `ui.csv`, `phone.csv`, `art/positions.md` y las pruebas de la escena, los screamers, el celular y el tutorial.

- **`desk.tscn`:**
  - `WallPlane/Hand` (AnimatedSprite2D con `hand_sprite`, oculta, después de los diales);
  - `Hands` (nodo con `hand_manager.gd`), con `CreakSound` (AudioStreamPlayer2D en x = 1200) y `FlashSound`;
  - `Overlay/Flash` (ColorRect blanco, transparente, sin recibir clics).
- **`HandManager`:**
  - `setup(requests, night, screamers)`;
  - `advance(delta)`: si el director tiene una Mano y no hay criatura ni otra Mano, empieza una visita hacia un dial al azar. Avanza la visita: en cada tirón, el cuadro, la posición con temblor de 1 o 2 px por 0,1 s y el crujido. Agarrada, `state.hand_pull`;
  - `start_visit(dial)`, `is_present()` y `flash()`: gasta batería, destella y, si hay Mano, la hace desaparecer;
  - señales `hand_appeared` y `hand_scared`.
- **`ScreamerManager`:** no arma la criatura mientras hay una Mano (`hand_present: Callable`, o la referencia al `HandManager`).
- **`PhoneView`:**
  - la linterna (`PhoneIcons.FLASHLIGHT`) en la barra superior, en (124, 21), con una zona de clic de 24×20;
  - sin batería se ve apagada;
  - señal `flash_pressed`;
  - tooltip `PHONE_FLASH`.
- **El destello:** el ColorRect blanco sube a 0,8 de opacidad y baja en 0,3 s; con "Reducir destellos", a 0,3.
- **`TutorialGuide`:**
  - nuevo estado del celular `HAND`: después de abrirlo, la Mano llega, y el aviso `TUTORIAL_HAND` sigue hasta el flash;
  - `hand_scared()` pasa a `OPEN_AFTER_HAND`, y cerrar el celular termina el tutorial;
  - cerrar el celular antes del flash no lo termina;
  - el escritorio larga la Mano del tutorial cuando el celular se abre y la criatura no está.
- **`art/positions.md`:** la fila de `hand_sprite`.

- [ ] **Paso 1:** pruebas que fallan:
  - `test_desk_scene.gd`: `test_la_mano_esta_escondida`;
  - `test_hand_manager.gd` (nuevo): `test_llega_cuando_el_director_la_pide`, `test_no_llega_con_la_criatura_cerca`, `test_agarrada_baja_el_dial`, `test_el_flash_la_espanta_y_gasta_bateria`, `test_suena_en_cada_tiron`, `test_queda_detras_de_los_paneles` y `test_reducir_destellos`;
  - `test_screamer_manager.gd`: `test_con_la_mano_no_llega_la_criatura`;
  - `test_phone_view.gd`: `test_la_linterna_avisa` y `test_sin_bateria_la_linterna_no_prende`;
  - `test_tutorial_guide.gd`: `test_la_mano_despues_del_celular` y `test_cerrar_el_celular_antes_del_flash_no_termina`.
- [ ] **Paso 2:** correr las pruebas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La Mano en el escritorio, la linterna del celular y su paso en la noche 0".

### Tarea 12: La prueba de equilibrio: cada noche se puede ganar

**Archivos:** `test/balance_model.gd` (nuevo), `test/test_balance.gd`, `test/dump_waves.gd` (nuevo) y `tools/plot_waves.py` (nuevo).

`balance_model.gd` es el modelo de "jugar bien" (ver los supuestos de arriba):

- `battery_needed(night, balance) -> float`, en %, con el peor caso:
  - lo que Sanity baja con el tiempo;
  - los screamers;
  - cada visita de la criatura: 3 s con la cortina abierta, 40 s cerrada y 2 revisiones de 1 s;
  - lo que hay que reponer para terminar con 10 o más;
  - un flash por cada visita de la Mano.
- `simulate(night, balance, seed) -> Dictionary`:
  - corre el `PacingDirector` real con un jugador que atiende de a una tarea, la que vence primero;
  - cada solicitud le toma 12 s y cuesta 2 preguntas; cada accidente, 4 s; cada Mano, 4 s;
  - devuelve las solicitudes con su llegada, su respuesta y su plazo, Trust al final y la curva (cuántas tareas hay abiertas cada segundo).

Pruebas en `test_balance.gd`:

- `test_la_bateria_alcanza_en_cada_noche`: `battery_needed` ≤ 100 en las noches 1 a 5;
- `test_jugando_bien_nada_vence` y `test_jugando_bien_trust_queda_sobre_75`: con 20 semillas por noche;
- `test_trust_amenaza`: 7 respuestas incorrectas bastan para perder cualquier noche.

Para el dibujo, `dump_waves.gd` escribe la simulación de una noche en JSON, y `plot_waves.py` dibuja la curva con matplotlib.

- [ ] **Paso 1:** escribir el modelo y las pruebas.
- [ ] **Paso 2:** correrlas. Si alguna falla, ajustar los valores (no el modelo) y anotarlo en este plan.
- [ ] **Paso 3:** correr todas las pruebas: OK.
- [ ] **Paso 4:** dibujar la curva de la noche 3 y la 5 y revisarlas.
- [ ] **Paso 5:** commit "Prueba de equilibrio: cada noche se puede ganar, y la curva de olas".

### Tarea 13: Capturas

**Archivos:** `test/capture_plan91.gd` (nuevo).

Capturas:

1. la Mano a mitad de camino;
2. la Mano sobre el dial de Sanity;
3. el flash, con el celular abierto;
4. un mensaje inicial sin lugar;
5. una característica dicha con otras palabras, marcada, con su nombre en el cuaderno abierto;
6. el aviso de videos, en el chat y en el PC.

La curva de olas sale de la Tarea 12.

- [ ] **Paso 1:** escribir el script y correrlo con ventana.
- [ ] **Paso 2:** revisar cada captura y corregir lo que se vea mal.
- [ ] **Paso 3:** commit "Capturas del Plan 9.1".

### Tarea 14: Documentos

**Archivos:**

- `CLAUDE.md`;
- `spook_dial_design.md`: §5, §8.1 a §8.3, §10.2 a §10.4 y §11;
- `docs/02_bucle_central.md`: §2, §3, §6, §9 y §10;
- `sonidos_pendiente.md`;
- `arte_pendiente.md`;
- `docs/04_instrucciones_godot.md`: sección I y una sección nueva para probar;
- `resumen.md`;
- `docs/00_log.md`.

- [ ] **Paso 1:** pasar las decisiones del 11-nov, con sus valores, a `CLAUDE.md` y al diseño v2.
- [ ] **Paso 2:** actualizar `docs/02`, `sonidos_pendiente.md`, `arte_pendiente.md` y `docs/04` (una sección nueva de unos 20 minutos para probar todo esto, y la sección I, donde Trust ya no sube).
- [ ] **Paso 3:** escribir la entrada de `resumen.md` (Sesión 21f) con sus 4 categorías, y cerrar S21f en `docs/00_log.md`. Después sigue S21b.
- [ ] **Paso 4:** commit "Documentos de la sesión S21f: ajustes de mecánicas y la Mano".

---

## Fuera de este plan

- Las demás propuestas de `docs/22` (A6, A7 y las secciones B a E): para otro momento (regla 6).
- Más cuadros de la Mano o una animación de retirada: si Benja los dibuja (`arte_pendiente.md`).
- Que la Mano tenga un aviso propio en las noches comunes: la noche 0 la enseña.
