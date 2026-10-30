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
   - **Clics:** al hacer clic en el cuaderno, el celular o el mixer, en el panel **Output** (Salida) de Godot aparece "Clic en Notebook", "Clic en Phone" o "Clic en Mixer".

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
   - el mensaje aparece escrito de a poco;
   - las frases en ámbar y subrayadas se pueden clickear.
4. **Identifica:** clickea las frases en ámbar.
   - Las características reales se ponen verdes y la barra cuenta "Características marcadas: 1 de 2".
   - Los señuelos vibran y se ponen rojos.
   - Con las 2 marcadas, la barra dice "Matías piensa…" y a los 3 segundos aparece el nombre (El Trauco).
   - Al clickear el nombre, en el panel **Output** (Salida) aparece "Abrir en el cuaderno la página de El Trauco (Plan 4)".
5. **Pregunta:** cada botón (¿Qué ves?, ¿Qué oyes?…) resta 5 segundos, y el amigo responde con lo de esa categoría. Con 5 segundos o menos, los botones se desactivan.
6. **Sin respuesta:** si se acaba el tiempo, el amigo cuenta que decidió solo y su entrada deja de parpadear. Responder desde el cuaderno llega en el Plan 4.
7. **Estática:**
   - en el panel **Scene**, selecciona el nodo `RequestManager`;
   - en el **Inspector**, baja **Test Signal** a 40 (se tapa el 25 % de las palabras) o a 20 (el 45 %);
   - vuelve a probar con **F5**: algunas palabras aparecen como `▒▒▒`. Una frase tapada no se puede clickear: pregunta por su categoría para recuperarla.
8. **El panel tapa el escritorio:** con el chat abierto, pasa el mouse por donde están el mixer y el celular, detrás del panel. No deben resaltarse, y un clic no debe escribir "Clic en Mixer" en **Output**. Cierra el chat (`Esc` o clic derecho) y vuelve a probar: ahora sí se resaltan.
9. **Al terminar, deja Test Signal en 100**, o cierra la escena sin guardar.

**Verifica:** los pasos 2 a 8 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Noche que se juega:** **Night Number**, en el Inspector de `RequestManager`. Por ahora solo la noche 3 tiene una entidad. Cuando agregues El Tue Tué y La Calchona a la noche 1, cámbialo a 1.
- **Señuelos por noche:** `data/nights/night_N.tres` > **Decoys In First Message**.
- **Los señuelos:** `data/catalog.tres` > **Decoys**. Cada uno tiene `Id`, `Category`, `Text Key` y `Place Keys` (vacío: sirve en cualquier lugar; si no, las claves de sus lugares, como `PLACE_FOREST`). Su texto va en `data/text/messages.csv`, con la frase clickeable entre asteriscos.
- Después de cambiar datos, pídele a Claude que corra las pruebas: el validador avisa en español si falta algo, como un lugar sin suficientes señuelos.
