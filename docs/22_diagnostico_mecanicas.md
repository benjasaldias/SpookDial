# Diagnóstico de las mecánicas: por qué el juego se siente plano

**Escaneo de Claude, 10 de noviembre de 2026.** Benja lo pidió antes de dar sus propias correcciones. **Nada de esto está decidido**, y cada propuesta que cambia una decisión de `CLAUDE.md` lo indica. No es un plan que se ejecute.

**Lo que eligió Benja el 11 de noviembre (de la sección A):**

| # | Decisión |
| --- | --- |
| A1 | **No** se comparten lugares: el mensaje inicial dice qué le pasa al amigo y menciona el lugar solo a veces. |
| A2 | **Sí:** los señuelos cuestan 1 s, y las características se dicen con sinónimos y paráfrasis. |
| A3, A5 y A8 | **Sí:** olas de verdad con final fuerte, aviso cuando los videos no alcanzan y la criatura se queda un tiempo al azar. |
| A4 | **No**, por ahora: la cuota no sube. |
| Propias | Benja sumó **la Mano** (un enemigo que se espanta con el flash del celular) y **Trust sin recuperación**. |

El resto (A6, A7 y las secciones B a E) queda para otro momento. Todo esto se implementa en la sesión que describe `docs/23_prompt_ajustes_mecanicas.md`.

Se revisaron el código (`scripts/core/` y `scripts/desk/`), los datos (`data/balance.tres`, las 6 noches y las 7 entidades), los textos y las capturas. Los números salen de los datos de hoy.

## 1. En cinco líneas

1. **No hay presión de verdad.** Las solicitudes llegan cada 40 a 110 s y casi nunca se juntan, así que el jugador casi nunca tiene que repartir la atención entre los 3 amigos.
2. **La decisión no es un puzzle.** El lugar delata a la entidad, el cuaderno dice qué preguntar y la regla trae la respuesta escrita igual que el botón.
3. **Acertar no se siente y equivocarse casi no duele.** La acción correcta no da nada, la de mayor riesgo nunca conviene y el daño se reduce a una línea de texto.
4. **El terror queda detrás de los paneles.** Mientras se juega, el chat y el cuaderno tapan el cuarto, y los sustos solo restan Sanity, que el celular repone.
5. **Hay muchos medidores y pocas decisiones.** Son 8 sistemas de mantenimiento, cada uno con su botón para rellenarlo, y casi no se cruzan entre sí.

## 2. Diagnóstico

### 2.1 La identificación se resuelve sola

- **El lugar delata a la entidad.** Cada entidad tiene 2 lugares y solo "el camino de tierra" se repite (La Calchona y La Viuda). Los otros 12 lugares son de una sola entidad: "Estoy en la orilla del lago" ya es El Cuero. En la noche 1 el lugar identifica a la entidad siempre, y en las demás, en unas 6 de cada 7 solicitudes. El validador revisa las características compartidas, pero no los lugares.
- **Los señuelos no cuestan nada.** Si se clickean todas las frases destacadas, la entidad queda identificada por fuerza bruta: los señuelos se ponen rojos y las características se marcan. No hace falta pensar cuál es cuál.
- **El cuaderno dice qué preguntar.** Cada característica y cada observación lleva su pregunta entre paréntesis, por ejemplo "oveja balando sola (¿Qué oyes?)".
- **«¿Qué oyes?» siempre es la primera pregunta.** En las 7 entidades, la regla 1 depende del audio. La mitad de las veces o más, basta con preguntar «¿Qué oyes?» y escuchar para responder, y si no, «¿Qué ves?» completa casi todo.
- **«¿Cómo está el ambiente?» nunca decide una acción.** Ninguna observación es de Ambiente.
- **Resultado:** una solicitud típica es leer el lugar, abrir la página desde el índice, preguntar «¿Qué oyes?», escuchar y responder. Son unos 10 a 15 s, siempre con el mismo procedimiento.

### 2.2 La regla es una tabla, no un puzzle

- Cada regla es "si pasa X → acción", con 1 o 2 condiciones de sí o no. La página escribe la acción con el mismo texto del botón del chat ("→ Dejarle un plato de comida"): hay que encontrar la línea y clickear el botón que dice lo mismo.
- Cada entidad tiene entre 4 y 8 situaciones posibles. Después de 2 o 3 encuentros, la tabla ya está memorizada.
- En Keep Talking, lo entretenido sale de dos cosas: **traducir** (quien ve describe con sus palabras y quien lee tiene que reconocer de qué habla) y las reglas con **pasos intermedios**. Aquí no pasa ninguna de las dos: el amigo usa las mismas palabras del cuaderno y las reglas se resuelven en un paso.

### 2.3 El riesgo y la recompensa no funcionan

- **La acción de mayor riesgo nunca conviene.** Tiene un 70 % de probabilidad de quitar 2 de las 3 vidas y baja Trust en 20, a cambio de un video que no hace falta, porque los envíos programados ya cubren la cuota. Además, el cuaderno la marca en rojo, así que funciona como una trampa señalizada y no como una tentación.
- **Acertar no da nada.** "Funcionó. Me dejó tranquilo." es la misma línea para las 7 entidades, así que jugar bien no se nota.
- **La única decisión de riesgo llega como castigo.** Si se pierde un video, la noche se pierde a las 06:00, salvo que se arriesgue a alguien. Pero el juego no avisa que la cuota ya no alcanza: el jugador se entera al final, después de 7 minutos.

### 2.4 El ritmo no tiene olas

Esto da la simulación del director con los datos de hoy (`plan_requests`):

| Noche | Llegadas (s desde las 00:00) | Espacio entre solicitudes | Tiempo para responder |
| --- | --- | --- | --- |
| 1 | 5, 90, 202, 271, 340 | 69 a 113 s | 80 s |
| 3 | 5, 70, 135, 214, 265, 309, 365 | 44 a 79 s | 55 s |
| 5 | 5, 52, 98, 141, 208, 244, 280, 304, 354, 380 | 24 a 67 s | 40 s |

- En la noche 1, el espacio entre solicitudes es mayor que el tiempo para responder: **aunque no se conteste nada, nunca hay 2 solicitudes a la vez.** En las noches 4 y 5, las 3 simultáneas casi nunca llegan a pasar.
- Las "olas" son en realidad un goteo parejo, con 25 s más de vez en cuando. Para que haya una ola, las solicitudes tienen que llegar juntas, con pocos segundos de diferencia, y después tiene que venir una calma de verdad.
- Todo se reparte parejo: los screamers (uno por tramo), los accidentes, los videos y las interferencias. Como nada se junta, la noche no tiene picos ni un final más intenso.
- Si cada solicitud pide unos 25 s de atención, en la noche 1 el jugador pasa más o menos la mitad del tiempo sin nada urgente que hacer.

### 2.5 Muchos medidores, pocas decisiones

| Sistema | Qué hace el jugador | ¿Hay una decisión? |
| --- | --- | --- |
| Señal | Audio Sync cuando baja | Poca: de 1 a 3 veces por amigo cada noche |
| Sanity | Scrollear el celular | Poca: la batería repone hasta 152 de Sanity por noche |
| Cortinas y criatura | Cerrar, esperar 25 s y abrir | No, una vez que se aprende cuánto dura |
| Videos | Mantener presionada la barra 10 s | No: es obligatorio |
| Accidentes | Elegir la opción obvia | No: "Presiona la herida" contra "Échale tierra" |
| Trust | Nada: se recupera solo | No |

- **Lo que muestran las barras casi nunca hace perder.**
  - Para que Trust llegue a 0 hay que equivocarse muchas veces.
  - Connection llega a 0 solo con los 3 amigos sin señal.
  - En la noche 1, si no se cierran las cortinas, Sanity no llega a 0 aunque no se toque el celular: baja unos 58 de 100.

  Lo que de verdad hace perder es un video que se pierde o un amigo que muere, y nada de eso está en las barras.
- **Los sistemas casi no se cruzan.** La señal y la estática sí se cruzan, y es la mejor interacción del juego. Sanity, Trust, las cortinas y los videos van cada uno por su lado.
- Los diales, las barras y las entradas del PC muestran lo mismo tres veces.

### 2.6 El terror está en el lugar equivocado

- **Mientras se juega, el cuarto no se ve.** Con el chat y el cuaderno abiertos (captura `arte_notebook.png`), la interfaz tapa unos dos tercios de la pantalla y casi toda la ventana. El terror ocurre en el cuarto, pero el jugador pasa la noche en el chat.
- **Los sustos no amenazan nada que importe.** Restan 8 o 15 de Sanity, que el celular repone, y después del segundo o el tercero se vuelven ruido.
- **El daño se comunica solo con texto:** "León recibió daño: 2/3" y "León murió.". No hay un grito cortado, ni un silencio, ni estática, ni una entrada del PC que se apague.
- **Las entidades no avanzan.** Durante una solicitud no cambia nada: la criatura no se acerca y el amigo no escribe nada nuevo. Lo único que avanza es el temporizador.
- **Los amigos nunca sorprenden.** Escriben siempre igual, y lo único que hacen por su cuenta es elegir al azar cuando nadie les contesta. La posesión de León, que es el mejor gancho de terror de la historia, no toca el juego.
- **El celular es el único momento sin decisiones:** scrollear sube Sanity y nada más. Lo que mejor funciona ahí son las fotos perturbadoras con poca Sanity, porque hacen dudar del único lugar seguro.

### 2.7 Las noches solo suben los números

Cada noche agrega 1 o 2 páginas y sube los valores, pero el juego no cambia de forma, y la noche 5 no trae nada nuevo. En FNAF, en cambio, cada noche trae un comportamiento nuevo.

## 3. Propuestas

Van ordenadas por cuánto mejoran el juego en relación con el trabajo que piden. Los costos son estos:

- **Datos:** solo `.tres`, `.csv` o `balance.tres`.
- **Chico:** menos de una sesión de código.
- **Medio:** un plan.
- **Grande:** cambia la estructura del juego.

### A. Arreglos baratos (datos o código chico)

| # | Qué | Qué arregla | Costo | ¿Cambia una decisión? |
| --- | --- | --- | --- | --- |
| A1 | **Lugares compartidos:** cada lugar sirve para 2 o 3 entidades (el bosque, el camino, el agua, la casa y la cueva). | 2.1: hay que preguntar para identificar | Datos | No |
| A2 | **Los señuelos cuestan:** clickear uno le quita 3 s al temporizador ("¿Qué? Eso no tiene nada que ver, Mati"). | 2.1: la fuerza bruta deja de ser gratis | Chico | Sí (26-oct: el señuelo no tiene "otro costo") |
| A3 | **Olas de verdad y un final fuerte:** las solicitudes de una ola llegan con 3 a 8 s de diferencia y después viene una calma de 40 a 60 s; las interferencias caen durante las olas y los videos, en las calmas; la última hora (05:00 a 06:00) junta la ola más grande con la criatura, y el primer minuto es de silencio. | 2.4 | Chico | Ajusta la del 2-nov (olas con respiro) |
| A4 | **La cuota obliga a arriesgar:** la cuota pasa a ser los envíos programados más 1, así que cada noche hay que elegir cuándo arriesgar a un amigo, y a cuál. | 2.3 | Datos | Sí (26-oct: los envíos cubren la cuota) |
| A5 | **Aviso de cuota imposible:** cuando los videos ya no alcanzan, el PC lo dice ("Faltan videos: alguien tiene que arriesgarse"). | 2.3: nadie pierde sin saber por qué | Chico | No |
| A6 | **Reacciones propias de cada entidad:** 3 líneas por entidad (bien, riesgo y mal) en vez de las 3 genéricas. | 2.3 y 2.6 | Datos (21 textos de Benja) | No |
| A7 | **"Matías piensa…" dura 1 s** en vez de 3. | Tiempo muerto | Datos | Ajusta la del 26-oct |
| A8 | **La criatura se queda un tiempo al azar** (de 15 a 40 s), así que revisar vuelve a importar. | 2.5 | Chico | Sí (7-nov: se queda 25 s fijos) |

### B. Que decidir cueste pensar (medio)

- **B1. Reglas que miran la noche y el cuarto.** El evaluador acepta condiciones que no salen de la solicitud:
  - la hora: "Entre las 03:00 y las 04:00, ninguna ofrenda sirve";
  - el amigo: "Si el amigo está herido, nunca acercarse";
  - el cuarto de Matías: "Si oíste el grito en tu cuarto, está sobre la cabaña: que tu amigo se quede callado y cierra las cortinas".

  Así los sistemas se cruzan: hay que mirar la hora en el celular, revisar la vida del amigo y escuchar el cuarto. Es la palanca más fiel a Keep Talking, y ya estaba como idea en `docs/17` (Lote A, "regla con condición").
- **B2. Página de "Reglas de la casa"** al principio del cuaderno: 3 o 4 reglas que valen para todas las entidades y se aplican antes que las de cada página. Se puede sumar una por noche, para que cada noche cambie algo (ver D2).
- **B3. Los amigos no hablan como el cuaderno.** Cada característica se dice de 2 o 3 formas: el cuaderno dice "grito de dos notas" y León escribe "hace como tue… tué". Hay que traducir, como en Keep Talking. Cada amigo puede describir a su manera, que sigue siendo solo sabor. El clic sigue marcando la característica, así que la ayuda se conserva.
  - **Costo:** textos de Benja y código chico.
  - **Cambia:** la convención de `docs/02` §9 según la cual la frase del chat es también el nombre en el cuaderno.
- **B4. La situación cambia a mitad de la solicitud.** Entre los 15 y los 25 s, una observación puede cambiar, y el amigo lo escribe sin que nadie le pregunte: "Mati… ya no grita." o "¡Ahora viene hacia mí!". La respuesta tiene que servir para la situación de ese momento. Da la escalada que hoy falta y obliga a releer el chat.
- **B5. El riesgo lo propone el amigo.** El cuaderno deja de marcar en rojo la acción de mayor riesgo, y es el amigo quien la pide ("¿Y si me acerco a grabarle la cara? Sería el video del año"). Junto con A4, aceptar se vuelve una decisión de verdad.
  - **Cambia:** la decisión del 26-oct según la cual el cuaderno marca la acción de mayor riesgo.

### C. El terror donde está la atención (medio)

- **C1. El daño se oye.** El mensaje se corta a mitad de una palabra ("Mati, se está acerc▒▒▒"), suena una ráfaga de estática y un grito por la radio, y la entrada del PC se apaga unos segundos. Solo después llega el aviso rojo. Si el amigo muere, aparece "escribiendo…", se va, y después no llega nada. También entra aquí el "escribiendo…" antes de cada respuesta, que ya estaba en los pendientes.
- **C2. El impostor.** Algo le escribe a Matías haciéndose pasar por un amigo: un amigo sin señal o aturdido que igual escribe, o uno que pide algo raro ("Mati, dime que entre a la cueva").
  - Las "Reglas de la casa" (B2) dicen cómo reconocerlo ("Un amigo sin señal no puede escribirte") y qué hacer: no contestar, o hacerle una pregunta.
  - Contestarle cuesta Sanity o hiere a alguien.
  - Vuelve sospechoso al chat, que es donde el jugador pasa la noche, y anticipa la posesión de León sin contarla.
  - No cambia la regla 9 mientras el impostor no sea León; si se quiere que lo sea, se decide en S21b, que ya incluye "alguien actúa raro".
- **C3. Con poca Sanity, las herramientas mienten.** Bajo 40 empiezan a pasar cosas: las letras del cuaderno se mueven, en el chat parpadea una pestaña de más, un audio trae un grito de más (y contar se vuelve difícil) y aparece un "MATÍAS:" que el jugador no escribió. Así Sanity importa antes de llegar a 0, y gastar batería se vuelve una decisión.
- **C4. La criatura también afecta a los amigos.** Mientras está en la ventana, la señal de todos baja más rápido. Mirar el cuarto pasa a ser parte de ayudarlos.

### D. Cambios más grandes (solo si Benja los quiere y caben)

- **D1. Mandar a grabar** (el "Pedir contenido" de `docs/05`, punto 13). Los videos dejan de llegar solos: Matías manda a un amigo a grabar, y eso lo expone a una entidad. El jugador decide cuánto riesgo y cuánto trabajo tiene a la vez, como con la energía en FNAF.
  - **Arregla:** 2.3, 2.4 y 2.5 de una vez.
  - **Cambia:** el director y la cuota.
- **D2. Un giro por noche.** Cada noche cambia una regla, como en FNAF. Por ejemplo: en la 2 aparece la criatura, en la 3 los amigos se separan, en la 4 llega el impostor y en la 5 el cuaderno pierde páginas. Encaja con S21b.
- **D3. Trust por amigo** (`docs/05`, punto 18). Un amigo con poca confianza no hace caso ("No, Mati, me voy a acercar igual"), o pregunta "¿seguro?" y hay que insistir.

### E. Recortes

- **Los accidentes, como están, no piden pensar.** Hay dos caminos: transformarlos (su código de "solicitud sin entidad" sirve para el impostor de C2) o quitarlos. Cualquiera de los dos cambia la decisión del 7-nov.
- **Los diales de la pared repiten lo que muestran las barras.** Pueden quedarse como decoración, pero no hace falta mantener las dos lecturas. Quitarlos cambia la decisión del 7-nov (los diales se quedan).
- **«¿Cómo está el ambiente?» solo sirve para identificar.** Con A1 sirve más. Si no basta, se quita o se le da una observación a cada entidad.

## 4. Recomendación de Claude

Si hubiera que elegir, este sería el orden:

1. **A1, A2, A3, A4, A5, A7 y A8**, en una sesión y casi todo con datos. Con esto el juego obliga a preguntar, la presión se junta en olas y arriesgar pasa a ser una decisión. Es lo que más cambia con menos trabajo.
2. **B1 con B2, B4 y C1**, en un plan. Con esto decidir cuesta pensar, las solicitudes escalan y el daño asusta.
3. **C2 (el impostor), junto con S21b.** Es la mecánica que puede volverse la firma del juego.
4. **D1 queda para después de la v1**, salvo que en la prueba con personas siga apareciendo que falta agencia.

**Calendario:** el contenido se congela el 25 de noviembre y la prueba con personas va del 23 al 29. Los puntos 1 y 2 alcanzan a entrar antes si se escriben y ejecutan esta semana y la siguiente. Todo lo de B y C suma textos que Benja tiene que corregir (reglas, reacciones y variantes), así que hay que dejarle tiempo antes del 25.

## 5. Lo que este escaneo no puede decir

- **Claude no jugó con las manos.** Los tiempos de atención (unos 25 s por solicitud) son estimaciones a partir del flujo; la prueba con personas es la que los confirma.
- **Claude no puede oír los sonidos.** Si los audios se distinguen de oído, solo lo puede decir Benja (`docs/04`, Q).
