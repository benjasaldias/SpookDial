# Plan de producción

Entrega: **10 de diciembre de 2026**, con el juego completo y jugable.

**Calendario recalibrado el 26 de octubre:** todavía no hay código, así que vamos una semana atrás del calendario original. Quedan 6 semanas y media.

## 1. Alcance por prioridad

El juego se construye en este orden. La **v1** es lo mínimo para entregar. Lo que viene después se agrega de a uno, en el orden de la lista, solo cuando lo anterior está terminado y probado. Cómo se implementa cada parte está en `docs/06_plan_v1.md`.

### v1 — obligatorio para el 10 de diciembre

| # | Qué | Detalle en |
| --- | --- | --- |
| 1 | Escena del escritorio con el arte, objetos clickeables, diales, parallax y paneles base | Diseño §6–7 y §16, `docs/07` |
| 2 | Solicitudes: mensajes con características clickeables, estática, preguntas, cuaderno con índice y reglas, respuesta desde la página, consecuencias, vida y pantalla de derrota explicativa | Diseño §8–9, `docs/02` |
| 3 | Señal por amigo, interferencias y Audio Sync individual en el mixer | Diseño §10.1 y §10.6 |
| 4 | Sanity con el celular, y Trust; ambos con sus efectos graduales | Diseño §10.2–10.3 |
| 5 | Recibir videos (manteniendo presionado) y la cuota como condición para ganar | Diseño §10.4–10.5 |
| 6 | Screamers (ambientales, sobre el cuaderno y un jumpscare por noche) con sus reglas de justicia | Diseño §11 |
| 7 | Director de ritmo, noche 0 (tutorial, decisión de Benja, sesión 16), 5 noches como datos y 7 entidades | Diseño §5, §13–14 |
| 8 | Menú principal, guardado al comienzo de cada noche, resumen entre noches y pantalla de victoria | Diseño §5 |
| 9 | Opciones: volumen por canal, reducir destellos, desactivar parallax y temporizadores ×1,5 | Diseño §19 |
| 10 | Sonido básico: ambiente, mensajes, alarmas, screamers y un sonido por entidad | Diseño §17 |

### 10bis — dinamismo (agregado el 7-nov, antes de probar con personas)

Tras probar el juego, Benja notó que es poco dinámico. El detalle y las decisiones están en `docs/17_ideas_dinamismo.md`, y el plan paso a paso, en `docs/18_plan_dinamismo.md` (Plan 9 de `docs/06`): barras de HUD, ajustes de dificultad y audios en «¿Qué oyes?» que cambian la acción correcta, batería del celular y cortinas (la criatura que se queda y hay que revisar), e incidentes con respuesta de sentido común. Entra en la semana 4–5, antes de probar con 3 a 5 personas. Editar los videos recibidos y la historia con decisiones quedan fuera, en la lista de después.

### 10ter — pedido por Benja el 8-nov, sin planificar todavía

| Qué | Dónde se decide |
| --- | --- |
| **Lore por noche, en la v1** (planificado en S21b, 12-nov): la historia en el chat, la llamada grupal, las decisiones con forma de accidente y que cada criatura nueva salga al menos una vez. Orden: ✅ el sistema y la noche 1 (S21l, `docs/31`); la noche 2 cuando Benja la apruebe; las noches 3 a 5 después de probar. **Mínimo si falta tiempo:** la intro y el cierre del vlog en la llamada grupal de cada noche, sin decisiones. Absorbe los puntos 20 y 22. | `docs/21_lore_por_noche.md` |
| ✅ La red social del celular imita a una real: Snapgram (hecho en S21c, 9-nov). | `docs/20_prompt_red_social.md` |

### Prioridad 2 — antes del 10 de diciembre, si alcanza el tiempo

| # | Qué |
| --- | --- |
| 11 | Traducción al inglés. Los textos están en CSV desde el primer día. |
| 12 | Cinemáticas opcionales (introducción y final; lo de entre noches lo cuenta el chat desde S21b), como texto con una ilustración y la opción de saltarlas. |

### Después de la v1, en este orden

| # | Qué |
| --- | --- |
| 13 | "Pedir contenido" (diseño en `docs/01`, sesión 1). |
| 14 | Ráfagas de imágenes con anomalías. |
| 15 | Mecánica de defensa dentro de la base en la noche 5. |
| 16 | Parallax de primer plano y partículas de polvo. |
| 17 | Estado "perdido" de los amigos. |
| 18 | Trust por amigo. |
| 19 | Audífonos en el escritorio (decorativos). |
| 20 | ✅ Pasó a la v1 con el lore (10ter, `docs/21`). Antes: progresión guionada entre los amigos: chats guionados que avanzan noche a noche, como el que sigue al susto guionado (idea de Benja, sesión 16). El Plan 7 ya deja los chats guionados como datos de una noche. |
| 21 | Editar los videos recibidos (nota de Benja, 7-nov), si al probar sigue faltando algo que hacer entre solicitudes. Detalle en `docs/17_ideas_dinamismo.md`, Lote D. |
| 22 | ✅ Pasó a la v1 con el lore (10ter, `docs/21`); la regla 9 se enmendó. Antes: historia con pseudo-lore y decisiones de sentido común (notas de Benja, 7-nov): los amigos se separan, se encuentran heridos, decisiones básicas contestadas por intuición. Choca con la regla 9 de `CLAUDE.md` (la historia no cambia las mecánicas) y habría que enmendarla. Detalle en `docs/17_ideas_dinamismo.md`, "Para después". Recomendación de Benja y de Claude: esperar a que las mecánicas se sientan bien solas. |

**Eliminado:** la cruz, el retrato y mentir (obsoletos), y el buscador por rasgos (reemplazado por las características clickeables).

## 2. Calendario

| Semana | Fechas | Claude (planes de `docs/06`) | Benja | Está listo cuando… |
| --- | --- | --- | --- | --- |
| 1 | 26 oct – 1 nov | Plan 1 (escena y arte) y Plan 2 (datos y textos) | Arte faltante del plan 1 (`docs/06` §3). Las 3 primeras entidades: El Tue Tué, La Calchona y El Trauco. | La escena se ve completa en Godot y una entidad está cargada como datos. |
| 2 | 2–8 nov | Plan 3 (solicitudes y chat) y Plan 4 (cuaderno) | Interfaz del chat y del cuaderno; textos reales de las 3 entidades. | El bucle central se juega con 3 entidades. |
| 3 | 9–15 nov | Plan 5 (consecuencias, medidores y noche) y Plan 6 (mantenimiento) | Diales rediseñados, mixer en piezas, celular ampliado y 2 entidades más. | Una noche completa se gana o se pierde. |
| 4 | 16–22 nov | Plan 7 (screamers y director) y Plan 8 (noches, menú, guardado y opciones) | Las 2 últimas entidades, screamers y menú. | El juego se puede terminar. |
| 5 | 23–29 nov | Correcciones. **El contenido se congela el 25 de noviembre.** | Pruebas con 3 a 5 personas. | Lista de problemas priorizada. |
| 6 | 30 nov – 5 dic | Plan 9 (sonido, pulido y versión de Windows) | Sonido y pulido. | Versión candidata lista el 5 de diciembre. |
| — | 6–10 dic | Correcciones finales | Prioridad 2, si alcanza. | Entregado el 10 de diciembre. |

**7-nov:** se agregó el Plan 9 (dinamismo, ítem 10bis de §1) entre la semana 4 y la 5, antes de probar con personas. El detalle de la secuencia real de sesiones, que ya se había adelantado bastante respecto a esta tabla, está en `docs/00_log.md`.

## 3. Riesgos

- **Vamos una semana atrás.** No hay margen para agregar nada a la v1. Si una semana se atrasa, lo primero que se simplifica es el número de entidades (las noches 4 y 5 reutilizan las conocidas).
- **Diseñar 7 entidades depende solo de ti.** Las 3 primeras hacen falta en la semana 2 para que el bucle central tenga contenido.
- **El arte nuevo de la interfaz** (chat, cuaderno, celular) es mucho. Mientras no esté, el prototipo usa paneles provisionales de Godot. El juego tiene que poder entregarse aunque algún panel quede simple.
- **OneDrive** a veces bloquea o reemplaza archivos mientras sincroniza. Git vive fuera de OneDrive y el respaldo real es GitHub: hay que crear el repositorio pronto.
- **Probar con otras personas** es lo que más se suele saltar. La semana 5 no se mueve.
