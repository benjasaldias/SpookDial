# Análisis del diseño (sesión 1, 15 de octubre de 2026)

> **Documento histórico.** Lo vigente está en `spook_dial_design.md` (v2), y el alcance y el calendario, en `docs/05_plan_produccion.md`. Las §5, §6 y §7 de este documento quedaron reemplazadas.
>
> **Qué pasó con cada propuesta (sesión 2):**
>
> | Propuesta | Resultado |
> | --- | --- |
> | Vida de los amigos, pantalla de derrota explicativa, temporizadores pausados por screamers, descarga manteniendo presionado, diales con íconos | Aceptadas |
> | Connection como señal | Aceptada y ampliada: **señal por amigo**, interferencias anunciadas y Audio Sync individual |
> | Efectos graduales | Aceptados, con los de Benja: Trust bajo acorta los temporizadores; Sanity bajo trae viñeta y screamers auditivos |
> | Acciones universales | **Rechazada.** Cada entidad tiene acciones propias y reglas estilo Keep Talking, y el amigo suele decir qué entidad es |
> | Buscador por rasgos | Pospuesto a después de la v1. Si la estática tapa el nombre, se pregunta de nuevo |
> | Personalidades con efectos | Rechazada: las personalidades son solo de sabor |
> | Finales Amistad × Fama | **Rechazada:** final único (ganas o pierdes). La cuota de contenido pasa a ser condición para ganar cada noche |
> | Evento final "Ayúdenme" e historia dentro del juego | **Rechazados:** el juego es estrictamente el escritorio; la historia va en cinemáticas opcionales |
> | Pedir contenido | Pospuesto a después de la v1 |
> | 6 entidades | Ahora son 7 (se suma el Trauco), con los **Brujos de Chiloé** como antagonistas de la historia |
> | Cortes de alcance | Aceptados como lista priorizada (`docs/05`). La cruz, el retrato y mentir estaban obsoletos |
> | Parallax solo en la ventana | Ventana y, levemente, la pared |
> | Proyecto fuera de OneDrive | Aceptado: `C:\dev\spook-dial`, con git y GitHub privado |

Revisión crítica de `spook_dial_design.md` antes de programar. Cada punto dice qué está mal, por qué importa y qué propongo.

- **Decidido**: lo resolviste durante la sesión.
- **Propuesta**: espera tu respuesta (preguntas en §7).

Uso los nombres de medidores de tu documento: **Sanity**, **Trust** y **Connection**.

## Resumen

- El concepto es bueno y se puede producir: fantasía de operador, folclore chileno, un solo escenario y riesgo/recompensa con dilema moral.
- El problema más grave no es una mecánica, es el **alcance**: el documento describe más juego del que cabe en 11 semanas para una persona que empieza con Godot. §5 y §6 proponen el recorte y el calendario.
- El documento tiene **14 contradicciones o vacíos** (§1). El más importante, la muerte, ya está decidido.
- Las debilidades de diseño más serias:
  - **Sobrecarga cognitiva** (§3.2).
  - **Medidores que no hacen nada hasta llegar a 0** (§3.3).
  - **Opciones de respuesta que delatan a la entidad** (§3.5).
  - **Un objetivo secundario sin consecuencias** (§3.6).

---

## 0. Lo que funciona (conservar)

1. **La fantasía de operador con información asimétrica.** Asusta porque las entidades no se ven, y por eso mismo es barata: no hay que animarlas.
2. **El folclore chileno.** Le da identidad propia en un mercado lleno de fantasmas genéricos, y sus remedios y comportamientos se pueden convertir en mecánicas.
3. **El ranking de riesgo en vez de "correcta/incorrecta".** Bien usado, permite decidir con información incompleta: "no sé si es A o B, así que elijo lo aceptable para las dos".
4. **Fama contra amistad.** El contenido empuja a arriesgar a los amigos y Trust empuja a protegerlos. Conecta directamente con el tema del Twine: lo que Matías realmente busca es amistad.
5. **Un escenario con noches paramétricas.** Si cada noche es un conjunto de datos y no una escena distinta, agregar noches cuesta poco.
6. **La duración**: unos 35 minutos más los reintentos. Es adecuada para una entrega.

---

## 1. Contradicciones del documento y cómo quedan

| # | Tema | Qué dice el documento | Resolución |
| --- | --- | --- | --- |
| 1 | Muerte de un amigo | §10 dice que la noche se reinicia. §7 (estado "muerto"), §11 ("conexión perdida de forma permanente") y §16 (final según sobrevivientes) suponen muertes permanentes. | **Decidido: se reinicia la noche.** Se eliminan el estado "muerto" persistente y la "conexión perdida permanente". El final se calcula con Trust y contenido (§2). |
| 2 | Pérdida de Sanity | §10: baja constante más screamers. §13: los screamers son "la única fuente". | **Propuesta:** ambas. Un drenaje lento obliga a usar el celular cada cierto rato, y cada screamer resta una cantidad fija. |
| 3 | Qué baja Trust | §8: la consecuencia negativa. §9 y §10: el riesgo de la opción elegida. | **Propuesta:** el riesgo de la opción elegida (como en §9), nunca la mala suerte. También baja al no contestar a tiempo y al usar "Pedir contenido". |
| 4 | Contenido extra | §8: elegir "LA PEOR consecuencia". §9: elegir la opción más arriesgada. | **Propuesta:** el contenido extra sale de elegir **Grabar**, si el amigo no muere. Se elimina la regla de "la peor consecuencia", porque el jugador elige opciones, no consecuencias. |
| 5 | Connection | §10: "indica cuántos amigos están conectados" (un conteo de 0 a 3), pero además es un medidor que "llega a 0". | **Propuesta:** que sea la **calidad de la señal**, un valor continuo que anuncia las desconexiones (§3.4). |
| 6 | Dónde se juega Audio Sync | §6 y §11: en el PC. El arte tiene un mixer que el documento no menciona. | **Decidido: en el mixer.** |
| 7 | El chat en el PC | §7: con un chat abierto, el PC muestra "gibberish". Pero las otras entradas tienen que parpadear para avisar que alguien espera. | **Propuesta:** el PC siempre muestra la lista de 3 entradas, con la conversación abierta destacada. El panel lateral muestra la conversación y tiene una pestaña con aviso por amigo. Se elimina el modo gibberish. |
| 8 | Objetos del escritorio | §6: audífonos, cruz, retrato y cortinas "de protección". El arte no tiene audífonos, cruz ni retrato, y sí tiene termómetro y mixer. | **Decidido:** el termómetro es decorativo y el mixer es Audio Sync. **Propuesta:** cortar audífonos, cruz y retrato. Las cortinas quedan como ambientación y blanco de screamers. |
| 9 | Entidades | §8.2: "Serán 9 criaturas chilenas". §21.3–4: "sin decidir". | **Propuesta:** folclore chileno confirmado, con **6 entidades** para la entrega (§5.2). |
| 10 | Noche 5 | §3: se agrega "una mecánica de defenderse contra una entidad dentro de la base". §15: "todas las mecánicas a la vez y el evento final". | **Propuesta:** ninguna mecánica nueva; el evento final usa lo que el jugador ya aprendió (§3.9). |
| 11 | Estados de daño | §8: "dañado, aturdido, perdido o muerto (si ha perdido mucha vida)", sin definir qué hace cada uno. | **Propuesta:** 3 puntos de vida (PV) por noche. **Herido** resta PV, **aturdido** deja al amigo no disponible unos segundos y **perdido** se corta. |
| 12 | Hora | §5: "12:00 AM a 6:00 AM". El celular dibujado dice "00:00". | **Propuesta:** formato de 24 horas (00:00 → 06:00), como ya está dibujado. |
| 13 | Protagonista | "Player" en todo el documento; "Matías" en §20. | **Propuesta:** Matías, León, Gonzalo y Agustín (pregunta 1). |
| 14 | Opciones de respuesta | §8: "siempre cuatro, y dependerán de la entidad". §9: un ranking por riesgo. | Si dependen de la entidad, delatan quién es. Ver §3.5. |

---

## 2. Qué implica "si un amigo muere, se reinicia la noche"

**Los amigos necesitan vida.** Sin ella, una sola mala decisión borra hasta 7 minutos de juego.

- Propuesta: **3 PV por amigo y por noche**, que se restauran al empezar cada noche.
- La opción más arriesgada puede quitar 2 PV. El amigo muere al llegar a 0.

**La pantalla de reinicio tiene que enseñar.** En un juego de deducción, morir sin entender por qué frustra, y morir entendiendo enseña.

- Debe mostrar qué entidad era, en qué estado estaba, qué se eligió y cuál era el ranking.
- Por ejemplo: *"Era El Cuero, en el agua. 'Grabar' era lo más arriesgado; lo seguro era 'Huir'."*
- Esto es lo que hace justo el reinicio.

**El reinicio es inmediato**, sin cinemáticas largas. La noche se vuelve a generar con otro orden, así que reintentar no es repetir de memoria.

**El final ya no puede depender de los sobrevivientes**, porque al terminar siempre quedan 3. Propuesta: dos ejes.

- **Amistad**: el promedio de Trust al cerrar cada noche.
- **Fama**: el contenido total comparado con la cuota total.

| | Fama baja | Fama alta |
| --- | --- | --- |
| **Amistad alta** | *Amigos de verdad.* El canal no despegó, pero Matías ya no está solo. Es el final "temático" del Twine. | *Leyenda.* El final difícil: exige ser experto, porque solo un experto sabe cuándo es seguro grabar. |
| **Amistad baja** | *Nada.* Ni canal ni amigos. | *Solo con sus números.* El canal triunfa y los amigos se van. |

**Trust vuelve a 100 al empezar cada noche.** Si no, una mala noche condena a las siguientes. El promedio para el final se guarda aparte.

---

## 3. Debilidades y malas ideas (de más a menos grave)

### 3.1 El alcance no cabe en el plazo — CRÍTICO

**Problema.** El documento describe todo esto:

- decisiones con mensajes generados por combinación;
- el cuaderno;
- 3 medidores;
- 3 minijuegos (Audio Sync, descarga y ráfagas de anomalías);
- el celular;
- varios tipos de screamer;
- 9 entidades con estados;
- 5 noches y una mecánica extra en la noche 5;
- historia, finales, menú, guardado y opciones.

Para 11 semanas, trabajando solo y en el primer proyecto con Godot, es demasiado.

**Por qué importa.** El cuello de botella no es el código, que hago yo. Son cuatro cosas, y las tres primeras dependen solo de ti:

1. el arte que dibujas tú;
2. unas 250 a 300 líneas de texto que escribes tú;
3. tu tiempo en la interfaz de Godot;
4. probar y balancear.

**Propuesta.** El recorte de §5 y el calendario de §6. El principio: **un bucle central feo pero jugable al final de la semana 2**, y todo lo demás después. Si en esa prueba el bucle no es divertido, ningún arte lo va a salvar, y es mejor saberlo en noviembre que en diciembre.

### 3.2 Sobrecarga cognitiva — ALTO

**Problema.** El jugador tiene que hacer todo esto a la vez:

- leer 3 chats y traducir las descripciones a rasgos;
- buscar en el cuaderno y decidir contra el temporizador;
- y entremedio, llevar el ritmo de Audio Sync, descargar, scrollear y aguantar screamers.

Los juegos de referencia evitan esa carga de distintas formas:

- FNAF funciona porque cada tarea es instantánea.
- Keep Talking reparte la carga entre dos personas.
- Home Safety Hotline atiende una llamada a la vez.

**Por qué importa.** La línea entre "tensión" y "caos frustrante" es fina, y en un juego de lectura se cruza rápido.

**Propuesta.**

- **Director de ritmo** (código). Pone un tope de solicitudes simultáneas por noche (1, 2, 2, 3 y 3) y una separación mínima entre eventos. En las primeras noches nunca junta desconexión, solicitud y envío.
- Chat y cuaderno **visibles a la vez**, sin alternar pantallas, y **marcadores por amigo** en el cuaderno (`docs/02` §6).
- Temporizadores generosos al inicio (45 s) que se acortan noche a noche.
- Minijuegos de reflejos de 5 s como máximo.
- Opción de accesibilidad: temporizadores ×1,5.

### 3.3 Medidores que no hacen nada hasta llegar a 0 — ALTO

**Problema.** Trust y Sanity solo importan cuando llegan a 0. Un medidor así es invisible hasta que te mata.

**Propuesta.** Un efecto gradual para cada uno. Los tres son baratos de programar:

- **Sanity bajo 40**: alucinaciones. Entradas que parpadean sin una solicitud real, letras cambiadas en el cuaderno, susurros.
- **Trust bajo 40**: amigos impacientes. Los temporizadores bajan un 25 % y rechazan "Pedir contenido".
- **Connection bajo 50**: mensajes con estática (algunas letras se reemplazan por ▒) y riesgo de desconexión.

### 3.4 Connection: redundante y al azar — MEDIO-ALTO

**Problema.**

- Como conteo de amigos conectados, el dial repite lo que ya muestran las entradas del PC.
- Si las desconexiones son puramente aleatorias, el jugador no puede anticiparlas, solo reaccionar.

**Propuesta: Connection pasa a ser la calidad de la señal.**

- Es un valor continuo de 0 a 100 que baja lentamente, más rápido en noches avanzadas y con actividad de entidades.
- Bajo 40, cada amigo puede desconectarse, y cada desconexión se **anuncia 3 segundos antes** (estática y la entrada titila).
- Bajo 50, los mensajes llegan con estática y las descargas son más lentas.
- **Audio Sync se juega en el mixer en cualquier momento.** Si sale bien, sube Connection y reconecta a todos. Si Connection llega a 0, se pierde la noche.

Con esto, el azar se vuelve legible y el escritorio queda con **cuatro objetos y cuatro trabajos**:

- el PC sirve para decidir;
- el cuaderno, para saber;
- el celular cuida Sanity;
- el mixer cuida Connection.

Opcional: los 3 faders del mixer, que ya están dibujados, pueden mostrar la conexión de cada amigo.

### 3.5 Las opciones de respuesta — ALTO

**Problema A.** Si las 4 opciones dependen de la entidad ("Échale sal"), las opciones mismas dicen quién es, y el cuaderno sobra.

**Problema B.** Si la mejor opción siempre es la más segura, las opciones 2 y 3 no tienen razón de existir. La excepción es la duda: cuando no sabes si es una entidad u otra, eliges la opción aceptable para ambas. Pero eso solo funciona si **las opciones son las mismas para todas las entidades**.

**Propuesta.** Cuatro acciones universales: **Huir · Esconderse · Quedarse quieto · Acercarse y grabar**.

- El folclore vive en los estados, en el texto del cuaderno y en las reacciones de los amigos (*"me escondí y grité lo de la sal… se fue"*).
- **Grabar** es la que da contenido, y en algunos estados es **segura**: ese es el premio del experto.

Detalle en `docs/02` §5.

### 3.6 Un objetivo secundario sin consecuencias — MEDIO

**Problema.** Si no llegar a la cuota de contenido no cambia nada, el jugador lo ignora, y el dilema de riesgo y recompensa desaparece.

**Propuesta.** El contenido define el eje **Fama** del final (§2) y se ve entre noches (suscriptores y comentarios).

Regla de balance: **jugar 100 % seguro no alcanza la cuota.** Para ser famoso hay que arriesgar a los amigos, o ser experto y grabar solo cuando es seguro.

### 3.7 El clicker de Receive Media — MEDIO

**Problema.** Presionar repetidamente el clic o el espacio cansa, puede doler (lesión por esfuerzo repetitivo), no es accesible y no pide ninguna decisión.

**Propuesta.** **Mantener presionado** "Descargar".

- Mientras lo mantienes no puedes hacer nada más, así que el costo de atención es el mismo.
- La velocidad depende de Connection.
- Si sueltas, la descarga se pausa.

### 3.8 Screamers — MEDIO

**Problema.**

- La "señal previa para que el jugador pueda reaccionar" no tiene ninguna reacción posible.
- Un screamer que tapa la pantalla en los últimos 3 segundos de un temporizador puede matar a un amigo, y eso se siente injusto.
- Los jumpscares pierden efecto si se repiten.

**Propuesta.** Sin contraataque (por alcance), pero con reglas de justicia:

- Los que tapan la pantalla **pausan los temporizadores**.
- Nunca ocurren en los últimos 5 segundos de una decisión.
- El aviso (un parpadeo de luz y una caída del sonido) sirve para soltar lo que estás haciendo.
- Variedad antes que frecuencia. La mayoría son ambientales: la cortina, los ojos en la ventana, el celular que vibra, las luces.
- Desde la noche 2 hay, como máximo, 1 jumpscare de pantalla completa por noche.

### 3.9 Una mecánica nueva en la noche 5 — MEDIO

**Problema.** Estrenar una mecánica en la noche más difícil, sin práctica, garantiza fracasos repetidos justo en el clímax.

**Propuesta.** Un evento guionado con lo ya aprendido. Por ejemplo:

- A las 05:00 la entidad está dentro de la cabaña; Connection cae y los screamers se intensifican.
- Por primera vez, el chat le ofrece a Matías la opción **"Ayúdenme"**.
- Si la Amistad es alta, los amigos vuelven y lo salvan. Si es baja, la enfrenta solo.

Es el tema del Twine ("decide dejarse salvar") convertido en mecánica, y cuesta poco: guion más una o dos ilustraciones.

### 3.10 La historia no tiene por dónde contarse — MEDIO

**Problema.** §16 dice que Matías nota que las entidades se interesan en él, pero no hay ningún canal para contarlo.

**Propuesta.** Todas estas son baratas:

- Charla breve de los amigos cuando no hay solicitudes (2 a 4 líneas).
- Una pantalla entre noches con la conversación después de la transmisión, las estadísticas del canal y las páginas nuevas del cuaderno.
- Loreto, la mamá, le escribe al celular en las noches 2 a 4. En la noche 5 llega un mensaje "de mamá" que no es de ella.

**¿Dónde está Matías?** Propuesta: en la cabaña, mientras los amigos exploran los alrededores (bosque, lago, casa abandonada, camino, cueva). Así cada noche tiene un lugar, y el lugar justifica qué entidades aparecen.

### 3.11 El parallax con el mouse — MEDIO

**Problema.** Si toda la escena se mueve con el mouse:

- los objetos clickeables se mueven mientras apuntas;
- todas las capas necesitan márgenes extra;
- y a ×1,5 (1080p), el pixel art tiembla al moverse.

**Propuesta.** Parallax relativo: solo se mueve el exterior que se ve por la ventana, y la habitación queda fija. Detalle en `docs/03` §4. Además, una opción para desactivarlo.

### 3.12 Los diales — MEDIO

**Problema.**

- Tienen 12 marcas, así que parecen relojes, y el jugador va a intentar leer la hora en ellos.
- Se distinguen solo por el color (verde, rojo y amarillo), que es justo lo que §18 prohíbe. Además, el daltonismo rojo-verde es el más común.

**Propuesta.**

- Caras de manómetro: escala semicircular con una zona roja en el extremo bajo.
- Un **ícono pixel por dial**: una antena para Connection, un ojo para Sanity y dos manos para Trust.
- Un LED que parpadea cuando el medidor baja de 25.

### 3.13 El folclore necesita adaptación — MEDIO

- En la tradición, **el Trauco** y **la Fiura** tienen contenido sexual; la leyenda del Trauco se usaba para encubrir embarazos. Para un público de 13 años o más hay que adaptarlos (el Trauco: hachazos en los árboles, una mirada que tuerce) o dejarlos fuera de la entrega.
- **El Imbunche** implica la mutilación de un niño. Conviene tratarlo de forma implícita.
- **Los brujos de Chiloé** se vinculan con un juicio real (1880–1881). Mejor tratarlos como figura mítica, sin caricaturizar a personas reales.
- Verifica cada leyenda en fuentes sólidas: Oreste Plath, *Geografía del mito y la leyenda chilenos*, y Memoria Chilena (Biblioteca Nacional).

### 3.14 Detalles menores

- **"Rejugabilidad porque las solicitudes combinan señales."** Sin un director, el azar genera combinaciones injustas, como tres solicitudes difíciles a la vez. El director de §3.2 lo controla.
- **Mentir (§21.2).** Cortar: no resuelve ningún problema claro y suma escritura.
- **Trust por amigo.** Es más rico, pero triplica la interfaz. Para la entrega, un solo Trust.

---

## 4. Mecánicas propuestas (resumen)

| Mecánica | Propuesta | Costo | Detalle |
| --- | --- | --- | --- |
| Vida de los amigos | 3 PV por noche | Bajo | §2 |
| Pantalla de reinicio que explica | Entidad, estado, elección y ranking | Bajo | §2 |
| Connection como señal | Valor continuo que anuncia las desconexiones | Bajo | §3.4 |
| Efectos graduales | Alucinaciones, impaciencia, estática | Bajo | §3.3 |
| Acciones universales | Huir / Esconderse / Quieto / Grabar | Bajo | `docs/02` §5 |
| Cuaderno-buscador | Filtros de 3 estados y marcadores por amigo (tu idea, refinada) | Medio | `docs/02` §6 |
| Preguntas de seguimiento | Preguntar por una categoría cuesta segundos | Medio | `docs/02` §7 |
| Personalidades | Temerario / escéptico / metódico, con efectos simples | Bajo | `docs/02` §8 |
| Pedir contenido | Tu idea, con cuatro ajustes | Bajo | `docs/02` §11 |
| Descarga manteniendo presionado | Reemplaza al clicker | Bajo | §3.7 |
| Director de ritmo | Controla cuántas cosas pasan a la vez | Medio | §3.2 |
| Finales Amistad × Fama | 4 finales | Bajo | §2 |
| Evento final "Ayúdenme" | Sin mecánica nueva | Bajo a medio | §3.9 |

---

## 5. Alcance para la entrega

### 5.1 Qué queda, qué se simplifica y qué se corta

**Queda:**

- el bucle central: chat, cuaderno-buscador y decisiones;
- los tres medidores;
- Audio Sync en el mixer, la recepción de videos y el celular;
- los screamers;
- 5 noches y los finales;
- menú principal y guardado al inicio de cada noche;
- opciones: volumen por canal, reducir destellos, desactivar el parallax y temporizadores ×1,5.

**Se simplifica:**

- de 9 a **6 entidades**;
- el parallax, solo en la ventana;
- la descarga, manteniendo presionado;
- los screamers, a 4 tipos más 1 jumpscare por noche;
- el feed, a 12 publicaciones;
- los finales, a texto más 1 ilustración;
- la noche 5, a un evento guionado;
- la historia, a textos entre noches y charla.

**Se corta (queda para después de la entrega):**

- las ráfagas de imágenes con anomalías, porque requieren mucho arte;
- la mecánica de defensa en la base;
- mentir;
- audífonos, cruz y retrato;
- el estado "perdido";
- Trust por amigo;
- la traducción al inglés.

### 5.2 Propuesta de entidades

| Entidad | Por qué entra | Lugar | Pareja señuelo (comparte rasgos) |
| --- | --- | --- | --- |
| El Tue Tué | Se reconoce por el sonido y tiene un remedio famoso (la sal) | Casa, techos | El Basilisco (canto de ave, plumas) |
| La Calchona | No es hostil si se la trata bien: rompe el patrón | Camino, campo | La Viuda (llanto de mujer) |
| El Cuero | Ligado al agua, con estados claros (orilla o agua) | Lago | — |
| El Basilisco | Grabar es mortal (por su mirada): castiga la codicia | Casa, bajo el piso | El Tue Tué |
| El Imbunche | Guardián: el peligro depende de dónde estás | Cueva | — |
| La Viuda | Figura humana; "no mires atrás" | Camino | La Calchona |

- **Los Brujos de Salamanca** no aparecen como entidad de turno, sino como **antagonistas de la historia**: son los que "se interesan" en Matías y protagonizan el evento final.
- **En reserva:** el Trauco (adaptado según §3.13) y la Fiura.

### 5.3 Progresión de las noches (revisada)

| Noche | Lugar | Entidades nuevas | Qué se agrega |
| --- | --- | --- | --- |
| 1 | Bosque junto a la cabaña | El Tue Tué, La Calchona | Decisiones, recepción de videos y Trust. Sin desconexiones. Un screamer guionado enseña Sanity y el celular. Mensajes con 3 señales. |
| 2 | Lago | El Cuero | Connection con Audio Sync de 4 tiempos, screamers regulares, Pedir contenido y preguntas de seguimiento. |
| 3 | Casa abandonada | El Basilisco | Efectos de Sanity baja; mensajes con menos señales. |
| 4 | Camino y cueva | El Imbunche, La Viuda | Audio Sync de 8 tiempos, varias solicitudes a la vez y parejas señuelo. |
| 5 | La cabaña | — | Todo a la vez, más el evento final de los Brujos. |

---

## 6. Calendario (15 de octubre → 31 de diciembre, 11 semanas)

| Hito | Fechas | Benja (arte, escritura, Godot) | Claude (código) | Está listo cuando… |
| --- | --- | --- | --- | --- |
| 0. Diseño congelado | 15–18 oct | Responder §7; decidir la ubicación del proyecto; instalar Aseprite Wizard; corregir y separar el arte P0 | Actualizar el diseño a v2; configurar el proyecto, git y el MCP | No queda ninguna contradicción abierta |
| 1. Bucle central | 19 oct – 1 nov | Arte P1 (interfaz del chat, entradas, íconos, avatares); bestiario de 3 entidades | Escena del escritorio, chat, generador de solicitudes, cuaderno-buscador, medidores, noche, reinicio explicativo | Una noche se juega de punta a punta con arte provisional, y podemos responder "¿es divertido?" |
| 2. Sistemas secundarios | 2–15 nov | Diales, mixer, celular ampliado, interfaz del cuaderno y bocetos | Audio Sync, descarga, celular, screamers, efectos graduales, Pedir contenido, director de ritmo | Todas las mecánicas funcionan en la noche 4 |
| 3. Contenido completo | 16–29 nov | 6 entidades escritas, textos entre noches, menú, finales y screamers | Noches 1 a 5 como datos, pantalla entre noches, menú, guardado, finales, evento final | El juego se puede terminar |
| 4. Pulido y pruebas | 30 nov – 13 dic | Pruebas con 3 a 5 personas, arte P3, sonido | Balance, efectos, opciones, errores | El contenido queda congelado el 13 de diciembre |
| 5. Cierre | 14–31 dic | Materiales de entrega | Versión de Windows y últimos errores | Entregado, con holgura para las fiestas |

---

## 7. Preguntas abiertas (respóndelas por escrito)

Puedes contestar con el número y "sí", "no" o tu alternativa.

1. **Nombres.** ¿Usamos Matías, León, Gonzalo y Agustín, del Twine? *Recomiendo: sí.*
2. **Lugar.** ¿Matías está en la cabaña mientras sus amigos exploran los alrededores? *Recomiendo: sí, porque justifica el evento final y el lugar de cada noche.*
3. **Entrega.** ¿Cuál es la fecha exacta? ¿Qué exige: una versión jugable, un documento, una duración mínima, una presentación, relación con el Twine?
4. **Idioma.** ¿Solo español para la entrega? *Recomiendo: sí, con los textos guardados en datos para poder traducirlos después.*
5. **Tono.** ¿Los amigos hablan con chilenismos? ¿Con garabatos suaves ("weón") o sin ninguno, pensando en el público de 13 años o más?
6. **Acciones universales.** ¿Aceptas Huir / Esconderse / Quieto / Grabar en vez de opciones distintas por entidad? (§3.5)
7. **Preguntas de seguimiento.** ¿Las probamos en el prototipo? *Recomiendo: sí.* (`docs/02` §7)
8. **Connection como calidad de señal**, con desconexiones anunciadas. ¿De acuerdo? (§3.4)
9. **Efectos graduales** de los tres medidores. ¿De acuerdo? (§3.3)
10. **Las 6 entidades** de §5.2, con los Brujos como antagonistas. ¿De acuerdo, o prefieres incluir al Trauco?
11. **Finales Amistad × Fama** (§2). ¿Cuatro finales? ¿Cuál es el "verdadero" para ti?
12. **Evento final "Ayúdenme"** (§3.9). ¿Te gusta?
13. **Personalidades.** ¿Quién es el temerario, quién el escéptico y quién el metódico? (`docs/02` §8)
14. **Pedir contenido**: −15 de Trust (−30 si el amigo está herido), una vez por amigo y noche, desde la noche 2. ¿De acuerdo? (`docs/02` §11)
15. **Cortes** de §5.1 (anomalías, defensa en la base, mentir, audífonos, cruz y retrato). ¿De acuerdo?
16. **Parallax solo en la ventana.** ¿De acuerdo? (`docs/03` §4)
17. **Proyecto.** ¿Lo movemos a `C:\dev\spook-dial` y usamos git con un repositorio privado en GitHub como respaldo? *Recomiendo: sí.* (`docs/04` A)
