# Bucle central: solicitudes, reglas y señal

Detalle de la mecánica central del diseño v2 (`spook_dial_design.md` §8–§10). Actualizado el 26 de octubre de 2026:

- la identificación ahora es por características clickeables;
- ya no existe la acción "Grabar": el video extra viene de la acción de mayor riesgo;
- la cuota la cubren los envíos programados;
- (sesión 8) el mensaje inicial trae 2 características camufladas entre señuelos, hay una barra con el avance de la identificación, la estática tapa una frase entera o nada, y con 5 s o menos no se puede preguntar;
- (sesión 10) cuando a un amigo le llega una solicitud nueva, su página del cuaderno vuelve al índice, y la frase entre asteriscos de una característica también es su nombre en el cuaderno;
- (sesión 12) el video de un amigo aturdido llega cuando se recupera. Después de probar el juego: los textos son borradores reales en primera persona (ya no se usa `[PROTO]`), cada mensaje lleva el nombre de quien escribe, y el amigo herido grita en el chat, seguido de un aviso rojo con su vida;
- (sesión 14) un amigo sin señal sigue recibiendo situaciones, pero no lee las respuestas y, si se le acaba el tiempo, elige mal; mientras haya amigos sin señal, Trust baja. Los videos se descargan en el chat (15 s para empezar, 20 s para terminar y 10 s de descarga), y Audio Sync se juega en una vista del mixer desde arriba (§4.1 y §6).
- (sesión 16) el director reparte las solicitudes en olas con respiro (§2), los screamers llegan en cualquier momento con sus reglas de justicia, y con Sanity bajo suenan alucinaciones que no restan Sanity (§6).
- (sesión 17, a pedido de Benja el 3 de noviembre) **la entidad se identifica preguntando:** el mensaje inicial solo saluda, dice el lugar y a veces trae una pista; las características, los señuelos y las observaciones salen al preguntar. Por eso cada solicitud tiene más tiempo y cada noche trae menos solicitudes (§2, §3 y §6).
- (S21h, tras el primer testeo, 11 de noviembre) una pregunta ya respondida no se repite, salvo que la estática haya tapado algo que sirve de su respuesta; las observaciones van en azul; "Matías piensa" dura 2 s, y los señuelos ya no cuestan (§3).

Los valores numéricos (§6) son un punto de partida para el prototipo; se ajustan probando.

---

## 1. Qué pone a prueba el juego

- **Aplicar reglas bajo presión**, al estilo Keep Talking. El desafío está dentro de la página del cuaderno: leer qué observa el amigo y aplicar la regla correcta antes de que se acabe el tiempo.
- **Identificar preguntando, sin depender de la memoria.** Los amigos nunca dicen el nombre de la entidad, y de entrada tampoco la describen: piden ayuda y hay que sacarles la información con las preguntas correctas, que cuestan tiempo. Quien reconoce a la entidad va directo a su página; quien no, clickea las características que le cuentan y espera unos segundos.
- **Manejar información degradada.** Con poca señal, la estática tapa palabras: características que ya no se pueden clickear u observaciones que deciden la regla.
- **Repartir la atención** entre 3 amigos, la señal, Sanity y los videos.

---

## 2. Ciclo de vida de una solicitud

1. **El director de ritmo** decide que un amigo disponible recibe una situación. Disponible significa vivo, sin otra solicitud y no aturdido. Un amigo sin señal también recibe situaciones (decisión de Benja, sesión 14; ver §4.1).
   - **Olas de verdad** (decisión de Benja, 11 de noviembre; reemplaza a las olas con respiro del 2-nov):
     - el primer minuto es de silencio, y la primera ola llega a los 60 s;
     - las solicitudes de una ola (2) llegan con 4 a 8 s de diferencia;
     - cuando se resuelven todas, empieza una calma de 40 a 60 s. Las olas están planeadas parejo entre los 60 s y la ola final, así que si una ola se resuelve rápido, la calma dura hasta la hora de la siguiente;
     - la **ola final**, de 3 (los 3 amigos a la vez), llega a `06:00 − tiempo para responder − 2 × 8 s − 10 s`, para que su última solicitud alcance a terminar aunque lleguen con el mayor espacio y aunque un amigo quede herido antes;
     - una ola común que empezaría a menos de 40 s de la final se salta, con las que siguen. Si la final llega con una ola sin resolver, empieza igual.
   - **Qué cae en cada momento:** en las olas, las interferencias (las que sobran, hacia el final), los accidentes (en las comunes, los que sobran hacia el comienzo) y la Mano (en las comunes, las que sobran hacia el final), de 3 a 15 s después de empezar la ola. En las calmas, los videos (si es la última calma, todos los que faltan) y los screamers, desde 5 a 15 s después de empezar la calma. Un video de una calma llega a más tardar 25 s antes de la ola siguiente. Una visita de la criatura llega en la ola final.
   - Si no hay a quién darle una solicitud (todos ocupados o aturdidos, o ya están las simultáneas de la noche), espera. Cuando un amigo queda herido, lo que falta se atrasa 10 s.
   - Nunca empieza una solicitud que no alcanza a terminar antes de las 06:00, y con "Temporizadores ×1,5" su tiempo no pasa de las 06:00: por eso el total de la noche es aproximado.
2. **Se generan los datos de la situación:**
   - la entidad, entre las conocidas en esa noche;
   - el lugar, el saludo, lo que le pasa al amigo y si el mensaje dice el lugar;
   - con qué forma dice el amigo cada característica;
   - un valor al azar para cada observación de esa entidad;
   - las 2 características, los señuelos y si el mensaje inicial trae pista.
3. **Se arma el mensaje inicial** (decisión de Benja, 3-nov): corto, sin describir a la entidad. Con fragmentos de texto:
   - un **saludo** al azar entre los del catálogo ("¡Mati, ayuda!!", "¿Estás ahí?", "Mati… algo pasó.");
   - **lo que le pasa** al amigo, al azar entre los del catálogo ("Me perdí.", "Algo me viene siguiendo."; decisión de Benja, 11 de noviembre);
   - **a veces**, el lugar ("Estoy en el bosque."), según la probabilidad de la noche (§6);
   - a veces, una **pista**: una de las 2 características, clickeable (probabilidad según la noche, §6).

   Todo lo demás se **pregunta** (§3). Lo que la solicitud tiene escondido, y que el amigo cuenta al preguntar:
   - **2 características** que distinguen a la entidad entre las conocidas (ninguna otra entidad conocida tiene las dos);
   - **señuelos** del lugar (cuántos, según la noche, §6), que las camuflan;
   - **todas las observaciones** de la entidad, cada una con un valor al azar.
4. **Se aplica la estática** según la señal del amigo (§4).
5. **Empieza el temporizador:** tiempo base de la noche × factor de Trust (§6).
6. **El jugador** pregunta y identifica (§3), abre la página, pregunta lo que le falta para aplicar las reglas y responde (§5).
7. **Se resuelve** la consecuencia (§5.2) y llega la reacción del amigo. Si eligió la acción de mayor riesgo y el amigo sobrevivió, se programa un video extra.
8. **Sin respuesta:** el amigo elige al azar entre las 4 acciones, se resuelve igual y baja Trust. Si está sin señal, elige mal y Trust no baja por esa decisión (§4.1).
9. **Si el amigo muere:** pantalla de derrota con la entidad, las observaciones, la regla que aplicaba y la acción correcta. Luego se reinicia la noche.

---

## 3. Identificar y preguntar

### 3.1 Características clickeables

- El mensaje inicial casi no trae nada que clickear: a veces una **pista** (una de las 2 características). Las demás frases clickeables salen **al preguntar** (§3.2).
- Las características y los señuelos que el amigo cuenta se ven destacados igual, en amarillo. Al clickear una característica, queda marcada; al clickear un señuelo, vibra y se pone rojo, **sin costo** (decisión D4 de Benja tras el primer testeo, que reemplaza el "−1 s" del 11 de noviembre).
- Las **observaciones** van en azul y no se clickean: deciden la fila de la tabla. El audio también va en azul (`ChatMessage.Token.is_observation`, que marca `MessageBuilder.answer()`).
- **Cada característica se dice de varias formas** (decisión de Benja, 11 de noviembre): además de su texto, tiene de 2 a 4 variantes con sinónimos y paráfrasis. Cada solicitud elige una al azar para cada característica y la usa siempre, también en la pista. El clic la marca igual, y el cuaderno muestra un nombre fijo.
- Los **señuelos** describen el lugar, un olor, un sonido o algo que se ve, y no ayudan a identificar. Viven en el catálogo, cada uno con su categoría y los lugares donde sirve (o en cualquiera).
- Una barra fija, sobre las preguntas, muestra cuántas características van marcadas ("1 de 2"; desde el principio dice "0 de 2").
- Con **las 2** marcadas (en cualquier mensaje de esa solicitud), la barra dice "Matías piensa…" durante **2 segundos** (`thinking_seconds` en `BalanceData`; eran 3 hasta el primer testeo) y aparece el nombre de la entidad. Clickear el nombre abre su página en el cuaderno.
- Si una característica está tapada por la estática, no se puede marcar: hay que volver a preguntar su categoría (§3.2) para que vuelva a aparecer.
- Quien reconoce a la entidad de memoria puede saltarse todo esto y abrir la página desde el índice.
- **En Difícil no hay nada de esto** (decisión D3 de Benja tras el primer testeo): las características, los señuelos, la pista y las observaciones van como el resto del texto y sin enlaces, y no hay barra ni "Matías piensa". Se lee y se abre la página desde el índice. El audio sigue en azul y se clickea, y el cuaderno no cambia (decisiones de Benja en S21i). Lo decide `DifficultyData.highlights`, que el chat lee con `RequestManager.highlights()`.

### 3.2 Preguntas

Preguntar es la forma de averiguar casi todo (decisión de Benja, 3-nov). Hay una pregunta por categoría:

| Pregunta | Qué cuenta el amigo |
| --- | --- |
| ¿Qué ves? | Las características, los señuelos y las observaciones de categoría Vista |
| ¿Qué oyes? | Los de Sonido |
| ¿Cómo está el ambiente? | Los de Ambiente |
| ¿Hay rastros? | Los de Rastro |

- La respuesta trae las características y los señuelos de esa categoría (también la pista del mensaje inicial, si es de esa categoría) y **todas** las observaciones de esa categoría.
- Qué preguntar es la decisión del jugador. Antes de identificar a la entidad, la pregunta correcta es la categoría donde puede estar una característica; después, la categoría de la observación que pide la regla. Desde el 11 de noviembre, la página del cuaderno ya no dice qué pregunta trae cada característica ni lista las observaciones: la condición de cada fila de la tabla dice qué hay que averiguar, y elegir la pregunta es parte de pensar (decisión de Benja).
- Cada pregunta descuenta **5 segundos** del temporizador (`question_cost` en `BalanceData`), y su botón lo muestra ("−5 s"). Con 5 s o menos ya no se puede preguntar: los botones se desactivan.
- **Una pregunta ya respondida no se repite** (tras el primer testeo): `FriendRequest` guarda cada categoría preguntada y si la estática tapó algo que sirve de su respuesta (`ChatMessage.lost_information()`: una frase clickeable, una observación o el audio; en la respuesta de "nada", cualquier palabra). Solo entonces se puede volver a preguntar.
- Si no hay nada en esa categoría, el amigo responde "nada", que también es información.
- Las respuestas pasan por la misma estática que los mensajes, y volver a preguntar tira la estática de nuevo.

---

## 4. Estática

Cada palabra de un mensaje del amigo se tapa (▒▒▒) con una probabilidad que depende de su señal:

| Señal del amigo | Palabras tapadas |
| --- | --- |
| 70 a 100 | 0 % |
| 50 a 69 | 10 % |
| 30 a 49 | 25 % |
| 1 a 29 | 45 % |
| 0 (sin señal) | 100 % |

- Las características y las observaciones se tapan con la misma probabilidad que cualquier palabra.
- Una frase clickeable (característica o señuelo) cuenta como una sola palabra: se tapa entera o no se tapa. Los espacios y los signos sueltos nunca se tapan.
- El tamaño del ▒▒▒ no revela cuántas letras tenía la palabra tapada.

### 4.1 Un amigo sin señal (decisión de Benja, sesión 14)

Con la señal en 0, el amigo queda desconectado:

- le siguen llegando situaciones, pero su mensaje llega tapado entero y no lee las preguntas ni las respuestas de Matías;
- decide cuando se le acaba el tiempo, no al llegar. Si Matías lo reconecta antes con Audio Sync, se puede preguntar (las respuestas llegan legibles) y responder como siempre;
- si decide sin señal, elige al azar una de las 3 acciones que no son la correcta. El daño es el de siempre, y esa decisión no baja Trust;
- mientras haya amigos sin señal, Trust baja 1 punto cada 4 s por cada uno y no se recupera;
- no envía videos: el suyo llega cuando se reconecta, como el de un amigo aturdido;
- si los 3 quedan sin señal, Connection llega a 0 y se pierde la noche.

---

## 5. Responder

### 5.1 Acciones de cada entidad

- Cada entidad tiene **4 acciones propias**, con el sabor de su leyenda.
- Los botones de respuesta del chat muestran las acciones de **la página abierta en el cuaderno para ese amigo**. Si no hay ninguna abierta, el chat dice "Abre el cuaderno para responder".
- Cuando a un amigo le llega una solicitud nueva, su página del cuaderno vuelve al índice (decisión de Benja, 30-oct).
- Cada regla de la página marca la **acción correcta** y la **acción de mayor riesgo**. Las otras dos son incorrectas en esa situación.

### 5.2 Consecuencias

| Elección | Daño | Trust | Contenido |
| --- | --- | --- | --- |
| Acción correcta (según la regla que aplica) | — | 0 | — |
| Acción de mayor riesgo | 70 %: −2 PV | −20 | +1 video si sobrevive |
| Acción incorrecta (incluye responder desde la página equivocada) | 60 %: −1 PV | −10 | — |
| Sin respuesta | El amigo elige al azar y se resuelve igual | −15 extra | Según lo que elija |
| Sin respuesta y sin señal (§4.1) | Elige al azar entre las 3 que no son la correcta | Sin cambio | Según lo que elija |

- Cada amigo tiene **3 PV por noche**. Al quedar herido, está **aturdido 15 s**. Con 0 PV muere y se pierde la noche.
- Un amigo aturdido no envía nada: si le tocaba enviar un video (programado o el extra), lo envía apenas se recupera (decisión de Benja, 31-oct).
- Cuando queda herido, el amigo grita en el chat y el juego avisa en rojo y centrado cuánta vida le queda: "León recibió daño: 2/3" (decisión de Benja, 31-oct; llega con el Plan 5).

---

## 6. Valores iniciales para el prototipo

Los valores que valen para todas las noches y los dos modos están en `data/balance.tres` (`BalanceData`). Los de cada noche están en `data/nights/hard/night_N.tres` (Difícil) y `data/nights/normal/night_N.tres` (Normal), y la noche 0 en `data/nights/night_0.tres` (`NightData`). Cada modo es un `DifficultyData` (`data/difficulty/normal.tres` y `hard.tres`) con sus 5 noches. Se ajustan en el Inspector.

### Por noche, en Difícil

Son los valores de antes del primer testeo.

| Parámetro | N1 | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- | --- |
| Solicitudes por noche (aprox.) | 7 | 7 | 9 | 9 | 11 |
| Solicitudes simultáneas máx. | 3 | 3 | 3 | 3 | 3 |
| Tiempo base para responder (s) | 80 | 65 | 55 | 50 | 45 |
| Probabilidad de que el mensaje inicial diga el lugar (noche 0: siempre) | 60 % | 55 % | 50 % | 45 % | 40 % |
| Probabilidad de pista en el mensaje inicial | 100 % | 75 % | 0 % | 0 % | 0 % |
| Señuelos por solicitud | 1 | 2 | 3 | 3 | 4 |
| Accidentes por noche | 1 | 1 | 2 | 2 | 3 |
| La señal baja | Sí | Sí | Sí | Sí | Sí |
| Interferencias (aprox. por noche) | 1 | 3 | 3 | 4 | 6 |
| Audio Sync (aplausos; 8 son 2 rondas de 4) | 4 | 4 | 4 | 8 | 8 |
| Audio Sync (golpes por minuto de la base) | 90 | 100 | 115 | 130 | 145 |
| Cuota de videos (= envíos programados) | 2 | 3 | 3 | 4 | 4 |
| Solicitudes por ola común | 2 | 2 | 2 | 2 | 2 |
| Solicitudes de la ola final (los 3 amigos a la vez) | 3 | 3 | 3 | 3 | 3 |
| Screamers (sin contar las alucinaciones) | 2 | 4 | 4 | 5 | 6 |
| Cuántos de ellos son la criatura de la ventana (el antiguo jumpscare) | 0 | 1 | 2 | 2 | 3 |
| Visitas de la Mano (la noche 0 la enseña aparte) | 1 | 1 | 2 | 2 | 3 |
| Batería que pide jugando bien (flashes y Sanity; `test_balance.gd`) | 10 % | 31 % | 57 % | 61 % | 90 % |
| Susto guionado (va en la noche 0 cuando exista) | A los 60 s | — | — | — | — |

### Por noche, en Normal

Es una curva más suave (decisiones de Benja tras el primer testeo, 11 de noviembre; `docs/26` §3.3). Son valores de partida que propuso Claude: `test_balance.gd` comprueba que toda noche de los dos modos se puede ganar, y Benja los ajusta en las pruebas (S22).

| Parámetro | N1 | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- | --- |
| Solicitudes por noche | 5 (plan) | 6 | 7 | 8 | 9 |
| Tiempo base para responder (s) | 90 | 80 | 70 | 65 | 60 |
| Probabilidad de que diga el lugar | 80 % | 75 % | 70 % | 65 % | 60 % |
| Probabilidad de pista en el mensaje inicial | 100 % | 100 % | 75 % | 50 % | 35 % |
| Señuelos por solicitud | 1 | 1 | 2 | 2 | 3 |
| Accidentes por noche | 0 | 1 | 1 | 2 | 2 |
| Interferencias | 1 (plan) | 2 | 2 | 3 | 4 |
| Audio Sync (aplausos) | 4 | 4 | 4 | 4 | 8 |
| Audio Sync (golpes por minuto) | 90 | 95 | 105 | 115 | 125 |
| Cuota de videos | 2 | 2 | 3 | 3 | 4 |
| Solicitudes de la ola final | 2 (plan) | 2 | 2 | 3 | 3 |
| Screamers | 2 | 4 | 4 | 5 | 6 |
| Visitas de la criatura | 0 | 1 | 1 | 2 | 2 |
| Visitas de la Mano | 1 (plan) | 1 | 1 | 2 | 2 |
| Batería que pide jugando bien (`test_balance.gd`) | 10 % | 31 % | 31 % | 61 % | 65 % |

Lo demás (olas de 2, 3 solicitudes a la vez, la señal que baja y Sanity) es igual que en Difícil.

### Por noche, en Extremo

Más exigente que Difícil en cada noche (pedido de Benja, 12 de noviembre; `docs/30`). Se desbloquea al terminar Difícil y se gana jugando como experto (11 s por consulta en el modelo de "jugar bien").

| Parámetro | N1 | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- | --- |
| Solicitudes por noche | 11 | 13 | 13 | 15 | 15 |
| Tiempo base para responder (s) | 45 | 42 | 40 | 40 | 38 |
| Calma entre olas (`wave_calm`) | 20 a 30 s | 20 a 30 s | 20 a 30 s | 20 a 30 s | 20 a 30 s |
| Probabilidad de que diga el lugar | 40 % | 35 % | 30 % | 25 % | 20 % |
| Probabilidad de pista | 0 % | 0 % | 0 % | 0 % | 0 % |
| Señuelos por solicitud | 3 | 3 | 4 | 4 | 4 |
| Accidentes | 2 | 2 | 3 | 3 | 4 |
| Interferencias | 4 | 5 | 6 | 7 | 8 |
| Audio Sync (aplausos) | 8 | 8 | 8 | 8 | 8 |
| Audio Sync (golpes por minuto) | 115 | 125 | 135 | 145 | 150 |
| Cuota de videos | 3 | 3 | 4 | 4 | 4 |
| Screamers | 4 | 5 | 5 | 6 | 6 |
| Visitas de la criatura | 1 | 2 | 2 | 3 | 3 |
| Visitas de la Mano | 2 | 2 | 2 | 3 | 3 |
| Batería que pide jugando bien | 41 % | 61 % | 61 % | 90 % | 90 % |

Lo demás: olas de 2 y la final de 3, 3 solicitudes a la vez, la señal que baja y Sanity −1 cada 6 s. Además, los castigos de la dificultad (`DifficultyData`, grupo **Castigos**):

- **Trust por error ×1,5** (`error_trust_scale`): incorrecta −22,5, mayor riesgo −30, sin respuesta −22,5 más y video perdido −15. Tardar en contestar no cambia.
- **Un amigo al azar empieza cada noche con 1 de vida** (`wounded_friends` y `wounded_health`), y su chat lo avisa al empezar (`CHAT_WOUNDED_START`). Los accidentes no le tocan.

**La noche 1 de Normal va armada a mano** con un plan de olas (`NightData.wave_plan`, una lista de `WaveData`; decisión de Benja, `docs/26` §3.2). Con un plan, las solicitudes, las olas, los accidentes, las interferencias, la Mano y los screamers salen del plan, y esos campos de la noche no se usan:

| Ola | Llegadas | Separación | Calma antes | En la ola | Screamers en la calma que sigue |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 consulta y 1 video | — | 45 s (desde las 00:00) | — | 1 |
| 2 | 2 consultas | 30 a 45 s | 30 a 45 s | 1 Mano y 1 interferencia | 1 |
| Final | consulta, video y consulta | 30 a 45 s | — | — | — |

- Las llegadas de una ola se alternan: consulta, video, consulta.
- Un video llega cuando a la consulta anterior le quedan 30 s (`video_time_left`) o, si ya no queda ninguna abierta, 3 a 6 s después (`video_after_answer`).
- La última ola del plan es la final y llega lo más tarde posible para que su última consulta termine antes de las 06:00: en la noche 1 de Normal, a las 03:04.
- Los videos del plan tienen que sumar la cuota (lo revisa `test_catalog.gd`).

### Medidores

| Medidor | Inicio | Baja | Sube | Efecto gradual | En 0 |
| --- | --- | --- | --- | --- | --- |
| Señal (cada amigo) | 100 | Entre −1 cada 3 s y −1 cada 6 s: a cada amigo le toca un ritmo al azar en ese rango. Interferencia: −40, anunciada 3 s antes. La Mano en Connection: −6 por segundo a cada uno, hasta 15. | Audio Sync exitoso: vuelve a 100 | Estática (§4). Descargas más lentas bajo 50. | Ese amigo queda sin señal (§4.1) |
| Connection (dial) | — | Es el promedio de las 3 señales | — | — | Se pierde la noche |
| Sanity | 100 | −1 cada 6 s (N1: cada 10 s). Screamer: −8 ambiental, −15 la criatura de la ventana. Cortinas cerradas: −0,3 por segundo más. Criatura afuera con la cortina abierta: −2 por segundo más. La Mano: −6 por segundo hasta 15. | +4 por segundo mientras scrolleas, con batería (48 s de scroll por noche, sin recarga; cada flash gasta 10 %) | Viñeta oscura y screamers auditivos falsos, más fuertes cuanto más baja | Se pierde la noche |
| Trust | 100 al empezar cada noche | Ver §5.2 (incorrecta −15, sin respuesta −15 más, mayor riesgo −20). Video perdido: −10. Con amigos sin señal, −1 cada 4 s por cada uno (§4.1). Cada solicitud abierta más de 30 s: −0,25 por segundo (45 s con "Temporizadores ×1,5"; decisión de Benja, 4 de noviembre). La Mano: −6 por segundo hasta 15. | No se recupera durante la noche (decisión de Benja, 11 de noviembre) | Temporizador × (0,6 + 0,4 × Trust/100) | Se pierde la noche |
| Vida (cada amigo) | 3 PV | Ver §5.2. Accidente mal respondido o sin respuesta: −1 PV, sin bajar Trust. | No se recupera durante la noche | Avatar herido | Muere y se pierde la noche |

### Otros

- Preguntar: 5 s (`question_cost` en `BalanceData`). Un señuelo no cuesta.
- **Por qué hay menos solicitudes y más tiempo (sesión 17, a probar):** el jugador atiende un chat a la vez, así que lo que cuenta es cuánta atención pide cada solicitud, no cuántas caben a la vez. Antes (todo en el mensaje) una solicitud pedía unos 10 a 15 s de atención; ahora pide unos 25 a 40 s (preguntar, marcar, abrir la página, preguntar las observaciones y responder). Se mantuvo más o menos la misma carga total por noche: de 6 a 18 solicitudes pasaron a 4 a 10, y de 45 a 30 s de tiempo pasaron a 90 a 65 s. Son valores iniciales: se ajustan probando (`data/nights/night_N.tres`, grupo **Solicitudes**).
- Espera de identificación: 2 s (`thinking_seconds` en `BalanceData`).
- Empezar a descargar un video que llegó: 15 s; si no, se pierde. Terminar la descarga: 20 s desde que empezó (decisión de Benja, sesión 14).
- Descarga: 10 s manteniendo presionada la barra del chat (15 s si la señal de ese amigo está bajo 50; sin señal no avanza). Si se suelta, se pausa.
- Audio Sync: la base va en los golpes por minuto de cada noche, y cada ronda va un 15 % más rápida que la anterior. Tras un compás de cuenta, el amigo aplaude 4 veces en corcheas (el primer aplauso al comienzo) y Matías lo repite en el compás siguiente. Las noches de 8 aplausos son 2 rondas de 4 seguidas, cada una con su cuenta y su patrón; si se falla la segunda, se vuelve a la primera con patrones nuevos (decisión de Benja, 4 de noviembre). Tolerancia de cada golpe: ±150 ms.
- Scroll del celular: cada movimiento de la rueda cuenta 0,3 s de scroll.
- Director de ritmo (decisión de Benja, 11 de noviembre; §2): silencio hasta los 60 s (`first_wave_at`); de 4 a 8 s entre las solicitudes de una ola (`wave_spacing`); calma de 40 a 60 s (`wave_calm`); lo de una ola, de 3 a 15 s después de empezar (`wave_event_delay`), y lo de una calma, de 5 a 15 s (`calm_event_delay`); un amigo herido atrasa 10 s lo que falta. En la noche 0, la primera solicitud llega a los 5 s (`first_request_delay`).
- Screamers (decisión de Benja, 11 de noviembre: en las calmas, con las reglas de justicia):
  - en las calmas, con al menos 25 s entre dos, y una visita de la criatura en la ola final;
  - la señal previa dura 1 s: las luces parpadean (el sonido ambiente no baja: pedido de Benja, 12-nov);
  - nunca empiezan si a una decisión o a un accidente le quedan 5 s o menos al terminar la señal previa (la mancha de tinta, que tapa las reglas 5 s, necesita 5 s más), ni durante una ronda de Audio Sync o un audio de un amigo;
  - los ambientales se eligen solo si su objeto está a la vista (el chat, el mixer y el celular ampliado tapan la ventana y el celular), y los del cuaderno, si está abierto. Las luces se ven siempre;
  - la criatura de la ventana (el antiguo jumpscare) solo se arma con el chat o el mixer abiertos, que tapan la ventana, y no mientras la Mano está en la pared; se ve apenas se cierran y se queda entre 15 y 40 s al azar desde que llega (`creature_stay`), aunque se cierren las cortinas. No tapa nada ni pausa la noche (decisiones de Benja, 4, 7 y 11 de noviembre).
- La Mano (decisión de Benja, 11 de noviembre): tarda 12 s en llegar al dial (`hand_approach_seconds`), a tirones de 0,5 a 0,7 s (`hand_step_seconds`); agarrado, el dial baja 6 por segundo (`hand_drain`) hasta 15 (`hand_floor`); cada flash gasta 10 % de la batería (`flash_cost`). No llega mientras la criatura está cerca.
- Videos que ya no alcanzan la cuota (decisión de Benja, 11 de noviembre): aviso en rojo en el chat, una vez por video perdido, y los videos del PC en rojo.
- **Toda noche se puede ganar** (requisito de Benja, 11 de noviembre): `test/test_balance.gd` lo comprueba con un modelo de "jugar bien" (`test/balance_model.gd`: 12 s y 2 preguntas por solicitud, 14 s en Difícil, donde se lee y se busca la página, y 11 s en Extremo, donde juega un experto; la Mano espantada antes de que agarre, la cortina cerrada a los 3 s de llegar la criatura). La batería alcanza, nada vence y Trust termina sobre 75 en las 5 noches de cada modo. Con 15 s por solicitud en Difícil, la noche 5 ya no se puede ganar, y en Extremo, con 12 s, las noches 4 y 5: están en el límite.
- **La holgura** (Plan 9.6): el modelo no cuenta como tareas las sincronizaciones ni el scroll del celular. En toda noche, el tiempo libre (sin tareas abiertas, desde la primera ola) tiene que alcanzar para sincronizar a los amigos (lo que pierden de señal con el tiempo y las interferencias, 70 por sincronización, más 2 s por abrir el mixer) y para reponer Sanity. La referencia es Difícil 5, que Benja probó: su holgura es 1,24. En Extremo, la noche 5 queda en 1,01.
- Alucinaciones (decisión de Benja, sesión 16): con Sanity bajo 50, una cada 40 s, y cada vez más seguidas hasta una cada 10 s con Sanity en 0 (±25 % al azar); más fuertes mientras más baja. No restan Sanity y no suenan durante Audio Sync, un audio de un amigo ni un screamer.
- Accidentes (decisión de Benja, 7 de noviembre): se reparten en la noche como los screamers, 15 s para responder (22,5 s con "Temporizadores ×1,5"). Solo le pasan a un amigo libre, con señal y con más de 1 PV; si la ola está llena, esperan.
- El chat guionado: cada línea del amigo llega 2,5 s después de la anterior; las de Matías esperan su botón.
- **La historia** (Plan 9.7, `docs/31`): cada línea espera lo que tarda en escribirse (60 letras por segundo) más 1,2 s para leerla. Los momentos "antes de" una ola empiezan 15 s antes (25 s el de antes de la ola 1 de la noche 1, que tiene 10 líneas). Mientras la historia cuenta algo, la ola espera a lo más 45 s (`story_hold_limit`, decisión de Benja). Una decisión dura lo que un accidente (15 s, 22,5 con "Temporizadores ×1,5"); Trust no baja de 1 por la historia, y los segundos que pierde la próxima consulta de un amigo nunca la dejan bajo 10 s. Los valores de las decisiones de la noche 1 (10 s menos, Trust −10 y −20) son de partida (`docs/21` §4). La prueba de equilibrio juega la historia: jugando bien, ninguna ola espera y la historia llega entera en los 3 modos.

---

## 7. Plantilla para diseñar una entidad (para Benja)

Copia esta plantilla una vez por entidad. Recomendaciones:

- Como máximo 3 observaciones y 3 reglas, más "en cualquier otro caso". Tiene que poder resolverse en 15 a 20 segundos de lectura.
- **Características** (2 a 4): rasgos fijos que la distinguen. Cada una debe compartirse con otra entidad como máximo; lo que la identifica es la combinación.
- **Observaciones:** cosas que cambian de una situación a otra y que un amigo puede describir sin saber de folclore ("lo vi antes de que me viera", "se oyen golpes en los árboles").
- En cada regla, la acción de mayor riesgo tiene que sonar tentadora: es la que da el video extra.

```text
## <Nombre>
Lugares donde aparece:
Folclore para el cuaderno (2 a 4 líneas):

Características (2 a 4; cada una con su categoría Vista/Sonido/Ambiente/Rastro):
  1.
  2.

Acciones (4, propias de su leyenda):
  A:            B:            C:            D:

Observaciones (2 o 3; cada una con su categoría y sus valores posibles):
  1. <pregunta>  — categoría: — valores: <x> / <y>
  2.
  3.

Reglas (se aplica la primera que se cumple):
  1. Si ________ → correcta: ___ · mayor riesgo: ___
  2. Si ________ → correcta: ___ · mayor riesgo: ___
  3. Si ________ → correcta: ___ · mayor riesgo: ___
  4. En cualquier otro caso → correcta: ___ · mayor riesgo: ___

Qué tiene que comunicar cada mensaje (la intención; tú escribes el texto):
Fuente del folclore:
```

---

## 8. Ejemplo de formato: El Trauco

Este ejemplo muestra **cómo se ve una página**, no cómo debe ser el Trauco. El folclore, las características, las acciones y las reglas los defines tú.

- **Características:** un hombrecito (Vista) · ropa de fibra vegetal (Vista) · huele a bosque húmedo (Ambiente).
- **Acciones:** Mirarlo fijo · Darle la espalda · Esconderse tras un árbol · Seguirlo de cerca.
- **Observaciones:**
  1. ¿Quién vio a quién primero? (Vista): el amigo / el Trauco.
  2. ¿Lleva el hacha en la mano? (Vista): sí / no.
  3. ¿Se oyen hachazos? (Sonido): sí / no.
- **Reglas:**
  1. Si el amigo lo vio primero → correcta: Mirarlo fijo · mayor riesgo: Seguirlo de cerca.
  2. Si el Trauco lo vio primero y lleva el hacha → correcta: Darle la espalda · mayor riesgo: Mirarlo fijo.
  3. Si solo se oyen hachazos → correcta: Esconderse tras un árbol · mayor riesgo: Seguirlo de cerca.
  4. En cualquier otro caso → correcta: Darle la espalda · mayor riesgo: Seguirlo de cerca.

**Ejemplo de solicitud** (la intención, no el texto). León avisa, nervioso, que entre los árboles hay **un hombrecito** con **ropa como de paja**, que lleva un hacha de piedra y que todavía no lo ha visto. La estática tapa "ropa".

1. El jugador no recuerda quién es. Clickea "hombrecito", pero no puede marcar la palabra tapada.
2. Pregunta **¿Qué ves?** (−5 s). León repite la descripción y ahora "ropa como de paja" llega clara.
3. La marca. Tras 2 s aparece "El Trauco", y al clickearlo se abre su página.
4. Aplica la regla 1 (el amigo lo vio primero) y responde **Mirarlo fijo**. Si le faltara un video para la cuota, podría arriesgar **Seguirlo de cerca**.

---

## 9. Textos (dónde están y cómo se escriben)

- Todos los textos del juego viven en **`data/text/*.csv`**, con las columnas `keys,es,en`. Godot los convierte en traducciones.
  - `messages.csv`: los fragmentos de los mensajes de los amigos (los saludos `FIRST_CALL_*`, el lugar, cada característica, cada valor de cada observación y las reacciones).
  - `ui.csv`: los botones, los menús y la interfaz.
  - `notebook.csv`: las páginas del cuaderno.
- **Claude escribe un borrador real de cada texto, y tú lo corriges** (decisión tuya, 31-oct; antes eran textos `[PROTO]`). Los amigos hablan en primera persona y en mensajes cortos, como en un chat: `Me vio primero. Me está mirando.`
- El chat muestra el nombre de quien escribe (`LEÓN:`), así que los textos no lo repiten.
- Cada característica marca su frase destacable (la que se clickea) **entre asteriscos** dentro de su fragmento: `había un *hombrecito* entre los árboles`. Se eligió así (26-oct) porque los corchetes chocan con el BBCode del chat. Las pruebas avisan si un texto no tiene exactamente una frase marcada.
- **Cada característica tiene un nombre fijo en el cuaderno** (`TRAIT_*_LABEL`, en `notebook.csv`), y de 2 a 4 formas más de decirse (`TRAIT_*_2` a `TRAIT_*_5`, en `messages.csv`), cada una con su frase entre asteriscos (decisión de Benja, 11 de noviembre). Antes, el nombre era la frase entre asteriscos de su texto (Plan 4). Las pruebas avisan si una forma no tiene exactamente una frase marcada.
- **Lo que le pasa al amigo** (`PREDICAMENT_*`, en `messages.csv`) va después del saludo.
- Los **señuelos** también van en `messages.csv`, con su frase clickeable entre asteriscos.
- **La página del cuaderno** (Plan 9.2, `notebook.csv`): el folclore, los nombres de las características, las reglas en una tabla (`NOTEBOOK_RULES`, `NOTEBOOK_CONDITION`, la condición de cada regla y una marca por acción: ✓, calavera o ✗), la leyenda de la calavera (`NOTEBOOK_RISK_LEGEND`) y las acciones numeradas. Las marcas son íconos (`art/ui/mark_*.png`), porque la fuente no tiene esos símbolos.
- **La noche 0** (Plan 9.2): las líneas de León van en `ui.csv` (`TUTORIAL_LEON_*`), lo que cuenta de Gonzalo en `messages.csv` (`TUTORIAL_TRAIT_*`, `TUTORIAL_DECOY_HOODIE` y `TUTORIAL_OBS_*`), su página en `notebook.csv` (`TUTORIAL_PAGE_*`, `TUTORIAL_ACTION_*` y `TUTORIAL_RULE_*`) y las tarjetas en `ui.csv` (`TUTORIAL_CARD_*` y `TUTORIAL_CARDS_*`).
- **Cada fragmento es una oración completa, con su puntuación.** El mensaje los une con un espacio. El inicial va en este orden: el saludo, lo que le pasa, el lugar (si lo dice) y la pista. Cada respuesta va en este orden: las características y los señuelos de esa categoría, mezclados, y sus observaciones.
- **Una coma dentro de un texto lleva comillas** (`"¡Mati, ayuda!!"`): sin ellas, el CSV parte el texto y se pierde lo que sigue. Una prueba (`test_text_csv.gd`) avisa.
- Los textos con datos usan marcadores con nombre: `{action}` (la acción que eligió el amigo) y `{marked}` y `{total}` (la barra de identificación).

---

## 10. Modelo de datos (Resources editables en el Inspector)

Implementado en el Plan 2 (`docs/08`). Los señuelos se agregan en el Plan 3 (`docs/10`); `BalanceData`, en el Plan 5 (`docs/12`); las publicaciones del celular, en el Plan 6 (`docs/13`), y los screamers y los chats guionados, en el Plan 7 (`docs/14`); la identificación por preguntas (saludos, pista y `question_cost`) se agregó el 3 de noviembre. Las clases están en `scripts/data/` y el contenido en `data/`.

```text
DecoyData        señuelo: como TraitData (id, category, text_key), más place_keys[] (vacío = cualquier lugar)
TraitData        id, category (SIGHT/SOUND/ENVIRONMENT/TRACES = Vista/Sonido/Ambiente/Rastro),
                 text_key (fragmento con la frase destacable entre asteriscos), label_key (el nombre en el cuaderno),
                 variant_keys[2-4] (otras formas de decirla)
IncidentData     id, message_key, correct_key, wrong_keys (1 o 2): un accidente, en ContentCatalog.incidents
ObservationData  id, category, audio_values (valor → audio; solo en "¿Qué oyes?"), question_key (la pregunta en el cuaderno),
                 values {valor → clave de su fragmento} (ej. friend, trauco)
ActionData       id, label_key
RuleData         conditions {id de observación → valor}, correct_action_id,
                 risky_action_id, text_key (la regla en el cuaderno)
EntityData       id, name_key, lore_key, sketch, place_keys[], traits[2-4], actions[4],
                 observations[2-3], rules[] (ordenadas; la última sin condiciones)
FriendData       id, name_key, avatar, color
NightData        number, place_key, new_entities[], requests_total, max_simultaneous,
                 base_decision_time, first_hint_chance (probabilidad de pista en el mensaje inicial),
                 place_chance (probabilidad de que diga el lugar), decoys_per_request,
                 wave_size (solicitudes por ola común), finale_size (las de la ola final), hand_visits,
                 signal_decays, signal_decay_interval, interference_count,
                 audio_sync_beats, sanity_drain_interval, content_quota,
                 scare_count, creature_visits, incident_count, audio_sync_bpm,
                 scripted_scare_time, scripted_scare (ScareKind), scripted_chat (ChatScriptData),
                 tutorial_requests[] y tutorial_cards[] (solo la noche 0)
TutorialRequestData  la solicitud fija de la noche 0: friend, entity, situation {observación → valor},
                 with_hint, decoys[] (fijos; desde el Plan 9.2, León describe a Gonzalo)
TutorialCardData una tarjeta del final de la noche 0: title_key, text_key, video (VideoStream, video/tutorial/*.ogv)
ChatScriptData   friend, lines[] (ChatLineData: speaker FRIEND/PLAYER, text_key), highlight_phone
StoryData        la historia de una noche (NightData.story; Plan 9.7): beats[] (StoryBeatData: moment, lead_seconds, steps[]),
                 starts_together
StoryStepData    kind (LINE/SEPARATE/JOIN/DECISION), speaker, text_key, decision, requires_flag, unless_flag
StoryDecisionData friend, message_key, options[] (StoryOptionData), no_answer
StoryOptionData  label_key, good, reply_keys[], trust_change, penalty_seconds + penalized[], damage +
                 damage_candidates[], sets_flag
BalanceData      night_seconds, friend_health, stun_seconds, consecuencias (probabilidad, daño y Trust, también el video perdido), vignette_start, el scroll del celular, las fotos perturbadoras (`disturbing_post_*`), la señal (interferencias y Trust sin señal), Audio Sync (tempo y tolerancia), los videos (plazos y descarga), el costo de preguntar (`question_cost`) y la espera de "Matías piensa" (`thinking_seconds`), el director (silencio, olas y calmas), los screamers (señal previa, justicia, Sanity, la criatura y la tinta), la Mano y el flash, y las alucinaciones
PhonePostData    picture (la foto, de 232×232; las cuentas no tienen nombre ni texto)
ContentCatalog   friends[3], nights[5], tutorial (la noche 0), decoys[], greeting_keys[] (saludos),
                 predicament_keys[] (lo que le pasa al amigo), alone_predicament_keys[] (las de uno solo), balance,
                 phone_posts[] (12 gatitos), phone_disturbing_posts[] (4 fotos, con poca Sanity) (data/catalog.tres)
```

- Una entidad es **un solo `.tres`** en `data/entities/`, con todas sus partes dentro.
- Las reglas nombran las acciones por su id. Responder desde la página equivocada es incorrecto aunque la otra entidad tenga una acción con el mismo id.
- Las entidades conocidas en una noche son las `new_entities` de esa noche y de las anteriores (ya no existe `intro_night`). La noche 0 (el tutorial) tiene sus propias páginas (desde el Plan 9.2, solo la de Gonzalo, `data/tutorial/gonzalo.tres`) y, si no tiene, usa las de la noche 1.
- Dos entidades comparten una característica si usan el mismo id, y entonces se dice igual: mismo texto, mismo nombre y mismas formas. Ninguna entidad puede tener todas sus características dentro de las de otra: así siempre hay un par que la distingue.
- Al correr las pruebas, un validador revisa el contenido real y avisa en español: cantidades de la plantilla (§7), ids que no existen, reglas que nunca se aplican, características compartidas por más de 2 entidades y claves de texto que faltan.
- Los tipos de screamer son `ScareKind`: la cortina, la ventana, el celular, las luces, el golpe del cuaderno, la tinta y `JUMPSCARE`, que desde el 4 de noviembre es la criatura que se asoma por la ventana.

---

## 11. Lo que salió del bucle central (y adónde fue)

- **"Grabar" como acción:** eliminada. Salió de una propuesta de la sesión 1 que se había rechazado. El video extra viene de la acción de mayor riesgo, como en el diseño original.
- **Buscador por rasgos con filtros:** reemplazado por las características clickeables.
- **"¿Qué es?":** eliminada, porque los amigos no saben qué es.
- **"Pedir contenido":** después de la v1 (`docs/05`).
- **Personalidades con efectos mecánicos:** descartadas. Las personalidades de los amigos son solo de sabor.
