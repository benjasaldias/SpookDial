# Plan 9.6: Extremo — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** una tercera dificultad, **Extremo** (pedido de Benja, 12 de noviembre, sesión S21k). Es más exigente que Difícil, pero se puede ganar de verdad:

1. **Olas más intensas:** más consultas, calmas cortas y menos tiempo para responder que Difícil en cada noche.
2. **Más obstrucciones:** más interferencias, Manos, visitas de la criatura, screamers, accidentes y señuelos; sin pista, y Audio Sync más rápido.
3. **Trust por error ×1,5:** incorrecta −22,5, mayor riesgo −30, sin respuesta −22,5 más y video perdido −15. Tardar en contestar no cambia.
4. **Un amigo al azar empieza cada noche con 1 de vida**, y su chat lo avisa.
5. Se identifica leyendo, como en Difícil, empieza en la noche 1 y **se desbloquea al terminar Difícil**.

**Cómo se asegura que se pueda ganar:**

- **Difícil está calibrado con la prueba de Benja:** sus noches finales son difíciles pero ganables, y en el modelo de "jugar bien" la noche 5 queda justo en el límite con 14 s por consulta.
- **A Extremo solo llega quien terminó Difícil:** un experto, que conoce las 7 criaturas de memoria. **Extremo se calibra con un experto que resuelve cada consulta en 11 s.** Con 11 s, toda noche de Extremo se gana sin perder nada; con 12 s, las noches 4 y 5 ya pierden tareas (están en el límite del experto); con 14 s, solo la noche 1 se gana.
- **La holgura (nueva prueba, para los 3 modos):** el tiempo libre de la noche, sin tareas abiertas desde la primera ola, tiene que cubrir lo que piden sincronizar la señal y reponer Sanity con el celular. El modelo de "jugar bien" no cuenta las sincronizaciones como tareas: así se comprueba que caben. Con la atención de cada modo, toda noche tiene holgura de 1 o más. En Extremo, las noches 4 y 5 quedan cerca de 1; Difícil 5 tiene 1,24.

**Arquitectura:**

- **`DifficultyData`** suma 3 campos: `error_trust_scale` (1 en Normal y Difícil, 1,5 en Extremo), `wounded_friends` (cuántos amigos empiezan heridos: 0 o 1) y `wounded_health` (con cuánta vida: 1). `balance_for(base)` entrega el equilibrio con los castigos por error escalados.
- **`NightData.wave_calm`**: la calma entre olas de esa noche. Con (0, 0), la de `balance.tres` (40 a 60 s). Extremo usa 20 a 30 s.
- **`RequestManager`** juega con el equilibrio de la dificultad (para la noche y las consecuencias) y, al empezar, hiere al amigo al azar y lo avisa en su chat.
- **`test/balance_model.gd`**: la atención de cada modo (`attention_for`: 12, 14 y 11 s) y la holgura (`free_time_ratio`).
- **Los datos:** `data/difficulty/extreme.tres` y `data/nights/extreme/night_1.tres` a `night_5.tres`.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`).

**Cómo se ejecuta:** se escribe y se ejecuta en la misma sesión (S21k), con un commit por tarea que Benja autorizó al empezar. **El código exacto de cada tarea está en su commit.**

**Punto de partida:** 748 pruebas OK.

---

## Decisiones de Benja (S21k, 12 de noviembre)

| Decisión | Detalle |
| --- | --- |
| **Una dificultad "Extremo"** | Más obstrucciones, olas más intensas, más Trust perdido por error y, quizás, un amigo al azar que empieza con 1 de vida. Tiene que ser difícil, pero ganable de verdad. |
| **Se desbloquea al terminar Difícil** | Normal → Difícil → Extremo, con candado mientras tanto. |
| **Trust por error ×1,5** | Incorrecta, mayor riesgo, sin respuesta y video perdido. |
| **Difícil no cambia** | Benja probó Difícil: sus noches finales son difíciles pero no imposibles. Es la referencia para calibrar Extremo. |
| **Más exigente que Difícil** | Extremo deja menos tiempo libre que Difícil y da menos tiempo para responder en cada noche. |
| **Olas de 2** | Las olas comunes son de 2, como en Difícil, y la final de 3: con menos tiempo para responder, 3 a la vez no se alcanzan a atender. |
| **Commits** | Benja autorizó todos los de la sesión, en `main` y sin push. |

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **El experto resuelve una consulta en 11 s** (3 menos que en Difícil). | A Extremo solo llega quien ganó Difícil y conoce las criaturas de memoria: lee el mensaje, hace 2 preguntas, abre la página y responde. Si al probar se siente imposible, la noche 5 es la primera que se afloja. |
| **El amigo herido es uno al azar cada noche,** con 1 de 3 de vida, y su chat lo avisa en rojo al empezar ("Agustín empieza herido: 1/3. No te equivoques con él."). | Benja lo propuso ("tal vez"). Sin el aviso, la primera pista sería perderlo. Los accidentes no le tocan, porque nunca matan a un amigo. |
| **Las calmas de Extremo duran de 20 a 30 s** (en Difícil, de 40 a 60). | Con 40 a 60 s no caben más de 3 o 4 olas antes de la final, y el director se salta las que sobran. Es lo que hace las olas más seguidas. |
| **Lo demás no cambia en Extremo:** la batería, la Mano, la criatura, la estática, Audio Sync (salvo su velocidad) y "Temporizadores ×1,5". | Lo pidió Benja: más cantidad, no reglas nuevas. |
| **La holgura cuenta las sincronizaciones así:** cada amigo pierde señal a su ritmo promedio y −40 por interferencia; cada sincronización recupera 70 (se sincroniza bajo 30) y dura sus rondas más 2 s. | Es una cuenta simple que deja a Difícil 5 en 1,24, que Benja probó. |

---

## Tareas

### Tarea 1: La atención de cada modo y la holgura

**Archivos:** `test/balance_model.gd`, `test/test_balance.gd` y `test/dump_waves.gd`.

- `simulate(night, balance, seed, attention)` recibe los segundos por consulta.
- `attention_for(difficulty)`: 12 en Normal, 14 en Difícil y 11 en Extremo (`EXPERT_ATTENTION`).
- `sync_seconds(night, balance)`: lo que dura sincronizar a un amigo (sus rondas de Audio Sync, más 2 s).
- `free_time_ratio(night, balance, attention, seeds)`: el menor tiempo libre desde la primera ola, entre las semillas, dividido por lo que piden las sincronizaciones y el scroll.

- [ ] **Paso 1:** pruebas en `test_balance.gd`:
  - `test_la_atencion_de_cada_modo`;
  - `test_toda_noche_tiene_holgura` (los 3 modos, holgura de 1 o más);
  - `test_dificil_5_es_la_referencia` (su holgura queda entre 1 y 1,5);
  - las que ya corren el modelo, con `attention_for`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La prueba de equilibrio mide la holgura para sincronizar y scrollear".

### Tarea 2: La calma de cada noche

**Archivos:** `scripts/data/night_data.gd`, `scripts/core/pacing_director.gd` y `test/test_pacing_director.gd`.

- `NightData.wave_calm := Vector2.ZERO`: con (0, 0) se usa la de `balance.tres`.
- El director la usa en las calmas y en la regla que salta una ola que ya no cabe antes de la final.

- [ ] **Paso 1:** pruebas: `test_la_noche_puede_traer_su_calma` y `test_sin_calma_propia_se_usa_la_del_equilibrio`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Cada noche puede traer su propia calma entre olas".

### Tarea 3: Los castigos de la dificultad y el amigo herido

**Archivos:** `scripts/data/difficulty_data.gd`, `scripts/desk/request_manager.gd`, `scripts/core/message_builder.gd`, `data/text/ui.csv` y sus pruebas (`test_night_and_catalog.gd` y `test_request_manager.gd`).

- **`DifficultyData`:**
  - `error_trust_scale := 1.0`, `wounded_friends := 0` y `wounded_health := 1`;
  - `balance_for(base)` entrega `base` si la escala es 1, o una copia con `wrong_trust`, `risky_trust`, `no_answer_trust` y `lost_video_trust` multiplicados.
- **`RequestManager`:**
  - `balance` es el de la dificultad: lo usan el estado de la noche y las consecuencias;
  - al empezar una noche que no es el tutorial, hiere a `wounded_friends` amigos distintos al azar (su vida baja a `wounded_health`, y la máxima sigue en 3) y avisa en su chat (`CHAT_WOUNDED_START`, en rojo).

- [ ] **Paso 1:** pruebas:
  - `test_night_and_catalog.gd`: `test_los_castigos_de_la_dificultad`;
  - `test_request_manager.gd`: `test_en_extremo_un_error_cuesta_mas_trust`, `test_un_amigo_empieza_herido`, `test_el_herido_cambia_de_noche_en_noche`, `test_sin_heridos_en_normal` y `test_el_herido_no_tiene_accidentes`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar y reimportar los textos.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Los castigos de la dificultad: Trust por error y un amigo herido".

### Tarea 4: Extremo

**Archivos:** `data/difficulty/extreme.tres`, `data/nights/extreme/night_1.tres` a `night_5.tres`, `data/catalog.tres`, `data/text/ui.csv`, `test/test_catalog.gd` y `test/test_balance.gd`.

| Valor | N1 | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- | --- |
| Consultas | 11 | 13 | 13 | 15 | 15 |
| Segundos para responder | 45 | 42 | 40 | 40 | 38 |
| Calma entre olas | 20 a 30 s | 20 a 30 s | 20 a 30 s | 20 a 30 s | 20 a 30 s |
| Interferencias | 4 | 5 | 6 | 7 | 8 |
| La Mano | 2 | 2 | 2 | 3 | 3 |
| La criatura | 1 | 2 | 2 | 3 | 3 |
| Screamers | 4 | 5 | 5 | 6 | 6 |
| Accidentes | 2 | 2 | 3 | 3 | 4 |
| Señuelos | 3 | 3 | 4 | 4 | 4 |
| Lugar | 40 % | 35 % | 30 % | 25 % | 20 % |
| Audio Sync (golpes por minuto) | 115 | 125 | 135 | 145 | 150 |
| Cuota | 3 | 3 | 4 | 4 | 4 |

Además: olas de 2, la final de 3, 3 a la vez, sin pista, Audio Sync de 8 aplausos, Sanity −1 cada 6 s y las mismas entidades en las mismas noches. La dificultad: `id` `extreme`, empieza en la noche 1, se lee, se desbloquea con Difícil, Trust por error ×1,5 y 1 amigo herido con 1 de vida.

- [ ] **Paso 1:** pruebas:
  - `test_catalog.gd`: `test_extremo` (tercera dificultad, desbloqueada por Difícil, noche 1, se lee, ×1,5 y 1 herido);
  - `test_balance.gd`: `test_valores_de_extremo` (la tabla) y `test_extremo_es_mas_duro_que_dificil` (noche a noche: más consultas, menos tiempo, calma más corta y más obstrucciones; nunca más pista ni más lugar);
  - las pruebas del modelo ya corren en las 3 dificultades.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** los `.tres`, el catálogo y los textos (`DIFFICULTY_EXTREME` y `DIFFICULTY_EXTREME_INFO`).
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "Extremo: más olas, más obstrucciones, castigos más duros y un amigo herido".

### Tarea 5: El menú con 3 dificultades y la revisión

**Archivos:** `test/test_game_state.gd`, `test/capture_plan96.gd` (nuevo) y lo que haga falta corregir.

- `test_dificil_desbloquea_extremo`: ganar la noche 5 de Difícil desbloquea Extremo y lo avisa; Extremo bloqueado dice "Termina Difícil para desbloquearla.".
- **Capturas a 1280×720 y 1920×1080:** la elección con Difícil y Extremo bloqueados, y con los 3 libres; el chat del amigo herido al empezar una noche de Extremo.

- [ ] **Paso 1:** la prueba y verla pasar (el menú y `GameState` ya son genéricos); si falla, corregir.
- [ ] **Paso 2:** sacar las capturas, revisarlas y corregir lo que haga falta.
- [ ] **Paso 3:** correr todas las pruebas: OK. Abrir el juego sin errores nuevos.
- [ ] **Paso 4:** commit "Revisión del menú con Extremo y del amigo herido".

---

## Fuera de este plan

- **Para Benja:**
  - probar Extremo (`docs/04`, W) y decir si la noche 5 se siente lograble;
  - corregir los textos nuevos (`DIFFICULTY_EXTREME`, `DIFFICULTY_EXTREME_INFO` y `CHAT_WOUNDED_START`).
- **Si Extremo se siente imposible:** primero la noche 5 (más tiempo o 13 consultas), después la calma (25 a 35 s).
