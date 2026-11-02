# Plan 6: Mantenimiento — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que las tres tareas de mantenimiento funcionen en la noche:

- **la señal:** cada amigo pierde señal a su propio ritmo y con interferencias, que se anuncian 3 s antes (su entrada del PC titila y suena estática). Sin señal, el amigo queda desconectado: su mensaje llega tapado entero, no lee las preguntas ni las respuestas de Matías y, si se le acaba el tiempo, elige mal. Mientras haya amigos sin señal, Trust baja;
- **Audio Sync en el mixer:** un clic en el mixer abre su vista desde arriba, y el botón «Sincronizar» del chat de un amigo la abre en su canal. Al elegir el canal de un amigo, una base marca el tiempo, el amigo aplaude un ritmo y Matías lo repite con la barra espaciadora o con clics. Si sale bien, la señal del amigo vuelve a 100;
- **los videos:** el amigo avisa en su chat que mandó uno. Hay 15 s para empezar a descargarlo, manteniendo presionada la barra de descarga del chat, y 20 s para terminar. La descarga tarda 10 s, y más con la señal débil;
- **el celular:** un clic en el celular abre sus redes sociales, que se scrollean con la rueda del mouse. Mientras se scrollea, Sanity sube.

**Arquitectura:**

- Lógica pura en `scripts/core/`: `FriendState` (la señal y la desconexión), `InterferenceSchedule` (las interferencias), `VideoSchedule` (los videos que esperan su descarga), `NightState` (junta todo, baja Trust con amigos sin señal y sube Sanity al scrollear) y `AudioSyncRound` (una ronda de Audio Sync).
- `RequestManager` aplica las reglas de un amigo sin señal y avisa en el chat lo que pasa con los videos y la señal. `NightManager` le pasa lo que pasó en cada paso de la noche.
- La interfaz: las entradas del PC (señal, interferencias y videos), la barra de descarga del chat, la vista del mixer (`scenes/ui/mixer_view.tscn`) y la del celular (`scenes/ui/phone_view.tscn`). Las dos vistas son provisionales y se dibujan con rectángulos hasta el arte de Benja. El escritorio las abre como modos exclusivos.
- Los sonidos provisionales van en `audio/sfx/` y los genera `tools/make_placeholder_sounds.py`.

**Stack:** Godot 4.7.2 (GDScript con tipado estático, dibujo con `_draw()` y `AudioStreamPlayer`) y Python 3, solo con su biblioteca estándar, para los sonidos. Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §6, §7, §8.7, §10.1, §10.2, §10.5 y §10.6, y `docs/02_bucle_central.md` §2, §4 y §6.

---

## Decisiones de este plan

### De Benja (sesión 14, 31 de octubre)

Están en `CLAUDE.md`, en el diseño v2 y en `docs/02`.

| Decisión | Detalle |
| --- | --- |
| **Audio Sync en el mixer visto desde arriba.** | Benja va a dibujar el mixer visto desde arriba. Sus dos medidores azules son los VU-metros: el de la izquierda muestra el ritmo de Matías y el de la derecha, el del amigo. Mientras no esté el arte, la vista es provisional: se dibuja en Godot con los colores del mixer del escritorio. |
| **El amigo marca un ritmo y Matías lo imita.** | El mixer parpadea con el ritmo del amigo (luces y aguja) y después Matías lo imita con clics o con la barra espaciadora. Suenan la base que marca el tiempo, los aplausos del amigo y los golpes de Matías. La actividad se empieza cuando el jugador quiere, con un clic en el mixer. |
| **Los videos se descargan en el chat.** | Cuando llega un video, hay 15 s para empezar a descargarlo (antes eran 10), manteniendo presionada su barra en el chat del amigo. Desde que empieza, hay 20 s para terminar. La descarga tarda 10 s; con la señal del amigo bajo 50, tarda 15 s, y con 0, no avanza. |
| **Un amigo sin señal.** | Le siguen llegando situaciones, pero su mensaje llega tapado entero y no lee las preguntas ni las respuestas de Matías. Si se le acaba el tiempo sin que lo reconecten, elige al azar una de las 3 acciones que no son la correcta: el daño es el de siempre, y esa decisión no baja Trust. Mientras haya amigos sin señal, Trust baja 1 punto cada 4 s por cada uno y no se recupera. |
| **«Sincronizar» desde el chat.** | El chat de cada amigo tiene un botón «Sincronizar», a la derecha de la barra de identificación: cierra el chat, abre el mixer en el canal de ese amigo y la ronda empieza enseguida. En el mixer se puede elegir cualquier canal con su fader, y la entrada del PC siempre abre el chat: cada control hace una sola cosa. |
| **El celular, provisional.** | Benja va a animar el scroll de las redes sociales. Mientras tanto, el celular ampliado es un feed dibujado en Godot, con 12 publicaciones que se repiten sin fin. |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| Al empezar la noche, a cada amigo le toca un ritmo al azar entre los dos valores de `NightData.signal_decay_interval` (de 3 a 6 s por punto de señal). | Diseño §10.1: la señal baja "con un ritmo que cambia según el amigo y la noche". |
| Las interferencias se reparten una por tramo igual de la noche, a una hora al azar lejos de los bordes del tramo, cada una para un amigo al azar. Golpean −40 y se anuncian 3 s antes, valores que están en `BalanceData`. | Así nunca llegan dos seguidas. El director del Plan 7 puede cambiar el reparto. |
| Sin señal es con la señal en 0. `FriendState.is_available()` (recibir solicitudes) no cambia, y `can_send()` (enviar videos) pide además señal. | Decisión de Benja: le siguen llegando situaciones. Sin señal no envía nada: su video llega cuando se reconecta, como el de un amigo aturdido. |
| Sin señal, la estática tapa el 100 % de las palabras (`ChatStatic`). | "El mensaje llega tapado entero". Los avisos del juego no pasan por la estática, así que el de daño se sigue leyendo. |
| Los avisos de que un amigo se quedó sin señal, de que volvió, de un video recibido y de uno perdido son avisos del juego (`ChatMessage.Sender.SYSTEM`): los malos van en rojo y los buenos en verde (`ChatMessage.Tone`). Que mandó un video lo dice el amigo, en primera persona. | Como el aviso de daño: centrados y sin nombre. El texto dice qué pasó, así que no depende solo del color (diseño §19). |
| `NightState.advance()` devuelve lo que pasó en ese paso (`NightState.Events`): los videos que llegaron, se recibieron o se perdieron, y los amigos que se quedaron sin señal. `NightManager` se lo pasa a `RequestManager.report()`, que escribe los avisos. | El estado de la noche sigue siendo lógica pura, y `RequestManager` sigue siendo el único que escribe en el chat. |
| La descarga es un botón invisible sobre una barra de progreso, en el chat del amigo y encima de la barra de identificación. Mientras está presionado, el chat le dice al estado de la noche qué video se descarga (`NightState.holding_download`). Al soltarlo, al cambiar de pestaña o al cerrar el chat, se pausa. | Decisión de Benja: manteniendo presionado, dentro del chat. La barra aparece solo mientras hay un video esperando, y la conversación se acorta para dejarle espacio. |
| La entrada del PC parpadea mientras hay un video esperando, como con una solicitud, y su temporizador dice "Video 12": el tiempo para empezar o para terminar la descarga. | El PC muestra los avisos de los amigos (diseño §6). Si también hay una solicitud, se ve su tiempo, que es lo más urgente. |
| Audio Sync va en corcheas sobre una base de 100 golpes por minuto: un compás de cuenta, después el amigo aplaude 4 u 8 veces (según la noche) en el doble de corcheas, con el primer aplauso al comienzo, y Matías los repite en otras tantas corcheas. Cada golpe tiene ±150 ms. La ronda termina apenas Matías acierta el último aplauso o apenas falla. | Con 4 aplausos, la ronda dura 7,2 s, y con 8, 12 s: ese es el costo de mantener la señal. El tempo y la tolerancia están en `BalanceData`. |
| Mientras Matías repite el ritmo, las luces del mixer se apagan: hay que recordarlo. Al terminar, las luces muestran el ritmo: en verde lo que acertó y en rojo lo que faltó. | Así se aprende de cada error. |
| La base es un bombo en los golpes 1 y 3 (más fuerte al empezar cada compás) y un platillo en los golpes 2 y 4. El aplauso del amigo y el golpe de Matías suenan distinto. | Solo por el sonido se distingue quién hace qué. |
| Al abrir el mixer desde el escritorio queda elegido el amigo con menos señal, y la ronda empieza con un clic en un fader o con la barra espaciadora. Con «Sincronizar», en cambio, la ronda empieza enseguida en el canal del amigo del chat. En la noche 1, el botón no aparece. | El mixer es un modo exclusivo (decisión de Benja, 31 de octubre), y desde el chat ya se sabe qué amigo hay que sincronizar. |
| En la noche 1 no hay Audio Sync (`audio_sync_beats` es 0): el mixer se abre, pero dice que la señal está estable. | En la noche 1 la señal no baja (diseño §14). |
| Cada movimiento de la rueda del mouse (o del touchpad) cuenta como 0,3 s de scroll, y mientras dura, Sanity sube 4 por segundo. El feed avanza 60 px por movimiento, con suavidad, y se repite sin fin. | Diseño §10.2: Sanity sube mientras se scrollea y deja de subir al detenerse. Con la rueda girando sin parar, sube 4 por segundo (docs/02 §6). |
| Las publicaciones son datos: `PhonePostData` (autor, texto, imagen y color) en el catálogo (`phone_posts`), con sus textos en `data/text/phone.csv`. Una publicación sin imagen muestra un paisaje de su color. | El contenido es datos (regla 7). Cuando Benja dibuje las publicaciones, pone cada imagen en el Inspector. |
| El mixer y el celular se dibujan con `_draw()`, con rectángulos y la fuente pixel, sin arte. | Son provisionales: el arte de Benja los reemplaza (ver "Fuera de este plan"), y la lógica (la ronda, el scroll y Sanity) no cambia. |
| Las vistas del mixer y del celular van a la izquierda, como el chat, y dejan ver las entradas del PC. Suben desde el escritorio al abrirse. | Mientras se sincroniza o se scrollea, se ven los avisos de los amigos. |
| Los sonidos son WAV provisionales que genera `tools/make_placeholder_sounds.py`, siempre iguales. Cada uno está en un `AudioStreamPlayer` de su escena. | Para cambiarlos por los definitivos (Plan 9) basta con reemplazar el archivo. |
| La estática suena una vez, al empezar el aviso de cada interferencia. | Diseño §10.1: se anuncia con estática y la entrada titilando. |
| Al terminar la noche, el mixer y el celular se cierran. | Para que la ronda no siga sonando detrás de la pantalla final. |

**Verificado en Godot 4.7.2**, en copias aparte del proyecto, ya borradas:

- todo el código de este plan se ejecutó: 326 pruebas OK, sin errores al correr, y tres capturas revisadas a ojo: el mixer en una ronda, la descarga de un video en el chat y el celular;
- después, un script aplicó el plan **tal como está escrito** a una copia limpia del proyecto: los 34 conteos de pruebas que dice coinciden, incluidas las fallas esperadas, todos los bloques a reemplazar aparecen una sola vez, y el código resultante es idéntico al probado, también los 7 sonidos.

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `251 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.
- [ ] **Python 3:** `python3 --version` muestra 3.8 o más nuevo. Solo se usa su biblioteca estándar.
- [ ] **Textos de Benja:** los textos de los CSV pueden tener cambios de Benja. Este plan no los reemplaza: solo agrega líneas al final.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar.** Al importar, Godot registra las clases nuevas (`class_name`), crea los `.uid` de los scripts nuevos, importa los sonidos y regenera las traducciones de los CSV. Cada tarea importa antes de correr las pruebas:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | grep -E "SCRIPT|Parse" ; echo "import listo"
```

Esperado: solo `import listo`. Si aparece `SCRIPT ERROR`, el script tiene un error de sintaxis: corregirlo y volver a importar. En los pasos "Verificar que fallan", el import puede no mostrar nada aunque una prueba nueva no cargue: el error aparece al correr las pruebas.

**Pruebas.** Para ver solo las fallas y el resumen:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "FALLA|pruebas OK"
```

**Commits.** Cada tarea termina en un commit, pero Claude **pregunta a Benja antes de cada uno**, salvo que Benja autorice de una vez todos los commits del plan al empezar (`CLAUDE.md`, regla 11). La línea `Co-Authored-By` nombra al modelo que ejecuta: los comandos dicen Sonnet 5.5, como propone `docs/00_log.md`; si ejecuta otro, se cambia el nombre. El push solo se hace con autorización.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

**Tabuladores:** GDScript indenta con tabuladores. Los bloques de este plan los tienen: al copiarlos, no hay que convertirlos en espacios. Lo más seguro es copiar cada bloque con un script, como en los planes anteriores.

**Cómo leer los cambios:**

- "`ruta`:" seguido de un bloque: crear el archivo con ese contenido.
- "`ruta` (archivo completo):": reemplazar todo el contenido del archivo.
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo, y son líneas completas.
- "Agregar al final de `ruta`:": en un `.gd`, dejar dos líneas en blanco antes del bloque; en un `.md`, una línea en blanco; en un `.csv`, agregar las líneas tal cual.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/balance_data.gd`, `data/balance.tres` | Los valores nuevos: el scroll, la señal, Audio Sync y los videos |
| `scripts/core/friend_state.gd` | La señal de un amigo: baja a su ritmo, interferencias, desconexión y Audio Sync |
| `scripts/core/interference_schedule.gd` | `InterferenceSchedule`: cuándo y a quién golpean las interferencias, y su aviso |
| `scripts/core/video_schedule.gd` | Los videos esperan su descarga: sus plazos y su velocidad según la señal |
| `scripts/core/night_state.gd` | Junta la señal, las interferencias, los videos, Trust con amigos sin señal y Sanity al scrollear, y devuelve lo que pasó en cada paso (`Events`) |
| `scripts/core/chat_static.gd` | Sin señal, el mensaje se tapa entero |
| `scripts/core/friend_request.gd`, `scripts/core/consequence.gd` | Un amigo sin señal elige mal, y su decisión no baja Trust |
| `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/ui/chat_message_view.gd` | Los avisos buenos y malos del juego (`Tone`) y el mensaje del video |
| `scripts/core/ending_text.gd` | La pantalla final dice si el amigo estaba sin señal |
| `scripts/core/audio_sync_round.gd` | `AudioSyncRound`: una ronda de Audio Sync |
| `scripts/desk/request_manager.gd` | Sin señal no se pregunta ni se responde; los avisos de la noche (`report()`) y la señal que vuelve (`restore_signal()`) |
| `scripts/desk/night_manager.gd` | Le pasa a `RequestManager` lo que pasó en cada paso |
| `scripts/ui/chat_entry.gd`, `scenes/ui/chat_entry.tscn` | Las barras de señal, el parpadeo de una interferencia, el video y "Sin señal" en la entrada del PC |
| `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres` | La barra de descarga, el chat de un amigo sin señal y el botón «Sincronizar» |
| `tools/make_placeholder_sounds.py`, `audio/sfx/*.wav` | Los sonidos provisionales |
| `scripts/ui/mixer_view.gd`, `scenes/ui/mixer_view.tscn` | La vista del mixer y Audio Sync |
| `scripts/data/phone_post_data.gd`, `scripts/data/content_catalog.gd`, `scripts/core/content_validator.gd`, `data/catalog.tres` | Las publicaciones del celular como datos |
| `scripts/ui/phone_view.gd`, `scenes/ui/phone_view.tscn` | La vista del celular y su scroll |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | Las entradas con señal y videos, el mixer y el celular como modos exclusivos, «Sincronizar» desde el chat y la estática de una interferencia |
| `data/text/ui.csv`, `data/text/messages.csv`, `data/text/phone.csv`, `project.godot` | Los textos nuevos, y el registro de `phone.csv` |
| `test/test_*.gd` | Pruebas de cada tarea |
| `test/capture_maintenance.gd` | Capturas del mantenimiento para revisarlo a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
NightManager.advance(delta), en cada frame mientras la noche no termine
  1. RequestManager.advance(delta): temporizadores; sin respuesta, el amigo decide solo (sin señal, elige mal)
  2. NightState.advance(delta) ──▶ Events
       FriendState.advance: el aturdimiento y la señal, cada amigo a su ritmo
       InterferenceSchedule.take_due ──▶ FriendState.interfere(40)
       Sanity: baja y, mientras se scrollea, sube       Trust: con amigos sin señal, baja
       VideoSchedule.advance(holding_download): videos que llegan, se descargan, se reciben o se pierden
  3. RequestManager.report(events) ──▶ avisos en el chat
  4. NightState.ending() ──▶ night_ended

Chat (ChatPanel)        barra de descarga presionada ──▶ NightState.holding_download
                        «Sincronizar» ──▶ escritorio ──▶ MixerView.open_for(amigo): la ronda empieza enseguida
Mixer (MixerView)       AudioSyncRound ──▶ sonidos, luces y agujas; si sale bien ──▶ RequestManager.restore_signal()
Celular (PhoneView)     rueda del mouse ──▶ NightState.scroll()
Escritorio (desk.gd)    entradas ◀ señal, interferencia, video; estática al empezar el aviso de una interferencia
                        clic en el mixer o en el celular ──▶ su vista, como modo exclusivo
```

---
### Tarea 1: Valores del mantenimiento como datos

**Archivos:**

- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `test/test_balance.gd`

`BalanceData` agrega los valores del scroll del celular, la señal, Audio Sync y los videos (`docs/02` §6 y las decisiones de Benja). Se ajustan en el Inspector de `data/balance.tres`.

- [ ] **Paso 1: Escribir la prueba**

En `test/test_balance.gd`, reemplazar:

```gdscript
	return true


## Las pruebas usan BalanceData.new(): sus valores por defecto deben ser los de data/balance.tres.
```

por:

```gdscript
	return true


## Los valores del mantenimiento (docs/02 §6 y decisiones de Benja del 31 de octubre).
func test_valores_del_mantenimiento() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.scroll_sanity_per_second, 4.0, "scrollear: Sanity +4 por segundo")
	check_eq(balance.scroll_grace, 0.3, "cada movimiento de la rueda cuenta 0,3 s")
	check_eq(balance.interference_damage, 40.0, "interferencia: −40 de señal")
	check_eq(balance.interference_warning, 3.0, "anunciada 3 s antes")
	check_eq(balance.offline_trust_interval, 4.0, "desconectado: Trust −1 cada 4 s por amigo")
	check_eq(balance.audio_sync_bpm, 100.0, "base de Audio Sync a 100 golpes por minuto")
	check_eq(balance.audio_sync_tolerance, 0.15, "tolerancia de ±150 ms")
	check_eq(balance.video_accept_seconds, 15.0, "15 s para empezar a descargar")
	check_eq(balance.video_finish_seconds, 20.0, "20 s para terminar")
	check_eq(balance.download_seconds, 10.0, "la descarga tarda 10 s")
	check_eq(balance.download_slow_seconds, 15.0, "con señal débil, 15 s")
	check_eq(balance.download_slow_below, 50.0, "señal débil: bajo 50")
	return true

## Las pruebas usan BalanceData.new(): sus valores por defecto deben ser los de data/balance.tres.
```

- [ ] **Paso 2: Verificar que falla**

Importar y correr las pruebas.

Esperado: `251 pruebas OK, 1 fallidas`. La falla es `test_balance.gd :: test_valores_del_mantenimiento` ("la prueba no terminó"), porque `BalanceData` todavía no tiene esos valores.

- [ ] **Paso 3: Agregar los valores**

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var vignette_start := 60.0
```

por:

```gdscript
@export var vignette_start := 60.0
## Sanity que se recupera por segundo mientras Matías scrollea el celular (docs/02 §6).
@export var scroll_sanity_per_second := 4.0
## Segundos que cuenta como scroll cada movimiento de la rueda del mouse: al dejar de scrollear, Sanity
## deja de subir.
@export var scroll_grace := 0.3

@export_group("Señal")
## Señal que le quita una interferencia a un amigo.
@export var interference_damage := 40.0
## Segundos que se anuncia una interferencia antes de golpear: la entrada del amigo titila y suena estática.
@export var interference_warning := 3.0
## Mientras haya amigos desconectados, Trust baja 1 punto cada tantos segundos por cada uno y no se
## recupera (decisión de Benja).
@export var offline_trust_interval := 4.0

@export_group("Audio Sync")
## Golpes por minuto de la base. El ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0
## Cuánto puede adelantarse o atrasarse cada golpe de Matías, en segundos (docs/02 §6).
@export var audio_sync_tolerance := 0.15

@export_group("Videos")
## Segundos para empezar a descargar un video que llegó. Si no empieza a tiempo, se pierde (decisión de Benja).
@export var video_accept_seconds := 15.0
## Segundos para terminar la descarga desde que empezó (decisión de Benja).
@export var video_finish_seconds := 20.0
## Segundos de descarga manteniendo presionado, con buena señal (decisión de Benja).
@export var download_seconds := 10.0
## Segundos de descarga cuando la señal del amigo está bajo download_slow_below (decisión de Benja).
## Con la señal en 0, la descarga no avanza.
@export var download_slow_seconds := 15.0
## Bajo esta señal, la descarga es lenta (diseño §10.1).
@export var download_slow_below := 50.0
```

En `data/balance.tres`, reemplazar:

```ini
vignette_start = 60.0
```

por:

```ini
vignette_start = 60.0
scroll_sanity_per_second = 4.0
scroll_grace = 0.3
interference_damage = 40.0
interference_warning = 3.0
offline_trust_interval = 4.0
audio_sync_bpm = 100.0
audio_sync_tolerance = 0.15
video_accept_seconds = 15.0
video_finish_seconds = 20.0
download_seconds = 10.0
download_slow_seconds = 15.0
download_slow_below = 50.0
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `252 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Valores del mantenimiento como datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: La señal de cada amigo

**Archivos:**

- Modificar: `scripts/core/friend_state.gd`, `test/test_friend_state.gd`

`FriendState` pierde señal a su propio ritmo, la pierde de golpe con una interferencia y la recupera con Audio Sync. Sin señal no envía videos, pero le siguen llegando solicitudes (decisión de Benja).

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_friend_state.gd`:

```gdscript
func test_la_senal_baja_con_el_tiempo() -> bool:
	var friend := FriendState.new(3)
	friend.advance(30.0)
	check_eq(friend.signal_level, 100.0, "sin ritmo de bajada no baja, como en la noche 1")
	friend.signal_decay_interval = 5.0
	friend.advance(50.0)
	check(is_equal_approx(friend.signal_level, 90.0), "−1 cada 5 s: %s" % friend.signal_level)
	friend.advance(1000.0)
	check_eq(friend.signal_level, 0.0, "no baja de 0")
	return true


func test_sin_senal_esta_desconectado() -> bool:
	var friend := FriendState.new(3)
	check(friend.is_online() and friend.can_send(), "conectado: puede enviar videos")
	friend.interfere(40.0)
	check_eq(friend.signal_level, 60.0, "una interferencia le quita 40")
	friend.interfere(80.0)
	check_eq(friend.signal_level, 0.0, "no baja de 0")
	check(not friend.is_online(), "desconectado")
	check(friend.is_available(), "igual le llegan solicitudes (decisión de Benja)")
	check(not friend.can_send(), "pero no puede enviar videos")
	friend.restore_signal()
	check_eq(friend.signal_level, 100.0, "Audio Sync: vuelve a 100")
	check(friend.is_online(), "conectado otra vez")
	return true


func test_aturdido_no_envia_videos() -> bool:
	var friend := FriendState.new(3)
	friend.hurt(1, 15.0)
	check(friend.is_online() and not friend.can_send(), "aturdido: no envía")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `252 pruebas OK, 3 fallidas`. Fallan las 3 pruebas nuevas de `test_friend_state.gd` ("la prueba no terminó").

- [ ] **Paso 3: La señal en `FriendState`**

En `scripts/core/friend_state.gd`, reemplazar:

```gdscript
## Lógica pura: NightState tiene uno por amigo.
```

por:

```gdscript
## Lógica pura: NightState tiene uno por amigo.

## La señal va de 0 a 100. Con 0, el amigo está desconectado.
const SIGNAL_MAX := 100.0
```

En `scripts/core/friend_state.gd`, reemplazar:

```gdscript
## Señal (0–100): decide la estática de sus mensajes. En el Plan 6 baja durante la noche.
var signal_level := 100.0
```

por:

```gdscript
## Señal (0–100): decide la estática de sus mensajes y la velocidad de sus descargas. Con 0 está desconectado.
var signal_level := SIGNAL_MAX
## Segundos por cada punto de señal que pierde con el tiempo. Con 0, la señal no baja (noche 1).
var signal_decay_interval := 0.0
```

En `scripts/core/friend_state.gd`, reemplazar:

```gdscript
## Puede recibir solicitudes y enviar videos: está vivo y no está aturdido.
func is_available() -> bool:
	return is_alive() and not is_stunned()
```

por:

```gdscript
## Tiene señal. Desconectado, no lee las preguntas ni las respuestas de Matías, y no envía videos.
func is_online() -> bool:
	return signal_level > 0.0


## Puede recibir solicitudes: está vivo y no está aturdido. Desconectado también le llegan, pero no lee
## las respuestas de Matías (decisión de Benja).
func is_available() -> bool:
	return is_alive() and not is_stunned()


## Puede enviar un video: está disponible y tiene señal.
func can_send() -> bool:
	return is_available() and is_online()
```

En `scripts/core/friend_state.gd`, reemplazar:

```gdscript
func advance(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
```

por:

```gdscript
## Una interferencia le quita `amount` de señal.
func interfere(amount: float) -> void:
	signal_level = maxf(signal_level - amount, 0.0)


## Audio Sync salió bien: la señal vuelve a 100.
func restore_signal() -> void:
	signal_level = SIGNAL_MAX


## Avanza `delta` segundos: el aturdimiento y, si la noche lo pide, la señal.
func advance(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
	if signal_decay_interval > 0.0:
		signal_level = maxf(signal_level - delta / signal_decay_interval, 0.0)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `255 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Señal de cada amigo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: Las interferencias

**Archivos:**

- Crear: `scripts/core/interference_schedule.gd`, `test/test_interference_schedule.gd`

`InterferenceSchedule` reparte las interferencias de la noche, dice si viene una (para el aviso) y entrega las que ya golpearon.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_interference_schedule.gd`:

```gdscript
extends "res://test/test_case.gd"

const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")


func _schedule(count: int) -> InterferenceSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	return InterferenceSchedule.new(count, 420.0, 3, rng)


func test_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.pending.size(), 3, "3 interferencias")
	for index in schedule.pending.size():
		var interference: InterferenceSchedule.Interference = schedule.pending[index]
		# Una en cada tercio de la noche (140 s), lejos de sus bordes.
		check(interference.time >= 140.0 * index + 28.0 and interference.time <= 140.0 * index + 112.0,
				"la %d, en su tramo: %s" % [index + 1, interference.time])
		check(interference.friend_index >= 0 and interference.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_sin_interferencias() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "ninguna")
	check(not schedule.is_warning(0, 0.0, 3.0), "sin aviso")
	return true


func test_se_anuncia_unos_segundos_antes() -> bool:
	var schedule := _schedule(1)
	var interference: InterferenceSchedule.Interference = schedule.pending[0]
	var friend := interference.friend_index
	check(not schedule.is_warning(friend, interference.time - 3.5, 3.0), "3,5 s antes, todavía no")
	check(schedule.is_warning(friend, interference.time - 2.5, 3.0), "2,5 s antes, sí")
	check(not schedule.is_warning((friend + 1) % 3, interference.time - 1.0, 3.0), "solo en su amigo")
	return true


func test_golpea_a_su_hora_una_sola_vez() -> bool:
	var schedule := _schedule(1)
	var interference: InterferenceSchedule.Interference = schedule.pending[0]
	check_eq(schedule.take_due(interference.time - 0.1), [], "antes de su hora, nada")
	check_eq(schedule.take_due(interference.time), [interference.friend_index], "a su hora, golpea")
	check_eq(schedule.take_due(interference.time + 10.0), [], "no vuelve a golpear")
	check(not schedule.is_warning(interference.friend_index, interference.time, 3.0), "ya no se anuncia")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `255 pruebas OK, 1 fallidas`. La falla es `test_interference_schedule.gd :: no se pudo cargar`, porque el script todavía no existe.

- [ ] **Paso 3: Crear `InterferenceSchedule`**

`scripts/core/interference_schedule.gd`:

```gdscript
extends RefCounted
## Las interferencias de la noche (diseño §10.1): golpes de estática que le quitan señal a un amigo de una
## vez. Cada una se anuncia unos segundos antes: la entrada del amigo titila y suena estática.
## Lógica pura: NightState la avanza y la aplica.


## Una interferencia que va a golpear a un amigo.
class Interference:
	var friend_index: int
	## Segundos desde las 00:00.
	var time: float

	func _init(interference_friend: int, interference_time: float) -> void:
		friend_index = interference_friend
		time = interference_time


## Las que todavía no golpean, en orden.
var pending: Array[Interference] = []


## Reparte `count` interferencias en la noche: una por tramo igual, a una hora al azar lejos de los bordes
## del tramo, cada una para un amigo al azar.
func _init(count: int, night_seconds: float, friend_count: int, rng: RandomNumberGenerator) -> void:
	if count <= 0:
		return
	var span := night_seconds / count
	for index in count:
		var time := span * (index + rng.randf_range(0.2, 0.8))
		pending.append(Interference.new(rng.randi_range(0, friend_count - 1), time))


## Al amigo `friend_index` le golpea una interferencia dentro de `warning` segundos o menos.
func is_warning(friend_index: int, now: float, warning: float) -> bool:
	for interference: Interference in pending:
		if interference.friend_index == friend_index and interference.time - now <= warning:
			return true
	return false


## Quita las interferencias que ya golpearon y devuelve a qué amigo le tocó cada una.
func take_due(now: float) -> Array[int]:
	var hit: Array[int] = []
	for interference: Interference in pending.duplicate():
		if interference.time <= now:
			pending.erase(interference)
			hit.append(interference.friend_index)
	return hit
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `259 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Interferencias de la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Los videos se descargan

**Archivos:**

- Modificar: `scripts/core/video_schedule.gd`, `scripts/core/night_state.gd`, `scripts/desk/night_manager.gd`, `test/test_video_schedule.gd`, `test/test_night_state.gd`, `test/test_night_manager.gd`

Un video que llega ya no cuenta solo: espera su descarga (`VideoSchedule.Offer`), con 15 s para empezarla y, desde ahí, 20 s para terminarla. `NightState.holding_download` dice qué video descarga Matías, y `NightState.advance()` devuelve lo que pasó en el paso (`NightState.Events`). Las pruebas del Plan 5 que recibían los videos solos ahora los descargan.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_video_schedule.gd` (archivo completo):

```gdscript
extends "res://test/test_case.gd"

const FriendState := preload("res://scripts/core/friend_state.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")


## Envíos de una noche de 420 s con `quota` videos entre 3 amigos, con los valores de docs/02 §6:
## 15 s para empezar la descarga, 20 s para terminarla y 10 s de descarga.
func _schedule(quota: int) -> VideoSchedule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return VideoSchedule.new(quota, BalanceData.new(), 3, rng)


func _friends() -> Array[FriendState]:
	var friends: Array[FriendState] = []
	for _i in 3:
		friends.append(FriendState.new(3))
	return friends


## Avanza `seconds` de a 1 segundo desde `start`, con Matías manteniendo presionada la descarga del amigo
## `holding` (-1: ninguna). Junta los cambios de todos los pasos.
func _advance(schedule: VideoSchedule, friends: Array[FriendState], start: float, seconds: int,
		holding: int) -> VideoSchedule.Changes:
	var all := VideoSchedule.Changes.new()
	for step in seconds:
		var changes := schedule.advance(start + step + 1.0, 1.0, friends, holding)
		all.offered.append_array(changes.offered)
		all.received.append_array(changes.received)
		all.lost.append_array(changes.lost)
	return all


## Un video extra del amigo 1, ya ofrecido en el segundo 1.
func _offered_extra(friends: Array[FriendState]) -> VideoSchedule:
	var schedule := _schedule(0)
	schedule.add_extra(1, 0.0)
	_advance(schedule, friends, 0.0, 1, -1)
	return schedule


func test_los_envios_se_reparten_en_la_noche() -> bool:
	var schedule := _schedule(3)
	check_eq(schedule.quota, 3, "cuota")
	check_eq(schedule.pending.map(func(delivery: VideoSchedule.Delivery) -> float: return delivery.time),
			[105.0, 210.0, 315.0], "a las 01:30, 03:00 y 04:30")
	for delivery: VideoSchedule.Delivery in schedule.pending:
		check(delivery.friend_index >= 0 and delivery.friend_index < 3, "de uno de los 3 amigos")
	return true


func test_a_su_hora_llega_como_oferta() -> bool:
	var schedule := _schedule(3)
	var friends := _friends()
	var first: int = schedule.pending[0].friend_index
	check_eq(_advance(schedule, friends, 0.0, 104, -1).offered, [], "antes de tiempo, nada")
	check_eq(_advance(schedule, friends, 104.0, 1, -1).offered, [first], "a los 105 s llega el primero")
	var offer := schedule.offer_for(first)
	check(offer != null and not offer.started, "espera que Matías empiece la descarga")
	if offer != null:
		check_eq(offer.time_left, 15.0, "15 s para empezar")
	check_eq(schedule.received, 0, "todavía no cuenta")
	return true


func test_sin_empezar_a_tiempo_se_pierde() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 14, -1)
	check(schedule.offer_for(1) != null, "a los 14 s sigue esperando")
	check_eq(_advance(schedule, friends, 15.0, 1, -1).lost, [1], "a los 15 s se pierde")
	check(schedule.offers.is_empty(), "ya no espera")
	check_eq(schedule.lost, 1, "perdidos")
	return true


func test_manteniendo_presionado_se_descarga_en_10_s() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 9, 1)
	var offer := schedule.offer_for(1)
	check(offer != null and offer.started, "empezó")
	if offer != null:
		check(is_equal_approx(offer.progress, 0.9), "a los 9 s, 90 %%: %s" % offer.progress)
		check_eq(offer.time_left, 11.0, "desde que empezó hay 20 s para terminar")
	check_eq(_advance(schedule, friends, 10.0, 1, 1).received, [1], "a los 10 s se recibe")
	check_eq(schedule.received, 1, "cuenta para la cuota")
	return true


func test_al_soltar_se_pausa() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 5, 1)
	_advance(schedule, friends, 6.0, 10, -1)
	var offer := schedule.offer_for(1)
	check(offer != null, "sigue esperando")
	if offer != null:
		check(is_equal_approx(offer.progress, 0.5), "conserva lo descargado: %s" % offer.progress)
		check_eq(offer.time_left, 5.0, "pero el tiempo corre")
	check_eq(_advance(schedule, friends, 16.0, 5, 1).received, [1], "terminó justo a los 20 s")
	return true


func test_hay_20_s_para_terminar() -> bool:
	var friends := _friends()
	var schedule := _offered_extra(friends)
	_advance(schedule, friends, 1.0, 5, 1)
	check_eq(_advance(schedule, friends, 6.0, 15, -1).lost, [1], "a los 20 s de empezar se pierde")
	return true


func test_la_velocidad_depende_de_la_senal() -> bool:
	var friends := _friends()
	friends[1].signal_level = 40.0
	var schedule := _offered_extra(friends)
	check(_advance(schedule, friends, 1.0, 14, 1).received.is_empty(), "con señal 40 no alcanza en 14 s")
	check_eq(_advance(schedule, friends, 15.0, 1, 1).received, [1], "tarda 15 s")
	friends = _friends()
	schedule = _offered_extra(friends)
	friends[1].signal_level = 0.0
	_advance(schedule, friends, 1.0, 5, 1)
	check_eq(schedule.offer_for(1).progress, 0.0, "sin señal no avanza")
	return true


func test_si_el_amigo_no_puede_enviar_se_atrasa() -> bool:
	var schedule := _schedule(0)
	var friends := _friends()
	schedule.add_extra(1, 0.0)
	friends[1].hurt(1, 15.0)
	check(_advance(schedule, friends, 0.0, 5, -1).offered.is_empty(), "aturdido: todavía no")
	friends[1].stun_left = 0.0
	friends[1].signal_level = 0.0
	check(_advance(schedule, friends, 5.0, 5, -1).offered.is_empty(), "sin señal: todavía no")
	friends[1].restore_signal()
	check_eq(_advance(schedule, friends, 10.0, 1, -1).offered, [1], "llega cuando puede")
	return true


func test_un_video_por_amigo_a_la_vez() -> bool:
	var schedule := _schedule(0)
	var friends := _friends()
	schedule.add_extra(1, 0.0)
	schedule.add_extra(1, 0.0)
	check_eq(_advance(schedule, friends, 0.0, 1, -1).offered, [1], "llega uno")
	check_eq(schedule.pending.size(), 1, "el otro espera")
	var changes := _advance(schedule, friends, 1.0, 10, 1)
	check_eq(changes.received, [1], "se descarga el primero")
	check_eq(changes.offered, [1], "y después llega el segundo")
	return true


func test_sin_cuota_ya_esta_cumplida() -> bool:
	var schedule := _schedule(0)
	check(schedule.pending.is_empty(), "sin envíos")
	check(schedule.is_quota_met(), "cumplida")
	return true
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	for _i in seconds:
```

por:

```gdscript
	for _i in seconds:
		state.advance(1.0)


## Avanza `seconds` de a 1 segundo, con Matías descargando cada video apenas llega.
func _advance_downloading(state: NightState, seconds: int) -> void:
	for _i in seconds:
		state.holding_download = state.videos.offers[0].friend_index if not state.videos.offers.is_empty() else -1
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
func test_los_videos_programados_llegan() -> bool:
	var state := _make_state()
	var arrived: Array[int] = []
	for _i in 140:
		arrived.append_array(state.advance(1.0))
	check_eq(arrived.size(), 1, "el primero a los 140 s")
	check_eq(state.videos.received, 1, "recibido")
```

por:

```gdscript
func test_los_videos_llegan_y_se_descargan() -> bool:
	var state := _make_state()
	var offered: Array[int] = []
	for _i in 140:
		offered.append_array(state.advance(1.0).videos.offered)
	check_eq(offered.size(), 1, "el primero llega a los 140 s")
	check_eq(state.videos.received, 0, "falta descargarlo")
	if offered.size() == 1:
		state.holding_download = offered[0]
		_advance(state, 10)
		check_eq(state.videos.received, 1, "descargado en 10 s")
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	check_eq(state.advance(0.1), [2], "llega el video de Agustín")
```

por:

```gdscript
	check_eq(state.advance(0.1).videos.offered, [2], "llega el video de Agustín")
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	check_eq(state.videos.received, 0, "aturdido: todavía no")
	_advance(state, 1)
	check_eq(state.videos.received, 1, "al recuperarse")
```

por:

```gdscript
	check(state.videos.offer_for(2) == null, "aturdido: todavía no")
	_advance(state, 1)
	check(state.videos.offer_for(2) != null, "al recuperarse")
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	_advance(state, 420)
	check_eq(state.videos.received, 2, "llegaron los 2 envíos")
	check_eq(state.ending(), NightState.Ending.WON, "ganó")
	state = _make_state()
	state.videos.pending.clear()
	_advance(state, 420)
	check_eq(state.ending(), NightState.Ending.QUOTA, "sin videos, pierde por la cuota")
```

por:

```gdscript
	_advance_downloading(state, 420)
	check_eq(state.videos.received, 2, "descargó los 2 envíos")
	check_eq(state.ending(), NightState.Ending.WON, "ganó")
	state = _make_state()
	_advance(state, 420)
	check_eq(state.videos.lost, 2, "sin descargarlos, se pierden")
	check_eq(state.ending(), NightState.Ending.QUOTA, "pierde por la cuota")
```

En `test/test_night_manager.gd`, reemplazar:

```gdscript
		night.advance(1.0)


func test_avanza_las_solicitudes_y_el_estado() -> bool:
```

por:

```gdscript
		night.advance(1.0)


## Avanza `seconds` de a 1 segundo, con Matías descargando cada video apenas llega.
func _advance_downloading(night: NightManager, seconds: int) -> void:
	for _i in seconds:
		var offers: Array = night.state().videos.offers
		night.state().holding_download = offers[0].friend_index if not offers.is_empty() else -1
		night.advance(1.0)


func test_avanza_las_solicitudes_y_el_estado() -> bool:
```

En `test/test_night_manager.gd`, reemplazar:

```gdscript
func test_avisa_cuando_llega_un_video() -> bool:
	var night := _make_night()
	var arrived := []
	night.video_received.connect(func(friend_index: int) -> void: arrived.append(friend_index))
	_advance(night, 139)
	check(arrived.is_empty(), "todavía no")
	_advance(night, 1)
	check_eq(arrived.size(), 1, "a los 140 s llega el primero")
```

por:

```gdscript
func test_avisa_cuando_se_recibe_un_video() -> bool:
	var night := _make_night()
	var received := []
	night.video_received.connect(func(friend_index: int) -> void: received.append(friend_index))
	_advance(night, 140)
	var offers: Array = night.state().videos.offers
	check_eq(offers.size(), 1, "a los 140 s llega el primero")
	check(received.is_empty(), "falta descargarlo")
	if offers.size() == 1:
		var friend_index: int = offers[0].friend_index
		night.state().holding_download = friend_index
		_advance(night, 10)
		check_eq(received, [friend_index], "descargado")
```

En `test/test_night_manager.gd`, reemplazar:

```gdscript
	_advance(night, 419)
	check(endings.is_empty(), "a los 419 s sigue")
	_advance(night, 1)
```

por:

```gdscript
	_advance_downloading(night, 419)
	check(endings.is_empty(), "a los 419 s sigue")
	_advance_downloading(night, 1)
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `238 pruebas OK, 4 fallidas`. No se pudieron cargar `test_night_state.gd` ni `test_video_schedule.gd`, y en `test_night_manager.gd` fallan `test_avisa_cuando_se_recibe_un_video` y `test_a_las_06_con_la_cuota_se_gana`.

- [ ] **Paso 3: Las ofertas de video**

En `scripts/core/video_schedule.gd`, reemplazar:

```gdscript
## Los videos de la noche (diseño §10.4): los envíos programados, que son justo los que pide la cuota,
## y los videos extra de la acción de mayor riesgo. Si al amigo le toca enviar y no puede (está
## aturdido), su video llega cuando se recupera (decisión de Benja).
## Por ahora los videos se reciben solos al llegar: aceptarlos y descargarlos llega en el Plan 6.
```

por:

```gdscript
## Los videos de la noche (diseño §10.4 y §10.5): los envíos programados, que son justo los que pide la cuota,
## y los videos extra de la acción de mayor riesgo. Cuando a un amigo le toca enviar, el video llega como
## una oferta: hay que empezar a descargarlo a tiempo y terminar la descarga manteniendo presionado
## (decisión de Benja). Si el amigo no puede enviar (está aturdido o sin señal), su video llega cuando puede.
## Lógica pura: NightState la avanza y el chat muestra la descarga.

const FriendState := preload("res://scripts/core/friend_state.gd")
```

En `scripts/core/video_schedule.gd`, reemplazar:

```gdscript
## Videos que hay que recibir para ganar la noche.
var quota := 0
var received := 0
## Los envíos que todavía no llegan.
var pending: Array[Delivery] = []


## Programa `night_quota` envíos repartidos parejo en la noche, cada uno de un amigo al azar.
func _init(night_quota: int, night_seconds: float, friend_count: int, rng: RandomNumberGenerator) -> void:
	quota = night_quota
	for index in night_quota:
		var time := night_seconds * (index + 1) / (night_quota + 1)
```

por:

```gdscript
## Un video que llegó y espera su descarga.
class Offer:
	var friend_index: int
	## Ya empezó la descarga: desde ahí corre el tiempo para terminarla.
	var started := false
	## Segundos que quedan para empezar o, si ya empezó, para terminar.
	var time_left: float
	## Cuánto se descargó, de 0 a 1.
	var progress := 0.0

	func _init(offer_friend: int, accept_seconds: float) -> void:
		friend_index = offer_friend
		time_left = accept_seconds

	func is_complete() -> bool:
		return progress >= 1.0 or is_equal_approx(progress, 1.0)


## Lo que pasó con los videos en un paso: de qué amigo es cada uno.
class Changes:
	var offered: Array[int] = []
	var received: Array[int] = []
	var lost: Array[int] = []


## Videos que hay que recibir para ganar la noche.
var quota := 0
var received := 0
var lost := 0
## Los envíos que todavía no llegan.
var pending: Array[Delivery] = []
## Los videos que esperan su descarga: como máximo uno por amigo.
var offers: Array[Offer] = []

var _balance: BalanceData


## Programa `night_quota` envíos repartidos parejo en la noche, cada uno de un amigo al azar.
func _init(night_quota: int, balance: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	quota = night_quota
	_balance = balance
	for index in night_quota:
		var time := balance.night_seconds * (index + 1) / (night_quota + 1)
```

En `scripts/core/video_schedule.gd`, reemplazar:

```gdscript
## Recibe los envíos que ya tocan y cuyo amigo puede enviar (`can_send` recibe el índice del amigo).
## Devuelve de qué amigo es cada video que llegó.
func receive_due(now: float, can_send: Callable) -> Array[int]:
	var arrived: Array[int] = []
	for delivery: Delivery in pending.duplicate():
		if delivery.time <= now and can_send.call(delivery.friend_index):
			pending.erase(delivery)
			arrived.append(delivery.friend_index)
	received += arrived.size()
	return arrived
```

por:

```gdscript
## El video del amigo `friend_index` que espera su descarga, o null.
func offer_for(friend_index: int) -> Offer:
	for offer: Offer in offers:
		if offer.friend_index == friend_index:
			return offer
	return null


## Cuánto avanza la descarga por segundo, de 0 a 1, según la señal del amigo: más lenta bajo
## download_slow_below y detenida sin señal (diseño §10.1).
func download_rate(signal_level: float) -> float:
	if signal_level <= 0.0:
		return 0.0
	if signal_level < _balance.download_slow_below:
		return 1.0 / _balance.download_slow_seconds
	return 1.0 / _balance.download_seconds


## Avanza `delta` segundos, hasta `now`. `holding` es el amigo cuya descarga mantiene presionada Matías
## (-1: ninguno); si no había empezado, empieza. Después llegan como ofertas los envíos que tocan, si su
## amigo puede enviar y no tiene otro video esperando.
func advance(now: float, delta: float, friends: Array[FriendState], holding: int) -> Changes:
	var changes := Changes.new()
	for offer: Offer in offers.duplicate():
		if offer.friend_index == holding:
			if not offer.started:
				offer.started = true
				offer.time_left = _balance.video_finish_seconds
			offer.progress = minf(offer.progress + delta * download_rate(friends[holding].signal_level), 1.0)
		if offer.is_complete():
			offers.erase(offer)
			received += 1
			changes.received.append(offer.friend_index)
			continue
		offer.time_left -= delta
		if offer.time_left <= 0.0:
			offers.erase(offer)
			lost += 1
			changes.lost.append(offer.friend_index)
	for delivery: Delivery in pending.duplicate():
		var friend_index := delivery.friend_index
		if delivery.time <= now and friends[friend_index].can_send() and offer_for(friend_index) == null:
			pending.erase(delivery)
			offers.append(Offer.new(friend_index, _balance.video_accept_seconds))
			changes.offered.append(friend_index)
	return changes
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
const METER_MAX := 100.0

var night: NightData
```

por:

```gdscript
const METER_MAX := 100.0


## Lo que pasó en un paso de la noche, para avisarlo en el chat.
class Events:
	## Los videos que llegaron, se recibieron o se perdieron.
	var videos: VideoSchedule.Changes


var night: NightData
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
var videos: VideoSchedule
```

por:

```gdscript
var videos: VideoSchedule
## El amigo cuya descarga mantiene presionada Matías en el chat, o -1 (decisión de Benja).
var holding_download := -1
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	videos = VideoSchedule.new(night.content_quota, balance.night_seconds, friend_count, rng)


## Avanza `delta` segundos: la hora, Sanity, Trust, el aturdimiento y los videos.
## Devuelve de qué amigo es cada video que llegó en este paso.
func advance(delta: float) -> Array[int]:
```

por:

```gdscript
	videos = VideoSchedule.new(night.content_quota, balance, friend_count, rng)


## Avanza `delta` segundos: la hora, Sanity, Trust, los amigos y los videos. Devuelve lo que pasó.
func advance(delta: float) -> Events:
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	return videos.receive_due(elapsed, is_available)
```

por:

```gdscript
	var events := Events.new()
	events.videos = videos.advance(elapsed, delta, friends, holding_download)
	return events
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
## Puede recibir solicitudes y enviar videos.
```

por:

```gdscript
## Puede recibir solicitudes: está vivo y no está aturdido.
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
## Llegó un video del amigo `friend_index`. Por ahora se recibe solo: aceptarlo llega en el Plan 6.
```

por:

```gdscript
## Se recibió un video del amigo `friend_index`: Matías terminó de descargarlo.
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
	for friend_index: int in requests.state.advance(delta):
```

por:

```gdscript
	var events := requests.state.advance(delta)
	for friend_index: int in events.videos.received:
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `264 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Los videos se descargan" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: La señal en la noche

**Archivos:**

- Modificar: `scripts/core/night_state.gd`, `test/test_night_state.gd`

El estado de la noche le da a cada amigo su ritmo de señal, aplica las interferencias y avisa quién se quedó sin señal. Con amigos sin señal, Trust baja (decisión de Benja), y mientras Matías scrollea el celular, Sanity sube.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_night_state.gd`:

```gdscript
func test_cada_amigo_pierde_senal_a_su_ritmo() -> bool:
	var catalog := Fixtures.make_catalog()
	var night := catalog.nights[0]
	night.signal_decays = true
	night.signal_decay_interval = Vector2(4, 6)
	var state := NightState.new(night, catalog.balance, 3, RandomNumberGenerator.new())
	_advance(state, 60)
	for friend in state.friends:
		check(friend.signal_decay_interval >= 4.0 and friend.signal_decay_interval <= 6.0,
				"−1 cada 4 a 6 s: %s" % friend.signal_decay_interval)
		check(is_equal_approx(friend.signal_level, 100.0 - 60.0 / friend.signal_decay_interval), "bajó a su ritmo")
	check_eq(_make_state().friends[0].signal_decay_interval, 0.0, "si la noche no lo pide, no baja")
	return true


func test_las_interferencias_se_anuncian_y_golpean() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].interference_count = 1
	var state := NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())
	var friend_index: int = state.interferences.pending[0].friend_index
	var time: float = state.interferences.pending[0].time
	state.advance(time - 3.5)
	check(not state.interference_warning(friend_index), "3,5 s antes, nada")
	state.advance(1.0)
	check(state.interference_warning(friend_index), "2,5 s antes, la entrada titila")
	state.advance(3.0)
	check_eq(state.friends[friend_index].signal_level, 60.0, "le quitó 40 de señal")
	check(not state.interference_warning(friend_index), "ya pasó")
	return true


func test_avisa_cuando_un_amigo_pierde_la_senal() -> bool:
	var state := _make_state()
	state.friends[2].signal_decay_interval = 1.0
	state.friends[2].signal_level = 1.5
	check_eq(state.advance(1.0).disconnected, [], "con 0,5 sigue conectado")
	check_eq(state.advance(1.0).disconnected, [2], "Agustín se quedó sin señal")
	check_eq(state.advance(1.0).disconnected, [], "avisa una sola vez")
	check_eq(state.offline_count(), 1, "1 amigo sin señal")
	return true


func test_sin_senal_trust_baja_y_no_se_recupera() -> bool:
	var state := _make_state()
	state.trust = 50.0
	state.friends[0].signal_level = 0.0
	_advance(state, 40)
	check(is_equal_approx(state.trust, 40.0), "un amigo sin señal: −1 cada 4 s: %s" % state.trust)
	state.friends[1].signal_level = 0.0
	_advance(state, 40)
	check(is_equal_approx(state.trust, 20.0), "dos amigos: el doble de rápido: %s" % state.trust)
	state.friends[0].restore_signal()
	state.friends[1].restore_signal()
	_advance(state, 20)
	check(is_equal_approx(state.trust, 20.0), "reconectados, 20 s sin recuperarse: %s" % state.trust)
	_advance(state, 8)
	check(is_equal_approx(state.trust, 21.0), "después se recupera como siempre: %s" % state.trust)
	return true


func test_scrollear_recupera_sanity() -> bool:
	var state := _make_state()
	state.sanity = 50.0
	for _i in 20:
		state.scroll()
		state.advance(0.1)
	check(is_equal_approx(state.sanity, 50.0 + 2.0 * 4.0 - 2.0 / 6.0), "2 s scrolleando: +4 por segundo: %s" % state.sanity)
	state.scroll()
	state.advance(1.0)
	check(is_equal_approx(state.sanity, 50.0 + 8.0 + 0.3 * 4.0 - 3.0 / 6.0),
			"un movimiento de la rueda cuenta 0,3 s: %s" % state.sanity)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `264 pruebas OK, 5 fallidas`. Fallan las 5 pruebas nuevas de `test_night_state.gd`.

- [ ] **Paso 3: La señal, Trust y Sanity en `NightState`**

`scripts/core/night_state.gd` (archivo completo):

```gdscript
extends RefCounted
## El estado de una noche en curso (diseño §5, §9 y §10): la hora, Sanity, Trust, cómo está cada amigo
## y su señal, las interferencias y los videos. Lógica pura: RequestManager lo crea, NightManager lo avanza
## y el escritorio lo muestra.

const Consequence := preload("res://scripts/core/consequence.gd")
const FriendState := preload("res://scripts/core/friend_state.gd")
const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")

## Cómo termina la noche. NONE: todavía no termina.
enum Ending { NONE, WON, FRIEND_DIED, SANITY, TRUST, CONNECTION, QUOTA }

## La noche va de las 00:00 a las 06:00.
const NIGHT_HOURS := 6
## Sanity, Trust y la señal van de 0 a 100.
const METER_MAX := 100.0


## Lo que pasó en un paso de la noche, para avisarlo en el chat.
class Events:
	## Los videos que llegaron, se recibieron o se perdieron.
	var videos: VideoSchedule.Changes
	## Amigos que se quedaron sin señal en este paso.
	var disconnected: Array[int] = []


var night: NightData
var balance: BalanceData
## Segundos desde las 00:00.
var elapsed := 0.0
var sanity := METER_MAX
var trust := METER_MAX
var friends: Array[FriendState] = []
var videos: VideoSchedule
## El amigo cuya descarga mantiene presionada Matías en el chat, o -1 (decisión de Benja).
var holding_download := -1
var interferences: InterferenceSchedule

## Segundos desde la última vez que bajó Trust.
var _since_trust_loss := 0.0
## Segundos que todavía cuentan como scroll del celular.
var _scroll_left := 0.0


func _init(night_data: NightData, balance_data: BalanceData, friend_count: int, rng: RandomNumberGenerator) -> void:
	night = night_data
	balance = balance_data
	for _index in friend_count:
		var friend := FriendState.new(balance.friend_health)
		if night.signal_decays:
			# Cada amigo pierde señal a su propio ritmo (diseño §10.1).
			friend.signal_decay_interval = rng.randf_range(night.signal_decay_interval.x, night.signal_decay_interval.y)
		friends.append(friend)
	videos = VideoSchedule.new(night.content_quota, balance, friend_count, rng)
	interferences = InterferenceSchedule.new(night.interference_count, balance.night_seconds, friend_count, rng)


## Avanza `delta` segundos: la hora, los amigos y su señal, las interferencias, Sanity, Trust y los videos.
## Devuelve lo que pasó, para avisarlo en el chat.
func advance(delta: float) -> Events:
	var events := Events.new()
	elapsed = minf(elapsed + delta, balance.night_seconds)
	var online: Array[bool] = []
	for friend: FriendState in friends:
		online.append(friend.is_online())
		friend.advance(delta)
	for friend_index: int in interferences.take_due(elapsed):
		friends[friend_index].interfere(balance.interference_damage)
	for index in friends.size():
		if online[index] and not friends[index].is_online():
			events.disconnected.append(index)
	_advance_sanity(delta)
	_advance_trust(delta)
	events.videos = videos.advance(elapsed, delta, friends, holding_download)
	return events


## Aplica la consecuencia de una solicitud del amigo `friend_index`: la vida, el aturdimiento, Trust y,
## si fue la acción de mayor riesgo y el amigo sobrevivió, el video extra.
func apply(friend_index: int, consequence: Consequence) -> void:
	var friend := friends[friend_index]
	if consequence.is_hurt():
		friend.hurt(consequence.damage, balance.stun_seconds)
	if consequence.trust_change < 0.0:
		_since_trust_loss = 0.0
	trust = clampf(trust + consequence.trust_change, 0.0, METER_MAX)
	if consequence.risky and friend.is_alive():
		videos.add_extra(friend_index, elapsed)


## Puede recibir solicitudes: está vivo y no está aturdido.
func is_available(friend_index: int) -> bool:
	return friends[friend_index].is_available()


## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2).
func scroll() -> void:
	_scroll_left = balance.scroll_grace


## Al amigo `friend_index` le va a golpear una interferencia: su entrada titila y suena estática.
func interference_warning(friend_index: int) -> bool:
	return interferences.is_warning(friend_index, elapsed, balance.interference_warning)


## Cuántos amigos están sin señal.
func offline_count() -> int:
	return friends.filter(func(friend: FriendState) -> bool: return not friend.is_online()).size()


## El dial de Connection: el promedio de las señales de los amigos (diseño §10.1).
func connection() -> float:
	var total := 0.0
	for friend: FriendState in friends:
		total += friend.signal_level
	return total / friends.size()


## La hora del celular, de "00:00" a "06:00".
func clock_text() -> String:
	var minutes := int(elapsed / balance.night_seconds * NIGHT_HOURS * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


## Cuánto se oscurece la vista, de 0 a 1: nada desde vignette_start de Sanity hacia arriba, y todo en 0.
func vignette_strength() -> float:
	return clampf((balance.vignette_start - sanity) / balance.vignette_start, 0.0, 1.0)


## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0.
## A las 06:00 se gana si se cumplió la cuota (diseño §5).
func ending() -> Ending:
	for friend: FriendState in friends:
		if not friend.is_alive():
			return Ending.FRIEND_DIED
	if sanity <= 0.0:
		return Ending.SANITY
	if trust <= 0.0:
		return Ending.TRUST
	if connection() <= 0.0:
		return Ending.CONNECTION
	if elapsed >= balance.night_seconds:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
	return Ending.NONE


## Sanity baja con el tiempo y sube mientras Matías scrollea el celular.
func _advance_sanity(delta: float) -> void:
	var scrolling := minf(_scroll_left, delta)
	_scroll_left = maxf(_scroll_left - delta, 0.0)
	sanity = clampf(sanity - delta / night.sanity_drain_interval + scrolling * balance.scroll_sanity_per_second,
			0.0, METER_MAX)


## Trust se recupera si no bajó en un rato. Con amigos sin señal, baja por cada uno y no se recupera
## (decisión de Benja).
func _advance_trust(delta: float) -> void:
	var offline := offline_count()
	if offline > 0:
		_since_trust_loss = 0.0
		trust = maxf(trust - delta * offline / balance.offline_trust_interval, 0.0)
		return
	_since_trust_loss += delta
	# Solo cuenta la parte del paso que cae después de la espera sin errores.
	var calm := clampf(_since_trust_loss - balance.trust_recovery_delay, 0.0, delta)
	trust = minf(trust + calm / balance.trust_recovery_interval, METER_MAX)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `269 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Señal, interferencias, Trust y Sanity en la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Un amigo sin señal

**Archivos:**

- Modificar: `scripts/core/chat_static.gd`, `scripts/core/friend_request.gd`, `scripts/core/consequence.gd`, `scripts/core/ending_text.gd`, `scripts/desk/request_manager.gd`, `data/text/ui.csv`, `test/test_chat_static.gd`, `test/test_consequence.gd`, `test/test_friend_request.gd`, `test/test_request_manager.gd`, `test/test_ending_text.gd`

Las reglas de Benja para un amigo sin señal: su mensaje llega tapado entero, no lee las preguntas ni las respuestas de Matías y, si se le acaba el tiempo, elige al azar una de las 3 acciones que no son la correcta, sin que esa decisión baje Trust. Si lo reconectan a tiempo, todo vuelve a funcionar. La pantalla final dice si el amigo murió por decidir sin señal.

**Test Signal**, en el Inspector de `RequestManager`, ahora acepta 0: los amigos empiezan sin señal.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_chat_static.gd`, reemplazar:

```gdscript
	var expected := {100: 0.0, 70: 0.0, 69: 0.10, 50: 0.10, 49: 0.25, 30: 0.25, 29: 0.45, 1: 0.45}
```

por:

```gdscript
	var expected := {100: 0.0, 70: 0.0, 69: 0.10, 50: 0.10, 49: 0.25, 30: 0.25, 29: 0.45, 1: 0.45, 0: 1.0}
```

Agregar al final de `test/test_chat_static.gd`:

```gdscript
## Un amigo sin señal: su mensaje llega tapado entero (decisión de Benja).
func test_sin_senal_se_tapa_todo() -> bool:
	var message := _long_message(200)
	ChatStatic.apply(message, 0.0, _rng())
	check_eq(_covered(message), 200, "las 200 palabras")
	return true
```

Agregar al final de `test/test_consequence.gd`:

```gdscript
## Si el amigo decidió solo y sin señal, su decisión no baja Trust, pero el daño es el de siempre
## (decisión de Benja).
func test_sin_senal_trust_no_baja() -> bool:
	var offline := Consequence.new(RuleEvaluator.Outcome.WRONG, false, _balance(1.0), RandomNumberGenerator.new(), true)
	check_eq(offline.trust_change, 0.0, "ni −10 ni −15")
	check_eq(offline.damage, 1, "el daño de siempre")
	return true
```

Agregar al final de `test/test_friend_request.gd`:

```gdscript
## Sin señal, el amigo elige mal: al azar entre las 3 acciones que no son la correcta (decisión de Benja).
func test_sin_senal_decide_mal() -> bool:
	var chosen := {}
	for seed_value in 40:
		var request := _make_request()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		request.decide_alone(rng, true)
		check(request.decided_offline, "decidió sin señal")
		check(request.outcome != RuleEvaluator.Outcome.CORRECT, "nunca la correcta")
		chosen[request.chosen_action.id] = true
	check_eq(chosen.size(), 3, "elige entre las otras 3")
	return true
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
func test_sin_senal_el_mensaje_llega_tapado_entero() -> bool:
	var manager := _make_manager()
	manager.state.friends[1].signal_level = 0.0
	var events := []
	_record(manager, events)
	manager.start_request(1)
	var message: ChatMessage = _messages(events)[0]
	for token: ChatMessage.Token in message.tokens:
		check(token.covered or not token.can_be_covered(), "tapado: %s" % token.text)
	manager.free()
	return true


func test_sin_senal_no_lee_preguntas_ni_respuestas() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(0)
	manager.state.friends[0].signal_level = 0.0
	check(not manager.ask(0, ClueCategory.Kind.SIGHT), "no puede preguntar")
	check(not manager.answer(0, request.entity.actions[0]), "no puede responder")
	check_eq(manager.requests[0], request, "la solicitud sigue esperando")
	manager.state.friends[0].restore_signal()
	check(manager.answer(0, request.entity.actions[0]), "reconectado, responde normal")
	manager.free()
	return true


func test_sin_senal_decide_mal_sin_bajar_trust() -> bool:
	var manager := _make_manager()
	var request := manager.start_request(2)
	manager.state.friends[2].signal_level = 0.0
	manager.advance(request.time_left + 0.1)
	check(request.finished and request.decided_offline, "decidió solo, sin señal")
	check(request.outcome != RuleEvaluator.Outcome.CORRECT, "eligió mal")
	check_eq(manager.state.trust, 100.0, "su decisión no bajó Trust")
	manager.free()
	return true
```

En `test/test_ending_text.gd`, reemplazar:

```gdscript
	"END_CHOSEN_ALONE": "{friend} eligió solo: {action}.",
```

por:

```gdscript
	"END_CHOSEN_ALONE": "{friend} eligió solo: {action}.",
	"END_CHOSEN_OFFLINE": "{friend} sin señal eligió: {action}.",
```

En `test/test_ending_text.gd`, reemplazar:

```gdscript
			EndingText.RULE_KEY, EndingText.CORRECT_KEY, EndingText.CHOSEN_BY_PLAYER_KEY, EndingText.CHOSEN_ALONE_KEY]
```

por:

```gdscript
			EndingText.RULE_KEY, EndingText.CORRECT_KEY, EndingText.CHOSEN_BY_PLAYER_KEY, EndingText.CHOSEN_ALONE_KEY,
			EndingText.CHOSEN_OFFLINE_KEY]
```

En `test/test_ending_text.gd`, reemplazar:

```gdscript
		"END_CHOSEN_ALONE": ["{friend}", "{action}"],
```

por:

```gdscript
		"END_CHOSEN_ALONE": ["{friend}", "{action}"],
		"END_CHOSEN_OFFLINE": ["{friend}", "{action}"],
```

Agregar al final de `test/test_ending_text.gd`:

```gdscript
func test_si_el_amigo_estaba_sin_senal() -> bool:
	var request := _fatal_request(&"a1", false)
	request.decided_offline = true
	var body := EndingText.body(NightState.Ending.FRIEND_DIED, _make_state(), request, FRIENDS, _translate)
	check(_plain(body).ends_with("Gonzalo sin señal eligió: K_beast_A1."), "dice que estaba sin señal: %s" % _plain(body))
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `248 pruebas OK, 8 fallidas`. No se pudieron cargar `test_consequence.gd`, `test_ending_text.gd` ni `test_friend_request.gd`; en `test_chat_static.gd` fallan `test_probabilidad_segun_la_senal` y `test_sin_senal_se_tapa_todo`, y en `test_request_manager.gd`, las 3 pruebas nuevas.

- [ ] **Paso 3: Las reglas de un amigo sin señal**

En `scripts/core/chat_static.gd`, reemplazar:

```gdscript
## Estática del chat (docs/02 §4): con poca señal, algunas palabras del amigo llegan tapadas (▒▒▒).
```

por:

```gdscript
## Estática del chat (docs/02 §4): con poca señal, algunas palabras del amigo llegan tapadas (▒▒▒), y sin señal,
## todas (decisión de Benja).
```

En `scripts/core/chat_static.gd`, reemplazar:

```gdscript
static func coverage_for_signal(signal_level: float) -> float:
```

por:

```gdscript
static func coverage_for_signal(signal_level: float) -> float:
	if signal_level <= 0.0:
		return 1.0
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
var answered_by_player := false
```

por:

```gdscript
var answered_by_player := false
## El amigo decidió solo y sin señal: eligió mal (decisión de Benja).
var decided_offline := false
```

En `scripts/core/friend_request.gd`, reemplazar:

```gdscript
## Sin respuesta a tiempo, el amigo elige al azar entre las 4 acciones (docs/02 §2).
func decide_alone(rng: RandomNumberGenerator) -> void:
	finish(entity.actions[rng.randi_range(0, entity.actions.size() - 1)], false)
```

por:

```gdscript
## Sin respuesta a tiempo, el amigo elige al azar entre las 4 acciones (docs/02 §2). Si estaba sin señal,
## elige mal: al azar entre las 3 que no son la correcta (decisión de Benja).
func decide_alone(rng: RandomNumberGenerator, offline := false) -> void:
	var choices: Array = entity.actions
	if offline:
		var correct_id := RuleEvaluator.applicable_rule(entity, situation).correct_action_id
		choices = entity.actions.filter(func(action: ActionData) -> bool: return action.id != correct_id)
	decided_offline = offline
	finish(choices[rng.randi_range(0, choices.size() - 1)], false)
```

En `scripts/core/consequence.gd`, reemplazar:

```gdscript
## si nadie respondió a tiempo y el amigo decidió solo: entonces Trust baja además.
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator) -> void:
```

por:

```gdscript
## si nadie respondió a tiempo y el amigo decidió solo: entonces Trust baja además. Si además estaba sin
## señal (`offline`), su decisión no baja Trust, que ya baja mientras esté desconectado (decisión de Benja).
func _init(outcome: RuleEvaluator.Outcome, answered_by_player: bool, balance: BalanceData,
		rng: RandomNumberGenerator, offline := false) -> void:
```

En `scripts/core/consequence.gd`, reemplazar:

```gdscript
	if not answered_by_player:
```

por:

```gdscript
	if offline:
		trust_change = 0.0
	elif not answered_by_player:
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Señal de los 3 amigos mientras no exista la del Plan 6. Bájala para ver la estática.
@export_range(1, 100) var test_signal := 100
```

por:

```gdscript
## Señal con la que empiezan los 3 amigos. Bájala para ver la estática; con 0 empiezan desconectados.
@export_range(0, 100) var test_signal := 100
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Matías pregunta por una categoría: cuesta 5 s y el amigo responde. false si no se pudo preguntar.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not request.pay_question():
```

por:

```gdscript
## Matías pregunta por una categoría: cuesta 5 s y el amigo responde. false si no se pudo preguntar:
## sin solicitud, sin tiempo o sin señal.
func ask(friend_index: int, category: ClueCategory.Kind) -> bool:
	var request := requests[friend_index]
	if request == null or not state.friends[friend_index].is_online() or not request.pay_question():
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Devuelve false si el amigo no espera respuesta.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null:
```

por:

```gdscript
## Devuelve false si el amigo no espera respuesta o está sin señal.
func answer(friend_index: int, action: ActionData) -> bool:
	var request := requests[friend_index]
	if request == null or action == null or not state.friends[friend_index].is_online():
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue.
func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng)
```

por:

```gdscript
## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
## (decisión de Benja), y sus mensajes llegan tapados enteros.
func _decide_alone(friend_index: int) -> void:
	var request := requests[friend_index]
	request.decide_alone(rng, not state.friends[friend_index].is_online())
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng)
```

por:

```gdscript
	request.consequence = Consequence.new(request.outcome, request.answered_by_player, catalog.balance, rng,
			request.decided_offline)
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
## y {friend} y {action}.
```

por:

```gdscript
## y {friend} y {action}. CHOSEN_OFFLINE: el amigo decidió solo y sin señal.
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
const CHOSEN_ALONE_KEY := "END_CHOSEN_ALONE"
```

por:

```gdscript
const CHOSEN_ALONE_KEY := "END_CHOSEN_ALONE"
const CHOSEN_OFFLINE_KEY := "END_CHOSEN_OFFLINE"
```

En `scripts/core/ending_text.gd`, reemplazar:

```gdscript
		lines.append(_line(translate, CHOSEN_BY_PLAYER_KEY, {"action": chosen}))
```

por:

```gdscript
		lines.append(_line(translate, CHOSEN_BY_PLAYER_KEY, {"action": chosen}))
	elif request.decided_offline:
		lines.append(_line(translate, CHOSEN_OFFLINE_KEY, {"friend": friend, "action": chosen}))
```

El texto de la pantalla final es un borrador real que Benja puede cambiar, conservando los marcadores entre llaves.

Agregar al final de `data/text/ui.csv`:

```csv
END_CHOSEN_OFFLINE,{friend} estaba sin señal y eligió: {action}.,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `276 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Un amigo sin señal" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Los avisos de la noche en el chat

**Archivos:**

- Modificar: `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/ui/chat_message_view.gd`, `scripts/desk/request_manager.gd`, `scripts/desk/night_manager.gd`, `data/text/messages.csv`, `data/text/ui.csv`, `test/test_chat_message_view.gd`, `test/test_message_builder.gd`, `test/test_request_manager.gd`, `test/test_night_manager.gd`

Lo que pasa en la noche se avisa en el chat del amigo: él cuenta que mandó un video, y el juego avisa, centrado, si el video se recibió (en verde) o se perdió (en rojo), si el amigo se quedó sin señal (en rojo) y si volvió a conectarse (en verde). `RequestManager.report()` recibe lo que pasó en cada paso, y `restore_signal()` es lo que llama el mixer cuando Audio Sync sale bien.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_message_view.gd`:

```gdscript
func test_un_aviso_bueno_va_en_verde() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, null)
	message.tone = ChatMessage.Tone.GOOD
	message.add_fragment("Video de León recibido: 1 de 3")
	var view := _make_view(message)
	var label := _label(view)
	check_eq(label.get_parsed_text(), "── Video de León recibido: 1 de 3 ──", "entre líneas")
	check(label.text.begins_with("[center]"), "centrado")
	check(label.text.contains(ChatMessageView.GOOD_COLOR), "en verde")
	check(not label.text.contains(ChatMessageView.DANGER_COLOR), "no en rojo")
	view.free()
	return true
```

Agregar al final de `test/test_message_builder.gd`:

```gdscript
func test_el_amigo_avisa_que_mando_un_video() -> bool:
	var message := MessageBuilder.video_sent(_translate)
	check_eq(message.sender, ChatMessage.Sender.FRIEND, "lo escribe el amigo")
	check_eq(message.plain_text(), MessageBuilder.VIDEO_SENT_KEY + ".", "su texto")
	return true


func test_los_avisos_del_juego() -> bool:
	var translate := func(_key: String) -> String: return "{friend}: {received} de {quota}"
	var values := {"friend": "León", "received": 1, "quota": 3}
	var notice := MessageBuilder.notice("K_NOTICE", values, ChatMessage.Tone.GOOD, translate)
	check_eq(notice.sender, ChatMessage.Sender.SYSTEM, "lo escribe el juego")
	check_eq(notice.tone, ChatMessage.Tone.GOOD, "es una buena noticia")
	check_eq(notice.plain_text(), "León: 1 de 3", "con sus datos")
	return true


func test_los_textos_de_videos_y_senal_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check(String(TranslationServer.translate(MessageBuilder.VIDEO_SENT_KEY)) != MessageBuilder.VIDEO_SENT_KEY,
			"falta FRIEND_VIDEO_SENT en messages.csv")
	for key: String in [MessageBuilder.VIDEO_RECEIVED_KEY, MessageBuilder.VIDEO_LOST_KEY, MessageBuilder.SIGNAL_LOST_KEY,
			MessageBuilder.SIGNAL_BACK_KEY]:
		check(String(TranslationServer.translate(key)).contains("{friend}"), "%s debe estar en ui.csv con {friend}" % key)
	for placeholder: String in ["{received}", "{quota}"]:
		check(String(TranslationServer.translate(MessageBuilder.VIDEO_RECEIVED_KEY)).contains(placeholder),
				"CHAT_VIDEO_RECEIVED debe tener %s" % placeholder)
	TranslationServer.set_locale(previous)
	return true
```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

por:

```gdscript
const NightState := preload("res://scripts/core/night_state.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
const VideoSchedule := preload("res://scripts/core/video_schedule.gd")
```

Agregar al final de `test/test_request_manager.gd`:

```gdscript
## El texto de `key` en ui.csv, con sus datos.
func _ui(key: String, values: Dictionary) -> String:
	return String(TranslationServer.translate(key)).format(values)


func test_avisa_en_el_chat_los_videos_y_la_senal() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	var night_events := NightState.Events.new()
	night_events.videos = VideoSchedule.Changes.new()
	night_events.disconnected.append(0)
	night_events.videos.offered.append(1)
	night_events.videos.received.append(2)
	night_events.videos.lost.append(1)
	manager.state.videos.received = 1
	manager.report(night_events)
	check_eq(events.map(func(entry: Array) -> int: return entry[1]), [0, 1, 2, 1], "cada aviso en el chat de su amigo")
	var messages := _messages(events)
	if messages.size() == 4:
		check_eq((messages[0] as ChatMessage).plain_text(), _ui("CHAT_SIGNAL_LOST", {"friend": "K_FRIEND_leon"}),
				"León se quedó sin señal")
		check_eq((messages[0] as ChatMessage).tone, ChatMessage.Tone.DANGER, "en rojo")
		check_eq((messages[1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "Gonzalo avisa que mandó un video")
		check_eq((messages[2] as ChatMessage).plain_text(),
				_ui("CHAT_VIDEO_RECEIVED", {"friend": "K_FRIEND_agustin", "received": 1, "quota": 2}), "con la cuota")
		check_eq((messages[2] as ChatMessage).tone, ChatMessage.Tone.GOOD, "el video recibido, en verde")
		check_eq((messages[3] as ChatMessage).plain_text(), _ui("CHAT_VIDEO_LOST", {"friend": "K_FRIEND_gonzalo"}),
				"el de Gonzalo se perdió")
		check_eq((messages[3] as ChatMessage).tone, ChatMessage.Tone.DANGER, "en rojo")
	manager.free()
	return true


func test_restaurar_la_senal_avisa_si_estaba_desconectado() -> bool:
	var manager := _make_manager()
	var events := []
	_record(manager, events)
	manager.restore_signal(1)
	check(events.is_empty(), "si tenía señal, no hay aviso")
	manager.state.friends[1].signal_level = 0.0
	manager.restore_signal(1)
	check_eq(manager.state.friends[1].signal_level, 100.0, "señal al 100")
	var messages := _messages(events)
	check_eq(messages.size(), 1, "avisa que volvió")
	if messages.size() == 1:
		check_eq((messages[0] as ChatMessage).plain_text(), _ui("CHAT_SIGNAL_BACK", {"friend": "K_FRIEND_gonzalo"}),
				"Gonzalo volvió")
		check_eq((messages[0] as ChatMessage).tone, ChatMessage.Tone.GOOD, "en verde")
	manager.free()
	return true
```

En `test/test_night_manager.gd`, reemplazar:

```gdscript
const Fixtures := preload("res://test/content_fixtures.gd")
```

por:

```gdscript
const Fixtures := preload("res://test/content_fixtures.gd")
const ChatMessage := preload("res://scripts/core/chat_message.gd")
```

Agregar al final de `test/test_night_manager.gd`:

```gdscript
func test_los_avisos_de_la_noche_llegan_al_chat() -> bool:
	var night := _make_night()
	var senders := []
	_requests.message_added.connect(func(_friend_index: int, message: ChatMessage) -> void:
		senders.append(message.sender))
	_advance(night, 140)
	check_eq(senders, [ChatMessage.Sender.FRIEND], "el amigo avisa que mandó el video")
	_advance(night, 15)
	check_eq(senders, [ChatMessage.Sender.FRIEND, ChatMessage.Sender.SYSTEM], "sin descargarlo se pierde, y el juego lo avisa")
	_free(night)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `237 pruebas OK, 4 fallidas`. No se pudieron cargar `test_chat_message_view.gd`, `test_message_builder.gd` ni `test_request_manager.gd`, y falla `test_night_manager.gd :: test_los_avisos_de_la_noche_llegan_al_chat`.

- [ ] **Paso 3: Los avisos**

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript
enum Sender { FRIEND, PLAYER, SYSTEM }
```

por:

```gdscript
enum Sender { FRIEND, PLAYER, SYSTEM }
## Un aviso del juego trae una mala noticia, en rojo, o una buena, en verde.
enum Tone { DANGER, GOOD }
```

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript
var sender: Sender
```

por:

```gdscript
var sender: Sender
## Solo cuenta en los avisos del juego.
var tone := Tone.DANGER
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
## Los avisos del juego, como el de daño.
const DANGER_COLOR := "ff4d5e"
```

por:

```gdscript
## Los avisos del juego: los malos, como el de daño, y los buenos, como un video recibido.
const DANGER_COLOR := "ff4d5e"
const GOOD_COLOR := "7ee08a"
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
		_label.text = "[center]%s[/center]" % _colored("── %s ──" % message.plain_text().replace("[", "[lb]"), DANGER_COLOR)
```

por:

```gdscript
		var color := GOOD_COLOR if message.tone == ChatMessage.Tone.GOOD else DANGER_COLOR
		_label.text = "[center]%s[/center]" % _colored("── %s ──" % message.plain_text().replace("[", "[lb]"), color)
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
const DAMAGE_KEY := "CHAT_DAMAGE"
```

por:

```gdscript
const DAMAGE_KEY := "CHAT_DAMAGE"
## El amigo avisa que mandó un video (messages.csv).
const VIDEO_SENT_KEY := "FRIEND_VIDEO_SENT"
## Avisos del juego sobre los videos y la señal (ui.csv). Llevan {friend}; el del video recibido, también
## {received} y {quota}.
const VIDEO_RECEIVED_KEY := "CHAT_VIDEO_RECEIVED"
const VIDEO_LOST_KEY := "CHAT_VIDEO_LOST"
const SIGNAL_LOST_KEY := "CHAT_SIGNAL_LOST"
const SIGNAL_BACK_KEY := "CHAT_SIGNAL_BACK"
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

por:

```gdscript
	return message


## El amigo avisa que mandó un video, que espera su descarga.
static func video_sent(translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment(_text(translate, VIDEO_SENT_KEY))
	return message


## Un aviso del juego, centrado: el texto de `key` con sus `values`. DANGER va en rojo y GOOD, en verde.
static func notice(key: String, values: Dictionary, tone: ChatMessage.Tone, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.SYSTEM, null)
	message.tone = tone
	message.add_fragment(_text(translate, key).format(values))
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Las solicitudes de la noche (planes 3 a 5): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
```

por:

```gdscript
## Las solicitudes de la noche (planes 3 a 6): las genera, avanza sus temporizadores, recibe las preguntas,
## los clics y las respuestas del chat, arma los mensajes con estática y resuelve las consecuencias.
## Desde el Plan 6 también avisa en el chat lo que pasa con los videos y la señal.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	return true


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
```

por:

```gdscript
	return true


## Avisa en el chat lo que pasó en un paso de la noche: el amigo que se quedó sin señal, el video que mandó
## un amigo y el que se recibió o se perdió. NightManager lo llama después de avanzar el estado de la noche.
func report(events: NightState.Events) -> void:
	for friend_index: int in events.disconnected:
		_add_notice(friend_index, MessageBuilder.SIGNAL_LOST_KEY, ChatMessage.Tone.DANGER)
	for friend_index: int in events.videos.offered:
		_add_friend_message(friend_index, MessageBuilder.video_sent(tr))
	for friend_index: int in events.videos.received:
		_add_notice(friend_index, MessageBuilder.VIDEO_RECEIVED_KEY, ChatMessage.Tone.GOOD)
	for friend_index: int in events.videos.lost:
		_add_notice(friend_index, MessageBuilder.VIDEO_LOST_KEY, ChatMessage.Tone.DANGER)


## Audio Sync salió bien: la señal del amigo vuelve a 100. Si estaba desconectado, el chat avisa que volvió.
func restore_signal(friend_index: int) -> void:
	var friend := state.friends[friend_index]
	var was_offline := not friend.is_online()
	friend.restore_signal()
	if was_offline:
		_add_notice(friend_index, MessageBuilder.SIGNAL_BACK_KEY, ChatMessage.Tone.GOOD)


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	message_added.emit(friend_index, MessageBuilder.damage_notice(request, friend_name, friend.health, friend.max_health, tr))


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
```

por:

```gdscript
	message_added.emit(friend_index, MessageBuilder.damage_notice(request, friend_name, friend.health, friend.max_health, tr))


## Un aviso del juego en el chat del amigo, con su nombre y los videos de la noche.
func _add_notice(friend_index: int, key: String, tone: ChatMessage.Tone) -> void:
	var values := {"friend": tr(catalog.friends[friend_index].name_key), "received": state.videos.received,
			"quota": state.videos.quota}
	message_added.emit(friend_index, MessageBuilder.notice(key, values, tone, tr))


func _add_friend_message(friend_index: int, message: ChatMessage) -> void:
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
	var events := requests.state.advance(delta)
```

por:

```gdscript
	var events := requests.state.advance(delta)
	requests.report(events)
```

Los textos son borradores reales que Benja corrige: lo que dice el amigo, en primera persona, y los avisos del juego, que conservan sus marcadores entre llaves.

Agregar al final de `data/text/messages.csv`:

```csv
FRIEND_VIDEO_SENT,"Te mandé un video, Mati. ¡Descárgalo antes de que se corte!",
```

Agregar al final de `data/text/ui.csv`:

```csv
CHAT_VIDEO_RECEIVED,Video de {friend} recibido: {received} de {quota},
CHAT_VIDEO_LOST,Se perdió el video de {friend},
CHAT_SIGNAL_LOST,{friend} se quedó sin señal,
CHAT_SIGNAL_BACK,{friend} volvió a conectarse,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `283 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Avisos de videos y señal en el chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: Las entradas del PC muestran la señal

**Archivos:**

- Modificar: `scripts/ui/chat_entry.gd`, `scenes/ui/chat_entry.tscn`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_chat_entry.gd`, `test/test_desk_scene.gd`

Cada entrada del PC muestra 5 barras de señal entre el nombre y la vida, llenas hasta el nivel de la señal y vacías arriba de él, para que no dependa del color. Las barras son provisionales hasta su arte (`docs/06` §3). La entrada titila mientras se anuncia una interferencia, se ve gris y dice "Sin señal" si el amigo está desconectado, y parpadea con "Video 12" mientras su video espera la descarga.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_entry.gd`:

```gdscript
## Las barras llenas de la señal, de la más baja a la más alta.
func _filled_bars(entry: Node2D) -> Array:
	return entry.get_node("Signal").get_children().map(func(bar: Panel) -> bool:
		return (bar.get_theme_stylebox(&"panel") as StyleBoxFlat).draw_center)


func test_barras_de_senal() -> bool:
	var entry := _make_entry()
	entry.set_signal(100.0)
	check_eq(_filled_bars(entry), [true, true, true, true, true], "señal llena: 5 barras")
	entry.set_signal(45.0)
	check_eq(_filled_bars(entry), [true, true, true, false, false], "una barra por cada 20: 3 llenas y 2 vacías")
	entry.set_signal(0.0)
	check_eq(_filled_bars(entry), [false, false, false, false, false], "sin señal, todas vacías")
	check_eq(entry.get_node("Signal").get_child_count(), 5, "se rehacen, no se acumulan")
	entry.free()
	return true


func test_titila_si_viene_una_interferencia() -> bool:
	var entry := _make_entry()
	entry.set_interference_warning(true)
	entry._process(0.05)
	check(entry.modulate.a < 1.0, "se apaga")
	entry._process(0.12)
	check_eq(entry.modulate.a, 1.0, "y se vuelve a encender")
	entry._process(0.12)
	check(entry.modulate.a < 1.0, "titila")
	entry.set_interference_warning(false)
	check_eq(entry.modulate.a, 1.0, "al pasar, queda encendida")
	entry.free()
	return true


func test_video_y_sin_senal() -> bool:
	var entry := _make_entry()
	var timer := entry.get_node("TimerLabel") as Label
	entry.show_video(12)
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_VIDEO")).format({"seconds": 12}), "el video")
	check(timer.text.contains("12"), "con los segundos")
	entry.show_offline()
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_OFFLINE")), "sin señal")
	check(timer.text != "ENTRY_OFFLINE", "el texto está en ui.csv")
	entry.free()
	return true
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
```

por:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const InterferenceSchedule := preload("res://scripts/core/interference_schedule.gd")
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
func test_las_entradas_muestran_la_senal() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.friends[0].signal_level = 30.0
	state.friends[2].signal_level = 0.0
	desk._process(0.0)
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").signal_bars, 2, "León con 2 barras")
	var agustin := desk.get_node("DeskPlane/Entries/EntryAgustin")
	check_eq(agustin.state, ChatEntry.State.DISCONNECTED, "Agustín, sin señal")
	check_eq((agustin.get_node("TimerLabel") as Label).text, String(TranslationServer.translate("ENTRY_OFFLINE")), "lo dice")
	desk.free()
	return true


func test_un_video_hace_parpadear_la_entrada() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.videos.add_extra(1, 0.0)
	state.advance(0.1)
	desk._process(0.0)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "en alerta")
	check_eq((gonzalo.get_node("TimerLabel") as Label).text,
			String(TranslationServer.translate("ENTRY_VIDEO")).format({"seconds": 15}), "15 s para empezar a descargarlo")
	desk.free()
	return true


func test_la_entrada_titila_antes_de_una_interferencia() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	state.interferences.pending.clear()
	state.interferences.pending.append(InterferenceSchedule.Interference.new(2, state.elapsed + 2.0))
	desk._process(0.0)
	check(desk.get_node("DeskPlane/Entries/EntryAgustin").interference_warning, "Agustín titila")
	check(not desk.get_node("DeskPlane/Entries/EntryLeon").interference_warning, "León no")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `283 pruebas OK, 6 fallidas`. Fallan las 3 pruebas nuevas de `test_chat_entry.gd` y las 3 de `test_desk_scene.gd`.

- [ ] **Paso 3: La entrada y el escritorio**

En `scenes/ui/chat_entry.tscn`, reemplazar:

```ini
offset_right = 120.0
```

por:

```ini
offset_right = 94.0
```

En `scenes/ui/chat_entry.tscn`, reemplazar:

```ini
text = "AMIGO"
```

por:

```ini
text = "AMIGO"

[node name="Signal" type="HBoxContainer" parent="."]
offset_left = 98.0
offset_top = 7.0
offset_right = 117.0
offset_bottom = 19.0
mouse_filter = 2
theme_override_constants/separation = 1
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
## El arte pone el fondo; Godot pone el nombre, la vida, el estado y el temporizador.
```

por:

```gdscript
## El arte pone el fondo; Godot pone el nombre, la señal, la vida, el estado y el temporizador.
## Titila mientras se anuncia una interferencia (diseño §10.1).
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
const HEALTH_COLOR := Color(0.85, 0.9, 0.95)
```

por:

```gdscript
const HEALTH_COLOR := Color(0.85, 0.9, 0.95)
## Las barras de señal también son provisionales (docs/06 §3): 5 barras que crecen de a 2 px.
const SIGNAL_BARS := 5
const SIGNAL_BAR_WIDTH := 3
## Lo que dice el temporizador cuando el amigo mandó un video (lleva {seconds}) y cuando está sin señal (ui.csv).
const VIDEO_KEY := "ENTRY_VIDEO"
const OFFLINE_KEY := "ENTRY_OFFLINE"
## Cada cuánto titila la entrada mientras se anuncia una interferencia.
const FLICKER_SECONDS := 0.12
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
var max_health := -1

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
```

por:

```gdscript
var max_health := -1
## Las barras de señal que muestra, de 0 a 5. -1 hasta la primera vez.
var signal_bars := -1
## Se anuncia una interferencia: la entrada titila.
var interference_warning := false

var _flicker_time := 0.0

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _signal_box: HBoxContainer = $Signal
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
	set_seconds_left(-1)
```

por:

```gdscript
	set_seconds_left(-1)


func _process(delta: float) -> void:
	if not interference_warning:
		return
	_flicker_time += delta
	modulate.a = 0.35 if fmod(_flicker_time, FLICKER_SECONDS * 2.0) < FLICKER_SECONDS else 1.0
```

En `scripts/ui/chat_entry.gd`, reemplazar:

```gdscript
	_timer_label.text = tr(STUNNED_KEY).format({"seconds": seconds})
```

por:

```gdscript
	_timer_label.text = tr(STUNNED_KEY).format({"seconds": seconds})


## El amigo mandó un video: cuánto le queda para empezar o terminar la descarga, en lugar del temporizador.
func show_video(seconds: int) -> void:
	_timer_label.visible = true
	_timer_label.text = tr(VIDEO_KEY).format({"seconds": seconds})


## El amigo está sin señal.
func show_offline() -> void:
	_timer_label.visible = true
	_timer_label.text = tr(OFFLINE_KEY)


## Titila mientras se anuncia una interferencia; al pasar, queda encendida.
func set_interference_warning(active: bool) -> void:
	interference_warning = active
	if not active:
		_flicker_time = 0.0
		modulate.a = 1.0


## Una barra por cada 20 de señal: llenas hasta su nivel y vacías (solo el borde) arriba de él, para que no
## dependa del color. Solo se rehacen si cambió cuántas van llenas.
func set_signal(level: float) -> void:
	var bars := ceili(clampf(level, 0.0, 100.0) / (100.0 / SIGNAL_BARS))
	if bars == signal_bars:
		return
	signal_bars = bars
	for bar: Node in _signal_box.get_children():
		_signal_box.remove_child(bar)
		bar.queue_free()
	for index in SIGNAL_BARS:
		var bar := Panel.new()
		bar.custom_minimum_size = Vector2(SIGNAL_BAR_WIDTH, 4 + index * 2)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override(&"panel", _pip_style(index < bars))
		_signal_box.add_child(bar)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Seleccionada si su chat está abierto; si no, en alerta mientras espera respuesta, o más oscura si el amigo
## está aturdido. El tiempo que le queda para responder o para recuperarse, y su vida.
func _refresh_entries() -> void:
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := _requests.state.friends[index]
		var state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			state = ChatEntry.State.SELECTED
		elif request != null:
			state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			state = ChatEntry.State.STUNNED
		if entry.state != state:
			entry.set_state(state)
		entry.set_health(friend.health, friend.max_health)
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
```

por:

```gdscript
## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta o la
## descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le queda para responder,
## para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y si viene una
## interferencia.
func _refresh_entries() -> void:
	var state := _requests.state
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := state.friends[index]
		var offer := state.videos.offer_for(index)
		var entry_state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			entry_state = ChatEntry.State.SELECTED
		elif not friend.is_online():
			entry_state = ChatEntry.State.DISCONNECTED
		elif request != null or offer != null:
			entry_state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			entry_state = ChatEntry.State.STUNNED
		if entry.state != entry_state:
			entry.set_state(entry_state)
		entry.set_health(friend.health, friend.max_health)
		entry.set_signal(friend.signal_level)
		entry.set_interference_warning(state.interference_warning(index))
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif offer != null:
			entry.show_video(ceili(offer.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		elif not friend.is_online():
			entry.show_offline()
```

Agregar al final de `data/text/ui.csv`:

```csv
ENTRY_VIDEO,Video {seconds},
ENTRY_OFFLINE,Sin señal,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `289 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ data/ test/
git commit -m "Señal, interferencias y videos en las entradas del PC" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---
### Tarea 9: La descarga en el chat

**Archivos:**

- Modificar: `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scenes/ui/chat_theme.tres`, `data/text/ui.csv`, `test/test_chat_panel.gd`

Si el amigo del chat mandó un video, su barra de descarga aparece encima de la barra de identificación, y la conversación se acorta para dejarle lugar. Mientras se mantiene presionada, el video se descarga. La barra se llena y dice cuánto va y el tiempo que queda, y si la descarga es lenta o no avanza, por qué. Con el amigo sin señal, el chat no deja preguntar ni responder y pide sincronizarlo en el mixer.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_panel.gd`:

```gdscript
## León mandó un video, que espera su descarga.
func _offer_video_from_leon() -> void:
	_manager.state.videos.add_extra(0, 0.0)
	_manager.state.advance(0.1)


func _download_text(panel: Control) -> String:
	return (panel.get_node("Panel/Download/Text") as Label).text


func test_la_descarga_aparece_con_el_video() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	panel._process(0.0)
	var download := panel.get_node("Panel/Download") as Control
	var conversations := panel.get_node("Panel/Conversations") as Control
	check(not download.visible, "sin video no hay barra")
	check_eq(conversations.offset_bottom, 431.0, "la conversación usa todo el alto")
	_offer_video_from_leon()
	panel._process(0.0)
	check(download.visible, "llegó el video de León")
	check_eq(conversations.offset_bottom, 395.0, "la conversación se acorta")
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_START").format({"seconds": 15, "percent": 0}).to_upper(),
			"pide mantener presionado, con el tiempo para empezar")
	panel.open_for(1)
	check(not download.visible, "Gonzalo no mandó nada")
	_free(panel)
	return true


func test_mantener_presionado_descarga() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_offer_video_from_leon()
	var hold := panel.get_node("Panel/Download/Hold") as Button
	hold.button_down.emit()
	panel._process(0.0)
	check_eq(_manager.state.holding_download, 0, "descarga el video de León")
	_manager.state.advance(1.0)
	panel._process(0.0)
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_ACTIVE").format({"seconds": 19, "percent": 10}).to_upper(),
			"10 % en 1 s, con 20 s para terminar")
	check(is_equal_approx((panel.get_node("Panel/Download/Bar") as ProgressBar).value, 10.0), "la barra avanza")
	hold.button_up.emit()
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al soltar se pausa")
	check_eq(_download_text(panel), "▼ " + tr("DOWNLOAD_PAUSED").format({"seconds": 19, "percent": 10}).to_upper(),
			"en pausa")
	_free(panel)
	return true


func test_cerrar_el_chat_suelta_la_descarga() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_offer_video_from_leon()
	(panel.get_node("Panel/Download/Hold") as Button).button_down.emit()
	panel._process(0.0)
	panel.hide()
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "con el chat cerrado no se descarga")
	panel.open_for(0)
	panel._process(0.0)
	check_eq(_manager.state.holding_download, -1, "al volver hay que presionar de nuevo")
	_free(panel)
	return true


func test_sin_senal_no_se_pregunta_ni_responde() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	_memory.open_page(0, _beast())
	_manager.start_request(0)
	_manager.state.friends[0].signal_level = 0.0
	panel._process(0.0)
	for button: Button in _question_buttons(panel):
		check(button.disabled, "no se puede preguntar")
	for button: Button in _answer_buttons(panel):
		check(button.disabled, "ni responder")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text,
			tr("CHAT_OFFLINE").format({"friend": tr(_manager.catalog.friends[0].name_key)}), "pide sincronizarlo")
	_free(panel)
	return true


func test_los_textos_de_la_descarga_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var panel_script := preload("res://scripts/ui/chat_panel.gd")
	for key: String in [panel_script.DOWNLOAD_START_KEY, panel_script.DOWNLOAD_ACTIVE_KEY, panel_script.DOWNLOAD_SLOW_KEY,
			panel_script.DOWNLOAD_PAUSED_KEY, panel_script.DOWNLOAD_OFFLINE_KEY]:
		check(String(TranslationServer.translate(key)).contains("{seconds}"), "%s debe estar en ui.csv con {seconds}" % key)
	for key: String in [panel_script.DOWNLOAD_ACTIVE_KEY, panel_script.DOWNLOAD_SLOW_KEY, panel_script.DOWNLOAD_PAUSED_KEY]:
		check(String(TranslationServer.translate(key)).contains("{percent}"), "%s debe tener {percent}" % key)
	check(String(TranslationServer.translate(panel_script.OFFLINE_KEY)).contains("{friend}"), "CHAT_OFFLINE debe tener {friend}")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `289 pruebas OK, 5 fallidas`. Fallan las 5 pruebas nuevas de `test_chat_panel.gd`.

- [ ] **Paso 3: La barra de descarga**

La barra va en la escena del chat, entre la conversación y la barra de identificación:

En `scenes/ui/chat_panel.tscn`, reemplazar:

```ini
mouse_filter = 2

[node name="IdentifyBar" type="HBoxContainer" parent="Panel"]
```

por:

```ini
mouse_filter = 2

[node name="Download" type="Control" parent="Panel"]
visible = false
layout_mode = 0
offset_left = 25.0
offset_top = 401.0
offset_right = 423.0
offset_bottom = 431.0
mouse_filter = 2

[node name="Bar" type="ProgressBar" parent="Panel/Download"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
theme_type_variation = &"DownloadBar"
show_percentage = false

[node name="Text" type="Label" parent="Panel/Download"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_colors/font_color = Color(0.86, 0.95, 0.89, 1)
horizontal_alignment = 1
vertical_alignment = 1

[node name="Hold" type="Button" parent="Panel/Download"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
focus_mode = 0
theme_type_variation = &"DownloadHold"

[node name="IdentifyBar" type="HBoxContainer" parent="Panel"]
```

Su estilo va en el tema del chat: un fondo como el de los botones, el relleno en verde y un borde verde al pasar el mouse o presionarla.

En `scenes/ui/chat_theme.tres`, reemplazar:

```ini
border_color = Color(0.25, 0.76, 0.79, 1)

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]
```

por:

```ini
border_color = Color(0.25, 0.76, 0.79, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_download_background"]
bg_color = Color(0.03, 0.05, 0.09, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.16, 0.42, 0.47, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_download_fill"]
bg_color = Color(0.15, 0.36, 0.22, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_download_hover"]
draw_center = false
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.49, 0.88, 0.54, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_download_pressed"]
bg_color = Color(0.49, 0.88, 0.54, 0.12)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.49, 0.88, 0.54, 1)

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]
```

En `scenes/ui/chat_theme.tres`, reemplazar:

```ini
ChatTab/styles/pressed = SubResource("StyleBoxFlat_tab_selected")
```

por:

```ini
ChatTab/styles/pressed = SubResource("StyleBoxFlat_tab_selected")
DownloadBar/base_type = &"ProgressBar"
DownloadBar/styles/background = SubResource("StyleBoxFlat_download_background")
DownloadBar/styles/fill = SubResource("StyleBoxFlat_download_fill")
DownloadHold/base_type = &"Button"
DownloadHold/styles/focus = SubResource("StyleBoxEmpty_focus")
DownloadHold/styles/hover = SubResource("StyleBoxFlat_download_hover")
DownloadHold/styles/hover_pressed = SubResource("StyleBoxFlat_download_pressed")
DownloadHold/styles/normal = SubResource("StyleBoxEmpty_focus")
DownloadHold/styles/pressed = SubResource("StyleBoxFlat_download_pressed")
```

`scripts/ui/chat_panel.gd` (archivo completo):

```gdscript
extends Control
## Panel del chat (planes 3, 4 y 6): una pestaña por amigo con su tiempo y un aviso de mensajes nuevos,
## la conversación, la descarga de su video, la barra de identificación, las preguntas y las respuestas.
## Los botones de respuesta son las acciones de la página que el cuaderno tiene abierta para ese amigo
## (diseño §8.5). Un video se descarga manteniendo presionada su barra (decisión de Benja), y con un amigo
## sin señal no se puede preguntar ni responder.
## Se ve como una terminal: cada mensaje lleva el nombre de quien escribe ("LEÓN:") en su color, y las
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.

## Clic en el nombre de la entidad: el cuaderno abre su página.
signal entity_page_requested(friend_index: int, entity: EntityData)
## Se eligió la conversación de un amigo: el cuaderno salta a su página.
signal friend_selected(friend_index: int)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const MessageBuilder := preload("res://scripts/core/message_builder.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Textos del panel (ui.csv). IDENTIFY_PROGRESS lleva {marked} y {total}; ANSWER_FROM_PAGE lleva {entity}.
const PROGRESS_KEY := "IDENTIFY_PROGRESS"
const THINKING_KEY := "IDENTIFY_THINKING"
const OPEN_NOTEBOOK_KEY := "CHAT_OPEN_NOTEBOOK"
const ANSWER_FROM_PAGE_KEY := "ANSWER_FROM_PAGE"
## El nombre de Matías en sus mensajes (ui.csv).
const PLAYER_NAME_KEY := "CHAT_PLAYER_NAME"
## El color de Matías: el de la terminal.
const PLAYER_COLOR := Color(0.25, 0.76, 0.79)
## Aviso de mensajes sin leer en una pestaña.
const UNREAD_MARK := "•"
## Un botón de respuesta por acción: cada entidad tiene 4 (docs/02 §5.1).
const ANSWER_COUNT := 4
## La descarga de un video (ui.csv). Llevan {seconds}; las que muestran el avance, también {percent}.
const DOWNLOAD_START_KEY := "DOWNLOAD_START"
const DOWNLOAD_ACTIVE_KEY := "DOWNLOAD_ACTIVE"
const DOWNLOAD_SLOW_KEY := "DOWNLOAD_SLOW"
const DOWNLOAD_PAUSED_KEY := "DOWNLOAD_PAUSED"
const DOWNLOAD_OFFLINE_KEY := "DOWNLOAD_OFFLINE"
## La flecha de la descarga, delante de su texto.
const DOWNLOAD_MARK := "▼"
## Sin señal no se puede preguntar ni responder (ui.csv). Lleva {friend}.
const OFFLINE_KEY := "CHAT_OFFLINE"
## Dónde termina la conversación: sobre la barra de identificación o, si hay un video, sobre su descarga.
const CONVERSATION_BOTTOM := 431.0
const CONVERSATION_BOTTOM_WITH_DOWNLOAD := 395.0

var selected_friend := 0

var _manager: RequestManager
var _memory: NotebookMemory
var _friend_names: Array[String] = []
var _friend_colors: Array[Color] = []
var _tabs: Array[Button] = []
var _scrolls: Array[ScrollContainer] = []
var _lists: Array[VBoxContainer] = []
var _unread: Array[bool] = []
var _answer_buttons: Array[Button] = []
## Matías mantiene presionada la barra de descarga.
var _holding_download := false

@onready var _panel: TextureRect = $Panel
@onready var _tab_bar: HBoxContainer = $Panel/Tabs
@onready var _conversation_area: Control = $Panel/Conversations
@onready var _download: Control = $Panel/Download
@onready var _download_bar: ProgressBar = $Panel/Download/Bar
@onready var _download_text: Label = $Panel/Download/Text
@onready var _download_hold: Button = $Panel/Download/Hold
@onready var _progress: Label = $Panel/IdentifyBar/Progress
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _questions: GridContainer = $Panel/Questions
@onready var _answer_hint: Label = $Panel/AnswerHint
@onready var _answers: GridContainer = $Panel/Answers


func _ready() -> void:
	hide()
	_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
	for category: ClueCategory.Kind in MessageBuilder.QUESTION_KEYS:
		var button := Button.new()
		button.text = tr(MessageBuilder.QUESTION_KEYS[category]).to_upper()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_question_pressed.bind(category))
		_questions.add_child(button)
	for index in ANSWER_COUNT:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Las acciones pueden ser largas: el botón crece hacia abajo en vez de salirse del panel.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_answer_pressed.bind(index))
		_answers.add_child(button)
		_answer_buttons.append(button)
	_entity_button.pressed.connect(_on_entity_pressed)
	_panel.gui_input.connect(_on_panel_gui_input)
	_download_hold.button_down.connect(_set_holding_download.bind(true))
	_download_hold.button_up.connect(_set_holding_download.bind(false))
	# Al cerrar el chat, la descarga se suelta.
	visibility_changed.connect(_set_holding_download.bind(false))


## Conecta el panel a las solicitudes y a la memoria del cuaderno. Crea una pestaña y una conversación
## por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData], memory: NotebookMemory) -> void:
	_manager = manager
	_memory = memory
	var tab_group := ButtonGroup.new()
	for index in friends.size():
		_friend_names.append(tr(friends[index].name_key))
		_friend_colors.append(friends[index].color)
		_unread.append(false)
		var tab := Button.new()
		tab.theme_type_variation = &"ChatTab"
		tab.add_theme_color_override(&"font_pressed_color", friends[index].color)
		tab.add_theme_color_override(&"font_hover_pressed_color", friends[index].color)
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(open_for.bind(index))
		_tab_bar.add_child(tab)
		_tabs.append(tab)
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override(&"separation", 6)
		scroll.add_child(list)
		# Cuando la conversación crece (mensaje nuevo o escritura progresiva), baja hasta el final.
		scroll.get_v_scroll_bar().changed.connect(_scroll_to_bottom.bind(scroll))
		_conversation_area.add_child(scroll)
		_scrolls.append(scroll)
		_lists.append(list)
	manager.message_added.connect(_on_message_added)
	manager.request_changed.connect(_on_request_changed)
	manager.request_finished.connect(_on_request_changed)
	_select(selected_friend)


## Abre el panel en la conversación del amigo `friend_index`.
func open_for(friend_index: int) -> void:
	_select(friend_index)
	show()


## Mensajes de un amigo, en orden.
func message_views(friend_index: int) -> Array[Node]:
	return _lists[friend_index].get_children()


func _process(_delta: float) -> void:
	_update_status()


## Actualiza lo que cambia con el tiempo: las pestañas, la barra de identificación, las preguntas,
## las respuestas y la descarga.
func _update_status() -> void:
	if _manager == null:
		return
	for index in _tabs.size():
		_tabs[index].text = _tab_text(index)
	_update_identify_bar()
	_update_questions()
	_update_answers()
	_update_download()


func _select(friend_index: int) -> void:
	_holding_download = false
	selected_friend = friend_index
	_unread[friend_index] = false
	for index in _scrolls.size():
		_scrolls[index].visible = index == friend_index
		_tabs[index].set_pressed_no_signal(index == friend_index)
	_update_status()
	friend_selected.emit(friend_index)


func _tab_text(index: int) -> String:
	var text := _friend_names[index].to_upper()
	var request := _manager.requests[index]
	if request != null:
		text += "  %d" % ceili(request.time_left)
	if _unread[index]:
		text += "  " + UNREAD_MARK
	return text


## Sobre las preguntas: cuántas características van marcadas, "Matías piensa…" o el nombre de la entidad.
func _update_identify_bar() -> void:
	var request := _manager.requests[selected_friend]
	var revealed := request != null and request.identification == FriendRequest.Identification.REVEALED
	_progress.visible = request != null and not revealed
	_entity_button.visible = revealed
	if request == null:
		return
	match request.identification:
		FriendRequest.Identification.PENDING:
			_progress.text = tr(PROGRESS_KEY).format({"marked": request.marked_count(), "total": request.traits.size()})
		FriendRequest.Identification.THINKING:
			_progress.text = tr(THINKING_KEY)
		FriendRequest.Identification.REVEALED:
			_entity_button.text = tr(request.entity.name_key)


## Con 5 s o menos, sin solicitud o con el amigo sin señal, no se puede preguntar.
func _update_questions() -> void:
	var request := _manager.requests[selected_friend]
	var can_ask := request != null and request.can_ask() and _manager.state.friends[selected_friend].is_online()
	for button: Button in _questions.get_children():
		button.disabled = not can_ask


## Las acciones de la página que el cuaderno tiene abierta para este amigo. Sin página, el aviso
## "Abre el cuaderno para responder". Sin solicitud, los botones se ven pero no responden. Con el amigo sin
## señal, tampoco, y el aviso pide sincronizarlo en el mixer.
func _update_answers() -> void:
	var page := _memory.page_for(selected_friend)
	var online := _manager.state.friends[selected_friend].is_online()
	_answers.visible = page != null
	if not online:
		_answer_hint.text = tr(OFFLINE_KEY).format({"friend": _friend_names[selected_friend]})
	elif page == null:
		_answer_hint.text = tr(OPEN_NOTEBOOK_KEY)
	else:
		_answer_hint.text = tr(ANSWER_FROM_PAGE_KEY).format({"entity": tr(page.name_key)})
	if page == null:
		return
	var waiting := _manager.requests[selected_friend] != null and online
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < page.actions.size()
		if button.visible:
			button.text = tr(page.actions[index].label_key)
		button.disabled = not waiting


## La barra de descarga del video que mandó este amigo, si mandó uno. Mientras el chat esté abierto y la
## barra presionada, el video se descarga; al soltarla, se pausa.
func _update_download() -> void:
	var state := _manager.state
	var offer := state.videos.offer_for(selected_friend)
	_download.visible = offer != null
	_conversation_area.offset_bottom = CONVERSATION_BOTTOM_WITH_DOWNLOAD if offer != null else CONVERSATION_BOTTOM
	if offer == null:
		_holding_download = false
	var holding := offer != null and visible and _holding_download
	state.holding_download = selected_friend if holding else -1
	if offer == null:
		return
	_download_bar.value = offer.progress * 100.0
	var signal_level := state.friends[selected_friend].signal_level
	var key := DOWNLOAD_PAUSED_KEY if offer.started else DOWNLOAD_START_KEY
	if signal_level <= 0.0:
		key = DOWNLOAD_OFFLINE_KEY
	elif holding:
		key = DOWNLOAD_SLOW_KEY if signal_level < _manager.catalog.balance.download_slow_below else DOWNLOAD_ACTIVE_KEY
	var values := {"seconds": ceili(offer.time_left), "percent": floori(offer.progress * 100.0)}
	_download_text.text = "%s %s" % [DOWNLOAD_MARK, tr(key).format(values).to_upper()]


func _set_holding_download(holding: bool) -> void:
	_holding_download = holding


func _on_message_added(friend_index: int, message: ChatMessage) -> void:
	# Quién escribe, en mayúsculas y con su color: el amigo o Matías. Los avisos del juego van sin nombre.
	var speaker := ""
	var color := PLAYER_COLOR
	match message.sender:
		ChatMessage.Sender.FRIEND:
			speaker = _friend_names[friend_index].to_upper()
			color = _friend_colors[friend_index]
		ChatMessage.Sender.PLAYER:
			speaker = tr(PLAYER_NAME_KEY).to_upper()
	var view := ChatMessageView.new(message, speaker, color)
	view.clue_clicked.connect(_on_clue_clicked)
	_lists[friend_index].add_child(view)
	if message.sender != ChatMessage.Sender.PLAYER and not (visible and friend_index == selected_friend):
		_unread[friend_index] = true


func _on_clue_clicked(view: ChatMessageView, clue_id: StringName) -> void:
	if _manager.click_clue(view.message, clue_id) == FriendRequest.ClueState.DECOY:
		view.shake(clue_id)


## Vuelve a armar los mensajes de esa solicitud: frases marcadas, en rojo o sin enlaces si terminó.
func _on_request_changed(friend_index: int, request: FriendRequest) -> void:
	for view: ChatMessageView in message_views(friend_index):
		if view.message.request == request:
			view.refresh()


func _on_question_pressed(category: ClueCategory.Kind) -> void:
	_manager.ask(selected_friend, category)


## Responde con la acción `index` de la página abierta para este amigo.
func _on_answer_pressed(index: int) -> void:
	var page := _memory.page_for(selected_friend)
	if page != null and index < page.actions.size():
		_manager.answer(selected_friend, page.actions[index])


func _on_entity_pressed() -> void:
	var request := _manager.requests[selected_friend]
	if request != null:
		entity_page_requested.emit(selected_friend, request.entity)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## El panel tapa los objetos del escritorio, así que recibe sus clics. Con clic derecho se cierra.
func _on_panel_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		hide()
		_panel.accept_event()
```

Los textos de la barra y el aviso de un amigo sin señal son borradores de interfaz que Benja puede cambiar, conservando los marcadores entre llaves:

Agregar al final de `data/text/ui.csv`:

```csv
DOWNLOAD_START,Mantén presionado para descargar · {seconds},
DOWNLOAD_ACTIVE,Descargando {percent} % · {seconds},
DOWNLOAD_SLOW,Señal débil: descarga lenta {percent} % · {seconds},
DOWNLOAD_PAUSED,En pausa {percent} %: mantén presionado · {seconds},
DOWNLOAD_OFFLINE,Sin señal: la descarga no avanza · {seconds},
CHAT_OFFLINE,{friend} está sin señal: sincronízalo en el mixer,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `294 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ data/ test/
git commit -m "Descarga de videos en el chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: Una ronda de Audio Sync

**Archivos:**

- Crear: `scripts/core/audio_sync_round.gd`, `test/test_audio_sync_round.gd`

`AudioSyncRound` es la lógica pura de una ronda: arma el ritmo del amigo, dice qué suena en cada corchea (la base y los aplausos) y evalúa los golpes de Matías. El mixer la avanza y la muestra (Tarea 12).

- [ ] **Paso 1: Escribir las pruebas**

`test/test_audio_sync_round.gd`:

```gdscript
extends "res://test/test_case.gd"

const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")


## Ronda de `beats` aplausos a 100 golpes por minuto (corcheas de 0,3 s), con ±0,15 s de tolerancia.
func _round(beats := 4, seed_value := 6) -> AudioSyncRound:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return AudioSyncRound.new(beats, 100.0, 0.15, rng)


## Avanza la ronda hasta `time` segundos desde que empezó. Devuelve las corcheas a las que llegó.
func _advance_to(sync_round: AudioSyncRound, time: float) -> Array[int]:
	return sync_round.advance(time - sync_round.elapsed)


## Golpea en cada aplauso del patrón, `offset` segundos después de su hora.
func _tap_pattern(sync_round: AudioSyncRound, offset: float) -> void:
	for call_step: int in sync_round.pattern:
		_advance_to(sync_round, sync_round.response_start() + call_step * sync_round.step_seconds + offset)
		sync_round.tap()


func test_el_patron() -> bool:
	for beats: int in [4, 8]:
		for seed_value in 20:
			var sync_round := _round(beats, seed_value)
			var unique := {}
			for step: int in sync_round.pattern:
				unique[step] = true
			check_eq(unique.size(), beats, "%d aplausos distintos" % beats)
			check_eq(sync_round.pattern[0], 0, "el primero, al comienzo")
			check(sync_round.pattern[-1] < beats * 2, "dentro de sus %d corcheas" % (beats * 2))
			var sorted := sync_round.pattern.duplicate()
			sorted.sort()
			check_eq(sync_round.pattern, sorted, "en orden")
	return true


func test_las_partes_de_la_ronda() -> bool:
	var sync_round := _round()
	check_eq(sync_round.step_seconds, 0.3, "una corchea a 100 golpes por minuto")
	check_eq(sync_round.total_steps(), 24, "la cuenta, el amigo y Matías: 8 corcheas cada uno")
	check_eq(sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "empieza con la cuenta")
	_advance_to(sync_round, 2.4)
	check_eq(sync_round.phase(), AudioSyncRound.Phase.CALL, "a los 2,4 s aplaude el amigo")
	_advance_to(sync_round, 4.7)
	check_eq(sync_round.phase(), AudioSyncRound.Phase.RESPONSE, "0,1 s antes de los 4,8 s, le toca a Matías")
	return true


func test_suenan_la_base_y_los_aplausos() -> bool:
	var sync_round := _round()
	check_eq(_advance_to(sync_round, 4.75), range(16), "las 16 corcheas de la cuenta y del amigo, en orden")
	check_eq(range(16).filter(sync_round.is_beat), [0, 2, 4, 6, 8, 10, 12, 14], "la base, en cada golpe")
	check_eq(range(24).filter(sync_round.is_accent), [0, 8, 16], "más fuerte al empezar cada compás")
	var claps := range(24).filter(sync_round.is_clap).map(func(step: int) -> int: return step - 8)
	check_eq(claps, sync_round.pattern, "el amigo aplaude su patrón, después de la cuenta")
	return true


func test_si_repite_el_ritmo_sale_bien() -> bool:
	var sync_round := _round()
	_tap_pattern(sync_round, 0.1)
	check(sync_round.succeeded, "con golpes 0,1 s tarde, sale bien")
	check_eq(sync_round.phase(), AudioSyncRound.Phase.DONE, "y termina")
	check_eq(sync_round.hits(), sync_round.pattern, "acertó todos")
	sync_round = _round()
	_tap_pattern(sync_round, -0.1)
	check(sync_round.succeeded, "0,1 s antes, también")
	return true


func test_un_golpe_de_mas_sale_mal() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, sync_round.response_start())
	check_eq(sync_round.tap(), AudioSyncRound.Tap.HIT, "el primero, a tiempo")
	check_eq(sync_round.tap(), AudioSyncRound.Tap.MISS, "otro golpe en el mismo aplauso sobra")
	check(sync_round.failed and sync_round.phase() == AudioSyncRound.Phase.DONE, "sale mal")
	return true


func test_si_se_le_pasa_un_aplauso_sale_mal() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, sync_round.response_start() + 0.16)
	check(sync_round.failed, "no golpeó el primero")
	check_eq(sync_round.advance(1.0), [], "terminó: ya no suena nada")
	return true


func test_los_golpes_antes_de_su_parte_no_cuentan() -> bool:
	var sync_round := _round()
	_advance_to(sync_round, 1.0)
	check_eq(sync_round.tap(), AudioSyncRound.Tap.IGNORED, "en la cuenta")
	_advance_to(sync_round, 3.0)
	check_eq(sync_round.tap(), AudioSyncRound.Tap.IGNORED, "mientras aplaude el amigo")
	check(not sync_round.failed, "no sale mal")
	_tap_pattern(sync_round, 0.0)
	check(sync_round.succeeded, "y después puede repetirlo")
	return true


func test_con_8_aplausos_dura_dos_compases() -> bool:
	var sync_round := _round(8)
	check_eq(sync_round.steps, 16, "16 corcheas para el amigo")
	check(is_equal_approx(sync_round.response_start(), 7.2), "Matías empieza a los 7,2 s")
	_tap_pattern(sync_round, 0.05)
	check(sync_round.succeeded, "sale bien")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `294 pruebas OK, 1 fallidas`. La falla es `test_audio_sync_round.gd :: no se pudo cargar`, porque el script todavía no existe.

- [ ] **Paso 3: Crear `AudioSyncRound`**

`scripts/core/audio_sync_round.gd`:

```gdscript
extends RefCounted
## Una ronda de Audio Sync (diseño §10.6): sobre una base que marca el tiempo, el amigo aplaude un ritmo y
## después Matías lo repite, con la barra espaciadora o con clics en el mixer (decisión de Benja).
## Lógica pura: el mixer la avanza, la muestra y la hace sonar.
##
## Todo va en corcheas, la mitad de un golpe de la base. La ronda tiene tres partes seguidas:
##   1. la cuenta: un compás de 8 corcheas, solo con la base;
##   2. el amigo aplaude `beats` veces en beats × 2 corcheas, la primera siempre al comienzo;
##   3. Matías repite los aplausos en otras tantas corcheas.
## Sale bien si cada aplauso tiene un golpe de Matías a menos de `tolerance` segundos y no sobra ningún
## golpe. Termina apenas acierta el último aplauso o apenas falla.

## En qué parte va la ronda.
enum Phase { COUNT_IN, CALL, RESPONSE, DONE }
## Qué pasó con un golpe de Matías: no contaba (antes de su parte o al terminar), acertó o sobró.
enum Tap { IGNORED, HIT, MISS }

## Corcheas por compás. La cuenta dura un compás.
const STEPS_PER_BAR := 8

## Aplausos del amigo: 4 u 8, según la noche (docs/02 §6).
var beats := 4
## Segundos de una corchea.
var step_seconds := 0.3
var tolerance := 0.15
## Corcheas de la parte del amigo, que son también las de la parte de Matías.
var steps := 8
## En qué corcheas aplaude el amigo, contadas desde el comienzo de su parte, de menor a mayor.
var pattern: Array[int] = []
## Segundos desde que empezó la ronda.
var elapsed := 0.0
var succeeded := false
var failed := false

## Los aplausos del patrón que Matías ya acertó.
var _hits: Array[int] = []
## La próxima corchea que suena, contada desde el comienzo de la cuenta.
var _next_step := 0


func _init(beat_count: int, bpm: float, tap_tolerance: float, rng: RandomNumberGenerator) -> void:
	beats = beat_count
	step_seconds = 30.0 / bpm
	tolerance = tap_tolerance
	steps = beat_count * 2
	# El primer aplauso marca el comienzo; los demás caen en corcheas al azar, sin repetirse.
	var others: Array[int] = []
	for step in range(1, steps):
		others.append(step)
	for index in range(others.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := others[index]
		others[index] = others[other]
		others[other] = swap
	pattern.append(0)
	pattern.append_array(others.slice(0, beats - 1))
	pattern.sort()


func phase() -> Phase:
	if succeeded or failed:
		return Phase.DONE
	if elapsed < call_start():
		return Phase.COUNT_IN
	if elapsed < response_start() - tolerance:
		return Phase.CALL
	return Phase.RESPONSE


## Corcheas de toda la ronda: la cuenta, el amigo y Matías.
func total_steps() -> int:
	return STEPS_PER_BAR + steps * 2


## Segundos desde el comienzo de la ronda hasta la parte del amigo.
func call_start() -> float:
	return STEPS_PER_BAR * step_seconds


## Segundos desde el comienzo de la ronda hasta la parte de Matías.
func response_start() -> float:
	return (STEPS_PER_BAR + steps) * step_seconds


## La base suena en cada golpe, una corchea sí y otra no.
func is_beat(step: int) -> bool:
	return step % 2 == 0


## Y suena más fuerte al empezar cada compás.
func is_accent(step: int) -> bool:
	return step % STEPS_PER_BAR == 0


## En la corchea `step`, contada desde la cuenta, aplaude el amigo.
func is_clap(step: int) -> bool:
	var call_step := step - STEPS_PER_BAR
	return call_step >= 0 and call_step < steps and pattern.has(call_step)


## Avanza `delta` segundos y devuelve las corcheas (contadas desde la cuenta) a las que llegó en este paso,
## para que suenen. Si a Matías se le pasó un aplauso, la ronda sale mal.
func advance(delta: float) -> Array[int]:
	var reached: Array[int] = []
	if phase() == Phase.DONE:
		return reached
	elapsed += delta
	while _next_step < total_steps() and _next_step * step_seconds <= elapsed:
		reached.append(_next_step)
		_next_step += 1
	for call_step: int in pattern:
		if not _hits.has(call_step) and elapsed > _tap_time(call_step) + tolerance:
			failed = true
	return reached


## Matías golpea ahora. Antes de su parte no cuenta. En su parte, acierta si hay un aplauso sin acertar a
## menos de `tolerance` segundos; si no, el golpe sobra y la ronda sale mal.
func tap() -> Tap:
	if phase() != Phase.RESPONSE:
		return Tap.IGNORED
	for call_step: int in pattern:
		if not _hits.has(call_step) and absf(elapsed - _tap_time(call_step)) <= tolerance:
			_hits.append(call_step)
			succeeded = _hits.size() == pattern.size()
			return Tap.HIT
	failed = true
	return Tap.MISS


## Los aplausos que Matías ya acertó, contados desde el comienzo de su parte.
func hits() -> Array[int]:
	return _hits


## Cuándo tiene que golpear Matías para repetir el aplauso de la corchea `call_step`.
func _tap_time(call_step: int) -> float:
	return response_start() + call_step * step_seconds
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `302 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Ronda de Audio Sync" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: Los sonidos provisionales

**Archivos:**

- Crear: `tools/make_placeholder_sounds.py`, `audio/sfx/*.wav` (los genera el script), `test/test_placeholder_sounds.gd`

Benja pidió que Audio Sync tenga sonido: la base que marca el tiempo y el ritmo del amigo. Hasta los sonidos definitivos (Plan 9), un script de Python genera 7 sonidos provisionales en `audio/sfx/`: el bombo y el platillo de la base, el aplauso del amigo, el golpe de Matías, el acierto, el error y la estática que anuncia una interferencia. Siempre genera los mismos archivos, y para cambiar un sonido basta con reemplazar su archivo.

- [ ] **Paso 1: Escribir la prueba**

`test/test_placeholder_sounds.gd`:

```gdscript
extends "res://test/test_case.gd"
## Los sonidos provisionales del Plan 6 (tools/make_placeholder_sounds.py), hasta los definitivos del Plan 9.

## Nombre de cada archivo de audio/sfx/ y cuántos segundos dura.
const SOUNDS := {
	"sync_kick": 0.22,
	"sync_tick": 0.06,
	"sync_clap": 0.25,
	"sync_tap": 0.12,
	"sync_success": 0.4,
	"sync_fail": 0.44,
	"interference_static": 3.0,
}


func test_los_sonidos_se_cargan() -> bool:
	for sound_name: String in SOUNDS:
		var stream: AudioStream = load("res://audio/sfx/%s.wav" % sound_name)
		check(stream is AudioStreamWAV, "se carga " + sound_name)
		if stream != null:
			check(absf(stream.get_length() - SOUNDS[sound_name]) < 0.01, "%s dura %s s: %s" % [sound_name,
					SOUNDS[sound_name], stream.get_length()])
	return true
```

- [ ] **Paso 2: Verificar que falla**

Importar y correr las pruebas.

Esperado: `302 pruebas OK, 1 fallidas`. La falla es `test_placeholder_sounds.gd :: test_los_sonidos_se_cargan`, porque los sonidos todavía no existen.

- [ ] **Paso 3: Generar los sonidos**

`tools/` tiene un `.gdignore`, así que Godot no importa el script.

`tools/make_placeholder_sounds.py`:

```python
"""Genera los sonidos provisionales del Plan 6 en audio/sfx/ (WAV mono de 16 bits a 44 100 Hz).

Son de relleno, hasta que Benja elija los definitivos (Plan 9): la base y los aplausos de Audio Sync,
el golpe de Matías, el resultado de una ronda y la estática que anuncia una interferencia.
Siempre generan los mismos archivos.

Uso, desde la carpeta del proyecto: python3 -I tools/make_placeholder_sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    with wave.open(str(OUT / (name + ".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


def kick():
    """Bombo de la base: un tono que cae de 155 a 45 Hz, con un golpe al comienzo."""
    samples, phase = [], 0.0
    for i in range(int(0.22 * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (45 + 110 * math.exp(-t * 30)) / RATE
        samples.append(0.9 * math.sin(phase) * math.exp(-t * 14) + 0.25 * math.sin(3 * phase) * math.exp(-t * 400))
    return samples


def tick():
    """Platillo cerrado de la base: ruido agudo y corto."""
    rng, samples, last_x, last_y = random.Random(2), [], 0.0, 0.0
    for i in range(int(0.06 * RATE)):
        x = rng.uniform(-1, 1)
        last_y, last_x = 0.86 * (last_y + x - last_x), x
        samples.append(0.5 * last_y * math.exp(-i / RATE * 70))
    return samples


def clap():
    """Aplauso del amigo: tres golpes de ruido muy seguidos y una cola corta."""
    rng, samples, low, last_x, last_y = random.Random(3), [], 0.0, 0.0, 0.0
    for i in range(int(0.25 * RATE)):
        t = i / RATE
        envelope = max(math.exp(-(t - start) * 120) for start in (0.0, 0.011, 0.022) if t >= start)
        if t >= 0.03:
            envelope = max(envelope, 0.6 * math.exp(-(t - 0.03) * 22))
        low += 0.35 * (rng.uniform(-1, 1) - low)
        last_y, last_x = 0.9 * (last_y + low - last_x), low
        samples.append(1.6 * last_y * envelope)
    return samples


def tap():
    """Golpe de Matías: un bloque de madera, distinto del aplauso."""
    samples = []
    for i in range(int(0.12 * RATE)):
        t = i / RATE
        tone = 0.7 * math.sin(2 * math.pi * 820 * t) + 0.25 * math.sin(2 * math.pi * 1640 * t)
        samples.append(0.8 * tone * math.exp(-t * 45))
    return samples


def notes(frequencies, seconds, decay, volume):
    """Notas seguidas con un timbre de consola (onda casi cuadrada)."""
    samples = []
    for frequency in frequencies:
        for i in range(int(seconds * RATE)):
            t = i / RATE
            wave_value = sum(math.sin(2 * math.pi * frequency * harmonic * t) / harmonic for harmonic in (1, 3, 5))
            samples.append(volume * wave_value * math.exp(-t * decay))
    return samples


def static():
    """Estática de 3 s que anuncia una interferencia: ruido con chasquidos, que aparece y se va."""
    rng, samples, low, crackle, seconds = random.Random(7), [], 0.0, 0.0, 3.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        if rng.random() < 0.002:
            crackle = rng.uniform(0.3, 1.0)
        crackle *= 0.9995
        low += 0.5 * (rng.uniform(-1, 1) - low)
        fade = min(t / 0.2, 1.0, (seconds - t) / 0.3)
        samples.append(0.7 * low * (0.25 + 0.5 * crackle) * fade)
    return samples


if __name__ == "__main__":
    write("sync_kick", kick())
    write("sync_tick", tick())
    write("sync_clap", clap())
    write("sync_tap", tap())
    write("sync_success", notes([523.25, 659.25, 783.99, 1046.5], 0.1, 9, 0.35))
    write("sync_fail", notes([233.08, 174.61], 0.22, 6, 0.4))
    write("interference_static", static())
    print("Sonidos provisionales en", OUT)
```

```bash
python3 -I tools/make_placeholder_sounds.py
```

Esperado: `Sonidos provisionales en /mnt/c/Users/benja/OneDrive/Documents/spook-dial/audio/sfx`, y en `audio/sfx/` quedan 7 archivos `.wav`.

- [ ] **Paso 4: Importar y verificar que pasan**

Al importar, Godot crea un `.import` por sonido.

Esperado: `303 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add tools/ audio/ test/
git commit -m "Sonidos provisionales del mantenimiento" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: El mixer: Audio Sync

**Archivos:**

- Crear: `scripts/ui/mixer_view.gd`, `scenes/ui/mixer_view.tscn`, `test/test_mixer_view.gd`
- Modificar: `data/text/ui.csv`

La vista del mixer desde arriba, provisional hasta el arte de Benja. Se dibuja con rectángulos y la fuente pixel, con los colores del mixer del escritorio: dos perillas de adorno, los dos VU-metros azules (el de Matías a la izquierda y el del amigo a la derecha), una fila de luces con el ritmo, un canal por amigo (su nombre, un LED y el fader a la altura de su señal) y, abajo, qué hacer.

Se abre en el canal del amigo con menos señal. Un clic en un fader, o la barra espaciadora, empieza la ronda: suena la base, el amigo aplaude (se mueve la aguja de la derecha y se encienden luces azules) y, cuando le toca a Matías, las luces se apagan y él repite el ritmo con la barra espaciadora o con clics en el mixer. Si sale bien, la señal del amigo vuelve a 100. Si no, la barra espaciadora empieza otra ronda. Se cierra con clic derecho; `Esc` y un clic fuera se agregan en la Tarea 15.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_mixer_view.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const MIXER := preload("res://scenes/ui/mixer_view.tscn")
const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

var _manager: RequestManager


## Mixer conectado a un manager con el catálogo de prueba, en la noche 2 con Audio Sync de 4 tiempos.
func _make_mixer() -> Control:
	var root := (Engine.get_main_loop() as SceneTree).root
	_manager = RequestManager.new()
	_manager.catalog = Fixtures.make_catalog()
	_manager.catalog.nights[1].audio_sync_beats = 4
	_manager.night_number = 2
	_manager.random_seed = 3
	_manager.requests_arrive = false
	root.add_child(_manager)
	var mixer := MIXER.instantiate()
	root.add_child(mixer)
	mixer.setup(_manager, _manager.catalog.friends)
	return mixer


func _free(mixer: Control) -> void:
	mixer.free()
	_manager.free()


func _click(button: MouseButton, position: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	click.position = position
	return click


func _space() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key


## Avanza el mixer hasta `time` segundos desde que empezó su ronda.
func _advance_to(mixer: Control, time: float) -> void:
	mixer._process(time - mixer.sync_round.elapsed)


## Golpea en cada aplauso del patrón de la ronda, a su hora.
func _tap_pattern(mixer: Control) -> void:
	var sync_round: AudioSyncRound = mixer.sync_round
	for call_step: int in sync_round.pattern.duplicate():
		_advance_to(mixer, sync_round.response_start() + call_step * sync_round.step_seconds)
		mixer.tap()


func test_se_abre_en_el_canal_con_menos_senal() -> bool:
	var mixer := _make_mixer()
	check(not mixer.visible, "oculto al inicio")
	_manager.state.friends[2].signal_level = 30.0
	mixer.open()
	check(mixer.visible, "se abre")
	check_eq(mixer.selected_friend, 2, "en el canal de Agustín, el de menos señal")
	check(mixer.sync_round == null, "sin ronda hasta que Matías la empiece")
	check_eq(mixer.status_text(), tr("MIXER_PICK"), "pide elegir un canal")
	_free(mixer)
	return true


func test_clic_en_un_canal_empieza_la_ronda() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer._gui_input(_click(MOUSE_BUTTON_LEFT, mixer.channel_rect(1).get_center()))
	check_eq(mixer.selected_friend, 1, "el canal de Gonzalo")
	check(mixer.sync_round != null and mixer.sync_round.beats == 4, "una ronda de 4 aplausos, la de la noche 2")
	check_eq(mixer.status_text(), tr("MIXER_COUNT_IN"), "empieza con la cuenta")
	_free(mixer)
	return true


func test_suenan_la_base_y_los_aplausos() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(0)
	mixer._process(0.01)
	check((mixer.get_node("Kick") as AudioStreamPlayer).playing, "la base empieza con la cuenta")
	_advance_to(mixer, mixer.sync_round.call_start() + 0.01)
	check((mixer.get_node("Clap") as AudioStreamPlayer).playing, "el amigo aplaude al comenzar su parte")
	check_eq(mixer.friend_level, 1.0, "su VU-metro, el de la derecha, se levanta")
	check_eq(mixer.player_level, 0.0, "el de Matías, no")
	check_eq(mixer.status_text(), tr("MIXER_LISTEN").format({"friend": tr(_manager.catalog.friends[0].name_key)}),
			"pide escuchar")
	mixer._process(0.2)
	check(mixer.friend_level < 1.0, "y la aguja vuelve a bajar")
	_free(mixer)
	return true


func test_si_repite_el_ritmo_la_senal_vuelve_a_100() -> bool:
	var mixer := _make_mixer()
	_manager.state.friends[1].signal_level = 0.0
	var notices := []
	_manager.message_added.connect(func(friend_index: int, _message: RefCounted) -> void: notices.append(friend_index))
	mixer.open()
	mixer.start_round(1)
	_tap_pattern(mixer)
	check(mixer.sync_round.succeeded, "salió bien")
	check_eq(_manager.state.friends[1].signal_level, 100.0, "la señal de Gonzalo vuelve a 100")
	check_eq(notices, [1], "y el chat avisa que volvió")
	check((mixer.get_node("Success") as AudioStreamPlayer).playing, "suena el acierto")
	check_eq(mixer.status_text(), tr("MIXER_SUCCESS").format({"friend": tr(_manager.catalog.friends[1].name_key)}), "lo dice")
	_free(mixer)
	return true


func test_fuera_de_ritmo_se_reintenta() -> bool:
	var mixer := _make_mixer()
	_manager.state.friends[0].signal_level = 40.0
	mixer.open()
	mixer.start_round(0)
	_advance_to(mixer, mixer.sync_round.response_start() + 1.0)
	check(mixer.sync_round.failed, "no golpeó: sale mal")
	check_eq(_manager.state.friends[0].signal_level, 40.0, "la señal sigue igual")
	check((mixer.get_node("Fail") as AudioStreamPlayer).playing, "suena el error")
	check_eq(mixer.status_text(), tr("MIXER_FAIL"), "lo dice")
	mixer._unhandled_input(_space())
	check_eq(mixer.sync_round.phase(), AudioSyncRound.Phase.COUNT_IN, "con la barra espaciadora, otra ronda")
	_free(mixer)
	return true


func test_espacio_y_clic_marcan_el_ritmo() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(2)
	_advance_to(mixer, mixer.sync_round.response_start())
	mixer._unhandled_input(_space())
	check_eq(mixer.sync_round.hits().size(), 1, "la barra espaciadora acertó el primer aplauso")
	check_eq(mixer.player_level, 1.0, "el VU-metro de Matías, el de la izquierda, se levanta")
	check((mixer.get_node("Tap") as AudioStreamPlayer).playing, "suena su golpe")
	mixer._gui_input(_click(MOUSE_BUTTON_LEFT, Vector2(30, 30)))
	check(mixer.sync_round.failed, "un clic en el mixer también golpea: aquí sobró")
	_free(mixer)
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var mixer := _make_mixer()
	mixer.open()
	mixer.start_round(0)
	mixer._gui_input(_click(MOUSE_BUTTON_RIGHT, Vector2(30, 30)))
	check(not mixer.visible, "cerrado")
	check(mixer.sync_round == null, "la ronda se corta")
	_free(mixer)
	return true


func test_sin_audio_sync_esa_noche() -> bool:
	var mixer := _make_mixer()
	_manager.night_number = 1
	mixer.open()
	mixer.start_round(0)
	check(mixer.sync_round == null, "en la noche 1 no hay rondas")
	check_eq(mixer.status_text(), tr("MIXER_NO_SYNC"), "y lo dice")
	_free(mixer)
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	var mixer_script := preload("res://scripts/ui/mixer_view.gd")
	for key: String in [mixer_script.TITLE_KEY, mixer_script.YOU_KEY, mixer_script.PICK_KEY, mixer_script.COUNT_IN_KEY,
			mixer_script.LISTEN_KEY, mixer_script.YOUR_TURN_KEY, mixer_script.SUCCESS_KEY, mixer_script.FAIL_KEY,
			mixer_script.HINT_KEY, mixer_script.NO_SYNC_KEY]:
		check(String(TranslationServer.translate(key)) != key, "falta %s en ui.csv" % key)
	for key: String in [mixer_script.LISTEN_KEY, mixer_script.SUCCESS_KEY]:
		check(String(TranslationServer.translate(key)).contains("{friend}"), "%s debe tener {friend}" % key)
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `303 pruebas OK, 1 fallidas`. La falla es `test_mixer_view.gd :: no se pudo cargar`, porque la escena todavía no existe.

- [ ] **Paso 3: Crear el mixer**

`scripts/ui/mixer_view.gd`:

```gdscript
extends Control
## El mixer visto desde arriba, para hacer Audio Sync (diseño §10.6). Es provisional hasta el arte de Benja:
## se dibuja con rectángulos, con los colores del mixer del escritorio.
##
## Cada fader es el canal de un amigo, y su altura es la señal. Al elegir un canal empieza una ronda: la base
## marca el tiempo, el amigo aplaude un ritmo y Matías lo repite con la barra espaciadora o con clics en el
## mixer (decisión de Benja). El VU-metro de la izquierda muestra los golpes de Matías, y el de la derecha,
## los aplausos del amigo. Si sale bien, la señal del amigo vuelve a 100; si no, se reintenta.
## Se cierra con clic derecho; Esc y un clic fuera lo cierran desde el escritorio.

const AudioSyncRound := preload("res://scripts/core/audio_sync_round.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## Textos del mixer (ui.csv). MIXER_LISTEN y MIXER_SUCCESS llevan {friend}.
const TITLE_KEY := "MIXER_TITLE"
const YOU_KEY := "MIXER_YOU"
const PICK_KEY := "MIXER_PICK"
const COUNT_IN_KEY := "MIXER_COUNT_IN"
const LISTEN_KEY := "MIXER_LISTEN"
const YOUR_TURN_KEY := "MIXER_YOUR_TURN"
const SUCCESS_KEY := "MIXER_SUCCESS"
const FAIL_KEY := "MIXER_FAIL"
const HINT_KEY := "MIXER_HINT"
const NO_SYNC_KEY := "MIXER_NO_SYNC"

const SIZE := Vector2(440, 430)
const FONT_SIZE := 11
## Colores provisionales, tomados de mixer_sprite.
const BODY_COLOR := Color(0.11, 0.12, 0.22)
const PANEL_COLOR := Color(0.15, 0.16, 0.29)
const EDGE_COLOR := Color(0.62, 0.64, 0.7)
const SHADOW_COLOR := Color(0.04, 0.04, 0.09)
const SCREEN_COLOR := Color(0.13, 0.22, 0.58)
const NEEDLE_COLOR := Color(0.55, 0.93, 0.95)
const TEXT_COLOR := Color(0.79, 0.84, 0.95)
const DIM_COLOR := Color(0.45, 0.5, 0.62)
const LIGHT_OFF := Color(0.2, 0.22, 0.34)
const CLAP_LIGHT := Color(0.38, 0.62, 1.0)
const HIT_LIGHT := Color(0.49, 0.88, 0.54)
const MISS_LIGHT := Color(1.0, 0.3, 0.37)
const LED_RED := Color(1.0, 0.25, 0.3)
const LED_GREEN := Color(0.35, 0.85, 0.45)
## Dónde va cada parte, en píxeles del mixer.
const METER_PLAYER := Rect2(100, 36, 112, 72)
const METER_FRIEND := Rect2(228, 36, 112, 72)
const STEP_TOP := 140.0
const STEP_SIZE := 10.0
const STEP_GAP := 4.0
const CHANNEL_TOP := 168.0
const CHANNEL_LEFT := 92.0
const CHANNEL_SIZE := Vector2(76, 192)
const CHANNEL_GAP := 12.0
## El riel del fader, desde arriba del canal.
const FADER_TOP := 52.0
const FADER_HEIGHT := 104.0
## Cuánto baja por segundo la aguja de un VU-metro después de un golpe (de 1 a 0).
const METER_FALL := 3.0

var selected_friend := 0
## La ronda en curso o la última, o null si todavía no empieza ninguna.
var sync_round: AudioSyncRound
## La aguja de cada VU-metro, de 0 a 1: la de Matías, a la izquierda, y la del amigo, a la derecha.
var player_level := 0.0
var friend_level := 0.0

var _manager: RequestManager
var _friend_names: Array[String] = []
var _friend_colors: Array[Color] = []
## La altura que muestra cada fader, de 0 a 1. Sigue a la señal con suavidad.
var _faders: Array[float] = []
## Las luces encendidas: corchea de la parte del amigo o de Matías → su color.
var _lights := {}
## La corchea que suena ahora en la parte del amigo o en la de Matías, o -1.
var _playhead := -1
## El LED de arriba parpadea con la base.
var _led := 0.0
## Para el parpadeo de los LED de los canales.
var _blink := 0.0
var _round_finished := false
var _rest_position := Vector2.ZERO

@onready var _kick: AudioStreamPlayer = $Kick
@onready var _tick: AudioStreamPlayer = $Tick
@onready var _clap: AudioStreamPlayer = $Clap
@onready var _tap: AudioStreamPlayer = $Tap
@onready var _success: AudioStreamPlayer = $Success
@onready var _fail: AudioStreamPlayer = $Fail


func _ready() -> void:
	hide()
	_rest_position = position


## Conecta el mixer a las solicitudes, que tienen el estado de la noche. Un canal por amigo, en orden.
func setup(manager: RequestManager, friends: Array[FriendData]) -> void:
	_manager = manager
	for friend: FriendData in friends:
		_friend_names.append(tr(friend.name_key))
		_friend_colors.append(friend.color)
		_faders.append(1.0)


## Aplausos del Audio Sync de esta noche: 0 si no hay.
func beats() -> int:
	return _manager.night().audio_sync_beats


## Se abre en el canal del amigo con menos señal, sin ronda: Matías la empieza cuando quiere.
func open() -> void:
	sync_round = null
	_lights.clear()
	_playhead = -1
	selected_friend = _weakest_friend()
	for index in _faders.size():
		_faders[index] = _manager.state.friends[index].signal_level / 100.0
	show()
	# Sube desde el escritorio.
	position = _rest_position + Vector2(0, 24)
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position", _rest_position, 0.15)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)


## Se cierra y corta la ronda.
func close() -> void:
	sync_round = null
	hide()


## Empieza una ronda en el canal del amigo `friend_index`. No hay rondas si la noche no tiene Audio Sync.
func start_round(friend_index: int) -> void:
	if beats() <= 0:
		return
	selected_friend = friend_index
	var balance := _manager.catalog.balance
	sync_round = AudioSyncRound.new(beats(), balance.audio_sync_bpm, balance.audio_sync_tolerance, _manager.rng)
	_round_finished = false
	_lights.clear()
	_playhead = -1


## Hay una ronda sonando.
func is_playing() -> bool:
	return sync_round != null and sync_round.phase() != AudioSyncRound.Phase.DONE


## Matías golpea: suena su golpe y se levanta su VU-metro. En su parte, la luz de la corchea queda verde si
## acertó o roja si el golpe sobró.
func tap() -> void:
	if not is_playing():
		return
	_tap.play()
	player_level = 1.0
	match sync_round.tap():
		AudioSyncRound.Tap.HIT:
			_lights[sync_round.hits()[-1]] = HIT_LIGHT
		AudioSyncRound.Tap.MISS:
			_lights[maxi(_playhead, 0)] = MISS_LIGHT
	if sync_round.phase() == AudioSyncRound.Phase.DONE:
		_finish_round()


## El rectángulo del canal del amigo `friend_index`, en píxeles del mixer.
func channel_rect(friend_index: int) -> Rect2:
	return Rect2(Vector2(CHANNEL_LEFT + friend_index * (CHANNEL_SIZE.x + CHANNEL_GAP), CHANNEL_TOP), CHANNEL_SIZE)


## Lo que dice el mixer abajo: qué hacer o cómo salió la ronda.
func status_text() -> String:
	var friend := _friend_names[selected_friend]
	if beats() <= 0:
		return tr(NO_SYNC_KEY)
	if sync_round == null:
		return tr(PICK_KEY)
	match sync_round.phase():
		AudioSyncRound.Phase.COUNT_IN:
			return tr(COUNT_IN_KEY)
		AudioSyncRound.Phase.CALL:
			return tr(LISTEN_KEY).format({"friend": friend})
		AudioSyncRound.Phase.RESPONSE:
			return tr(YOUR_TURN_KEY)
	return tr(SUCCESS_KEY if sync_round.succeeded else FAIL_KEY).format({"friend": friend})


func _process(delta: float) -> void:
	if not visible:
		return
	player_level = maxf(player_level - delta * METER_FALL, 0.0)
	friend_level = maxf(friend_level - delta * METER_FALL, 0.0)
	_led = maxf(_led - delta * 4.0, 0.0)
	_blink += delta
	for index in _faders.size():
		var target := _manager.state.friends[index].signal_level / 100.0
		_faders[index] = lerpf(_faders[index], target, minf(delta * 8.0, 1.0))
	if is_playing():
		for step: int in sync_round.advance(delta):
			_play_step(step)
		if sync_round.phase() == AudioSyncRound.Phase.DONE:
			_finish_round()
	queue_redraw()


## Clic izquierdo: durante una ronda, golpea; si no, empieza la ronda del canal clickeado.
## Clic derecho: se cierra.
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	accept_event()
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		close()
	elif mouse.button_index == MOUSE_BUTTON_LEFT:
		if is_playing():
			tap()
			return
		for index in _faders.size():
			if channel_rect(index).has_point(mouse.position):
				start_round(index)


## La barra espaciadora golpea durante una ronda; si no hay ninguna sonando, empieza la del canal elegido.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo or key.keycode != KEY_SPACE:
		return
	get_viewport().set_input_as_handled()
	if is_playing():
		tap()
	else:
		start_round(selected_friend)


## Suena la corchea `step`: la base en cada golpe (bombo y platillo) y el aplauso del amigo, con su luz.
## Cuando le toca a Matías, las luces se apagan: el ritmo hay que recordarlo.
func _play_step(step: int) -> void:
	if sync_round.is_beat(step):
		_led = 1.0
		if step % 4 == 0:
			_kick.volume_db = 0.0 if sync_round.is_accent(step) else -6.0
			_kick.play()
		else:
			_tick.play()
	var response_step := AudioSyncRound.STEPS_PER_BAR + sync_round.steps
	if step == response_step:
		_lights.clear()
	if step >= response_step:
		_playhead = step - response_step
	elif step >= AudioSyncRound.STEPS_PER_BAR:
		_playhead = step - AudioSyncRound.STEPS_PER_BAR
	if sync_round.is_clap(step):
		_clap.play()
		friend_level = 1.0
		_lights[step - AudioSyncRound.STEPS_PER_BAR] = CLAP_LIGHT


## Al terminar la ronda, las luces muestran el ritmo: en verde lo que acertó Matías y en rojo lo que se le
## pasó. Si salió bien, la señal del amigo vuelve a 100 y el chat avisa si estaba desconectado.
func _finish_round() -> void:
	if _round_finished:
		return
	_round_finished = true
	_playhead = -1
	for call_step: int in sync_round.pattern:
		_lights[call_step] = HIT_LIGHT if sync_round.hits().has(call_step) else MISS_LIGHT
	if sync_round.succeeded:
		_success.play()
		_manager.restore_signal(selected_friend)
	else:
		_fail.play()


## El amigo con menos señal: el que más necesita sincronizarse.
func _weakest_friend() -> int:
	var friends := _manager.state.friends
	var weakest := 0
	for index in range(1, friends.size()):
		if friends[index].signal_level < friends[weakest].signal_level:
			weakest = index
	return weakest


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, SIZE)
	draw_rect(body, SHADOW_COLOR)
	draw_rect(body.grow(-2), EDGE_COLOR)
	draw_rect(body.grow(-4), BODY_COLOR)
	draw_rect(body.grow(-10), PANEL_COLOR, false)
	_draw_text(tr(TITLE_KEY).to_upper(), Vector2(18, 26), DIM_COLOR)
	_draw_led(Vector2(410, 16), LED_RED, _led if is_playing() else 0.0)
	_draw_knob(Vector2(52, 72))
	_draw_knob(Vector2(388, 72))
	_draw_meter(METER_PLAYER, player_level)
	_draw_meter(METER_FRIEND, friend_level)
	_draw_text_centered(tr(YOU_KEY).to_upper(), METER_PLAYER.get_center().x, 128, TEXT_COLOR)
	_draw_text_centered(_friend_names[selected_friend].to_upper(), METER_FRIEND.get_center().x, 128,
			_friend_colors[selected_friend])
	_draw_steps()
	for index in _faders.size():
		_draw_channel(index)
	_draw_decor()
	_draw_text_centered(status_text().to_upper(), SIZE.x / 2.0, 394, TEXT_COLOR)
	_draw_text_centered(tr(HINT_KEY).to_upper(), SIZE.x / 2.0, 414, DIM_COLOR)


## Un VU-metro azul: la aguja se levanta con cada golpe y vuelve a caer.
func _draw_meter(rect: Rect2, level: float) -> void:
	draw_rect(rect, SHADOW_COLOR)
	draw_rect(rect.grow(-2), SCREEN_COLOR)
	var pivot := Vector2(rect.get_center().x, rect.end.y - 8)
	for index in 9:
		var angle := deg_to_rad(-50.0 + index * 12.5)
		var direction := Vector2(sin(angle), -cos(angle))
		var mark_length := 6.0 if index % 2 == 0 else 3.0
		draw_line(pivot + direction * 48.0, pivot + direction * (48.0 + mark_length), NEEDLE_COLOR.darkened(0.35))
	var needle := deg_to_rad(lerpf(-50.0, 50.0, level))
	draw_line(pivot, pivot + Vector2(sin(needle), -cos(needle)) * 50.0, NEEDLE_COLOR, 2.0)
	draw_rect(Rect2(pivot - Vector2(3, 3), Vector2(6, 6)), EDGE_COLOR)


## Una luz por corchea de la parte del amigo: se encienden con sus aplausos y, en la parte de Matías, con sus
## golpes. La que suena ahora se ve más clara, y cada golpe de la base tiene una marca debajo.
func _draw_steps() -> void:
	var count := beats() * 2
	if count <= 0:
		return
	var left := (SIZE.x - count * STEP_SIZE - (count - 1) * STEP_GAP) / 2.0
	for index in count:
		var rect := Rect2(left + index * (STEP_SIZE + STEP_GAP), STEP_TOP, STEP_SIZE, STEP_SIZE)
		var color: Color = _lights.get(index, LIGHT_OFF)
		if index == _playhead:
			color = color.lightened(0.4)
		draw_rect(rect.grow(1), SHADOW_COLOR)
		draw_rect(rect, color)
		if index % 2 == 0:
			draw_rect(Rect2(rect.position + Vector2(4, 14), Vector2(2, 2)), DIM_COLOR)


## El canal de un amigo: su nombre, un LED, el fader a la altura de su señal y el número. El canal elegido
## lleva un borde de su color.
func _draw_channel(index: int) -> void:
	var rect := channel_rect(index)
	var friend := _manager.state.friends[index]
	draw_rect(rect, _friend_colors[index] if index == selected_friend else SHADOW_COLOR)
	draw_rect(rect.grow(-2), PANEL_COLOR)
	var center_x := rect.get_center().x
	_draw_text_centered(_friend_names[index].to_upper(), center_x, rect.position.y + 18, _friend_colors[index])
	# El LED: rojo fijo sin señal, rojo parpadeando si viene una interferencia y verde si está bien.
	var led_color := LED_GREEN
	var lit := 0.6
	if not friend.is_online():
		led_color = LED_RED
		lit = 1.0
	elif _manager.state.interference_warning(index):
		led_color = LED_RED
		lit = 1.0 if fmod(_blink, 0.24) < 0.12 else 0.0
	_draw_led(Vector2(center_x - 4, rect.position.y + 28), led_color, lit)
	var track := Rect2(center_x - 2, rect.position.y + FADER_TOP, 4, FADER_HEIGHT)
	draw_rect(track, SHADOW_COLOR)
	for mark in 6:
		var y := track.position.y + mark * FADER_HEIGHT / 5.0
		draw_rect(Rect2(center_x - 14, y, 6, 1), DIM_COLOR)
		draw_rect(Rect2(center_x + 8, y, 6, 1), DIM_COLOR)
	var knob_y := roundf(track.end.y - _faders[index] * FADER_HEIGHT)
	draw_rect(Rect2(center_x - 15, knob_y - 6, 30, 12), SHADOW_COLOR)
	draw_rect(Rect2(center_x - 14, knob_y - 5, 28, 10), EDGE_COLOR)
	draw_rect(Rect2(center_x - 14, knob_y - 1, 28, 2), SHADOW_COLOR)
	var value_color := TEXT_COLOR if friend.is_online() else LED_RED
	_draw_text_centered("%d" % roundi(friend.signal_level), center_x, rect.end.y - 12, value_color)


func _draw_led(top_left: Vector2, color: Color, lit: float) -> void:
	draw_rect(Rect2(top_left - Vector2.ONE, Vector2(10, 10)), SHADOW_COLOR)
	draw_rect(Rect2(top_left, Vector2(8, 8)), color.darkened(0.75).lerp(color, lit))


## Una perilla de adorno, como las del mixer del escritorio.
func _draw_knob(center: Vector2) -> void:
	draw_circle(center, 24.0, SHADOW_COLOR)
	draw_circle(center, 22.0, EDGE_COLOR.darkened(0.25))
	draw_circle(center, 16.0, EDGE_COLOR)
	draw_line(center, center + Vector2(9, -12), SHADOW_COLOR, 2.0)


## Botones y barras de colores de adorno, como los del mixer del escritorio.
func _draw_decor() -> void:
	var button_colors := [Color(0.85, 0.25, 0.25), Color(0.93, 0.83, 0.3), Color(0.35, 0.75, 0.35)]
	for row in 3:
		for column in 3:
			var top_left := Vector2(26 + column * 18, 196 + row * 22)
			draw_rect(Rect2(top_left - Vector2.ONE, Vector2(14, 14)), SHADOW_COLOR)
			draw_rect(Rect2(top_left, Vector2(12, 12)), EDGE_COLOR)
			draw_rect(Rect2(top_left + Vector2(3, 3), Vector2(6, 6)), button_colors[column])
	var bar_colors := [Color(0.35, 0.75, 0.35), Color(0.93, 0.83, 0.3), Color(0.3, 0.5, 0.95), Color(0.85, 0.45, 0.2)]
	for row in bar_colors.size():
		draw_rect(Rect2(366, 200 + row * 12, 48, 6), bar_colors[row])


func _draw_text(text: String, baseline_left: Vector2, color: Color) -> void:
	draw_string(FONT, baseline_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _draw_text_centered(text: String, center_x: float, baseline: float, color: Color) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_draw_text(text, Vector2(roundf(center_x - width / 2.0), baseline), color)
```

`scenes/ui/mixer_view.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/mixer_view.gd" id="mixer_script"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_kick.wav" id="kick"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_tick.wav" id="tick"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_clap.wav" id="clap"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_tap.wav" id="tap"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_success.wav" id="success"]
[ext_resource type="AudioStream" path="res://audio/sfx/sync_fail.wav" id="fail"]

[node name="MixerView" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_left = 20.0
offset_top = 140.0
offset_right = 460.0
offset_bottom = 570.0
script = ExtResource("mixer_script")

[node name="Kick" type="AudioStreamPlayer" parent="."]
stream = ExtResource("kick")

[node name="Tick" type="AudioStreamPlayer" parent="."]
stream = ExtResource("tick")
volume_db = -8.0

[node name="Clap" type="AudioStreamPlayer" parent="."]
stream = ExtResource("clap")

[node name="Tap" type="AudioStreamPlayer" parent="."]
stream = ExtResource("tap")
volume_db = -4.0

[node name="Success" type="AudioStreamPlayer" parent="."]
stream = ExtResource("success")
volume_db = -6.0

[node name="Fail" type="AudioStreamPlayer" parent="."]
stream = ExtResource("fail")
volume_db = -6.0
```

Los textos del mixer son borradores de interfaz que Benja puede cambiar, conservando los marcadores entre llaves:

Agregar al final de `data/text/ui.csv`:

```csv
MIXER_TITLE,Audio Sync,
MIXER_YOU,Tú,
MIXER_PICK,Elige un canal: clic en su fader,
MIXER_COUNT_IN,Prepárate…,
MIXER_LISTEN,Escucha a {friend},
MIXER_YOUR_TURN,¡Repite el ritmo!,
MIXER_SUCCESS,¡{friend} sincronizado! Señal al 100 %,
MIXER_FAIL,Fuera de ritmo: espacio para reintentar,
MIXER_HINT,Espacio o clic: marca el ritmo · Clic derecho: salir,
MIXER_NO_SYNC,La señal está estable: esta noche no hace falta sincronizar,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `312 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ data/ test/
git commit -m "Audio Sync en el mixer" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 13: Las publicaciones del celular

**Archivos:**

- Crear: `scripts/data/phone_post_data.gd`, `data/text/phone.csv`
- Modificar: `scripts/data/content_catalog.gd`, `scripts/core/content_validator.gd`, `data/catalog.tres`, `project.godot`, `test/test_catalog.gd`, `test/test_validator_texts.gd`, `test/test_translations.gd`

Las publicaciones del celular son contenido, así que van como datos: `PhonePostData` guarda quién publica, su texto, su imagen y un color para la imagen provisional. El catálogo tiene 12, con sus textos en un CSV nuevo, `data/text/phone.csv`, que Benja corrige. El validador revisa que sus textos existan.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_translations.gd`, reemplazar:

```gdscript
const FILES := ["messages", "notebook", "ui"]
```

por:

```gdscript
const FILES := ["messages", "notebook", "phone", "ui"]
```

Agregar al final de `test/test_catalog.gd`:

```gdscript
func test_el_celular_tiene_publicaciones() -> bool:
	var catalog := _load_catalog()
	if catalog == null:
		return true
	check_eq(catalog.phone_posts.size(), 12, "unas 12 publicaciones (docs/06 §3)")
	for post: PhonePostData in catalog.phone_posts:
		check(not post.author_key.is_empty() and not post.text_key.is_empty(), "cada una con su autor y su texto")
	return true
```

Agregar al final de `test/test_validator_texts.gd`:

```gdscript
func test_publicacion_sin_texto() -> bool:
	var catalog := Fixtures.make_catalog()
	var post := PhonePostData.new()
	post.author_key = "K_POST_AUTHOR"
	post.text_key = "K_POST_TEXT"
	catalog.phone_posts.append(post)
	var errors := ContentValidator.validate_texts(catalog, _translate_except(["K_POST_TEXT"]))
	check_contains(errors, "Publicación 1 del celular, texto: la clave 'K_POST_TEXT' no está en ningún CSV")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `303 pruebas OK, 3 fallidas`. No se pudieron cargar `test_catalog.gd` ni `test_validator_texts.gd`, porque la clase `PhonePostData` no existe, y falla `test_translations.gd :: test_las_traducciones_estan_registradas`.

- [ ] **Paso 3: Las publicaciones como datos**

`scripts/data/phone_post_data.gd`:

```gdscript
class_name PhonePostData
extends Resource
## Una publicación del celular (diseño §10.2), de las que Matías scrollea para recuperar Sanity.
## Hasta el arte del celular ampliado (docs/06 §3), su imagen se dibuja con `color`.

## Quién publica (phone.csv).
@export var author_key: String
## Lo que dice la publicación (phone.csv).
@export var text_key: String
## La imagen de la publicación. Sin imagen, se dibuja un paisaje provisional de este color.
@export var picture: Texture2D
@export var color := Color(0.3, 0.45, 0.7)
```

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
@export var balance: BalanceData
```

por:

```gdscript
@export var balance: BalanceData
## Las publicaciones que se scrollean en el celular (PhonePostData), en orden.
@export var phone_posts: Array[PhonePostData] = []
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
		keys.append(["Señuelo '%s'" % decoy.id, decoy.text_key])
```

por:

```gdscript
		keys.append(["Señuelo '%s'" % decoy.id, decoy.text_key])
	for index in catalog.phone_posts.size():
		var post := catalog.phone_posts[index]
		keys.append(["Publicación %d del celular, autor" % (index + 1), post.author_key])
		keys.append(["Publicación %d del celular, texto" % (index + 1), post.text_key])
```

Los textos de las publicaciones son borradores reales que Benja corrige. El nombre de la red social, "copuchas", también se puede cambiar.

`data/text/phone.csv`:

```csv
keys,es,en
PHONE_APP_NAME,copuchas,
PHONE_POST_01_AUTHOR,@cata.viaja,
PHONE_POST_01_TEXT,Atardecer en Valparaíso. No hay nada mejor que esto.,
PHONE_POST_02_AUTHOR,@perrito_bombon,
PHONE_POST_02_TEXT,Bombón aprendió a dar la pata. Estoy llorando.,
PHONE_POST_03_AUTHOR,@don.lucho.completos,
PHONE_POST_03_TEXT,Hoy: dos completos italianos a luca y media.,
PHONE_POST_04_AUTHOR,@fena_gamer,
PHONE_POST_04_TEXT,Llevo tres horas con el mismo jefe. No me rindo.,
PHONE_POST_05_AUTHOR,@la.abuela.rosa,
PHONE_POST_05_TEXT,Hice sopaipillas pasadas. ¿Quién viene a tomar once?,
PHONE_POST_06_AUTHOR,@memes_del_sur,
PHONE_POST_06_TEXT,Yo a las 3 AM viendo cómo se hacen los lápices.,
PHONE_POST_07_AUTHOR,@trekking.chiloe,
PHONE_POST_07_TEXT,Llegamos al mirador. Valió cada paso.,
PHONE_POST_08_AUTHOR,@gatitos_de_conce,
PHONE_POST_08_TEXT,Este es Michi. Michi duerme. Sé como Michi.,
PHONE_POST_09_AUTHOR,@la.jose.dibuja,
PHONE_POST_09_TEXT,Terminé mi primer cómic. ¡Gracias por el apoyo!,
PHONE_POST_10_AUTHOR,@futbol.de.barrio,
PHONE_POST_10_TEXT,Ganamos 3 a 2 en el último minuto. ¡Vamos!,
PHONE_POST_11_AUTHOR,@recetas.rapidas,
PHONE_POST_11_TEXT,"Pan amasado en 20 minutos. La receta, en los comentarios.",
PHONE_POST_12_AUTHOR,@lluvia.en.osorno,
PHONE_POST_12_TEXT,Llueve hace cuatro días. Ya es parte de la familia.,
```

En `data/catalog.tres`, reemplazar:

```ini
[ext_resource type="Resource" path="res://data/balance.tres" id="13_balance"]
```

por:

```ini
[ext_resource type="Resource" path="res://data/balance.tres" id="13_balance"]
[ext_resource type="Script" path="res://scripts/data/phone_post_data.gd" id="14_post"]
```

En `data/catalog.tres`, reemplazar:

```ini
place_keys = Array[String](["PLACE_FOREST"])

[resource]
```

por:

```ini
place_keys = Array[String](["PLACE_FOREST"])

[sub_resource type="Resource" id="PhonePost_01"]
script = ExtResource("14_post")
author_key = "PHONE_POST_01_AUTHOR"
text_key = "PHONE_POST_01_TEXT"
color = Color(0.93, 0.55, 0.3, 1)

[sub_resource type="Resource" id="PhonePost_02"]
script = ExtResource("14_post")
author_key = "PHONE_POST_02_AUTHOR"
text_key = "PHONE_POST_02_TEXT"
color = Color(0.62, 0.42, 0.28, 1)

[sub_resource type="Resource" id="PhonePost_03"]
script = ExtResource("14_post")
author_key = "PHONE_POST_03_AUTHOR"
text_key = "PHONE_POST_03_TEXT"
color = Color(0.9, 0.74, 0.3, 1)

[sub_resource type="Resource" id="PhonePost_04"]
script = ExtResource("14_post")
author_key = "PHONE_POST_04_AUTHOR"
text_key = "PHONE_POST_04_TEXT"
color = Color(0.45, 0.3, 0.7, 1)

[sub_resource type="Resource" id="PhonePost_05"]
script = ExtResource("14_post")
author_key = "PHONE_POST_05_AUTHOR"
text_key = "PHONE_POST_05_TEXT"
color = Color(0.72, 0.45, 0.32, 1)

[sub_resource type="Resource" id="PhonePost_06"]
script = ExtResource("14_post")
author_key = "PHONE_POST_06_AUTHOR"
text_key = "PHONE_POST_06_TEXT"
color = Color(0.42, 0.5, 0.62, 1)

[sub_resource type="Resource" id="PhonePost_07"]
script = ExtResource("14_post")
author_key = "PHONE_POST_07_AUTHOR"
text_key = "PHONE_POST_07_TEXT"
color = Color(0.3, 0.6, 0.42, 1)

[sub_resource type="Resource" id="PhonePost_08"]
script = ExtResource("14_post")
author_key = "PHONE_POST_08_AUTHOR"
text_key = "PHONE_POST_08_TEXT"
color = Color(0.85, 0.6, 0.35, 1)

[sub_resource type="Resource" id="PhonePost_09"]
script = ExtResource("14_post")
author_key = "PHONE_POST_09_AUTHOR"
text_key = "PHONE_POST_09_TEXT"
color = Color(0.85, 0.5, 0.65, 1)

[sub_resource type="Resource" id="PhonePost_10"]
script = ExtResource("14_post")
author_key = "PHONE_POST_10_AUTHOR"
text_key = "PHONE_POST_10_TEXT"
color = Color(0.35, 0.68, 0.35, 1)

[sub_resource type="Resource" id="PhonePost_11"]
script = ExtResource("14_post")
author_key = "PHONE_POST_11_AUTHOR"
text_key = "PHONE_POST_11_TEXT"
color = Color(0.82, 0.68, 0.45, 1)

[sub_resource type="Resource" id="PhonePost_12"]
script = ExtResource("14_post")
author_key = "PHONE_POST_12_AUTHOR"
text_key = "PHONE_POST_12_TEXT"
color = Color(0.35, 0.48, 0.7, 1)

[resource]
```

En `data/catalog.tres`, reemplazar:

```ini
balance = ExtResource("13_balance")
```

por:

```ini
balance = ExtResource("13_balance")
phone_posts = Array[ExtResource("14_post")]([SubResource("PhonePost_01"), SubResource("PhonePost_02"), SubResource("PhonePost_03"), SubResource("PhonePost_04"), SubResource("PhonePost_05"), SubResource("PhonePost_06"), SubResource("PhonePost_07"), SubResource("PhonePost_08"), SubResource("PhonePost_09"), SubResource("PhonePost_10"), SubResource("PhonePost_11"), SubResource("PhonePost_12")])
```

`phone.csv` se registra como traducción, junto a los otros CSV:

En `project.godot`, reemplazar:

```ini
locale/translations=PackedStringArray("res://data/text/messages.es.translation", "res://data/text/notebook.es.translation", "res://data/text/ui.es.translation")
```

por:

```ini
locale/translations=PackedStringArray("res://data/text/messages.es.translation", "res://data/text/notebook.es.translation", "res://data/text/phone.es.translation", "res://data/text/ui.es.translation")
```

- [ ] **Paso 4: Importar y verificar que pasan**

Al importar, Godot crea `data/text/phone.es.translation`.

Esperado: `314 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/ project.godot
git commit -m "Publicaciones del celular como datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 14: El celular: las redes sociales

**Archivos:**

- Crear: `scripts/ui/phone_view.gd`, `scenes/ui/phone_view.tscn`, `test/test_phone_view.gd`

La vista del celular ampliado, provisional hasta el arte de Benja: el celular en modo oscuro, con la hora, la señal y la batería arriba, el nombre de la red social y el feed. Cada publicación muestra quién la publica, su imagen (un paisaje pixelado de su color, si no tiene imagen), sus "me gusta" y su texto. La rueda del mouse o el touchpad avanzan el feed con suavidad, que se repite sin fin, y mientras se scrollea, Sanity sube. Se cierra con clic derecho.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_phone_view.gd`:

```gdscript
extends "res://test/test_case.gd"

const Fixtures := preload("res://test/content_fixtures.gd")
const PHONE := preload("res://scenes/ui/phone_view.tscn")
const NightState := preload("res://scripts/core/night_state.gd")
const PhoneView := preload("res://scripts/ui/phone_view.gd")

var _state: NightState


## Celular con el estado de la noche 1 del catálogo de prueba y 3 publicaciones.
func _make_phone() -> Control:
	var catalog := Fixtures.make_catalog()
	_state = NightState.new(catalog.nights[0], catalog.balance, 3, RandomNumberGenerator.new())
	var posts: Array[PhonePostData] = []
	for index in 3:
		var post := PhonePostData.new()
		post.author_key = "K_AUTHOR_%d" % index
		post.text_key = "K_TEXT_%d" % index
		posts.append(post)
	var phone := PHONE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(phone)
	phone.setup(_state, posts)
	return phone


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_empieza_oculto_y_se_abre() -> bool:
	var phone := _make_phone()
	check(not phone.visible, "oculto al inicio")
	phone.open()
	check(phone.visible, "se abre")
	phone.free()
	return true


func test_la_rueda_scrollea_y_recupera_sanity() -> bool:
	var phone := _make_phone()
	phone.open()
	_state.sanity = 50.0
	phone._gui_input(_mouse(MOUSE_BUTTON_WHEEL_DOWN))
	_state.advance(0.3)
	check(_state.sanity > 50.0, "Sanity sube mientras scrollea: %s" % _state.sanity)
	phone._process(1.0)
	check_eq(phone.scroll, PhoneView.WHEEL_STEP, "las publicaciones suben")
	var calm := _state.sanity
	_state.advance(1.0)
	check(_state.sanity < calm, "al dejar de scrollear, Sanity vuelve a bajar")
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(0, 2)
	phone._gui_input(pan)
	_state.advance(0.3)
	check(_state.sanity > calm - 1.0 / 6.0, "el touchpad también scrollea")
	phone.free()
	return true


func test_las_publicaciones_se_repiten_sin_fin() -> bool:
	var phone := _make_phone()
	phone.open()
	check_eq(phone.post_at_top(), 0, "empieza en la primera")
	for _i in 40:
		phone.scroll_by(PhoneView.WHEEL_STEP)
	phone._process(1.0)
	check_eq(phone.scroll, 2400.0, "40 movimientos de la rueda")
	check_eq(phone.post_at_top(), 1, "después de 3 publicaciones vuelve a empezar: arriba está la segunda")
	phone.scroll_by(-3000.0)
	phone._process(1.0)
	check(phone.post_at_top() >= 0 and phone.post_at_top() < 3, "también hacia arriba")
	phone.free()
	return true


func test_clic_derecho_lo_cierra() -> bool:
	var phone := _make_phone()
	phone.open()
	phone._gui_input(_mouse(MOUSE_BUTTON_RIGHT))
	check(not phone.visible, "cerrado")
	phone.free()
	return true


func test_sus_textos_existen() -> bool:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	check(String(TranslationServer.translate(PhoneView.APP_NAME_KEY)) != PhoneView.APP_NAME_KEY, "falta PHONE_APP_NAME en phone.csv")
	TranslationServer.set_locale(previous)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `314 pruebas OK, 1 fallidas`. La falla es `test_phone_view.gd :: no se pudo cargar`, porque la escena todavía no existe.

- [ ] **Paso 3: Crear el celular**

`scripts/ui/phone_view.gd`:

```gdscript
extends Control
## El celular ampliado (diseño §10.2): las redes sociales que Matías scrollea con la rueda del mouse para
## recuperar Sanity. Es provisional hasta el arte de Benja: el celular y las publicaciones se dibujan con
## rectángulos, y una publicación sin imagen muestra un paisaje de su color.
## Las publicaciones se repiten sin fin. Se cierra con clic derecho; Esc y un clic fuera lo cierran desde
## el escritorio.

const NightState := preload("res://scripts/core/night_state.gd")
const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## El nombre de la red social (phone.csv).
const APP_NAME_KEY := "PHONE_APP_NAME"
const SIZE := Vector2(260, 520)
const FONT_SIZE := 11
## Alto de cada publicación en el feed.
const POST_HEIGHT := 236.0
## Cuántos píxeles avanza el feed con cada movimiento de la rueda.
const WHEEL_STEP := 60.0
## Cuánto avanza con el touchpad, por unidad de su gesto.
const PAN_STEP := 30.0
## Qué tan rápido sigue el feed a la rueda.
const SCROLL_SPEED := 10.0
## Colores provisionales: el celular de noche, en modo oscuro.
const BODY_COLOR := Color(0.07, 0.08, 0.12)
const EDGE_COLOR := Color(0.24, 0.26, 0.34)
const GLASS_COLOR := Color(0.01, 0.01, 0.03)
const FEED_COLOR := Color(0.07, 0.08, 0.11)
const TEXT_COLOR := Color(0.86, 0.88, 0.94)
const DIM_COLOR := Color(0.5, 0.54, 0.64)
const ACCENT_COLOR := Color(1.0, 0.7, 0.4)
const HEART_COLOR := Color(1.0, 0.35, 0.45)
const DIVIDER_COLOR := Color(0.16, 0.17, 0.22)

## Cuántos píxeles se scrolleó. Crece sin fin hacia abajo: las publicaciones se repiten.
var scroll := 0.0

var _target_scroll := 0.0
var _state: NightState
var _posts: Array[PhonePostData] = []
var _rest_position := Vector2.ZERO

@onready var _feed: Control = $Feed


func _ready() -> void:
	hide()
	_rest_position = position
	_feed.draw.connect(_draw_feed)


## Conecta el celular al estado de la noche (la hora y Sanity) y a sus publicaciones.
func setup(state: NightState, posts: Array[PhonePostData]) -> void:
	_state = state
	_posts = posts


func open() -> void:
	show()
	# Sube desde el escritorio.
	position = _rest_position + Vector2(0, 24)
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position", _rest_position, 0.15)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)


func close() -> void:
	hide()


## Avanza el feed `amount` píxeles (hacia abajo si es positivo). Mientras Matías scrollea, Sanity sube.
func scroll_by(amount: float) -> void:
	_target_scroll += amount
	_state.scroll()


## La publicación que está arriba del feed, por su posición en la lista.
func post_at_top() -> int:
	if _posts.is_empty():
		return -1
	return floori(fposmod(scroll, POST_HEIGHT * _posts.size()) / POST_HEIGHT)


func _process(delta: float) -> void:
	if not visible:
		return
	scroll = lerpf(scroll, _target_scroll, minf(delta * SCROLL_SPEED, 1.0))
	queue_redraw()
	_feed.queue_redraw()


## La rueda del mouse y el touchpad scrollean. El clic derecho cierra el celular.
func _gui_input(event: InputEvent) -> void:
	var pan := event as InputEventPanGesture
	if pan != null:
		scroll_by(pan.delta.y * PAN_STEP)
		accept_event()
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	accept_event()
	match mouse.button_index:
		MOUSE_BUTTON_WHEEL_DOWN:
			scroll_by(WHEEL_STEP)
		MOUSE_BUTTON_WHEEL_UP:
			scroll_by(-WHEEL_STEP)
		MOUSE_BUTTON_RIGHT:
			close()


## El celular: el cuerpo con las esquinas en escalón, la barra con la hora, el nombre de la red social y,
## abajo, la barra de inicio. El feed se dibuja aparte, recortado a su pantalla.
func _draw() -> void:
	draw_rect(Rect2(4, 0, SIZE.x - 8, SIZE.y), BODY_COLOR)
	draw_rect(Rect2(0, 4, SIZE.x, SIZE.y - 8), BODY_COLOR)
	draw_rect(Rect2(2, 2, SIZE.x - 4, SIZE.y - 4), BODY_COLOR)
	draw_rect(Rect2(2, 2, SIZE.x - 4, SIZE.y - 4), EDGE_COLOR, false)
	draw_rect(Rect2(10, 14, 240, 492), GLASS_COLOR)
	draw_rect(Rect2(110, 6, 40, 3), EDGE_COLOR)
	draw_rect(Rect2(14, 18, 232, 478), FEED_COLOR)
	_draw_text(self, _state.clock_text(), Vector2(22, 31), TEXT_COLOR)
	for bar in 4:
		draw_rect(Rect2(196 + bar * 4, 28 - bar * 2, 3, 3 + bar * 2), TEXT_COLOR)
	draw_rect(Rect2(216, 22, 20, 9), TEXT_COLOR, false)
	draw_rect(Rect2(218, 24, 12, 5), TEXT_COLOR)
	draw_rect(Rect2(236, 24, 2, 5), TEXT_COLOR)
	draw_string(FONT, Vector2(22, 57), tr(APP_NAME_KEY), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE * 2, ACCENT_COLOR)
	draw_string(FONT, Vector2(214, 55), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	draw_rect(Rect2(14, 63, 232, 1), DIVIDER_COLOR)
	draw_rect(Rect2(98, 487, 64, 3), DIM_COLOR)


## Las publicaciones, una debajo de otra y repetidas sin fin, corridas según el scroll.
func _draw_feed() -> void:
	if _posts.is_empty():
		return
	var offset := fposmod(scroll, POST_HEIGHT * _posts.size())
	var index := floori(offset / POST_HEIGHT)
	var top := index * POST_HEIGHT - offset
	while top < _feed.size.y:
		_draw_post(index % _posts.size(), top)
		top += POST_HEIGHT
		index += 1


## Una publicación: quién la publica, su imagen, los "me gusta" y su texto en hasta 2 líneas.
func _draw_post(index: int, top: float) -> void:
	var post := _posts[index]
	var author := tr(post.author_key)
	var avatar := Rect2(10, top + 8, 20, 20)
	_feed.draw_rect(avatar, post.color)
	_draw_text(_feed, author.trim_prefix("@").left(1).to_upper(), avatar.position + Vector2(7, 15), FEED_COLOR)
	_draw_text(_feed, author, Vector2(36, top + 22), TEXT_COLOR)
	_draw_text(_feed, "···", Vector2(200, top + 22), DIM_COLOR)
	var picture := Rect2(10, top + 34, 212, 140)
	if post.picture != null:
		_feed.draw_texture_rect(post.picture, picture, false)
	else:
		_draw_landscape(picture, post.color, index)
	_draw_text(_feed, "♥ %d" % _likes(index), Vector2(10, top + 192), HEART_COLOR)
	_feed.draw_multiline_string(FONT, Vector2(10, top + 210), tr(post.text_key), HORIZONTAL_ALIGNMENT_LEFT, 212,
			FONT_SIZE, 2, TEXT_COLOR)
	_feed.draw_rect(Rect2(0, top + POST_HEIGHT - 1, _feed.size.x, 1), DIVIDER_COLOR)


## Una imagen provisional: un paisaje del color de la publicación, distinto en cada una.
func _draw_landscape(rect: Rect2, color: Color, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sky := rect.size.y * 0.6
	for band in 6:
		_feed.draw_rect(Rect2(rect.position.x, rect.position.y + band * sky / 6.0, rect.size.x, sky / 6.0 + 1.0),
				color.lightened(0.45 - band * 0.07))
	var sun := rect.position + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.15, 0.35)) * rect.size
	_feed.draw_circle(sun.round(), 12.0, color.lightened(0.75))
	var height := rng.randf_range(0.3, 0.5)
	for x in range(0, int(rect.size.x), 4):
		height = clampf(height + rng.randf_range(-0.05, 0.05), 0.2, 0.6)
		var hill := roundf(height * rect.size.y)
		_feed.draw_rect(Rect2(rect.position.x + x, rect.end.y - hill, 4, hill), color.darkened(0.45))
	_feed.draw_rect(Rect2(rect.position.x, rect.end.y - 20, rect.size.x, 20), color.darkened(0.7))


## Los "me gusta" de una publicación: siempre los mismos para cada una.
func _likes(index: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = index + 100
	return rng.randi_range(12, 2400)


func _draw_text(canvas: CanvasItem, text: String, baseline_left: Vector2, color: Color) -> void:
	canvas.draw_string(FONT, baseline_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
```

El feed es un nodo aparte que recorta lo que dibuja a la pantalla del celular:

`scenes/ui/phone_view.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/phone_view.gd" id="phone_script"]

[node name="PhoneView" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_left = 140.0
offset_top = 100.0
offset_right = 400.0
offset_bottom = 620.0
script = ExtResource("phone_script")

[node name="Feed" type="Control" parent="."]
clip_contents = true
layout_mode = 0
offset_left = 14.0
offset_top = 64.0
offset_right = 246.0
offset_bottom = 480.0
mouse_filter = 2
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `319 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ test/
git commit -m "Redes sociales en el celular" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 15: El mixer y el celular en el escritorio

**Archivos:**

- Modificar: `scripts/desk/desk.gd`, `scenes/desk/desk.tscn`, `test/test_desk_scene.gd`

El escritorio agrega las vistas del mixer y del celular. Un clic en el mixer o en el celular abre su vista y cierra los paneles y la otra vista; abrir el chat o el cuaderno las cierra (modos exclusivos, decisión de Benja). `Esc` o un clic fuera cierran todo. Cuando empieza el aviso de una interferencia, suena estática, y al terminar la noche, el mixer y el celular se cierran.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
func test_el_mixer_y_el_celular_son_modos_exclusivos() -> bool:
	var desk := _make_desk()
	var mixer := desk.get_node("UI/MixerView") as Control
	var phone := desk.get_node("UI/PhoneView") as Control
	_open_panels(desk)
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	check(mixer.visible and not phone.visible and _panels_closed(desk), "el mixer, sin paneles")
	desk.get_node("DeskPlane/Phone").clicked.emit()
	check(phone.visible and not mixer.visible, "el celular cierra el mixer")
	check_eq(phone.post_at_top(), 0, "con las publicaciones del catálogo")
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	check(not phone.visible and (desk.get_node("UI/ChatPanel") as Control).visible, "abrir el chat cierra el celular")
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	check(not mixer.visible and (desk.get_node("UI/NotebookPanel") as Control).visible, "abrir el cuaderno cierra el mixer")
	desk.free()
	return true


func test_esc_y_un_clic_fuera_cierran_el_mixer_y_el_celular() -> bool:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	for object_name: String in ["Mixer", "Phone"]:
		for event: InputEvent in [escape, _click(MOUSE_BUTTON_LEFT)]:
			var desk := _make_desk()
			desk.get_node("DeskPlane/" + object_name).clicked.emit()
			desk._unhandled_input(event)
			check(not (desk.get_node("UI/MixerView") as Control).visible and not (desk.get_node("UI/PhoneView") as Control).visible,
					"%s cerrado" % object_name)
			desk.free()
	return true


func test_la_estatica_suena_al_anunciarse_una_interferencia() -> bool:
	var desk := _make_desk()
	var state := _state(desk)
	var sound := desk.get_node("InterferenceSound") as AudioStreamPlayer
	state.interferences.pending.clear()
	desk._process(0.0)
	check(not sound.playing, "en silencio")
	state.interferences.pending.append(InterferenceSchedule.Interference.new(1, state.elapsed + 2.0))
	desk._process(0.0)
	check(sound.playing, "suena la estática")
	desk.free()
	return true


func test_al_terminar_la_noche_se_cierran_el_mixer_y_el_celular() -> bool:
	var desk := _make_desk()
	desk.get_node("DeskPlane/Mixer").clicked.emit()
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	check(not (desk.get_node("UI/MixerView") as Control).visible, "el mixer se cierra: su ronda no sigue sonando")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `319 pruebas OK, 4 fallidas`. Fallan las 4 pruebas nuevas de `test_desk_scene.gd`.

- [ ] **Paso 3: Las vistas en el escritorio**

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="FontFile" path="res://fonts/departure_mono/DepartureMono-Regular.otf" id="pixel_font"]
```

por:

```ini
[ext_resource type="FontFile" path="res://fonts/departure_mono/DepartureMono-Regular.otf" id="pixel_font"]
[ext_resource type="PackedScene" path="res://scenes/ui/mixer_view.tscn" id="mixer_view"]
[ext_resource type="PackedScene" path="res://scenes/ui/phone_view.tscn" id="phone_view"]
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="NotebookPanel" parent="UI" instance=ExtResource("notebook_panel")]

[node name="Overlay" type="CanvasLayer" parent="."]
```

por:

```ini
[node name="NotebookPanel" parent="UI" instance=ExtResource("notebook_panel")]

[node name="MixerView" parent="UI" instance=ExtResource("mixer_view")]

[node name="PhoneView" parent="UI" instance=ExtResource("phone_view")]

[node name="InterferenceSound" type="AudioStreamPlayer" parent="."]
stream = ExtResource("static_sound")
volume_db = -6.0

[node name="Overlay" type="CanvasLayer" parent="."]
```

`scripts/desk/desk.gd` (archivo completo):

```gdscript
extends Node2D
## Escena principal del escritorio. Las entradas del PC muestran las solicitudes de cada amigo (parpadean
## y muestran su tiempo mientras esperan respuesta) y abren el chat en su conversación. El cuaderno se abre
## con un clic en él o en el nombre de la entidad, y muestra la página del amigo del chat. El chat y el
## cuaderno son independientes y pueden estar abiertos a la vez (decisión de Benja). Cada uno se cierra
## con clic derecho sobre él; Esc o un clic fuera de los paneles cierra los dos.
## Desde el Plan 5, los diales, el celular y el PC muestran el estado de la noche, la viñeta oscurece
## la vista cuando baja Sanity, y al terminar la noche aparece una pantalla que explica qué pasó.
## Desde el Plan 6, un clic en el mixer abre su vista (Audio Sync) y uno en el celular, sus redes sociales.
## Son modos exclusivos: cierran los paneles y el otro modo, y abrir un panel los cierra (decisión de Benja).
## Cuando se anuncia una interferencia, suena estática.

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const DialGauge := preload("res://scripts/desk/dial_gauge.gd")
const FriendRequest := preload("res://scripts/core/friend_request.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const NightState := preload("res://scripts/core/night_state.gd")
const NotebookMemory := preload("res://scripts/core/notebook_memory.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")

## Videos recibidos, en el PC (ui.csv). Lleva {received} y {quota}.
const VIDEOS_KEY := "PC_VIDEOS"

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
var notebook_memory: NotebookMemory

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel
@onready var _notebook_panel: Control = $UI/NotebookPanel
@onready var _requests: RequestManager = $RequestManager
@onready var _night: NightManager = $NightManager
@onready var _dial_connection: DialGauge = $WallPlane/DialConnection
@onready var _dial_sanity: DialGauge = $WallPlane/DialSanity
@onready var _dial_trust: DialGauge = $WallPlane/DialTrust
@onready var _clock: Label = $DeskPlane/Phone/Clock
@onready var _videos: Label = $DeskPlane/PC/Videos
@onready var _vignette: ColorRect = $Overlay/Vignette
@onready var _end_screen: Control = $Overlay/EndScreen
@onready var _mixer: Control = $UI/MixerView
@onready var _phone: Control = $UI/PhoneView
@onready var _interference_sound: AudioStreamPlayer = $InterferenceSound

## Qué amigos tenían anunciada una interferencia en el frame anterior: la estática suena al empezar el aviso.
var _warned: Array[bool] = []


func _ready() -> void:
	var friends := _requests.catalog.friends
	notebook_memory = NotebookMemory.new(friends.size())
	_night.setup(_requests)
	_chat_panel.setup(_requests, friends, notebook_memory)
	_notebook_panel.setup(notebook_memory, _requests.catalog.known_entities(_requests.night_number), friends)
	_mixer.setup(_requests, friends)
	_phone.setup(_requests.state, _requests.catalog.phone_posts)
	_warned.resize(friends.size())
	_warned.fill(false)
	for index in _entries.size():
		_entries[index].display_name = tr(friends[index].name_key)
		_entries[index].pressed.connect(_on_entry_pressed.bind(index))
	_chat_panel.visibility_changed.connect(_refresh_entries)
	_chat_panel.friend_selected.connect(_notebook_panel.select_friend)
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
	_requests.request_started.connect(_on_request_started)
	_night.night_ended.connect(_on_night_ended)
	_end_screen.retry_pressed.connect(_on_retry_pressed)
	$DeskPlane/Notebook.clicked.connect(_open_notebook)
	$DeskPlane/Mixer.clicked.connect(open_mixer)
	$DeskPlane/Phone.clicked.connect(open_phone)


func _process(_delta: float) -> void:
	_refresh_entries()
	_refresh_meters()


## Cierra el chat y el cuaderno. El celular y el mixer se usan sin ningún panel abierto (decisión de Benja).
func close_panels() -> void:
	_chat_panel.hide()
	_notebook_panel.hide()


## Cierra el mixer y el celular.
func close_modes() -> void:
	_mixer.close()
	_phone.close()


## Audio Sync: el mixer se usa sin paneles y sin el celular.
func open_mixer() -> void:
	close_panels()
	_phone.close()
	_mixer.open()


## Las redes sociales: el celular se usa sin paneles y sin el mixer.
func open_phone() -> void:
	close_panels()
	_mixer.close()
	_phone.open()


## El escritorio es el último en recibir la entrada: aquí llega lo que nadie atendió. Las entradas del PC
## y los objetos del escritorio consumen sus clics, y los paneles, el mixer y el celular, los que caen sobre
## ellos. Esc o un clic fuera de ellos los cierra.
func _unhandled_input(event: InputEvent) -> void:
	if not (_chat_panel.visible or _notebook_panel.visible or _mixer.visible or _phone.visible):
		return
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	if event.is_action_pressed(&"ui_cancel") or click:
		close_panels()
		close_modes()
		get_viewport().set_input_as_handled()


func _on_entry_pressed(index: int) -> void:
	close_modes()
	_chat_panel.open_for(index)
	_refresh_entries()


## Abre el cuaderno en la página del amigo del chat. El chat queda como estaba: abierto o cerrado.
func _open_notebook() -> void:
	close_modes()
	_notebook_panel.open_for(_chat_panel.selected_friend)


func _on_entity_page_requested(friend_index: int, entity: EntityData) -> void:
	notebook_memory.open_page(friend_index, entity)
	_notebook_panel.open_for(friend_index)


## Una solicitud nueva empieza en el índice: la página de la anterior casi nunca sirve (decisión de Benja).
func _on_request_started(friend_index: int, _request: FriendRequest) -> void:
	notebook_memory.close_page(friend_index)


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
## y el celular se cierran, para que la ronda de Audio Sync no siga sonando.
func _on_night_ended(ending: NightState.Ending, fatal_request: FriendRequest) -> void:
	close_modes()
	var names: Array[String] = []
	for friend: FriendData in _requests.catalog.friends:
		names.append(tr(friend.name_key))
	_end_screen.show_ending(ending, _requests.state, fatal_request, names)


## La noche empieza de nuevo y se vuelve a generar, así que no se repite de memoria (diseño §5).
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta o la
## descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le queda para responder,
## para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y si viene una
## interferencia.
func _refresh_entries() -> void:
	var state := _requests.state
	for index in _entries.size():
		var entry := _entries[index]
		var request := _requests.requests[index]
		var friend := state.friends[index]
		var offer := state.videos.offer_for(index)
		var entry_state := ChatEntry.State.IDLE
		if _chat_panel.visible and index == _chat_panel.selected_friend:
			entry_state = ChatEntry.State.SELECTED
		elif not friend.is_online():
			entry_state = ChatEntry.State.DISCONNECTED
		elif request != null or offer != null:
			entry_state = ChatEntry.State.WARNING
		elif friend.is_stunned():
			entry_state = ChatEntry.State.STUNNED
		if entry.state != entry_state:
			entry.set_state(entry_state)
		entry.set_health(friend.health, friend.max_health)
		entry.set_signal(friend.signal_level)
		var warning := state.interference_warning(index)
		entry.set_interference_warning(warning)
		if warning and not _warned[index]:
			_interference_sound.play()
		_warned[index] = warning
		if request != null:
			entry.set_seconds_left(ceili(request.time_left))
		elif offer != null:
			entry.show_video(ceili(offer.time_left))
		elif friend.is_stunned():
			entry.show_stun(ceili(friend.stun_left))
		elif not friend.is_online():
			entry.show_offline()
		else:
			entry.set_seconds_left(-1)


## Los diales (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del PC
## y la viñeta de Sanity.
func _refresh_meters() -> void:
	var state := _requests.state
	_dial_connection.value = state.connection() / NightState.METER_MAX
	_dial_sanity.value = state.sanity / NightState.METER_MAX
	_dial_trust.value = state.trust / NightState.METER_MAX
	_clock.text = state.clock_text()
	_videos.text = tr(VIDEOS_KEY).format({"received": state.videos.received, "quota": state.videos.quota})
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", state.vignette_strength())
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `323 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ test/
git commit -m "Mixer y celular en el escritorio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 16: Sincronizar desde el chat

**Archivos:**

- Modificar: `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scripts/ui/mixer_view.gd`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_chat_panel.gd`, `test/test_mixer_view.gd`, `test/test_desk_scene.gd`

El chat de cada amigo tiene un botón «Sincronizar», a la derecha de la barra de identificación (decisión de Benja): cierra el chat, abre el mixer en el canal de ese amigo y la ronda empieza enseguida. Así, quien ve la estática o el aviso de que el amigo está sin señal lo arregla ahí mismo. En la noche 1, que no tiene Audio Sync, el botón no aparece.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_panel.gd`:

```gdscript
func test_el_boton_sincronizar() -> bool:
	var panel := _make_panel()
	panel.open_for(1)
	panel._process(0.0)
	var sync := panel.get_node("Panel/IdentifyBar/Sync") as Button
	check(not sync.visible, "en la noche 1 no hay Audio Sync")
	_manager.catalog.nights[0].audio_sync_beats = 4
	panel._process(0.0)
	check(sync.visible, "con Audio Sync, se ve")
	check_eq(sync.text, tr("CHAT_SYNC").to_upper(), "en mayúsculas")
	check(sync.text != "CHAT_SYNC", "el texto está en ui.csv")
	var requested := []
	panel.sync_requested.connect(func(friend_index: int) -> void: requested.append(friend_index))
	sync.pressed.emit()
	check_eq(requested, [1], "pide sincronizar a Gonzalo, el del chat")
	_free(panel)
	return true
```

Agregar al final de `test/test_mixer_view.gd`:

```gdscript
func test_se_abre_en_el_canal_de_un_amigo() -> bool:
	var mixer := _make_mixer()
	mixer.open_for(1)
	check(mixer.visible, "se abre")
	check_eq(mixer.selected_friend, 1, "en el canal de Gonzalo, aunque no sea el de menos señal")
	check(mixer.sync_round != null, "con la ronda empezada")
	_free(mixer)
	return true
```

Agregar al final de `test/test_desk_scene.gd`:

```gdscript
func test_sincronizar_desde_el_chat() -> bool:
	var desk := _make_desk()
	desk.get_node("DeskPlane/Entries/EntryAgustin").pressed.emit()
	desk.get_node("UI/ChatPanel").sync_requested.emit(2)
	var mixer := desk.get_node("UI/MixerView") as Control
	check(mixer.visible and not (desk.get_node("UI/ChatPanel") as Control).visible, "el chat se cierra y se abre el mixer")
	check_eq(mixer.selected_friend, 2, "en el canal de Agustín")
	check(mixer.sync_round != null, "con la ronda empezada")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `323 pruebas OK, 3 fallidas`. Fallan las 3 pruebas nuevas: `test_chat_panel.gd :: test_el_boton_sincronizar`, `test_desk_scene.gd :: test_sincronizar_desde_el_chat` y `test_mixer_view.gd :: test_se_abre_en_el_canal_de_un_amigo`.

- [ ] **Paso 3: El botón «Sincronizar»**

El botón va al final de la barra de identificación, que ahora se alinea a la derecha: sin solicitud, el botón queda solo a la derecha.

En `scenes/ui/chat_panel.tscn`, reemplazar:

```ini
offset_bottom = 465.0
```

por:

```ini
offset_bottom = 465.0
alignment = 2
```

En `scenes/ui/chat_panel.tscn`, reemplazar:

```ini
theme_override_font_sizes/font_size = 22
```

por:

```ini
theme_override_font_sizes/font_size = 22

[node name="Sync" type="Button" parent="Panel/IdentifyBar"]
layout_mode = 2
focus_mode = 0
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
## sin señal no se puede preguntar ni responder.
```

por:

```gdscript
## sin señal no se puede preguntar ni responder. El botón «Sincronizar» abre el mixer en el canal del amigo
## (decisión de Benja).
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
signal friend_selected(friend_index: int)
```

por:

```gdscript
signal friend_selected(friend_index: int)
## Clic en «Sincronizar»: el mixer se abre en el canal de este amigo, con la ronda empezada.
signal sync_requested(friend_index: int)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
const OFFLINE_KEY := "CHAT_OFFLINE"
```

por:

```gdscript
const OFFLINE_KEY := "CHAT_OFFLINE"
## El botón que abre el mixer en el canal del amigo (ui.csv).
const SYNC_KEY := "CHAT_SYNC"
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
```

por:

```gdscript
@onready var _entity_button: Button = $Panel/IdentifyBar/EntityName
@onready var _sync_button: Button = $Panel/IdentifyBar/Sync
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	_entity_button.pressed.connect(_on_entity_pressed)
```

por:

```gdscript
	_entity_button.pressed.connect(_on_entity_pressed)
	_sync_button.text = tr(SYNC_KEY).to_upper()
	_sync_button.pressed.connect(_on_sync_pressed)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	_update_identify_bar()
```

por:

```gdscript
	_update_identify_bar()
	# Sin Audio Sync esa noche (la 1), no hay nada que sincronizar.
	_sync_button.visible = _manager.night().audio_sync_beats > 0
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
		entity_page_requested.emit(selected_friend, request.entity)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
```

por:

```gdscript
		entity_page_requested.emit(selected_friend, request.entity)


func _on_sync_pressed() -> void:
	sync_requested.emit(selected_friend)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)
```

por:

```gdscript
	tween.tween_property(self, ^"modulate:a", 1.0, 0.15)


## Se abre en el canal del amigo `friend_index` y la ronda empieza enseguida: es lo que hace el botón
## «Sincronizar» del chat (decisión de Benja).
func open_for(friend_index: int) -> void:
	open()
	selected_friend = friend_index
	start_round(friend_index)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Son modos exclusivos: cierran los paneles y el otro modo, y abrir un panel los cierra (decisión de Benja).
```

por:

```gdscript
## Son modos exclusivos: cierran los paneles y el otro modo, y abrir un panel los cierra (decisión de Benja).
## El botón «Sincronizar» del chat también abre el mixer, en el canal de ese amigo.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
```

por:

```gdscript
	_chat_panel.entity_page_requested.connect(_on_entity_page_requested)
	_chat_panel.sync_requested.connect(open_mixer_for)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_mixer.open()
```

por:

```gdscript
	_mixer.open()


## El botón «Sincronizar» del chat: el mixer se abre en el canal de ese amigo, con la ronda empezada.
func open_mixer_for(friend_index: int) -> void:
	close_panels()
	_phone.close()
	_mixer.open_for(friend_index)
```

Agregar al final de `data/text/ui.csv`:

```csv
CHAT_SYNC,Sincronizar,
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `326 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ data/ test/
git commit -m "Sincronizar desde el chat" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 17: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_maintenance.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/02_bucle_central.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `326 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Capturar el mantenimiento y revisarlo**

`test/capture_maintenance.gd` no empieza con `test_`, así que el ejecutor de pruebas no lo corre.

`test/capture_maintenance.gd`:

```gdscript
extends SceneTree
## Capturas del mantenimiento para revisarlo a ojo (Plan 6). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_maintenance.gd -- /mnt/c/dev/capturas/mixer.png /mnt/c/dev/capturas/download.png /mnt/c/dev/capturas/phone.png
## 1. Las 02:00. León tiene 72 de señal, Gonzalo 18 y Agustín 0 (sin señal). En el mixer, una ronda con
##    Gonzalo, mientras el amigo aplaude.
## 2. El chat de León, que mandó un video: Matías lo descarga manteniendo presionada la barra. Agustín, sin
##    señal, pidió ayuda: su entrada muestra el tiempo.
## 3. El celular, scrolleado.

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	manager.requests_arrive = false
	manager.rng.seed = 5
	var state: RefCounted = manager.state
	state.elapsed = 140.0
	state.videos.pending.clear()
	state.interferences.pending.clear()
	var signals := [72.0, 18.0, 0.0]
	for index in 3:
		state.friends[index].signal_decay_interval = 0.0
		state.friends[index].signal_level = signals[index]
	desk.open_mixer()
	desk.get_node("UI/MixerView").start_round(1)
	await create_timer(3.4).timeout
	await _save(0)
	desk.close_modes()
	manager.start_request(2)
	state.videos.add_extra(0, state.elapsed)
	await create_timer(0.2).timeout
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	desk.get_node("UI/ChatPanel/Panel/Download/Hold").button_down.emit()
	await create_timer(4.0).timeout
	await _save(1)
	desk.get_node("UI/ChatPanel/Panel/Download/Hold").button_up.emit()
	desk.open_phone()
	desk.get_node("UI/PhoneView").scroll_by(400.0)
	await create_timer(1.0).timeout
	await _save(2)
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

Se ejecuta **con ventana** (sin `--headless`): Godot abre una ventana unos 10 segundos y se cierra solo.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_maintenance.gd -- /mnt/c/dev/capturas/mixer.png /mnt/c/dev/capturas/download.png /mnt/c/dev/capturas/phone.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: `Captura guardada en C:\dev\capturas\mixer.png`, lo mismo con `download.png` y con `phone.png`. Abrir las imágenes (con la herramienta Read) y comprobar.

En `mixer.png`:

- a la izquierda, el mixer visto desde arriba: dos perillas grises, dos VU-metros azules con "TÚ" debajo del de la izquierda y "GONZALO" debajo del de la derecha, y una fila de 8 luces con algunas en azul (los aplausos que van);
- tres canales: LEÓN, con el fader en 72; GONZALO, elegido (con el borde de su color), en 18; y AGUSTÍN, en 0, con el número y el LED en rojo;
- abajo, "ESCUCHA A GONZALO" y la ayuda "ESPACIO O CLIC: MARCA EL RITMO · CLIC DERECHO: SALIR";
- en el PC, 5 barras de señal en cada entrada: León con 4 llenas, Gonzalo con 1 y Agustín con ninguna y "Sin señal".

En `download.png`:

- el chat de León, con su mensaje "Te mandé un video, Mati. ¡Descárgalo antes de que se corte!";
- sobre la barra de identificación, la barra de descarga, verde hasta un 40 % más o menos, que dice "▼ DESCARGANDO 39 % · 17" (o un número cercano);
- debajo de ella, a la derecha y sobre las preguntas, el botón "SINCRONIZAR";
- la pestaña de Agustín, con el tiempo de su solicitud y `•`;
- en el PC, la entrada de León dice "Video" con sus segundos, y la de Agustín, el tiempo de su solicitud.

En `phone.png`:

- a la izquierda, el celular: la hora arriba (cerca de las 02:07), la señal y la batería, y "copuchas" en naranja;
- las publicaciones, cada una con su autor, un paisaje pixelado, "♥" con un número y su texto en dos líneas como máximo;
- el feed no se sale de la pantalla del celular.

Si algo no coincide, revisarlo antes de seguir.

- [ ] **Paso 3: Actualizar las instrucciones de Godot (`docs/04_instrucciones_godot.md`)**

Desde el Plan 6, el mixer y el celular abren sus vistas, y los videos se descargan. Cuatro secciones decían otra cosa.

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
| **I.** Probar la noche (Plan 5) | ⬜ Pendiente (unos 15 minutos) |
```

por:

```markdown
| **I.** Probar la noche (Plan 5) | ⬜ Pendiente (unos 15 minutos) |
| **J.** Probar el mantenimiento (Plan 6) | ⬜ Pendiente (unos 20 minutos) |
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
   - **Clics:** al hacer clic en el celular o el mixer, en el panel **Output** (Salida) de Godot aparece "Clic en Phone" o "Clic en Mixer". Al hacer clic en el cuaderno, se abre su panel (Plan 4).
```

por:

```markdown
   - **Clics:** al hacer clic en el mixer o en el celular, se abre su vista ampliada (Plan 6). Al hacer clic en el cuaderno, se abre su panel (Plan 4).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
8. **El panel tapa el escritorio:** con el chat abierto, pasa el mouse por donde están el mixer y el celular, detrás del panel. No deben resaltarse, y un clic no debe escribir "Clic en Mixer" en **Output**. Cierra el chat (`Esc` o clic derecho) y vuelve a probar: ahora sí se resaltan.
```

por:

```markdown
8. **El panel tapa el escritorio:** con el chat abierto, pasa el mouse por donde están el mixer y el celular, detrás del panel. No deben resaltarse, y un clic no debe abrir el mixer. Cierra el chat (`Esc` o clic derecho) y vuelve a probar: ahora sí se resaltan.
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
7. **El celular y el mixer:** con solo el cuaderno abierto, haz clic en el mixer. El cuaderno se cierra, y en el panel **Output** (Salida) aparece "Clic en Mixer".
```

por:

```markdown
7. **El celular y el mixer:** con solo el cuaderno abierto, haz clic en el mixer. El cuaderno se cierra y se abre el mixer (Plan 6).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
   - arriba de la pantalla del PC dice "Videos: 0 de 3". A las 01:30, a las 03:00 y a las 04:30 llega un video, y el contador sube solo (por ahora no hay que aceptarlo);
   - en la pared, el dial del medio (Sanity, aguja roja) baja de a poco. El de abajo (Trust, aguja amarilla) baja cuando eliges mal. El de arriba (Connection, aguja verde) no se mueve hasta el Plan 6;
```

por:

```markdown
   - arriba de la pantalla del PC dice "Videos: 0 de 3". A las 01:30, a las 03:00 y a las 04:30 llega un video, que hay que descargar en el chat (sección J);
   - en la pared, el dial del medio (Sanity, aguja roja) baja de a poco. El de abajo (Trust, aguja amarilla) baja cuando eliges mal. El de arriba (Connection, aguja verde) baja con la señal de los amigos (sección J);
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
4. **La acción de mayor riesgo:** en otra solicitud, elige la de mayor riesgo. Si el amigo sobrevive, el contador de videos sube uno más; si quedó herido, el video llega cuando se recupera. Trust baja más que con una acción incorrecta.
```

por:

```markdown
4. **La acción de mayor riesgo:** en otra solicitud, elige la de mayor riesgo. Si el amigo sobrevive, manda un video extra, que hay que descargar en su chat; si quedó herido, lo manda cuando se recupera. Trust baja más que con una acción incorrecta.
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
8. **Ganar:** juega una noche completa (7 minutos) sin que muera nadie. A las 06:00, si llegaron los 3 videos, aparece "Llegaste a las 06:00" con el botón **Jugar de nuevo**.
```

por:

```markdown
8. **Ganar:** juega una noche completa (7 minutos) sin que muera nadie. A las 06:00, si descargaste los 3 videos, aparece "Llegaste a las 06:00" con el botón **Jugar de nuevo**.
```

Agregar al final de `docs/04_instrucciones_godot.md`:

````markdown
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
````

- [ ] **Paso 4: Actualizar la hoja de ruta, el modelo de datos, el registro y el resumen**

- `docs/06_plan_v1.md`: en la línea del Plan 6, cambiar "(por ejecutar)" por "(ejecutado)".
- `docs/02_bucle_central.md`, en §10:
  - en la línea de `BalanceData`, agregar al final: ", el scroll del celular, la señal (interferencias y Trust sin señal), Audio Sync (tempo y tolerancia) y los videos (plazos y descarga)";
  - en la línea de `ContentCatalog`, cambiar "balance (data/catalog.tres)" por "balance, phone_posts[] (data/catalog.tres)", y agregar antes de ella la línea `PhonePostData    author_key, text_key, picture (sin imagen, se dibuja un paisaje), color`;
  - en el párrafo de arriba del bloque, agregar ", y las publicaciones del celular, en el Plan 6 (`docs/13`)" después de "`BalanceData`, en el Plan 5 (`docs/12`)".
- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar:
  - la sección J de `docs/04`;
  - entre los textos que Benja corrige: en `messages.csv`, el aviso del video (`FRIEND_VIDEO_SENT`); en `ui.csv`, los avisos de videos y señal (`CHAT_VIDEO_*`, `CHAT_SIGNAL_*` y `CHAT_OFFLINE`), el botón «Sincronizar» (`CHAT_SYNC`), las entradas (`ENTRY_VIDEO` y `ENTRY_OFFLINE`), la descarga (`DOWNLOAD_*`), el mixer (`MIXER_*`) y `END_CHOSEN_OFFLINE`; y todo `phone.csv`;
  - el arte del mixer visto desde arriba y del celular ampliado (ver "Fuera de este plan").
- `docs/00_log.md`:
  - S15 queda ✅;
  - S16 (escribir el Plan 7: screamers y director) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/13` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` y `.import` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/ scenes/ data/ audio/ tools/
git commit -m "Plan 6 terminado: mantenimiento" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Fuera de este plan, a propósito

- **El arte de Benja** (`docs/06` §3). Cuando esté, Claude lo integra sin cambiar la lógica ni las pruebas de comportamiento:
  - **el mixer visto desde arriba:** el cuerpo, los dos VU-metros azules (el de la izquierda para Matías y el de la derecha para el amigo), la perilla de un fader, los LED y las luces del ritmo. Reemplazan el dibujo de `mixer_view.gd`; la ronda (`AudioSyncRound`) no cambia;
  - **el celular ampliado**, con las publicaciones o con la animación del scroll. La imagen de cada publicación va en **Picture**, en su `PhonePostData` de `data/catalog.tres`;
  - **las barras de señal** de las entradas del PC, que hoy son rectángulos.
- **Plan 7 (screamers y director):** el director de ritmo puede decidir cuándo llegan los videos y las interferencias, que hoy se reparten parejo en la noche.
- **Plan 8 (opciones):** "Reducir destellos" debe apagar el parpadeo de las entradas y de los LED del mixer, y hay que decidir si "Temporizadores ×1,5" alarga también los plazos de los videos.
- **Plan 9 (sonido):** los sonidos definitivos reemplazan los de `audio/sfx/` (con los mismos nombres) y van a sus buses: hoy todos van a Master. Faltan sonidos para cuando llega un video y cuando se recibe.
- **Lo que llegó tapado sigue tapado:** si un amigo sin señal se reconecta, sus mensajes de antes no se recuperan; hay que preguntar de nuevo. Es así a propósito.

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 6; diseño §10.1, §10.2, §10.5 y §10.6; decisiones de Benja):

  | Requisito | Tarea |
  | --- | --- |
  | La señal de cada amigo baja a su ritmo, y Connection es su promedio | 2, 5 y 8 |
  | Interferencias de −40, anunciadas 3 s antes con la entrada titilando y estática | 1, 3, 5, 8, 11 y 15 |
  | Sin señal: el mensaje llega tapado entero, no lee preguntas ni respuestas y, al acabarse el tiempo, elige mal sin bajar Trust; Trust baja mientras haya amigos sin señal (decisión de Benja) | 2, 5, 6 y 9 |
  | Avisos en el chat: el video que llega, se recibe o se pierde, y la señal que se pierde o vuelve | 7 |
  | Videos: 15 s para empezar, 20 s para terminar y 10 s de descarga (15 s con señal débil, detenida sin señal), manteniendo presionado en el chat (decisión de Benja) | 1, 4, 8 y 9 |
  | Audio Sync en el mixer: se empieza con un clic en el mixer, el amigo marca un ritmo con sonido sobre una base, y Matías lo repite con clics o con la barra espaciadora; los VU-metros de Matías (izquierda) y del amigo (derecha); si sale bien, la señal vuelve a 100 (decisión de Benja) | 10, 11, 12 y 15 |
  | «Sincronizar» desde el chat, en el canal de ese amigo (decisión de Benja) | 16 |
  | Audio Sync de 4 u 8 aplausos según la noche, con reintentos, y se puede salir | 10 y 12 |
  | El celular: scrollear con la rueda recupera Sanity, con un feed provisional atractivo (decisión de Benja) | 1, 5, 13, 14 y 15 |
  | El mixer y el celular son modos exclusivos | 15 |
  | "Las tres tareas de mantenimiento funcionan en la noche" | 15, 16 y 17 (`docs/04`, J) |

- **Nombres consistentes:**
  - `BalanceData` (`scroll_*`, `interference_*`, `offline_trust_interval`, `audio_sync_*`, `video_*_seconds` y `download_*`) se usa igual en `NightState`, `VideoSchedule`, `MixerView`, `ChatPanel` y las pruebas;
  - `FriendState` (`signal_level`, `signal_decay_interval`, `is_online()`, `is_available()`, `can_send()`, `interfere()` y `restore_signal()`) coincide entre las tareas 2, 4, 5, 6, 7, 8, 9 y 12;
  - `InterferenceSchedule` (`Interference`, `pending`, `is_warning()` y `take_due()`) y `NightState.interference_warning()` coinciden entre las tareas 3, 5, 8 y 15;
  - `VideoSchedule` (`Offer`, `Changes`, `offers`, `lost`, `offer_for()`, `download_rate()` y `advance()`) y `NightState` (`Events`, `holding_download`, `scroll()` y `offline_count()`) coinciden entre las tareas 4, 5, 7, 8, 9 y 14;
  - los avisos (`ChatMessage.Tone`, `MessageBuilder.video_sent()`, `notice()` y sus claves, `ChatMessageView.GOOD_COLOR`, `RequestManager.report()` y `restore_signal()`) coinciden entre las tareas 7 y 12;
  - `AudioSyncRound` (`Phase`, `Tap`, `STEPS_PER_BAR`, `pattern`, `steps`, `step_seconds`, `advance()`, `tap()`, `hits()`, `is_beat()`, `is_accent()` e `is_clap()`) coincide entre las tareas 10 y 12;
  - `MixerView` (`setup()`, `open()`, `open_for()`, `close()`, `start_round()`, `tap()`, `channel_rect()`, `status_text()`, `sync_round`, `player_level` y `friend_level`), `PhoneView` (`setup()`, `open()`, `close()`, `scroll_by()`, `post_at_top()` y `scroll`) y `PhonePostData` coinciden con `desk.gd` y las pruebas;
  - `ChatPanel.sync_requested` y `desk.gd` (`open_mixer()`, `open_mixer_for()`, `open_phone()` y `close_modes()`) coinciden entre las tareas 15 y 16 y sus pruebas;
  - los nodos nuevos (`Panel/Download` y `Panel/IdentifyBar/Sync` del chat, `Signal` de la entrada, `UI/MixerView`, `UI/PhoneView` e `InterferenceSound` del escritorio) son los que usan los scripts y las pruebas.
- **Conteo de pruebas acumulado:** 251 → 252, 255, 259, 264, 269, 276, 283, 289, 294, 302, 303, 312, 314, 319, 323 y 326.
