# Arte pendiente

Todo el arte que falta para la v1, en un solo lugar. Actualizado el 2 de noviembre de 2026 (sesión 14).

- **Cómo usar esta lista:** dibuja en el orden que prefieras y avísale a Claude cuando una pieza esté lista. La integración se hace en una sesión aparte.
- **Mientras tanto:** todo lo marcado "provisional" ya funciona en el juego con un reemplazo hecho en Godot, así que nada bloquea la programación.
- **El arte se congela el 25 de noviembre** (`docs/05`).
- **Detalle técnico** (separar en Aseprite, tags y carpetas): `docs/03_plan_arte.md`. Estado de los archivos actuales: `docs/06_plan_v1.md` §3.

## Reglas para todo el arte

- 1 píxel de arte = 1 unidad de Godot, con la paleta actual (268 colores). Nada se escala, salvo las **vistas ampliadas**, que se pueden dibujar a la mitad y mostrar a ×2 exacto.
- Archivos `.aseprite` en `art/sprites/` (o en las carpetas de `docs/03` §8), con nombres en inglés y en `snake_case`. Las capas de referencia llevan el prefijo `ref_` y van ocultas.
- Texto: no hace falta dibujarlo. Los nombres, números y la hora los escribe Godot con la fuente Departure Mono.
- Si un objeto cambia de posición, anota la nueva en `art/positions.md`.

---

## 1. Alta: reemplaza piezas provisionales que ya están en el juego

| Pieza | Tamaño | Qué incluye | Qué hay hoy |
| --- | --- | --- | --- |
| **Mixer visto desde arriba** (Audio Sync, Plan 6) | 440×430, o 220×215 a ×2 | El cuerpo visto desde arriba; **dos VU-metros azules** (el de la izquierda muestra el ritmo de Matías y el de la derecha, el del amigo), con su aguja aparte o en frames por nivel; la perilla de un fader (Godot la usa en los 3 canales y la sube o baja según la señal); un LED por canal; una fila de luces para el ritmo (8 o 16, encendida y apagada). Las perillas y los botones de adorno, como en tu mixer del escritorio. | Dibujo provisional en Godot (`scenes/ui/mixer_view.tscn`). Ver `C:\dev\capturas\plan6_mixer.png`. |
| **Celular ampliado** (redes sociales, Plan 6) | 260×520, o 130×260 a ×2 | El celular de frente, con la pantalla. Decide si el feed es: (a) **12 publicaciones** sueltas (imagen de unos 212×140 cada una; Godot pone el autor, el texto y los "me gusta"), o (b) **una animación del scroll**, que avanza con la rueda del mouse. | Feed provisional en Godot (`scenes/ui/phone_view.tscn`), con paisajes de color. Ver `C:\dev\capturas\plan6_phone.png`. |
| **Barras de señal** de las entradas del PC | Unos 19×12 | 6 estados: de 0 a 5 barras. Que se distingan llenas de vacías sin depender del color. | Rectángulos dibujados por Godot. |
| **Diales rediseñados** | Como `dial_sprite` (112×113) | Cara de manómetro con un ícono para cada uno (Connection, Sanity y Trust) y un LED de alerta. La aguja sigue siendo `arrow_sprite`. | `dial_sprite` con cara de reloj. |
| **Celular del escritorio sin la hora** y **dígitos LCD** | Como `phone_sprite` (86×55); los dígitos, una tira "0123456789:" | El celular sin el "00:00" pintado. Los dígitos, del alto que tiene la hora dibujada hoy. | Un parche azul tapa la hora pintada y Godot escribe encima. |
| **Interfaz del cuaderno** | La página mide 449×696 (como `screen_sprite`) y va a la derecha | La página (9-slice), las pestañas del índice y **un boceto por entidad**, de unos 96×96 (7 en total). | Tema provisional de papel en Godot (`scenes/ui/notebook_theme.tres`), sin bocetos. |
| **Pantallas de victoria y derrota** | 1280×720 (o un marco centrado) | Fondo o marco para "Llegaste a las 06:00" y "Perdiste la noche". El texto lo pone Godot. | Un fondo oscuro con texto. |

## 2. Media: piezas de las entradas del PC y del escritorio

| Pieza | Tamaño | Qué incluye | Qué hay hoy |
| --- | --- | --- | --- |
| Íconos de estado de las entradas | 12 a 16 px, en una grilla de 16×16 | Conectado, desconectado, esperando, herido, aturdido y video. | Godot lo dice con texto ("Sin señal", "Aturdido 12", "Video 12"). |
| Marcas de vida de las entradas | Unos 6×10 | Llena y vacía. | Rectángulos de Godot. |
| Fondo neutro de las entradas | 243×26 | Un fondo que Godot tiñe para alerta, sin señal o seleccionada. **Ojo:** hoy, en el frame rojo de alerta, los segundos del temporizador tocan el ícono ⚠; si rehaces ese frame, deja libres unos 8 px a la derecha. | `entry_sprite` (`idle` y `warning`). |
| Ícono del contador de videos | Pequeño | Va junto a "Videos: 1 de 3" en el PC. | Solo texto. |
| Luces del PC y del escritorio | Como en el maestro | `pcLightOver`, `pcLightUnder` y `pcDesklight` como archivos aparte, para que Godot cambie su intensidad y color (Plan 7). | Pintadas en el fondo. |
| LED genérico | Unos 8×8 | Encendido y apagado. Se reutiliza en el micrófono y los diales. | El brillo del micrófono está pintado. |
| Avatares de los amigos | Unos 24×24 | 3 amigos × 3 expresiones: normal, asustado y herido. | No hay avatares: el chat muestra el nombre en su color. |
| Cursor | 16×16 o 32×32 | Normal y mano. | El cursor del sistema. |

## 3. Para los planes 7 y 8

| Pieza | Para qué | Notas |
| --- | --- | --- |
| **Screamers** | Plan 7 | Manos o un rostro que tapan la pantalla (2 o 3 frames), 1 o 2 jumpscares cortos y una mancha de tinta que tapa las reglas del cuaderno. |
| Animación `scare` de las cortinas | Plan 7 | Un screamer ambiental (3 a 6 frames). |
| Publicaciones perturbadoras del celular | Plan 7 | 3 de las 12, para cuando Sanity está baja. Depende de lo que elijas en el celular ampliado. |
| **Menú principal y logo** | Plan 8 | El logo "Spook Dial" y la escena del escritorio con otra iluminación. |
| Pantalla entre noches | Plan 8 | La página del canal, con el contenido de la noche. |

## 4. Opcional (pulido, si sobra tiempo)

- El chat: burbujas, botones en 4 estados, pestañas y "escribiendo…" en 3 frames. El estilo de terminal hecho en Godot ya funciona, así que esto es solo si quieres reemplazarlo.
- `exterior_sprite` y `background_sprite` con 8 px más por lado, para que la cámara se mueva más.
- `blink` de los ojos de la ventana y `twinkle` de la estrella.
- La franja de luz de luna como archivo aparte.
- Manchas de humedad que crecen noche a noche.
- Cinemáticas opcionales (prioridad 2): una ilustración por escena.

## Ya no hace falta

- Las piezas del mixer del escritorio (`mixer_vu` y `mixer_fader_knob`): Audio Sync se juega en la vista desde arriba, así que `mixer_sprite` puede quedar de una sola pieza.
- El termómetro, el ícono "Grabar" y el de la quinta pregunta: se eliminaron del juego.
