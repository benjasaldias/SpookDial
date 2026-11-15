# Spook Dial — Documento de diseño (v2)

**Versión 2 · 15 de octubre de 2026.** Es la única fuente de verdad sobre qué es el juego.

- La versión original quedó en `spook_dial_design_v1.md`.
- El análisis que llevó a estos cambios está en `docs/01_analisis_diseno.md`.
- El detalle de la mecánica central (reglas, valores numéricos, modelo de datos) está en `docs/02_bucle_central.md`.
- El orden de trabajo y el calendario están en `docs/05_plan_produccion.md`.

Última actualización: 14 de noviembre de 2026.

- 26 de octubre: identificación por características, acción de mayor riesgo y cuota cubierta por los envíos. En la sesión 8, señuelos, barra de identificación, estática por frase y preguntas con 5 s o menos.
- 30 y 31 de octubre (sesión 10): el cuaderno a la derecha e independiente del chat, el celular y el mixer como modos exclusivos, y el cuaderno que vuelve al índice con cada solicitud nueva.
- 31 de octubre (sesión 12): cada dial conserva el color de su aguja, y el video de un amigo aturdido llega cuando se recupera. Después de probar el juego: el chat con estilo de terminal, los textos reales en primera persona y el aviso de daño en el chat.
- 31 de octubre al 2 de noviembre (sesión 14): un amigo sin señal, los videos que se descargan en el chat, Audio Sync en el mixer visto desde arriba y el botón «Sincronizar» del chat.
- 2 de noviembre (sesión 16): el ritmo de la noche en olas, los screamers en cualquier momento, las alucinaciones, la figura de la ventana, la noche 0 (tutorial) y el chat guionado que enseña el celular.
- 4 de noviembre (sesión 18): la noche 0 guiada y sin perder, las 7 entidades como borrador de Claude, el menú de pausa y los temporizadores ×1,5 solo para responder.
- 4 de noviembre (después de probar el Plan 8): la criatura se asoma por la ventana en lugar del jumpscare (se arma detrás del chat o el mixer), las noches 1 y 2 con más sucesos, Audio Sync de 8 aplausos en 2 rondas de 4, Trust que también baja si tardas en contestar y los diales explicados en la noche 0.
- 7 de noviembre (notas de prueba, `docs/17`): las barras arriba de la pantalla, acertar más difícil, los audios en «¿Qué oyes?», Audio Sync más rápido, la batería del celular, las cortinas, la criatura que se queda y hay que revisar, y los accidentes.
- 9 de noviembre (S21c): Snapgram, la red social con fotos reales de gatitos y fotos perturbadoras con poca Sanity.
- 10 de noviembre (S21d): sonidos realistas sin palabras, el Imbunche que llora como guagua, las voces que murmuran, el cuaderno universitario y el arte de interfaz de Claude en pixel art.
- 11 de noviembre, después del Plan 9.1 (`docs/25`): la letra nítida en pantalla completa, el cuaderno con las reglas en una tabla, y la noche 0 en el chat con León, con la página de Gonzalo y unas tarjetas con videos.
- 11 de noviembre (S21e y S21f, `docs/22` a `docs/24`): el mensaje inicial dice qué le pasa al amigo y el lugar solo a veces, los señuelos cuestan 1 s, las características se dicen con otras palabras, olas de verdad con una ola final, el aviso de videos, la criatura se queda un tiempo al azar, la Mano, Trust sin recuperación y más batería.
- 11 de noviembre, tras el primer testeo (S21h, `docs/26` y `docs/27`): las preguntas muestran su costo y no se repiten, lo decisivo va en azul (también en el cuaderno), el chat se ordena en bloques con las respuestas como hojas del cuaderno y la señal en barritas, "Matías piensa" dura 2 s, los señuelos ya no cuestan, y la noche ganada se guarda.
- 11 de noviembre, tras el primer testeo (S21i, `docs/26` §3 y `docs/28`): **dos modos, Normal y Difícil**, que se eligen al empezar una partida. Difícil se desbloquea al terminar Normal. La noche 1 de Normal va armada a mano, las noches 2 a 5 de Normal son algo más fáciles, y en Difícil se identifica leyendo, sin nada destacado.
- 12 de noviembre, tras el primer testeo (S21j, `docs/26` §4 y `docs/29`): **la noche 0 de nuevo**, donde solo funciona lo que León va enseñando y eso parpadea, con lo que cuesta preguntar, lo azul, un audio, la estática y Gonzalo mostrando qué pasa si nadie contesta; el flash es un botón con relieve y las tarjetas van con colores y viñetas. Y 5 pedidos de Benja: el feed más lento, las fotos perturbadoras desde Sanity 50, el ambiente que no baja antes de un screamer y una alarma en cada entrada del PC.
- 12 de noviembre (S21b, `docs/21`): **la historia va en el chat durante la noche**, como el vlog del canal Acá Penan, con una llamada grupal cuando los amigos están juntos y decisiones con forma de accidente. Las consultas no cambian, salvo que cada criatura nueva sale al menos una vez. Las cinemáticas quedan solo para la intro y el final.
- 12 de noviembre (S21l, `docs/31`): **la historia de la noche 1 se juega** en los 3 modos. La ola espera a la historia a lo más 45 s, y la historia no baja Trust de 1.
- 12 de noviembre, después de probar la noche 1 (S21l, `docs/32`): **vlog o emergencia.** Un amigo sin nada que jugar está grabando ("• REC", sin preguntas ni respuestas); lo que pide ayuda va marcado en rojo. Una alarma distinta por amigo, con su propio ritmo; un aviso suave para lo demás; la línea de nuevos; un golpe al empezar cada ola y la música (de Benja). La noche con historia espera a que se abra la llamada, termina a las 06:30 y lleva la historia en su horario, más lenta, sin regalar tiempo.
- 12 de noviembre (S21k, `docs/30`): **un tercer modo, Extremo**, que se desbloquea al terminar Difícil: olas más seguidas, menos tiempo, más obstrucciones, Trust por error ×1,5 y un amigo al azar que empieza cada noche con 1 de vida. Se gana jugando como experto.
- 14 de noviembre (S21n, `docs/33`), tras la segunda prueba de la noche 1: **la noche termina cuando se acaba**, con las olas en cadena y sin saltarse ninguna; la historia se lee más lento; una **nota S, A, B o C** al ganar cada noche, y Difícil 5 con 9 consultas.

---

## 1. Identificación

- **Título:** Spook Dial (juego de palabras con *speed dial*).
- **Plataforma:** PC (Windows).
- **Género:** terror psicológico, simulación de escritorio, puzzle de reglas bajo presión.
- **Audiencia:** 13 años o más.
- **Motor:** Godot 4.7.2.
- **Arte:** pixel art 2D a 1280×720, hecho en Aseprite. Tipografía: Departure Mono, una fuente pixel monoespaciada con licencia libre (OFL).
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
- **La historia se cuenta en el chat, durante la noche** (enmendado por Benja, 12 de noviembre; `docs/21`): lo que los amigos le escriben a Matías y una llamada grupal cuando están juntos. Puede usar las mecánicas que ya existen (separarse, quedar inconsciente, desaparecer sin señal, un accidente o una decisión con forma de accidente), pero nunca agrega otra forma de perder, nunca mata a un amigo y nunca cambia qué criatura llega ni qué acción es la correcta. Las **cinemáticas opcionales** quedan para la introducción y el final.
- Las entidades **no pueden dañar a Matías**: solo asustarlo. El riesgo de muerte siempre recae sobre los amigos.

## 4. Personajes

- **Matías (el jugador).** Nunca se le ve: el jugador mira desde sus ojos.
- **León, Gonzalo y Agustín.** Los amigos que graban. Cada uno tiene nombre, avatar y una personalidad propia, que es solo de sabor (no cambia las reglas). Su voz llega al chat convertida en texto. León es el presentador del canal, Gonzalo el líder y Agustín el miedoso (`docs/21` §3). León es el que termina poseído: los traiciona en las noches 4 y 5, en el chat.
- **Loreto.** La madre de Matías; aparece solo en las cinemáticas.
- **Las entidades.** Siete criaturas del folclore chileno (§13). **El jugador nunca las ve durante las decisiones**: las conoce por lo que dicen sus amigos y por su cuaderno.
- **Los Brujos de Chiloé.** Son los antagonistas de la historia, los que se interesan cada vez más en Matías. Solo aparecen en las cinemáticas y en la ambientación, no como entidad que hay que resolver.

## 5. Estructura de una partida

- **Menú principal:** Continuar (solo si hay una partida en curso; dice la noche y la dificultad: "Continuar: noche 3 · Normal"), Nueva partida, Opciones y Salir.
- **Dos modos: Normal y Difícil** (decisiones de Benja tras el primer testeo, 11 de noviembre; `docs/26` §3). Todo lo que baja la dificultad va a Normal, y el juego de antes del testeo es Difícil:
  - **se eligen solo al empezar una partida nueva:** "Nueva partida" muestra las dos, con Normal marcada y una línea que describe cada una; con una partida guardada, después de elegir pide confirmar que se borra;
  - **Difícil se desbloquea al terminar Normal** (al ganar su noche 5): mientras tanto aparece con un candado y "Termina Normal para desbloquearla.", y al terminar Normal el resumen de la victoria lo avisa;
  - **Normal empieza en la noche 0 (el tutorial) y Difícil en la noche 1**, sin tutorial;
  - **cada modo tiene sus 5 noches** (§14), con las mismas entidades en las mismas noches;
  - **en Difícil se identifica leyendo** (§8.3).
- **Un tercer modo, Extremo** (pedido de Benja, 12 de noviembre; `docs/30`), más exigente que Difícil, pero que se puede ganar de verdad:
  - **se desbloquea al terminar Difícil**, empieza en la noche 1 y se identifica leyendo, como Difícil;
  - **olas más seguidas:** más consultas, en olas de 2 con calmas de 30 a 40 s (en vez de 40 a 60; eran 20 a 30 hasta el Plan 9.9), y menos tiempo para responder que Difícil en cada noche;
  - **más obstrucciones:** más interferencias, Manos, visitas de la criatura, screamers, accidentes y señuelos; sin pista, y Audio Sync de 8 aplausos más rápido;
  - **cada error baja Trust ×1,5:** una respuesta incorrecta −22,5, la de mayor riesgo −30, sin respuesta −22,5 más y un video perdido −15. Tardar en contestar no cambia;
  - **cada noche, un amigo al azar empieza con 1 de vida** (de 3), y su chat lo avisa en rojo al empezar. Con él no se puede fallar, y la acción de mayor riesgo es una apuesta mortal. Los accidentes no le tocan, porque nunca matan;
  - **se gana jugando como experto:** a Extremo solo llega quien terminó Difícil, y la prueba de equilibrio comprueba que cada noche se gana resolviendo cada consulta en unos 11 s (Difícil pide 14), con tiempo libre para sincronizar y scrollear (§14).
- **Noche 0 (tutorial)** antes de la noche 1 (decisión de Benja, sesión 16), **sin perder** (sesión 18). Desde el 11 de noviembre no es un onboarding con un aviso arriba: **León enseña en su chat**, de forma natural, con chistes y sin entidades reales. Desde el 12 de noviembre (S21j, tras el primer testeo), **solo funciona lo que León va enseñando**, cuando terminó de escribir, y **eso parpadea** hasta que se aprieta. Al empezar solo responden su entrada y la pausa; el cuaderno se desbloquea con el nombre, Gonzalo en su parte y el mixer cuando hay que sincronizar; el celular, las cortinas y Agustín, nunca. Los pasos:
  - **describe a Gonzalo** ("usa lentes", "huele mal"), y el cuaderno tiene una sola página, la suya, con su tabla de decisiones;
  - hay que preguntarle qué ve, y León explica que **cada pregunta cuesta 5 s**; después, marcar lo amarillo (un señuelo, "un polerón rojo", no sirve);
  - León explica que **lo azul no se clickea pero decide la fila de la tabla**, y pide preguntarle qué oye: manda **un audio, las tripas de Gonzalo** (tiene hambre), que hay que escuchar;
  - preguntar por el ambiente, marcar la otra y abrir la página de Gonzalo cuando aparece su nombre;
  - León cuenta que Gonzalo está enojado y con hambre, y pide **la mejor decisión** (la del ✓) y después **la peor** (la de la calavera). Si se elige otra, dice que se intente de nuevo;
  - la peor le cuesta un combo, pero manda un video, que hay que descargar;
  - **Gonzalo muestra qué pasa si nadie contesta** (decisión de Benja, D6): pide ayuda en su chat con **15 s reales**, que corren desde que se abre, sin poder preguntar ni responder. Al llegar a 0 decide solo, se pega con la puerta y sale el aviso de daño, sin efecto real. De vuelta con León, explica que si no contestas a tiempo deciden solos, casi siempre mal, y baja Trust;
  - **la estática:** la señal de León baja y un mensaje llega con una de cada 3 palabras tapadas, siempre igual; León explica que con poca señal sus mensajes llegan tapados;
  - **se le corta la señal** y hay que sincronizarlo con el botón de las barritas (en el mixer parpadea su canal y, en tu turno, tu VU-metro). Al volver, se abre su chat, dice que ya estás listo y se despide;
  - después aparecen **4 tarjetas, cada una con un video del juego**: los medidores y cómo baja cada uno, el celular y Sanity, la sombra en la ventana y la cortina, y la Mano con el flash. Desde el 12 de noviembre van **en viñetas, con Connection en verde, Sanity en rojo y Trust en amarillo** (el color de su aguja) y lo importante en ámbar. "Siguiente" pasa de una a otra, y la última empieza la noche 1;
  - el tiempo para responder no corre solo, el plazo del video espera, nadie sale herido y Trust no baja;
  - "Nueva partida" en Normal empieza en la noche 0, y "Saltar tutorial" está en la pausa (`Esc`); las tarjetas tienen su propio "Saltar". Difícil no tiene noche 0.
- **5 noches.** El reloj va de las **00:00 a las 06:00** (formato de 24 horas) en **7 minutos reales**, pero desde el 14 de noviembre (decisión de Benja, S21n, `docs/33`) **la noche no termina a una hora: termina cuando se acaba**, cuando la ola final se resolvió, no queda nada abierto ni videos por recibir, la historia terminó de contarse y pasaron 3 s. Jugar rápido la acorta. El reloj sigue a la misma velocidad y marca cuándo terminaron ("Llegaste a las 04:52"); alguien lento puede pasar de las 06:00.
- **Ritmo de la noche: olas de verdad** (decisiones de Benja, sesión 16 y 11 de noviembre):
  - **el primer minuto es de silencio;**
  - las solicitudes llegan en **olas de 2**, con 4 a 8 segundos de diferencia;
  - cuando se resuelven todas las de una ola viene una **calma de verdad**, de 40 a 60 segundos (o lo que cuente la historia, si es más), para sincronizar, descargar videos, mirar el celular o revisar la ventana. Desde el 14 de noviembre las olas van **en cadena**: cada una llega cuando pasa su calma desde que se resolvió la anterior;
  - la **ola final** es el clímax: los **3 amigos piden ayuda a la vez**, tras su calma, como las demás olas, y desde la noche 2 llega también la criatura;
  - **ninguna ola se salta** (hasta el 14 de noviembre, una ola que ya no cabía antes de la final se saltaba);
  - **en las olas** caen las interferencias, los accidentes (no en la final) y la Mano; **en las calmas**, los videos y los screamers;
  - cuando un amigo queda herido, lo que falta se atrasa unos segundos.
- **Se gana la noche** cuando termina **con la cuota de contenido cumplida**.
- **Se pierde la noche** en cualquiera de estos casos:
  - Sanity, Trust o Connection llegan a 0;
  - un amigo muere;
  - la noche termina sin la cuota cumplida.
- **Al perder:** una pantalla explica qué pasó y la noche se reinicia desde el comienzo. La noche se vuelve a generar, así que no se repite de memoria.
- **Guardado:** al comienzo de cada noche y al ganarla, con la noche siguiente, así que volver al menú no hace repetir una noche ganada. Cuando León se despide en la noche 0 se guarda la noche 1, para no repetir el tutorial si se sale en las tarjetas (tras el primer testeo, 11 de noviembre). La partida guarda también su dificultad; una guardada antes de que existieran los modos se lee como Normal. **El progreso** (qué modos se terminaron) va en su propio archivo, porque la partida se borra al ganar la noche 5.
- **Pausa** (decisión de Benja, sesión 18): sin ningún panel abierto, `Esc` pausa la noche y abre un menú con Continuar, Opciones y Volver al menú. Volver al menú pierde la noche, que se retoma desde su comienzo.
- **Entre noches:** un resumen (contenido obtenido y páginas nuevas del cuaderno) y, desde el 14 de noviembre, **la nota de la noche**, como en Cuphead: S, A, B o C, según lo que esperaron los amigos y las vidas que perdieron. La espera promedio de cada pedido de ayuda (consulta, accidente o decisión de la historia) se compara con la meta del modo (Normal 15 s, Difícil 20 s, Extremo 15 s): hasta la meta da 3 puntos, hasta 1,5 veces 2, hasta el doble 1. Ninguna vida perdida da 3 puntos, una 2 y dos 1 (la herida con que empieza un amigo en Extremo no cuenta). S con 5 o 6 puntos, A con 4, B con 2 o 3 y C con 0 o 1. La nota no se guarda. Después, una cinemática opcional.
- **Final único:** sobrevivir las 5 noches, como en FNAF.

## 6. El escritorio

Cada objeto cumple una función:

| Objeto | Función |
| --- | --- |
| **PC** | Muestra siempre las 3 entradas de los amigos: estado, señal, temporizador y avisos. Al hacer clic en una se abre su conversación. También muestra el contador de contenido de la noche. **Una entrada en alerta pita cada medio segundo** con la alarma de su amigo (un doble bip, un zumbido y un trino), desde que entra en alerta y con su propio ritmo, y su luz se enciende con el pitido; se calla durante Audio Sync y mientras suena un audio (Plan 9.8). Un "•" junto al nombre dice que su chat tiene algo sin leer. |
| **Cuaderno** | El manual: un índice con el nombre de cada entidad y una página por entidad con sus reglas (§12). |
| **Mixer** | Audio Sync. Al hacer clic se abre visto desde arriba: sus 3 faders son los canales de los 3 amigos, y sus dos VU-metros azules muestran el ritmo de Matías (el de la izquierda) y el del amigo (el de la derecha) (§10.6). |
| **Celular** | Muestra la hora y su batería. Al abrirlo se scrollea con la rueda del mouse para recuperar Sanity (§10). |
| **Diales** (en la pared) | Connection, Sanity y Trust. Tienen cara de manómetro, un ícono propio y un LED de alerta, para que no dependan del color. Cada uno conserva el color de su aguja: Connection verde, Sanity roja y Trust amarilla. |
| **Micrófono** | Su LED se enciende al responder (ambientación). |
| **Ventana y cortinas** | Las cortinas se abren y se cierran con un clic (§10.2). Por la ventana se asoma la criatura (§11). |

## 7. Interfaz

- **Barras arriba de la pantalla** (decisión de Benja, 7 de noviembre): Connection, Sanity y Trust, en el hueco entre el chat y el cuaderno, que no las tapan. Cada una tiene el color de su dial, titila si baja de golpe y prende una luz bajo 25.
- **El PC siempre muestra la lista** de las 3 entradas. La conversación abierta se ve destacada.
- **Panel de chat** a la izquierda de la pantalla. Desde el primer testeo (11 de noviembre), cada control tiene su forma y cada bloque, su título:
  - una pestaña por amigo, con aviso y temporizador;
  - el historial de la conversación, que se scrollea con la rueda del mouse y toma el alto que sobra;
  - la barra de descarga, cuando el amigo mandó un video;
  - la identificación: cuántas características van marcadas, "Matías piensa…" o el nombre de la entidad, con el ícono del cuaderno porque abre su página; y al lado, **el botón de sincronizar**, cuadrado, con la señal del amigo en barritas (de 0 a 4; verdes, ámbar o rojas según la estática). **Sin señal parpadea** con un borde rojo, que queda fijo con "Reducir destellos";
  - **PREGUNTAR:** los 4 botones de pregunta, cada uno con su ícono (ojo, parlante, nube y huella), su etiqueta corta y **lo que cuesta ("−5 s")** o su marca (§8.4). Al preguntar, la pestaña del amigo muestra el "−5 s";
  - **RESPONDER:** las respuestas son **hojas del cuaderno**, con el número de su columna de la tabla en una nota adhesiva, una debajo de otra (§8.5). Las de un accidente, que se responde sin cuaderno, son botones de terminal.
  - Los títulos dicen por qué no se puede usar un bloque: "PREGUNTAR · SIN TIEMPO", "RESPONDER · ABRE EL CUADERNO" o "RESPONDER · SIN SEÑAL: SINCRONÍZALO".
- **Cuaderno** a la derecha, como espejo del chat y del mismo tamaño. Mientras está abierto tapa los diales; el PC queda visible entre los dos paneles.
- **El chat y el cuaderno son independientes:** abrir uno no abre ni cierra el otro, y son los únicos paneles que pueden estar abiertos a la vez. El clic derecho sobre un panel lo cierra; `Esc`, o un clic en el escritorio fuera de los paneles, cierra los dos.
- **El celular (redes sociales) y el mixer (Audio Sync) son modos exclusivos:** se usan sin ningún otro panel ni objeto abierto. Ese es el costo de oportunidad.
- **Mensajes:** aparecen escritos progresivamente, con un sonido breve por mensaje.
- **El chat se ve como una terminal:** cada mensaje lleva el nombre de quien escribe ("LEÓN:", "MATÍAS:") en su color, y los avisos del juego, como el de daño, van en rojo y centrados.
- **La letra se ve nítida en cualquier pantalla** (pedido de Benja, 11 de noviembre): Departure Mono solo es nítida si su tamaño real es múltiplo de 11 px. En pantalla completa a 1080p, la letra común pasa de 11 a 15 px (22 reales), un poco más grande; a 1280×720, 1440p y 4K queda igual.
- **Alarma:** cuando un amigo espera respuesta, su entrada parpadea y suena una alarma.

## 8. Mecánica central: solicitudes y reglas

### 8.1 Flujo de una solicitud

1. **Llega.** Un amigo pide ayuda con un mensaje corto: saluda ("¡Mati, ayuda!!", "¿Estás ahí?") y dice **qué le pasa** ("Me perdí.", "Algo me viene siguiendo.", "Creo que escuché algo."). **Dice dónde está solo a veces** (60 % en la noche 1 y cada vez menos, hasta 40 % en la 5; siempre en la noche 0), y a veces trae una pista (decisión de Benja, 11 de noviembre). Reconocer rápido a la criatura es parte de la habilidad, así que no importa que a veces el lugar la delate. **No describe lo que ve ni dice el nombre de la entidad**: el experto es Matías, y la información hay que preguntarla (§8.4). Empieza su temporizador.
2. **El jugador identifica la entidad**, de memoria o con las características que le cuenta el amigo al preguntar (§8.3).
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

Lo que cuenta el amigo, al preguntar, es de tres tipos:

- **Características.** Son fijas de cada entidad (por ejemplo, "un hombrecito" o "huele a azufre"). Aparecen **destacadas** y se pueden clickear. **Cada una se dice de varias formas** (decisión de Benja, 11 de noviembre): "un hombrecito" también puede ser "un enano" o "alguien chiquitito, como un niño viejo", y "neblina helada", "una niebla que te congela los huesos". Así hay que reconocerla de verdad. El cuaderno muestra siempre el mismo nombre (§12).
- **Señuelos.** Aparecen destacados igual que las características, pero no ayudan a identificar: describen el lugar, un olor, un sonido o algo que se ve. Sirven para camuflar las características.
- **Observaciones.** Cambian en cada situación y deciden qué regla se aplica. **Van en azul** y no se clickean (decisión de Benja, 11 de noviembre, tras el primer testeo): lo amarillo dice qué criatura es y lo azul, qué hacer en la tabla. Un audio también va en azul, porque es una observación.

Hay dos formas de identificar a la entidad:

- **De memoria:** quien la reconoce abre su página directamente.
- **Con las características:** el jugador clickea las frases destacadas. Una característica queda marcada; un señuelo vibra y se pone rojo. Una barra muestra cuántas características van marcadas (1 de 2). Con las 2 marcadas, tras una breve espera (**2 segundos**, mientras Matías piensa; eran 3 hasta el primer testeo), aparece el nombre de la entidad, y al clickearlo se abre su página.

Detalles:

- Así se premia a quien memoriza, sin castigar demasiado a quien no.
- Una característica tapada por la estática no se puede clickear: hay que preguntar (§8.4) para recuperarla.
- **En Difícil no se destaca nada** (decisión D3 de Benja tras el primer testeo): las características, los señuelos y las observaciones van como el resto del texto, nada se clickea, no hay barra de identificación y Matías no piensa. Se reconoce a la criatura leyendo y se busca su página en el índice del cuaderno. **El audio sigue en azul y se clickea**, porque es la forma de oírlo, y **el cuaderno no cambia**: es el manual (decisiones de Benja en S21i).
- El amigo cuenta, al preguntar, **2 características** que distinguen a la entidad entre las conocidas, mezcladas con señuelos: 1 en la noche 1 y hasta 4 en la noche 5. **Un señuelo no cuesta tiempo:** solo vibra y se pone rojo (decisión D4 de Benja tras el primer testeo, que reemplaza el "−1 s" del 11 de noviembre, porque castigaba demasiado).
- Cada solicitud elige al azar con qué forma dice el amigo cada característica, y la usa siempre, también en la pista. El clic la marca igual.
- El mensaje inicial puede traer **una pista**: una de las 2 características (siempre en la noche 1 y cada vez menos hasta la noche 5).

### 8.4 Preguntas de seguimiento

Junto a las respuestas hay preguntas: **¿Qué ves? · ¿Qué oyes? · ¿Cómo está el ambiente? · ¿Hay rastros?**

- **Es la forma de averiguar casi todo** (decisión de Benja, 3-nov): el mensaje inicial no describe nada. Elegir las preguntas correctas es parte del juego, porque cada una cuesta tiempo.
- Cada pregunta cuesta **5 segundos** del temporizador (el amigo tarda en mirar). Con 5 segundos o menos ya no se puede preguntar.
- La respuesta trae las características y los señuelos de esa categoría, y todas las observaciones de esa categoría. También puede llegar con estática si la señal sigue baja.
- **Cada botón muestra lo que cuesta** ("−5 s"), y al preguntar, la pestaña del amigo también (decisión de Benja, 11 de noviembre, tras el primer testeo).
- **Una pregunta ya respondida no se repite:** queda con ✓, más tenue. **Excepción:** si la estática tapó algo que sirve de su respuesta (una característica, un señuelo, una observación o el audio; en la respuesta de "nada", cualquier palabra), el botón vuelve con un ícono de estática, porque hay que volver a preguntar para recuperarlo, y la estática se tira de nuevo.
- Los botones dicen la pregunta corta (¿Qué ves?, ¿Qué oyes?, ¿Ambiente? y ¿Rastros?); Matías pregunta con la frase completa.
- Como identificar lleva más trabajo, cada solicitud tiene más tiempo (de 90 s en la noche 1 a 65 s en la 5) y hay menos solicitudes por noche (`docs/02` §6).

### 8.5 Responder desde el cuaderno

- Cada entidad tiene **4 acciones propias**, con el sabor de su leyenda.
- Los botones de respuesta del chat muestran **las acciones de la página que el jugador tiene abierta para ese amigo**. Sin una página abierta, el chat indica que hay que abrir el cuaderno.
- **Se ven como hojas del cuaderno** (tras el primer testeo): papel cuadriculado, con el número de la columna de la tabla en una nota adhesiva y la acción escrita.
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

Si el temporizador llega a 0, el amigo decide solo (al azar entre sus 4 acciones) y la consecuencia se resuelve igual. Además baja Trust por no contestar. Un amigo sin señal también decide solo al acabarse su tiempo, pero elige mal (al azar entre las 3 acciones que no son la correcta), y esa decisión no baja Trust (§10.1).

### 8.8 Audios en «¿Qué oyes?»

Decisión de Benja, 7 de noviembre.

- Cada entidad tiene una observación que **el amigo manda como audio** en vez de contarla. Se escucha con un clic en el mensaje, las veces que se quiera: lo único que cuesta es el tiempo que pasa.
- **Lo que se oye cambia la acción correcta:** que El Tue Tué grite 1 vez, 3 veces o ninguna son casos distintos, y que La Calchona bale o bufe, también. Las reglas del cuaderno lo dicen.
- Las características que se oyen siguen siendo texto clickeable: el audio no identifica a la entidad.
- La estática tapa el audio entero o no lo tapa (§8.2). Tapado no se puede escuchar: hay que volver a preguntar, y la pregunta vuelve a habilitarse (§8.4).
- El audio va en azul, como las demás observaciones (§8.3).
- La opción "Subtítulos de los audios" (§19) muestra qué se oye.

### 8.9 Accidentes

Decisión de Benja, 7 de noviembre.

- Un amigo puede tener un accidente sin que nadie tenga la culpa: se tropieza, se corta o se cae al agua. Son 1, 1, 2, 2 y 3 por noche, y no hay en la noche 0.
- Se responde en el chat, en 15 s, con las opciones del accidente, sin cuaderno: una buena idea y 1 o 2 malas, que se eligen con sentido común.
- Una mala respuesta o no contestar le quita 1 de vida y lo deja aturdido, sin bajar Trust. La buena idea no le quita nada.
- Solo le pasa a un amigo libre, con señal y con más de 1 de vida: **un accidente nunca mata**. Si la ola está llena, espera.

## 9. Consecuencias

- **Vida:** cada amigo tiene **3 PV por noche**, que se restauran al empezar la siguiente.
- **Herido:** queda **aturdido 15 segundos**; en ese tiempo no pide ayuda ni envía nada. Si le tocaba enviar un video, lo envía apenas se recupera.
- **En el chat:** el amigo herido grita ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y el juego avisa en rojo cuánta vida le queda: "León recibió daño: 2/3".
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
  - con 0, el amigo **queda sin señal** (decisión de Benja, sesión 14):
    - le siguen llegando situaciones, pero su mensaje llega tapado entero y no lee las preguntas ni las respuestas de Matías;
    - si Matías lo reconecta con Audio Sync antes de que se acabe su tiempo, se pregunta y se responde como siempre. Si no, elige mal (§8.7);
    - mientras haya amigos sin señal, Trust baja, más rápido cuantos más sean;
    - no envía videos hasta que se reconecta.
- **Audio Sync, individual y cuando el jugador quiera.** En el mixer se elige el canal de un amigo con su fader, o se usa el botón de sincronizar del chat de ese amigo (el de las barritas de su señal), que abre el mixer en su canal (decisión de Benja, sesión 14), y se sincroniza. La entrada del PC siempre abre el chat. Si sale bien, su señal vuelve a 100. Así el jugador puede decidir gastar tiempo en mantener alta la señal antes de que algo falle.
- **El dial de la pared** muestra el promedio de las tres señales. Llega a 0 solo si todos están desconectados.
- **Si cualquiera de los 3 diales (Connection, Sanity o Trust) llega a 0, se pierde la noche.**

### 10.2 Sanity

- Baja lento todo el tiempo, y de golpe con cada screamer (una cantidad fija).
- Se recupera **scrolleando el celular**: sube mientras el jugador scrollea y deja de subir cuando se detiene.
- **El celular tiene batería** (decisión de Benja, 7 de noviembre): un tope por noche, sin recarga, que alcanza para **48 s** de scroll (desde el 11 de noviembre; antes 38). Se gasta al scrollear y con **cada flash, que gasta 10 %** (§11, la Mano), así que hay que guardar batería. Sin batería no hay feed ni flash.
- **Snapgram** (decisión de Benja, 9 de noviembre): la red social del celular imita la forma de Instagram, con barra superior, cabecera, foto cuadrada, íconos y barra de navegación. Todo son **fotos reales de gatitos** (mixed media): las cuentas no tienen nombre, el texto se simula con barras grises y los botones son solo dibujo.
- **El feed avanza lento** (pedido de Benja, 12 de noviembre): cada paso de la rueda mueve 30 px (antes 60), para que se alcancen a ver las fotos. Sanity sube igual, porque cuenta el tiempo scrolleando.
- **Fotos perturbadoras** (decisión de Benja, 9 de noviembre; desde el 12 de noviembre, desde Sanity 50): con Sanity 50 o menos, 1 de cada 4 publicaciones es una foto perturbadora, y van subiendo en escalones parejos (2 y 3 de cada 4) hasta **4 de cada 4 con Sanity 10 o menos**. Solo es un susto: no resta Sanity. Una foto a la vista nunca cambia, y un lugar perturbador lo sigue siendo si Sanity baja más.
- **Las cortinas** (decisión de Benja, 7 de noviembre): se abren y se cierran con un clic. Cerradas, el cuarto se oscurece y Sanity baja de a poco. Abiertas no pasa nada, salvo que la criatura esté afuera (§11): entonces baja rápido.
- **Toda noche se puede ganar** (requisito de Benja, 11 de noviembre): la batería de los flashes, más la que hace falta para reponer Sanity jugando bien, no pasa de 100 % (en la noche 5 son 90 %). Lo comprueba `test/test_balance.gd`.
- **Efecto gradual:** mientras más baja, más se oscurece la visión con una viñeta y más **screamers auditivos falsos** aparecen (sonidos que no vienen de nada).
  - Son sonidos del cuarto (golpes en la ventana, pasos, susurros y rasguños) y también del juego (la estática de una interferencia y el celular vibrando). Confunden: el jugador mira y no hay nada (decisión de Benja, sesión 16).
  - No restan Sanity y nunca suenan durante Audio Sync.
- Con 0, Matías entra en pánico y **se pierde la noche**.

### 10.3 Trust

- Baja al elegir acciones riesgosas (§9), al no contestar a tiempo y mientras haya amigos sin señal (§10.1).
- **También baja si tardas en contestar** (decisión de Benja, 4 de noviembre): cada solicitud que lleva más de 30 s abierta le quita 0,25 por segundo. Preguntar cuenta como tiempo abierto. Responder rápido no cuesta nada.
- **Baja 10 si se pierde un video** (decisión de Benja, 11 de noviembre): el amigo arriesgó para grabarlo y Matías no lo descargó.
- **No se recupera durante la noche** (decisión de Benja, 11 de noviembre), así que cada error pesa: una respuesta incorrecta le quita 15, no contestar 15 más, y la acción de mayor riesgo 20. Con 7 respuestas incorrectas se pierde cualquier noche.
- **Efecto gradual:** mientras más baja, **menos tiempo esperan los amigos tu respuesta** (sus temporizadores se acortan).
- Con 0, los amigos ya no quieren pedirte ayuda y **se pierde la noche**.
- Vuelve a 100 al comienzo de cada noche.

### 10.4 Contenido (la cuota)

- Cada noche tiene una **cuota de videos**. Cumplirla es condición para ganar la noche.
- El contenido llega por dos vías:
  - **Envíos programados.** Los amigos graban y mandan videos durante la noche, y **son justo los suficientes para cumplir la cuota** si el jugador los recibe todos.
  - **La acción de mayor riesgo.** Si el amigo sobrevive, llega un video extra (si quedó herido, cuando se recupera). Sirve para compensar los envíos perdidos, a cambio de arriesgar al amigo y su confianza.
- **Los envíos programados llegan en las calmas** entre las olas (§5), a tiempo para descargarlos antes de la ola siguiente.
- **Aviso cuando los videos ya no alcanzan** (decisión de Benja, 11 de noviembre): si al perderse un video los que quedan (los recibidos, los que esperan su descarga y los que faltan llegar) ya no alcanzan la cuota, el chat de ese amigo avisa en rojo que **alguien tiene que arriesgarse**, porque la acción de mayor riesgo da un video extra. Avisa una vez por cada video que se pierde. El PC muestra los videos en rojo ("Videos: 1 de 3 (faltan)") hasta que vuelvan a alcanzar.

### 10.5 Recibir videos (Receive Media)

- El amigo avisa en su chat que mandó un video. Hay **15 segundos para empezar a descargarlo** (decisión de Benja, sesión 14).
- La descarga se hace dentro del chat, **manteniendo presionada** su barra. Tarda **10 segundos**; con la señal de ese amigo bajo 50, tarda 15, y sin señal no avanza. Si se suelta, se pausa.
- Desde que empieza, hay **20 segundos para terminarla**.
- Si no se empieza o no se termina a tiempo, el video se pierde.

### 10.6 Audio Sync

- La base sube noche a noche (90, 100, 115, 130 y 145 golpes por minuto), y cada ronda va un 15 % más rápida que la anterior (decisión de Benja, 7 de noviembre).
- Se empieza cuando el jugador quiere, con un clic en el mixer, que se abre visto desde arriba. Se elige el canal del amigo en su fader, o con el botón de sincronizar del chat de ese amigo, que abre el mixer en su canal y empieza la ronda enseguida.
- Una base marca el tiempo, y el amigo marca un ritmo de **4 aplausos**. El mixer parpadea con el ritmo y suena (decisión de Benja, sesión 14). Las noches de 8 aplausos son **2 rondas de 4 seguidas**, cada una con su cuenta y su patrón: si se falla la segunda, se vuelve a la primera (decisión de Benja, 4 de noviembre). La señal solo vuelve a 100 al terminar todas.
- Después, el jugador lo imita con **clics en el mixer o con la barra espaciadora**.
- El mixer muestra una fila de **8 luces**, las de una ronda, aunque la noche tenga 2 (decisión de Benja, 8 de noviembre). Junto a la fila, si hay varias rondas, una luz por ronda, visible desde que se abre el mixer: azul la que está en curso y verde las pasadas; al fallar se apagan (decisión de Benja, 9 de noviembre).
- Los dos VU-metros azules del mixer muestran los dos ritmos: el de la izquierda, el del jugador, y el de la derecha, el del amigo.
- Se puede reintentar las veces que se quiera, y se puede salir para atender otra cosa.

## 11. Screamers

- **Llegan en las calmas** entre las olas (decisión de Benja, 11 de noviembre; antes, en cualquier momento), con las reglas de justicia (sesión 16). Una visita de la criatura llega en la ola final.
- **Tipos:**
  - ambientales: la cortina se abre o se cierra sola (decisión de Benja, 7 de noviembre), aparece la figura en la ventana, el celular vibra, las luces parpadean. La figura de la ventana está escondida y solo aparece al asustar (decisión de Benja, sesión 16);
  - sobre el cuaderno: se cierra de golpe, o una mancha de tinta tapa las reglas durante 5 segundos;
  - **la criatura en la ventana** (antes, un jumpscare de pantalla completa; decisión de Benja, 4 de noviembre): desde la noche 2 (1, 2, 2 y 3 veces por noche). Se asoma por la ventana con respiración pesada y golpes en el vidrio. Se arma solo cuando el chat o el mixer tapan la ventana, y al cerrarlos ya está ahí. No tapa la pantalla ni pausa la noche. **Se queda un tiempo al azar, entre 15 y 40 s desde que llega** (decisión de Benja, 11 de noviembre; antes, 25 s fijos): si la cortina estaba cerrada, la abre; mientras esté afuera con la cortina abierta, Sanity baja rápido. Cerrar la cortina no la espanta, y con la cortina cerrada no se oye, así que hay que abrirla para revisar si sigue ahí y volver a cerrarla si sigue.
- **La Mano** (idea de Benja, 11 de noviembre): el segundo enemigo del cuarto, un brazo negro y peludo (`hand_sprite`).
  - **Cómo se acerca:** asoma por el borde derecho hacia un dial al azar (Connection, Sanity o Trust, los 3 por igual) y tarda unos 12 s en llegar, a tirones de 0,5 a 0,7 s: en cada uno alterna sus 3 cuadros y tiembla 1 o 2 píxeles, como un movimiento forzado de Undertale.
  - **Cómo suena:** en cada tirón, un crujido sutil de algo que se retuerce, con o sin el cuaderno abierto.
  - **Dónde se ve:** en la pared, detrás de los paneles: el chat, el mixer y el cuaderno la tapan, y entonces solo la delata el crujido.
  - **Qué hace:** si agarra el dial, lo baja 6 puntos por segundo hasta 15, nunca hasta 0, y se queda hasta que la espantan. En Connection baja las 3 señales parejo, así que también sube la estática.
  - **Cómo se espanta:** con el **flash del celular**, el botón FLASH de la barra superior del celular abierto (desde el 12 de noviembre, un botón con relieve que se hunde al apretarlo; antes, un rayo que no parecía botón), que la hace desaparecer al instante. Cada flash gasta 10 % de la batería, haya o no una Mano.
  - **Cuándo llega:** en las olas, 1, 1, 2, 2 y 3 veces en las noches 1 a 5. No coincide con la criatura: espera a que se vaya, y la criatura no se arma mientras la Mano está en la pared. La enseña una tarjeta con video al final de la noche 0.
- **La sombra:** lo que se asoma por la ventana (la criatura y la figura) hace sombra sobre el escritorio. Con la cortina cerrada no hay sombra, para no delatar a la criatura (decisión de Benja, 8 de noviembre).
- **Señal previa breve:** un parpadeo de luz. **El sonido ambiente no baja** (pedido de Benja, 12 de noviembre: bajarlo arruinaba el suspenso).
- **Reglas de justicia:**
  - los que tapan la pantalla **pausan los temporizadores**;
  - nunca ocurren en los últimos 5 segundos de una decisión;
  - no empiezan mientras suena un audio de un amigo, para que no se confundan con él.
- Cada uno resta una cantidad fija de Sanity. No dañan a Matías.
- **El susto guionado** (decisión de Benja, sesión 16). Desde el 11 de noviembre ya no está en la noche 0, que enseña con el chat de León y las tarjetas; queda guardado (`data/scripts/scare_chat.tres`) para la progresión guionada de la historia. Después del susto:
  1. un amigo escribe: "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar";
  2. Matías responde con un botón: "Creo que me estoy volviendo loco, no sé si puedo seguir";
  3. el amigo contesta: "Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar";
  4. el borde del celular parpadea hasta que Matías lo abre.

  Es el primero de los momentos guionados entre los amigos: más adelante habrá una progresión guionada (`docs/05`).

## 12. El cuaderno

- **Se ve como un cuaderno universitario** (decisión de Benja, 10 de noviembre): hoja cuadriculada con margen rojo y espiral, la tapa verde del cuaderno del escritorio, una mancha de café y garabatos a lápiz. Las pestañas son notas adhesivas. La letra es Departure Mono, la del chat, para que se lea rápido.
- **Índice:** una pestaña con el nombre de cada entidad conocida.
- **Página de una entidad:**
  - folclore breve y un boceto;
  - sus características, para quien quiera aprenderlas de memoria, cada una con un nombre fijo, aunque el amigo la diga con otras palabras, y sin decir qué pregunta la trae (decisiones de Benja, 11 de noviembre). Van **con destacador amarillo**, como en el chat (decisión de Benja en S21h);
  - **las reglas en una tabla**, en orden (vale la primera fila que se cumpla): **Condición | 1 | 2 | 3 | 4**, con una marca por acción: ✓ verde la correcta, una **calavera** roja la de mayor riesgo, que da un video extra, y ✗ las otras (decisión de Benja, 11 de noviembre). Las observaciones ya no tienen una lista aparte: la condición de cada fila dice qué hay que averiguar. **Las condiciones van en lápiz pasta azul**, como las observaciones del chat, para conectar lo que cuenta el amigo con la fila (decisión de Benja en S21h);
  - las 4 acciones, numeradas como las columnas.
- **La hoja**, con la cuadrícula más suave (pedido de Benja, 11 de noviembre).
- **Memoria por amigo:** el cuaderno recuerda la página abierta de cada amigo y salta a ella al cambiar de chat. Cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice.
- **Está deliberadamente limitado:** no tiene todas las páginas desde el principio; las nuevas llegan entre noches.

## 13. Entidades

Siete criaturas del folclore chileno, con la plantilla de `docs/02`. Desde la sesión 18 son datos (`data/entities/`): un borrador de Claude, con las 3 de `docs/09` y 4 nuevas, que Benja corrige.

| Entidad | Lugar habitual | Noche en que aparece |
| --- | --- | --- |
| El Tue Tué | Casas, techos, árboles | 1 |
| La Calchona | Caminos, campo | 1 |
| El Cuero | Lagos | 2 |
| La Viuda | Caminos | 2 |
| El Trauco | Bosque | 3 |
| El Basilisco | Casas, bajo el piso | 4 |
| El Imbunche | Cuevas | 4 |

**Cuidado con el folclore (público de 13 años o más):** en la tradición, el Trauco tiene contenido sexual, y el Imbunche implica la mutilación de un niño. Se usan sus otros rasgos (hachazos y mirada; guardián deforme), sin esos elementos. El Imbunche fue un niño robado: en su audio, entre los gruñidos, puede oírse un llanto de guagua, y eso cambia la acción correcta (decisión de Benja, 10 de noviembre). Fuentes sugeridas: Oreste Plath, *Geografía del mito y la leyenda chilenos*, y Memoria Chilena.

## 14. Progresión de las noches

| Noche | Dónde están los amigos | Entidades nuevas | Qué se agrega |
| --- | --- | --- | --- |
| 0 (tutorial) | La cabaña | Gonzalo, su página propia | Sin perder (§5). León enseña en su chat: preguntar, marcar, abrir la página, la mejor y la peor decisión, descargar el video y sincronizar. Después, 4 tarjetas con videos: los medidores, el celular, la ventana y la Mano. |
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust, ya sin ayuda. La señal baja un poco, con 1 interferencia y Audio Sync de 4 aplausos, y hay 2 screamers ambientales, 1 accidente y 1 visita de la Mano. El mensaje inicial siempre trae una pista. |
| 2 | Camino y lago | El Cuero, La Viuda | Señal por amigo, interferencias, Audio Sync de 4 tiempos, estática y screamers regulares. |
| 3 | Bosque | El Trauco | Sin pista en el mensaje inicial: preguntar es necesario. El Trauco comparte 2 características con La Calchona. |
| 4 | Casa abandonada y cueva | El Basilisco, El Imbunche | Audio Sync de 8 aplausos (2 rondas de 4) y varias solicitudes a la vez. |
| 5 | Todos los lugares | — | Todo a la vez, al máximo. |

**Normal y Difícil** (§5) tienen las mismas entidades en las mismas noches, pero cada modo tiene sus valores (`docs/02` §6; `data/nights/normal/` y `data/nights/hard/`). La tabla de arriba describe Difícil, que es el juego de antes del primer testeo. Normal es una curva más suave:

- **La noche 1 de Normal va armada a mano** (pedido de Benja tras el primer testeo; `docs/26` §3.2), para que lo que llega no llegue junto:

  | Momento | Qué pasa |
  | --- | --- |
  | Silencio | 45 s |
  | Ola 1 | 1 consulta, y su video cuando se responde o cuando le quedan 30 s |
  | Calma | 1 screamer |
  | Ola 2 | 2 consultas separadas por 30 a 45 s, la Mano y 1 interferencia |
  | Calma | 1 screamer |
  | Ola final (hacia las 03:04) | consulta, video y consulta, sin llegar juntos |

  Hay 90 s para responder, la cuota es de 2 y no hay accidente: los accidentes empiezan en la noche 2.
- **Las noches 2 a 5 de Normal** tienen más tiempo para responder, menos consultas, menos señuelos, accidentes, interferencias, Manos y visitas de la criatura, y un Audio Sync más lento. Los screamers son los mismos: son el terror, no la dificultad.

**Extremo** (§5; `data/nights/extreme/`) es más duro que Difícil en cada noche: de 11 a 15 consultas en olas de 2 con calmas de 30 a 40 s, de 45 a 38 s para responder, y más interferencias, Manos, visitas de la criatura, screamers, accidentes y señuelos. Su noche 1 se gana al ritmo de Difícil, y desde la noche 2 pide jugar como experto. Los valores están en `docs/02` §6.

**Toda noche se puede ganar** (requisito de Benja): la prueba de equilibrio lo comprueba en los 3 modos con quien juega bien (12 s por consulta en Normal, 14 en Difícil y 11 en Extremo), y revisa que el tiempo libre alcance para sincronizar a los amigos y reponer Sanity con el celular. La referencia es Difícil 5, que Benja probó: difícil pero ganable.

## 15. Historia

**Durante la noche** (decisión de Benja, 12 de noviembre; `docs/21`), la historia se cuenta en el chat. Los amigos graban un vlog para su canal, **Acá Penan**, y cada noche es un capítulo:

- **la llamada grupal:** cuando están los 3 juntos y no hay nada que jugar, el chat es una llamada grupal, con un ícono, y no se puede cambiar de chat. Si llega una consulta, un accidente, una decisión o un video, se separa en los 3 chats;
- **cuándo llega:** al empezar la noche, al terminar una ola, 15 s antes de la siguiente, después de la ola final y cuando se responde una decisión; nunca en medio de una ola, salvo las decisiones. Marca el chat como no leído, sin alarma, y leerla es opcional;
- **las decisiones** llegan como un accidente (alarma y 15 s) y pueden bajar Trust, quitar segundos a la próxima consulta de un amigo o hacerle daño, sin matarlo nunca;
- **las consultas no cambian:** la criatura y el lugar siguen al azar, aunque la historia hable de las criaturas de la noche. Cada criatura nueva de la noche sale al menos una vez, y solo se fuerza cuando falta;
- va igual en los 3 modos y se repite igual al perder una noche;
- **la ola espera a la historia** mientras cuenta algo antes de ella, a lo más 45 s (decisión de Benja, S21l): jugando bien nunca espera. Si la ola final llegaba encima de la ola anterior, lo que iba antes de ella se saltaba (las decisiones también), pero los amigos se reunían igual; desde el 14 de noviembre ya no pasa, porque la final espera a que se resuelva la ola anterior;
- **la historia nunca hace perder:** su daño no le quita vida a quien tiene 1, y Trust no baja de 1 por ella (decisión de Benja, S21l);
- **vlog o emergencia** (pedidos de Benja después de probar la noche 1, `docs/32`): un amigo sin nada que jugar está grabando, y su chat no muestra preguntas ni respuestas, sino "• REC · LEÓN ESTÁ GRABANDO". Lo que pide ayuda (el mensaje inicial, las respuestas, un accidente y la pregunta de una decisión) lleva "▲" y la barra en rojo, y una línea "▲ LEÓN PIDE AYUDA" lo separa del vlog. Las líneas del vlog que llegan a un chat que no se mira suenan con un "pop" suave y marcan la entrada con un "•"; al abrir un chat, una línea "NUEVOS" dice dónde empezar. Un golpe de sonido marca el inicio de cada ola, y la música cambia entre la calma y las olas (las pistas las consigue Benja);
- **la historia se lee en vivo:** la noche espera congelada a que se abra la llamada, y cada línea queda lo que se tarda en leerla: desde el 14 de noviembre, lo que tarda en escribirse, 3,5 palabras por segundo y 1 s (antes, 15 letras por segundo). El director pone la historia en su horario (la primera ola llega cuando terminó el susto y cada calma dura lo que cuenta). Del 12 al 14 de noviembre, una noche con historia terminaba a las 06:30 para no regalar tiempo; desde el 14 (`docs/33`), toda noche termina cuando se acaba, también la historia;
- la noche 1 está escrita, aprobada e implementada (S21l, `docs/31`); la noche 2, pospuesta, y las noches 3 a 5, en esquema (`docs/21`).

**Las cinemáticas opcionales** (introducción y final), basadas en la versión Twine:

- Matías acompaña a sus amigos a una cabaña aislada cerca de Puerto Montt.
- Los Brujos de Chiloé se interesan cada vez más en él.
- León termina poseído.
- Lo que Matías realmente buscaba no era contenido, sino amistad.

El guion de las cinemáticas lo escribe Benja. Los guiones del chat se trabajan en un documento compartido (enlazado en `docs/21`).

## 16. Arte

- **Pixel art 2D** a 1280×720, en perspectiva de un punto de fuga.
- **Cámara que mira hacia el mouse (a prueba):** toda la escena tiene un zoom leve (×1,05) y se desplaza hacia donde apunta el mouse, como si el jugador mirara hacia ese lado. El desplazamiento no supera el margen del zoom, así que todos los objetos siguen alcanzables. Si no funciona, se quita.
- **Fotos reales en el celular** (decisión de Benja, 9 de noviembre): las fotos de Snapgram son la única excepción al pixel art. Se muestran a 232×232, sin escalar.
- **Iluminación baja.** La pantalla del PC y la ventana son las fuentes principales. Cada entidad puede teñir la luz, pero siempre con sonido además del color.
- **Detalle técnico:** `docs/03_plan_arte.md`.

## 17. Sonido

- Es clave para la tensión: estática, ruidos del entorno de los amigos y silencios.
- Los amigos suenan mientras escriben, como en Undertale: un sonido muy corto cada tantas letras, con una voz distinta para cada uno (sonido, altura y ritmo). Solo suena el chat que se está viendo, y no suena encima de un audio. Matías y los avisos del juego no tienen voz (decisión de Benja, 8 de noviembre). Desde el 10 de noviembre, cada sonido es **una sílaba murmurada que llega por un micrófono barato**, no un pitido de consola (decisión de Benja).
- **Sonidos realistas y de terror** (decisión de Benja, 10 de noviembre): casi todos se sintetizan (`tools/make_sounds.py`), y lo que la síntesis no logra (animales, llanto, gruñidos) sale de grabaciones de dominio público o CC0, con sus créditos en `audio/source/creditos.md`.
- **Ningún sonido dice palabras** (decisión de Benja, 10 de noviembre): las voces de las criaturas son gritos, quejidos o gruñidos.
- Un sonido propio para cada entidad.
- Screamers auditivos cuando Sanity baja.

## 18. Textos

- **Benja corrige los diálogos.** Claude escribe un borrador real de cada texto, corto y en primera persona cuando habla un amigo, e indica en qué archivo está. Benja lo corrige después.
- Todos los textos viven en archivos de traducción (`data/text/*.csv`, con una columna para español y otra para inglés).

## 19. Accesibilidad y opciones

- Reducir destellos (también el borde del botón de sincronizar, que queda fijo en vez de parpadear).
- Volumen por canal.
- Desactivar el parallax.
- Temporizadores ×1,5: alarga solo el tiempo para responder una solicitud (decisión de Benja, sesión 18).
- Ninguna información crítica depende solo del color.
- **Subtítulos de los audios** (Plan 9, para quien no pueda oírlos): el mensaje con audio muestra qué se oye.

## 20. Por confirmar

Nada pendiente (26 de octubre de 2026). Los valores numéricos de `docs/02` son un punto de partida y se ajustan probando.

## 21. Referencias

- **Five Nights at Freddy's:** estructura por noches, ubicación fija y gestión de recursos bajo presión.
- **Keep Talking and Nobody Explodes:** un manual de reglas que se consulta bajo presión de tiempo.
- **Home Safety Hotline:** guiar a terceros usando un manual.
- **Not For Broadcast:** varias tareas en paralelo.
- **Lethal Company:** el rol de operador que guía a quienes exploran.

**Después de la entrega** quedan pendientes, en orden de prioridad: Pedir contenido, buscador por rasgos, ráfagas de imágenes con anomalías, defensa en la base, entre otras (`docs/05_plan_produccion.md`).
