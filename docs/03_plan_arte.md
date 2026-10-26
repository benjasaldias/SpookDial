# Plan de arte: del archivo con capas a sprites animados en Godot

Respuesta al objetivo 2 de la sesión 1. Se basa en una lectura (sin modificarlo) de `C:\Users\benja\OneDrive\Desktop\SpookDial_Sprites.aseprite`.

> **Estado al 26 de octubre:** Benja ya separó 15 archivos en `art/sprites/`, con nombres propios (`curtains_sprite`, `pc_sprite`, etc.) en vez de los que proponía §5. El inventario vigente, lo que falta y las posiciones están en `docs/06_plan_v1.md` §3 y en `art/positions.md`. Este documento sigue sirviendo para las reglas del pipeline (§2), el parallax (§4) y el arte nuevo (§6).

---

## 0. Respuesta corta

**Sí, hay que separar.** En Aseprite, todas las capas de un archivo comparten la misma línea de tiempo. Por eso, dos cosas que se animan a distinto ritmo (los ojos de la ventana y el LED del mixer) no pueden vivir en el mismo archivo.

La regla:

- **Todo lo que se anima por su cuenta, se mueve o se clickea va en su propio archivo**, con sus propios tags.
- Lo que nunca cambia se agrupa en un plano estático.

**Corrección a tu idea de las entradas del PC.** Sí deben ser independientes, pero **no como sprites del PC ni como animaciones de Aseprite**. Son interfaz de Godot: una escena `ChatEntry` repetida 3 veces, donde el nombre, el temporizador y el parpadeo los hace Godot. Tú dibujas solo las piezas: el fondo, los íconos de estado y los avatares.

**Muchas de las animaciones que imaginas no hay que dibujarlas.** Las agujas, la vibración del celular, el parpadeo de luces, el resaltado al pasar el mouse, los fundidos y el vaivén de las cortinas los hace Godot (§2, regla 2).

---

## 1. Lo que encontré en tu archivo

`SpookDial_Sprites.aseprite`: 1280×720, 20 capas y 2 frames de 100 ms. El dibujo es nativo a 1280×720, con detalle de 1 px y 268 colores.

Coordenadas de cada capa: x, y es la esquina superior izquierda del contenido, en el frame 1.

| Capa | x | y | Ancho | Alto | Notas |
| --- | --- | --- | --- | --- | --- |
| Background | 0 | −2 | 1280 | 720 | Desplazada 2 px hacia arriba (error 1) |
| Window | 266 | 114 | 265 | 311 | Marco y exterior juntos: hay que separarlos |
| Shadow | 300 | 172 | 177 | 237 | Silueta con ojos; los ojos cambian en el frame 2 |
| GlassPane | 273 | 121 | 251 | 297 | |
| Curtains | 219 | 92 | 374 | 352 | |
| pcDesklight (oculta) | 465 | 554 | 363 | 115 | Luz |
| Desk | 0 | 505 | 1280 | 213 | La franja de luz de luna cambia en el frame 2 |
| Notebook | 1017 | 562 | 146 | 78 | |
| Microphone | 830 | 571 | 85 | 98 | |
| Phone | 357 | 618 | 86 | 55 | La hora "00:00" está dibujada |
| SoundMixer | 130 | 565 | 210 | 82 | En el frame 2 tiene píxeles del LED del micrófono (error 2) |
| Cables | 241 | 503 | 659 | 185 | |
| pcLightUnder (oculta) | 484 | 414 | 309 | 172 | Luz semitransparente |
| PC | 479 | 433 | 322 | 229 | Las 3 entradas están dibujadas y cambian de color en el frame 2 |
| pcLightOver (oculta) | 443 | 384 | 387 | 200 | Luz semitransparente |
| Dials | 840 | 89 | 112 | 372 | |
| Arrows | 889 | 102 | 16 | 306 | Las 3 agujas en una sola capa |
| Thermometer | 49 | 230 | 13 | 55 | **Fuera del juego** (decisión de Benja, 26-10-2026) |
| Shading | 0 | 0 | 1280 | 593 | Casi todo está en x ≥ 960 y no tapa ningún objeto: se puede fusionar con el fondo |
| Guidelines (oculta) | 0 | 0 | 1280 | 720 | Guías de perspectiva |

**Datos útiles para la interfaz:**

- La zona negra de la pantalla del PC va aproximadamente de x 510 a 770 y de y 438 a 568.
- Las entradas dibujadas miden 243×25 px y empiezan en x 518, en y 454, 494 y 534.

### Errores

1. **`Background` está en y = −2**, así que las filas y = 718–719 quedan transparentes (se nota en el PNG exportado). `Desk` tampoco las cubre, porque termina en y = 717.
   - Arreglo: pinta esas 2 filas en `Desk`, continuando el borde frontal oscuro.
   - No muevas `Background`: desalinearía la pared con el resto.
2. **En el frame 2, el brillo verde del LED del micrófono** (x 856–861, y 590–595) está en la capa `SoundMixer`. Bórralo de ahí: el LED será un sprite propio.
3. **El frame 2 mezcla 5 cambios independientes:** las entradas del PC, los ojos, la franja de luz de luna, el sombreado del mixer y el LED. Esto es justo el problema que intuiste.
   - Anota para qué era cada cambio y después **borra el frame 2 del maestro**.
   - Cada cambio pasa a su propio archivo o a Godot (tabla de §5).

---

## 2. Reglas del pipeline

1. **Un archivo por cada cosa que se anima, se mueve o se clickea por separado.**
2. **Si cambia la forma → Aseprite. Si cambia la posición, la rotación, la escala, el color o la opacidad → Godot.**
   - Lo hace Godot: agujas, vibración del celular, parpadeo de LEDs y pantallas, luces que titilan o cambian de color según la entidad, resaltado al pasar el mouse, fundidos, vaivén suave de las cortinas (con un shader) y sacudidas de pantalla.
   - Lo dibujas en Aseprite: ojos que parpadean, la cortina que se agita en un screamer, expresiones de los avatares, el "escribiendo…", los niveles de los VU-metros y los jumpscares.
3. **El texto, los números y la interfaz viva no se dibujan en la escena.**
   - La pantalla del PC queda vacía: las entradas las arma Godot.
   - La pantalla del celular también: Godot escribe la hora con una fuente de dígitos que dibujas tú.
4. **No dibujes estados de "mouse encima" para los objetos.** Un shader de contorno los genera. Los botones de la interfaz sí pueden tener estados dibujados.
5. **Pinta lo que queda detrás de lo que se mueve o desaparece:**
   - la pared y la ventana detrás de las cortinas;
   - el exterior detrás de la silueta;
   - la cara del dial debajo de la aguja;
   - el escritorio bajo el celular, que vibra.
6. **El mismo grid para todo: 1 píxel de arte = 1 unidad de Godot.** Nada se escala en Godot, salvo las vistas ampliadas a ×2 exacto (el mixer y el celular ampliados).
7. **Los planos estáticos conservan el lienzo completo** (1280×720; el de la pared, con 8 px extra por lado), así quedan alineados sin medir nada. Los objetos se recortan y se anota su posición.
8. **Las luces son sprites aparte** (tus capas `pcLight*` ocultas). Godot les cambia la intensidad y el color, para parpadeos y para el color de cada entidad. Antes de retocarlas, pruébalas en Godot con el modo de mezcla "Add".

---

## 3. Resolución (decidido: 1280×720)

- Sigues dibujando igual: 1 píxel es 1 píxel, sin mezclar tamaños de píxel. La interfaz también se dibuja a esa escala.
- El juego escala ×2 en 1440p y ×3 en 4K, y esas dos se ven perfectas. En 1080p escala ×1,5, y eso se resuelve en Godot: hay una prueba pendiente entre el filtro Nearest y un shader de escalado suave. No requiere nada de ti.
- **Para animar:** a esta resolución, cada frame cuesta unas 4 veces más que a 640×360. Por eso las animaciones dibujadas son pocas y pequeñas, y todo lo demás lo mueve Godot.

---

## 4. Parallax: la ventana y, levemente, la pared (reemplazado)

> **26-10-2026:** reemplazado por una cámara con zoom leve que mira hacia el mouse (`CLAUDE.md`, Decisiones). Esta sección queda como referencia.

| Plano | Qué contiene | Movimiento con el mouse |
| --- | --- | --- |
| Exterior | Cielo, luna, árboles y la silueta de la ventana | ±6 px |
| Pared | Pared, marco de la ventana, vidrio, cortinas, diales con sus agujas, termómetro y sombreado | ±2 a 3 px |
| Escritorio | Escritorio, cables y todos los objetos clickeables | Fijo |

**Por qué así:**

- Los objetos clickeables no se mueven mientras apuntas.
- Casi no hay temblor a ×1,5, porque lo que se mueve es oscuro o se mueve muy poco.
- La profundidad se percibe por el movimiento relativo entre los tres planos.

**Lo que tienes que hacer:**

- Separar el exterior de la capa `Window` y pintarlo **16 px más grande que el vidrio por cada lado**.
- Darle al plano de la pared **8 px extra por cada lado** (lienzo de 1296×736, que Godot coloca en −8, −8) y pintar la pared hasta ese borde. El escritorio tapa su borde inferior.

**Después de la entrega (opcional):**

- una franja de primer plano (el borde del escritorio) que se mueva ±8 px, con un lienzo de 1312 px de ancho;
- partículas de polvo, que las hace Godot.

---

## 5. Mapa de separación

Prioridades:

- **P0**: antes del prototipo.
- **P1**: semanas 1 a 4.
- **P2**: semanas 5 y 6.
- **P3**: pulido.

| Archivo nuevo | Sale de | Tipo | Tags (animaciones) | Lo que hace Godot | Prio. |
| --- | --- | --- | --- | --- | --- |
| `scene/room_wall.aseprite` (1296×736) | Background, el marco de Window, GlassPane, las caras de Dials, Thermometer y Shading | Estático | — | Parallax leve | P0 |
| `scene/room_desk.aseprite` (1280×720) | Desk y Cables | Estático | — | — (fijo) | P0 |
| `scene/exterior.aseprite` (1280×720) | El interior de Window: cielo, luna, estrella y árboles | Estático | (P3: `twinkle` de la estrella) | Parallax | P0 |
| `objects/window_shadow.aseprite` | Shadow | Animado | `idle`; `blink` (3 frames) | Aparecer, desaparecer y parallax | P1 (`blink` en P3) |
| `objects/curtains.aseprite` | Curtains | Estático + screamer | `idle` (1 frame); `scare` (3–6 frames) | Vaivén con shader; se mueve con la pared | P0 (`scare` en P3) |
| `objects/laptop.aseprite` | PC **sin las 3 entradas** | Estático | — | — (lo clickeable son las entradas, que muestran estado, señal y temporizador) | P0 |
| `objects/light_screen_over.aseprite`, `light_screen_under.aseprite`, `light_desk.aseprite` | pcLightOver, pcLightUnder, pcDesklight | Luces | — | Intensidad, parpadeo y color por entidad | P1 |
| `objects/light_moon.aseprite` | La franja de luz de luna de Desk | Luz | — | Se apaga cuando la silueta tapa la luna | P2 |
| `objects/mixer_base.aseprite` | SoundMixer, sin LED ni VU encendidos | Estático | — | Contorno (es clickeable) | P1 |
| `objects/mixer_vu.aseprite` | Los displays del mixer | Por niveles | `level` (5 frames: 0 a 4) | Elige el frame según el aplauso | P1 |
| `objects/mixer_fader_knob.aseprite` | La perilla de un fader | Estático | — | Se usa 3 veces (un canal por amigo). Godot la sube o la baja según la señal del amigo y resalta el canal elegido. | P1 |
| `objects/led.aseprite` | — (nuevo y genérico) | Estático | — | Color, encendido y parpadeo. Se reutiliza en el mixer, el micrófono y los diales | P1 |
| `objects/phone.aseprite` | Phone **sin la hora** | Estático | — | Vibración, brillo de notificación y contorno | P0 |
| `ui/lcd_digits.aseprite` | Los dígitos del celular, redibujados en una tira "0123456789:" | Fuente | — | Fuente de imagen para la hora | P1 |
| `objects/microphone.aseprite` | Microphone, sin el brillo del LED | Estático | — | — | P1 |
| `objects/notebook_closed.aseprite` | Notebook | Estático | (P3: `scare`, hojas que se agitan) | Contorno | P0 |
| `objects/needle.aseprite` | **Una** aguja de Arrows, en gris claro, apuntando hacia arriba | Estático | — | Rotación y color (se usa 3 veces); se mueve con la pared | P0 |

**Sobre la aguja:** deja el eje de giro en un píxel fácil de ubicar (por ejemplo, el centro de la base) y anótalo en `art/positions.md`.

**Lo que sale del arte porque lo hace Godot:** las 3 entradas azules del PC, la hora "00:00", el color de las agujas y el brillo de los LEDs.

---

## 6. Arte nuevo que falta

### P1 (semanas 1 a 4, para el prototipo jugable)

- **Chat:**
  - panel (9-slice);
  - burbujas de amigo y de Matías (9-slice);
  - botón en 4 estados: normal, mouse encima, presionado y desactivado;
  - pestaña de amigo;
  - barra de tiempo (fondo y relleno);
  - "escribiendo…" en 3 frames.
- **Entradas del PC (243×25):**
  - un fondo neutro, que Godot tiñe para alerta, desconectado o seleccionado;
  - íconos de estado de 12 a 16 px: conectado, desconectado, esperando, herido, aturdido y video;
  - barras de señal en 5 niveles (de 0 a 4 barras).
- **Contador de videos** para la pantalla del PC: un ícono pequeño; el número lo escribe Godot.
- **Avatares:** 3 amigos × 3 expresiones (normal, asustado, herido), de unos 24×24.
- **Íconos:** Grabar y las 5 preguntas. Las acciones propias de cada entidad pueden ir solo con texto.
- **Cuaderno:**
  - página (9-slice);
  - pestañas del índice;
  - 7 bocetos de entidades, de unos 96×96.
- **Diales** rediseñados como manómetros con ícono (`docs/01` §3.12).
- **Cursor:** normal y mano.

### P2 (semanas 5 y 6)

- **Celular ampliado** en vertical (unos 180×320) y 12 publicaciones simples (unos 120×120). Tres de ellas, perturbadoras, para cuando Sanity está baja.
- **Pantalla entre noches:** la página del canal.
- **Menú principal:** el logo "Spook Dial" y la escena con otra iluminación.
- **Screamers:**
  - manos o un rostro que tapan la pantalla (2 o 3 frames);
  - 1 o 2 jumpscares cortos;
  - una mancha de tinta para el cuaderno.
- **Pantallas de victoria y de derrota.**
- **Cinemáticas opcionales** (prioridad 2, solo si alcanza): una ilustración por escena.

### P3 (pulido, semanas 7 y 8)

- `scare` de las cortinas, `blink` de los ojos y `twinkle` de la estrella.
- La luz de luna.
- Manchas de humedad que crecen noche a noche ("la protección se debilita").

---

## 7. Paso a paso para separar (en Aseprite)

**Antes de empezar:** los archivos nuevos se guardan en `art/sprites/` del proyecto (`C:\Users\benja\OneDrive\Documents\spook-dial`).

### Paso 1: respaldo y correcciones del maestro

1. Duplica `SpookDial_Sprites.aseprite` como `SpookDial_Sprites_backup_2026-10-15.aseprite`.
2. Corrige los errores 1 y 2 de §1. Anota para qué era el frame 2 y bórralo.
3. Guarda el maestro como `art/_layout/scene_layout.aseprite`.
   - Es tu maqueta: lo usas para ver la composición completa.
   - Godot no lo importa, porque la carpeta `art/_layout/` tiene un archivo `.gdignore` (ya está creado).

### Paso 2: un archivo por objeto

Repite esto para cada fila de §5 que no sea un plano:

1. Con el maestro abierto: *File > Save Copy As…* → el nombre de la tabla, en su carpeta. Así el maestro queda intacto.
2. Abre la copia y borra todas las capas menos las del objeto.
   - Si quieres contexto mientras animas, deja una capa con la escena aplanada, ocúltala y llámala `ref_scene`. Godot la ignorará si está oculta (`docs/04`, F).
3. Haz una selección rectangular alrededor del objeto, con un margen de 4 a 8 px (más si la animación se sale del contorno).
   - Mientras la dibujas, la barra de estado muestra su posición y su tamaño.
   - **Anota la X y la Y** de la esquina superior izquierda en `art/positions.md`.
   - Si prefieres exactitud, usa una *Slice*: su ventana de propiedades muestra x, y, ancho y alto.
4. *Sprite > Crop*.
5. Crea los tags de la tabla.
   - Para animaciones que no se repiten (`scare`), en las propiedades del tag pon *Repeat* = 1.
   - La duración de cada frame (en ms) se define en Aseprite, y Godot la respeta.
6. Guarda. Godot reimporta solo cada vez que guardas.

### Paso 3: los planos estáticos

1. *File > Save Copy As…* → `scene/room_wall.aseprite`. Borra todo menos las capas de la pared (tabla de §5).
2. En ese archivo: *Sprite > Canvas Size* y agrega 8 px por cada lado (queda de 1296×736). Pinta la pared hasta el nuevo borde.
3. En `Window`, corta el interior (cielo, luna y árboles) y llévalo a `scene/exterior.aseprite`, agrandándolo 16 px por lado. En `room_wall`, el vidrio queda transparente.
4. Repite el paso 1 para `scene/room_desk.aseprite`, dejando solo Desk y Cables, con el lienzo de 1280×720.
5. Borra las 3 entradas del PC y la hora del celular, si quedaron en algún plano.
6. Pinta lo que quedaba detrás de lo que se mueve (§2, regla 5).

### Paso 4: paleta

Guarda tu paleta actual (268 colores) como preset, para que todo el arte nuevo use los mismos colores.

---

## 8. Convenciones

- **Carpetas:**
  - `res://art/scene/` para los planos;
  - `res://art/objects/`;
  - `res://art/ui/`;
  - `res://art/screamers/`;
  - `res://art/_layout/` para la maqueta, que no se importa.
- **Nombres de archivo** en inglés y en `snake_case`. Las capas de referencia llevan el prefijo `ref_` y van ocultas.
- **Tags** en inglés: `idle`, `scare`, `blink`, `level`, `on`, `off`.
- **Íconos pequeños** en una grilla de 16×16, en un solo archivo por familia. Claude los recorta en Godot.
- **Paneles 9-slice:** un archivo por panel.

---

## 9. Calendario de arte

| Semana | Arte |
| --- | --- |
| 0 (15–18 oct) | Errores del maestro y separación P0: planos, cortinas, laptop, celular, cuaderno y aguja. Uno o dos días. |
| 1–2 (19 oct – 1 nov) | Interfaz del chat, entradas con barras de señal, avatares, íconos y diales rediseñados. |
| 3–4 (2–15 nov) | Mixer en piezas, LED, luces, dígitos LCD, interfaz del cuaderno, bocetos, silueta de la ventana y cursor. |
| 5 (16–25 nov) | Celular ampliado y publicaciones, pantalla entre noches, menú y logo, screamers, victoria y derrota. **El 25 de noviembre se congela el arte.** |
| 6–7 (26 nov – 5 dic) | Solo correcciones y pulido P3 si sobra tiempo. Cinemáticas opcionales (prioridad 2). |

---

## 10. Tipografía

**Requisitos:**

- ñ, á é í ó ú ü, ¿ y ¡;
- que se lea bien en párrafos, porque el juego tiene mucho texto;
- una licencia que permita usarla en el juego.

**Candidatas** (verifica la licencia y los caracteres antes de elegir): *Pixel Operator*, *monogram*, *m5x7* / *m6x11* y *Silver*.

**Tamaño:** siempre un múltiplo entero de la grilla de la fuente. Por ejemplo, una fuente de grilla 8 px se usa a 16, que en 1080p queda a 24: ×3 exacto.

**Opcional:** una segunda fuente "manuscrita" para el cuaderno.
