# Audit para Fable 5.2: qué le falta al juego y qué sesiones lo resuelven (S21q)

**Escaneo de Claude (Opus 5.5), 16 de noviembre de 2026.** Benja pidió identificar dónde puede mejorar el juego o dónde le falta desarrollo, para dárselo a Fable 5.2, el modelo más potente, y separarlo en sesiones. **Nada de esto está decidido.** Cada propuesta que agrega alcance o cambia una decisión de `CLAUDE.md` lo dice. Los prompts de las sesiones están en `docs/35_prompts_fable.md`.

Se revisaron `docs/00_log.md`, la última entrada de `resumen.md` con sus pendientes, `docs/05`, `docs/21`, `docs/22`, `arte_pendiente.md`, `sonidos_pendiente.md`, la sección Z de `docs/04`, los guardados, los textos y los scripts más grandes. Claude no jugó el juego ni oyó los sonidos.

## 1. En pocas líneas

1. **El juego está completo como sistema, pero nadie ha probado sus estados cruzados.** Hay 872 pruebas, y todas miran una pieza a la vez o el modelo de "jugar bien". Desde el Plan 9.9, la noche termina solo cuando todo se resolvió: si algo queda abierto para siempre, la noche no termina nunca. Es el riesgo más grande antes de probar con personas (23 de noviembre).
2. **El contenido es el cuello de botella.** Las 7 criaturas son un borrador de Claude que nadie ha medido como puzzle. La historia tiene la noche 1; la 2 espera la aprobación de Benja, y las 3 a 5 son un esquema. El contenido se congela el 25 de noviembre.
3. **Falta lo que hace publicable un juego:** no hay pantalla de créditos (la licencia de la fuente la pide), ni opción de pantalla completa. Los guardados se escriben sin protección y la versión web no se ha probado. Hay 0 de 546 textos en inglés.
4. **Lo que pasa todavía se lee más de lo que se siente.** El daño, el acierto y el error son sobre todo texto. El punto C1 de `docs/22` (el daño se oye) y el "escribiendo…" siguen pendientes.
5. **El código tiene 2 archivos que hacen demasiado.** `request_manager.gd` (962 líneas) lleva las consultas, los accidentes, los chats guionados, la llamada, la historia y el tutorial. `chat_panel.gd` tiene 1075 líneas. Cada sesión nueva los hace crecer.
6. **La profundidad de diseño quedó sin explorar.** Las secciones B a D de `docs/22` (reglas que miran el cuarto, la situación que cambia, el impostor) no se discutieron. Agregarlas va contra la regla 6 antes de la v1, así que van después de la entrega, salvo que las pruebas digan otra cosa.

## 2. Hallazgos por área

| # | Área | Qué falta o se puede mejorar | Evidencia | Impacto | ¿Agrega alcance? | Sesión |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Robustez | Ninguna prueba juega la escena real con entradas al azar. Hay que probar combinaciones como un amigo aturdido con una decisión abierta, un video atrasado al final, la llamada que espera una línea, la pausa durante Audio Sync o Esc en el tutorial. | `RequestManager.night_complete()` exige que el director esté en DONE, que no quede nada abierto, que los videos estén resueltos y que la historia haya terminado, y no tiene tope de tiempo. | Alto: una noche que no termina arruina una prueba con personas. | No | F1 |
| 2 | Robustez | Los guardados se escriben directo sobre el archivo, sin un archivo temporal. Un corte a mitad de la escritura puede borrar el progreso (Difícil y Extremo desbloqueados). | `save_game.gd:47`, `game_progress.gd:28`, `game_settings.gd:50` | Medio | No | F5 |
| 3 | Contenido | Nadie ha medido si las reglas de las 7 criaturas son buenos puzzles: cuántas preguntas hacen falta para decidir, qué filas se confunden, si 2 criaturas que comparten características se distinguen y si el folclore es fiel. `ContentValidator` revisa la forma, no la calidad. | `data/entities/*.tres`, `notebook.csv`, `content_validator.gd` | Alto: es el corazón del juego, y se congela el 25. | No | F2 |
| 4 | Contenido | Las reacciones son genéricas (A6 de `docs/22`): acertar contra el Tue Tué suena igual que contra el Cuero. | `docs/22` §3 A6 | Medio | No (son textos) | F2 |
| 5 | Historia | Faltan los guiones de las noches 3 a 5, con sus "Por decidir": quién cae en la trampa, qué hace León sin que lo noten, la opción letal del Imbunche. Si no alcanzan, falta también su versión mínima (la intro y el cierre del vlog). | `docs/21` §6, `docs/05` 10ter | Alto para la historia; el mínimo salva la entrega. | No (está en la v1) | F3 |
| 6 | Sensación | El daño es una línea roja. No hay "escribiendo…" antes de que conteste un amigo. Faltan sonidos: la llegada de un video, los clics del menú, las pantallas finales y el ambiente del menú. | `docs/22` C1; `sonidos_pendiente.md`, "Faltan" | Alto en el terror | No (es presentación de lo que existe) | F4 |
| 7 | Legibilidad | Varias pantallas no se han revisado en una captura a 1080p: la ayuda de las barritas, la conversación con la ventana maximizada y el panel de opciones con el tema del chat. | Pendientes de S21o, "Menor" | Medio | No | F4 |
| 8 | Publicación | No hay pantalla de créditos. La fuente (OFL), las 5 grabaciones y las fotos de Snapgram necesitan sus créditos, y la OFL obliga a incluir su licencia. | No hay ningún `CREDITS` en `scripts/`, `scenes/` ni `data/text/` | Alto (licencias) | No | F5 |
| 9 | Publicación | No hay pantalla completa (ni en Opciones ni con F11). La versión web no se ha probado: el audio que espera el primer clic, el guardado en el navegador, el peso de los WAV y el rendimiento. Los presets podrían exportar `test/`, `tools/` y `docs/`. | Pendientes de S21o; `export_presets.cfg` sin commitear; `docs/04` Z | Alto si los testers juegan en la web | No | F5 |
| 10 | Publicación | Hay restos conocidos: el ambiente que queda sonando al cerrar el escritorio, `END_TUTORIAL*` sin usar, y el escritorio suelto (F6) con botones que no hacen nada. | Pendientes de S21o, "Menor" | Bajo | No | F5 |
| 11 | Idioma | Hay 0 de 546 textos en inglés (messages 254, notebook 115, ui 173 y phone 4) y no hay opción de idioma. Es la prioridad 2 de `docs/05`. | Columna `en` vacía en los 4 CSV | Medio (prioridad 2) | No (está en `docs/05`) | F6 |
| 12 | Código | `RequestManager` tiene 6 responsabilidades y 72 funciones; `ChatPanel`, 66. Cada noche de historia les suma casos. | `scripts/desk/request_manager.gd`, `scripts/ui/chat_panel.gd` | Medio ahora y alto si el juego sigue después | No | F7 |
| 13 | Diseño | No se discutió B1 a B5 (reglas con la hora o el cuarto, reglas de la casa, la situación que cambia, el riesgo que propone el amigo), C2 (el impostor), C3 (las herramientas mienten) ni D1 a D3. | `docs/22` §3 | Alto a largo plazo | **Sí** | F8 |
| 14 | Instrucciones | `CLAUDE.md` pesa 55 KB y tiene 93 decisiones, muchas reemplazadas ("Desde el 11-nov…"). Fable sigue las instrucciones al pie de la letra, y las reglas viejas le cuestan contexto y atención. | `CLAUDE.md`, "Decisiones tomadas" | Medio en todas las sesiones | No | F0 |

**Lo que no es para Fable:** el arte (es de Benja y está en `arte_pendiente.md`), oír los sonidos, sentir si una noche es justa y los pasos en la interfaz de Godot. Tampoco los ajustes chicos de datos, como una calma o un tiempo, que Sonnet hace igual de bien y más barato.

## 3. Por qué estas sesiones son para Fable

Fable 5.2 rinde más que Opus 5.5 en trabajo largo y sin supervisión, en razonar entre muchos archivos y en escribir. Por token cuesta el doble que Opus 5.5. Conviene usarlo donde esa diferencia se nota:

- **Encontrar errores entre sistemas** (F1 y F7): hay que tener en la cabeza el director, la historia, los videos y el chat a la vez.
- **Juzgar contenido** (F2 y F3): puzzles, folclore chileno y la voz de 3 amigos.
- **Revisar capturas** (F4): Fable puede mirar las imágenes de los scripts de captura y decir qué no se lee.
- **Traducir con tono** (F6): modismos chilenos, chistes y nombres de criaturas que no se traducen.

Las sesiones que solo ejecutan un plan ya escrito siguen en Sonnet 5.5, como dice el registro.

## 4. Las sesiones, en orden

El calendario manda: las pruebas con personas son del 23 al 29 de noviembre, el contenido se congela el 25 y la entrega es el 10 de diciembre. Lo que más limita es **el tiempo de Benja** para leer y corregir, así que F2 y F3 se hacen antes, para que alcance a revisarlos.

| Sesión | Qué | Cuándo | Esfuerzo | Necesita de Benja |
| --- | --- | --- | --- | --- |
| F0 (opcional) | `CLAUDE.md` más liviano, con las decisiones reemplazadas archivadas | Cuando quiera, mejor antes de F1 | medium | Aprobar el cambio |
| **F1** | Caza de errores: la noche que no termina y los estados cruzados, con una prueba que juega al azar | **17 a 21 de noviembre**, antes de las pruebas | **xhigh** | Commitear S21p antes; autorizar los commits |
| **F2** | Las 7 criaturas como puzzles, y reacciones propias | **17 a 21 de noviembre**, antes del congelamiento | high | Corregir los textos antes del 25 |
| F5a | La versión para los testers: web, créditos, pantalla completa y guardados | 18 a 22 de noviembre, **solo si los testers juegan en itch.io**; si no, todo va en F5b | high | Subir a itch.io (`docs/04`, Z) |
| F3 | La historia: borradores de las noches 3 a 5 y su versión mínima | 18 a 22 de noviembre, cuando Benja haya probado la noche 1 (puede ir junto a S21m) | high | Contestar los "Por decidir"; corregir los guiones |
| F4 | Sensación y legibilidad: Fable escribe y ejecuta el **Plan 10** (reemplaza a S23 y S24) | 30 de noviembre a 5 de diciembre, con lo que salga de S22 | high | Escuchar y aprobar |
| F5b | La versión candidata: lo que no entró en F5a, más la limpieza | 3 a 6 de diciembre | high | Probar el `.exe` y la web |
| F6 | El juego en inglés | 1 a 8 de diciembre, si alcanza (prioridad 2) | high | Elegir el glosario |
| F7 | Ordenar `RequestManager` y `ChatPanel` | Después del 10 de diciembre, o antes si F1 encuentra errores que vienen de cómo están mezclados | xhigh | Autorizar la rama |
| F8 | Diseñar la versión siguiente: profundidad con `docs/22` B a D | Después del 10 de diciembre, o en S22 si los testers dicen que es plano | high | Decidir |

**Mínimo recomendado:** F1 y F2. Son las que más protegen la prueba con personas y el congelamiento. **S22** (las correcciones tras las pruebas) también le conviene a Fable, porque pide juicio con información incompleta; se abre con el prompt de siempre del registro.

## 5. Cómo abrir una sesión de Fable

1. En Claude Code, elige **Fable 5.2** y el esfuerzo de la tabla con `/model`. El esfuerzo por defecto es **high**. **xhigh** solo vale en F1 y F7, que son largas y difíciles. **max** no conviene: gasta mucho más y casi no mejora.
2. Escribe lo que dice cada sesión en `docs/35_prompts_fable.md`, por ejemplo `Lee docs/35_prompts_fable.md y haz la sesión F1.`
3. Fable trabaja mucho rato sin hablar. Es normal: deja la sesión corriendo y vuelve por el resultado.

## 6. Lo que este audit no puede decir

- Si una noche es divertida. Eso lo dicen tus pruebas y las de S22.
- Si hay errores de verdad en los estados cruzados. F1 los busca; aquí solo se ve que nada los prueba.
- Si las reglas de las criaturas son malas. F2 las mide; hoy nadie lo ha hecho.
