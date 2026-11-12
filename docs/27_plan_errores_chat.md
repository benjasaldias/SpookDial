# Plan 9.3: Errores y el chat — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** la primera de las 3 sesiones con el feedback del primer testeo (`docs/26` §2, sesión S21h):

1. **Las preguntas** muestran lo que cuestan y no se repiten, salvo que la estática haya tapado su respuesta (observación 1).
2. **Lo decisivo va en azul:** las observaciones en el chat y las condiciones en el cuaderno (observación 7).
3. **El chat, más claro:** cada control con su forma: preguntas con ícono, respuestas como hojas del cuaderno, sincronizar con las barritas de la señal y el nombre con un cuaderno (observación 5).
4. **"Matías piensa" dura 2 s** (observación 8).
5. **La descarga responde al primer clic** (observación 10).
6. **La noche ganada se guarda** al volver al menú (observación 11).
7. **Los señuelos ya no cuestan** (decisión D4).

**Arquitectura:**

- **Lógica pura primero:**
  - `FriendRequest` recuerda qué categorías se preguntaron y si su respuesta salió tapada;
  - `ChatMessage` marca las observaciones y sabe si la estática tapó algo que importa.
- **`Highlight`** (`scripts/ui/highlight.gd`) hace parpadear un borde alrededor de cualquier `Control`, y queda fijo con "Reducir destellos". Lo usa el botón de la señal y, en S21j, el tutorial.
- **El chat** pasa a un `VBoxContainer`:
  - la conversación toma el alto que sobra;
  - debajo van la descarga, la fila de identificación y la señal, y los bloques **PREGUNTAR** y **RESPONDER**, cada uno con su título.
- **El arte nuevo** es pixel art de Claude en `art/ui/chat_*.png`, generado por `tools/make_ui_art.py`.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`). El arte, con Python (Pillow y numpy).

**Cómo se ejecuta:** igual que los Planes 9.1 y 9.2. Se escribe y se ejecuta en la misma sesión (S21h), con un commit por tarea que Benja autorizó al empezar. **El código exacto de cada tarea está en su commit.** Las pruebas que tocan la disposición del chat fuerzan el acomodo de los contenedores, porque `run_tests.gd` no deja pasar cuadros entre pruebas.

**Punto de partida:** 626 pruebas OK.

**Resultado (11-nov, S21h):** ejecutado completo, en 11 commits. **661 pruebas OK.** Las capturas se revisaron a 1280×720, 1920×1080 y 1920×1009 (ventana maximizada), en `C:\dev\capturas\plan93_*.png`, y el juego abre sin errores nuevos.

| Tarea | Commit | Pruebas |
| --- | --- | --- |
| 1. Las preguntas no se repiten | `162b533` | 633 |
| 2. "Matías piensa" 2 s y los señuelos sin costo | `7f63403` | 635 |
| 3. La descarga al primer clic | `1e02dee` | 638 |
| 4. La noche ganada se guarda | `809568e` | 640 |
| 5. El parpadeo | `3d2eeb7` | 644 |
| 6. El arte del chat | `140bd58` | 645 |
| 7. El chat en bloques | `2ded642` | 648 |
| 8. Las preguntas con su ícono y su costo | `8ef62bf` | 653 |
| 9. Las respuestas como hojas | `4c1877f` | 654 |
| 10. La señal y el cuaderno del nombre | `49d5b71` | 657 |
| 11. Lo decisivo en azul | `5c85d62` | 661 |
| 12. Revisión a 1280×720 y 1080p | — | 661 |

**Lo que cambió al ejecutar:**

- **La descarga:** la primera sospecha (que Godot pide mover el mouse para que un botón que aparece debajo responda) se descartó con clics simulados. Tampoco era el botón tapado por la conversación. La causa es un clic que empieza un instante antes de que aparezca la barra, y Benja confirmó que así le pasó al tester (Tarea 3).
- **Las respuestas van en una columna**, no en 2×2. A 1080p, en media columna caben unas 17 letras por línea, y la acción más larga ("Salir retrocediendo, sin darle la espalda", 41 letras) ocuparía 4 líneas; a todo el ancho caben unas 38. Además quedan como la lista de acciones del cuaderno, del 1 al 4.
- **Las respuestas tienen su alto reservado:** el que piden las acciones más largas de las entidades de la noche, o las opciones de un accidente, medido con la letra de ahora. Si no, abrir una página empujaba las preguntas hacia arriba.
- **Los íconos:** la oreja no se leía a 9×9 (parecía un "?"), así que **Sonido es un parlante**. Rastros es la huella de una pata.
- **El "−5 s" de la pestaña** lleva fondo oscuro y borde rojo, sobre el borde de la pestaña: en rojo solo, encima de la conversación, no se leía.
- **Las hojas van por encima de las líneas CRT** del chat (`z_index` 1), para verse como papel y no como algo impreso en la pantalla.
- **Una sola variación del tema**, `ChatIconButton`, para los botones con ícono (las preguntas, la señal y el nombre). No invierte los colores al pasar el mouse, así el costo rojo y la señal se siguen leyendo.
- **Las pestañas:** un solo espacio entre el nombre, el tiempo y el aviso, y el texto se corta si no cabe, para que a 1080p no ensanchen el chat.
- **León:** como el botón ya no dice "Sincronizar", `TUTORIAL_LEON_SIGNAL_WARN` dice "el botón de las barritas" hasta que S21j rehaga el tutorial.
- **Las pruebas acomodan el chat a mano:** `run_tests.gd` no deja pasar cuadros, y los contenedores se acomodan al final de cada cuadro. Las que miran posiciones llaman a `_layout()`, y las que aprietan la barra usan clics simulados con `push_input` (también la prueba del tutorial y `capture_maintenance.gd`).

---

## Decisiones de Benja (S21g y S21h, 11 de noviembre)

| Decisión | Detalle |
| --- | --- |
| **D4: los señuelos no cuestan** | En ningún modo. Un señuelo solo vibra y se pone rojo. |
| **Las preguntas no se repiten** | Cada botón muestra su costo; una pregunta respondida queda con ✓ y bloqueada, salvo que la estática haya tapado su respuesta (`docs/26` §2.1). |
| **Lo decisivo en azul** | Las observaciones en azul y sin clic; las características y los señuelos, en amarillo y con clic. |
| **El cuaderno, con los mismos colores** (pregunta de S21h) | Las condiciones de la tabla en lápiz pasta azul y los nombres de las características con destacador amarillo: amarillo para saber qué página es y azul para saber qué fila. |
| **El chat rediseñado** (pregunta de S21h) | El esquema de `docs/26` §2.3, con el costo en cada botón de pregunta y los accidentes con botones de terminal. |
| **"Matías piensa" a 2 s** | Ajustable en `data/balance.tres` (`thinking_seconds`). |
| **La descarga** (pregunta de S21h) | El tester apretó justo cuando aparecía la barra. |
| **Commits** | Benja autorizó todos los de la sesión, en `main` y sin push. |

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **Una pregunta se puede repetir solo si la estática tapó una característica, un señuelo, una observación o el audio.** Si la respuesta es la de "nada" ("No veo nada raro."), cuenta cualquier palabra tapada. | Una palabra de relleno tapada ("▒▒▒ un hombrecito") no esconde nada que sirva: repetirla costaría 5 s por nada. |
| **Las etiquetas cortas de las preguntas:** ¿QUÉ VES?, ¿QUÉ OYES?, ¿AMBIENTE? y ¿RASTROS? Matías sigue preguntando con la frase completa ("¿Cómo está el ambiente?"). | Con el ícono y el costo, a 1080p solo caben unas 12 letras por botón. |
| **El "−5 s" de la pestaña** sale debajo de ella, en rojo, y sube y se desvanece en algo más de 1 s. | A 1080p, la pestaña ("AGUSTÍN 43 •") ya no tiene espacio para más texto. |
| **Las respuestas usan la nota adhesiva de las pestañas del cuaderno** (`notebook_tab.png`) para su número. | Las une a la vista con el cuaderno. |
| **Los accidentes siguen con botones de terminal**, sin número. | Se responden con sentido común, sin cuaderno: una hoja numerada confundiría. |
| **La señal en el botón de sincronizar:** una barrita por cada 25 de señal; verdes con 70 o más (sin estática), ámbar entre 30 y 69 y rojas bajo 30. Sin señal, una × y el borde rojo que parpadea. | Los colores siguen los tramos de la estática (`ChatStatic.COVERAGE`), así que el ícono avisa cuánto se va a tapar. |
| **El parpadeo:** un borde de 2 px, 0,4 s encendido y 0,4 s apagado. | Se ve sin tapar el botón. |
| **La descarga avanza mientras el botón izquierdo esté apretado sobre la barra,** aunque el clic haya empezado fuera de ella. Si el mouse sale de la barra, se pausa. | Es la causa del error (ver la Tarea 3). |
| **Se quitan `decoy_cost` y su código**, no solo se dejan en 0. | La decisión D4 vale para los dos modos: el campo ya no tiene uso. |
| **Al ganar una noche se guarda la siguiente,** y al despedirse León en la noche 0 se guarda la noche 1. | "Continuar" no vuelve a una noche ganada ni al tutorial terminado. |

---

## Tareas

### Tarea 1: Las preguntas no se repiten (lógica)

**Archivos:** `scripts/core/chat_message.gd`, `message_builder.gd`, `friend_request.gd`, `scripts/desk/request_manager.gd` y sus pruebas (`test_chat_message.gd`, `test_message_builder.gd`, `test_friend_request.gd` y `test_request_manager.gd`).

- **`ChatMessage`:**
  - `Token.is_observation` marca las palabras de una observación;
  - `add_fragment(text, clue_id, observation := false)` marca las palabras del fragmento;
  - `lost_information() -> bool` es `true` si la estática tapó una frase clickeable, una palabra de una observación o el audio. Si el mensaje no tiene nada de eso (la respuesta de "nada"), basta con cualquier palabra tapada.
- **`MessageBuilder.answer()`** agrega cada observación con `observation = true`.
- **`FriendRequest`** guarda las respuestas por categoría (`ClueCategory.Kind` → si salió tapada):
  - `was_asked(category)` y `answer_covered(category)`;
  - `can_ask_about(category)`: `can_ask()`, y además la categoría no se preguntó o su respuesta salió tapada;
  - `record_answer(category, covered)`.
- **`RequestManager.ask()`** rechaza una pregunta que no se puede repetir (sin costo). Después de agregar la respuesta, con su estática, guarda `lost_information()`.

- [x] **Paso 1:** pruebas:
  - `test_chat_message.gd`: `test_las_observaciones_se_marcan` y `test_informacion_perdida`, que cubre la característica, el relleno, la observación, el audio y la respuesta de "nada";
  - `test_message_builder.gd`: `test_la_respuesta_marca_las_observaciones`;
  - `test_friend_request.gd`: `test_una_pregunta_respondida_no_se_repite` y `test_con_la_respuesta_tapada_se_puede_repetir`;
  - `test_request_manager.gd`: `test_no_se_repite_una_pregunta` y `test_guarda_si_la_respuesta_salio_tapada`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Las preguntas ya respondidas no se repiten, salvo con estática".

### Tarea 2: "Matías piensa" 2 s y los señuelos sin costo

**Archivos:** `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/core/friend_request.gd`, `request_generator.gd`, `scripts/ui/chat_panel.gd`, `chat_message_view.gd`, `data/text/ui.csv` y las pruebas (`test_friend_request.gd`, `test_request_generator.gd`, `test_chat_panel.gd` y `test_balance.gd`).

- **`BalanceData`:**
  - `thinking_seconds := 2.0`, en el grupo "Identificación";
  - se borra `decoy_cost`.
- **`FriendRequest`:** `THINKING_TIME` pasa a ser `thinking_seconds`, que copia el generador; se borran `DECOY_COST`, `decoy_cost` y su descuento.
- **El chat:**
  - el señuelo vibra sin costo (`ChatMessageView.shake(clue_id)`);
  - se borran `DECOY_COST_KEY` y `CHAT_DECOY_COST`.
- **`TUTORIAL_LEON_DECOY`:** "Jaja no, todos andamos con polerón. Eso no te sirve." (sin "y te costó un segundo").

- [x] **Paso 1:** pruebas:
  - `test_matias_piensa_lo_que_dice_el_equilibrio` y `test_un_senuelo_no_cuesta` (reemplaza a la del costo), en `test_friend_request.gd`;
  - `test_copia_el_tiempo_de_pensar` en `test_request_generator.gd`;
  - `test_el_senuelo_vibra_sin_costo` en `test_chat_panel.gd`, que reemplaza a `test_el_senuelo_muestra_lo_que_costo`;
  - en `test_balance.gd`, 2 s de pensar en lugar de 1 s por señuelo.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y reimportar los textos (`--import`).
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Matías piensa 2 s, y los señuelos ya no cuestan".

### Tarea 3: La descarga responde al primer clic

**Diagnóstico** (`superpowers:systematic-debugging`, con scripts temporales que simulaban clics reales con `push_input`):

- En el panel solo y en el escritorio completo, mantener presionada la barra funciona al primer clic si el clic **empieza** sobre ella. Eso también vale si el mouse estaba quieto donde apareció la barra, así que se descarta que Godot pida mover el mouse antes.
- Se descarta la hipótesis 1 de `docs/26`: `Download` va después de `Conversations` en el árbol, así que recibe el clic primero. Se descarta la 2: nada cambia la pestaña ni la visibilidad al hacer clic. La 3 es real pero inofensiva: la descarga empieza un cuadro después.
- **Se reproduce** cuando el clic empieza un instante antes de que aparezca la barra, o en el mismo cuadro, porque Godot atiende la entrada antes de `_process`, que es donde la barra se hace visible. Ese clic lo recibe la conversación. Aunque el jugador lo mantenga sobre la barra, el botón `Hold` nunca recibe su `button_down`: `holding_download` queda en -1 y la descarga no avanza hasta que se suelta y se vuelve a apretar. Benja confirmó que así le pasó al tester: la barra recién aparecía.

**Arreglo:**

- El panel sigue el botón izquierdo y la posición del mouse en `_input`, que recibe todos los clics, empiecen donde empiecen.
- `is_holding_download()` es `true` si el chat está abierto, el amigo elegido tiene un video y el botón izquierdo está apretado con el mouse sobre la barra.
- `Hold` pasa de `Button` a `Panel`:
  - sigue recibiendo los clics, para que el escritorio no cierre el chat;
  - se ve normal, iluminada o apretada según ese mismo estado.
- Se borran `_holding_download`, `button_down`, `button_up` y la conexión con `visibility_changed`.

**Archivos:** `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres` y `test/test_chat_panel.gd`.

- [x] **Paso 1:** pruebas en `test_chat_panel.gd`, todas con clics simulados (`push_input`):
  - `test_apretar_justo_antes_de_que_aparezca_la_barra` (la que reproduce el error);
  - `test_mantener_presionado_descarga`, reescrita;
  - `test_fuera_de_la_barra_no_descarga`;
  - `test_cerrar_el_chat_suelta_la_descarga`, reescrita.
- [x] **Paso 2:** correrlas y ver que la primera falla con `holding_download = -1`.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "La descarga responde aunque el clic empiece justo antes de que aparezca la barra".

### Tarea 4: La noche ganada se guarda

**Archivos:** `scripts/autoload/game_state.gd` y `test/test_game_state.gd`.

- `_on_night_ended`: al ganar se guarda la noche siguiente, y si era la última se borra la partida, como hoy.
- `prepare_night(0)` conecta `RequestManager.tutorial_finished`: cuando León se despide, se guarda la noche 1. Así, salir en las tarjetas no obliga a repetir el tutorial.

- [x] **Paso 1:** pruebas:
  - `test_ganar_una_noche_guarda_la_siguiente`, en la que perder no cambia lo guardado;
  - `test_al_despedirse_leon_se_guarda_la_noche_1`;
  - `test_al_ganar_la_ultima_noche_se_borra_la_partida`, corregida: ganar la noche 4 guarda la 5.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Ganar una noche guarda la siguiente, y la despedida de León guarda la noche 1".

### Tarea 5: El parpadeo (`Highlight`)

**Archivos:** `scripts/ui/highlight.gd` (nuevo) y `test/test_highlight.gd` (nuevo).

- `Highlight` (`Node2D`) se agrega como hijo de un `Control` y dibuja un borde de 2 px, 2 px por fuera de él, con `z_index` 1 para quedar sobre sus vecinos.
- **Propiedades:**
  - `active`: sin activar no dibuja nada;
  - `reduce_flashes`;
  - `color`: ámbar por defecto.
- `static func is_lit(time, reduce_flashes) -> bool`: encendido 0,4 s y apagado 0,4 s. Con "Reducir destellos", siempre encendido.
- `static func attach(target: Control) -> Highlight`: lo crea y lo agrega. Así lo usará el tutorial (S21j).

- [x] **Paso 1:** pruebas:
  - `test_parpadea`;
  - `test_con_reducir_destellos_queda_fijo`;
  - `test_el_borde_rodea_al_control`;
  - `test_inactivo_no_se_ve`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "El parpadeo: un borde que avisa qué apretar".

### Tarea 6: El arte del chat

**Archivos:** `tools/make_ui_art.py`, `art/ui/chat_*.png` (nuevos) y `test/test_ui_art.gd` (nuevo).

- **Íconos de las preguntas**, de 9×9 y en blanco, porque el botón les da su color: ojo (`chat_icon_sight`), oreja (`chat_icon_sound`), nube (`chat_icon_environment`) y huella (`chat_icon_traces`).
- **Estados**, de 9×9:
  - ✓ verde claro (`chat_icon_check`);
  - estática, con puntos grises de 2 tonos (`chat_icon_static`).
- **El cuaderno** del nombre de la entidad (`chat_icon_notebook`, 11×11): la tapa verde, la espiral y la etiqueta, con la paleta del cuaderno.
- **La señal** (`chat_signal.png`): 5 cuadros de 15×12, de 0 a 4 barritas, en 3 filas (verde, ámbar y rojo). Las vacías llevan solo el borde, y sin señal hay una ×.
- **Las hojas de respuesta** (`chat_answer_normal`, `_hover`, `_pressed` y `_disabled`): texturas 9-slice de 19×19 con márgenes de 4. Llevan papel cuadriculado (un cuadro de 11 que se repite), un borde oscuro y la sombra abajo y a la derecha:
  - al pasar el mouse, el papel se aclara;
  - apretada, se oscurece;
  - deshabilitada, se apaga.

- [x] **Paso 1:** prueba `test_el_arte_del_chat_existe`: cada PNG se importa como `Texture2D`, con el tamaño esperado.
- [x] **Paso 2:** correrla y ver que falla.
- [x] **Paso 3:** dibujar en `make_ui_art.py`, correrlo (`/usr/bin/python3 tools/make_ui_art.py`) e importar (`--import`, con el editor cerrado).
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar el arte ampliado.
- [x] **Paso 5:** commit "El arte del chat: íconos, la señal y las hojas de respuesta".

### Tarea 7: El chat rediseñado: la disposición y los títulos

**Archivos:** `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres`, `scripts/ui/chat_panel.gd`, `data/text/ui.csv`, `test/test_chat_panel.gd` y los scripts de captura y de prueba que usan las rutas de los nodos (`capture_*.gd`, `test_desk_scene.gd`, `test_screamer_manager.gd` y `test_tutorial_desk.gd`).

- **`Panel/Layout`** (`VBoxContainer`) contiene, en orden:
  - `Tabs`;
  - `Conversations`, que se estira;
  - `Download`;
  - `IdentifyBar`, con un alto mínimo para que nada salte al llegar una solicitud;
  - `AskTitle` y `Questions`;
  - `AnswerTitle` (antes `AnswerHint`), `Answers` y `ScriptReply`.
- Los nodos que usa el código llevan nombre único (`%Questions`), así que una próxima reubicación no rompe las rutas.
- Se borran `CONVERSATION_BOTTOM` y `CONVERSATION_BOTTOM_WITH_DOWNLOAD`.
- **Los títulos** (`SectionTitle` en el tema: mayúsculas, el teal de la terminal):
  - **PREGUNTAR**, que agrega " · SIN SEÑAL" o " · SIN TIEMPO" cuando no se puede;
  - **RESPONDER**, que agrega:
    - " · EL TRAUCO", con la página abierta;
    - " · ABRE EL CUADERNO";
    - " · SIN SEÑAL: SINCRONÍZALO";
    - " · ¿QUÉ LE DICES?", en un accidente.
- **Textos** en `ui.csv`:
  - nuevos: `CHAT_ASK_TITLE`, `CHAT_ANSWER_TITLE` y `CHAT_NO_TIME`;
  - más cortos: `CHAT_OPEN_NOTEBOOK` y `CHAT_OFFLINE`;
  - se borra `ANSWER_FROM_PAGE`.

- [x] **Paso 1:** pruebas en `test_chat_panel.gd`:
  - `test_los_titulos_de_cada_bloque` (con página, sin página, sin señal, sin tiempo y en un accidente);
  - `test_la_descarga_acorta_la_conversacion` (fuerza el acomodo);
  - las de siempre, con las rutas nuevas.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar, reimportar los textos y actualizar las rutas.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura.
- [x] **Paso 5:** commit "El chat en bloques: la conversación, PREGUNTAR y RESPONDER".

### Tarea 8: Las preguntas con su ícono, su costo y su estado

**Archivos:** `scripts/ui/question_button.gd` (nuevo), `scripts/ui/chat_panel.gd`, `scenes/ui/chat_theme.tres`, `scripts/ui/pixel_text.gd`, `data/text/ui.csv` y `test/test_chat_panel.gd`.

- **`QuestionButton`** (`Button`, variación `QuestionButton`, que al pasar el mouse no invierte los colores) lleva adentro su ícono, la etiqueta corta (`QUESTION_*_SHORT`) y, a la derecha, el costo ("−5 s", de `CHAT_QUESTION_COST`) o su estado.
- `set_state(state)`, donde `State` es uno de:
  - `READY`;
  - `ASKED`: ✓ y tenue, deshabilitada;
  - `STATIC`: ícono de estática y el costo, habilitada;
  - `LOCKED`: deshabilitada.
- El tamaño mínimo sigue al de la letra (`PixelTextSizer.changed`).
- **`PixelText.icon_size(pixels)`:** el tamaño de un ícono que sigue nítido junto a la letra. Lo usa también el cuaderno, que hoy hace la cuenta a mano.
- **El chat:**
  - elige el estado de cada pregunta con `can_ask_about`, `was_asked` y `answer_covered`;
  - al pagar una pregunta, saca el "−5 s" rojo debajo de la pestaña del amigo (`CostPopup`), que sube y se desvanece.

- [x] **Paso 1:** pruebas:
  - `test_cada_pregunta_muestra_su_costo`;
  - `test_la_pregunta_respondida_queda_marcada`;
  - `test_con_estatica_la_pregunta_vuelve`;
  - `test_al_preguntar_la_pestana_muestra_el_costo`;
  - `test_el_icono_sigue_a_la_letra` (en `test_pixel_text.gd`).
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y reimportar los textos.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura.
- [x] **Paso 5:** commit "Las preguntas: su ícono, su costo y si ya se hicieron".

### Tarea 9: Las respuestas como hojas del cuaderno

**Archivos:** `scripts/ui/chat_panel.gd`, `scenes/ui/chat_theme.tres` y `test/test_chat_panel.gd`.

- Cada botón de respuesta usa la variación `AnswerSheet`:
  - las 4 hojas de `chat_answer_*` (`StyleBoxTexture`, con el centro en mosaico);
  - letra de tinta;
  - margen izquierdo para la nota adhesiva.
- **La nota adhesiva** (`Number`) es un `PanelContainer` con `notebook_tab.png` y el número de la columna, a la izquierda y centrado en alto.
- **En un accidente**, los botones vuelven al estilo de terminal y sin número.

- [x] **Paso 1:** pruebas:
  - `test_las_respuestas_son_hojas_numeradas`;
  - `test_un_accidente_se_responde_desde_el_chat`, que ahora comprueba además el estilo de terminal y que no hay número.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura.
- [x] **Paso 5:** commit "Las respuestas son hojas del cuaderno, con el número de su columna".

### Tarea 10: El nombre con un cuaderno y el botón de la señal

**Archivos:** `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres`, `scripts/desk/desk.gd` y las pruebas (`test_chat_panel.gd` y `test_desk_scene.gd`).

- **El nombre de la entidad** lleva el ícono del cuaderno.
- **`Sync`** es un botón cuadrado (`SyncButton`), con la señal del amigo elegido:
  - `static func signal_frame(level) -> Vector2i` dice cuántas barritas y en qué fila de color;
  - lleva `Sincronizar` (`CHAT_SYNC`) como tooltip, con el estilo de la terminal;
  - con 0 de señal, su `Highlight` rojo parpadea.
- **`desk.apply_settings`** le pasa "Reducir destellos" al chat.

- [x] **Paso 1:** pruebas:
  - `test_la_senal_en_barritas` (0, 10, 30, 69, 70 y 100);
  - `test_el_boton_sincronizar`, reescrita: el ícono, el tooltip y el pedido de sincronizar;
  - `test_sin_senal_el_boton_parpadea`, también con "Reducir destellos";
  - en `test_desk_scene.gd`, que la opción llega al chat.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura.
- [x] **Paso 5:** commit "La señal del amigo en el botón de sincronizar, y el cuaderno junto al nombre".

### Tarea 11: Lo decisivo en azul, en el chat y en el cuaderno

**Archivos:** `scripts/ui/chat_message_view.gd`, `scripts/core/notebook_page.gd` y sus pruebas (`test_chat_message_view.gd` y `test_notebook_page.gd`).

- **El chat:**
  - las palabras de una observación van en `OBSERVATION_COLOR`, sin enlace;
  - el audio también va en azul, porque es una observación, y sigue con su enlace para escucharlo.
- **El color:** se elige con capturas.
  - Tiene que leerse sobre el fondo oscuro.
  - No se puede confundir con el de Gonzalo (`#80a6ff`, pastel) ni con el cian de Matías (`#40c2c9`).
  - Se prueba un azul saturado, más puro que el de Gonzalo.
- **El cuaderno:**
  - las condiciones de la tabla, en lápiz pasta azul (`CONDITION_COLOR`), distinto del azul oscuro de los títulos;
  - los nombres de las características, con destacador amarillo (`[bgcolor]`).

- [x] **Paso 1:** pruebas:
  - `test_las_observaciones_van_en_azul` y `test_el_audio_va_en_azul` (en `test_chat_message_view.gd`);
  - `test_las_condiciones_van_en_azul` y `test_las_caracteristicas_con_destacador` (en `test_notebook_page.gd`).
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura del chat y del cuaderno.
- [x] **Paso 5:** commit "Lo decisivo en azul: las observaciones y las condiciones del cuaderno".

### Tarea 12: Revisión a 1280×720 y a 1080p

**Archivos:** `test/capture_plan93.gd` (nuevo) y lo que haga falta corregir.

- **Capturas del chat:** con un video, con estática (una pregunta que vuelve), sin señal (el botón que parpadea), con la página abierta (las hojas) y con un accidente. Van a 1280×720 y a 1920×1080, en `C:\dev\capturas\plan93_*.png`.
- **Qué se revisa:**
  - la letra sigue nítida;
  - nada se sale de su botón;
  - los íconos se ven parejos;
  - el azul se distingue;
  - y la conversación conserva un alto razonable.

- [x] **Paso 1:** escribir el script y sacar las capturas.
- [x] **Paso 2:** revisarlas y corregir lo que haga falta, con su prueba si es lógica.
- [x] **Paso 3:** correr todas las pruebas: OK. Abrir el juego sin errores.
- [x] **Paso 4:** commit "Revisión del chat a 1280×720 y a 1080p".

---

## Fuera de este plan

- **S21i:** en Difícil se apagan el amarillo, el azul, los clics y "Matías piensa".
- **S21j:** el tutorial usa el parpadeo, las hojas, la señal y el costo de las preguntas, y León explica lo azul y los audios.
- **Para Benja:** redibujar los íconos, las hojas o el botón de la señal (`arte_pendiente.md`) y corregir los textos nuevos (al cerrar la sesión, en `resumen.md`).
