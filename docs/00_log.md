# Registro de sesiones

**Léelo primero.** Dice qué sesión toca ahora, con qué modelo y nivel de esfuerzo, y qué documento se usa.

Estados: ✅ completada · ▶ siguiente · ⏳ pendiente · ✏️ modificada · ❌ cancelada

---

## ▶ Siguiente sesión: S21b — Planificar el lore por noche

| | |
| --- | --- |
| **Qué se hace** | Se planifica con Benja qué le pasa al grupo en cada noche, con `superpowers:brainstorming`. El resultado es un documento de contenido, sin código; el plan de implementación sale de ahí, en otra sesión. |
| **Tipo** | Planificación, sin código. |
| **Modelo** | **Opus 5.5** |
| **Esfuerzo** | **high** |
| **Antes de empezar** | Conviene haber probado el Plan 9.1 (`docs/04`, R, unos 20 minutos), aunque no es requisito. |
| **Qué escribirle a Claude** | `Lee docs/19_prompt_lore.md y sigue sus instrucciones.` |
| **Tu parte** | Decidir el lore de cada noche y corregir los borradores. |
| **Está terminada cuando** | El documento de lore está escrito y aprobado, y la sesión que lo implementa está agendada en este registro. |

**Después:** S22, las correcciones tras las pruebas con personas (contenido congelado el 25 de noviembre).

---

## Qué documentos son planes de sesión

Solo se ejecutan los documentos `docs/NN_plan_*.md` que **no** son hojas de ruta. Hoy **no hay ninguno pendiente**: el **Plan 9.1: ajustes de mecánicas y la Mano** (`docs/24`) se escribió y se ejecutó en S21f. Queda 1 prompt de sesión listo: `docs/19` (S21b). El siguiente plan numerado es el **Plan 10** (sonido, pulido y versión, el Plan 9 original), que se escribe en S23.

| Documento | Qué es | ¿Se ejecuta? |
| --- | --- | --- |
| `docs/00_log.md` | Este registro: qué sesión toca | — |
| `docs/24_plan_ajustes_mecanicas.md` | **Plan 9.1**: ajustes de mecánicas y la Mano, con lo que cambió al ejecutarlo | Ya ejecutado (S21f) ✅ |
| `docs/23_prompt_ajustes_mecanicas.md` | Prompt de la sesión S21f: ajustes de mecánicas y la Mano | Ya ejecutado (S21f) ✅ |
| `docs/22_diagnostico_mecanicas.md` | Diagnóstico de Claude: por qué el juego se siente plano, con propuestas y lo que eligió Benja | No (referencia) |
| `docs/20_prompt_red_social.md` | Prompt de la sesión S21c: la red social imita a una real | Ya ejecutado (S21c) ✅ |
| `docs/19_prompt_lore.md` | Prompt de la sesión S21b: planificar el lore por noche | **Sí, en S21b** |
| `docs/18_plan_dinamismo.md` | **Plan 9**: dinamismo, paso a paso, con código | Ya ejecutado (S21) ✅ |
| `docs/17_ideas_dinamismo.md` | Notas de la prueba del 7-nov, ordenadas, con las decisiones del Plan 9 | No (referencia; de aquí sale el Plan 9) |
| `docs/16_plan_feedback_1.md` | **Plan 8.1**: el feedback de la primera prueba, paso a paso, con código | Ya ejecutado (S19) ✅ |
| `docs/15_plan_noches_menu.md` | **Plan 8**, paso a paso, con código | Ya ejecutado (S19) ✅ |
| `docs/14_plan_screamers_director.md` | **Plan 7**, paso a paso, con código | Ya ejecutado (S17) ✅ |
| `docs/13_plan_mantenimiento.md` | **Plan 6**, paso a paso, con código | Ya ejecutado (S15) ✅ |
| `docs/12_plan_consecuencias_noche.md` | **Plan 5**, paso a paso, con código | Ya ejecutado (S13) ✅ |
| `docs/11_plan_cuaderno.md` | **Plan 4**, paso a paso, con código | Ya ejecutado (S11) ✅ |
| `docs/10_plan_solicitudes_chat.md` | **Plan 3**, paso a paso, con código | Ya ejecutado (S9) ✅ |
| `docs/09_propuesta_entidades.md` | Borrador de 3 entidades para que Benja las refine | No (referencia para Benja) |
| `docs/08_plan_datos_textos.md` | **Plan 2**, paso a paso, con código | Ya ejecutado (S7) ✅ |
| `docs/07_plan_escena_arte.md` | **Plan 1**, paso a paso, con código | Ya ejecutado (S5) ✅ |
| `docs/06_plan_v1.md` | Hoja de ruta: los 10 planes de la v1 y el estado del arte | No; de aquí salen los planes 2 a 10 |
| `docs/05_plan_produccion.md` | Alcance por prioridad y calendario por semana | No |
| `docs/02_bucle_central.md` | Detalle de la mecánica central y plantilla de entidades | No (referencia) |
| `docs/03_plan_arte.md` | Reglas del pipeline de arte y arte faltante | No (referencia) |
| `docs/04_instrucciones_godot.md` | Lo que tú haces en Godot | Tú, cuando haya pasos pendientes (hoy: L, M, O, P, Q y R) |
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
| S17 | 3 nov | Ejecutar el Plan 7 → una noche con ritmo y screamers justos | Ejecución | Sonnet 5.5 · high | Autorizar commits; probar (`docs/04`, K) | ✅ |
| S18 | 4 nov | Escribir el Plan 8: noches (con la noche 0, el tutorial), menú, guardado y opciones | Plan | Opus 5.5 · high (se adelantó) | Decisiones de la noche 0, las entidades y las opciones | ✅ |
| S19 | 4 nov | Ejecutar el Plan 8 → el juego se puede terminar | Ejecución | Sonnet 5.5 · high (se adelantó) | Autorizar commits; probar (`docs/04`, L) | ✅ |
| S20 | 7 nov | Escribir el Plan 9: dinamismo (nuevo, `docs/17`) | Plan | Opus 5.5 · high | Decisiones del dinamismo | ✅ |
| S21 | 7 nov | Ejecutar el Plan 9 → el juego es más dinámico | Ejecución | Sonnet 5.5 · high (se adelantó) | Autorizar commits; probar (`docs/04`, N) | ✅ |
| S21e | 10–11 nov | Diagnóstico de las mecánicas (`docs/22`) y prompt de los ajustes (`docs/23`) | Diseño | Opus 5.5 | Elegir qué arreglar | ✅ |
| S21f | 11 nov | Ajustes de mecánicas y la Mano (`docs/23`, Plan 9.1 en `docs/24`) | Diseño, plan y ejecución | Opus 5.5 · xhigh | Probar (`docs/04`, R); corregir los textos nuevos; decir desde cuándo se ve la Mano | ✅ |
| **S21b** | Antes del 25 nov | **Planificar el lore por noche** (`docs/19`) | Plan | **Opus 5.5 · high** | Decisiones del lore; corregir borradores | ▶ |
| S21c | 9 nov | Red social que imita a una real (`docs/20`) | Diseño y ejecución | Opus 5.5 · high (se adelantó a S21b) | Probar (`docs/04`, P); confirmar de dónde son las fotos | ✅ |
| S21d | 10 nov | Pulir el arte y los sonidos de Claude (pedido de Benja, sin plan aparte) | Diseño y ejecución | Opus 5.5 | Escuchar los sonidos y revisar el arte (`docs/04`, Q); corregir los textos del Imbunche | ✅ |
| S22 | 23–29 nov | Correcciones tras las pruebas con personas (contenido congelado el 25) | Corrección | Opus 5.5 · high | Pruebas con 3 a 5 personas | ⏳ |
| S23 | 30 nov | Escribir el Plan 10: sonido, pulido y versión | Plan | Opus 5.5 · high | Los sonidos que faltan (`sonidos_pendiente.md`); los de S21d ya no son de relleno | ⏳ |
| S24 | 1–5 dic | Ejecutar el Plan 10 → versión candidata | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S25 | 6–10 dic | Correcciones finales y entrega | Corrección | Opus 5.5 · high | — | ⏳ |

**Si una sesión de ejecución no termina su plan**, la siguiente sesión la continúa (se anota como ✏️) antes de pasar a la que sigue en la tabla.

---

## Cambios a la secuencia

| Fecha | Cambio |
| --- | --- |
| 11-nov | ✏️ S21f se hizo el mismo 11 de noviembre (fecha objetivo: 11 a 16), en Opus 5.5 · xhigh. Benja contestó las 6 preguntas y autorizó todos los commits al empezar. El Plan 9.1 (`docs/24`) se escribió y se ejecutó en la misma sesión: 12 commits en `main`, de 556 a 613 pruebas OK. La prueba de equilibrio encontró y corrigió un video que podía caer encima de la ola final. Queda abierta una pregunta: la Mano casi no se ve a mitad de camino. **S21b (el lore) es la siguiente.** Detalle en `resumen.md`, Sesión 21f. |
| 11-nov | ✏️ **S21e, nueva:** Benja pidió un escaneo profundo de lo que hace que el juego se sienta plano. Claude escribió el diagnóstico (`docs/22`), y Benja eligió qué arreglar y sumó la Mano y Trust sin recuperación. **S21f, nueva y siguiente:** implementa esos ajustes con el prompt `docs/23` (Plan 9.1) en Opus 5.5 · xhigh. S21b pasa a ir después de S21f. Detalle en `resumen.md`, Sesión 21e. |
| 10-nov | ✏️ **S21d, nueva y fuera de la secuencia:** Benja pidió pulir todo el arte y los sonidos que había generado Claude, con las skills nuevas de `disciplines`. Se adelanta una parte del Plan 10: los sonidos ya no son de relleno, y el mixer, el cuaderno, la tinta, el celular, las barras y los menús son pixel art en `art/ui/`. El Plan 10 conserva los sonidos que **faltan**. S21b sigue siendo la siguiente. Detalle en `resumen.md`, Sesión 21d. |
| 9-nov | ✏️ S21c se hizo antes que S21b, como permitía el registro, porque es independiente del lore. Se diseñó con Benja y se programó en la misma sesión, sin un plan aparte. Creció más allá de la vista: las fotos perturbadoras, que el prompt dejaba como pregunta, entraron ahora con su regla en `balance.tres` (detalle en `resumen.md`, Sesión 21c). S21b sigue siendo la siguiente. |
| 9-nov | ✏️ Benja probó el Plan 9 el 8-nov y pidió 5 cosas. S21 siguió con 3 correcciones (la sombra sobre el escritorio, 8 luces y luces de ronda en Audio Sync, y las voces de los amigos: 542 pruebas OK) y 2 prompts para sesiones nuevas: **S21b, planificar el lore** (`docs/19`) y **S21c, la red social** (`docs/20`). Entran antes de S22; la implementación del lore se agenda al cerrar S21b. Detalle en `resumen.md`, Sesión 21 y su continuación. |
| 7-nov | ✏️ S21 se adelantó al mismo 7 de noviembre (fecha objetivo: 10 a 17 de noviembre), justo después de S20, y se ejecutó inline con `superpowers:executing-plans` en Sonnet 5.5 · high, como proponía el registro. Benja autorizó los 11 commits al empezar, directo en `main`. El plan se aplicó tal como está escrito (521 pruebas OK, las 5 capturas revisadas); solo se corrigió un detalle de formato de los bloques que terminan al final de un archivo (detalle en `resumen.md`, Sesión 21). S22 depende ahora de que Benja pruebe el juego (`docs/04`, N). |
| 7-nov | ✏️ Benja probó el juego y dio 8 notas sobre que el juego es poco dinámico. Se ordenaron y se brainstormearon con preguntas con opciones (`docs/17_ideas_dinamismo.md`): barras de HUD (nueva, nota 9), ajustes de dificultad y audios en «¿Qué oyes?» que cambian la acción correcta, batería del celular (tope por noche), cortinas con la criatura que se queda y hay que revisar, e incidentes con respuesta de sentido común. La historia con decisiones (notas 3 y 6) y editar videos (nota 5) quedan para después. **Nuevo Plan 9: dinamismo** (escrito en S20, `docs/18`, 11 tareas, de 461 a 521 pruebas), que entra antes de probar con personas y empuja el resto de la secuencia: S20–S21 nuevas (escribir y ejecutar el Plan 9), y lo que era S20–S23 pasa a S22–S25. El Plan 9 original (sonido) pasa a ser el **Plan 10**. |
| 4-nov | ✏️ Después de ejecutar el Plan 8, Benja probó el juego y dio feedback (la criatura en la ventana en lugar del jumpscare, las noches 1 y 2, Audio Sync en 2 rondas, Trust por tardar y los diales). Se trabajó en la misma sesión S19, con `superpowers:brainstorming` y `superpowers:writing-plans`: el plan quedó en `docs/16_plan_feedback_1.md` (Plan 8.1, 7 tareas, de 446 a 461 pruebas) y se ejecutó inline en Sonnet 5.5 · high, con los 7 commits autorizados en `main` (detalle en `resumen.md`, Sesión 19, continuación). Nuevo `sonidos_pendiente.md`. |
| 4-nov | ✏️ S19 se adelantó al 4 de noviembre (fecha objetivo: 20 a 22 de noviembre), justo después de S18, y se ejecutó inline con `superpowers:executing-plans` en Sonnet 5.5 · high, como proponía el registro. Benja autorizó los 14 commits al empezar, directo en `main`. El plan se aplicó tal como está escrito (446 pruebas OK), sin correcciones; solo queda anotado un detalle visual menor del panel de opciones (detalle en `resumen.md`, Sesión 19). S20 depende ahora de que Benja pruebe el juego (`docs/04`, L). |
| 4-nov | ✏️ S18 se adelantó al 4 de noviembre (fecha objetivo: 19 de noviembre) y se escribió en Opus 5.5 con esfuerzo high. Benja todavía no había probado la identificación por preguntas ni los screamers (`docs/04`, G y K), así que no hubo notas de prueba. Tomó 6 decisiones: la noche 0 guiada y sin perder, que enseña también a descargar un video y se puede saltar; las 7 entidades como borrador de Claude; los temporizadores ×1,5 solo para responder, y el menú de pausa con Esc (detalle en `resumen.md`, Sesión 18). |
| 3-nov | ✏️ Después de ejecutar el Plan 7, y a pedido de Benja, se cambió la identificación: **la entidad se identifica preguntando** (el mensaje inicial solo saluda, dice el lugar y a veces trae una pista; el resto sale al preguntar), con más tiempo por solicitud y menos solicitudes por noche (detalle en `resumen.md`, Sesión 17, continuación). Se hizo en la misma sesión S17, sin un plan aparte. **El Plan 8 debe tenerlo en cuenta:** la noche 0 (tutorial) tiene que enseñar a preguntar. |
| 3-nov | ✏️ S17 se adelantó al 3 de noviembre (fecha objetivo: 17 a 19 de noviembre), justo después de S16, y se ejecutó inline con `superpowers:executing-plans` en Sonnet 5.5 · high, como proponía el registro. Benja autorizó los 14 commits al empezar, directo en `main`. El plan se aplicó tal como está escrito; solo se agregó una línea en blanco por legibilidad en `scripts/desk/clickable_sprite.gd` (detalle en `resumen.md`, Sesión 17). |
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
| S17 | 3-nov | Plan 7 ejecutado: 373 pruebas OK. El director con olas y respiro, los 7 screamers con sus reglas de justicia, las alucinaciones, la figura de la ventana escondida, el sonido ambiente, el susto guionado de la noche 1 y el chat de Gonzalo con el botón de Matías y el celular que parpadea. 12 sonidos provisionales. Capturas revisadas. `docs/04`, K. Después, a pedido de Benja, la entidad se identifica preguntando (`docs/04`, G) | `resumen.md`, Sesión 17 y su continuación |
| S18 | 4-nov | Plan 8 escrito (`docs/15`): 14 tareas, de 382 a 446 pruebas. La noche 0 guiada y sin perder, las 7 entidades (borrador de Claude), el menú principal, el guardado, el resumen entre noches, la victoria final, el menú de pausa y las opciones (decisiones de Benja). Código probado en una copia aparte y plan validado sobre una copia limpia | `resumen.md`, Sesión 18 |
| S19 | 4-nov | Plan 8 ejecutado: 446 pruebas OK, en 14 commits (y, el mismo día, el Plan 8.1 con el feedback de Benja: 461 pruebas OK, en 7 commits más). La noche 0 guiada con su aviso, las 7 entidades (borrador de Claude), las opciones con 3 canales de audio, el guardado, `GameState` y el menú principal, el resumen entre noches y la victoria, y el menú de pausa con Esc. Capturas revisadas y arranque sin errores. `docs/04`, L. **El juego se puede terminar** | `resumen.md`, Sesión 19 |
| S20 | 7-nov | Notas de prueba ordenadas (`docs/17`) y Plan 9 escrito (`docs/18`): 11 tareas, de 461 a 521 pruebas. Las barras, la dificultad, Audio Sync más rápido, los audios que cambian la acción, la batería, las cortinas, la criatura que se queda y los accidentes (decisiones de Benja). Código probado en una copia aparte y plan validado sobre una copia limpia | `resumen.md`, Sesión 20 |
| S21 | 7-nov | Plan 9 ejecutado: 521 pruebas OK, en 11 commits. Las barras de Connection, Sanity y Trust, menos tiempo y sin pista desde la noche 3, Audio Sync más rápido, los audios de las 7 entidades que cambian la acción, la batería del celular, las cortinas, la criatura que se queda 25 s y los accidentes que se responden con sentido común. Capturas revisadas y arranque sin errores. `docs/04`, N. **El juego es más dinámico.** Continuación: la sombra sobre el escritorio, 8 luces y luces de ronda en Audio Sync, las voces de los amigos (542 pruebas OK) y los prompts `docs/19` y `docs/20`. `docs/04`, O | `resumen.md`, Sesión 21 y su continuación |
| S21c | 9-nov | Snapgram: la red social imita a una real, con 12 fotos reales de gatitos, cuentas sin nombre y barras grises, y 4 fotos perturbadoras con poca Sanity. 555 pruebas OK y capturas revisadas. `docs/04`, P | `resumen.md`, Sesión 21c |
| S21d | 10-nov | Arte y sonidos pulidos: 38 sonidos realistas sin palabras (síntesis y 5 grabaciones de dominio público o CC0), el Imbunche que llora como guagua, las voces que murmuran, y 17 PNG de pixel art (el mixer, el cuaderno universitario, la tinta, el celular, las barras, las barras de señal y los menús, con los sprites del cuarto en el menú). 556 pruebas OK y capturas revisadas. `docs/04`, Q | `resumen.md`, Sesión 21d |
| S21e | 10–11 nov | Diagnóstico de las mecánicas: el lugar delata a la entidad, los señuelos no cuestan, las olas no existen (simulación del director), el riesgo nunca conviene y el terror queda detrás de los paneles. Benja eligió los ajustes y sumó la Mano y Trust sin recuperación. Prompt `docs/23` para S21f | `resumen.md`, Sesión 21e |
| S21f | 11-nov | Plan 9.1 escrito y ejecutado (`docs/24`): 613 pruebas OK, en 12 commits. El mensaje inicial con lo que le pasa al amigo y el lugar solo a veces, las características con otras palabras y un nombre fijo en el cuaderno, el señuelo de 1 s, olas de verdad con una ola final, el aviso de videos, la criatura al azar, la Mano con el flash del celular (y su paso en la noche 0), Trust sin recuperación, y una prueba de que toda noche se puede ganar | `resumen.md`, Sesión 21f |
| S15 | 2-nov | Plan 6 ejecutado: 326 pruebas OK. La señal de cada amigo con interferencias, las reglas de un amigo sin señal, los avisos de videos y señal en el chat, la descarga en el chat, Audio Sync en el mixer (también con «Sincronizar»), el celular con su feed y 7 sonidos provisionales. Capturas del mixer, de la descarga y del celular revisadas. `docs/04`, J | `resumen.md`, Sesión 15 |
