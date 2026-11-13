# Plan 9.8: vlog o emergencia — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que el jugador distinga sin dudar cuándo un amigo **graba el vlog** y cuándo **pide ayuda** (feedback de Benja al probar la noche 1 del Plan 9.7, 12 de noviembre), que se alcance a leer la historia y que la alarma suene a alarma, **sin regalar tiempo libre**: la noche queda con el mismo equilibrio que tenía.

**Arquitectura:**

- **El horario** (`NightData.overtime_minutes`, `NightData.length()` y `BalanceData.finale_margin`): una noche con historia dura hasta las 06:30, y la ola final llega lo más tarde posible con 5 s de holgura al final. Todo lo que usaba `night_seconds` como largo de la noche usa el de la noche.
- **La historia en el horario:** `StoryRunner` mide cuánto dura cada momento (`story_needs()`), con las líneas a 15 letras por segundo (mínimo 2 s) y cada decisión con su tiempo completo. `PacingDirector` recibe esas duraciones: la primera ola llega cuando terminó lo de antes, cada calma dura al menos lo que cuenta su historia, y las olas comunes se planean dejando el tiempo de la reunión antes de la final. La espera de la ola (`story_hold`) queda solo de seguro.
- **La noche espera la llamada:** `RequestManager.waiting_for_call` congela la noche (`NightManager` no avanza y cuenta como pausada) hasta que se abre la llamada.
- **El chat:** el modo vlog (sin preguntas ni respuestas y con "● REC") y la emergencia marcada (`ChatMessage.urgent` y la línea `ChatMessage.divider`), el separador de no leídos, el aviso suave y el punto de no leído en las entradas.
- **Los sonidos:** 3 alarmas nuevas, el aviso suave y el golpe de la ola (`tools/make_sounds.py`); cada entrada pita con su propio ritmo (`ChatEntry`), y la música cambia entre la calma y las olas (`MusicPlayer`, con las pistas de Benja).

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`).

**Cómo se ejecuta:** se escribe y se ejecuta en la misma sesión (S21l, segunda parte), con un commit por tarea (Benja autorizó todos los de la sesión). **El código exacto de cada tarea está en su commit.**

**Punto de partida:** 821 pruebas OK (commit `af84e5f`).

---

## El feedback de Benja (12 de noviembre, después de probar la noche 1)

1. No se distingue cuándo un amigo pide ayuda y cuándo solo documenta: no se nota la separación entre la ola y la calma. Ideas de Benja: ocultar las preguntas de Matías en la calma, y música tensa en las olas y una más eerie en las calmas.
2. Que el aviso de un chat que no es de alarma se note más, con un sonido.
3. La alarma no suena alarmante: que sean sonidos distintos (sin el acorde), que empiecen en el momento en que empieza la alarma y que sigan el parpadeo de la luz de la entrada, porque hoy suenan todas coordinadas y se siente raro.
4. Un separador de mensajes no leídos, para saber dónde empezar.
5. Que la noche no empiece hasta abrir la llamada, con el tiempo congelado, para leer la historia en vivo.
6. En la calma, los mensajes pasan muy rápido.

## Decisiones de Benja (preguntas en la sesión)

| Pregunta | Decisión |
| --- | --- |
| El chat sin nada que jugar | **Modo vlog con REC:** sin PREGUNTAR ni RESPONDER y con "● REC · LEÓN ESTÁ GRABANDO" abajo. Cuando llega algo, vuelven los bloques y una línea roja "⚠ LEÓN PIDE AYUDA" separa la emergencia del vlog. |
| Los mensajes | **Se marca la emergencia:** el mensaje inicial, las respuestas a las preguntas, el accidente y la pregunta de una decisión llevan "⚠" antes del nombre y la barra izquierda en rojo. El vlog queda como hoy. |
| La música | **La consigue Benja** (2 pistas: calma y ola). Claude deja listo el cambio entre las dos. |
| El momento en que empieza una ola | **Un golpe de sonido** corto y tenso (lo sintetiza Claude). |
| El ritmo de la alarma | **La luz parpadea 2 veces por segundo** (hoy 5) y cada parpadeo trae su pitido; cada entrada empieza a pitar cuando entra en alerta. |
| El sonido de la alarma | **3 alarmas electrónicas:** León un doble bip agudo, Gonzalo un zumbido grave y Agustín un trino rápido. |
| El aviso suave | **Un "pop" de mensaje** (a lo más uno cada 2 s) y **un "•" en la entrada del PC** hasta leerlo. Nunca parpadea. |
| La velocidad del vlog | **El doble de lento,** pero sin regalar tiempo (propuesta de Benja, completada por Claude y confirmada): las noches con historia terminan a las 06:30; el director pone la historia en el horario; la final empieza lo más tarde posible con 5 s de holgura al final (al ejecutar: solo en las noches con historia); la espera de la ola queda solo de seguro; y la noche se equilibra para quedar como hoy. |
| El diseño | Aprobado completo, para hacerlo en esta sesión. |
| Los 5 s de holgura de la final | **Solo en las noches con historia** (pedido al ejecutar la Tarea 1): con 5 s en todas, Difícil 5 se ponía un pelo más difícil (una ola que antes se saltaba ahora cabía). Las noches sin historia siguen con 10 s. |

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **Una línea dura lo que se tarda en leerla, a 15 letras por segundo** (mínimo 2 s; antes, 60 letras por segundo más 1,2 s). Una de 80 letras: 5,3 s. | Es el doble de lento (decisión de Benja), con una velocidad de lectura cómoda. |
| **Un momento "antes de una ola" empieza lo que dura antes de ella** (más 2 s), y nunca menos que su `lead_seconds`. | Así nunca hace esperar a la ola, aunque se alargue. |
| **Una decisión cuenta su tiempo completo** (la pregunta, 15 s y la respuesta más larga) al planear la calma. | Jugando lento tampoco hace esperar a la final; jugando rápido queda tiempo libre, que el equilibrio compensa. |
| **La noche se congela solo en las noches que empiezan con la llamada** (hoy la 1, en los 3 modos), y mientras tanto las 3 entradas tienen un borde que parpadea. | Es lo que pidió Benja para leer en vivo. La noche 0 no cambia. |
| **El modo vlog vale en todas las noches salvo la noche 0**, también sin historia: el amigo sin nada que jugar siempre está grabando. | La noche 0 tiene su propio flujo, donde León dice qué apretar. |
| **El "pop" suena con cualquier línea de un amigo que no es una emergencia** (las emergencias ya tienen la alarma), y con las de la llamada. | Si sonara también con las emergencias, se mezclaría con la alarma. |
| **La música va en el volumen "Ambiente"** de las opciones, y mientras no estén las pistas no suena nada. | No hace falta otro control para 2 pistas. |
| **La pantalla final dice la hora en que terminó la noche** ("Llegaste a las 06:30"). | El texto decía 06:00 fijo. |
| **El equilibrio se compara con las referencias de hoy** (la noche 1, 20 semillas): la holgura, la batería y Trust. Se ajustan los valores de la noche 1 (los 3 modos) hasta quedar cerca. | Lo pidió Benja: "que quede con el mismo balanceo que ahora". |

**Las referencias de hoy** (antes del Plan 9.8):

| Noche 1 | Holgura | Batería | Trust mínimo |
| --- | --- | --- | --- |
| Normal | 6,19 | 10 % | 90 |
| Difícil | 4,90 | 10 % | 83,2 |
| Extremo | 1,91 | 41,4 % | 88,2 |

Difícil 5 (la referencia de S21k) tiene holgura 1,24, y Extremo 5, 1,01: con la final 5 s más tarde, se vuelven a medir.

---

## Tareas

### Tarea 1: El horario: hasta las 06:30 y la final con 5 s de holgura

**Archivos:** `scripts/data/night_data.gd`, `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/core/night_state.gd`, `scripts/core/pacing_director.gd`, `scripts/desk/request_manager.gd`, `scripts/core/ending_text.gd`, `scripts/ui/end_screen.gd`, `data/text/ui.csv`, `data/nights/*/night_1.tres`, `test/balance_model.gd` y sus pruebas.

- `NightData.overtime_minutes := 0` (minutos de juego después de las 06:00) y `length(balance)`: `night_seconds` × (360 + minutos) / 360. La noche 1 de los 3 modos, 30 (455 s).
- `BalanceData.finale_margin := 5.0`: lo que la final deja libre al final de una noche con historia (las demás siguen con `hurt_respite`, 10 s).
- `NightState` termina a `length()`, y el reloj sigue a la misma velocidad: llega a 06:30.
- `PacingDirector.finale_time()` y `request_due()`, `RequestManager.start_request()` y el modelo usan el largo de la noche.
- `END_WON_TITLE` y `END_QUOTA` llevan `{time}`: la hora en que terminó.

- [ ] **Paso 1:** pruebas: el reloj llega a 06:30 y la noche termina ahí (`test_night_state.gd`); la final con 5 s de holgura y en una noche más larga (`test_pacing_director.gd`); los títulos con la hora (`test_ending_text.gd`); los valores (`test_balance.gd` y `test_catalog.gd`).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK (las que fijan horas de la final se actualizan a los 5 s).
- [ ] **Paso 5:** commit "Las noches con historia terminan a las 06:30 y la final deja 5 s".

### Tarea 2: La historia en el horario

**Archivos:** `scripts/core/story_runner.gd`, `scripts/core/pacing_director.gd`, `scripts/desk/request_manager.gd`, `test/balance_model.gd`, `test/test_story_runner.gd`, `test/test_pacing_director.gd` y `test/test_request_manager.gd`.

- **`StoryRunner`:** una línea dura `max(letras / 15, 2)` s; `beat_seconds(beat, translate, decision_seconds)` mide un momento (sus líneas y, por decisión, la pregunta, el tiempo completo y la respuesta más larga); `story_needs(story, translate, decision_seconds)` devuelve, por momento, cuánto dura; y un momento "antes de" empieza `max(lead_seconds, lo que dura + 2)` antes de su ola.
- **`PacingDirector.new(night, balance, rng, story_needs)`:**
  - la primera ola, no antes de lo que duran el comienzo y lo de antes de la primera ola;
  - las olas comunes automáticas se reparten hasta `finale_at` menos lo que necesita la calma antes de la final (la reunión y lo de antes de la final);
  - cada calma dura al menos su historia: después de la primera ola, lo de "después de la primera"; antes de la última ola común, lo de "antes de la última"; antes de la final, la reunión y lo de antes de la final;
  - la regla que salta una ola que ya no cabe cuenta ese tiempo.
- `RequestManager` y el modelo miden la historia y se la pasan al director.

- [ ] **Paso 1:** pruebas: la duración de una línea y de un momento, la anticipación calculada (`test_story_runner.gd`); la primera ola espera la historia, cada calma dura su historia, las olas se planean con la reunión y el salto la cuenta (`test_pacing_director.gd`); el manager se la pasa al director (`test_request_manager.gd`).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La historia en el horario: el vlog más lento y las olas que le dejan su tiempo".

### Tarea 3: La noche espera la llamada

**Archivos:** `scripts/desk/request_manager.gd`, `scripts/desk/night_manager.gd`, `scripts/desk/desk.gd`, `test/test_night_manager.gd` y `test/test_desk_scene.gd`.

- `RequestManager.waiting_for_call`: en una noche con historia que empieza con la llamada, hasta `call_opened()`.
- `NightManager` no avanza mientras tanto, y `is_paused()` es verdadero (la Mano y los screamers esperan).
- El escritorio avisa cuando se ve la llamada, y mientras se espera, las 3 entradas tienen el borde que parpadea.

- [ ] **Paso 1:** pruebas: la noche congelada hasta abrir la llamada (`test_night_manager.gd`); abrir una entrada la abre y la noche corre; las entradas parpadean mientras tanto (`test_desk_scene.gd`).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La noche espera a que se abra la llamada".

### Tarea 4: El modo vlog y la emergencia marcada

**Archivos:** `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/ui/chat_message_view.gd`, `scripts/desk/request_manager.gd`, `scenes/ui/chat_panel.tscn`, `scripts/ui/chat_panel.gd`, `data/text/ui.csv` y sus pruebas.

- `ChatMessage.urgent` (lo marcan el mensaje inicial, las respuestas, el accidente y la pregunta de una decisión) y `ChatMessage.divider` (la línea "⚠ LEÓN PIDE AYUDA", `CHAT_HELP_DIVIDER`, que el manager pone antes del primer mensaje de una consulta, un accidente o una decisión).
- `ChatMessageView`: lo urgente lleva "⚠" antes del nombre y la barra en rojo; la línea va centrada entre "━━".
- `ChatPanel`: sin nada que jugar (fuera de la llamada y de la noche 0), PREGUNTAR y RESPONDER se ocultan y se ve `%VlogBar`: "● REC · LEÓN ESTÁ GRABANDO" (`CHAT_VLOG_REC`).

- [ ] **Paso 1:** pruebas en `test_message_builder.gd`, `test_chat_message_view.gd`, `test_request_manager.gd` y `test_chat_panel.gd`.
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar y reimportar los textos.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El modo vlog y la emergencia marcada en el chat".

### Tarea 5: La alarma, el aviso suave y el golpe de la ola

**Archivos:** `tools/make_sounds.py` (`audio/sfx/alarm_*.wav`, `chat_notify.wav` y `wave_stinger.wav`), `scripts/ui/chat_entry.gd`, `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scripts/desk/request_manager.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn`, `sonidos_pendiente.md` y sus pruebas.

- **La alarma:** cada entrada lleva su reloj: en alerta, la luz se enciende la primera mitad de cada medio segundo y pita al empezarlo, desde el instante en que entra en alerta. Con "Reducir destellos", la luz queda fija y pita igual. El escritorio ya no le da un reloj común.
- **El punto:** `ChatEntry.set_unread()` agrega " •" al nombre; el chat dice qué conversaciones tienen mensajes sin leer (`has_unread()` y `has_unread_call()`).
- **El "pop":** el chat lo toca cuando llega a una conversación que no se ve una línea de un amigo que no es urgente, o una de la llamada, a lo más uno cada 2 s.
- **El golpe:** `RequestManager.wave_started` y el escritorio lo toca.

- [ ] **Paso 1:** pruebas en `test_chat_entry.gd` (el ritmo, que empieza al entrar en alerta, que cada una lleva el suyo y el punto), `test_chat_panel.gd` (el pop y los no leídos) y `test_desk_scene.gd` (el golpe y los puntos).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar y generar solo esos sonidos con `make_sounds.py`.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "La alarma de cada amigo con su ritmo, el aviso suave y el golpe de la ola".

### Tarea 6: El separador de no leídos y la música

**Archivos:** `scripts/ui/chat_panel.gd`, `data/text/ui.csv`, `scripts/desk/music_player.gd` (nuevo), `scenes/desk/desk.tscn`, `scripts/desk/desk.gd` y sus pruebas.

- **El separador:** cada conversación recuerda su primer mensaje sin leer; al verla, la línea "── NUEVOS ──" (`CHAT_UNREAD_DIVIDER`) queda justo antes. Hay una por conversación, y se mueve con la siguiente tanda.
- **`MusicPlayer`:** 2 reproductores en el bus "Ambience", con `audio/music/calm.ogg` y `wave.ogg` si existen; `intense` elige cuál, con un fundido de 2 s. El escritorio lo pone en las olas (y en la final). Sin las pistas, no suena nada.

- [ ] **Paso 1:** pruebas en `test_chat_panel.gd` (el separador) y `test_music_player.gd` (nuevo: el fundido y sin pistas).
- [ ] **Paso 2:** correrlas y ver que fallan.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** correr todas las pruebas: OK.
- [ ] **Paso 5:** commit "El separador de no leídos y la música por momento".

### Tarea 7: El equilibrio

**Archivos:** `data/nights/*/night_1.tres`, `test/test_balance.gd` y lo que haga falta ajustar.

- Medir la noche 1 de los 3 modos y las noches 2 a 5 (por la final con 5 s), y ajustar la noche 1 hasta quedar cerca de las referencias.
- `test_la_historia_no_regala_tiempo`: la holgura de cada noche 1 queda a un 5 % de su referencia, y la batería a 1 punto.

- [ ] **Paso 1:** medir, ajustar y anotar aquí cómo quedó.

  **Cómo quedó** (20 semillas). Con la noche hasta las 06:30 y la historia en el horario, sin ajustar nada, la holgura subía: Normal 6,36 (+2,7 %), Difícil 5,28 (+7,8 %) y Extremo 2,15 (+12,6 %, y su batería de 41,4 a 44,4 %). Se ajustó la noche 1 de cada modo: Sanity baja lo mismo en total que antes (−1 cada 10,8 s en Normal y Difícil, 6,5 s en Extremo), y la señal cae un poco más rápido, lo que consume el tiempo libre que agrega la historia.

  | Noche 1 | Señal (s por punto) | Holgura (antes) | Batería (antes) | Trust mínimo (antes) |
  | --- | --- | --- | --- | --- |
  | Normal | 2,9 a 5,8 (3 a 6) | 6,17 (6,19) | 10 % (10 %) | 90 (90) |
  | Difícil | 2,8 a 5,6 (3 a 6) | 4,97 (4,90) | 10 % (10 %) | 83,2 (83,2) |
  | Extremo | 2,5 a 5 (3 a 6) | 1,95 (1,91) | 41,4 % (41,4 %) | 88,2 (88,2) |

  Las noches 2 a 5 no cambiaron (no tienen historia, y su final sigue con 10 s de holgura).
- [ ] **Paso 2:** la prueba.
- [ ] **Paso 3:** correr todas las pruebas: OK.
- [ ] **Paso 4:** commit "La noche 1 con su historia queda con el equilibrio de antes".

### Tarea 8: Revisión y documentos

- [ ] **Paso 1:** capturas a 1280×720 y 1080p (`test/capture_plan98.gd`): la llamada en espera, el modo vlog, la emergencia marcada con su línea, el separador y las entradas con el punto. Una prueba de humo con la noche 1 entera en los 3 modos.
- [ ] **Paso 2:** correr todas las pruebas: OK. Commit "Revisión de la historia clara".
- [ ] **Paso 3:** documentos (`CLAUDE.md`, el diseño v2, `docs/02`, `docs/04` (la sección X), `sonidos_pendiente.md`, este plan, `docs/00_log.md` y `resumen.md`). Commit.

---

## Fuera de este plan

- **Para Benja:** las 2 pistas de música (`sonidos_pendiente.md`), escuchar las alarmas, el pop y el golpe, y volver a probar la noche 1 (`docs/04`, X).
