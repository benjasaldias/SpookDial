# Registro de sesiones

**Léelo primero.** Dice qué sesión toca ahora, con qué modelo y nivel de esfuerzo, y qué documento se usa.

Estados: ✅ completada · ▶ siguiente · ⏳ pendiente · ✏️ modificada · ❌ cancelada

---

## ▶ Siguiente sesión: S5 — Ejecutar el Plan 1

| | |
| --- | --- |
| **Qué se hace** | Construir la escena del escritorio con tu arte, siguiendo `docs/07_plan_escena_arte.md` tarea por tarea (14 tareas y 32 pruebas). |
| **Tipo** | Ejecución de un plan ya escrito, con todo el código incluido. |
| **Modelo** | **Sonnet 5.5** |
| **Esfuerzo** | **high** |
| **Si se traba** (errores de Godot, WSL u OneDrive que no se resuelven en 2 o 3 intentos) | Cambiar a **Opus 5.5**, esfuerzo **high**. |
| **Antes de empezar** | Godot **cerrado**. Abre Claude Code en esta carpeta (OneDrive). |
| **Qué escribirle a Claude** | "Ejecuta el Plan 1 (`docs/07`) inline, tarea por tarea." |
| **Tu parte** | Tener Godot cerrado mientras Claude trabaja; al final, la revisión visual de la Tarea 14 (unos 5 minutos); aprobar los commits. |
| **Está terminada cuando** | Pasan las 32 pruebas, la captura se parece a la maqueta en un 90 % o más y tú revisaste la escena en Godot. |

---

## Qué documentos son planes de sesión

Solo se ejecutan los documentos `docs/NN_plan_*.md` que **no** son hojas de ruta. Hoy hay **uno**: `docs/07`.

| Documento | Qué es | ¿Se ejecuta? |
| --- | --- | --- |
| `docs/00_log.md` | Este registro: qué sesión toca | — |
| `docs/07_plan_escena_arte.md` | **Plan 1**, paso a paso, con código | **Sí: es la sesión S5** |
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
| **S5** | 27–28 oct | **Ejecutar el Plan 1: escena y arte** | Ejecución | **Sonnet 5.5 · high** | Godot cerrado | ▶ |
| S6 | 29 oct | Escribir el Plan 2: datos y textos | Plan | Opus 5.5 · high | — | ⏳ |
| S7 | 30 oct – 1 nov | Ejecutar el Plan 2 | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S8 | 2 nov | Escribir el Plan 3: solicitudes y chat | Plan | Opus 5.5 · xhigh (es el más complejo) | **3 entidades diseñadas** | ⏳ |
| S9 | 3–5 nov | Ejecutar el Plan 3 | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S10 | 6 nov | Escribir el Plan 4: cuaderno | Plan | Opus 5.5 · high | Interfaz del cuaderno (si está) | ⏳ |
| S11 | 7–8 nov | Ejecutar el Plan 4 → **el bucle central se juega** | Ejecución | Sonnet 5.5 · high | Probarlo | ⏳ |
| S12 | 9 nov | Escribir el Plan 5: consecuencias, medidores y noche | Plan | Opus 5.5 · high | — | ⏳ |
| S13 | 10–12 nov | Ejecutar el Plan 5 | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S14 | 12 nov | Escribir el Plan 6: mantenimiento | Plan | Opus 5.5 · high | Mixer en piezas, celular ampliado | ⏳ |
| S15 | 13–15 nov | Ejecutar el Plan 6 → **una noche completa** | Ejecución | Sonnet 5.5 · high | Probarlo | ⏳ |
| S16 | 16 nov | Escribir el Plan 7: screamers y director | Plan | Opus 5.5 · high | Arte de screamers | ⏳ |
| S17 | 17–19 nov | Ejecutar el Plan 7 | Ejecución | Sonnet 5.5 · high | — | ⏳ |
| S18 | 19 nov | Escribir el Plan 8: noches, menú, guardado y opciones | Plan | Opus 5.5 · high | **Las 7 entidades** | ⏳ |
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
