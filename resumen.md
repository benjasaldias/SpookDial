# Resumen de sesiones — Spook Dial

La entrada más reciente va arriba, y sus listas de pendientes son la lista vigente. En cada cierre se arrastran los pendientes que siguen abiertos y se marcan con [x] los cumplidos.

---

## Sesión 6 — 26 de octubre de 2026 (noche) — Plan 2 escrito: datos y textos

Plan escrito con `superpowers:writing-plans`, en Opus 5.5.

### Realizado

- **Nuevo `docs/08_plan_datos_textos.md`:** el Plan 2 en 10 tareas con código completo. Lleva las pruebas de 36 a 78:
  - clases `Resource` con `class_name` en `scripts/data/`: `TraitData`, `ActionData`, `ObservationData`, `RuleData`, `EntityData`, `FriendData`, `NightData` y `ContentCatalog`;
  - `scripts/core/rule_evaluator.gd`: qué regla se aplica, si una respuesta es correcta, de mayor riesgo o incorrecta, y todas las situaciones posibles;
  - `scripts/core/content_validator.gd`: revisa el contenido real al correr las pruebas y avisa en español (cantidades de la plantilla, ids que no existen, reglas que nunca se aplican, características compartidas por más de 2 entidades y textos que faltan);
  - `data/text/messages.csv`, `notebook.csv` y `ui.csv`, con textos `[PROTO]`;
  - El Trauco de ejemplo, los 3 amigos, las 5 noches (valores de `docs/02` §6) y `data/catalog.tres`;
  - sección F de `docs/04`: revisar una entidad en el Inspector y cómo agregar una.
- **Decisión de Benja:** la frase clickeable de una característica va **entre asteriscos** (`vio un *hombrecito*`). Anotada en `CLAUDE.md` y en `docs/02` §9.
- **Decisiones técnicas** (detalle en `docs/08`):
  - las reglas nombran las acciones por id;
  - cada noche lista sus entidades nuevas (ya no existe `intro_night`);
  - un catálogo reúne amigos y noches;
  - la columna `en` queda vacía.

  `docs/02` §10 ya está actualizado con el modelo nuevo.
- **Formato verificado en Godot 4.7.2** con un proyecto de prueba aparte, ya borrado:
  - arrays y diccionarios tipados en `.tres`;
  - el CSV se importa a `data/text/<archivo>.<idioma>.translation`;
  - una celda `en` vacía muestra el español;
  - `TranslationServer` funciona en las pruebas sin interfaz.

### Errores encontrados

- **Los corchetes de `docs/02` §9 chocaban con `[PROTO]` y con el BBCode del chat.** Se reemplazaron por asteriscos.
- **Enlazar el mismo sub-recurso de una acción desde una regla es frágil en el Inspector:** si se crea uno nuevo en vez de copiarlo, la regla queda apuntando a otra acción. Por eso las reglas usan ids.
- **Un `class_name` nuevo no existe para Godot hasta actualizar la caché de clases.** El plan importa (`--import`) después de crear cada clase.

### Pendientes Código

- [ ] **S7: ejecutar el Plan 2** (`docs/08`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [x] **S6: escribir el Plan 2.**
- [ ] Planes 3 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Menor: `tools/__pycache__/` quedó en git; agregarlo a `.gitignore` y quitarlo del repositorio cuando Benja apruebe.

### Pendientes Externos

- [ ] **Después de S7:** revisar El Trauco en el Inspector (`docs/04`, F).
- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara: si convence, se queda; si no, se apaga (*Look Enabled*) y se quita el parallax.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7. Las características llevan su frase clickeable entre asteriscos.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10).

---

## Sesión 5 — 26 de octubre de 2026 (noche) — Plan 1 ejecutado: escena del escritorio

Ejecutado inline con `superpowers:executing-plans`, en Opus 5.5. Benja autorizó todos los commits del plan en `main`, sin push.

### Realizado

- **Las 14 tareas de `docs/07`, con 32 pruebas OK y 0 fallidas** (`~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`):
  - ejecutor de pruebas propio en `test/`;
  - pantalla de 1280×720, aspect `keep`, filtro Nearest, snap a píxel, color de fondo y `desk.tscn` como escena principal;
  - `pc_sprite` sin las capas `Entry` y `screen_sprite` importado como textura (el cambio de importador por archivo funcionó, sin necesidad del plan B);
  - matemática del dial, del parallax y de la opacidad por píxel;
  - shader de contorno y `ClickableSprite`, `DialGauge`, `ChatEntry` y `ChatPanel` provisional;
  - `scenes/desk/desk.tscn`, con todo el arte en su lugar, el parallax de la pared (±3, ±2) y el del exterior (±2, ±1 extra).
- **Comparación con la maqueta (`tools/compare_png.py`): 89,6 % al principio y 99,3 % después de que Benja integró la sombra en `background_sprite`.** Fuera de las zonas explicadas solo difieren **63 px (0,01 %)**, así que todo el arte está en su posición exacta. Las diferencias por zona, en la primera comparación:

  | Zona | Píxeles | Causa |
  | --- | --- | --- |
  | Esquina superior derecha (x ≥ 1000) | 9,70 % → 0,03 % | A `background_sprite` le faltaba la capa de sombra; Benja la integró |
  | Diales | 0,28 % | Las agujas apuntan según su valor (1,0 = 120°), no hacia arriba |
  | Última fila | 0,28 % | La maqueta tiene transparentes las filas y = 718–719 (error conocido del maestro) |
  | Termómetro | 0,07 % | No está en `background_sprite`; Benja decidió dejarlo fuera |
  | Entradas | 0,07 % | Ahora tienen los nombres |

- **Escalado a 1080p (Tarea 13):**
  - `--write-movie` graba siempre a 1280×720, así que el ×1,5 se simuló con Nearest sobre recortes del teclado y de un dial;
  - los grosores alternan entre 1 y 2 px; se nota de cerca, pero no rompe la imagen;
  - **recomendación: mantener Nearest en la v1** y dejar el shader de escalado suave en la lista posterior a la v1. Benja decide tras probarlo en su monitor (`docs/04`, D).
- `docs/04`: nuevas secciones C (revisar la escena), D (probar el escalado) y E (mover un objeto).
- **Cambios pedidos por Benja tras probar el juego:**
  - **Termómetro fuera** del arte y del juego (`CLAUDE.md`, diseño v2, `docs/03`, `docs/06` y `art/positions.md`).
  - **El chat se cierra con un clic fuera del panel.** El clic no se consume: si cae en la entrada de otro amigo, se abre su chat.
  - **Cámara que mira hacia el mouse (a prueba)**, en lugar del parallax por planos: zoom ×1,05 y desplazamiento hacia el mouse hasta el margen del zoom. Una prueba confirma que el punto bajo el mouse es el mismo que sin zoom, así que todo sigue alcanzable. Se ajusta o se apaga en el Inspector (`LookCamera`: *Look Enabled*, *Look Zoom* y *Follow Speed*). `parallax_rig.gd` se borró.
  - 36 pruebas OK, 0 fallidas; la comparación con la maqueta (sin cámara) sigue en 99,3 %.
- 15 commits en `main`, con push a GitHub (autorizado por Benja). Después, 3 commits más por los cambios pedidos, sin push.

### Errores encontrados

- **El ejecutor de pruebas del plan tenía dos fallas** (corregidas en `test/run_tests.gd`):
  - una suite cuyo script no cargaba se saltaba en silencio y no contaba como falla;
  - `SceneTree._initialize()` corre **antes** de que la raíz entre al árbol, así que los nodos agregados ahí no recibían `_ready` ni tenían viewport. Ahora las suites corren diferidas (`call_deferred`).
- **El shader de contorno del plan no compilaba en GL Compatibility:** no acepta `TEXTURE` como argumento `sampler2D` de una función propia. Ahora el muestreo va dentro de `fragment()`.
- **A `background_sprite` le faltaba la capa de sombra** de la esquina superior derecha. Benja la integró y aplanó el archivo: corregido. El termómetro queda fuera por decisión de Benja.
- **La aguja rotada se ve dentada incluso a ×1**, porque girar pixel art con Nearest deforma sus bordes. Tenerlo en cuenta en el rediseño de los diales (por ejemplo, agujas pre-dibujadas en varios ángulos).
- **Godot reescribe `project.godot` al importar:** quitó `aspect="keep"` porque es el valor por defecto, y reordenó líneas. No es un problema (la prueba lo confirma).
- **`Camera2D` ya tiene una propiedad `enabled`**: la de la cámara nueva se llama `look_enabled`.
- **El zoom de la cámara (×1,05) escala el pixel art** y puede dar píxeles de ancho desparejo que titilan al moverse. Es una excepción a la regla 10, aceptada para probar.
- **Error de Claude:** una línea suelta (`cat >` sin entrada) colgó el primer comando 5 minutos. No afectó al proyecto.

### Pendientes Código

- [ ] **S6: escribir el Plan 2** (datos y textos), con Opus 5.5 en esfuerzo high (`docs/00_log.md`).
- [x] Volver a comparar con la maqueta tras el arreglo de `background_sprite`: 99,3 %.
- [x] Commitear los `.uid` generados por Godot.
- [ ] Planes 3 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [x] **S5: ejecutar el Plan 1.**

### Pendientes Externos

- [ ] **Revisar la escena en Godot** (`docs/04`, C), sobre todo la cámara: si convence, se queda; si no, se apaga (*Look Enabled*) y se quita el parallax.
- [ ] **Probar el escalado a pantalla completa y decidir** si se queda Nearest (`docs/04`, D).
- [x] Termómetro: queda fuera del juego.
- [x] Sombra de la esquina superior derecha integrada en `background_sprite`.
- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Elegir una tipografía pixel (`docs/03` §10).
- [x] Push a GitHub de los commits de esta sesión (autorizado).

---

## Sesión 4 — 26 de octubre de 2026 (tarde) — Orden del arte, repositorio y registro de sesiones

### Realizado

- **Arte nuevo verificado contra el maestro:**
  - `background_sprite` (1280×720) va en (0, 0) y ya cubre la última fila de píxeles;
  - `exterior_sprite` (251×297) calza al 100 % con el hueco del vidrio, en (273, 121).
- **`art/` ordenado** (autorizado por Benja):
  - `arrrow_sprite` pasó a llamarse `arrow_sprite`;
  - el maestro y su PNG quedaron en `art/_layout/` (`scene_layout.*`), que Godot ignora;
  - se borraron los `.import` sobrantes;
  - Godot reimportó todo: 17 sprites, ninguno con error.
- **Plan 1 (`docs/07`) actualizado:**
  - fondo con `background_sprite`, ya no con el maestro;
  - exterior recortado al vidrio, con su propio parallax (±2, ±1 sobre la pared);
  - nombres nuevos y maqueta en `art/_layout/scene_layout.png`;
  - corregida la verificación de importación (las exitosas no escriben `valid`);
  - regla de commits agregada.
- **Nuevo `docs/00_log.md`:** registro de sesiones con la siguiente (S5), qué documentos son planes que se ejecutan, la secuencia S5 a S23 con modelo y esfuerzo, y los cambios a la secuencia.
- **`CLAUDE.md`:** leer `docs/00_log.md` al empezar y actualizarlo al cerrar; preguntar antes de cada commit; remoto de GitHub; ubicación de la maqueta.
- `art/positions.md` y `docs/06` §3 actualizados.
- **Primer commit y push** a `https://github.com/benjasaldias/SpookDial.git` (autorizado por Benja).

### Errores encontrados

- **`docs/07` esperaba `valid=true` en los `.import`**, pero las importaciones exitosas no escriben esa línea. Corregido.
- **`exterior_sprite` mide justo lo que el vidrio:** al moverse deja ver 1 a 2 px del exterior pintado en `window_sprite`. Es aceptable; si se nota, agrandarlo 8 px por lado (`art/positions.md`).

### Pendientes Código

- [ ] **S5: ejecutar el Plan 1** (`docs/07`), con Sonnet 5.5 en esfuerzo high y Godot cerrado (`docs/00_log.md`).
- [ ] Planes 2 a 9 según `docs/00_log.md`.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [x] Primer commit y push.
- [x] Ordenar `art/sprites/`.

### Pendientes Externos

- [ ] **Antes de S8 (2 de noviembre):** diseñar El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7.
- [ ] Godot: volver al proyecto de OneDrive en el Project Manager, si todavía no lo hiciste (`docs/04`, A).
- [ ] Arte para los planes 3 a 6: interfaz del chat y del cuaderno, barras de señal, celular sin la hora y dígitos LCD, diales rediseñados, mixer en piezas y celular ampliado (`docs/06` §3).
- [ ] Opcional: `exterior_sprite` y `background_sprite` con 8 px extra por lado.
- [ ] Elegir una tipografía pixel (`docs/03` §10).
- [x] `background_sprite` y `exterior_sprite`.
- [x] Crear el repositorio en GitHub.

---

## Sesión 3 — 26 de octubre de 2026 — Diseño cerrado, arte revisado y Plan 1

### Realizado

- **Decisiones de Benja** (en `CLAUDE.md` y en el diseño v2):
  - los amigos **nunca dicen el nombre** de la entidad; se identifica de memoria o **clickeando todas las características destacadas** (espera de unos 3 s);
  - se responde desde la página abierta del cuaderno;
  - cada regla marca la **acción correcta** y la **de mayor riesgo**, que da un video extra;
  - **no existe "Grabar"**;
  - la cuota la cubren los **envíos programados**;
  - si cualquiera de los 3 diales llega a 0, se pierde la noche;
  - el proyecto **se queda en OneDrive**.
- **"Grabar" corregido:** salió por error de una propuesta rechazada de la sesión 1. Se quitó del diseño v2, de `docs/02` y de `CLAUDE.md`.
- **Diseño v2:** §8 (identificación, preguntas, respuesta y reglas), §9 (consecuencias), §10 (diales y cuota), §12 (cuaderno) y §20 (nada por confirmar). `docs/02` reescrito.
- **Calendario recalibrado** en `docs/05` (vamos una semana atrás). El buscador por rasgos sale de la lista posterior a la v1, porque lo reemplazan las características clickeables.
- **Arte revisado:** los 15 archivos de `art/sprites/` se compararon píxel a píxel con el maestro, y las posiciones exactas quedaron en `art/positions.md`. Inventario y faltantes en `docs/06` §3.
- **Nuevo `docs/06_plan_v1.md`:** la v1 dividida en 9 planes, con arquitectura, criterios de cierre y arte faltante por plan.
- **Nuevo `docs/07_plan_escena_arte.md`:** el Plan 1 paso a paso (skill `superpowers:writing-plans`), en 14 tareas con código completo, 32 pruebas, comparación visual con la maqueta y prueba de escalado a 1080p.
- **Entorno:**
  - ruta de Aseprite corregida en `editor_settings-4.7.tres` (con respaldo previo);
  - los 16 `.aseprite` reimportados y verificados (animaciones y tamaños correctos);
  - copia de `C:\dev\spook-dial` borrada, tras confirmar que no tenía nada propio;
  - git reiniciado en OneDrive con su carpeta interna en `/mnt/c/dev/spook-dial.git`;
  - MCP `godot` configurado para la carpeta de OneDrive (y quitado de `C:\dev`).

### Errores encontrados

- **Los 16 `.aseprite` estaban con `valid=false`.** La ruta de Aseprite del paso B nunca se guardó en Godot. Corregida.
- **Godot no reintenta importaciones fallidas.** Borrar el `.md5` no basta: hay que borrar el `.import` (o el `.md5` y el `.res`). Anotado en `CLAUDE.md` y corregido en la Tarea 3 del Plan 1.
- **OneDrive interfiere con la edición:** varias ediciones respondieron "no such file", aunque el cambio quedó escrito. Anotado en `CLAUDE.md`.
- **"Grabar" se había colado en el diseño v2** sin que Benja lo aprobara. Corregido.
- **Pendiente de arte:**
  - el celular sigue con "00:00" dibujado;
  - los diales siguen con cara de reloj;
  - la ventana no tiene el exterior separado;
  - no existe `wall_sprite` (se usa el maestro como fondo provisional);
  - en `art/sprites/` sobran un PNG duplicado y un `icon.svg.import`.

### Pendientes Código

- [ ] **Siguiente sesión: ejecutar el Plan 1** (`docs/07`), con Godot cerrado durante los pasos sin interfaz.
- [ ] Primer commit y push cuando Benja cree el repositorio en GitHub (con su aprobación).
- [ ] Ordenar `art/sprites/` (`docs/06` §3) cuando Benja lo apruebe.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Planes 2 a 9: escribir cada uno en detalle al comenzar su semana (`docs/06` §2).
- [x] Corregir la ruta de Aseprite y verificar la importación (sesión 2).
- [x] Plan de implementación del Hito 1: reemplazado por los Planes 1 a 4 de `docs/06`.

### Pendientes Externos

- [ ] **Godot:** volver al proyecto de OneDrive en el Project Manager (`docs/04`, A).
- [ ] **Crear el repositorio privado en GitHub.**
- [ ] **Entidades:** las 3 primeras (El Tue Tué, La Calchona y El Trauco) con la plantilla nueva de `docs/02` §7. Hacen falta para la semana 2.
- [ ] **Arte para el Plan 1:**
  - `wall_sprite` (Background + Shading + Thermometer, idealmente 1296×736);
  - separar el exterior de la ventana.
- [ ] **Arte para los planes 3 a 5:**
  - interfaz del chat y del cuaderno;
  - barras de señal;
  - celular sin la hora y dígitos LCD;
  - diales rediseñados (`docs/06` §3).
- [ ] Aprobar el orden de `art/sprites/` y decidir si se renombra `arrrow_sprite`.
- [ ] Elegir una tipografía pixel (candidatas en `docs/03` §10).
- [ ] Sonido (semana 6).
- [x] Revisar el diseño v2 y responder sus puntos por confirmar.
- [x] Corregir la ruta de Aseprite: la corrigió Claude.

---

## Sesión 2 — 15 de octubre de 2026 (noche) — Decisiones, diseño v2 y cambio a C:\dev

### Realizado

- Benja respondió las 17 preguntas de la sesión 1 y 4 más (ubicación, cuota, identificación y diseño v2). Todas las decisiones quedaron en `CLAUDE.md`. Las más importantes:
  - acciones propias por entidad, con reglas estilo Keep Talking;
  - final único, con la cuota de contenido como condición para ganar cada noche;
  - señal por amigo con Audio Sync individual;
  - 7 entidades, con los Brujos de Chiloé solo en la historia;
  - el juego es estrictamente el escritorio;
  - entrega el **10 de diciembre**.
- Diseño v2 escrito en `spook_dial_design.md`. El original quedó en `spook_dial_design_v1.md`.
- `docs/02_bucle_central.md` reescrito: reglas por entidad, estática, señal por amigo, valores iniciales, plantilla de entidad, textos en CSV y modelo de datos.
- Nuevo `docs/05_plan_produccion.md`: alcance por prioridad (v1, prioridad 2 y lo de después), calendario al 10 de diciembre y riesgos.
- `docs/03_plan_arte.md` actualizado: plano de pared con parallax leve, `room_wall` y `room_desk`, perillas de los faders, barras de señal y calendario.
- `docs/01` marcado como histórico, con una tabla de qué pasó con cada propuesta. `docs/04` reescrito con el estado de cada paso.
- Proyecto copiado a `C:\dev\spook-dial`, sin `.godot/`. La copia de OneDrive queda como respaldo.
- Git inicializado en `C:\dev\spook-dial` (rama `main`, `core.filemode=false`), sin commits.
- Script `~/tools/godot-wsl.sh`: ejecuta el Godot de Windows desde WSL traduciendo las rutas.
- MCP `godot` configurado **solo para `C:\dev\spook-dial`** (scope local): `GODOT_MCP_ROOT=/mnt/c/dev` y `GODOT_EXECUTABLE=~/tools/godot-wsl.sh`. La configuración global, que usan los otros proyectos de `~/godot-games`, no se tocó.
- Verificado:
  - Aseprite Wizard 9.8.0 está instalado y activado, con SpriteFrames como importador por defecto;
  - el proyecto copiado **carga sin errores en Godot 4.7.2 con el plugin activado** (importación sin interfaz);
  - Aseprite 1.3.18.6 responde en la ruta de Steam;
  - el MCP resuelve la carpeta y el ejecutable correctos.
- Cargado el skill `superpowers:brainstorming`: el diseño v2 es su "spec" y queda esperando la revisión de Benja.

### Errores encontrados

- **La ruta de Aseprite no quedó guardada en Godot.** `editor_settings-4.7.tres` todavía tiene la por defecto (`C:\Steam\…`), así que importar `.aseprite` fallaría (`docs/04`, B).
- **Godot de Windows no puede abrir proyectos dentro de WSL** (su explorador no sale de C:). La copia de `~/godot-games/spook-dial` quedó desactualizada; no es la que Benja movió.
- **El servidor MCP llama a Godot con rutas de Linux**, que el ejecutable de Windows no entiende. Resuelto con `~/tools/godot-wsl.sh`.
- **`project.godot` tiene `aspect = expand`.** Se ajusta tras la prueba de escalado.

### Pendientes Código

- [x] Reconfigurar el MCP y hacer `git init` (sesión 1).
- [x] Actualizar `spook_dial_design.md` a v2 (sesión 1).
- [x] ~~Instalar Aseprite Wizard desde GitHub~~: lo instaló Benja.
- [ ] Borrar `~/godot-games/spook-dial` cuando Benja lo pida.
- [ ] Primer commit y push cuando Benja cree el repositorio en GitHub (con su aprobación).
- [ ] Cuando Benja apruebe el diseño v2: plan de implementación del Hito 1 con `superpowers:writing-plans`.
- [ ] Prueba de escalado a 1080p (×1,5): filtro Nearest contra un shader de escalado suave, más el parallax de la ventana y la pared. Con el resultado, fijar la pantalla en `project.godot`.
- [ ] Estructura de carpetas y autoloads (`GameState`, `EventBus`, `AudioManager`, `SaveManager`).
- [ ] Modelo de datos (`docs/02` §10) y carga de textos desde `data/text/*.csv`, con prototipos `[PROTO]`.
- [ ] Hito 1, prototipo del bucle central (`docs/05`, v1 #1 y #2) con 3 entidades y arte provisional.
- [ ] Shader de contorno para el resaltado al pasar el mouse, y detección de clic por píxel.

### Pendientes Externos

- [ ] **Revisar el diseño v2** (`spook_dial_design.md`) y decidir los 3 puntos "por confirmar" de su §20.
- [ ] `docs/04`:
  - A: cambiarse a `C:\dev` en Godot y en VS Code;
  - B: corregir la ruta de Aseprite;
  - C: prueba con un archivo.
- [ ] Crear el repositorio privado en GitHub.
- [ ] Arte P0:
  - corregir los 2 errores del maestro;
  - separar los planos (`room_wall` con 8 px extra por lado, `room_desk` y `exterior`) y los objetos (`docs/03` §5 y §7);
  - dejar en blanco la pantalla del PC y la hora del celular;
  - anotar las posiciones en `art/positions.md`.
- [ ] Arte P1: interfaz del chat, entradas con barras de señal, avatares, íconos, diales rediseñados, mixer en piezas (con las perillas de los faders), LED, dígitos LCD y cursor.
- [ ] Entidades: El Tue Tué, La Calchona y El Trauco con la plantilla de `docs/02` §7 **antes del 25 de octubre**; las 7 antes del 18 de noviembre.
- [ ] Elegir una tipografía pixel con ñ, tildes, ¿ y ¡ (candidatas en `docs/03` §10).
- [ ] Sonido (desde el Hito 3): lista de efectos y ambientes, y bibliotecas con licencia clara.
- [x] Responder las preguntas abiertas.
- [x] Decidir la ubicación del proyecto.
- [x] Recargar VS Code: los plugins y el MCP se cargaron en esta sesión.
- [x] Confirmar la fecha de entrega: 10 de diciembre, completo y jugable.

---

## Sesión 1 — 15 de octubre de 2026 — Planificación (sin código)

### Realizado

- Lectura completa de `spook_dial_design.md` y análisis crítico en `docs/01_analisis_diseno.md`: 14 contradicciones, 14 debilidades, alcance recortado, calendario de 11 semanas y 17 preguntas abiertas.
- Análisis del arte, del PNG y del archivo maestro `SpookDial_Sprites.aseprite`, leído sin modificarlo:
  - 20 capas con sus coordenadas;
  - 2 frames y sus diferencias;
  - el arte es nativo a 1280×720, con detalle de 1 px y 268 colores.
- Diseño del bucle central (chat, cuaderno-buscador, preguntas de seguimiento y "Pedir contenido") en `docs/02_bucle_central.md`.
- Plan de arte en `docs/03_plan_arte.md` e instrucciones de Godot en `docs/04_instrucciones_godot.md`.
- Archivos creados: `CLAUDE.md`, `resumen.md`, `docs/` (con `.gdignore`), `art/_layout/.gdignore` y `art/positions.md` (con las coordenadas actuales y el centro de cada dial).
- Decisiones de Benja:
  - si un amigo muere, se reinicia la noche;
  - se mantiene la resolución de 1280×720;
  - Audio Sync se juega en el mixer;
  - el termómetro es decorativo;
  - la entrega es en unos 2,5 meses, y Benja trabaja solo con Claude.
- Verificado:
  - Godot 4.7.2 (Windows) se puede ejecutar desde WSL;
  - el servidor MCP `godot` arranca sin errores;
  - existe Aseprite Wizard v9.8.0 para Godot 4 (pide 4.3 o más; no confirma 4.7).

### Errores encontrados

- **Arte:** la cel de `Background` está en y = −2, así que las filas y = 718–719 quedan **transparentes** en ambos frames (también en el PNG exportado).
- **Arte:** en el frame 2, el brillo verde del LED del micrófono (36 px semitransparentes en x 856–861, y 590–595) está pintado en la capa `SoundMixer` y no en `Microphone`.
- **Arte:** el frame 2 mezcla cambios independientes: el color de las entradas del PC, los ojos de la ventana, la franja de luz de luna en el escritorio, el sombreado del mixer y el LED del micrófono. En una sola línea de tiempo no se pueden animar por separado; se resuelve separando archivos (`docs/03`).
- **Arte y diseño:** los diales parecen relojes (tienen 12 marcas) y se distinguen solo por color (verde, rojo y amarillo). Es un problema de lectura y de daltonismo.
- **Diseño:** 14 contradicciones o vacíos en `spook_dial_design.md` (muerte, Sanity, Trust, contenido extra, Connection, Audio Sync, chat "gibberish", objetos, entidades, finales…). El detalle y la resolución están en `docs/01` §1.
- **Entorno:** el proyecto vive en OneDrive (riesgo de conflictos de sincronización con `.godot/`) y no tiene git.
- **Entorno:** hay una copia duplicada del proyecto en `~/godot-games/spook-dial`. El MCP `godot` solo puede trabajar ahí (`GODOT_MCP_ROOT`), no en la carpeta real.
- **Entorno:** los plugins `superpowers` y `godot` se instalaron minutos antes de la sesión y no se cargaron, igual que las herramientas del MCP `godot`. Hay que recargar VS Code.

### Pendientes Código

- [ ] Cuando Benja decida la ubicación del proyecto: reconfigurar el MCP `godot` (`GODOT_MCP_ROOT`), hacer `git init` con su aprobación y borrar la copia duplicada.
- [ ] Si Benja no pudo instalar Aseprite Wizard desde AssetLib: instalar la v9.8.0 desde GitHub en `addons/`.
- [ ] Prueba de escalado a 1080p (×1,5): filtro Nearest contra un shader de escalado suave, más el parallax de la ventana. Con el resultado, fijar la configuración de pantalla en `project.godot`.
- [ ] Estructura de carpetas y autoloads (`GameState`, `EventBus`, `AudioManager`, `SaveManager`).
- [ ] Modelo de datos como Resources (`TraitData`, `EntityStateData`, `EntityData`, `FriendData`, `NightData`), según `docs/02` §13.
- [ ] Hito 1, prototipo del bucle central con arte provisional:
  - escena del escritorio con objetos clickeables;
  - panel de chat;
  - generador de solicitudes y temporizadores;
  - cuaderno-buscador con marcadores;
  - medidores y reloj de la noche;
  - victoria, derrota y reinicio con pantalla explicativa.
- [ ] Shader de contorno para el resaltado al pasar el mouse, y detección de clic por píxel.
- [ ] Actualizar `spook_dial_design.md` a v2 cuando Benja responda las preguntas, con su aprobación.

### Pendientes Externos

- [ ] **Responder las preguntas abiertas** (`docs/01` §7).
- [ ] Decidir la ubicación del proyecto (recomendado: `C:\dev\spook-dial`, fuera de OneDrive) y si se usa GitHub (`docs/04`, A).
- [ ] Recargar VS Code (*Developer: Reload Window*) para cargar `superpowers`, `godot` y el MCP.
- [ ] Godot: instalar y configurar Aseprite Wizard, y hacer la prueba (`docs/04`, B a F).
- [ ] Arte P0:
  - corregir los 2 errores del maestro;
  - separar los planos y los objetos (`docs/03` §5 y §7);
  - dejar en blanco la pantalla del PC y la hora del celular;
  - separar el exterior de la ventana;
  - anotar las posiciones en `art/positions.md`.
- [ ] Arte P1: interfaz del chat, entradas del PC, avatares, íconos de acción y de rasgo, diales rediseñados con íconos, mixer en piezas, LED genérico, dígitos LCD y cursor.
- [ ] Escritura: bestiario de 6 entidades con la plantilla de `docs/02` §14, y las voces de los amigos.
- [ ] Elegir una tipografía pixel con ñ, tildes, ¿ y ¡ (candidatas en `docs/03` §10).
- [ ] Confirmar la fecha exacta de entrega y qué exige.
- [ ] Sonido (desde el Hito 3): lista de efectos y ambientes, y bibliotecas con licencia clara.
