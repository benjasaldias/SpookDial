# Arte pendiente

Todo el arte que falta para la v1, en un solo lugar. Actualizado el 10 de noviembre de 2026 (sesión S21d).

- **Cómo usar esta lista:** dibuja en el orden que prefieras y avísale a Claude cuando una pieza esté lista. La integración se hace en una sesión aparte.
- **Mientras tanto:** todo lo marcado "provisional" ya funciona en el juego con un reemplazo hecho en Godot, así que nada bloquea la programación.
- **Lo que dibujó Claude** (10 de noviembre) está en `art/ui/` y lo genera `tools/make_ui_art.py`, con la paleta de tus sprites. Ya no es provisional, pero lo puedes redibujar: deja tu PNG con el mismo nombre en `art/ui/` y no vuelvas a correr el script, porque lo pisaría.
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
| ~~**Mixer visto desde arriba**~~ ✅ Claude (`art/ui/mixer_body.png` y `mixer_fader_cap.png`). Si lo redibujas: | 440×430, o 220×215 a ×2 | El cuerpo visto desde arriba; **dos VU-metros azules** (el de la izquierda muestra el ritmo de Matías y el de la derecha, el del amigo), con su aguja aparte o en frames por nivel; la perilla de un fader (Godot la usa en los 3 canales y la sube o baja según la señal); un LED por canal; una fila de luces para el ritmo (8 o 16, encendida y apagada). Las perillas y los botones de adorno, como en tu mixer del escritorio. | Pixel art de Claude; Godot dibuja encima las agujas, las luces, las perillas de los faders y los textos. Ver `C:\dev\capturas\arte_mixer.png`. |
| ~~**Marco del celular ampliado**~~ ✅ Claude (`art/ui/phone_frame.png`), en el azul de tu celular del escritorio | 260×520, o 130×260 a ×2 | Solo el celular de frente, con la pantalla vacía: el agujero de la pantalla va de (14, 18) a (246, 496). Godot dibuja encima la hora, el feed y las fotos. Las fotos ya están (`art/phone/`). | Pixel art de Claude. Ver `C:\dev\capturas\arte_snapgram.png`. |
| ~~**Barras de señal**~~ ✅ Claude (`art/ui/signal_bars.png`; sin señal llevan una x) | 19×12 | 6 estados: de 0 a 5 barras. Que se distingan llenas de vacías sin depender del color. | Pixel art de Claude. |
| **Diales rediseñados** | Como `dial_sprite` (112×113) | Cara de manómetro con un ícono para cada uno (Connection, Sanity y Trust) y un LED de alerta. La aguja sigue siendo `arrow_sprite`. | `dial_sprite` con cara de reloj. |
| **Celular del escritorio sin la hora** y **dígitos LCD** | Como `phone_sprite` (86×55); los dígitos, una tira "0123456789:" | El celular sin el "00:00" pintado. Los dígitos, del alto que tiene la hora dibujada hoy. | Un parche azul tapa la hora pintada y Godot escribe encima. |
| **Bocetos del cuaderno** (la hoja y las pestañas ya están: ✅ Claude) | Unos 96×96 | **Un boceto por entidad** (7 en total), dibujado como a lápiz en la hoja cuadriculada. | La hoja de cuaderno universitario (`art/ui/notebook_page.png`) y las pestañas como notas adhesivas, en Departure Mono. Sin bocetos. Ver `C:\dev\capturas\arte_notebook.png`. |
| Pantallas de victoria y derrota (opcional) | 1280×720 | Un fondo propio para "Llegaste a las 06:00" y "Perdiste la noche", si quieres más que el marco. | El escritorio oscurecido y un marco de placa (`art/ui/menu_frame.png`, de Claude) con botones de aparato. Ver `C:\dev\capturas\arte_summary.png`. |

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
| **Screamers** | Plan 7 | Manos o un rostro que tapan la pantalla (2 o 3 frames) y una criatura que se asome por la ventana, si quieres animarla. La figura de la ventana (`enemy_sprite`) aparece como screamer y, desde el 4 de noviembre, es la criatura que se asoma (sin animación de entrada). ~~La mancha de tinta~~ ✅ Claude: 3 cuadros que salpican y chorreones que bajan (`art/ui/ink_*.png`). |
| Animación de las cortinas al abrirse y cerrarse | Plan 9 | Opcional. Hoy cambian de golpe entre `Open` y `Closed`, los 2 estados que dibujó Benja. |
| ~~Las barras de Connection, Sanity y Trust~~ ✅ Claude | Plan 9 | Una placa de instrumento (`art/ui/hud_bars.png`) con barras de LED en segmentos. |
| La batería del celular del escritorio | Plan 9 | Opcional. Hoy es una barrita verde bajo la hora (`DeskPlane/Phone/BatteryBar`). |
| Luces del PC y del escritorio | Plan 7 | Las de la sección 2. Mientras tanto, el apagón oscurece todo el cuarto por igual. |
| Logo e íconos de Snapgram | S21c | Opcional. El logo hoy es "Snapgram" en Departure Mono a 22 px. Los íconos miden 11×11 (me gusta, comentar, enviar, guardar, inicio, buscar, publicar, videos y perfil), y hoy están hechos píxel por píxel en `scripts/ui/phone_icons.gd`. |
| **Logo** (el menú ya está: ✅ Claude) | Plan 8 | El logo "Spook Dial". Hoy es texto en Departure Mono a 66 px. El menú muestra tus sprites del cuarto a la luz de la luna, oscurecidos, y el marco de placa a la derecha (`scenes/menu/main_menu.tscn`). Ver `C:\dev\capturas\arte_menu.png`. |
| Pantalla entre noches | Plan 8 | La página del canal, con el contenido de la noche. |
| **La Mano** (`hand_sprite`, ✅ tuya, 3 cuadros) | Plan 9.1 | Ya está en el juego, y en el video de su tarjeta de la noche 0 (si cambia, hay que volver a grabarlo: `tools/make_tutorial_videos.sh`). **Ojo:** el lado derecho del cuarto es casi negro, así que a mitad de camino la Mano no se ve (`C:\dev\capturas\plan91_mano_camino.png`): recién aparece en los últimos 3 o 4 s, sobre la pared, y antes solo la delata el crujido. Si quieres que se vea antes, sirven unos pelos o un borde un poco más claros en el brazo. Opcional: un cuadro de "agarre" propio y una animación de retirada al flash (hoy desaparece de golpe). |
| Las marcas de la tabla del cuaderno ✅ Claude | Plan 9.2 | ✓, ✗ y la calavera, de 9×9 (`art/ui/mark_*.png`, de `tools/make_ui_art.py`). Si las redibujas, del mismo tamaño. |
| Un boceto de Gonzalo para su página de la noche 0 | Plan 9.2 | Opcional, como los bocetos de las entidades. |
| El rayo de la linterna | Plan 9.1 | Opcional. Hoy es un ícono de 11×11 hecho píxel por píxel (`PhoneIcons.FLASHLIGHT`, en `scripts/ui/phone_icons.gd`), en la barra superior del celular ampliado. |
| Los íconos de las preguntas ✅ Claude | Plan 9.3 | 9×9 y en blanco, porque el botón les da su color (`art/ui/chat_icon_sight`, `_sound`, `_environment` y `_traces`): un ojo, un parlante (la oreja no se leía a ese tamaño), una nube con niebla y la huella de una pata. Más el ✓ verde y la estática (`chat_icon_check` y `chat_icon_static`). Si los redibujas, del mismo tamaño. Ver `C:\dev\capturas\plan93_1920_static.png`. |
| El cuaderno junto al nombre de la entidad ✅ Claude | Plan 9.3 | 11×11 (`art/ui/chat_icon_notebook.png`): la tapa verde, la etiqueta, la espiral y el canto de las hojas. |
| La señal del botón de sincronizar ✅ Claude | Plan 9.3 | `art/ui/chat_signal.png`: 5 cuadros de 15×12 (de 0 a 4 barritas) en 3 filas (verde, ámbar y rojo); sin señal, una ×. Si la redibujas, con la misma grilla. |
| Las hojas de respuesta ✅ Claude | Plan 9.3 | Texturas 9-slice de 19×19 con márgenes de 4 (`art/ui/chat_answer_normal`, `_hover`, `_pressed` y `_disabled`): el papel del cuaderno, con un cuadro de 11 que se repite, el borde y la sombra. La nota adhesiva del número es la de las pestañas del cuaderno (`notebook_tab.png`). Ver `C:\dev\capturas\plan93_1280_chat.png`. |
| El candado de la dificultad bloqueada ✅ Claude | Plan 9.4 | 11×11 (`art/ui/menu_lock.png`): un candado de acero gris con su arco y el ojo de la cerradura, que el menú muestra al doble junto a "Difícil" mientras no se termine Normal. Si lo redibujas, del mismo tamaño. Ver `C:\dev\capturas\plan94_1280_choice_locked.png`. |

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
