# Prompts de las sesiones de Fable 5.2 (F0 a F8)

Salen del audit `docs/34_audit_fable.md`, que dice por qué existe cada sesión, cuándo va y con qué esfuerzo. Benja abre cada una eligiendo **Fable 5.2** con `/model`, con el esfuerzo de la tabla, y escribe:

`Lee docs/35_prompts_fable.md y haz la sesión F<n>.`

Cada sesión lee primero la sección "Para todas las sesiones" y después la suya. Los prompts dicen **qué** lograr y **cuándo está terminado**. El **cómo** lo decide Fable.

---

## Para todas las sesiones

**Lee antes de empezar:** `CLAUDE.md` completo, `docs/00_log.md`, la entrada más reciente de `resumen.md` y la fila de tu sesión en `docs/34_audit_fable.md`. `resumen.md` pesa más de 400 KB: lee solo las entradas que necesites.

**Lo que ya está aprobado, sin preguntar:**

- leer cualquier archivo del proyecto y correr las pruebas (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`);
- crear y borrar archivos en tu scratchpad;
- escribir scripts de prueba o de análisis en `test/` y `tools/`;
- correr los scripts de captura con `timeout 150`.

**Lo que hay que preguntar o respetar:**

- **Commits:** al empezar, pregúntale a Benja si autoriza los commits de la sesión (regla 11). Nunca hagas push.
- **El editor de Godot:** antes de usar `--import`, pregúntale a Benja si lo tiene cerrado.
- **Solo lectura:** los `.aseprite` y PNG de Benja (regla 5). El diseño v2 cambia solo con decisiones de Benja.
- **Alcance:** nada que agregue una mecánica entra sin que Benja lo decida (regla 6). Si encuentras una idea buena, anótala en tu informe, no la implementes.
- **El árbol de git:** si hay cambios sin commitear que no son tuyos (por ejemplo, los de S21p), no los mezcles con los tuyos. Pregúntale a Benja si los commitea él antes.

**Terminar el trabajo.** No pares mientras quede trabajo que Benja pidió. Los errores, los tiempos agotados, los archivos que OneDrive bloquea (ver `CLAUDE.md`, "Entorno técnico") y las pruebas que fallan son obstáculos normales: diagnostícalos y sigue. Para solo si la tarea necesita una decisión de Benja o si el obstáculo es deliberado, como un archivo de solo lectura. Las preguntas breves se hacen durante la sesión, con opciones y una recomendada (regla 3); mientras Benja contesta, sigue con lo que no depende de la respuesta.

**Comunicar.** Benja no ve tus herramientas ni los archivos que abriste. Tu mensaje final se tiene que entender solo: primero lo importante, en español claro, sin nombres que inventaste durante el trabajo. Las instrucciones de Godot para Benja siguen la regla 2.

**Al cerrar (regla 4):** una entrada al inicio de `resumen.md` con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos (arrastra los abiertos); el estado de tu sesión y la siguiente en `docs/00_log.md`; y `CLAUDE.md` y el diseño v2 solo si Benja cambió una decisión.

---

## F0 · `CLAUDE.md` más liviano (opcional)

**Esfuerzo:** medium. **Tipo:** mantenimiento, sin código.

### Tu tarea

`CLAUDE.md` pesa 55 KB y su tabla "Decisiones tomadas" tiene 93 filas, muchas reemplazadas por otras más nuevas ("Desde el 11-nov…", "reemplaza a la del 2-nov"). Cada sesión lo carga entero. Propón una versión que diga lo mismo que rige hoy en mucho menos espacio, sin perder ninguna decisión vigente.

- Usa la skill **`claude-api`** con el subcomando **`prompt-audit`** sobre `CLAUDE.md` y los archivos de memoria. Sirve para encontrar instrucciones viejas, repetidas o contradictorias.
- Las decisiones reemplazadas **no se borran**: pasan a un archivo nuevo en `docs/` (con el siguiente número libre, por ejemplo `docs/36_decisiones_historicas.md`), con su fecha. `CLAUDE.md` queda con la decisión vigente de cada tema y un enlace a ese archivo.
- No cambies el sentido de ninguna regla. Si 2 decisiones se contradicen, pregúntale a Benja cuál rige.

### Terminado cuando

Benja aprobó el diff. `CLAUDE.md` quedó con todas las decisiones vigentes y mide menos de la mitad, y nada se perdió (lo reemplazado está en el archivo nuevo).

---

## F1 · Caza de errores: la noche que no termina y los estados cruzados

**Esfuerzo:** xhigh. **Tipo:** diagnóstico, pruebas y correcciones. **Antes del 22 de noviembre**, porque las pruebas con personas empiezan el 23.

### Tu tarea

Desde el Plan 9.9, una noche termina solo cuando `RequestManager.night_complete()` es verdadero: el director en DONE, nada abierto, los videos resueltos y la historia terminada. No tiene tope de tiempo. Si una combinación de estados deja algo abierto para siempre, la noche no termina, y el tester se queda mirando un escritorio quieto. Las 872 pruebas miran una pieza a la vez, y `test_balance.gd` usa un modelo que "juega bien". Nada juega la escena real como la jugaría una persona torpe o rara.

Encuentra y corrige los errores que aparecen cuando los sistemas se cruzan. Algunos sospechosos, sin confirmar:

- un amigo aturdido o sin señal cuando llega una decisión de la historia o la ola final;
- un video atrasado (amigo aturdido) cuando todo lo demás ya terminó;
- una línea de la llamada que espera a que la llamada se vea, mientras algo impide que se vea;
- la pausa (Esc), Audio Sync, el celular o un audio sonando justo cuando cambia la fase del director;
- perder o ganar mientras un panel está abierto; volver al menú y empezar otra noche (lo que queda vivo de la anterior);
- el tutorial (noche 0) con clics fuera de orden;
- Extremo, con el amigo herido desde el principio.

**El entregable principal es una prueba que juega al azar:** un script sin pantalla que carga el escritorio real y juega muchas noches con semillas distintas. Cubre las noches 1 a 5 de los 3 modos y la noche 0. Elige respuestas buenas, malas o ninguna, pregunta de más, abre y cierra paneles, deja pasar el tiempo y sincroniza a veces. En cada noche comprueba que:

- termina (gana o pierde) antes de un tope generoso, por ejemplo 15 minutos de juego;
- no hay errores de script;
- los medidores quedan en su rango;
- la historia nunca mata a un amigo ni hace perder (regla 9).

Cuando reproduzcas un error, anota la semilla. Después escribe una prueba chica que lo muestre, corrígelo y deja la prueba. La prueba al azar queda en `test/` para que S22 y las sesiones siguientes la vuelvan a correr. Si es lenta, que `run_tests.gd` corra pocas semillas y un script aparte corra muchas.

Si un error viene de cómo están mezcladas las responsabilidades de `RequestManager`, corrígelo con el cambio mínimo y anótalo para F7. No reestructures en esta sesión.

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:systematic-debugging` | Cada error se entiende antes de corregirlo: causa raíz, no parche. |
| `superpowers:test-driven-development` | Cada corrección entra con la prueba que la muestra fallando. |
| `godot:godot-gdscript-headless-testing` | La prueba al azar sin pantalla, que falla con un código distinto de 0. |
| `godot:godot-signals-groups` y `godot:godot-nodes-scenes` | Lo que queda conectado o vivo al cambiar de noche. |
| `code-review` (con esfuerzo high) | Al final, revisar tu propio diff antes de cerrar. |
| `superpowers:verification-before-completion` | Correr todas las pruebas y abrir una noche de verdad antes de decir que está listo. |

### Terminado cuando

- La prueba al azar corre al menos 200 noches sin una noche que no termine ni un error de script.
- Cada error encontrado tiene su prueba y su corrección, o una explicación de por qué no se corrigió.
- Todas las pruebas pasan, también `test_balance`.
- El informe para Benja dice qué se encontró, cómo se manifestaba en el juego y qué conviene mirar en las pruebas con personas.

---

## F2 · Las 7 criaturas como puzzles

**Esfuerzo:** high. **Tipo:** análisis de contenido y borradores. **Antes del 21 de noviembre**, para que Benja alcance a corregir antes del congelamiento (25 de noviembre).

### Tu tarea

Las 7 criaturas (`data/entities/*.tres` y sus textos en `notebook.csv` y `messages.csv`) son un borrador de Claude del 4 de noviembre. Benja las corrige antes del 25. Nadie ha medido si funcionan como puzzles de Keep Talking. `ContentValidator` revisa que la forma sea válida, no que el puzzle sea bueno. Tu trabajo es medirlas, decir qué falla y dejar borradores mejores, para que Benja corrija sobre algo ya bueno.

Mide, con un script de análisis que quede en `tools/` o `test/`:

- **Identificar:** qué preguntas distinguen a cada criatura de las otras en cada noche, sobre todo desde la noche 3, donde comparten 2 características. Si hay pares que no se distinguen con las preguntas que existen, o que se distinguen sin preguntar nada, anótalo.
- **Decidir:** para cada criatura, si cada fila de la tabla se alcanza, si 2 filas pueden valer a la vez (reglas ambiguas), cuántas preguntas hacen falta para saber la fila, y si la pista de audio cambia la decisión como dice el diseño.
- **Los textos:** si las variantes (`variant_keys`) y los señuelos se confunden con las características de otra criatura, y si la voz es la de un amigo chileno que escribe rápido y con miedo.

Juzga también:

- **El folclore:** si cada criatura es fiel a cómo se cuenta en Chile (puedes buscar fuentes en la web y citarlas en el informe).
- **Las reacciones:** si las reacciones genéricas se pueden reemplazar por 3 propias de cada criatura (acierto, calavera y error; A6 de `docs/22`).

Las criaturas son un borrador de Claude (decisión del 4 de noviembre), así que puedes **aplicar** los cambios a los datos como borradores nuevos, con las pruebas en verde. Ninguno cambia la estructura: siguen 4 acciones, reglas en tabla, ✓ y calavera. Cada texto nuevo o cambiado va a la lista de Benja (regla 8). Si una mejora pide cambiar algo del sistema, por ejemplo una regla que mire la hora, es una idea para F8: anótala y no la implementes.

### Skills

| Skill | Para qué |
| --- | --- |
| `godot:godot-resources` | Leer y escribir los `.tres` de las criaturas sin romperlos. |
| `disciplines:level-design` | Pensar cada criatura como un encuentro: qué aprende el jugador y en qué noche. |
| `superpowers:brainstorming` | Si un cambio necesita a Benja (por ejemplo, quitarle una característica a una criatura), una pregunta a la vez, con opciones y una recomendada. |
| `superpowers:verification-before-completion` | Las pruebas, `test_balance` y una captura del cuaderno con una criatura cambiada. |

### Entregables

- `docs/NN_revision_criaturas.md`, con el siguiente número libre de `docs/`: una tabla por criatura con lo medido, los problemas, lo que cambiaste y lo que queda para Benja. Al final, la lista de textos nuevos con sus claves y su archivo.
- El script de análisis, para volver a medir cuando Benja corrija.

### Terminado cuando

Cada criatura se distingue preguntando y no tiene filas ambiguas, o el informe explica por qué no. Las pruebas pasan, y Benja tiene una lista corta y clara de lo que debe corregir.

---

## F3 · La historia: borradores de las noches 3 a 5 y su versión mínima

**Esfuerzo:** high. **Tipo:** diseño narrativo y textos, sin código. **Cuándo:** después de que Benja pruebe la noche 1 con su historia (`docs/04`, X y AA). Puede ir junto a S21m (la noche 2).

### Tu tarea

`docs/21_lore_por_noche.md` tiene la noche 1 aprobada e implementada, la 2 escrita y esperando a Benja, y las 3 a 5 solo como esquema (§6), con sus "Por decidir". El contenido se congela el 25 de noviembre. Escribe los borradores completos de las noches 3 a 5, listos para que Benja los corrija, y su **versión mínima** (la intro y el cierre del vlog en la llamada, sin decisiones; `docs/05`, 10ter), por si no alcanza la completa.

- Primero cierra con Benja los "Por decidir" de §6, de a una pregunta, con opciones y una recomendada: quién cae en la trampa y cómo salen, qué hace León en la noche 4 sin falsear pistas, si el Imbunche pasa de la 4 a la 5, y cómo funciona su opción letal.
- **La regla 9 manda.** La historia usa solo mecánicas que existen (separarse, quedar inconsciente, desaparecer sin señal, un accidente o una decisión con forma de accidente). Nunca agrega otra forma de perder, nunca mata a un amigo y nunca cambia qué criatura llega ni qué acción es correcta. La opción letal del Imbunche cambia una regla de la criatura, no la historia: márcalo como una decisión de Benja.
- Escribe como los guiones de la noche 1: el formato de `data/story/night_1.tres` y `STORY_N1_*` en `messages.csv`. Respeta lo que dura cada momento (`StoryRunner.line_seconds()`, 5 palabras por segundo y 0,5 s) para que las calmas de cada noche alcancen; las calmas están en `data/nights/*/night_*.tres`.
- La voz es la de 3 amigos chilenos que graban un vlog (Acá Penan): mensajes cortos, en primera persona, con humor y miedo. Lee los textos aprobados de la noche 1 para el tono.
- Los guiones se trabajan en el documento compartido que enlaza `docs/21` (usa la herramienta Artifact: léelo con `read` y publica sobre la misma URL). Lee la versión viva antes de cambiarla, porque Benja la edita.

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:brainstorming` | Las decisiones de §6 con Benja, una a la vez. |
| `disciplines:dialogue-systems` | Las decisiones con forma de accidente y cómo se ramifican sin cambiar la noche. |
| `disciplines:level-design` | La curva de tensión de cada noche: qué cuenta la historia en cada calma. |

### Terminado cuando

Las noches 3 a 5 tienen su borrador completo y su versión mínima en el documento compartido, `docs/21` §6 está al día con lo que decidió Benja, y la siguiente sesión puede implementarlas sin volver a preguntar lo de §6.

---

## F4 · Sensación y legibilidad: el Plan 10

**Esfuerzo:** high. **Tipo:** plan y ejecución (reemplaza a S23 y S24). **Cuándo:** del 30 de noviembre al 5 de diciembre, con lo que salga de S22.

### Tu tarea

El juego funciona, pero lo que pasa se lee más de lo que se siente. Escribe el Plan 10 (sonido y pulido) y ejecútalo. El objetivo es que cada cosa importante se **sienta** sin agregar mecánicas:

- **El daño se oye** (C1 de `docs/22`): el mensaje se corta a mitad de palabra, suena una ráfaga de estática y la entrada del PC se apaga un momento. Solo después llega el aviso rojo.
- **El amigo está escribiendo:** un "escribiendo…" breve antes de sus respuestas, sin alargar las esperas que mide el equilibrio (o con `test_balance` en verde).
- **Acertar y equivocarse se notan,** además de los 2 sonidos de S21p: una reacción en el chat, en la entrada y en los diales, que no tape la lectura.
- **Los sonidos que faltan:** `sonidos_pendiente.md`, "Faltan": la llegada y la recepción de un video, los clics, el ambiente del menú y las pantallas finales. Se generan con `tools/make_sounds.py`, con las reglas de sonido de `CLAUDE.md`.
- **Legibilidad:** revisa con capturas a 1280×720 y a 1080p el chat (también con la ventana maximizada), el cuaderno, el celular, el mixer, las opciones, la pantalla final con la nota y las tarjetas de la noche 0. Mira las imágenes tú mismo y corrige lo que no se lee o se ve roto. Los pendientes "Menor" de la sesión 21o son una buena lista de partida.

Antes de escribir el plan, lee lo que dijeron los testers en S22 (la entrada de S22 en `resumen.md`) y dale prioridad a lo que ellos notaron. C3 (las herramientas mienten con poca Sanity) es una mecánica nueva: va al informe para F8, no al plan.

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:writing-plans` | `docs/NN_plan_sonido_pulido.md` (Plan 10), con tareas chicas. |
| `superpowers:executing-plans` y `superpowers:test-driven-development` | Ejecutarlo con pruebas. |
| `disciplines:game-feel` | La reacción al daño, al acierto y al error, sin exagerar en un juego de escritorio. |
| `disciplines:audio-design` | Los sonidos nuevos, su volumen y cómo se mezclan con la música. |
| `disciplines:game-ui-ux` | La revisión de legibilidad. |
| `godot:godot-animation` y `godot:godot-shaders` | Los cortes, la estática y el apagón de la entrada. |
| `superpowers:verification-before-completion` | Capturas revisadas y pruebas en verde. |

### Terminado cuando

El plan está ejecutado, las capturas están revisadas a las 2 resoluciones, `test_balance` sigue en verde y `docs/04` tiene una sección para que Benja escuche y pruebe lo nuevo.

---

## F5 · La versión publicable (web y Windows)

**Esfuerzo:** high. **Tipo:** código, exportación e instrucciones para Benja. Se puede hacer en 2 partes: **F5a** antes del 22 de noviembre, solo si los testers juegan en itch.io, y **F5b** del 3 al 6 de diciembre.

### Tu tarea

Deja el juego listo para publicar. Lo que falta, según el audit:

- **Créditos:** una pantalla desde el menú con Benja, Claude, la fuente Departure Mono (OFL, que además obliga a incluir `OFL.txt` con el juego), las 5 grabaciones (`audio/source/creditos.md`), la música de Benja y las fotos de Snapgram (pregúntale a Benja de dónde salen si no está anotado).
- **Pantalla completa:** en Opciones y con F11, guardada en la configuración. La letra nítida (`PixelTextSizer`) tiene que seguir funcionando al cambiar.
- **Guardados seguros:** `save_game.gd`, `game_progress.gd` y `game_settings.gd` escriben directo sobre el archivo. Que escriban a un archivo temporal y lo renombren, y que un archivo dañado no rompa el menú ni borre el progreso de otro archivo.
- **La web:** que el audio empiece tras el primer clic (los navegadores lo bloquean antes), que el guardado persista en el navegador, que la descarga inicial no sea enorme (por ejemplo, los WAV largos como Ogg) y que el rendimiento alcance en GL Compatibility. Los cambios de Benja para la web (`main_menu.gd`, `export_presets.cfg`) están sin commitear: pregúntale antes de tocarlos.
- **Lo que se exporta:** que los presets dejen fuera `test/`, `tools/`, `docs/`, `art/_layout/` y `art/phone/source/`, y que incluyan `OFL.txt`.
- **La limpieza conocida:** el ambiente que queda sonando al cerrar el escritorio, `END_TUTORIAL*` sin usar y los botones que no hacen nada con el escritorio suelto (F6).
- **Un número de versión** visible en el menú.

Lo que tiene que hacer Benja en Godot o en itch.io va a `docs/04` con la regla 2 (la sección Z ya tiene una parte).

### Skills

| Skill | Para qué |
| --- | --- |
| `godot:godot-export` | Los presets, la exportación sin pantalla y la web sin cabeceras especiales. |
| `disciplines:save-systems` | La escritura segura y qué pasa con un archivo dañado. |
| `disciplines:performance-optimization` | Medir el peso y los cuadros por segundo en la web antes de optimizar. |
| `godot:godot-ui-control` | La pantalla de créditos y la opción de pantalla completa. |
| `run` | Abrir el juego exportado y comprobar que arranca. |
| `superpowers:verification-before-completion` | Exportar de verdad y probar la versión exportada, no solo el proyecto. |

### Terminado cuando

Hay una versión web y un `.exe` exportados en `C:\dev\builds\`, que arrancan, suenan, guardan y muestran los créditos. Las pruebas pasan, y `docs/04` dice exactamente qué subir a itch.io.

---

## F6 · El juego en inglés

**Esfuerzo:** high. **Tipo:** traducción y código chico. **Cuándo:** del 1 al 8 de diciembre, después de que Benja corrigió los textos (el contenido se congela el 25). Es la prioridad 2 de `docs/05`: si no alcanza, no entra.

### Tu tarea

Traduce al inglés los 546 textos de `data/text/*.csv` (columna `en`) y deja una opción de idioma en Opciones.

- Primero acuerda con Benja un **glosario corto**: si las criaturas conservan su nombre en español (recomendado: sí, con artículo en inglés o sin él), cómo suena "Mati", qué se hace con los chilenismos (wn, cachai, la cagó) y el nombre del canal (Acá Penan).
- La voz de los amigos importa más que la literalidad: mensajes cortos, en primera persona, con el mismo humor y el mismo miedo. Las frases clickeables entre asteriscos y las variantes tienen que seguir funcionando como pistas. Una variante no puede delatar a otra criatura en inglés aunque no lo haga en español.
- El largo importa: revisa con capturas que nada se salga del chat, el cuaderno, las tarjetas y los menús a 1280×720. Si un texto no cabe, acórtalo en inglés; no cambies la interfaz.
- Registra los `.en.translation` (pendiente de S21o) y guarda el idioma en la configuración.
- Lo que Benja tiene que revisar va a una lista, como con los textos en español (regla 8).

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:brainstorming` | El glosario, una decisión a la vez. |
| `godot:godot-ui-control` | La opción de idioma y el cambio de idioma sin reiniciar. |
| `superpowers:verification-before-completion` | `ContentValidator` y las capturas en inglés. |

### Terminado cuando

Todos los textos tienen inglés, el validador pasa con los 2 idiomas, las capturas en inglés no tienen texto cortado y el glosario quedó en `docs/`.

---

## F7 · Ordenar `RequestManager` y `ChatPanel` (después de la entrega)

**Esfuerzo:** xhigh. **Tipo:** reestructuración con pruebas. **Cuándo:** después del 10 de diciembre, o antes si F1 encontró errores que vienen de cómo está mezclado el código. Va en una rama aparte.

### Tu tarea

Eres responsable del código de este juego a largo plazo, y su diseño interno depende de ti. `scripts/desk/request_manager.gd` (962 líneas, 72 funciones) lleva las consultas, los accidentes, los chats guionados, la llamada grupal, la historia y el tutorial. `scripts/ui/chat_panel.gd` (1075 líneas) mezcla la vista, la llamada, el tutorial y las descargas. Sepáralos en piezas con una responsabilidad cada una (convención de `CLAUDE.md`), sin cambiar nada de lo que ve el jugador.

- **El comportamiento no cambia.** Las 872 pruebas (o las que haya) y la prueba al azar de F1 son la red: tienen que pasar igual antes y después de cada paso.
- Si una prueba depende de la estructura interna y no del comportamiento, cámbiala, y explica por qué en el commit.
- Hazlo en pasos chicos, cada uno con su commit, en una rama (`superpowers:using-git-worktrees`). Antes de unirla a `main`, pregúntale a Benja.
- Actualiza "Entorno técnico" en `CLAUDE.md`, que nombra muchas de estas funciones.

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:using-git-worktrees` | Trabajar aislado de `main`. |
| `superpowers:writing-plans` | El orden de las extracciones antes de empezar. |
| `godot:godot-nodes-scenes` y `godot:godot-signals-groups` | Cómo se comunican las piezas nuevas. |
| `simplify` y `code-review` (high) | Revisar cada paso. |
| `superpowers:finishing-a-development-branch` | Cerrar la rama. |

### Terminado cuando

Ningún archivo de la noche pasa de unas 400 líneas o, si alguno pasa, el informe explica por qué. Todas las pruebas y la prueba al azar pasan, y Benja aprobó la unión.

---

## F8 · Diseñar la versión siguiente (después de la entrega)

**Esfuerzo:** high. **Tipo:** diseño con Benja, sin código. **Cuándo:** después del 10 de diciembre, o durante S22 si los testers dicen que el juego es plano o repetitivo.

### Tu tarea

`docs/22` dejó sin discutir las propuestas que dan profundidad: B1 a B5 (reglas que miran la hora, al amigo o el cuarto; reglas de la casa; la situación que cambia a mitad de la consulta; el riesgo que propone el amigo), C2 (el impostor), C3 (las herramientas mienten con poca Sanity), C4 y D1 a D3. F2 y F4 pueden haber sumado ideas. Con lo que dijeron los testers (S22), ayuda a Benja a elegir qué entra en la versión siguiente.

- Ordena las ideas por cuánto cambian la experiencia contra lo que cuestan, y por si chocan con una decisión de `CLAUDE.md`. Cada choque se dice.
- Haz las preguntas de a una, con opciones y una recomendada. Benja decide.
- No escribas código. El resultado es un documento de diseño y, si Benja lo pide, el prompt de la sesión que lo planifica.

### Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:brainstorming` | Toda la sesión. |
| `disciplines:level-design` y `disciplines:game-ai` | La progresión por noche y el impostor. |
| `disciplines:game-feel` | Que las ideas nuevas se sientan, no solo se lean. |

### Terminado cuando

Hay un documento de diseño con lo que Benja eligió, lo que descartó y por qué, y `docs/05` está al día.
