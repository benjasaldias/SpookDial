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
