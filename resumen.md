# Resumen de sesiones — Spook Dial

La entrada más reciente va arriba, y sus listas de pendientes son la lista vigente. En cada cierre se arrastran los pendientes que siguen abiertos y se marcan con [x] los cumplidos.

---

## Sesión 21h — 11 de noviembre de 2026 — Plan 9.3: errores y el chat

La primera de las 3 sesiones con el feedback del primer testeo (`docs/26` §2), en Opus 5.5 · xhigh. Benja contestó 3 preguntas al empezar (autorizó todos los commits, el cuaderno con los colores del chat y el diseño) y una durante el diagnóstico de la descarga. El Plan 9.3 (`docs/27`) se escribió y se ejecutó en la misma sesión, en `main` y sin push. La sesión se detuvo una vez a pedido de Benja, sin pérdidas.

### Realizado

- **Decisión de Benja:** el cuaderno usa los mismos colores que el chat: las condiciones de la tabla en lápiz pasta azul y las características con destacador amarillo.
- **Plan 9.3**, ejecutado en 11 commits, **de 626 a 661 pruebas OK**:
  1. **Las preguntas no se repiten:** cada solicitud recuerda qué se preguntó y si la estática tapó algo que sirve (una característica, un señuelo, una observación o el audio). Solo entonces la pregunta vuelve.
  2. **"Matías piensa" dura 2 s** (`thinking_seconds` en `data/balance.tres`), y **los señuelos ya no cuestan:** se borraron `decoy_cost`, su código, el "−1 s" del chat y la mención en la broma de León.
  3. **La descarga responde al primer clic** (diagnosticado con `systematic-debugging`):
     - la causa era un clic que empieza un instante antes de que aparezca la barra: lo recibía la conversación;
     - ahora el chat sigue el botón del mouse y descarga mientras esté apretado sobre la barra.
  4. **La noche ganada se guarda:** al ganar se guarda la siguiente, y al despedirse León, la noche 1.
  5. **El parpadeo** (`Highlight`): un borde que avisa qué apretar, fijo con "Reducir destellos". Lo reusará el tutorial.
  6. **El arte del chat** (`art/ui/chat_*.png`, de `tools/make_ui_art.py`): los íconos de las preguntas (ojo, parlante, nube con niebla y huella), el ✓ y la estática, el cuaderno del nombre, la señal en barritas y las hojas de respuesta.
  7. **El chat en bloques:** la conversación, la descarga, la identificación y los bloques **PREGUNTAR** y **RESPONDER**, cada uno con un título que dice por qué no se puede usar. Las respuestas tienen su alto reservado, así que nada se mueve al abrir una página.
  8. **Las preguntas** muestran su ícono, una etiqueta corta, su costo ("−5 s") y su marca (✓ o estática). Al preguntar, la pestaña del amigo muestra el "−5 s".
  9. **Las respuestas son hojas del cuaderno,** una debajo de otra, con el número de su columna en una nota adhesiva. Las de un accidente siguen siendo botones de terminal.
  10. **El botón de sincronizar** muestra la señal del amigo en barritas y parpadea sin señal. El nombre de la entidad lleva el ícono del cuaderno.
  11. **Lo decisivo en azul:** las observaciones y el audio en el chat, y en el cuaderno las condiciones y el destacador.
  12. **Revisión** a 1280×720, 1080p y con la ventana maximizada (`test/capture_plan93.gd`, en `C:\dev\capturas\plan93_*.png`). El juego abre sin errores nuevos.
- **Documentos:**
  - `CLAUDE.md` (las decisiones implementadas y 2 notas técnicas);
  - el diseño v2 (§5, §7, §8.3, §8.4, §8.5, §8.8, §10, §12 y §19);
  - `docs/02` (§3);
  - `docs/04` (la sección T, nueva, y 2 frases de la S que habían quedado viejas);
  - `docs/26` (§2 ejecutada), `docs/27` con su resultado, `arte_pendiente.md` y `docs/00_log.md`.
- Esta sesión no tiene sonidos nuevos: `sonidos_pendiente.md` no cambia.

### Errores encontrados

- **La descarga:** no era un botón que aparece bajo el mouse quieto ni la conversación tapando la barra, como suponía `docs/26`. Era un clic que empezaba antes de que la barra se viera. Se arregló.
- **El guardado:** ganar y volver al menú hacía repetir la noche ganada. Se arregló.
- **Al simular el mouse en las pruebas,** los clics no llegaban: sin pantalla, la ventana mide 64×64 y hay que usar coordenadas locales (`push_input(evento, true)`). Quedó anotado en `CLAUDE.md`.
- **Corregidos con las capturas:**
  - la oreja de 9×9 parecía un "?", y pasó a ser un parlante;
  - el "−5 s" en rojo no se leía sobre la conversación, y ahora lleva fondo;
  - las líneas CRT rayaban las hojas, que ahora van por encima;
  - las respuestas en 2×2 no cabían a 1080p, y van en una columna.
- **Las pruebas no dejan pasar cuadros,** y el chat en un `VBoxContainer` se acomoda al final de cada cuadro. Las pruebas que miran posiciones lo acomodan a mano.
- **El escritorio suelto** sigue avisando al cerrar que `ambient_room.wav` y su reproducción quedan sin liberar (el pendiente menor de siempre).

### Pendientes Código

- [ ] **S21i y S21j: el resto del feedback del primer testeo** (`docs/26`): Normal y Difícil, y el tutorial. **S21i es la siguiente.**
  - En Difícil se apagan el amarillo, el azul, los clics y "Matías piensa" (`ChatMessageView` y el chat).
  - El tutorial usa el parpadeo (`Highlight`), las hojas y el botón de las barritas. León explica lo azul, el costo de preguntar y los audios. `TUTORIAL_LEON_SIGNAL_WARN` ya dice "el botón de las barritas".
- [ ] **Si la conversación queda baja con la ventana maximizada** (escala 1,4, letra de 16): con el video y las hojas a la vista se leen unas 6 líneas. Si Benja lo nota, achicar el alto reservado de las respuestas o la letra del nombre de la entidad.
- [ ] Menor: la ayuda del botón de las barritas ("Sincronizar") lleva el estilo de la terminal en el tema, pero no se revisó en una captura.
- [ ] **Pantalla completa:** el juego no tiene opción para ponerla (F11 o en Opciones). Para el Plan 10, si Benja la quiere.
- [ ] Si Benja redibuja algo que se ve en los videos de las tarjetas (las barras, los diales, la ventana, el celular o la Mano): volver a grabarlos con `tools/make_tutorial_videos.sh`.
- [ ] Menor: si el jugador pregunta muy rápido en la noche 0, las líneas de León pueden llegar después de las respuestas. **Se resuelve en S21j** (`docs/26` §4.3).
- [ ] Menor: el final de la noche 0 con la pantalla de "Práctica terminada" (`END_TUTORIAL*`, en `EndingText`) ya no se usa; se puede borrar.
- [ ] **Según lo que diga Benja de la visibilidad de la Mano:** dejarla así, que asome más cerca del dial (`HandVisit.START_X`), un borde tenue por shader o arte nuevo de Benja.
- [ ] Si en la prueba con personas la Mano agarra casi siempre: alargar `hand_approach_seconds` o hacer más fuerte el crujido (`Hands/CreakSound`).
- [ ] Para otro momento (`docs/22`): A6 (reacciones por entidad), A7 ("Matías piensa" a 1 s; S21h lo bajó a 2 s, y se cambia en `thinking_seconds`) y las secciones B a E.
- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`, S21b): después de S21j.
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q y R), también el crujido y el flash.
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 y del 9.1 son de partida y se ajustan ahí, y `test_balance.gd` avisa si una noche deja de poder ganarse.
- [ ] Si en las pruebas con personas no entienden los accidentes: enseñarlos en la noche 0 (Audio Sync ya se enseña; S21j lo refuerza con el ícono de señal).
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar (`ambient_room.wav` y su reproducción, confirmado en S21h).
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram (y el rayo de la linterna), y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja, también los íconos del chat, la señal y las hojas.
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo.
- [x] ~~Marcar en el chat qué categorías ya se preguntaron~~ (S21h: el ✓ de cada pregunta).
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.

### Pendientes Externos

- [ ] **Probar el chat nuevo, la descarga y el guardado** (`docs/04`, T, unos 15 minutos). Dime si se entiende qué hace cada botón, si el azul se distingue y si las hojas se sienten parte del cuaderno.
- [ ] **Corregir los textos nuevos del Plan 9.3** antes del 25 de noviembre, en `ui.csv`:
  - los títulos: `CHAT_ASK_TITLE`, `CHAT_ANSWER_TITLE`, `CHAT_NO_TIME` y `CHAT_NO_SIGNAL`, y los que se acortaron, `CHAT_OPEN_NOTEBOOK` y `CHAT_OFFLINE`;
  - las preguntas cortas, `QUESTION_*_SHORT`, y el costo, `CHAT_QUESTION_COST`;
  - León: `TUTORIAL_LEON_DECOY` y `TUTORIAL_LEON_SIGNAL_WARN`.
- [ ] **Si quieres:** redibujar los íconos del chat, la señal o las hojas (`arte_pendiente.md`).
- [ ] **Abrir S21i** (`Lee docs/26_feedback_testeo_1.md y haz la sesión S21i.`), después S21j y S21b.
- [ ] **Revisar `docs/26`**, sobre todo los valores propuestos para Normal (§3.3) y el orden de la conversación de León (§4.3).
- [ ] **Probar el Plan 9.2** (`docs/04`, S, unos 15 minutos): la letra con la ventana grande, el cuaderno y la noche 0 con León. Dime qué líneas de León cambiarías.
- [ ] **Corregir los textos nuevos del Plan 9.2** antes del 25 de noviembre:
  - lo que dice León (`TUTORIAL_LEON_*`), las tarjetas (`TUTORIAL_CARD_*` y `TUTORIAL_CARDS_*`) y `PAUSE_SKIP_TUTORIAL`, en `ui.csv`;
  - lo que cuenta de Gonzalo (`TUTORIAL_TRAIT_*`, `TUTORIAL_DECOY_HOODIE` y `TUTORIAL_OBS_*`), en `messages.csv`;
  - su página (`TUTORIAL_PAGE_*`, `TUTORIAL_ACTION_*` y `TUTORIAL_RULE_*`) y `NOTEBOOK_RULES`, `NOTEBOOK_CONDITION` y `NOTEBOOK_RISK_LEGEND`, en `notebook.csv`;
  - `IDENTIFY_PROGRESS` y `MIXER_HINT` se acortaron para caber.
- [ ] **Si quieres:** un boceto de Gonzalo para su página, o redibujar las marcas de la tabla (`arte_pendiente.md`).
- [ ] **Probar el Plan 9.1** (`docs/04`, R, unos 20 minutos) y decir **desde qué momento ves la Mano**, si guardar batería se vuelve una decisión y cómo se sienten las olas y las calmas.
- [ ] **Corregir los textos nuevos del Plan 9.1** antes del 25 de noviembre:
  - lo que le pasa al amigo (`PREDICAMENT_*`) y las variantes de las características (`TRAIT_*_2` a `_4`), en `messages.csv`;
  - los nombres de las características en el cuaderno (`TRAIT_*_LABEL`), en `notebook.csv`;
  - `CHAT_VIDEOS_SHORT` y `PC_VIDEOS_SHORT`, en `ui.csv` (`CHAT_DECOY_COST` ya no existe);
  - `PHONE_FLASH`, en `phone.csv`.
- [ ] **Escuchar el crujido de la Mano y el flash** (`audio/sfx/hand_creak.wav` y `phone_flash.wav`; `sonidos_pendiente.md`).
- [ ] **Si quieres:** pelos o un borde más claros en el brazo de la Mano, para que se vea antes sobre el lado oscuro, o un cuadro de agarre y una retirada (`arte_pendiente.md`).
- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio), **del Plan 9.1** (`docs/24`) y **del Plan 9.3** (`docs/27`), sobre todo el modelo de "jugar bien" de la prueba de equilibrio.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos). Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar y que preguntar cuesta tiempo, si distinguen lo amarillo de lo azul, si reconocen las características dichas con otras palabras, si ven y oyen la Mano, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21g — 11 de noviembre de 2026 — Feedback del primer testeo: planificación

Benja hizo la primera prueba con un tester que nunca había visto el juego (jugador ocasional de Switch, sin interrupciones) y trajo 16 observaciones. Sesión de planificación, sin código, en Opus 5.5.

### Realizado

- **Lectura del código** que tocan las observaciones: el chat, el tutorial, el director, el guardado y los datos de las noches.
- **8 decisiones de Benja**, en 2 rondas de preguntas:
  - Normal y Difícil se eligen solo al empezar; Difícil se desbloquea al terminar Normal y empieza en la noche 1;
  - Normal es una curva suave en las 5 noches;
  - Difícil no destaca nada;
  - los señuelos no cuestan en ningún modo;
  - Gonzalo, en el tutorial, es una demostración guiada;
  - la noche 1 de Normal va sin accidente;
  - estas sesiones van antes del lore.
- **`docs/26_feedback_testeo_1.md`:** las decisiones, el diseño de cada cambio y **3 sesiones** en Opus 5.5 · xhigh, cada una con su plan:
  - **S21h:** errores y el chat (Plan 9.3);
  - **S21i:** Normal y Difícil (Plan 9.4);
  - **S21j:** el tutorial (Plan 9.5).
- Lleva una tabla que ubica cada observación y propone los valores de Normal.
- **Documentos:**
  - `docs/00_log.md`: S21h es la siguiente y S21b pasa después de S21j;
  - `CLAUDE.md`: 3 decisiones nuevas y `docs/26` en la tabla.
- El diseño v2 se actualiza en cada sesión, cuando implementa la decisión.

### Errores encontrados

- **De la lectura del código:**
  - la partida solo se guarda al comienzo de cada noche, así que ganar y volver al menú hace repetir la noche (`GameState.prepare_night`);
  - el botón de descarga tiene 3 causas posibles, anotadas en `docs/26` §2.5.
- Ninguno se arregló todavía: son de S21h.

### Pendientes Código

- [ ] **Pantalla completa:** el juego no tiene opción para ponerla (F11 o en Opciones). Para el Plan 10, si Benja la quiere.
- [ ] Si Benja redibuja algo que se ve en los videos de las tarjetas (las barras, los diales, la ventana, el celular o la Mano): volver a grabarlos con `tools/make_tutorial_videos.sh`.
- [ ] Menor: si el jugador pregunta muy rápido en la noche 0, las líneas de León pueden llegar después de las respuestas. **Se resuelve en S21j** (`docs/26` §4.3).
- [ ] Menor: el final de la noche 0 con la pantalla de "Práctica terminada" (`END_TUTORIAL*`, en `EndingText`) ya no se usa; se puede borrar.
- [ ] **Según lo que diga Benja de la visibilidad de la Mano:** dejarla así, que asome más cerca del dial (`HandVisit.START_X`), un borde tenue por shader o arte nuevo de Benja.
- [ ] Si en la prueba con personas la Mano agarra casi siempre: alargar `hand_approach_seconds` o hacer más fuerte el crujido (`Hands/CreakSound`).
- [ ] Para otro momento (`docs/22`): A6 (reacciones por entidad), A7 ("Matías piensa" a 1 s; S21h lo baja a 2 s) y las secciones B a E.
- [ ] **S21h, S21i y S21j: el feedback del primer testeo** (`docs/26`): errores y el chat, Normal y Difícil, y el tutorial. **S21h es la siguiente.**
- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`, S21b): después de S21j.
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q y R), también el crujido y el flash.
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 y del 9.1 son de partida y se ajustan ahí, y `test_balance.gd` avisa si una noche deja de poder ganarse.
- [ ] Si en las pruebas con personas no entienden los accidentes: enseñarlos en la noche 0 (Audio Sync ya se enseña; S21j lo refuerza con el ícono de señal).
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram (y el rayo de la linterna), y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja.
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo. (Marcar las categorías ya preguntadas entra en S21h.)
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.

### Pendientes Externos

- [ ] **Probar el Plan 9.2** (`docs/04`, S, unos 15 minutos): la letra con la ventana grande, el cuaderno y la noche 0 con León. Dime qué líneas de León cambiarías.
- [ ] **Corregir los textos nuevos del Plan 9.2** antes del 25 de noviembre:
  - lo que dice León (`TUTORIAL_LEON_*`), las tarjetas (`TUTORIAL_CARD_*` y `TUTORIAL_CARDS_*`) y `PAUSE_SKIP_TUTORIAL`, en `ui.csv`;
  - lo que cuenta de Gonzalo (`TUTORIAL_TRAIT_*`, `TUTORIAL_DECOY_HOODIE` y `TUTORIAL_OBS_*`), en `messages.csv`;
  - su página (`TUTORIAL_PAGE_*`, `TUTORIAL_ACTION_*` y `TUTORIAL_RULE_*`) y `NOTEBOOK_RULES`, `NOTEBOOK_CONDITION` y `NOTEBOOK_RISK_LEGEND`, en `notebook.csv`;
  - `IDENTIFY_PROGRESS` y `MIXER_HINT` se acortaron para caber.
- [ ] **Si quieres:** un boceto de Gonzalo para su página, o redibujar las marcas de la tabla (`arte_pendiente.md`).
- [ ] **Probar el Plan 9.1** (`docs/04`, R, unos 20 minutos) y decir **desde qué momento ves la Mano**, si guardar batería se vuelve una decisión y cómo se sienten las olas y las calmas.
- [ ] **Corregir los textos nuevos del Plan 9.1** antes del 25 de noviembre:
  - lo que le pasa al amigo (`PREDICAMENT_*`) y las variantes de las características (`TRAIT_*_2` a `_4`), en `messages.csv`;
  - los nombres de las características en el cuaderno (`TRAIT_*_LABEL`), en `notebook.csv`;
  - `CHAT_DECOY_COST`, `CHAT_VIDEOS_SHORT` y `PC_VIDEOS_SHORT`, en `ui.csv` (los textos del tutorial viejo ya no existen: los reemplazó el chat de León);
  - `PHONE_FLASH`, en `phone.csv`.
- [ ] **Escuchar el crujido de la Mano y el flash** (`audio/sfx/hand_creak.wav` y `phone_flash.wav`; `sonidos_pendiente.md`).
- [ ] **Si quieres:** pelos o un borde más claros en el brazo de la Mano, para que se vea antes sobre el lado oscuro, o un cuadro de agarre y una retirada (`arte_pendiente.md`).
- [ ] **Abrir S21h** (`Lee docs/26_feedback_testeo_1.md y haz la sesión S21h.`), después S21i, S21j y S21b.
- [ ] **Revisar `docs/26`**, sobre todo los valores propuestos para Normal (§3.3) y el orden de la conversación de León (§4.3).
- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio) y **del Plan 9.1** (`docs/24`, al inicio), sobre todo el modelo de "jugar bien" de la prueba de equilibrio.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos). Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si reconocen las características dichas con otras palabras, si ven y oyen la Mano, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21f (continuación) — 11 de noviembre de 2026 — Plan 9.2: la letra nítida, el cuaderno con tabla y el tutorial con León

Después del Plan 9.1, Benja pidió 3 cambios. Se diseñaron con 4 preguntas cortas; Benja aprobó el diseño y los commits, y el Plan 9.2 (`docs/25`) se escribió y se ejecutó en la misma sesión.

### Realizado

- **Decisiones de Benja (las 4 preguntas):**
  - la acción de mayor riesgo se marca con una **calavera** en la tabla;
  - León enseña también **a preguntar y a descargar el video**;
  - **el susto guionado y su chat se quitan** de la noche 0;
  - **"Saltar tutorial" va en la pausa**.
- **Plan 9.2**, ejecutado en 6 commits, **de 613 a 625 pruebas OK**:
  1. **La letra nítida en pantalla completa.**
     - Departure Mono solo es nítida si su tamaño real es múltiplo de 11 px. A 1080p, la de 11 quedaba en 16,5 px reales, con trazos disparejos.
     - `PixelText` (autoload `PixelTextSizer`) apunta a un tamaño real: a 1080p la letra pasa a 15 (22 px reales); en una ventana maximizada, a 16; a 1280×720, 1440p y 4K queda igual.
     - Lo aplica a los temas, a los nodos con tamaño propio y al texto dibujado por código.
  2. **El cuaderno:**
     - sin las preguntas entre paréntesis ni la lista de observaciones;
     - las reglas en una tabla, **Condición | 1 | 2 | 3 | 4**, con ✓ verde, calavera roja y ✗ (íconos de 9×9 en `art/ui/`), y la leyenda de la calavera;
     - las acciones numeradas y la cuadrícula más suave.
  3. **La noche 0 en el chat con León.**
     - `TutorialChat` (lógica pura) lleva la conversación: preguntar, marcar (con el polerón rojo como señuelo), preguntar por el ambiente, abrir la página de Gonzalo, la mejor decisión y la peor (si se elige otra, "intenta de nuevo"), el video, la señal que se corta y la despedida.
     - La página de Gonzalo (`data/tutorial/gonzalo.tres`) es la única del cuaderno esa noche.
     - Se borraron `TutorialGuide`, el aviso de arriba y 22 textos viejos. El chat del susto quedó guardado en `data/scripts/scare_chat.tres`.
  4. **Las tarjetas con videos:** 4 videos reales del juego, grabados con el Movie Maker de Godot (`test/record_tutorial_clips.gd` y `tools/make_tutorial_videos.sh`, en Theora): los medidores, el celular, la ventana (vertical, para que se vea la sombra) y la Mano. Las tarjetas son datos de la noche 0 (`TutorialCardData`).
  5. **Revisión a 1080p** (`test/capture_plan92.gd`): la placa de las barras más ancha, el porcentaje del celular, "Videos" en el PC, 2 textos más cortos, y la noche 0 sin el aviso de videos que faltan.
- **Documentos:**
  - `CLAUDE.md` (4 decisiones nuevas, notas en las que cambiaron y las herramientas nuevas);
  - el diseño v2 (§5, §7, §11, §12 y §14);
  - `docs/02` (§3, §9 y §10);
  - `docs/04` (la sección S, nueva, y las L y R, corregidas);
  - `arte_pendiente.md`, el plan con su resultado y `docs/00_log.md`.

### Errores encontrados

- **La primera regla de la letra fallaba con la ventana maximizada:** a 1920×1009 la escala es 1,4, y la letra quedaba en 8 px. Se cambió la regla para que apunte al tamaño real.
- **La tabla del cuaderno no mostraba bordes:** en Godot 4.7, `[cell=6 border=…]` ignora las opciones; la sintaxis que funciona es `[cell expand=6 padding=…]`, con el borde en el tema.
- **El video de la ventana no mostraba a la criatura ni la sombra** en 640×360. Pasó a ser vertical.
- **En la noche 0, el PC avisaba que faltaban videos** antes de que León mandara el suyo. Se corrigió.
- **El juego no tiene opción de pantalla completa:** `docs/04` no puede pedir una tecla. Quedó como pendiente.
- **Un script de prueba temporal se coló en un commit** (`test/_nb_probe.gd`) y se sacó en el siguiente.

### Pendientes Código

- [ ] **Pantalla completa:** el juego no tiene opción para ponerla (F11 o en Opciones). Para el Plan 10, si Benja la quiere.
- [ ] Si Benja redibuja algo que se ve en los videos de las tarjetas (las barras, los diales, la ventana, el celular o la Mano): volver a grabarlos con `tools/make_tutorial_videos.sh`.
- [ ] Menor: si el jugador pregunta muy rápido en la noche 0, las líneas de León pueden llegar después de las respuestas. Si en la prueba se nota, esperar a que León termine de escribir antes de responder.
- [ ] Menor: el final de la noche 0 con la pantalla de "Práctica terminada" (`END_TUTORIAL*`, en `EndingText`) ya no se usa; se puede borrar.
- [ ] **Según lo que diga Benja de la visibilidad de la Mano:** dejarla así, que asome más cerca del dial (`HandVisit.START_X`), un borde tenue por shader o arte nuevo de Benja.
- [ ] Si en la prueba con personas la Mano agarra casi siempre: alargar `hand_approach_seconds` o hacer más fuerte el crujido (`Hands/CreakSound`).
- [ ] Para otro momento (`docs/22`): A6 (reacciones por entidad), A7 ("Matías piensa" a 1 s) y las secciones B a E.
- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`, S21b): es la sesión siguiente.
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q y R), también el crujido y el flash.
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 y del 9.1 son de partida y se ajustan ahí, y `test_balance.gd` avisa si una noche deja de poder ganarse.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram (y el rayo de la linterna), y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja.
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.

### Pendientes Externos

- [ ] **Probar el Plan 9.2** (`docs/04`, S, unos 15 minutos): la letra con la ventana grande, el cuaderno y la noche 0 con León. Dime qué líneas de León cambiarías.
- [ ] **Corregir los textos nuevos del Plan 9.2** antes del 25 de noviembre:
  - lo que dice León (`TUTORIAL_LEON_*`), las tarjetas (`TUTORIAL_CARD_*` y `TUTORIAL_CARDS_*`) y `PAUSE_SKIP_TUTORIAL`, en `ui.csv`;
  - lo que cuenta de Gonzalo (`TUTORIAL_TRAIT_*`, `TUTORIAL_DECOY_HOODIE` y `TUTORIAL_OBS_*`), en `messages.csv`;
  - su página (`TUTORIAL_PAGE_*`, `TUTORIAL_ACTION_*` y `TUTORIAL_RULE_*`) y `NOTEBOOK_RULES`, `NOTEBOOK_CONDITION` y `NOTEBOOK_RISK_LEGEND`, en `notebook.csv`;
  - `IDENTIFY_PROGRESS` y `MIXER_HINT` se acortaron para caber.
- [ ] **Si quieres:** un boceto de Gonzalo para su página, o redibujar las marcas de la tabla (`arte_pendiente.md`).
- [ ] **Probar el Plan 9.1** (`docs/04`, R, unos 20 minutos) y decir **desde qué momento ves la Mano**, si guardar batería se vuelve una decisión y cómo se sienten las olas y las calmas.
- [ ] **Corregir los textos nuevos del Plan 9.1** antes del 25 de noviembre:
  - lo que le pasa al amigo (`PREDICAMENT_*`) y las variantes de las características (`TRAIT_*_2` a `_4`), en `messages.csv`;
  - los nombres de las características en el cuaderno (`TRAIT_*_LABEL`), en `notebook.csv`;
  - `CHAT_DECOY_COST`, `CHAT_VIDEOS_SHORT` y `PC_VIDEOS_SHORT`, en `ui.csv` (los textos del tutorial viejo ya no existen: los reemplazó el chat de León);
  - `PHONE_FLASH`, en `phone.csv`.
- [ ] **Escuchar el crujido de la Mano y el flash** (`audio/sfx/hand_creak.wav` y `phone_flash.wav`; `sonidos_pendiente.md`).
- [ ] **Si quieres:** pelos o un borde más claros en el brazo de la Mano, para que se vea antes sobre el lado oscuro, o un cuadro de agarre y una retirada (`arte_pendiente.md`).
- [ ] **Abrir S21b** (planificar el lore, `docs/19`).
- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio) y **del Plan 9.1** (`docs/24`, al inicio), sobre todo el modelo de "jugar bien" de la prueba de equilibrio.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos). Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si reconocen las características dichas con otras palabras, si ven y oyen la Mano, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21f — 11 de noviembre de 2026 — Plan 9.1: ajustes de mecánicas y la Mano

Sesión de diseño corto, plan y ejecución, en Opus 5.5 · xhigh, con el prompt `docs/23`. Benja contestó las 6 preguntas, autorizó todos los commits al empezar y el plan (`docs/24`) se ejecutó completo, en `main` y sin push.

### Realizado

- **Decisiones de Benja (las 6 preguntas):**
  - la segunda forma de bajar Trust es **un video perdido (−10)**;
  - el flash se usa con un **ícono en la barra superior del celular abierto** (un rayo);
  - **la Mano va detrás del cuaderno**, y para que se note, **suena un crujido sutil** de algo que se retuerce en cada tirón (pedido de Benja, que cambia el "en silencio" del 11-nov);
  - en **Connection** baja las 3 señales parejo, y **Trust** se trata igual que los otros diales;
  - la Mano llega **desde la noche 1 (1, 1, 2, 2 y 3 veces)** y la **noche 0 la enseña** con el celular abierto;
  - Benja confirmó la tabla de valores, que trae 2 cambios: la batería pasa de **38 a 48 s**, y el tiempo para responder de las noches 4 y 5 sube a **50 y 45 s**.
- **Plan 9.1** (`docs/24_plan_ajustes_mecanicas.md`), escrito y ejecutado: 12 commits, **de 556 a 613 pruebas OK**.
  1. **El mensaje inicial:** saludo, qué le pasa al amigo (8 frases) y, a veces, el lugar (60, 55, 50, 45 y 40 %).
  2. **Las características con otras palabras:** de 2 a 3 formas más para cada una de las 18 (54 textos), y un nombre fijo en el cuaderno. El validador exige el nombre, de 2 a 4 formas con una frase entre asteriscos, y que las compartidas se digan igual.
  3. **El señuelo cuesta 1 s,** con "−1 s" en el chat mientras vibra.
  4. **Trust no se recupera,** un video perdido le quita 10 y una respuesta incorrecta, 15.
  5. **El aviso de que los videos no alcanzan,** en el chat y en rojo en el PC.
  6. **El director de olas,** reescrito:
     - silencio hasta los 60 s, olas de 2 con 4 a 8 s entre una solicitud y otra, y calmas de 40 a 60 s desde que se resuelve la ola;
     - una ola final de 3, con los 3 amigos a la vez, entre las 04:29 y las 04:59;
     - las interferencias, los accidentes y la Mano caen en las olas; los videos y los screamers, en las calmas;
     - solicitudes: 7, 7, 9, 9 y 11;
     - con "Temporizadores ×1,5", una solicitud no pasa de las 06:00.
  7. **La criatura se queda entre 15 y 40 s al azar.**
  8. **La Mano:**
     - `HandVisit` (lógica) y `HandManager` (escritorio), con el sprite de Benja importado por Claude;
     - tarda 12 s en llegar a tirones, agarrada baja el dial 6 por segundo hasta 15 y se queda;
     - la espanta el flash (10 % de batería) y no coincide con la criatura;
     - en la noche 0 llega 5 s después de abrir el celular.
  9. **Sonidos:** `hand_creak.wav` (sutil, −26 LUFS) y `phone_flash.wav`, en `tools/make_sounds.py`.
  10. **Prueba de equilibrio:** `test/balance_model.gd` corre el director real con un jugador que "juega bien". `test_balance.gd` comprueba en las 5 noches, con 20 semillas, que nada vence, que Trust termina sobre 75 y que la batería alcanza. La noche 5 pide 90 %: es la más justa, con 6,9 s de holgura en su peor semilla.
  11. **Curva de olas:** `test/dump_waves.gd` y `tools/plot_waves.py`.
- **Capturas revisadas** (`C:\dev\capturas\plan91_*.png`): la Mano a mitad de camino y sobre el dial de Sanity, el flash, un mensaje sin lugar, una característica con otras palabras y su nombre en el cuaderno, el aviso de videos y la curva de olas de las noches 3 y 5.
- **Documentos:**
  - `CLAUDE.md` y el diseño v2 (§5, §8.1 a §8.3, §10.2 a §10.4, §11, §12 y §14), con las decisiones del 11-nov y sus valores, y anotaciones en las decisiones anteriores que cambiaron;
  - `docs/02` §2, §3, §6, §9 y §10;
  - `docs/04`: la sección R, nueva, y la sección I, corregida;
  - `sonidos_pendiente.md`, `arte_pendiente.md`, `art/positions.md` (la fila de `hand_sprite`) y `docs/00_log.md`.

### Errores encontrados

- **Un video podía caer encima de la ola final.** Lo encontró la prueba de equilibrio: en la noche 5, un video de la última calma llegaba 0,3 s antes de la final y le quitaba los 10 s de su descarga. Se corrigió en el director: el video de una calma llega a más tardar 25 s antes de la ola siguiente.
- **La Mano casi no se ve a mitad de camino** (`plan91_mano_camino.png`). El lado derecho del cuarto es casi negro, igual que el brazo, así que recién se distingue en los últimos 3 o 4 s del camino. Antes, solo la delata el crujido. La prueba de equilibrio supone que se espanta antes de que agarre: hay que ver en la prueba si se alcanza.
- **Con olas de verdad, el tiempo de las noches 4 y 5 no alcanzaba** para la ola final (3 a la vez). Se subió con el visto bueno de Benja.
- **Con 38 s de batería, la noche 5 no se podía ganar** (pedía 106 %). Se subió a 48 s con el visto bueno de Benja.
- **El editor de Godot cerrado permitió importar la Mano por consola:** no hizo falta un paso en `docs/04`.
- Menor: `String.num(1.0)` da "1.0" en Godot 4.7. El "−1 s" se arma con `"%.1f"` sin el ".0" final.

### Pendientes Código

- [x] S21f: ajustes de mecánicas y la Mano (`docs/24`).
- [x] Pasar las decisiones del 11-nov al diseño v2, con sus valores.
- [x] Registrar `hand_sprite` en `art/positions.md` e importarlo con Aseprite Wizard.
- [ ] **Según lo que diga Benja de la visibilidad de la Mano:** dejarla así, que asome más cerca del dial (`HandVisit.START_X`), un borde tenue por shader o arte nuevo de Benja.
- [ ] Si en la prueba con personas la Mano agarra casi siempre: alargar `hand_approach_seconds` o hacer más fuerte el crujido (`Hands/CreakSound`).
- [ ] Para otro momento (`docs/22`): A6 (reacciones por entidad), A7 ("Matías piensa" a 1 s) y las secciones B a E.
- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`, S21b): es la sesión siguiente.
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q y R), también el crujido y el flash.
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 y del 9.1 son de partida y se ajustan ahí, y `test_balance.gd` avisa si una noche deja de poder ganarse.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram (y el rayo de la linterna), y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja.
- [x] ~~Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes~~: desde el Plan 9.1, las interferencias caen en las olas y los videos en las calmas (decisión de Benja).
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.

### Pendientes Externos

- [ ] **Probar el Plan 9.1** (`docs/04`, R, unos 20 minutos) y decir **desde qué momento ves la Mano**, si guardar batería se vuelve una decisión y cómo se sienten las olas y las calmas.
- [ ] **Corregir los textos nuevos del Plan 9.1** antes del 25 de noviembre:
  - lo que le pasa al amigo (`PREDICAMENT_*`) y las variantes de las características (`TRAIT_*_2` a `_4`), en `messages.csv`;
  - los nombres de las características en el cuaderno (`TRAIT_*_LABEL`), en `notebook.csv`;
  - `CHAT_DECOY_COST`, `CHAT_VIDEOS_SHORT`, `PC_VIDEOS_SHORT`, `TUTORIAL_HAND`, `TUTORIAL_HAND_DONE` y los cambios en `TUTORIAL_DIALS`, `TUTORIAL_MARK`, `TUTORIAL_SCROLL` y `TUTORIAL_OPEN_CURTAINS`, en `ui.csv`;
  - `PHONE_FLASH`, en `phone.csv`.
- [ ] **Escuchar el crujido de la Mano y el flash** (`audio/sfx/hand_creak.wav` y `phone_flash.wav`; `sonidos_pendiente.md`).
- [ ] **Si quieres:** pelos o un borde más claros en el brazo de la Mano, para que se vea antes sobre el lado oscuro, o un cuadro de agarre y una retirada (`arte_pendiente.md`).
- [ ] **Abrir S21b** (planificar el lore, `docs/19`).
- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio) y **del Plan 9.1** (`docs/24`, al inicio), sobre todo el modelo de "jugar bien" de la prueba de equilibrio.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos). Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si reconocen las características dichas con otras palabras, si ven y oyen la Mano, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21e — 10 y 11 de noviembre de 2026 — Diagnóstico de las mecánicas

Sesión pedida por Benja, en Opus 5.5: un escaneo profundo de lo que hace que el juego se sienta plano y las ideas para mejorarlo. Sin código.

### Realizado

- **Diagnóstico** (`docs/22_diagnostico_mecanicas.md`). Se revisaron el código, los datos de las 6 noches y las 7 entidades, los textos y las capturas. Los hallazgos principales:
  - **el lugar delata a la entidad:** de los 13 lugares, 12 son de una sola entidad;
  - **los señuelos no cuestan nada,** así que clickear todo identifica a la entidad;
  - **el cuaderno dice qué preguntar,** y la regla trae la acción con el mismo texto del botón;
  - **en las 7 entidades, la regla 1 depende del audio,** y «¿Cómo está el ambiente?» nunca decide una acción;
  - **las olas no existen:** según la simulación del director, las solicitudes llegan cada 40 a 110 s, y en la noche 1 nunca hay 2 a la vez, aunque no se conteste;
  - **la acción de mayor riesgo nunca conviene,** porque la cuota ya está cubierta;
  - **lo que muestran las barras casi nunca hace perder;**
  - **el terror queda detrás del chat y del cuaderno.**

  Propuestas en 5 grupos: A (arreglos baratos), B (que decidir cueste pensar), C (el terror en el chat), D (cambios grandes) y E (recortes).
- **Decisiones de Benja (11-nov):**
  - el mensaje inicial dice qué le pasa al amigo y menciona el lugar solo a veces;
  - los señuelos cuestan 1 s y las características se dicen con sinónimos;
  - olas de verdad y un final fuerte;
  - la cuota **no** sube;
  - aviso cuando los videos ya no alcanzan;
  - la criatura se queda un tiempo al azar;
  - **la Mano** (idea suya): asoma en silencio por la derecha hacia un dial al azar y lo baja hasta un mínimo; se espanta con el flash del celular, que gasta batería;
  - **Trust sin recuperación,** con una segunda forma de bajar por decidir.

  Ya están en `CLAUDE.md`. El diseño v2 se actualiza en S21f, junto con los valores.
- **El sprite de la Mano**, revisado: 319×81, 3 cuadros, sin tags. En la maqueta (capa `Hand`, cuadro 2), agarra el dial de Connection.
- **Prompt de la siguiente sesión** (`docs/23_prompt_ajustes_mecanicas.md`), para Opus 5.5 · xhigh. Trae las skills que hay que usar, las decisiones y 6 preguntas, cada una con una opción recomendada. Claude recomienda que el flash cueste **10 %** de la batería, y no 5 %, y que **un video perdido baje Trust**.
- **Documentos:** `CLAUDE.md` (6 decisiones y 2 documentos nuevos) y `docs/00_log.md` (S21e cerrada, S21f siguiente y S21b después).

### Errores encontrados

- **Claude no jugó con las manos:** los tiempos de atención del diagnóstico (unos 25 s por solicitud) son estimaciones.
- **Choque de espacio con la Mano:** el cuaderno abierto tapa la mitad derecha de la pantalla, justo los diales y el lugar por donde entra la Mano. Queda como pregunta 3 de S21f.
- **Con un señuelo de 1 s, clickear todo sigue siendo barato** (como mucho 4 s en la noche 5). Lo que más obliga a identificar son los sinónimos, sobre todo para quien reconoce a la criatura desde el cuaderno. El costo se ajusta en `balance.tres`.
- **Benja cambió la maqueta** (`scene_layout.aseprite`, capa `Hand`) y agregó `hand_sprite.aseprite`. Ninguno de los dos tiene commit todavía.

### Pendientes Código

- [ ] **S21f: ajustes de mecánicas y la Mano** (`docs/23_prompt_ajustes_mecanicas.md`, Plan 9.1), antes de S21b.
- [ ] En S21f: pasar las decisiones del 11-nov al diseño v2, con sus valores (en `CLAUDE.md` ya están, sin valores).
- [ ] En S21f: registrar `hand_sprite` en `art/positions.md` e importarlo con Aseprite Wizard.
- [ ] Para otro momento (`docs/22`): A6 (reacciones por entidad), A7 ("Matías piensa" a 1 s) y las secciones B a E (reglas con condiciones, "Reglas de la casa", situaciones que cambian, el daño que se oye, el impostor, mandar a grabar, recortes).
- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`).
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q).
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 son de partida y se ajustan ahí: tiempos, señuelos, batería (38 s), cortinas, la criatura (25 s) y los accidentes.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram, y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.

### Pendientes Externos

- [ ] **Abrir S21f** y contestar sus 6 preguntas (`docs/23`). Lo ideal es tener el editor de Godot cerrado.
- [ ] Decidir si quieres hacer `art/_layout/scene_layout.aseprite` (con la capa `Hand`) y `hand_sprite.aseprite` en un commit ahora o en S21f.
- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio), sobre todo que la criatura no se oiga con la cortina cerrada y que un accidente nunca mate.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`. `TUTORIAL_DIALS` ya se reescribió en el Plan 9 para hablar de las barras.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21d — 10 de noviembre de 2026 — Arte y sonidos pulidos

Sesión pedida por Benja, fuera de la secuencia y antes de S21b, en Opus 5.5. Se usaron las skills nuevas `disciplines:create-game-assets` y `disciplines:audio-design` (Benja instaló el plugin `disciplines` de awesome-gamedev-agent-skills; se verificó que el plugin `godot` del mismo marketplace estaba bien instalado). El arte de Benja no se tocó.

### Realizado

- **Decisiones de Benja:**
  - sonidos mixtos: síntesis más grabaciones de dominio público o CC0, con créditos;
  - **ningún sonido dice palabras**, así que el Imbunche llora como guagua en vez de decir "Matías";
  - las voces de los amigos murmuran por radio;
  - el cuaderno es universitario, con Departure Mono;
  - además del mixer, el cuaderno y la tinta, pasan a pixel art el marco del celular, las barras de arriba, las barras de señal, y el menú y las pantallas finales.
- **Sonidos (38):** `tools/make_sounds.py` y `tools/sound_lib.py` reemplazan a `make_placeholder_sounds.py`.
  - **La biblioteca** tiene ruido, filtros, resonancias, golpes por modos, fricción, burbujas, reverberación por sala, el filtro del celular y el de la radio, y sonoridad BS.1770 con limitador.
  - **Cada sonido** tiene su sonoridad objetivo, y los audios de una misma entidad comparten fondo y ganancia. El detalle está en `sonidos_pendiente.md`, reescrito.
  - **Ambiente y respiración:** el ambiente pasa de 8 a 24 s, en estéreo, y él y la respiración van en bucle desde su importación (`edit/loop_mode=2`).
- **Grabaciones:** 5, de Wikimedia Commons, en `audio/source/` (Godot las ignora), cada una con su ficha `.json` y todas en `audio/source/creditos.md`. Son el gallo, la oveja, el llanto de guagua y dos de gruñidos.
- **El Imbunche:** la observación `called_name` pasa a `baby_cry` en `data/entities/imbunche.tres`, con los textos `OBS_IMBUNCHE_BABY_CRY_*` y `RULE_IMBUNCHE_1` y una frase nueva en `ENTITY_IMBUNCHE_LORE` (borradores). Sus archivos de audio cambian de nombre.
- **Arte (`art/ui/`, 17 PNG):** lo genera `tools/make_ui_art.py` con la paleta de `mixer_sprite`, `notebook_sprite` y `phone_sprite`.
  - El cuerpo del mixer y la perilla de los faders: el código dibuja solo lo que se mueve.
  - La hoja del cuaderno y 3 pestañas como notas adhesivas, en el tema nuevo `notebook_theme.tres`, con colores de lápiz pasta en `notebook_page.gd`.
  - La mancha de tinta: 3 cuadros que salpican y chorreones que bajan (`ink_blot.gd`).
  - El marco del celular, la placa de las barras de arriba (con barras de LED en segmentos), las barras de señal (un sprite con una x sin señal) y el marco y 3 botones de los menús.
- **El menú, la pausa y el resumen** usan `scenes/ui/menu_theme.tres` y `scripts/ui/framed_box.gd`, que dibuja el marco detrás de cada columna sin mover sus nodos. El menú muestra los sprites de Benja del cuarto, oscurecidos, con la columna a la derecha.
- **Pruebas:** 556 OK (eran 555).
  - `test_placeholder_sounds.gd` pasa a llamarse `test_sounds.gd`, con las duraciones nuevas y una prueba del bucle.
  - `test_chat_entry.gd` revisa el cuadro de las barras de señal.
- **Capturas revisadas:** `C:\dev\capturas\arte_*.png` (el mixer, el cuaderno, la tinta, Snapgram, el menú, el resumen y la pausa). La importación sale sin errores en la segunda pasada.
- **Documentos:** `sonidos_pendiente.md`, `arte_pendiente.md`, `docs/04` (sección Q nueva), `CLAUDE.md`, el diseño v2 (§12, §13 y §17) y `docs/00_log.md`.
- **Commits (3, sin push, aprobados por Benja):** los sonidos y el Imbunche (con `__pycache__/` fuera de git), el arte de interfaz y los documentos.

### Errores encontrados

- **Claude no puede escuchar.** Cada sonido se revisó con su espectrograma, su sonoridad y sus picos, y se corrigió lo que se veía mal:
  - los bufidos que el viento tapaba;
  - los dos cantos del gallo, que iban pegados y se podían oír como 4;
  - el retumbo de la cueva, que tapaba los gruñidos;
  - un eco largo en los tacos;
  - el chillido de la ventana, que era muy corto.

  Falta escucharlos (`docs/04`, Q).
- **El volumen general cambia:** los sonidos de relleno iban de -5 a -27 LUFS sin criterio, y ahora siguen objetivos por tipo. Los volúmenes de los nodos no se tocaron, así que el balance hay que oírlo jugando.
- **La grabación del gallo viene algo saturada.** Se nota poco, porque suena apagado, como bajo el piso.
- **Los rasguños** (`hallucination_scratch`) conservan algo de tono, como de uñas que chirrían.
- **Commons limita las descargas** (error 429): hay que bajar las grabaciones de a pocas y con pausas.
- **La primera importación** avisa "Failed loading resource" y "Parse Error" por los archivos nuevos (igual que con las voces y las fotos). En la segunda pasada no aparece.
- **El primer intento de la mancha** se fundía en un óvalo gigante: la suma de gotas crecía sin límite. Se cambió por gotas que se apagan a 1,6 radios.
- **Departure Mono es más ancha** que la letra anterior del cuaderno. La página de La Calchona cabe, pero las más largas se deslizan más.

### Pendientes Código

- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`).
- [ ] Ajustar las recetas de `tools/make_sounds.py` según lo que diga Benja al escuchar (`docs/04`, Q).
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: los créditos de las fotos de Snapgram, si sus licencias los piden, y los de las 5 grabaciones (`audio/source/creditos.md`; no son obligatorios, pero conviene ponerlos).
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos y el arte de `art/ui/` a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 son de partida y se ajustan ahí: tiempos, señuelos, batería (38 s), cortinas, la criatura (25 s) y los accidentes.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %). Las opciones siguen con el tema del chat, no con el de los menús.
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [x] ~~Plan 10: reemplazar los sonidos provisionales~~: hecho en esta sesión. Quedan los que **faltan** (al llegar y recibir un video, los clics, la música del menú y las pantallas finales: `sonidos_pendiente.md`) y, si hace falta, separar más canales que `Ambience` y `Effects`.
- [ ] Cuando llegue el arte de Benja: el logo, los bocetos de las 7 entidades, los diales rediseñados, los íconos de Snapgram, y las manos o el rostro de los screamers. Lo de `art/ui/` se reemplaza si Benja lo redibuja.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.
- [x] Menor: `tools/__pycache__/` quedó en git: Benja aprobó, y ya está en `.gitignore` y fuera del repositorio.

### Pendientes Externos

- [ ] **Escuchar los sonidos nuevos y revisar el arte** (`docs/04`, Q, unos 20 minutos). Lo más importante: que los audios de cada entidad se distingan de oído.
- [ ] **Corregir los textos nuevos del Imbunche** (borradores de Claude): `OBS_IMBUNCHE_BABY_CRY_YES` y `_NO` en `messages.csv`, y `OBS_IMBUNCHE_BABY_CRY_Q`, `RULE_IMBUNCHE_1` y la frase nueva de `ENTITY_IMBUNCHE_LORE` en `notebook.csv`.
- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el logo, los bocetos de las entidades, los íconos de Snapgram o redibujar cualquier pieza de `art/ui/` (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos) y corregir `MIXER_ROUNDS` (`ui.csv`). Las voces ahora murmuran: escúchalas con la sección Q.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio), sobre todo que la criatura no se oiga con la cortina cerrada y que un accidente nunca mate.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`. `TUTORIAL_DIALS` ya se reescribió en el Plan 9 para hablar de las barras.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21c — 9 de noviembre de 2026 — Snapgram: la red social imita a una real

S21c se hizo antes que S21b (el registro lo permitía), en Opus 5.5 · high, con `superpowers:brainstorming` y `superpowers:test-driven-development`. Se diseñó con Benja y se programó en la misma sesión, sin un plan aparte.

### Realizado

- **Decisiones de Benja:** el nombre Snapgram; la forma de Instagram, sin historias; **solo fotos reales de gatitos** (mixed media), cuentas sin nombre y texto simulado con barras grises; botones solo de dibujo; y las fotos perturbadoras entran ahora, cada vez más seguido con menos Sanity. Benja cambió bastante la propuesta: Claude proponía variedad de temas, usuarios creíbles y pixel art.
- **El celular** (`scripts/ui/phone_view.gd`): barra superior, publicación de 332 px (avatar, barra de usuario, foto de 232×232, íconos y 3 barras) y navegación abajo. Sin batería se apaga toda la app, y quedan la hora y "Sin batería".
- **Los íconos** (`scripts/ui/phone_icons.gd`): 9 de 11×11, provisionales.
- **Las fotos perturbadoras** (`scripts/core/phone_feed.gd`): bajo Sanity 30, 1 de cada 6; bajo 15, 1 de cada 3. Se turnan y no restan Sanity. Una foto a la vista nunca cambia: se decide al entrar a la pantalla o al abrir el celular.
- **Los datos:** `PhonePostData` queda solo con `picture`; `ContentCatalog.phone_disturbing_posts` y 4 valores `disturbing_post_*` en `data/balance.tres`. El validador exige que cada publicación tenga foto. `phone.csv` pierde los 24 textos de publicaciones.
- **Las fotos:** Benja pasó 12 de gatitos y 4 perturbadoras (no 3) a `art/phone/source/`, que Godot ignora. `tools/crop_phone_photos.sh` las recorta a `art/phone/`. A `cat4` se le recorta desde arriba, porque al centro quedaba sin orejas.
- **Pruebas:** de 542 a 555 OK. Se quitó `test_publicacion_sin_texto`, porque ya no hay textos, y se ajustó la ayuda `_make_phone`, que usaba los campos eliminados. Las pruebas de Sanity y batería no cambiaron.
- **Capturas revisadas** (`C:\dev\capturas\snapgram_*.png`, con `test/capture_snapgram.gd`): el feed, una foto perturbadora con Sanity en 10 y sin batería. También se revisó que el juego arranca sin errores.
- **Documentos:** `CLAUDE.md`, el diseño v2 (§10.2 y §16), `arte_pendiente.md`, `docs/02`, `docs/03`, `docs/04` (nueva sección P), `docs/05` y `docs/00_log.md`.

### Errores encontrados

- **Los derechos de las fotos no están confirmados.** Las 4 perturbadoras parecen sacadas de internet (de 320 a 447 px de ancho), y `scary2` tiene abajo la marca de agua de una cámara. Los gatitos parecen de un banco de fotos, pero Claude no lo puede confirmar. No frena el desarrollo; hay que resolverlo antes de publicar.
- **El nombre Snapgram junta "Snap" e "-gram"**, que recuerdan a Snapchat e Instagram. Una búsqueda rápida no encontró una app activa con ese nombre exacto, solo Snapigram, pero no es una revisión legal. Se cambia en `phone.csv`.
- **La viñeta oscurece las fotos perturbadoras,** porque va por encima del celular. Con Sanity en 10, la figura se ve, pero apagada. Se decide jugando (`docs/04`, P).
- **Aviso de la primera importación:** "Failed loading resource" de las fotos nuevas, igual que con las voces. En la segunda pasada no aparece.
- **Lo que no se probó:** cómo se sienten las fotos jugando, cuántas veces llega a verlas el jugador antes de que se acabe la batería y cómo se ven a pantalla completa (a 1080p se escalan ×1,5).

### Pendientes Código

- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`).
- [x] **Rediseñar la red social** (`docs/20_prompt_red_social.md`): hecho en esta sesión.
- [ ] Si las fotos perturbadoras no se alcanzan a ver bajo la viñeta: dejar el celular por encima de ella, en su propia capa. Hay que cambiar `UI/PhoneView` en `desk.gd` y en los 5 archivos de pruebas y capturas que lo usan.
- [ ] Plan 10: agregar los créditos de las fotos de Snapgram, si sus licencias los piden.
- [ ] Al probar el escalado a 1080p (`docs/04`, D): mirar cómo se ven las fotos a ×1,5 con el filtro Nearest.
- [ ] Lore (S21b): decidir si el canal de los amigos aparece en Snapgram. Con cuentas sin nombre, habría que ver cómo se reconoce.
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 son de partida y se ajustan ahí: tiempos, señuelos, batería (38 s), cortinas, la criatura (25 s) y los accidentes.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %).
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 10: reemplazar los sonidos provisionales de `audio/sfx/` y `audio/clues/` (ver `sonidos_pendiente.md`) y, si hace falta, separar más canales que `Ambience` y `Effects`.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y de HUD, y los screamers.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar Snapgram** (`docs/04`, P, unos 10 minutos) y decir si las fotos perturbadoras se alcanzan a ver bajo la viñeta.
- [ ] **Confirmar de dónde salió cada foto** de `art/phone/source/` y que su licencia permita usarla en un juego publicado. Si alguna no sirve, reemplázala: las perturbadoras son las que más preocupan.
- [ ] **Si cambias de idea con el nombre:** Snapgram está en `PHONE_APP_NAME` (`data/text/phone.csv`).
- [ ] **Si quieres:** dibujar el marco del celular, el logo y los íconos (`arte_pendiente.md`).
- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos), sobre todo cómo suenan las voces, y corregir `MIXER_ROUNDS` (`ui.csv`).
- [ ] **Si dibujas el mixer ampliado:** incluye las 2 luces de ronda junto a la fila de 8.
- [ ] **Escuchar los 15 audios** (`audio/clues/`) y poner los reales (`sonidos_pendiente.md`), porque hay que distinguirlos de oído. Después, los de la criatura (`scare_creature_*.wav`) y el resto de `audio/sfx/`.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio), sobre todo que la criatura no se oiga con la cortina cerrada y que un accidente nunca mate.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`. `TUTORIAL_DIALS` ya se reescribió en el Plan 9 para hablar de las barras.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** El menú principal y el logo, las pantallas de victoria y derrota, y, si quieres animarlas, las cortinas y la criatura de la ventana.
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.

---

## Sesión 21 y su continuación — 7 al 9 de noviembre de 2026 — Plan 9 ejecutado: dinamismo; correcciones de Benja y prompts del lore y la red social

S21 se adelantó al mismo 7 de noviembre (fecha objetivo: 10 a 17 de noviembre), justo después de S20, y se ejecutó inline con `superpowers:executing-plans` en Sonnet 5.5 · high, como proponía el registro. Benja autorizó los 11 commits en `main` al empezar. El plan se aplicó tal como está escrito: un script leyó los bloques de `docs/18` y los aplicó paso a paso, y en cada tarea los conteos de pruebas dieron los que el plan anticipa (461 → 521).

### Realizado

- **Tarea 1, las barras** (`scripts/ui/stat_bars.gd`): Connection, Sanity y Trust arriba, en el hueco entre el chat y el cuaderno, cada una con el color de su dial. Titilan si bajan 2 puntos o más de una vez y prenden una luz bajo 25. Los diales de la pared se quedan, y el aviso de la noche 0 baja a y = 70, bajo las barras. 469 pruebas.
- **Tarea 2, acertar es más difícil:** tiempo para responder de 80, 65, 55, 45 y 40 s; pista de 100, 75, 0, 0 y 0 %; señuelos de 1, 2, 3, 3 y 4. El Trauco comparte 2 características con La Calchona (suma `long_tangled_hair`) y El Imbunche, con El Basilisco (suma `shed_skin`). 470 pruebas.
- **Tarea 3, Audio Sync más rápido:** `audio_sync_bpm` pasa a cada noche (90, 100, 115, 130 y 145) y cada ronda va un 15 % más rápida que la anterior (`audio_sync_round_speedup`). La tolerancia no se tocó. 471 pruebas.
- **Tarea 4, los audios en el chat:** `ChatMessage.add_audio()` y un enlace "▶ Escuchar audio" que suena con un clic, la estática lo tapa entero, no empiezan screamers ni alucinaciones mientras suena, y la opción nueva "Subtítulos de los audios" (apagada por defecto). 483 pruebas.
- **Tarea 5, los audios de las 7 entidades:** cada una manda un audio en «¿Qué oyes?» y lo que se oye cambia la acción correcta (`cries`, `bleat_tone`, `whistle`, `heels`, `ground`, `crows` y `called_name`). 15 audios provisionales en `audio/clues/`, generados con `tools/make_placeholder_sounds.py`, y reglas y textos reescritos. 485 pruebas.
- **Tarea 6, la batería del celular:** un tope de 38 s de scroll por noche, sin recarga, con su barra en el celular del escritorio y "Sin batería". 489 pruebas.
- **Tarea 7, las cortinas:** se abren y se cierran con un clic, con el arte de Benja (tags `Open` y `Closed`). Cerradas, el cuarto se oscurece (`CurtainShade`) y Sanity baja de a poco. El screamer de la cortina la abre o la cierra. 495 pruebas.
- **Tarea 8, la criatura se queda:** `creature_visits` (1, 2, 2 y 3 en las noches 2 a 5) reemplaza a `has_jumpscare`. La criatura abre la cortina al llegar, se queda 25 s aunque se cierre, baja Sanity rápido con la cortina abierta y no se oye con la cortina cerrada: hay que abrirla para revisar. 500 pruebas.
- **Tarea 9, la noche 0:** el aviso enseña las cortinas con la criatura del susto guionado, y también los audios y la batería. 502 pruebas.
- **Tarea 10, los accidentes:** `IncidentData` y `FriendIncident`, repartidos por el director. Un amigo libre, con señal y con más de 1 de vida se tropieza o se corta; se responde en el chat con 3 opciones de sentido común y 15 s, sin cuaderno. Una mala respuesta o no responder le quita 1 de vida y lo aturde, sin bajar Trust, y nunca mata. 521 pruebas.
- **Tarea 11, documentos:** las decisiones de Benja del 7-nov entraron a `CLAUDE.md` y al diseño v2, y se actualizaron `docs/02`, `docs/04` (nueva sección N), `docs/06`, `docs/17`, `arte_pendiente.md` y `sonidos_pendiente.md`.
- **Capturas** (`C:\dev\capturas\plan9_*.png`), las 5 revisadas a ojo: las barras con el cuaderno abierto, "▶ Escuchar audio" en turquesa, las cortinas cerradas con el cuarto oscuro, el celular con "15%" en rojo y el accidente con "¿Qué le dices?" y sus 3 opciones.
- **Commits (11, directo en `main`, sin push):** `91b1925`, `aaa56e3`, `f500807`, `e5dfc6f`, `a967a9a`, `54e1927`, `142bc7b`, `0c360b4`, `34c2368`, `ba34ce3` y el de cierre, "Plan 9 terminado: dinamismo".
- **El pendiente de las ayudas para los diales** ya se cumplió con las barras.

**Continuación (8 y 9 de noviembre, Opus 5.5).** Benja jugó el Plan 9, le gustó ("mucho mejor") y pidió 5 cosas. Las 3 de código quedaron hechas, de 521 a 542 pruebas, y Benja autorizó el commit y el push:

- **La sombra sobre el escritorio:** Benja dibujó `desk_sprite` con los tags `Enemy` y `NoEnemy`. La criatura y el screamer de la ventana hacen sombra; con la cortina cerrada no hay, para no delatar a la criatura (la propuso Claude y Benja la confirmó).
- **Audio Sync:** la fila tiene 8 luces, las de una ronda (`MixerView.step_count()`), aunque la noche tenga 2 rondas. Claude le planteó 4 formas de indicar las rondas y Benja eligió **las luces de ronda**: junto a la fila, una por ronda, solo si hay varias y desde que se abre el mixer; azul la que está en curso, verde las pasadas, y al fallar se apagan. Se dibujan con rectángulos hasta el arte del mixer.
- **Las voces de los amigos** (`scripts/core/chat_voice.gd`, nuevo): un sonido corto cada tantas letras, como en Undertale. León, onda cuadrada media, 1 de cada 3 letras; Gonzalo, triangular grave, 1 de cada 4; Agustín, pulso agudo, 1 de cada 2. Sonidos en `audio/sfx/voice_*.wav` y ajustes en `data/friends/*.tres`, grupo Voice. Solo suena el chat que se está viendo, no suena sobre un audio y Matías no tiene voz. Con la escritura en tiempo real, en la misma frase suenan unas 26, 20 y 37 veces.
- **Nuevo `docs/19_prompt_lore.md` y `docs/20_prompt_red_social.md`:** prompts para las 2 sesiones aparte que pidió Benja.
- **Documentos:** `CLAUDE.md`, el diseño v2 (§10.6, §11 y §17), `docs/04` (nueva sección O), `docs/05` (10ter), `sonidos_pendiente.md` y `docs/00_log.md`.
- **Capturas revisadas** (`C:\dev\capturas\fb2_*.png`): la sombra con la criatura, sin ella y con la cortina cerrada, y el mixer de la noche 4 con 8 luces y "Ronda 1 de 2".

### Errores encontrados

- **Un detalle de formato del plan, en unos 15 bloques:** los bloques "reemplazar" cuyo texto está al final del archivo terminan con una línea en blanco que el archivo no tiene (casi siempre, el final de un archivo de pruebas; también `docs/04` y `chat_panel.tscn`). El aplicador los reconoce, los aplica sin esa línea y exige que estén al final del archivo; el resultado es el que el plan describe y los conteos coinciden.
- **Un mensaje de commit distinto al del plan** en la Tarea 4: Claude escribió uno propio, y se corrigió con `amend` (el commit era local) antes de seguir.
- **Aviso al cerrar el escritorio suelto** (`--quit-after`): `ambient_room.wav` sigue sonando cuando se cierra el juego y Godot avisa de 2 objetos sin liberar. No es un error de script ni viene de este plan; el menú principal arranca sin ninguna línea de error.
- **Lo que no se probó:** cómo se sienten los valores, si los 15 audios provisionales se distinguen de oído y jugar una noche de punta a punta. Las pruebas y las capturas no dicen si es más entretenido: eso solo lo dice jugarlo (`docs/04`, N).
- **Continuación, las 16 luces:** eran un error del Plan 8.1, que contaba el total de aplausos en vez de los de una ronda. Las últimas 8 luces nunca se usaban.
- **Continuación, las voces no se oyeron:** Claude revisó que suenen, cuántas veces y con qué archivo y altura, pero no puede oírlas. Si son agradables o cansan, solo lo dice Benja (`docs/04`, O).
- **Continuación, aviso de la primera importación:** al importar por primera vez, `data/friends/*.tres` avisa "Failed loading resource" de las voces, porque se leen antes de que Godot importe los `.wav`. En la segunda pasada no aparece.

### Pendientes Código

- [ ] **Planificar el lore** (`docs/19_prompt_lore.md`) y **rediseñar la red social** (`docs/20_prompt_red_social.md`).
- [ ] **S22: correcciones tras las pruebas con personas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre. Todos los valores del Plan 9 son de partida y se ajustan ahí: tiempos, señuelos, batería (38 s), cortinas, la criatura (25 s) y los accidentes.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Si Benja dibuja la animación de las cortinas o de la criatura: va en `curtains_sprite`.
- [ ] Si las voces cansan: subir `CHARS_PER_SECOND` no ayuda; bajar la frecuencia con `voice_every`, o hacer sonar solo el comienzo de cada mensaje.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %).
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Menor: al cerrar el escritorio suelto, el sonido ambiente en bucle queda sonando y Godot avisa de 2 objetos sin liberar.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 10: reemplazar los sonidos provisionales de `audio/sfx/` y `audio/clues/` (ver `sonidos_pendiente.md`) y, si hace falta, separar más canales que `Ambience` y `Effects`.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y de HUD, y los screamers.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar las correcciones** (`docs/04`, O, unos 10 minutos), sobre todo cómo suenan las voces, y corregir `MIXER_ROUNDS` (`ui.csv`).
- [ ] **Si dibujas el mixer ampliado:** incluye las 2 luces de ronda junto a la fila de 8.
- [x] **Probar el dinamismo** (`docs/04`, N): Benja lo jugó el 8-nov y anotó sus correcciones.
- [ ] **Escuchar los 15 audios** (`audio/clues/`) y poner los reales (`sonidos_pendiente.md`), porque hay que distinguirlos de oído. Después, los de la criatura (`scare_creature_*.wav`) y el resto de `audio/sfx/`.
- [ ] **Corregir las reglas de las 7 entidades** (están en `data/entities/`, en el Inspector, con sus textos en `messages.csv` y `notebook.csv`) y los textos nuevos del Plan 9: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`. Antes del congelamiento del contenido (25 de noviembre).
- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio), sobre todo que la criatura no se oiga con la cortina cerrada y que un accidente nunca mate.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `MIXER_ROUND` y `MIXER_FAIL_RESTART`. `TUTORIAL_DIALS` ya se reescribió en el Plan 9 para hablar de las barras.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** El menú principal y el logo, las pantallas de victoria y derrota, y, si quieres animarlas, las cortinas y la criatura de la ventana.
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden las barras, Audio Sync, los audios, las cortinas, la batería y los accidentes.
- [x] El commit de la cortina cerrada de Benja (`art/sprites/curtains_sprite.aseprite`) ya estaba hecho: el Plan 9 partió con git limpio.

---

## Sesión 20 — 7 de noviembre de 2026 — Notas de prueba ordenadas y Plan 9 escrito: dinamismo

Benja probó el juego y notó que no era tan entretenido ni dinámico. Pidió ordenar sus 8 notas y volverlas acciones, respondió las preguntas y decidió que todo entra antes del 25 de noviembre, salvo la historia y editar videos. Se ordenaron en Sonnet y el plan se escribió en Opus 5.5 con `superpowers:writing-plans`. Benja también dibujó las cortinas cerradas durante la sesión. El código del plan **todavía no está en el juego**: se ejecuta en S21.

### Realizado

- **Nuevo `docs/17_ideas_dinamismo.md`:** las notas ordenadas, con el diagnóstico (el juego es reactivo) y las decisiones de Benja.
- **Nuevo `docs/18_plan_dinamismo.md`:** el Plan 9 en 11 tareas con código completo, de 461 a 521 pruebas:
  - **las barras** de Connection, Sanity y Trust, arriba, en el hueco entre el chat y el cuaderno (los diales se quedan);
  - **acertar es más difícil:** menos tiempo, sin pista desde la noche 3, más señuelos y entidades que comparten 2 características;
  - **Audio Sync más rápido**, por noche y por ronda;
  - **audios en «¿Qué oyes?»:** cada entidad tiene una observación que se escucha, y lo que se oye cambia la acción correcta (15 audios provisionales en `audio/clues/`, reglas de las entidades reescritas y opción de subtítulos);
  - **la batería del celular:** un tope por noche;
  - **las cortinas**, con el arte nuevo de Benja (tags `Open` y `Closed`), y **la criatura que se queda** 25 s y hay que revisar; la cortina también se abre o se cierra sola con un screamer;
  - **la noche 0** enseña las cortinas, los audios y la batería;
  - **los accidentes:** se responden en el chat con sentido común, sin cuaderno.
- **Decisiones de Benja:** están en `docs/18` y entran a `CLAUDE.md` y al diseño v2 al ejecutar el plan (Tarea 11), junto con los supuestos que Benja no corrija.
- **`docs/05` y `docs/06`:** el nuevo Plan 9, el antiguo Plan 9 (sonido) pasa a ser el Plan 10, y editar videos y la historia van a la lista de después.
- **`docs/00_log.md`:** S20 ✅, S21 (ejecutar el Plan 9) como siguiente, y lo que era S20 a S23 pasa a S22 a S25.
- **Validación:** todo el código corrió en una copia aparte (`C:\dev\plan9`), con 521 pruebas OK. Se revisaron 5 capturas (`C:\dev\capturas\plan9_*.png`), se simularon 12 noches completas sin errores de script y el juego arranca limpio. Después, un script aplicó el plan tal como está escrito a una copia limpia (`C:\dev\plan9_check`), con la caché de importación real: los 357 bloques se aplicaron, los 21 conteos salen de esa pasada y el resultado es idéntico al código probado.

### Errores encontrados

- **En la sesión, Claude dio por hecho que el proyecto no tenía arte de la cortina cerrada.** `docs/17` decía que faltaba, pero Benja ya lo había dibujado: se notó al revisar `git status`.
- **Dos pruebas del borrador estaban mal, no el código:** una apuntaba a la costura transparente del centro de la cortina cerrada (x = 187), y otras contaban mal los 25 s de la criatura. Se corrigieron antes de escribir el plan.
- **Lo que no se probó:** cómo se sienten los valores, si los 15 audios provisionales se distinguen de oído y jugar de punta a punta. Las capturas y las pruebas no dicen si es más entretenido: eso solo lo dice jugarlo (`docs/04`, N, que llega con el plan).

### Pendientes Código

- [ ] **S21: ejecutar el Plan 9** (`docs/18`, 11 tareas).
- [ ] **S22: correcciones tras las pruebas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre.
- [ ] Si en las pruebas con personas no entienden Audio Sync o los accidentes: enseñarlos en la noche 0.
- [ ] Si la velocidad de Audio Sync se queda corta: bajar `audio_sync_tolerance` por noche.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %).
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Planes 10 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 10: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 10: reemplazar los sonidos provisionales de `audio/sfx/` (ver `sonidos_pendiente.md`) y, si hace falta, separar más canales que `Ambience` y `Effects`.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y los screamers.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8`, `C:\dev\plan8_check`, `C:\dev\plan9` y `C:\dev\plan9_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Revisar los supuestos del Plan 9** (`docs/18`, al inicio) antes de S21, sobre todo que la criatura no se oiga con la cortina cerrada, que un accidente nunca mate y las reglas nuevas de las entidades.
- [ ] **Autorizar el commit de tu cortina** (`art/sprites/curtains_sprite.aseprite`) y de los documentos de esta sesión: el Plan 9 parte con git limpio.
- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Poner los sonidos reales** (`sonidos_pendiente.md`), empezando por la respiración y los golpes de la criatura (`scare_creature_*.wav`).
- [ ] **Corregir los textos del Plan 8.1** (en `ui.csv`): `TUTORIAL_DIALS` y `TUTORIAL_DIALS_OK`, `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir las 7 entidades** antes del congelamiento del contenido (25 de noviembre): están en `data/entities/` (Inspector) y sus textos en `messages.csv` y `notebook.csv`. Conviene hacerlo después de S21, que reescribe sus reglas.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** El menú principal y el logo, las pantallas de victoria y derrota, y, si quieres animarla, la criatura de la ventana.
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden los diales, las barras, Audio Sync y los accidentes.

---

## Sesión 19 (continuación) — 4 de noviembre de 2026 — Plan 8.1: el feedback de la primera prueba

Benja probó el juego después del Plan 8 y dio 5 puntos de feedback (el 4.º y el 5.º llegaron después de preguntarle por el 4.º, que había llegado vacío). Se trabajó con `superpowers:brainstorming` (3 rondas de preguntas con opciones) y `superpowers:writing-plans`, y se ejecutó inline en Sonnet 5.5, con los 7 commits autorizados en `main`. El plan quedó en **`docs/16_plan_feedback_1.md`** (7 tareas, de 446 a 461 pruebas).

### Realizado

- **La criatura se asoma por la ventana en lugar del jumpscare** (era aburrido): la figura de `enemy_sprite`, con respiración pesada y golpes en el vidrio, sin tapar la pantalla ni pausar la noche. **Se arma solo cuando el chat o el mixer tapan la ventana**, y al cerrarlos ya está ahí, sin animación de entrada (así no hace falta animarla); se queda 4 s y se retira. Si la ventana ya está a la vista (el susto guionado de la noche 0), aparece enseguida. Mientras esté cerca no empiezan otros screamers ni alucinaciones. Los otros 6 screamers no cambian. Se quitó la pantalla del jumpscare, su rojo parpadeante, `jumpscare_seconds` y el grito.
- **Sonidos provisionales de la criatura** (`scare_creature_breathing.wav` y `scare_creature_knocks.wav`) y el documento nuevo **`sonidos_pendiente.md`**: todos los sonidos del juego, dónde suena cada uno, cómo tendría que sonar y cómo reemplazarlo.
- **Las noches 1 y 2 con más sucesos:** la noche 1 pasa a 5 solicitudes, 2 a la vez, 85 s, señal que baja, 1 interferencia, Audio Sync de 4 aplausos y 2 screamers ambientales; la noche 2, a 7 solicitudes, 3 interferencias y 4 screamers.
- **Audio Sync de 8 aplausos en 2 rondas de 4** (`MixerView`): cada una con su cuenta y su patrón; acertar la 1 pasa sola a la 2, y fallar la 2 vuelve a la 1 con un patrón nuevo. La señal vuelve a 100 al terminar las 2. El mixer dice "Ronda 1 de 2".
- **Trust también baja si tardas en contestar:** cada solicitud abierta más de 30 s (45 con "Temporizadores ×1,5") le quita 0,25 por segundo, y mientras haya una Trust no se recupera. Preguntar cuenta. No aplica en la noche 0 ni a un amigo sin señal.
- **Los diales se explican en la noche 0:** el primer aviso del tutorial, con un botón "Entendido".
- **Documentos:** `CLAUDE.md` (6 decisiones nuevas), diseño v2 (§10.3, §10.6, §11 y §13), `docs/02` §6, `docs/04` (secciones K y L corregidas y la nueva M), `arte_pendiente.md` y `docs/00_log.md`.
- **Capturas revisadas:** `creature.png` (la figura en la ventana, sin pantalla gris ni rojo) y `plan8_tutorial.png` (el aviso de los diales con "Entendido").

### Errores encontrados

- **La primera captura de la criatura no mostraba la figura.** El desvanecimiento del screamer de la ventana, que seguía corriendo, la escondía (comparten la figura). En el juego real el hueco de 25 s entre screamers lo evita, pero era frágil: ahora cada uno corta el desvanecimiento del otro (Paso 6 de la Tarea 5 del plan, con su prueba).
- **El plan decía que Benja había autorizado los commits** y no era cierto: se le preguntó antes de ejecutar y se corrigió el texto.
- **Se quitó un bloque sin efecto** que el plan traía en la Tarea 7 (reemplazaba una línea por sí misma).
- **Lo que no se probó:** el sonido real de la respiración y los golpes (son relleno), cómo se sienten las noches 1 y 2 y Trust (los valores son de partida), y jugar de punta a punta. Eso lo cubre `docs/04`, M.

### Pendientes Código

- [x] Feedback de la primera prueba (`docs/16`).
- [ ] **S20: correcciones tras las pruebas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre.
- [ ] Si Trust sigue sin notarse: las ayudas para los diales que Benja no eligió (letrero al pasar el mouse, aviso cuando uno baja de golpe, nombres provisionales bajo cada dial).
- [ ] Si en las pruebas con personas no entienden Audio Sync: enseñarlo en la noche 0 (ahora aparece en la noche 1, sin práctica).
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (fondo al 95 %).
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState`.
- [ ] Planes 9 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (ver `sonidos_pendiente.md`) y, si hace falta, separar más canales que `Ambience` y `Effects`.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y los screamers.
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8` y `C:\dev\plan8_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el feedback** (`docs/04`, M, unos 15 minutos) y decir cómo se sienten las noches 1 y 2, Trust y la criatura. Los valores son de partida: `data/balance.tres` y `data/nights/night_N.tres`.
- [ ] **Poner los sonidos reales** (`sonidos_pendiente.md`), empezando por la respiración y los golpes de la criatura (`scare_creature_*.wav`).
- [ ] **Corregir los textos nuevos de este plan** (en `ui.csv`): `TUTORIAL_DIALS` y `TUTORIAL_DIALS_OK`, `MIXER_ROUND` y `MIXER_FAIL_RESTART`.
- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir las 7 entidades** antes del congelamiento del contenido (25 de noviembre): están en `data/entities/` (Inspector) y sus textos en `messages.csv` y `notebook.csv`.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_*`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K), **la identificación por preguntas** (G), **el mantenimiento** (J), **la noche** (I) y **el chat y el cuaderno** (G y H).
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** El menú principal y el logo, las pantallas de victoria y derrota, y, si quieres animarla, la criatura de la ventana.
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, si la noche de práctica es muy larga o muy corta, y si entienden los diales y Audio Sync.

---

## Sesión 19 — 4 de noviembre de 2026 — Plan 8 ejecutado: noches, menú, guardado y opciones

Benja pidió ejecutar el Plan 8 con `superpowers:executing-plans`, en Sonnet 5.5 (como proponía el registro). Se adelantó al 4 de noviembre, justo después de S18 (la fecha objetivo era el 20 al 22). Benja autorizó los 14 commits al empezar, directo en `main`. El plan tiene tabuladores en cada bloque de código, así que, en lugar de copiarlos a mano, un script (en la carpeta temporal de la sesión, no en el repositorio) leyó los bloques del plan y los aplicó paso por paso; se detenía si un bloque a reemplazar no aparecía exactamente una vez. El plan se aplicó **tal como está escrito**: ningún bloque falló y no hubo que corregir nada.

### Realizado

- **Las 14 tareas del Plan 8, con 14 commits y de 382 a 446 pruebas.** En cada "Verificar que fallan" y cada "Verificar que pasan" el conteo fue el que el plan esperaba (386, 392, 396, 401, 403, 407, 413, 416, 420, 427, 431, 439 y 446):
  - **la noche 0** (`data/nights/night_0.tres`, en `ContentCatalog.tutorial`) con 3 solicitudes fijas (`TutorialRequestData`): el tiempo espera, nadie sale herido, el video espera su descarga y el susto guionado llega cuando no queda nada pendiente;
  - **el aviso del tutorial** (`TutorialGuide` y `scenes/ui/tutorial_hint.tscn`), con "Saltar tutorial";
  - **las 7 entidades** en `data/entities/` (borrador de Claude), con sus textos en los CSV y 7 señuelos nuevos;
  - **las opciones** (`GameSettings`, con 3 canales de audio en `default_bus_layout.tres`), **reducir destellos**, **la cámara fija**, **los temporizadores ×1,5** y **el panel de opciones**;
  - **la partida guardada** (`SaveGame`), **`GameState`** (autoload), **el menú principal** (ahora la escena principal), **el resumen entre noches y la victoria final** y **el menú de pausa** con Esc.
- **Capturas revisadas** (`C:\dev\capturas\plan8_menu.png`, `plan8_tutorial.png`, `plan8_summary.png` y `plan8_pause.png`): coinciden con lo que describe el plan. Nuevo `test/capture_plan8.gd`.
- **El juego arranca** por su escena principal (el menú y `GameState`) sin errores, con `--headless`.
- **Documentos:** `docs/04` recibe la sección L (probar el juego de punta a punta) y el paso 6 de la K remite a ella; `docs/06` y `docs/02` quedan al día; `docs/00_log.md`: S19 ✅ y S20 como siguiente.

### Errores encontrados

- **Ninguno en el plan ni en el código.** Todos los bloques a reemplazar aparecieron una sola vez y los 27 conteos de pruebas coincidieron.
- **Detalle visual, menor** (`plan8_pause.png`): el fondo del panel de opciones es 95 % opaco, así que el menú de pausa se transparenta tenue detrás ("Pausa" bajo la fila "Ambiente"). Es lo que el plan especifica y la vista es provisional hasta el arte; si molesta, se sube el alfa del fondo en `scenes/ui/options_panel.tscn` a 1,0 o se oculta la caja de la pausa mientras las opciones están abiertas.
- **Lo que no se probó:** jugar de punta a punta, el sonido real de los canales y el aspecto del tutorial paso a paso. Las pruebas cubren la lógica y la escena, y las capturas, 4 momentos. Eso lo cubre la sección L de `docs/04`.

### Pendientes Código

- [x] **S19: ejecutar el Plan 8** (`docs/15`, 14 tareas).
- [x] Plan 8: la noche 0, "Reducir destellos", "Temporizadores ×1,5", las entidades en `.tres` y el Night Number de `RequestManager` (ahora lo elige `GameState`).
- [ ] **S20: correcciones tras las pruebas** (`docs/00_log.md`), con el contenido congelado el 25 de noviembre.
- [ ] Menor: el panel de opciones deja ver tenue el menú de pausa detrás (ver "Errores encontrados").
- [ ] Menor: abrir el escritorio solo (F6): "Empezar la noche N" y "Volver al menú" no hacen nada, porque los atiende `GameState` (`docs/15`, "Fuera de este plan").
- [ ] Planes 9 en adelante según `docs/00_log.md`.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres) y, si hace falta, separar más canales que `Ambience` y `Effects` (se agregan a `GameSettings.BUSES` y al panel de opciones). Faltan sonidos para cuando llega un video y cuando se recibe, y los del menú y los botones.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y los screamers (`docs/13`, `docs/14` y `docs/15`, "Fuera de este plan").
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8` y `C:\dev\plan8_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos): la noche 0, el menú, el guardado, la pausa y las opciones.
- [ ] **Corregir las 7 entidades** antes del congelamiento del contenido (25 de noviembre): están en `data/entities/` (Inspector) y sus textos en `messages.csv` y `notebook.csv`. Son un borrador de Claude: las 3 de `docs/09` y El Cuero, La Viuda, El Basilisco y El Imbunche, nuevas. Cada una reparte sus características en categorías distintas y comparte una con otra entidad.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_TUTORIAL*`, `END_VICTORY*`, `END_NEW_PAGES`, `END_NO_NEW_PAGES`, `END_NEXT` y `END_MENU`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K, unos 20 minutos). Su paso 6 (el susto guionado) ahora está en la noche 0 (sección L, paso 2).
- [ ] **Probar la identificación por preguntas** (`docs/04`, G, unos 10 minutos) y decir cómo se siente: tiempos, solicitudes por noche, la pista y el costo de preguntar.
- [ ] **Probar el mantenimiento** (`docs/04`, J), **la noche** (`docs/04`, I) y **el chat y el cuaderno** (`docs/04`, G y H). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** El menú principal y el logo, y las pantallas de victoria y derrota (hoy son provisionales, hechas en Godot).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, y si la noche de práctica es muy larga o muy corta (se ajusta en `data/nights/night_0.tres`, sin código).

---

## Sesión 18 — 4 de noviembre de 2026 — Plan 8 escrito: noches, menú, guardado y opciones

Benja pidió escribir el Plan 8 con `superpowers:writing-plans`. Se escribió en Opus 5.5 con esfuerzo high, adelantado al 4 de noviembre (la fecha objetivo era el 19). Benja todavía no había probado la identificación por preguntas ni los screamers (`docs/04`, G y K), así que no hubo notas de prueba que meter al plan.

### Realizado

- **Nuevo `docs/15_plan_noches_menu.md`:** el Plan 8 en 14 tareas con código completo. Lleva las pruebas de 382 a 446:
  - **la noche 0** como datos (`data/nights/night_0.tres`, en `ContentCatalog.tutorial`): 3 solicitudes fijas (`TutorialRequestData`), una de cada amigo, con El Tue Tué y La Calchona, un video y, al final, el susto guionado con el chat de Gonzalo, que se mueven desde la noche 1;
  - **el tutorial en la lógica:** el tiempo para responder espera (solo las preguntas lo gastan), nadie sale herido, Trust no baja, el video espera su descarga y la noche no termina sola. `RequestManager` da las solicitudes fijas de a una y el susto espera lo pendiente;
  - **el aviso del tutorial** (`TutorialGuide`, lógica pura, y `scenes/ui/tutorial_hint.tscn`): dice qué hacer según lo que se ve, con el botón "Saltar tutorial". El tutorial termina al cerrar el celular;
  - **las 7 entidades** en `data/entities/`, con sus textos en los CSV y 7 señuelos nuevos: El Tue Tué y La Calchona (noche 1), El Cuero y La Viuda (2), El Trauco (3, el de `docs/09`), El Basilisco y El Imbunche (4);
  - **las opciones** (`GameSettings`, `user://settings.cfg`), con 3 canales de audio (`default_bus_layout.tres`: `Master`, `Ambience` y `Effects`), reducir destellos, la cámara fija y los temporizadores ×1,5; **la partida guardada** (`SaveGame`, `user://save.cfg`), al comienzo de cada noche;
  - **la pantalla final como resumen entre noches** (videos y páginas nuevas del cuaderno), el final del tutorial y la victoria final, con "Empezar la noche N", "Reintentar" y "Volver al menú";
  - **`GameState`** (autoload): el juego de punta a punta; **el menú principal**, que pasa a ser la escena principal; **el panel de opciones** y **el menú de pausa** con Esc;
  - la sección L de `docs/04` (probar el juego de punta a punta), que se aplica al ejecutar el plan.
- **Decisiones de Benja** (en `CLAUDE.md` y el diseño v2 §5, §11, §13, §14 y §19):
  - **la noche 0 es guiada y no se pierde:** unos 3 o 4 minutos, con un aviso que dice qué hacer en cada paso, el tiempo que espera y nadie herido;
  - **enseña también a descargar un video**, y **se puede saltar** con un botón;
  - **las 7 entidades son un borrador de Claude**, que Benja corrige antes del 25 de noviembre;
  - **"Temporizadores ×1,5" alarga solo el tiempo para responder;**
  - **menú de pausa con Esc**, sin paneles abiertos.
- **Validación:** todo el código se ejecutó en una copia aparte (`C:\dev\plan8`), con 446 pruebas OK, sin errores al correr, y cuatro capturas revisadas: `C:\dev\capturas\plan8_menu.png` (el menú con "Continuar: noche 2"), `plan8_tutorial.png` (el chat de León con el aviso que pide preguntar), `plan8_summary.png` (el resumen de la noche 1, con El Cuero y La Viuda) y `plan8_pause.png` (las opciones sobre la pausa). Después, un script aplicó el plan **tal como está escrito** a una copia limpia del último commit: los 27 conteos de pruebas coinciden, incluidas las fallas esperadas, los 208 bloques a reemplazar aparecen una sola vez, y el código resultante es idéntico al probado. Se validó dos veces: la primera encontró que dos borrados (la línea `END_PLAY_AGAIN` de `ui.csv` y el guion de `night_1.tres`) dejaban una línea en blanco de más, y se corrigió el plan.
- `docs/00_log.md`: S18 ✅ y S19 (ejecutar el Plan 8) como siguiente.

### Errores encontrados

- **En el código de prueba, antes de escribir el plan** (corregidos en la copia, no llegan al plan): una prueba comparaba una opacidad `float32` con `==`; una función devolvía un arreglo literal dentro de un `x if c else y`, que GDScript no tipa (se cambió por dos `return`); y dos pruebas inferían el tipo de un valor sin tipo (`var desk := game.prepare_night(…)`).
- **El arte de la alerta de las entradas parpadea 5 veces por segundo** (2 cuadros a 10 fps): "Reducir destellos" la deja fija en el cuadro de la alerta.

### Pendientes Código

- [x] **S18: escribir el Plan 8** (`docs/15`).
- [ ] **S19: ejecutar el Plan 8** (`docs/15`, 14 tareas).
- [ ] Planes 9 en adelante según `docs/00_log.md`.
- [ ] Plan 8 (al ejecutarlo): la noche 0, "Reducir destellos", "Temporizadores ×1,5", las entidades en `.tres` y el Night Number de `RequestManager` (ahora lo elige `GameState`) quedan resueltos; se marcan al cerrar S19.
- [ ] Registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres) y, si hace falta, separar más canales que `Ambience` y `Effects`. Faltan sonidos para cuando llega un video y cuando se recibe, y los del menú.
- [ ] Cuando llegue el arte: el menú y el logo, las pantallas de victoria y derrota, el mixer, el celular, las barras de señal y los screamers (`docs/13`, `docs/14` y `docs/15`, "Fuera de este plan").
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte.
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si al probar se siente seco o lento: una demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron.
- [ ] Borrar `~/godot-games/spook-dial` y las copias `C:\dev\plan8` y `C:\dev\plan8_check` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **S19: autorizar los commits del Plan 8** y, después, **probar el juego de punta a punta** (`docs/04`, L, unos 25 minutos).
- [ ] **Corregir las 7 entidades** antes del congelamiento del contenido (25 de noviembre): después de S19 están en `data/entities/` (Inspector) y sus textos en `messages.csv` y `notebook.csv`. Son un borrador de Claude: las 3 de `docs/09` y El Cuero, La Viuda, El Basilisco y El Imbunche, nuevas. Cada una reparte sus características en categorías distintas y comparte una con otra entidad.
- [ ] **Corregir los textos nuevos del Plan 8** (en `ui.csv`): el aviso del tutorial (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el resumen y la victoria (`END_TUTORIAL*`, `END_VICTORY*`, `END_NEW_PAGES`, `END_NO_NEW_PAGES`, `END_NEXT` y `END_MENU`); y los 7 señuelos nuevos (`DECOY_*`, en `messages.csv`).
- [ ] **Probar los screamers y el director** (`docs/04`, K, unos 20 minutos). El paso 6 (el susto guionado) pasa a la noche 0 al ejecutar el Plan 8.
- [ ] **Probar la identificación por preguntas** (`docs/04`, G, unos 10 minutos) y decir cómo se siente: tiempos, solicitudes por noche, la pista y el costo de preguntar.
- [ ] **Probar el mantenimiento** (`docs/04`, J), **la noche** (`docs/04`, I) y **el chat y el cuaderno** (`docs/04`, G y H). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Corregir los textos que escribió Claude en los planes anteriores** (la lista completa está en la Sesión 17).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara, y **probar el escalado a pantalla completa** (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** Para el Plan 8: el menú principal y el logo, y las pantallas de victoria y derrota (hoy son provisionales, hechas en Godot).
- [ ] Al probar con personas (semana 5): fijarse si notan que hay que preguntar, y si la noche de práctica es muy larga o muy corta (se ajusta en `data/nights/night_0.tres`, sin código).

---

## Sesión 17 y su continuación — 3 de noviembre de 2026 — Plan 7 ejecutado: screamers y director; la entidad se identifica preguntando

Ejecutado inline con `superpowers:executing-plans`, en Sonnet 5.5 con esfuerzo high, como proponía el registro. Se adelantó al 3 de noviembre, justo después de S16 (la fecha objetivo era del 17 al 19 de noviembre). Al empezar, Benja autorizó los 14 commits del plan, directo en `main`; no se hizo push.

### Realizado

- **Las 14 tareas de `docs/14`, con 373 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`), sin ningún `ERROR` ni aviso de recursos en uso al terminar. Coincidieron todos los conteos del plan, incluidas las fallas esperadas antes de cada implementación (326 → 328, 336, 340, 346, 350, 352, 354, 359, 359, 362, 363, 371 y 373).
  - **El director de ritmo (`PacingDirector`):** las solicitudes llegan en olas (2, 3, 3, 4 y 4 por noche) con un respiro de 25 s, se aprietan hacia las 06:00, un amigo herido las atrasa 10 s y nunca empieza una que no alcanza a terminar antes de las 06:00. `RequestManager` le pregunta en cada paso.
  - **Los screamers:** la cortina, la figura en la ventana, el celular, las luces, el cuaderno que se cierra de golpe, la mancha de tinta y el jumpscare (uno por noche desde la noche 2). Se anuncian con 1 s de señal previa (las luces parpadean y baja el sonido ambiente), solo se eligen si su objeto está a la vista, nunca empiezan en los últimos 5 s de una decisión ni durante Audio Sync, y cada uno resta Sanity (8, o 15 el jumpscare). El jumpscare tapa la pantalla 1,5 s y pausa la noche.
  - **Las alucinaciones:** con Sanity bajo 50, suenan golpes, pasos, susurros, rasguños, la estática y el celular a un lado de la pantalla, más seguidos y más fuertes mientras más baja. No restan Sanity y no suenan durante Audio Sync.
  - **El susto guionado:** a los 60 s de la noche 1, sin solicitudes, llega el jumpscare. Después, Gonzalo escribe "Todo bien hermano??…", su entrada parpadea, Matías responde con un botón y Gonzalo lo manda a usar el celular, cuyo borde parpadea hasta que lo abre. El chat es un dato de la noche (`NightData.scripted_chat`): se puede mover a la noche 0 en el Inspector.
  - **Datos y sonido:** los valores del director, de los screamers y de las alucinaciones están en `data/balance.tres`; las olas, los screamers de cada noche y el guion, en `data/nights/night_N.tres`. Hay 12 sonidos provisionales nuevos en `audio/sfx/` (los 7 del Plan 6 salen idénticos) y el ambiente del cuarto suena siempre. La figura de la ventana empieza escondida.
  - **Interfaz:** el cuaderno se cierra de golpe o se mancha de tinta (`InkBlot`), el chat tiene el botón de la respuesta guionada (`ScriptReply`), el contorno de un objeto puede parpadear (`ClickableSprite.blinking`) y el ejecutor de pruebas espera 0,2 s antes de salir.
  - Todos los commits están en `main` (de `75b4e13` a `3b4884a`, uno por tarea), más el de cierre.
- **Capturas revisadas a ojo** (`test/capture_screamers.gd`, en `C:\dev\capturas\`: `window.png`, `ink.png`, `jumpscare.png`, `script.png` y `script_phone.png`). Las cinco coinciden con lo que describe el plan: la figura con ojos rojos tapando la luna, la mancha de tinta sobre la página de El Trauco, el jumpscare (silueta a ×2 sobre gris teñido de rojo), el chat de Gonzalo con el botón de Matías y el celular con su contorno amarillo. Contra las capturas de la sesión 16: `jumpscare.png` y `script.png` salen idénticas píxel a píxel y `window.png` difiere en 3 píxeles; en `ink.png` y `script_phone.png` cambia la posición del escenario, porque la cámara sigue al mouse (la zona del cuaderno de `ink.png` difiere en un 0,3 %), y la hora del celular marca 00:58 en lugar de 00:57.
- **`docs/04`:** se agregó la sección **K** (probar los screamers y el director) y su fila en el índice. `docs/06` (Plan 7 ejecutado), `docs/02` (modelo de datos) y `docs/00_log.md` (S17 ✅, S18 siguiente) quedaron al día.

### Errores encontrados

- **Ninguno en el plan:** todos los bloques a reemplazar aparecieron una sola vez y no hubo que corregir código.
- **Dos diferencias de forma con el plan, sin efecto en el comportamiento:** en `scripts/desk/clickable_sprite.gd` se dejó una línea en blanco entre la propiedad `hovered` y el comentario de `blinking` (el plan las deja pegadas), y en `NightManager.advance()` el `return` de `if delta <= 0.0:` se escribió dentro del mismo reemplazo en lugar de conservar el original.
- **Avisos que no son errores:** al verificar que las pruebas nuevas fallan antes de implementar (Tareas 12 y 13), Godot avisó `2 resources still in use at exit`: es de las pruebas que abortan con el escritorio a medio liberar. Con el código implementado, las corridas terminan limpias.

### Pendientes Código

- [x] **S16: escribir el Plan 7 (screamers y director).**
- [x] **S17: ejecutar el Plan 7** (`docs/14`, 14 tareas).
- [ ] **S18: escribir el Plan 8** (`docs/00_log.md`): la noche 0 (tutorial, decisión de Benja): qué enseña y cuánto dura, las 5 noches como datos, las 7 entidades, el menú, el guardado, el resumen entre noches y las opciones. El susto guionado y su chat se mueven de la noche 1 a la 0 en el Inspector (grupo **Guion**), sin código.
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager` (hoy en 3).
- [ ] Planes 8 y 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos (también el de `phone.csv`).
- [ ] Plan 8: "Reducir destellos" debe apagar el parpadeo de las entradas y de los LED del mixer, y suavizar la señal previa, el apagón de las luces y los parpadeos rojos del jumpscare (Plan 7); decidir con Benja si "Temporizadores ×1,5" alarga también los plazos de los videos (el margen de justicia de los screamers no cambia).
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres, también los del Plan 7) y ponerlos en sus buses (hoy todos van a Master). Faltan sonidos para cuando llega un video y cuando se recibe (`docs/13`, "Fuera de este plan").
- [ ] Cuando llegue el arte: reemplazar el dibujo provisional del mixer y del celular, las barras de señal de las entradas y, desde el Plan 7, los screamers (el jumpscare de `Overlay/Jumpscare`, `ink_blot.gd`), la cortina (animación `scare` en lugar del `skew`) y las luces (`Darkness`) (`docs/13` y `docs/14`, "Fuera de este plan").
- [ ] Si en las pruebas con personas los videos y las interferencias se juntan con las olas de solicitudes: el director no los mueve hoy, y habría que ajustarlo (`docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte (correr el temporizador unos píxeles, o el ícono en el arte).
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si Benja quiere ajustarlos en el Inspector: pasar `QUESTION_COST` y `THINKING_TIME` a `BalanceData`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar los screamers y el director** (`docs/04`, K, unos 20 minutos). Para ver las alucinaciones sin esperar, hay que subir **Hallucination Start** a 100 y bajar **Hallucination Slowest** a 10 en `data/balance.tres`, y dejar 50 y 40 al terminar (si no, `test_balance.gd` falla).
- [ ] **Revisar las propuestas del susto guionado** (en `data/nights/night_1.tres`, grupo **Guion**): que sea un jumpscare, a los 60 s, y que el chat lo escriba Gonzalo.
- [ ] **Para el Plan 8 (S18): qué enseña la noche 0 y cuánto dura**, además de las 7 entidades.
- [ ] **Probar el mantenimiento** (`docs/04`, J, unos 20 minutos): la señal, Audio Sync, los videos y el celular.
- [ ] **Probar la noche** (`docs/04`, I, unos 15 minutos). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo, las reacciones y las 2 reacciones de un amigo herido;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - `ui.csv`: el aviso de daño (`CHAT_DAMAGE`), `PC_VIDEOS`, `ENTRY_STUNNED` y los textos de la pantalla final (`END_*`). Conserva los marcadores entre llaves, como `{friend}`;
  - del Plan 6: en `messages.csv`, el aviso del video (`FRIEND_VIDEO_SENT`); en `ui.csv`, los avisos de videos y señal (`CHAT_VIDEO_*`, `CHAT_SIGNAL_*` y `CHAT_OFFLINE`), el botón «Sincronizar» (`CHAT_SYNC`), las entradas (`ENTRY_VIDEO` y `ENTRY_OFFLINE`), la descarga (`DOWNLOAD_*`), el mixer (`MIXER_*`) y `END_CHOSEN_OFFLINE`; y todo `phone.csv`: las 12 publicaciones y el nombre de la red social, "copuchas";
  - el chat guionado del Plan 7 (`SCRIPT_SCARE_*`, en `messages.csv`) son tus textos, copiados tal cual: ajústalos si quieres.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** Benja avisa cuando una pieza esté lista y se integra en una sesión aparte. Lo más urgente:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5, que hoy usa piezas provisionales:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - **para el Plan 6, que hoy los dibuja provisionales en Godot:** el mixer visto desde arriba (440×430, o 220×215 a ×2), el celular ampliado (260×520, o 130×260 a ×2) y las barras de señal de las entradas (`docs/06` §3 y `docs/03` §6);
  - **para el Plan 7, que hoy usa la figura de la ventana y dibujos de Godot:** los screamers (manos o un rostro que tapan la pantalla, 1 o 2 jumpscares y la mancha de tinta), la animación `scare` de las cortinas y las luces (`pcLightOver`, `pcLightUnder` y `pcDesklight`) como archivos aparte (`arte_pendiente.md` §3).
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

### Continuación: la entidad se identifica preguntando (cambio de Benja)

Al terminar el Plan 7, Benja pidió un cambio de mecánica: la identificación era demasiado breve y obligaba a exponer toda la información de entrada. Quería que el amigo empezara con algo simple ("Mati, ayuda!!", "¿Estás ahí?"), quizá con una pista opcional, y que el jugador tuviera que hacer las preguntas correctas hasta dar con la entidad, con más tiempo y con las preguntas y los mensajes bien manejados (a cargo de Claude). Claude lo juzgó realizable en la misma sesión (Sonnet 5.5, esfuerzo xhigh) y lo hizo sin un plan aparte, con pruebas primero. **Quedó sin commit: Claude pregunta a Benja antes** (la autorización de los 14 commits del Plan 7 no cubre este cambio).

#### Realizado

- **El mensaje inicial es corto:** un saludo al azar (6 en `data/catalog.tres`, `greeting_keys`, con sus textos `FIRST_CALL_*` en `messages.csv`), el lugar y, con la probabilidad de la noche, una **pista**: una de las 2 características, clickeable. Antes traía las 2 características camufladas y hasta todas las observaciones.
- **Todo lo demás se pregunta:** las características, los señuelos y las observaciones salen solo al preguntar su categoría. La respuesta repite lo de esa categoría (también la pista); repetir la pregunta tira la estática de nuevo, así que sigue sirviendo para recuperar una frase tapada. No cambió la regla de los 5 s ni el resto de la estática.
- **Datos nuevos:**
  - `NightData.first_hint_chance` (probabilidad de pista) y `decoys_per_request` (antes `decoys_in_first_message`); se quitó `first_message_observations`;
  - `BalanceData.question_cost` (5 s, grupo **Identificación**): lo que cuesta una pregunta, ahora ajustable en el Inspector;
  - `ContentCatalog.greeting_keys`; el validador avisa si no hay saludos o si falta un texto.
- **Equilibrio (valores iniciales, sin probar):** el jugador atiende un chat a la vez, así que lo que importa es cuánta atención pide cada solicitud. Antes pedía unos 10 a 15 s; ahora unos 25 a 40 s. Para mantener más o menos la carga de cada noche:

  | | N1 | N2 | N3 | N4 | N5 |
  | --- | --- | --- | --- | --- | --- |
  | Tiempo para responder (antes) | 90 (45) | 80 (40) | 75 (35) | 70 (32) | 65 (30) |
  | Solicitudes por noche (antes) | 4 (6) | 6 (9) | 7 (12) | 8 (15) | 10 (18) |
  | Probabilidad de pista inicial | 100 % | 75 % | 50 % | 35 % | 20 % |

  Las solicitudes simultáneas, las olas, los señuelos, los videos y los screamers no cambiaron.
- **Pruebas: de 373 a 382 OK, 0 fallidas.** Se escribieron antes que el código (hubo 148 fallas esperadas al cambiar el catálogo de pruebas). Nuevas: la pista opcional, el saludo del catálogo, el costo de preguntar, el mensaje inicial con y sin pista, el validador de saludos, los valores reales de cada noche y una de punta a punta (`test_la_entidad_se_identifica_preguntando`). `test_text_csv.gd` vigila que cada fila de los CSV tenga 3 columnas.
- **Capturas:** `test/capture_chat.gd` se adaptó al flujo nuevo. La captura `C:\dev\capturas\chat_preguntas.png` muestra el saludo, el lugar y la pista en el mensaje inicial, y después las respuestas a "¿Qué ves?" y "¿Cómo está el ambiente?" con sus frases clickeables.
- **Documentos al día:** `docs/02` (§1, §2, §3, §6, §9, §10), `spook_dial_design.md` (§8.1, §8.3 y §8.4), `CLAUDE.md` (decisión nueva del 03-11-2026 y dos filas del 26-10 ajustadas), `docs/04` (sección G y cómo ajustarlo) y `docs/00_log.md`.

#### Errores encontrados

- **Una coma sin comillas cortaba un saludo:** `¡Mati, ayuda!!` salía como `¡Mati`. Se vio al imprimir una solicitud con los textos reales (las pruebas con claves falsas no lo notaban). Se corrigió con comillas y se agregó `test_text_csv.gd`, que revisa todos los CSV; los demás estaban bien.
- **Una prueba comparaba frases clickeables con claves sin asteriscos**, que el `TranslationServer` real no vuelve clickeables. Se cambió a comparar el texto.
- **El equilibrio es una estimación.** Cambiar la carga de cada solicitud mueve todos los números de la noche; no se pudo jugar. Hay que probarlo (ver Pendientes).

#### Pendientes Código (nuevos)

- [ ] **Plan 8 (S18): la noche 0 (tutorial) tiene que enseñar a preguntar** (qué categoría pregunta cada cosa, que cuesta tiempo y que la estática se recupera repitiendo). Con el tutorial, la noche 1 puede suponer que ya se sabe.
- [ ] Si al probar se siente seco o lento: una pequeña demora de "escribiendo…" en las respuestas del amigo, y marcar en el chat qué categorías ya se preguntaron (hoy cada botón siempre se ve igual).
- [ ] Con las 7 entidades (Plan 8): revisar que el contenido haga importar las preguntas (ver Pendientes Externos) y, si conviene, que el validador avise cuando una entidad tenga todas sus características en una sola categoría.

#### Pendientes Externos (nuevos)

- [ ] **Probar la identificación por preguntas** (`docs/04`, G, unos 10 minutos) y decir cómo se siente: tiempos, cantidad de solicitudes por noche, qué tan seguido llega la pista y el costo de preguntar (todo se ajusta en el Inspector; `docs/04`, G, "Para ajustar").
- [ ] **Corregir los 6 saludos** (`FIRST_CALL_*` en `messages.csv`): son borradores de Claude, en primera persona y cortos.
- [ ] **Al diseñar las 7 entidades:** reparte las características en categorías distintas (Vista, Sonido, Ambiente, Rastro) y procura que lo que decide las reglas (las observaciones) esté en otra categoría que las características. Así la pregunta correcta cambia según el caso, y preguntarlo todo cuesta caro.

---

## Sesión 16 — 2 de noviembre de 2026 — Plan 7 escrito: screamers y director

Benja pidió escribir el Plan 7 con `superpowers:writing-plans`. Se escribió en Opus 5.5 con esfuerzo high, justo después de S15 (la fecha objetivo era el 16 de noviembre). Benja todavía no había probado el mantenimiento (`docs/04`, J), así que no hubo notas de prueba que meter al plan.

### Realizado

- **Nuevo `docs/14_plan_screamers_director.md`:** el Plan 7 en 14 tareas con código completo. Lleva las pruebas de 326 a 373:
  - lógica pura en `scripts/core/`: el director de ritmo (`PacingDirector`: cuándo llega cada solicitud y cada screamer), qué screamer toca y si es justo (`Screamer`), las alucinaciones (`HallucinationClock`) y el chat guionado (`ChatScript`). `NightState` baja Sanity de golpe y `NightManager` pausa la noche durante el jumpscare;
  - datos: los valores del director, de los screamers y de las alucinaciones en `BalanceData`; las olas, los screamers de cada noche y el guion en `NightData`; los tipos de screamer (`ScareKind`) y el chat guionado (`ChatScriptData` y `ChatLineData`). La noche 1 recibe el susto guionado y el chat de Gonzalo, con tus textos tal cual;
  - `ScreamerManager`, un nodo nuevo del escritorio: la señal previa (las luces parpadean y baja el sonido ambiente), los 7 screamers (la cortina, la figura en la ventana, el celular, las luces, el golpe del cuaderno, la mancha de tinta y el jumpscare), las alucinaciones a un lado de la pantalla y el chat que sigue al susto guionado;
  - la interfaz: el cuaderno que se cierra de golpe o se mancha de tinta, el botón de la respuesta de Matías en el chat, la entrada que avisa mientras el amigo espera esa respuesta, el contorno del celular que parpadea, el sonido ambiente del cuarto, la oscuridad de las luces, la pantalla del jumpscare y la figura de la ventana escondida;
  - 12 sonidos provisionales nuevos, que genera `tools/make_placeholder_sounds.py`: el ambiente, uno por screamer y cuatro alucinaciones (los 7 del Plan 6 salen idénticos);
  - la sección K de `docs/04` (probar los screamers y el director), que se aplica al ejecutar el plan.
- **Decisiones de Benja** (en `CLAUDE.md`, el diseño v2 §5, §10.2, §11 y §14, `docs/02` §2 y §6, `docs/05` y `docs/06`):
  - **olas con respiro:** las solicitudes llegan en grupos y, después de cada uno, hay unos 25 s sin solicitudes nuevas; se aprietan hacia las 06:00, y un amigo herido atrasa las que faltan;
  - **los screamers llegan en cualquier momento**, solo con las reglas de justicia;
  - **alucinaciones del cuarto y del juego:** golpes, pasos, susurros y rasguños, y también la estática y el celular; no restan Sanity y no suenan durante Audio Sync;
  - **la figura de la ventana, escondida:** aparece al asustar y, a ×2, es el jumpscare provisional;
  - **noche 0 (tutorial):** una noche nueva antes de la 1, que se diseña en el Plan 8. El susto guionado y su chat son datos de una noche: mientras no exista la noche 0, van en la 1;
  - **el chat guionado tras el susto:** Benja escribió los tres mensajes; Matías responde con un botón, y después el borde del celular parpadea hasta que lo abre. Más adelante quiere una progresión guionada entre los amigos: quedó en `docs/05` (#20, después de la v1), y los chats guionados ya son datos.
- **Propuestas de Claude, que Benja puede cambiar en el Inspector** (`data/nights/night_1.tres`, grupo **Guion**): el susto guionado es el jumpscare (por "te escuché gritar"), llega a los 60 s y el chat lo escribe Gonzalo. También los valores nuevos de `docs/02` §6: olas de 2, 3, 3, 4 y 4 solicitudes; 0, 3, 4, 5 y 6 screamers por noche; al menos 25 s entre dos screamers y ninguno en los primeros 30 s; ningún screamer durante una ronda de Audio Sync; alucinaciones con Sanity bajo 50.
- **El plan se verificó en Godot 4.7.2:**
  - todo su código se ejecutó en una copia aparte, con 373 pruebas OK, sin errores al correr, y cinco capturas revisadas: `C:\dev\capturas\plan7_window.png` (la figura en la ventana), `plan7_ink.png` (la mancha de tinta en la página de El Trauco), `plan7_jumpscare.png`, `plan7_script.png` (el chat de Gonzalo con el botón de Matías) y `plan7_script_phone.png` (el celular con su contorno encendido);
  - después, un script aplicó el plan **tal como está escrito** a una copia limpia: los 27 conteos de pruebas coinciden, incluidas las fallas esperadas, todos los bloques a reemplazar aparecen una sola vez, y el código resultante es idéntico al probado, también los 19 sonidos. Se validó dos veces, la segunda con el plan final;
  - las copias ya se borraron.
- El código del plan lo armó un script que toma los cambios de cada tarea de los commits de la copia de trabajo, así que sus tabuladores son los del código probado.
- `docs/06`: el Plan 7 queda escrito, y el Plan 8 incluye la noche 0. `arte_pendiente.md` §3: qué usa hoy cada screamer. `docs/00_log.md`: S16 ✅ y S17 ▶.

### Errores encontrados

- **Al revisar las capturas** (antes de armar el plan): la mancha de tinta tapaba solo el centro de la página y las reglas seguían legibles, la silueta del jumpscare casi no se veía sobre negro, y la captura del chat salía antes de que el mensaje terminara de escribirse. Se corrigieron: tres manchas, una sobre otra; un destello gris detrás de la silueta; y 1,5 s de espera en la captura.
- **A veces, al terminar las pruebas, Godot avisaba `2 resources still in use at exit`:** los sonidos que las pruebas dejan sonando (el ambiente y los screamers) se liberan en el hilo de audio, y el ejecutor salía antes. Ahora espera 0,2 s antes de salir (Tarea 12): 6 corridas seguidas salieron limpias.
- **Errores de Claude, sin efecto en el plan:** al escribir el código en la copia de trabajo, una prueba del chat guionado sumaba tiempos que no dan exacto en coma flotante (2,4 + 0,1), quedó un contador viejo en `RequestManager`, y un `if` en línea no servía para un arreglo con tipo. Una prueba nueva pasaba antes de implementar su código; se cambió para que falle primero. Todo se corrigió antes de armar el plan.

### Pendientes Código

- [x] **S16: escribir el Plan 7 (screamers y director).**
- [ ] **S17: ejecutar el Plan 7** (`docs/14`, 14 tareas), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Plan 8 (S18): la noche 0 (tutorial, decisión de Benja): qué enseña y cuánto dura. El susto guionado y su chat se mueven de la noche 1 a la 0 en el Inspector (grupo **Guion**), sin código.
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 8 y 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos (desde el Plan 6, también el de `phone.csv`).
- [ ] Plan 8: "Reducir destellos" debe apagar el parpadeo de las entradas y de los LED del mixer, y suavizar la señal previa, el apagón de las luces y los parpadeos rojos del jumpscare (Plan 7); decidir con Benja si "Temporizadores ×1,5" alarga también los plazos de los videos.
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres, también los del Plan 7) y ponerlos en sus buses (hoy todos van a Master). Faltan sonidos para cuando llega un video y cuando se recibe (`docs/13`, "Fuera de este plan").
- [ ] Cuando llegue el arte: reemplazar el dibujo provisional del mixer y del celular, las barras de señal de las entradas y, desde el Plan 7, los screamers, la cortina y las luces (`docs/13` y `docs/14`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte (correr el temporizador unos píxeles, o el ícono en el arte).
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si Benja quiere ajustarlos en el Inspector: pasar `QUESTION_COST` y `THINKING_TIME` a `BalanceData` (`FIRST_REQUEST_DELAY` pasa con el Plan 7).
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Después de S17: probar los screamers y el director** (`docs/04`, K, unos 20 minutos).
- [ ] **Revisar las propuestas del susto guionado** (después de S17, en `data/nights/night_1.tres`, grupo **Guion**): que sea un jumpscare, a los 60 s, y que el chat lo escriba Gonzalo.
- [ ] **Para el Plan 8 (S18): qué enseña la noche 0 y cuánto dura**, además de las 7 entidades.
- [ ] **Probar el mantenimiento** (`docs/04`, J, unos 20 minutos): la señal, Audio Sync, los videos y el celular.
- [ ] **Probar la noche** (`docs/04`, I, unos 15 minutos). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo, las reacciones y las 2 reacciones de un amigo herido;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - `ui.csv`: el aviso de daño (`CHAT_DAMAGE`), `PC_VIDEOS`, `ENTRY_STUNNED` y los textos de la pantalla final (`END_*`). Conserva los marcadores entre llaves, como `{friend}`;
  - del Plan 6: en `messages.csv`, el aviso del video (`FRIEND_VIDEO_SENT`); en `ui.csv`, los avisos de videos y señal (`CHAT_VIDEO_*`, `CHAT_SIGNAL_*` y `CHAT_OFFLINE`), el botón «Sincronizar» (`CHAT_SYNC`), las entradas (`ENTRY_VIDEO` y `ENTRY_OFFLINE`), la descarga (`DOWNLOAD_*`), el mixer (`MIXER_*`) y `END_CHOSEN_OFFLINE`; y todo `phone.csv`: las 12 publicaciones y el nombre de la red social, "copuchas";
  - el chat guionado del Plan 7 (`SCRIPT_SCARE_*`, en `messages.csv`) son tus textos, copiados tal cual: ajústalos si quieres.
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`.** Benja avisa cuando una pieza esté lista y se integra en una sesión aparte. Lo más urgente:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5, que hoy usa piezas provisionales:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - **para el Plan 6, que hoy los dibuja provisionales en Godot:** el mixer visto desde arriba (440×430, o 220×215 a ×2), el celular ampliado (260×520, o 130×260 a ×2) y las barras de señal de las entradas (`docs/06` §3 y `docs/03` §6);
  - **para el Plan 7, que hoy usa la figura de la ventana y dibujos de Godot:** los screamers (manos o un rostro que tapan la pantalla, 1 o 2 jumpscares y la mancha de tinta), la animación `scare` de las cortinas y las luces (`pcLightOver`, `pcLightUnder` y `pcDesklight`) como archivos aparte (`arte_pendiente.md` §3).
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

---

## Sesión 15 — 2 de noviembre de 2026 — Plan 6 ejecutado: mantenimiento

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5 (el registro proponía Sonnet 5.5 · high). Se adelantó al 2 de noviembre, justo después de S14 (la fecha objetivo era del 13 al 15 de noviembre). Al empezar, Benja autorizó todos los commits del plan en `main` y el push al terminar.

### Realizado

- **Las 17 tareas de `docs/13`, con 326 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`), sin errores al correr. Coincidieron todos los conteos del plan, incluidas las fallas esperadas (251 → 252, 255, 259, 264, 269, 276, 283, 289, 294, 302, 303, 312, 314, 319, 323 y 326).
  - El código se copió de los bloques del plan con un script, para conservar sus tabuladores. Antes de tocar el proyecto, el mismo script aplicó el plan completo a una copia limpia del último commit, y cada texto a reemplazar aparecía una sola vez. El código final es idéntico al de esa copia, salvo una línea en blanco (ver "Errores encontrados"), y los 7 sonidos generados también son idénticos.
  - **La señal:** cada amigo pierde señal a su propio ritmo, y las interferencias le quitan 40 de golpe. Se anuncian 3 s antes: su entrada titila y suena estática. El dial de Connection es el promedio de las tres señales.
  - **Un amigo sin señal:** su mensaje llega tapado entero y no lee las preguntas ni las respuestas. Si se le acaba el tiempo, elige al azar una de las 3 acciones que no son la correcta, y esa decisión no baja Trust. Mientras haya amigos sin señal, Trust baja 1 punto cada 4 s por cada uno. La pantalla final dice si el amigo decidió sin señal.
  - **Avisos en el chat:** el amigo avisa que mandó un video, y el juego avisa, centrado, si el video se recibió (en verde) o se perdió (en rojo), y si el amigo se quedó sin señal (en rojo) o volvió a conectarse (en verde).
  - **Las entradas del PC:** 5 barras de señal, el parpadeo de una interferencia, "Sin señal" en gris y "Video 15" mientras un video espera su descarga.
  - **Los videos se descargan en el chat,** manteniendo presionada su barra, que aparece sobre la de identificación: 15 s para empezar, 20 s para terminar y 10 s de descarga (15 s con la señal bajo 50; sin señal no avanza).
  - **Audio Sync en el mixer** (`scenes/ui/mixer_view.tscn`, provisional): la vista desde arriba, con los dos VU-metros azules, las luces del ritmo y un fader por amigo. Una base marca el tiempo, el amigo aplaude un ritmo de 4 u 8 aplausos y Matías lo repite con la barra espaciadora o con clics. Si sale bien, la señal vuelve a 100. El botón «Sincronizar» del chat abre el mixer en el canal de ese amigo, con la ronda empezada. En la noche 1, el mixer dice que la señal está estable y el botón no aparece.
  - **El celular** (`scenes/ui/phone_view.tscn`, provisional): un feed de 12 publicaciones que se repite sin fin y se scrollea con la rueda o con el touchpad. Mientras se scrollea, Sanity sube 4 por segundo. Las publicaciones son datos (`PhonePostData`, en `data/catalog.tres`).
  - **El mixer y el celular son modos exclusivos:** se abren sin paneles y se cierran con clic derecho, con `Esc`, con un clic fuera o al terminar la noche.
  - **7 sonidos provisionales** en `audio/sfx/`, generados por `tools/make_placeholder_sounds.py`.
- **Textos nuevos**, borradores reales que tú corriges: en `messages.csv`, `FRIEND_VIDEO_SENT`; en `ui.csv`, `CHAT_VIDEO_*`, `CHAT_SIGNAL_*`, `CHAT_OFFLINE`, `CHAT_SYNC`, `ENTRY_VIDEO`, `ENTRY_OFFLINE`, `DOWNLOAD_*`, `MIXER_*` y `END_CHOSEN_OFFLINE`; y el nuevo `data/text/phone.csv`, con las 12 publicaciones y el nombre de la red social, "copuchas".
- **Capturas revisadas** (`C:\dev\capturas\mixer.png`, `download.png` y `phone.png`), idénticas byte a byte a las que tomó S14 al validar el plan. Se cumple todo lo que pide el plan:
  - en el mixer: "TÚ" y "GONZALO" bajo los VU-metros, los aplausos en azul, León en 72, Gonzalo elegido en 18 y Agustín en 0 y en rojo, "ESCUCHA A GONZALO" y la ayuda. En el PC, León tiene 4 barras, Gonzalo 1 y Agustín ninguna, con "Sin señal";
  - en la descarga: el mensaje de León, la barra verde con "▼ DESCARGANDO 39 % · 17", el botón "SINCRONIZAR" y la pestaña "AGUSTÍN 31 •". En el PC, "Video 17" en León y "31" en Agustín;
  - en el celular: "02:07", la señal, la batería, "copuchas" en naranja y las publicaciones (autor, paisaje, "♥" con su número y el texto en dos líneas), sin salirse de la pantalla.
- `docs/04`: nueva sección **J** (probar el mantenimiento) y arreglos en C, G, H e I, que hablaban de "Clic en Mixer" y de videos que llegaban solos. `docs/06`: el Plan 6 queda ejecutado. `docs/02` §10: `PhonePostData` y los valores nuevos de `BalanceData`. `docs/00_log.md`: S15 ✅ y S16 ▶.
- 17 commits en `main` (uno por tarea), subidos a GitHub al terminar.

### Errores encontrados

- **El plan se aplicó tal como está escrito, con un solo cambio cosmético:** en la Tarea 1, el bloque nuevo de `test/test_balance.gd` dejaba una sola línea en blanco antes de la función siguiente, y el resto del archivo usa dos. Se agregó la que faltaba.
- **En la Tarea 13, el primer import muestra `Cannot open file 'res://data/text/phone.es.translation'`:** `project.godot` ya registra la traducción, y es ese mismo import el que la crea. No es un error del código: el filtro del plan (`SCRIPT|Parse`) no lo muestra, y un segundo import y las pruebas salen sin errores.
- **Errores de Claude, sin efecto en el juego:** el script que comparaba los conteos falló una vez aunque el conteo coincidía, porque el Godot de Windows termina sus líneas con `\r`; se corrigió y la Tarea 2 siguió desde su paso 3. Al actualizar `docs/00_log.md` quedaron unas filas de la tabla vieja de S15, que se quitaron antes del commit.
- **Ya conocido:** en una entrada del PC en alerta, los segundos tocan el ícono ⚠ del arte. Se ve otra vez en `phone.png` ("Video 16").

### Pendientes Código

- [x] **S15: ejecutar el Plan 6.**
- [ ] **S16: escribir el Plan 7 (screamers y director)**, con Opus 5.5 en esfuerzo high (`docs/00_log.md`). El director también puede decidir cuándo llegan los videos y las interferencias, que hoy se reparten parejo en la noche (`docs/13`, "Fuera de este plan").
- [ ] Pasar a `.tres` las entidades que Benja refine, agregar El Tue Tué y La Calchona a la noche 1, y cambiar a 1 el **Night Number** de `RequestManager`.
- [ ] Planes 7 a 9 según `docs/00_log.md`.
- [ ] Plan 8: registrar los `.en.translation` cuando la columna `en` tenga textos (desde el Plan 6, también el de `phone.csv`).
- [ ] Plan 8: "Reducir destellos" debe apagar el parpadeo de las entradas y de los LED del mixer; decidir con Benja si "Temporizadores ×1,5" alarga también los plazos de los videos.
- [ ] Plan 9: incluir `fonts/departure_mono/OFL.txt` en la exportación del juego, como pide la licencia de la fuente.
- [ ] Plan 9: reemplazar los sonidos provisionales de `audio/sfx/` (con los mismos nombres) y ponerlos en sus buses (hoy todos van a Master). Faltan sonidos para cuando llega un video y cuando se recibe (`docs/13`, "Fuera de este plan").
- [ ] Cuando llegue el arte: reemplazar el dibujo provisional del mixer y del celular, y las barras de señal de las entradas (`docs/13`, "Fuera de este plan").
- [ ] Menor: que los segundos de una entrada en alerta no toquen el ícono ⚠ del arte (correr el temporizador unos píxeles, o el ícono en el arte).
- [ ] Si al probar las respuestas delatan demasiado las características: agregarles señuelos (`docs/10`, "Fuera de este plan").
- [ ] Si Benja las quiere: varias versiones de cada reacción, para que no se repitan.
- [ ] Si Benja quiere ajustarlos en el Inspector: pasar `QUESTION_COST`, `THINKING_TIME` y `FIRST_REQUEST_DELAY` a `BalanceData` (`docs/12`, "Fuera de este plan").
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Probar el mantenimiento** (`docs/04`, J, unos 20 minutos): la señal, Audio Sync, los videos y el celular.
- [ ] **Probar la noche** (`docs/04`, I, unos 15 minutos). Si cambias un valor de `data/balance.tres` a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.
- [ ] **Probar el chat y el cuaderno con el estilo nuevo** (`docs/04`, G y H, unos 20 minutos). En la noche 3, si el mensaje inicial no trae lo que decide la regla, pregunta: así está diseñada.
- [ ] **Revisar El Trauco en el Inspector** (`docs/04`, F, unos 5 minutos).
- [ ] Refinar las 3 entidades a partir del borrador de `docs/09_propuesta_entidades.md` (plantilla de `docs/02` §7). Las características llevan su frase clickeable entre asteriscos, y esa frase tiene que entenderse sola: también es su nombre en el cuaderno.
- [ ] **Escribir los señuelos** (`data/catalog.tres` y `messages.csv`). Cada lugar necesita al menos los que pide la noche (hasta 3); las pruebas avisan si faltan.
- [ ] **Corregir los textos que escribió Claude:**
  - `messages.csv`: el lugar, las características, las observaciones, los señuelos, las respuestas "nada", la decisión del amigo, las reacciones y las 2 reacciones de un amigo herido;
  - `notebook.csv`: el folclore, las acciones, las preguntas y las reglas de El Trauco;
  - `ui.csv`: el aviso de daño (`CHAT_DAMAGE`), `PC_VIDEOS`, `ENTRY_STUNNED` y los textos de la pantalla final (`END_*`). Conserva los marcadores entre llaves, como `{friend}`;
  - **del Plan 6 (S15):** en `messages.csv`, el aviso del video (`FRIEND_VIDEO_SENT`); en `ui.csv`, los avisos de videos y señal (`CHAT_VIDEO_*`, `CHAT_SIGNAL_*` y `CHAT_OFFLINE`), el botón «Sincronizar» (`CHAT_SYNC`), las entradas (`ENTRY_VIDEO` y `ENTRY_OFFLINE`), la descarga (`DOWNLOAD_*`), el mixer (`MIXER_*`) y `END_CHOSEN_OFFLINE`; y todo `phone.csv`: las 12 publicaciones y el nombre de la red social, "copuchas".
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] **Arte: la lista completa está en `arte_pendiente.md`** (desde el 2 de noviembre). Benja avisa cuando una pieza esté lista y se integra en una sesión aparte. Lo más urgente, para los planes 4 a 7:
  - **la interfaz del cuaderno:** la página (449×696, como `screen_sprite`; va a la derecha), las pestañas del índice y los bocetos de las entidades (unos 96×96). El tema `scenes/ui/notebook_theme.tres` los recibe;
  - para el chat, ahora es opcional: el estilo de terminal ya está hecho en Godot, y el arte de burbujas, botones y pestañas puede reemplazarlo;
  - **para el Plan 5, que hoy usa piezas provisionales:** el celular sin la hora y una tira de dígitos LCD "0123456789:", los diales rediseñados (manómetro con ícono y LED) y las pantallas de victoria y derrota. Opcional: las marcas de vida de las entradas;
  - **para el Plan 6, que hoy los dibuja provisionales en Godot (decisión de Benja, sesión 14):** el mixer visto desde arriba (el cuerpo, los dos VU-metros azules, la perilla de un fader, los LED y una fila de luces para el ritmo; 440×430, o 220×215 a ×2), el celular ampliado con unas 12 publicaciones o con la animación del scroll (260×520, o 130×260 a ×2) y las barras de señal de las entradas (`docs/06` §3 y `docs/03` §6);
  - para el Plan 7 (S16): los screamers y las luces (`pcLightOver`, `pcLightUnder` y `pcDesklight`) como archivos aparte (`docs/06` §3).
- [ ] Al probar con personas (semana 5): fijarse si notan que en la noche 3 hay que preguntar. Si no, una ayuda posible es marcar en el cuaderno qué observaciones ya contó el amigo (iría a la lista de `docs/05`).

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
