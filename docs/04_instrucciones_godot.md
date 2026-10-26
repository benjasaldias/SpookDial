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
