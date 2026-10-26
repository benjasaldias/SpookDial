# Bucle central: solicitudes, reglas y señal

Detalle de la mecánica central del diseño v2 (`spook_dial_design.md` §8–§10). Actualizado el 26 de octubre de 2026:

- la identificación ahora es por características clickeables;
- ya no existe la acción "Grabar": el video extra viene de la acción de mayor riesgo;
- la cuota la cubren los envíos programados.

Los valores numéricos (§6) son un punto de partida para el prototipo; se ajustan probando.

---

## 1. Qué pone a prueba el juego

- **Aplicar reglas bajo presión**, al estilo Keep Talking. El desafío está dentro de la página del cuaderno: leer qué observa el amigo y aplicar la regla correcta antes de que se acabe el tiempo.
- **Identificar sin depender de la memoria.** Los amigos nunca dicen el nombre de la entidad. Quien la reconoce va directo a su página; quien no, clickea las características destacadas y espera unos segundos.
- **Manejar información degradada.** Con poca señal, la estática tapa palabras: características que ya no se pueden clickear u observaciones que deciden la regla.
- **Repartir la atención** entre 3 amigos, la señal, Sanity y los videos.

---

## 2. Ciclo de vida de una solicitud

1. **El director de ritmo** decide que un amigo disponible recibe una situación. Disponible significa conectado, sin otra solicitud y no aturdido.
2. **Se generan los datos de la situación:**
   - la entidad, entre las conocidas en esa noche;
   - el lugar;
   - un valor al azar para cada observación de esa entidad.
3. **Se arma el mensaje inicial** con fragmentos de texto:
   - el lugar;
   - las **características** necesarias para distinguir a la entidad entre las conocidas (destacadas y clickeables);
   - N **observaciones** (según la noche, §6), en texto normal.
4. **Se aplica la estática** según la señal del amigo (§4).
5. **Empieza el temporizador:** tiempo base de la noche × factor de Trust (§6).
6. **El jugador** identifica (§3), pregunta si le falta algo (§3.2), abre la página y responde (§5).
7. **Se resuelve** la consecuencia (§5.2) y llega la reacción del amigo. Si eligió la acción de mayor riesgo y el amigo sobrevivió, se programa un video extra.
8. **Sin respuesta:** el amigo elige al azar entre las 4 acciones, se resuelve igual y baja Trust.
9. **Si el amigo muere:** pantalla de derrota con la entidad, las observaciones, la regla que aplicaba y la acción correcta. Luego se reinicia la noche.

---

## 3. Identificar y preguntar

### 3.1 Características clickeables

- Las características del mensaje aparecen destacadas. Al clickear una, queda marcada.
- Con **todas** marcadas, empieza una espera de **3 segundos** (Matías piensa) y aparece el nombre de la entidad. Clickear el nombre abre su página en el cuaderno.
- Si una característica está tapada por la estática, no se puede marcar: hay que preguntar en su categoría (§3.2) para que vuelva a aparecer.
- Quien reconoce a la entidad de memoria puede saltarse todo esto y abrir la página desde el índice.

### 3.2 Preguntas de seguimiento

| Pregunta | Qué repite el amigo |
| --- | --- |
| ¿Qué ves? | Las características y observaciones de categoría Vista |
| ¿Qué oyes? | Las de Sonido |
| ¿Cómo está el ambiente? | Las de Ambiente |
| ¿Hay rastros? | Las de Rastro |

- Cada pregunta descuenta **5 segundos** del temporizador y se puede repetir.
- Si no hay nada en esa categoría, el amigo responde "nada", que también es información.
- Las respuestas pasan por la misma estática que los mensajes.

---

## 4. Estática

Cada palabra de un mensaje del amigo se tapa (▒▒▒) con una probabilidad que depende de su señal:

| Señal del amigo | Palabras tapadas |
| --- | --- |
| 70 a 100 | 0 % |
| 50 a 69 | 10 % |
| 30 a 49 | 25 % |
| 1 a 29 | 45 % |

- Las características y las observaciones se tapan con la misma probabilidad que cualquier palabra.
- El tamaño del ▒▒▒ no revela cuántas letras tenía la palabra tapada.

---

## 5. Responder

### 5.1 Acciones de cada entidad

- Cada entidad tiene **4 acciones propias**, con el sabor de su leyenda.
- Los botones de respuesta del chat muestran las acciones de **la página abierta en el cuaderno para ese amigo**. Si no hay ninguna abierta, el chat dice "Abre el cuaderno para responder".
- Cada regla de la página marca la **acción correcta** y la **acción de mayor riesgo**. Las otras dos son incorrectas en esa situación.

### 5.2 Consecuencias

| Elección | Daño | Trust | Contenido |
| --- | --- | --- | --- |
| Acción correcta (según la regla que aplica) | — | 0 | — |
| Acción de mayor riesgo | 70 %: −2 PV | −20 | +1 video si sobrevive |
| Acción incorrecta (incluye responder desde la página equivocada) | 60 %: −1 PV | −10 | — |
| Sin respuesta | El amigo elige al azar y se resuelve igual | −15 extra | Según lo que elija |

- Cada amigo tiene **3 PV por noche**. Al quedar herido, está **aturdido 15 s**. Con 0 PV muere y se pierde la noche.

---

## 6. Valores iniciales para el prototipo

### Por noche

| Parámetro | N1 | N2 | N3 | N4 | N5 |
| --- | --- | --- | --- | --- | --- |
| Solicitudes por noche (aprox.) | 6 | 9 | 12 | 15 | 18 |
| Solicitudes simultáneas máx. | 1 | 2 | 2 | 3 | 3 |
| Tiempo base para responder (s) | 45 | 40 | 35 | 32 | 30 |
| Observaciones en el mensaje inicial | Todas | Todas | Todas menos 1 | 1 | 1 |
| La señal baja | No | Sí | Sí | Sí | Sí |
| Interferencias (aprox. por noche) | 0 | 2 | 3 | 4 | 6 |
| Audio Sync (tiempos) | — | 4 | 4 | 8 | 8 |
| Cuota de videos (= envíos programados) | 2 | 3 | 3 | 4 | 4 |

### Medidores

| Medidor | Inicio | Baja | Sube | Efecto gradual | En 0 |
| --- | --- | --- | --- | --- | --- |
| Señal (cada amigo) | 100 | Entre −1 cada 3 s y −1 cada 6 s (varía). Interferencia: −40, anunciada 3 s antes. | Audio Sync exitoso: vuelve a 100 | Estática (§4). Descargas más lentas bajo 50. | Ese amigo se desconecta |
| Connection (dial) | — | Es el promedio de las 3 señales | — | — | Se pierde la noche |
| Sanity | 100 | −1 cada 6 s (N1: cada 10 s). Screamer: −8 ambiental, −15 jumpscare. | +4 por segundo mientras scrolleas | Viñeta oscura y screamers auditivos falsos, más fuertes cuanto más baja | Se pierde la noche |
| Trust | 100 al empezar cada noche | Ver §5.2 | +1 cada 8 s si no hubo errores en 20 s | Temporizador × (0,6 + 0,4 × Trust/100) | Se pierde la noche |
| Vida (cada amigo) | 3 PV | Ver §5.2 | No se recupera durante la noche | Avatar herido | Muere y se pierde la noche |

### Otros

- Preguntar: 5 s.
- Espera de identificación: 3 s.
- Aceptar un envío: 10 s.
- Descarga: 3 s manteniendo presionado (6 s si la señal de ese amigo está bajo 50).
- Tolerancia de Audio Sync: ±150 ms.

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
3. La marca. Tras 3 s aparece "El Trauco", y al clickearlo se abre su página.
4. Aplica la regla 1 (el amigo lo vio primero) y responde **Mirarlo fijo**. Si le faltara un video para la cuota, podría arriesgar **Seguirlo de cerca**.

---

## 9. Textos (dónde están y cómo se escriben)

- Todos los textos del juego viven en **`data/text/*.csv`**, con las columnas `keys,es,en`. Godot los convierte en traducciones.
  - `messages.csv`: los fragmentos de los mensajes de los amigos (lugar, cada característica, cada valor de cada observación y las reacciones).
  - `ui.csv`: los botones, los menús y la interfaz.
  - `notebook.csv`: las páginas del cuaderno.
- Mientras tanto, Claude deja textos de prototipo que empiezan con `[PROTO]` y **describen la intención**. Por ejemplo: `[PROTO] León dice que vio al ser antes de que él lo viera`. Tú los reemplazas por el texto real.
- Cada característica marca su frase destacable (la que se clickea) **entre asteriscos** dentro de su fragmento: `había un *hombrecito* entre los árboles`. Se eligió así (26-oct) porque los corchetes chocaban con `[PROTO]` y con el BBCode del chat. Las pruebas avisan si un texto no tiene exactamente una frase marcada.

---

## 10. Modelo de datos (Resources editables en el Inspector)

Implementado en el Plan 2 (`docs/08`). Las clases están en `scripts/data/` y el contenido en `data/`.

```text
TraitData        id, category (SIGHT/SOUND/ENVIRONMENT/TRACES = Vista/Sonido/Ambiente/Rastro),
                 text_key (fragmento con la frase destacable entre asteriscos)
ObservationData  id, category, question_key (la pregunta en el cuaderno),
                 values {valor → clave de su fragmento} (ej. friend, trauco)
ActionData       id, label_key
RuleData         conditions {id de observación → valor}, correct_action_id,
                 risky_action_id, text_key (la regla en el cuaderno)
EntityData       id, name_key, lore_key, sketch, place_keys[], traits[2-4], actions[4],
                 observations[2-3], rules[] (ordenadas; la última sin condiciones)
FriendData       id, name_key, avatar, color
NightData        number, place_key, new_entities[], requests_total, max_simultaneous,
                 base_decision_time, first_message_observations (todas / todas menos 1 / 1),
                 signal_decays, signal_decay_interval, interference_count,
                 audio_sync_beats, sanity_drain_interval, content_quota
ContentCatalog   friends[3], nights[5] (data/catalog.tres)
```

- Una entidad es **un solo `.tres`** en `data/entities/`, con todas sus partes dentro.
- Las reglas nombran las acciones por su id. Responder desde la página equivocada es incorrecto aunque la otra entidad tenga una acción con el mismo id.
- Las entidades conocidas en una noche son las `new_entities` de esa noche y de las anteriores (ya no existe `intro_night`).
- Dos entidades comparten una característica si usan el mismo id.
- Al correr las pruebas, un validador revisa el contenido real y avisa en español: cantidades de la plantilla (§7), ids que no existen, reglas que nunca se aplican, características compartidas por más de 2 entidades y claves de texto que faltan.
- `screamer_rate` se agrega a `NightData` en el Plan 7.

---

## 11. Lo que salió del bucle central (y adónde fue)

- **"Grabar" como acción:** eliminada. Salió de una propuesta de la sesión 1 que se había rechazado. El video extra viene de la acción de mayor riesgo, como en el diseño original.
- **Buscador por rasgos con filtros:** reemplazado por las características clickeables.
- **"¿Qué es?":** eliminada, porque los amigos no saben qué es.
- **"Pedir contenido":** después de la v1 (`docs/05`).
- **Personalidades con efectos mecánicos:** descartadas. Las personalidades de los amigos son solo de sabor.
