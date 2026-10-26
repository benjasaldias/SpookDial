# Spook Dial — Documento de diseño

Documento de contexto para desarrollo. Describe el juego: fantasía, mecánicas, contenido y presentación. No contiene planificación técnica ni de código.

---

## 1. Identificación

- **Título:** Spook Dial (juego de palabras con *speed dial*).
- **Plataforma:** PC.
- **Género:** Terror psicológico, simulación de escritorio, puzzle de deducción.
- **Audiencia objetivo:** +13, público joven y adulto.
- **Motor:** Godot.
- **Arte:** pixel art 2D hecho en Aseprite. Tipografía: una pixel font existente, no dibujada a mano.
- **Idioma del juego:** a definir (el desarrollo y los documentos están en español).

## 2. Pitch

El jugador controla a **Player**, un experto en lo paranormal demasiado cobarde y poco sociable como para exponerse. Trabaja desde su escritorio mientras tres amigos, que no le temen a nada, graban contenido en lugares embrujados. Durante cinco noches Player debe guiarlos por chat: interpretar lo que ven y oyen, decidir por ellos, mantener la conexión y evitar que su cordura y la confianza de sus amigos se agoten.

La fantasía central es la de **operador**: el jugador nunca está en el lugar del peligro, pero es la única fuente de conocimiento, y sus decisiones definen el destino de otras personas.

## 3. Forma del juego

Suspenso en **primera persona con cámara fija**. Todo ocurre en el escritorio de Player. El jugador **no se desplaza**: interactúa con los objetos que tiene enfrente y reparte su atención entre varios frentes a la vez, mientras las entidades lo atormentan también a él.

Player está protegido en su base: las entidades **no pueden alcanzarlo ni matarlo, sólo asustarlo (a excepción de la última noche, que incorporará una mecánica adicional de defenderse contra una entidad dentro de la base)**. El riesgo de muerte siempre recae sobre los amigos.

## 4. Personajes

- **Player (protagonista jugable):** experto en entidades y fenómenos paranormales. Quiere lucrar con su conocimiento, pero no puede ser la cara de un canal y le teme al peligro. Nunca se le ve: el jugador mira desde sus ojos.
- **Los tres amigos:** salen a grabar, le piden ayuda a Player y le envían el contenido (videos e imágenes). Cada uno tiene nombre, avatar e icono propios en la interfaz del chat. Su voz se convierte a texto en el chat.
- **Las entidades:** criaturas paranormales distintas entre sí, unas más peligrosas que otras. **El jugador nunca las ve durante las decisiones**: sólo las conoce por las descripciones de sus amigos y por su cuaderno.

## 5. Estructura de una partida

- **Menú principal:** Continuar (sólo si hay una partida en curso), Nueva partida, Opciones, Salir.
- Una partida consta de **5 noches**.
- Cada noche transcurre entre las **12:00 AM y las 6:00 AM**, en aproximadamente **7 minutos reales**.
- **Objetivo principal de cada noche:** llegar a las 6:00 AM sin que ningún medidor llegue a 0. Si alguno llega a 0, la noche se reinicia.
- **Objetivo secundario:** juntar un mínimo de contenido para el canal (videos y anomalías).
- **Entre noches:** se muestra el resultado del canal (contenido obtenido y estado de los amigos) y se añaden **páginas nuevas al cuaderno**.

## 6. El escritorio

Cada objeto del escritorio cumple una función y se puede clickear:

- **Computadora:** muestra el estado de los tres amigos y quién espera respuesta. Al clickear a un amigo se abre su conversación en un panel lateral en la pantall (pantalla real, no del pc del juego) grande al lado izquierdo, con el historial y las opciones de respuesta si hay una decisión pendiente. Desde aquí también se recibe contenido y se inicia Audio Sync.
- **Cuaderno:** contiene el conocimiento de Player sobre entidades y situaciones. Es la fuente para tomar cada decisión.
- **Celular:** sirve para scrollear redes sociales con la rueda del mouse y recuperar Sanity.
- **Medidores:** tres diales en la pared que muestran Connection, Sanity y Trust.
- **Micrófono y audífonos:** ambientan la comunicación con los amigos.
- **Cruz, retrato y cortinas:** ambientación y protección de Player. Los screamers los alteran (la cortina se mueve, el retrato cambia).

## 7. Interfaz de la computadora

La pantalla de la computadora tendrá dos modos:

- **Lista de chats:** una entrada por amigo, con nombre, avatar/icono y estado (conectado, desconectado, esperando respuesta, muerto).
- **Vista de conversación (estilo app de mensajería):** Se mostarará una pestaña con giberish mientras se tenga el chat abierto (pues la pantalla del pc es pequeña, el panel lateral mostrará el chat real)

Comportamiento clave:

- El jugador **clickea una de las tres entradas** para abrir esa conversación. Sólo ve una conversación a la vez, aunque varios amigos pidan ayuda al mismo tiempo.
- Cuando un amigo espera respuesta, **su entrada en la lista parpadea y suena una alarma** e indica el tiempo límite. Ese parpadeo es la señal de que hay algo urgente en un chat que no está abierto.
- El historial se **scrollea con la rueda del mouse**.
- Los mensajes aparecen como texto escrito progresivamente, con un sonido breve por mensaje.

## 8. Mecánica 1 — Decisiones

El núcleo del juego.

- Los amigos envían mensajes del tipo *"Veo X, estoy en una habitación Y, ¿qué hago?"*.
- Cada solicitud tiene un **tiempo límite**. Si expira sin respuesta, **el amigo decide solo**, con probabilidad de equivocarse.
- Las opciones de respuesta son siempre cuatro, y dependerán de la entidad.
- Player debe **cruzar las señales descritas** (lo que se ve, lo que se oye, el ambiente) con su cuaderno, al estilo de *Keep Talking and Nobody Explodes*.
- **Una señal aislada no basta**: algunas entidades comparten señales individuales, y lo que identifica a una entidad es la combinación.
- Una respuesta correcta protege al amigo. Una incorrecta puede dejarlo **dañado, aturdido, perdido o muerto (si ha perdido mucha vida)**.
- Si un amigo recibe una consecuencia negativa por una decisión de Player, **baja Trust**, pero si elige LA PEOR consecuencia negativa (ya sea accidental o intencional), Player recibirá un content adicional de ese NPC.

### 8.1 Entidades con estados, no con respuestas fijas

Cada entidad no tiene una única respuesta correcta: tiene **varios comportamientos o estados**, y el estado cambia cuál es la respuesta correcta. Que dos entidades compartan una señal superficial no debe ser el único recurso para generar ambigüedad; la ambigüedad viene de leer bien el estado.

Ejemplo del comportamiento buscado: una entidad que deja un rastro de líquido. Si el líquido está **fresco**, la entidad está cerca y la respuesta correcta es no moverse; si el líquido está **seco**, la entidad ya pasó y está lejos, y lo correcto es seguir avanzando.

El cuaderno describe las entidades a este nivel: señales, estados y qué hacer en cada estado.

### 8.2 Entidades

Serán 9 criaturas mitológicas chilenas:
1. El Trauco
2. El Tue Tué
3. La Viuda
4. Calchona
5. Imbunche
6. El Basilisco
7. Brujos de Salamanca
8. El Cuero
9. La Fiura

## 9. Riesgo y recompensa

Sistema que atraviesa las decisiones:

- Para cada situación, el **cuaderno indica un orden de las opciones según su riesgo**. No es una única respuesta correcta y tres equivocadas: es un ranking.
- La **opción más arriesgada entrega +1 de contenido** (llega después como envío de Receive Media), pero tiene la **mayor probabilidad de incapacitar o matar** al amigo, además de ser la que más impacta en el medidor Trust.
- **Ninguna opción está etiquetada como arriesgada en la interfaz.** El jugador sólo lo sabe si consultó el cuaderno. El juego no distingue si la decisión arriesgada fue intencional o accidental.
- **Trust baja según el riesgo de la opción elegida, no según la consecuencia.** Mandar a un amigo a una opción muy arriesgada le cuesta confianza aunque salga ileso; una opción prudente que sale mal no la castiga igual.
- **Trust no está atada al fracaso en conseguir contenido.** Perder un envío no baja Trust.

## 10. Medidores

Tres diales en la pared. Si alguno llega a 0, el jugador pierde y reinicia la noche.

- **Connection:** indica cuántos amigos están conectados. La conexión se pierde de forma aleatoria y Player debe recuperarla con Audio Sync. Un amigo desconectado decide solo y es muy probable que muera. Si uno muere, pierdes esa noche y puedes continuar desde el comienzo de esa noche.
- **Sanity:** Baja constante y lentamente. Además, baja **cuando ocurre un screamer**, en una cantidad fija por screamer.
- **Trust:** baja cuando Player manda a un amigo a una opción arriesgada, o cuando no le contesta el llamado a un amigo. Se recupera lentamente mientras no ocurran nuevos errores.

## 11. Minijuegos

### Audio Sync — ritmo, recupera Connection

- Se activa al clickear el chat de un amigo **desconectado**.
- El amigo marca **4 u 8 tiempos con aplausos** (según la dificultad de la noche) y Player debe replicarlos con la **barra espaciadora**.
- Se puede reintentar las veces que se quiera, y se puede salir del chat para atender otras cosas y volver después.
- Si el amigo murió, la opción desaparece y se indica que la conexión se perdió de forma permanente.

### Receive Media — clicker y encontrar la diferencia

- Cada cierto tiempo un amigo envía contenido, con un **tiempo limitado para aceptarlo**.
- Si es un **video**, se descarga presionando repetidamente click o espacio (clicker).
- **Desde la noche 3**, algunos envíos son **ráfagas de imágenes** en las que hay que identificar la que tiene la anomalía.
- Si no se acepta a tiempo o se falla, ese contenido se pierde y no avanza el objetivo secundario. Al completarlo, sí lo avanza.

## 12. Scroll Social Media

No es un minijuego, sino una **acción de recuperación**:

- Player scrollea redes sociales desde el celular para calmarse y **recuperar Sanity**.
- Se scrollea con la **rueda del mouse**: Sanity sube mientras el jugador scrollea y deja de subir si se detiene.
- Se puede usar en cualquier momento, y el jugador decide cuándo soltar el celular.
- **Costo de oportunidad:** mientras lo usa, no está atendiendo el resto de los frentes (chats parpadeando, envíos de contenido, conexiones caídas).

## 13. Screamers

- Las entidades atormentan a Player en cualquier momento y pueden **interrumpir o complicar lo que está haciendo**: tapan la pantalla unos segundos, desordenan las páginas del cuaderno, hacen vibrar el celular, cortan el audio de un amigo.
- Cada screamer baja una **cantidad fija de Sanity**. Es la única fuente de pérdida de Sanity.
- Todos tienen una **señal previa muy breve** (un parpadeo de luz, una caída del sonido ambiente) para que el jugador pueda reaccionar.
- Los screamers **no matan ni dañan a Player**: sólo lo asustan y le roban tiempo y atención.

## 14. El cuaderno

- Es el manual del jugador y la fuente de toda decisión: señales, estados de cada entidad, orden de riesgo de las opciones.
- Es **deliberadamente limitado**: no cubre todo desde el principio. Entre noches se agregan páginas nuevas.
- Es físico y diegético: se abre, se pasan páginas, y un screamer puede **desordenarlo**, obligando a reordenarlo bajo presión.

## 15. Progresión de las noches

Las mecánicas se introducen de a poco para no abrumar al jugador.

| Noche | Qué se agrega |
|---|---|
| 1 | Decisiones, Receive Media con videos y Trust. Sin pérdida de conexión. Un único screamer, que enseña Sanity y Scroll Social Media. Funciona como tutorial. |
| 2 | Pérdida de conexión y Audio Sync de 4 tiempos. Los screamers pasan a ser regulares. |
| 3 | Ráfagas de imágenes con anomalías (objetivo secundario de ANOMALIES). Screamers más frecuentes. |
| 4 | Audio Sync de 8 tiempos. Varios amigos piden ayuda a la vez y las señales de las entidades se solapan. |
| 5 | Todas las mecánicas a la vez y el evento final de la historia. |

## 16. Historia y finales

- Cada noche el canal crece con el contenido que graban los amigos, pero **Player empieza a notar que las entidades se interesan cada vez más en él**.
- Su protección se debilita a medida que avanzan las noches.
- **El final depende de cuántos amigos sobrevivieron y de cuánta confianza queda.**

## 17. Arte y sonido

- **Pixel art 2D que busca sensación de tridimensionalidad**: perspectiva de un punto de fuga, capas separadas (fondo, pared, escritorio, primer plano) y **efecto parallax al mover el mouse**.
- **Iluminación baja**, con la pantalla de la computadora y la ventana como fuentes de luz principal. Tal vez una lámpara secundaria.
- El sonido es clave para la tensión: estática, ruidos del entorno de los amigos y silencios.
- Las voces de los amigos se muestran como **texto con un sonido breve por mensaje**.
- Cada entidad tiene **sonido e iluminación propios y distinguibles**, no sólo color: además de ser una decisión estética, sirve para que un jugador daltónico pueda identificarlas.

## 18. Accesibilidad y opciones

- Opción para **reducir los destellos** (los screamers y los parpadeos de luz).
- Control de volumen por canal.
- Señales redundantes: ninguna información crítica depende únicamente del color.

## 19. Referencias

- **Five Nights at Freddy's:** estructura por noches, ubicación fija del jugador, gestión de recursos bajo presión.
- **Keep Talking and Nobody Explodes:** información dividida en dos y un manual que se consulta bajo presión de tiempo.
- **Lethal Company:** rol de operador que guía a los compañeros que exploran.
- **Phasmophobia:** identificación de entidades a partir de sus señales.
- **Home Safety Hotline:** identificación de entidades a partir de descripciones de terceros, usando un manual. Spook Dial añade un cuaderno más limitado, varios interlocutores simultáneos, medidores y minijuegos.
- **Not For Broadcast:** gestión de una transmisión con varias tareas en paralelo.

### Selling points

- **Comunicación asimétrica:** el jugador es la única fuente de conocimiento y sus decisiones definen el destino de otros personajes.
- **Tensión por multitarea:** decidir, recuperar la conexión, mantener la cordura y recibir contenido al mismo tiempo.
- **Riesgo y recompensa:** las opciones arriesgadas dan más contenido, pero pueden dañar a un amigo y costar confianza.
- **Aprendizaje gradual:** cada noche suma una mecánica nueva.
- **Alcance acotado:** un solo escenario permite concentrar el esfuerzo en atmósfera, arte y sonido.
- **Rejugabilidad:** las solicitudes se generan combinando señales, por lo que cada intento de una noche es distinto.

---

## 20. Adaptación narrativa (versión Twine)

Existe una versión de historia interactiva de Spook Dial, escrita en Twine para un curso, estructurada según el Viaje del Héroe. No es el juego en Godot, pero fija nombres y una trama que pueden reutilizarse:

- **Matías:** el protagonista, equivalente a Player. Aislado, sin amigos, experto en lo paranormal.
- **León, Gonzalo y Agustín:** los tres amigos que graban el canal.
- **Loreto:** la madre de Matías.
- **Lugares:** el colegio en Puerto Montt (mundo ordinario) y una cabaña aislada (mundo especial), donde el grupo pasa las noches de grabación.
- **Trama:** el grupo le pide ayuda a Matías por su conocimiento; él los acompaña al viaje; durante las noches guía a sus amigos; **León es poseído**; en el clímax Matías queda malherido y **decide dejarse salvar por sus amigos** en lugar de levantarse solo. El epílogo lo muestra de vuelta en el colegio, acompañado.
- **Defecto del protagonista:** el aislamiento. Lo que realmente busca no es contenido ni dinero, sino amistad.
- Esa versión tiene además tres finales de derrota: rechazar la invitación, abandonar el viaje y morir en la cabaña.

Si el juego en Godot toma estos nombres, Player pasa a llamarse Matías y los tres amigos quedan nombrados. Está pendiente decidirlo.

---

## 21. Decisiones abiertas

Puntos discutidos y **no resueltos**. No deben darse por definidos:

1. **Diferenciación mecánica de los tres amigos.** Hoy sólo se distinguen por nombre, avatar e icono. Se propuso darles perfiles que cambiaran la calidad de la información (temerario / escéptico / metódico), pero no quedó en el Concept.
2. **Mecánica de mentir.** Se discutió la posibilidad de que Player pueda mentirle a un amigo como acción meta. Sin decidir.
3. **Nombres definitivos de las entidades** y su bestiario completo con estados.
4. **Folclore chileno** como fuente de entidades (se mencionaron el Trauco y el Imbunche, y la sal o la arena como defensa). Sin decidir.
5. **Valores numéricos:** cuánto baja cada medidor, duración de los tiempos límite, umbral de contenido por noche.
6. **Condición exacta de los finales:** cómo se combinan amigos sobrevivientes y Trust.
7. **Nombres de los personajes del juego** (ver sección 20).
8. **Idioma del juego.**
