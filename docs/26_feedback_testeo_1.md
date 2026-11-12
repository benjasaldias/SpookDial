# Feedback del primer testeo y plan de sesiones (S21h, S21i y S21j)

**Origen:** la primera prueba con un tester que nunca había visto el juego (11 de noviembre de 2026). Es jugador ocasional de Nintendo Switch y no conoce este estilo de juego. Benja no interrumpió la partida. El tester jugó la noche 0 y la noche 1.

**Qué es este documento:** las 16 observaciones del tester, ordenadas, con las decisiones que tomó Benja en S21g (8 preguntas) y el diseño de cada cambio. Se reparte en **3 sesiones de Opus 5.5 · xhigh**. Cada una cierra lo poco que queda abierto, escribe su plan (`docs/27`, `docs/28` y `docs/29`) y lo ejecuta en la misma sesión, como S21f.

**Regla de Benja para la dificultad:** todo cambio que baje la dificultad va a un modo **Normal**. Lo que hoy es el juego pasa a ser **Difícil**, salvo lo que se dice en cada punto.

---

## 1. Decisiones de Benja (S21g, 11 de noviembre)

| # | Tema | Decisión |
| --- | --- | --- |
| D1 | Dónde se elige la dificultad | **Solo al empezar** una partida nueva. **Difícil se desbloquea al terminar Normal** (ganar la noche 5). En el menú, "Continuar" muestra la dificultad de la partida guardada. |
| D2 | Alcance de Normal | **Una curva suave en las 5 noches.** La noche 1 se arma como pidió Benja (§3.2), y las noches 2 a 5 son algo más fáciles que hoy. Claude propone los valores (§3.3), y `test_balance` comprueba los dos modos. |
| D3 | Cómo se identifica en Difícil | **Nada destacado:** ni amarillo ni azul, nada se clickea y Matías no piensa. Se reconoce a la criatura leyendo y se busca su página en el índice del cuaderno. Los señuelos quedan como texto que confunde. |
| D4 | Costo de los señuelos | **Se quita en los dos modos.** Un señuelo solo vibra y se pone rojo. Reemplaza al "−1 s" del 11 de noviembre. |
| D5 | Inicio de Difícil | **Una partida en Difícil empieza en la noche 1**, sin tutorial. |
| D6 | Gonzalo en el tutorial | **Demostración guiada:** tras la mejor y la peor decisión, el chat de Gonzalo muestra 15 s que corren de verdad, con los botones bloqueados. Al llegar a 0, Gonzalo decide solo, elige mal y sale el aviso de daño (sin efecto real). León lo explica y el tutorial sigue con él. |
| D7 | Lo demás de la noche 1 en Normal | **Sin accidente**, con 1 interferencia en la segunda ola y los 2 screamers en las calmas. Los accidentes llegan desde la noche 2 en Normal. |
| D8 | Orden | Estas sesiones van **antes del lore (S21b)**. |

### Cambios que valen en los dos modos

No son de dificultad, sino de claridad o errores:

- las preguntas ya hechas se bloquean y se ve lo que cuesta cada una (§2.1);
- el chat se rediseña (§2.3);
- el botón de sincronizar parpadea si el amigo no tiene señal (§2.3);
- "Matías piensa" dura menos (§2.4);
- los señuelos no cuestan (D4);
- el botón de descarga funciona al primer clic y la partida se guarda al ganar (§2.5 y §2.6);
- todo el tutorial (§4), que solo se juega en Normal (D5).

---

## 2. Sesión S21h: errores y el chat (Plan 9.3, `docs/27`)

**✅ Ejecutada el 11 de noviembre** (S21h, `docs/27`): 11 commits, 661 pruebas OK. Lo que cambió al ejecutar (las respuestas en una columna, el parlante en vez de la oreja y la causa real de la descarga) está al inicio de `docs/27`.

**Modelo:** Opus 5.5 · xhigh. **Va primero** porque el tutorial (S21j) usa los botones nuevos y el parpadeo, y Difícil (S21i) apaga los colores que se agregan aquí.

### 2.1 Las preguntas: lo que cuestan y no repetirlas (observación 1)

**El tester:** no se entendía que preguntar quita tiempo, y se podía repetir una pregunta ya hecha.

**Diseño:**

- Cada botón de pregunta muestra su costo ("−5 s"), y al pulsarlo la pestaña del amigo muestra "−5 s" unos segundos, como antes mostraba el costo del señuelo.
- **Una pregunta ya respondida se bloquea** y queda marcada (✓, más tenue).
- **Excepción:** si la estática tapó algo de esa respuesta (una frase, una observación o el audio), el botón vuelve a habilitarse con un ícono de estática, porque la regla del 15 de octubre dice que hay que volver a preguntar para recuperar lo tapado. Esto ya cumple el pendiente "marcar en el chat qué categorías ya se preguntaron".
- Las preguntas se guardan por solicitud (`FriendRequest.asked: Dictionary[ClueCategory.Kind, bool]` y si su respuesta salió tapada). Es lógica pura y se prueba primero.

### 2.2 Las características decisivas en azul (observación 7)

**El tester:** no había una división clara entre lo que describe a la criatura y lo que decide qué hacer en la tabla.

**Diseño:**

- **Amarillo** (como hoy): las características y los señuelos, que se clickean.
- **Azul, nuevo:** las **observaciones** (lo que decide la fila de la tabla: "Está enojado", "1 grito"), que **no se clickean**. El mensaje de un audio también va en azul, porque es una observación.
- En el cuaderno, la columna **Condición** de la tabla usa el mismo azul, para que el jugador conecte las dos cosas. Está por confirmar en la sesión: es una pregunta corta.
- Elegir el azul: tiene que leerse sobre el fondo oscuro, no confundirse con el azul de Gonzalo ni con el cian de Matías, y respetar la paleta (`art/ui/`).
- En esta sesión el azul se aplica siempre. S21i lo apaga en Difícil, junto con el amarillo y los clics (D3).
- `ChatMessage.Token` necesita saber que es una observación (un tipo o una marca), y `MessageBuilder.answer()` la marca.

### 2.3 El chat, más claro (observación 5)

**El tester:** hay mucho texto y botones iguales, y no se distingue para qué sirve cada uno.

**Diseño:** cada tipo de control con su propia forma, en pixel art de Claude (`tools/make_ui_art.py`, con la paleta de los sprites):

| Control | Hoy | Nuevo |
| --- | --- | --- |
| Preguntas | 4 botones de terminal, iguales a todo | Botones de terminal con un ícono de 9×9 por categoría (ojo, oreja, nube y huella), el costo y su estado (✓ o estática). |
| Respuestas | 4 botones de terminal | **Hojas del cuaderno**: papel cuadriculado con el **número de la columna de la tabla** (1 a 4) en una nota adhesiva y la acción escrita. Se ven como parte del cuaderno, no del chat. |
| Sincronizar | Botón con texto "SINCRONIZAR" | **Botón cuadrado con un ícono de señal** (las barritas del wifi) que muestra la señal de ese amigo: de 0 a 4 barras, en verde, ámbar o rojo. **Parpadea si el amigo tiene 0 de señal** (y en el tutorial, cuando León lo pide). Con "Reducir destellos", un borde fijo en vez del parpadeo. |
| Nombre de la entidad | Botón de texto | Botón con un ícono de cuaderno, para que se entienda que abre su página. |
| Avisos | "Abre el cuaderno para responder", etc. | Más cortos, y con el mismo estilo que el título de su sección ("PREGUNTAR" y "RESPONDER"). |

**Esquema de referencia** (la sesión lo ajusta con capturas a 1280×720 y 1080p):

```
┌ LEÓN 42 • │ GONZALO │ AGUSTÍN ──────────┐
│ LEÓN: ¡Mati, ayuda!! Me perdí.           │
│ MATÍAS: ¿Qué ves?                        │
│ LEÓN: Veo un hombrecito (amarillo).      │
│       Está enojado (azul).               │
│ ▼ VIDEO  ███████░░░  60 %   15 s         │
├──────────────────────────────────────────┤
│ Matías piensa…           [cuaderno]  [▂▄▆█] │  ← identificación · sincronizar
│ PREGUNTAR  −5 s cada una                 │
│ [ojo ¿QUÉ VES? ✓]   [oreja ¿QUÉ OYES?]   │
│ [nube ¿AMBIENTE?]   [huella ¿HUELLAS?]   │
│ RESPONDER · EL TRAUCO                    │
│ ┌1┐ Quedarse quieto   ┌2┐ Correr         │  ← hojas del cuaderno
│ ┌3┐ Prender fuego     ┌4┐ Gritarle       │
└──────────────────────────────────────────┘
```

**El parpadeo, una pieza reutilizable:** un `Highlight` (un nodo o un helper de UI) que hace parpadear cualquier `Control` o sprite del escritorio con un borde, y que respeta "Reducir destellos". Lo usan el botón de sincronizar sin señal y, en S21j, el tutorial.

### 2.4 "Matías piensa" más corto (observación 8)

- `FriendRequest.THINKING_TIME` pasa de **3 a 2 s**, y conviene moverlo a `BalanceData` (`thinking_seconds`) para que se ajuste en el Inspector, por la regla 7.

### 2.5 La descarga que no responde al primer clic (observación 10)

**El tester:** a veces mantener presionada la barra no hace nada al primer clic.

- Se diagnostica con `superpowers:systematic-debugging`, reproduciendo el clic con un `InputEventMouseButton` simulado en una prueba antes de arreglarlo.
- Hipótesis que hay que revisar, de la lectura del código:
  1. Cuando aparece el video, `Download` se hace visible y `Conversations` se acorta en `_process` (`CONVERSATION_BOTTOM_WITH_DOWNLOAD`). En ese primer frame, el `ScrollContainer` de la conversación todavía tapa la barra y se come el clic.
  2. `_select()` y `visibility_changed` sueltan la descarga (`_holding_download = false`). Si el clic en la barra también cambia de pestaña o de visibilidad, el `button_down` se pierde.
  3. El orden de `_process`: `_update_download()` pone `state.holding_download` en el frame siguiente al `button_down`.
- **Aceptación:** una prueba que presiona la barra apenas aparece el video y comprueba que `state.holding_download` queda en ese amigo.

### 2.6 La noche ganada no se guarda al volver al menú (observación 11)

- Hoy solo se guarda al comienzo de cada noche (`GameState.prepare_night`). Si se gana y se aprieta "Volver al menú", "Continuar" vuelve a la noche ya ganada.
- **Arreglo:** en `GameState._on_night_ended`, al ganar, guardar la noche siguiente. También se guarda la noche 1 cuando León se despide en la noche 0, para que salir en las tarjetas no obligue a repetir el tutorial. Desde S21i, se guarda también la dificultad.
- Prueba primero, con `SaveGame` sobre un archivo temporal.

### 2.7 Los señuelos ya no cuestan (D4)

- `BalanceData.decoy_cost` queda en 0 y se borran el "−1 s" del chat (`CHAT_DECOY_COST`) y la mención en la línea de León (`TUTORIAL_LEON_DECOY`: "…y te costó un segundo").
- Conviene quitar el campo y su código, y no solo dejarlo en 0. La sesión decide.

**Terminada cuando:** todas las pruebas pasan, las capturas del chat (con video, con estática, sin señal y con la página abierta) se revisaron a 1280×720 y a 1080p, y la letra sigue nítida.

---

## 3. Sesión S21i: Normal y Difícil (Plan 9.4, `docs/28`)

**✅ Ejecutada el 11 de noviembre** (S21i, `docs/28`): 11 commits, 715 pruebas OK. Lo que decidió Benja en la sesión (el audio en azul en Difícil, el cuaderno igual y la ola final con consulta, video y consulta) y lo que cambió al ejecutar (14 s por consulta en el modelo de Difícil) están al inicio de `docs/28`.

**Modelo:** Opus 5.5 · xhigh.

### 3.1 La estructura de la dificultad

**Propuesta (la sesión la confirma con el código):**

- Un recurso nuevo, `DifficultyData` (`data/difficulty/normal.tres` y `hard.tres`), editable en el Inspector:
  - su nombre (`name_key`, en `ui.csv`);
  - sus 5 noches (`nights: Array[NightData]`), porque cada modo tiene las suyas;
  - la noche en que empieza (0 en Normal y 1 en Difícil, D5);
  - cómo se identifica: **guiada** (amarillo, azul, clics y "Matías piensa") o **leyendo** (nada destacado, D3).
- Los `.tres` actuales pasan a `data/nights/hard/` y los de Normal van en `data/nights/normal/`. La noche 0 es una sola.
- `ContentCatalog` recibe la dificultad y entrega las noches que corresponden. Hay que revisar `known_entities`, `new_pages`, `night()` y `test_catalog`.
- **El progreso**, aparte de la partida: un archivo propio (`user://progress.cfg`) con "terminó Normal", porque `save.cfg` se borra al ganar la noche 5.
- `SaveGame` guarda la noche y la dificultad. Una partida vieja sin dificultad se lee como Normal.

### 3.2 La noche 1 en Normal, armada a mano (observación 12)

**El tester:** la noche 1 trae demasiado para alguien que todavía está aprendiendo.

**Lo que pidió Benja:**

| Ola | Qué trae |
| --- | --- |
| 1 | **1 consulta**. Un poco después, el video, cuando a la consulta le queda poco tiempo, para que no llegue todo junto. |
| 2 | **1 o 2 consultas, no juntas**, más la Mano. Por D7, también 1 interferencia. |
| Final | **2 consultas y un video, no juntos**, separados por menos tiempo que el máximo para responder una consulta. |

En las calmas van los 2 screamers. No hay accidente (D7).

**Diseño:**

- `NightData` recibe un plan de olas opcional, `wave_plan: Array[WaveData]`. Si está vacío, el director arma las olas solo, como hoy. Así las noches 2 a 5 de Normal y todas las de Difícil no cambian de mecanismo.
- `WaveData` (recurso nuevo, editable): las consultas, su separación (`request_spacing: Vector2`), la Mano, las interferencias, los accidentes, los screamers de la calma que sigue y **los videos de la ola**, con cuándo llegan: "cuando a la primera consulta le quedan N s" (propuesta: 30 s) o, si ya se respondió, unos segundos después.
- La separación de la ola 2 y de la final, por ejemplo de 30 a 45 s con 90 s para responder, cumple "menos que el máximo por consulta".
- Hoy el director suelta los videos solo en las calmas, y `test_balance` comprueba que ninguno caiga sobre la ola final. Hay que extender `PacingDirector`, `VideoSchedule`, `balance_model.gd` y `dump_waves.gd` a los videos dentro de una ola, y revisar la curva con `tools/plot_waves.py`.
- **Valores de partida:**
  - 5 consultas (1 + 2 + 2);
  - 90 s para responder;
  - el primer silencio de 45 s (hoy 60);
  - una calma de 30 a 45 s después de la ola 1;
  - la cuota de 2, que dan los 2 videos programados.

  Benja puede dejar la ola 2 en 1 consulta desde el Inspector.

### 3.3 Las noches 2 a 5 en Normal (D2)

Son valores de partida que propone Claude. La sesión los confirma con `test_balance` y con la curva de olas, y Benja los ajusta en las pruebas (S22).

| Valor | Difícil (hoy) | Normal (propuesta) |
| --- | --- | --- |
| Segundos para responder | 80, 65, 55, 50, 45 | **90, 80, 70, 65, 60** |
| Consultas por noche | 7, 7, 9, 9, 11 | **5, 6, 7, 8, 9** |
| Ola final | 3 en todas | **2, 2, 2, 3, 3** |
| Señuelos por consulta | 1, 2, 3, 3, 4 | **1, 1, 2, 2, 3** |
| Pista en el mensaje inicial | 100, 75, 0, 0, 0 % | **100, 100, 75, 50, 35 %** |
| Lugar en el mensaje inicial | 60, 55, 50, 45, 40 % | **80, 75, 70, 65, 60 %** |
| Accidentes | 1, 1, 2, 2, 3 | **0, 1, 1, 2, 2** |
| Interferencias | 1, 3, 3, 4, 6 | **1, 2, 2, 3, 4** |
| La Mano | 1, 1, 2, 2, 3 | **1, 1, 1, 2, 2** |
| La criatura | 0, 1, 2, 2, 3 | **0, 1, 1, 2, 2** |
| Audio Sync (golpes por minuto) | 90, 100, 115, 130, 145 | **90, 95, 105, 115, 125** |
| Audio Sync (aplausos) | 4, 4, 4, 8, 8 | **4, 4, 4, 4, 8** |
| Cuota de videos | 2, 3, 3, 4, 4 | **2, 2, 3, 3, 4** (la comprueba `test_balance`) |
| Screamers | 2, 4, 4, 5, 6 | Iguales: son el terror, no la dificultad. |

`BalanceData` es uno solo para los dos modos. Si la sesión ve que un valor global también debería cambiar en Normal (por ejemplo, `wave_calm`), lo propone como pregunta corta.

### 3.4 Difícil: se identifica leyendo (D3)

- No hay amarillo ni azul, nada se clickea, no hay barra de identificación y Matías no piensa. Las preguntas siguen igual.
- Se abre la página **a mano desde el índice del cuaderno**. Los botones de respuesta ya dependen de la página abierta para ese amigo, así que no cambian.
- La memoria del cuaderno sigue volviendo al índice con cada consulta nueva (30 de octubre).
- `test_balance` necesita un modelo de "jugar bien" sin clics: el tiempo para leer y abrir la página en vez de marcar y esperar a Matías. La sesión propone cuántos segundos.

### 3.5 El menú

- **"Nueva partida"** abre una elección: Normal (marcado) y Difícil. Difícil aparece con candado y el texto "Termina Normal para desbloquearla" mientras no se haya ganado la noche 5 en Normal.
- **"Continuar"** muestra la noche y la dificultad ("Continuar · Noche 3 · Normal"). Texto en `ui.csv`.
- Al ganar la noche 5 en Normal, la pantalla final avisa que se desbloqueó Difícil.
- Si hay una partida guardada y se elige "Nueva partida", conviene confirmar antes de borrarla, si hoy no se hace. La sesión lo revisa.

**Terminada cuando:**

- `test_balance` pasa en los 2 modos, con las 5 noches cada uno;
- la curva de la noche 1 en Normal se ve como la tabla de §3.2 (`dump_waves` y `plot_waves`);
- el menú se revisó con capturas;
- se puede jugar una noche de Difícil sin clics.

---

## 4. Sesión S21j: el tutorial (Plan 9.5, `docs/29`)

**Modelo:** Opus 5.5 · xhigh. Usa lo de S21h (el parpadeo, el ícono de señal y las respuestas nuevas). Solo se juega en Normal (D5).

### 4.1 Lo que se puede usar en la noche 0 (observación 4)

**El tester:** es raro poder usarlo todo desde el principio.

- En la noche 0 solo se usan **el chat** y lo que León va enseñando:
  - el cuaderno, cuando pide abrir la página;
  - la entrada de Gonzalo, en su parte;
  - el mixer, cuando pide sincronizar.
- El celular, las cortinas, el mixer antes de tiempo, el cuaderno antes de tiempo y las otras entradas del PC no responden: no se iluminan al pasar el mouse ni al hacer clic.
- La pausa con Esc sigue funcionando, porque ahí está "Saltar tutorial".
- Desde la noche 1, todo como hoy.
- **Diseño:** un conjunto de "desbloqueados" en el escritorio. `ClickableSprite` y `ChatEntry` reciben un `enabled`. `TutorialChat.Reply` dice qué se desbloquea en cada paso, como hoy dice `send_video` o `cut_signal`.

### 4.2 Parpadea lo que hay que apretar (observaciones 5 y 6)

- **Cada vez que León pide apretar algo, eso parpadea** (el `Highlight` de S21h) hasta que se aprieta:
  - el botón de la pregunta que pide;
  - las frases que hay que marcar;
  - el nombre de la entidad;
  - las 4 hojas de respuesta (todas, para no regalar la correcta);
  - la barra de descarga;
  - el botón de sincronizar;
  - en el mixer, la zona donde se hace clic para seguir el ritmo.
- `TutorialChat.Reply` recibe un `highlight` (un id) que `RequestManager` y el escritorio traducen al control.

### 4.3 La conversación nueva de León

El orden propuesto. Las líneas nuevas las escribe Claude como borrador y Benja las corrige (regla 8).

1. **Saludo y "pregúntame qué veo"**, con "¿Qué ves?" parpadeando.
2. **El costo de preguntar (observación 2):** después de la primera pregunta, León dice algo como *"Ojo: cada pregunta te cuesta 5 segundos. Tienes que saber qué preguntar: haz solo las necesarias."*
3. **Marcar** lo amarillo. El chiste del polerón ya no habla de un segundo (D4).
4. **Lo azul (§2.2):** León explica que lo azul no se clickea, pero decide qué hacer en la tabla.
5. **El audio (observación 9):** León pide preguntar "¿Qué oyes?" y manda un **audio**: las tripas de Gonzalo, que pasan de "ambiente" a "sonido" con su audio. Hay que escucharlo con un clic; el mensaje del audio parpadea.
   - El sonido nuevo se genera con `tools/make_sounds.py` y se anota en `sonidos_pendiente.md`. Ningún sonido dice palabras.
   - La pregunta del ambiente sigue para la segunda característica.
6. **El nombre y la página**: el nombre parpadea, y el cuaderno se desbloquea.
7. **La mejor y la peor decisión**, como hoy, con las 4 hojas parpadeando.
8. **El video**, con la barra parpadeando.
9. **Gonzalo y el tiempo que se acaba (observación 3, D6):**
   - León avisa que Gonzalo le está escribiendo.
   - La entrada de Gonzalo se desbloquea y parpadea.
   - En su chat, Gonzalo pide ayuda con un **temporizador real de 15 s**, y las respuestas están bloqueadas (con un aviso: *"Mira qué pasa si no contestas"*).
   - Al llegar a 0, Gonzalo **decide solo y elige mal**, y sale el aviso de daño ("Gonzalo recibió daño: 2/3"). No tiene efecto real: la noche 0 no tiene consecuencias.
   - Después parpadea la entrada de León, y él explica: *"Si no contestas a tiempo, deciden solos, casi siempre mal, y baja Trust."*
   - Hace falta una segunda `TutorialRequestData`, la de Gonzalo, con su propia lógica: no se puede responder, el temporizador corre y nadie sale herido de verdad.
10. **La estática (observación 16):**
    - La señal de León baja a unos 30 y escribe un mensaje con palabras tapadas. La estática es **fija** en el tutorial, no al azar, para que siempre se vea.
    - Después explica: *"Con poca señal mis mensajes llegan tapados."*
11. **La señal se corta:** León dice que hagan clic en **el botón de las barritas** para sincronizarlo, y ese botón parpadea. En el mixer, parpadea lo que hay que apretar.
12. **La despedida**, y las tarjetas.

**Pendiente menor que se resuelve aquí:** si el jugador pregunta muy rápido, las líneas de León llegan después de las respuestas. Con el parpadeo y los desbloqueos, conviene que los botones se habiliten cuando León termina de escribir.

### 4.4 El botón del flash y su video (observación 13)

**El tester:** el rayo del celular no parece un botón.

- El rayo pasa a ser un **botón con relieve** (pixel art de Claude): un borde, una sombra y un estado presionado, con el rayo y quizás la palabra "FLASH".
- El video de la tarjeta de la Mano se vuelve a grabar (`test/record_tutorial_clips.gd` y `tools/make_tutorial_videos.sh`, con el editor cerrado). Tiene que mostrar el celular asomando y **el botón presionándose**.
- El Movie Maker no graba el cursor del sistema, así que el script de grabación dibuja un cursor de mentira que va al botón y lo aprieta.

### 4.5 Las tarjetas con colores (observación 14)

- Los textos de las tarjetas pasan de `Label` a `RichTextLabel` con BBCode.
- **Connection en verde, Sanity en rojo y Trust en amarillo** (el color de su aguja, decisión del 31 de octubre), y lo importante destacado.
- **Departure Mono no tiene negrita.** Hay que probar:
  - una `FontVariation` con `variation_embolden`, revisando que la letra siga nítida (regla de los múltiplos de 11 px);
  - o, si no, destacar con color y mayúsculas.
- Los colores de cada medidor se toman de un solo lugar (los de las barras y los diales), no se repiten en el CSV. Por ejemplo, con etiquetas propias que se reemplazan al mostrar el texto.

**Terminada cuando:**

- la noche 0 se juega completa en una prueba automática que sigue los pasos (como `test_tutorial_chat`);
- los videos se volvieron a grabar;
- las capturas de cada paso se revisaron;
- `docs/04` tiene la sección para que Benja lo pruebe.

---

## 5. Cómo abrir cada sesión

| Sesión | Qué escribirle a Claude |
| --- | --- |
| S21h | `Lee docs/26_feedback_testeo_1.md y haz la sesión S21h.` |
| S21i | `Lee docs/26_feedback_testeo_1.md y haz la sesión S21i.` |
| S21j | `Lee docs/26_feedback_testeo_1.md y haz la sesión S21j.` |

### Instrucciones comunes para las 3 sesiones

**Antes de preguntar nada, lee:**

- `CLAUDE.md` completo, `docs/00_log.md` y la entrada más reciente de `resumen.md`;
- este documento completo (las decisiones de §1 no se vuelven a discutir);
- el código de tu sesión.
  - **S21h:** `scripts/ui/chat_panel.gd`, `chat_message_view.gd`, `notebook_panel.gd`, `scripts/core/friend_request.gd`, `message_builder.gd`, `chat_message.gd`, `chat_static.gd`, `scripts/desk/request_manager.gd`, `scripts/autoload/game_state.gd`, `scripts/core/save_game.gd`, `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres` y `tools/make_ui_art.py`.
  - **S21i:** `scripts/core/pacing_director.gd`, `video_schedule.gd`, `request_generator.gd`, `scripts/data/night_data.gd`, `balance_data.gd`, `content_catalog.gd`, `scripts/autoload/game_state.gd`, `scripts/ui/main_menu.gd`, `end_screen.gd`, `test/balance_model.gd`, `test/test_balance.gd`, `test/dump_waves.gd` y `data/nights/*.tres`.
  - **S21j:** `scripts/core/tutorial_chat.gd`, `scripts/desk/request_manager.gd`, `desk.gd`, `clickable_sprite.gd`, `scripts/ui/chat_entry.gd`, `mixer_view.gd`, `phone_view.gd`, `phone_icons.gd`, `tutorial_cards.gd`, `data/tutorial/`, `data/nights/night_0.tres`, `test/record_tutorial_clips.gd` y `tools/make_tutorial_videos.sh`.

**Skills:**

| Skill | Para qué |
| --- | --- |
| `superpowers:brainstorming` | Solo lo que quede abierto, una pregunta a la vez, con opciones y una recomendada. Sé breve: casi todo ya está decidido. |
| `superpowers:writing-plans` | El plan de la sesión (`docs/27`, `docs/28` o `docs/29`), con tareas chicas y conteos de pruebas. |
| `superpowers:test-driven-development` | Cada cambio de lógica pura entra con su prueba primero. |
| `superpowers:systematic-debugging` | **S21h:** el botón de descarga (§2.5), antes de tocar el código. |
| `superpowers:executing-plans` | Ejecutar el plan en la misma sesión, con un commit por tarea. |
| `superpowers:verification-before-completion` | Pruebas, capturas a 1280×720 y 1080p, y el juego abierto sin errores, antes de dar algo por terminado. |
| `godot:godot-ui-control` y `disciplines:game-ui-ux` | **S21h y S21j:** el chat, los botones, el parpadeo y el menú. |
| `disciplines:create-game-assets` | **S21h y S21j:** el pixel art nuevo (íconos, hojas de respuesta, botón de señal y botón del flash). |
| `disciplines:level-design` | **S21i:** la curva de tensión y calma de la noche 1 en Normal y de la curva Normal. |
| `godot:godot-resources` | **S21i:** `DifficultyData` y `WaveData`, editables en el Inspector (regla 7). |
| `disciplines:save-systems` | **S21i:** la dificultad en la partida, el archivo de progreso y las partidas viejas. |
| `disciplines:audio-design` | **S21j:** el audio de las tripas. |
| `godot:godot-gdscript-headless-testing` | Correr `test/run_tests.gd` sin abrir el editor. |

**Reglas:**

- **Commits:** pregunta a Benja al empezar si autoriza los commits de toda la sesión (regla 11). Nunca hagas push sin su permiso.
- **Textos:** borradores reales en `data/text/*.csv`, sin marcas, cortos y en primera persona cuando habla un amigo. Al cerrar, lista las claves nuevas para que Benja las corrija.
- **Arte:** todo el pixel art nuevo va en `art/ui/` y lo genera `tools/make_ui_art.py`. Los `.aseprite` y PNG de Benja no se tocan.
- **Si el plan no alcanza a ejecutarse completo:** la sesión siguiente lo continúa (✏️ en `docs/00_log.md`) antes de pasar a la que sigue.
- **Al cerrar** (regla 4):
  - `resumen.md`, `docs/00_log.md` y `docs/04` (una sección de prueba para Benja);
  - `CLAUDE.md` y el diseño v2, con las decisiones de §1 que la sesión implementó. Este documento no reemplaza al diseño: la sesión que implementa una decisión la pasa a `spook_dial_design.md`, con sus valores;
  - `docs/02` §3 y §6 (S21i: los valores de Normal);
  - `arte_pendiente.md` y `sonidos_pendiente.md`, con lo nuevo de Claude que Benja puede redibujar o cambiar.

---

## 6. Las 16 observaciones y dónde se resuelven

| # | Observación del tester | Dónde | Modo |
| --- | --- | --- | --- |
| 1 | No se entiende que preguntar quita tiempo; las preguntas se pueden repetir | S21h §2.1 | Ambos |
| 2 | León debe decir que cada pregunta cuesta tiempo | S21j §4.3 (paso 2) | Tutorial |
| 3 | El tutorial no muestra qué pasa si se acaba el tiempo (Gonzalo) | S21j §4.3 (paso 9) | Tutorial |
| 4 | En la noche 0 se puede usar todo desde el principio | S21j §4.1 | Tutorial |
| 5 | El chat es engorroso; respuestas y sincronizar con otro diseño; el ícono de señal | S21h §2.3; el tutorial, en S21j §4.2 | Ambos |
| 6 | En el tutorial, parpadea lo que hay que apretar | S21j §4.2 | Tutorial |
| 7 | Separar lo decisivo (azul) de lo descriptivo (amarillo); en Difícil, nada | S21h §2.2 y S21i §3.4 | Normal / Difícil |
| 8 | "Matías piensa" es largo | S21h §2.4 | Ambos |
| 9 | El tutorial no enseña los audios | S21j §4.3 (paso 5) | Tutorial |
| 10 | La descarga a veces no responde al primer clic | S21h §2.5 | Ambos |
| 11 | La noche ganada no se guarda al volver al menú | S21h §2.6 | Ambos |
| 12 | La noche 1 es demasiado intensa | S21i §3.2 | Normal |
| 13 | El botón del flash no parece botón; mostrarlo en el video | S21j §4.4 | Ambos |
| 14 | Las tarjetas: colores y negrita | S21j §4.5 | Tutorial |
| 15 | El costo del señuelo castiga demasiado | S21h §2.7 | Ambos (D4) |
| 16 | El tutorial no muestra palabras tapadas por la estática | S21j §4.3 (paso 10) | Tutorial |

## 7. Alcance (regla 6)

- Normal y Difícil es alcance nuevo, pedido por Benja tras la prueba. Entra antes de la v1 porque sin él la prueba con personas (S22) mediría un juego que un jugador ocasional no puede aprender.
- Las 3 sesiones caben antes del congelamiento del contenido (25 de noviembre), junto con S21b.
- Si el calendario se aprieta, lo primero que se puede recortar es la curva Normal de las noches 2 a 5: se puede dejar igual que Difícil, salvo la noche 1. Después, la regrabación del video del flash.
