# Spook Dial — Documento de diseño (v2)

**Versión 2 · 15 de octubre de 2026.** Es la única fuente de verdad sobre qué es el juego.

- La versión original quedó en `spook_dial_design_v1.md`.
- El análisis que llevó a estos cambios está en `docs/01_analisis_diseno.md`.
- El detalle de la mecánica central (reglas, valores numéricos, modelo de datos) está en `docs/02_bucle_central.md`.
- El orden de trabajo y el calendario están en `docs/05_plan_produccion.md`.

Última actualización: 26 de octubre de 2026 (identificación por características, acción de mayor riesgo y cuota cubierta por los envíos; en la sesión 8, señuelos, barra de identificación, estática por frase y preguntas con 5 s o menos).

---

## 1. Identificación

- **Título:** Spook Dial (juego de palabras con *speed dial*).
- **Plataforma:** PC (Windows).
- **Género:** terror psicológico, simulación de escritorio, puzzle de reglas bajo presión.
- **Audiencia:** 13 años o más.
- **Motor:** Godot 4.7.2.
- **Arte:** pixel art 2D a 1280×720, hecho en Aseprite. Tipografía: una fuente pixel existente.
- **Idioma:** español. Se agrega inglés antes de la entrega si alcanza el tiempo; los textos se preparan para traducir desde el primer día.
- **Entrega:** 10 de diciembre de 2026. Debe estar completo y jugable.

## 2. Pitch

Matías es un experto en lo paranormal, demasiado cobarde y poco sociable para exponerse. Desde un escritorio en una cabaña del sur de Chile guía por chat a sus tres amigos (León, Gonzalo y Agustín), que graban contenido en lugares embrujados de los alrededores.

Durante cinco noches tiene que hacer cuatro cosas:

- interpretar lo que sus amigos ven y oyen;
- aplicar lo que sabe de cada criatura del folclore chileno;
- mantener la conexión;
- no perder la cordura ni la confianza de sus amigos.

**Fantasía central: el operador.** El jugador nunca está en el lugar del peligro, pero es la única fuente de conocimiento, y sus decisiones definen el destino de otras personas.

## 3. Principio rector: el juego es el escritorio

- **Todo el juego ocurre en el escritorio de Matías**, en primera persona y con cámara fija. El jugador no se desplaza: interactúa con los objetos que tiene enfrente.
- **La historia queda fuera de las mecánicas.** Se cuenta en **cinemáticas opcionales** (introducción, entre noches y final) y nunca cambia cómo se juega.
- Las entidades **no pueden dañar a Matías**: solo asustarlo. El riesgo de muerte siempre recae sobre los amigos.

## 4. Personajes

- **Matías (el jugador).** Nunca se le ve: el jugador mira desde sus ojos.
- **León, Gonzalo y Agustín.** Los amigos que graban. Cada uno tiene nombre, avatar y una personalidad propia, que es solo de sabor (no cambia las reglas). Su voz llega al chat convertida en texto. León es el que termina poseído, pero eso ocurre solo en las cinemáticas.
- **Loreto.** La madre de Matías; aparece solo en las cinemáticas.
- **Las entidades.** Siete criaturas del folclore chileno (§13). **El jugador nunca las ve durante las decisiones**: las conoce por lo que dicen sus amigos y por su cuaderno.
- **Los Brujos de Chiloé.** Son los antagonistas de la historia, los que se interesan cada vez más en Matías. Solo aparecen en las cinemáticas y en la ambientación, no como entidad que hay que resolver.

## 5. Estructura de una partida

- **Menú principal:** Continuar (solo si hay una partida en curso), Nueva partida, Opciones y Salir.
- **5 noches.** Cada una va de las **00:00 a las 06:00** (formato de 24 horas) en unos **7 minutos reales**.
- **Se gana la noche** al llegar a las 06:00 **con la cuota de contenido cumplida**.
- **Se pierde la noche** en cualquiera de estos casos:
  - Sanity, Trust o Connection llegan a 0;
  - un amigo muere;
  - son las 06:00 y no se cumplió la cuota.
- **Al perder:** una pantalla explica qué pasó y la noche se reinicia desde el comienzo. La noche se vuelve a generar, así que no se repite de memoria.
- **Guardado:** al comienzo de cada noche.
- **Entre noches:** un resumen (contenido obtenido y páginas nuevas del cuaderno), y después una cinemática opcional.
- **Final único:** sobrevivir las 5 noches, como en FNAF.

## 6. El escritorio

Cada objeto cumple una función:

| Objeto | Función |
| --- | --- |
| **PC** | Muestra siempre las 3 entradas de los amigos: estado, señal, temporizador y avisos. Al hacer clic en una se abre su conversación. También muestra el contador de contenido de la noche. |
| **Cuaderno** | El manual: un índice con el nombre de cada entidad y una página por entidad con sus reglas (§12). |
| **Mixer** | Audio Sync. Sus 3 faders son los canales de los 3 amigos (§10). |
| **Celular** | Muestra la hora. Al abrirlo se scrollea con la rueda del mouse para recuperar Sanity (§10). |
| **Diales** (en la pared) | Connection, Sanity y Trust. Tienen cara de manómetro, un ícono propio y un LED de alerta, para que no dependan del color. |
| **Micrófono** | Su LED se enciende al responder (ambientación). |
| **Ventana y cortinas** | Ambientación y blanco de screamers. |

## 7. Interfaz

- **El PC siempre muestra la lista** de las 3 entradas. La conversación abierta se ve destacada.
- **Panel de chat** a la izquierda de la pantalla:
  - una pestaña por amigo, con aviso y temporizador;
  - el historial de la conversación, que se scrollea con la rueda del mouse;
  - los botones de preguntas y de respuesta.
- **Cuaderno** al centro. Los diales siguen visibles a la derecha.
- **Para usar el celular o el mixer** hay que cerrar los paneles (`Esc` o clic derecho). Ese es el costo de oportunidad.
- **Mensajes:** aparecen escritos progresivamente, con un sonido breve por mensaje.
- **Alarma:** cuando un amigo espera respuesta, su entrada parpadea y suena una alarma.

## 8. Mecánica central: solicitudes y reglas

### 8.1 Flujo de una solicitud

1. **Llega.** Un amigo escribe dónde está y describe lo que ve y oye. **Nunca dice el nombre de la entidad**: el experto es Matías. Empieza su temporizador.
2. **El jugador identifica la entidad**, de memoria o con las características destacadas del mensaje (§8.3).
3. **Abre la página de esa entidad** en el cuaderno.
4. **Aplica las reglas** de la página según lo que observa el amigo. Si le falta un dato, pregunta (§8.4).
5. **Responde** con una de las 4 acciones de la página (§8.5).
6. **Se resuelve** la consecuencia (§9).

### 8.2 Estática

Según la **señal de ese amigo** (§10), algunas palabras de su mensaje llegan tapadas por estática (▒▒▒).

- Puede taparse cualquier palabra: **también una característica** o el dato que decide la regla.
- Una frase destacada de varias palabras se tapa entera o no se tapa.
- Con la señal alta no hay estática; mientras más baja, más palabras se pierden.
- Así, mantener la señal es mantener la información.

### 8.3 Identificar la entidad

Los mensajes traen tres tipos de información:

- **Características.** Son fijas de cada entidad (por ejemplo, "un hombrecito" o "huele a azufre"). Aparecen **destacadas** y se pueden clickear.
- **Señuelos.** Aparecen destacados igual que las características, pero no ayudan a identificar: describen el lugar, un olor, un sonido o algo que se ve. Sirven para camuflar las características.
- **Observaciones.** Cambian en cada situación y deciden qué regla se aplica. Van como texto normal.

Hay dos formas de identificar a la entidad:

- **De memoria:** quien la reconoce abre su página directamente.
- **Con las características:** el jugador clickea las frases destacadas. Una característica queda marcada; un señuelo vibra y se pone rojo. Una barra muestra cuántas características van marcadas (1 de 2). Con las 2 marcadas, tras una breve espera (unos 3 segundos, mientras Matías piensa), aparece el nombre de la entidad, y al clickearlo se abre su página.

Detalles:

- Así se premia a quien memoriza, sin castigar demasiado a quien no.
- Una característica tapada por la estática no se puede clickear: hay que preguntar (§8.4) para recuperarla.
- El mensaje inicial trae **2 características** que distinguen a la entidad entre las conocidas, mezcladas con señuelos: 1 en la noche 1 y hasta 3 en la noche 5. Clickear un señuelo no cuesta nada, aparte del tiempo.

### 8.4 Preguntas de seguimiento

Junto a las respuestas hay preguntas: **¿Qué ves? · ¿Qué oyes? · ¿Cómo está el ambiente? · ¿Hay rastros?**

- Cada pregunta cuesta **5 segundos** del temporizador (el amigo tarda en mirar). Con 5 segundos o menos ya no se puede preguntar.
- La respuesta repite las características y los señuelos de esa categoría que traía el mensaje, y todas las observaciones de esa categoría. También puede llegar con estática si la señal sigue baja.
- Se pueden repetir.

### 8.5 Responder desde el cuaderno

- Cada entidad tiene **4 acciones propias**, con el sabor de su leyenda.
- Los botones de respuesta del chat muestran **las acciones de la página que el jugador tiene abierta para ese amigo**. Sin una página abierta, el chat indica que hay que abrir el cuaderno.
- **Por qué:**
  - si las opciones vinieran ya puestas en el chat, delatarían a la entidad;
  - obliga a consultar el cuaderno;
  - responder desde la página equivocada es un error.

### 8.6 Las reglas (estilo Keep Talking and Nobody Explodes)

Cada página del cuaderno tiene:

- **Observaciones:** 2 o 3 cosas que el amigo puede ver u oír. Por ejemplo: "¿quién vio a quién primero?" o "¿se oyen hachazos?". Cada una pertenece a una categoría de pregunta (Vista, Sonido, Ambiente o Rastro).
- **Reglas ordenadas:** como máximo 3, más "en cualquier otro caso". Se aplica la **primera que se cumple**. Cada regla marca:
  - la **acción correcta**;
  - la **acción de mayor riesgo**, que da un video extra si el amigo sobrevive.

  Las otras dos acciones son incorrectas.

Las observaciones cambian en cada solicitud, así que la misma entidad pide acciones distintas. Lo que se pone a prueba es leer la página bajo presión, no adivinar.

### 8.7 Si no hay respuesta

Si el temporizador llega a 0, el amigo decide solo (al azar entre sus 4 acciones) y la consecuencia se resuelve igual. Además baja Trust por no contestar. Un amigo desconectado también decide solo, pero sin ese castigo.

## 9. Consecuencias

- **Vida:** cada amigo tiene **3 PV por noche**, que se restauran al empezar la siguiente.
- **Herido:** queda **aturdido 15 segundos**; en ese tiempo no pide ayuda ni envía nada.
- **Muerte:** con 0 PV el amigo muere y **se pierde la noche**.

| Elección | Daño | Trust | Contenido |
| --- | --- | --- | --- |
| Acción correcta | — | — | — |
| Acción de mayor riesgo | 70 %: −2 PV | baja mucho | +1 video si sobrevive |
| Acción incorrecta (incluye responder desde la página equivocada) | 60 %: −1 PV | baja | — |

- **Trust baja según el riesgo de lo elegido, no según la suerte.** Una opción prudente que sale mal no se castiga igual.
- Los valores exactos están en `docs/02` y se ajustan probando.

## 10. Medidores y tareas de mantenimiento

### 10.1 Connection (la señal de cada amigo)

- **Cada amigo tiene su propia señal** (0–100). Se ve en las barras de su entrada del PC y en su fader del mixer.
- **Baja de dos formas:**
  - poco a poco, con un ritmo que cambia según el amigo y la noche;
  - de golpe, con **interferencias al azar**. Cada interferencia se **anuncia 3 segundos antes** con estática y la entrada titilando.
- **Efectos:**
  - con la señal bajo 50 hay estática en los mensajes (§8.2) y las descargas son más lentas;
  - con 0, el amigo **se desconecta** y decide solo si le llega una situación.
- **Audio Sync, individual y cuando el jugador quiera.** En el mixer se elige el canal de un amigo (su fader, o su entrada del PC) y se sincroniza. Si sale bien, su señal vuelve a 100. Así el jugador puede decidir gastar tiempo en mantener alta la señal antes de que algo falle.
- **El dial de la pared** muestra el promedio de las tres señales. Llega a 0 solo si todos están desconectados.
- **Si cualquiera de los 3 diales (Connection, Sanity o Trust) llega a 0, se pierde la noche.**

### 10.2 Sanity

- Baja lento todo el tiempo, y de golpe con cada screamer (una cantidad fija).
- Se recupera **scrolleando el celular**: sube mientras el jugador scrollea y deja de subir cuando se detiene.
- **Efecto gradual:** mientras más baja, más se oscurece la visión con una viñeta y más **screamers auditivos falsos** aparecen (sonidos que no vienen de nada).
- Con 0, Matías entra en pánico y **se pierde la noche**.

### 10.3 Trust

- Baja al elegir acciones riesgosas (§9) y al no contestar a tiempo.
- Se recupera lentamente mientras no haya nuevos errores.
- **Efecto gradual:** mientras más baja, **menos tiempo esperan los amigos tu respuesta** (sus temporizadores se acortan).
- Con 0, los amigos ya no quieren pedirte ayuda y **se pierde la noche**.
- Vuelve a 100 al comienzo de cada noche.

### 10.4 Contenido (la cuota)

- Cada noche tiene una **cuota de videos**. Cumplirla es condición para ganar la noche.
- El contenido llega por dos vías:
  - **Envíos programados.** Los amigos graban y mandan videos durante la noche, y **son justo los suficientes para cumplir la cuota** si el jugador los recibe todos.
  - **La acción de mayor riesgo.** Si el amigo sobrevive, llega un video extra. Sirve para compensar los envíos perdidos, a cambio de arriesgar al amigo y su confianza.

### 10.5 Recibir videos (Receive Media)

- Llega un aviso con **10 segundos para aceptar**.
- La descarga se hace **manteniendo presionado** el botón. Su velocidad depende de la señal de ese amigo, y si se suelta, se pausa.
- Si no se acepta a tiempo, el video se pierde.

### 10.6 Audio Sync

- Se elige el canal del amigo en el mixer.
- El amigo marca **4 u 8 tiempos con aplausos**, según la noche. Los VU-metros del mixer los muestran, además del sonido.
- El jugador los repite con la **barra espaciadora**.
- Se puede reintentar las veces que se quiera, y se puede salir para atender otra cosa.

## 11. Screamers

- **Tipos:**
  - ambientales: la cortina se mueve, aparecen ojos en la ventana, el celular vibra, las luces parpadean;
  - sobre el cuaderno: se cierra de golpe, o una mancha de tinta tapa las reglas durante 5 segundos;
  - jumpscare de pantalla completa: como máximo **uno por noche**, desde la noche 2.
- **Señal previa breve:** un parpadeo de luz y una caída del sonido ambiente.
- **Reglas de justicia:**
  - los que tapan la pantalla **pausan los temporizadores**;
  - nunca ocurren en los últimos 5 segundos de una decisión.
- Cada uno resta una cantidad fija de Sanity. No dañan a Matías.

## 12. El cuaderno

- **Índice:** una pestaña con el nombre de cada entidad conocida.
- **Página de una entidad:**
  - folclore breve y un boceto;
  - sus características, para quien quiera aprenderlas de memoria;
  - las observaciones y a qué pregunta pertenece cada una;
  - las reglas ordenadas, cada una con su acción correcta y su acción de mayor riesgo;
  - las 4 acciones.
- **Memoria por amigo:** el cuaderno recuerda la página abierta de cada amigo y salta a ella al cambiar de chat.
- **Está deliberadamente limitado:** no tiene todas las páginas desde el principio; las nuevas llegan entre noches.

## 13. Entidades

Siete criaturas del folclore chileno. Benja define las reglas y las acciones de cada una con la plantilla de `docs/02`.

| Entidad | Lugar habitual | Noche en que aparece |
| --- | --- | --- |
| El Tue Tué | Casas, techos, árboles | 1 |
| La Calchona | Caminos, campo | 1 |
| El Cuero | Lagos | 2 |
| La Viuda | Caminos | 2 |
| El Trauco | Bosque | 3 |
| El Basilisco | Casas, bajo el piso | 4 |
| El Imbunche | Cuevas | 4 |

**Cuidado con el folclore (público de 13 años o más):** en la tradición, el Trauco tiene contenido sexual, y el Imbunche implica la mutilación de un niño. Se usan sus otros rasgos (hachazos y mirada; guardián deforme), sin esos elementos. Fuentes sugeridas: Oreste Plath, *Geografía del mito y la leyenda chilenos*, y Memoria Chilena.

## 14. Progresión de las noches

| Noche | Dónde están los amigos | Entidades nuevas | Qué se agrega |
| --- | --- | --- | --- |
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust. La señal no baja. Un screamer guionado enseña Sanity y el celular. Los mensajes traen todas las observaciones. |
| 2 | Camino y lago | El Cuero, La Viuda | Señal por amigo, interferencias, Audio Sync de 4 tiempos, estática y screamers regulares. |
| 3 | Bosque | El Trauco | Mensajes con menos observaciones: preguntar se vuelve necesario. |
| 4 | Casa abandonada y cueva | El Basilisco, El Imbunche | Audio Sync de 8 tiempos y varias solicitudes a la vez. |
| 5 | Todos los lugares | — | Todo a la vez, al máximo. |

## 15. Historia (fuera del juego)

Se cuenta solo en cinemáticas opcionales (introducción, entre noches y final), basadas en la versión Twine:

- Matías acompaña a sus amigos a una cabaña aislada cerca de Puerto Montt.
- Los Brujos de Chiloé se interesan cada vez más en él.
- León termina poseído.
- Lo que Matías realmente buscaba no era contenido, sino amistad.

El guion de las cinemáticas lo escribe Benja.

## 16. Arte

- **Pixel art 2D** a 1280×720, en perspectiva de un punto de fuga.
- **Cámara que mira hacia el mouse (a prueba):** toda la escena tiene un zoom leve (×1,05) y se desplaza hacia donde apunta el mouse, como si el jugador mirara hacia ese lado. El desplazamiento no supera el margen del zoom, así que todos los objetos siguen alcanzables. Si no funciona, se quita.
- **Iluminación baja.** La pantalla del PC y la ventana son las fuentes principales. Cada entidad puede teñir la luz, pero siempre con sonido además del color.
- **Detalle técnico:** `docs/03_plan_arte.md`.

## 17. Sonido

- Es clave para la tensión: estática, ruidos del entorno de los amigos y silencios.
- Un sonido breve por mensaje.
- Un sonido propio para cada entidad.
- Screamers auditivos cuando Sanity baja.

## 18. Textos

- **Benja escribe los diálogos.** Claude deja textos de prototipo que **describen la intención** de cada mensaje, marcados con `[PROTO]`, e indica en qué archivo están.
- Todos los textos viven en archivos de traducción (`data/text/*.csv`, con una columna para español y otra para inglés).

## 19. Accesibilidad y opciones

- Reducir destellos.
- Volumen por canal.
- Desactivar el parallax.
- Temporizadores ×1,5.
- Ninguna información crítica depende solo del color.

## 20. Por confirmar

Nada pendiente (26 de octubre de 2026). Los valores numéricos de `docs/02` son un punto de partida y se ajustan probando.

## 21. Referencias

- **Five Nights at Freddy's:** estructura por noches, ubicación fija y gestión de recursos bajo presión.
- **Keep Talking and Nobody Explodes:** un manual de reglas que se consulta bajo presión de tiempo.
- **Home Safety Hotline:** guiar a terceros usando un manual.
- **Not For Broadcast:** varias tareas en paralelo.
- **Lethal Company:** el rol de operador que guía a quienes exploran.

**Después de la entrega** quedan pendientes, en orden de prioridad: Pedir contenido, buscador por rasgos, ráfagas de imágenes con anomalías, defensa en la base, entre otras (`docs/05_plan_produccion.md`).
