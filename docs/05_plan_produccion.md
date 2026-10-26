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
| 7 | Director de ritmo, 5 noches como datos y 7 entidades | Diseño §13–14 |
| 8 | Menú principal, guardado al comienzo de cada noche, resumen entre noches y pantalla de victoria | Diseño §5 |
| 9 | Opciones: volumen por canal, reducir destellos, desactivar parallax y temporizadores ×1,5 | Diseño §19 |
| 10 | Sonido básico: ambiente, mensajes, alarmas, screamers y un sonido por entidad | Diseño §17 |

### Prioridad 2 — antes del 10 de diciembre, si alcanza el tiempo

| # | Qué |
| --- | --- |
| 11 | Traducción al inglés. Los textos están en CSV desde el primer día. |
| 12 | Cinemáticas opcionales (introducción, entre noches y final), como texto con una ilustración y la opción de saltarlas. |

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

## 3. Riesgos

- **Vamos una semana atrás.** No hay margen para agregar nada a la v1. Si una semana se atrasa, lo primero que se simplifica es el número de entidades (las noches 4 y 5 reutilizan las conocidas).
- **Diseñar 7 entidades depende solo de ti.** Las 3 primeras hacen falta en la semana 2 para que el bucle central tenga contenido.
- **El arte nuevo de la interfaz** (chat, cuaderno, celular) es mucho. Mientras no esté, el prototipo usa paneles provisionales de Godot. El juego tiene que poder entregarse aunque algún panel quede simple.
- **OneDrive** a veces bloquea o reemplaza archivos mientras sincroniza. Git vive fuera de OneDrive y el respaldo real es GitHub: hay que crear el repositorio pronto.
- **Probar con otras personas** es lo que más se suele saltar. La semana 5 no se mueve.
