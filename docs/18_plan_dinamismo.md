# Plan 9: Dinamismo — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que el juego deje de ser solo reactivo, con las notas que Benja dio el 7 de noviembre después de probarlo (`docs/17_ideas_dinamismo.md`):

1. **Barras arriba de la pantalla** para Connection, Sanity y Trust, porque los diales no se entendían.
2. **Acertar es más difícil:** menos tiempo, sin pista desde la noche 3, más señuelos y entidades que se confunden.
3. **Audio Sync más rápido**, noche a noche y de una ronda a la siguiente.
4. **Audios en «¿Qué oyes?»:** el amigo manda un audio y lo que se oye cambia la acción correcta.
5. **Batería del celular:** un tope por noche, para que Sanity no se rellene gratis.
6. **Cortinas** que se abren y se cierran, con la criatura que se queda y hay que revisar.
7. **Accidentes:** un amigo se hiere sin que nadie tenga la culpa, y se responde con sentido común.

**Arquitectura:**

- Datos: `ObservationData.audio_values` (valor → audio), `IncidentData` (nuevo, en `ContentCatalog.incidents`), `NightData` (`audio_sync_bpm`, `creature_visits`, `incident_count`) y `BalanceData`.
- Lógica pura: `NightState` lleva la batería, las cortinas y la criatura afuera; `FriendIncident` (nuevo) es un accidente en curso; `PacingDirector` reparte las visitas de la criatura y los accidentes; `ContentValidator` revisa los audios y los accidentes; `TutorialGuide` enseña las cortinas.
- Escritorio: `ScreamerManager` lleva las cortinas y la criatura, `RequestManager` lleva los accidentes y `StatBars` (nuevo) dibuja las barras.
- Interfaz: `ChatMessage` y `ChatMessageView` muestran el audio como un enlace, `ChatPanel` lo hace sonar y muestra las opciones de un accidente, y `PhoneView` muestra la batería.
- Sonidos: `tools/make_placeholder_sounds.py` genera 15 audios provisionales en `audio/clues/`.

**Stack:** Godot 4.7.2 (GDScript con tipado estático). Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `docs/17_ideas_dinamismo.md`, `spook_dial_design.md` §7, §8, §10, §11 y §14, y `docs/02_bucle_central.md` §6.

**Validación:** este plan salió de código que ya corrió en una copia aparte (`C:\dev\plan9`), con 521 pruebas OK, sin errores al correr y 5 capturas revisadas. Después, un script lo aplicó tal como está escrito sobre una copia limpia: todos los conteos de abajo son los que dio esa pasada.

---

## Decisiones de este plan

### De Benja (7 de noviembre, después de probar el juego)

Se agregan a `CLAUDE.md` y al diseño v2 en la Tarea 11.

| Decisión | Detalle |
| --- | --- |
| **Barras en el hueco central, arriba, y los diales se quedan.** | Entre el chat y el cuaderno, que no las tapan. Cada una con su color. |
| **Acertar a tiempo es fácil por el cuaderno y por el tiempo.** | Se baja el tiempo y se complican las reglas. |
| **Los audios cambian la acción correcta.** | Si El Tue Tué suena 3 veces es distinto a si suena 1 o 0. Si La Calchona bala es distinto a si bufa. |
| **Audio Sync más rápido.** | Benja lo pidió sin valores. |
| **La batería es un tope por noche, sin recarga.** | Para que no se abuse de rellenar Sanity. |
| **Las cortinas se abren y se cierran.** | Cerradas, el cuarto se oscurece y Sanity baja de a poco. Con algo afuera y abiertas, baja rápido. |
| **La criatura se queda un tiempo fijo.** | Hay que abrir la cortina para revisar si sigue ahí y volver a cerrarla si sigue. Al aparecer, abre la cortina. |
| **El screamer de la cortina:** | se abre o se cierra sola, en vez de mecerse. |
| **Accidentes con respuesta (opción C2).** | Una solicitud corta, sin entidad ni cuaderno, que se responde con sentido común. |
| **La historia y editar videos quedan para después.** | Primero las mecánicas (`docs/05`, puntos 21 y 22). |

### Supuestos de Claude (Benja los corrige)

Benja no los decidió. Todos los valores son de partida y están en `data/balance.tres` y `data/nights/night_N.tres`.

| Supuesto | Por qué |
| --- | --- |
| Tiempo para responder: 80, 65, 55, 45 y 40 s. Pista: 100, 75, 0, 0 y 0 %. Señuelos: 1, 2, 3, 3 y 4. | Los valores de ejemplo de `docs/17`. |
| Audio Sync: 90, 100, 115, 130 y 145 golpes por minuto, y cada ronda un 15 % más rápida. | A 145 una corchea dura 0,21 s, más que la tolerancia de 0,15 s: todavía se distinguen los golpes. La tolerancia no se toca. |
| La batería dura 38 s de scroll. | A +4 de Sanity por segundo son 150 puntos: una vez y media la barra, como proponía `docs/17`. |
| La batería también corre en la noche 0, y sin batería el celular dice "Sin batería". La hora sigue en el celular del escritorio. | Enseña que se acaba. La hora no se puede perder. |
| Cortinas cerradas: −0,3 de Sanity por segundo. Criatura afuera con la cortina abierta: −2 por segundo. La criatura se queda 25 s desde que llega y sigue restando 15 al llegar. | En el peor caso, sin hacer nada, son unos 65 puntos. Cerrar enseguida deja el costo cerca de 20. |
| **Con la cortina cerrada, la criatura no se oye.** | Si se oyera, no haría falta abrir para revisar, que es lo que Benja pidió. Detrás del chat o el mixer sus golpes se repiten: avisan que hay que ir a la ventana. |
| Revisar no tiene un costo extra: con la cortina abierta y la criatura ahí, corre el goteo rápido, y nada más. | Era una pregunta abierta de `docs/17`. |
| La criatura llega 1, 2, 2 y 3 veces en las noches 2 a 5 (`creature_visits` reemplaza a `has_jumpscare`). | Una vez por noche casi no se notaría la mecánica. Sale de los screamers de la noche: no se suman. |
| El cuarto se oscurece un 35 %, de golpe, y las cortinas cambian de golpe. | Benja dibujó 2 estados, sin animación. |
| Las cortinas se pueden clickear con el chat abierto, en la parte que se ve, y ese clic no cierra el chat. También se clickean en el hueco de la ventana. | Cerrarlas tiene que ser rápido. |
| **El audio no identifica a la entidad:** las características siguen siendo texto clickeable, y el audio es una observación. | Así la identificación no cambia. Lo que cambia es la acción. |
| Un audio se escucha gratis, las veces que se quiera (dura 3 s), y solo cuesta el tiempo que pasa. La estática lo tapa entero: hay que volver a preguntar. Al cerrar el chat se corta. | Igual que una frase clickeable tapada. |
| Mientras suena un audio no empiezan screamers ni alucinaciones. | Se confundirían con él: es la misma regla de Audio Sync. |
| Opción nueva **"Subtítulos de los audios"**, apagada por defecto. | Sin ella, quien no oye no puede jugar (diseño §19). También ayuda mientras los sonidos son de relleno. |
| Las reglas de 5 entidades cambian para que el audio decida. Tue Tué: `cries` (una, tres o ninguna) reemplaza a `cried_three_times`. Cuero, Trauco: la regla del audio pasa a ser la primera. Trauco: `ground` pasa a oírse. Viuda y Basilisco: una observación nueva (`heels` y `crows`). Calchona e Imbunche ya dependían del sonido y solo suman los audios. | Regla 8: son borradores que Benja corrige antes del 25-nov. |
| El Trauco comparte 2 características con La Calchona (suma `long_tangled_hair`, sin "como de mujer" en el texto), y El Imbunche, 2 con El Basilisco (suma `shed_skin`). | `docs/17`, noches 3 a 5. |
| Accidentes: 1, 1, 2, 2 y 3 por noche, 15 s para responder, −1 de vida y aturdido, sin bajar Trust. Con "Temporizadores ×1,5", 22,5 s. | Un accidente no es culpa de Matías. |
| **Un accidente nunca mata:** solo le pasa a un amigo libre, con señal y con más de 1 de vida. | Perder la noche por azar se sentiría injusto. |
| Un accidente se reparte como un screamer y **puede caer en el respiro**, salvo que la ola esté llena. | Corrige a `docs/17`, que decía respetar el respiro: ese tiempo muerto es justo el que hay que llenar. |
| Las barras dicen Connection, Sanity y Trust, y el aviso de la noche 0 usa esos nombres, no Conexión, Cordura y Confianza. | Son los nombres que usa Benja y los del resto de los textos. |
| Las barras titilan si bajan 2 puntos o más de una vez, y prenden una luz bajo 25. | El diseño ya pedía un LED de alerta. |
| La noche 0 enseña las cortinas con la criatura del susto guionado, que también se queda 25 s. El aviso del tutorial baja a y = 70, bajo las barras. | Si no, la mecánica nueva llega sin práctica. |
| Los textos nuevos son borradores de Claude. | Regla 8 de `CLAUDE.md`. |

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`.
- [ ] **El arte de Benja está en git.** `art/sprites/curtains_sprite.aseprite` ya tiene los tags `Open` y `Closed`.
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```text
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | tail -1
  ```

  Esperado: `461 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.

Todos los comandos se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Importar y probar.** Cada paso que corre las pruebas importa antes, porque Godot registra clases, `.uid` y audio nuevos:

```text
~/tools/godot-wsl.sh --headless --path "$PWD" --import 2>&1 | tr -d '\r' | grep -E "SCRIPT|Parse" ; echo "import listo"
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | grep -E "^FALLA|SCRIPT ERROR|pruebas OK"
```

Al importar puede salir `importer for type 'aseprite_wizard...' not found` para las cortinas. Es un aviso de la primera pasada: el archivo se importa igual.

En los pasos "Verificar que fallan", Esperado: las pruebas nuevas aparecen como `FALLA` (o su suite como "no se pudo cargar"), con el conteo que dice el paso. Una suite que no carga cuenta como una sola falla y sus pruebas no corren, así que el total puede bajar mucho: en las Tareas 4 y 10, `content_fixtures.gd` usa algo que todavía no existe y arrastra a todas las suites que lo cargan. Es lo esperado.

**Commits.** Cada tarea termina en un commit, directo en `main`. Hay que preguntarle a Benja al empezar si los autoriza todos (`CLAUDE.md`, regla 11). No hay `push`. Cada commit lleva la línea de atribución que indique la sesión.

**OneDrive:** si Write o Edit responden "no such file", el cambio normalmente quedó escrito. Verificar con `grep` antes de reintentar.

**Tabuladores:** GDScript indenta con tabuladores. Los bloques de este plan los tienen y se aplican con un script, como en los planes 8 y 8.1.

**Cómo leer los cambios:**

- "`ruta`:" seguido de un bloque: crear el archivo con ese contenido.
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo en ese momento. Si hay varios seguidos para el mismo archivo, se aplican en orden.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/ui/stat_bars.gd` (nuevo), `scenes/desk/desk.tscn`, `scenes/ui/tutorial_hint.tscn` | Las barras y el aviso del tutorial bajo ellas |
| `data/nights/night_*.tres`, `data/entities/*.tres`, `data/balance.tres`, `scripts/data/night_data.gd`, `scripts/data/balance_data.gd` | Los valores de cada noche y las entidades |
| `scripts/ui/mixer_view.gd` | Audio Sync con la base de la noche y rondas más rápidas |
| `scripts/data/observation_data.gd`, `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/ui/chat_message_view.gd`, `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn` | Los audios en el chat |
| `scripts/core/game_settings.gd`, `scripts/ui/options_panel.gd`, `scenes/ui/options_panel.tscn` | La opción de subtítulos |
| `tools/make_placeholder_sounds.py`, `audio/clues/*.wav` (nuevos) | Los 15 audios provisionales |
| `scripts/core/night_state.gd`, `scripts/ui/phone_view.gd`, `data/text/phone.csv` | La batería y lo que bajan las cortinas y la criatura |
| `scripts/desk/clickable_sprite.gd`, `scripts/desk/screamer_manager.gd`, `scripts/core/screamer.gd`, `scripts/core/pacing_director.gd` | Las cortinas y la criatura |
| `scripts/core/tutorial_guide.gd`, `scripts/desk/desk.gd` | La noche 0 y conectar todo en el escritorio |
| `scripts/data/incident_data.gd`, `scripts/core/friend_incident.gd` (nuevos), `scripts/desk/request_manager.gd`, `data/catalog.tres` | Los accidentes |
| `scripts/core/content_validator.gd` | Revisa audios y accidentes |
| `data/text/*.csv` | Los textos nuevos |
| `CLAUDE.md`, `spook_dial_design.md`, `docs/02`, `docs/04`, `docs/06`, `docs/17`, `arte_pendiente.md`, `sonidos_pendiente.md`, `resumen.md`, `docs/00_log.md` | Documentos |
| `test/test_*.gd`, `test/content_fixtures.gd`, `test/capture_plan9.gd` | Pruebas y capturas |

---

### Tarea 1: Las barras de Connection, Sanity y Trust

**Archivos:**

- Crear: `scripts/ui/stat_bars.gd`, `test/test_stat_bars.gd`
- Modificar: `scenes/desk/desk.tscn`, `scenes/ui/tutorial_hint.tscn`, `scripts/desk/desk.gd`, `data/text/ui.csv`

Van en la capa `Overlay`, encima de la viñeta, para que Sanity baja no las oscurezca, y debajo de la pantalla final y de la pausa. No reciben clics. Se dibujan con rectángulos, como el mixer.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_stat_bars.gd`:

```gdscript
extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const StatBars := preload("res://scripts/ui/stat_bars.gd")


func _make_bars() -> Control:
	var bars := StatBars.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(bars)
	return bars


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func test_cada_barra_muestra_su_valor() -> bool:
	var bars := _make_bars()
	bars.set_values(40.0, 60.0, 80.0)
	check_eq(bars.fill(StatBars.Stat.CONNECTION), 0.4, "Connection")
	check_eq(bars.fill(StatBars.Stat.SANITY), 0.6, "Sanity")
	check_eq(bars.fill(StatBars.Stat.TRUST), 0.8, "Trust")
	bars.free()
	return true


func test_cada_barra_conserva_el_color_de_su_dial() -> bool:
	check(StatBars.COLORS[StatBars.Stat.CONNECTION].g > 0.7, "Connection, verde")
	check(StatBars.COLORS[StatBars.Stat.SANITY].r > 0.8 and StatBars.COLORS[StatBars.Stat.SANITY].g < 0.5, "Sanity, roja")
	check(StatBars.COLORS[StatBars.Stat.TRUST].r > 0.8 and StatBars.COLORS[StatBars.Stat.TRUST].g > 0.7, "Trust, amarilla")
	return true


func test_titila_si_baja_de_golpe_y_no_si_baja_de_a_poco() -> bool:
	var bars := _make_bars()
	bars.set_values(100.0, 100.0, 100.0)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "el primer valor no cuenta como una baja")
	bars.set_values(100.0, 99.9, 100.0)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "de a poco no titila")
	bars.set_values(100.0, 91.9, 100.0)
	check(bars.is_flashing(StatBars.Stat.SANITY), "un susto la hace titilar")
	check(not bars.is_flashing(StatBars.Stat.TRUST), "las otras, no")
	bars._process(StatBars.FLASH_SECONDS + 0.1)
	check(not bars.is_flashing(StatBars.Stat.SANITY), "deja de titilar")
	bars.free()
	return true


func test_avisa_bajo_25() -> bool:
	var bars := _make_bars()
	bars.set_values(25.0, 24.0, 100.0)
	check(not bars.is_alert(StatBars.Stat.CONNECTION), "con 25, todavía no")
	check(bars.is_alert(StatBars.Stat.SANITY), "con 24, sí")
	bars.free()
	return true


func test_con_reducir_destellos_la_luz_no_parpadea() -> bool:
	var bars := _make_bars()
	bars.set_values(100.0, 10.0, 100.0)
	bars.reduce_flashes = true
	for step in 8:
		bars._process(0.1)
		check_eq(bars.alert_light(), 1.0, "queda fija")
	bars.free()
	return true


## Van arriba, en el hueco entre el chat y el cuaderno, y no reciben clics.
func test_estan_en_el_hueco_entre_el_chat_y_el_cuaderno() -> bool:
	var desk := _make_desk()
	var bars := desk.get_node("Overlay/StatBars") as Control
	var chat_right: float = desk.get_node("UI/ChatPanel/Panel").get_global_rect().end.x
	var notebook_left: float = desk.get_node("UI/NotebookPanel/Page").get_global_rect().position.x
	var rect := bars.get_global_rect()
	check(rect.position.x >= chat_right, "el chat no las tapa")
	check(rect.end.x <= notebook_left, "el cuaderno no las tapa")
	check(rect.end.y <= 92.0, "quedan sobre la barra de las cortinas")
	check_eq(bars.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no reciben clics")
	desk.free()
	return true


func test_el_aviso_del_tutorial_va_debajo_de_las_barras() -> bool:
	var desk := _make_desk()
	var bars := desk.get_node("Overlay/StatBars") as Control
	var hint := desk.get_node("Overlay/TutorialHint") as Control
	check(hint.offset_top >= bars.offset_bottom, "no se tapan")
	desk.free()
	return true


func test_muestran_el_estado_de_la_noche() -> bool:
	var desk := _make_desk()
	var state: RefCounted = desk.get_node("RequestManager").state
	state.sanity = 50.0
	state.trust = 30.0
	desk._process(0.0)
	var bars := desk.get_node("Overlay/StatBars") as Control
	check_eq(bars.fill(StatBars.Stat.SANITY), 0.5, "Sanity")
	check_eq(bars.fill(StatBars.Stat.TRUST), 0.3, "Trust")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `461 pruebas OK, 1 fallidas`.

- [ ] **Paso 3: Escribir las barras y conectarlas**

En `data/text/ui.csv`, reemplazar:

```csv
TUTORIAL_PHONE,"El susto bajó tu Sanity, el dial rojo. Haz clic en el celular del escritorio.",
```

por:

```csv
TUTORIAL_PHONE,"El susto bajó tu Sanity, la barra roja. Haz clic en el celular del escritorio.",
```

En `data/text/ui.csv`, reemplazar:

```csv
TUTORIAL_DIALS,"Los 3 diales de la pared: Conexión (verde) es la señal de tus amigos. Cordura (roja) baja con los sustos y sube con el celular. Confianza (amarilla) baja si respondes mal o tardas en contestar. Si uno llega a 0, se pierde la noche.",
TUTORIAL_DIALS_OK,Entendido,
```

por:

```csv
TUTORIAL_DIALS,"Mira las 3 barras de arriba, que son también los diales de la pared. Connection (verde) es la señal de tus amigos. Sanity (roja) baja con los sustos y sube con el celular. Trust (amarilla) baja si respondes mal o tardas en contestar. Si una llega a 0, se pierde la noche.",
TUTORIAL_DIALS_OK,Entendido,
HUD_CONNECTION,Connection,
HUD_SANITY,Sanity,
HUD_TRUST,Trust,
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[ext_resource type="PackedScene" path="res://scenes/ui/phone_view.tscn" id="phone_view"]
```

por:

```text
[ext_resource type="PackedScene" path="res://scenes/ui/phone_view.tscn" id="phone_view"]
[ext_resource type="Script" path="res://scripts/ui/stat_bars.gd" id="stat_bars_script"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
mouse_filter = 2

[node name="TutorialHint" parent="Overlay" instance=ExtResource("tutorial_hint")]
```

por:

```text
mouse_filter = 2

[node name="StatBars" type="Control" parent="Overlay"]
layout_mode = 3
anchors_preset = 0
offset_left = 490.0
offset_top = 8.0
offset_right = 790.0
offset_bottom = 62.0
mouse_filter = 2
script = ExtResource("stat_bars_script")

[node name="TutorialHint" parent="Overlay" instance=ExtResource("tutorial_hint")]
```

En `scenes/ui/tutorial_hint.tscn`, reemplazar:

```text
offset_top = 12.0
```

por:

```text
offset_top = 70.0
```

En `scenes/ui/tutorial_hint.tscn`, reemplazar:

```text
offset_bottom = 12.0
```

por:

```text
offset_bottom = 70.0
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Con Esc y sin nada abierto, la noche se pausa y aparece el menú de pausa (decisión de Benja, sesión 18).
```

por:

```gdscript
## Con Esc y sin nada abierto, la noche se pausa y aparece el menú de pausa (decisión de Benja, sesión 18).
## Desde el Plan 9, unas barras arriba de la pantalla muestran lo mismo que los diales, que se quedan (decisión de
## Benja).
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _vignette: ColorRect = $Overlay/Vignette
```

por:

```gdscript
@onready var _vignette: ColorRect = $Overlay/Vignette
@onready var _stat_bars: Control = $Overlay/StatBars
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_screamers.reduce_flashes = settings.reduce_flashes
```

por:

```gdscript
	_screamers.reduce_flashes = settings.reduce_flashes
	_stat_bars.reduce_flashes = settings.reduce_flashes
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Los diales (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del PC
## y la viñeta de Sanity.
```

por:

```gdscript
## Los diales y las barras (cada uno con su color fijo, decisión de Benja), la hora del celular, los videos del
## PC y la viñeta de Sanity.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_dial_trust.value = state.trust / NightState.METER_MAX
```

por:

```gdscript
	_dial_trust.value = state.trust / NightState.METER_MAX
	_stat_bars.set_values(state.connection(), state.sanity, state.trust)
```

`scripts/ui/stat_bars.gd`:

```gdscript
extends Control
## Las barras de Connection, Sanity y Trust (decisión de Benja, 7 de noviembre): dicen de un vistazo cómo va la
## noche, porque los diales de la pared no se entendían. Van arriba, en el hueco entre el chat y el cuaderno, así
## que ninguno de los dos las tapa, y cada una conserva el color de su dial. Titilan si bajan de golpe y prenden
## una luz con poco valor. Son provisionales hasta el arte: se dibujan con rectángulos.

## Las barras, de arriba hacia abajo.
enum Stat { CONNECTION, SANITY, TRUST }

const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")

## Sus nombres (ui.csv), en el orden de Stat.
const LABEL_KEYS: Array[String] = ["HUD_CONNECTION", "HUD_SANITY", "HUD_TRUST"]
## Los colores de las agujas de los diales, en el orden de Stat.
const COLORS: Array[Color] = [Color(0.35, 0.85, 0.45), Color(1.0, 0.3, 0.37), Color(0.95, 0.82, 0.3)]
const FONT_SIZE := 11
const METER_MAX := 100.0
## Una barra titila si baja al menos tantos puntos de una vez.
const FLASH_DROP := 2.0
const FLASH_SECONDS := 0.6
## Bajo este valor se prende su luz.
const ALERT_BELOW := 25.0
## Segundos que la luz de alerta está encendida, y después apagada.
const BLINK_SECONDS := 0.25
const BACK_COLOR := Color(0.03, 0.05, 0.09, 0.85)
const EDGE_COLOR := Color(0.24, 0.26, 0.34)
const TRACK_COLOR := Color(0.1, 0.11, 0.16)
const TEXT_COLOR := Color(0.86, 0.88, 0.94)
const LIGHT_OFF := Color(0.2, 0.22, 0.28)
## Dónde va cada parte, en píxeles de las barras.
const ROW_TOP := 5.0
const ROW_HEIGHT := 16.0
const LABEL_LEFT := 7.0
const BAR_LEFT := 93.0
const BAR_SIZE := Vector2(184, 10)
const LIGHT_LEFT := 283.0

## La opción "Reducir destellos" (diseño §19): la luz de alerta queda fija y la barra titila una sola vez.
var reduce_flashes := false

var _values: Array[float] = [METER_MAX, METER_MAX, METER_MAX]
var _flash_left: Array[float] = [0.0, 0.0, 0.0]
var _started := false
var _blink := 0.0


## Muestra los valores de 0 a 100. Una barra que bajó de golpe titila; el primer valor no cuenta como una baja.
func set_values(connection: float, sanity: float, trust: float) -> void:
	var next: Array[float] = [connection, sanity, trust]
	for stat in next.size():
		if _started and _values[stat] - next[stat] >= FLASH_DROP:
			_flash_left[stat] = FLASH_SECONDS
		_values[stat] = next[stat]
	_started = true
	queue_redraw()


## Cuánto se llena la barra, de 0 a 1.
func fill(stat: Stat) -> float:
	return clampf(_values[stat] / METER_MAX, 0.0, 1.0)


func is_flashing(stat: Stat) -> bool:
	return _flash_left[stat] > 0.0


func is_alert(stat: Stat) -> bool:
	return _values[stat] < ALERT_BELOW


## Cuánto brilla la luz de alerta: parpadea, o queda fija si se reducen los destellos.
func alert_light() -> float:
	return 1.0 if reduce_flashes or fmod(_blink, BLINK_SECONDS * 2.0) < BLINK_SECONDS else 0.0


func _process(delta: float) -> void:
	_blink += delta
	for stat in _flash_left.size():
		_flash_left[stat] = maxf(_flash_left[stat] - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE_COLOR, false)
	for stat: int in Stat.values():
		_draw_row(stat)


## Una fila: el nombre, la barra de su color y la luz de alerta. Al bajar de golpe, la barra se aclara.
func _draw_row(stat: Stat) -> void:
	var top := ROW_TOP + stat * ROW_HEIGHT
	draw_string(FONT, Vector2(LABEL_LEFT, top + 10.0), tr(LABEL_KEYS[stat]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE, TEXT_COLOR)
	var bar := Rect2(Vector2(BAR_LEFT, top + 1.0), BAR_SIZE)
	draw_rect(bar, TRACK_COLOR)
	var color := COLORS[stat]
	if is_flashing(stat):
		var lit := reduce_flashes or fmod(_flash_left[stat], BLINK_SECONDS) < BLINK_SECONDS / 2.0
		color = color.lightened(0.55) if lit else color
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_SIZE.x * fill(stat)), BAR_SIZE.y)), color)
	var light := COLORS[stat].lerp(LIGHT_OFF, 1.0 - alert_light()) if is_alert(stat) else LIGHT_OFF
	draw_rect(Rect2(Vector2(LIGHT_LEFT, top + 2.0), Vector2(8, 8)), light)
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `469 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "Barras de Connection, Sanity y Trust"
```

---

### Tarea 2: Acertar es más difícil

**Archivos:**

- Modificar: `data/nights/night_1.tres` a `night_5.tres`, `data/entities/trauco.tres`, `data/entities/imbunche.tres`, `data/text/messages.csv`, `test/test_balance.gd`, `test/test_catalog.gd`

Solo datos. Las entidades que se confunden siguen siendo válidas: cada una conserva características propias, así que `distinguishing_pairs()` encuentra pares.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
## La identificación por preguntas (decisión de Benja, 3 de noviembre): más tiempo por solicitud, menos
## solicitudes por noche (la atención es en serie) y una pista opcional en el mensaje inicial.
```

por:

```gdscript
## La identificación por preguntas (decisión de Benja, 3 de noviembre): menos solicitudes por noche (la atención
## es en serie) y una pista opcional en el mensaje inicial. Desde el 7 de noviembre, el tiempo baja más rápido, no
## hay pista desde la noche 3 y hay más señuelos: acertar a tiempo era demasiado fácil.
```

En `test/test_balance.gd`, reemplazar:

```gdscript
	var times := [85.0, 80.0, 75.0, 70.0, 65.0]
	var hints := [1.0, 0.75, 0.5, 0.35, 0.2]
	var decoys := [1, 1, 2, 2, 3]
```

por:

```gdscript
	var times := [80.0, 65.0, 55.0, 45.0, 40.0]
	var hints := [1.0, 0.75, 0.0, 0.0, 0.0]
	var decoys := [1, 2, 3, 3, 4]
```

En `test/test_catalog.gd`, reemplazar:

```gdscript
const ContentValidator := preload("res://scripts/core/content_validator.gd")
```

por:

```gdscript
const ContentValidator := preload("res://scripts/core/content_validator.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
```

En `test/test_catalog.gd`, reemplazar:

```gdscript
		check(not post.author_key.is_empty() and not post.text_key.is_empty(), "cada una con su autor y su texto")
	return true

```

por:

```gdscript
		check(not post.author_key.is_empty() and not post.text_key.is_empty(), "cada una con su autor y su texto")
	return true


## Desde la noche 3 hay entidades que se confunden: comparten 2 características, y solo se distinguen por otra
## (decisión de Benja, 7 de noviembre).
func test_entidades_que_comparten_2_caracteristicas() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for pair: Array in [[&"trauco", &"calchona"], [&"imbunche", &"basilisco"]]:
		var first := _entity(catalog, pair[0])
		var second := _entity(catalog, pair[1])
		var shared := 0
		for trait_data: TraitData in first.traits:
			if second.traits.any(func(other: TraitData) -> bool: return other.id == trait_data.id):
				shared += 1
		check_eq(shared, 2, "%s y %s comparten 2" % pair)
		var known := catalog.all_entities()
		check(not RequestGenerator.distinguishing_pairs(first, known).is_empty(), "%s se puede distinguir" % pair[0])
		check(not RequestGenerator.distinguishing_pairs(second, known).is_empty(), "%s se puede distinguir" % pair[1])
	return true


func _entity(catalog: ContentCatalog, entity_id: StringName) -> EntityData:
	for entity: EntityData in catalog.all_entities():
		if entity.id == entity_id:
			return entity
	return null

```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `468 pruebas OK, 2 fallidas`.

- [ ] **Paso 3: Cambiar los valores y las características**

En `data/entities/imbunche.tres`, reemplazar:

```text
text_key = "TRAIT_STALE_AIR"
```

por:

```text
text_key = "TRAIT_STALE_AIR"

[sub_resource type="Resource" id="Trait_shed_skin"]
script = ExtResource("2_trait")
id = &"shed_skin"
category = 3
text_key = "TRAIT_SHED_SKIN"
```

En `data/entities/imbunche.tres`, reemplazar:

```text
traits = Array[ExtResource("2_trait")]([SubResource("Trait_one_leg_hop"), SubResource("Trait_hoarse_grunts"), SubResource("Trait_stale_air")])
```

por:

```text
traits = Array[ExtResource("2_trait")]([SubResource("Trait_one_leg_hop"), SubResource("Trait_hoarse_grunts"), SubResource("Trait_stale_air"), SubResource("Trait_shed_skin")])
```

En `data/entities/trauco.tres`, reemplazar:

```text
text_key = "TRAIT_SNAGGED_THREADS"
```

por:

```text
text_key = "TRAIT_SNAGGED_THREADS"

[sub_resource type="Resource" id="Trait_long_tangled_hair"]
script = ExtResource("2_trait")
id = &"long_tangled_hair"
text_key = "TRAIT_LONG_TANGLED_HAIR"
```

En `data/entities/trauco.tres`, reemplazar:

```text
traits = Array[ExtResource("2_trait")]([SubResource("Trait_little_man"), SubResource("Trait_three_blows"), SubResource("Trait_snagged_threads")])
```

por:

```text
traits = Array[ExtResource("2_trait")]([SubResource("Trait_little_man"), SubResource("Trait_three_blows"), SubResource("Trait_snagged_threads"), SubResource("Trait_long_tangled_hair")])
```

En `data/nights/night_1.tres`, reemplazar:

```text
base_decision_time = 85.0
```

por:

```text
base_decision_time = 80.0
```

En `data/nights/night_2.tres`, reemplazar:

```text
base_decision_time = 80.0
```

por:

```text
base_decision_time = 65.0
```

En `data/nights/night_2.tres`, reemplazar:

```text
decoys_per_request = 1
```

por:

```text
decoys_per_request = 2
```

En `data/nights/night_3.tres`, reemplazar:

```text
base_decision_time = 75.0
first_hint_chance = 0.5
decoys_per_request = 2
```

por:

```text
base_decision_time = 55.0
first_hint_chance = 0.0
decoys_per_request = 3
```

En `data/nights/night_4.tres`, reemplazar:

```text
base_decision_time = 70.0
first_hint_chance = 0.35
decoys_per_request = 2
```

por:

```text
base_decision_time = 45.0
first_hint_chance = 0.0
decoys_per_request = 3
```

En `data/nights/night_5.tres`, reemplazar:

```text
base_decision_time = 65.0
first_hint_chance = 0.2
decoys_per_request = 3
```

por:

```text
base_decision_time = 40.0
first_hint_chance = 0.0
decoys_per_request = 4
```

En `data/text/messages.csv`, reemplazar:

```csv
TRAIT_LONG_TANGLED_HAIR,"Tiene *pelo largo y enredado*, como de mujer.",
```

por:

```csv
TRAIT_LONG_TANGLED_HAIR,Tiene *pelo largo y enredado*.,
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `470 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "Menos tiempo, sin pista desde la noche 3 y entidades que se confunden"
```

---

### Tarea 3: Audio Sync más rápido

**Archivos:**

- Modificar: `scripts/data/night_data.gd`, `scripts/data/balance_data.gd`, `data/balance.tres`, `data/nights/night_1.tres` a `night_5.tres`, `scripts/ui/mixer_view.gd`, `test/test_balance.gd`, `test/test_mixer_view.gd`

`audio_sync_bpm` pasa de `BalanceData` a `NightData`, y `BalanceData` gana `audio_sync_round_speedup`. Fallar la segunda ronda vuelve a la primera, así que vuelve a su velocidad.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
	check_eq(balance.audio_sync_bpm, 100.0, "base de Audio Sync a 100 golpes por minuto")
```

por:

```gdscript
	check_eq(balance.audio_sync_round_speedup, 1.15, "cada ronda va un 15 % más rápido que la anterior")
```

En `test/test_balance.gd`, reemplazar:

```gdscript
	var beats := [4, 4, 4, 8, 8]
```

por:

```gdscript
	var beats := [4, 4, 4, 8, 8]
	var bpms := [90.0, 100.0, 115.0, 130.0, 145.0]
```

En `test/test_balance.gd`, reemplazar:

```gdscript
		check_eq(night.audio_sync_beats, beats[index], who + ": aplausos de Audio Sync")
```

por:

```gdscript
		check_eq(night.audio_sync_beats, beats[index], who + ": aplausos de Audio Sync")
		check_eq(night.audio_sync_bpm, bpms[index], who + ": golpes por minuto de Audio Sync")
```

En `test/test_mixer_view.gd`, reemplazar:

```gdscript
	check(not mixer.status_text().contains(tr("MIXER_ROUND").format({"round": 1, "total": 1})), "no dice 'ronda 1 de 1'")
	_free(mixer)
	return true

```

por:

```gdscript
	check(not mixer.status_text().contains(tr("MIXER_ROUND").format({"round": 1, "total": 1})), "no dice 'ronda 1 de 1'")
	_free(mixer)
	return true


## La base de cada noche es la de NightData, y la segunda ronda va más rápida (decisión de Benja, 7 de noviembre).
func test_la_base_es_la_de_la_noche_y_la_segunda_ronda_va_mas_rapida() -> bool:
	var mixer := _make_two_round_mixer()
	_manager.catalog.nights[1].audio_sync_bpm = 120.0
	mixer.open()
	mixer.start_round(0)
	check_eq(mixer.sync_round.step_seconds, 0.25, "la primera, a 120 golpes por minuto")
	_advance_to(mixer, mixer.sync_round.response_start())
	_tap_pattern(mixer)
	check_eq(mixer.round_index, 1, "pasó a la segunda")
	check(is_equal_approx(mixer.sync_round.step_seconds, 0.25 / 1.15), "la segunda, un 15 % más rápida")
	_free(mixer)
	return true

```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `468 pruebas OK, 3 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/balance.tres`, reemplazar:

```text
audio_sync_bpm = 100.0
```

por:

```text
audio_sync_round_speedup = 1.15
```

En `data/nights/night_1.tres`, reemplazar:

```text
audio_sync_beats = 4
```

por:

```text
audio_sync_beats = 4
audio_sync_bpm = 90.0
```

En `data/nights/night_2.tres`, reemplazar:

```text
audio_sync_beats = 4
```

por:

```text
audio_sync_beats = 4
audio_sync_bpm = 100.0
```

En `data/nights/night_3.tres`, reemplazar:

```text
audio_sync_beats = 4
```

por:

```text
audio_sync_beats = 4
audio_sync_bpm = 115.0
```

En `data/nights/night_4.tres`, reemplazar:

```text
audio_sync_beats = 8
```

por:

```text
audio_sync_beats = 8
audio_sync_bpm = 130.0
```

En `data/nights/night_5.tres`, reemplazar:

```text
audio_sync_beats = 8
```

por:

```text
audio_sync_beats = 8
audio_sync_bpm = 145.0
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
## Golpes por minuto de la base. El ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0
```

por:

```gdscript
## Cuánto más rápida es cada ronda que la anterior, en las noches de varias rondas (decisión de Benja, 7 de
## noviembre). La base de la primera es la de NightData.audio_sync_bpm.
@export var audio_sync_round_speedup := 1.15
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var audio_sync_beats := 0
```

por:

```gdscript
@export var audio_sync_beats := 0
## Golpes por minuto de la base del Audio Sync, que sube noche a noche (decisión de Benja, 7 de noviembre). El
## ritmo del amigo va en corcheas, 2 por golpe.
@export var audio_sync_bpm := 100.0
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
## Arma la ronda `round_index`, con su cuenta y su patrón al azar.
```

por:

```gdscript
## Arma la ronda `round_index`, con su cuenta y su patrón al azar. La base es la de la noche, y cada ronda va más
## rápida que la anterior (decisión de Benja, 7 de noviembre).
```

En `scripts/ui/mixer_view.gd`, reemplazar:

```gdscript
	sync_round = AudioSyncRound.new(mini(beats(), ROUND_BEATS), balance.audio_sync_bpm, balance.audio_sync_tolerance,
			_manager.rng)
```

por:

```gdscript
	var bpm := _manager.night().audio_sync_bpm * pow(balance.audio_sync_round_speedup, round_index)
	sync_round = AudioSyncRound.new(mini(beats(), ROUND_BEATS), bpm, balance.audio_sync_tolerance, _manager.rng)
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `471 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "Audio Sync más rápido por noche y por ronda"
```

---

### Tarea 4: Los audios en el chat

**Archivos:**

- Modificar: `scripts/data/observation_data.gd`, `scripts/core/chat_message.gd`, `scripts/core/message_builder.gd`, `scripts/ui/chat_message_view.gd`, `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `scripts/desk/desk.gd`, `scripts/desk/screamer_manager.gd`, `scripts/core/game_settings.gd`, `scripts/ui/options_panel.gd`, `scenes/ui/options_panel.tscn`, `scripts/core/content_validator.gd`, `data/text/ui.csv`, `test/content_fixtures.gd` y las pruebas de cada uno

El audio es una pieza más del mensaje (`Token.is_audio`) y se muestra como un enlace `[url]`, igual que una frase clickeable. Así la estática lo tapa sin código nuevo: `ChatStatic` recorre las piezas. Esta tarea no cambia ninguna entidad: la Tarea 5 pone los audios.

- [ ] **Paso 1: Escribir las pruebas**

En `test/content_fixtures.gd`, reemplazar:

```gdscript
	return data

```

por:

```gdscript
	return data


## Un audio de `seconds` segundos de silencio.
static func make_audio(seconds := 1.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data := PackedByteArray()
	data.resize(int(seconds * 44100) * 2)
	stream.data = data
	return stream

```

En `test/test_chat_message.gd`, reemplazar:

```gdscript
	check_eq(message.plain_text(), "Vi un %s %s" % [ChatMessage.COVER_TEXT, ChatMessage.COVER_TEXT], "texto con estática")
	return true

```

por:

```gdscript
	check_eq(message.plain_text(), "Vi un %s %s" % [ChatMessage.COVER_TEXT, ChatMessage.COVER_TEXT], "texto con estática")
	return true


func test_un_audio_es_una_sola_pieza() -> bool:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment("Escucha.")
	var stream := AudioStreamWAV.new()
	message.add_audio(stream, "▶ Escuchar audio", "Gritó tres veces.")
	check_eq(message.audio, stream, "el mensaje guarda el audio")
	check_eq(message.audio_caption, "Gritó tres veces.", "y su subtítulo")
	var token: ChatMessage.Token = message.tokens[-1]
	check(token.is_audio, "la última pieza es el audio")
	check_eq(token.text, "▶ Escuchar audio", "entera, sin separar las palabras")
	check(token.can_be_covered(), "la estática lo puede tapar")
	check(not token.is_clue(), "no es una frase clickeable")
	return true

```

En `test/test_chat_message_view.gd`, reemplazar:

```gdscript
	check(not label.text.contains(ChatMessageView.DANGER_COLOR), "no en rojo")
	view.free()
	return true

```

por:

```gdscript
	check(not label.text.contains(ChatMessageView.DANGER_COLOR), "no en rojo")
	view.free()
	return true


## Un mensaje de la solicitud con un audio.
func _make_audio_message(request: FriendRequest) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_audio(Fixtures.make_audio(), "▶ Audio", "Gritó tres veces.")
	return message


func test_un_audio_es_un_enlace() -> bool:
	var view := _make_view(_make_audio_message(_make_request()))
	check(_label(view).text.contains("[url=%s]" % ChatMessageView.AUDIO_META), "se puede clickear")
	check(not _label(view).get_parsed_text().contains("Gritó"), "sin subtítulo")
	var clicked: Array = []
	view.audio_clicked.connect(func(clicked_view: Node) -> void: clicked.append(clicked_view))
	view._on_meta_clicked(ChatMessageView.AUDIO_META)
	check_eq(clicked, [view], "avisa que se clickeó")
	view.free()
	return true


func test_un_audio_tapado_no_se_puede_escuchar() -> bool:
	var message := _make_audio_message(_make_request())
	message.tokens[-1].covered = true
	var view := _make_view(message)
	check(not _label(view).text.contains("[url"), "sin enlace: hay que volver a preguntar")
	check(_label(view).get_parsed_text().contains(ChatMessage.COVER_TEXT), "se ve tapado")
	view.free()
	return true


func test_un_audio_de_una_solicitud_terminada_no_se_escucha() -> bool:
	var request := _make_request()
	var view := _make_view(_make_audio_message(request))
	request.finished = true
	view.refresh()
	check(not _label(view).text.contains("[url"), "sin enlace")
	view.free()
	return true


func test_el_subtitulo_del_audio() -> bool:
	var view := ChatMessageView.new(_make_audio_message(_make_request()), "", Color.WHITE, true)
	(Engine.get_main_loop() as SceneTree).root.add_child(view)
	check(_label(view).get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	view.free()
	return true

```

En `test/test_chat_panel.gd`, reemplazar:

```gdscript
	check_eq(panel.message_views(1).size(), 2, "la línea de Gonzalo y la respuesta de Matías")
	_free(panel)
	return true

```

por:

```gdscript
	check_eq(panel.message_views(1).size(), 2, "la línea de Gonzalo y la respuesta de Matías")
	_free(panel)
	return true


## Abre el chat del amigo 0 con un mensaje con audio.
func _send_audio(panel: Control) -> ChatMessage:
	panel.open_for(0)
	var request := _manager.start_request(0)
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, request)
	message.add_audio(Fixtures.make_audio(), "▶ Audio", "Gritó tres veces.")
	_manager.message_added.emit(0, message)
	return message


func test_clic_en_un_audio_lo_hace_sonar() -> bool:
	var panel := _make_panel()
	var message := _send_audio(panel)
	check(not panel.is_audio_playing(), "todavía no")
	panel.message_views(0)[-1]._on_meta_clicked(ChatMessageView.AUDIO_META)
	check(panel.is_audio_playing(), "suena")
	check_eq((panel.get_node("AudioClip") as AudioStreamPlayer).stream, message.audio, "el audio del mensaje")
	_free(panel)
	return true


func test_al_cerrar_el_chat_el_audio_se_corta() -> bool:
	var panel := _make_panel()
	_send_audio(panel)
	panel.message_views(0)[-1]._on_meta_clicked(ChatMessageView.AUDIO_META)
	panel.hide()
	check(not panel.is_audio_playing(), "se corta")
	_free(panel)
	return true


func test_con_subtitulos_el_audio_se_lee() -> bool:
	var panel := _make_panel()
	panel.audio_captions = true
	_send_audio(panel)
	var label := panel.message_views(0)[-1].get_node("Bubble/Text") as RichTextLabel
	check(label.get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	_free(panel)
	return true

```

En `test/test_game_settings.gd`, reemplazar:

```gdscript
	check(not settings.reduce_flashes and not settings.still_camera and not settings.slow_timers, "todo apagado")
```

por:

```gdscript
	check(not settings.reduce_flashes and not settings.still_camera and not settings.slow_timers, "todo apagado")
	check(not settings.audio_captions, "sin subtítulos: hay que oír los audios")
```

En `test/test_game_settings.gd`, reemplazar:

```gdscript
	settings.still_camera = true
	settings.slow_timers = true
	check_eq(settings.write(TEST_PATH), OK, "se guardan")
```

por:

```gdscript
	settings.still_camera = true
	settings.slow_timers = true
	settings.audio_captions = true
	check_eq(settings.write(TEST_PATH), OK, "se guardan")
```

En `test/test_game_settings.gd`, reemplazar:

```gdscript
	check(read.reduce_flashes and read.still_camera and read.slow_timers, "los interruptores")
```

por:

```gdscript
	check(read.reduce_flashes and read.still_camera and read.slow_timers, "los interruptores")
	check(read.audio_captions, "los subtítulos de los audios")
```

En `test/test_game_settings.gd`, reemplazar:

```gdscript
	for path: String in ["res://scenes/desk/desk.tscn", "res://scenes/ui/mixer_view.tscn"]:
```

por:

```gdscript
	for path: String in ["res://scenes/desk/desk.tscn", "res://scenes/ui/mixer_view.tscn",
			"res://scenes/ui/chat_panel.tscn"]:
```

En `test/test_message_builder.gd`, reemplazar:

```gdscript
				"CHAT_VIDEO_RECEIVED debe tener %s" % placeholder)
	TranslationServer.set_locale(previous)
	return true

```

por:

```gdscript
				"CHAT_VIDEO_RECEIVED debe tener %s" % placeholder)
	TranslationServer.set_locale(previous)
	return true


## El amigo manda un audio en lugar de contar la observación (decisión de Benja, 7 de noviembre).
func test_una_observacion_con_audio_llega_como_audio() -> bool:
	var request := _make_request()
	var stream := Fixtures.make_audio()
	request.entity.observations[1].audio_values = {&"yes": Fixtures.make_audio(), &"no": stream}
	var message := MessageBuilder.answer(request, ClueCategory.Kind.SOUND, _translate)
	check_eq(message.audio, stream, "el audio del valor de esta solicitud")
	check_eq(message.audio_caption, "K_beast_O2_NO.", "su texto queda de subtítulo")
	check(not message.plain_text().contains("K_beast_O2_NO"), "el amigo no lo cuenta")
	check(message.plain_text().contains(MessageBuilder.AUDIO_LABEL_KEY), "se ve el audio: " + message.plain_text())
	check(_clue_ids(message).has(&"beast_trait_2"), "la característica sigue siendo clickeable")
	return true


func test_las_otras_categorias_no_traen_audio() -> bool:
	var request := _make_request()
	request.entity.observations[1].audio_values = {&"yes": Fixtures.make_audio(), &"no": Fixtures.make_audio()}
	check_eq(MessageBuilder.answer(request, ClueCategory.Kind.SIGHT, _translate).audio, null, "¿Qué ves?, sin audio")
	return true

```

En `test/test_options_panel.gd`, reemplazar:

```gdscript
	(panel.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
```

por:

```gdscript
	(panel.get_node("Center/Box/Timers") as CheckBox).button_pressed = true
	(panel.get_node("Center/Box/Captions") as CheckBox).button_pressed = true
```

En `test/test_options_panel.gd`, reemplazar:

```gdscript
	check_eq(changes.size(), 4, "avisa cada cambio")
```

por:

```gdscript
	check(settings.audio_captions, "los subtítulos de los audios")
	check_eq(changes.size(), 5, "avisa cada cambio")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "y se queda a la vista")
	desk.free()
	return true

```

por:

```gdscript
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "y se queda a la vista")
	desk.free()
	return true


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
func test_nada_mientras_suena_un_audio() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel")
	chat.open_for(0)
	var clip := chat.get_node("AudioClip") as AudioStreamPlayer
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var data := PackedByteArray()
	data.resize(44100 * 20)
	stream.data = data
	clip.stream = stream
	clip.play()
	_scare_now(desk)
	_state(desk).elapsed = 100.0
	_process(desk, 3)
	check(not _screamers(desk).is_warning(), "no se anuncia nada")
	desk.free()
	return true

```

En `test/test_validator_entity.gd`, reemplazar:

```gdscript
	check_contains(errors, "no tiene lugares")
	return true

```

por:

```gdscript
	check_contains(errors, "no tiene lugares")
	return true


func test_los_audios_de_una_observacion() -> bool:
	var entity := Fixtures.make_entity()
	var observation := entity.observations[0]
	observation.category = ClueCategory.Kind.SOUND
	observation.audio_values = {&"yes": AudioStreamWAV.new(), &"no": AudioStreamWAV.new()}
	check(ContentValidator.validate_entity(entity).is_empty(), "con un audio por valor, está bien")
	observation.audio_values = {&"yes": AudioStreamWAV.new()}
	check_contains(ContentValidator.validate_entity(entity), "le falta el audio de 'no'")
	observation.audio_values = {&"yes": AudioStreamWAV.new(), &"no": AudioStreamWAV.new(), &"maybe": AudioStreamWAV.new()}
	check_contains(ContentValidator.validate_entity(entity), "el audio 'maybe' no es de ningún valor")
	observation.audio_values = {&"yes": AudioStreamWAV.new(), &"no": AudioStreamWAV.new()}
	observation.category = ClueCategory.Kind.SIGHT
	check_contains(ContentValidator.validate_entity(entity), "los audios van en '¿Qué oyes?'")
	return true

```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `419 pruebas OK, 10 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/text/ui.csv`, reemplazar:

```csv
HUD_TRUST,Trust,
```

por:

```csv
HUD_TRUST,Trust,
CHAT_AUDIO,▶ Escuchar audio,
OPTIONS_AUDIO_CAPTIONS,Subtítulos de los audios,
```

En `scenes/ui/chat_panel.tscn`, reemplazar:

```text
offset_bottom = 675.0
mouse_filter = 2

```

por:

```text
offset_bottom = 675.0
mouse_filter = 2

[node name="AudioClip" type="AudioStreamPlayer" parent="."]
bus = &"Effects"

```

En `scenes/ui/options_panel.tscn`, reemplazar:

```text
theme_override_font_sizes/font_size = 22

[node name="Back" type="Button" parent="Center/Box"]
```

por:

```text
theme_override_font_sizes/font_size = 22

[node name="Captions" type="CheckBox" parent="Center/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 22

[node name="Back" type="Button" parent="Center/Box"]
```

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript
	var covered := false
```

por:

```gdscript
	var covered := false
	## Es el audio del mensaje: se clickea para escucharlo.
	var is_audio := false
```

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript
var request: FriendRequest
```

por:

```gdscript
var request: FriendRequest
## El audio que manda el amigo, o null (decisión de Benja, 7 de noviembre).
var audio: AudioStream
## Qué se oye en el audio, para la opción "Subtítulos de los audios".
var audio_caption := ""
```

En `scripts/core/chat_message.gd`, reemplazar:

```gdscript


## El texto como se ve, con la estática.
```

por:

```gdscript


## Agrega un audio: una sola pieza con `label`, que la estática tapa entera o no tapa.
func add_audio(stream: AudioStream, label: String, caption: String) -> void:
	audio = stream
	audio_caption = caption
	if not tokens.is_empty():
		tokens.append(Token.new(" "))
	var token := Token.new(label)
	token.is_audio = true
	tokens.append(token)


## El texto como se ve, con la estática.
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
			errors.append("%s: la observación '%s' necesita al menos %d valores" % [who, observation.id, MIN_VALUES])
```

por:

```gdscript
			errors.append("%s: la observación '%s' necesita al menos %d valores" % [who, observation.id, MIN_VALUES])
		_check_audio(errors, who, observation)
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript


static func _check_rule(errors: Array[String], who: String, entity: EntityData, index: int) -> void:
```

por:

```gdscript


## Una observación con audios los tiene en "¿Qué oyes?" y tiene uno por cada valor, ni más ni menos.
static func _check_audio(errors: Array[String], who: String, observation: ObservationData) -> void:
	if observation.audio_values.is_empty():
		return
	var where := "%s, observación '%s'" % [who, observation.id]
	if observation.category != ClueCategory.Kind.SOUND:
		errors.append("%s: los audios van en '¿Qué oyes?'" % where)
	for value: StringName in observation.values:
		if observation.audio_for(value) == null:
			errors.append("%s: le falta el audio de '%s'" % [where, value])
	for value: StringName in observation.audio_values:
		if not observation.has_value(value):
			errors.append("%s: el audio '%s' no es de ningún valor" % [where, value])


static func _check_rule(errors: Array[String], who: String, entity: EntityData, index: int) -> void:
```

En `scripts/core/game_settings.gd`, reemplazar:

```gdscript
var slow_timers := false
```

por:

```gdscript
var slow_timers := false
## Los audios de los amigos muestran qué se oye, para quien no pueda oírlos.
var audio_captions := false
```

En `scripts/core/game_settings.gd`, reemplazar:

```gdscript
	slow_timers = bool(file.get_value(SECTION, "slow_timers", false))
```

por:

```gdscript
	slow_timers = bool(file.get_value(SECTION, "slow_timers", false))
	audio_captions = bool(file.get_value(SECTION, "audio_captions", false))
```

En `scripts/core/game_settings.gd`, reemplazar:

```gdscript
	file.set_value(SECTION, "slow_timers", slow_timers)
```

por:

```gdscript
	file.set_value(SECTION, "slow_timers", slow_timers)
	file.set_value(SECTION, "audio_captions", audio_captions)
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
	ClueCategory.Kind.TRACES: "ANSWER_NOTHING_TRACES",
}
## El amigo decidió solo porque nadie respondió a tiempo. {action} es la acción que eligió (messages.csv).
```

por:

```gdscript
	ClueCategory.Kind.TRACES: "ANSWER_NOTHING_TRACES",
}
## Lo que se ve en lugar de una observación que el amigo manda como audio (ui.csv).
const AUDIO_LABEL_KEY := "CHAT_AUDIO"
## El amigo decidió solo porque nadie respondió a tiempo. {action} es la acción que eligió (messages.csv).
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
## inicial, si es de esa categoría) y todas las observaciones de esa categoría. Es la única forma de saberlos.
```

por:

```gdscript
## inicial, si es de esa categoría) y todas las observaciones de esa categoría. Es la única forma de saberlos.
## Una observación con audio llega como audio: hay que escucharla (decisión de Benja, 7 de noviembre).
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
		if observation.category == category:
```

por:

```gdscript
		if observation.category != category:
			continue
		var stream := observation.audio_for(request.situation[observation.id])
		if stream != null:
			message.add_audio(stream, _text(translate, AUDIO_LABEL_KEY), _observation_text(request, observation, translate))
		else:
```

En `scripts/data/observation_data.gd`, reemplazar:

```gdscript
@export var values: Dictionary[StringName, String] = {}
```

por:

```gdscript
@export var values: Dictionary[StringName, String] = {}
## Si tiene audios, el amigo manda el audio del valor en vez de contarlo (decisión de Benja, 7 de noviembre), y el
## texto de `values` queda de subtítulo. Solo en la categoría "¿Qué oyes?": un audio por valor.
@export var audio_values: Dictionary[StringName, AudioStream] = {}
```

En `scripts/data/observation_data.gd`, reemplazar:

```gdscript
	return values.has(value)
```

por:

```gdscript
	return values.has(value)


## El audio de `value`, o null si esta observación se cuenta con texto.
func audio_for(value: StringName) -> AudioStream:
	return audio_values.get(value)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_screamers.advance(delta, _scare_view(), _mixer.is_playing())
```

por:

```gdscript
	_screamers.advance(delta, _scare_view(), _mixer.is_playing() or _chat_panel.is_audio_playing())
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_requests.timer_scale = settings.timer_scale()
```

por:

```gdscript
	_requests.timer_scale = settings.timer_scale()
	_chat_panel.audio_captions = settings.audio_captions
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Avanza `delta` segundos con lo que se ve del escritorio (`view`). Con `busy` (una ronda de Audio Sync),
## no empieza nada: ni screamers ni alucinaciones.
```

por:

```gdscript
## Avanza `delta` segundos con lo que se ve del escritorio (`view`). Con `busy` (una ronda de Audio Sync o un audio
## de un amigo), no empieza nada: ni screamers ni alucinaciones.
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
## y el señuelo vibra y queda rojo. Los avisos del juego, como el de daño, van centrados y en rojo.
```

por:

```gdscript
## y el señuelo vibra y queda rojo. Los avisos del juego, como el de daño, van centrados y en rojo.
## Un audio es otro enlace: se escucha con un clic (decisión de Benja, 7 de noviembre).
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
signal clue_clicked(view: Node, clue_id: StringName)
```

por:

```gdscript
signal clue_clicked(view: Node, clue_id: StringName)
## Clic en el audio del mensaje.
signal audio_clicked(view: Node)
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
const INDENT := 48
```

por:

```gdscript
const INDENT := 48
## El enlace del audio, que no se confunde con el id de una frase clickeable.
const AUDIO_META := "__audio"
const AUDIO_COLOR := "40c2c9"
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
var speaker_color := Color.WHITE
```

por:

```gdscript
var speaker_color := Color.WHITE
## Se muestra qué se oye en el audio: la opción "Subtítulos de los audios".
var show_caption := false
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
func _init(chat_message: ChatMessage, speaker_name := "", color := Color.WHITE) -> void:
```

por:

```gdscript
func _init(chat_message: ChatMessage, speaker_name := "", color := Color.WHITE, caption := false) -> void:
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
	speaker_color = color
```

por:

```gdscript
	speaker_color = color
	show_caption = caption
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
	var text := token.text.replace("[", "[lb]")
```

por:

```gdscript
	var text := token.text.replace("[", "[lb]")
	if token.is_audio:
		return _audio_bbcode(text)
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript


## Cuántas letras ocupa "LEÓN: ", que se ven antes de que empiece a escribir.
```

por:

```gdscript


## El audio se escucha con un clic, hasta que termina su solicitud. Con la opción, se lee qué se oye.
func _audio_bbcode(text: String) -> String:
	var bbcode := _colored(text, AUDIO_COLOR)
	if message.request == null or not message.request.finished:
		bbcode = "[url=%s]%s[/url]" % [AUDIO_META, bbcode]
	if show_caption:
		bbcode += " (%s)" % message.audio_caption.replace("[", "[lb]")
	return bbcode


## Cuántas letras ocupa "LEÓN: ", que se ven antes de que empiece a escribir.
```

En `scripts/ui/chat_message_view.gd`, reemplazar:

```gdscript
	clue_clicked.emit(self, StringName(str(meta)))
```

por:

```gdscript
	if str(meta) == AUDIO_META:
		audio_clicked.emit(self)
	else:
		clue_clicked.emit(self, StringName(str(meta)))
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
```

por:

```gdscript
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
## Los audios que mandan los amigos suenan aquí, con un clic en el mensaje (decisión de Benja, 7 de noviembre), y
## al cerrar el chat se cortan.
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
var selected_friend := 0
```

por:

```gdscript
var selected_friend := 0
## La opción "Subtítulos de los audios": vale para los mensajes que llegan desde ahora.
var audio_captions := false
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
@onready var _script_reply: Button = $Panel/ScriptReply
```

por:

```gdscript
@onready var _script_reply: Button = $Panel/ScriptReply
@onready var _audio_clip: AudioStreamPlayer = $AudioClip
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	visibility_changed.connect(_set_holding_download.bind(false))
```

por:

```gdscript
	visibility_changed.connect(_set_holding_download.bind(false))
	visibility_changed.connect(_audio_clip.stop)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	show()
```

por:

```gdscript
	show()


## Suena un audio de un amigo. Mientras tanto no empiezan screamers ni alucinaciones, que se confundirían con él.
func is_audio_playing() -> bool:
	return _audio_clip.playing
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	var view := ChatMessageView.new(message, speaker, color)
	view.clue_clicked.connect(_on_clue_clicked)
```

por:

```gdscript
	var view := ChatMessageView.new(message, speaker, color, audio_captions)
	view.clue_clicked.connect(_on_clue_clicked)
	view.audio_clicked.connect(_on_audio_clicked)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
		_unread[friend_index] = true
```

por:

```gdscript
		_unread[friend_index] = true


func _on_audio_clicked(view: ChatMessageView) -> void:
	_audio_clip.stream = view.message.audio
	_audio_clip.play()
```

En `scripts/ui/options_panel.gd`, reemplazar:

```gdscript
	"Timers": "OPTIONS_SLOW_TIMERS",
```

por:

```gdscript
	"Timers": "OPTIONS_SLOW_TIMERS",
	"Captions": "OPTIONS_AUDIO_CAPTIONS",
```

En `scripts/ui/options_panel.gd`, reemplazar:

```gdscript
@onready var _timers: CheckBox = $Center/Box/Timers
```

por:

```gdscript
@onready var _timers: CheckBox = $Center/Box/Timers
@onready var _captions: CheckBox = $Center/Box/Captions
```

En `scripts/ui/options_panel.gd`, reemplazar:

```gdscript
	for check_name: String in ["Flashes", "Camera", "Timers"]:
```

por:

```gdscript
	for check_name: String in ["Flashes", "Camera", "Timers", "Captions"]:
```

En `scripts/ui/options_panel.gd`, reemplazar:

```gdscript
	_timers.button_pressed = game_settings.slow_timers
```

por:

```gdscript
	_timers.button_pressed = game_settings.slow_timers
	_captions.button_pressed = game_settings.audio_captions
```

En `scripts/ui/options_panel.gd`, reemplazar:

```gdscript
			settings.slow_timers = on
```

por:

```gdscript
			settings.slow_timers = on
		"Captions":
			settings.audio_captions = on
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `483 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "El amigo puede mandar un audio en lugar de contar una observación"
```

---

### Tarea 5: Los audios de las 7 entidades

**Archivos:**

- Crear: `audio/clues/*.wav` (15, generados)
- Modificar: `tools/make_placeholder_sounds.py`, `data/entities/*.tres`, `data/nights/night_0.tres`, `data/text/messages.csv`, `data/text/notebook.csv`, `test/test_catalog.gd`, `test/test_placeholder_sounds.gd`, `test/test_trauco.gd`

Cada entidad tiene una observación con audio, y lo que se oye cambia la acción correcta (`test_cada_entidad_tiene_un_audio_que_cambia_la_accion` lo revisa con el contenido real):

| Entidad | Observación | Valores | Lo que decide |
| --- | --- | --- | --- |
| El Tue Tué | `cries` (nueva, reemplaza a `cried_three_times`) | `one`, `three`, `none` | 3 gritos: quedarse callado. 1 grito sobre una casa: tijeras. Ninguno: sal. 1 grito de paso: imitarlo. |
| La Calchona | `bleat_tone` | `weeping`, `snorting` | Sus reglas ya dependían de esto. |
| El Cuero | `whistle` | `yes`, `no` | Pasa a ser la primera regla. |
| La Viuda | `heels` (nueva) | `slow`, `fast` | Tacos rápidos: rezar, antes que nada. |
| El Trauco | `ground` (ahora se oye) | `muddy`, `dry` | Pasos en el barro: seguirlo, antes que nada. |
| El Basilisco | `crows` (nueva) | `once`, `twice` | El gallo canta 2 veces: salir de la casa, antes que nada. |
| El Imbunche | `called_name` | `yes`, `no` | Su regla ya dependía de esto. |

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_catalog.gd`, reemplazar:

```gdscript
const ContentValidator := preload("res://scripts/core/content_validator.gd")
```

por:

```gdscript
const ContentValidator := preload("res://scripts/core/content_validator.gd")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")
```

En `test/test_catalog.gd`, reemplazar:

```gdscript
	return null

```

por:

```gdscript
	return null


## Cada entidad tiene una observación que el amigo manda como audio, y lo que se oye cambia la acción correcta: 1
## grito no es lo mismo que 3 (decisión de Benja, 7 de noviembre).
func test_cada_entidad_tiene_un_audio_que_cambia_la_accion() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	for entity: EntityData in catalog.all_entities():
		var with_audio := entity.observations.filter(func(observation: ObservationData) -> bool:
			return not observation.audio_values.is_empty())
		check_eq(with_audio.size(), 1, "'%s' tiene una observación con audio" % entity.id)
		if with_audio.size() == 1:
			check(_audio_changes_the_action(entity, with_audio[0]), "en '%s', el audio no cambia nada" % entity.id)
	return true


## Hay dos situaciones que solo difieren en `observation` y que piden acciones distintas.
func _audio_changes_the_action(entity: EntityData, observation: ObservationData) -> bool:
	for situation: Dictionary in RuleEvaluator.all_situations(entity):
		var correct := RuleEvaluator.applicable_rule(entity, situation).correct_action_id
		for value: StringName in observation.value_ids():
			var other := situation.duplicate()
			other[observation.id] = value
			if RuleEvaluator.applicable_rule(entity, other).correct_action_id != correct:
				return true
	return false

```

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
## Los sonidos provisionales de los planes 6 y 7 (tools/make_placeholder_sounds.py), hasta los definitivos del
## Plan 9.
```

por:

```gdscript
## Los sonidos provisionales (tools/make_placeholder_sounds.py), hasta los definitivos del Plan 10.
```

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
}


```

por:

```gdscript
}

## Los audios que mandan los amigos, en audio/clues/ (decisión de Benja, 7 de noviembre). Duran 3 s.
const CLUE_SOUNDS: Array[String] = [
	"tue_tue_cries_one", "tue_tue_cries_three", "tue_tue_cries_none",
	"calchona_bleat_tone_weeping", "calchona_bleat_tone_snorting",
	"cuero_whistle_yes", "cuero_whistle_no",
	"viuda_heels_slow", "viuda_heels_fast",
	"trauco_ground_muddy", "trauco_ground_dry",
	"basilisco_crows_once", "basilisco_crows_twice",
	"imbunche_called_name_yes", "imbunche_called_name_no",
]
const CLUE_SECONDS := 3.0


func test_los_audios_de_los_amigos_se_cargan() -> bool:
	for sound_name: String in CLUE_SOUNDS:
		var stream: AudioStream = load("res://audio/clues/%s.wav" % sound_name)
		check(stream is AudioStreamWAV, "se carga " + sound_name)
		if stream != null:
			check(absf(stream.get_length() - CLUE_SECONDS) < 0.01, "%s dura %s s" % [sound_name, stream.get_length()])
	return true


```

En `test/test_trauco.gd`, reemplazar:

```gdscript
## Las reglas de la propuesta de docs/09: si el Trauco lo vio primero, mirar al suelo; con el bastón, hablar fuerte;
## en el barro, seguirlo (el giro); y si no, tirarle arena.
```

por:

```gdscript
## Las reglas: si sus pasos chapotean (se oye en el audio), seguirlo; si el Trauco lo vio primero, mirar al suelo; con
## el bastón, hablar fuerte; y si no, tirarle arena.
```

En `test/test_trauco.gd`, reemplazar:

```gdscript
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"muddy"},
```

por:

```gdscript
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"muddy"},
			&"follow_to_tree", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"trauco", &"in_hand": &"cane", &"ground": &"dry"},
```

En `test/test_trauco.gd`, reemplazar:

```gdscript
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"cane", &"ground": &"muddy"},
			&"talk_loud", &"throw_sand")
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"axe", &"ground": &"muddy"},
			&"follow_to_tree", &"throw_sand")
```

por:

```gdscript
	_check_rule(entity, {&"saw_first": &"friend", &"in_hand": &"cane", &"ground": &"dry"},
			&"talk_loud", &"throw_sand")
```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `482 pruebas OK, 3 fallidas`.

- [ ] **Paso 3: Agregar los sonidos, las reglas y los textos**

En `data/entities/basilisco.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/basilisco_crows_once.wav" id="audio_once"]
[ext_resource type="AudioStream" path="res://audio/clues/basilisco_crows_twice.wav" id="audio_twice"]
```

En `data/entities/basilisco.tres`, reemplazar:

```text

[sub_resource type="Resource" id="Rule_1"]
```

por:

```text

[sub_resource type="Resource" id="Observation_crows"]
script = ExtResource("4_observation")
id = &"crows"
category = 1
question_key = "OBS_BASILISCO_CROWS_Q"
values = Dictionary[StringName, String]({
&"once": "OBS_BASILISCO_CROWS_ONCE",
&"twice": "OBS_BASILISCO_CROWS_TWICE"
})
audio_values = Dictionary[StringName, AudioStream]({
&"once": ExtResource("audio_once"),
&"twice": ExtResource("audio_twice")
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"crows": &"twice"
})
correct_action_id = &"leave_house"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_1"

[sub_resource type="Resource" id="Rule_2"]
```

En `data/entities/basilisco.tres`, reemplazar:

```text
correct_action_id = &"burn_egg"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_1"

[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
```

por:

```text
correct_action_id = &"burn_egg"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_2"

[sub_resource type="Resource" id="Rule_3"]
script = ExtResource("5_rule")
```

En `data/entities/basilisco.tres`, reemplazar:

```text
correct_action_id = &"leave_house"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_2"

[sub_resource type="Resource" id="Rule_otherwise"]
```

por:

```text
correct_action_id = &"leave_house"
risky_action_id = &"lift_board"
text_key = "RULE_BASILISCO_3"

[sub_resource type="Resource" id="Rule_otherwise"]
```

En `data/entities/basilisco.tres`, reemplazar:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_egg"), SubResource("Observation_floor")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

por:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_egg"), SubResource("Observation_floor"), SubResource("Observation_crows")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_3"), SubResource("Rule_otherwise")])
```

En `data/entities/calchona.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/calchona_bleat_tone_weeping.wav" id="audio_weeping"]
[ext_resource type="AudioStream" path="res://audio/clues/calchona_bleat_tone_snorting.wav" id="audio_snorting"]
```

En `data/entities/calchona.tres`, reemplazar:

```text
&"snorting": "OBS_CALCHONA_BLEAT_TONE_SNORTING"
})

```

por:

```text
&"snorting": "OBS_CALCHONA_BLEAT_TONE_SNORTING"
})
audio_values = Dictionary[StringName, AudioStream]({
&"weeping": ExtResource("audio_weeping"),
&"snorting": ExtResource("audio_snorting")
})

```

En `data/entities/cuero.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/cuero_whistle_yes.wav" id="audio_yes"]
[ext_resource type="AudioStream" path="res://audio/clues/cuero_whistle_no.wav" id="audio_no"]
```

En `data/entities/cuero.tres`, reemplazar:

```text
&"no": "OBS_CUERO_WHISTLE_NO"
})

```

por:

```text
&"no": "OBS_CUERO_WHISTLE_NO"
})
audio_values = Dictionary[StringName, AudioStream]({
&"yes": ExtResource("audio_yes"),
&"no": ExtResource("audio_no")
})

```

En `data/entities/cuero.tres`, reemplazar:

```text
&"position": &"on_shore"
```

por:

```text
&"whistle": &"yes"
```

En `data/entities/cuero.tres`, reemplazar:

```text
correct_action_id = &"throw_thorns"
```

por:

```text
correct_action_id = &"stay_still"
```

En `data/entities/cuero.tres`, reemplazar:

```text
[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"whistle": &"yes"
})
correct_action_id = &"stay_still"
risky_action_id = &"poke_hide"
text_key = "RULE_CUERO_2"
```

por:

```text
[sub_resource type="Resource" id="Rule_2"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"position": &"on_shore"
})
correct_action_id = &"throw_thorns"
risky_action_id = &"poke_hide"
text_key = "RULE_CUERO_2"
```

En `data/entities/imbunche.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/imbunche_called_name_yes.wav" id="audio_yes"]
[ext_resource type="AudioStream" path="res://audio/clues/imbunche_called_name_no.wav" id="audio_no"]
```

En `data/entities/imbunche.tres`, reemplazar:

```text
&"no": "OBS_IMBUNCHE_CALLED_NAME_NO"
```

por:

```text
&"no": "OBS_IMBUNCHE_CALLED_NAME_NO"
})
audio_values = Dictionary[StringName, AudioStream]({
&"yes": ExtResource("audio_yes"),
&"no": ExtResource("audio_no")
```

En `data/entities/trauco.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/trauco_ground_muddy.wav" id="audio_muddy"]
[ext_resource type="AudioStream" path="res://audio/clues/trauco_ground_dry.wav" id="audio_dry"]
```

En `data/entities/trauco.tres`, reemplazar:

```text
id = &"ground"
category = 3
question_key = "OBS_TRAUCO_GROUND_Q"
```

por:

```text
id = &"ground"
category = 1
question_key = "OBS_TRAUCO_GROUND_Q"
```

En `data/entities/trauco.tres`, reemplazar:

```text
&"dry": "OBS_TRAUCO_GROUND_DRY"
})

[sub_resource type="Resource" id="Rule_1"]
```

por:

```text
&"dry": "OBS_TRAUCO_GROUND_DRY"
})
audio_values = Dictionary[StringName, AudioStream]({
&"muddy": ExtResource("audio_muddy"),
&"dry": ExtResource("audio_dry")
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"ground": &"muddy"
})
correct_action_id = &"follow_to_tree"
risky_action_id = &"throw_sand"
text_key = "RULE_TRAUCO_1"

[sub_resource type="Resource" id="Rule_2"]
```

En `data/entities/trauco.tres`, reemplazar:

```text
risky_action_id = &"follow_to_tree"
text_key = "RULE_TRAUCO_1"

[sub_resource type="Resource" id="Rule_2"]
```

por:

```text
risky_action_id = &"follow_to_tree"
text_key = "RULE_TRAUCO_2"

[sub_resource type="Resource" id="Rule_3"]
```

En `data/entities/trauco.tres`, reemplazar:

```text
correct_action_id = &"talk_loud"
risky_action_id = &"throw_sand"
text_key = "RULE_TRAUCO_2"

[sub_resource type="Resource" id="Rule_3"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"ground": &"muddy"
})
correct_action_id = &"follow_to_tree"
```

por:

```text
correct_action_id = &"talk_loud"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/tue_tue_cries_one.wav" id="audio_one"]
[ext_resource type="AudioStream" path="res://audio/clues/tue_tue_cries_three.wav" id="audio_three"]
[ext_resource type="AudioStream" path="res://audio/clues/tue_tue_cries_none.wav" id="audio_none"]
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
[sub_resource type="Resource" id="Observation_cried_three_times"]
```

por:

```text
[sub_resource type="Resource" id="Observation_cries"]
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
id = &"cried_three_times"
```

por:

```text
id = &"cries"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
question_key = "OBS_TUE_TUE_CRIED_THREE_TIMES_Q"
```

por:

```text
question_key = "OBS_TUE_TUE_CRIES_Q"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
&"yes": "OBS_TUE_TUE_CRIED_THREE_TIMES_YES",
&"no": "OBS_TUE_TUE_CRIED_THREE_TIMES_NO"
```

por:

```text
&"one": "OBS_TUE_TUE_CRIES_ONE",
&"three": "OBS_TUE_TUE_CRIES_THREE",
&"none": "OBS_TUE_TUE_CRIES_NONE"
})
audio_values = Dictionary[StringName, AudioStream]({
&"one": ExtResource("audio_one"),
&"three": ExtResource("audio_three"),
&"none": ExtResource("audio_none")
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
&"circling": &"over_house"
```

por:

```text
&"cries": &"three"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
correct_action_id = &"cross_scissors"
risky_action_id = &"mimic_cry"
```

por:

```text
correct_action_id = &"stay_silent"
risky_action_id = &"offer_salt"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
&"cried_three_times": &"yes"
```

por:

```text
&"cries": &"one",
&"circling": &"over_house"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
correct_action_id = &"stay_silent"
risky_action_id = &"offer_salt"
text_key = "RULE_TUE_TUE_2"
```

por:

```text
correct_action_id = &"cross_scissors"
risky_action_id = &"mimic_cry"
text_key = "RULE_TUE_TUE_2"

[sub_resource type="Resource" id="Rule_3"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"cries": &"none"
})
correct_action_id = &"offer_salt"
risky_action_id = &"mimic_cry"
text_key = "RULE_TUE_TUE_3"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
script = ExtResource("5_rule")
correct_action_id = &"offer_salt"
risky_action_id = &"mimic_cry"
text_key = "RULE_OTHERWISE"
```

por:

```text
script = ExtResource("5_rule")
correct_action_id = &"mimic_cry"
risky_action_id = &"cross_scissors"
text_key = "RULE_OTHERWISE"
```

En `data/entities/tue_tue.tres`, reemplazar:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_circling"), SubResource("Observation_cried_three_times")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

por:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_circling"), SubResource("Observation_cries")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_3"), SubResource("Rule_otherwise")])
```

En `data/entities/viuda.tres`, reemplazar:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
```

por:

```text
[ext_resource type="Script" path="res://scripts/data/rule_data.gd" id="5_rule"]
[ext_resource type="AudioStream" path="res://audio/clues/viuda_heels_slow.wav" id="audio_slow"]
[ext_resource type="AudioStream" path="res://audio/clues/viuda_heels_fast.wav" id="audio_fast"]
```

En `data/entities/viuda.tres`, reemplazar:

```text

[sub_resource type="Resource" id="Rule_1"]
```

por:

```text

[sub_resource type="Resource" id="Observation_heels"]
script = ExtResource("4_observation")
id = &"heels"
category = 1
question_key = "OBS_VIUDA_HEELS_Q"
values = Dictionary[StringName, String]({
&"slow": "OBS_VIUDA_HEELS_SLOW",
&"fast": "OBS_VIUDA_HEELS_FAST"
})
audio_values = Dictionary[StringName, AudioStream]({
&"slow": ExtResource("audio_slow"),
&"fast": ExtResource("audio_fast")
})

[sub_resource type="Resource" id="Rule_1"]
script = ExtResource("5_rule")
conditions = Dictionary[StringName, StringName]({
&"heels": &"fast"
})
correct_action_id = &"pray"
risky_action_id = &"greet"
text_key = "RULE_VIUDA_1"

[sub_resource type="Resource" id="Rule_2"]
```

En `data/entities/viuda.tres`, reemplazar:

```text
risky_action_id = &"carry_her"
text_key = "RULE_VIUDA_1"

[sub_resource type="Resource" id="Rule_2"]
```

por:

```text
risky_action_id = &"carry_her"
text_key = "RULE_VIUDA_2"

[sub_resource type="Resource" id="Rule_3"]
```

En `data/entities/viuda.tres`, reemplazar:

```text
})
correct_action_id = &"pray"
risky_action_id = &"greet"
text_key = "RULE_VIUDA_2"
```

por:

```text
})
correct_action_id = &"keep_walking"
risky_action_id = &"greet"
text_key = "RULE_VIUDA_3"
```

En `data/entities/viuda.tres`, reemplazar:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_request"), SubResource("Observation_footprints")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_otherwise")])
```

por:

```text
observations = Array[ExtResource("4_observation")]([SubResource("Observation_request"), SubResource("Observation_footprints"), SubResource("Observation_heels")])
rules = Array[ExtResource("5_rule")]([SubResource("Rule_1"), SubResource("Rule_2"), SubResource("Rule_3"), SubResource("Rule_otherwise")])
```

En `data/nights/night_0.tres`, reemplazar:

```text
&"cried_three_times": &"no"
```

por:

```text
&"cries": &"one"
```

En `data/nights/night_0.tres`, reemplazar:

```text
&"cried_three_times": &"yes"
```

por:

```text
&"cries": &"three"
```

En `data/text/messages.csv`, reemplazar:

```csv
OBS_TUE_TUE_CRIED_THREE_TIMES_YES,Gritó tres veces seguidas.,
OBS_TUE_TUE_CRIED_THREE_TIMES_NO,Gritó una vez y se calló.,
```

por:

```csv
OBS_TUE_TUE_CRIES_ONE,Gritó una vez y se calló.,
OBS_TUE_TUE_CRIES_THREE,Gritó tres veces seguidas.,
OBS_TUE_TUE_CRIES_NONE,No se oye ningún grito.,
```

En `data/text/messages.csv`, reemplazar:

```csv
OBS_VIUDA_FOOTPRINTS_NORMAL,Deja huellas como cualquier persona.,
```

por:

```csv
OBS_VIUDA_FOOTPRINTS_NORMAL,Deja huellas como cualquier persona.,
OBS_VIUDA_HEELS_SLOW,Sus tacos suenan lentos.,
OBS_VIUDA_HEELS_FAST,Sus tacos suenan rápido.,
```

En `data/text/messages.csv`, reemplazar:

```csv
OBS_TRAUCO_GROUND_MUDDY,El suelo está todo embarrado.,
OBS_TRAUCO_GROUND_DRY,El suelo está seco.,
```

por:

```csv
OBS_TRAUCO_GROUND_MUDDY,Sus pasos chapotean en el barro.,
OBS_TRAUCO_GROUND_DRY,Sus pasos crujen en la tierra seca.,
```

En `data/text/messages.csv`, reemplazar:

```csv
OBS_BASILISCO_FLOOR_INTACT,El piso está entero.,
```

por:

```csv
OBS_BASILISCO_FLOOR_INTACT,El piso está entero.,
OBS_BASILISCO_CROWS_ONCE,El gallo cantó una vez.,
OBS_BASILISCO_CROWS_TWICE,El gallo cantó dos veces.,
```

En `data/text/notebook.csv`, reemplazar:

```csv
OBS_TUE_TUE_CRIED_THREE_TIMES_Q,¿Gritó tres veces seguidas?,
RULE_TUE_TUE_1,Si da vueltas sobre una casa,
RULE_TUE_TUE_2,Si gritó tres veces seguidas,
```

por:

```csv
OBS_TUE_TUE_CRIES_Q,¿Cuántas veces grita?,
RULE_TUE_TUE_1,Si gritó tres veces,
RULE_TUE_TUE_2,Si gritó una vez y da vueltas sobre una casa,
RULE_TUE_TUE_3,Si no se oye ningún grito,
```

En `data/text/notebook.csv`, reemplazar:

```csv
RULE_CUERO_1,Si está en la orilla,
RULE_CUERO_2,Si se oye un silbido,
```

por:

```csv
RULE_CUERO_1,Si se oye un silbido,
RULE_CUERO_2,Si está en la orilla,
```

En `data/text/notebook.csv`, reemplazar:

```csv
RULE_VIUDA_1,Si pidió ayuda para cruzar,
RULE_VIUDA_2,Si no deja huellas,
```

por:

```csv
OBS_VIUDA_HEELS_Q,¿Cómo suenan sus tacos?,
RULE_VIUDA_1,Si sus tacos suenan rápido,
RULE_VIUDA_2,Si pidió ayuda para cruzar,
RULE_VIUDA_3,Si no deja huellas,
```

En `data/text/notebook.csv`, reemplazar:

```csv
OBS_TRAUCO_GROUND_Q,¿Cómo está el suelo?,
RULE_TRAUCO_1,Si el Trauco lo vio primero,
RULE_TRAUCO_2,Si lleva el bastón,
RULE_TRAUCO_3,Si el suelo está embarrado,
```

por:

```csv
OBS_TRAUCO_GROUND_Q,¿Cómo suenan sus pasos?,
RULE_TRAUCO_1,Si sus pasos chapotean,
RULE_TRAUCO_2,Si el Trauco lo vio primero,
RULE_TRAUCO_3,Si lleva el bastón,
```

En `data/text/notebook.csv`, reemplazar:

```csv
RULE_BASILISCO_1,Si hay un huevo chico y arrugado,
RULE_BASILISCO_2,Si hay una tabla levantada,
```

por:

```csv
OBS_BASILISCO_CROWS_Q,¿Cuántas veces canta el gallo?,
RULE_BASILISCO_1,Si el gallo canta dos veces,
RULE_BASILISCO_2,Si hay un huevo chico y arrugado,
RULE_BASILISCO_3,Si hay una tabla levantada,
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
- 4 de noviembre: la respiración y los golpes de la criatura de la ventana, que reemplazan al grito del jumpscare.
```

por:

```python
- 4 de noviembre: la respiración y los golpes de la criatura de la ventana, que reemplazan al grito del jumpscare;
- Plan 9: los audios que mandan los amigos, en audio/clues/ (3 s cada uno, con el lugar de fondo).
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"
```

por:

```python
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"
CLUES = OUT.parent / "clues"
CLUE_SECONDS = 3.0
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
```

por:

```python
def write(name, samples, folder=OUT):
    folder.mkdir(parents=True, exist_ok=True)
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    with wave.open(str(OUT / (name + ".wav")), "wb") as out:
```

por:

```python
    with wave.open(str(folder / (name + ".wav")), "wb") as out:
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python


if __name__ == "__main__":
```

por:

```python


def outdoors(seed):
    """El fondo de un audio de un amigo: 3 s de viento suave."""
    white, samples, low = noise(seed), [], 0.0
    for i in range(int(CLUE_SECONDS * RATE)):
        t = i / RATE
        low += 0.03 * (white() - low)
        samples.append(0.5 * low * min(t / 0.1, 1.0, (CLUE_SECONDS - t) / 0.1))
    return samples


def water(seed):
    """El fondo de un audio junto al lago: 3 s de agua que golpea la orilla."""
    white, samples, low = noise(seed), [], 0.0
    for i in range(int(CLUE_SECONDS * RATE)):
        t = i / RATE
        low += 0.08 * (white() - low)
        wave_level = 0.35 + 0.65 * math.sin(2 * math.pi * 0.7 * t) ** 2
        samples.append(0.5 * low * wave_level * min(t / 0.1, 1.0, (CLUE_SECONDS - t) / 0.1))
    return samples


def over(background, sound, starts):
    """Mezcla `sound` sobre `background`, una vez por cada segundo de `starts`."""
    mixed = list(background)
    for start in starts:
        first = int(start * RATE)
        for i, value in enumerate(sound):
            if first + i < len(mixed):
                mixed[first + i] += value
    return mixed


def cry():
    """El Tue Tué: un grito de dos notas, como de queltehue."""
    samples = []
    for frequency in (1900, 1400):
        for i in range(int(0.22 * RATE)):
            t = i / RATE
            samples.append(0.5 * math.sin(2 * math.pi * frequency * t) * min(t / 0.01, 1.0) * math.exp(-t * 6))
    return samples


def bleat():
    """La Calchona bala como llorando: un tono que tiembla y cae."""
    samples, phase, seconds = [], 0.0, 1.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (340 - 90 * t / seconds + 22 * math.sin(2 * math.pi * 7 * t)) / RATE
        tone = math.sin(phase) + 0.5 * math.sin(2 * phase) + 0.3 * math.sin(3 * phase)
        samples.append(0.3 * tone * min(t / 0.05, 1.0, (seconds - t) / 0.2))
    return samples


def snort():
    """La Calchona bufa: un soplido grave y corto."""
    white, samples, low, seconds = noise(41), [], 0.0, 0.45
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.2 * (white() - low)
        samples.append(1.6 * low * min(t / 0.02, 1.0) * math.exp(-t * 6))
    return samples


def whistle():
    """El Cuero: un silbido agudo que sube, como si alguien llamara."""
    samples, phase, seconds = [], 0.0, 1.2
    for i in range(int(seconds * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (1500 + 800 * t / seconds) / RATE
        samples.append(0.35 * math.sin(phase) * min(t / 0.08, 1.0, (seconds - t) / 0.15))
    return samples


def heel():
    """La Viuda: un paso de taco, seco y agudo."""
    samples = []
    for i in range(int(0.1 * RATE)):
        t = i / RATE
        samples.append(0.6 * (math.sin(2 * math.pi * 1800 * t) + 0.6 * math.sin(2 * math.pi * 420 * t)) * math.exp(-t * 70))
    return samples


def squelch():
    """El Trauco en el barro: un paso húmedo y grave."""
    white, samples, low, seconds = noise(42), [], 0.0, 0.35
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.1 * (white() - low)
        wobble = 0.6 + 0.4 * math.sin(2 * math.pi * 26 * t)
        samples.append(2.6 * low * wobble * math.exp(-t * 9))
    return samples


def crunch():
    """El Trauco en tierra seca: un paso áspero y corto."""
    white, samples, last_x, last_y, seconds = noise(43), [], 0.0, 0.0, 0.18
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.85 * (last_y + x - last_x), x
        samples.append(0.7 * last_y * math.exp(-t * 22))
    return samples


def crow():
    """El Basilisco: un canto de gallo apagado, que sube y cae."""
    samples, phase, seconds = [], 0.0, 0.9
    for i in range(int(seconds * RATE)):
        t = i / RATE
        progress = t / seconds
        phase += 2 * math.pi * (600 + 520 * math.sin(math.pi * progress) ** 2) / RATE
        tone = math.sin(phase) + 0.6 * math.sin(2 * phase) + 0.4 * math.sin(3 * phase)
        samples.append(0.25 * tone * min(t / 0.05, 1.0, (seconds - t) / 0.15))
    return samples


def grunt():
    """El Imbunche: un gruñido ronco."""
    samples, seconds = [], 0.4
    for i in range(int(seconds * RATE)):
        t = i / RATE
        tone = sum(math.sin(2 * math.pi * 85 * harmonic * t) / harmonic for harmonic in (1, 2, 3, 4, 5))
        rasp = 0.6 + 0.4 * math.sin(2 * math.pi * 31 * t)
        samples.append(0.3 * tone * rasp * min(t / 0.03, 1.0, (seconds - t) / 0.1))
    return samples


def name_call():
    """El Imbunche dice el nombre: tres sílabas de una voz ronca, "Ma-tí-as"."""
    samples, seconds = [], 0.9
    for i in range(int(seconds * RATE)):
        t = i / RATE
        syllable = max(math.sin(2 * math.pi * 3.3 * t), 0.0)
        pitch = 150 + 40 * math.sin(2 * math.pi * 1.1 * t)
        tone = sum(math.sin(2 * math.pi * pitch * harmonic * t) / harmonic for harmonic in (1, 2, 3, 5, 7))
        samples.append(0.35 * tone * syllable)
    return samples


def clue_sounds():
    """Los audios que mandan los amigos: {nombre del archivo: muestras}."""
    steps_at = (0.3, 0.9, 1.5, 2.1)
    grunts_at = (0.2, 0.8, 2.2)
    return {
        "tue_tue_cries_one": over(outdoors(51), cry(), (1.0,)),
        "tue_tue_cries_three": over(outdoors(51), cry(), (0.3, 1.2, 2.1)),
        "tue_tue_cries_none": outdoors(51),
        "calchona_bleat_tone_weeping": over(outdoors(52), bleat(), (0.3, 1.7)),
        "calchona_bleat_tone_snorting": over(outdoors(52), snort(), (0.4, 1.3, 2.2)),
        "cuero_whistle_yes": over(water(53), whistle(), (0.8,)),
        "cuero_whistle_no": water(53),
        "viuda_heels_slow": over(outdoors(54), heel(), (0.3, 1.1, 1.9, 2.7)),
        "viuda_heels_fast": over(outdoors(54), heel(), tuple(0.2 + 0.28 * step for step in range(10))),
        "trauco_ground_muddy": over(outdoors(55), squelch(), steps_at),
        "trauco_ground_dry": over(outdoors(55), crunch(), steps_at),
        "basilisco_crows_once": over(outdoors(56), crow(), (1.0,)),
        "basilisco_crows_twice": over(outdoors(56), crow(), (0.4, 1.7)),
        "imbunche_called_name_yes": over(over(outdoors(57), grunt(), grunts_at), name_call(), (1.25,)),
        "imbunche_called_name_no": over(outdoors(57), grunt(), grunts_at),
    }


if __name__ == "__main__":
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    print("Sonidos provisionales en", OUT)
```

por:

```python
    for clue_name, clue_samples in clue_sounds().items():
        write(clue_name, clue_samples, CLUES)
    print("Sonidos provisionales en", OUT, "y", CLUES)
```

- [ ] **Paso 4: Generar los audios**

```bash
python3 -I tools/make_placeholder_sounds.py
```

Esperado: `Sonidos provisionales en ...` y 15 archivos en `audio/clues/`. El script vuelve a escribir `audio/sfx/` con los mismos sonidos. Si Benja ya puso sonidos reales ahí, hay que restaurarlos con `git checkout -- audio/sfx`.

- [ ] **Paso 5: Verificar que pasan**

Esperado: `485 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add -A
git commit -m "Las 7 entidades mandan audios, y lo que se oye cambia la acción"
```

---

### Tarea 6: La batería del celular

**Archivos:**

- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/core/night_state.gd`, `scripts/ui/phone_view.gd`, `data/text/phone.csv`, `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `test/test_balance.gd`, `test/test_night_state.gd`, `test/test_phone_view.gd`, `test/test_desk_scene.gd`

`NightState` se crea en cada noche, así que la batería vuelve a 100 sola al empezar la siguiente.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
	check_eq(balance.scroll_grace, 0.3, "cada movimiento de la rueda cuenta 0,3 s")
```

por:

```gdscript
	check_eq(balance.scroll_grace, 0.3, "cada movimiento de la rueda cuenta 0,3 s")
	check_eq(balance.phone_battery_seconds, 38.0, "la batería alcanza para 38 s de scroll")
```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
		check_eq((desk.get_node(path) as Node2D).position, POSITIONS[path], path)
```

por:

```gdscript
		check_eq((desk.get_node(path) as Node2D).position, POSITIONS[path], path)
	desk.free()
	return true


## La batería también se ve en el celular del escritorio: su barra se acorta (decisión de Benja, 7 de noviembre).
func test_la_barra_de_bateria_del_celular() -> bool:
	var desk := _make_desk()
	var bar := desk.get_node("DeskPlane/Phone/BatteryBar") as ColorRect
	var full := bar.size.x
	desk.get_node("RequestManager").state.battery = 50.0
	desk._process(0.0)
	check_eq(bar.size.x, roundf(full / 2.0), "a la mitad")
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	check_eq(state.trust, 96.0, "después de 20 s sin bajar, vuelve a subir")
	return true

```

por:

```gdscript
	check_eq(state.trust, 96.0, "después de 20 s sin bajar, vuelve a subir")
	return true


## Scrollea `seconds` segundos: mantiene la rueda en movimiento, de a 0,1 s.
func _scroll_for(state: NightState, seconds: float) -> void:
	for _step in roundi(seconds * 10.0):
		state.scroll()
		state.advance(0.1)


## La batería del celular es un tope por noche, sin recarga (decisión de Benja, 7 de noviembre).
func test_la_bateria_se_gasta_solo_al_scrollear() -> bool:
	var state := _make_state()
	check_eq(state.battery, 100.0, "empieza llena")
	state.advance(30.0)
	check_eq(state.battery, 100.0, "sin scrollear no se gasta")
	_scroll_for(state, 19.0)
	check(absf(state.battery - 50.0) < 1.0, "19 de 38 s: la mitad: %s" % state.battery)
	state.advance(30.0)
	check(absf(state.battery - 50.0) < 1.0, "no se recarga: %s" % state.battery)
	return true


func test_sin_bateria_sanity_no_sube() -> bool:
	var state := _make_state()
	_scroll_for(state, 40.0)
	check_eq(state.battery, 0.0, "se acabó")
	check(not state.has_battery(), "sin batería")
	state.sanity = 50.0
	_scroll_for(state, 5.0)
	check(state.sanity < 50.0, "scrollear ya no sirve: %s" % state.sanity)
	return true

```

En `test/test_phone_view.gd`, reemplazar:

```gdscript
	TranslationServer.set_locale(previous)
	return true

```

por:

```gdscript
	TranslationServer.set_locale(previous)
	return true


func test_sin_bateria_el_feed_no_avanza() -> bool:
	var phone := _make_phone()
	_state.battery = 0.0
	phone.scroll_by(120.0)
	for _frame in 60:
		phone._process(0.05)
	check_eq(phone.scroll, 0.0, "el feed no se mueve")
	phone.free()
	return true

```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `484 pruebas OK, 5 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/balance.tres`, reemplazar:

```text
scroll_grace = 0.3
```

por:

```text
scroll_grace = 0.3
phone_battery_seconds = 38.0
```

En `data/text/phone.csv`, reemplazar:

```csv
PHONE_POST_12_TEXT,Llueve hace cuatro días. Ya es parte de la familia.,
```

por:

```csv
PHONE_POST_12_TEXT,Llueve hace cuatro días. Ya es parte de la familia.,
PHONE_NO_BATTERY,Sin batería,
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
horizontal_alignment = 1
vertical_alignment = 1

```

por:

```text
horizontal_alignment = 1
vertical_alignment = 1

[node name="BatteryBar" type="ColorRect" parent="DeskPlane/Phone"]
offset_left = 29.0
offset_top = 20.0
offset_right = 73.0
offset_bottom = 22.0
mouse_filter = 2
color = Color(0.49, 0.88, 0.54, 1)

```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
var trust := METER_MAX
```

por:

```gdscript
var trust := METER_MAX
## La batería del celular (0–100). Se gasta solo mientras Matías scrollea y no se recarga (decisión de Benja, 7 de
## noviembre).
var battery := METER_MAX
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2).
```

por:

```gdscript
## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2). Sin batería, no pasa nada.
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	_scroll_left = balance.scroll_grace
```

por:

```gdscript
	if has_battery():
		_scroll_left = balance.scroll_grace


## Al celular le queda batería.
func has_battery() -> bool:
	return battery > 0.0
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
## Sanity baja con el tiempo y sube mientras Matías scrollea el celular.
```

por:

```gdscript
## Sanity baja con el tiempo y sube mientras Matías scrollea el celular, hasta que se acaba la batería.
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	var scrolling := minf(_scroll_left, delta)
	_scroll_left = maxf(_scroll_left - delta, 0.0)
```

por:

```gdscript
	var battery_left := battery / METER_MAX * balance.phone_battery_seconds
	var scrolling := minf(minf(_scroll_left, delta), battery_left)
	_scroll_left = maxf(_scroll_left - delta, 0.0)
	battery = maxf(battery - scrolling / balance.phone_battery_seconds * METER_MAX, 0.0)
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var scroll_grace := 0.3
```

por:

```gdscript
@export var scroll_grace := 0.3
## Segundos de scroll que dura la batería del celular, que vuelve a llenarse solo al empezar la noche (decisión de
## Benja, 7 de noviembre). 38 s a 4 de Sanity por segundo son una vez y media la barra.
@export var phone_battery_seconds := 38.0
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
const VIDEOS_KEY := "PC_VIDEOS"

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
```

por:

```gdscript
const VIDEOS_KEY := "PC_VIDEOS"

## El largo de la barra de batería del celular del escritorio, llena.
const BATTERY_BAR_WIDTH := 44.0

## Qué página del cuaderno tiene abierta cada amigo. La usan el cuaderno y los botones de respuesta del chat.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _clock: Label = $DeskPlane/Phone/Clock
```

por:

```gdscript
@onready var _clock: Label = $DeskPlane/Phone/Clock
@onready var _battery_bar: ColorRect = $DeskPlane/Phone/BatteryBar
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_clock.text = state.clock_text()
```

por:

```gdscript
	_clock.text = state.clock_text()
	_battery_bar.size.x = roundf(BATTERY_BAR_WIDTH * state.battery / NightState.METER_MAX)
```

En `scripts/ui/phone_view.gd`, reemplazar:

```gdscript
## el escritorio.
```

por:

```gdscript
## el escritorio. La batería alcanza para un rato por noche y, sin ella, no hay nada que mirar (decisión de Benja,
## 7 de noviembre).
```

En `scripts/ui/phone_view.gd`, reemplazar:

```gdscript
const APP_NAME_KEY := "PHONE_APP_NAME"
```

por:

```gdscript
const APP_NAME_KEY := "PHONE_APP_NAME"
## Lo que se ve sin batería (phone.csv).
const NO_BATTERY_KEY := "PHONE_NO_BATTERY"
## Bajo este porcentaje, la batería se ve en rojo.
const LOW_BATTERY := 20.0
```

En `scripts/ui/phone_view.gd`, reemplazar:

```gdscript
func scroll_by(amount: float) -> void:
```

por:

```gdscript
func scroll_by(amount: float) -> void:
	if not _state.has_battery():
		return
```

En `scripts/ui/phone_view.gd`, reemplazar:

```gdscript
	draw_rect(Rect2(216, 22, 20, 9), TEXT_COLOR, false)
	draw_rect(Rect2(218, 24, 12, 5), TEXT_COLOR)
	draw_rect(Rect2(236, 24, 2, 5), TEXT_COLOR)
```

por:

```gdscript
	_draw_battery()
```

En `scripts/ui/phone_view.gd`, reemplazar:

```gdscript
## Las publicaciones, una debajo de otra y repetidas sin fin, corridas según el scroll.
func _draw_feed() -> void:
```

por:

```gdscript
## La batería: el ícono, que se vacía, y su porcentaje. Con poca, en rojo.
func _draw_battery() -> void:
	var color := HEART_COLOR if _state.battery < LOW_BATTERY else TEXT_COLOR
	draw_rect(Rect2(216, 22, 20, 9), color, false)
	draw_rect(Rect2(218, 24, roundf(16.0 * _state.battery / 100.0), 5), color)
	draw_rect(Rect2(236, 24, 2, 5), color)
	_draw_text(self, "%d%%" % ceili(_state.battery), Vector2(162, 31), color)


## Las publicaciones, una debajo de otra y repetidas sin fin, corridas según el scroll. Sin batería, un aviso.
func _draw_feed() -> void:
	if not _state.has_battery():
		_feed.draw_rect(Rect2(Vector2.ZERO, _feed.size), GLASS_COLOR)
		var center := Vector2(0, _feed.size.y / 2.0)
		_feed.draw_string(FONT, center, tr(NO_BATTERY_KEY), HORIZONTAL_ALIGNMENT_CENTER, _feed.size.x, FONT_SIZE, DIM_COLOR)
		return
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `489 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "El celular tiene batería: un tope por noche"
```

---

### Tarea 7: Las cortinas

**Archivos:**

- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/core/night_state.gd`, `scripts/core/screamer.gd`, `scripts/desk/clickable_sprite.gd`, `scripts/desk/screamer_manager.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` y las pruebas de cada uno

**Ojo:** `curtains_sprite` tiene los tags `Open` y `Closed`, así que ya no tiene la animación `default`: por eso la escena pide `animation = &"Open"`. Si el importador no lo tomó, borrar `.godot/imported/curtains_sprite*` e importar otra vez.

El cuarto se oscurece con un nodo propio, `CurtainShade`: la capa `Darkness` no sirve, porque los screamers la devuelven a 0. Las cortinas cerradas tapan a la figura de la ventana porque se dibujan encima. El screamer de la cortina deja de mecerla y la abre o la cierra.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_art_imports.gd`, reemplazar:

```gdscript
		check_eq(panel.get_size(), Vector2(449, 696), "tamaño del panel")
	return true

```

por:

```gdscript
		check_eq(panel.get_size(), Vector2(449, 696), "tamaño del panel")
	return true


## Benja dibujó las cortinas abiertas y cerradas (tags Open y Closed).
func test_las_cortinas_tienen_sus_2_estados() -> bool:
	var frames: SpriteFrames = load(SPRITES + "curtains_sprite.aseprite")
	check(frames.has_animation(&"Open"), "abiertas")
	check(frames.has_animation(&"Closed"), "cerradas")
	return true

```

En `test/test_balance.gd`, reemplazar:

```gdscript
	check_eq(balance.jumpscare_sanity, 15.0, "jumpscare: Sanity −15")
```

por:

```gdscript
	check_eq(balance.jumpscare_sanity, 15.0, "jumpscare: Sanity −15")
	check_eq(balance.closed_curtains_sanity, 0.3, "con las cortinas cerradas, Sanity −0,3 por segundo")
	check_eq(balance.creature_sanity, 2.0, "con la criatura a cortina abierta, Sanity −2 por segundo")
```

En `test/test_clickable_sprite.gd`, reemplazar:

```gdscript
const CLICKABLE := preload("res://scripts/desk/clickable_sprite.gd")
```

por:

```gdscript
const CLICKABLE := preload("res://scripts/desk/clickable_sprite.gd")
const PixelHit := preload("res://scripts/desk/pixel_hit.gd")
```

En `test/test_clickable_sprite.gd`, reemplazar:

```gdscript
	check_eq(material.get_shader_parameter("enabled"), false, "deja de parpadear")
	phone.free()
	return true

```

por:

```gdscript
	check_eq(material.get_shader_parameter("enabled"), false, "deja de parpadear")
	phone.free()
	return true


## Las cortinas abiertas se clickean también en el hueco de la ventana: el clic usa el dibujo de las cerradas.
func test_el_clic_puede_usar_el_dibujo_de_otra_animacion() -> bool:
	var curtains := AnimatedSprite2D.new()
	curtains.set_script(CLICKABLE)
	curtains.sprite_frames = load("res://art/sprites/curtains_sprite.aseprite")
	curtains.animation = &"Open"
	curtains.centered = false
	curtains.hit_animation = &"Closed"
	(Engine.get_main_loop() as SceneTree).root.add_child(curtains)
	check(PixelHit.is_opaque(curtains._bitmap, Vector2(170, 200)), "el hueco de la ventana recibe el clic")
	curtains.free()
	return true

```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
	check_eq(bar.size.x, roundf(full / 2.0), "a la mitad")
```

por:

```gdscript
	check_eq(bar.size.x, roundf(full / 2.0), "a la mitad")
	desk.free()
	return true


## Las cortinas se abren y se cierran con un clic (decisión de Benja, 7 de noviembre). Cerradas, el cuarto se
## oscurece.
func test_las_cortinas_se_abren_y_se_cierran() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	var shade := desk.get_node("CurtainShade") as CanvasItem
	var state: RefCounted = desk.get_node("RequestManager").state
	check_eq(curtains.animation, &"Open", "empiezan abiertas")
	check_eq(shade.modulate.a, 0.0, "con el cuarto iluminado")
	curtains.clicked.emit()
	check_eq(curtains.animation, &"Closed", "un clic las cierra")
	check(state.curtains_closed, "la noche lo sabe")
	check(shade.modulate.a > 0.0, "y el cuarto se oscurece")
	check((desk.get_node("Screamers/CurtainsSound") as AudioStreamPlayer).playing, "con su sonido")
	curtains.clicked.emit()
	check_eq(curtains.animation, &"Open", "otro clic las abre")
	check(not state.curtains_closed, "la noche lo sabe")
	check_eq(shade.modulate.a, 0.0, "y vuelve la luz")
```

En `test/test_night_state.gd`, reemplazar:

```gdscript
	check(state.sanity < 50.0, "scrollear ya no sirve: %s" % state.sanity)
	return true

```

por:

```gdscript
	check(state.sanity < 50.0, "scrollear ya no sirve: %s" % state.sanity)
	return true


## Cerrar las cortinas baja Sanity de a poco; con la criatura afuera y la cortina abierta, baja rápido (decisión de
## Benja, 7 de noviembre).
func test_las_cortinas_y_la_criatura_bajan_sanity() -> bool:
	var state := _make_state()
	var base := 1.0 / state.night.sanity_drain_interval
	check(is_equal_approx(state.sanity_drain_per_second(), base), "sin nada, el goteo de la noche")
	state.curtains_closed = true
	check(is_equal_approx(state.sanity_drain_per_second(), base + 0.3), "cerradas, goteo lento")
	state.creature_outside = true
	check(is_equal_approx(state.sanity_drain_per_second(), base + 0.3), "con la criatura afuera, igual: no se ve")
	state.curtains_closed = false
	check(is_equal_approx(state.sanity_drain_per_second(), base + 2.0), "abiertas con la criatura, rápido")
	state.sanity = 50.0
	state.advance(1.0)
	check(is_equal_approx(state.sanity, 50.0 - base - 2.0), "y Sanity baja: %s" % state.sanity)
	return true

```

En `test/test_screamer.gd`, reemplazar:

```gdscript
			ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE], "la cortina, la ventana y el celular")
```

por:

```gdscript
			ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE], "la cortina, la ventana y el celular")
	return true


## Con las cortinas cerradas no se ve la ventana (decisión de Benja, 7 de noviembre).
func test_con_las_cortinas_cerradas_no_hay_figura_en_la_ventana() -> bool:
	var view := _view(true)
	view.curtains_closed = true
	check_eq(Screamer.candidates(view), [ScareKind.Kind.LIGHTS, ScareKind.Kind.CURTAINS, ScareKind.Kind.PHONE],
			"la cortina y el celular, sin la ventana")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
```

por:

```gdscript


## El screamer de la cortina ya no la mece: se abre o se cierra sola (decisión de Benja, 7 de noviembre).
func test_la_cortina_se_abre_o_se_cierra_sola() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	_screamers(desk).play(ScareKind.Kind.CURTAINS)
	check_eq(curtains.animation, &"Closed", "abierta, se cierra sola")
	check(_state(desk).curtains_closed, "y la noche lo sabe")
	_screamers(desk).play(ScareKind.Kind.CURTAINS)
	check_eq(curtains.animation, &"Open", "cerrada, se abre sola")
	desk.free()
	return true


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `489 pruebas OK, 6 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/balance.tres`, reemplazar:

```text
phone_battery_seconds = 38.0
```

por:

```text
phone_battery_seconds = 38.0
closed_curtains_sanity = 0.3
creature_sanity = 2.0
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
sprite_frames = ExtResource("curtains")
centered = false
```

por:

```text
sprite_frames = ExtResource("curtains")
animation = &"Open"
centered = false
script = ExtResource("clickable_script")
hit_animation = &"Closed"
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
display_name = "Agustín"

[node name="Darkness" type="Polygon2D" parent="."]
```

por:

```text
display_name = "Agustín"

[node name="CurtainShade" type="Polygon2D" parent="."]
modulate = Color(1, 1, 1, 0)
color = Color(0, 0, 0, 1)
polygon = PackedVector2Array(-64, -64, 1344, -64, 1344, 784, -64, 784)

[node name="Darkness" type="Polygon2D" parent="."]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
[node name="Screamers" type="Node" parent="." node_paths=PackedStringArray("curtains", "figure", "phone", "darkness", "notebook", "ambient")]
```

por:

```text
[node name="Screamers" type="Node" parent="." node_paths=PackedStringArray("curtains", "figure", "phone", "darkness", "curtain_shade", "notebook", "ambient")]
```

En `scenes/desk/desk.tscn`, reemplazar:

```text
darkness = NodePath("../Darkness")
```

por:

```text
darkness = NodePath("../Darkness")
curtain_shade = NodePath("../CurtainShade")
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
var battery := METER_MAX
```

por:

```gdscript
var battery := METER_MAX
## Las cortinas están cerradas: el cuarto se oscurece y Sanity baja de a poco (decisión de Benja, 7 de noviembre).
var curtains_closed := false
## La criatura está afuera: con las cortinas abiertas, Sanity baja rápido (decisión de Benja, 7 de noviembre).
var creature_outside := false
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript


## Al celular le queda batería.
```

por:

```gdscript


## Cuánta Sanity se pierde por segundo: lo de la noche, más lo de las cortinas cerradas o, si están abiertas, lo de
## la criatura. Cerradas, la criatura no se ve (decisión de Benja, 7 de noviembre).
func sanity_drain_per_second() -> float:
	var drain := 1.0 / night.sanity_drain_interval
	if curtains_closed:
		drain += balance.closed_curtains_sanity
	elif creature_outside:
		drain += balance.creature_sanity
	return drain


## Al celular le queda batería.
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	sanity = clampf(sanity - delta / night.sanity_drain_interval + scrolling * balance.scroll_sanity_per_second,
```

por:

```gdscript
	sanity = clampf(sanity - delta * sanity_drain_per_second() + scrolling * balance.scroll_sanity_per_second,
```

En `scripts/core/screamer.gd`, reemplazar:

```gdscript
	var panel_open := false
```

por:

```gdscript
	var panel_open := false
	## Las cortinas tapan la ventana: no se ve nada afuera.
	var curtains_closed := false
```

En `scripts/core/screamer.gd`, reemplazar:

```gdscript
		kinds.append_array([ScareKind.Kind.CURTAINS, ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE])
```

por:

```gdscript
		kinds.append(ScareKind.Kind.CURTAINS)
		if not view.curtains_closed:
			kinds.append(ScareKind.Kind.WINDOW)
		kinds.append(ScareKind.Kind.PHONE)
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var phone_battery_seconds := 38.0
```

por:

```gdscript
@export var phone_battery_seconds := 38.0

## Sanity que se pierde por segundo con las cortinas cerradas: la pieza a oscuras también pesa (decisión de Benja,
## 7 de noviembre). Se suma a lo que baja con el tiempo.
@export var closed_curtains_sanity := 0.3
## Sanity que se pierde por segundo con la criatura afuera y las cortinas abiertas (decisión de Benja, 7 de
## noviembre). Se suma a lo que baja con el tiempo.
@export var creature_sanity := 2.0
```

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
signal clicked
```

por:

```gdscript
signal clicked

## La animación cuyo dibujo recibe los clics. Vacía: la que tiene el sprite. Así las cortinas abiertas se clickean
## también en el hueco de la ventana.
@export var hit_animation: StringName
```

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
	_bitmap = PixelHit.bitmap_from_texture(sprite_frames.get_frame_texture(animation, 0))
```

por:

```gdscript
	var drawing := animation if hit_animation.is_empty() else hit_animation
	_bitmap = PixelHit.bitmap_from_texture(sprite_frames.get_frame_texture(drawing, 0))
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Benja).
```

por:

```gdscript
## Benja). Las cortinas se abren y se cierran con un clic (ScreamerManager), y la batería del celular se ve en su
## barra.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_end_screen.menu_pressed.connect(menu_requested.emit)
```

por:

```gdscript
	_end_screen.menu_pressed.connect(menu_requested.emit)
	$WallPlane/Curtains.clicked.connect(_screamers.toggle_curtains)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	view.panel_open = _chat_panel.visible or _mixer.visible
```

por:

```gdscript
	view.panel_open = _chat_panel.visible or _mixer.visible
	view.curtains_closed = _requests.state.curtains_closed
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
const Screamer := preload("res://scripts/core/screamer.gd")

## Volumen del sonido ambiente durante la señal previa y el screamer, en decibeles.
```

por:

```gdscript
const Screamer := preload("res://scripts/core/screamer.gd")

## Las animaciones de las cortinas (tags del arte de Benja).
const CURTAINS_OPEN := &"Open"
const CURTAINS_CLOSED := &"Closed"
## Cuánto se oscurece el cuarto con las cortinas cerradas.
const CLOSED_SHADE := 0.35
## Volumen del sonido ambiente durante la señal previa y el screamer, en decibeles.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Segundos que duran la cortina, la figura, el celular y las luces.
```

por:

```gdscript
## Segundos que duran la figura, el celular y las luces.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
@export var curtains: Node2D
```

por:

```gdscript
@export var curtains: AnimatedSprite2D
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
@export var darkness: CanvasItem
```

por:

```gdscript
@export var darkness: CanvasItem
## Oscurece el cuarto mientras las cortinas están cerradas.
@export var curtain_shade: CanvasItem
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript


## Muestra el screamer `kind` ahora, con su sonido, y resta Sanity. Después del susto guionado (`scripted`)
```

por:

```gdscript


## Clic en las cortinas: se cierran o se abren, con su sonido (decisión de Benja, 7 de noviembre).
func toggle_curtains() -> void:
	_set_curtains(not _requests.state.curtains_closed)
	($CurtainsSound as AudioStreamPlayer).play()


## Muestra el screamer `kind` ahora, con su sonido, y resta Sanity. Después del susto guionado (`scripted`)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
			_sway_curtains()
```

por:

```gdscript
			_set_curtains(not _requests.state.curtains_closed)
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## La cortina se mece, colgada de su barra.
func _sway_curtains() -> void:
	var tween := create_tween()
	for skew_value: float in [0.08, -0.05, 0.03, 0.0]:
		tween.tween_property(curtains, ^"skew", skew_value, EFFECT_SECONDS / 4.0)
```

por:

```gdscript
## Las cortinas quedan cerradas o abiertas. Cerradas, tapan la ventana y el cuarto se oscurece.
func _set_curtains(closed: bool) -> void:
	_requests.state.curtains_closed = closed
	curtains.animation = CURTAINS_CLOSED if closed else CURTAINS_OPEN
	curtain_shade.modulate.a = CLOSED_SHADE if closed else 0.0
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `495 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "Las cortinas se abren y se cierran"
```

---

### Tarea 8: La criatura se queda y hay que revisar

**Archivos:**

- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/data/night_data.gd`, `data/nights/night_0.tres` a `night_5.tres`, `scripts/core/pacing_director.gd`, `scripts/desk/screamer_manager.gd`, `test/test_balance.gd`, `test/test_pacing_director.gd`, `test/test_screamer_manager.gd`

`creature_seconds` ahora se cuenta desde que llega, y no desde que se ve. La criatura sigue armándose solo detrás del chat o el mixer (decisión del 4-nov). `has_jumpscare` pasa a ser `creature_visits`, y `jumpscare_at`, `jumpscare_slots`.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_balance.gd`, reemplazar:

```gdscript
	check_eq(balance.creature_seconds, 4.0, "la criatura se queda 4 s a la vista")
```

por:

```gdscript
	check_eq(balance.creature_seconds, 25.0, "la criatura se queda 25 s afuera")
```

En `test/test_balance.gd`, reemplazar:

```gdscript
	var scare_counts := [2, 4, 4, 5, 6]
```

por:

```gdscript
	var scare_counts := [2, 4, 4, 5, 6]
	var creature_visits := [0, 1, 2, 2, 3]
```

En `test/test_balance.gd`, reemplazar:

```gdscript
		check_eq(night.has_jumpscare, night.number >= 2, who + ": un jumpscare desde la noche 2")
```

por:

```gdscript
		check_eq(night.creature_visits, creature_visits[index], who + ": visitas de la criatura")
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
## Una noche con `count` screamers y, si `jumpscare`, uno de ellos es el jumpscare.
func _scary_night(count: int, jumpscare: bool) -> NightData:
```

por:

```gdscript
## Una noche con `count` screamers, de los que `visits` son la criatura de la ventana.
func _scary_night(count: int, visits: int) -> NightData:
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
	night.has_jumpscare = jumpscare
```

por:

```gdscript
	night.creature_visits = visits
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
		var times := _director(_scary_night(6, true), seed_value).scare_times
```

por:

```gdscript
		var times := _director(_scary_night(6, 1), seed_value).scare_times
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
func test_uno_es_el_jumpscare_si_la_noche_lo_tiene() -> bool:
	for jumpscare: bool in [true, false]:
```

por:

```gdscript
func test_la_criatura_llega_las_veces_que_pide_la_noche() -> bool:
	for visits: int in [0, 1, 3]:
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
			var director := _director(_scary_night(4, jumpscare), seed_value)
```

por:

```gdscript
			var director := _director(_scary_night(4, visits), seed_value)
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
			check_eq(found, 1 if jumpscare else 0, "jumpscares en una noche %s jumpscare" % ("con" if jumpscare else "sin"))
```

por:

```gdscript
			check_eq(found, visits, "visitas de la criatura")
	return true


func test_la_criatura_no_llega_mas_veces_que_los_screamers() -> bool:
	var director := _director(_scary_night(2, 5))
	check_eq(director.jumpscare_slots.size(), 2, "2 screamers, 2 visitas")
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
	var director := _director(_scary_night(0, false))
```

por:

```gdscript
	var director := _director(_scary_night(0, 0))
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	director.jumpscare_at = 0 if jumpscare else -1
```

por:

```gdscript
	director.jumpscare_slots.assign([0] if jumpscare else [])
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	desk._process(3.9)
	check(figure.visible, "a los 3,9 s, todavía")
```

por:

```gdscript
	desk._process(24.9)
	check(figure.visible, "a los 24,9 s de llegar, todavía")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	check(not screamers.is_creature_near(), "a los 4 s, se retira")
	check(not (screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "y se calla")
```

por:

```gdscript
	check(not screamers.is_creature_near(), "a los 25 s, se va")
	check(not (screamers.get_node("CreatureBreathing") as AudioStreamPlayer).playing, "y se calla")
	desk.free()
	return true


## Hace llegar a la criatura detrás del chat y cierra el chat: queda a la vista.
func _creature_at_window(desk: Node2D) -> void:
	var chat := desk.get_node("UI/ChatPanel") as Control
	_scare_now(desk, true)
	chat.show()
	desk._process(0.0)
	desk._process(1.0)
	chat.hide()
	desk._process(0.0)


## Mientras la criatura está afuera, la cortina abierta baja Sanity rápido (decisión de Benja, 7 de noviembre).
func test_la_criatura_afuera_baja_sanity() -> bool:
	var desk := _make_desk()
	_creature_at_window(desk)
	check(_state(desk).creature_outside, "la noche sabe que está afuera")
	desk._process(25.0)
	check(not _state(desk).creature_outside, "cuando se va, ya no")
	desk.free()
	return true


## Si la cortina estaba cerrada, la criatura la abre al llegar (idea de Benja, 7 de noviembre).
func test_la_criatura_abre_la_cortina_cerrada() -> bool:
	var desk := _make_desk()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	curtains.clicked.emit()
	check_eq(curtains.animation, &"Closed", "cerrada")
	_creature_at_window(desk)
	check_eq(curtains.animation, &"Open", "la criatura la abrió")
	check(not _state(desk).curtains_closed, "y la noche lo sabe")
	desk.free()
	return true


## Se queda un tiempo fijo, aunque se cierre la cortina: hay que abrirla para ver si sigue ahí. Con la cortina
## cerrada no se oye, para que haya que revisar (decisión de Benja, 7 de noviembre).
func test_cerrar_la_cortina_no_la_espanta() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	var breathing := screamers.get_node("CreatureBreathing") as AudioStreamPlayer
	var knocks := screamers.get_node("CreatureKnocks") as AudioStreamPlayer
	_creature_at_window(desk)
	curtains.clicked.emit()
	desk._process(0.5)
	check(screamers.is_creature_near(), "sigue ahí")
	check(not breathing.playing and not knocks.playing, "pero no se oye")
	curtains.clicked.emit()
	desk._process(0.0)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "al abrir la cortina, se ve")
	check(breathing.playing, "y se oye")
	curtains.clicked.emit()
	desk._process(24.6)
	check(not screamers.is_creature_near(), "se fue sola, a su hora")
	check(not _state(desk).creature_outside, "y al abrir la cortina ya no baja Sanity rápido")
	desk.free()
	return true


## Detrás de un panel, sus golpes se repiten: son el aviso de que hay que ir a la ventana.
func test_detras_de_un_panel_los_golpes_se_repiten() -> bool:
	var desk := _make_desk()
	var chat := desk.get_node("UI/ChatPanel") as Control
	var knocks := _screamers(desk).get_node("CreatureKnocks") as AudioStreamPlayer
	_scare_now(desk, true)
	chat.show()
	desk._process(0.0)
	desk._process(1.0)
	knocks.stop()
	desk._process(0.1)
	check(knocks.playing, "vuelven a sonar")
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
	_process(desk, 4)
	check(kinds.size() >= 2, "al retirarse, llega el otro: %s" % [kinds])
```

por:

```gdscript
	_process(desk, 24)
	check(kinds.size() >= 2, "al irse, llega el otro: %s" % [kinds])
```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `490 pruebas OK, 10 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/balance.tres`, reemplazar:

```text
creature_seconds = 4.0
```

por:

```text
creature_seconds = 25.0
```

En `data/nights/night_0.tres`, reemplazar:

```text
has_jumpscare = false
```

por:

```text
creature_visits = 0
```

En `data/nights/night_1.tres`, reemplazar:

```text
has_jumpscare = false
```

por:

```text
creature_visits = 0
```

En `data/nights/night_2.tres`, reemplazar:

```text
has_jumpscare = true
```

por:

```text
creature_visits = 1
```

En `data/nights/night_3.tres`, reemplazar:

```text
has_jumpscare = true
```

por:

```text
creature_visits = 2
```

En `data/nights/night_4.tres`, reemplazar:

```text
has_jumpscare = true
```

por:

```text
creature_visits = 2
```

En `data/nights/night_5.tres`, reemplazar:

```text
has_jumpscare = true
```

por:

```text
creature_visits = 3
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
## Los screamers llegan en cualquier momento, repartidos en la noche, y uno puede ser el jumpscare. El susto
```

por:

```gdscript
## Los screamers llegan en cualquier momento, repartidos en la noche, y algunos son el jumpscare. El susto
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
## Cuál de los screamers que faltan es el jumpscare, contado desde el próximo (0); -1 si no hay.
var jumpscare_at := -1
```

por:

```gdscript
## Cuáles de los screamers que faltan son el jumpscare, contados desde el próximo (0).
var jumpscare_slots: Array[int] = []
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
	if night.has_jumpscare and not scare_times.is_empty():
		jumpscare_at = rng.randi_range(0, scare_times.size() - 1)
```

por:

```gdscript
	jumpscare_slots = plan_jumpscares(night.creature_visits, scare_times.size(), rng)
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript


## Toca un screamer: llegó su hora y pasaron scare_min_gap segundos desde el anterior.
```

por:

```gdscript


## Cuáles de `scare_count` screamers son el jumpscare: `visits` al azar, sin pasar de los que hay.
static func plan_jumpscares(visits: int, scare_count: int, rng: RandomNumberGenerator) -> Array[int]:
	var slots: Array[int] = []
	for index in scare_count:
		slots.append(index)
	for index in range(slots.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := slots[index]
		slots[index] = slots[other]
		slots[other] = swap
	return slots.slice(0, mini(visits, scare_count))


## Toca un screamer: llegó su hora y pasaron scare_min_gap segundos desde el anterior.
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
	return jumpscare_at == 0
```

por:

```gdscript
	return jumpscare_slots.has(0)
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
	jumpscare_at -= 1
```

por:

```gdscript
	var slots: Array[int] = []
	for slot: int in jumpscare_slots:
		if slot > 0:
			slots.append(slot - 1)
	jumpscare_slots = slots
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
## Segundos que la criatura de la ventana se queda a la vista, desde que se ve (decisión de Benja, 4 de
## noviembre). No tapa nada: la noche no se pausa.
@export var creature_seconds := 4.0
```

por:

```gdscript
## Segundos que la criatura de la ventana se queda afuera, desde que llega, aunque se cierren las cortinas: hay que
## abrirlas para revisar si sigue ahí (decisión de Benja, 7 de noviembre). No tapa nada: la noche no se pausa.
@export var creature_seconds := 25.0
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
## Uno de los screamers es la criatura que se asoma por la ventana (el antiguo jumpscare): como máximo uno por
## noche, desde la noche 2.
@export var has_jumpscare := false
```

por:

```gdscript
## Cuántos de esos screamers son la criatura que se asoma por la ventana (el antiguo jumpscare): desde la noche 2,
## y más seguido hacia el final (decisión de Benja, 7 de noviembre).
@export var creature_visits := 0
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## chat o el mixer tapan la ventana, y está ahí al cerrarlos. Después del susto guionado empieza su chat
## guionado (decisión de Benja).
```

por:

```gdscript
## chat o el mixer tapan la ventana, y está ahí al cerrarlos. Se queda un tiempo fijo: si las cortinas estaban
## cerradas las abre, y cerrarlas no la espanta, pero baja menos Sanity y no se oye, así que hay que abrirlas para
## revisar si sigue ahí (decisión de Benja, 7 de noviembre). Después del susto guionado empieza su chat guionado
## (decisión de Benja).
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## Segundos que lleva a la vista la criatura.
var _creature_seen := 0.0
```

por:

```gdscript
## Segundos que la criatura se queda todavía afuera.
var _creature_left := 0.0
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## La criatura llega a la ventana, con su respiración y sus golpes en el vidrio. Si la ventana está a la vista,
## aparece enseguida; si un panel la tapa, espera detrás, y al cerrarlo ya está ahí, sin animación de entrada.
func _creature_arrives() -> void:
```

por:

```gdscript
## La criatura llega a la ventana, con su respiración y sus golpes en el vidrio, y abre las cortinas si estaban
## cerradas. Si la ventana está a la vista, aparece enseguida; si un panel la tapa, espera detrás, y al cerrarlo ya
## está ahí, sin animación de entrada.
func _creature_arrives() -> void:
	var state := _requests.state
	state.creature_outside = true
	_creature_left = _requests.catalog.balance.creature_seconds
	if state.curtains_closed:
		_set_curtains(false)
		($CurtainsSound as AudioStreamPlayer).play()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
		_breathing.volume_db = HIDDEN_BREATHING_DB
```

por:

```gdscript
	_refresh_creature_sound()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
## La criatura se ve en la ventana, con la respiración más fuerte, durante creature_seconds.
```

por:

```gdscript
## La criatura se ve en la ventana. Las cortinas cerradas la tapan, porque se dibujan encima.
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	_creature = Creature.SEEN
	_creature_seen = 0.0
```

por:

```gdscript
	_creature = Creature.SEEN
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	_breathing.volume_db = 0.0
```

por:

```gdscript


## La criatura detrás de un panel se ve apenas la ventana queda a la vista, y se va a los creature_seconds de
## llegar, con las cortinas abiertas o cerradas.
func _advance_creature(delta: float) -> void:
	if _creature == Creature.AWAY:
		return
	_creature_left -= delta
	if _creature_left <= 0.0:
		_creature_leaves()
		return
	if _creature == Creature.HIDDEN and _window_visible:
		_show_creature()
	_refresh_creature_sound()


## Con las cortinas abiertas se oye su respiración, más fuerte si se ve, y detrás de un panel se repiten sus golpes,
## que avisan que hay que ir a la ventana. Con las cortinas cerradas no se oye nada: hay que abrirlas para saber si
## sigue ahí.
func _refresh_creature_sound() -> void:
	if _requests.state.curtains_closed:
		_breathing.stop()
		_knocks.stop()
		return
	_breathing.volume_db = 0.0 if _creature == Creature.SEEN else HIDDEN_BREATHING_DB
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript


## La criatura detrás de un panel se ve apenas la ventana queda a la vista; a la vista, se retira a los
## creature_seconds.
func _advance_creature(delta: float) -> void:
	match _creature:
		Creature.HIDDEN:
			if _window_visible:
				_show_creature()
		Creature.SEEN:
			_creature_seen += delta
			if _creature_seen >= _requests.catalog.balance.creature_seconds:
				_creature_leaves()
```

por:

```gdscript
	if _creature == Creature.HIDDEN and not _knocks.playing:
		_knocks.play()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	_creature = Creature.AWAY
```

por:

```gdscript
	_creature = Creature.AWAY
	_requests.state.creature_outside = false
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `500 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "La criatura se queda: hay que abrir la cortina para revisar"
```

---

### Tarea 9: La noche 0 enseña las cortinas, los audios y la batería

**Archivos:**

- Modificar: `scripts/core/tutorial_guide.gd`, `scripts/desk/desk.gd`, `data/text/ui.csv`, `test/test_tutorial_guide.gd`, `test/test_tutorial_desk.gd`

El aviso de las cortinas va antes que todo lo demás, salvo los diales: mientras la criatura esté a la vista, lo urgente es cerrarlas.

- [ ] **Paso 1: Escribir las pruebas**

En `test/test_tutorial_desk.gd`, reemplazar:

```gdscript
	# El respiro, el susto guionado (con su señal previa y su pausa) y lo que tarda Gonzalo en escribir.
	_play(desk, 10)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_GONZALO_NAME"), "Gonzalo escribió")
```

por:

```gdscript
	# El respiro, el susto guionado (con su señal previa y su pausa) y lo que tarda Gonzalo en escribir.
	_play(desk, 10)
	# La criatura enseña las cortinas: se cierran, se espera y se abren para revisar.
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	check_eq(_hint_text(desk), _expected(TutorialGuide.CLOSE_CURTAINS_KEY), "cerrar las cortinas")
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CURTAINS_KEY), "revisar")
	_play(desk, 25)
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CHAT_KEY, "FRIEND_GONZALO_NAME"), "Gonzalo escribió")
```

En `test/test_tutorial_desk.gd`, reemplazar:

```gdscript
	check(not hint.visible, "el aviso se va con la pantalla final")
	desk.free()
	return true

```

por:

```gdscript
	check(not hint.visible, "el aviso se va con la pantalla final")
	desk.free()
	return true


## La criatura del susto guionado: el aviso pide cerrar las cortinas, y después abrirlas para revisar (decisión de
## Benja, 7 de noviembre).
func test_la_criatura_ensena_las_cortinas() -> bool:
	var desk := _make_desk()
	desk.get_node("RequestManager").tutorial_queue.clear()
	var curtains := desk.get_node("WallPlane/Curtains") as AnimatedSprite2D
	(desk.get_node("Overlay/TutorialHint/Box/Ok") as Button).pressed.emit()
	_play(desk, 6)
	check_eq(_hint_text(desk), _expected(TutorialGuide.CLOSE_CURTAINS_KEY), "pide cerrarlas")
	curtains.clicked.emit()
	desk._process(0.0)
	check_eq(_hint_text(desk), _expected(TutorialGuide.OPEN_CURTAINS_KEY), "pide revisar")
	desk.free()
	return true

```

En `test/test_tutorial_guide.gd`, reemplazar:

```gdscript


func test_sus_textos_existen() -> bool:
```

por:

```gdscript


## La criatura del susto guionado enseña las cortinas (decisión de Benja, 7 de noviembre).
func test_las_cortinas() -> bool:
	var guide := TutorialGuide.new()
	var view := _view()
	view.creature_at_window = true
	_check_hint(guide, view, TutorialGuide.CLOSE_CURTAINS_KEY)
	view.creature_at_window = false
	view.curtains_closed = true
	_check_hint(guide, view, TutorialGuide.OPEN_CURTAINS_KEY)
	view.curtains_closed = false
	_check_hint(guide, view, TutorialGuide.WELCOME_KEY)
	return true


func test_sus_textos_existen() -> bool:
```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `491 pruebas OK, 2 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/text/ui.csv`, reemplazar:

```csv
TUTORIAL_ANSWER,"Lee las reglas en orden: vale la primera que se cumple. Si te falta un dato, pregúntalo. Después responde con su acción, desde el chat.",
```

por:

```csv
TUTORIAL_ANSWER,"Lee las reglas en orden: vale la primera que se cumple. Si te falta un dato, pregúntalo. Si te mandan un audio, escúchalo con un clic: lo que se oye cambia la acción. Después responde desde el chat.",
```

En `data/text/ui.csv`, reemplazar:

```csv
TUTORIAL_SCROLL,"Scrollea con la rueda del mouse: mientras scrolleas, Sanity sube. Ciérralo con clic derecho para terminar.",
```

por:

```csv
TUTORIAL_SCROLL,"Scrollea con la rueda del mouse: mientras scrolleas, Sanity sube. La batería no se recarga en toda la noche, así que úsala con cuidado. Ciérralo con clic derecho para terminar.",
```

En `data/text/ui.csv`, reemplazar:

```csv
OPTIONS_AUDIO_CAPTIONS,Subtítulos de los audios,
```

por:

```csv
OPTIONS_AUDIO_CAPTIONS,Subtítulos de los audios,
TUTORIAL_CLOSE_CURTAINS,"¡Hay algo en la ventana! Mientras esté ahí, Sanity baja rápido. Haz clic en las cortinas para cerrarlas.",
TUTORIAL_OPEN_CURTAINS,"Cerradas, Sanity baja de a poco y no oyes si sigue afuera. Ábrelas con un clic para revisar: si sigue ahí, vuelve a cerrarlas.",
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
## de la entidad, responder desde el cuaderno y descargar un video. Después del susto guionado, a responderle al
## amigo y a usar el celular. El tutorial termina cuando Matías cierra el celular.
```

por:

```gdscript
## de la entidad, responder desde el cuaderno y descargar un video. Después del susto guionado, a cerrar las
## cortinas y revisar si la criatura sigue ahí, a responderle al amigo y a usar el celular. El tutorial termina
## cuando Matías cierra el celular.
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
const DIALS_OK_KEY := "TUTORIAL_DIALS_OK"
```

por:

```gdscript
const DIALS_OK_KEY := "TUTORIAL_DIALS_OK"
const CLOSE_CURTAINS_KEY := "TUTORIAL_CLOSE_CURTAINS"
const OPEN_CURTAINS_KEY := "TUTORIAL_OPEN_CURTAINS"
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
	var script_friend := -1
```

por:

```gdscript
	var script_friend := -1
	## La criatura está afuera y las cortinas abiertas.
	var creature_at_window := false
	var curtains_closed := false
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
## Qué hacer ahora. Primero los diales, después el celular, el chat guionado, el video y la solicitud en curso.
```

por:

```gdscript
## Qué hacer ahora. Primero los diales, después las cortinas, el celular, el chat guionado, el video y la solicitud
## en curso.
```

En `scripts/core/tutorial_guide.gd`, reemplazar:

```gdscript
		return Hint.new(DIALS_KEY, -1, true)
```

por:

```gdscript
		return Hint.new(DIALS_KEY, -1, true)
	if view.creature_at_window:
		return Hint.new(CLOSE_CURTAINS_KEY)
	if view.curtains_closed:
		return Hint.new(OPEN_CURTAINS_KEY)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## espera y el chat guionado.
```

por:

```gdscript
## espera, el chat guionado, la criatura y las cortinas.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	view.chat_friend = _chat_panel.selected_friend if _chat_panel.visible else -1
```

por:

```gdscript
	view.chat_friend = _chat_panel.selected_friend if _chat_panel.visible else -1
	view.creature_at_window = state.creature_outside and not state.curtains_closed
	view.curtains_closed = state.curtains_closed
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `502 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "La noche 0 enseña las cortinas, los audios y la batería"
```

---

### Tarea 10: Los accidentes

**Archivos:**

- Crear: `scripts/data/incident_data.gd`, `scripts/core/friend_incident.gd`, `test/test_friend_incident.gd`
- Modificar: `scripts/data/night_data.gd`, `scripts/data/balance_data.gd`, `scripts/data/content_catalog.gd`, `data/balance.tres`, `data/catalog.tres`, `data/nights/night_1.tres` a `night_5.tres`, `scripts/core/pacing_director.gd`, `scripts/core/night_state.gd`, `scripts/core/message_builder.gd`, `scripts/core/content_validator.gd`, `scripts/desk/request_manager.gd`, `scripts/desk/screamer_manager.gd`, `scripts/desk/desk.gd`, `scripts/ui/chat_panel.gd`, `data/text/messages.csv`, `data/text/ui.csv` y las pruebas de cada uno

Un accidente no es una `FriendRequest`: no tiene entidad, ni reglas, ni características. Va en `RequestManager.incidents`, un arreglo por amigo como `requests`, y sus opciones usan los botones de respuesta del chat. Esto deja listo el marco de las "solicitudes sin entidad" que necesitará la historia (`docs/05`, punto 22).

- [ ] **Paso 1: Escribir las pruebas**

En `test/content_fixtures.gd`, reemplazar:

```gdscript
	return stream

```

por:

```gdscript
	return stream


## Un accidente: "K_INCIDENT_<id>", una buena idea y 2 malas. No va en el catálogo de prueba: cada prueba lo agrega.
static func make_incident(incident_id: StringName = &"trip") -> IncidentData:
	var incident := IncidentData.new()
	incident.id = incident_id
	incident.message_key = "K_INCIDENT_%s" % incident_id
	incident.correct_key = "K_INCIDENT_%s_OK" % incident_id
	incident.wrong_keys.assign(["K_INCIDENT_%s_BAD_1" % incident_id, "K_INCIDENT_%s_BAD_2" % incident_id])
	return incident

```

En `test/test_balance.gd`, reemplazar:

```gdscript


## Trust también baja si tardas en contestar (decisión de Benja, 4 de noviembre).
```

por:

```gdscript


## Los accidentes de los amigos (decisión de Benja, 7 de noviembre).
func test_accidentes() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.balance.incident_seconds, 15.0, "15 s para responder un accidente")
	check_eq(catalog.balance.incident_damage, 1, "una mala respuesta: −1 PV")
	var counts := [1, 1, 2, 2, 3]
	for index in catalog.nights.size():
		check_eq(catalog.nights[index].incident_count, counts[index], "noche %d: accidentes" % (index + 1))
	check_eq(catalog.tutorial.incident_count, 0, "en la noche 0 no hay")
	return true


## Trust también baja si tardas en contestar (decisión de Benja, 4 de noviembre).
```

En `test/test_catalog.gd`, reemplazar:

```gdscript


## Desde la noche 3 hay entidades que se confunden: comparten 2 características, y solo se distinguen por otra
```

por:

```gdscript


func test_hay_accidentes() -> bool:
	var catalog: ContentCatalog = load(CATALOG_PATH)
	check(catalog.incidents.size() >= 5, "varios accidentes: %d" % catalog.incidents.size())
	return true


## Desde la noche 3 hay entidades que se confunden: comparten 2 características, y solo se distinguen por otra
```

En `test/test_chat_panel.gd`, reemplazar:

```gdscript
	check(label.get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	_free(panel)
	return true

```

por:

```gdscript
	check(label.get_parsed_text().contains("Gritó tres veces."), "con la opción, se lee")
	_free(panel)
	return true


func test_un_accidente_se_responde_desde_el_chat() -> bool:
	var panel := _make_panel()
	_manager.catalog.incidents.append(Fixtures.make_incident())
	panel.open_for(0)
	var incident: RefCounted = _manager.start_incident(0)
	panel._process(0.0)
	check((panel.get_node("Panel/Answers") as Control).visible, "se ven las opciones, sin cuaderno")
	var buttons := _answer_buttons(panel)
	for index in incident.options.size():
		check((buttons[index] as Button).visible, "opción %d" % index)
		check_eq((buttons[index] as Button).text, tr(incident.options[index]), "su texto")
		check(not (buttons[index] as Button).disabled, "se puede elegir")
	check(not (buttons[3] as Button).visible, "la cuarta no se usa")
	check_eq((panel.get_node("Panel/AnswerHint") as Label).text, tr(panel.INCIDENT_HINT_KEY), "el aviso")
	check(_question_buttons(panel).all(func(button: Button) -> bool: return button.disabled), "no se pregunta")
	check(panel._tab_text(0).contains("15"), "la pestaña muestra su tiempo")
	(buttons[0] as Button).pressed.emit()
	check_eq(_manager.incidents[0], null, "al elegir, termina")
	_free(panel)
	return true

```

En `test/test_desk_scene.gd`, reemplazar:

```gdscript
	check_eq(shade.modulate.a, 0.0, "y vuelve la luz")
```

por:

```gdscript
	check_eq(shade.modulate.a, 0.0, "y vuelve la luz")
	desk.free()
	return true


## La entrada del amigo avisa el accidente y muestra su tiempo.
func test_la_entrada_avisa_un_accidente() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	manager.start_incident(0)
	desk._process(0.0)
	check_eq(desk.get_node("DeskPlane/Entries/EntryLeon").state, ChatEntry.State.WARNING, "en alerta")
```

`test/test_friend_incident.gd`:

```gdscript
extends "res://test/test_case.gd"
## Los accidentes de los amigos (decisión de Benja, 7 de noviembre).

const Fixtures := preload("res://test/content_fixtures.gd")
const FriendIncident := preload("res://scripts/core/friend_incident.gd")


func _make_incident(seed_value := 1) -> FriendIncident:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FriendIncident.new(Fixtures.make_incident(), 2, 15.0, rng)


func test_tiene_la_buena_idea_y_las_malas() -> bool:
	var incident := _make_incident()
	check_eq(incident.friend_index, 2, "su amigo")
	check_eq(incident.options.size(), 3, "3 opciones")
	check(incident.options.has("K_INCIDENT_trip_OK"), "la buena")
	check(incident.options.has("K_INCIDENT_trip_BAD_1"), "una mala")
	return true


func test_la_buena_idea_no_siempre_va_primero() -> bool:
	var firsts := {}
	for seed_value in range(1, 21):
		firsts[_make_incident(seed_value).options[0]] = true
	check(firsts.size() > 1, "las opciones se barajan: %s" % [firsts.keys()])
	return true


func test_solo_la_buena_idea_es_correcta() -> bool:
	var incident := _make_incident()
	var correct := 0
	for index in incident.options.size():
		if incident.is_correct(index):
			correct += 1
			check_eq(incident.options[index], "K_INCIDENT_trip_OK", "es la buena")
	check_eq(correct, 1, "una sola")
	return true


func test_se_le_acaba_el_tiempo() -> bool:
	var incident := _make_incident()
	incident.advance(14.0)
	check(not incident.is_out_of_time(), "a los 14 s, todavía")
	incident.advance(2.0)
	check(incident.is_out_of_time(), "a los 15 s, se acabó")
	return true
```

En `test/test_pacing_director.gd`, reemplazar:

```gdscript
	check(not _director(_night()).scripted_scare_due(100.0, 0), "una noche sin susto guionado")
	return true

```

por:

```gdscript
	check(not _director(_night()).scripted_scare_due(100.0, 0), "una noche sin susto guionado")
	return true


func test_reparte_los_accidentes_en_la_noche() -> bool:
	var night := _night()
	night.incident_count = 3
	var director := _director(night)
	check_eq(director.incident_times.size(), 3, "3 accidentes")
	var first: float = director.incident_times[0]
	check(not director.incident_due(first - 1.0), "todavía no")
	check(director.incident_due(first), "a su hora")
	director.incident_started()
	check_eq(director.incident_times.size(), 2, "quedan 2")
	return true

```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
	check_eq(manager.impatient_count(), 0, "sin señal ya baja Trust por eso")
	manager.free()
	return true

```

por:

```gdscript
	check_eq(manager.impatient_count(), 0, "sin señal ya baja Trust por eso")
	manager.free()
	return true


## Manager de la noche 1 con un accidente en el catálogo.
func _make_incident_manager() -> RequestManager:
	var catalog := Fixtures.make_catalog()
	catalog.incidents.append(Fixtures.make_incident())
	return _make_manager(catalog)


## La opción correcta o una incorrecta del accidente del amigo `friend_index`.
func _option(manager: RequestManager, friend_index: int, correct: bool) -> int:
	var incident: RefCounted = manager.incidents[friend_index]
	for index in incident.options.size():
		if incident.is_correct(index) == correct:
			return index
	return -1


func test_un_accidente_llega_al_chat() -> bool:
	var manager := _make_incident_manager()
	var events := []
	_record(manager, events)
	var incident: RefCounted = manager.start_incident(1)
	check(incident != null, "empezó")
	check_eq(manager.incidents[1], incident, "es del amigo")
	check_eq(incident.time_left, 15.0, "15 s")
	check_eq(events.size(), 1, "un mensaje")
	if events.size() == 1:
		check_eq(events[0][0], "message_added", "del amigo")
		check_eq(events[0][2].sender, ChatMessage.Sender.FRIEND, "lo escribe el amigo")
	manager.free()
	return true


func test_la_buena_idea_lo_salva() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	check(manager.answer_incident(0, _option(manager, 0, true)), "respondió")
	check_eq(manager.incidents[0], null, "terminó")
	check_eq(manager.state.friends[0].health, 3, "no perdió vida")
	check(not manager.state.friends[0].is_stunned(), "ni quedó aturdido")
	manager.free()
	return true


func test_una_mala_idea_lo_hiere() -> bool:
	var manager := _make_incident_manager()
	var events := []
	manager.start_incident(0)
	_record(manager, events)
	manager.answer_incident(0, _option(manager, 0, false))
	check_eq(manager.state.friends[0].health, 2, "−1 PV")
	check(manager.state.friends[0].is_stunned(), "aturdido")
	check_eq(manager.state.trust, 100.0, "un accidente no baja Trust")
	var senders := events.map(func(event: Array) -> ChatMessage.Sender: return event[2].sender)
	check_eq(senders, [ChatMessage.Sender.PLAYER, ChatMessage.Sender.FRIEND, ChatMessage.Sender.SYSTEM],
			"Matías, el amigo y el aviso de daño")
	manager.free()
	return true


func test_si_nadie_responde_lo_hiere() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	manager.advance(16.0)
	check_eq(manager.incidents[0], null, "terminó")
	check_eq(manager.state.friends[0].health, 2, "−1 PV")
	manager.free()
	return true


## Con la opción "Temporizadores ×1,5", también hay más tiempo para responder un accidente.
func test_un_accidente_con_temporizadores_lentos() -> bool:
	var manager := _make_incident_manager()
	manager.timer_scale = 1.5
	check_eq(manager.start_incident(0).time_left, 22.5, "22,5 s")
	manager.free()
	return true


func test_un_amigo_ocupado_no_tiene_accidentes() -> bool:
	var manager := _make_incident_manager()
	manager.start_request(0)
	check_eq(manager.start_incident(0), null, "con una solicitud, no")
	check(manager.start_incident(1) != null, "otro amigo, sí")
	check_eq(manager.start_request(1), null, "y con un accidente, no le llegan solicitudes")
	manager.state.friends[2].health = 1
	check_eq(manager.start_incident(2), null, "un accidente nunca lo mata: con 1 PV no tiene")
	manager.free()
	return true


func test_sin_senal_no_responde() -> bool:
	var manager := _make_incident_manager()
	manager.start_incident(0)
	manager.state.friends[0].signal_level = 0.0
	check(not manager.answer_incident(0, 0), "no lee la respuesta")
	check(manager.incidents[0] != null, "sigue esperando")
	manager.free()
	return true


## El director reparte los accidentes, y uno llega solo si hay espacio: no se suman a una ola llena.
func test_llegan_a_su_hora_si_hay_espacio() -> bool:
	var manager := _make_incident_manager()
	manager.requests_arrive = true
	manager.director.request_times.clear()
	manager.director.incident_times.assign([10.0])
	manager.night().max_simultaneous = 1
	manager.start_request(0)
	manager.advance(11.0)
	check(manager.incidents.all(func(incident: RefCounted) -> bool: return incident == null), "con la ola llena, espera")
	manager.answer(0, manager.requests[0].entity.actions[0])
	manager.advance(1.0)
	check_eq(manager.incidents.count(null), 2, "al desocuparse, llega")
	manager.free()
	return true

```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
```

por:

```gdscript


func test_nunca_en_los_ultimos_5_s_de_un_accidente() -> bool:
	var desk := _make_desk()
	var manager := desk.get_node("RequestManager")
	manager.start_incident(0)
	manager.incidents[0].time_left = 4.0
	_scare_now(desk)
	desk._process(0.0)
	check(not _screamers(desk).is_warning(), "espera a que el jugador responda")
	desk.free()
	return true


## Mientras suena un audio de un amigo no empieza nada que se confunda con él (decisión de Benja, 7 de noviembre).
```

En `test/test_validator_catalog.gd`, reemplazar:

```gdscript
	check(ContentValidator.validate_catalog(catalog).is_empty(), "el tutorial es opcional para el validador")
	return true

```

por:

```gdscript
	check(ContentValidator.validate_catalog(catalog).is_empty(), "el tutorial es opcional para el validador")
	return true


func test_los_accidentes() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].incident_count = 1
	check_contains(ContentValidator.validate_catalog(catalog), "la noche 1 pide accidentes y el catálogo no tiene")
	catalog.incidents.append(Fixtures.make_incident())
	check(ContentValidator.validate_catalog(catalog).is_empty(), "con uno, está bien")
	catalog.incidents[0].wrong_keys.clear()
	check_contains(ContentValidator.validate_catalog(catalog), "Accidente 'trip': necesita 1 o 2 malas ideas")
	catalog.incidents.append(null)
	check_contains(ContentValidator.validate_catalog(catalog), "hay un espacio vacío en 'incidents'")
	return true

```

- [ ] **Paso 2: Verificar que fallan**

Esperado: `271 pruebas OK, 174 fallidas`.

- [ ] **Paso 3: Implementar**

En `data/balance.tres`, reemplazar:

```text
no_answer_trust = -15.0
```

por:

```text
no_answer_trust = -15.0
incident_seconds = 15.0
incident_damage = 1
```

En `data/catalog.tres`, reemplazar:

```text
[ext_resource type="Resource" path="res://data/nights/night_0.tres" id="15_night_0"]
```

por:

```text
[ext_resource type="Resource" path="res://data/nights/night_0.tres" id="15_night_0"]
[ext_resource type="Script" path="res://scripts/data/incident_data.gd" id="16_incident"]
```

En `data/catalog.tres`, reemplazar:

```text
text_key = "DECOY_SMOKE_SMELL"

[sub_resource type="Resource" id="PhonePost_01"]
```

por:

```text
text_key = "DECOY_SMOKE_SMELL"

[sub_resource type="Resource" id="Incident_cut"]
script = ExtResource("16_incident")
id = &"cut"
message_key = "INCIDENT_CUT"
correct_key = "INCIDENT_CUT_OK"
wrong_keys = Array[String](["INCIDENT_CUT_BAD_1", "INCIDENT_CUT_BAD_2"])

[sub_resource type="Resource" id="Incident_ankle"]
script = ExtResource("16_incident")
id = &"ankle"
message_key = "INCIDENT_ANKLE"
correct_key = "INCIDENT_ANKLE_OK"
wrong_keys = Array[String](["INCIDENT_ANKLE_BAD_1", "INCIDENT_ANKLE_BAD_2"])

[sub_resource type="Resource" id="Incident_soaked"]
script = ExtResource("16_incident")
id = &"soaked"
message_key = "INCIDENT_SOAKED"
correct_key = "INCIDENT_SOAKED_OK"
wrong_keys = Array[String](["INCIDENT_SOAKED_BAD_1", "INCIDENT_SOAKED_BAD_2"])

[sub_resource type="Resource" id="Incident_bump"]
script = ExtResource("16_incident")
id = &"bump"
message_key = "INCIDENT_BUMP"
correct_key = "INCIDENT_BUMP_OK"
wrong_keys = Array[String](["INCIDENT_BUMP_BAD_1", "INCIDENT_BUMP_BAD_2"])

[sub_resource type="Resource" id="Incident_thorn"]
script = ExtResource("16_incident")
id = &"thorn"
message_key = "INCIDENT_THORN"
correct_key = "INCIDENT_THORN_OK"
wrong_keys = Array[String](["INCIDENT_THORN_BAD_1", "INCIDENT_THORN_BAD_2"])

[sub_resource type="Resource" id="PhonePost_01"]
```

En `data/catalog.tres`, reemplazar:

```text
tutorial = ExtResource("15_night_0")
```

por:

```text
tutorial = ExtResource("15_night_0")
incidents = Array[ExtResource("16_incident")]([SubResource("Incident_cut"), SubResource("Incident_ankle"), SubResource("Incident_soaked"), SubResource("Incident_bump"), SubResource("Incident_thorn")])
```

En `data/nights/night_1.tres`, reemplazar:

```text
wave_size = 2
```

por:

```text
wave_size = 2
incident_count = 1
```

En `data/nights/night_2.tres`, reemplazar:

```text
wave_size = 3
```

por:

```text
wave_size = 3
incident_count = 1
```

En `data/nights/night_3.tres`, reemplazar:

```text
wave_size = 3
```

por:

```text
wave_size = 3
incident_count = 2
```

En `data/nights/night_4.tres`, reemplazar:

```text
wave_size = 4
```

por:

```text
wave_size = 4
incident_count = 2
```

En `data/nights/night_5.tres`, reemplazar:

```text
wave_size = 4
```

por:

```text
wave_size = 4
incident_count = 3
```

En `data/text/messages.csv`, reemplazar:

```csv
DECOY_SMOKE_SMELL,Se siente *olor a humo de leña*.,
```

por:

```csv
DECOY_SMOKE_SMELL,Se siente *olor a humo de leña*.,
INCIDENT_CUT,¡Auch! Me tropecé con una raíz y me corté la mano. Está sangrando harto.,
INCIDENT_CUT_OK,Presiona la herida con algo limpio,
INCIDENT_CUT_BAD_1,"Déjala sangrar, se limpia sola",
INCIDENT_CUT_BAD_2,Échale tierra para que se seque,
INCIDENT_ANKLE,Pisé mal y me doblé el tobillo. Me duele caleta.,
INCIDENT_ANKLE_OK,Siéntate y véndalo firme,
INCIDENT_ANKLE_BAD_1,"Sigue corriendo, se te pasa solo",
INCIDENT_ANKLE_BAD_2,Sácate la zapatilla y camina descalzo,
INCIDENT_SOAKED,Me caí al agua. Estoy empapado y tiritando.,
INCIDENT_SOAKED_OK,Sácate lo mojado y abrígate,
INCIDENT_SOAKED_BAD_1,Quédate quieto hasta que se seque,
INCIDENT_SOAKED_BAD_2,Métete de nuevo para acostumbrarte,
INCIDENT_BUMP,Me pegué con una rama en la cabeza. Estoy medio mareado.,
INCIDENT_BUMP_OK,Siéntate y respira un rato,
INCIDENT_BUMP_BAD_1,Corre para despertarte,
INCIDENT_BUMP_BAD_2,Acuéstate a dormir ahí mismo,
INCIDENT_THORN,Se me enterró una espina en la pierna.,
INCIDENT_THORN_OK,Sácala con cuidado y límpiate,
INCIDENT_THORN_BAD_1,"Déjala, ya saldrá sola",
INCIDENT_THORN_BAD_2,Quiébrala para que no moleste,
INCIDENT_GOOD,"Buena, Mati. Ya estoy mejor.",
INCIDENT_BAD,¡Auch! Eso fue peor. Me duele todo.,
INCIDENT_NO_ANSWER,¿Mati? No me contestaste y se puso peor.,
```

En `data/text/ui.csv`, reemplazar:

```csv
TUTORIAL_OPEN_CURTAINS,"Cerradas, Sanity baja de a poco y no oyes si sigue afuera. Ábrelas con un clic para revisar: si sigue ahí, vuelve a cerrarlas.",
```

por:

```csv
TUTORIAL_OPEN_CURTAINS,"Cerradas, Sanity baja de a poco y no oyes si sigue afuera. Ábrelas con un clic para revisar: si sigue ahí, vuelve a cerrarlas.",
CHAT_INCIDENT_HINT,¿Qué le dices?,
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	_check_decoys(errors, catalog, entities)
	return errors
```

por:

```gdscript
	_check_decoys(errors, catalog, entities)
	_check_incidents(errors, catalog)
	return errors


## Los accidentes: ids únicos, una buena idea y 1 o 2 malas. Una noche que pide accidentes necesita que existan.
static func _check_incidents(errors: Array[String], catalog: ContentCatalog) -> void:
	if catalog.incidents.has(null):
		errors.append("Catálogo: hay un espacio vacío en 'incidents'")
		return
	_check_unique_ids(errors, "Catálogo", "accidentes", catalog.incidents)
	for incident: IncidentData in catalog.incidents:
		if incident.wrong_keys.size() < 1 or incident.wrong_keys.size() > 2:
			errors.append("Accidente '%s': necesita 1 o 2 malas ideas" % incident.id)
	if not catalog.incidents.is_empty():
		return
	for night: NightData in catalog.nights:
		if night.incident_count > 0:
			errors.append("Catálogo: la noche %d pide accidentes y el catálogo no tiene" % night.number)
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
		keys.append(["Saludo %d" % (index + 1), catalog.greeting_keys[index]])
```

por:

```gdscript
		keys.append(["Saludo %d" % (index + 1), catalog.greeting_keys[index]])
	for incident: IncidentData in catalog.incidents:
		var where := "Accidente '%s'" % incident.id
		keys.append([where + ", mensaje", incident.message_key])
		keys.append([where + ", buena idea", incident.correct_key])
		for wrong_key: String in incident.wrong_keys:
			keys.append([where + ", mala idea", wrong_key])
```

`scripts/core/friend_incident.gd`:

```gdscript
extends RefCounted
## Un accidente en curso (decisión de Benja, 7 de noviembre): el amigo espera una respuesta de sentido común
## durante unos segundos. Lógica pura: RequestManager lo avanza y el chat muestra sus opciones.

var friend_index := 0
var data: IncidentData
## Las opciones, barajadas: claves de messages.csv.
var options: Array[String] = []
## Segundos que quedan para responder.
var time_left := 0.0


func _init(incident: IncidentData, friend: int, seconds: float, rng: RandomNumberGenerator) -> void:
	data = incident
	friend_index = friend
	time_left = seconds
	options.append(incident.correct_key)
	options.append_array(incident.wrong_keys)
	for index in range(options.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := options[index]
		options[index] = options[other]
		options[other] = swap


func advance(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)


func is_out_of_time() -> bool:
	return time_left <= 0.0


## La opción `index` es la buena idea.
func is_correct(index: int) -> bool:
	return options[index] == data.correct_key
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
const DAMAGE_KEY := "CHAT_DAMAGE"
```

por:

```gdscript
const DAMAGE_KEY := "CHAT_DAMAGE"
## Cómo le fue con un accidente: una buena idea, una mala o sin respuesta (messages.csv).
const INCIDENT_GOOD_KEY := "INCIDENT_GOOD"
const INCIDENT_BAD_KEY := "INCIDENT_BAD"
const INCIDENT_NO_ANSWER_KEY := "INCIDENT_NO_ANSWER"
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript


## El amigo avisa que mandó un video, que espera su descarga.
```

por:

```gdscript


## El amigo cuenta su accidente.
static func incident(data: IncidentData, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(ChatMessage.Sender.FRIEND, null)
	message.add_fragment(_text(translate, data.message_key))
	return message


## Una línea del amigo o de Matías, sin solicitud: la opción elegida o cómo le fue en un accidente.
static func line(sender: ChatMessage.Sender, key: String, translate: Callable) -> ChatMessage:
	var message := ChatMessage.new(sender, null)
	message.add_fragment(_text(translate, key))
	return message


## El amigo avisa que mandó un video, que espera su descarga.
```

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
		videos.add_extra(friend_index, elapsed)
```

por:

```gdscript
		videos.add_extra(friend_index, elapsed)


## Un accidente hirió al amigo `friend_index`: pierde vida y queda aturdido, sin que baje Trust.
func injure(friend_index: int) -> void:
	friends[friend_index].hurt(balance.incident_damage, balance.stun_seconds)
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
## guionado espera un momento sin solicitudes. Las reglas de justicia las revisa Screamer al elegir cuál.
```

por:

```gdscript
## guionado espera un momento sin solicitudes. Las reglas de justicia las revisa Screamer al elegir cuál.
## Los accidentes también se reparten en la noche (decisión de Benja, 7 de noviembre).
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
var last_scare := -INF
```

por:

```gdscript
var last_scare := -INF
## Las horas de los accidentes que faltan, en orden.
var incident_times: Array[float] = []
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
		scripted_scare_time = night.scripted_scare_time
```

por:

```gdscript
		scripted_scare_time = night.scripted_scare_time
	incident_times = plan_scares(night.incident_count, balance, rng)
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript


## Toca el susto guionado: llegó su hora y no hay solicitudes activas.
```

por:

```gdscript


## Toca un accidente: llegó su hora.
func incident_due(now: float) -> bool:
	return not incident_times.is_empty() and now >= incident_times[0]


## Empezó el accidente que tocaba.
func incident_started() -> void:
	incident_times.pop_front()


## Toca el susto guionado: llegó su hora y no hay solicitudes activas.
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var no_answer_trust := -15.0
```

por:

```gdscript
@export var no_answer_trust := -15.0

@export_group("Accidentes")
## Segundos para responder un accidente (decisión de Benja, 7 de noviembre).
@export var incident_seconds := 15.0
## Vida que le quita al amigo una mala respuesta o no responder. No baja Trust: un accidente no es culpa de Matías.
@export var incident_damage := 1
```

En `scripts/data/content_catalog.gd`, reemplazar:

```gdscript
@export var greeting_keys: Array[String] = []
```

por:

```gdscript
@export var greeting_keys: Array[String] = []
## Los accidentes que les pueden pasar a los amigos (decisión de Benja, 7 de noviembre).
@export var incidents: Array[IncidentData] = []
```

`scripts/data/incident_data.gd`:

```gdscript
class_name IncidentData
extends Resource
## Un accidente de un amigo: se tropieza, se corta o se cae al agua (decisión de Benja, 7 de noviembre). No tiene
## entidad ni cuaderno: se responde con sentido común, entre una buena idea y 1 o 2 malas.

@export var id: StringName
## Lo que escribe el amigo (messages.csv).
@export var message_key: String
## La respuesta que lo salva, en messages.csv.
@export var correct_key: String
## Las malas ideas, en messages.csv: 1 o 2.
@export var wrong_keys: Array[String] = []
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var wave_size := 3
```

por:

```gdscript
@export var wave_size := 3

## Accidentes de la noche: un amigo se tropieza o se corta, y se responde con sentido común (decisión de Benja, 7
## de noviembre).
@export var incident_count := 0
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## un chat guionado) o la descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le
```

por:

```gdscript
## un accidente o un chat guionado) o la descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
		var request := _requests.requests[index]
```

por:

```gdscript
		var request := _requests.requests[index]
		var incident := _requests.incidents[index]
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
		elif request != null or offer != null or _requests.chat_script_reply(index) != null:
```

por:

```gdscript
		elif request != null or incident != null or offer != null or _requests.chat_script_reply(index) != null:
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
			entry.set_seconds_left(ceili(request.time_left))
```

por:

```gdscript
			entry.set_seconds_left(ceili(request.time_left))
		elif incident != null:
			entry.set_seconds_left(ceili(incident.time_left))
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## herido (decisión de Benja).
```

por:

```gdscript
## herido (decisión de Benja).
## Desde el Plan 9, también los accidentes de los amigos: se responden en el chat, sin cuaderno, y una mala
## respuesta los hiere (decisión de Benja, 7 de noviembre).
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
const Consequence := preload("res://scripts/core/consequence.gd")
```

por:

```gdscript
const Consequence := preload("res://scripts/core/consequence.gd")
const FriendIncident := preload("res://scripts/core/friend_incident.gd")
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
var requests: Array[FriendRequest] = []
```

por:

```gdscript
var requests: Array[FriendRequest] = []
## El accidente en curso de cada amigo, o null.
var incidents: Array[FriendIncident] = []
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		requests.append(null)
```

por:

```gdscript
		requests.append(null)
		incidents.append(null)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
			_decide_alone(index)
```

por:

```gdscript
			_decide_alone(index)
	_advance_incidents(delta)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		_maybe_start_request()
```

por:

```gdscript
		_maybe_start_request()
		_maybe_start_incident()
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una, si no está disponible
## (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la opción
## "Temporizadores ×1,5", más largo.
```

por:

```gdscript
## Empieza una solicitud para el amigo `friend_index`. Devuelve null si ya tiene una o un accidente, si no está
## disponible (aturdido o muerto) o si no hay entidades. Con Trust bajo, el temporizador es más corto, y con la
## opción "Temporizadores ×1,5", más largo.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	if requests[friend_index] != null or not state.is_available(friend_index):
```

por:

```gdscript
	if not _is_free(friend_index):
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request

```

por:

```gdscript
	_add_friend_message(friend_index, MessageBuilder.first_message(request, tr))
	return request


## Empieza un accidente al azar para el amigo `friend_index`. Devuelve null si no puede tenerlo: tiene que estar
## libre y con señal, y con vida de sobra, porque un accidente nunca mata a un amigo.
func start_incident(friend_index: int) -> FriendIncident:
	if not _can_have_incident(friend_index) or catalog.incidents.is_empty():
		return null
	var data := catalog.incidents[rng.randi_range(0, catalog.incidents.size() - 1)]
	var incident := FriendIncident.new(data, friend_index, catalog.balance.incident_seconds * timer_scale, rng)
	incidents[friend_index] = incident
	_add_friend_message(friend_index, MessageBuilder.incident(data, tr))
	return incident


## Matías responde el accidente con la opción `option`. Devuelve false si el amigo no espera respuesta o está sin
## señal.
func answer_incident(friend_index: int, option: int) -> bool:
	var incident := incidents[friend_index]
	if incident == null or not state.friends[friend_index].is_online():
		return false
	message_added.emit(friend_index, MessageBuilder.line(ChatMessage.Sender.PLAYER, incident.options[option], tr))
	if incident.is_correct(option):
		incidents[friend_index] = null
		_add_friend_message(friend_index, MessageBuilder.line(ChatMessage.Sender.FRIEND, MessageBuilder.INCIDENT_GOOD_KEY, tr))
	else:
		_incident_hurts(friend_index, MessageBuilder.INCIDENT_BAD_KEY)
	return true

```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
```

por:

```gdscript


## El amigo no tiene ni solicitud ni accidente, y está disponible.
func _is_free(friend_index: int) -> bool:
	return requests[friend_index] == null and incidents[friend_index] == null and state.is_available(friend_index)


func _can_have_incident(friend_index: int) -> bool:
	var friend := state.friends[friend_index]
	return _is_free(friend_index) and friend.is_online() and friend.health > catalog.balance.incident_damage


## Avanza los accidentes. Si a uno se le acaba el tiempo, el amigo sale herido.
func _advance_incidents(delta: float) -> void:
	for index in incidents.size():
		var incident := incidents[index]
		if incident == null:
			continue
		incident.advance(delta)
		if incident.is_out_of_time():
			_incident_hurts(index, MessageBuilder.INCIDENT_NO_ANSWER_KEY)


## Termina el accidente con el amigo herido: lo cuenta y el juego avisa cuánta vida le queda. Las solicitudes que
## faltan se atrasan, como con cualquier amigo herido.
func _incident_hurts(friend_index: int, reaction_key: String) -> void:
	incidents[friend_index] = null
	state.injure(friend_index)
	director.friend_hurt()
	_add_friend_message(friend_index, MessageBuilder.line(ChatMessage.Sender.FRIEND, reaction_key, tr))
	var friend := state.friends[friend_index]
	var friend_name := tr(catalog.friends[friend_index].name_key)
	message_added.emit(friend_index, MessageBuilder.damage_notice(null, friend_name, friend.health, friend.max_health, tr))


## Sin respuesta a tiempo, el amigo elige solo y cuenta qué hizo y cómo le fue. Si está sin señal, elige mal
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		if requests[index] == null and state.is_available(index):
```

por:

```gdscript
		if _is_free(index):
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		director.request_started(_elapsed)
```

por:

```gdscript
		director.request_started(_elapsed)


## Cuando el director lo pide, a un amigo libre al azar le pasa un accidente. Si la ola está llena o nadie puede
## tenerlo, espera.
func _maybe_start_incident() -> void:
	if not director.incident_due(_elapsed) or active_count() >= night().max_simultaneous:
		return
	var free_friends: Array[int] = []
	for index in requests.size():
		if _can_have_incident(index):
			free_friends.append(index)
	if free_friends.is_empty():
		return
	if start_incident(free_friends[rng.randi_range(0, free_friends.size() - 1)]) != null:
		director.incident_started()
```

En `scripts/desk/screamer_manager.gd`, reemplazar:

```gdscript
	for request: RefCounted in _requests.requests:
		if request != null:
			time_lefts.append(request.time_left)
```

por:

```gdscript
	for pending: Array in [_requests.requests, _requests.incidents]:
		for item: RefCounted in pending:
			if item != null:
				time_lefts.append(item.time_left)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
```

por:

```gdscript
## pestañas y las preguntas van en mayúsculas (decisión de Benja, 31-oct).
## Un accidente se responde aquí mismo, con sus opciones en los botones de respuesta, sin cuaderno (decisión de
## Benja, 7 de noviembre).
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
const OFFLINE_KEY := "CHAT_OFFLINE"
```

por:

```gdscript
const OFFLINE_KEY := "CHAT_OFFLINE"
## Sobre las opciones de un accidente (ui.csv).
const INCIDENT_HINT_KEY := "CHAT_INCIDENT_HINT"
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	var request := _manager.requests[index]
```

por:

```gdscript
	var request := _manager.requests[index]
	var incident := _manager.incidents[index]
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
		text += "  %d" % ceili(request.time_left)
```

por:

```gdscript
		text += "  %d" % ceili(request.time_left)
	elif incident != null:
		text += "  %d" % ceili(incident.time_left)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
		return
	var page := _memory.page_for(selected_friend)
	var online := _manager.state.friends[selected_friend].is_online()
```

por:

```gdscript
		return
	var online := _manager.state.friends[selected_friend].is_online()
	var incident := _manager.incidents[selected_friend]
	if incident != null:
		_show_incident_options(incident.options, online)
		return
	var page := _memory.page_for(selected_friend)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
		button.disabled = not waiting
```

por:

```gdscript
		button.disabled = not waiting


## Las opciones de un accidente, en los botones de respuesta. Sin señal, el amigo no las lee.
func _show_incident_options(options: Array[String], online: bool) -> void:
	_answers.visible = true
	_answer_hint.text = tr(INCIDENT_HINT_KEY) if online else tr(OFFLINE_KEY).format({"friend": _friend_names[selected_friend]})
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		button.visible = index < options.size()
		if button.visible:
			button.text = tr(options[index])
		button.disabled = not online
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
## Responde con la acción `index` de la página abierta para este amigo.
func _on_answer_pressed(index: int) -> void:
```

por:

```gdscript
## Responde el accidente del amigo o, si no tiene, con la acción `index` de la página abierta para él.
func _on_answer_pressed(index: int) -> void:
	if _manager.incidents[selected_friend] != null:
		_manager.answer_incident(selected_friend, index)
		return
```

- [ ] **Paso 4: Verificar que pasan**

Esperado: `521 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add -A
git commit -m "Accidentes: se responden con sentido común, sin cuaderno"
```

---

### Tarea 11: Documentos, capturas y cierre

**Archivos:**

- Crear: `test/capture_plan9.gd`
- Modificar: `CLAUDE.md`, `spook_dial_design.md`, `docs/02_bucle_central.md`, `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/17_ideas_dinamismo.md`, `arte_pendiente.md`, `sonidos_pendiente.md`, `tools/make_placeholder_sounds.py`, `resumen.md`, `docs/00_log.md`

- [ ] **Paso 1: Actualizar los documentos y agregar las capturas**

En `CLAUDE.md`, reemplazar:

```markdown
| `docs/16_plan_feedback_1.md` | Plan 8.1: el feedback de la primera prueba (la criatura en la ventana, las noches 1 y 2, Audio Sync en rondas, Trust y los diales). |
```

por:

```markdown
| `docs/16_plan_feedback_1.md` | Plan 8.1: el feedback de la primera prueba (la criatura en la ventana, las noches 1 y 2, Audio Sync en rondas, Trust y los diales). |
| `docs/17_ideas_dinamismo.md` | Las notas de la prueba del 7-nov, ordenadas y con sus decisiones: de aquí sale el Plan 9. |
| `docs/18_plan_dinamismo.md` | Plan 9, paso a paso: las barras, la dificultad, los audios, la batería, las cortinas y los accidentes. |
```

En `CLAUDE.md`, reemplazar:

```markdown
| 04-11-2026 | **Los diales se explican en la noche 0:** el primer aviso del tutorial dice qué es cada uno, con un botón "Entendido". No hay letreros ni avisos de cambio por ahora. |
```

por:

```markdown
| 04-11-2026 | **Los diales se explican en la noche 0:** el primer aviso del tutorial dice qué es cada uno, con un botón "Entendido". No hay letreros ni avisos de cambio por ahora. |
| 07-11-2026 | **Barras arriba de la pantalla:** Connection, Sanity y Trust también se ven como barras, cada una con su color, en el hueco entre el chat y el cuaderno, que no las tapan. Los diales de la pared se quedan. |
| 07-11-2026 | **Acertar es más difícil:** menos tiempo por noche (80, 65, 55, 45 y 40 s), sin pista inicial desde la noche 3 y más señuelos (1, 2, 3, 3 y 4). Desde la noche 3 hay entidades que comparten 2 características. |
| 07-11-2026 | **Audios en «¿Qué oyes?»:** cada entidad tiene una observación que el amigo manda como audio, y el jugador la escucha con un clic en el chat. Lo que se oye cambia la acción correcta (1, 3 o ningún grito del Tue Tué no son lo mismo; que La Calchona bale o bufe, tampoco). Las características siguen siendo texto clickeable. Se pueden repetir gratis, la estática puede tapar el audio (hay que volver a preguntar) y mientras suena no empiezan screamers ni alucinaciones. Opción "Subtítulos de los audios". |
| 07-11-2026 | **Audio Sync más rápido:** la base sube noche a noche (90, 100, 115, 130 y 145 golpes por minuto), y la segunda ronda va un 15 % más rápida que la primera. |
| 07-11-2026 | **El celular tiene batería:** un tope por noche, sin recarga, que alcanza para unos 38 s de scroll. Sin batería no hay feed. |
| 07-11-2026 | **Las cortinas se abren y se cierran con un clic.** Cerradas, el cuarto se oscurece y Sanity baja de a poco; abiertas, no pasa nada, salvo que haya algo afuera. |
| 07-11-2026 | **La criatura se queda un tiempo fijo** (25 s) y reemplaza a la decisión del 4-nov en lo que dura: mientras esté afuera con la cortina abierta, Sanity baja rápido. Si la cortina estaba cerrada, la abre al llegar. Cerrarla no la espanta y con la cortina cerrada no se oye, así que hay que abrirla para revisar si sigue ahí. Llega más veces: 1, 2, 2 y 3 en las noches 2 a 5. |
| 07-11-2026 | **El screamer de la cortina** ya no la mece: la cortina se abre o se cierra sola. |
| 07-11-2026 | **Accidentes:** un amigo se tropieza o se corta sin que nadie tenga la culpa (1, 1, 2, 2 y 3 por noche). Se responde en el chat con sentido común, sin cuaderno, en 15 s. Una mala respuesta o no contestar le quita 1 de vida y lo aturde, sin bajar Trust. Nunca matan a un amigo. |
| 07-11-2026 | **La historia con decisiones y editar los videos quedan para después** de hacer divertidas las mecánicas (`docs/05`, puntos 21 y 22). |
```

En `arte_pendiente.md`, reemplazar:

```markdown
| Animación `scare` de las cortinas | Plan 7 | Un screamer ambiental (3 a 6 frames). Mientras tanto, Godot mece la cortina entera. |
```

por:

```markdown
| Animación de las cortinas al abrirse y cerrarse | Plan 9 | Opcional. Hoy cambian de golpe entre `Open` y `Closed`, los 2 estados que dibujó Benja. |
| Las barras de Connection, Sanity y Trust | Plan 9 | Opcional. 300×54 px, arriba al centro. Hoy las dibuja Godot con rectángulos (`scripts/ui/stat_bars.gd`). |
| La batería del celular del escritorio | Plan 9 | Opcional. Hoy es una barrita verde bajo la hora (`DeskPlane/Phone/BatteryBar`). |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Tiempo base para responder (s) | 85 | 80 | 75 | 70 | 65 |
| Probabilidad de pista en el mensaje inicial | 100 % | 75 % | 50 % | 35 % | 20 % |
| Señuelos por solicitud | 1 | 1 | 2 | 2 | 3 |
```

por:

```markdown
| Tiempo base para responder (s) | 80 | 65 | 55 | 45 | 40 |
| Probabilidad de pista en el mensaje inicial | 100 % | 75 % | 0 % | 0 % | 0 % |
| Señuelos por solicitud | 1 | 2 | 3 | 3 | 4 |
| Accidentes por noche | 1 | 1 | 2 | 2 | 3 |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Audio Sync (aplausos; 8 son 2 rondas de 4) | 4 | 4 | 4 | 8 | 8 |
```

por:

```markdown
| Audio Sync (aplausos; 8 son 2 rondas de 4) | 4 | 4 | 4 | 8 | 8 |
| Audio Sync (golpes por minuto de la base) | 90 | 100 | 115 | 130 | 145 |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Uno de ellos es la criatura de la ventana (el antiguo jumpscare) | No | Sí | Sí | Sí | Sí |
```

por:

```markdown
| Cuántos de ellos son la criatura de la ventana (el antiguo jumpscare) | 0 | 1 | 2 | 2 | 3 |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Sanity | 100 | −1 cada 6 s (N1: cada 10 s). Screamer: −8 ambiental, −15 la criatura de la ventana. | +4 por segundo mientras scrolleas | Viñeta oscura y screamers auditivos falsos, más fuertes cuanto más baja | Se pierde la noche |
```

por:

```markdown
| Sanity | 100 | −1 cada 6 s (N1: cada 10 s). Screamer: −8 ambiental, −15 la criatura de la ventana. Cortinas cerradas: −0,3 por segundo más. Criatura afuera con la cortina abierta: −2 por segundo más. | +4 por segundo mientras scrolleas, con batería (38 s de scroll por noche, sin recarga) | Viñeta oscura y screamers auditivos falsos, más fuertes cuanto más baja | Se pierde la noche |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
| Vida (cada amigo) | 3 PV | Ver §5.2 | No se recupera durante la noche | Avatar herido | Muere y se pierde la noche |
```

por:

```markdown
| Vida (cada amigo) | 3 PV | Ver §5.2. Accidente mal respondido o sin respuesta: −1 PV, sin bajar Trust. | No se recupera durante la noche | Avatar herido | Muere y se pierde la noche |
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
- Audio Sync: una base de 100 golpes por minuto. Tras un compás de cuenta, el amigo aplaude 4 veces en corcheas (el primer aplauso al comienzo) y Matías lo repite en el compás siguiente. Las noches de 8 aplausos son 2 rondas de 4 seguidas, cada una con su cuenta y su patrón; si se falla la segunda, se vuelve a la primera con patrones nuevos (decisión de Benja, 4 de noviembre). Tolerancia de cada golpe: ±150 ms.
```

por:

```markdown
- Audio Sync: la base va en los golpes por minuto de cada noche, y cada ronda va un 15 % más rápida que la anterior. Tras un compás de cuenta, el amigo aplaude 4 veces en corcheas (el primer aplauso al comienzo) y Matías lo repite en el compás siguiente. Las noches de 8 aplausos son 2 rondas de 4 seguidas, cada una con su cuenta y su patrón; si se falla la segunda, se vuelve a la primera con patrones nuevos (decisión de Benja, 4 de noviembre). Tolerancia de cada golpe: ±150 ms.
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
  - nunca empiezan si a una decisión le quedan 5 s o menos al terminar la señal previa (la mancha de tinta, que tapa las reglas 5 s, necesita 5 s más), ni durante una ronda de Audio Sync;
```

por:

```markdown
  - nunca empiezan si a una decisión o a un accidente le quedan 5 s o menos al terminar la señal previa (la mancha de tinta, que tapa las reglas 5 s, necesita 5 s más), ni durante una ronda de Audio Sync o un audio de un amigo;
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
  - la criatura de la ventana (el antiguo jumpscare) solo se arma con el chat o el mixer abiertos, que tapan la ventana; se ve apenas se cierran y se queda 4 s. No tapa nada ni pausa la noche (decisión de Benja, 4 de noviembre).
- Alucinaciones (decisión de Benja, sesión 16): con Sanity bajo 50, una cada 40 s, y cada vez más seguidas hasta una cada 10 s con Sanity en 0 (±25 % al azar); más fuertes mientras más baja. No restan Sanity y no suenan durante Audio Sync ni durante un screamer.
```

por:

```markdown
  - la criatura de la ventana (el antiguo jumpscare) solo se arma con el chat o el mixer abiertos, que tapan la ventana; se ve apenas se cierran y se queda 25 s desde que llega, aunque se cierren las cortinas. No tapa nada ni pausa la noche (decisiones de Benja, 4 y 7 de noviembre).
- Alucinaciones (decisión de Benja, sesión 16): con Sanity bajo 50, una cada 40 s, y cada vez más seguidas hasta una cada 10 s con Sanity en 0 (±25 % al azar); más fuertes mientras más baja. No restan Sanity y no suenan durante Audio Sync, un audio de un amigo ni un screamer.
- Accidentes (decisión de Benja, 7 de noviembre): se reparten en la noche como los screamers, 15 s para responder (22,5 s con "Temporizadores ×1,5"). Solo le pasan a un amigo libre, con señal y con más de 1 PV; si la ola está llena, esperan.
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
ObservationData  id, category, question_key (la pregunta en el cuaderno),
```

por:

```markdown
IncidentData     id, message_key, correct_key, wrong_keys (1 o 2): un accidente, en ContentCatalog.incidents
ObservationData  id, category, audio_values (valor → audio; solo en "¿Qué oyes?"), question_key (la pregunta en el cuaderno),
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
                 scare_count, has_jumpscare,
```

por:

```markdown
                 scare_count, creature_visits, incident_count, audio_sync_bpm,
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
| **G.** Probar las solicitudes y el chat (Plan 3) | ⬜ Pendiente (unos 10 minutos) |
```

por:

```markdown
| **G.** Probar las solicitudes y el chat (Plan 3) | ⬜ Pendiente (unos 10 minutos) |
| **N.** Probar el dinamismo (Plan 9) | ⬜ Pendiente (unos 20 minutos) |
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
2. **La criatura en la ventana:** en la noche 2 o más, deja el chat de un amigo abierto cuando llegue el susto (se nota por la señal previa: las luces parpadean y baja el ambiente). Se oyen una respiración y golpes en el vidrio, pero no se ve nada. Cierra el chat: la criatura ya está en la ventana, y se va a los 4 s. No tapa la pantalla.
```

por:

```markdown
2. **La criatura en la ventana:** en la noche 2 o más, deja el chat de un amigo abierto cuando llegue el susto (se nota por la señal previa: las luces parpadean y baja el ambiente). Se oyen una respiración y golpes en el vidrio, pero no se ve nada. Cierra el chat: la criatura ya está en la ventana. No tapa la pantalla. (Desde el Plan 9 se queda 25 s: ver la sección N.)
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
- **Cuánto se queda la criatura:** `Creature Seconds` (4 s).
```

por:

```markdown
- **Cuánto se queda la criatura:** `Creature Seconds` (25 s desde el Plan 9).
```

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
- **Los sonidos de la criatura:** `sonidos_pendiente.md`.

```

por:

```markdown
- **Los sonidos de la criatura:** `sonidos_pendiente.md`.

## N. Probar el dinamismo (Plan 9)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez. Con **Nueva partida** o **Continuar**, según la noche que quieras ver.

1. **Las barras:** arriba, en el centro, están Connection, Sanity y Trust. Abre el chat y el cuaderno a la vez: se siguen viendo. Equivócate en una respuesta: Trust titila.
2. **Los audios:** en una solicitud, presiona **¿Qué oyes?**. El amigo manda **▶ Escuchar audio**: haz clic para oírlo, las veces que quieras. Abre la página de la entidad: lo que se oye cambia la regla que se aplica.
3. **Audio Sync:** en la noche 1 la base es lenta, y en la noche 5, bastante más rápida. En la noche 4 o 5, la ronda 2 va más rápida que la 1.
4. **La batería:** scrollea el celular: el porcentaje baja, y también la barrita verde del celular del escritorio. Con 0 %, dice "Sin batería" y Sanity ya no sube.
5. **Las cortinas:** haz clic en ellas: se cierran, el cuarto se oscurece y Sanity baja un poco más rápido. Otro clic las abre.
6. **La criatura:** desde la noche 2, con el chat abierto se oyen golpes. Ciérralo: la criatura está en la ventana y Sanity baja rápido. Cierra la cortina: deja de oírse. Ábrela: si sigue ahí, se ve y se oye; se va a los 25 s de llegar.
7. **La cortina sola:** a veces un screamer abre o cierra la cortina.
8. **Los accidentes:** un amigo escribe que se tropezó o se cortó. En su chat aparecen opciones, sin cuaderno, y tienes 15 s. Elige la mala a propósito: pierde 1 de vida y queda aturdido, pero Trust no baja.
9. **La noche 0:** el aviso ya no va pegado arriba, sino bajo las barras, y al final enseña las cortinas.

**Verifica:** los pasos 1 a 9 se cumplen. Si algo falla o se siente mal, anótalo.

### Para ajustar

- **Tiempo, pista, señuelos, accidentes y visitas de la criatura:** `data/nights/night_N.tres`, en el Inspector (`Base Decision Time`, `First Hint Chance`, `Decoys Per Request`, `Incident Count` y `Creature Visits`).
- **Audio Sync:** `Audio Sync Bpm` en cada noche, y `Audio Sync Round Speedup` en `data/balance.tres`.
- **La batería:** `Phone Battery Seconds` en `data/balance.tres` (38 s).
- **Las cortinas y la criatura:** `Closed Curtains Sanity` (0,3), `Creature Sanity` (2) y `Creature Seconds` (25).
- **Los accidentes:** `Incident Seconds` (15) e `Incident Damage` (1); sus textos, en `messages.csv` (`INCIDENT_*`).
- **Las reglas y los audios de cada entidad:** `data/entities/`, en el Inspector.

Si cambias un valor de `data/balance.tres` o de una noche a propósito, avísale a Claude: `test_balance.gd` lo compara con `docs/02`.

```

En `docs/06_plan_v1.md`, reemplazar:

```markdown
- El **Plan 9: dinamismo** tiene sus decisiones en `docs/17_ideas_dinamismo.md` y se escribe paso a paso en `docs/18_plan_dinamismo.md` (sesión S20).
```

por:

```markdown
- El **Plan 9: dinamismo** tiene sus decisiones en `docs/17_ideas_dinamismo.md` y está escrito paso a paso en `docs/18_plan_dinamismo.md` (ejecutado).
```

En `docs/17_ideas_dinamismo.md`, reemplazar:

```markdown
**Esto es un borrador de Claude, ya con todas las decisiones de diseño tomadas (7-nov).** Ordena las notas de Benja y las vuelve acciones concretas. Falta solo planificar las sesiones (§4) y actualizar `docs/05`.
```

por:

```markdown
**Las notas de Benja del 7 de noviembre, ordenadas y con sus decisiones.** Ya se volvieron plan: `docs/18_plan_dinamismo.md`, que además fija lo que aquí quedó abierto. Si algo no coincide, vale el plan.
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
**Cómo reemplazar uno:** copia tu archivo a `audio/sfx/` con **el mismo nombre** del que reemplaza (`.wav`, mono o estéreo) y vuelve a abrir el proyecto en Godot. No hay que tocar nada más: la escena lo carga por nombre. Si el sonido nuevo dura distinto, avísale a Claude, porque `test/test_placeholder_sounds.gd` anota cuántos segundos dura cada uno. **No corras `make_placeholder_sounds.py` después de poner los tuyos:** vuelve a escribir los provisionales encima.
```

por:

```markdown
**Cómo reemplazar uno:** copia tu archivo a `audio/sfx/` (los audios de los amigos, a `audio/clues/`) con **el mismo nombre** del que reemplaza (`.wav`, mono o estéreo) y vuelve a abrir el proyecto en Godot. No hay que tocar nada más: la escena lo carga por nombre. Si el sonido nuevo dura distinto, avísale a Claude, porque `test/test_placeholder_sounds.gd` anota cuántos segundos dura cada uno. **No corras `make_placeholder_sounds.py` después de poner los tuyos:** vuelve a escribir los provisionales encima.
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
## Primero: la criatura en la ventana (4 de noviembre)
```

por:

```markdown
## Primero: los audios que mandan los amigos (7 de noviembre)
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
Reemplazan al grito del jumpscare. La criatura se asoma por la ventana cuando el chat o el mixer la tapan, y se ve al cerrarlos.
```

por:

```markdown
Están en `audio/clues/` y duran 3 s, con el lugar de fondo. **Son parte del juego:** hay que distinguirlos de oído, porque lo que se oye cambia la acción correcta. Si cambias uno, que se siga notando la diferencia con los otros de su entidad. Duran 3 s para que `test_placeholder_sounds.gd` los acepte; si los tuyos duran otra cosa, avísale a Claude.

| Archivo | Se tiene que oír |
| --- | --- |
| `tue_tue_cries_one.wav` | El grito de dos notas, una vez |
| `tue_tue_cries_three.wav` | El grito de dos notas, tres veces |
| `tue_tue_cries_none.wav` | Solo el lugar: ningún grito |
| `calchona_bleat_tone_weeping.wav` | Una oveja balando como si llorara |
| `calchona_bleat_tone_snorting.wav` | Bufidos fuertes, como enojada |
| `cuero_whistle_yes.wav` | Agua y un silbido agudo, como si alguien llamara |
| `cuero_whistle_no.wav` | Solo agua |
| `viuda_heels_slow.wav` | Pasos de taco lentos |
| `viuda_heels_fast.wav` | Pasos de taco rápidos |
| `trauco_ground_muddy.wav` | Pasos que chapotean en el barro |
| `trauco_ground_dry.wav` | Pasos que crujen en tierra seca |
| `basilisco_crows_once.wav` | Un canto de gallo apagado, una vez |
| `basilisco_crows_twice.wav` | El mismo canto, dos veces |
| `imbunche_called_name_yes.wav` | Gruñidos roncos y, entre ellos, una voz que dice "Matías" |
| `imbunche_called_name_no.wav` | Solo gruñidos roncos |

## La criatura en la ventana (4 de noviembre)

Reemplazan al grito del jumpscare. La criatura se asoma por la ventana cuando el chat o el mixer la tapan, y se ve al cerrarlos. Se queda 25 s desde que llega; con la cortina cerrada no se oye.
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
| `scare_creature_breathing.wav` | 8 s | Desde que la criatura llega (bajito, detrás del panel) y más fuerte cuando se ve. Se corta a los 4 s de verse. | Respiración pesada y ronca, de algo grande al otro lado del vidrio. |
| `scare_creature_knocks.wav` | 7 s | Al llegar la criatura, mientras el panel está abierto. | Golpeteos en el vidrio, en tandas que se vuelven más fuertes. Los golpes caen en 0,6 s, 1,1 s, 2,9 s, 3,35 s, 3,8 s, 5,4 s, 5,8 s, 6,2 s y 6,5 s del archivo. |
```

por:

```markdown
| `scare_creature_breathing.wav` | 8 s | Desde que la criatura llega (bajito, detrás del panel) y más fuerte cuando se ve. Se repite mientras esté afuera con la cortina abierta. | Respiración pesada y ronca, de algo grande al otro lado del vidrio. |
| `scare_creature_knocks.wav` | 7 s | Al llegar la criatura, y se repite mientras un panel la tape. | Golpeteos en el vidrio, en tandas que se vuelven más fuertes. Los golpes caen en 0,6 s, 1,1 s, 2,9 s, 3,35 s, 3,8 s, 5,4 s, 5,8 s, 6,2 s y 6,5 s del archivo. |
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
| `scare_curtains.wav` | 1,2 s | Las cortinas se mecen | Roce de tela |
```

por:

```markdown
| `scare_curtains.wav` | 1,2 s | Las cortinas se abren o se cierran: con un clic, solas o porque las abre la criatura | Roce de tela |
```

En `sonidos_pendiente.md`, reemplazar:

```markdown
Son del Plan 9 (sonido y pulido):
```

por:

```markdown
Son del Plan 10 (sonido y pulido):
```

En `spook_dial_design.md`, reemplazar:

```markdown
Última actualización: 4 de noviembre de 2026.
```

por:

```markdown
Última actualización: 7 de noviembre de 2026.
```

En `spook_dial_design.md`, reemplazar:

```markdown
- 4 de noviembre (después de probar el Plan 8): la criatura se asoma por la ventana en lugar del jumpscare (se arma detrás del chat o el mixer), las noches 1 y 2 con más sucesos, Audio Sync de 8 aplausos en 2 rondas de 4, Trust que también baja si tardas en contestar y los diales explicados en la noche 0.
```

por:

```markdown
- 4 de noviembre (después de probar el Plan 8): la criatura se asoma por la ventana en lugar del jumpscare (se arma detrás del chat o el mixer), las noches 1 y 2 con más sucesos, Audio Sync de 8 aplausos en 2 rondas de 4, Trust que también baja si tardas en contestar y los diales explicados en la noche 0.
- 7 de noviembre (notas de prueba, `docs/17`): las barras arriba de la pantalla, acertar más difícil, los audios en «¿Qué oyes?», Audio Sync más rápido, la batería del celular, las cortinas, la criatura que se queda y hay que revisar, y los accidentes.
```

En `spook_dial_design.md`, reemplazar:

```markdown
| **Celular** | Muestra la hora. Al abrirlo se scrollea con la rueda del mouse para recuperar Sanity (§10). |
```

por:

```markdown
| **Celular** | Muestra la hora y su batería. Al abrirlo se scrollea con la rueda del mouse para recuperar Sanity (§10). |
```

En `spook_dial_design.md`, reemplazar:

```markdown
| **Ventana y cortinas** | Ambientación y blanco de screamers. |
```

por:

```markdown
| **Ventana y cortinas** | Las cortinas se abren y se cierran con un clic (§10.2). Por la ventana se asoma la criatura (§11). |
```

En `spook_dial_design.md`, reemplazar:

```markdown
## 7. Interfaz

- **El PC siempre muestra la lista** de las 3 entradas. La conversación abierta se ve destacada.
```

por:

```markdown
## 7. Interfaz

- **Barras arriba de la pantalla** (decisión de Benja, 7 de noviembre): Connection, Sanity y Trust, en el hueco entre el chat y el cuaderno, que no las tapan. Cada una tiene el color de su dial, titila si baja de golpe y prende una luz bajo 25.
- **El PC siempre muestra la lista** de las 3 entradas. La conversación abierta se ve destacada.
```

En `spook_dial_design.md`, reemplazar:

```markdown
Si el temporizador llega a 0, el amigo decide solo (al azar entre sus 4 acciones) y la consecuencia se resuelve igual. Además baja Trust por no contestar. Un amigo sin señal también decide solo al acabarse su tiempo, pero elige mal (al azar entre las 3 acciones que no son la correcta), y esa decisión no baja Trust (§10.1).

## 9. Consecuencias
```

por:

```markdown
Si el temporizador llega a 0, el amigo decide solo (al azar entre sus 4 acciones) y la consecuencia se resuelve igual. Además baja Trust por no contestar. Un amigo sin señal también decide solo al acabarse su tiempo, pero elige mal (al azar entre las 3 acciones que no son la correcta), y esa decisión no baja Trust (§10.1).

### 8.8 Audios en «¿Qué oyes?»

Decisión de Benja, 7 de noviembre.

- Cada entidad tiene una observación que **el amigo manda como audio** en vez de contarla. Se escucha con un clic en el mensaje, las veces que se quiera: lo único que cuesta es el tiempo que pasa.
- **Lo que se oye cambia la acción correcta:** que El Tue Tué grite 1 vez, 3 veces o ninguna son casos distintos, y que La Calchona bale o bufe, también. Las reglas del cuaderno lo dicen.
- Las características que se oyen siguen siendo texto clickeable: el audio no identifica a la entidad.
- La estática tapa el audio entero o no lo tapa (§8.2). Tapado no se puede escuchar: hay que volver a preguntar.
- La opción "Subtítulos de los audios" (§19) muestra qué se oye.

### 8.9 Accidentes

Decisión de Benja, 7 de noviembre.

- Un amigo puede tener un accidente sin que nadie tenga la culpa: se tropieza, se corta o se cae al agua. Son 1, 1, 2, 2 y 3 por noche, y no hay en la noche 0.
- Se responde en el chat, en 15 s, con las opciones del accidente, sin cuaderno: una buena idea y 1 o 2 malas, que se eligen con sentido común.
- Una mala respuesta o no contestar le quita 1 de vida y lo deja aturdido, sin bajar Trust. La buena idea no le quita nada.
- Solo le pasa a un amigo libre, con señal y con más de 1 de vida: **un accidente nunca mata**. Si la ola está llena, espera.

## 9. Consecuencias
```

En `spook_dial_design.md`, reemplazar:

```markdown
- Se recupera **scrolleando el celular**: sube mientras el jugador scrollea y deja de subir cuando se detiene.
```

por:

```markdown
- Se recupera **scrolleando el celular**: sube mientras el jugador scrollea y deja de subir cuando se detiene.
- **El celular tiene batería** (decisión de Benja, 7 de noviembre): un tope por noche, sin recarga, que alcanza para unos 38 s de scroll (una vez y media la barra). Se gasta solo al scrollear. Sin batería no hay feed.
- **Las cortinas** (decisión de Benja, 7 de noviembre): se abren y se cierran con un clic. Cerradas, el cuarto se oscurece y Sanity baja de a poco. Abiertas no pasa nada, salvo que la criatura esté afuera (§11): entonces baja rápido.
```

En `spook_dial_design.md`, reemplazar:

```markdown
### 10.6 Audio Sync

- Se empieza cuando el jugador quiere, con un clic en el mixer, que se abre visto desde arriba. Se elige el canal del amigo en su fader, o con el botón «Sincronizar» del chat de ese amigo, que abre el mixer en su canal y empieza la ronda enseguida.
```

por:

```markdown
### 10.6 Audio Sync

- La base sube noche a noche (90, 100, 115, 130 y 145 golpes por minuto), y cada ronda va un 15 % más rápida que la anterior (decisión de Benja, 7 de noviembre).
- Se empieza cuando el jugador quiere, con un clic en el mixer, que se abre visto desde arriba. Se elige el canal del amigo en su fader, o con el botón «Sincronizar» del chat de ese amigo, que abre el mixer en su canal y empieza la ronda enseguida.
```

En `spook_dial_design.md`, reemplazar:

```markdown
  - ambientales: la cortina se mueve, aparece la figura en la ventana, el celular vibra, las luces parpadean. La figura de la ventana está escondida y solo aparece al asustar (decisión de Benja, sesión 16);
```

por:

```markdown
  - ambientales: la cortina se abre o se cierra sola (decisión de Benja, 7 de noviembre), aparece la figura en la ventana, el celular vibra, las luces parpadean. La figura de la ventana está escondida y solo aparece al asustar (decisión de Benja, sesión 16);
```

En `spook_dial_design.md`, reemplazar:

```markdown
  - **la criatura en la ventana** (antes, un jumpscare de pantalla completa; decisión de Benja, 4 de noviembre): como máximo **uno por noche**, desde la noche 2. Se asoma por la ventana con respiración pesada y golpes en el vidrio. Se arma solo cuando el chat o el mixer tapan la ventana, y al cerrarlos ya está ahí; se queda unos 4 segundos. No tapa la pantalla ni pausa la noche.
```

por:

```markdown
  - **la criatura en la ventana** (antes, un jumpscare de pantalla completa; decisión de Benja, 4 de noviembre): desde la noche 2 (1, 2, 2 y 3 veces por noche). Se asoma por la ventana con respiración pesada y golpes en el vidrio. Se arma solo cuando el chat o el mixer tapan la ventana, y al cerrarlos ya está ahí. No tapa la pantalla ni pausa la noche. **Se queda 25 s desde que llega** (decisión de Benja, 7 de noviembre): si la cortina estaba cerrada, la abre; mientras esté afuera con la cortina abierta, Sanity baja rápido. Cerrar la cortina no la espanta, y con la cortina cerrada no se oye, así que hay que abrirla para revisar si sigue ahí y volver a cerrarla si sigue.
```

En `spook_dial_design.md`, reemplazar:

```markdown
  - nunca ocurren en los últimos 5 segundos de una decisión.
```

por:

```markdown
  - nunca ocurren en los últimos 5 segundos de una decisión;
  - no empiezan mientras suena un audio de un amigo, para que no se confundan con él.
```

En `spook_dial_design.md`, reemplazar:

```markdown
| 0 (tutorial) | Alrededores de la cabaña | (usa las páginas de la noche 1) | Guiada y sin perder (§5): preguntar, identificar, responder desde el cuaderno y descargar un video. Al final, el susto guionado y su chat enseñan Sanity y el celular (§11). |
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust, ya sin ayuda. La señal baja un poco, con 1 interferencia y Audio Sync de 4 aplausos, y hay 2 screamers ambientales. El mensaje inicial siempre trae una pista. |
```

por:

```markdown
| 0 (tutorial) | Alrededores de la cabaña | (usa las páginas de la noche 1) | Guiada y sin perder (§5): preguntar, identificar, escuchar un audio, responder desde el cuaderno y descargar un video. Al final, el susto guionado y su chat enseñan las cortinas, Sanity y el celular (§11). |
| 1 | Alrededores de la cabaña | El Tue Tué, La Calchona | Solicitudes, reglas, recibir videos, cuota y Trust, ya sin ayuda. La señal baja un poco, con 1 interferencia y Audio Sync de 4 aplausos, y hay 2 screamers ambientales y 1 accidente. El mensaje inicial siempre trae una pista. |
```

En `spook_dial_design.md`, reemplazar:

```markdown
| 3 | Bosque | El Trauco | Mensajes con menos observaciones: preguntar se vuelve necesario. |
```

por:

```markdown
| 3 | Bosque | El Trauco | Sin pista en el mensaje inicial: preguntar es necesario. El Trauco comparte 2 características con La Calchona. |
```

En `spook_dial_design.md`, reemplazar:

```markdown
- Ninguna información crítica depende solo del color.
```

por:

```markdown
- Ninguna información crítica depende solo del color.
- **Subtítulos de los audios** (Plan 9, para quien no pueda oírlos): el mensaje con audio muestra qué se oye.
```

`test/capture_plan9.gd`:

```gdscript
extends SceneTree
## Capturas del Plan 9 para revisarlas a ojo. No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan9.gd -- /mnt/c/dev/capturas/plan9_hud.png /mnt/c/dev/capturas/plan9_audio.png /mnt/c/dev/capturas/plan9_curtains.png /mnt/c/dev/capturas/plan9_phone.png /mnt/c/dev/capturas/plan9_incident.png
## 1. Las barras con el cuaderno abierto: Sanity y Trust bajas.
## 2. El chat de León con un audio en la respuesta a "¿Qué oyes?".
## 3. Las cortinas cerradas, con el cuarto oscurecido.
## 4. El celular abierto con poca batería.
## 5. Un accidente en el chat, con sus opciones.

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
	desk.get_node("RequestManager").requests_arrive = false
	desk.get_node("RequestManager").random_seed = 21
	root.add_child(desk)
	return desk


func _capture() -> void:
	var desk := _desk(1)
	var state: NightState = desk.get_node("RequestManager").state
	state.sanity = 45.0
	state.trust = 20.0
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	await create_timer(0.3).timeout
	await _save(0)
	desk.free()
	desk = _desk(1)
	var manager := desk.get_node("RequestManager")
	manager.start_request(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	manager.ask(0, ClueCategory.Kind.SOUND)
	await create_timer(1.5).timeout
	await _save(1)
	desk.free()
	desk = _desk(2)
	desk.get_node("WallPlane/Curtains").clicked.emit()
	await create_timer(0.3).timeout
	await _save(2)
	desk.free()
	desk = _desk(1)
	state = desk.get_node("RequestManager").state
	state.battery = 15.0
	desk.open_phone()
	await create_timer(0.4).timeout
	await _save(3)
	desk.free()
	desk = _desk(1)
	manager = desk.get_node("RequestManager")
	manager.start_incident(0)
	desk.get_node("DeskPlane/Entries/EntryLeon").pressed.emit()
	await create_timer(1.5).timeout
	await _save(4)
	desk.free()
	await create_timer(0.2).timeout
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
Son de relleno, hasta que Benja elija los definitivos (Plan 9):
```

por:

```python
Son de relleno, hasta que Benja elija los definitivos (Plan 10):
```

- [ ] **Paso 2: Verificar que pasan**

Esperado: `521 pruebas OK, 0 fallidas`.

- [ ] **Paso 3: Revisar las capturas**

Corre con ventana, no con `--headless`:

```text
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan9.gd -- 'C:\dev\capturas\plan9_hud.png' 'C:\dev\capturas\plan9_audio.png' 'C:\dev\capturas\plan9_curtains.png' 'C:\dev\capturas\plan9_phone.png' 'C:\dev\capturas\plan9_incident.png'
```

Esperado:

- `plan9_hud.png`: las 3 barras arriba, con el cuaderno abierto al lado, sin taparse.
- `plan9_audio.png`: en el chat de León, "▶ Escuchar audio" en color turquesa.
- `plan9_curtains.png`: las cortinas cerradas tapan la ventana y el cuarto está más oscuro.
- `plan9_phone.png`: el celular abierto con "15%" en rojo y la barrita corta en el celular del escritorio.
- `plan9_incident.png`: el accidente en el chat, con "¿Qué le dices?" y 3 opciones.

- [ ] **Paso 4: Cerrar la sesión**

- `resumen.md`: entrada de la sesión (arriba del todo) con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar:
  - **probar el dinamismo** (`docs/04`, N, unos 20 minutos) y decir cómo se sienten la dificultad, las cortinas, la batería y los accidentes;
  - **escuchar los 15 audios** (`audio/clues/`) y poner los reales (`sonidos_pendiente.md`), porque hay que distinguirlos de oído;
  - **corregir las reglas de las 7 entidades** y los textos nuevos: `RULE_*`, `OBS_*`, `INCIDENT_*`, `HUD_*`, `TUTORIAL_*`, `CHAT_AUDIO`, `CHAT_INCIDENT_HINT`, `OPTIONS_AUDIO_CAPTIONS` y `PHONE_NO_BATTERY`;
  - **revisar los supuestos de este plan**, sobre todo que la criatura no se oiga con la cortina cerrada y que un accidente nunca mate.
- Arrastrar los pendientes que sigan abiertos. El pendiente de las ayudas para los diales ya se cumplió con las barras.
- `docs/00_log.md`: S21 ✅, con la fecha real, y S22 (correcciones tras las pruebas con personas) como siguiente, con su tabla al inicio del registro. `docs/18_plan_dinamismo.md` pasa a "Ya ejecutado (S21) ✅".

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add -A
git commit -m "Plan 9 terminado: dinamismo"
```

---

## Fuera de este plan, a propósito

- **La historia con decisiones y los amigos incrédulos** (notas 3 y 6): después de que las mecánicas se sientan bien (`docs/05`, punto 22). Choca con la regla 9 de `CLAUDE.md`.
- **Editar los videos** (nota 5): se decide al probar si sigue faltando algo que hacer (`docs/05`, punto 21).
- **La animación de las cortinas y de la criatura:** Benja dibujó 2 estados. Si dibuja la animación, va en `curtains_sprite`.
- **Bajar la tolerancia de Audio Sync:** `docs/17` la dejaba como opcional. Primero hay que probar la velocidad.
- **Enseñar Audio Sync y los accidentes en la noche 0:** si en las pruebas con personas no se entienden, es una tarea de S22.
- **Los sonidos reales:** los 15 audios son relleno, y eso pesa más que antes, porque ahora hay que distinguirlos (`sonidos_pendiente.md`).
- **El equilibrio:** todos los valores son de partida y se ajustan en S22.

## Autorrevisión del plan

- **Cobertura** (`docs/17` y las respuestas de Benja):

  | Requisito | Tarea |
  | --- | --- |
  | Barras en el hueco central, arriba; los diales se quedan | 1 |
  | Menos tiempo, sin pista desde la noche 3, más señuelos | 2 |
  | Entidades que comparten 2 características en las noches 3 a 5 | 2 |
  | Audio Sync más rápido por noche y por ronda | 3 |
  | El amigo manda un audio en «¿Qué oyes?» | 4 |
  | Lo que se oye cambia la acción correcta | 5 |
  | La estática tapa el audio y no hay alucinaciones mientras suena | 4 |
  | Batería con tope por noche, con indicador | 6 |
  | Cortinas que se abren y se cierran, y Sanity según su estado | 7 |
  | El screamer de la cortina la abre o la cierra | 7 |
  | La criatura se queda un tiempo fijo y hay que revisar | 8 |
  | La criatura abre la cortina al llegar | 8 |
  | La noche 0 explica las barras, los audios, la batería y las cortinas | 1 y 9 |
  | Accidentes con respuesta de sentido común (C2) | 10 |
  | Documentos al día | 11 |

- **Nombres consistentes:** `StatBars.Stat`, `set_values()`, `fill()`, `is_flashing()`, `is_alert()` y `alert_light()` (Tarea 1); `audio_sync_bpm` y `audio_sync_round_speedup` (Tarea 3); `audio_values`, `audio_for()`, `add_audio()`, `audio_caption`, `AUDIO_META`, `audio_clicked`, `audio_captions`, `is_audio_playing()` y `AudioClip` (Tarea 4); `battery`, `has_battery()` y `phone_battery_seconds` (Tarea 6); `curtains_closed`, `creature_outside`, `sanity_drain_per_second()`, `toggle_curtains()`, `CurtainShade` y `hit_animation` (Tarea 7); `creature_visits`, `jumpscare_slots` y `plan_jumpscares()` (Tarea 8); `creature_at_window`, `CLOSE_CURTAINS_KEY` y `OPEN_CURTAINS_KEY` (Tarea 9); e `IncidentData`, `FriendIncident`, `incidents`, `start_incident()`, `answer_incident()`, `incident_due()`, `incident_started()`, `injure()` e `incident_count` (Tarea 10) coinciden entre el código y las pruebas.
