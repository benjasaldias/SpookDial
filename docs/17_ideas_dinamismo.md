# Ideas para hacer el juego más dinámico (notas de la prueba del 7-nov)

**Las notas de Benja del 7 de noviembre, ordenadas y con sus decisiones.** Ya se volvieron plan: `docs/18_plan_dinamismo.md`, que además fija lo que aquí quedó abierto. Si algo no coincide, vale el plan.

## 1. Diagnóstico

Hoy el juego es **reactivo**: todo lo dispara un amigo (llega una solicitud) y el jugador solo responde. Entre solicitud y solicitud hay un respiro de 25 s en el que casi no hay nada que decidir, y cuando llega la solicitud, el cuaderno la vuelve resoluble con tiempo de sobra. Falta:

1. **Tensión en la decisión**: acertar es demasiado fácil.
2. **Cosas que atender por cuenta propia**: variables que el jugador administra sin que nadie se lo pida.
3. **Imprevisibilidad**: hoy un amigo solo se hiere si el jugador se equivoca.

Las notas 1–2 atacan el punto 1; 5, 7 y 8 el punto 2; 4 el punto 3. Las notas 3 y 6 (historia) son otra cosa, y Benja misma las deja para más adelante.

## 2. Las notas ordenadas

| Nota | Tema | Qué busca | Va en |
| --- | --- | --- | --- |
| 1 | Acertar a tiempo es fácil (cuaderno simple y tiempo de sobra) | Más tensión en la decisión | Lote A |
| 2 | Acelerar los Audio Sync | Que no se vuelva rutina | Lote A |
| 7 | Batería del celular | Que Sanity no se rellene gratis | Lote B |
| 8 | Cortinas abribles | Sanity con una decisión espacial; la criatura obliga a actuar | Lote B |
| 4 | Heridas por accidente | Imprevisibilidad | Lote C |
| 5 | Algo que hacer mientras se espera | Quitar el tiempo muerto | Lote D |
| 9 (nueva) | Los diales no se entienden: barras de HUD para Connection, Sanity y Trust | Que se vea el estado de un vistazo | Lote E |
| 3 y 6 | Cronología, decisiones de sentido común, amigos incrédulos | Historia | Para después |

## 3. Acciones concretas

### Lote A — Ajustes de dificultad (casi todo datos)

**Nota 1: acertar demasiado fácil.** Palancas que ya existen, de menor a mayor costo:

| Palanca | Hoy | Acción propuesta |
| --- | --- | --- |
| Tiempo para decidir (`base_decision_time`) | 90, 80, 75, 70, 65 s | Bajar más rápido por noche (ej. 80, 65, 55, 45, 40). Valores a probar. |
| Pista inicial (`first_hint_chance`) | 100, 75, 50, 35, 20 % | Dejar 0 % desde la noche 3. |
| Señuelos por solicitud | 1, 1, 2, 2, 3 | Subir 1 desde la noche 2. |
| Características compartidas entre entidades | Una por entidad | Que en las noches 3–5 haya entidades que comparten 2 y se distingan solo por una pregunta concreta (se corrige en los CSV/`.tres`, mismo trabajo que la corrección de las 7 entidades). |
| Regla con condición | No hay | Revisar si el evaluador de reglas ya soporta condiciones (ej. «si el amigo está herido» o «si es antes de las 03:00»). Si las soporta, es la palanca más fiel a Keep Talking: el cuaderno se complica sin subir el tiempo. Si no, es un cambio de código mayor. |

Sesión: se puede hacer dentro de S20 (corrección tras pruebas), porque es casi todo balance.

**Audios en lugar de descripciones en «¿Qué oyes?» [decidido 7-nov].** Benja considera que las condiciones del cuaderno son simples (aunque son provisionales). Hoy la respuesta a «¿Qué oyes?» es un texto. La propuesta de Benja: que el amigo **mande un audio** y el jugador lo reproduzca. Ejemplos: El Tue Tué, 1, 3 o ningún canto del ave; La Calchona, un balido o un bufido.
- **Qué implica:** un tipo nuevo de observación con un clip de audio (o varios, con una cantidad) en vez de texto, un botón de reproducir en el chat, y sonidos para las 7 entidades (los provisionales los puede generar Claude, y Benja pone los reales, como en `sonidos_pendiente.md`).
- **El audio cambia la acción correcta [decidido 7-nov].** No es solo identificación: la cantidad o la variante del sonido decide qué acción es la correcta en esa misma entidad (ej. El Tue Tué con 1 canto pide una acción, con 3 otra, y sin canto una tercera; La Calchona con un balido pide una acción y con un bufido otra). Es la «regla con condición» de la tabla de arriba: el cuaderno se complica sin subir el tiempo, al estilo Keep Talking. Hay que revisar si el evaluador de reglas ya soporta una condición así o si hay que ampliarlo (ver la fila de la tabla de arriba); probablemente la forma más simple es que la regla de cada acción liste, además del acierto o error, qué variante de sonido la hace correcta.
- **Encaja con lo ya hecho:** la estática puede tapar el audio (con poca señal llega cortado o distorsionado), y las alucinaciones sonoras nunca deben sonar mientras se reproduce uno, como ya no suenan durante Audio Sync.
- **Preguntas de diseño:** ¿cuenta como una de las 2 características clickeables o es una respuesta aparte? ¿Se puede repetir sin costo o cada reproducción gasta tiempo? ¿Hay subtítulo opcional (ej. «[canto ×3]») para quien no pueda oír? El plan lo tiene que fijar.
- **Costo:** medio. Es un cambio de datos (`ObservationData`), de chat y de sonido, más los 7 grupos de audios.

**Nota 2: acelerar los Audio Sync.** Hoy `audio_sync_bpm = 100` es único y global. Acción: pasar el bpm a `NightData` (ej. 90, 100, 115, 130, 145) y, en las noches de 2 rondas, que la ronda 2 vaya más rápida que la 1. Opcional: bajar `audio_sync_tolerance` (0,15 s) por noche. Cambio chico de código más datos.

### Lote B — La economía de Sanity (notas 7 y 8)

Juntas forman un sistema: Sanity pasa a tener **fuentes de pérdida, una fuente de ganancia limitada y una decisión espacial**.

| Pierde Sanity | Recupera Sanity |
| --- | --- |
| Goteo pasivo (`sanity_drain_interval`) | Celular, con batería limitada |
| Screamers (8 / 15) | |
| Cortinas cerradas (goteo lento, nuevo) | |
| Criatura afuera con la cortina abierta (goteo rápido, nuevo) | |

**Nota 7: batería del celular.**
- Batería 0–100 %, llena al empezar cada noche. Se gasta solo mientras se scrollea.
- **Tope por noche, sin recarga [decidido 7-nov].** Simple, se entiende y obliga a guardar la batería.
- Con 0 %, el celular muestra «batería baja» y no se puede scrollear. Valor de partida a probar: que una batería llena alcance para recuperar ~1,5 veces la barra de Sanity.
- Falta el indicador visible: un porcentaje sobre el celular abierto y una marca en el celular del escritorio. Se hace en Godot con arte provisional.
- La noche 0 (tutorial) debe explicarlo: el aviso del celular dice que la batería es limitada.

**Nota 8: cortinas.**
- Las cortinas pasan a ser clickeables, abiertas o cerradas (`curtains_sprite` ya está en la escena).
- **Cerradas:** el cuarto se oscurece (ya existe la capa `Darkness`) y Sanity baja de a poco. Es el costo de la seguridad.
- **Abiertas:** sin costo, pero si hay algo afuera, Sanity baja **rápido** hasta que se cierren.
- **La criatura se queda un tiempo fijo [decidido 7-nov].** No se va cuando cierras la cortina: el jugador tiene que **abrirla para revisar si sigue ahí** y volver a cerrarla si sigue. Mientras está afuera con la cortina abierta, Sanity baja rápido; cerrada, baja el goteo lento. Se sigue armando solo cuando el chat o el mixer tapan la ventana (así sigue siendo justo) y se sigue anunciando con los golpes y la respiración. Si la cortina estaba cerrada, la criatura la abre al aparecer (idea de Benja).
- **El screamer ambiental de la cortina cambia [decidido 7-nov]:** en vez de «la cortina se mece», la cortina **se abre o se cierra sola**.
- Pendientes de diseño: cuántos segundos se queda la criatura, cuántas veces puede aparecer por noche, y si revisar tiene un costo (abrir un instante cuesta una dosis de Sanity rápido aunque ya no esté).
- Arte: falta el frame de **cortina cerrada** (`curtains_sprite` hoy solo tiene `idle`). Hasta que Benja lo dibuje, Godot lo provisiona sin escalar el sprite (regla 10), con un dibujo plano de relleno.
- Cambia la decisión del 4-nov (la criatura se va a los 4 s), así que habría que actualizar `CLAUDE.md` y el diseño §10.2 y §11.

### Lote C — Incidentes (nota 4)

**Incidente con respuesta (C2) [decidido 7-nov].** El amigo escribe «¡auch! me tropecé, creo que me corté». Aparece una solicitud corta sin entidad ni cuaderno, con 2 o 3 opciones de sentido común («Presiona la herida», «Sigue caminando»). Acertar evita el daño o lo reduce; fallar lo aplica. Es la **versión chica de la nota 3** («combate ocasional» entre decisiones simples) y deja resuelto el marco técnico para ella: una solicitud sin entidad.
- Va como solicitud extra del director, con su propia probabilidad por noche, respetando el respiro de 25 s.
- Cuidado: no hay que tocar «un amigo muerto pierde la noche» ni los 3 puntos de vida. Hay que revisar si la vida se recupera hoy (no está en estas notas).
- Las personalidades siguen siendo solo de sabor: el incidente puede tener texto distinto por amigo, pero el mismo efecto.

### Lote D — Algo que hacer mientras se espera (nota 5)

**[Decidido 7-nov: se deja para cuando se vea, tras los lotes anteriores, si hace falta algo adicional.]**

Hay que decidir **si hace falta**. Los lotes B y C ya meten cosas entre solicitudes (batería, cortinas, incidentes, señal); conviene **probar primero** si el tiempo muerto sigue ahí. Si sigue:

- **Editar los videos recibidos.** Cada video descargado entra a una bandeja en el PC y se «procesa» con un minijuego corto: recortar una parte, quitar el cuadro con la anomalía, limpiar la estática. Alternativas de recompensa (**elegir una**):
  - la edición es **obligatoria** para que el video cuente para la cuota (cambia la decisión del 26-oct);
  - es **opcional** y da un beneficio (recuperar algo de Trust, o contenido «limpio» para el resumen de la noche). Menos riesgosa, menos fuerte.
- Costo: es un panel nuevo, con su arte y su lógica, y toca la regla de modos exclusivos (es un tercer panel o un modo nuevo). Es el lote más grande.
- Otros rellenos más baratos, si hace falta antes: responder mensajes «de relleno» de los amigos, o limpiar la estática de la entrada de un amigo.

### Lote E — Barras de HUD para Connection, Sanity y Trust (nota 9)

**En el hueco central, arriba, y los diales se quedan [decidido 7-nov].** El chat ocupa x 11–460 y el cuaderno x 820–1269, así que en el centro de la pantalla (x 470–810) no lo tapa ninguno de los dos y las barras se ven siempre, incluso con el cuaderno abierto (que es justo cuando más importan Trust y Sanity).
- **Posición concreta propuesta:** en la pared, a la derecha de las cortinas, ~x 610–810 e y 70–135, tres barras de ~190×14 apiladas, cada una con su ícono a la izquierda (los mismos de los diales) y su color (Connection verde, Sanity roja, Trust amarilla). Va en la capa `UI`, para que no se mueva con la cámara.
- **Choque a resolver:** el aviso de la noche 0 está en el mismo hueco, arriba (x 470–810, y 12). Las barras van debajo, o el aviso se corre un poco.
- **Los diales del arte se quedan** como decoración con agujas que se mueven; las barras son la lectura principal.
- **Detalles que ayudan a que se entienda:** que la barra titile al bajar de golpe (por daño o screamer), que se ponga en alerta bajo 25 (el diseño ya define un LED de alerta en los diales), y el ícono para no depender solo del color.
- **Cambios de texto:** el aviso de la noche 0 que explica los diales pasa a explicar también las barras, y `docs/04` y el diseño §6–7 se actualizan.
- **Costo:** bajo. Son nodos de UI en Godot sin arte nuevo (barras provisionales dibujadas con `ColorRect`), con una prueba de lógica para el color y el titileo.

### Para después — Historia y cronología (notas 3 y 6)

- Nota 3: cronología (juntos → se separan → uno aparece herido → uno desaparece) con decisiones de sentido común, y las solicitudes de ayuda como «combate ocasional».
- Nota 6: arranca con los amigos incrédulos; el cuaderno no está en la mesa o está deshabilitado; en el primer encuentro Matías dice «confíen en mí».
- **Choca con la regla 9 de `CLAUDE.md`:** «la historia va solo en cinemáticas opcionales y nunca cambia las mecánicas». Habría que enmendarla y actualizar el diseño. También choca con la noche 0, que ya enseña el cuaderno desde el inicio.
- Lo que sí quedó listo para esto: los chats guionados como datos de una noche (Plan 7), el punto 20 de `docs/05` (progresión guionada) y, si se hace el Lote C, las solicitudes sin entidad.
- Recomendación (coincide con la nota de Benja): **no empezar** hasta que las mecánicas sean divertidas solas. Reevaluar tras el Lote C, ya con el juego probado.

## 4. Orden y calendario

**Benja confirmó que todo esto entra antes del 25-nov** (Lotes E, A, B y C), y que la historia se deja para después, cuando las mecánicas ya se sientan bien. Hoy es 7 de noviembre; el contenido se congela el 25 y la prueba con 3 a 5 personas es del 23 al 29 (semana 5). Para que esa prueba ya sea sobre la versión más dinámica, los 4 lotes tienen que estar listos **antes del 23-nov**, dentro del hueco libre que hoy tiene `docs/00_log.md`. Orden propuesto (cada uno depende del anterior: la noche 0 y el aviso de los diales que toca E se complican si se hace después de B, y las entidades de A hay que tocarlas una sola vez):

| Orden | Lote | Qué incluye | Costo |
| --- | --- | --- | --- |
| 1 | E | Barras de HUD de Connection, Sanity y Trust | Bajo |
| 2 | A | Tiempos y pistas por noche, señuelos, características compartidas, audios de «¿Qué oyes?» que cambian la acción correcta, Audio Sync más rápido por noche | Medio (los audios son lo que más pesa) |
| 3 | B | Batería del celular (tope por noche) y cortinas (Sanity espacial, la criatura que se queda y hay que revisar) | Medio-alto (necesita el frame de cortina cerrada) |
| 4 | C | Incidentes con respuesta de sentido común (C2) | Medio |

**Riesgo de alcance:** el Plan 9 (sonido, pulido y versión) está agendado para el 30 de nov. Por la regla 6 de `CLAUDE.md`, el Lote D (editar videos) y la historia quedan fuera de la v1 salvo que sobre tiempo después de probar con personas.

## 5. Siguiente paso

Las decisiones de diseño están tomadas. Falta planificar las sesiones que escriben y ejecutan esto (§4 de abajo, en la respuesta a Benja) y actualizar `docs/00_log.md` y `docs/05_plan_produccion.md` en consecuencia.
