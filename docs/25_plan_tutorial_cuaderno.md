# Plan 9.2: La letra nítida, el cuaderno con tabla y el tutorial con León — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** las notas que Benja dio el 11 de noviembre después del Plan 9.1:

1. **La letra se ve fea en pantalla completa.** Tiene que verse nítida, y puede ser un poco más grande.
2. **El cuaderno:**
   - sin las preguntas entre paréntesis ni la lista de observaciones;
   - las reglas en una tabla, **Condición | 1 | 2 | 3 | 4**, con una marca por acción;
   - la cuadrícula, más suave.
3. **La noche 0 deja de ser un onboarding:**
   - León la enseña en el chat, de forma natural y con chistes, describiendo a Gonzalo en vez de una entidad real, con una página del cuaderno propia;
   - el jugador elige la mejor y la peor decisión, y si se equivoca, vuelve a intentarlo;
   - León pierde la señal para enseñar Audio Sync, y se despide;
   - después, unas tarjetas con videos muestran los medidores, el celular, la sombra y la cortina, y la Mano.
4. **Sin texto de relleno:** nada de paréntesis que no aportan ni de información obvia o repetida.

**Arquitectura:**

- **`PixelText`** (`scripts/ui/pixel_text.gd`, autoload) elige el tamaño de letra nítido para la escala de la ventana y lo aplica a los temas, a los nodos con tamaño propio y al texto dibujado por código.
- **`NotebookPage`** arma la tabla con `[table]` de RichTextLabel y 3 íconos nuevos (`art/ui/mark_*.png`).
- **`TutorialChat`** (`scripts/core/tutorial_chat.gd`, lógica pura) es la conversación de León: recibe lo que hace el jugador y devuelve las líneas de León y lo que el juego tiene que hacer (cortar la señal, mandar el video o terminar).
- **`RequestManager`** la conecta en la noche 0.
- **`TutorialCards`** (`scenes/ui/tutorial_cards.tscn`) muestra las tarjetas con videos Theora (`video/tutorial/*.ogv`), que graba `test/record_tutorial_clips.gd` y convierte `tools/make_tutorial_videos.sh`.
- **Se quitan** `TutorialGuide`, el aviso de arriba (`TutorialHint`), el susto guionado de la noche 0 y el paso de la Mano de la noche 0.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`). Para los videos, el Movie Maker de Godot (`--write-movie`) y ffmpeg con libtheora.

**Cómo se ejecuta:** igual que el Plan 9.1. Se escribe y se ejecuta en la misma sesión (S21f, continuación), con un commit por tarea, que Benja autorizó al aprobar el diseño. **El código exacto de cada tarea está en su commit.**

**Punto de partida:** 613 pruebas OK.

**Resultado (11-nov, S21f, continuación):** ejecutado completo, en 6 commits (las Tareas 3, 4 y 5 van juntas). **625 pruebas OK.** Las capturas están revisadas a 1920×1080, 1920×1009 (ventana maximizada) y 1280×720, en `C:\dev\capturas\plan92_*.png`.

| Tarea | Commit | Pruebas |
| --- | --- | --- |
| 1. La letra nítida | `61270b3` | 616 |
| 2. El cuaderno con tabla | `d4375b5` | 617 |
| 3, 4 y 5. La noche 0 con León | `ec01e50` | 619 |
| 6. Los videos | `a078230` | 619 |
| 7. Las tarjetas | `75f16c1` | 624 |
| 8. Revisión a 1080p | `23f1ecb` | 625 |

**Lo que cambió al ejecutar:**

- **La regla de la letra apunta al tamaño real:** primero elige cuántos píxeles reales debe medir la letra (el múltiplo de 11 más cercano) y después el tamaño que da justo eso. Así también queda nítida en una ventana maximizada (escala 1,4, sin la barra de tareas), donde la primera regla la dejaba chica. A 1080p el resultado es el mismo.
- **La tabla:** `[cell=6 border=…]` ignora el borde y el relleno en Godot 4.7; hace falta `[cell expand=6 padding=…]`, y el borde de todas las celdas sale del color `table_border` del tema del cuaderno.
- **El video de la ventana es vertical** (420×512): la criatura y su sombra en el escritorio no caben juntas en 640×360. Por eso las tarjetas llevan el video a la izquierda y el texto a la derecha.
- **El contenido de las tarjetas es dato** (`TutorialCardData`, en la noche 0), por la regla 7.
- **Con la letra más grande a 1080p**, la revisión corrigió:
  - la placa de las barras, que pasa a 320 px;
  - el porcentaje de la batería del celular;
  - el alto de "Videos" en el PC;
  - dos textos más cortos (`IDENTIFY_PROGRESS` y `MIXER_HINT`);
  - y en la noche 0 ya no se avisa que faltan videos.
- **El tutorial viejo se borró:** `TutorialGuide`, `TutorialHint` y 22 textos `TUTORIAL_*` de `ui.csv`.

---

## Decisiones de Benja (11 de noviembre, después del Plan 9.1)

| Decisión | Detalle |
| --- | --- |
| **La letra, nítida en pantalla completa** | Puede ser un poco más grande. |
| **Cuaderno sin pistas de preguntas ni observaciones** | Las características van sin "(¿Qué ves?)", y desaparece la sección de observaciones. |
| **Reglas en tabla** | Condición, 1, 2, 3 y 4. La acción correcta lleva ✓ verde, la de mayor riesgo una **calavera** roja y las otras ✗ (pregunta 1). |
| **Cuadrícula del cuaderno más suave** | Las líneas oscuras bajan de opacidad. |
| **La noche 0 en el chat con León** | Sin entidades reales: describe a Gonzalo ("usa lentes", "huele mal"), con chistes y con una página propia del cuaderno, la única de esa noche. |
| **Qué enseña León** | Preguntar, marcar las características y abrir la página (pregunta 2); la mejor decisión y la peor, y si el jugador elige otra, León le dice que lo intente de nuevo; el video que manda después de la peor (pregunta 2); y la señal que se corta, que se arregla con Audio Sync. Al final dice que estás listo y se despide. |
| **Después, tarjetas con videos** | Los medidores y cómo baja cada uno, Sanity y el celular, la sombra en la ventana y la cortina, y la Mano con el flash. Cortas y claras. |
| **Se quitan el susto guionado y el chat de Gonzalo de la noche 0** | El chat queda guardado para la historia (pregunta 3). |
| **"Saltar tutorial" va en la pausa** | Y las tarjetas tienen su propio "Saltar" (pregunta 4). |

## Supuestos de Claude (Benja los corrige)

| Supuesto | Por qué |
| --- | --- |
| **Los tamaños nítidos:** la letra de 11 pasa a 15 a 1080p (22 px reales, el doble exacto), la de 33 pasa a 37 (55 px reales) y la de 22 y la de 66 se quedan, porque ya salen nítidas. En una ventana de 1280×720, en 1440p y en 4K, la letra queda igual. | Con 11 px, la letra no puede quedar nítida a 1080p: 11 × 1,5 = 16,5 píxeles reales, que no es múltiplo de su grilla de 11. Lo midió una prueba: con 15, todos los trazos miden 2, 4, 6… píxeles. |
| **La página de Gonzalo** tiene 4 acciones: ofrecerle desodorante, contarle un chiste, esconderle los lentes y pedirle una pizza. La tabla tiene 3 reglas: si está enojado, si tiene hambre y en cualquier otro caso. León cuenta que está enojado, como siempre. | Una tabla chica, con chistes, donde la ✓ y la calavera se distinguen enseguida. |
| **Un señuelo en el tutorial** ("anda con un polerón rojo"), y León bromea si se clickea. | Enseña los señuelos sin decirlos. |
| **Las tarjetas son 4**, cada una con un video de 6 a 8 s en bucle, recortado del juego a 640×360. | Un video por tema, sin escalar el pixel art. |
| **Al terminar las tarjetas se pasa directo a la noche 1**, sin la pantalla de "Práctica terminada". | Las tarjetas ya cierran el tutorial. |

---

## Tareas

### Tarea 1: La letra nítida (`PixelText`)

**Archivos:** `scripts/ui/pixel_text.gd` (nuevo), `project.godot` (autoload), `scripts/ui/phone_view.gd`, `scripts/ui/stat_bars.gd`, `scripts/ui/mixer_view.gd` y `test/test_pixel_text.gd` (nuevo).

- `static func crisp_size(base: int, scale: float) -> int`: de los tamaños entre `base × 0,7` y `base × 1,4`, los nítidos son los que cumplen `int(tamaño × escala) % 11 == 0`. De esos, elige el más cercano a `base × 4/3` si `base` es 11 (la letra común) o a `base` si es más grande, y en un empate el mayor. Si ninguno es nítido, devuelve `base`. Una escala menor que 1 cuenta como 1.
- `static func window_scale(window: Window) -> float`: el mínimo entre ancho / 1280 y alto / 720.
- `static func size(base: int) -> int`: `crisp_size` con la escala de la ventana principal. La usan los textos dibujados por código.
- **El autoload:**
  - al empezar, guarda los tamaños base de los 3 temas (chat, cuaderno y menús);
  - cuando cambia el tamaño de la ventana, aplica `crisp_size` a los temas y a cada Control con un tamaño de letra propio (guarda su base en un meta), y avisa con `changed`;
  - aplica lo mismo a cada nodo que entra al árbol.
- Los textos dibujados por código pasan de `FONT_SIZE` a `PixelText.size(FONT_SIZE)`.

- [x] **Paso 1:** pruebas en `test_pixel_text.gd`: `test_tamanos_nitidos` (a 1×, 1,5×, 2× y 3×, con 11, 22, 33 y 66), `test_escala_de_la_ventana` y `test_aplica_a_temas_y_nodos` (con `apply(1.5)` y de vuelta a `apply(1.0)`).
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y registrar el autoload.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "La letra en pixel art, nítida en cualquier pantalla".

### Tarea 2: El cuaderno con tabla

**Archivos:** `scripts/core/notebook_page.gd`, `tools/make_ui_art.py` (los íconos y la cuadrícula), `art/ui/mark_check.png`, `mark_cross.png`, `mark_risk.png` y `notebook_page.png`, `data/text/notebook.csv` y `test/test_notebook_page.gd`.

- **La página:** el folclore; **Características**, con solo su nombre; **Reglas**, en una tabla `[table=5]`: la condición y, por cada acción, su ícono; debajo, la leyenda de la calavera; y **Acciones**, numeradas del 1 al 4.
- **Los íconos:** 9×9 px en pixel art: ✓ verde lápiz, ✗ gris lápiz y una calavera roja. En la tabla van con `[img]`, del tamaño de la letra.
- **La cuadrícula:** `GRID` se mezcla más con el papel.
- **Textos:** `NOTEBOOK_RULES` ("Reglas: vale la primera fila que se cumpla"), `NOTEBOOK_CONDITION` ("Condición") y `NOTEBOOK_RISK_LEGEND` ("mayor riesgo: da un video extra"). Se quitan `NOTEBOOK_OBSERVATIONS`, `NOTEBOOK_CLUE_LINE` y `NOTEBOOK_RULE_ACTIONS`.

- [x] **Paso 1:** pruebas en `test_notebook_page.gd`: `test_pagina_completa` (reescrita), `test_la_tabla_marca_cada_accion`, `test_sin_preguntas_ni_observaciones` y `test_acciones_numeradas`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar, generar el arte (`/usr/bin/python3 tools/make_ui_art.py`) e importar.
- [x] **Paso 4:** correr todas las pruebas: OK. Revisar una captura del cuaderno.
- [x] **Paso 5:** commit "El cuaderno: las reglas en una tabla, sin pistas de preguntas".

### Tarea 3: La página de Gonzalo y la noche 0 nueva (datos)

**Archivos:** `data/tutorial/gonzalo.tres` (nuevo), `data/nights/night_0.tres`, `data/scripts/scare_chat.tres` (nuevo: el chat guionado que se guarda), `scripts/data/content_catalog.gd`, `scripts/core/content_validator.gd`, los CSV y las pruebas del catálogo y del validador.

- **`gonzalo.tres`:**
  - características: `glasses` (Vista, "Usa *lentes*, de los gruesos.") y `bad_smell` (Ambiente, "*Huele mal*. Pero mal mal."), cada una con 2 formas más y su nombre;
  - observación: `mood` (Vista), con `angry`, `hungry` y `fine`;
  - acciones: `deodorant`, `joke`, `hide_glasses` y `pizza`;
  - reglas: si está enojado, ✓ chiste y calavera esconderle los lentes; si tiene hambre, ✓ pizza y calavera desodorante; en cualquier otro caso, ✓ desodorante y calavera esconderle los lentes.
- **El señuelo** `red_hoodie` (Vista, "Anda con *un polerón rojo*."), que sirve solo en el lugar del tutorial.
- **`night_0.tres`:**
  - `new_entities = [gonzalo]`;
  - 1 solicitud fija: León, con Gonzalo enojado y sin pista;
  - sin susto guionado ni chat;
  - Audio Sync de 4 aplausos a 90 golpes por minuto.
- **`ContentCatalog.known_entities(0)`:** las páginas de la noche 0, si tiene; si no, las de la noche 1.
- **El validador** revisa las páginas de la noche 0 como cualquier entidad.

- [x] **Paso 1:** pruebas:
  - `test_catalog.gd`: `test_la_noche_0_solo_tiene_la_pagina_de_gonzalo`;
  - `test_night_and_catalog.gd`: las páginas conocidas en la noche 0;
  - `test_balance.gd`: que la noche 0 no tenga susto y tenga Audio Sync.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y escribir los textos.
- [x] **Paso 4:** correr todas las pruebas. Las del tutorial viejo fallan hasta la Tarea 5.
- [x] **Paso 5:** sin commit: va con la Tarea 5.

### Tarea 4: La conversación de León (`TutorialChat`, lógica pura)

**Archivos:** `scripts/core/tutorial_chat.gd` (nuevo) y `test/test_tutorial_chat.gd` (nuevo).

- **Pasos:** `ASK_SIGHT`, `MARK`, `ASK_AMBIENT`, `OPEN_PAGE`, `BEST`, `WORST`, `DOWNLOAD`, `SIGNAL`, `READY` y `DONE`.
- **Los métodos** reciben lo que pasó y cada uno devuelve un `Reply`:
  - `start()`;
  - `question_asked(category)`, `clue_marked(is_decoy)` e `identified()`;
  - `page_opened()`, `answered(outcome)`, `video_received()` y `signal_restored()`.
- **Un `Reply` trae:**
  - las líneas de León (`lines`, claves de `ui.csv`);
  - si la respuesta del jugador cuenta (`accept_answer`);
  - las órdenes para el juego: `send_video`, `cut_signal` y `finished`.
- **Lo que hace cada paso:**
  - **las respuestas:** en `BEST`, solo la correcta avanza, y cualquier otra devuelve la línea de "intenta de nuevo"; en `WORST`, solo la de mayor riesgo;
  - **el señuelo:** León bromea solo la primera vez que se clickea uno;
  - **la señal:** después del video, León avisa y pide `cut_signal`;
  - **el final:** al volver la señal, se despide y pide `finished`.

- [x] **Paso 1:** pruebas en `test_tutorial_chat.gd`:
  - `test_saluda_y_pide_preguntar`;
  - `test_la_pregunta_correcta_avanza`;
  - `test_falta_una_caracteristica`;
  - `test_el_senuelo_una_sola_vez`;
  - `test_abrir_la_pagina`;
  - `test_la_mejor_hasta_acertar`;
  - `test_la_peor_manda_el_video`;
  - `test_despues_del_video_se_corta_la_senal`;
  - `test_al_volver_la_senal_se_despide`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr `test_tutorial_chat.gd`: OK.
- [x] **Paso 5:** sin commit: va con la Tarea 5.

### Tarea 5: El tutorial en el escritorio

**Archivos:** `scripts/desk/request_manager.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` (sin `TutorialHint`), `scripts/ui/pause_menu.gd` y `scenes/ui/pause_menu.tscn` ("Saltar tutorial"), `scripts/autoload/game_state.gd`, `data/text/ui.csv`, y se borran `scripts/core/tutorial_guide.gd`, `scripts/ui/tutorial_hint.gd`, `scenes/ui/tutorial_hint.tscn` y `test/test_tutorial_guide.gd`.

- **`RequestManager`, en la noche 0:**
  - empieza la solicitud de León sin mensaje inicial, y `TutorialChat` escribe por León;
  - una respuesta que el tutorial no acepta no termina la solicitud: se ve la respuesta de Matías y León contesta;
  - cuando la peor se acepta, la solicitud termina sin consecuencias, León manda el video, después le corta la señal y, al volver, `tutorial_finished`.
- **El escritorio:**
  - quita `TutorialGuide`, el aviso de arriba y la Mano de la noche 0;
  - con `tutorial_finished`, muestra las tarjetas (Tarea 7).
- **La pausa:** en la noche 0, "Saltar tutorial" (`PAUSE_SKIP_TUTORIAL`).
- **Textos:** las líneas de León (`TUTORIAL_LEON_*`). Se quitan los `TUTORIAL_*` viejos que ya no se usan.

- [x] **Paso 1:** pruebas:
  - `test_tutorial_desk.gd` (reescrita): `test_el_tutorial_de_punta_a_punta` (con el chat de León: preguntar, marcar, abrir la página, equivocarse, la mejor, la peor, el video, la señal y el final), `test_sin_aviso_arriba`, y que el cuaderno solo tenga a Gonzalo;
  - `test_pause_menu.gd`: `test_saltar_tutorial_solo_en_la_noche_0`.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar y borrar lo viejo.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "La noche 0 en el chat con León, con la página de Gonzalo" (Tareas 3, 4 y 5).

### Tarea 6: Los videos de las tarjetas

**Archivos:** `test/record_tutorial_clips.gd` (nuevo), `tools/make_tutorial_videos.sh` (nuevo) y `video/tutorial/meters.ogv`, `phone.ogv`, `window.ogv` y `hand.ogv`.

- **`record_tutorial_clips.gd -- <clip>`** arma el escritorio y lo maneja, mientras el Movie Maker de Godot graba a 30 cuadros por segundo:
  - **`meters`:** una interferencia, un screamer y una respuesta incorrecta bajan Connection, Sanity y Trust;
  - **`phone`:** el celular abierto, con Sanity subiendo mientras se scrollea y la batería bajando;
  - **`window`:** la criatura y su sombra, la cortina que se cierra y se vuelve a abrir;
  - **`hand`:** la Mano que avanza hacia un dial, el celular que se abre y el flash.
- **`make_tutorial_videos.sh`** graba cada clip y lo recorta a 640×360, a 1:1, sin escalar el pixel art. Lo convierte a Theora (`-q:v 8`, sin audio) en `video/tutorial/`.

- [x] **Paso 1:** escribir los dos scripts.
- [x] **Paso 2:** grabar y convertir los 4 videos; revisar un cuadro de cada uno.
- [x] **Paso 3:** importar y comprobar que Godot los carga (`VideoStreamTheora`).
- [x] **Paso 4:** commit "Los videos de las tarjetas del tutorial".

### Tarea 7: Las tarjetas

**Archivos:** `scenes/ui/tutorial_cards.tscn` y `scripts/ui/tutorial_cards.gd` (nuevos), `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `data/text/ui.csv` y `test/test_tutorial_cards.gd` (nuevo).

- **Una tarjeta por tema:** el título, el video en bucle, de 1 a 4 frases cortas y "1 de 4". Usa el marco y los botones de los menús.
- **Los botones:** "Siguiente"; en la última, "Empezar la noche 1"; y "Saltar".
- **Al terminar o saltar:** `next_night_requested`, que lleva a la noche 1.
- **Textos:** `TUTORIAL_CARD_*_TITLE`, `TUTORIAL_CARD_*_TEXT`, `TUTORIAL_CARDS_NEXT`, `TUTORIAL_CARDS_START`, `TUTORIAL_CARDS_SKIP` y `TUTORIAL_CARDS_PAGE`.

- [x] **Paso 1:** pruebas en `test_tutorial_cards.gd`: `test_empieza_en_la_primera`, `test_siguiente_hasta_la_ultima`, `test_saltar_termina`, `test_cada_tarjeta_tiene_su_video` y `test_sus_textos_existen`. En `test_tutorial_desk.gd`: al terminar el chat aparecen las tarjetas.
- [x] **Paso 2:** correrlas y ver que fallan.
- [x] **Paso 3:** implementar.
- [x] **Paso 4:** correr todas las pruebas: OK.
- [x] **Paso 5:** commit "Las tarjetas con videos al final de la noche 0".

### Tarea 8: Revisión a 1080p

**Archivos:** `test/capture_plan92.gd` (nuevo) y lo que haya que corregir.

- Capturas a 1920×1080 y a 1280×720 de:
  - el chat y el cuaderno abiertos;
  - el chat de León en la noche 0;
  - una tarjeta;
  - el celular, el mixer, las barras y las entradas del PC;
  - el menú, la pausa, las opciones y la pantalla final.
- Corregir lo que no quepa con la letra más grande.

- [x] **Paso 1:** escribir el script y capturar.
- [x] **Paso 2:** revisar cada captura y corregir.
- [x] **Paso 3:** correr todas las pruebas: OK.
- [x] **Paso 4:** commit "Revisión a 1080p".

### Tarea 9: Documentos

`CLAUDE.md`, el diseño v2 (§5, §7, §12, §14 y §19), `docs/02` (§3, §6 y §9), `docs/04` (las secciones L y R, y una nueva para probar esto), `arte_pendiente.md`, `resumen.md` y `docs/00_log.md`.

- [x] **Paso 1:** actualizar los documentos.
- [x] **Paso 2:** commit "Documentos del Plan 9.2".

---

## Fuera de este plan

- Un boceto de Gonzalo para su página: si Benja lo dibuja (`arte_pendiente.md`).
- Grabar los videos con el arte final: `tools/make_tutorial_videos.sh` los vuelve a grabar cuando cambie el arte.
