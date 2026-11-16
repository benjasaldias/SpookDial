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
| **Q.** Escuchar los sonidos nuevos y revisar el arte de Claude | ⬜ Pendiente (unos 20 minutos) |
| **R.** Probar los ajustes de mecánicas y la Mano (Plan 9.1) | ⬜ Pendiente (unos 15 minutos) |
| **S.** Probar la letra en pantalla completa, el cuaderno y la noche 0 con León (Plan 9.2) | ⬜ Pendiente (unos 15 minutos) |
| **T.** Probar el chat nuevo, la descarga y el guardado (Plan 9.3) | ⬜ Pendiente (unos 15 minutos) |
| **U.** Probar Normal y Difícil (Plan 9.4) | ⬜ Pendiente (unos 20 minutos) |
| **V.** Probar la noche 0 nueva y los pedidos del 12 de noviembre (Plan 9.5) | ⬜ Pendiente (unos 20 minutos) |
| **W.** Probar Extremo (Plan 9.6) | ⬜ Pendiente (unos 30 minutos, o más si quieres ganarlo) |
| **X.** Probar la historia de la noche 1 (planes 9.7 y 9.8) | ⬜ Pendiente (unos 25 minutos: la noche 1 en Normal y, si alcanzas, en Difícil) |
| **Y.** Poner la música de la noche (Plan 9.8) | ⬜ Pendiente: cuando tengas las 2 pistas |
| **AA.** Probar la noche que termina cuando se acaba, y la nota (Plan 9.9) | ⬜ Pendiente (unos 25 minutos) |
| **AB.** Probar la llamada que no se roba el chat, la lectura más rápida y los sonidos de respuesta (S21p) | ⬜ Pendiente (unos 10 minutos) |
| Importar `hand_sprite` con Aseprite Wizard | ✅ Hecho por Claude (11-11-2026): animación `default`, 3 cuadros de 319×81 |
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
   - arriba de la pantalla del PC dice "Videos: 0 de 3". Los videos llegan en las calmas entre las olas, y hay que descargarlos en el chat (sección J). Desde el Plan 9.1, el primer minuto es de silencio (sección R);
   - en la pared, el dial del medio (Sanity, aguja roja) baja de a poco. El de abajo (Trust, aguja amarilla) baja cuando eliges mal. El de arriba (Connection, aguja verde) baja con la señal de los amigos (sección J);
   - cada entrada del PC muestra 3 marcas de vida.
3. **Una acción incorrecta:** cuando llegue una solicitud, ábrela, identifica a la entidad y elige una acción que no sea la correcta ni la de mayor riesgo (míralo en las reglas del cuaderno). El amigo cuenta cómo le fue:
   - si quedó herido, grita en el chat ("¡ME ATACÓ! CONCÉNTRATE, MATI.") y debajo aparece un aviso rojo y centrado con la vida que le queda ("León recibió daño: 2/3"). Pierde una marca de vida en su entrada del PC, que se oscurece y dice "Aturdido" con los segundos que faltan. Durante 15 segundos no le llegan solicitudes;
   - el dial de Trust baja, y desde el 11 de noviembre **no se recupera en toda la noche** (sección R).
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
2. **La noche 0, la noche de práctica:** desde el 11 de noviembre la enseña León en su chat. Los pasos están en la sección S.
3. **El final de la práctica:** después de las tarjetas con videos, **Empezar la noche 1**.
4. **La noche 1 y el resumen:** aparecen El Tue Tué y La Calchona. Si pierdes, **Reintentar** vuelve a empezar la noche. Si llegas a las 06:00 con la cuota, el resumen dice cuántos videos conseguiste y qué páginas suma el cuaderno la noche siguiente (después de la noche 1: El Cuero y La Viuda), con **Empezar la noche 2** y **Volver al menú**.
5. **La pausa y el guardado:** en una noche, sin ningún panel abierto, presiona **Esc**: la noche se detiene y aparece el menú de pausa (**Continuar**, **Opciones** y **Volver al menú**). Con un panel abierto, **Esc** solo cierra los paneles, como antes. Presiona **Volver al menú**: ahora el menú tiene **Continuar: noche 1**, que empieza la noche desde su comienzo. Cierra el juego, presiona **F5** otra vez: **Continuar** sigue ahí.
6. **Nueva partida con una partida guardada:** el menú pregunta si quieres borrarla. **Cancelar** no hace nada.
7. **Las opciones** (desde el menú o desde la pausa):
   - los 3 volúmenes (general, ambiente y efectos) cambian el sonido al tiro;
   - **Reducir destellos:** las entradas en alerta quedan fijas en lugar de parpadear, el aviso de una interferencia atenúa la entrada sin titilar, el LED del mixer no parpadea, y la señal previa de un screamer y el apagón de las luces se oscurecen una sola vez;
   - **Cámara fija:** la escena deja de moverse con el mouse;
   - **Temporizadores ×1,5:** las solicitudes nuevas dan 1,5 veces más tiempo para responder (los plazos de los videos no cambian).
   - Cierra y vuelve a abrir el juego: las opciones se mantienen.
8. **Saltar la práctica:** en la noche 0, **Esc** y **Saltar tutorial** pasan directo a la noche 1.

**Verifica:** los pasos 1 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

**Para probar una noche sin pasar por las anteriores:** abre `scenes/desk/desk.tscn`, selecciona el nodo `RequestManager` en el panel **Scene** y cambia **Night Number** (de 0 a 5) en el **Inspector**. Presiona **F6**, que ejecuta solo la escena abierta, sin el menú: así no se guarda nada. Al terminar, vuelve a dejar 3.

### Para ajustar

- **La noche 0** está en `data/nights/night_0.tres`. En el grupo **Tutorial**, **Tutorial Requests** tiene la solicitud de León (Gonzalo enojado y con hambre, con su señuelo), y **Tutorial Cards**, las 4 tarjetas, cada una con su video. La página de Gonzalo está en `data/tutorial/gonzalo.tres`.
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

## Q. Escuchar los sonidos nuevos y revisar el arte de Claude

Del 10 de noviembre (sesión S21d). Claude no puede escuchar: revisó cada sonido con su espectrograma y su sonoridad, pero **lo que importa es cómo suenan**. Usa audífonos.

### Los audios de los amigos (lo más importante)

1. En el Explorador de Windows, abre `C:\Users\benja\OneDrive\Documents\spook-dial\audio\clues\`.
2. Haz doble clic en cada archivo para escucharlo. Escucha **los de una misma entidad uno tras otro**: tienen que distinguirse sin mirar el nombre.
3. **Verifica:**
   - el Tue Tué grita 1 vez, 3 veces o ninguna, y no hay duda de cuántas;
   - el balido de La Calchona suena a llanto y el bufido, a enojo;
   - el silbido del Cuero se oye sobre el agua;
   - los tacos de La Viuda son claramente lentos o rápidos;
   - el barro del Trauco chapotea y la tierra seca cruje;
   - el gallo del Basilisco canta 1 o 2 veces, y no se confunde con 4;
   - el llanto de guagua del Imbunche se oye entre los gruñidos.

### Los demás sonidos

1. Abre `audio\sfx\` y escucha cada uno. La lista de cómo debería sonar está en `sonidos_pendiente.md`.
2. Después, en el juego (**F5**):
   - juega una noche con Audio Sync: el bombo, el platillo, el aplauso del amigo y tu golpe se tienen que distinguir;
   - escucha las voces de los amigos mientras escriben (ahora murmuran);
   - fíjate si el ambiente se nota cuando se repite (dura 24 s).
3. **Verifica:** nada suena demasiado fuerte o demasiado bajo comparado con lo demás. Anota cuáles cambiarías y cómo, y díselo a Claude: ajusta la receta en `tools/make_sounds.py`.

### El arte

En el juego (**F5**), mira:

- **el mixer:** abre Audio Sync;
- **el cuaderno:** ábrelo en una página;
- **la mancha de tinta:** si no sale sola, la muestra `test/capture_screamers.gd`; la captura está en `C:\dev\capturas\arte_ink.png`;
- **el celular** y **las barras de arriba**;
- **las barras de señal** del PC;
- **el menú, la pausa (`Esc`) y el resumen** al terminar una noche.

Las capturas de Claude están en `C:\dev\capturas\arte_*.png`.

**Verifica:** el estilo combina con tu arte y el cuaderno se lee rápido. Si quieres redibujar una pieza, la lista con los tamaños está en `arte_pendiente.md`.

---

## R. Probar los ajustes de mecánicas y la Mano (Plan 9.1)

Del 11 de noviembre (sesión S21f). Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez. Son unos 20 minutos.

### La noche 0

Desde el Plan 9.2, la noche 0 ya no enseña la Mano con el celular: la enseña una tarjeta con video al final (sección S).

### Una noche normal (unos 15 minutos)

1. En el panel **FileSystem**, abre `scenes/desk/desk.tscn`. En el panel **Scene**, selecciona **RequestManager** y, en el **Inspector**, deja **Night Number** en 3. Presiona **F6** (correr la escena actual).
2. **El primer minuto es de silencio.** A las 01:00 del celular (unos 60 s), llegan 2 solicitudes juntas, con pocos segundos de diferencia.
3. **El mensaje inicial:** el amigo saluda y cuenta qué le pasa ("Me perdí.", "Algo me viene siguiendo."). A veces dice dónde está y a veces no.
4. **Las características con otras palabras:** pregunta. Las frases destacadas no siempre son las del cuaderno: por ejemplo, "un enano" en vez de "hombrecito". Márcalas igual. Abre la página de la entidad: el cuaderno muestra el nombre de siempre.
5. **Un señuelo:** haz clic en una frase destacada que no sea una característica. Vibra en rojo, dice "−1 s" al lado y el tiempo de la pestaña baja 1. La segunda vez que la clickeas ya no cuesta.
6. **La calma:** cuando respondas las 2 solicitudes, no llega otra por al menos 40 s. En la calma llega un video, y a veces un screamer.
7. **La Mano:** llega en una ola, mientras respondes. Escucha el crujido. Abre el celular y espántala con el rayo. Si la dejas, agarra un dial y lo baja hasta 15: mira las barras de arriba.
8. **Un video perdido:** deja pasar un video sin descargarlo. El chat dice que se perdió y, en rojo, que ya no alcanzan los videos y alguien tiene que arriesgarse. Arriba del PC dice "Videos: 0 de 3 (faltan)" en rojo, y Trust baja 10.
9. **Trust no sube:** después de un error, espera un rato sin errores. Trust se queda donde estaba.
10. **La criatura:** cuando llegue, cierra las cortinas y ábrelas cada tanto. Cada vez se queda un rato distinto (entre 15 y 40 s).
11. **La ola final:** hacia las 04:30 o 05:00 del celular, los 3 amigos piden ayuda a la vez, y llega la criatura.

**Verifica:** los pasos 2 a 11 se cumplen. Anota cómo se sienten las olas y las calmas, si la Mano asusta y si guardar batería es una decisión.

### La curva de olas

Claude dibujó cómo se reparte una noche, con un jugador que juega bien: `C:\dev\capturas\plan91_olas_3.png` y `plan91_olas_5.png`. En rojo, las olas (la final, más fuerte); arriba, cada solicitud, accidente, Mano y video; abajo, cuántas cosas hay abiertas a la vez.

### Los textos nuevos para corregir (antes del 25 de noviembre)

- `data/text/messages.csv`: `PREDICAMENT_1` a `PREDICAMENT_8` (lo que le pasa al amigo) y las variantes de las 18 características (`TRAIT_*_2` a `TRAIT_*_4`).
- `data/text/notebook.csv`: los nombres de las características en el cuaderno (`TRAIT_*_LABEL`).
- `data/text/ui.csv`: `CHAT_DECOY_COST`, `CHAT_VIDEOS_SHORT`, `PC_VIDEOS_SHORT`, `TUTORIAL_HAND`, `TUTORIAL_HAND_DONE`, y los cambios en `TUTORIAL_DIALS`, `TUTORIAL_MARK`, `TUTORIAL_SCROLL` y `TUTORIAL_OPEN_CURTAINS`.
- `data/text/phone.csv`: `PHONE_FLASH` (lo que dice el rayo al pasar el mouse).

### Para ajustar

Todos los valores están en el **Inspector**:

- `data/balance.tres`:
  - grupo **Director**: el silencio, las olas y las calmas;
  - grupo **La Mano**: el costo del flash, cuánto tarda, a qué velocidad baja el dial y hasta dónde;
  - `Decoy Cost`, `Creature Stay`, `Phone Battery Seconds` y `Lost Video Trust`.
- `data/nights/night_N.tres`: `Place Chance`, `Finale Size`, `Hand Visits` y `Requests Total`.

Si cambias algo, avísale a Claude: `test_balance.gd` comprueba que todas las noches se sigan pudiendo ganar.

---

## S. Probar la letra, el cuaderno y la noche 0 con León (Plan 9.2)

Del 11 de noviembre (sesión S21f, continuación). Avísale a Claude antes de abrir Godot. Son unos 15 minutos.

### La letra en pantalla completa

1. Abre Godot y el proyecto, y presiona **F5**. Agranda la ventana del juego como lo hiciste cuando viste la letra fea: maximizada o en pantalla completa. El juego no tiene todavía una opción de pantalla completa.
2. **Verifica:** el texto del menú, del chat y del cuaderno se ve nítido, sin trazos más gruesos que otros, y un poco más grande que en la ventana chica. Si tu monitor no es de 1920×1080, dime cuál es: en algunas resoluciones (como 1600×900) la letra nítida queda un poco más chica.

### El cuaderno

1. Juega la noche 1 (o abre `scenes/desk/desk.tscn` con **Night Number** en 1 y presiona **F6**) y abre una página del cuaderno.
2. **Verifica:**
   - las características van sin las preguntas entre paréntesis, y no hay lista de observaciones;
   - las reglas son una tabla, **Condición | 1 | 2 | 3 | 4**: ✓ verde la correcta, calavera roja la de mayor riesgo, ✗ las otras, con la leyenda de la calavera abajo;
   - las acciones van numeradas como las columnas;
   - la cuadrícula se ve más suave.

### La noche 0 con León

1. En el menú, **Nueva partida**. No hay aviso arriba: León te escribe, y su entrada del PC parpadea.
2. Sigue lo que dice León:
   - pregúntale qué ve y marca lo que sirve (prueba a marcar el polerón rojo: León bromea; desde el Plan 9.3 ya no cuesta tiempo);
   - pregúntale por el ambiente y marca la que falta. Cuando aparece **Gonzalo**, haz clic en su nombre: el cuaderno tiene solo su página;
   - elige una acción que no sea la del ✓: León te dice que lo intentes de nuevo. Después, la del ✓, y luego la de la calavera;
   - descarga el video que te manda;
   - se le corta la señal: aprieta el botón de las barritas en su chat (desde el Plan 9.3 ya no dice "Sincronizar") y copia sus aplausos.
3. León se despide. Salen 4 tarjetas con videos: los medidores, el celular, la ventana y la Mano. **Siguiente** pasa de una a otra, y la última, **Empezar la noche 1**.
4. **Saltar:** vuelve a **Nueva partida**, presiona **Esc** y elige **Saltar tutorial**: pasa a la noche 1.

**Verifica:** León suena natural, los chistes funcionan y las tarjetas se entienden sin leer de más. Dime qué líneas cambiarías.

### Los textos nuevos para corregir (antes del 25 de noviembre)

- `data/text/ui.csv`: lo que dice León (`TUTORIAL_LEON_*`), las tarjetas (`TUTORIAL_CARD_*` y `TUTORIAL_CARDS_*`), `PAUSE_SKIP_TUTORIAL`, y los cambios en `IDENTIFY_PROGRESS` y `MIXER_HINT`, que se acortaron para caber con la letra más grande.
- `data/text/messages.csv`: lo que cuenta León de Gonzalo (`TUTORIAL_TRAIT_*`, `TUTORIAL_DECOY_HOODIE` y `TUTORIAL_OBS_*`).
- `data/text/notebook.csv`: la página de Gonzalo (`TUTORIAL_PAGE_*`, `TUTORIAL_TRAIT_*_LABEL`, `TUTORIAL_ACTION_*` y `TUTORIAL_RULE_*`), `NOTEBOOK_RULES`, `NOTEBOOK_CONDITION` y `NOTEBOOK_RISK_LEGEND`.

### Si cambias el arte

Los videos de las tarjetas son grabaciones del juego. Si cambias algo que se ve en ellos (las barras, los diales, la ventana, el celular o la Mano), avísale a Claude: los vuelve a grabar con `tools/make_tutorial_videos.sh`.

---

## T. Probar el chat nuevo, la descarga y el guardado (Plan 9.3)

Del 11 de noviembre (sesión S21h), con el feedback del primer testeo. Avísale a Claude antes de abrir Godot. Son unos 15 minutos. Para las pruebas con una señal fija se usa el escritorio suelto:

1. En el panel **FileSystem** (abajo a la izquierda), haz doble clic en `scenes/desk/desk.tscn`.
2. En el panel **Scene** (arriba a la izquierda), haz clic en el nodo **RequestManager**.
3. En el **Inspector** (a la derecha) quedan **Night Number** (la noche que se juega) y **Test Signal** (la señal con que empiezan los 3 amigos).
4. Para jugar el escritorio, presiona **F6**. Al terminar, vuelve a dejar **Test Signal** en **100** y no guardes la escena.

### El chat en bloques

1. Con **Night Number** en **1**, presiona **F6** y espera la primera solicitud (llega al minuto). Abre su chat.
2. **Verifica:**
   - arriba, la conversación; abajo, la identificación y la señal, y los bloques **PREGUNTAR** y **RESPONDER**, cada uno con su título;
   - cada pregunta tiene su ícono (ojo, parlante, nube y huella) y su costo, **−5 s**;
   - al preguntar **¿Qué ves?**, sale un **−5 s** rojo sobre la pestaña del amigo, y el botón queda con un ✓, tenue, y no se puede repetir;
   - lo que describe a la criatura va en **amarillo** y se puede clickear; lo que decide la fila de la tabla (como "Está enojado" o un audio) va en **azul** y no se clickea;
   - al marcar las 2 características, "Matías piensa…" dura **2 segundos**;
   - un señuelo solo vibra y se pone rojo: ya no cuesta tiempo;
   - el nombre de la entidad lleva el ícono del cuaderno; al hacer clic se abre su página;
   - las respuestas son **hojas del cuaderno**, una debajo de otra, con el número de su columna de la tabla en una nota amarilla. Abrir la página no mueve las preguntas de su lugar.

### El cuaderno con los mismos colores

**Verifica:** en la página abierta, los nombres de las características van con **destacador amarillo** y las condiciones de la tabla, en **lápiz pasta azul**, más vivo que el de los títulos.

### La estática y la señal

1. Pon **Test Signal** en **25** y presiona **F6**. Cuando llegue una solicitud, pregunta **¿Qué ves?**.
2. **Verifica:**
   - si la estática tapó algo que sirve (una característica, un señuelo, una observación o el audio), el botón vuelve con un ícono de estática y su **−5 s**: se puede repetir;
   - el botón cuadrado junto a la identificación muestra la señal del amigo en barritas: verdes con 70 o más, ámbar desde 30 y rojas abajo.
3. Pon **Test Signal** en **0** y presiona **F6**.
4. **Verifica:**
   - el botón de las barritas parpadea con un borde rojo;
   - los títulos dicen **PREGUNTAR · SIN SEÑAL** y **RESPONDER · SIN SEÑAL: SINCRONÍZALO**;
   - con **Esc**, **Opciones** y **Reducir destellos**, el borde queda fijo.

### La descarga al primer clic

1. Con **Test Signal** en **100**, juega hasta que un amigo mande un video (llega en una calma, después de la primera ola).
2. Con su chat abierto, deja el mouse **apretado al final de la conversación**, justo donde aparece la barra, antes de que aparezca.
3. **Verifica:** cuando aparece la barra, el video se descarga sin soltar el botón. Era el error del tester: antes había que soltar y volver a apretar.

### El accidente

**Verifica:** cuando un amigo tiene un accidente (desde la noche 1, en una ola), sus opciones son botones de terminal, sin número, porque se responden sin cuaderno, y el título dice **RESPONDER · ¿QUÉ LE DICES?**.

### El guardado

1. En el menú, **Nueva partida**, y juega la noche 0 hasta que León se despide. En las tarjetas, presiona **Esc** y **Volver al menú**.
2. **Verifica:** **Continuar** empieza la noche 1, no el tutorial.
3. Si ganas una noche y eliges **Volver al menú** en la pantalla final, **Continuar** empieza la noche siguiente.

### Los textos nuevos para corregir (antes del 25 de noviembre)

Todos en `data/text/ui.csv`:

- los títulos: `CHAT_ASK_TITLE`, `CHAT_ANSWER_TITLE`, `CHAT_NO_TIME` y `CHAT_NO_SIGNAL`, y los que se acortaron para caber en un título, `CHAT_OPEN_NOTEBOOK` y `CHAT_OFFLINE`;
- las preguntas cortas de los botones: `QUESTION_SIGHT_SHORT`, `QUESTION_SOUND_SHORT`, `QUESTION_ENVIRONMENT_SHORT` y `QUESTION_TRACES_SHORT`; Matías sigue preguntando con la frase completa;
- el costo: `CHAT_QUESTION_COST`;
- León: `TUTORIAL_LEON_DECOY` (sin "y te costó un segundo") y `TUTORIAL_LEON_SIGNAL_WARN` (el botón de las barritas).

Se borraron `CHAT_DECOY_COST` y `ANSWER_FROM_PAGE`.

### Si quieres redibujar

Los íconos del chat, la señal y las hojas son pixel art de Claude (`art/ui/chat_*.png`, lo genera `tools/make_ui_art.py`). Está en `arte_pendiente.md`. Si dejas un archivo tuyo con el mismo nombre, Claude no vuelve a correr el script.

## U. Probar Normal y Difícil (Plan 9.4)

Del 11 de noviembre (sesión S21i), con el feedback del primer testeo. Avísale a Claude antes de abrir Godot. Son unos 20 minutos.

### El menú

1. Presiona **F5** (el juego completo). En el menú, **Nueva partida**.
2. **Verifica:**
   - aparece **Elige la dificultad**, con **Normal** marcada (iluminada, con borde celeste) y una línea que describe cada modo;
   - **Difícil** está hundida, con un candado, y abajo dice en ámbar **Termina Normal para desbloquearla.**;
   - **Volver** regresa a los botones del menú;
   - si tienes una partida guardada, **Empezar** primero pregunta si quieres borrarla.
3. Empieza en Normal: arranca la noche 0, con León. Sal con **Esc** y **Volver al menú**.
4. **Verifica:** **Continuar** dice **Continuar: noche de práctica · Normal**.

### La noche 1 de Normal (lo más importante)

1. En el menú, **Continuar** (o salta el tutorial con **Esc** y **Saltar tutorial**) hasta la noche 1.
2. **Verifica, con el reloj del celular:**
   - el silencio dura unos 45 s (hasta las 00:38);
   - llega **una** consulta sola, con 90 s para responder;
   - cuando la respondes (o cuando le quedan 30 s), llega un video, no antes;
   - después hay una calma, con un susto;
   - después llegan 2 consultas separadas por 30 a 45 s, con la Mano y una interferencia entre medio;
   - otra calma, con otro susto;
   - hacia las 03:04 empieza la ola final: una consulta, después el video y después la otra consulta, nunca juntas;
   - no hay accidentes.
3. **Dime:**
   - si la noche se siente tranquila para aprender o aburrida;
   - si la calma antes de la ola final se hace larga (si respondes rápido dura cerca de un minuto);
   - si después de la última consulta sobra mucho tiempo hasta las 06:00.

Los valores están en `data/nights/normal/night_1.tres`: en el **Inspector**, el grupo **Plan de olas** tiene las 3 olas. Abre cada una con un clic. Por ejemplo, para dejar la ola 2 en una consulta, cambia su **Requests** de **2** a **1**.

### Difícil

Para jugar Difícil sin terminar Normal, usa el escritorio suelto:

1. En el panel **FileSystem** (abajo a la izquierda), haz doble clic en `scenes/desk/desk.tscn`.
2. En el panel **Scene** (arriba a la izquierda), haz clic en el nodo **RequestManager**.
3. En el **Inspector** (a la derecha), arrastra el archivo `data/difficulty/hard.tres` desde **FileSystem** hasta la propiedad **Difficulty**. Deja **Night Number** en **1**.
4. Presiona **F6** y espera la primera consulta (llega al minuto). Abre su chat y pregunta.
5. **Verifica:**
   - nada va en amarillo ni en azul, y no se puede clickear ninguna frase;
   - el audio (**▶ Escuchar audio**) sí va en azul y se escucha con un clic;
   - no hay barra de características ni "Matías piensa": junto al botón de las barritas no aparece nada;
   - abres el cuaderno, buscas la página en el índice (las pestañas amarillas) y las respuestas del chat son las de esa página;
   - el cuaderno se ve igual que en Normal.
6. Al terminar, haz clic con el botón derecho sobre **Difficulty** en el Inspector y elige **Clear** (Limpiar), para dejarla vacía. No guardes la escena.

### Desbloquear Difícil (opcional)

Para ver el aviso y el menú con Difícil libre, sin jugar las 5 noches:

1. Cierra el juego.
2. En el Explorador de Windows, abre `%APPDATA%\Godot\app_userdata\Spook Dial\`.
3. Crea un archivo de texto `progress.cfg` con estas dos líneas:

   ```
   [progress]
   finished=PackedStringArray("normal")
   ```

4. **Verifica:** en **Nueva partida**, Difícil ya no tiene candado, y al elegirla empieza en la noche 1.
5. Para volver a bloquearla, borra `progress.cfg`.

### Los textos nuevos para corregir (antes del 25 de noviembre)

Todos en `data/text/ui.csv`:

- los modos: `DIFFICULTY_NORMAL`, `DIFFICULTY_HARD`, `DIFFICULTY_NORMAL_INFO` y `DIFFICULTY_HARD_INFO`;
- el menú: `MENU_DIFFICULTY_TITLE`, `MENU_LOCKED` (lleva `{difficulty}`), `MENU_START` y `MENU_BACK`;
- el aviso al terminar Normal: `END_UNLOCKED` (lleva `{difficulty}`).

### Si quieres redibujar

El candado es pixel art de Claude (`art/ui/menu_lock.png`, de 11×11, lo genera `tools/make_ui_art.py`). Está en `arte_pendiente.md`.

---

## V. Probar la noche 0 nueva y los pedidos del 12 de noviembre (Plan 9.5)

Del 12 de noviembre (sesión S21j), con el feedback del primer testeo. Avísale a Claude antes de abrir Godot. Son unos 20 minutos.

### La noche 0 (lo más importante)

1. Presiona **F5**. En el menú, **Nueva partida** y **Normal** (si tienes una partida guardada, confirma que se borre).
2. **Verifica, al empezar:**
   - el celular, las cortinas, el cuaderno, el mixer y las entradas de Gonzalo y Agustín **no se iluminan al pasar el mouse ni responden al clic**;
   - **Esc** pausa (ahí está **Saltar tutorial**).
3. Abre el chat de León y sigue lo que pide. **En cada paso, verifica que lo que hay que apretar parpadea** (un borde ámbar, o la frase que late) **y que se habilita recién cuando León termina de escribir**:
   1. **¿QUÉ VES?** Después León dice que **cada pregunta cuesta 5 s** (la pestaña muestra "−5 s").
   2. Las frases amarillas laten. Marca **lentes** (prueba también el polerón: bromea una vez).
   3. León explica **lo azul** ("Está enojado") y pide **¿QUÉ OYES?**
   4. Llega **▶ Escuchar audio**, que late: escúchalo. Son **las tripas de Gonzalo**. León espera a que termine y lo comenta.
   5. **¿AMBIENTE?** y marca **huele mal**. Matías piensa y aparece el nombre, que parpadea: haz clic, y se abre la página (el cuaderno ya responde).
   6. Las **4 hojas** parpadean juntas: elige mal una vez, después la del ✓ y después la de la calavera.
   7. La **barra del video** parpadea: mantenla presionada.
   8. León dice que **Gonzalo te está escribiendo**: su entrada se desbloquea y parpadea, con **15** detenidos.
   9. Abre su chat: **el tiempo corre** en su pestaña y en su entrada, no se puede preguntar ni responder, y las respuestas dicen **MIRA QUÉ PASA SI NO CONTESTAS**. A los 15 s cuenta qué hizo y sale **Gonzalo recibió daño: 2/3**, pero su entrada sigue con sus 3 marcas.
   10. Parpadea la entrada de León: ábrela. León explica, su señal baja, un mensaje llega **con palabras tapadas** y después se corta la señal.
   11. El **botón de las barritas** parpadea en rojo: apriétalo. En el mixer parpadea **"TÚ"** en tu turno (o el canal de León, si fallas).
   12. Al sincronizar, el mixer se cierra solo, se abre el chat de León y se despide. Después vienen las tarjetas.
4. **Verifica las tarjetas:** cada idea es una viñeta, **Connection en verde, Sanity en rojo y Trust en amarillo**, y lo importante en ámbar. La de **La Mano** muestra el celular, un cursor que aprieta **FLASH** y la Mano que se va.
5. **Dime:**
   - si en algún paso no supiste qué apretar, o algo parpadeó antes de tiempo;
   - si la demostración de Gonzalo se entiende sin que nadie te explique;
   - qué líneas de León y de Gonzalo cambiarías.

### Los pedidos del 12 de noviembre

1. Empieza la noche 1 (o abre el escritorio suelto, **F6** sobre `scenes/desk/desk.tscn`).
2. **Verifica:**
   - **la alarma:** cuando un amigo pide algo y su chat está cerrado, su entrada pita una vez por segundo, en rojo con cada pitido; con 2 o 3 a la vez suenan juntas (el acorde). Durante Audio Sync y mientras suena un audio, se callan;
   - **el ambiente:** antes y durante un susto (las luces parpadean), el viento y el cuarto siguen sonando igual;
   - **el celular:** cada paso de la rueda avanza la mitad que antes, y Sanity sube igual;
   - **el botón FLASH:** entre la hora y la batería, con relieve; se ilumina con el mouse encima, se hunde al apretarlo y se ve apagado sin batería;
   - **las fotos perturbadoras:** con Sanity en 50 o menos ya sale alguna (1 de cada 4), y con muy poca, casi todas. Para que Sanity baje rápido, cierra las cortinas un rato (la barra roja de arriba lo muestra) y después abre el celular.
3. **Dime:**
   - si la alarma molesta (se puede bajar o espaciar);
   - si con el feed más lento alcanzas a ver las fotos.

### Los textos nuevos para corregir (antes del 25 de noviembre)

En `data/text/ui.csv`:

- León: `TUTORIAL_LEON_COST`, `TUTORIAL_LEON_BLUE`, `TUTORIAL_LEON_ASK_SOUND`, `TUTORIAL_LEON_LISTEN`, `TUTORIAL_LEON_HEARD`, `TUTORIAL_LEON_GONZALO`, `TUTORIAL_LEON_NO_ANSWER`, `TUTORIAL_LEON_STATIC` (la que llega tapada) y `TUTORIAL_LEON_STATIC_EXPLAIN`;
- Gonzalo: `TUTORIAL_GONZALO_HELP`, `TUTORIAL_GONZALO_ALONE`, `TUTORIAL_GONZALO_HURT` y `TUTORIAL_GONZALO_WATCH`;
- las tarjetas: `TUTORIAL_CARD_*_TEXT` (en viñetas: cada línea empieza con "• "; `{connection}`, `{sanity}` y `{trust}` se pintan solos, y lo que va entre `[b]` y `[/b]` sale en ámbar).

En `data/text/phone.csv`: `PHONE_FLASH_BUTTON` ("FLASH").

Ya no existen `TUTORIAL_LEON_ASK_SIGHT_AGAIN`, `TUTORIAL_LEON_NAME_OPEN` ni `TUTORIAL_LEON_WAIT`: con el chat bloqueado, ya no pueden pasar.

### Si quieres redibujar o cambiar sonidos

- El botón del flash es pixel art de Claude (`art/ui/phone_flash_button.png`, 3 cuadros de 14×14), en `arte_pendiente.md`.
- Las tripas (`audio/clues/tutorial_stomach_yes.wav`) y las alarmas (`audio/sfx/alarm_*.wav`) están en `sonidos_pendiente.md`.

## W. Probar Extremo (Plan 9.6)

Del 12 de noviembre (sesión S21k). Avísale a Claude antes de abrir Godot. Son unos 30 minutos para verlo, o más si quieres ganarlo.

### Desbloquearlo sin terminar Difícil

1. Cierra el juego.
2. En el Explorador de Windows, abre `%APPDATA%\Godot\app_userdata\Spook Dial\`.
3. Abre (o crea) `progress.cfg` con el Bloc de notas y deja estas dos líneas:

   ```
   [progress]
   finished=PackedStringArray("normal", "hard")
   ```

4. **Verifica:** en **Nueva partida** aparecen **Normal**, **Difícil** y **Extremo**, los 3 sin candado. Sin ese archivo, Extremo dice **Termina Difícil para desbloquearla.**

### Jugarlo

1. Elige **Extremo** y **Empezar**: arranca la noche 1, sin tutorial.
2. **Verifica:**
   - al empezar, el chat de un amigo dice en rojo que **empieza herido: 1/3**, y su entrada del PC muestra 1 de vida;
   - nada va en amarillo ni en azul, como en Difícil, salvo el audio;
   - las olas son de 2 consultas, con calmas cortas (20 a 30 s), y la final de 3;
   - una respuesta incorrecta baja Trust 22,5 (en Difícil, 15);
   - al herido no le pasan accidentes.
3. **Dime:**
   - si la noche 1 se siente como el paso siguiente después de Difícil;
   - hasta qué noche llegas;
   - si el amigo herido se siente justo o injusto.

**Qué esperar:** según el modelo, la noche 1 se gana al ritmo de Difícil (unos 14 s por consulta), y desde la noche 2 hace falta jugar como experto: unos 11 s por consulta para llegar a la noche 5. Si la noche 5 se siente imposible, se afloja primero esa (más tiempo o 13 consultas).

Los valores están en `data/nights/extreme/night_N.tres` y en `data/difficulty/extreme.tres` (grupo **Castigos**: **Error Trust Scale**, **Wounded Friends** y **Wounded Health**).

### Los textos nuevos para corregir (antes del 25 de noviembre)

Todos en `data/text/ui.csv`: `DIFFICULTY_EXTREME`, `DIFFICULTY_EXTREME_INFO` y `CHAT_WOUNDED_START` (lleva `{friend}`, `{health}` y `{max}`).

---

## X. Probar la historia de la noche 1 (planes 9.7 y 9.8)

Del 12 de noviembre (sesión S21l). Avísale a Claude antes de abrir Godot. Son unos 25 minutos: la noche 1 en Normal y, si alcanzas, en Difícil (dura unos 7 minutos y medio cada una: termina a las 06:30). La historia es la misma en los 3 modos.

**Lo nuevo después de tu primera prueba (Plan 9.8):**

- la noche **espera congelada a las 00:00** hasta que abres la llamada (las 3 entradas tienen un borde que parpadea);
- un amigo sin nada que jugar está **grabando**: su chat no tiene preguntas ni respuestas, y abajo dice **"• REC · LEÓN ESTÁ GRABANDO"**;
- lo que **pide ayuda** va en rojo: una línea **"── ▲ LEÓN PIDE AYUDA ──"**, y "▲" antes del nombre con la barra izquierda roja;
- cada amigo tiene **su alarma** (León un doble bip, Gonzalo un zumbido, Agustín un trino), cada medio segundo y con su propio ritmo;
- una línea del vlog en un chat que no estás mirando hace un **"pop" suave** y pone un **"•"** junto al nombre en el PC; al abrir el chat, **"── NUEVOS ──"** marca dónde empezar;
- un **golpe de sonido** al empezar cada ola;
- el vlog va **al doble de lento**, y la noche termina a las **06:30**.

### Llegar a la noche 1

- **En Normal:** **Nueva partida**, elige **Normal** y **Empezar**. Empieza en la noche 0: con `Esc` abre la pausa y aprieta **Saltar tutorial**.
- **En Difícil o Extremo:** desbloquéalos con `progress.cfg` (está explicado en la sección W) y elige el modo: empiezan en la noche 1.

### Qué verificar

1. **Al empezar (00:00):** la hora no corre, las 3 entradas del PC tienen un borde que parpadea y un **auricular celeste** a la derecha. Haz clic en cualquiera: el chat dice **LLAMADA GRUPAL**, no tiene pestañas, arriba están las barritas de los 3 y León, Gonzalo y Agustín presentan el capítulo de **Acá Penan**, cada uno con su color y su voz. **Verifica:** la hora del celular empieza a correr recién ahí.
2. **Unos 25 s antes de la primera ola:** el susto ("???? qué fue eso" hasta "Escóndanse!! Nos reunimos en la cabaña!!"). La llamada termina, vuelven las pestañas y cada uno escribe en su chat dónde se escondió (el punto en la pestaña marca lo que no leíste).
3. **Al terminar la ola 1:** León muestra el establo, Gonzalo la cocina, Agustín se siente en una película y León pregunta si lo llamaste. **15 s antes de la ola 2,** cada uno escribe que algo se acerca.
4. **Al terminar la ola 2, la reunión:** Gonzalo prende la luz del pórtico y después **León decide** (con alarma, 15 s y 4 opciones en su chat). Después **decide Agustín**: en plural si León fue a las luces blancas. Prueba al menos una vez no contestar.
5. **Cuando llegan:** vuelve la llamada, con todo lo que se habló antes ("Ya estamos todos. Nadie se separa más").
6. **15 s antes de la ola final,** 3 líneas en la llamada; la final la corta en los 3 chats. **Después de la final,** el cierre del vlog.
7. **Además:** el Tue Tué y la Calchona salen al menos una vez cada uno, y con los 3 juntos ninguna consulta dice "Me perdí" ni "Me separé de los demás".

**Qué esperar:** jugando bien, la historia nunca atrasa una ola. Si te demoras en las decisiones, la ola final espera a que terminen, a lo más 45 s. Si la final te llega encima de la ola 2, la reunión se salta y se reúnen solos.

### Dime

- si la historia **se deja, se modifica o se quita**;
- si se entiende que es una llamada (y que no se puede cambiar de chat);
- si las decisiones se sienten justas y si los castigos se notan (10 s menos, Trust −10 o −20);
- si se lee bien sin perder el hilo de las consultas;
- **lo más importante:** si ahora se distingue cuándo un amigo graba y cuándo pide ayuda, y si las alarmas suenan a alarma sin cansar (si molestan, se bajan con `ALARM_RMS` en `tools/make_sounds.py`).

### Dónde se cambia

- **El guion:** en Godot, panel **FileSystem** (Sistema de archivos), carpeta `data/story`, doble clic en `night_1.tres`. En el **Inspector**, **Beats** tiene los 7 momentos; despliega uno para ver sus **Steps** (cada línea con su **Speaker** y su **Text Key**). Una decisión tiene sus **Options**, con **Trust Change**, **Penalty Seconds**, **Penalized** y **Damage**. Al guardar (`Ctrl+S`), **verifica:** el archivo sigue en la lista de **Story** de `data/nights/normal/night_1.tres`.
- **Los textos:** `data/text/messages.csv`, las claves `STORY_N1_*`.
- **Cuánto espera una ola a la historia:** `data/balance.tres`, grupo **Director**, **Story Hold Limit** (45).

### Los textos nuevos para corregir (antes del 25 de noviembre)

- **Borradores de Claude** (el guion no los tenía), en `messages.csv`: lo que contesta León a las opciones malas (`STORY_N1_LEON_STABLE_REPLY` y `STORY_N1_LEON_SHOUT_REPLY`) y lo que le responde Matías a Agustín (`STORY_N1_AGUSTIN_HIDE`, `_RUN`, `STORY_N1_DUO_HIDE` y `_RUN`).
- En `ui.csv`: `CHAT_CALL_TITLE` y `CHAT_CALL_SYNC` (lleva `{friend}`); y los del Plan 9.8: `CHAT_VLOG_REC` y `CHAT_HELP_DIVIDER` (llevan `{friend}`), `CHAT_UNREAD_DIVIDER`, y `END_WON_TITLE` y `END_QUOTA`, que ahora llevan `{time}` (la hora en que terminó la noche).

---

## Y. Poner la música de la noche (Plan 9.8)

Cuando tengas las 2 pistas (las especificaciones están en `sonidos_pendiente.md`, "Faltan"). Avísale a Claude antes de abrir Godot.

1. En el Explorador de Windows, crea la carpeta `audio\music\` dentro del proyecto y deja ahí las 2 pistas con estos nombres exactos: `calm.ogg` (la eerie, para las calmas) y `wave.ogg` (la tensa, para las olas).
2. Abre Godot: las importa solo. No hace falta marcar nada más: el juego las repite sin pausa.
3. **Verifica:** juega la noche 1. Al abrir la llamada suena la pista de calma; al empezar la primera ola cambia a la tensa (con un fundido de 2 s), y al terminar la ola vuelve la de calma. Su volumen es el de **Ambiente** en las opciones.
4. Anota de dónde salió cada pista, con su licencia, en `audio/source/creditos.md`.

---

## Z. Publicar en itch.io: versión web y descarga para Windows

**Estado: pendiente.** El código ya está listo para web (se oculta el botón «Salir», que no cierra una pestaña); falta lo que se hace en Godot y en itch.io. Las carpetas de salida van **fuera de OneDrive y fuera del proyecto**, por ejemplo `C:\dev\builds\web\` y `C:\dev\builds\windows\` (créalas en el Explorador).

### 1. Instalar las plantillas de Web (solo hay las de Windows)

1. Godot, menú **Editor > Manage Export Templates…**.
2. Arriba debe decir **4.7.2.stable**. Pulsa **Download** (en 4.7 puedes elegir solo **Web** para no bajar todo) y espera a que termine.
3. **Verifica:** la lista muestra Web y Windows Desktop como instalados.

### 2. Crear el preset Web

1. **Project > Export…** > **Add… > Web**.
2. A la derecha, **Options**: deja **Thread Support** y **Extensions Support** **apagados** (así no hace falta ninguna cabecera especial en itch.io).
3. Abajo, **Export Path**: pulsa la carpeta, ve a `C:\dev\builds\web\` y escribe el nombre **`index.html`** (tiene que llamarse así).
4. Pulsa **Export Project…**, desmarca **Export With Debug** y guarda.
5. **Verifica:** en esa carpeta hay `index.html`, `index.js`, `index.wasm`, `index.pck` y algunos más. Ábrelos con un servidor local (el doble clic a `index.html` **no** funciona en los navegadores): en esa carpeta, `python -m http.server 8000` y entra a `http://localhost:8000`.

### 3. Crear el preset Windows (la descarga)

Igual que en la guía anterior: **Add… > Windows Desktop**, **Binary Format > Embed PCK** activado, **Export Path** `C:\dev\builds\windows\SpookDial.exe`, **Export With Debug** apagado.

### 4. Empaquetar

- **Web:** selecciona **todo el contenido** de `builds\web\` (no la carpeta) > clic derecho > *Enviar a > Carpeta comprimida*; renómbralo `SpookDial_web.zip`. Debe tener `index.html` en la raíz del zip.
- **Windows:** comprime `SpookDial.exe` (no el `.console.exe`) con `OFL.txt` y `audio/source/creditos.md`; llámalo `SpookDial_windows.zip`.

### 5. Subir a itch.io (un solo proyecto con las dos)

1. **Kind of project: HTML** (permite también archivos descargables).
2. En **Uploads**, sube los 2 zips.
3. En `SpookDial_web.zip` marca **This file will be played in the browser**. En `SpookDial_windows.zip`, la plataforma **Windows**.
4. **Embed options:** **Viewport dimensions** 1280 × 720, **Fullscreen button** activado, **Click to launch in fullscreen** a tu gusto. **SharedArrayBuffer support:** apagado.
5. Guarda en **Draft**, prueba la página y recién ahí pon **Public**.
6. **Verifica en el navegador:** que se oigan los sonidos (el primer clic los activa), que se vean la letra y los videos de la noche 0, que «Continuar» recuerde la partida tras cerrar y reabrir la pestaña, y que no aparezca el botón «Salir».

---

## AA. Probar la noche que termina cuando se acaba, y la nota (Plan 9.9)

**Estado: pendiente.** Unos 25 minutos.

1. **El inicio de la noche 1.** Empieza una partida nueva en Normal y salta el tutorial (`Esc` > «Saltar tutorial»). Abre la llamada y lee la intro y el susto sin apurarte. **Dime** si ahora alcanzas a leer todo, o si se hace lento.
2. **El final.** Juega la noche 1 entera. Cuando se resuelve la ola final y se despiden en el vlog, la noche termina unos 3 s después. **Verifica:** la pantalla dice «Llegaste a las HH:MM», con la hora a la que terminó, y ya no queda tiempo muerto al final.
3. **La nota.** En el resumen aparecen la letra grande («Nota A»), cuánto esperaron tus amigos por pedido de ayuda (con la meta) y las vidas perdidas. **Dime** si la nota se siente justa para cómo jugaste.
4. **Más rápido o más lento.** Vuelve a jugar la noche 1 (desde el menú, «Continuar» repite la noche 2; para repetir la 1, pierde una noche a propósito o empieza de nuevo), una vez respondiendo rápido y otra tomándote tu tiempo. **Verifica:** jugando rápido la noche termina antes y la nota sube.
5. **La noche 2 de Normal.** Sus calmas son de 75 a 95 s (las de siempre son de 40 a 60) para que, jugando bien, no termine antes de las 04:30. **Dime** si alguna calma se hace larga.

**Si quieres ajustar la nota**, en Godot:
- La meta de espera de cada modo: panel **FileSystem** (abajo a la izquierda) > doble clic en `data/difficulty/normal.tres` (o `hard.tres`, `extreme.tres`) > en el **Inspector** (a la derecha), sección **Nota** > **Wait Goal** (en segundos). Guarda con `Ctrl+S`.
- Cuánto pide cada letra: doble clic en `data/balance.tres` > **Inspector** > sección **Nota**: **Grade Wait Factors** (x: hasta cuántas veces la meta da 2 puntos; y: hasta cuántas da 1) y **Grade S Points**, **Grade A Points** y **Grade B Points** (desde cuántos puntos, de 6, es cada letra).
- **Verifica:** gana una noche y mira si la letra cambió como esperabas.

**Corrige los textos nuevos** en `data/text/ui.csv`: `END_GRADE`, `END_WAIT` y `END_LIVES`.


## AB. Probar la llamada que no se roba el chat, la lectura más rápida y los sonidos de respuesta (S21p)

**Estado: pendiente.** Unos 10 minutos, en la noche 1 de Normal (o Difícil).

1. **La espera de la intro.** Abre la llamada y lee la intro. Cada línea espera ahora lo que tardas en escribirla y leerla a 5 palabras por segundo, más 0,5 s. **Dime** si sigue quedando espera, o si ahora llega antes de que termines de leer.
2. **El chat del amigo al resolver.** En las olas, resuelve una consulta con otras todavía por llegar (sobre todo en la ola final). **Verifica:** te quedas en el chat del amigo al que ayudaste y alcanzas a leer su reacción; no te lleva a la llamada. Al terminar la ola, la llamada vuelve solo si hay una línea nueva, unos 3 s después de la última respuesta. Si no tienen nada más que decir, te quedas en el chat del amigo (con su cartel "REC").
3. **Los sonidos.** Responde bien una consulta: suena un chime breve y suave. Elige la calavera: suena una cámara de fotos. Una respuesta incorrecta, o dejar que el amigo decida solo, no suena nada. **Dime** si el chime agobia al repetirse, o si el volumen de alguno no te convence.

**Si quieres ajustar algo**, en Godot:
- **Los 3 s antes de volver a la llamada:** panel **FileSystem** > doble clic en `data/balance.tres` > **Inspector** > sección **Director** > **Call Delay** (en segundos). Guarda con `Ctrl+S`. **Verifica:** resuelve una consulta con una línea de la llamada por llegar y mira cuánto tarda en volver.
- **El volumen de los sonidos:** en `tools/make_sounds.py`, las recetas `request_correct()` y `photo_shutter()` fijan su RMS al final (−26 y −22); un número más bajo suena más suave. Después, `/usr/bin/python3 tools/make_sounds.py request_correct photo_shutter` con el editor cerrado.
