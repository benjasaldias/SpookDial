# Instrucciones para hacer en Godot

Pasos que conviene que hagas tú en la interfaz de Godot (o en Windows). Hacerlos por código no sería igual de eficiente, o necesitan tu equipo y tu decisión.

- Uso los nombres en inglés de la interfaz. Si tu Godot está en español, el nombre aproximado va entre paréntesis.
- Cada bloque termina con cómo verificar que quedó bien.

## Estado

| Paso | Estado |
| --- | --- |
| Instalar y activar Aseprite Wizard (v9.8.0), con SpriteFrames como importador por defecto | ✅ Hecho por Benja (sesión 2) |
| Ruta de Aseprite | ✅ Corregida por Claude en la configuración del editor (26-10-2026) |
| Prueba de importación | ✅ Verificada por Claude: los 16 `.aseprite` importan bien, con sus animaciones |
| **A.** Volver al proyecto de OneDrive en el Project Manager | ⬜ Pendiente |
| **C.** Revisar la escena del escritorio (Plan 1) | ⬜ Pendiente (unos 5 minutos) |
| **D.** Probar el escalado a pantalla completa y decidir | ⬜ Pendiente |
| **E.** Cómo mover un objeto de la escena | Referencia |
| **F.** Revisar una entidad en el Inspector (Plan 2) | ⬜ Pendiente (unos 5 minutos) |
| **G.** Probar las solicitudes y el chat (Plan 3) | ⬜ Pendiente (unos 10 minutos) |
| **N.** Probar el dinamismo (Plan 9) | ✅ Benja lo probó el 8-nov y anotó las correcciones |
| **O.** Probar las correcciones del 8-nov | ⬜ Pendiente (unos 10 minutos) |
| **P.** Probar Snapgram | ⬜ Pendiente (unos 10 minutos) |
| **H.** Probar el cuaderno (Plan 4) | ⬜ Pendiente (unos 10 minutos) |
| **I.** Probar la noche (Plan 5) | ⬜ Pendiente (unos 15 minutos) |
| **J.** Probar el mantenimiento (Plan 6) | ⬜ Pendiente (unos 20 minutos) |
| **K.** Probar los screamers y el director (Plan 7) | ⬜ Pendiente (unos 20 minutos) |
| **L.** Probar las noches, el menú, el guardado y las opciones (Plan 8) | ⬜ Pendiente (unos 25 minutos) |

---

## Regla mientras Claude trabaja

Cuando Claude te pida **cerrar Godot**, ciérralo por completo, incluida la lista de proyectos. Si dos Godot (el tuyo y el que Claude ejecuta sin ventana) escriben la carpeta `.godot/` a la vez, se puede corromper la caché de importación.

---

## A. Volver al proyecto de OneDrive

El proyecto se queda en `C:\Users\benja\OneDrive\Documents\spook-dial`. La copia de `C:\dev\spook-dial` ya no existe.

1. Abre Godot. En el Project Manager, la entrada de `C:\dev\spook-dial` aparece como faltante: selecciónala y presiona **Remove** (Quitar), o usa **Remove Missing** (Quitar faltantes).
2. Si el proyecto de OneDrive no está en la lista:
   - presiona **Import** (Importar);
   - abre `C:\Users\benja\OneDrive\Documents\spook-dial\project.godot`;
   - confirma con **Import & Edit**.
3. En VS Code, trabaja en la carpeta de OneDrive (la de este chat).

**Verifica:**

- En **Project > Tools > Aseprite Wizard > Config…** aparece `C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe`.
- En **FileSystem**, al hacer doble clic en `art/sprites/entry_sprite.aseprite` se abre el panel **SpriteFrames** (abajo), con las animaciones `idle` y `warning`.

---

## B. Cada vez que agregues un archivo de arte

- **Objetos animados o clickeables:** sirve el importador por defecto (SpriteFrames).
- **Planos estáticos y piezas de interfaz** (por ejemplo `wall_sprite` o `screen_sprite`):
  1. Selecciona el archivo.
  2. Abre la pestaña **Import**.
  3. En *Import As*, elige **Aseprite Texture**.
  4. Presiona **Reimport**.

  También puede hacerlo Claude, con Godot cerrado.
- **Si un archivo no se importa** (en FileSystem aparece con un ícono de error): avísale a Claude. Godot no reintenta los archivos que fallaron una vez, y hay que forzarlo.

---

## C. Revisar la escena del escritorio (Plan 1)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto `spook-dial`. La primera vez, Godot crea algunos archivos `.uid` nuevos junto a los scripts: es normal, y van en el siguiente commit.
2. En el panel **FileSystem** (Sistema de archivos), abajo a la izquierda, haz doble clic en `scenes/desk/desk.tscn`. La escena se abre en el centro.
3. Presiona **F5** (Run Project, Ejecutar proyecto). Se abre la ventana del juego.
4. Prueba:
   - **Resaltado:** pasa el mouse sobre el cuaderno, el celular y el mixer. Cada uno muestra un contorno claro de 1 píxel; fuera de ellos, el contorno desaparece.
   - **Chat:** haz clic en la entrada de León en la pantalla del PC. La entrada se ilumina y a la izquierda aparece el panel con el título "León".
   - **Cerrar:** presiona `Esc`, haz clic derecho o haz clic en cualquier parte fuera del panel. El panel se cierra y la entrada vuelve a su color. Si el clic cae en la entrada de otro amigo, se abre directamente su chat.
   - **Cámara:** mueve el mouse de una esquina a otra. Toda la escena se corre hacia el lado contrario (al mirar a la derecha, la escena va a la izquierda), unos 30 px como máximo. Comprueba que alcanzas el cuaderno, el mixer y las tres entradas.
   - **Si la cámara no te convence:** selecciona el nodo `LookCamera` en el panel **Scene** y, en el **Inspector**, desmarca **Look Enabled** (la escena queda fija y sin zoom), o cambia **Look Zoom** (1,00 a 1,20) y **Follow Speed** (más alto, más rápido). Guarda con **Ctrl + S** y vuelve a probar con **F5**.
   - **Clics:** al hacer clic en el mixer o en el celular, se abre su vista ampliada (Plan 6). Al hacer clic en el cuaderno, se abre su panel (Plan 4).

**Verifica:** las cinco pruebas anteriores se cumplen. Si alguna falla, anota cuál y qué pasó.

---

## D. Probar el escalado a pantalla completa

El juego mide 1280×720. En un monitor de 1920×1080, Godot lo amplía ×1,5 con filtro Nearest (sin suavizado), y algunos píxeles del arte quedan de 1 px y otros de 2 px de ancho.

1. Ejecuta el juego con **F5**.
2. Maximiza la ventana con el botón de maximizar de Windows, o con **Win + ↑**.
3. Mira de cerca el teclado del PC y las marcas de los diales, y mueve el mouse para ver la cámara. Con el zoom de la cámara, los grosores desparejos también pueden aparecer sin maximizar, y titilar al moverse.

**Decide:** si los grosores desparejos se notan lo suficiente como para que valga la pena, se agrega en el futuro un shader de escalado suave (va a la lista posterior a la v1). Si no, se queda Nearest. Díselo a Claude.

---

## E. Cómo mover un objeto de la escena

Si algo quedó corrido un píxel, o quieres probar otra ubicación:

1. Abre `scenes/desk/desk.tscn` (doble clic en **FileSystem**).
2. En el panel **Scene** (Escena), arriba a la izquierda, selecciona el nodo. Por ejemplo, `DeskPlane > Phone`.
3. En el **Inspector**, a la derecha, abre **Transform** (Transformación) y cambia **Position** (Posición): `x` e `y` en píxeles, siempre en números enteros.
4. Guarda con **Ctrl + S**.

**Verifica:** el objeto se ve en su nuevo lugar en el editor y al ejecutar con **F5**. Anota la nueva posición en `art/positions.md` y avísale a Claude: la prueba `test_cada_objeto_en_su_posicion` revisa las posiciones y habrá que actualizarla.

---

## F. Revisar una entidad en el Inspector (Plan 2)

Cada entidad es un archivo `.tres` en `data/entities/`. Todo lo suyo (características, acciones, observaciones y reglas) vive dentro de ese archivo. Sus textos están en `data/text/*.csv`.

1. Abre Godot y el proyecto.
2. En el panel **FileSystem** (Sistema de archivos), abre `data` > `entities` y haz doble clic en `trauco.tres`.
3. En el **Inspector** (a la derecha) aparecen `Id`, `Name Key`, `Lore Key`, `Sketch`, `Place Keys`, `Traits`, `Actions`, `Observations` y `Rules`. Si dejas el mouse sobre un campo, aparece su explicación.
4. Despliega **Rules** y haz clic en el primer elemento (`RuleData`). Debe mostrar:
   - **Conditions**: `saw_first` → `friend`;
   - **Correct Action Id**: `stare`;
   - **Risky Action Id**: `follow_closely`;
   - **Text Key**: `RULE_TRAUCO_1`.
5. Despliega **Observations** > el primer elemento > **Values**: deben aparecer `friend` y `trauco`, cada uno con su clave de texto.
6. Abre `data/catalog.tres`: **Friends** debe tener 3 elementos y **Nights**, 5. Abre `data/nights/night_3.tres`: en **New Entities** está `trauco.tres`.
7. **No guardes cambios** en esta revisión. Si cambiaste algo sin querer, deshazlo con `Ctrl+Z`, o cierra la pestaña sin guardar.

**Verifica:** todos los campos se ven y se pueden editar. Si un campo aparece vacío o en rojo, avísale a Claude.

### Para más adelante: agregar una entidad

1. En **FileSystem**, haz clic derecho en `trauco.tres` > **Duplicate…** (Duplicar…) y ponle el nombre de la nueva entidad, por ejemplo `tue_tue.tres`. La copia trae sus partes por dentro, independientes del Trauco.
2. Cambia el `Id` y edita sus partes. En las reglas, las acciones se escriben con su id (`Correct Action Id`, `Risky Action Id`). Las condiciones se agregan en **Conditions** con *Add Key/Value Pair* (Agregar par clave/valor): a la izquierda el id de la observación y a la derecha el valor.
3. Abre la noche en que aparece (`data/nights/night_N.tres`) y arrastra el archivo a **New Entities**.
4. Agrega sus textos a los CSV. La frase clickeable de cada característica va entre asteriscos: `vio un *hombrecito*`.
5. Pídele a Claude que corra las pruebas: si algo quedó mal (una regla que nunca se aplica, un id que no existe, un texto que falta), el error lo dice en español.

---

## G. Probar las solicitudes y el chat (Plan 3)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Llega una solicitud:** a los 5 segundos, una entrada del PC parpadea y muestra los segundos que le quedan al amigo.
3. **Abre el chat:** haz clic en esa entrada. A la izquierda se abre el chat en la conversación de ese amigo:
   - arriba hay una pestaña por amigo, con su tiempo y un `•` si tiene mensajes sin leer;
   - el mensaje aparece escrito de a poco, después del nombre de quien escribe ("LEÓN:"), en su color;
   - **es corto** (cambio del 3 de noviembre): un saludo ("¡Mati, ayuda!!", "¿Estás ahí?"…) y el lugar. A veces trae una pista: una frase en ámbar y subrayada, que se puede clickear.
4. **Pregunta para identificar:** el amigo no describe nada hasta que le preguntas. Presiona **¿Qué ves?**, **¿Qué oyes?**, **¿Cómo está el ambiente?** o **¿Hay rastros?**: responde con lo de esa categoría, y las frases en ámbar y subrayadas se pueden clickear.
   - Las características reales se ponen verdes y la barra cuenta "Características marcadas: 1 de 2".
   - Los señuelos vibran y se ponen rojos.
   - Con las 2 marcadas, la barra dice "Matías piensa…" y a los 3 segundos aparece el nombre (El Trauco).
   - Al clickear el nombre, se abre el cuaderno en la página de El Trauco (se prueba en la sección H).
5. **Las preguntas cuestan:** cada botón resta 5 segundos. Con 5 segundos o menos, los botones se desactivan. Fíjate en cómo se siente: ¿hace falta pensar qué preguntar, o conviene preguntar las 4 de corrido (20 segundos)? ¿Alcanza el tiempo de la noche (90 segundos en la 1; en la 3, 75) para identificar, preguntar las observaciones y responder? Anota qué ajustarías.
6. **Sin respuesta:** si se acaba el tiempo, el amigo cuenta que decidió solo y su entrada deja de parpadear. Responder desde el cuaderno se prueba en la sección H.
7. **Estática:**
   - en el panel **Scene**, selecciona el nodo `RequestManager`;
   - en el **Inspector**, baja **Test Signal** a 40 (se tapa el 25 % de las palabras) o a 20 (el 45 %);
   - vuelve a probar con **F5**: algunas palabras aparecen como `▒▒▒`. Una frase tapada no se puede clickear: pregunta por su categoría para recuperarla.
8. **El panel tapa el escritorio:** con el chat abierto, pasa el mouse por donde están el mixer y el celular, detrás del panel. No deben resaltarse, y un clic no debe abrir el mixer. Cierra el chat (`Esc` o clic derecho) y vuelve a probar: ahora sí se resaltan.
9. **Al terminar, deja Test Signal en 100**, o cierra la escena sin guardar.

### Para ajustar la identificación por preguntas

- **Cuánto cuesta preguntar:** `data/balance.tres`, grupo **Identificación**, **Question Cost** (5 segundos).
- **Por noche** (`data/nights/night_N.tres`, grupo **Solicitudes**): cuánto tiempo tiene cada solicitud (**Base Decision Time**), cuántas hay (**Requests Total**), qué tan seguido el mensaje inicial trae una pista (**First Hint Chance**: 1 es siempre y 0, nunca) y cuántos señuelos hay (**Decoys Per Request**).
- **Los saludos** están en `data/text/messages.csv` (`FIRST_CALL_*`). Para agregar uno, agrega su fila al final y su clave en **Greeting Keys**, en `data/catalog.tres`. Si el texto lleva una coma, ponlo entre comillas: `"¡Mati, ayuda!!"`.
- Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara estos archivos con `docs/02`.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Noche que se juega:** **Night Number**, en el Inspector de `RequestManager`. Por ahora solo la noche 3 tiene una entidad. Cuando agregues El Tue Tué y La Calchona a la noche 1, cámbialo a 1.
- **Señuelos por noche:** `data/nights/night_N.tres` > **Decoys In First Message**.
- **Los señuelos:** `data/catalog.tres` > **Decoys**. Cada uno tiene `Id`, `Category`, `Text Key` y `Place Keys` (vacío: sirve en cualquier lugar; si no, las claves de sus lugares, como `PLACE_FOREST`). Su texto va en `data/text/messages.csv`, con la frase clickeable entre asteriscos.
- Después de cambiar datos, pídele a Claude que corra las pruebas: el validador avisa en español si falta algo, como un lugar sin suficientes señuelos.

---

## H. Probar el cuaderno (Plan 4)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Identifica y abre la página:** cuando una entrada del PC parpadee, haz clic en ella. En el chat, clickea las 2 características hasta que aparezca el nombre (El Trauco) y haz clic en él.
   - A la derecha se abre el cuaderno, del mismo tamaño que el chat, en la página de El Trauco. Arriba dice "Ayudando a" y el nombre del amigo.
   - La página tiene el folclore, las características y las observaciones (cada una con la pregunta que la trae, entre paréntesis), las reglas y las acciones. Se scrollea con la rueda del mouse.
   - En cada regla, la acción correcta va en verde y la de mayor riesgo, después de "Mayor riesgo:", en rojo.
3. **Responde:** en el chat, bajo las preguntas, dice "Acciones de El Trauco" y hay 4 botones. Aplica las reglas a lo que cuenta el amigo y haz clic en una acción.
   - Tu acción aparece en el chat, después de "MATÍAS:", y el amigo reacciona según si fue la correcta, la de mayor riesgo o una incorrecta.
   - La entrada del amigo deja de parpadear.
4. **Los paneles son independientes:**
   - con los dos abiertos, haz clic derecho sobre el cuaderno: se cierra solo el cuaderno;
   - haz clic en el cuaderno del escritorio (sobre la mesa, a la derecha): se vuelve a abrir, y el chat no cambia;
   - haz clic derecho sobre el chat: se cierra solo el chat, y el cuaderno sigue abierto;
   - con el cuaderno abierto, haz clic en otra entrada del PC: se abre el chat de ese amigo, y el cuaderno salta a su página. Si no tiene una, dice "Elige una entidad en el índice".
5. **Memoria por amigo:** abre la página de El Trauco para un amigo y cambia de pestaña en el chat: el cuaderno muestra la página de cada amigo. Cuando a un amigo le llega una solicitud nueva, su cuaderno vuelve al índice.
6. **Cerrar todo:** con los dos paneles abiertos, presiona `Esc`: se cierran los dos. Ábrelos de nuevo y haz clic en una parte vacía de la escena, como la pared sobre el PC: también se cierran los dos.
7. **El celular y el mixer:** con solo el cuaderno abierto, haz clic en el mixer. El cuaderno se cierra y se abre el mixer (Plan 6).
8. **El cuaderno tapa el escritorio:** con el cuaderno abierto, pasa el mouse por donde está el cuaderno del escritorio, detrás del panel. No debe resaltarse.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para más adelante

- **El arte del cuaderno:** la página (449×696, como `screen_sprite`), las pestañas del índice y los bocetos de las entidades (unos 96×96). Cuando estén, Claude los pone en `scenes/ui/notebook_theme.tres` y en el **Sketch** de cada entidad.

---

## I. Probar la noche (Plan 5)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**.
2. **Los medidores:**
   - el celular muestra la hora: empieza en 00:00 y avanza un minuto cada poco más de un segundo. La noche dura 7 minutos, hasta las 06:00;
   - arriba de la pantalla del PC dice "Videos: 0 de 3". A las 01:30, a las 03:00 y a las 04:30 llega un video, que hay que descargar en el chat (sección J);
   - en la pared, el dial del medio (Sanity, aguja roja) baja de a poco. El de abajo (Trust, aguja amarilla) baja cuando eliges mal. El de arriba (Connection, aguja verde) baja con la señal de los amigos (sección J);
   - cada entrada del PC muestra 3 marcas de vida.
3. **Una acción incorrecta:** cuando llegue una solicitud, ábrela, identifica a la entidad y elige una acción que no sea la correcta ni la de mayor riesgo (míralo en las reglas del cuaderno). El amigo cuenta cómo le fue:
   - si quedó herido, grita en el chat ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y debajo aparece un aviso rojo y centrado con la vida que le queda ("León recibió daño: 2/3"). Pierde una marca de vida en su entrada del PC, que se oscurece y dice "Aturdido" con los segundos que faltan. Durante 15 segundos no le llegan solicitudes;
   - el dial de Trust baja. Si pasas 20 segundos sin errores, empieza a subir de a poco.
4. **La acción de mayor riesgo:** en otra solicitud, elige la de mayor riesgo. Si el amigo sobrevive, manda un video extra, que hay que descargar en su chat; si quedó herido, lo manda cuando se recupera. Trust baja más que con una acción incorrecta.
5. **Sin respuesta:** deja que se acabe el tiempo de una solicitud. El amigo cuenta qué hizo y, en otro mensaje, cómo le fue. Trust baja más que si hubieras respondido.
6. **Perder:** sigue respondiendo mal al mismo amigo hasta que pierda sus 3 marcas. La pantalla se oscurece de a poco y dice "Perdiste la noche", que el amigo murió y por qué: la entidad, lo que observaba, la regla que se aplicaba, la acción correcta (en verde) y la que elegiste (en rojo). Haz clic en **Reintentar**: la noche empieza de nuevo, con otras solicitudes.
7. **La viñeta y Sanity:** para no esperar, acelera Sanity.
   - En el panel **FileSystem**, haz doble clic en `data/nights/night_3.tres`.
   - En el **Inspector**, dentro de **Sanity y cuota**, cambia **Sanity Drain Interval** de 6 a 1 y guarda con **Ctrl + S**.
   - Presiona **F5**. Hacia los 40 segundos, los bordes de la pantalla se oscurecen en bandas, cada vez más hacia el centro, también sobre el chat. A los 100 segundos, Sanity llega a 0 y se pierde la noche ("Matías entró en pánico").
   - **Al terminar, vuelve Sanity Drain Interval a 6** y guarda.
8. **Ganar:** juega una noche completa (7 minutos) sin que muera nadie. A las 06:00, si descargaste los 3 videos, aparece "Llegaste a las 06:00" con el botón **Jugar de nuevo**.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Los valores de equilibrio** están en `data/balance.tres`. Haz doble clic en él y cámbialos en el **Inspector**: la duración de la noche (**Night Seconds**), la vida y el aturdimiento (**Amigos**), la probabilidad de herir, el daño y lo que baja Trust en cada caso (**Consecuencias**), cómo se recupera Trust (**Trust**) y desde qué valor de Sanity aparece la viñeta (**Sanity**).
  - Para probar más rápido, baja **Night Seconds** a 120: la noche entera dura 2 minutos. Al terminar, vuélvelo a 420.
  - Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara el archivo con `docs/02`, y hay que actualizar los dos.
- **Por noche** (`data/nights/night_N.tres`): **Content Quota** (los videos de la cuota) y **Sanity Drain Interval** (los segundos por cada punto de Sanity).
- **La forma de la viñeta:** en `desk.tscn`, selecciona `Overlay/Vignette`. En el **Inspector**, en **Material** > **Shader Parameters**, cambia **Bands** (cuántos niveles de oscuridad hay) y **Max Darkness** (lo más oscuro, en los bordes).

---

## J. Probar el mantenimiento (Plan 6)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**. Se juega la noche 3: la señal baja y hay 3 interferencias.
2. **La señal:** cada entrada del PC tiene 5 barras de señal entre el nombre y las marcas de vida. Bajan de a poco, cada amigo a su ritmo, y el dial de arriba (Connection) baja con ellas: es el promedio de las tres.
3. **Una interferencia:** en algún momento, una entrada titila unos 3 segundos y suena estática. Después, a ese amigo le faltan unas 2 barras (40 de señal). Con la señal bajo 70, sus mensajes llegan con palabras tapadas (`▒▒▒`).
4. **Audio Sync:** haz clic en el mixer del escritorio. Se abre visto desde arriba, con el canal del amigo con menos señal elegido (con el borde de su color).
   - Haz clic en un fader o presiona la barra espaciadora. Suena la base: es la cuenta, de 4 golpes.
   - Después aplaude el amigo: se mueve la aguja del VU-metro de la derecha y se encienden luces azules.
   - Cuando dice "¡Repite el ritmo!", las luces se apagan: repite los aplausos con la barra espaciadora o con clics en el mixer. La aguja de la izquierda sigue tus golpes.
   - Si sale bien, dice que el amigo quedó sincronizado y su fader sube a 100. Si no, dice "Fuera de ritmo", y las luces muestran en verde lo que acertaste y en rojo lo que faltó: presiona la barra espaciadora para reintentar.
   - Cierra el mixer con clic derecho, con `Esc` o con un clic fuera.
   - **Desde el chat:** abre el chat de un amigo y haz clic en **Sincronizar**, a la derecha, sobre las preguntas. El chat se cierra, se abre el mixer en el canal de ese amigo y la ronda empieza enseguida.
5. **Sin señal:** para no esperar tanto, en el panel **Scene** selecciona el nodo `RequestManager` y, en el **Inspector**, cambia **Test Signal** de 100 a 15. Presiona **F5**. Los amigos empiezan con poca señal y se desconectan entre 45 y 90 segundos después:
   - su entrada se ve gris y dice "Sin señal", y en su chat aparece un aviso rojo: "… se quedó sin señal";
   - el dial de Trust baja mientras haya amigos sin señal, más rápido con más de uno;
   - si a un amigo sin señal le llega una solicitud, su mensaje llega tapado entero y no puedes preguntar ni responder: el chat pide sincronizarlo (usa **Sincronizar**). Si lo sincronizas antes de que se acabe su tiempo, aparece un aviso verde, "… volvió a conectarse", y ya puedes preguntar (las respuestas llegan legibles) y responder. Si se acaba el tiempo sin señal, el amigo elige mal;
   - si los tres se quedan sin señal, se pierde la noche ("Se perdió la conexión con los tres amigos").
   - **Al terminar, vuelve Test Signal a 100.**
6. **Los videos:** a las 01:30 (unos 105 segundos), un amigo avisa en su chat que mandó un video. Su entrada parpadea y dice "Video 15", y los segundos bajan.
   - Abre su chat: sobre la barra de identificación aparece la barra de descarga. Mantén presionado el clic sobre ella: se llena en 10 segundos (en 15 si la señal del amigo está bajo 50) y dice cuánto va. Si sueltas, se pausa. Desde que empiezas, tienes 20 segundos para terminar.
   - Al terminar, aparece un aviso verde ("Video de … recibido: 1 de 3"), y el PC dice "Videos: 1 de 3".
   - Prueba también perder uno: no lo empieces a descargar en 15 segundos. Aparece un aviso rojo ("Se perdió el video de …"). Sin los 3 videos, a las 06:00 se pierde la noche.
7. **El celular:** haz clic en el celular del escritorio. Se abre ampliado, con la hora arriba y publicaciones. Gira la rueda del mouse: el feed avanza y, mientras scrolleas, el dial de Sanity (el del medio) sube. Al dejar de scrollear, vuelve a bajar de a poco. Ciérralo con clic derecho, con `Esc` o con un clic fuera.
8. **Modos exclusivos:** con el mixer abierto, haz clic en el celular: el mixer se cierra. Con el celular abierto, haz clic en una entrada del PC: se abre el chat y el celular se cierra.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Los valores de equilibrio** están en `data/balance.tres`. Haz doble clic en él y cámbialos en el **Inspector**:
  - **Sanity:** cuánto sube por segundo al scrollear (**Scroll Sanity Per Second**) y cuánto dura cada movimiento de la rueda (**Scroll Grace**);
  - **Señal:** cuánto quita una interferencia (**Interference Damage**), con cuánta anticipación se anuncia (**Interference Warning**) y cada cuántos segundos baja Trust por cada amigo sin señal (**Offline Trust Interval**);
  - **Audio Sync:** el tempo de la base (**Audio Sync Bpm**) y cuánto puede adelantarse o atrasarse cada golpe (**Audio Sync Tolerance**, en segundos);
  - **Videos:** el tiempo para empezar (**Video Accept Seconds**) y para terminar (**Video Finish Seconds**) la descarga, cuánto tarda con buena señal (**Download Seconds**) y con señal débil (**Download Slow Seconds**), y desde qué señal es débil (**Download Slow Below**).
  - Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara el archivo con `docs/02`.
- **Por noche** (`data/nights/night_N.tres`, grupo **Señal**): si la señal baja (**Signal Decays**), cada cuántos segundos baja un punto (**Signal Decay Interval**: el mínimo en **x** y el máximo en **y**), cuántas interferencias hay (**Interference Count**) y cuántos aplausos tiene Audio Sync (**Audio Sync Beats**: 4 u 8, o 0 si esa noche no hay).
- **Los sonidos provisionales** están en `audio/sfx/`. Para probar otro, reemplaza el archivo por uno con el mismo nombre.
- **Las publicaciones del celular** están en `data/catalog.tres`, en **Phone Posts**, y sus textos, en `data/text/phone.csv`.

---

## K. Probar los screamers y el director (Plan 7)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**. Se juega la noche 3. Ahora suena de fondo el ambiente del cuarto (viento y un zumbido), y la figura de la ventana ya no está.
2. **El ritmo:** las solicitudes llegan en olas de 3. Dentro de una ola llegan con unos 20 a 35 segundos entre una y otra, y después de cada ola hay un respiro unos 25 segundos más largo, sin solicitudes nuevas. Hacia las 06:00 llegan más seguidas. Si un amigo queda herido, la siguiente se atrasa unos 10 segundos.
3. **Los screamers:** en la noche 3 hay 4, desde los 30 segundos, y uno de ellos es la criatura que se asoma por la ventana (ver la sección M).
   - Antes de cada uno, las luces parpadean y baja el sonido ambiente durante 1 segundo.
   - Con el escritorio a la vista (sin el chat, el mixer ni el celular abiertos), puede ser que la cortina se meza, que aparezca la figura en la ventana, que el celular vibre o que se apaguen las luces. Con el chat abierto, solo las luces. Con el cuaderno abierto, también puede cerrarse de golpe o mancharse de tinta durante 5 segundos.
   - Cada uno baja de golpe el dial de Sanity (el del medio): 8 puntos, y la criatura, 15.
   - La criatura no tapa la pantalla ni pausa la noche: se asoma por la ventana, con respiración y golpes en el vidrio, solo cuando el chat o el mixer están abiertos (sección M).
4. **Justicia:** ningún screamer empieza si a una solicitud le quedan 6 segundos o menos, ni durante una ronda de Audio Sync.
5. **Alucinaciones:** para no esperar a que baje Sanity, haz doble clic en `data/balance.tres` y, en el **Inspector**, en el grupo **Alucinaciones**, cambia **Hallucination Start** de 50 a 100 y **Hallucination Slowest** de 40 a 10. Presiona **F5**.
   - Cada unos 10 segundos suena algo a un lado de la pantalla: golpes en la ventana, pasos, susurros, rasguños, la estática de una interferencia o el celular vibrando. No pasa nada más: son falsos.
   - Durante una ronda de Audio Sync no suena ninguno.
   - **Al terminar, vuelve a dejar 50 y 40.** Si no, `test_balance.gd` falla.
6. **El susto guionado:** desde el Plan 8 está en la noche 0, la noche de práctica (sección L, paso 2).

**Verifica:** los pasos 1 a 6 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Los valores de equilibrio** están en `data/balance.tres`. Haz doble clic en él y cámbialos en el **Inspector**:
  - **Director:** cuándo llega la primera solicitud (**First Request Delay**), cuánto dura el respiro después de cada ola (**Wave Respite**), cuánto se aprietan hacia las 06:00 (**Wave Tightening**: 0,5 es la mitad), cuánto tiempo mínimo pasa entre dos (**Request Min Gap**) y cuánto las atrasa un amigo herido (**Hurt Respite**);
  - **Screamers:** cuánto dura la señal previa (**Scare Warning**), cuántos segundos le tienen que quedar a una decisión (**Scare Margin**), cuánto tiempo mínimo pasa entre dos (**Scare Min Gap**), desde cuándo hay (**First Scare After**), cuánto restan (**Scare Sanity** y **Jumpscare Sanity**) y cuánto duran la criatura de la ventana (**Creature Seconds**) y la tinta (**Ink Seconds**);
  - **Alucinaciones:** desde qué Sanity suenan (**Hallucination Start**) y cada cuánto, al empezar (**Hallucination Slowest**) y con Sanity en 0 (**Hallucination Fastest**).
  - Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara el archivo con `docs/02`.
- **Por noche** (`data/nights/night_N.tres`): cuántas solicitudes trae cada ola (**Wave Size**, en **Solicitudes**); cuántos screamers hay y si uno es la criatura de la ventana (**Scare Count** y **Has Jumpscare**, en **Screamers**); y el guion (en **Guion**): a qué segundo llega el susto guionado (**Scripted Scare Time**; 0 si no hay), qué screamer es (**Scripted Scare**) y su chat (**Scripted Chat**: el amigo, las líneas con quién habla y su texto, y si al final parpadea el celular).
- **Los textos del chat guionado** están en `data/text/messages.csv` (`SCRIPT_SCARE_*`).
- **Los sonidos provisionales** están en `audio/sfx/`. Para probar otro, reemplaza el archivo por uno con el mismo nombre.

---

## L. Probar las noches, el menú, el guardado y las opciones (Plan 8)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto, y presiona **F5**. Ahora el juego empieza en el **menú principal**: "SPOOK DIAL", **Nueva partida**, **Opciones** y **Salir**. La primera vez no está **Continuar**, porque no hay una partida guardada.
2. **La noche 0, la noche de práctica:** presiona **Nueva partida**. Arriba, entre el chat y los diales, un aviso dice qué hacer en cada paso. En esta noche el tiempo para responder no corre solo (solo lo gastan las preguntas) y nadie sale herido. Síguelo:
   - León te escribe: abre su chat con su entrada del PC, pregunta, marca las 2 características, haz clic en el nombre de la criatura y responde con la acción de la primera regla que se cumple.
   - Agustín: lo mismo. Al terminar te manda un video: abre su chat y mantén presionada la barra hasta que se descargue. La siguiente solicitud espera el video.
   - Gonzalo: su mensaje no trae pista. Prueba a responder con una acción equivocada: el aviso dice que, en una noche de verdad, habría salido herido.
   - Unos segundos después, con la ventana a la vista, la criatura se asoma por la ventana, con respiración y golpes en el vidrio, y Gonzalo te escribe. Respóndele con el botón. Después, el borde del celular parpadea: ábrelo, scrollea con la rueda y ciérralo con clic derecho. Ahí termina la práctica.
3. **El final de la práctica:** la pantalla dice "Práctica terminada". Presiona **Empezar la noche 1**.
4. **La noche 1 y el resumen:** aparecen El Tue Tué y La Calchona. Si pierdes, **Reintentar** vuelve a empezar la noche. Si llegas a las 06:00 con la cuota, el resumen dice cuántos videos conseguiste y qué páginas suma el cuaderno la noche siguiente (después de la noche 1: El Cuero y La Viuda), con **Empezar la noche 2** y **Volver al menú**.
5. **La pausa y el guardado:** en una noche, sin ningún panel abierto, presiona **Esc**: la noche se detiene y aparece el menú de pausa (**Continuar**, **Opciones** y **Volver al menú**). Con un panel abierto, **Esc** solo cierra los paneles, como antes. Presiona **Volver al menú**: ahora el menú tiene **Continuar: noche 1**, que empieza la noche desde su comienzo. Cierra el juego, presiona **F5** otra vez: **Continuar** sigue ahí.
6. **Nueva partida con una partida guardada:** el menú pregunta si quieres borrarla. **Cancelar** no hace nada.
7. **Las opciones** (desde el menú o desde la pausa):
   - los 3 volúmenes (general, ambiente y efectos) cambian el sonido al tiro;
   - **Reducir destellos:** las entradas en alerta quedan fijas en lugar de parpadear, el aviso de una interferencia atenúa la entrada sin titilar, el LED del mixer no parpadea, y la señal previa de un screamer y el apagón de las luces se oscurecen una sola vez;
   - **Cámara fija:** la escena deja de moverse con el mouse;
   - **Temporizadores ×1,5:** las solicitudes nuevas dan 1,5 veces más tiempo para responder (los plazos de los videos no cambian).
   - Cierra y vuelve a abrir el juego: las opciones se mantienen.
8. **Saltar la práctica:** con **Nueva partida**, el botón **Saltar tutorial** del aviso pasa directo a la noche 1.

**Verifica:** los pasos 1 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

**Para probar una noche sin pasar por las anteriores:** abre `scenes/desk/desk.tscn`, selecciona el nodo `RequestManager` en el panel **Scene** y cambia **Night Number** (de 0 a 5) en el **Inspector**. Presiona **F6**, que ejecuta solo la escena abierta, sin el menú: así no se guarda nada. Al terminar, vuelve a dejar 3.

### Para ajustar

- **La noche 0** está en `data/nights/night_0.tres`. En el grupo **Tutorial**, **Tutorial Requests** tiene las 3 solicitudes fijas, en orden: quién la pide (**Friend**), qué entidad es (**Entity**), qué observa el amigo (**Situation**: el id de cada observación y su valor; lo que falte sale al azar), si el mensaje inicial trae una pista (**With Hint**) y si al terminar el amigo manda un video (**Sends Video**). El susto y su chat están en el grupo **Guion**, como antes: en la noche 0, el susto llega cuando ya no queda nada pendiente.
- **Los textos nuevos** están en `data/text/ui.csv`: el aviso de la práctica (`TUTORIAL_*`), el menú (`MENU_*`), la pausa (`PAUSE_*`), las opciones (`OPTIONS_*`) y el final y el resumen (`END_*`).
- **Las 7 entidades** están en `data/entities/`, un `.tres` cada una, y sus textos en `data/text/messages.csv` y `data/text/notebook.csv`. Son un borrador de Claude: corrígelas en el **Inspector** (como en la sección F) y en los CSV. Las pruebas avisan si algo no cumple la plantilla.
- **La partida y las opciones** se guardan en `%APPDATA%\Godot\app_userdata\Spook Dial\` (`save.cfg` y `settings.cfg`). Para empezar de cero, borra `save.cfg`.

---

## M. Probar el feedback de la primera prueba (Plan 8.1)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. **Los diales:** con **Nueva partida**, lo primero que dice el aviso de la noche 0 son los 3 diales, con un botón **Entendido**. Presiónalo: sigue el aviso de siempre.
2. **La criatura en la ventana:** en la noche 2 o más, deja el chat de un amigo abierto cuando llegue el susto (se nota por la señal previa: las luces parpadean y baja el ambiente). Se oyen una respiración y golpes en el vidrio, pero no se ve nada. Cierra el chat: la criatura ya está en la ventana. No tapa la pantalla. (Desde el Plan 9 se queda 25 s: ver la sección N.)
3. **Las noches 1 y 2:** la noche 1 ahora tiene señal que baja, 1 interferencia, Audio Sync de 4 aplausos y 2 screamers (sin la criatura). ¿Pasa más? ¿Es muy difícil? Anota qué sientes.
4. **Audio Sync en 2 rondas:** en la noche 4 o 5, el mixer dice "Ronda 1 de 2". Si aciertas, pasa sola a la 2. Si fallas la 2, dice que vuelves a la ronda 1.
5. **Trust:** deja una solicitud sin responder más de 30 s y mira el dial amarillo: baja de a poco. Responde y deja de bajar.

**Verifica:** los pasos 1 a 5 se cumplen. Si algo falla, o los valores se sienten mal, anótalo: están en `data/balance.tres` (Trust y la criatura) y en `data/nights/night_N.tres`.

### Para ajustar

- **Trust por tardar:** `data/balance.tres`, `Slow Answer Grace` (30 s) y `Slow Answer Trust` (0,25 por segundo).
- **Cuánto se queda la criatura:** `Creature Seconds` (25 s desde el Plan 9).
- **Las noches 1 y 2:** `data/nights/night_1.tres` y `night_2.tres`, en el Inspector.
- **Los sonidos de la criatura:** `sonidos_pendiente.md`.

## N. Probar el dinamismo (Plan 9)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez. Con **Nueva partida** o **Continuar**, según la noche que quieras ver.

1. **Las barras:** arriba, en el centro, están Connection, Sanity y Trust. Abre el chat y el cuaderno a la vez: se siguen viendo. Equivócate en una respuesta: Trust titila.
2. **Los audios:** en una solicitud, presiona **¿Qué oyes?**. El amigo manda **▶ Escuchar audio**: haz clic para oírlo, las veces que quieras. Abre la página de la entidad: lo que se oye cambia la regla que se aplica.
3. **Audio Sync:** en la noche 1 la base es lenta, y en la noche 5, bastante más rápida. En la noche 4 o 5, la ronda 2 va más rápida que la 1.
4. **La batería:** scrollea el celular: el porcentaje baja, y también la barrita verde del celular del escritorio. Con 0 %, dice "Sin batería" y Sanity ya no sube.
5. **Las cortinas:** haz clic en ellas: se cierran, el cuarto se oscurece y Sanity baja un poco más rápido. Otro clic las abre.
6. **La criatura:** desde la noche 2, con el chat abierto se oyen golpes. Ciérralo: la criatura está en la ventana y Sanity baja rápido. Cierra la cortina: deja de oírse. Ábrela: si sigue ahí, se ve y se oye; se va a los 25 s de llegar.
7. **La cortina sola:** a veces un screamer abre o cierra la cortina.
8. **Los accidentes:** un amigo escribe que se tropezó o se cortó. En su chat aparecen opciones, sin cuaderno, y tienes 15 s. Elige la mala a propósito: pierde 1 de vida y queda aturdido, pero Trust no baja.
9. **La noche 0:** el aviso ya no va pegado arriba, sino bajo las barras, y al final enseña las cortinas.

**Verifica:** los pasos 1 a 9 se cumplen. Si algo falla o se siente mal, anótalo.

### Para ajustar

- **Tiempo, pista, señuelos, accidentes y visitas de la criatura:** `data/nights/night_N.tres`, en el Inspector (`Base Decision Time`, `First Hint Chance`, `Decoys Per Request`, `Incident Count` y `Creature Visits`).
- **Audio Sync:** `Audio Sync Bpm` en cada noche, y `Audio Sync Round Speedup` en `data/balance.tres`.
- **La batería:** `Phone Battery Seconds` en `data/balance.tres` (38 s).
- **Las cortinas y la criatura:** `Closed Curtains Sanity` (0,3), `Creature Sanity` (2) y `Creature Seconds` (25).
- **Los accidentes:** `Incident Seconds` (15) e `Incident Damage` (1); sus textos, en `messages.csv` (`INCIDENT_*`).
- **Las reglas y los audios de cada entidad:** `data/entities/`, en el Inspector.

Si cambias un valor de `data/balance.tres` o de una noche a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.

## O. Probar las correcciones del 8 de noviembre

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. **Las voces:** empieza una noche y abre el chat de León cuando escriba. Se oye un sonido corto mientras aparecen las letras. Haz lo mismo con Gonzalo (más grave y pausado) y con Agustín (más agudo y rápido).
2. **Dónde no suenan:** con el chat cerrado no se oye nada. Con la pestaña de otro amigo abierta, tampoco. Tus mensajes (MATÍAS) no suenan. Si haces clic en **▶ Escuchar audio** mientras el amigo escribe, solo se oye el audio.
3. **La sombra:** en la noche 2 o más, cuando la criatura se asome, cae una franja de sombra sobre el escritorio, bajo la ventana. Cierra la cortina: desaparece. Ábrela: si la criatura sigue ahí, vuelve. Cuando se va, desaparece.
4. **Audio Sync:** en la noche 4 o 5, la fila de luces del mixer tiene 8, no 16, y a su lado dice RONDAS con 2 luces. La de la ronda en curso se pone azul, y al pasarla, verde. Si fallas la segunda, se apagan las 2. En las noches 1 a 3, esas luces no están.

**Verifica:** los pasos 1 a 4 se cumplen. Di si las voces cansan o si se confunden con la tensión de la noche.

### Para ajustar las voces

1. En el panel **FileSystem** de Godot (abajo a la izquierda), abre `data/friends/` y haz doble clic en `leon.tres`, `gonzalo.tres` o `agustin.tres`.
2. En el panel **Inspector** (a la derecha), abre el grupo **Voice**.
3. Cambia `Voice Pitch` (1 es normal, 1,2 es más agudo y 0,8 más grave), `Voice Spread` (0,05 es parejo y 0,15 es muy variado) o `Voice Every` (2 habla rápido y 4 pausado).
4. Guarda con `Ctrl+S` y prueba con **F5**.

Para el volumen de todas las voces: abre `scenes/ui/chat_panel.tscn`, selecciona el nodo `Voice` en el panel **Scene** y cambia `Volume Db` en el Inspector (hoy −8; −14 es bastante más bajo).

## P. Probar Snapgram

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre el proyecto y presiona **F5**. En el menú, entra a una noche.
2. **El feed:** haz clic en el celular del escritorio. Arriba dice "Snapgram". Se ve una foto de gatitos completa, con barras grises en vez de nombres y textos, y más abajo el comienzo de la siguiente publicación. Abajo está la barra con 5 íconos.
3. **El scroll:** mueve la rueda del mouse. El feed avanza y Sanity sube, como antes. Los botones no hacen nada, a propósito.
4. **Sin batería:** sigue scrolleando hasta que se acabe (unos 38 s). La pantalla queda negra, con la hora y "Sin batería".
5. **Clic derecho** cierra el celular.

### Para ver las fotos perturbadoras sin esperar

Sin este truco, aparecen solo con Sanity bajo 30. Es un cambio temporal:

1. En el panel **FileSystem** de Godot (abajo a la izquierda), abre `data/` y haz doble clic en `balance.tres`.
2. En el panel **Inspector** (a la derecha), abre el grupo **Sanity**.
3. Cambia `Disturbing Post Sanity` a `100` y `Disturbing Post Every` a `2`. Guarda con `Ctrl+S`.
4. Presiona **F5** y scrollea en el celular: 1 de cada 2 publicaciones es perturbadora. Una foto a la vista no cambia nunca.
5. **Déjalo como estaba:** `Disturbing Post Sanity` en `30` y `Disturbing Post Every` en `6`. Guarda con `Ctrl+S`.

**Verifica:** los pasos anteriores se cumplen, y en `balance.tres` volvieron los valores 30 y 6. Después juega una noche hasta tener poca Sanity y di si las fotos perturbadoras se alcanzan a ver bajo la viñeta, porque la viñeta también oscurece el celular. Claude puede dejar el celular por encima de ella.

### Para cambiar una foto

Exporta un PNG de exactamente **232×232** con el mismo nombre en `art/phone/` (`post_01.png` a `post_12.png` y `disturbing_1.png` a `disturbing_4.png`). Godot lo reimporta al abrir el proyecto. Si la imagen tiene otro tamaño, déjala en `art/phone/source/` y pídele a Claude que la recorte: usa `tools/crop_phone_photos.sh`.

### Para ajustar cuándo aparecen

En `data/balance.tres`, grupo **Sanity**: `Disturbing Post Sanity` y `Disturbing Post Every` (hoy, bajo 30, una de cada 6), y `Disturbing Post Worse Sanity` y `Disturbing Post Worse Every` (hoy, bajo 15, una de cada 3).
