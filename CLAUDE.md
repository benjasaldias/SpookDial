# Spook Dial — contexto y reglas del proyecto

Lee este archivo completo al empezar cada sesión. Después lee **`docs/00_log.md`**, que dice qué sesión toca y con qué documento, y luego `resumen.md`, que tiene el detalle y los pendientes vigentes.

## Qué es

- Juego de terror psicológico para PC hecho en **Godot 4.7.2** (renderer GL Compatibility), con **pixel art 2D a 1280×720** dibujado en Aseprite.
- El protagonista, Matías, nunca sale de su escritorio. Durante **5 noches de unos 7 minutos** (más una **noche 0 de tutorial**) guía por chat a **3 amigos** (León, Gonzalo y Agustín) que enfrentan criaturas del **folclore chileno**. Para eso aplica las reglas de su **cuaderno**, al estilo de Keep Talking and Nobody Explodes.
- Equipo: **Benja** hace el diseño, el arte y los diálogos. Domina Aseprite y es principiante en Godot. **Claude** hace el código.
- **Entrega: 10 de diciembre de 2026**, con el juego completo y jugable. El alcance priorizado y el calendario están en `docs/05_plan_produccion.md`.

## Documentos

| Archivo | Para qué sirve |
| --- | --- |
| `docs/00_log.md` | **Registro de sesiones: cuál sigue, con qué modelo y esfuerzo, y qué documentos son planes que se ejecutan.** |
| `spook_dial_design.md` | **Diseño v2: la única fuente de verdad sobre qué es el juego.** Su §20 lista lo que falta confirmar. |
| `resumen.md` | Log de sesiones. Los pendientes de la entrada más reciente son la lista vigente. |
| `docs/02_bucle_central.md` | Detalle de la mecánica central: solicitudes, reglas, estática, valores iniciales, plantilla de entidad, textos y modelo de datos. |
| `docs/03_plan_arte.md` | Pipeline de Aseprite a Godot: qué se separa, qué se anima y dónde, y qué arte falta. |
| `docs/04_instrucciones_godot.md` | Pasos que Benja hace en la interfaz de Godot, con su estado. |
| `docs/05_plan_produccion.md` | Alcance por prioridad (v1 y lo que viene después), calendario y riesgos. |
| `docs/06_plan_v1.md` | Hoja de ruta de la primera versión: los planes de implementación en orden y el estado del arte. |
| `docs/07_plan_escena_arte.md` | Plan 1, paso a paso: la escena del escritorio con el arte de Benja. |
| `docs/08_plan_datos_textos.md` | Plan 2, paso a paso: clases de datos, evaluador y validador de reglas, CSV y El Trauco de ejemplo. |
| `docs/09_propuesta_entidades.md` | Borrador de Claude con El Tue Tué, La Calchona y El Trauco, para que Benja los refine. No es contenido decidido. |
| `docs/10_plan_solicitudes_chat.md` | Plan 3, paso a paso: solicitudes, mensajes con señuelos, estática, preguntas y panel del chat. |
| `docs/11_plan_cuaderno.md` | Plan 4, paso a paso: el cuaderno, la memoria de página por amigo y las respuestas desde el chat. |
| `docs/12_plan_consecuencias_noche.md` | Plan 5, paso a paso: consecuencias, vida y aturdimiento, medidores, reloj, cuota y final de la noche. |
| `docs/13_plan_mantenimiento.md` | Plan 6, paso a paso: la señal de cada amigo, Audio Sync en el mixer, la descarga de videos en el chat y el celular. |
| `docs/14_plan_screamers_director.md` | Plan 7, paso a paso: el director de ritmo, los screamers, las alucinaciones y el susto guionado con su chat. |
| `docs/15_plan_noches_menu.md` | Plan 8, paso a paso: la noche 0 (tutorial), las 7 entidades, el menú, el guardado, el resumen entre noches, la pausa y las opciones. |
| `arte_pendiente.md` | **Todo el arte que falta**, por urgencia, con tamaños y lo que hay hoy en su lugar. |
| `audio/source/creditos.md` | De dónde salen las 5 grabaciones que usan los sonidos, con su licencia. |
| `sonidos_pendiente.md` | **Todos los sonidos**: dónde suena cada uno, cómo se generan, cómo cambiarlos y cuáles faltan. |
| `docs/16_plan_feedback_1.md` | Plan 8.1: el feedback de la primera prueba (la criatura en la ventana, las noches 1 y 2, Audio Sync en rondas, Trust y los diales). |
| `docs/17_ideas_dinamismo.md` | Las notas de la prueba del 7-nov, ordenadas y con sus decisiones: de aquí sale el Plan 9. |
| `docs/18_plan_dinamismo.md` | Plan 9, paso a paso: las barras, la dificultad, los audios, la batería, las cortinas y los accidentes. |
| `docs/19_prompt_lore.md` | Prompt de la sesión que planifica el lore por noche. |
| `docs/20_prompt_red_social.md` | Prompt de la sesión que rediseña la red social del celular. |
| `docs/22_diagnostico_mecanicas.md` | Diagnóstico de Claude de por qué el juego se siente plano, con propuestas. Al inicio dice cuáles eligió Benja (11-nov). |
| `docs/23_prompt_ajustes_mecanicas.md` | Prompt de la sesión que implementa los ajustes del 11-nov y la Mano. |
| `docs/24_plan_ajustes_mecanicas.md` | Plan 9.1 (ejecutado en S21f): el mensaje inicial, los señuelos y las variantes, las olas, el aviso de videos, la criatura al azar, la Mano y Trust sin recuperación. |
| `art/positions.md` | Posición de cada objeto recortado en la escena. |
| `docs/01_analisis_diseno.md` | Análisis de la sesión 1. Es **histórico**: su encabezado dice qué se aceptó y qué no. |
| `spook_dial_design_v1.md` | Diseño original (histórico). |

## Reglas de trabajo

1. **Idioma.** La conversación, los documentos y los comentarios del código van en español. Los identificadores, nombres de archivos, nodos, capas y tags de Aseprite van en inglés: `snake_case` para archivos y variables, `PascalCase` para clases y nodos.
2. **Regla de Godot (de Benja).** Si hay algo que Claude no puede hacer directamente, y la alternativa por código NO es igual de eficiente o más que hacerlo en la interfaz de Godot, al **final** de la sesión Claude le da a Benja instrucciones **muy específicas**:
   - el menú exacto, el panel, el nodo, la propiedad y el valor;
   - cómo verificar que quedó bien.

   Benja es principiante en Godot: no hay que asumir que conoce la interfaz. Esas instrucciones se guardan también en `docs/04_instrucciones_godot.md`, con su estado.

3. **Preguntas.** Las breves, con opciones y una de ellas marcada como recomendada, se hacen durante la sesión. Las largas o abiertas se juntan al final.
4. **Cierre de sesión.** Agregar una entrada al inicio de `resumen.md` con las cuatro categorías: Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. Arrastrar los pendientes que sigan abiertos. **Actualizar `docs/00_log.md`**: marcar el estado de la sesión, dejar clara la siguiente y anotar cualquier cambio a la secuencia. Si cambió una decisión o una regla, actualizar este archivo y el diseño v2.
5. **No tocar sin permiso.** Los `.aseprite` y PNG de Benja son de solo lectura. El diseño v2 se actualiza solo con decisiones que Benja tomó.
6. **Alcance.** Hay fecha de entrega. Toda idea nueva se compara con `docs/05`; si no cabe, va al final de la lista priorizada. Benja no quiere seguir agregando cosas antes de tener la v1.
7. **El contenido es datos.** Entidades, observaciones, reglas, acciones, amigos y noches son `Resource` (`.tres`) editables en el Inspector. Nada de contenido en constantes del código.
8. **Textos.**
   - **Benja corrige los diálogos.** Claude escribe un borrador real de cada texto, sin marcas de prototipo: corto, y en primera persona cuando habla un amigo. Siempre dice en qué archivo quedó, y Benja lo corrige después (decisión de Benja, 31-10-2026).
   - Todos los textos van en `data/text/*.csv` (columnas `keys,es,en`) para poder traducirlos al inglés.
9. **El juego es estrictamente el escritorio.** La historia va solo en cinemáticas opcionales y nunca cambia las mecánicas.
10. **Pixel art.** 1 píxel de arte = 1 unidad de Godot, con posiciones enteras y filtro Nearest. No se escalan sprites, salvo las vistas ampliadas a ×2 exacto. Las fotos de Snapgram son la única excepción al pixel art: son fotos reales, de 232×232 y sin escalar.
11. **Commits:** preguntar a Benja durante la sesión antes de **cada** commit, salvo que él lo haya pedido explícitamente antes. Nunca hacer push sin su autorización.

## Decisiones tomadas

No se vuelven a discutir salvo que Benja lo pida. El detalle de cada una está en el diseño v2.

| Fecha | Decisión |
| --- | --- |
| 15-10-2026 | Si un amigo muere, **se pierde la noche** y se reinicia (estilo FNAF). |
| 15-10-2026 | Resolución base **1280×720** (el arte es nativo). El escalado ×1,5 a 1080p se resuelve en Godot (prueba pendiente). |
| 15-10-2026 | **Audio Sync se juega en el mixer**, por amigo (un fader por canal). |
| 26-10-2026 | **No hay termómetro:** queda fuera del arte y del juego. |
| 15-10-2026 | **Final único:** se gana sobreviviendo las 5 noches. La **cuota de contenido es condición para ganar cada noche**. |
| 26-10-2026 | **La cuota la cubren los envíos programados** si se reciben todos. La **acción de mayor riesgo** da un video extra si el amigo sobrevive. **No existe una acción "Grabar"**: fue un error de Claude, que nunca se acordó. |
| 26-10-2026 | **Cada entidad tiene 4 acciones propias** y **reglas estilo Keep Talking**. Cada regla marca la acción correcta y la de mayor riesgo; las otras dos son incorrectas. |
| 26-10-2026 | **Los amigos nunca dicen el nombre de la entidad.** Se identifica de memoria, o **clickeando todas las características destacadas** del mensaje; tras una espera de unos 3 s aparece el nombre. |
| 26-10-2026 | **Se responde desde el cuaderno:** las opciones del chat son las acciones de la página abierta para ese amigo. |
| 30-10-2026 | **Memoria del cuaderno por amigo:** cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice. |
| 31-10-2026 | **El chat y el cuaderno son independientes** y son los únicos paneles que pueden estar abiertos a la vez. El cuaderno va **a la derecha, como espejo del chat** (tapa los diales mientras está abierto). El clic derecho sobre un panel lo cierra; `Esc` o un clic fuera de los paneles cierra los dos. **El celular y el mixer son modos exclusivos**, sin ningún panel abierto. |
| 31-10-2026 | **Cada dial conserva el color de su aguja:** Connection verde, Sanity roja y Trust amarilla. El valor lo muestra el ángulo. |
| 31-10-2026 | **El video de un amigo aturdido se atrasa:** lo envía apenas se recupera. Vale para los envíos programados y para el video extra de la acción de mayor riesgo. |
| 31-10-2026 | **Textos reales:** ya no se usa `[PROTO]`. Claude escribe borradores reales (los amigos, en primera persona y en mensajes cortos) y Benja los corrige. |
| 31-10-2026 | **El chat se ve como una terminal:** fuente Departure Mono (pixel, licencia OFL) en múltiplos de 11 px, también en las entradas del PC; cada mensaje lleva el nombre de quien escribe ("LEÓN:", "MATÍAS:") en su color; fondo oscuro detrás del vidrio y líneas CRT suaves. Los amigos son rosa (León), azul (Gonzalo) y lila (Agustín), para no confundirse con el ámbar, el verde y el rojo de las pistas. |
| 31-10-2026 | **Aviso de daño en el chat (Plan 5):** el amigo herido grita en primera persona ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y el juego avisa en rojo y centrado cuánta vida le queda ("León recibió daño: 2/3"). La vida sigue siendo de 3 puntos. |
| 31-10-2026 | **Un amigo sin señal** sigue recibiendo situaciones, pero su mensaje llega tapado entero y no lee preguntas ni respuestas. Si no lo reconectan antes de que se acabe su tiempo, elige al azar una de las 3 acciones que no son la correcta: daño normal y sin bajar Trust por esa decisión. Mientras haya amigos sin señal, Trust baja 1 punto cada 4 s por cada uno y no se recupera. |
| 31-10-2026 | **Videos:** el amigo avisa en su chat. Hay 15 s para empezar a descargarlo y, desde ahí, 20 s para terminar, manteniendo presionada su barra en el chat. La descarga tarda 10 s (15 s con la señal del amigo bajo 50; sin señal no avanza). |
| 31-10-2026 | **Audio Sync en el mixer visto desde arriba** (Benja lo dibuja): el VU-metro azul de la izquierda muestra el ritmo de Matías y el de la derecha, el del amigo. Una base marca el tiempo, el amigo aplaude un ritmo y Matías lo imita con clics o con la barra espaciadora. Se empieza con un clic en el mixer. Desde el 10-nov, la vista es pixel art de Claude (`art/ui/`), y Benja la puede redibujar. |
| 31-10-2026 | **El celular** (el scroll de redes sociales) es provisional hasta que Benja lo anime. Desde el 9-nov, lo provisional es solo el marco y los íconos; desde el 10-nov, el marco es pixel art de Claude y solo los íconos son provisionales. |
| 09-11-2026 | **Snapgram:** la red social del celular se llama así (elección de Benja) e imita la forma de Instagram, sin historias: barra superior, cabecera, foto cuadrada de 232×232, íconos y barra de navegación. **Son solo fotos reales de gatitos** (mixed media), las cuentas no tienen nombre, el texto son barras grises y los botones son solo dibujo. Scroll, Sanity y batería no cambian. |
| 09-11-2026 | **Fotos perturbadoras en Snapgram:** con Sanity bajo 30, 1 de cada 6 publicaciones; bajo 15, 1 de cada 3 (`data/balance.tres`). No restan Sanity. Una foto a la vista nunca cambia: se decide al entrar a la pantalla. Son 4 fotos que pasó Benja. |
| 10-11-2026 | **Sonidos realistas y de terror:** casi todos se sintetizan con `tools/make_sounds.py`, y lo que la síntesis no logra (el gallo, la oveja, el llanto y los gruñidos) sale de grabaciones de dominio público o CC0, con sus créditos en `audio/source/creditos.md`. El balance se fija en el script (LUFS por sonido, picos bajo -1 dBFS). |
| 10-11-2026 | **Ningún sonido dice palabras:** las criaturas gritan, se quejan o gruñen. **El Imbunche llora como guagua** en lugar de decir "Matías": la observación pasó a `baby_cry` ("¿Se oye un llanto?"). |
| 10-11-2026 | **Las voces de los amigos murmuran:** cada letra es una sílaba murmurada que llega por un micrófono barato, no un pitido de consola. El ritmo y la altura no cambian. |
| 10-11-2026 | **El cuaderno es universitario:** hoja cuadriculada con margen rojo y espiral, la tapa verde, una mancha de café y garabatos a lápiz; las pestañas son notas adhesivas, y la letra es Departure Mono (11 px, el título a 22). |
| 10-11-2026 | **El arte de interfaz de Claude es pixel art** con la paleta de los sprites de Benja (`art/ui/`, que genera `tools/make_ui_art.py`): el mixer, el cuaderno, la mancha de tinta, el marco del celular, la placa de las barras, las barras de señal y el marco y los botones de los menús. El menú muestra los sprites del cuarto a la luz de la luna. Benja puede redibujar cualquier pieza; el logo sigue siendo suyo. |
| 02-11-2026 | **«Sincronizar» desde el chat:** el chat de cada amigo tiene un botón que abre el mixer en su canal y empieza la ronda. El canal también se elige en el fader del mixer, y la entrada del PC siempre abre el chat: cada control hace una sola cosa. |
| 02-11-2026 | **El director reparte las solicitudes en olas con respiro:** después de cada ola hay unos 25 s sin solicitudes nuevas, las olas se aprietan hacia las 06:00 y, cuando un amigo queda herido, las que faltan se atrasan.  Desde el 11-nov, olas de verdad (ver abajo). |
| 02-11-2026 | **Los screamers llegan en cualquier momento de la noche**, solo con las reglas de justicia del diseño (§11).  Desde el 11-nov, en las calmas entre las olas. |
| 02-11-2026 | **Alucinaciones del cuarto y del juego:** con Sanity bajo suenan golpes, pasos, susurros y rasguños, y también la estática de una interferencia y el celular vibrando, que no vienen de nada. No restan Sanity y nunca suenan durante Audio Sync. |
| 02-11-2026 | **La figura de la ventana** (`enemy_sprite`) está escondida: aparece como el screamer de la ventana y es la criatura que se asoma (decisión del 4-nov). |
| 04-11-2026 | **La criatura se asoma por la ventana en lugar del jumpscare** (era aburrido): con respiración pesada y golpes en el vidrio, sin tapar la pantalla ni pausar la noche. Se arma **solo cuando el chat o el mixer tapan la ventana**, y al cerrarlos ya está ahí (así no hace falta animarla); se queda 4 s a la vista. Los otros 6 screamers no cambian. Los sonidos son provisionales y están en `sonidos_pendiente.md`. |
| 04-11-2026 | **Las noches 1 y 2 tienen más sucesos:** la noche 1 pasa a 5 solicitudes, 2 a la vez y 85 s, con la señal que baja, 1 interferencia, Audio Sync de 4 aplausos y 2 screamers ambientales; la noche 2 pasa a 7 solicitudes, 3 interferencias y 4 screamers (`docs/02` §6). |
| 04-11-2026 | **Audio Sync de 8 aplausos son 2 rondas de 4**, cada una con su cuenta y su patrón: si se falla la segunda, se vuelve a la primera. La señal solo vuelve a 100 al terminar las 2. |
| 04-11-2026 | **Trust también baja si tardas en contestar:** cada solicitud que lleva más de 30 s abierta (45 con "Temporizadores ×1,5") le quita 0,25 por segundo, y mientras haya una Trust no se recupera. Preguntar cuenta como tiempo abierto. No aplica en la noche 0. |
| 04-11-2026 | **Los diales se explican en la noche 0:** el primer aviso del tutorial dice qué es cada uno, con un botón "Entendido". No hay letreros ni avisos de cambio por ahora. |
| 07-11-2026 | **Barras arriba de la pantalla:** Connection, Sanity y Trust también se ven como barras, cada una con su color, en el hueco entre el chat y el cuaderno, que no las tapan. Los diales de la pared se quedan. |
| 07-11-2026 | **Acertar es más difícil:** menos tiempo por noche (80, 65, 55, 45 y 40 s), sin pista inicial desde la noche 3 y más señuelos (1, 2, 3, 3 y 4). Desde la noche 3 hay entidades que comparten 2 características.  Desde el 11-nov, 50 y 45 s en las noches 4 y 5. |
| 07-11-2026 | **Audios en «¿Qué oyes?»:** cada entidad tiene una observación que el amigo manda como audio, y el jugador la escucha con un clic en el chat. Lo que se oye cambia la acción correcta (1, 3 o ningún grito del Tue Tué no son lo mismo; que La Calchona bale o bufe, tampoco). Las características siguen siendo texto clickeable. Se pueden repetir gratis, la estática puede tapar el audio (hay que volver a preguntar) y mientras suena no empiezan screamers ni alucinaciones. Opción "Subtítulos de los audios". |
| 07-11-2026 | **Audio Sync más rápido:** la base sube noche a noche (90, 100, 115, 130 y 145 golpes por minuto), y la segunda ronda va un 15 % más rápida que la primera. |
| 07-11-2026 | **El celular tiene batería:** un tope por noche, sin recarga, que alcanza para unos 38 s de scroll. Sin batería no hay feed.  Desde el 11-nov, 48 s, y el flash también la gasta. |
| 07-11-2026 | **Las cortinas se abren y se cierran con un clic.** Cerradas, el cuarto se oscurece y Sanity baja de a poco; abiertas, no pasa nada, salvo que haya algo afuera. |
| 07-11-2026 | **La criatura se queda un tiempo fijo** (25 s) y reemplaza a la decisión del 4-nov en lo que dura: mientras esté afuera con la cortina abierta, Sanity baja rápido. Si la cortina estaba cerrada, la abre al llegar. Cerrarla no la espanta y con la cortina cerrada no se oye, así que hay que abrirla para revisar si sigue ahí. Llega más veces: 1, 2, 2 y 3 en las noches 2 a 5.  Desde el 11-nov, entre 15 y 40 s al azar. |
| 07-11-2026 | **El screamer de la cortina** ya no la mece: la cortina se abre o se cierra sola. |
| 07-11-2026 | **Accidentes:** un amigo se tropieza o se corta sin que nadie tenga la culpa (1, 1, 2, 2 y 3 por noche). Se responde en el chat con sentido común, sin cuaderno, en 15 s. Una mala respuesta o no contestar le quita 1 de vida y lo aturde, sin bajar Trust. Nunca matan a un amigo. |
| 07-11-2026 | **La historia con decisiones y editar los videos quedan para después** de hacer divertidas las mecánicas (`docs/05`, puntos 21 y 22). |
| 08-11-2026 | **Sombra sobre el escritorio:** lo que se asoma por la ventana (la criatura y el screamer de la ventana) hace sombra (`desk_sprite`, tags `Enemy` y `NoEnemy`). Con la cortina cerrada no hay sombra, para no delatar a la criatura. |
| 08-11-2026 | **Audio Sync muestra una fila de 8 luces**, las de una ronda, aunque la noche tenga 2 rondas. |
| 09-11-2026 | **Luces de ronda en Audio Sync:** junto a la fila, una luz por ronda (solo si la noche tiene varias), visible desde que se abre el mixer: azul la ronda en curso, verde las pasadas. Al fallar se apagan, porque se vuelve a la primera. |
| 08-11-2026 | **Los amigos suenan mientras escriben,** como en Undertale, cada uno con su voz (sonido, altura y ritmo, en `data/friends/*.tres`). Solo suena el chat que se está viendo, no suena sobre un audio, y Matías y los avisos no tienen voz. |
| 11-11-2026 | **El mensaje inicial no siempre dice el lugar:** el amigo saluda, dice qué le pasa (8 frases, como "Me perdí." o "Algo me viene siguiendo.") y menciona el lugar solo a veces: 60, 55, 50, 45 y 40 % en las noches 1 a 5, y siempre en la noche 0. Orden: saludo, lo que le pasa, lugar y pista. Reconocer rápido a la criatura es parte de la habilidad. Reemplaza al lugar fijo del 3-nov. |
| 11-11-2026 | **Los señuelos cuestan 1 s** del temporizador la primera vez que se clickean, también en la noche 0, y el chat muestra "−1 s" mientras vibran (reemplaza al "sin otro costo" del 26-oct). **Las características se dicen con sinónimos y paráfrasis:** de 2 a 4 formas más cada una (`variant_keys`), y la solicitud elige una al azar, también para la pista. El cuaderno muestra un **nombre fijo** por característica (`label_key`, en `notebook.csv`), que ya no es la frase entre asteriscos. |
| 11-11-2026 | **Olas de verdad:** el primer minuto es de silencio; las solicitudes de una ola (2) llegan con 4 a 8 s de diferencia; cuando se resuelven viene una calma de 40 a 60 s, y la **ola final**, de 3 (los 3 amigos a la vez), llega lo más tarde posible (04:29 a 04:59) con la criatura desde la noche 2. Una ola que ya no cabe antes de la final se salta. **En las olas:** las interferencias, los accidentes y la Mano; **en las calmas:** los videos (a más tardar 25 s antes de la ola siguiente) y los screamers. Solicitudes por noche: 7, 7, 9, 9 y 11; 3 simultáneas. Reemplaza a la del 2-nov. **La cuota no sube** (sigue la del 26-oct). |
| 11-11-2026 | **Aviso cuando los videos ya no alcanzan:** si al perderse un video los que quedan (recibidos, esperando y por llegar) no alcanzan la cuota, el chat de ese amigo avisa en rojo que alguien tiene que arriesgarse, una vez por video perdido, y el PC muestra "Videos: 1 de 3 (faltan)" en rojo hasta que vuelvan a alcanzar. **La criatura se queda entre 15 y 40 s al azar** (reemplaza los 25 s fijos del 7-nov). |
| 11-11-2026 | **La Mano** (idea de Benja, `hand_sprite`): el segundo enemigo del cuarto. Asoma desde el borde derecho hacia un dial al azar (los 3 por igual) y tarda unos 12 s en llegar, a tirones de 0,5 a 0,7 s, alternando sus 3 cuadros y temblando 1 o 2 px en cada tirón, como en Undertale. Agarrado, baja el dial 6 por segundo hasta 15, nunca a 0, y **se queda hasta que la espantan**; en Connection baja las 3 señales parejo. **Se espanta al instante con el flash del celular**: el rayo de la barra superior del celular abierto, que gasta 10 % de la batería, haya o no una Mano. Está en la pared, **detrás de los paneles** (el cuaderno la tapa), y en cada tirón suena un **crujido sutil** de algo que se retuerce (decisión de Benja en S21f; antes era en silencio). Llega 1, 1, 2, 2 y 3 veces, y la noche 0 la enseña con el celular abierto. No coincide con la criatura. **Toda noche debe ser ganable:** lo comprueba `test_balance.gd`. |
| 11-11-2026 | **Trust no se recupera durante la noche** (vuelve a 100 al empezar cada noche). **Un video perdido baja Trust 10** (la segunda forma de bajar, elegida en S21f). Con eso, una respuesta incorrecta pasa a −15; sin respuesta, −15 más; la de mayor riesgo, −20, y tardar, −0,25 por segundo. |
| 11-11-2026 | **Batería y tiempo, para que toda noche se pueda ganar:** la batería pasa de 38 a **48 s** de scroll (con 38, la noche 5 pedía 106 %), y el tiempo para responder de las noches 4 y 5 sube a **50 y 45 s** (antes 45 y 40), porque con olas de verdad no se alcanzaba la ola final. |
| 02-11-2026 | **Noche 0 (tutorial):** una noche nueva antes de la 1. El susto guionado y su chat son datos de una noche y van al final de la noche 0. |
| 04-11-2026 | **La noche 0 es guiada y no se pierde:** unos 3 o 4 minutos, con 3 solicitudes fijas (una de cada amigo, con El Tue Tué y La Calchona). Un aviso arriba de la pantalla dice qué hacer en cada paso. El tiempo para responder no corre solo (solo las preguntas le quitan tiempo), nadie sale herido y Trust no baja. Enseña también a descargar un video (sus plazos esperan). Termina con el susto guionado, el chat de Gonzalo y el celular. "Nueva partida" empieza en la noche 0, y el aviso tiene un botón "Saltar tutorial".  Desde el 11-nov, enseña también la Mano y el flash, con el celular abierto. |
| 04-11-2026 | **Las 7 entidades son un borrador de Claude:** las 3 de `docs/09` y 4 nuevas, como `.tres` y CSV. Benja las corrige antes del congelamiento del contenido (25-nov). |
| 04-11-2026 | **"Temporizadores ×1,5" alarga solo el tiempo para responder** una solicitud: no los plazos de los videos ni el margen de justicia de los screamers. |
| 04-11-2026 | **Menú de pausa con `Esc`:** sin ningún panel abierto, `Esc` pausa la noche (Continuar, Opciones y Volver al menú). Volver al menú pierde la noche, que se retoma desde su comienzo. Con un panel abierto, `Esc` lo cierra, como antes. |
| 03-11-2026 | **La entidad se identifica preguntando:** el mensaje inicial es corto: un saludo ("¡Mati, ayuda!!", "¿Estás ahí?"), el lugar y, a veces, una **pista** (una de las 2 características; probabilidad por noche: 100, 75, 50, 35 y 20 %). Las características, los señuelos y las observaciones salen **al preguntar** su categoría (5 s cada pregunta), así que hay que elegir las preguntas correctas. Como cada solicitud pide más atención, hay **más tiempo** (90, 80, 75, 70 y 65 s) y **menos solicitudes** (4, 6, 7, 8 y 10 por noche): valores a probar.  Desde el 11-nov, el lugar solo a veces y con lo que le pasa al amigo, y las solicitudes y los tiempos cambiaron (ver arriba). |
| 02-11-2026 | **Chat guionado tras el susto:** un amigo escribe "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar"; Matías responde con un botón ("Creo que me estoy volviendo loco, no sé si puedo seguir"); el amigo contesta "Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar", y el borde del celular parpadea hasta que Matías lo abre. Más adelante habrá una progresión guionada entre los amigos (`docs/05`). |
| 26-10-2026 | **La frase clickeable de una característica va entre asteriscos** en el CSV: `vio un *hombrecito*` (no corchetes, que chocan con el BBCode del chat). |
| 26-10-2026 | **Las 2 características se cuentan camufladas entre señuelos** (desde el 3-nov, al preguntar; antes venían en el mensaje inicial): frases clickeables que no ayudan a identificar (describen el lugar, un olor, un sonido o algo que se ve). Al clickear un señuelo, vibra y se pone rojo, sin otro costo. Señuelos por solicitud, por noche: 1, 1, 2, 2 y 3.  Desde el 11-nov, un señuelo cuesta 1 s. |
| 26-10-2026 | **La identificación tiene una barra fija con el avance** ("1 de 2"), luego "Matías piensa…" y el nombre. **La estática tapa una frase clickeable entera o nada.** Con **5 s o menos no se puede preguntar.** |
| 15-10-2026 | **Estática:** con poca señal se tapan palabras. Una característica tapada no se puede clickear; hay que preguntar para recuperarla. |
| 26-10-2026 | **Si cualquiera de los 3 diales llega a 0, se pierde la noche.** El dial de Connection es el promedio de las tres señales. |
| 15-10-2026 | **Señal por amigo:** baja gradualmente y con interferencias anunciadas; Audio Sync individual en cualquier momento. |
| 15-10-2026 | Efectos graduales: **Trust bajo acorta los temporizadores** (en 0, los amigos dejan de pedir ayuda: se pierde la noche); **Sanity bajo trae viñeta y screamers auditivos**. |
| 15-10-2026 | Preguntas de seguimiento sí. Pedir contenido y personalidades con efecto mecánico, no (las personalidades son solo de sabor). |
| 15-10-2026 | Nombres: **Matías, León, Gonzalo y Agustín**. Matías está en una cabaña. León es el poseído, solo en la historia. |
| 15-10-2026 | **7 entidades:** El Tue Tué, La Calchona, El Cuero, La Viuda, El Trauco, El Basilisco y El Imbunche. Los **Brujos de Chiloé** son antagonistas de la historia. |
| 26-10-2026 | **Cámara que mira hacia el mouse (a prueba):** toda la escena con un zoom leve (×1,05) y desplazada hacia donde apunta el mouse, hasta el margen que deja el zoom, para que todo siga alcanzable. Reemplaza al parallax por planos. Es una excepción a la regla 10. Si no funciona, se quita el parallax por completo. |
| 15-10-2026 | Idioma: español para la entrega; inglés antes del 10-dic si alcanza. Textos en CSV desde el inicio. |
| 26-10-2026 | El proyecto **se queda en OneDrive** (así se conserva el historial del chat), con la carpeta de git **fuera de OneDrive**. GitHub privado (Benja crea el repositorio). |

## Entorno técnico

- **Proyecto:** `C:\Users\benja\OneDrive\Documents\spook-dial` (desde WSL: `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`).
  - **Git:** su carpeta interna está fuera de OneDrive, en `/mnt/c/dev/spook-dial.git`, y el proyecto tiene un archivo `.git` que apunta ahí. Usar git solo desde WSL (VS Code conectado a WSL, o Claude); GitHub Desktop de Windows no entiende esa ruta.
  - **OneDrive interfiere:** a veces Edit/Write responden "no such file" porque OneDrive reemplaza el archivo mientras sincroniza. El cambio normalmente queda escrito: verificar con `grep` antes de reintentar.
  - **Copia vieja:** `~/godot-games/spook-dial` está desactualizada y no se edita; se borra cuando Benja lo pida.
- **Godot en Windows:** `C:\Users\benja\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`. Ojo: la carpeta se llama igual que el ejecutable.
- **Godot desde WSL:** `~/tools/godot-wsl.sh` traduce las rutas de Linux a rutas de Windows y llama al ejecutable de Windows. Ejemplo:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" --import   # desde la carpeta del proyecto
  ```

  **No usar `--import` mientras Benja tiene el editor abierto en el mismo proyecto.**

- **MCP `godot`:** configuración local para esta carpeta, con `GODOT_MCP_ROOT` igual a la ruta del proyecto y `GODOT_EXECUTABLE=~/tools/godot-wsl.sh`. Los otros proyectos de `~/godot-games` usan la configuración global, que no se tocó. El servidor no activa plugins: eso lo hace Benja en Project Settings > Plugins.
- **Aseprite (Steam):** `C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe` (versión 1.3.18). El plugin **Aseprite Wizard 9.8.0** está instalado, activado y con la ruta correcta (corregida por Claude el 26-10-2026). Los 16 sprites importan bien.
- **Reimportar un `.aseprite`:** Godot no reintenta un archivo cuyo `.import` quedó con `valid=false`. Para forzar la reimportación, hay que borrar su `.import` (o su `.md5` y su `.res` en `.godot/imported/`) y correr `godot-wsl.sh --headless --path "$PWD" --import` con el editor cerrado.
- **Fuente:** Departure Mono, en `fonts/departure_mono/`, con su licencia (`OFL.txt`), que debe ir con el juego. Se importa sin suavizado ni hinting (en su `.otf.import`) y se usa en múltiplos de 11 px.
- **Sonidos y arte de interfaz generados:** `/usr/bin/python3 tools/make_sounds.py` (necesita numpy, scipy y `ffmpeg`) escribe `audio/sfx/` y `audio/clues/`; `/usr/bin/python3 tools/make_ui_art.py` (Pillow y numpy) escribe `art/ui/`. El `python3` de miniconda no tiene esas librerías. Si Benja deja un archivo suyo con el mismo nombre, no hay que volver a correrlos.
- **Fotos de Snapgram:** los originales de Benja están en `art/phone/source/` (Godot los ignora) y `tools/crop_phone_photos.sh` los recorta a `art/phone/`, a 232×232.
- **Arte:** los sprites están en `art/sprites/` (posiciones en `art/positions.md`). La maqueta está en `art/_layout/` (`scene_layout.aseprite` y `scene_layout.png`), que Godot ignora.
- **Git:** remoto `origin` = `https://github.com/benjasaldias/SpookDial.git` (privado; `gh` está autenticado como `benjasaldias`). Rama `main`. Usar `core.filemode=false` (el disco es NTFS).
- **Pantalla:** viewport de 1280×720, stretch mode `canvas_items`, aspect `keep` (Godot no lo escribe en `project.godot` porque es el valor por defecto), filtro `Nearest` y snap a píxel. Falta que Benja confirme el escalado a 1080p (`docs/04`, D).
- **Pruebas:** `~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd` ejecuta todos los `test/test_*.gd` (sin addons). Una suite que no carga cuenta como falla.
- **Equilibrio:** `test/balance_model.gd` es el modelo de "jugar bien" con el que `test_balance.gd` comprueba que toda noche se puede ganar. Para ver la curva de olas de una noche: `~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_waves.gd -- <noche> <semilla> <archivo.json>` y después `/usr/bin/python3 tools/plot_waves.py <archivo.json> <imagen.png>`.
- **Capturas:** `--write-movie` graba siempre al tamaño del viewport (1280×720), aunque se pida otra resolución. `tools/compare_png.py` compara una captura con la maqueta.

## Convenciones de código

Es una propuesta; se confirma al empezar a programar.

- GDScript con tipado estático. Las señales se nombran en pasado (`request_resolved`). Un script por responsabilidad.
- Carpetas de `res://`: `art/`, `audio/`, `fonts/`, `data/` (recursos `.tres` y `data/text/*.csv`), `scenes/`, `scripts/`, `shaders/` y `addons/`. `docs/` y `art/_layout/` tienen `.gdignore`.
- Autoloads previstos: `GameState` (noche, medidores y amigos), `EventBus` (señales globales), `AudioManager` y `SaveManager`.
- La lógica pura (aplicar reglas, resolver consecuencias, estática, medidores) va en clases sin dependencias de escena, para poder probarla.
- Specs y planes van en `docs/`, numerados, y no en `docs/superpowers/`.
