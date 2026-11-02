# Registro de sesiones

**Léelo primero.** Dice qué sesión toca ahora, con qué modelo y nivel de esfuerzo, y qué documento se usa.

Estados: ✅ completada · ▶ siguiente · ⏳ pendiente · ✏️ modificada · ❌ cancelada

---

## ▶ Siguiente sesión: S17 — Ejecutar el Plan 7 (screamers y director)

| | |
| --- | --- |
| **Qué se hace** | Ejecutar `docs/14_plan_screamers_director.md`: 14 tareas, de 326 a 373 pruebas. Al terminar, las solicitudes llegan en olas, hay screamers justos y alucinaciones, y en la noche 1 el susto guionado y el chat de Gonzalo enseñan el celular. |
| **Tipo** | Ejecutar un plan. |
| **Modelo** | **Sonnet 5.5** |
| **Esfuerzo** | **high** |
| **Antes de empezar** | Cierra Godot (el plan importa). Lo ideal es que hayas probado el mantenimiento (`docs/04`, J), pero no es necesario. |
| **Qué escribirle a Claude** | "Ejecuta el Plan 7 (docs/14) con superpowers:executing-plans" |
| **Tu parte** | Autorizar los commits (de a uno o todos al empezar). Después, probar los screamers y el director (`docs/04`, K, unos 20 minutos). |
| **Está terminada cuando** | Las 373 pruebas pasan, las capturas están revisadas y S18 es la siguiente. |

---

## Qué documentos son planes de sesión

Solo se ejecutan los documentos `docs/NN_plan_*.md` que **no** son hojas de ruta. Hoy hay **uno pendiente**: el Plan 7 (`docs/14`), que se ejecuta en S17.

| Documento | Qué es | ¿Se ejecuta? |
| --- | --- | --- |
| `docs/00_log.md` | Este registro: qué sesión toca | — |
| `docs/14_plan_screamers_director.md` | **Plan 7**, paso a paso, con código | **Sí, en S17** ▶ |
| `docs/13_plan_mantenimiento.md` | **Plan 6**, paso a paso, con código | Ya ejecutado (S15) ✅ |
| `docs/12_plan_consecuencias_noche.md` | **Plan 5**, paso a paso, con código | Ya ejecutado (S13) ✅ |
| `docs/11_plan_cuaderno.md` | **Plan 4**, paso a paso, con código | Ya ejecutado (S11) ✅ |
| `docs/10_plan_solicitudes_chat.md` | **Plan 3**, paso a paso, con código | Ya ejecutado (S9) ✅ |
| `docs/09_propuesta_entidades.md` | Borrador de 3 entidades para que Benja las refine | No (referencia para Benja) |
| `docs/08_plan_datos_textos.md` | **Plan 2**, paso a paso, con código | Ya ejecutado (S7) ✅ |
| `docs/07_plan_escena_arte.md` | **Plan 1**, paso a paso, con código | Ya ejecutado (S5) ✅ |
| `docs/06_plan_v1.md` | Hoja de ruta: los 9 planes de la v1 y el estado del arte | No; de aquí salen los planes 2 a 9 |
| `docs/05_plan_produccion.md` | Alcance por prioridad y calendario por semana | No |
| `docs/02_bucle_central.md` | Detalle de la mecánica central y plantilla de entidades | No (referencia) |
| `docs/03_plan_arte.md` | Reglas del pipeline de arte y arte faltante | No (referencia) |
| `docs/04_instrucciones_godot.md` | Lo que tú haces en Godot | Tú, cuando haya pasos pendientes |
| `docs/01_analisis_diseno.md` | Análisis de la sesión 1 | No (histórico) |
| `spook_dial_design.md` | Qué es el juego (diseño v2) | No (referencia principal) |
| `resumen.md` | Detalle de cada sesión: hecho, errores y pendientes | No |

---

## Secuencia de sesiones

Hay dos tipos de sesión, que se alternan:

- **Escribir un plan:** decisiones técnicas. Usa Opus 5.5 y produce un `docs/NN_plan_*.md` con código.
- **Ejecutar un plan:** seguir un plan ya escrito. Usa Sonnet 5.5, más rápido y barato, que basta porque el código está en el plan.

| # | Fecha objetivo | Sesión | Tipo | Modelo · esfuerzo | Necesita de ti | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | 15-oct | Planificación inicial y análisis del diseño | Diseño | Opus 5.5 · max | — | ✅ |
| S2 | 15-oct | Decisiones, diseño v2 y alcance | Diseño | Opus 5.5 · high | — | ✅ |
| S3 | 26-oct | Diseño cerrado, revisión del arte y Plan 1 escrito | Diseño y plan | Opus 5.5 · high | — | ✅ |
| S4 | 26-oct | Orden del arte, repositorio y este registro | Mantenimiento | Opus 5.5 · low | — | ✅ |
| S5 | 26 oct | Ejecutar el Plan 1: escena y arte | Ejecución | Opus 5.5 (se adelantó) | Revisión visual y escalado | ✅ |
| S6 | 26 oct | Escribir el Plan 2: datos y textos | Plan | Opus 5.5 · high | — | ✅ |
| S7 | 26 oct | Ejecutar el Plan 2 | Ejecución | Opus 5.5 (se adelantó) | Revisar el Inspector (`docs/04`, F) | ✅ |
| S8 | 26 oct | Escribir el Plan 3: solicitudes y chat | Plan | Opus 5.5 (se adelantó) | Decisiones del chat | ✅ |
| S9 | 30 oct | Ejecutar el Plan 3 | Ejecución | Opus 5.5 · max (en vez de Sonnet) | Autorizar commits; probar (`docs/04`, G) | ✅ |
| S10 | 30–31 oct | Escribir el Plan 4: cuaderno | Plan | Opus 5.5 · max (se adelantó) | Decisiones del cuaderno | ✅ |
| S11 | 31 oct | Ejecutar el Plan 4 → el bucle central se juega | Ejecución | Opus 5.5 (se adelantó; en vez de Sonnet) | Autorizar commits; probar (`docs/04`, H) | ✅ |
| S12 | 31 oct | Escribir el Plan 5: consecuencias, medidores y noche | Plan | Opus 5.5 · high (se adelantó) | Decisiones de las consecuencias | ✅ |
| S13 | 31 oct | Ejecutar el Plan 5 → una noche se gana o se pierde | Ejecución | Opus 5.5 · max (se adelantó; en vez de Sonnet) | Autorizar commits; probar (`docs/04`, I) | ✅ |
| S14 | 31 oct – 2 nov | Escribir el Plan 6: mantenimiento | Plan | Opus 5.5 (se adelantó) | Decisiones del mantenimiento | ✅ |
| S15 | 2 nov | Ejecutar el Plan 6 → una noche completa | Ejecución | Opus 5.5 (se adelantó; en vez de Sonnet) | Autorizar commits; probar (`docs/04`, J) | ✅ |
| S16 | 2 nov | Escribir el Plan 7: screamers y director | Plan | Opus 5.5 · high (se adelantó) | Decisiones de los screamers y del ritmo | ✅ |
| **S17** | 17–19 nov | **Ejecutar el Plan 7 → una noche con ritmo y screamers justos** | Ejecución | **Sonnet 5.5 · high** | Autorizar commits; probar (`docs/04`, K) | ▶ |
| S18 | 19 nov | Escribir el Plan 8: noches (con la noche 0, el tutorial), menú, guardado y opciones | Plan | Opus 5.5 · high | **Las 7 entidades** y qué enseña la noche 0 | ⏳ |
| S19 | 20–22 nov | Ejecutar el Plan 8 → **el juego se puede terminar** | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S20 | 23–29 nov | Correcciones tras las pruebas con personas (contenido congelado el 25) | Corrección | Opus 5.5 · high | Pruebas con 3 a 5 personas | ⏳ |
| S21 | 30 nov | Escribir el Plan 9: sonido, pulido y versión | Plan | Opus 5.5 · high | Sonidos elegidos | ⏳ |
| S22 | 1–5 dic | Ejecutar el Plan 9 → versión candidata | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S23 | 6–10 dic | Correcciones finales y entrega | Corrección | Opus 5.5 · high | — | ⏳ |

**Si una sesión de ejecución no termina su plan**, la siguiente sesión la continúa (se anota como ✏️) antes de pasar a la que sigue en la tabla.

---

## Cambios a la secuencia

| Fecha | Cambio |
| --- | --- |
| 2-nov | ✏️ S16 se adelantó al 2 de noviembre (fecha objetivo: 16 de noviembre), justo después de S15, y se escribió en Opus 5.5 con esfuerzo high. Benja tomó 6 decisiones de los screamers y del ritmo: olas con respiro, screamers en cualquier momento, alucinaciones del cuarto y del juego, la figura de la ventana escondida, la noche 0 (tutorial) y el chat guionado que sigue al susto (detalle en `resumen.md`, Sesión 16). La noche 0 se diseña en el Plan 8 (S18). |
| 2-nov | ✏️ S15 se adelantó al 2 de noviembre (fecha objetivo: 13 a 15 de noviembre), justo después de S14, y se ejecutó inline con `superpowers:executing-plans` en Opus 5.5 (el registro proponía Sonnet 5.5 · high). El plan se aplicó tal como está escrito; solo se agregó una línea en blanco que faltaba entre dos funciones de `test/test_balance.gd`. |
| 2-nov | ✏️ S14 se adelantó: empezó el 31 de octubre (fecha objetivo: 12 de noviembre), justo después de S13, y terminó el 2 de noviembre. Se escribió en Opus 5.5. Benja tomó 5 decisiones del mantenimiento: Audio Sync en el mixer visto desde arriba, el botón «Sincronizar» del chat, los videos que se descargan en el chat, las reglas de un amigo sin señal y el celular provisional (detalle en `resumen.md`, Sesión 14). La sesión se cortó una vez por falta de créditos, sin pérdidas. |
| 31-oct | ✏️ S13 se adelantó al 31 de octubre (fecha objetivo: 10 a 12 de noviembre) y se ejecutó inline con `superpowers:executing-plans` en Opus 5.5 con esfuerzo max (el registro proponía Sonnet 5.5 · high). El plan se aplicó tal como está escrito, sin correcciones. |
| 31-oct | ✏️ S12 siguió con las notas de prueba de Benja: el chat con estilo de terminal y los textos reales quedaron aplicados al juego, y el aviso de daño entró al Plan 5, que pasó a 13 tareas (de 185 a 251 pruebas) y se volvió a validar. La sesión se cortó una vez por falta de créditos, sin pérdidas (detalle en `resumen.md`, Sesión 12, continuación). |
| 31-oct | ✏️ S12 se adelantó al 31 de octubre (fecha objetivo: 9 de noviembre), justo después de S11, y se escribió en Opus 5.5 con esfuerzo high. Benja tomó 3 decisiones de las consecuencias y los medidores (detalle en `resumen.md`, Sesión 12). |
| 31-oct | ✏️ S11 se adelantó al 31 de octubre (fecha objetivo: 1 a 8 de noviembre) y se ejecutó inline con `superpowers:executing-plans` en Opus 5.5 (el registro proponía Sonnet 5.5). El plan se aplicó tal como está escrito, sin correcciones. |
| 31-oct | ✏️ S10 se adelantó al 30 y 31 de octubre (fecha objetivo: 6 de noviembre), justo después de S9, y se escribió en Opus 5.5 con esfuerzo max. Benja decidió que el cuaderno va a la derecha y es independiente del chat (detalle en `resumen.md`, Sesión 10). La sesión se interrumpió una vez, sin pérdidas. |
| 30-oct | ✏️ S9 se ejecutó inline con `superpowers:executing-plans` en Opus 5.5 (el registro proponía Sonnet 5.5), primero en esfuerzo xhigh y después en max. El plan se aplicó tal como está escrito, sin correcciones. |
| 26-oct | ✏️ S8 se adelantó al 26-oct sin las entidades refinadas: Benja pidió ejecutar el Plan 3, que no estaba escrito, y eligió escribirlo. El plan usa El Trauco y entidades de prueba; El Tue Tué y La Calchona entran como datos cuando estén. |
| 26-oct | ✏️ `docs/09` es la propuesta de entidades de Claude, así que el Plan 3 pasa a `docs/10`. |
| 26-oct | ✏️ S7 se adelantó al 26-oct y se ejecutó con Opus 5.5. Se corrigió el registro de las traducciones del plan (solo `.es`) y se agregaron guardas a 3 pruebas (detalle en `resumen.md`, Sesión 7). |
| 26-oct | ✏️ S6 se adelantó al 26-oct. El Plan 2 quedó en `docs/08`. |
| 26-oct | ✏️ S5 se adelantó al mismo 26-oct y se ejecutó con Opus 5.5. Se corrigieron 2 fallas del ejecutor de pruebas y el shader de contorno del plan (detalle en `resumen.md`, Sesión 5). |
| 26-oct | ✏️ Plan 1 actualizado: usa `background_sprite` y `exterior_sprite` (con parallax propio del exterior), `arrow_sprite`, y la maqueta en `art/_layout/`. |
| 26-oct | ❌ Cancelado el cambio del proyecto a `C:\dev`: el proyecto se queda en OneDrive, con git fuera. |
| 26-oct | ✏️ El "Hito 1" del calendario original se reemplazó por los Planes 1 a 4, y el calendario se corrió una semana. |

---

## Historial

| Sesión | Fecha | Resultado | Detalle |
| --- | --- | --- | --- |
| S1 | 15-oct | Análisis del diseño, plan de arte, bucle central y primeros documentos | `resumen.md`, Sesión 1 |
| S2 | 15-oct | Diseño v2, alcance y calendario; MCP, wrapper de Godot y git | `resumen.md`, Sesión 2 |
| S3 | 26-oct | Identificación por características, "Grabar" corregido, arte revisado, `docs/06` y Plan 1 | `resumen.md`, Sesión 3 |
| S4 | 26-oct | Fondo y exterior integrados al plan, arte ordenado, primer commit en GitHub y este registro | `resumen.md`, Sesión 4 |
| S5 | 26-oct | Plan 1 ejecutado: 32 pruebas OK, escena del escritorio con el arte, parallax y comparación con la maqueta (99,3 % tras integrar la sombra del fondo). Luego: chat que se cierra con un clic fuera, cámara con zoom que mira hacia el mouse (a prueba) y termómetro fuera | `resumen.md`, Sesión 5 |
| S6 | 26-oct | Plan 2 escrito (`docs/08`): 10 tareas y 42 pruebas nuevas. Asteriscos para las características (decisión de Benja). `docs/02` §9–10 actualizado | `resumen.md`, Sesión 6 |
| S7 | 26-oct | Plan 2 ejecutado: 78 pruebas OK. Clases de datos, evaluador y validador de reglas, CSV `[PROTO]`, El Trauco de ejemplo, 3 amigos, 5 noches y catálogo. `docs/04`, F | `resumen.md`, Sesión 7 |
| S8 | 26-oct | Plan 3 escrito (`docs/10`): 12 tareas, de 78 a 148 pruebas. Señuelos (decisión de Benja), barra de identificación, estática por frase y preguntas con 5 s o menos. Código probado en una copia aparte y el plan validado sobre una copia limpia | `resumen.md`, Sesión 8 |
| S9 | 30-oct | Plan 3 ejecutado: 148 pruebas OK. Señuelos, solicitudes con temporizador, estática, preguntas, identificación por clics y panel del chat con pestañas. Captura del chat revisada. `docs/04`, G | `resumen.md`, Sesión 9 |
| S10 | 30 y 31-oct | Plan 4 escrito (`docs/11`): 7 tareas, de 148 a 177 pruebas. Cuaderno a la derecha e independiente del chat, memoria por amigo que vuelve al índice y reacción provisional (decisiones de Benja). Código probado en una copia aparte y plan validado sobre una copia limpia | `resumen.md`, Sesión 10 |
| S11 | 31-oct | Plan 4 ejecutado: 177 pruebas OK. Memoria de páginas por amigo, página de la entidad, respuesta y reacción provisional, panel del cuaderno a la derecha y respuestas desde el chat. Captura del cuaderno revisada. `docs/04`, H | `resumen.md`, Sesión 11 |
| S12 | 31-oct | Plan 5 escrito (`docs/12`). Videos que llegan solos hasta el Plan 6, video de un amigo aturdido que se atrasa y color fijo por dial (decisiones de Benja). Después, notas de prueba: chat de terminal con Departure Mono, textos reales en primera persona y aviso de daño agregado al Plan 5 (13 tareas, de 185 a 251 pruebas). Plan validado dos veces sobre copias limpias | `resumen.md`, Sesión 12 y su continuación |
| S13 | 31-oct | Plan 5 ejecutado: 251 pruebas OK. Valores de equilibrio en `data/balance.tres`, consecuencias, vida y aturdimiento, aviso de daño en el chat, reloj de la noche, diales, hora, videos, viñeta y pantalla final. Capturas de la noche revisadas. `docs/04`, I | `resumen.md`, Sesión 13 |
| S14 | 31-oct al 2-nov | Plan 6 escrito (`docs/13`): 17 tareas, de 251 a 326 pruebas. Audio Sync en el mixer visto desde arriba y desde el botón «Sincronizar» del chat, los videos que se descargan en el chat, las reglas de un amigo sin señal y el celular provisional (decisiones de Benja). Código probado en una copia aparte y plan validado sobre una copia limpia | `resumen.md`, Sesión 14 |
| S16 | 2-nov | Plan 7 escrito (`docs/14`): 14 tareas, de 326 a 373 pruebas. El director con olas y respiro, los screamers con sus reglas de justicia, las alucinaciones, la figura de la ventana escondida y el susto guionado de la noche 1 con el chat de Gonzalo (decisiones de Benja). La noche 0 (tutorial) entra al Plan 8. Código probado en una copia aparte y plan validado sobre una copia limpia | `resumen.md`, Sesión 16 |
| S15 | 2-nov | Plan 6 ejecutado: 326 pruebas OK. La señal de cada amigo con interferencias, las reglas de un amigo sin señal, los avisos de videos y señal en el chat, la descarga en el chat, Audio Sync en el mixer (también con «Sincronizar»), el celular con su feed y 7 sonidos provisionales. Capturas del mixer, de la descarga y del celular revisadas. `docs/04`, J | `resumen.md`, Sesión 15 |
