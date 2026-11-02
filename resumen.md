# Resumen de sesiones — Spook Dial

La entrada más reciente va arriba, y sus listas de pendientes son la lista vigente. En cada cierre se arrastran los pendientes que siguen abiertos y se marcan con [x] los cumplidos.

---

## Sesión 14 — 31 de octubre al 2 de noviembre de 2026 — Plan 6 escrito: mantenimiento

Benja pidió escribir el Plan 6 con `superpowers:writing-plans`, con tres preferencias suyas: Audio Sync en un mixer visto desde arriba, con sonido y que se empieza con un clic; los videos descargados en el chat, con tiempos nuevos; y un celular provisional atractivo. Se escribió en Opus 5.5, justo después de S13 (la fecha objetivo era el 12 de noviembre). La sesión se cortó una vez por falta de créditos, sin pérdidas.

### Realizado

- **Nuevo `docs/13_plan_mantenimiento.md`:** el Plan 6 en 17 tareas con código completo. Lleva las pruebas de 251 a 326:
  - lógica pura en `scripts/core/`: la señal de cada amigo (`FriendState`), las interferencias (`InterferenceSchedule`), los videos que esperan su descarga (`VideoSchedule`), la noche (`NightState`: Trust con amigos sin señal y Sanity al scrollear) y una ronda de Audio Sync (`AudioSyncRound`);
  - las reglas de un amigo sin señal, y los avisos de la noche en el chat: el video que manda un amigo, el que se recibe o se pierde, y la señal que se pierde o vuelve;
  - las entradas del PC con 5 barras de señal, el parpadeo de una interferencia, "Sin señal" y "Video 12";
  - la barra de descarga en el chat, que se mantiene presionada, y el botón «Sincronizar», que abre el mixer en el canal del amigo;
  - el mixer visto desde arriba (dos VU-metros azules, las luces del ritmo y un fader por amigo) y el celular (un feed de 12 publicaciones que se repite sin fin), los dos provisionales y dibujados en Godot;
  - 7 sonidos provisionales que genera `tools/make_placeholder_sounds.py`: la base (bombo y platillo), el aplauso del amigo, el golpe de Matías, el acierto, el error y la estática;
  - las publicaciones del celular como datos (`PhonePostData`), con sus textos en un CSV nuevo, `data/text/phone.csv`;
  - la sección J de `docs/04` (probar el mantenimiento) y los arreglos a C, G, H e I, que se aplican al ejecutar el plan.
- **Decisiones de Benja** (en `CLAUDE.md`, el diseño v2 §6, §8.7 y §10, y `docs/02` §2, §4, §4.1, §5.2 y §6):
  - **Audio Sync en el mixer visto desde arriba**, que Benja va a dibujar: el VU-metro azul de la izquierda muestra el ritmo de Matías, y el de la derecha, el del amigo. Una base marca el tiempo, el amigo aplaude un ritmo y Matías lo imita con clics o con la barra espaciadora. Se empieza con un clic en el mixer;
  - **«Sincronizar» desde el chat:** Benja propuso un botón en el chat del amigo, y Claude lo recomendó en lugar de elegir el canal desde la entrada del PC (que habría hecho dos cosas con el mismo clic). Abre el mixer en el canal de ese amigo y empieza la ronda. La entrada del PC siempre abre el chat;
  - **los videos se descargan en el chat**, manteniendo presionada su barra: 15 s para empezar (antes eran 10), 20 s para terminar desde que empieza y 10 s de descarga; con la señal bajo 50, 15 s (recomendado por Claude), y sin señal, no avanza;
  - **un amigo sin señal:** Benja propuso que eligiera mal, con su mensaje tapado entero y Trust bajando mientras esté desconectado. Claude completó lo que faltaba y Benja lo confirmó: le siguen llegando situaciones, decide cuando se le acaba el tiempo (así se puede reconectar antes), elige al azar una de las 3 acciones que no son la correcta, con el daño de siempre y sin que esa decisión baje Trust, y mientras haya amigos sin señal, Trust baja 1 punto cada 4 s por cada uno y no se recupera;
  - **el celular es provisional** hasta que Benja lo anime.
- **El plan se verificó en Godot 4.7.2:**
  - todo su código se ejecutó en una copia aparte, con 326 pruebas OK, sin errores al correr, y tres capturas revisadas: `C:\dev\capturas\plan6_mixer.png` (el mixer en una ronda), `plan6_download.png` (la descarga de un video, con el botón «Sincronizar») y `plan6_phone.png` (el celular);
  - después, un script aplicó el plan **tal como está escrito** a una copia limpia: los 34 conteos de pruebas coinciden, incluidas las fallas esperadas, todos los bloques a reemplazar aparecen una sola vez, y el código resultante es idéntico al probado, también los sonidos. Se validó dos veces: antes y después de agregar el botón «Sincronizar»;
  - además, el plan final se volvió a aplicar (sin Godot) al último commit del proyecto, con el mismo resultado;
  - las copias ya se borraron.
- El código del plan lo armó un script que toma cada bloque de los commits de la copia de trabajo, así que sus tabuladores son los del código probado.
- `docs/03` y `docs/06` §3: el arte del mixer visto desde arriba y del celular ampliado, con tamaños sugeridos. `docs/06` §1 y §2: el Plan 6 queda escrito. `docs/00_log.md`: S14 ✅ y S15 ▶.

### Errores encontrados

- **El diseño v2 y `docs/02` se contradecían** sobre un amigo desconectado: el diseño decía que decide solo si le llega una situación, y `docs/02` (y una nota del Plan 5), que no recibe solicitudes. Se resolvió con la decisión de Benja, y los dos documentos dicen ahora lo mismo.
- **El diseño v2 decía que el canal de Audio Sync se elige también desde la entrada del PC,** lo que choca con que el mixer sea un modo exclusivo. Benja eligió el botón «Sincronizar» del chat, y el diseño ya no menciona la entrada.
- **Errores de Claude, sin efecto en el plan:** al escribir el código, un reemplazo en `desk.gd` usó un comentario distinto del real y no se aplicó; se corrigió en la copia de trabajo. También se coló en un commit de la copia un script auxiliar, que se quitó antes de armar el plan; la validación confirma que el plan no lo crea.
- **La sesión se cortó por falta de créditos** justo al terminar la primera validación. Al retomar se comprobó que no había nada a medias: los documentos editados estaban completos y la validación había terminado bien.
- **Detalle visual, anterior al Plan 6:** en una entrada del PC en alerta (el arte rojo), los segundos del temporizador tocan el ícono ⚠ del arte. Pasa igual con las solicitudes. Se ve en `plan6_phone.png`.

### Pendientes Código

- [x] **S14: escribir el Plan 6 (mantenimiento).**
- [ ] **S15: ejecutar el Plan 6** (`docs/13`, 17 tareas), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 7 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos (desde el Plan 6, también el de `phone.csv`).
- [ ] Plan 8: "Reducir destellos" debe apagar el parpadeo de las entradas y de los LED del mixer; decidir con Benja si "Temporizadores ×1,5" alarga también los plazos de los videos.
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres) y ponerlos en sus buses.
- [ ] Cuando llegue el arte: reemplazar el dibujo provisional del mixer y del celular, y las barras de señal de las entradas (`docs/13`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte (correr el temporizador unos píxeles, o el ícono en el arte).
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si Benja quiere ajustarlos en el Inspector: pasar `QUESTION_COST`, `THINKING_TIME` y `FIRST_REQUEST_DELAY` a `BalanceData` (`docs/12`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Después de S15: probar el mantenimiento** (`docs/04`, J, unos 20 minutos).
- [ ] **Probar la noche** (`docs/04`, I, unos 15 minutos). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo, las reacciones y las 2 reacciones de un amigo herido;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - `ui.csv`: el aviso de daño (`CHAT_DAMAGE`), `PC_VIDEOS`, `ENTRY_STUNNED` y los textos de la pantalla final (`END_*`). Conserva los marcadores entre llaves, como `{friend}`;
  - **desde S15:** en `messages.csv`, el aviso del video (`FRIEND_VIDEO_SENT`); en `ui.csv`, los avisos de videos y señal (`CHAT_VIDEO_*`, `CHAT_SIGNAL_*` y `CHAT_OFFLINE`), el botón «Sincronizar» (`CHAT_SYNC`), las entradas (`ENTRY_VIDEO` y `ENTRY_OFFLINE`), la descarga (`DOWNLOAD_*`), el mixer (`MIXER_*`) y `END_CHOSEN_OFFLINE`; y todo `phone.csv`: las 12 publicaciones y el nombre de la red social, "copuchas".
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`** (desde el 2 de noviembre). Benja avisa cuando una pieza esté lista y se integra en una sesión aparte. Lo más urgente, para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5, que hoy usa piezas provisionales:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - **para el Plan 6 (decisión de Benja, sesión 14):** el mixer visto desde arriba (el cuerpo, los dos VU-metros azules, la perilla de un fader, los LED y una fila de luces para el ritmo; 440×430, o 220×215 a ×2), el celular ampliado con unas 12 publicaciones o con la animación del scroll (260×520, o 130×260 a ×2) y las barras de señal de las entradas (`docs/06` §3 y `docs/03` §6).
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

---

## Sesión 13 — 31 de octubre de 2026 — Plan 5 ejecutado: consecuencias, medidores y noche

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5 con esfuerzo max (el registro proponía Sonnet 5.5 · high). Se adelantó al 31 de octubre (la fecha objetivo era del 10 al 12 de noviembre). Benja autorizó todos los commits del plan en `main` y, al terminar, el push.

### Realizado

- **Las 13 tareas de `docs/12`, con 251 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`), sin errores ni avisos al correr. Coincidieron todos los conteos del plan, incluidas las fallas esperadas (185 → 188, 193, 196, 201, 215, 220, 224, 231, 236, 239, 246 y 251).
  - El código se copió de los bloques del plan con un script, para conservar sus tabuladores. Antes de tocar el proyecto, el mismo script aplicó el plan completo a una copia, para comprobar que cada texto a reemplazar aparecía una sola vez. El código final es idéntico al de esa copia.
  - **Valores de equilibrio:** `data/balance.tres` (`BalanceData`), que el catálogo referencia. Se ajusta en el Inspector (`docs/04`, I, "Para ajustar").
  - **Lógica pura en `scripts/core/`:** `Consequence`, `FriendState`, `VideoSchedule`, `NightState` y `EndingText`.
  - **`RequestManager`** crea el estado de la noche y aplica cada consecuencia antes de la reacción del amigo. No le da solicitudes a un amigo aturdido o muerto, y con Trust bajo hay menos tiempo para responder. Sin respuesta, el amigo cuenta qué hizo y, en otro mensaje, cómo le fue.
  - **Aviso de daño en el chat:** el amigo herido grita y, debajo, el juego avisa en rojo y centrado cuánta vida le queda ("León recibió daño: 2/3"). Marca la pestaña del amigo.
  - **`NightManager`**, el reloj de la noche: avanza las solicitudes y el estado, y al terminar la noche todo se detiene.
  - **Escritorio:** los diales conectados, la hora en el celular, "Videos: 1 de 3" en el PC, las marcas de vida y el aturdimiento en las entradas, la viñeta de Sanity (`shaders/vignette.gdshader`) y la pantalla final (`scenes/ui/end_screen.tscn`), que explica la derrota y permite reintentar.
- **Textos nuevos**, borradores reales que tú corriges:
  - `data/text/messages.csv`: las 2 reacciones de un amigo herido (`REACTION_RISKY_HURT` y `REACTION_WRONG_HURT`);
  - `data/text/ui.csv`: el aviso de daño (`CHAT_DAMAGE`), los videos del PC (`PC_VIDEOS`), el aturdimiento de la entrada (`ENTRY_STUNNED`) y los textos de la pantalla final (`END_*`).
- **Capturas revisadas** (`C:\dev\capturas\night.png` y `night_lost.png`). Se cumple todo lo que pide el plan:
  - a las 03:00, el celular dice "03:01" sin restos del "00:00" dibujado, y el PC, "Videos: 1 de 3". León está oscurecido, con 1 marca llena y 2 vacías y "Aturdido 14"; Gonzalo está en alerta, con su tiempo. Las agujas marcan Connection 100, Sanity 25 y Trust 55, y la viñeta oscurece los bordes en bandas;
  - en la derrota: "Perdiste la noche", "Gonzalo murió.", la entidad, las 3 observaciones, la regla 4, la acción correcta en verde, la elegida en rojo y el botón "Reintentar". Detrás, en el chat, están el grito y el aviso "── Gonzalo recibió daño: 0/3 ──", muy tenues porque la pantalla final tapa el 92 %.
- `docs/04`: nueva sección **I** (probar la noche). `docs/06`: el Plan 5 queda ejecutado. `docs/02`: `BalanceData` en §6 y §10. `docs/00_log.md`: S13 ✅ y S14 ▶.
- 13 commits en `main` (uno por tarea), subidos a GitHub al terminar.

### Errores encontrados

- **El plan no necesitó correcciones:** se aplicó tal como está escrito.

### Pendientes Código

- [x] **S13: ejecutar el Plan 5.**
- [ ] **S14: escribir el Plan 6 (mantenimiento)**, con Opus 5.5 en esfuerzo high (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 6 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si Benja quiere ajustarlos en el Inspector: pasar `QUESTION_COST`, `THINKING_TIME` y `FIRST_REQUEST_DELAY` a `BalanceData` (`docs/12`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar la noche** (`docs/04`, I, unos 15 minutos). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo, las reacciones y las 2 reacciones nuevas de un amigo herido;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - `ui.csv`: el aviso de daño (`CHAT_DAMAGE`), `PC_VIDEOS`, `ENTRY_STUNNED` y los textos de la pantalla final (`END_*`). Conserva los marcadores entre llaves, como `{friend}`.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5, que hoy usa piezas provisionales:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - **para el Plan 6 (S14):** el mixer en piezas (base, VU-metro de 5 niveles, perilla de fader y LED), el celular ampliado con unas 12 publicaciones y las barras de señal (`docs/06` §3).
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

---

## Sesión 12 (continuación) — 31 de octubre de 2026 — Notas de prueba: chat de terminal, textos reales y aviso de daño

Benja probó el juego (estado del Plan 4) y dejó tres notas: había demasiado texto y marcas `[PROTO]`, el chat se veía aburrido, y siempre "salía mal" aunque eligiera la acción correcta. Se resolvieron en la misma sesión, en Opus 5.5, con las skills de depuración sistemática, brainstorming y diseño. La sesión se cortó una vez por falta de créditos. Al retomar se comprobó que no había nada a medias: el proyecto seguía limpio y el trabajo estaba en copias aparte.

### Realizado

- **Nota 3 (siempre "salía mal"): no es un error del juego.** Lo que se encontró:
  - responder la acción correcta con los botones del chat da "funcionó" en 40 de 40 solicitudes, y las condiciones de cada regla de El Trauco coinciden con su texto en el cuaderno;
  - en la noche 3, el mensaje inicial trae 2 de las 3 observaciones: así está diseñada, para que haya que preguntar. En 3000 solicitudes, solo el 51 % se puede decidir con el mensaje inicial, y quien responde sin preguntar se equivoca el 29 % de las veces;
  - además, una característica decía "Vio a un hombrecito", que se confunde con "quién vio a quién primero". Los textos nuevos lo evitan.
- **Nota 1 (textos):**
  - todos los textos de `messages.csv` y `notebook.csv` son ahora borradores reales, sin `[PROTO]`. Los amigos hablan en primera persona y en mensajes cortos ("Me vio primero. Me está mirando."). Tú los corriges (regla 8 de `CLAUDE.md`, actualizada);
  - cada mensaje lleva el nombre de quien escribe, "LEÓN:" o "MATÍAS:", en su color. El de Matías se cambia en `CHAT_PLAYER_NAME` (`ui.csv`);
  - el aviso de daño y el grito del amigo herido entran en el Plan 5 (abajo), porque necesitan la vida de los amigos.
- **Nota 2 (estilo del chat), aprobado por Benja con una maqueta:**
  - la fuente Departure Mono (pixel, licencia OFL), en `fonts/departure_mono/`, sin suavizado y a 11 px. También se usa en las entradas del PC;
  - el tema nuevo `scenes/ui/chat_theme.tres`: fondo azul casi negro detrás del vidrio del panel, líneas CRT suaves (`shaders/scanlines.gdshader`), una barra de color a la izquierda de cada mensaje, pestañas en el color de cada amigo y preguntas en mayúsculas;
  - los colores nuevos de los amigos: León rosa, Gonzalo azul y Agustín lila;
  - 8 pruebas nuevas: 185 pruebas OK.
- **Plan 5 actualizado (`docs/12`):**
  - la Tarea 7 nueva, el aviso de daño en el chat: el amigo herido grita ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y el juego avisa en rojo y centrado cuánta vida le queda ("León recibió daño: 2/3"). Es un mensaje del juego (`ChatMessage.Sender.SYSTEM`), sin nombre y sin estática;
  - la hora del celular, los videos del PC y la pantalla final usan la fuente nueva;
  - ahora son 13 tareas, de 185 a 251 pruebas. Se volvió a validar sobre una copia limpia: los 27 conteos de pruebas coinciden, y el código resultante es idéntico al probado.
- Capturas en `C:\dev\capturas\`: `chat.png`, `notebook.png`, `chat_mock_1.png`, `chat_mock_2.png`, `night.png` y `night_lost.png` (las dos últimas, del Plan 5 con el aviso de daño).
- Las decisiones de Benja quedaron en `CLAUDE.md`, el diseño v2 (§1, §7, §9 y §18), `docs/02` (§5.2 y §9), `docs/03` §10 (la tipografía elegida) y `docs/06` §3. `docs/04`, G y H: lo que cambia al probar.

### Errores encontrados

- **El cálculo del resultado no fallaba** (nota 3). El problema era la información incompleta de la noche 3, que es intencional, y un texto confuso. El detalle está arriba.
- **El interior del panel del chat era translúcido:** la habitación se veía detrás del texto. Ahora hay un fondo oscuro detrás del vidrio.
- **Los colores de los amigos se confundían** con los de las pistas: León (ámbar), Agustín (verde) y Gonzalo (celeste, como Matías). Se cambiaron.
- **La barra de color de cada mensaje habría hecho caer el juego** si el tema del chat pasara a usar texturas. Se protegió.
- **Al agregar el aviso de daño, una prueba del Plan 4 contaba los mensajes** después de una respuesta que podía herir al amigo. Ahora esa prueba no tiene heridas.
- **Con el fondo oscuro, el chat tapa el celular:** la primera captura del Plan 5 ahora va con el chat cerrado.
- **El plan reemplaza líneas completas:** un ancla del aviso de daño era solo el comienzo de una línea. Se corrigió antes de validar.
- **La sesión se cortó por falta de créditos.** No hubo pérdidas: el proyecto estaba limpio y el trabajo, en copias aparte.

### Pendientes Código

- [x] **S12: escribir el Plan 5**, y actualizarlo con el aviso de daño.
- [ ] **S13: ejecutar el Plan 5** (`docs/12`, 13 tareas), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 6 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Después de S13:** probar la noche (`docs/04`, I, unos 15 minutos).
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo y las reacciones;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - desde S13: las 2 reacciones de herido (`messages.csv`) y, en `ui.csv`, el aviso de daño (`CHAT_DAMAGE`) y los textos de la pantalla final (`END_*`).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - también faltan las barras de señal, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [x] Elegir una tipografía pixel: Departure Mono (`docs/03` §10). Si prefieres otra, se cambia en el tema del chat.
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

---

## Sesión 12 — 31 de octubre de 2026 — Plan 5 escrito: consecuencias, medidores y noche

Benja pidió escribir el Plan 5 con `superpowers:writing-plans`, justo después de ejecutar el Plan 4 (la fecha objetivo era el 9 de noviembre). Se escribió en Opus 5.5, con esfuerzo high.

### Realizado

- **Nuevo `docs/12_plan_consecuencias_noche.md`:** el Plan 5 en 12 tareas con código completo. Lleva las pruebas de 177 a 239:
  - `data/balance.tres` (`BalanceData`): los valores de equilibrio que valen para todas las noches, editables en el Inspector;
  - lógica pura en `scripts/core/`: `Consequence` (daño, Trust y mayor riesgo), `FriendState` (vida, aturdimiento y señal de un amigo), `VideoSchedule` (los envíos y la cuota), `NightState` (la hora, Sanity, Trust, los amigos, los videos y cómo termina la noche) y `EndingText` (los textos de la pantalla final);
  - `RequestManager` crea el estado de la noche y aplica cada consecuencia antes de la reacción del amigo, que ahora depende de si quedó herido. Un amigo aturdido o muerto no recibe solicitudes. Sin respuesta, el amigo cuenta qué hizo y, en otro mensaje, cómo le fue;
  - `NightManager`, el reloj de la noche: avanza las solicitudes y el estado, y avisa cuando la noche se gana o se pierde. Al terminar, todo se detiene;
  - en el escritorio: los diales conectados, la hora en el celular, "Videos: 1 de 3" en el PC, las marcas de vida y el aturdimiento en las entradas, la viñeta de Sanity (un shader en bandas) y la pantalla final, que explica la derrota y permite reintentar;
  - los textos: los del PC, de la entrada y de la pantalla final en `ui.csv`, sin `[PROTO]`; en `messages.csv`, 2 reacciones `[PROTO]` nuevas (herido), y las 3 que había cambian, porque ahora también siguen a una decisión del amigo;
  - la sección I de `docs/04` (probar la noche), que se agrega al ejecutar el plan.
- **Decisiones de Benja:**
  - los videos se reciben solos hasta el Plan 6, que agrega aceptarlos en 10 s y descargarlos. Así, una noche ya se gana o se pierde con el Plan 5 (`docs/06` §2);
  - si a un amigo aturdido le toca enviar un video, lo envía apenas se recupera. Vale también para el video extra (`CLAUDE.md`, diseño v2 §9 y §10.4, y `docs/02` §5.2);
  - cada dial conserva el color de su aguja: Connection verde, Sanity roja y Trust amarilla (`CLAUDE.md` y diseño v2 §6).
- **El plan se verificó en Godot 4.7.2:**
  - todo su código se ejecutó en una copia aparte, con 239 pruebas OK y dos capturas revisadas: el escritorio a las 03:00 con la viñeta (`C:\dev\capturas\night.png`) y la pantalla de derrota (`C:\dev\capturas\night_lost.png`);
  - después, un script aplicó el plan **tal como está escrito** a una copia limpia: los 23 conteos de pruebas que indica coinciden, incluidas las fallas esperadas, y el código resultante es idéntico al probado;
  - las copias ya se borraron.
- `docs/06`: el Plan 5 queda escrito, y las filas de los planes 5 y 6 dicen qué parte de los videos va en cada uno. `docs/00_log.md`: S12 ✅ y S13 ▶.

### Errores encontrados

- **La primera viñeta casi no se veía:** con Sanity en 25, la escena oscura la escondía. Se ajustó el shader para que el borde avance más hacia el centro. En la captura final se nota, y el chat sigue legible.
- **En la primera captura, el contador de videos no era el esperado:** al poner la hora en 03:00, llegaron también los envíos programados anteriores. La captura del plan ahora vacía los envíos antes de empezar.
- **Un texto `[PROTO]` con una coma iba sin comillas** en `messages.csv`, y habría partido la línea en dos columnas. Se corrigió antes de escribir el plan.

### Pendientes Código

- [x] **S12: escribir el Plan 5.**
- [ ] **S13: ejecutar el Plan 5** (`docs/12`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 6 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el cuaderno en Godot** (`docs/04`, H, unos 10 minutos).
- [ ] **Probar las solicitudes y el chat en Godot** (`docs/04`, G, unos 10 minutos). Ojo: desde el Plan 4, el chat se cierra con clic derecho sobre él, con `Esc` o con un clic fuera de los paneles.
- [ ] **Después de S13:** probar la noche (`docs/04`, I, unos 15 minutos).
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` (desde S13, son 5 reacciones: las 3 de antes, que cambian, y las 2 de un amigo herido) y `notebook.csv`. Cada fragmento, como una oración completa con su punto.
- [ ] Revisar los textos de la pantalla final (`END_*` en `ui.csv`, desde S13). Son de interfaz y están escritos, pero puedes cambiarlos conservando los marcadores entre llaves.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` ya existe y los recibe;
  - para el chat: burbujas, botones (4 estados), pestañas y "escribiendo…". El tema `scenes/ui/chat_theme.tres` está listo para recibirlos;
  - **para el Plan 5:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - también faltan las barras de señal, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10). Debe tener `▒` (U+2592).

---

## Sesión 11 — 31 de octubre de 2026 — Plan 4 ejecutado: cuaderno

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5 (el registro proponía Sonnet 5.5). Benja autorizó todos los commits del plan en `main`, sin push.

### Realizado

- **Las 7 tareas de `docs/11`, con 177 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`), sin errores al correr. Coincidieron todos los conteos del plan, incluidas las fallas esperadas (148 → 151, 156, 158, 160, 168 y 177). El código se copió de los bloques del plan con un script, para conservar sus tabuladores exactos.
  - **Lógica pura en `scripts/core/`:** `NotebookMemory` (la página abierta de cada amigo) y `NotebookPage` (la página de una entidad en BBCode).
  - **`MessageBuilder`** agrega la respuesta de Matías y la reacción del amigo según el resultado. **`RequestManager`** agrega `answer()`: una acción de la página de otra entidad es incorrecta.
  - **Cuaderno:** `scenes/ui/notebook_panel.tscn` y `scripts/ui/notebook_panel.gd`, a la derecha (449×696, en x 820–1269), con el tema provisional `scenes/ui/notebook_theme.tres`.
  - **Chat:** 4 botones de respuesta con las acciones de la página abierta para ese amigo, y la señal `friend_selected`. La conversación se achicó de 448 a 370 px.
  - **Escritorio:** crea la memoria, conecta el chat con el cuaderno, vuelve al índice cuando llega una solicitud nueva y cierra los paneles con `Esc` o con un clic fuera. El celular y el mixer cierran los paneles.
- **Textos nuevos:**
  - `data/text/notebook.csv`, sin `[PROTO]`: los títulos de las secciones y los formatos de las líneas (`NOTEBOOK_*`);
  - `data/text/ui.csv`, sin `[PROTO]`: "Elige una entidad en el índice", "Ayudando a {friend}" y "Acciones de {entity}";
  - `data/text/messages.csv`, como `[PROTO]` (Benja los reemplaza): las 3 reacciones (`REACTION_CORRECT`, `REACTION_RISKY` y `REACTION_WRONG`).
- **Captura del cuaderno revisada** (`C:\dev\capturas\notebook.png`). Se cumple todo lo que pide el plan:
  - en el chat de León, las 2 características en verde, la barra con "El Trauco", las 4 preguntas, "Acciones de El Trauco" y los 4 botones;
  - en el cuaderno, "Ayudando a León", la pestaña de El Trauco marcada, el folclore, las características y las observaciones con su pregunta entre paréntesis, y las reglas con la acción correcta en verde y la de mayor riesgo en rojo, después de "Mayor riesgo:";
  - en el PC, León seleccionada, y los diales tapados por el cuaderno.
- `docs/04`: nueva sección **H** (probar el cuaderno), y las secciones C y G ya no dicen que el cuaderno llega en el Plan 4. `docs/06`: el Plan 4 queda ejecutado. `docs/00_log.md`: S11 ✅ y S12 ▶.
- 7 commits en `main`, sin push.

### Errores encontrados

- **El plan no necesitó correcciones:** se aplicó tal como está escrito.
- En la captura siguen los dos detalles conocidos de la Sesión 9: la pestaña de León dice 29 y su entrada 30 (el desfase de un frame), y las oraciones del mensaje quedan pegadas porque los textos `[PROTO]` no terminan en punto.

### Pendientes Código

- [x] **S11: ejecutar el Plan 4.**
- [ ] **S12: escribir el Plan 5 (consecuencias, medidores y noche)**, con Opus 5.5 en esfuerzo high (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 5 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el cuaderno en Godot** (`docs/04`, H, unos 10 minutos). Lo ideal es antes de S12.
- [ ] **Probar las solicitudes y el chat en Godot** (`docs/04`, G, unos 10 minutos). Ojo: desde el Plan 4, el chat se cierra con clic derecho sobre él, con `Esc` o con un clic fuera de los paneles.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` (ahora también las 3 reacciones) y `notebook.csv`. Cada fragmento, como una oración completa con su punto.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` ya existe y los recibe;
  - para el chat: burbujas, botones (4 estados), pestañas y "escribiendo…". El tema `scenes/ui/chat_theme.tres` está listo para recibirlos;
  - también faltan las barras de señal, el celular sin la hora y los dígitos LCD, los diales rediseñados, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10). Debe tener `▒` (U+2592).

---

## Sesión 10 — 30 y 31 de octubre de 2026 — Plan 4 escrito: cuaderno

Benja pidió escribir el Plan 4 con `superpowers:writing-plans`, justo después de ejecutar el Plan 3. Se escribió en Opus 5.5, con esfuerzo max. La sesión se interrumpió una vez (el equipo se reinició) y no se perdió nada del proyecto.

### Realizado

- **Push a GitHub** de los 12 commits de S9 (autorizado por Benja).
- **Nuevo `docs/11_plan_cuaderno.md`:** el Plan 4 en 7 tareas con código completo. Lleva las pruebas de 148 a 177:
  - lógica pura en `scripts/core/`: `NotebookMemory` (la página abierta de cada amigo) y `NotebookPage` (la página de una entidad en BBCode);
  - `MessageBuilder` agrega la respuesta de Matías y la reacción del amigo, y `RequestManager` agrega `answer()`;
  - `NotebookPanel`: el índice, con una pestaña por entidad conocida, y la página: folclore, boceto, características y observaciones con la pregunta que las trae, reglas (la correcta en verde y la de mayor riesgo en rojo, también nombrada) y acciones. Tema provisional de papel;
  - el chat: 4 botones de respuesta con las acciones de la página abierta para ese amigo. Sin página, dice "Abre el cuaderno para responder";
  - el escritorio conecta el chat con el cuaderno y cierra los paneles con `Esc` o con un clic fuera. Cada panel se cierra con clic derecho, y el celular y el mixer cierran los paneles;
  - los textos: los títulos y formatos de la página en `notebook.csv`, los de los paneles en `ui.csv` y las reacciones `[PROTO]` en `messages.csv`;
  - la sección H de `docs/04` (probar el cuaderno), que se agrega al ejecutar el plan.
- **Decisiones de Benja** (en `CLAUDE.md`, el diseño v2 §7 y §12, y `docs/02` §5.1):
  - cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice;
  - mientras no existan las consecuencias (Plan 5), el amigo reacciona según el resultado, con textos `[PROTO]`;
  - el chat y el cuaderno son independientes: abrir uno no abre ni cierra el otro, y son los únicos paneles que pueden estar abiertos a la vez. El celular y el mixer son modos exclusivos;
  - el cuaderno va a la derecha, como espejo del chat (449×696, en x 820–1269), y tapa los diales mientras está abierto;
  - el clic derecho sobre un panel lo cierra; `Esc` o un clic fuera de los paneles cierra los dos.
- **El plan se verificó en Godot 4.7.2:**
  - todo su código se ejecutó en una copia aparte, con 177 pruebas OK y una captura del cuaderno junto al chat (`C:\dev\capturas\notebook.png`);
  - después, el plan **tal como está escrito** se aplicó a una copia limpia: los 14 conteos de pruebas que indica coinciden, y el código resultante es idéntico al probado;
  - las copias ya se borraron.
- `docs/02` §9: la frase entre asteriscos de una característica también es su nombre en el cuaderno, así que tiene que entenderse sola. `docs/03` y `docs/06` §3: el tamaño de la página del cuaderno.
- `docs/06` y `docs/00_log.md` actualizados: S10 ✅ y S11 ▶.

### Errores encontrados

- **El cuaderno al centro tapaba el PC.** Así lo decía el diseño (§7), pero si se abría solo, no había cómo llegar a las entradas para abrir el chat y responder. Benja decidió que va a la derecha y es independiente del chat. El diseño v2 está actualizado.
- **Con dos paneles, el chat ya no puede cerrarse solo con un clic fuera** (Plan 3): un clic en el cuaderno del escritorio lo habría cerrado. Por eso el cierre con `Esc` y con un clic fuera pasa al escritorio, que es el último en recibir la entrada.
- **En dos pasos "Verificar que fallan", la falla real no era la que Claude predijo** (tareas 4 y 6). Godot carga un archivo de pruebas que llama a un método que todavía no existe, y la prueba falla al correr. El plan tiene las salidas reales, comprobadas en la copia limpia.
- **La interrupción borró el scratchpad.** La copia de trabajo estaba en `C:\dev`, así que no se perdió nada; se rehicieron los ayudantes.
- **Error de Claude:** un ayudante de la validación usaba `sys.path[0]`, que con `python3 -I` no es la carpeta del script, y no agregó los textos de la Tarea 2. Se corrigió y se repitió el paso. El plan no tenía el error.

### Pendientes Código

- [x] **S10: escribir el Plan 4.**
- [ ] **S11: ejecutar el Plan 4** (`docs/11`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 5 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar las solicitudes y el chat en Godot** (`docs/04`, G, unos 10 minutos). Lo ideal es antes de S11, porque el Plan 4 cambia cómo se cierra el chat.
- [ ] **Después de S11:** probar el cuaderno (`docs/04`, H, unos 10 minutos).
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` y `notebook.csv`. Cada fragmento, como una oración completa con su punto.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres`, que se crea en S11, los recibe;
  - para el chat: burbujas, botones (4 estados), pestañas y "escribiendo…". El tema `scenes/ui/chat_theme.tres` está listo para recibirlos;
  - también faltan las barras de señal, el celular sin la hora y los dígitos LCD, los diales rediseñados, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10). Debe tener `▒` (U+2592).

---

## Sesión 9 — 30 de octubre de 2026 — Plan 3 ejecutado: solicitudes y chat

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5 (el registro proponía Sonnet 5.5), primero en esfuerzo xhigh y después en max. Benja autorizó todos los commits del plan en `main`, sin push.

### Realizado

- **Las 12 tareas de `docs/10`, con 148 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`). Los 25 conteos de pruebas del plan coincidieron, incluidas las fallas esperadas. El código se copió de los bloques del plan con un script, para conservar sus tabuladores exactos.
  - **Datos:** `DecoyData` (señuelo), `ContentCatalog.decoys` con `decoys_for_place()`, y `NightData.decoys_in_first_message` (1, 1, 2, 2 y 3 en las noches).
  - **Validador:** avisa si una entidad tiene todas sus características dentro de las de otra, y revisa los señuelos (ids, lugares, cantidad por lugar y noche, y sus textos).
  - **Lógica pura en `scripts/core/`:** `FriendRequest`, `ChatMessage`, `ChatStatic`, `RequestGenerator` y `MessageBuilder`.
  - **`RequestManager`**, un nodo de `desk.tscn` que juega la noche 3 (El Trauco) con el ritmo provisional.
  - **Chat:** `ChatMessageView` (burbuja) y `ChatPanel` reescrito, con el tema provisional `scenes/ui/chat_theme.tres`.
  - **Escritorio:** las entradas del PC parpadean y muestran el tiempo. El panel se queda con los clics de su área, y lo que tiene debajo no se resalta.
- **Textos nuevos:**
  - `data/text/messages.csv`, como `[PROTO]` (Benja los reemplaza): los 6 señuelos (`DECOY_*`), las respuestas "nada" (`ANSWER_NOTHING_*`) y "decidí solo" (`FRIEND_DECIDED_ALONE`, con `{action}`);
  - `data/text/ui.csv`, sin `[PROTO]`: las 4 preguntas del diseño (§8.4), "Abre el cuaderno para responder", la barra de identificación (con `{marked}` y `{total}`) y "Matías piensa…".
- **Captura del chat revisada** (`C:\dev\capturas\chat.png`). Se cumple todo lo que pide el plan:
  - pestañas con su tiempo y el `•` de mensajes sin leer;
  - palabras tapadas con `▒▒▒`, frases en ámbar, una característica en verde y un señuelo en rojo;
  - la pregunta de Matías a la derecha y la respuesta debajo;
  - la barra en "1 de 2", con las 4 preguntas y el aviso del cuaderno;
  - en el PC, León seleccionada (brillo ×1,3) y Gonzalo en alerta.
- `docs/04`: nueva sección **G** (probar el chat). `docs/06`: el Plan 3 queda ejecutado. `docs/00_log.md`: S9 ✅ y S10 ▶; además, el historial quedó en orden (S7 antes de S8).
- 12 commits en `main`, sin push.

### Errores encontrados

- **El plan no necesitó correcciones:** se aplicó tal como está escrito.
- **Las entradas del PC van un frame atrás de las pestañas del chat.** `desk.gd` las actualiza antes de que `RequestManager` avance el tiempo en ese frame. En la captura se nota como 1 s de diferencia (pestaña 23, entrada 24) porque cayó justo en un cambio de segundo: sus esperas son de 4 s y 3 s exactos. Al jugar no se nota (un frame dura unos 16 ms).
- **Las oraciones de un mensaje quedan pegadas** ("…entre los árboles [PROTO] Vio a un…"), porque los textos `[PROTO]` no terminan en punto. Se arregla cuando Benja escriba cada fragmento como una oración completa, con su punto (`docs/02` §9).
- **En la captura se ve el caso de camuflaje ya conocido:** los 2 señuelos eran de Ambiente y de Sonido, así que la respuesta a "¿Qué ves?" trajo solo las 2 características. Benja decidió probarlo así (pendiente abajo).
- Al cambiar el esfuerzo a max se interrumpió una llamada de la Tarea 1. No alcanzó a escribir nada y se repitió.

### Pendientes Código

- [x] **S9: ejecutar el Plan 3.**
- [ ] **S10: escribir el Plan 4 (cuaderno)** en `docs/11`, con Opus 5.5 en esfuerzo high (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 4 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar las solicitudes y el chat en Godot** (`docs/04`, G, unos 10 minutos). Lo ideal es antes de S10.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` y `notebook.csv`. Cada fragmento, como una oración completa con su punto.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 4 a 6:
  - para S10, si se puede, **la interfaz del cuaderno**: la página, las pestañas del índice y los bocetos de las entidades;
  - para el chat: burbujas, botones (4 estados), pestañas y "escribiendo…". El tema `scenes/ui/chat_theme.tres` está listo para recibirlos;
  - también faltan las barras de señal, el celular sin la hora y los dígitos LCD, los diales rediseñados, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10). Debe tener `▒` (U+2592).

---

## Sesión 8 — 26 y 27 de octubre de 2026 (noche) — Plan 3 escrito: solicitudes y chat

Benja pidió **ejecutar** el Plan 3, pero `docs/10` no existía: S8, que lo escribe, seguía pendiente. Benja eligió escribirlo ahora, sin esperar las entidades refinadas. Se usó `superpowers:writing-plans`, en Opus 5.5.

### Realizado

- **Nuevo `docs/10_plan_solicitudes_chat.md`:** el Plan 3 en 12 tareas con código completo. Lleva las pruebas de 78 a 148:
  - datos: `DecoyData` (señuelo), `ContentCatalog.decoys` y `NightData.decoys_in_first_message`;
  - validador: ninguna entidad puede tener todas sus características dentro de las de otra; además revisa los señuelos (ids, lugares y cantidad por lugar y noche);
  - lógica pura en `scripts/core/`: `FriendRequest`, `ChatMessage` (mensaje separado en piezas), `ChatStatic`, `RequestGenerator` y `MessageBuilder`;
  - `RequestManager`, un nodo de `desk.tscn` con un ritmo provisional hasta el director del Plan 7;
  - `ChatMessageView` (burbuja con enlaces, escritura progresiva y vibración) y `ChatPanel` reescrito: pestañas, barra de identificación, preguntas y "Abre el cuaderno para responder";
  - las entradas del PC parpadean y muestran el tiempo; el panel ya no deja pasar los clics al mixer y al celular;
  - 6 señuelos `[PROTO]` y los textos nuevos en `data/text/*.csv` (los diálogos, como `[PROTO]`);
  - la sección G de `docs/04` (probar el chat), que se agrega al ejecutar el plan.
- **Decisiones de Benja** (en `CLAUDE.md`, el diseño v2 §8.2–8.4 y `docs/02` §2–4, §6, §9 y §10):
  - el mensaje inicial trae **2 características camufladas entre señuelos**. Los señuelos son frases clickeables que no ayudan a identificar; al clickearlos vibran y se ponen rojos, sin otro costo;
  - hay **1, 1, 2, 2 y 3 señuelos** por noche;
  - una **barra fija** muestra el avance de la identificación;
  - la estática tapa una frase **entera o nada**;
  - con **5 s o menos no se puede preguntar**;
  - las respuestas repiten solo lo del mensaje inicial, sin señuelos nuevos (se prueba así).
- **El plan se verificó en Godot 4.7.2:**
  - todo su código se ejecutó en una copia aparte del proyecto, con 148 pruebas OK y una captura del chat revisada (`C:\dev\capturas\chat_probe.png`);
  - después, el plan **tal como está escrito** se aplicó a una copia limpia: los 25 conteos de pruebas que indica coinciden, y el código resultante es idéntico al probado;
  - las copias ya se borraron.
- `docs/06` y `docs/00_log.md` actualizados: S8 ✅ y S9 ▶.

### Errores encontrados

- **Se pidió ejecutar un plan que no existía.** El registro decía que S8 (escribirlo) era la siguiente. Se resolvió preguntándole a Benja.
- **Error heredado del Plan 1: el clic atravesaba el panel del chat.** El panel no detenía el mouse, así que un clic sobre él llegaba al mixer o al celular, que quedan debajo, y además se resaltaban. El plan lo corrige: el panel pasa a `mouse_filter = STOP` y los objetos no se resaltan si el mouse está sobre un panel. Esto se revisa a mano (`docs/04`, G), porque sin ventana Godot no mueve el mouse.
- **Sin ventana, Godot no informa las advertencias del analizador de GDScript** (ni con `treat_warnings_as_errors`, ni con `--check-only`). Se revisaron a mano y se corrigieron dos nombres que tapaban otros: `free` y `log`.
- **Una copia hecha con `git archive` no trae los `.translation`** (están en `.gitignore`), y sus pruebas de traducción fallan hasta el primer import. No afecta al proyecto.
- **`▒` no está en la fuente por defecto:** se ve gracias a la fuente de respaldo del sistema. La tipografía pixel que se elija debe incluirlo.
- **Camuflaje en las respuestas:** si ningún señuelo es de la categoría preguntada, la respuesta delata las características. Benja decidió probarlo así.
- **Se borró el scratchpad de la sesión a mitad del trabajo.** Se rehízo el plan, se volvió a validar y no se perdió nada del proyecto.

### Pendientes Código

- [x] **S8: escribir el Plan 3.**
- [ ] **S9: ejecutar el Plan 3** (`docs/10`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine, y agregar El Tue Tué y La Calchona a la noche 1.
- [ ] Planes 4 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Después de S9:** probar el chat en Godot (`docs/04`, G, unos 10 minutos).
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` y `notebook.csv`.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6. Para el chat: burbujas, botones (4 estados), pestañas y "escribiendo…". El tema `scenes/ui/chat_theme.tres` está listo para recibirlos. También faltan las barras de señal, el celular sin la hora y los dígitos LCD, los diales rediseñados, el mixer en piezas y el celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10). Debe tener `▒` (U+2592).

---

## Sesión 7 — 26 de octubre de 2026 (noche) — Plan 2 ejecutado: datos y textos

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5 (el registro proponía Sonnet 5.5). Benja autorizó todos los commits del plan en `main`, sin push.

### Realizado

- **Commit previo** con el trabajo de S6 que había quedado sin commitear: `docs/08`, los cambios de los documentos y `look_camera.gd.uid`.
- **Las 10 tareas de `docs/08`, con 78 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`):
  - clases de datos con `class_name` en `scripts/data/`: `ClueCategory`, `TraitData`, `ActionData`, `ObservationData`, `RuleData`, `EntityData`, `FriendData`, `NightData` y `ContentCatalog`;
  - `scripts/core/rule_evaluator.gd` (regla que se aplica, resultado de una respuesta y todas las situaciones posibles) y `scripts/core/content_validator.gd` (entidad, catálogo y textos, con los errores en español);
  - `data/text/messages.csv`, `notebook.csv` y `ui.csv`, con textos `[PROTO]`, registrados en `project.godot` con el español como idioma de respaldo;
  - `data/entities/trauco.tres` (ejemplo de formato), `data/friends/*.tres`, `data/nights/night_1.tres` a `night_5.tres` (valores de `docs/02` §6) y `data/catalog.tres`;
  - `test_catalog.gd` valida el contenido real cada vez que se corren las pruebas;
  - `docs/04`, sección F: revisar una entidad en el Inspector y cómo agregar una.
- **Textos `[PROTO]`** (Benja los reemplaza): `data/text/messages.csv` (lugar, características y valores de las observaciones del Trauco) y `data/text/notebook.csv` (folclore, acciones, preguntas y reglas). Los nombres y los lugares de las noches, en `ui.csv`, no son prototipo.
- `docs/06`: el Plan 2 queda marcado como ejecutado.
- **Push a GitHub** de los 11 commits (autorizado por Benja).
- **Pedido de Benja: nuevo `docs/09_propuesta_entidades.md`**, un borrador de El Tue Tué, La Calchona y El Trauco basado en el folclore (Wikipedia, BioBioChile, Currículum Nacional y Museo de Chiloé), para que Benja lo refine. Cada entidad trae características, acciones, observaciones, reglas, la intención de los mensajes, un ejemplo de solicitud e ideas de arte y sonido. Pasó el validador real (`validate_catalog`) sin errores. Por eso el Plan 3 pasa a `docs/10`.

### Errores encontrados

- **Godot 4.7.2 no genera el `.en.translation` si la columna `en` está entera vacía**, y el plan registraba los seis archivos `.translation`. Hay que tener al menos una celda `en` llena para que exista el `.en`. Se registran solo los tres `.es`; con `locale/fallback="es"` el inglés muestra el español (la prueba lo confirma). El `.en` se registra en el Plan 8, junto con la opción de idioma. `docs/08` está corregido.
- **Dos pruebas del plan pasaban aunque faltara el archivo que revisan.** En GDScript, un error en tiempo de ejecución (`null.rules`) corta la función sin registrar una falla, así que `test_reglas_del_ejemplo` y dos pruebas de `test_catalog.gd` daban OK sin el `.tres`. Se agregaron guardas que fallan si el archivo no carga y luego salen de la prueba. **Para los próximos planes:** comprobar con `check()` que lo cargado no sea `null` antes de usarlo.
- Al importar con las traducciones ya registradas pero sin generar, Godot muestra `Cannot open file …translation` una vez. Es esperado y desaparece en el import siguiente.

### Pendientes Código

- [x] **S7: ejecutar el Plan 2.**
- [ ] **S8: escribir el Plan 3** (solicitudes y chat) en `docs/10`, con Opus 5.5 en esfuerzo xhigh (`docs/00_log.md`).
- [ ] Pasar a `.tres` las entidades que Benja refine (en S8 o antes, si lo pide).
- [ ] Planes 4 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] **Antes de S8 (2 de noviembre):** refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos.
- [ ] Reemplazar los textos `[PROTO]` de `data/text/messages.csv` y `notebook.csv` cuando el Trauco definitivo esté diseñado.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara: si convence, se queda; si no, se apaga (*Look Enabled*) y se quita el parallax.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10).

---

## Sesión 6 — 26 de octubre de 2026 (noche) — Plan 2 escrito: datos y textos

Plan escrito con `superpowers:writing-plans`, en Opus 5.5.

### Realizado

- **Nuevo `docs/08_plan_datos_textos.md`:** el Plan 2 en 10 tareas con código completo. Lleva las pruebas de 36 a 78:
  - clases `Resource` con `class_name` en `scripts/data/`: `TraitData`, `ActionData`, `ObservationData`, `RuleData`, `EntityData`, `FriendData`, `NightData` y `ContentCatalog`;
  - `scripts/core/rule_evaluator.gd`: qué regla se aplica, si una respuesta es correcta, de mayor riesgo o incorrecta, y todas las situaciones posibles;
  - `scripts/core/content_validator.gd`: revisa el contenido real al correr las pruebas y avisa en español (cantidades de la plantilla, ids que no existen, reglas que nunca se aplican, características compartidas por más de 2 entidades y textos que faltan);
  - `data/text/messages.csv`, `notebook.csv` y `ui.csv`, con textos `[PROTO]`;
  - El Trauco de ejemplo, los 3 amigos, las 5 noches (valores de `docs/02` §6) y `data/catalog.tres`;
  - sección F de `docs/04`: revisar una entidad en el Inspector y cómo agregar una.
- **Decisión de Benja:** la frase clickeable de una característica va **entre asteriscos** (`vio un *hombrecito*`). Anotada en `CLAUDE.md` y en `docs/02` §9.
- **Decisiones técnicas** (detalle en `docs/08`):
  - las reglas nombran las acciones por id;
  - cada noche lista sus entidades nuevas (ya no existe `intro_night`);
  - un catálogo reúne amigos y noches;
  - la columna `en` queda vacía.

  `docs/02` §10 ya está actualizado con el modelo nuevo.
- **Formato verificado en Godot 4.7.2** con un proyecto de prueba aparte, ya borrado:
  - arrays y diccionarios tipados en `.tres`;
  - el CSV se importa a `data/text/<archivo>.<idioma>.translation`;
  - una celda `en` vacía muestra el español;
  - `TranslationServer` funciona en las pruebas sin interfaz.

### Errores encontrados

- **Los corchetes de `docs/02` §9 chocaban con `[PROTO]` y con el BBCode del chat.** Se reemplazaron por asteriscos.
- **Enlazar el mismo sub-recurso de una acción desde una regla es frágil en el Inspector:** si se crea uno nuevo en vez de copiarlo, la regla queda apuntando a otra acción. Por eso las reglas usan ids.
- **Un `class_name` nuevo no existe para Godot hasta actualizar la caché de clases.** El plan importa (`--import`) después de crear cada clase.

### Pendientes Código

- [ ] **S7: ejecutar el Plan 2** (`docs/08`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [x] **S6: escribir el Plan 2.**
- [ ] Planes 3 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Después de S7:** revisar El Trauco en el Inspector (`docs/04`, F).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara: si convence, se queda; si no, se apaga (*Look Enabled*) y se quita el parallax.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7. Las características llevan su frase clickeable entre asteriscos.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10).

---

## Sesión 5 — 26 de octubre de 2026 (noche) — Plan 1 ejecutado: escena del escritorio

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5. Benja autorizó todos los commits del plan en `main`, sin push.

### Realizado

- **Las 14 tareas de `docs/07`, con 32 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`):
  - ejecutor de pruebas propio en `test/`;
  - pantalla de 1280×720, aspect `keep`, filtro Nearest, snap a píxel, color de fondo y `desk.tscn` como escena principal;
  - `pc_sprite` sin las capas `Entry` y `screen_sprite` importado como textura (el cambio de importador por archivo funcionó, sin necesidad del plan B);
  - matemática del dial, del parallax y de la opacidad por píxel;
  - shader de contorno y `ClickableSprite`, `DialGauge`, `ChatEntry` y `ChatPanel` provisional;
  - `scenes/desk/desk.tscn`, con todo el arte en su lugar, el parallax de la pared (±3, ±2) y el del exterior (±2, ±1 extra).
- **Comparación con la maqueta (`tools/compare_png.py`): 89,6 % al principio y 99,3 % después de que Benja integró la sombra en `background_sprite`.** Fuera de las zonas explicadas solo difieren **63 px (0,01 %)**, así que todo el arte está en su posición exacta. Las diferencias por zona, en la primera comparación:

  | Zona | Píxeles | Causa |
  | --- | --- | --- |
  | Esquina superior derecha (x ≥ 1000) | 9,70 % → 0,03 % | A `background_sprite` le faltaba la capa de sombra; Benja la integró |
  | Diales | 0,28 % | Las agujas apuntan según su valor (1,0 = 120°), no hacia arriba |
  | Última fila | 0,28 % | La maqueta tiene transparentes las filas y = 718–719 (error conocido del maestro) |
  | Termómetro | 0,07 % | No está en `background_sprite`; Benja decidió dejarlo fuera |
  | Entradas | 0,07 % | Ahora tienen los nombres |

- **Escalado a 1080p (Tarea 13):**
  - `--write-movie` graba siempre a 1280×720, así que el ×1,5 se simuló con Nearest sobre recortes del teclado y de un dial;
  - los grosores alternan entre 1 y 2 px; se nota de cerca, pero no rompe la imagen;
  - **recomendación: mantener Nearest en la v1** y dejar el shader de escalado suave en la lista posterior a la v1. Benja decide tras probarlo en su monitor (`docs/04`, D).
- `docs/04`: nuevas secciones C (revisar la escena), D (probar el escalado) y E (mover un objeto).
- **Cambios pedidos por Benja tras probar el juego:**
  - **Termómetro fuera** del arte y del juego (`CLAUDE.md`, diseño v2, `docs/03`, `docs/06` y `art/positions.md`).
  - **El chat se cierra con un clic fuera del panel.** El clic no se consume: si cae en la entrada de otro amigo, se abre su chat.
  - **Cámara que mira hacia el mouse (a prueba)**, en lugar del parallax por planos: zoom ×1,05 y desplazamiento hacia el mouse hasta el margen del zoom. Una prueba confirma que el punto bajo el mouse es el mismo que sin zoom, así que todo sigue alcanzable. Se ajusta o se apaga en el Inspector (`LookCamera`: *Look Enabled*, *Look Zoom* y *Follow Speed*). `parallax_rig.gd` se borró.
  - 36 pruebas OK, 0 fallidas; la comparación con la maqueta (sin cámara) sigue en 99,3 %.
- 15 commits en `main`, con push a GitHub (autorizado por Benja). Después, 3 commits más por los cambios pedidos, sin push.

### Errores encontrados

- **El ejecutor de pruebas del plan tenía dos fallas** (corregidas en `test/run_tests.gd`):
  - una suite cuyo script no cargaba se saltaba en silencio y no contaba como falla;
  - `SceneTree._initialize()` corre **antes** de que la raíz entre al árbol, así que los nodos agregados ahí no recibían `_ready` ni tenían viewport. Ahora las suites corren diferidas (`call_deferred`).
- **El shader de contorno del plan no compilaba en GL Compatibility:** no acepta `TEXTURE` como argumento `sampler2D` de una función propia. Ahora el muestreo va dentro de `fragment()`.
- **A `background_sprite` le faltaba la capa de sombra** de la esquina superior derecha. Benja la integró y aplanó el archivo: corregido. El termómetro queda fuera por decisión de Benja.
- **La aguja rotada se ve dentada incluso a ×1**, porque girar pixel art con Nearest deforma sus bordes. Tenerlo en cuenta en el rediseño de los diales (por ejemplo, agujas pre-dibujadas en varios ángulos).
- **Godot reescribe `project.godot` al importar:** quitó `aspect="keep"` porque es el valor por defecto, y reordenó líneas. No es un problema (la prueba lo confirma).
- **`Camera2D` ya tiene una propiedad `enabled`**: la de la cámara nueva se llama `look_enabled`.
- **El zoom de la cámara (×1,05) escala el pixel art** y puede dar píxeles de ancho desparejo que titilan al moverse. Es una excepción a la regla 10, aceptada para probar.
- **Error de Claude:** una línea suelta (`cat >` sin entrada) colgó el primer comando 5 minutos. No afectó al proyecto.

### Pendientes Código

- [ ] **S6: escribir el Plan 2** (datos y textos), con Opus 5.5 en esfuerzo high (`docs/00_log.md`).
- [x] Volver a comparar con la maqueta tras el arreglo de `background_sprite`: 99,3 %.
- [x] Commitear los `.uid` generados por Godot.
- [ ] Planes 3 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [x] **S5: ejecutar el Plan 1.**

### Pendientes Externos

- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara: si convence, se queda; si no, se apaga (*Look Enabled*) y se quita el parallax.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [x] Termómetro: queda fuera del juego.
- [x] Sombra de la esquina superior derecha integrada en `background_sprite`.
- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10).
- [x] Push a GitHub de los commits de esta sesión (autorizado).

---

## Sesión 4 — 26 de octubre de 2026 (tarde) — Orden del arte, repositorio y registro de sesiones

### Realizado

- **Arte nuevo verificado contra el maestro:**
  - `background_sprite` (1280×720) va en (0, 0) y ya cubre la última fila de píxeles;
  - `exterior_sprite` (251×297) calza al 100 % con el hueco del vidrio, en (273, 121).
- **`art/` ordenado** (autorizado por Benja):
  - `arrrow_sprite` pasó a llamarse `arrow_sprite`;
  - el maestro y su PNG quedaron en `art/_layout/` (`scene_layout.*`), que Godot ignora;
  - se borraron los `.import` sobrantes;
  - Godot reimportó todo: 17 sprites, ninguno con error.
- **Plan 1 (`docs/07`) actualizado:**
  - fondo con `background_sprite`, ya no con el maestro;
  - exterior recortado al vidrio, con su propio parallax (±2, ±1 sobre la pared);
  - nombres nuevos y maqueta en `art/_layout/scene_layout.png`;
  - corregida la verificación de importación (las exitosas no escriben `valid`);
  - regla de commits agregada.
- **Nuevo `docs/00_log.md`:** registro de sesiones con la siguiente (S5), qué documentos son planes que se ejecutan, la secuencia S5 a S23 con modelo y esfuerzo, y los cambios a la secuencia.
- **`CLAUDE.md`:** leer `docs/00_log.md` al empezar y actualizarlo al cerrar; preguntar antes de cada commit; remoto de GitHub; ubicación de la maqueta.
- `art/positions.md` y `docs/06` §3 actualizados.
- **Primer commit y push** a `https://github.com/benjasaldias/SpookDial.git` (autorizado por Benja).

### Errores encontrados

- **`docs/07` esperaba `valid=true` en los `.import`**, pero las importaciones exitosas no escriben esa línea. Corregido.
- **`exterior_sprite` mide justo lo que el vidrio:** al moverse deja ver 1 a 2 px del exterior pintado en `window_sprite`. Es aceptable; si se nota, agrandarlo 8 px por lado (`art/positions.md`).

### Pendientes Código

- [ ] **S5: ejecutar el Plan 1** (`docs/07`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Planes 2 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [x] Primer commit y push.
- [x] Ordenar `art/sprites/`.

### Pendientes Externos

- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Opcional: `exterior_sprite` y `background_sprite` con 8 px extra por lado.
- [ ] Elegir una tipografía pixel (`docs/03` §10).
- [x] `background_sprite` y `exterior_sprite`.
- [x] Crear el repositorio en GitHub.

---

## Sesión 3 — 26 de octubre de 2026 — Diseño cerrado, arte revisado y Plan 1

### Realizado

- **Decisiones de Benja** (en `CLAUDE.md` y en el diseño v2):
  - los amigos **nunca dicen el nombre** de la entidad; se identifica de memoria o **clickeando todas las características destacadas** (espera de unos 3 s);
  - se responde desde la página abierta del cuaderno;
  - cada regla marca la **acción correcta** y la **de mayor riesgo**, que da un video extra;
  - **no existe "Grabar"**;
  - la cuota la cubren los **envíos programados**;
  - si cualquiera de los 3 diales llega a 0, se pierde la noche;
  - el proyecto **se queda en OneDrive**.
- **"Grabar" corregido:** salió por error de una propuesta rechazada de la sesión 1. Se quitó del diseño v2, de `docs/02` y de `CLAUDE.md`.
- **Diseño v2:** §8 (identificación, preguntas, respuesta y reglas), §9 (consecuencias), §10 (diales y cuota), §12 (cuaderno) y §20 (nada por confirmar). `docs/02` reescrito.
- **Calendario recalibrado** en `docs/05` (vamos una semana atrás). El buscador por rasgos sale de la lista posterior a la v1, porque lo reemplazan las características clickeables.
- **Arte revisado:** los 15 archivos de `art/sprites/` se compararon píxel a píxel con el maestro, y las posiciones exactas quedaron en `art/positions.md`. Inventario y faltantes en `docs/06` §3.
- **Nuevo `docs/06_plan_v1.md`:** la v1 dividida en 9 planes, con arquitectura, criterios de cierre y arte faltante por plan.
- **Nuevo `docs/07_plan_escena_arte.md`:** el Plan 1 paso a paso (skill `superpowers:writing-plans`), en 14 tareas con código completo, 32 pruebas, comparación visual con la maqueta y prueba de escalado a 1080p.
- **Entorno:**
  - ruta de Aseprite corregida en `editor_settings-4.7.tres` (con respaldo previo);
  - los 16 `.aseprite` reimportados y verificados (animaciones y tamaños correctos);
  - copia de `C:\dev\spook-dial` borrada, tras confirmar que no tenía nada propio;
  - git reiniciado en OneDrive con su carpeta interna en `/mnt/c/dev/spook-dial.git`;
  - MCP `godot` configurado para la carpeta de OneDrive (y quitado de `C:\dev`).

### Errores encontrados

- **Los 16 `.aseprite` estaban con `valid=false`.** La ruta de Aseprite del paso B nunca se guardó en Godot. Corregida.
- **Godot no reintenta importaciones fallidas.** Borrar el `.md5` no basta: hay que borrar el `.import` (o el `.md5` y el `.res`). Anotado en `CLAUDE.md` y corregido en la Tarea 3 del Plan 1.
- **OneDrive interfiere con la edición:** varias ediciones respondieron "no such file", aunque el cambio quedó escrito. Anotado en `CLAUDE.md`.
- **"Grabar" se había colado en el diseño v2** sin que Benja lo aprobara. Corregido.
- **Pendiente de arte:**
  - el celular sigue con "00:00" dibujado;
  - los diales siguen con cara de reloj;
  - la ventana no tiene el exterior separado;
  - no existe `wall_sprite` (se usa el maestro como fondo provisional);
  - en `art/sprites/` sobran un PNG duplicado y un `icon.svg.import`.

### Pendientes Código

- [ ] **Siguiente sesión: ejecutar el Plan 1** (`docs/07`), con Godot cerrado durante los pasos sin interfaz.
- [ ] Primer commit y push cuando Benja cree el repositorio en GitHub (con su aprobación).
- [ ] Ordenar `art/sprites/` (`docs/06` §3) cuando Benja lo apruebe.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Planes 2 a 9: escribir cada uno en detalle al comenzar su semana (`docs/06` §2).
- [x] Corregir la ruta de Aseprite y verificar la importación (sesión 2).
- [x] Plan de implementación del Hito 1: reemplazado por los Planes 1 a 4 de `docs/06`.

### Pendientes Externos

- [ ] **Godot:** volver al proyecto de OneDrive en el Project Manager (`docs/04`, A).
- [ ] **Crear el repositorio privado en GitHub.**
- [ ] **Entidades:** las 3 primeras (El Tue Tué, La Calchona y El Trauco) con la plantilla nueva de `docs/02` §7. Hacen falta para la semana 2.
- [ ] **Arte para el Plan 1:**
  - `wall_sprite` (Background + Shading + Thermometer, idealmente 1296×736);
  - separar el exterior de la ventana.
- [ ] **Arte para los planes 3 a 5:**
  - interfaz del chat y del cuaderno;
  - barras de señal;
  - celular sin la hora y dígitos LCD;
  - diales rediseñados (`docs/06` §3).
- [ ] Aprobar el orden de `art/sprites/` y decidir si se renombra `arrrow_sprite`.
- [ ] Elegir una tipografía pixel (candidatas en `docs/03` §10).
- [ ] Sonido (semana 6).
- [x] Revisar el diseño v2 y responder sus puntos por confirmar.
- [x] Corregir la ruta de Aseprite: la corrigió Claude.

---

## Sesión 2 — 15 de octubre de 2026 (noche) — Decisiones, diseño v2 y cambio a C:\dev

### Realizado

- Benja respondió las 17 preguntas de la sesión 1 y 4 más (ubicación, cuota, identificación y diseño v2). Todas las decisiones quedaron en `CLAUDE.md`. Las más importantes:
  - acciones propias por entidad, con reglas estilo Keep Talking;
  - final único, con la cuota de contenido como condición para ganar cada noche;
  - señal por amigo con Audio Sync individual;
  - 7 entidades, con los Brujos de Chiloé solo en la historia;
  - el juego es estrictamente el escritorio;
  - entrega el **10 de diciembre**.
- Diseño v2 escrito en `spook_dial_design.md`. El original quedó en `spook_dial_design_v1.md`.
- `docs/02_bucle_central.md` reescrito: reglas por entidad, estática, señal por amigo, valores iniciales, plantilla de entidad, textos en CSV y modelo de datos.
- Nuevo `docs/05_plan_produccion.md`: alcance por prioridad (v1, prioridad 2 y lo de después), calendario al 10 de diciembre y riesgos.
- `docs/03_plan_arte.md` actualizado: plano de pared con parallax leve, `room_wall` y `room_desk`, perillas de los faders, barras de señal y calendario.
- `docs/01` marcado como histórico, con una tabla de qué pasó con cada propuesta. `docs/04` reescrito con el estado de cada paso.
- Proyecto copiado a `C:\dev\spook-dial`, sin `.godot/`. La copia de OneDrive queda como respaldo.
- Git inicializado en `C:\dev\spook-dial` (rama `main`, `core.filemode=false`), sin commits.
- Script `~/tools/godot-wsl.sh`: ejecuta el Godot de Windows desde WSL traduciendo las rutas.
- MCP `godot` configurado **solo para `C:\dev\spook-dial`** (scope local): `GODOT_MCP_ROOT=/mnt/c/dev` y `GODOT_EXECUTABLE=~/tools/godot-wsl.sh`. La configuración global, que usan los otros proyectos de `~/godot-games`, no se tocó.
- Verificado:
  - Aseprite Wizard 9.8.0 está instalado y activado, con SpriteFrames como importador por defecto;
  - el proyecto copiado **carga sin errores en Godot 4.7.2 con el plugin activado** (importación sin interfaz);
  - Aseprite 1.3.18.6 responde en la ruta de Steam;
  - el MCP resuelve la carpeta y el ejecutable correctos.
- Cargado el skill `superpowers:brainstorming`: el diseño v2 es su "spec" y queda esperando la revisión de Benja.

### Errores encontrados

- **La ruta de Aseprite no quedó guardada en Godot.** `editor_settings-4.7.tres` todavía tiene la por defecto (`C:\Steam\…`), así que importar `.aseprite` fallaría (`docs/04`, B).
- **Godot de Windows no puede abrir proyectos dentro de WSL** (su explorador no sale de C:). La copia de `~/godot-games/spook-dial` quedó desactualizada; no es la que Benja movió.
- **El servidor MCP llama a Godot con rutas de Linux**, que el ejecutable de Windows no entiende. Resuelto con `~/tools/godot-wsl.sh`.
- **`project.godot` tiene `aspect = expand`.** Se ajusta tras la prueba de escalado.

### Pendientes Código

- [x] Reconfigurar el MCP y hacer `git init` (sesión 1).
- [x] Actualizar `spook_dial_design.md` a v2 (sesión 1).
- [x] ~~Instalar Aseprite Wizard desde GitHub~~: lo instaló Benja.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Primer commit y push cuando Benja cree el repositorio en GitHub (con su aprobación).
- [ ] Cuando Benja apruebe el diseño v2: plan de implementación del Hito 1 con `superpowers:writing-plans`.
- [ ] Prueba de escalado a 1080p (×1,5): filtro Nearest contra un shader de escalado suave, más el parallax de la ventana y la pared. Con el resultado, fijar la pantalla en `project.godot`.
- [ ] Estructura de carpetas y autoloads (`GameState`, `EventBus`, `AudioManager`, `SaveManager`).
- [ ] Modelo de datos (`docs/02` §10) y carga de textos desde `data/text/*.csv`, con prototipos `[PROTO]`.
- [ ] Hito 1, prototipo del bucle central (`docs/05`, v1 #1 y #2) con 3 entidades y arte provisional.
- [ ] Shader de contorno para el resaltado al pasar el mouse, y detección de clic por píxel.

### Pendientes Externos

- [ ] **Revisar el diseño v2** (`spook_dial_design.md`) y decidir los 3 puntos "por confirmar" de su §20.
- [ ] `docs/04`:
  - A: cambiarse a `C:\dev` en Godot y en VS Code;
  - B: corregir la ruta de Aseprite;
  - C: prueba con un archivo.
- [ ] Crear el repositorio privado en GitHub.
- [ ] Arte P0:
  - corregir los 2 errores del maestro;
  - separar los planos (`room_wall` con 8 px extra por lado, `room_desk` y `exterior`) y los objetos (`docs/03` §5 y §7);
  - dejar en blanco la pantalla del PC y la hora del celular;
  - anotar las posiciones en `art/positions.md`.
- [ ] Arte P1: interfaz del chat, entradas con barras de señal, avatares, íconos, diales rediseñados, mixer en piezas (con las perillas de los faders), LED, dígitos LCD y cursor.
- [ ] Entidades: El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7 **antes del 25 de octubre**; las 7 antes del 18 de noviembre.
- [ ] Elegir una tipografía pixel con ñ, tildes, ¿ y ¡ (candidatas en `docs/03` §10).
- [ ] Sonido (desde el Hito 3): lista de efectos y ambientes, y bibliotecas con licencia clara.
- [x] Responder las preguntas abiertas.
- [x] Decidir la ubicación del proyecto.
- [x] Recargar VS Code: los plugins y el MCP se cargaron en esta sesión.
- [x] Confirmar la fecha de entrega: 10 de diciembre, completo y jugable.

---

## Sesión 1 — 15 de octubre de 2026 — Planificación (sin código)

### Realizado

- Lectura completa de `spook_dial_design.md` y análisis crítico en `docs/01_analisis_diseno.md`: 14 contradicciones, 14 debilidades, alcance recortado, calendario de 11 semanas y 17 preguntas abiertas.
- Análisis del arte, del PNG y del archivo maestro `SpookDial_Sprites.aseprite`, leído sin modificarlo:
  - 20 capas con sus coordenadas;
  - 2 frames y sus diferencias;
  - el arte es nativo a 1280×720, con detalle de 1 px y 268 colores.
- Diseño del bucle central (chat, cuaderno-buscador, preguntas de seguimiento y "Pedir contenido") en `docs/02_bucle_central.md`.
- Plan de arte en `docs/03_plan_arte.md` e instrucciones de Godot en `docs/04_instrucciones_godot.md`.
- Archivos creados: `CLAUDE.md`, `resumen.md`, `docs/` (con `.gdignore`), `art/_layout/.gdignore` y `art/positions.md` (con las coordenadas actuales y el centro de cada dial).
- Decisiones de Benja:
  - si un amigo muere, se reinicia la noche;
  - se mantiene la resolución de 1280×720;
  - Audio Sync se juega en el mixer;
  - el termómetro es decorativo;
  - la entrega es en unos 2,5 meses, y Benja trabaja solo con Claude.
- Verificado:
  - Godot 4.7.2 (Windows) se puede ejecutar desde WSL;
  - el servidor MCP `godot` arranca sin errores;
  - existe Aseprite Wizard v9.8.0 para Godot 4 (pide 4.3 o más; no confirma 4.7).

### Errores encontrados

- **Arte:** la cel de `Background` está en y = −2, así que las filas y = 718–719 quedan **transparentes** en ambos frames (también en el PNG exportado).
- **Arte:** en el frame 2, el brillo verde del LED del micrófono (36 px semitransparentes en x 856–861, y 590–595) está pintado en la capa `SoundMixer` y no en `Microphone`.
- **Arte:** el frame 2 mezcla cambios independientes: el color de las entradas del PC, los ojos de la ventana, la franja de luz de luna en el escritorio, el sombreado del mixer y el LED del micrófono. En una sola línea de tiempo no se pueden animar por separado; se resuelve separando archivos (`docs/03`).
- **Arte y diseño:** los diales parecen relojes (tienen 12 marcas) y se distinguen solo por color (verde, rojo y amarillo). Es un problema de lectura y de daltonismo.
- **Diseño:** 14 contradicciones o vacíos en `spook_dial_design.md` (muerte, Sanity, Trust, contenido extra, Connection, Audio Sync, chat "gibberish", objetos, entidades, finales…). El detalle y la resolución están en `docs/01` §1.
- **Entorno:** el proyecto vive en OneDrive (riesgo de conflictos de sincronización con `.godot/`) y no tiene git.
- **Entorno:** hay una copia duplicada del proyecto en `~/godot-games/spook-dial`. El MCP `godot` solo puede trabajar ahí (`GODOT_MCP_ROOT`), no en la carpeta real.
- **Entorno:** los plugins `superpowers` y `godot` se instalaron minutos antes de la sesión y no se cargaron, igual que las herramientas del MCP `godot`. Hay que recargar VS Code.

### Pendientes Código

- [ ] Cuando Benja decida la ubicación del proyecto: reconfigurar el MCP `godot` (`GODOT_MCP_ROOT`), hacer `git init` con su aprobación y borrar la copia duplicada.
- [ ] Si Benja no pudo instalar Aseprite Wizard desde AssetLib: instalar la v9.8.0 desde GitHub en `addons/`.
- [ ] Prueba de escalado a 1080p (×1,5): filtro Nearest contra un shader de escalado suave, más el parallax de la ventana. Con el resultado, fijar la configuración de pantalla en `project.godot`.
- [ ] Estructura de carpetas y autoloads (`GameState`, `EventBus`, `AudioManager`, `SaveManager`).
- [ ] Modelo de datos como Resources (`TraitData`, `EntityStateData`, `EntityData`, `FriendData`, `NightData`), según `docs/02` §13.
- [ ] Hito 1, prototipo del bucle central con arte provisional:
  - escena del escritorio con objetos clickeables;
  - panel de chat;
  - generador de solicitudes y temporizadores;
  - cuaderno-buscador con marcadores;
  - medidores y reloj de la noche;
  - victoria, derrota y reinicio con pantalla explicativa.
- [ ] Shader de contorno para el resaltado al pasar el mouse, y detección de clic por píxel.
- [ ] Actualizar `spook_dial_design.md` a v2 cuando Benja responda las preguntas, con su aprobación.

### Pendientes Externos

- [ ] **Responder las preguntas abiertas** (`docs/01` §7).
- [ ] Decidir la ubicación del proyecto (recomendado: `C:\dev\spook-dial`, fuera de OneDrive) y si se usa GitHub (`docs/04`, A).
- [ ] Recargar VS Code (*Developer: Reload Window*) para cargar `superpowers`, `godot` y el MCP.
- [ ] Godot: instalar y configurar Aseprite Wizard, y hacer la prueba (`docs/04`, B a F).
- [ ] Arte P0:
  - corregir los 2 errores del maestro;
  - separar los planos y los objetos (`docs/03` §5 y §7);
  - dejar en blanco la pantalla del PC y la hora del celular;
  - separar el exterior de la ventana;
  - anotar las posiciones en `art/positions.md`.
- [ ] Arte P1: interfaz del chat, entradas del PC, avatares, íconos de acción y de rasgo, diales rediseñados con íconos, mixer en piezas, LED genérico, dígitos LCD y cursor.
- [ ] Escritura: bestiario de 6 entidades con la plantilla de `docs/02` §14, y las voces de los amigos.
- [ ] Elegir una tipografía pixel con ñ, tildes, ¿ y ¡ (candidatas en `docs/03` §10).
- [ ] Confirmar la fecha exacta de entrega y qué exige.
- [ ] Sonido (desde el Hito 3): lista de efectos y ambientes, y bibliotecas con licencia clara.
