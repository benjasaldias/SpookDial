# La historia por noche (S21b)

Sesión S21b, 12 de noviembre de 2026, con Benja. Es un documento de contenido, sin código: el plan de implementación sale de aquí, en otra sesión.

- **La noche 1 está aprobada** por Benja, con sus textos corregidos, e **implementada en S21l** (Plan 9.7, `docs/31`), en los 3 modos.
- **La noche 2 queda pospuesta:** el borrador está escrito, pero Benja no alcanzó a revisarlo, y no se implementa hasta que lo apruebe.
- **Las noches 3 a 5 son un esquema** con las ideas de Benja, para detallar después de probar las noches 1 y 2.

Los guiones se trabajan en el documento compartido **"Spook Dial — Guiones de las 5 noches"** (https://claude.ai/artifact/6FbUx39GCLyCPsjrJA7Aqo). Ahí Benja edita los textos. Este archivo copia lo aprobado y fija las reglas; si los dos no coinciden, manda la última versión que aprobó Benja.

---

## 1. Decisiones de Benja

| # | Pregunta | Decisión |
| --- | --- | --- |
| 1 | ¿Quién decide qué criatura le toca a cada amigo y dónde está? | **La historia habla de las criaturas de la noche, pero el juego no cambia:** cada consulta sigue eligiendo la criatura y el lugar al azar. Benja acepta el plot hole ("es algo que un jugador entiende"). Lo único nuevo: **cada criatura nueva de la noche sale al menos una vez**. |
| 2 | ¿Cómo se ve una conversación del grupo? | **Una llamada grupal** (idea de Benja): cuando están los 3 juntos, el chat se muestra como llamada grupal, con un ícono que lo deja claro, y no se puede cambiar de chat. Cuando se separan, vuelven los 3 chats. |
| 3 | ¿Qué pasa con la historia al repetir una noche? | Se repite igual. |
| 4 | ¿En qué modos va? | Igual en Normal, Difícil y Extremo. La prueba de equilibrio incluye sus efectos. |
| 5 | ¿Cómo se llama el canal? | **Acá Penan.** |
| 6 | ¿Y las cinemáticas? | Quedan solo la intro y el final, opcionales (prioridad 2). Lo de entre noches lo cuenta el chat. |
| — | La regla 9 | Enmendada (abajo). |
| — | Personalidades | Aprobadas como las propuso Claude (§3). |
| — | Las líneas *[semilla]* (pistas de la traición de León) | Van: Benja corrigió la de la noche 1. |

**La regla 9, enmendada:**

> **El juego es estrictamente el escritorio.** La historia se cuenta en el chat durante la noche: lo que los amigos le escriben a Matías y la llamada grupal cuando están juntos. Puede usar las mecánicas que ya existen (separarse, quedar inconsciente, desaparecer sin señal, un accidente o una decisión con forma de accidente), pero **nunca agrega otra forma de perder, nunca mata a un amigo y nunca cambia qué criatura llega ni qué acción es la correcta**. Las cinemáticas opcionales quedan para la intro y el final.

## 2. Cómo funciona

- **La llamada grupal:**
  - **solo con los 3 juntos y sin nada que jugar** (propuesta de Claude, sin objeción de Benja);
  - las 3 entradas del PC la abren y muestran el ícono;
  - cada línea lleva el nombre de quien habla, en su color, y suena con su voz;
  - la estática de cada línea depende de la señal de quien habla, y un amigo sin señal llega tapado;
  - arriba están las barritas de los 3, y cada una abre el mixer en su canal;
  - **si llega una consulta, un accidente, una decisión o un video, la llamada se separa en los 3 chats.** Mezclar 2 o 3 consultas en una conversación sería imposible, porque cada una depende del chat de su amigo (preguntas, hojas, temporizador, señal y descarga). Cuando ya no queda nada abierto y siguen juntos, la llamada vuelve, con lo que se habló antes.
- **Cuándo llega la historia:**
  - al empezar la noche (el minuto de silencio: la intro del vlog);
  - al terminar una ola;
  - 15 s antes de la siguiente (el build-up, que además avisa que viene una ola);
  - después de la ola final (el cierre);
  - cuando pasa algo, por ejemplo cuando se responde una decisión.

  **Nunca en medio de una ola**, salvo las decisiones. En Extremo, que tiene más olas, los momentos se anclan a la primera ola, a la última ola común y a la final; las del medio no tienen historia.
- **Los mensajes de historia** marcan el chat como no leído, **sin alarma** (la alarma sigue siendo solo para lo que se juega). Son cortos y leerlos es opcional.
- **Las decisiones** llegan como un accidente: con alarma, 15 s y sus opciones. No contestar cuenta como la peor.
- **La historia nunca mata:** un daño de la historia, como el de un accidente, no le quita vida a un amigo que tiene 1.
- **Las consultas no cambian:** la criatura y el lugar siguen saliendo al azar. Cada criatura nueva de la noche sale al menos una vez, y **solo se fuerza cuando hace falta:** si quedan tantas consultas como criaturas nuevas que todavía no salieron, las que quedan son esas. Así siguen siendo casi igual de probables (sin esto, en la noche 2 de Normal el Cuero faltaría en un 18 % de las noches).
- **En la historia se nombra a las criaturas** ("dicen que acá penan el Tue Tué y la Calchona"): es un vlog sobre ellas. En las consultas los amigos siguen sin decir el nombre. **La historia no usa las frases de las características** ("cara de persona", "neblina helada"), para no confundirlas con pistas.
- **Cuando están juntos,** la consulta no usa "Me perdí" ni "Me separé de los demás" (`PREDICAMENT_1` y `_4`).

## 3. Personajes y canal

El canal se llama **Acá Penan**, y cada noche es un capítulo.

| Personaje | Rol | Cómo escribe |
| --- | --- | --- |
| León | El presentador: carismático y bromista, molesta a los demás. Termina traicionándolos (noches 4 y 5). | Suelto, con "!!" y "Jajaja" |
| Gonzalo | El líder: práctico, serio y medio gruñón. Decide a dónde van y piensa en el canal. | Poco y pausado, con frases cortas |
| Agustín | El miedoso: nervioso, arranca cuando se asusta. Es el alivio cómico. | Rápido, con frases cortas seguidas |
| Matías | El experto desde la base. No sale en cámara, pero lo nombran. Le dicen Mati. | — |

Estilo, como escribe Benja: sin ¿ ni ¡ al principio y sin punto al final del último mensaje.

## 4. Noche 1 · La cabaña del campo (aprobada)

Llegan juntos, algo los asusta y se separan: Gonzalo en la cabaña, León en el establo y Agustín en el bosque. Antes de la ola final, Matías los ayuda a reunirse en la cabaña.

| Momento | Quién | Texto | Efecto en el juego |
| --- | --- | --- | --- |
| 00:00 · llamada grupal | León | Holaaa a todos y bienvenidos a Acá Penan!! | Empiezan juntos |
| | León | Hoy vamos a una cabaña en medio del campo, donde dicen que penan el Tue Tué y la Calchona | |
| | Gonzalo | Y desde la base nos ayuda nuestro experto, el Mati | |
| | Agustín | hola Mati sisi bacán ok. ya, grabemos rápido y nos vamos | |
| | León | Jajaja el Agus ya se quiere ir y todavía ni llegamos | |
| 15 s antes de la ola 1 · llamada grupal | Agustín | ???? qué fue eso | |
| | León | Un peo lol | |
| | Agustín | No imbécil, algo pasó volando arriba del techo | |
| | Gonzalo | Era un pájaro, Agustín | |
| | León | LOCO ESO NO ERA UN PÁJARO | |
| | Agustín | Ah chao yo me voy a la cresta | |
| | Gonzalo | Escóndanse!! Nos reunimos en la cabaña!! | Termina la llamada: se separan |
| Al separarse · cada uno en su chat | Gonzalo | Estoy adentro de la cabaña. Desde la ventana se ve todo el campo | |
| | León | Me metí al establo. Huele a caballo, pero no hay ningún caballo | |
| | Agustín | Corrí por el camino de tierra y llegué al bosque. Mati no me dejes solo | |
| Al terminar la ola 1 | León | Ya, mientras tanto les muestro el establo. Hay monturas viejas y un libro de 1987 | |
| | León | Random igual el libro, dejen un comentario si apoyan la alfabetización del ganado | |
| | Gonzalo | Grabé la cocina. Hay platos recién servidos pero nadie cerca | |
| | Agustín | Estoy todo despersonalizado amigos es como que estoy viendo mi propia película de terror found footage | |
| | León *[semilla]* | Mati, me hablaste? Escuché mi nombre | |
| 15 s antes de la ola 2 | Gonzalo | Algo está caminando en el techo | |
| | León | Se apagó la ampolleta del establo, no encuentro la salida | |
| | Agustín | algo se mueve entre los árboles. Se mueve cuando yo me muevo. Voy a tener que correr más rápido. MATI, MANDA AYUDA POR FAVOR!! | |
| Al terminar la ola 2 · reunirse | Gonzalo | Ya, esto se está poniendo feo. Mati, asegúrate de que todos lleguen bien a la cabaña | |
| | Gonzalo | Prendí la luz del pórtico pa que me encuentren. Es amarilla y está fijada al marco de la puerta | |
| Decisión de León (alarma, 15 s) | León | Salí del establo. Veo tres luces, una amarilla y dos blancas que se mueven rápido y juntas. A cuál voy?? | Ver la tabla de la decisión de León |
| | León (va a la amarilla) | Llegué a la cabaña. Estoy con el Gonza, gracias Mati | |
| | León (va a las blancas) | Llegué donde el Agus y lo ayudé a escapar. Vamos a la cabaña ahora | Agustín decide con León (plural) |
| | León (sin respuesta) | No me contestaste y grité por ayuda. Algo me empezó a perseguir, estoy agotado | Igual que "Grita y ve de dónde responden" |
| Decisión de Agustín (alarma, 15 s; después de la de León) | Agustín | Solo: Mati, creo que esta cosa me va a alcanzar antes de que llegue a la cabaña. Qué hago? · Con León: Mati, creo que esta cosa nos va a alcanzar antes de que lleguemos a la cabaña. Qué hacemos? | ✓ Esconderse · ✗ Correr |
| | Agustín (acierto) | Solo: "Pasó de largo, no me vio!!" y después "llegué!! llegué. gracias Mati" · Con León: "Pasó de largo, no nos vio!!" y después "llegamos!! gracias Mati" | |
| | Agustín (error) | Solo: Me alcanzó!! Estoy sangrando Mati, si me muero te voy a penar · Con León: Nos alcanzó!! Mati, si nos morimos te vamos a penar | Trust −10 y daño a Agustín. Si está con León, el daño es para el que tenga más vida |
| | Agustín (sin respuesta) | Solo: "No contestaste y corrí" y el texto del error · Con León: "No contestaste y corrimos" y el texto del error | Igual que el error |
| Cuando llegan · llamada grupal | Gonzalo | Ya estamos todos. Nadie se separa más | Juntos otra vez |
| | Agustín | Pensé que me estaban siguiendo... | |
| | León | Al bosque...? Jajaja | |
| 15 s antes de la ola final | León | Mati… hay algo dando vueltas a la cabaña | |
| | Gonzalo | Apaguen las linternas | |
| | Agustín | está en todas las ventanas a la vez | |
| Después de la ola final · llamada grupal | León | Y eso fue todo por hoy en Acá Penan!! | |
| | Gonzalo | Sobrevivimos al Tue Tué y a la Calchona, apenas. No vayan a decirnos que es IA | |
| | Agustín | dale like si quieres que no volvamos nunca más | |
| | León | Gracias Mati!! Nos vamos a la base | |

**La decisión de León** (diseño de Benja). Las dos luces blancas que se mueven juntas son la linterna de Agustín, que arranca. Hay 2 opciones buenas, cada una con su costo, y 2 malas:

| Opción de Matías | Qué pasa | Efecto (los valores son de partida) |
| --- | --- | --- |
| ✓ Anda a la amarilla | León llega a la cabaña; Agustín queda solo | La próxima consulta de Agustín, 10 s menos |
| ✓ Anda a las blancas | León rescata a Agustín y siguen juntos | La próxima consulta de León, 10 s menos, y Trust −10 |
| ✗ Vuelve al establo y espera ahí | — | Trust −20 y la próxima consulta de los 3, 10 s menos |
| ✗ Grita y ve de dónde responden | — | Igual que la anterior |
| Sin respuesta | León grita y algo lo persigue | Igual que la anterior |

Benja escribió "baja bastante Trust" y "le quita tiempo"; los −20, −10 y 10 s son de Claude, para probar. Benja había propuesto 3 s; Claude propuso 10, porque 3 s sobre 90 no se notan.

**Lo que había que resolver en el plan** (resuelto en S21l, `docs/31`): la final espera a las decisiones, a lo más 45 s (decisión de Benja); el daño y el aturdimiento son los de un accidente; y las respuestas de León a las 2 opciones malas, que el guion no tenía, son borradores de Claude en `messages.csv` (`STORY_N1_LEON_STABLE_REPLY` y `_SHOUT_REPLY`), igual que las de Matías a Agustín ("Escóndete" y "Corre"; con León, "Escóndanse" y "Corran").

- **Las dos decisiones van una después de la otra,** porque la de Agustín depende de si León fue con él. Con los mensajes, son unos 40 s. En Extremo, la calma antes de la final es de 20 a 30 s: el plan tiene que decidir si la final espera a que terminen o si las decisiones se acortan.
- **El daño del error de Agustín** sigue la regla de que la historia nunca mata: no le quita vida a quien tiene 1. Si están juntos, el daño es para el que tenga más vida; si los dos tienen 1, a ninguno.
- **Si un amigo está aturdido o sin señal cuando le toca decidir,** la decisión espera, como un accidente.

## 5. Noche 2 · El sendero del lago (pospuesta)

Borrador de Claude, **sin revisar por Benja**: no se implementa hasta que lo apruebe. Los textos están en el documento compartido. El resumen:

- **Intro, juntos:** el sendero que bordea el lago, donde "en el agua vive el Cuero" y "por los caminos anda la Viuda".
- **Antes de la ola 1:** algo se mueve en el agua y Agustín arranca al bosque. León lo sigue y Gonzalo se queda en el sendero. Claude propuso cambiar la neblina helada de la idea de Benja, porque es la característica `TRAIT_ICY_MIST` del Cuero y de La Viuda (por confirmar).
- **Ola 1:** Agustín queda inconsciente, sin consultas ni accidentes. León lo encuentra y Matías lo guía para curarlo: una decisión en el chat de León, que es el accidente de la noche. Si falla, Agustín pierde 1 de vida.
- **Al terminar la ola 1:** Agustín despierta y no recuerda cómo se cayó (*[semilla]*: "León, tú venías detrás mío cuando me caí?").
- **Ola 2:** Gonzalo va a ver algo en el muelle y **se queda sin señal**. Encontrarlo es sincronizarlo. Si llega la calma antes de la final y sigue sin señal, León dice que lo encontraron pero que su celular no conecta.
- **Ola final, juntos,** y el cierre del vlog.

## 6. Noches 3 a 5 (esquema)

Solo las ideas de Benja; los textos se escriben después de probar las noches 1 y 2.

| Noche | Lugar | Criaturas nuevas | Ideas de Benja | Por decidir |
| --- | --- | --- | --- | --- |
| 3 | El bosque | El Trauco | Se quedan atrapados o caen en una trampa | Quién cae, cómo salen y con qué mecánica |
| 4 | La casa abandonada | El Basilisco (y el Imbunche, según el diseño §14) | León los traiciona y no se dan cuenta | Qué hace León sin que lo noten, sin falsear pistas |
| 5 | La cueva del Imbunche | — | León los traiciona y se dan cuenta. El Imbunche es especialmente fuerte y tiene una **opción LETAL**, además de la calavera, que mata al instante. Antes del encuentro: "Mati, yo creo que esa wea nos toca y cagamos. Mantennos lejos de eso" (tal cual) | Si el Imbunche pasa de la noche 4 a la 5. La opción letal cambia una regla de la entidad, no la historia: propuesta de Claude, que sea siempre la misma acción en todas las filas y que el cuaderno la marque distinto de la calavera |

## 7. Lo que necesita la implementación (para el plan)

Implementado en S21l (Plan 9.7, `docs/31`), salvo lo de la noche 2, al final de esta sección.

| Pieza | Qué hace | Base que ya existe |
| --- | --- | --- |
| Guion de la noche | Los momentos de la historia como datos de la noche (`.tres`), con sus líneas en `messages.csv` | `ChatScriptData`, `ChatLineData` y `NightData.scripted_chat` |
| Disparadores | Al empezar, al terminar una ola, 15 s antes de la siguiente, después de la final y al responder una decisión | `PacingDirector` (fases y `next_at`) |
| Llamada grupal | El chat como llamada cuando están juntos, con quién habla en cada línea, su ícono (pixel art de Claude en `art/ui/`) y la separación automática | `ChatPanel`, que hoy tiene una pestaña por amigo |
| Juntos o separados | Estado de la historia por amigo; los "predicaments" de un amigo solo se filtran | `RequestGenerator` |
| Decisión de la historia | Como un accidente, con opciones que pueden dar 2 aciertos, bajar Trust y restar segundos a la próxima consulta de un amigo | `IncidentData` y `FriendIncident` |
| Texto según otra decisión | Las líneas de Agustín cambian si León fue con él | — |
| Criaturas nuevas al menos una vez | Forzar solo cuando faltan | `RequestGenerator.generate()` |
| Equilibrio | La prueba de los 3 modos cuenta las decisiones y sus castigos | `test/balance_model.gd` y `test_balance.gd` |

Para la noche 2 (cuando se apruebe): un amigo inconsciente (sin consultas ni accidentes), una decisión que daña a otro amigo, y cortar la señal de un amigo a propósito.

## 8. Alcance

El lore pasa a la v1 como el punto **10ter** de `docs/05`, en este orden: el sistema y la noche 1 primero; la noche 2 cuando Benja la apruebe, y las noches 3 a 5 después de probar. **Si falta tiempo,** el mínimo es la intro y el cierre del vlog en la llamada grupal de cada noche, sin decisiones. Las cinemáticas quedan en prioridad 2, solo la intro y el final.
