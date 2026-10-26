# Spook Dial — contexto y reglas del proyecto

Lee este archivo completo al empezar cada sesión. Después lee **`docs/00_log.md`**, que dice qué sesión toca y con qué documento, y luego `resumen.md`, que tiene el detalle y los pendientes vigentes.

## Qué es

- Juego de terror psicológico para PC hecho en **Godot 4.7.2** (renderer GL Compatibility), con **pixel art 2D a 1280×720** dibujado en Aseprite.
- El protagonista, Matías, nunca sale de su escritorio. Durante **5 noches de unos 7 minutos** guía por chat a **3 amigos** (León, Gonzalo y Agustín) que enfrentan criaturas del **folclore chileno**. Para eso aplica las reglas de su **cuaderno**, al estilo de Keep Talking and Nobody Explodes.
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
   - **Benja escribe los diálogos.** Claude no escribe diálogos finales.
   - Claude deja textos de prototipo que empiezan con `[PROTO]` y **describen la intención** del mensaje, y siempre dice en qué archivo quedaron.
   - Todos los textos van en `data/text/*.csv` (columnas `keys,es,en`) para poder traducirlos al inglés.
9. **El juego es estrictamente el escritorio.** La historia va solo en cinemáticas opcionales y nunca cambia las mecánicas.
10. **Pixel art.** 1 píxel de arte = 1 unidad de Godot, con posiciones enteras y filtro Nearest. No se escalan sprites, salvo las vistas ampliadas a ×2 exacto.
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
| 26-10-2026 | **La frase clickeable de una característica va entre asteriscos** en el CSV: `vio un *hombrecito*` (no corchetes, que chocan con `[PROTO]` y con BBCode). |
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
- **Arte:** los sprites están en `art/sprites/` (posiciones en `art/positions.md`). La maqueta está en `art/_layout/` (`scene_layout.aseprite` y `scene_layout.png`), que Godot ignora.
- **Git:** remoto `origin` = `https://github.com/benjasaldias/SpookDial.git` (privado; `gh` está autenticado como `benjasaldias`). Rama `main`. Usar `core.filemode=false` (el disco es NTFS).
- **Pantalla:** viewport de 1280×720, stretch mode `canvas_items`, aspect `keep` (Godot no lo escribe en `project.godot` porque es el valor por defecto), filtro `Nearest` y snap a píxel. Falta que Benja confirme el escalado a 1080p (`docs/04`, D).
- **Pruebas:** `~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd` ejecuta todos los `test/test_*.gd` (sin addons). Una suite que no carga cuenta como falla.
- **Capturas:** `--write-movie` graba siempre al tamaño del viewport (1280×720), aunque se pida otra resolución. `tools/compare_png.py` compara una captura con la maqueta.

## Convenciones de código

Es una propuesta; se confirma al empezar a programar.

- GDScript con tipado estático. Las señales se nombran en pasado (`request_resolved`). Un script por responsabilidad.
- Carpetas de `res://`: `art/`, `audio/`, `fonts/`, `data/` (recursos `.tres` y `data/text/*.csv`), `scenes/`, `scripts/`, `shaders/` y `addons/`. `docs/` y `art/_layout/` tienen `.gdignore`.
- Autoloads previstos: `GameState` (noche, medidores y amigos), `EventBus` (señales globales), `AudioManager` y `SaveManager`.
- La lógica pura (aplicar reglas, resolver consecuencias, estática, medidores) va en clases sin dependencias de escena, para poder probarla.
- Specs y planes van en `docs/`, numerados, y no en `docs/superpowers/`.
