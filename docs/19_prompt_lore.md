# Prompt: planificar el lore por noche

Sesión de **planificación, sin código**. Modelo sugerido: Opus 5.5 · high. Benja la abre escribiendo: `Lee docs/19_prompt_lore.md y sigue sus instrucciones.`

---

## Tu tarea

Benja probó el juego y las mecánicas ya le gustan. Lo que falta es **lore por noche**: que algo le pase al grupo mientras se juega. Planifica con él qué pasa en cada noche, usando `superpowers:brainstorming`. El resultado es un documento de contenido, no código: el plan de implementación sale de ahí, en otra sesión.

Antes de preguntar nada, lee:

- `CLAUDE.md` completo, `docs/00_log.md` y la entrada más reciente de `resumen.md`;
- `spook_dial_design.md`: §2 a §5 (pitch, principio rector, personajes y estructura), §8.9 (accidentes), §9 (consecuencias), §14 (progresión) y §15 (historia);
- `docs/17_ideas_dinamismo.md`, "Para después" (las notas 3 y 6 de Benja), y `docs/05_plan_produccion.md`, puntos 20 y 22;
- lo que ya existe para contar cosas: `scripts/data/chat_script_data.gd`, `chat_line_data.gd`, `incident_data.gd`, `night_data.gd`, `RequestManager.start_chat_script()`, `data/nights/*.tres` y `data/text/messages.csv`.

## Lo que Benja quiere planificar

Eventos por noche, de estos tipos:

- el grupo **se separa** o **se reúne**;
- un miembro **cae inconsciente** o **despierta**;
- alguien **recibe daño**;
- alguien **actúa raro**;
- **texto de relleno:** al final del día esto es un vlog para un canal, y los amigos deberían narrar de acuerdo a eso (hablarle a la cámara, comentar lo que graban, bromear entre ellos).

## Lo que hay que decidir con Benja

Una pregunta a la vez, con opciones y una recomendada. Estas son las que el proyecto ya deja abiertas:

1. **Cuánto cambia la regla 9.** `CLAUDE.md` y el diseño (§3 y §15) dicen que la historia va solo en cinemáticas opcionales y nunca cambia las mecánicas. Un lore que pasa en el chat durante la noche ya no cumple eso. Hay que enmendar la regla con palabras exactas. ¿Las cinemáticas se mantienen, se reemplazan o se complementan?
2. **¿Los eventos son solo texto o cambian el juego?** Es la decisión central. Por evento: "inconsciente" podría ser el estado de aturdido que ya existe, y "recibe daño" podría quitar vida de verdad o ser solo narración. Recuerda que **si un amigo muere se pierde la noche**, y que los accidentes se decidieron para que nunca maten: un daño de la historia no debería hacer perder por azar.
3. **Contradicciones entre la historia y la noche.** Es el riesgo más grande. Si la historia dice que León está inconsciente y justo le llega una solicitud, o que el grupo se separó y el mensaje dice "estoy en el patio", se rompe. Las solicitudes eligen lugar y amigo al azar y el director las reparte (`PacingDirector`). Propón cómo se evita: que el evento bloquee solicitudes de ese amigo, que condicione los lugares, o que el texto sea lo bastante vago.
4. **Cuándo aparecen.** Un texto de relleno no puede competir con una solicitud abierta: el jugador está leyendo pistas y haciendo preguntas contra el tiempo. El director ya deja unos 25 s de respiro entre olas: ¿va ahí? Decide también si un mensaje de relleno marca la pestaña como no leída, y qué pasa si Matías tiene el chat cerrado o si el amigo está sin señal (no lee ni escribe claro).
5. **Dónde se cuenta lo que es del grupo.** Hoy cada amigo tiene un chat solo con Matías: no hay chat grupal. Lo que le pasa al grupo se cuenta por el chat de cada uno, o hace falta algo nuevo. Recomienda lo primero, salvo que Benja lo pida: agregar un chat grupal es alcance nuevo.
6. **¿Hay decisiones de Matías?** El 7-nov Benja dejó "la historia con decisiones" para después, y su lista de ahora no las incluye. Confírmalo.
7. **Perder y repetir.** Una noche perdida se reinicia: ¿el lore se repite igual? ¿Hace falta poder saltarlo, o variantes para que no canse?
8. **Quiénes son.** El diseño solo dice que las personalidades son de sabor, y no las describe. Hay que definirlas para escribir su narración. Datos que ya existen: León es el que termina poseído (¿"actúa raro" es esto, de a poco?), Matías buscaba amistad más que contenido, y los Brujos de Chiloé se interesan en él. Las voces del chat ya son distintas: León, medio y cuadrado; Gonzalo, grave y pausado; Agustín, agudo y rápido (`data/friends/*.tres`). Falta el nombre del canal y de qué trata cada video.
9. **Alcance y fecha.** La entrega es el 10 de diciembre, y el contenido y el arte se congelan el 25 de noviembre. Los puntos 20 y 22 de `docs/05` hoy están después de la v1. Hay que moverlos, compararlos con lo demás (regla 6) y decir qué se recorta si no alcanza. Propón un mínimo que funcione si falta tiempo (por ejemplo, 1 evento y 2 o 3 textos de relleno por noche).

## Reglas del contenido

- Los amigos **nunca dicen el nombre de la entidad**, y el relleno no puede regalar ni falsear pistas ni reglas. No lleva frases clickeables.
- Mensajes cortos y en primera persona, con la forma de hablar de los textos de `messages.csv`. Benja corrige los diálogos: tú escribes un **borrador real**, sin marcas de prototipo.
- La progresión de lugares ya está en el diseño §14: alrededores de la cabaña, camino y lago, bosque, casa abandonada y cueva, y todos los lugares en la noche 5. La noche 0 es el tutorial y ya termina con un chat guionado de Gonzalo.
- Final único: se gana sobreviviendo las 5 noches.
- No agregues ideas que Benja no pidió sin compararlas con `docs/05` (regla 6). Si Benja te pide opinión sobre una regla suya, opina y devuélvela completa para que la confirme.

## Lo que tiene que quedar al terminar

1. **`docs/21_lore_por_noche.md`:** las personalidades, el canal y, por cada noche (0 a 5), una tabla con: momento (hora del reloj o qué ola), amigo, tipo de evento, texto en borrador y efecto en el juego (o "ninguno"). Con los casos de la pregunta 3 resueltos.
2. **Las decisiones de Benja** en `CLAUDE.md` y en el diseño v2, incluida la regla 9 enmendada.
3. **`docs/05`** con el nuevo orden y **`docs/00_log.md`** con la sesión cerrada y la siguiente: escribir el plan de implementación con `superpowers:writing-plans`. Entrada en `resumen.md`, con sus cuatro categorías.

No escribas código ni textos en los CSV en esta sesión. Commits: pregunta antes de cada uno (regla 11). Sin push.
