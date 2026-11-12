# Plan 9.5: el tutorial — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** la última de las 3 sesiones con el feedback del primer testeo (`docs/26` §4, sesión S21j), más 5 pedidos de Benja al aprobar el diseño (12 de noviembre):

1. **La noche 0 de nuevo:** solo funciona lo que León va enseñando, y eso parpadea hasta que se aprieta (observaciones 4, 5 y 6). León explica lo que cuesta preguntar (2), lo azul (7), los audios con las tripas de Gonzalo (9) y la estática (16). Gonzalo muestra qué pasa si se acaba el tiempo, con 15 s reales y sin efecto (3, D6).
2. **El botón del flash** con relieve, y su video grabado de nuevo con un cursor que lo aprieta (13).
3. **Las tarjetas** con el color de cada medidor y en viñetas (14).
4. **Pedidos de Benja (12-nov):**
   - el feed de Snapgram avanza más lento con la rueda, y Sanity sube igual;
   - las fotos perturbadoras salen desde Sanity 50 (1 de cada 4) hasta 4 de cada 4 con 10 o menos;
   - el ambiente ya no baja antes de un screamer;
   - cada entrada del PC pita al titilar, con su nota: las 3 juntas hacen un acorde disminuido.

**Arquitectura:**

- **`TutorialChat`** (lógica pura) se reescribe con los pasos nuevos. Cada respuesta (`Reply`) es una **lista ordenada** de líneas de León y órdenes:
  - qué parpadea (`Focus`) y qué se desbloquea (`Unlock`);
  - mandar el video;
  - empezar la demostración de Gonzalo;
  - bajar la señal, escribir la línea con estática fija y cortar la señal;
  - abrir el chat de León;
  - terminar.
- **`RequestManager`**:
  - cumple las órdenes en orden, con las pausas de siempre;
  - expone `tutorial_focus`, `tutorial_wants(focus)` (ese foco y León ya terminó) y `is_unlocked(unlock)` (fuera del tutorial, siempre);
  - recibe 2 avisos nuevos, `tutorial_chat_opened(friend)` y `tutorial_audio_played(friend, stream)`;
  - la demostración de Gonzalo es una segunda `TutorialRequestData` con `demo_seconds = 15`: su temporizador corre desde que se abre su chat, no se puede preguntar ni responder y, al llegar a 0, Gonzalo cuenta qué hizo y sale el aviso de daño sin efecto;
  - en la noche 0 las líneas de León no llevan estática al azar: solo una tiene estática fija (`ChatStatic.apply_fixed`, una de cada 3 palabras).
- **El escritorio** bloquea lo que no se desbloqueó: `ClickableSprite.enabled` y `ChatEntry.enabled`, y las pestañas del chat. `Highlight` rodea también nodos 2D (las entradas del PC).
- **El chat** solo habilita lo que pide León cuando terminó de escribir, y lo hace parpadear:
  - los botones (`Highlight`): preguntas, nombre, hojas, descarga y barritas;
  - las frases y el audio, con el efecto `pulse` del texto (fijo y subrayado con "Reducir destellos").
- **El mixer** dibuja su propio borde: el canal de León antes de una ronda y "TÚ" en su turno.

**Stack:** Godot 4.7.2 (GDScript con tipado estático), con las pruebas propias (`test/run_tests.gd`). El arte, con Python (Pillow y numpy), y los sonidos, con `tools/make_sounds.py`.

**Cómo se ejecuta:** como los Planes 9.1 a 9.4. Se escribe y se ejecuta en la misma sesión (S21j), con un commit por tarea que Benja autorizó al empezar. **El código exacto de cada tarea está en su commit.** El editor de Godot queda cerrado toda la sesión (Benja), así que se puede importar y grabar.

**Punto de partida:** 715 pruebas OK.

**Resultado (12-nov, S21j):** ejecutado completo, en 10 commits. **748 pruebas OK.** Las capturas de cada paso se revisaron a 1280×720 y a 1920×1080 (`C:\dev\capturas\plan95_*.png`), los clips del celular y de la Mano se grabaron de nuevo y el juego abre sin errores.

| Tarea | Commit | Pruebas |
| --- | --- | --- |
| 1. El ambiente no baja | `c84c40d` | 716 |
| 2. Snapgram más lento y las fotos desde 50 | `8f17636` | 720 |
| 3. La alarma de las entradas | `9e4a2d4` | 723 |
| 4 a 6. La conversación nueva, el manager, Gonzalo y las tripas | `59ae67a` | 734 |
| 7. Los bloqueos del escritorio | `45a88e6` | 740 |
| 8. El chat en la noche 0 | `a82537a` | 744 |
| 9. El mixer en la noche 0 | `37a4a55` | 746 |
| 10. El botón del flash | `4aa0688` | 747 |
| 11. Las tarjetas | `e5f5348` | 748 |
| 12. De punta a punta, los videos y la revisión | `78bcbb7` | 748 |

**Lo que cambió al ejecutar:**

- **Las tareas 4, 5 y 6 van en un solo commit:** el manager usaba la forma vieja de `TutorialChat`, y separadas no compilaban.
- **La alarma pita una vez por segundo y no en cada destello:** la alerta de una entrada alterna rojo y azul 5 veces por segundo, y un pitido por destello habría sido insoportable. Las 3 entradas usan un reloj común (el del escritorio), así que pitan juntas, y la entrada se enciende en rojo con el pitido.
- **El scroll avanza 30 px por paso de la rueda** (la mitad de los 60 de antes) y no 24: con 24 había que dar unos 14 pasos por foto.
- **El escritorio dice en cada cuadro qué chat se está mirando** (`RequestManager.tutorial_view`), en vez de una señal al abrirlo: así también cuenta si el jugador ya estaba en el chat de León cuando a Gonzalo se le acaba el tiempo.
- **Lo destacado de las tarjetas va en ámbar, sin negrita:** con `variation_embolden` la letra casi no cambiaba (captura `plan95_*_17_negrita.png`). Las viñetas son una lista `[ul]`, para que lo que no cabe en una línea quede alineado.
- **El clip de la Mano mide 640×512 y el celular sube bajo los diales:** el recorte de antes (la mitad derecha) no mostraba el celular. El del celular también se grabó de nuevo, porque se ve el botón.
- **El nombre de la entidad sigue abriendo la página** después de su paso, y en la demostración de Gonzalo no hay barra de identificación ni preguntas habilitadas (vistos en las capturas).
- **`run_tests.gd` acepta nombres de suites** después de `--`, para correr solo esas.
- **Las pruebas avanzan los tweens a mano** (`custom_step`): sin eso, los mensajes nunca terminan de escribirse y en la noche 0 nada se habilita.
- **La noche 0 de prueba (`content_fixtures.gd`) ya no pierde señal sola,** como la de verdad: con los pasos nuevos, León se quedaba sin señal antes de descargar el video.

---

## Decisiones de Benja (S21g, S21j)

- **D6 (S21g):** Gonzalo, como demostración guiada: 15 s que corren de verdad, con los botones bloqueados, y al llegar a 0 decide solo, elige mal y sale el aviso de daño (sin efecto real).
- **En el chat de la noche 0 solo funciona lo que pide León** (S21j), y se habilita cuando termina de escribir.
- **Los commits de la sesión, autorizados** (S21j), en `main` y sin push.
- **Pedidos al aprobar el diseño (12-nov):**
  - las tarjetas con colores y viñetas;
  - el scroll más lento con la misma recuperación de Sanity;
  - las fotos perturbadoras desde Sanity 50;
  - el ambiente sin bajar;
  - la alarma de las entradas.

## La conversación de León

| # | León (y Gonzalo) | Parpadea y se habilita | Sigue cuando |
| --- | --- | --- | --- |
| 1 | `HELLO`, `GUESS` | ¿QUÉ VES? | pregunta |
| 2 | `COST` (nueva), `MARK` | las frases amarillas | marca una característica (el señuelo da `DECOY`, una vez) |
| 3 | `BLUE` (nueva), `ASK_SOUND` (nueva) | ¿QUÉ OYES? | pregunta |
| 4 | `LISTEN` (nueva) | el audio | lo escucha; León espera a que termine |
| 5 | `HEARD` (nueva), `AMBIENT` | ¿AMBIENTE? | pregunta |
| 6 | — | las frases amarillas | marca la otra y Matías piensa |
| 7 | `NAME`; se desbloquea el cuaderno | el nombre | se abre la página |
| 8 | `DECIDE`, `BEST` | las 4 hojas | elige la del ✓ (si no, `RETRY`) |
| 9 | `BEST_OK`, `WORST` | las 4 hojas | elige la calavera (si no, `WORST_RETRY`) |
| 10 | `WORST_OK`, `DOWNLOAD`; manda el video | la barra | se descarga |
| 11 | `VIDEO_OK`, `GONZALO` (nueva); se desbloquea Gonzalo y llega su solicitud | la entrada de Gonzalo | se abre su chat |
| 12 | Gonzalo: `TUTORIAL_GONZALO_HELP`; corren 15 s; RESPONDER · `TUTORIAL_GONZALO_WATCH` | nada | llega a 0 |
| 13 | Gonzalo: `TUTORIAL_GONZALO_ALONE`, `TUTORIAL_GONZALO_HURT` y "Gonzalo recibió daño: 2/3" | la entrada de León | se abre el chat de León |
| 14 | `NO_ANSWER` (nueva); su señal baja a 30; `STATIC` (nueva, con estática fija); `STATIC_EXPLAIN` (nueva); `SIGNAL_WARN`, `SIGNAL_CUT`; señal 0 y se desbloquea el mixer | las barritas; en el mixer, el canal y después "TÚ" | vuelve la señal |
| 15 | Se abre el chat de León: `BACK`, `READY` y las tarjetas | — | — |

Se borran `TUTORIAL_LEON_ASK_SIGHT_AGAIN`, `TUTORIAL_LEON_NAME_OPEN` y `TUTORIAL_LEON_WAIT`: con el chat bloqueado ya no pueden pasar.

---

## Tareas

### Tarea 1: el ambiente no baja antes de un screamer

**Archivos:** `scripts/desk/screamer_manager.gd`, `test/test_screamer_manager.gd`.

- [ ] Prueba: al anunciar y mostrar un screamer, `Ambient.volume_db` no cambia.
- [ ] Quitar `DUCKED_DB`, `DUCK_SECONDS`, `RETURN_SECONDS`, `_ambient_db` y sus tweens. Las luces de la señal previa siguen.
- [ ] Pruebas OK y commit.

### Tarea 2: Snapgram más lento, y las fotos perturbadoras desde 50

**Archivos:** `scripts/core/phone_feed.gd`, `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/ui/phone_view.gd`, `test/test_phone_feed.gd` y `test/test_phone_view.gd`.

- [ ] Pruebas de `PhoneFeed`:
  - con Sanity sobre 50, ninguna;
  - con 50, 1 de cada 4 en cada grupo de 4 lugares seguidos;
  - con 40, 1; con 30, 2; con 20, 3;
  - con 10 o menos, las 4;
  - el mismo lugar con la misma Sanity sale siempre igual.
- [ ] `BalanceData`: `disturbing_post_start_sanity` (50), `disturbing_post_full_sanity` (10) y `disturbing_post_group` (4), en lugar de los 4 campos de hoy. Entre las dos, la cantidad sube en escalones parejos. Cuáles lugares del grupo se eligen al azar con una semilla del grupo, así que no cambian mientras se ven.
- [ ] `PhoneView.WHEEL_STEP` de 60 a 24 y `PAN_STEP` de 30 a 12. Sanity sube igual, porque cuenta el tiempo scrolleando (`scroll_grace`), no los píxeles. Prueba: un paso de la rueda avanza 24 px y alarga el scroll igual que antes.
- [ ] Pruebas OK y commit.

### Tarea 3: la alarma de las entradas

**Archivos:** `tools/make_sounds.py`, `audio/sfx/alarm_*.wav`, `scripts/data/friend_data.gd`, `data/friends/*.tres`, `scripts/ui/chat_entry.gd`, `scenes/ui/chat_entry.tscn`, `scripts/desk/desk.gd`, `test/test_chat_entry.gd` y `test/test_sounds.gd`.

- [ ] Sonidos (`make_sounds.py`): `alarm_leon` (si, 987,8 Hz), `alarm_gonzalo` (re, 1174,7 Hz) y `alarm_agustin` (fa, 1396,9 Hz). Juntos hacen el acorde disminuido de si. Cada uno es un pitido corto (0,12 s) y suave: un seno con un poco del segundo armónico, ataque de 5 ms y en el parlante de un PC, a −26 LUFS. `test_sounds.gd` los incluye.
- [ ] `FriendData.alarm: AudioStream`, en los 3 `.tres`.
- [ ] `ChatEntry`:
  - suena su alarma cada vez que el cuadro de alerta se enciende (`frame_changed` de la animación `warning`);
  - con "Reducir destellos" la alerta queda fija, así que pita con el mismo ritmo, con su propio reloj;
  - `muted` la calla.
- [ ] El escritorio calla las alarmas mientras suena Audio Sync o un audio de un amigo. Pruebas: pita al encenderse, no pita en las otras alertas, calla con `muted`.
- [ ] Anotar los 3 en `sonidos_pendiente.md`. Pruebas OK y commit.

### Tarea 4: la conversación nueva de León

**Archivos:** `scripts/core/tutorial_chat.gd`, `test/test_tutorial_chat.gd`.

- [ ] `TutorialChat`:
  - `enum Focus { NONE, ASK_SIGHT, ASK_SOUND, ASK_ENVIRONMENT, CLUES, AUDIO, ENTITY_NAME, ANSWERS, DOWNLOAD, DEMO_ENTRY, GUIDE_ENTRY, SYNC }`;
  - `enum Unlock { NOTEBOOK, DEMO_FRIEND, MIXER }`;
  - `Reply.items` (cada uno, una línea o una orden con su valor) y `Reply.lines()` para las pruebas.
- [ ] Las órdenes:
  - `FOCUS` y `UNLOCK`;
  - `SEND_VIDEO` y `START_DEMO`;
  - `SIGNAL` (con el nivel), `STATIC_LINE` (con la clave), `CUT_SIGNAL` y `OPEN_GUIDE_CHAT`;
  - `PAUSE` y `FINISH`.
- [ ] Los eventos:
  - `start`, `question_asked`, `clue_marked`, `audio_played`, `identified` y `page_opened`;
  - `answered`, `video_received`, `chat_opened(is_demo_friend)`, `demo_timed_out` y `signal_restored`.
- [ ] Pruebas: cada paso de la tabla con sus líneas, su foco y sus desbloqueos. También:
  - la broma del señuelo, una vez;
  - las respuestas que no cuentan;
  - lo que llega fuera de su paso no hace nada;
  - todas las claves existen en `ui.csv`.
- [ ] Textos nuevos en `ui.csv` (tabla de arriba) y se borran las 3 viejas. `TUTORIAL_LEON_DECOY` ya no habla de un segundo (S21h).
- [ ] Pruebas OK y commit.

### Tarea 5: el manager cumple las órdenes

**Archivos:** `scripts/desk/request_manager.gd`, `scripts/core/chat_static.gd`, `scripts/data/tutorial_request_data.gd`, `scripts/core/request_generator.gd`, `test/content_fixtures.gd`, `test/test_request_manager.gd` y `test/test_chat_static.gd`.

- [ ] `ChatStatic.apply_fixed(message)`: tapa una de cada 3 palabras que se pueden tapar, empezando por la segunda. Prueba.
- [ ] `TutorialRequestData.demo_seconds` (0: se responde, con el temporizador en espera, como León). La demostración llega con su temporizador en espera hasta que se abre su chat, y después corre.
- [ ] `RequestManager`:
  - `tutorial_focus`, `tutorial_busy()`, `tutorial_wants()` e `is_unlocked()`;
  - `tutorial_chat_opened()` y `tutorial_audio_played()`, que deja a León esperando lo que dura el audio;
  - la demostración: `_maybe_start_demo`, y al llegar a 0, sus 2 líneas y el aviso de daño con 1 menos de vida, sin tocar su vida;
  - las líneas de León sin estática al azar;
  - `tutorial_chat_requested(friend)`, una señal que el escritorio atiende abriendo el chat.
- [ ] Fixtures: la noche 0 de prueba suma la demostración de Gonzalo.
- [ ] Pruebas:
  - el foco llega después de las líneas;
  - `tutorial_wants` es falso mientras León escribe;
  - la demostración no corre hasta abrir su chat;
  - a los 15 s, el aviso de daño sin daño;
  - la línea con estática fija y las otras limpias;
  - el audio hace esperar a León.
- [ ] Pruebas OK y commit.

### Tarea 6: los datos de la noche 0 y las tripas

**Archivos:** `tools/make_sounds.py`, `audio/clues/tutorial_stomach_*.wav`, `data/tutorial/gonzalo.tres`, `data/nights/night_0.tres`, `data/text/ui.csv`, `test/test_catalog.gd` y `test/test_sounds.gd`.

- [ ] Sonidos:
  - `tutorial_stomach_yes`: el cuarto de la cabaña con 2 gruñidos de tripas, gorgoteos graves de ruido con una resonancia que se mueve y burbujas;
  - `tutorial_stomach_no`: el cuarto solo.

  Pasan por el celular, como los demás audios. Se importan con el editor cerrado (`--import`).
- [ ] `gonzalo.tres`: la observación `hungry` pasa a "¿Qué oyes?" con sus 2 audios.
- [ ] `night_0.tres`: una segunda `TutorialRequestData`, la de Gonzalo, con la misma página y `demo_seconds = 15`.
- [ ] `test_catalog.gd`: 2 solicitudes, la segunda es la demostración, y el hambre se oye.
- [ ] `sonidos_pendiente.md`. Pruebas OK y commit.

### Tarea 7: los bloqueos del escritorio

**Archivos:** `scripts/desk/clickable_sprite.gd`, `scripts/ui/chat_entry.gd`, `scripts/ui/highlight.gd`, `scripts/desk/desk.gd`, `scripts/ui/chat_panel.gd`, `test/test_tutorial_desk.gd` y `test/test_highlight.gd`.

- [ ] `ClickableSprite.enabled`: sin habilitar, no se ilumina ni recibe clics.
- [ ] `ChatEntry.enabled`, y un `Highlight` propio (`highlighted`).
- [ ] `Highlight.target_size`, para rodear un nodo 2D.
- [ ] El escritorio, cada cuadro en la noche 0:
  - el cuaderno, el mixer, el celular y las cortinas;
  - las entradas: la del guía siempre, la de la demostración con `DEMO_FRIEND` y las demás nunca;
  - las pestañas del chat (`ChatPanel.set_tab_enabled`);
  - el parpadeo de `DEMO_ENTRY` y `GUIDE_ENTRY`;
  - avisa `tutorial_chat_opened` cuando se abre un chat (`ChatPanel.conversation_opened`) y abre el chat del guía cuando se pide.
- [ ] Pruebas:
  - en la noche 0 el celular, las cortinas, el cuaderno y Agustín no responden al principio;
  - Esc pausa;
  - en la noche 1 todo responde.
- [ ] Pruebas OK y commit.

### Tarea 8: el chat en la noche 0

**Archivos:** `scripts/ui/chat_panel.gd`, `scripts/ui/chat_message_view.gd`, `test/test_chat_panel.gd`.

- [ ] Fuera del tutorial no cambia nada. En la noche 0, cada control se habilita solo si `tutorial_wants(su foco)` y el último mensaje del guía terminó de escribirse:
  - las preguntas, por su categoría;
  - el nombre y las hojas;
  - la barra de descarga y las barritas (que también se apagan sin su foco).
- [ ] Parpadean con un `Highlight` cada uno. Las 4 hojas comparten uno, alrededor de `Answers`.
- [ ] `ChatMessageView`:
  - `attention` hace latir las frases sin marcar (`[pulse]`), o las subraya con "Reducir destellos";
  - `audio_attention` hace lo mismo con el audio;
  - `links_enabled` apaga los enlaces de las frases;
  - el panel las cambia en los mensajes del guía cuando cambia el foco.
- [ ] El audio:
  - se oye con su enlace desde que León lo pide, y se puede repetir después;
  - el panel avisa `tutorial_audio_played`;
  - en la demostración, el título de las respuestas dice `TUTORIAL_GONZALO_WATCH`.
- [ ] Pruebas, en una noche 0 de verdad:
  - al empezar solo ¿QUÉ VES? se habilita y parpadea, después de que León termina;
  - las frases no se clickean antes de su paso;
  - las hojas parpadean juntas;
  - la barra parpadea con su foco.
- [ ] Pruebas OK y commit.

### Tarea 9: el mixer en la noche 0

**Archivos:** `scripts/ui/mixer_view.gd`, `test/test_mixer_view.gd`.

- [ ] `MixerView.guide_rect()`:
  - con el foco `SYNC`, el canal del guía sin ronda (o con una ronda fallida) y el VU-metro de Matías en su turno;
  - en los demás casos, nada.
- [ ] Lo dibuja con el ritmo de `Highlight.is_lit` y el ámbar de siempre.
- [ ] Pruebas de cada caso. Pruebas OK y commit.

### Tarea 10: el botón del flash

**Archivos:** `tools/make_ui_art.py`, `art/ui/phone_flash_button.png`, `scripts/ui/phone_view.gd`, `data/text/phone.csv` y `test/test_phone_view.gd`.

- [ ] Arte: 3 cuadros de 12×12 (normal, encima y apretado), con borde oscuro, luz arriba a la izquierda y sombra abajo a la derecha. El apretado va con la luz y la sombra al revés. Usa la paleta del marco del celular y se estira como 9-slice (márgenes de 4).
- [ ] `PhoneView`:
  - dibuja el botón en la barra superior, centrado donde estaba el rayo, con el rayo y `PHONE_FLASH_BUTTON` ("FLASH") con la letra de siempre (`PixelText`);
  - su tamaño sale del texto, así que crece a 1080p;
  - se ilumina con el mouse encima y se ve apretado 0,18 s al hacer clic;
  - sin batería se ve apagado y no responde.
- [ ] Pruebas:
  - el rectángulo del botón contiene el rayo y el texto;
  - un clic dentro pide el flash y lo deja apretado;
  - sin batería no.
- [ ] `arte_pendiente.md`. Pruebas OK y commit.

### Tarea 11: las tarjetas con colores y viñetas

**Archivos:** `scripts/ui/tutorial_cards.gd`, `scenes/ui/tutorial_cards.tscn`, `scripts/ui/stat_bars.gd`, `data/text/ui.csv` y `test/test_tutorial_cards.gd`.

- [ ] El texto pasa a `RichTextLabel` con BBCode.
- [ ] En el CSV, `{connection}`, `{sanity}` y `{trust}` se reemplazan por el nombre en el color de su aguja, que sale de `StatBars.COLORS`, un solo lugar.
- [ ] Cada idea es una línea con "•".
- [ ] Lo importante:
  - se prueba con `[b]` y una `FontVariation` de Departure Mono con `variation_embolden`;
  - si no queda nítida a 1080p, se quita y se destaca con color (el ámbar de las frases).
- [ ] Pruebas: los 3 nombres salen con su color y ninguna clave queda sin reemplazar.
- [ ] Pruebas OK y commit.

### Tarea 12: la noche 0 de punta a punta, los videos y la revisión

**Archivos:** `test/test_tutorial_desk.gd`, `test/record_tutorial_clips.gd`, `tools/make_tutorial_videos.sh`, `video/tutorial/hand.ogv` y `test/capture_plan95.gd`.

- [ ] Prueba de punta a punta en el escritorio: sigue los 15 pasos. En cada uno revisa qué parpadea y qué está habilitado, y termina en las tarjetas y la noche 1.
- [ ] El clip `hand`:
  - el celular sube con el botón a la vista;
  - un cursor de mentira (un `Sprite2D` dibujado en el script) va al botón y lo aprieta, y el botón se ve apretado;
  - la Mano se va.

  Se graba de nuevo solo ese clip, y también los otros 3 si el arte que se ve cambió (el botón del flash solo sale en `hand`).
- [ ] Capturas de cada paso a 1280×720 y 1920×1080 (`C:\dev\capturas\plan95_*.png`), con las tarjetas y el celular. Se revisan a ojo y se corrige lo que se vea mal.
- [ ] El juego abre sin errores nuevos. Commit.

---

## Al cerrar (regla 4)

- `resumen.md`, `docs/00_log.md` y `docs/04` (sección V, nueva: probar la noche 0 y los pedidos del 12-nov).
- `CLAUDE.md` y el diseño v2:
  - la noche 0 nueva;
  - las fotos desde 50;
  - el ambiente sin bajar;
  - la alarma;
  - el scroll más lento;
  - el botón del flash.
- `docs/26` (§4 ejecutada) y este plan, con su resultado.
- `arte_pendiente.md` y `sonidos_pendiente.md`.
