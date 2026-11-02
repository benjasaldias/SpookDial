# Plan 7: Screamers y director — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que la noche tenga un ritmo controlado y screamers justos:

- **el director de ritmo:** las solicitudes llegan en olas, con un respiro sin solicitudes nuevas después de cada una, y se aprietan hacia las 06:00. Si no hay a quién darle una solicitud, o un amigo queda herido, las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00;
- **los screamers:** cuatro ambientales (la cortina, la figura en la ventana, el celular y las luces), dos sobre el cuaderno (se cierra de golpe o una mancha de tinta tapa la página) y el jumpscare de pantalla completa, uno por noche desde la noche 2. Llegan en cualquier momento, anunciados por un parpadeo de luz y una caída del sonido ambiente, y siguen las reglas de justicia: nunca en los últimos 5 s de una decisión, y el jumpscare pausa la noche. Cada uno resta Sanity;
- **las alucinaciones:** con Sanity bajo suenan golpes, pasos, susurros y rasguños, y también la estática y el celular, que no vienen de nada, más seguidos y más fuertes mientras más baja Sanity;
- **el susto guionado:** en la noche 1 (hasta que exista la noche 0, el tutorial), un jumpscare y después un chat guionado con Gonzalo enseñan Sanity y el celular. Matías responde con un botón, y al final el borde del celular parpadea hasta que Matías lo abre.

**Arquitectura:**

- Lógica pura en `scripts/core/`: `PacingDirector` (cuándo llega cada solicitud y cada screamer), `Screamer` (qué screamer toca, cuánto resta y si es justo), `HallucinationClock` (cuándo suena una alucinación) y `ChatScript` (un chat guionado en curso). `NightState` aprende a bajar Sanity de golpe y `NightManager`, a pausar la noche.
- Datos: `BalanceData` agrega los valores del director, de los screamers y de las alucinaciones; `NightData`, las olas, los screamers de la noche y el guion. Clases nuevas: `ScareKind` (los tipos de screamer), `ChatScriptData` y `ChatLineData` (un chat guionado).
- `RequestManager` le pregunta al director cuándo empezar cada solicitud, y escribe el chat guionado. `ScreamerManager` (`scripts/desk/screamer_manager.gd`), un nodo nuevo del escritorio, anuncia y muestra los screamers y hace sonar las alucinaciones.
- La interfaz: el cuaderno se cierra de golpe y se mancha de tinta (`scripts/ui/ink_blot.gd`), el chat tiene el botón de la respuesta guionada, el contorno de un objeto del escritorio puede parpadear, y el escritorio tiene el sonido ambiente, la oscuridad de las luces y la pantalla del jumpscare.
- Los sonidos provisionales nuevos van en `audio/sfx/` y los genera `tools/make_placeholder_sounds.py`, como los del Plan 6.

**Stack:** Godot 4.7.2 (GDScript con tipado estático, `Tween`, `_draw()`, `AudioStreamPlayer` y `AudioStreamPlayer2D`) y Python 3, solo con su biblioteca estándar, para los sonidos. Las pruebas usan el ejecutor propio (`test/run_tests.gd`) y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §5, §10.2, §11 y §14, y `docs/02_bucle_central.md` §2 y §6.

---

## Decisiones de este plan

### De Benja (sesión 16, 2 de noviembre)

Están en `CLAUDE.md`, en el diseño v2 y en `docs/02`.

| Decisión | Detalle |
| --- | --- |
| **Olas con respiro.** | Las solicitudes llegan en grupos. Después de cada grupo hay una calma de unos 25 s sin solicitudes nuevas, para sincronizar, descargar o mirar el celular. Las olas se aprietan hacia las 06:00, y cuando un amigo queda herido, la siguiente solicitud se atrasa unos segundos. |
| **Screamers en cualquier momento.** | Llegan al azar en toda la noche, solo con las reglas de justicia del diseño (§11). |
| **Alucinaciones del cuarto y del juego.** | Golpes en la ventana, pasos, susurros y rasguños, y también la estática de una interferencia y el celular vibrando: confunden, porque el jugador mira y no hay nada. No restan Sanity, para no entrar en espiral, y no suenan durante Audio Sync. |
| **La figura de la ventana, escondida.** | La figura oscura con ojos rojos (`enemy_sprite`) ya no está siempre en la ventana: aparece al asustar, como el screamer de la ventana. Hasta que Benja dibuje el jumpscare, también es el jumpscare provisional, a ×2. |
| **Noche 0 (tutorial).** | Es una noche nueva antes de la 1. El susto guionado y su chat se guardan como datos de una noche, para moverlos sin tocar código; mientras no exista la noche 0, van en la 1. Qué enseña la noche 0 y cuánto dura se decide en el Plan 8. |
| **El chat guionado tras el susto.** | Un amigo escribe "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar". Matías responde **con un botón**: "Creo que me estoy volviendo loco, no sé si puedo seguir". El amigo contesta "Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar", y el borde del celular parpadea hasta que Matías lo usa. Los textos son de Benja, tal cual. Más adelante habrá una progresión guionada entre los amigos (`docs/05`, después de la v1). |

### Técnicas

| Decisión | Por qué |
| --- | --- |
| El director planifica al empezar la noche la hora de cada solicitud: la primera a los 5 s y la última justo a tiempo para responderla antes de las 06:00. Entre ellas, los espacios se acortan parejo hasta la mitad del primero, con ±15 % de azar, y después de cada ola (`NightData.wave_size` solicitudes) se suma un respiro de 25 s. | Así hay olas, se aprietan hacia el final y cada noche es distinta. Con la noche 3, los espacios van de unos 37 s a unos 18 s, y los respiros, de unos 62 s a unos 43 s. |
| Las olas son de 2 solicitudes en la noche 1, de 3 en las noches 2 y 3, y de 4 en las noches 4 y 5. | Crecen con las solicitudes simultáneas de cada noche (`docs/02` §6). |
| Si una solicitud no puede empezar a su hora (todos están ocupados o aturdidos, o ya están las simultáneas de la noche), espera, y las que faltan se atrasan lo mismo. Un amigo herido las atrasa 10 s. Entre dos solicitudes pasan al menos 6 s. | Si no, las atrasadas llegarían todas juntas. Por eso el total de solicitudes de la noche es aproximado. |
| Nunca empieza una solicitud que no alcanza a terminar antes de las 06:00, con el tiempo que tendría (más corto con Trust bajo). | Una solicitud que la noche corta a la mitad no se puede resolver. |
| `RequestManager` lleva su propia hora para el director (`_elapsed`), que avanza igual que la del estado de la noche. | Así las pruebas de `RequestManager` siguen funcionando sin `NightManager`, y en el escritorio las dos horas son la misma, también durante una pausa. |
| Los screamers de la noche (`NightData.scare_count`) se reparten uno por tramo igual, desde los 30 s, a una hora al azar lejos de los bordes del tramo, como las interferencias. Si la noche tiene jumpscare (`has_jumpscare`, desde la noche 2), uno de ellos al azar lo es. | "En cualquier momento", pero nunca demasiado seguidos: quedan al menos 25 s entre dos. |
| Cada screamer se anuncia con 1 s de señal previa: la oscuridad parpadea dos veces y el sonido ambiente baja a −40 dB. Vuelve 1,5 s después del screamer, en 2 s. | Diseño §11: "un parpadeo de luz y una caída del sonido ambiente". |
| Un screamer solo empieza si a ninguna decisión le quedan 5 s o menos al terminar su señal previa. La mancha de tinta tapa las reglas 5 s, así que necesita 5 s más. El jumpscare tapa la pantalla, pero pausa la noche, así que no los necesita. Si ninguno es justo, el director espera. | Diseño §11: "nunca ocurren en los últimos 5 segundos de una decisión" y "los que tapan la pantalla pausan los temporizadores". |
| Ni los screamers ni las alucinaciones empiezan durante una ronda de Audio Sync. | Audio Sync se juega con el oído: un sonido de más la arruinaría. Benja lo decidió para las alucinaciones, y vale lo mismo para los screamers. |
| Los ambientales se eligen solo si su objeto está a la vista: el chat, el mixer y el celular ampliado tapan la cortina, la ventana y el celular del escritorio. Las luces se ven siempre. Los del cuaderno, solo con el cuaderno abierto, y la tinta, solo en la página de una entidad. | Un susto que no se ve no asusta. Entre los que se ven, se elige al azar. |
| El jumpscare dura 1,5 s y la noche se pausa mientras tanto (`NightManager.pause()`): no avanzan la hora, los temporizadores, la señal, Sanity ni los videos. Tapa los clics. | Diseño §11. |
| Un screamer resta 8 de Sanity, y el jumpscare, 15 (`docs/02` §6). | Ya estaban en `docs/02`. |
| El susto guionado (`NightData.scripted_scare_time`, 60 s en la noche 1) espera un momento sin solicitudes, y su tipo es un dato (`scripted_scare`): por defecto, el jumpscare. Cuenta como screamer para el espacio de 25 s. | "Te escuché gritar": el jumpscare es el susto más claro. Si Benja prefiere otro, lo cambia en el Inspector. |
| El chat guionado es un dato de la noche (`NightData.scripted_chat`, un `ChatScriptData`): el amigo, las líneas (`ChatLineData`: quién habla y su texto en `messages.csv`) y si el celular parpadea al terminar. Lo escribe Gonzalo. | Benja quiere agregar después más chats guionados entre los amigos: quedan como datos, sin código nuevo. Gonzalo es un borrador: se cambia en el Inspector. |
| Cada línea del amigo llega 2,5 s después de la anterior, como si escribiera. La de Matías espera su botón, que reemplaza a las respuestas del chat mientras tanto, y la entrada del amigo parpadea mientras espera. | Decisión de Benja: Matías responde con un botón. Que la entrada parpadee hace que el jugador abra el chat. |
| `RequestManager` sigue siendo el único que escribe en el chat: también las líneas del chat guionado. | Como en el Plan 6. |
| El contorno de un objeto del escritorio (`ClickableSprite.blinking`) parpadea 0,4 s encendido y 0,4 s apagado. Al abrir el celular, deja de parpadear. | Decisión de Benja: el borde del celular parpadea. |
| Las alucinaciones empiezan con Sanity bajo 50: una cada 40 s, y cada vez más seguidas hasta una cada 10 s con Sanity en 0, con ±25 % de azar. Su volumen va de −18 dB a −3 dB. Suenan desde fuera de la pantalla, a la izquierda o a la derecha (`AudioStreamPlayer2D`). | Diseño §10.2: "más screamers auditivos falsos" mientras más baja, y `docs/02` §6: "más fuertes cuanto más baja". Que suenen a un lado hace que no vengan de nada. |
| La figura de la ventana (`WallPlane/Enemy`) empieza escondida. En su screamer aparece 0,9 s y se desvanece en 0,6 s. | Decisión de Benja. |
| Mientras no esté el arte de Benja: la cortina se mece (`skew`), el celular se mueve 2 px a cada lado, las luces oscurecen todo el cuarto con un polígono negro sobre el escritorio (debajo de los paneles), la mancha de tinta se dibuja con círculos y el jumpscare es la silueta de la figura a ×2 sobre un destello gris, con parpadeos rojos. | Son provisionales: el arte los reemplaza sin cambiar la lógica (ver "Fuera de este plan"). Sobre negro, la silueta oscura casi no se veía. |
| El sonido ambiente (`audio/sfx/ambient_room.wav`, 8 s de viento y un zumbido) suena siempre en el escritorio y se repite al terminar. | Sin sonido ambiente, la señal previa no tendría qué bajar. El Plan 9 lo reemplaza. |
| El director no cambia cuándo llegan los videos ni las interferencias: siguen repartidos uno por tramo. | Ya están espaciados, y los respiros dejan tiempo para atenderlos. Si las pruebas con personas muestran que se juntan con las olas, se ajusta después. |
| El ejecutor de pruebas espera 0,2 s antes de salir. | Los sonidos que las pruebas dejan sonando se liberan en el hilo de audio; sin la espera, a veces Godot avisa al salir que quedaron recursos en uso. |

**Verificado en Godot 4.7.2**, en copias aparte del proyecto, ya borradas:

- todo el código de este plan se ejecutó: 373 pruebas OK, sin errores al correr, y cinco capturas revisadas a ojo: la figura en la ventana, la mancha de tinta, el jumpscare, el chat guionado con el botón de Matías y el celular con su contorno encendido;
- después, un script aplicó el plan **tal como está escrito** a una copia limpia del proyecto: los 27 conteos de pruebas que dice coinciden, incluidas las fallas esperadas, todos los bloques a reemplazar aparecen una sola vez, y el código resultante es idéntico al probado, también los 19 sonidos. Las capturas salen iguales, salvo el tono rojo del jumpscare, que depende del instante en que se toma.

---

## Antes de empezar

- [ ] **Godot cerrado.** Este plan usa `--import`, que necesita el editor cerrado (`docs/04`, "Regla mientras Claude trabaja").
- [ ] **Las pruebas pasan.** Desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
  ```

  Esperado: `326 pruebas OK, 0 fallidas`.
- [ ] **Git limpio:** `git status` no muestra cambios.
- [ ] **Python 3:** `python3 --version` muestra 3.8 o más nuevo. Solo se usa su biblioteca estándar.
- [ ] **Datos y textos de Benja:** los CSV y los `.tres` pueden tener cambios de Benja. Este plan no reemplaza sus textos: en los CSV solo agrega líneas al final, y en los `.tres`, reemplaza líneas que Benja no edita. Si un bloque a reemplazar no aparece, revisar el archivo antes de seguir.

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
- "En `ruta`, reemplazar:" un bloque, "por:" otro bloque: el primero aparece una sola vez en el archivo, y son líneas completas. Si hay varios seguidos para el mismo archivo, se aplican en orden.
- "Agregar al final de `ruta`:": en un `.gd`, dejar dos líneas en blanco antes del bloque; en un `.md`, una línea en blanco; en un `.csv`, agregar las líneas tal cual.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/data/balance_data.gd`, `data/balance.tres` | Los valores del director, de los screamers y de las alucinaciones |
| `scripts/data/night_data.gd`, `data/nights/night_*.tres` | Las olas, los screamers de cada noche y el guion (el susto guionado y su chat) |
| `scripts/data/scare_kind.gd` | `ScareKind`: los tipos de screamer |
| `scripts/core/pacing_director.gd` | `PacingDirector`: cuándo llega cada solicitud y cada screamer |
| `scripts/core/screamer.gd` | `Screamer`: qué screamer toca con lo que se ve, cuánto resta y si es justo |
| `scripts/core/hallucination_clock.gd` | `HallucinationClock`: cuándo suena una alucinación y qué tan fuerte |
| `scripts/core/night_state.gd`, `scripts/desk/night_manager.gd` | Un screamer baja Sanity de golpe; el jumpscare pausa la noche |
| `scripts/desk/request_manager.gd` | Las solicitudes llegan cuando dice el director; el chat guionado |
| `scripts/data/chat_line_data.gd`, `scripts/data/chat_script_data.gd`, `scripts/core/chat_script.gd` | Un chat guionado: sus datos y su avance |
| `scripts/core/message_builder.gd`, `scripts/core/content_validator.gd`, `data/text/messages.csv` | Las líneas del chat guionado en el chat, su revisión y sus textos |
| `tools/make_placeholder_sounds.py`, `audio/sfx/*.wav` | El sonido ambiente, los de los screamers y los de las alucinaciones, provisionales |
| `scripts/ui/ink_blot.gd`, `scripts/ui/notebook_panel.gd`, `scenes/ui/notebook_panel.tscn` | El cuaderno se cierra de golpe o se mancha de tinta |
| `scripts/desk/clickable_sprite.gd` | El contorno que parpadea para pedir atención |
| `scripts/desk/screamer_manager.gd` | `ScreamerManager`: anuncia y muestra los screamers, y hace sonar las alucinaciones |
| `scripts/desk/desk.gd`, `scenes/desk/desk.tscn` | El sonido ambiente, la oscuridad, la pantalla del jumpscare, la figura escondida, lo que se ve para elegir un screamer, el chat guionado en las entradas y el celular que parpadea |
| `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn` | El botón de la respuesta guionada de Matías |
| `test/run_tests.gd` | Espera un momento antes de salir, para que se liberen los sonidos |
| `test/test_*.gd` | Pruebas de cada tarea |
| `test/capture_screamers.gd` | Capturas de los screamers para revisarlos a ojo (no es una prueba) |

## Cómo encajan las piezas

```text
NightManager.advance(delta), en cada frame mientras la noche no termine (salvo lo que quede de pausa)
  1. RequestManager.advance(delta)
       temporizadores; el chat guionado (ChatScript) escribe su próxima línea
       PacingDirector.request_due() ──▶ start_request() a un amigo libre ──▶ request_started()
       un amigo herido ──▶ PacingDirector.friend_hurt(): las que faltan se atrasan
  2. NightState.advance(delta) ──▶ Events   3. avisos en el chat   4. NightState.ending()

Escritorio (desk._process(delta))
  ScreamerManager.advance(delta, lo que se ve (Screamer.View), ¿hay una ronda de Audio Sync?)
    HallucinationClock.advance(Sanity) ──▶ una alucinación a un lado de la pantalla
    PacingDirector.scripted_scare_due() o scare_due() ──▶ Screamer.pick(): uno que se vea y sea justo
      ──▶ señal previa (1 s: las luces parpadean, baja el ambiente) ──▶ play(): el screamer y su sonido
          NightState.scare(8 o 15)    el jumpscare ──▶ NightManager.pause(1,5)
          el susto guionado ──▶ RequestManager.start_chat_script() ──▶ líneas de Gonzalo y botón de Matías
  RequestManager.chat_script_finished ──▶ el celular del escritorio parpadea hasta que Matías lo abre
```

---

### Tarea 1: Valores del director y de los screamers como datos

**Archivos:**

- Crear: `scripts/data/scare_kind.gd`
- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/data/night_data.gd`, `data/nights/night_1.tres` a `night_5.tres`, `test/test_balance.gd`

`BalanceData` agrega tres grupos: el director, los screamers y las alucinaciones. `NightData` agrega las solicitudes por ola, los screamers de la noche y el guion: el susto guionado. `ScareKind` es la lista de los tipos de screamer, que usan `NightData` y la lógica de las tareas siguientes. Los valores están en `docs/02` §6 y se ajustan en el Inspector.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_balance.gd`:

```gdscript
## Los valores del director, de los screamers y de las alucinaciones (docs/02 §6 y decisiones de Benja del
## 2 de noviembre).
func test_valores_del_director_y_los_screamers() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check(balance != null, "se carga")
	if balance == null:
		return true
	check_eq(balance.first_request_delay, 5.0, "la primera solicitud, a los 5 s")
	check_eq(balance.wave_respite, 25.0, "respiro de 25 s después de cada ola")
	check_eq(balance.wave_tightening, 0.5, "al final, las solicitudes llegan al doble de rápido")
	check_eq(balance.request_min_gap, 6.0, "al menos 6 s entre dos solicitudes")
	check_eq(balance.hurt_respite, 10.0, "un amigo herido atrasa las solicitudes 10 s")
	check_eq(balance.scare_warning, 1.0, "señal previa de 1 s")
	check_eq(balance.scare_margin, 5.0, "nunca en los últimos 5 s de una decisión")
	check_eq(balance.scare_min_gap, 25.0, "al menos 25 s entre dos screamers")
	check_eq(balance.first_scare_after, 30.0, "sin screamers en los primeros 30 s")
	check_eq(balance.scare_sanity, 8.0, "screamer: Sanity −8")
	check_eq(balance.jumpscare_sanity, 15.0, "jumpscare: Sanity −15")
	check_eq(balance.jumpscare_seconds, 1.5, "el jumpscare dura 1,5 s")
	check_eq(balance.ink_seconds, 5.0, "la mancha de tinta dura 5 s")
	check_eq(balance.hallucination_start, 50.0, "alucinaciones con Sanity bajo 50")
	check_eq(balance.hallucination_slowest, 40.0, "una cada 40 s al empezar")
	check_eq(balance.hallucination_fastest, 10.0, "una cada 10 s con Sanity en 0")
	return true


## Las olas y los screamers de cada noche (docs/02 §6).
func test_olas_y_screamers_de_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var wave_sizes := [2, 3, 3, 4, 4]
	var scare_counts := [0, 3, 4, 5, 6]
	for index in catalog.nights.size():
		var night: NightData = catalog.nights[index]
		var who := "noche %d" % night.number
		check_eq(night.wave_size, wave_sizes[index], who + ": solicitudes por ola")
		check_eq(night.scare_count, scare_counts[index], who + ": screamers")
		check_eq(night.has_jumpscare, night.number >= 2, who + ": un jumpscare desde la noche 2")
		check_eq(night.scripted_scare_time, 60.0 if night.number == 1 else 0.0, who + ": susto guionado")
	check_eq(catalog.nights[0].scripted_scare, ScareKind.Kind.JUMPSCARE, "el susto guionado es un jumpscare")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `322 pruebas OK, 1 fallidas`. No se pudo cargar `test_balance.gd`, porque la clase `ScareKind` no existe.

- [ ] **Paso 3: Agregar los valores**

`scripts/data/scare_kind.gd`:

```gdscript
class_name ScareKind
extends RefCounted
## Los screamers (diseño §11): cuatro ambientales (la cortina, la figura en la ventana, el celular y las
## luces), dos sobre el cuaderno (se cierra de golpe o una mancha de tinta tapa la página) y el jumpscare de
## pantalla completa.

enum Kind { CURTAINS, WINDOW, PHONE, LIGHTS, NOTEBOOK_SLAM, INK, JUMPSCARE }
```

En `scripts/data/balance_data.gd`, reemplazar:

```gdscript
@export var download_slow_below := 50.0
```

por:

```gdscript
@export var download_slow_below := 50.0

@export_group("Director")
## Segundos hasta la primera solicitud de la noche.
@export var first_request_delay := 5.0
## Segundos de calma sin solicitudes nuevas después de cada ola (decisión de Benja).
@export var wave_respite := 25.0
## Cuánto se aprietan las solicitudes hacia las 06:00: el último espacio entre dos es este tanto más corto
## que el primero (0,5: la mitad).
@export_range(0.0, 0.9) var wave_tightening := 0.5
## Segundos mínimos entre dos solicitudes, aunque una llegue atrasada.
@export var request_min_gap := 6.0
## Segundos que se atrasan las solicitudes que faltan cuando un amigo queda herido (decisión de Benja).
@export var hurt_respite := 10.0

@export_group("Screamers")
## Segundos de la señal previa: las luces parpadean y baja el sonido ambiente (diseño §11).
@export var scare_warning := 1.0
## Un screamer nunca ocurre si a una decisión le quedan tantos segundos o menos (diseño §11).
@export var scare_margin := 5.0
## Segundos mínimos entre dos screamers.
@export var scare_min_gap := 25.0
## Segundos de calma al empezar la noche, sin screamers.
@export var first_scare_after := 30.0
## Sanity que resta un screamer ambiental o sobre el cuaderno (docs/02 §6).
@export var scare_sanity := 8.0
## Sanity que resta el jumpscare (docs/02 §6).
@export var jumpscare_sanity := 15.0
## Segundos que dura el jumpscare. Tapa la pantalla, así que la noche se pausa (diseño §11).
@export var jumpscare_seconds := 1.5
## Segundos que la mancha de tinta tapa la página del cuaderno (diseño §11).
@export var ink_seconds := 5.0

@export_group("Alucinaciones")
## Bajo este valor de Sanity suenan screamers auditivos falsos (diseño §10.2).
@export var hallucination_start := 50.0
## Segundos entre dos alucinaciones con Sanity justo bajo hallucination_start…
@export var hallucination_slowest := 40.0
## …y con Sanity en 0. En el medio, el espacio se acorta parejo.
@export var hallucination_fastest := 10.0
```

En `data/balance.tres`, reemplazar:

```ini
download_slow_below = 50.0
```

por:

```ini
download_slow_below = 50.0
first_request_delay = 5.0
wave_respite = 25.0
wave_tightening = 0.5
request_min_gap = 6.0
hurt_respite = 10.0
scare_warning = 1.0
scare_margin = 5.0
scare_min_gap = 25.0
first_scare_after = 30.0
scare_sanity = 8.0
jumpscare_sanity = 15.0
jumpscare_seconds = 1.5
ink_seconds = 5.0
hallucination_start = 50.0
hallucination_slowest = 40.0
hallucination_fastest = 10.0
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var decoys_in_first_message := 1
```

por:

```gdscript
@export var decoys_in_first_message := 1
## Solicitudes por ola: llegan seguidas y, después de cada ola, hay un respiro (decisión de Benja).
@export var wave_size := 3
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var content_quota := 2


## Cuántas observaciones trae el mensaje inicial de una entidad que tiene `total`.
```

por:

```gdscript
@export var content_quota := 2

@export_group("Screamers")
## Screamers de la noche, sin contar las alucinaciones ni el susto guionado. Llegan en cualquier momento,
## con las reglas de justicia (decisión de Benja).
@export var scare_count := 0
## Uno de los screamers es el jumpscare de pantalla completa: como máximo uno por noche, desde la noche 2.
@export var has_jumpscare := false

@export_group("Guion")
## Segundos desde las 00:00 del susto guionado (0: no hay). Llega en el primer momento sin solicitudes.
@export var scripted_scare_time := 0.0
## Qué screamer es el susto guionado.
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE


## Cuántas observaciones trae el mensaje inicial de una entidad que tiene `total`.
```

En `data/nights/night_1.tres`, reemplazar:

```ini
decoys_in_first_message = 1
```

por:

```ini
decoys_in_first_message = 1
wave_size = 2
```

En `data/nights/night_1.tres`, reemplazar:

```ini
content_quota = 2
```

por:

```ini
content_quota = 2
scare_count = 0
has_jumpscare = false
scripted_scare_time = 60.0
```

En `data/nights/night_2.tres`, reemplazar:

```ini
decoys_in_first_message = 1
```

por:

```ini
decoys_in_first_message = 1
wave_size = 3
```

En `data/nights/night_2.tres`, reemplazar:

```ini
content_quota = 3
```

por:

```ini
content_quota = 3
scare_count = 3
has_jumpscare = true
```

En `data/nights/night_3.tres`, reemplazar:

```ini
decoys_in_first_message = 2
```

por:

```ini
decoys_in_first_message = 2
wave_size = 3
```

En `data/nights/night_3.tres`, reemplazar:

```ini
content_quota = 3
```

por:

```ini
content_quota = 3
scare_count = 4
has_jumpscare = true
```

En `data/nights/night_4.tres`, reemplazar:

```ini
decoys_in_first_message = 2
```

por:

```ini
decoys_in_first_message = 2
wave_size = 4
```

En `data/nights/night_4.tres`, reemplazar:

```ini
content_quota = 4
```

por:

```ini
content_quota = 4
scare_count = 5
has_jumpscare = true
```

En `data/nights/night_5.tres`, reemplazar:

```ini
decoys_in_first_message = 3
```

por:

```ini
decoys_in_first_message = 3
wave_size = 4
```

En `data/nights/night_5.tres`, reemplazar:

```ini
content_quota = 4
```

por:

```ini
content_quota = 4
scare_count = 6
has_jumpscare = true
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `328 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "Valores del director y de los screamers como datos" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: El director: las solicitudes en olas

**Archivos:**

- Crear: `scripts/core/pacing_director.gd`, `test/test_pacing_director.gd`

`PacingDirector` planifica al empezar la noche la hora de cada solicitud y, durante la noche, dice cuándo toca empezar la siguiente:

- la primera llega a los `first_request_delay` segundos (5) y la última, justo a tiempo para responderla antes de las 06:00 (a los 385 s en la noche 3);
- entre ellas, los espacios se acortan parejo hasta (1 − `wave_tightening`) del primero, con ±15 % de azar, y se reparten el tiempo que dejan los respiros;
- después de cada ola de `wave_size` solicitudes se suma un respiro de `wave_respite` segundos (25);
- una solicitud atrasada atrasa a las que faltan (`request_started()`), igual que un amigo herido (`friend_hurt()`), y entre dos pasan al menos `request_min_gap` segundos (6);
- si ya no alcanza a terminar antes de las 06:00, no llegan más (`request_due()`).

- [ ] **Paso 1: Escribir las pruebas**

`test/test_pacing_director.gd`:

```gdscript
extends "res://test/test_case.gd"

const PacingDirector := preload("res://scripts/core/pacing_director.gd")


## Una noche como la 3 (docs/02 §6): 12 solicitudes en olas de 3, con 35 s para responder.
func _night() -> NightData:
	var night := NightData.new()
	night.requests_total = 12
	night.wave_size = 3
	night.base_decision_time = 35.0
	return night


func _director(night: NightData, seed_value := 1) -> PacingDirector:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PacingDirector.new(night, BalanceData.new(), rng)


## Los espacios entre las horas de `times`.
func _gaps(times: Array[float]) -> Array[float]:
	var gaps: Array[float] = []
	for index in times.size() - 1:
		gaps.append(times[index + 1] - times[index])
	return gaps


func test_planifica_todas_las_solicitudes_de_la_noche() -> bool:
	for seed_value in range(1, 21):
		var times := _director(_night(), seed_value).request_times
		check_eq(times.size(), 12, "12 solicitudes")
		check_eq(times[0], 5.0, "la primera a los 5 s")
		check(is_equal_approx(times[-1], 385.0), "la última alcanza a terminar a las 06:00: %s" % times[-1])
		for gap: float in _gaps(times):
			check(gap > 0.0, "en orden")
	return true


func test_despues_de_cada_ola_hay_un_respiro() -> bool:
	for seed_value in range(1, 21):
		var gaps := _gaps(_director(_night(), seed_value).request_times)
		for index in gaps.size():
			if (index + 1) % 3 == 0:
				check(gaps[index] >= 25.0, "el respiro dura al menos 25 s: %s" % gaps[index])
				check(gaps[index] > gaps[index - 1], "el respiro es más largo que el espacio de la ola: %s" % [gaps])
	return true


func test_las_olas_se_aprietan_hacia_las_06() -> bool:
	for seed_value in range(1, 21):
		var gaps := _gaps(_director(_night(), seed_value).request_times)
		# Dentro de la primera ola y de la última: los espacios 0-1 y 9-10.
		var first := gaps[0] + gaps[1]
		var last := gaps[9] + gaps[10]
		check(last < first, "al final llegan más seguidas: %s" % [gaps])
	return true


func test_llega_a_su_hora_y_no_antes() -> bool:
	var director := _director(_night())
	check(not director.request_due(4.9, 35.0), "a los 4,9 s todavía no")
	check(director.request_due(5.0, 35.0), "a los 5 s, sí")
	director.request_started(5.0)
	var second := director.request_times[0]
	check(not director.request_due(second - 0.1, 35.0), "la segunda, todavía no")
	check(director.request_due(second, 35.0), "la segunda, a su hora")
	return true


func test_si_una_llega_tarde_las_demas_se_atrasan() -> bool:
	var director := _director(_night())
	director.request_started(5.0)
	var planned := director.request_times.duplicate()
	director.request_started(planned[0] + 7.0)
	check_eq(director.request_times.size(), planned.size() - 1, "quedan las demás")
	for index in director.request_times.size():
		check(is_equal_approx(director.request_times[index], planned[index + 1] + 7.0), "atrasada 7 s")
	return true


func test_al_menos_6_s_entre_dos_solicitudes() -> bool:
	var director := _director(_night())
	director.request_times.assign([10.0, 11.0, 30.0])
	director.request_started(10.0)
	check(not director.request_due(11.0, 35.0), "a 1 s de la anterior, no")
	check(director.request_due(16.0, 35.0), "a 6 s, sí")
	return true


func test_un_amigo_herido_atrasa_las_que_faltan() -> bool:
	var director := _director(_night())
	var planned := director.request_times.duplicate()
	director.friend_hurt()
	for index in planned.size():
		check(is_equal_approx(director.request_times[index], planned[index] + 10.0), "atrasada 10 s")
	return true


func test_no_empieza_una_que_no_alcanza_a_terminar() -> bool:
	var director := _director(_night())
	director.request_times.assign([400.0, 410.0])
	check(not director.request_due(400.0, 30.0), "a las 05:43 ya no alcanza a responder en 30 s")
	check(director.request_times.is_empty(), "no llegan más")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `328 pruebas OK, 1 fallidas`. No se pudo cargar `test_pacing_director.gd`, porque `scripts/core/pacing_director.gd` no existe.

- [ ] **Paso 3: Crear el director**

`scripts/core/pacing_director.gd`:

```gdscript
extends RefCounted
## El director de ritmo (diseño §14 y decisiones de Benja, sesión 16): decide cuándo llega cada solicitud.
## Las solicitudes llegan en olas de NightData.wave_size, y después de cada ola hay un respiro sin solicitudes
## nuevas. Se aprietan hacia las 06:00. Si una llega tarde (no había a quién dársela) o un amigo queda herido,
## las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00.
## Lógica pura: RequestManager la consulta en cada paso.

## Las horas de las solicitudes que faltan, en segundos desde las 00:00 y en orden.
var request_times: Array[float] = []
## La hora en que empezó la última solicitud.
var last_request := -INF

var _balance: BalanceData


func _init(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	request_times = plan_requests(night, balance, rng)


## Las horas de las solicitudes de la noche. La primera llega a los first_request_delay segundos y la última,
## justo a tiempo para responderla antes de las 06:00. Entre ellas, los espacios se acortan parejo hasta
## (1 − wave_tightening) del primero, con algo de azar, y después de cada ola se suma un respiro.
static func plan_requests(night: NightData, balance: BalanceData, rng: RandomNumberGenerator) -> Array[float]:
	var times: Array[float] = []
	var count := night.requests_total
	if count <= 0:
		return times
	var start := balance.first_request_delay
	times.append(start)
	var wave_size := maxi(night.wave_size, 1)
	var gaps: Array[float] = []
	var total := 0.0
	var respites := 0
	for index in count - 1:
		var gap := (1.0 - balance.wave_tightening * index / maxf(count - 2, 1)) * rng.randf_range(0.85, 1.15)
		gaps.append(gap)
		total += gap
		if (index + 1) % wave_size == 0:
			respites += 1
	var end := balance.night_seconds - night.base_decision_time
	var free := maxf(end - start - respites * balance.wave_respite, 0.0)
	var time := start
	for index in gaps.size():
		time += gaps[index] / total * free
		if (index + 1) % wave_size == 0:
			time += balance.wave_respite
		times.append(time)
	return times


## Toca empezar una solicitud: llegó su hora y pasaron request_min_gap segundos desde la anterior. Si ya no
## alcanza a terminar antes de las 06:00 (dura `decision_seconds`), no llegan más.
func request_due(now: float, decision_seconds: float) -> bool:
	if request_times.is_empty() or now < request_times[0] or now - last_request < _balance.request_min_gap:
		return false
	if now + decision_seconds > _balance.night_seconds:
		request_times.clear()
		return false
	return true


## Empezó la solicitud que tocaba. Si llegó tarde, las que faltan se atrasan lo mismo: así no se juntan.
func request_started(now: float) -> void:
	if request_times.is_empty():
		return
	var late := maxf(now - request_times.pop_front(), 0.0)
	last_request = now
	delay(late)


## Un amigo quedó herido: las solicitudes que faltan se atrasan hurt_respite segundos (decisión de Benja).
func friend_hurt() -> void:
	delay(_balance.hurt_respite)


## Atrasa `seconds` las solicitudes que faltan.
func delay(seconds: float) -> void:
	for index in request_times.size():
		request_times[index] += seconds
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `336 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "El director: las solicitudes en olas" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: El director: cuándo llegan los screamers

**Archivos:**

- Modificar: `scripts/core/pacing_director.gd`, `test/test_pacing_director.gd`

El director también planifica los screamers de la noche: uno por tramo igual desde `first_scare_after` (30 s), y, si la noche tiene jumpscare, uno de ellos al azar lo es (`next_is_jumpscare()`). Durante la noche dice cuándo toca uno (`scare_due()`), con al menos `scare_min_gap` segundos (25) desde el anterior. El susto guionado llega a su hora en el primer momento sin solicitudes (`scripted_scare_due()`) y cuenta como screamer para ese espacio. Qué screamer es y si es justo lo decide `Screamer`, en la Tarea 4.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_pacing_director.gd`:

```gdscript
## Una noche con `count` screamers y, si `jumpscare`, uno de ellos es el jumpscare.
func _scary_night(count: int, jumpscare: bool) -> NightData:
	var night := _night()
	night.scare_count = count
	night.has_jumpscare = jumpscare
	return night


func test_reparte_los_screamers_en_la_noche() -> bool:
	for seed_value in range(1, 21):
		var times := _director(_scary_night(6, true), seed_value).scare_times
		check_eq(times.size(), 6, "6 screamers")
		check(times[0] >= 30.0, "ninguno en los primeros 30 s: %s" % times[0])
		check(times[-1] <= 420.0, "todos antes de las 06:00")
		for gap: float in _gaps(times):
			check(gap >= 25.0, "al menos 25 s entre dos: %s" % [times])
	return true


func test_uno_es_el_jumpscare_si_la_noche_lo_tiene() -> bool:
	for jumpscare: bool in [true, false]:
		for seed_value in range(1, 11):
			var director := _director(_scary_night(4, jumpscare), seed_value)
			var found := 0
			while not director.scare_times.is_empty():
				if director.next_is_jumpscare():
					found += 1
				director.scare_started(director.scare_times[0])
			check_eq(found, 1 if jumpscare else 0, "jumpscares en una noche %s jumpscare" % ("con" if jumpscare else "sin"))
	return true


func test_un_screamer_llega_a_su_hora_y_espaciado() -> bool:
	var director := _director(_scary_night(0, false))
	director.scare_times.assign([40.0, 50.0])
	check(not director.scare_due(39.0), "todavía no")
	check(director.scare_due(40.0), "a su hora")
	director.scare_started(40.0)
	check(not director.scare_due(50.0), "a 10 s del anterior, espera")
	check(director.scare_due(65.0), "a 25 s, sí")
	return true


func test_el_susto_guionado_espera_un_momento_sin_solicitudes() -> bool:
	var night := _night()
	night.scripted_scare_time = 60.0
	var director := _director(night)
	check(not director.scripted_scare_due(59.0, 0), "todavía no")
	check(not director.scripted_scare_due(60.0, 1), "hay una solicitud: espera")
	check(director.scripted_scare_due(70.0, 0), "sin solicitudes, llega")
	director.scare_times.assign([75.0])
	director.scripted_scare_started(70.0)
	check(not director.scripted_scare_due(80.0, 0), "llega una sola vez")
	check(not director.scare_due(80.0), "el siguiente screamer espera 25 s desde el guionado")
	check(director.scare_due(95.0), "a los 25 s, sí")
	check(not _director(_night()).scripted_scare_due(100.0, 0), "una noche sin susto guionado")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `328 pruebas OK, 1 fallidas`. No se pudo cargar `test_pacing_director.gd`, porque el director todavía no tiene `scare_times` ni las funciones de los screamers.

- [ ] **Paso 3: Los screamers en el director**

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
## El director de ritmo (diseño §14 y decisiones de Benja, sesión 16): decide cuándo llega cada solicitud.
## Las solicitudes llegan en olas de NightData.wave_size, y después de cada ola hay un respiro sin solicitudes
## nuevas. Se aprietan hacia las 06:00. Si una llega tarde (no había a quién dársela) o un amigo queda herido,
## las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00.
## Lógica pura: RequestManager la consulta en cada paso.
```

por:

```gdscript
## El director de ritmo (diseño §11 y §14, y decisiones de Benja, sesión 16): decide cuándo llega cada
## solicitud y cada screamer.
## Las solicitudes llegan en olas de NightData.wave_size, y después de cada ola hay un respiro sin solicitudes
## nuevas. Se aprietan hacia las 06:00. Si una llega tarde (no había a quién dársela) o un amigo queda herido,
## las que faltan se atrasan, y nunca empieza una que no alcanza a terminar antes de las 06:00.
## Los screamers llegan en cualquier momento, repartidos en la noche, y uno puede ser el jumpscare. El susto
## guionado espera un momento sin solicitudes. Las reglas de justicia las revisa Screamer al elegir cuál.
## Lógica pura: RequestManager la consulta para las solicitudes y ScreamerManager, para los screamers.
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
var last_request := -INF
```

por:

```gdscript
var last_request := -INF
## Las horas de los screamers que faltan, sin el guionado, en orden.
var scare_times: Array[float] = []
## Cuál de los screamers que faltan es el jumpscare, contado desde el próximo (0); -1 si no hay.
var jumpscare_at := -1
## La hora del susto guionado, o -1 si no hay o ya pasó.
var scripted_scare_time := -1.0
## La hora en que empezó el último screamer.
var last_scare := -INF
```

En `scripts/core/pacing_director.gd`, reemplazar:

```gdscript
	request_times = plan_requests(night, balance, rng)
```

por:

```gdscript
	request_times = plan_requests(night, balance, rng)
	scare_times = plan_scares(night.scare_count, balance, rng)
	if night.has_jumpscare and not scare_times.is_empty():
		jumpscare_at = rng.randi_range(0, scare_times.size() - 1)
	if night.scripted_scare_time > 0.0:
		scripted_scare_time = night.scripted_scare_time
```

Agregar al final de `scripts/core/pacing_director.gd`:

```gdscript
## Las horas de `count` screamers: uno por tramo igual de la noche, después de first_scare_after, a una hora al
## azar lejos de los bordes del tramo. Así llegan en cualquier momento (decisión de Benja), pero nunca
## demasiado seguidos.
static func plan_scares(count: int, balance: BalanceData, rng: RandomNumberGenerator) -> Array[float]:
	var times: Array[float] = []
	if count <= 0:
		return times
	var span := (balance.night_seconds - balance.first_scare_after) / count
	for index in count:
		times.append(balance.first_scare_after + span * (index + rng.randf_range(0.2, 0.8)))
	return times


## Toca un screamer: llegó su hora y pasaron scare_min_gap segundos desde el anterior.
func scare_due(now: float) -> bool:
	return not scare_times.is_empty() and now >= scare_times[0] and now - last_scare >= _balance.scare_min_gap


## El próximo screamer es el jumpscare.
func next_is_jumpscare() -> bool:
	return jumpscare_at == 0


## Empezó el screamer que tocaba.
func scare_started(now: float) -> void:
	if scare_times.is_empty():
		return
	scare_times.pop_front()
	jumpscare_at -= 1
	last_scare = now


## Toca el susto guionado: llegó su hora y no hay solicitudes activas.
func scripted_scare_due(now: float, active_requests: int) -> bool:
	return scripted_scare_time > 0.0 and now >= scripted_scare_time and active_requests == 0


## Empezó el susto guionado. Cuenta como screamer: el siguiente espera scare_min_gap segundos.
func scripted_scare_started(now: float) -> void:
	scripted_scare_time = -1.0
	last_scare = now
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `340 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "El director: cuándo llegan los screamers" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Qué screamer toca y si es justo

**Archivos:**

- Crear: `scripts/core/screamer.gd`, `test/test_screamer.gd`

`Screamer` es lógica pura:

- `candidates()`: los screamers que se pueden elegir con lo que se ve (`Screamer.View`). Las luces siempre; la cortina, la ventana y el celular, si el escritorio está a la vista; el golpe, con el cuaderno abierto, y la tinta, en la página de una entidad;
- `sanity_cost()`: 8, o 15 el jumpscare;
- `is_fair()`: a ninguna decisión le quedan `scare_margin` segundos (5) o menos al terminar la señal previa (1 s) y lo que tapa el screamer (la tinta, 5 s);
- `pick()`: uno al azar entre los que se ven y son justos, o el jumpscare si toca; `NONE` si ninguno es justo.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_screamer.gd`:

```gdscript
extends "res://test/test_case.gd"

const Screamer := preload("res://scripts/core/screamer.gd")


func _view(desk_visible: bool, notebook_open := false, notebook_page := false) -> Screamer.View:
	var view := Screamer.View.new()
	view.desk_visible = desk_visible
	view.notebook_open = notebook_open
	view.notebook_page = notebook_page
	return view


func test_las_luces_siempre_se_pueden() -> bool:
	check_eq(Screamer.candidates(_view(false)), [ScareKind.Kind.LIGHTS], "con todo tapado, solo las luces")
	return true


func test_con_el_escritorio_a_la_vista() -> bool:
	check_eq(Screamer.candidates(_view(true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.CURTAINS,
			ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE], "la cortina, la ventana y el celular")
	return true


func test_con_el_cuaderno_abierto() -> bool:
	check_eq(Screamer.candidates(_view(false, true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.NOTEBOOK_SLAM],
			"en el índice, se puede cerrar de golpe")
	check_eq(Screamer.candidates(_view(false, true, true)), [ScareKind.Kind.LIGHTS, ScareKind.Kind.NOTEBOOK_SLAM,
			ScareKind.Kind.INK], "en una página, también la tinta")
	return true


func test_cuanto_resta_cada_uno() -> bool:
	var balance := BalanceData.new()
	check_eq(Screamer.sanity_cost(ScareKind.Kind.CURTAINS, balance), 8.0, "ambiental: −8")
	check_eq(Screamer.sanity_cost(ScareKind.Kind.INK, balance), 8.0, "sobre el cuaderno: −8")
	check_eq(Screamer.sanity_cost(ScareKind.Kind.JUMPSCARE, balance), 15.0, "jumpscare: −15")
	return true


func test_nunca_en_los_ultimos_5_s_de_una_decision() -> bool:
	var balance := BalanceData.new()
	# Con la señal previa de 1 s, a la decisión le tienen que quedar más de 6 s; con la tinta, más de 11.
	check(Screamer.is_fair(ScareKind.Kind.LIGHTS, [], balance), "sin decisiones, siempre")
	check(not Screamer.is_fair(ScareKind.Kind.LIGHTS, [30.0, 6.0], balance), "a una le quedan 6 s")
	check(Screamer.is_fair(ScareKind.Kind.LIGHTS, [30.0, 6.5], balance), "a las dos les quedan más de 6 s")
	check(Screamer.is_fair(ScareKind.Kind.JUMPSCARE, [6.5], balance), "el jumpscare pausa la noche")
	check(not Screamer.is_fair(ScareKind.Kind.INK, [11.0], balance), "la tinta tapa las reglas 5 s")
	check(Screamer.is_fair(ScareKind.Kind.INK, [11.5], balance), "la tinta, con tiempo de sobra")
	return true


func test_elige_solo_entre_los_que_se_ven_y_son_justos() -> bool:
	var balance := BalanceData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var picked := {}
	for _i in 60:
		picked[Screamer.pick(_view(false, true, true), false, [8.0], balance, rng)] = true
	check_eq(picked.keys().size(), 2, "las luces y el golpe: %s" % [picked.keys()])
	check(not picked.has(ScareKind.Kind.INK), "la tinta no alcanza: a la decisión le quedan 8 s")
	check_eq(Screamer.pick(_view(true), true, [], balance, rng), ScareKind.Kind.JUMPSCARE, "si toca, el jumpscare")
	check_eq(Screamer.pick(_view(true), false, [5.5], balance, rng), Screamer.NONE, "ninguno es justo: espera")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `340 pruebas OK, 1 fallidas`. No se pudo cargar `test_screamer.gd`, porque `scripts/core/screamer.gd` no existe.

- [ ] **Paso 3: Crear `Screamer`**

`scripts/core/screamer.gd`:

```gdscript
extends RefCounted
## Qué screamer toca, cuánto resta y si es justo (diseño §11). Los ambientales asustan con un objeto del
## escritorio, así que solo se eligen si ese objeto está a la vista, y los del cuaderno, si está abierto. Las
## luces se ven siempre. Lógica pura: ScreamerManager elige con ella, y el escritorio dice qué se ve.

## pick() no encontró ninguno justo: hay que esperar.
const NONE := -1


## Lo que se ve del escritorio cuando toca un screamer.
class View:
	## La cortina, la ventana y el celular del escritorio: los tapan el chat, el mixer y el celular ampliado.
	var desk_visible := true
	var notebook_open := false
	## El cuaderno muestra la página de una entidad, no el índice: la tinta tiene reglas que tapar.
	var notebook_page := false


## Los screamers que se pueden elegir con lo que se ve. El jumpscare va aparte: lo decide el director.
static func candidates(view: View) -> Array[ScareKind.Kind]:
	var kinds: Array[ScareKind.Kind] = [ScareKind.Kind.LIGHTS]
	if view.desk_visible:
		kinds.append_array([ScareKind.Kind.CURTAINS, ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE])
	if view.notebook_open:
		kinds.append(ScareKind.Kind.NOTEBOOK_SLAM)
		if view.notebook_page:
			kinds.append(ScareKind.Kind.INK)
	return kinds


## Sanity que resta: el jumpscare, más que los demás (docs/02 §6).
static func sanity_cost(kind: ScareKind.Kind, balance: BalanceData) -> float:
	return balance.jumpscare_sanity if kind == ScareKind.Kind.JUMPSCARE else balance.scare_sanity


## Segundos que el screamer tapa algo mientras la noche sigue: la tinta tapa las reglas. El jumpscare tapa la
## pantalla, pero pausa la noche, así que no cuenta.
static func blocking_seconds(kind: ScareKind.Kind, balance: BalanceData) -> float:
	return balance.ink_seconds if kind == ScareKind.Kind.INK else 0.0


## Es justo si a ninguna decisión en curso (`time_lefts`) le quedan scare_margin segundos o menos cuando
## terminen la señal previa y lo que el screamer tapa (diseño §11).
static func is_fair(kind: ScareKind.Kind, time_lefts: Array, balance: BalanceData) -> bool:
	var needed := balance.scare_margin + balance.scare_warning + blocking_seconds(kind, balance)
	for time_left: float in time_lefts:
		if time_left <= needed:
			return false
	return true


## Un screamer al azar entre los que se ven y son justos; si toca el jumpscare, solo él. NONE si ninguno es
## justo.
static func pick(view: View, jumpscare: bool, time_lefts: Array, balance: BalanceData,
		rng: RandomNumberGenerator) -> int:
	var kinds: Array[ScareKind.Kind] = [ScareKind.Kind.JUMPSCARE]
	if not jumpscare:
		kinds = candidates(view)
	var fair := kinds.filter(func(kind: ScareKind.Kind) -> bool: return is_fair(kind, time_lefts, balance))
	if fair.is_empty():
		return NONE
	return fair[rng.randi_range(0, fair.size() - 1)]
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `346 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Qué screamer toca y si es justo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Las alucinaciones

**Archivos:**

- Crear: `scripts/core/hallucination_clock.gd`, `test/test_hallucination_clock.gd`

`HallucinationClock` dice cuándo suena una alucinación: con Sanity bajo `hallucination_start` (50), una cada `hallucination_slowest` segundos (40), y cada vez más seguidas hasta una cada `hallucination_fastest` (10) con Sanity en 0, con ±25 % de azar. También dice su volumen. Si no está permitida (durante una ronda de Audio Sync o un screamer), la que toca espera. Qué sonido es lo elige `ScreamerManager`, en la Tarea 12.

- [ ] **Paso 1: Escribir las pruebas**

`test/test_hallucination_clock.gd`:

```gdscript
extends "res://test/test_case.gd"

const HallucinationClock := preload("res://scripts/core/hallucination_clock.gd")


func _clock() -> HallucinationClock:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return HallucinationClock.new(BalanceData.new(), rng)


## Cuántas alucinaciones suenan en `seconds` segundos, de a 1, con Sanity en `sanity`.
func _count(clock: HallucinationClock, seconds: int, sanity: float, allowed := true) -> int:
	var count := 0
	for _i in seconds:
		if clock.advance(1.0, sanity, allowed):
			count += 1
	return count


func test_con_sanity_alta_no_suenan() -> bool:
	check_eq(_count(_clock(), 300, 50.0), 0, "con Sanity en 50, ninguna")
	return true


func test_mas_seguidas_y_mas_fuertes_mientras_mas_baja() -> bool:
	var clock := _clock()
	check(is_equal_approx(clock.interval(50.0), 40.0), "justo bajo 50, cada 40 s")
	check(is_equal_approx(clock.interval(25.0), 25.0), "con 25, cada 25 s")
	check(is_equal_approx(clock.interval(0.0), 10.0), "con 0, cada 10 s")
	check(is_equal_approx(clock.volume_db(50.0), HallucinationClock.QUIET_DB), "justo bajo 50, suaves")
	check(is_equal_approx(clock.volume_db(0.0), HallucinationClock.LOUD_DB), "con 0, fuertes")
	return true


func test_suenan_cada_tanto() -> bool:
	# Con Sanity en 0, cada 10 s ± 25 %: en 120 s, entre 9 y 16.
	var count := _count(_clock(), 120, 0.0)
	check(count >= 9 and count <= 16, "suenan seguido: %d" % count)
	return true


func test_esperan_durante_audio_sync() -> bool:
	var clock := _clock()
	check_eq(_count(clock, 60, 0.0, false), 0, "durante una ronda, ninguna")
	check(clock.advance(1.0, 0.0, true), "al terminar la ronda, suena la que esperaba")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `346 pruebas OK, 1 fallidas`. No se pudo cargar `test_hallucination_clock.gd`, porque `scripts/core/hallucination_clock.gd` no existe.

- [ ] **Paso 3: Crear `HallucinationClock`**

`scripts/core/hallucination_clock.gd`:

```gdscript
extends RefCounted
## Los screamers auditivos falsos (diseño §10.2): con Sanity bajo hallucination_start suenan sonidos que no
## vienen de nada, más seguidos y más fuertes mientras más baja. No restan Sanity (decisión de Benja): son un
## síntoma, no una causa. Lógica pura: ScreamerManager la avanza y hace sonar uno al azar.

## Volumen de una alucinación, en decibeles, con Sanity justo bajo hallucination_start y con Sanity en 0.
const QUIET_DB := -18.0
const LOUD_DB := -3.0

var _balance: BalanceData
var _rng: RandomNumberGenerator
## Sanity está bajo el umbral y corre la espera.
var _active := false
## Segundos que faltan para la próxima.
var _wait_left := 0.0


func _init(balance: BalanceData, rng: RandomNumberGenerator) -> void:
	_balance = balance
	_rng = rng


## Cuánto bajó Sanity desde el umbral: 0 justo bajo hallucination_start y 1 en 0.
func depth(sanity: float) -> float:
	return clampf(1.0 - sanity / _balance.hallucination_start, 0.0, 1.0)


## Segundos entre dos alucinaciones con esta Sanity, sin el azar.
func interval(sanity: float) -> float:
	return lerpf(_balance.hallucination_slowest, _balance.hallucination_fastest, depth(sanity))


func volume_db(sanity: float) -> float:
	return lerpf(QUIET_DB, LOUD_DB, depth(sanity))


## Avanza `delta` segundos. Devuelve true si ahora suena una. Si no está permitida (hay una ronda de Audio Sync
## o un screamer), la que toca espera.
func advance(delta: float, sanity: float, allowed: bool) -> bool:
	if sanity >= _balance.hallucination_start:
		_active = false
		return false
	if not _active:
		_active = true
		_wait_left = _next_wait(sanity)
	_wait_left -= delta
	if _wait_left > 0.0 or not allowed:
		return false
	_wait_left = _next_wait(sanity)
	return true


## La próxima espera: el espacio de esta Sanity, ± 25 %.
func _next_wait(sanity: float) -> float:
	return interval(sanity) * _rng.randf_range(0.75, 1.25)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `350 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Las alucinaciones" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: El susto baja Sanity y el jumpscare pausa la noche

**Archivos:**

- Modificar: `scripts/core/night_state.gd`, `scripts/desk/night_manager.gd`, `test/test_night_state.gd`, `test/test_night_manager.gd`

`NightState.scare()` baja Sanity de golpe. `NightManager.pause()` pausa la noche: mientras dura, `advance()` no avanza las solicitudes ni el estado de la noche, y si el paso es más largo que lo que queda de pausa, avanza solo lo que sobra.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_night_state.gd`:

```gdscript
func test_un_screamer_baja_sanity_de_golpe() -> bool:
	var state := _make_state()
	state.sanity = 50.0
	state.scare(8.0)
	check_eq(state.sanity, 42.0, "−8")
	state.scare(100.0)
	check_eq(state.sanity, 0.0, "no baja de 0")
	return true
```

Agregar al final de `test/test_night_manager.gd`:

```gdscript
func test_el_jumpscare_pausa_la_noche() -> bool:
	var night := _make_night()
	var request := _requests.start_request(1)
	night.pause(1.5)
	check(night.is_paused(), "en pausa")
	night.advance(1.0)
	check_eq(night.state().elapsed, 0.0, "la hora no avanza")
	check_eq(request.time_left, 45.0, "el temporizador tampoco")
	night.advance(1.0)
	check(not night.is_paused(), "la pausa terminó")
	check_eq(night.state().elapsed, 0.5, "avanza lo que sobra después de la pausa")
	check_eq(request.time_left, 44.5, "el temporizador también")
	_free(night)
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `350 pruebas OK, 2 fallidas`. Fallan `test_night_state.gd :: test_un_screamer_baja_sanity_de_golpe` y `test_night_manager.gd :: test_el_jumpscare_pausa_la_noche` ("la prueba no terminó"), porque `scare()` y `pause()` no existen.

- [ ] **Paso 3: El susto y la pausa**

En `scripts/core/night_state.gd`, reemplazar:

```gdscript
	return friends[friend_index].is_available()


## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2).
```

por:

```gdscript
	return friends[friend_index].is_available()


## Un screamer asustó a Matías: Sanity baja `amount` de golpe (diseño §10.2).
func scare(amount: float) -> void:
	sanity = maxf(sanity - amount, 0.0)


## Matías scrolleó el celular: durante scroll_grace segundos, Sanity sube (diseño §10.2).
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
## Al terminar, todo se detiene: los temporizadores, la hora y los medidores.
```

por:

```gdscript
## Al terminar, todo se detiene: los temporizadores, la hora y los medidores. Mientras el jumpscare tapa la
## pantalla, la noche se pausa (Plan 7, diseño §11).
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
var ended := false
```

por:

```gdscript
var ended := false

## Segundos que le quedan a la pausa.
var _pause_left := 0.0
```

En `scripts/desk/night_manager.gd`, reemplazar:

```gdscript
## Avanza la noche `delta` segundos. Cuando termina, ya no avanza más.
func advance(delta: float) -> void:
	if ended or requests == null:
```

por:

```gdscript
## Pausa la noche `seconds` segundos: no avanzan los temporizadores, la hora ni los medidores (diseño §11).
func pause(seconds: float) -> void:
	_pause_left = maxf(_pause_left, seconds)


func is_paused() -> bool:
	return _pause_left > 0.0


## Avanza la noche `delta` segundos, menos lo que quede de pausa. Cuando termina, ya no avanza más.
func advance(delta: float) -> void:
	if ended or requests == null:
		return
	var paused := minf(_pause_left, delta)
	_pause_left -= paused
	delta -= paused
	if delta <= 0.0:
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `352 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "El susto baja Sanity y el jumpscare pausa la noche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Las solicitudes llegan en olas

**Archivos:**

- Modificar: `scripts/desk/request_manager.gd`, `test/test_request_manager.gd`

`RequestManager` crea el director junto con el estado de la noche, y le pregunta en cada paso si toca una solicitud. Si toca, se la da a un amigo libre al azar, como antes, sin pasar de las simultáneas; si no hay a quién, espera. Un amigo herido atrasa las que faltan. `FIRST_REQUEST_DELAY` pasa a `BalanceData.first_request_delay` (Tarea 1).

Cambian dos pruebas, que suponían el ritmo provisional (una solicitud cada 70 s en la noche 1): la que espera la segunda solicitud, que ahora llega cuando dice el director, y la de las simultáneas y el total, que se separa en dos. El helper `_make_manager()` acepta un catálogo, para cambiar la noche antes de que el director la planifique.

- [ ] **Paso 1: Cambiar las pruebas**

En `test/test_request_manager.gd`, reemplazar:

```gdscript
## Manager con el catálogo de prueba, en la noche 1 (solo "beast"), sin que las solicitudes lleguen solas.
func _make_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
```

por:

```gdscript
## Manager con el catálogo de prueba (u otro), en la noche 1 (solo "beast"), sin que las solicitudes lleguen
## solas.
func _make_manager(catalog: ContentCatalog = null) -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = catalog if catalog != null else Fixtures.make_catalog()
```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
	# Noche 1: 6 solicitudes, así que llegan cada 70 s. La primera se acaba a los 45 s (a los 50,1 s del total).
	manager.advance(69.0)
	check_eq(manager.active_count(), 0, "la primera ya terminó")
	manager.advance(1.0)
	check_eq(manager.active_count(), 1, "70 s después de la primera llega la segunda")
```

por:

```gdscript
	# La segunda llega cuando dice el director, más de 45 s después: la primera ya se acabó.
	var second: float = manager.director.request_times[0]
	manager.advance(second - 5.1 - 0.1)
	check_eq(manager.active_count(), 0, "la segunda todavía no llega")
	manager.advance(0.2)
	check_eq(manager.active_count(), 1, "la segunda llega a su hora")
```

En `test/test_request_manager.gd`, reemplazar:

```gdscript
func test_no_pasa_de_las_simultaneas_ni_del_total() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	var night := manager.night()
	night.requests_total = 2
	night.max_simultaneous = 1
	night.base_decision_time = 100.0
	manager.advance(5.0)
	manager.advance(90.0)
	check_eq(manager.active_count(), 1, "no pasa de 1 simultánea")
	for _i in 20:
		manager.advance(30.0)
	check_eq(manager.active_count(), 0, "no pasa de 2 en la noche")
```

por:

```gdscript
func test_no_pasa_de_las_simultaneas() -> bool:
	var manager := _make_manager()
	manager.requests_arrive = true
	manager.advance(5.0)
	check_eq(manager.active_count(), 1, "llega la primera")
	for request: FriendRequest in manager.requests:
		if request != null:
			request.time_left = 1000.0
	manager.advance(manager.director.request_times[0] - 5.0 + 1.0)
	check_eq(manager.active_count(), 1, "la noche 1 tiene 1 simultánea: la segunda espera")
	manager.free()
	return true


func test_no_pasa_del_total() -> bool:
	var catalog := Fixtures.make_catalog()
	catalog.nights[0].requests_total = 2
	# Sin heridas: un amigo herido atrasaría la segunda hasta que ya no alcanza a terminar.
	catalog.balance.risky_hurt_chance = 0.0
	catalog.balance.wrong_hurt_chance = 0.0
	var manager := _make_manager(catalog)
	manager.requests_arrive = true
	var started := []
	manager.request_started.connect(func(friend_index: int, _request: FriendRequest) -> void:
		started.append(friend_index))
	for _i in 420:
		manager.advance(1.0)
	check_eq(started.size(), 2, "2 solicitudes en la noche")
	manager.free()
	return true


func test_un_amigo_herido_atrasa_las_solicitudes() -> bool:
	var manager := _make_manager()
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var planned := manager.director.request_times.duplicate()
	var request := manager.start_request(0)
	manager.answer(0, _wrong_action(request))
	check(request.consequence.is_hurt(), "quedó herido")
	for index in planned.size():
		check(is_equal_approx(manager.director.request_times[index], planned[index] + 10.0), "atrasadas 10 s")
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `332 pruebas OK, 1 fallidas`. No se pudo cargar `test_request_manager.gd`, porque `RequestManager` todavía no tiene `director`.

- [ ] **Paso 3: Las solicitudes, cuando dice el director**

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## El ritmo es provisional, hasta el director del Plan 7: llega una solicitud cada
## (duración de la noche ÷ solicitudes de la noche) segundos, sin pasar de las simultáneas.
```

por:

```gdscript
## Desde el Plan 7, el director de ritmo (PacingDirector) decide cuándo llega cada solicitud: en olas, con un
## respiro después de cada una (decisión de Benja), sin pasar de las simultáneas.
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
const RequestGenerator := preload("res://scripts/core/request_generator.gd")

## Segundos hasta la primera solicitud.
const FIRST_REQUEST_DELAY := 5.0
```

por:

```gdscript
const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
var state: NightState

var _since_last_request := 0.0
var _started_count := 0
```

por:

```gdscript
var state: NightState
## Decide cuándo llega cada solicitud y cada screamer (Plan 7).
var director: PacingDirector

## Segundos desde las 00:00, como la hora del estado de la noche: el director cuenta en esa hora.
var _elapsed := 0.0
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
```

por:

```gdscript
	state = NightState.new(night(), catalog.balance, catalog.friends.size(), rng)
	director = PacingDirector.new(night(), catalog.balance, rng)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
func advance(delta: float) -> void:
```

por:

```gdscript
func advance(delta: float) -> void:
	_elapsed += delta
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		_maybe_start_request(delta)
```

por:

```gdscript
		_maybe_start_request()
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	requests[friend_index] = request
	_started_count += 1
```

por:

```gdscript
	requests[friend_index] = request
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
## depende de si quedó herido.
```

por:

```gdscript
## depende de si quedó herido. Un amigo herido atrasa las solicitudes que faltan (decisión de Benja).
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	state.apply(request.friend_index, request.consequence)
```

por:

```gdscript
	state.apply(request.friend_index, request.consequence)
	if request.consequence.is_hurt():
		director.friend_hurt()
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
func _maybe_start_request(delta: float) -> void:
	_since_last_request += delta
	var current := night()
	var wait := FIRST_REQUEST_DELAY if _started_count == 0 else catalog.balance.night_seconds / current.requests_total
	if _since_last_request < wait or _started_count >= current.requests_total:
		return
	if active_count() >= current.max_simultaneous:
```

por:

```gdscript
## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
## Si no hay a quién dársela, espera: el director atrasa las que faltan.
func _maybe_start_request() -> void:
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust)):
		return
	if active_count() >= night().max_simultaneous:
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
		_since_last_request = 0.0
```

por:

```gdscript
		director.request_started(_elapsed)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `354 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "Las solicitudes llegan en olas" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: El chat guionado

**Archivos:**

- Crear: `scripts/data/chat_line_data.gd`, `scripts/data/chat_script_data.gd`, `scripts/core/chat_script.gd`, `test/test_chat_script.gd`
- Modificar: `scripts/data/night_data.gd`, `scripts/core/message_builder.gd`, `scripts/core/content_validator.gd`, `scripts/desk/request_manager.gd`, `data/text/messages.csv`, `data/nights/night_1.tres`, `test/test_validator_catalog.gd`, `test/test_validator_texts.gd`

Un chat guionado es un dato de la noche (`NightData.scripted_chat`): un `ChatScriptData` con el amigo, las líneas (`ChatLineData`, de él o de Matías) y si el celular parpadea al terminar. `ChatScript` lo avanza: cada línea del amigo llega 2,5 s después de la anterior, y la de Matías espera su botón (`reply()`). `RequestManager` lo empieza (`start_chat_script()`), escribe sus líneas en el chat, dice qué línea espera el botón de cada amigo (`chat_script_reply()`) y avisa cuando termina (`chat_script_finished`). El validador revisa que el chat sea de un amigo del catálogo, que tenga líneas y que sus textos existan.

La noche 1 recibe el chat del susto guionado, con los textos de Benja tal cual, en `messages.csv`. Lo escribe Gonzalo (un borrador: se cambia en el Inspector).

- [ ] **Paso 1: Escribir las pruebas**

`test/test_chat_script.gd`:

```gdscript
extends "res://test/test_case.gd"

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatScript := preload("res://scripts/core/chat_script.gd")
const Fixtures := preload("res://test/content_fixtures.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")


## Un chat guionado de prueba: el amigo, Matías y el amigo otra vez.
func _chat_data(friend: FriendData) -> ChatScriptData:
	var data := ChatScriptData.new()
	data.friend = friend
	for entry: Array in [[ChatLineData.Speaker.FRIEND, "K_LINE_1"], [ChatLineData.Speaker.PLAYER, "K_LINE_2"],
			[ChatLineData.Speaker.FRIEND, "K_LINE_3"]]:
		var line := ChatLineData.new()
		line.speaker = entry[0]
		line.text_key = entry[1]
		data.lines.append(line)
	return data


func _make_manager() -> RequestManager:
	var manager := RequestManager.new()
	manager.catalog = Fixtures.make_catalog()
	manager.night_number = 1
	manager.random_seed = 7
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	return manager


func test_el_amigo_escribe_y_matias_responde_con_un_boton() -> bool:
	var chat := ChatScript.new(_chat_data(FriendData.new()), 1)
	check_eq(chat.advance(2.0), null, "el amigo está escribiendo")
	var first := chat.advance(0.5)
	check(first != null and first.text_key == "K_LINE_1", "a los 2,5 s llega su línea")
	var reply := chat.pending_reply()
	check(reply != null and reply.text_key == "K_LINE_2", "espera la respuesta de Matías")
	check_eq(chat.advance(30.0), null, "sin respuesta, el amigo espera")
	check_eq(chat.reply(), reply, "Matías responde")
	check_eq(chat.pending_reply(), null, "ya respondió")
	check_eq(chat.advance(2.0), null, "el amigo escribe")
	var last := chat.advance(0.5)
	check(last != null and last.text_key == "K_LINE_3", "llega la última")
	check(chat.is_done(), "terminó")
	check_eq(chat.reply(), null, "ya no hay nada que responder")
	return true


func test_el_manager_escribe_el_chat_guionado() -> bool:
	var manager := _make_manager()
	var events := []
	manager.message_added.connect(func(friend_index: int, message: ChatMessage) -> void:
		events.append([friend_index, message]))
	var finished := []
	manager.chat_script_finished.connect(func(chat: ChatScript) -> void: finished.append(chat))
	manager.start_chat_script(_chat_data(manager.catalog.friends[1]))
	manager.advance(2.5)
	check_eq(events.size(), 1, "Gonzalo escribe")
	if events.size() == 1:
		check_eq(events[0][0], 1, "en el chat de Gonzalo")
		check_eq((events[0][1] as ChatMessage).sender, ChatMessage.Sender.FRIEND, "lo escribe él")
		check_eq((events[0][1] as ChatMessage).plain_text(), String(TranslationServer.translate("K_LINE_1")), "su línea")
	check(manager.chat_script_reply(1) != null, "espera la respuesta de Matías")
	check_eq(manager.chat_script_reply(0), null, "en el chat de León, nada")
	check(manager.reply_chat_script(), "Matías responde")
	check_eq((events[-1][1] as ChatMessage).sender, ChatMessage.Sender.PLAYER, "lo escribe Matías")
	check(not manager.reply_chat_script(), "no responde dos veces")
	manager.advance(2.5)
	check_eq(events.size(), 3, "llega la última línea")
	check_eq(finished.size(), 1, "terminó")
	check_eq(manager.chat_script, null, "ya no hay chat guionado")
	manager.free()
	return true


func test_la_noche_1_tiene_el_chat_del_susto() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var chat := catalog.nights[0].scripted_chat
	check(chat != null, "la noche 1 tiene un chat guionado")
	if chat == null:
		return true
	check_eq(chat.friend, catalog.friends[1], "lo escribe Gonzalo")
	check_eq(chat.lines.map(func(line: ChatLineData) -> int: return line.speaker),
			[ChatLineData.Speaker.FRIEND, ChatLineData.Speaker.PLAYER, ChatLineData.Speaker.FRIEND],
			"Gonzalo, Matías y Gonzalo")
	check(chat.highlight_phone, "después, el celular parpadea")
	return true
```

Agregar al final de `test/test_validator_catalog.gd`:

```gdscript
func test_chat_guionado() -> bool:
	var catalog := Fixtures.make_catalog()
	var chat := ChatScriptData.new()
	chat.friend = FriendData.new()
	catalog.nights[0].scripted_chat = chat
	var errors := ContentValidator.validate_catalog(catalog)
	check_contains(errors, "Noche 1: el chat guionado no es de un amigo del catálogo")
	check_contains(errors, "Noche 1: el chat guionado no tiene líneas")
	return true
```

Agregar al final de `test/test_validator_texts.gd`:

```gdscript
func test_lineas_del_chat_guionado() -> bool:
	var catalog := Fixtures.make_catalog()
	var line := ChatLineData.new()
	line.text_key = "K_LINE"
	var chat := ChatScriptData.new()
	chat.friend = catalog.friends[0]
	chat.lines.append(line)
	catalog.nights[0].scripted_chat = chat
	var errors := ContentValidator.validate_texts(catalog, _translate_except(["K_LINE"]))
	check_contains(errors, "Noche 1, chat guionado, línea 1: la clave 'K_LINE' no está en ningún CSV")
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `341 pruebas OK, 3 fallidas`. No se pudieron cargar `test_chat_script.gd`, `test_validator_catalog.gd` ni `test_validator_texts.gd`, porque las clases `ChatScriptData` y `ChatLineData` no existen.

- [ ] **Paso 3: El chat guionado**

`scripts/data/chat_line_data.gd`:

```gdscript
class_name ChatLineData
extends Resource
## Una línea de un chat guionado (decisión de Benja, sesión 16): la escribe el amigo o la responde Matías
## con un botón.

enum Speaker { FRIEND, PLAYER }

@export var speaker: Speaker = Speaker.FRIEND
## El texto, en messages.csv.
@export var text_key: String
```

`scripts/data/chat_script_data.gd`:

```gdscript
class_name ChatScriptData
extends Resource
## Un chat guionado (decisión de Benja, sesión 16): un amigo y Matías conversan siguiendo un guion, fuera de
## las solicitudes. El primero es el que sigue al susto guionado y enseña el celular.

## Quién escribe: uno de los amigos del catálogo.
@export var friend: FriendData
## Las líneas, en orden. Las de Matías esperan su botón.
@export var lines: Array[ChatLineData] = []
## Al terminar, el celular del escritorio parpadea hasta que Matías lo abre.
@export var highlight_phone := false
```

En `scripts/data/night_data.gd`, reemplazar:

```gdscript
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE
```

por:

```gdscript
@export var scripted_scare: ScareKind.Kind = ScareKind.Kind.JUMPSCARE
## El chat guionado que sigue al susto guionado (decisión de Benja, sesión 16), o ninguno.
@export var scripted_chat: ChatScriptData
```

`scripts/core/chat_script.gd`:

```gdscript
extends RefCounted
## Un chat guionado en curso (decisión de Benja, sesión 16): el amigo escribe sus líneas y Matías responde las
## suyas con un botón. Cada línea del amigo llega LINE_DELAY segundos después de la anterior, como si
## escribiera. Lógica pura: RequestManager la avanza y escribe las líneas en el chat.

## Segundos que tarda el amigo en escribir cada línea.
const LINE_DELAY := 2.5

var data: ChatScriptData
var friend_index := 0
## La próxima línea, contada desde la primera.
var next_line := 0

var _wait_left := LINE_DELAY


func _init(script_data: ChatScriptData, script_friend: int) -> void:
	data = script_data
	friend_index = script_friend


func is_done() -> bool:
	return next_line >= data.lines.size()


## La línea de Matías que espera su botón, o null.
func pending_reply() -> ChatLineData:
	if is_done():
		return null
	var line := data.lines[next_line]
	return line if line.speaker == ChatLineData.Speaker.PLAYER else null


## Matías respondió. Devuelve su línea, o null si no había nada que responder.
func reply() -> ChatLineData:
	var line := pending_reply()
	if line != null:
		next_line += 1
		_wait_left = LINE_DELAY
	return line


## Avanza `delta` segundos. Devuelve la línea del amigo que llega ahora, o null. Mientras espera la respuesta
## de Matías, no avanza.
func advance(delta: float) -> ChatLineData:
	if is_done() or pending_reply() != null:
		return null
	_wait_left -= delta
	if _wait_left > 0.0:
		return null
	var line := data.lines[next_line]
	next_line += 1
	_wait_left = LINE_DELAY
	return line
```

En `scripts/core/message_builder.gd`, reemplazar:

```gdscript
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

por:

```gdscript
	return message


## Una línea de un chat guionado, del amigo o de Matías, sin solicitud.
static func script_line(line: ChatLineData, translate: Callable) -> ChatMessage:
	var sender := ChatMessage.Sender.PLAYER if line.speaker == ChatLineData.Speaker.PLAYER else ChatMessage.Sender.FRIEND
	var message := ChatMessage.new(sender, null)
	message.add_fragment(_text(translate, line.text_key))
	return message


static func _observation_text(request: FriendRequest, observation: ObservationData, translate: Callable) -> String:
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
					% [who, index + 1, night.number])
```

por:

```gdscript
					% [who, index + 1, night.number])
		_check_scripted_chat(errors, catalog, night)
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
		keys.append(["Noche %d" % night.number, night.place_key])
```

por:

```gdscript
		keys.append(["Noche %d" % night.number, night.place_key])
		if night.scripted_chat != null:
			for index in night.scripted_chat.lines.size():
				var line := night.scripted_chat.lines[index]
				if line != null:
					keys.append(["Noche %d, chat guionado, línea %d" % [night.number, index + 1], line.text_key])
```

En `scripts/core/content_validator.gd`, reemplazar:

```gdscript
	return keys
```

por:

```gdscript
	return keys


## El chat guionado de una noche, si tiene: de un amigo del catálogo y con líneas.
static func _check_scripted_chat(errors: Array[String], catalog: ContentCatalog, night: NightData) -> void:
	var chat := night.scripted_chat
	if chat == null:
		return
	var who := "Noche %d: el chat guionado" % night.number
	if not catalog.friends.has(chat.friend):
		errors.append(who + " no es de un amigo del catálogo")
	if chat.lines.is_empty():
		errors.append(who + " no tiene líneas")
	elif chat.lines.has(null):
		errors.append(who + " tiene un espacio vacío en 'lines'")
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
signal request_finished(friend_index: int, request: FriendRequest)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
```

por:

```gdscript
signal request_finished(friend_index: int, request: FriendRequest)
## Terminó el chat guionado (Plan 7).
signal chat_script_finished(chat: ChatScript)

const ChatMessage := preload("res://scripts/core/chat_message.gd")
const ChatScript := preload("res://scripts/core/chat_script.gd")
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
var director: PacingDirector
```

por:

```gdscript
var director: PacingDirector
## El chat guionado en curso, o null (Plan 7).
var chat_script: ChatScript
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
			_decide_alone(index)
```

por:

```gdscript
			_decide_alone(index)
	_advance_chat_script(delta)
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	request_finished.emit(friend_index, request)
	return true
```

por:

```gdscript
	request_finished.emit(friend_index, request)
	return true


## Empieza el chat guionado `data`: su amigo escribe sus líneas y Matías responde las suyas con un botón
## (decisión de Benja). Sin un amigo del catálogo o sin líneas, no pasa nada.
func start_chat_script(data: ChatScriptData) -> void:
	if data == null or data.lines.is_empty():
		return
	var friend_index := catalog.friends.find(data.friend)
	if friend_index < 0:
		return
	chat_script = ChatScript.new(data, friend_index)


## La línea que Matías tiene que responder en el chat del amigo `friend_index`, o null.
func chat_script_reply(friend_index: int) -> ChatLineData:
	if chat_script == null or chat_script.friend_index != friend_index:
		return null
	return chat_script.pending_reply()


## Matías responde con el botón del chat guionado. Devuelve false si no había nada que responder.
func reply_chat_script() -> bool:
	if chat_script == null:
		return false
	var line := chat_script.reply()
	if line == null:
		return false
	message_added.emit(chat_script.friend_index, MessageBuilder.script_line(line, tr))
	_finish_chat_script_if_done()
	return true
```

En `scripts/desk/request_manager.gd`, reemplazar:

```gdscript
	message_added.emit(friend_index, message)


## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
```

por:

```gdscript
	message_added.emit(friend_index, message)


## El amigo del chat guionado escribe su próxima línea cuando le toca.
func _advance_chat_script(delta: float) -> void:
	if chat_script == null:
		return
	var line := chat_script.advance(delta)
	if line != null:
		_add_friend_message(chat_script.friend_index, MessageBuilder.script_line(line, tr))
	_finish_chat_script_if_done()


func _finish_chat_script_if_done() -> void:
	if chat_script == null or not chat_script.is_done():
		return
	var finished := chat_script
	chat_script = null
	chat_script_finished.emit(finished)


## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
```

Agregar al final de `data/text/messages.csv`:

```csv
SCRIPT_SCARE_ASK,Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar,
SCRIPT_SCARE_REPLY,"Creo que me estoy volviendo loco, no sé si puedo seguir",
SCRIPT_SCARE_PHONE,"Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar",
```

En `data/nights/night_1.tres`, reemplazar:

```ini
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
```

por:

```ini
[ext_resource type="Script" path="res://scripts/data/entity_data.gd" id="2_entity"]
[ext_resource type="Script" path="res://scripts/data/chat_script_data.gd" id="3_chat"]
[ext_resource type="Script" path="res://scripts/data/chat_line_data.gd" id="4_line"]
[ext_resource type="Resource" path="res://data/friends/gonzalo.tres" id="5_gonzalo"]

[sub_resource type="Resource" id="Line_ask"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_ASK"

[sub_resource type="Resource" id="Line_reply"]
script = ExtResource("4_line")
speaker = 1
text_key = "SCRIPT_SCARE_REPLY"

[sub_resource type="Resource" id="Line_phone"]
script = ExtResource("4_line")
text_key = "SCRIPT_SCARE_PHONE"

[sub_resource type="Resource" id="Chat_scare"]
script = ExtResource("3_chat")
friend = ExtResource("5_gonzalo")
lines = Array[ExtResource("4_line")]([SubResource("Line_ask"), SubResource("Line_reply"), SubResource("Line_phone")])
highlight_phone = true
```

En `data/nights/night_1.tres`, reemplazar:

```ini
scripted_scare_time = 60.0
```

por:

```ini
scripted_scare_time = 60.0
scripted_chat = SubResource("Chat_scare")
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `359 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ data/ test/
git commit -m "El chat guionado" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: Sonidos provisionales de los screamers

**Archivos:**

- Modificar: `tools/make_placeholder_sounds.py`, `test/test_placeholder_sounds.gd`
- Crear (los genera el script): `audio/sfx/ambient_room.wav`, `scare_curtains.wav`, `scare_window.wav`, `scare_phone.wav`, `scare_lights.wav`, `scare_slam.wav`, `scare_ink.wav`, `scare_jumpscare.wav`, `hallucination_knock.wav`, `hallucination_steps.wav`, `hallucination_whisper.wav` y `hallucination_scratch.wav`

El script genera 12 sonidos más: el ambiente del cuarto (8 s que se repiten), uno por screamer y cuatro alucinaciones. Las alucinaciones también usan dos sonidos que ya existen: la estática (`interference_static.wav`) y el celular (`scare_phone.wav`). Los 7 sonidos del Plan 6 salen idénticos.

- [ ] **Paso 1: Escribir la prueba**

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
## Los sonidos provisionales del Plan 6 (tools/make_placeholder_sounds.py), hasta los definitivos del Plan 9.
```

por:

```gdscript
## Los sonidos provisionales de los planes 6 y 7 (tools/make_placeholder_sounds.py), hasta los definitivos del
## Plan 9.
```

En `test/test_placeholder_sounds.gd`, reemplazar:

```gdscript
	"interference_static": 3.0,
```

por:

```gdscript
	"interference_static": 3.0,
	"ambient_room": 8.0,
	"scare_curtains": 1.2,
	"scare_window": 1.5,
	"scare_phone": 1.2,
	"scare_lights": 1.5,
	"scare_slam": 0.5,
	"scare_ink": 0.6,
	"scare_jumpscare": 1.5,
	"hallucination_knock": 1.0,
	"hallucination_steps": 2.0,
	"hallucination_whisper": 2.0,
	"hallucination_scratch": 1.5,
```

- [ ] **Paso 2: Verificar que falla**

Importar y correr las pruebas.

Esperado: `358 pruebas OK, 1 fallidas`. Falla `test_placeholder_sounds.gd :: test_los_sonidos_se_cargan`, porque los sonidos nuevos no existen.

- [ ] **Paso 3: Generar los sonidos**

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
"""Genera los sonidos provisionales del Plan 6 en audio/sfx/ (WAV mono de 16 bits a 44 100 Hz).

Son de relleno, hasta que Benja elija los definitivos (Plan 9): la base y los aplausos de Audio Sync,
el golpe de Matías, el resultado de una ronda y la estática que anuncia una interferencia.
```

por:

```python
"""Genera los sonidos provisionales de los planes 6 y 7 en audio/sfx/ (WAV mono de 16 bits a 44 100 Hz).

Son de relleno, hasta que Benja elija los definitivos (Plan 9):
- Plan 6: la base y los aplausos de Audio Sync, el golpe de Matías, el resultado de una ronda y la estática
  que anuncia una interferencia;
- Plan 7: el sonido ambiente del cuarto, uno por screamer y los cuatro de las alucinaciones.
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    return samples


if __name__ == "__main__":
```

por:

```python
    return samples


def noise(seed):
    """Ruido blanco que siempre sale igual."""
    rng = random.Random(seed)
    return lambda: rng.uniform(-1, 1)


def ambient():
    """Sonido ambiente del cuarto, 8 s que se repiten: viento grave que sube y baja, y un zumbido eléctrico."""
    white, samples, low, lower, seconds = noise(11), [], 0.0, 0.0, 8.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.02 * (white() - low)
        lower += 0.1 * (low - lower)
        gust = 0.6 + 0.4 * math.sin(2 * math.pi * t / seconds) * math.sin(2 * math.pi * 3 * t / seconds)
        hum = 0.03 * math.sin(2 * math.pi * 50 * t) + 0.015 * math.sin(2 * math.pi * 100 * t)
        fade = min(t / 0.5, 1.0, (seconds - t) / 0.5)
        samples.append((3.0 * lower * gust + hum) * fade)
    return samples


def rustle():
    """La cortina: roce de tela, ráfagas de ruido que suben y bajan."""
    white, samples, last_x, last_y, seconds = noise(12), [], 0.0, 0.0, 1.2
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.8 * (last_y + x - last_x), x
        swish = abs(math.sin(2 * math.pi * 2.5 * t)) ** 2
        samples.append(0.5 * last_y * swish * math.exp(-t * 1.5))
    return samples


def sting():
    """La figura de la ventana: un golpe grave y un chillido que sube."""
    white, samples, phase, seconds = noise(13), [], 0.0, 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        boom = 0.8 * math.sin(2 * math.pi * 48 * t) * math.exp(-t * 4)
        phase += 2 * math.pi * (900 + 500 * t / seconds + 25 * math.sin(2 * math.pi * 7 * t)) / RATE
        screech = 0.3 * (math.sin(phase) + 0.4 * math.sin(2.01 * phase)) * min(t / 0.05, 1.0) * math.exp(-t * 1.8)
        samples.append(boom + screech + 0.05 * white() * math.exp(-t * 3))
    return samples


def buzz():
    """El celular vibra: tres zumbidos graves."""
    samples, seconds, partials = [], 1.2, ((160, 1.0), (320, 0.5), (480, 0.3))
    for i in range(int(seconds * RATE)):
        t = i / RATE
        on = (t % 0.4) < 0.3
        tone = sum(volume * math.sin(2 * math.pi * frequency * t) for frequency, volume in partials)
        samples.append(0.35 * tone if on else 0.0)
    return samples


def flicker():
    """Las luces parpadean: zumbido eléctrico que se corta, con chasquidos."""
    white, rng, samples, seconds = noise(14), random.Random(15), [], 1.5
    cut, crackle = False, 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        if i % 2205 == 0:
            cut = rng.random() < 0.4
        if rng.random() < 0.003:
            crackle = 1.0
        crackle *= 0.995
        hum = sum(math.sin(2 * math.pi * 100 * h * t) / h for h in (1, 2, 3, 5))
        samples.append((0.0 if cut else 0.25 * hum) + 0.5 * crackle * white())
    return samples


def slam():
    """El cuaderno se cierra de golpe: un golpe seco y grave."""
    white, samples, seconds = noise(16), [], 0.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        samples.append(0.7 * math.sin(2 * math.pi * 70 * t) * math.exp(-t * 18) + 0.3 * white() * math.exp(-t * 60))
    return samples


def splat():
    """La mancha de tinta: algo húmedo que se aplasta y gotea."""
    white, samples, low, seconds = noise(17), [], 0.0, 0.6
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.15 * (white() - low)
        drips = sum(math.exp(-(t - start) * 40) for start in (0.25, 0.38, 0.47) if t >= start)
        samples.append(1.2 * low * (math.exp(-t * 14) + 0.4 * drips))
    return samples


def scream():
    """El jumpscare: un grito disonante y fuerte."""
    white, samples, phases, seconds = noise(18), [], [0.0, 0.0, 0.0], 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for index, base in enumerate((520, 555, 740)):
            phases[index] += 2 * math.pi * (base + 40 * math.sin(2 * math.pi * (6 + index) * t)) / RATE
            value += 2 * (phases[index] / (2 * math.pi) % 1.0) - 1
        envelope = min(t / 0.02, 1.0) * (1.0 if t < 1.0 else (seconds - t) / 0.5)
        samples.append((0.22 * value + 0.25 * white()) * envelope)
    return samples


def knock():
    """Alucinación: tres golpes en la ventana."""
    samples, seconds = [], 1.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for start in (0.0, 0.25, 0.5):
            if t >= start:
                local = t - start
                value += math.sin(2 * math.pi * 130 * local) * math.exp(-local * 35)
                value += 0.3 * math.sin(2 * math.pi * 900 * local) * math.exp(-local * 200)
        samples.append(0.8 * value)
    return samples


def steps():
    """Alucinación: cuatro pasos lentos sobre madera."""
    white, samples, low, seconds = noise(19), [], 0.0, 2.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.2 * (white() - low)
        value = 0.0
        for start in (0.0, 0.5, 1.0, 1.5):
            if t >= start:
                local = t - start
                value += 0.6 * math.sin(2 * math.pi * 85 * local) * math.exp(-local * 25)
                value += 0.6 * low * math.exp(-local * 30)
        samples.append(value)
    return samples


def whisper():
    """Alucinación: un susurro sin palabras, ruido agudo con sílabas."""
    white, samples, last_x, last_y, seconds = noise(20), [], 0.0, 0.0, 2.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.6 * (last_y + x - last_x), x
        syllables = max(math.sin(2 * math.pi * 4.5 * t) * math.sin(2 * math.pi * 1.3 * t + 1.0), 0.0)
        fade = min(t / 0.2, 1.0, (seconds - t) / 0.3)
        samples.append(0.7 * last_y * syllables * fade)
    return samples


def scratch():
    """Alucinación: rasguños en la pared, trazos de ruido áspero."""
    white, samples, last_x, last_y, seconds = noise(21), [], 0.0, 0.0, 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.7 * (last_y + x - last_x), x
        stroke = (t % 0.5) / 0.5
        grain = 0.5 + 0.5 * math.sin(2 * math.pi * 60 * t)
        samples.append(0.6 * last_y * math.sin(math.pi * stroke) * grain)
    return samples


if __name__ == "__main__":
```

En `tools/make_placeholder_sounds.py`, reemplazar:

```python
    write("interference_static", static())
```

por:

```python
    write("interference_static", static())
    write("ambient_room", ambient())
    write("scare_curtains", rustle())
    write("scare_window", sting())
    write("scare_phone", buzz())
    write("scare_lights", flicker())
    write("scare_slam", slam())
    write("scare_ink", splat())
    write("scare_jumpscare", scream())
    write("hallucination_knock", knock())
    write("hallucination_steps", steps())
    write("hallucination_whisper", whisper())
    write("hallucination_scratch", scratch())
```

Después, generar los sonidos:

```bash
python3 -I tools/make_placeholder_sounds.py
git status --short audio/
```

Esperado: `Sonidos provisionales en …/audio/sfx`, y `git status` muestra solo los 12 `.wav` nuevos (`??`): los 7 del Plan 6 no cambian.

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `359 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

`git add` incluye los `.import` que Godot creó al importar los sonidos.

```bash
git add tools/ audio/ test/
git commit -m "Sonidos provisionales de los screamers" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: El cuaderno se cierra de golpe o se mancha de tinta

**Archivos:**

- Crear: `scripts/ui/ink_blot.gd`
- Modificar: `scripts/ui/notebook_panel.gd`, `scenes/ui/notebook_panel.tscn`, `test/test_notebook_panel.gd`

Los dos screamers del cuaderno:

- `slam()`: el cuaderno se cierra de golpe. La página de cada amigo se conserva, así que al abrirlo vuelve a la misma;
- `splash_ink(seconds)`: una mancha de tinta (`InkBlot`) tapa casi toda la página unos segundos y se desvanece al final. No tapa los clics. Es provisional: se dibuja con círculos, siempre con la misma forma;
- `shows_page()`: el cuaderno está abierto en la página de una entidad, donde la tinta tiene reglas que tapar.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_notebook_panel.gd`:

```gdscript
func test_la_tinta_tapa_la_pagina_unos_segundos() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _entities[0])
	panel.open_for(0)
	var ink := panel.get_node("InkBlot") as Control
	check(not ink.visible, "sin tinta")
	panel.splash_ink(5.0)
	check(ink.visible, "la mancha tapa la página")
	check_eq(ink.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no tapa los clics")
	ink._process(4.0)
	check(ink.visible, "a los 4 s sigue")
	ink._process(1.1)
	check(not ink.visible, "a los 5 s se fue")
	panel.free()
	return true


func test_el_golpe_cierra_el_cuaderno_y_conserva_la_pagina() -> bool:
	var panel := _make_panel()
	_memory.open_page(0, _entities[1])
	panel.open_for(0)
	check(panel.shows_page(), "abierto en una página")
	panel.slam()
	check(not panel.visible, "se cerró de golpe")
	check(not panel.shows_page(), "cerrado, no muestra nada")
	panel.open_for(0)
	check_eq(_title(panel).text, String(TranslationServer.translate(_entities[1].name_key)), "al abrirlo, la misma página")
	panel.free()
	return true


func test_en_el_indice_no_muestra_una_pagina() -> bool:
	var panel := _make_panel()
	panel.open_for(0)
	check(not panel.shows_page(), "en el índice")
	panel.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `359 pruebas OK, 3 fallidas`. Fallan las 3 pruebas nuevas de `test_notebook_panel.gd` ("la prueba no terminó"), porque el cuaderno no tiene `InkBlot` ni las funciones nuevas.

- [ ] **Paso 3: El golpe y la tinta**

`scripts/ui/ink_blot.gd`:

```gdscript
extends Control
## La mancha de tinta del screamer del cuaderno (diseño §11): tapa la página unos segundos y se desvanece al
## final. Provisional hasta el arte de Benja (docs/06 §3): se dibuja con círculos, siempre con la misma forma.

## Segundos que tarda en desvanecerse, al final.
const FADE_SECONDS := 0.5
const INK_COLOR := Color(0.05, 0.04, 0.08)
const SHAPE_SEED := 23

## Segundos que le quedan.
var time_left := 0.0


func _ready() -> void:
	hide()


## Aparece y tapa la página `seconds` segundos.
func splash(seconds: float) -> void:
	time_left = seconds
	modulate.a = 1.0
	show()


func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	modulate.a = clampf(time_left / FADE_SECONDS, 0.0, 1.0)
	if time_left <= 0.0:
		hide()


## Tres manchas grandes, una sobre otra, chorreones que caen de la última y salpicaduras alrededor: tapan casi
## toda la página sin salirse del rectángulo.
func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SHAPE_SEED
	var radius := size.x * 0.24
	var middle := size / 2.0
	var centers: Array[Vector2] = []
	for offset: float in [-0.22, 0.0, 0.22]:
		centers.append(middle + Vector2(0.0, size.y * offset))
	for center: Vector2 in centers:
		draw_circle(center, radius, INK_COLOR)
		for _i in 8:
			var angle := rng.randf_range(0.0, TAU)
			var distance := rng.randf_range(0.5, 1.0) * radius
			draw_circle(center + Vector2.from_angle(angle) * distance, rng.randf_range(0.35, 0.6) * radius, INK_COLOR)
	var bottom := centers[-1]
	for _i in 5:
		var x := bottom.x + rng.randf_range(-0.8, 0.8) * radius
		var length := rng.randf_range(0.6, 1.4) * radius
		draw_rect(Rect2(x - 4.0, bottom.y, 8.0, length), INK_COLOR)
		draw_circle(Vector2(x, bottom.y + length), 7.0, INK_COLOR)
	for _i in 24:
		var angle := rng.randf_range(0.0, TAU)
		var reach := Vector2(rng.randf_range(1.3, 1.6), rng.randf_range(1.0, 2.6)) * radius
		draw_circle(middle + Vector2(cos(angle), sin(angle)) * reach, rng.randf_range(3.0, 9.0), INK_COLOR)
```

En `scripts/ui/notebook_panel.gd`, reemplazar:

```gdscript
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.
```

por:

```gdscript
## Se cierra con clic derecho; Esc y un clic fuera de los paneles los cierran desde el escritorio.
## Desde el Plan 7, dos screamers lo usan: se cierra de golpe, o una mancha de tinta tapa la página.
```

En `scripts/ui/notebook_panel.gd`, reemplazar:

```gdscript
@onready var _body: RichTextLabel = $Page/Layout/Scroll/Content/Body
```

por:

```gdscript
@onready var _body: RichTextLabel = $Page/Layout/Scroll/Content/Body
@onready var _ink: Control = $InkBlot
```

En `scripts/ui/notebook_panel.gd`, reemplazar:

```gdscript
	_refresh()


func _refresh() -> void:
```

por:

```gdscript
	_refresh()


## El screamer de la tinta: una mancha tapa la página `seconds` segundos (diseño §11).
func splash_ink(seconds: float) -> void:
	_ink.splash(seconds)


## El screamer del golpe: el cuaderno se cierra de golpe. La página de cada amigo se conserva.
func slam() -> void:
	hide()


## Está abierto en la página de una entidad, no en el índice: la tinta tiene reglas que tapar.
func shows_page() -> bool:
	return visible and _shown_entity != null


func _refresh() -> void:
```

En `scenes/ui/notebook_panel.tscn`, reemplazar:

```ini
[ext_resource type="Theme" path="res://scenes/ui/notebook_theme.tres" id="notebook_theme"]
```

por:

```ini
[ext_resource type="Theme" path="res://scenes/ui/notebook_theme.tres" id="notebook_theme"]
[ext_resource type="Script" path="res://scripts/ui/ink_blot.gd" id="ink_script"]
```

En `scenes/ui/notebook_panel.tscn`, reemplazar:

```ini
scroll_active = false
```

por:

```ini
scroll_active = false

[node name="InkBlot" type="Control" parent="."]
visible = false
layout_mode = 0
offset_left = 836.0
offset_top = 96.0
offset_right = 1253.0
offset_bottom = 690.0
mouse_filter = 2
script = ExtResource("ink_script")
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `362 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ test/
git commit -m "El cuaderno se cierra de golpe o se mancha de tinta" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: El contorno que parpadea

**Archivos:**

- Modificar: `scripts/desk/clickable_sprite.gd`, `test/test_clickable_sprite.gd`

Un objeto del escritorio puede pedir atención (`blinking`): su contorno parpadea, 0,4 s encendido y 0,4 s apagado, hasta que se apague. Con el mouse encima, el contorno se ve siempre, como antes. Así se enseña el celular (decisión de Benja).

- [ ] **Paso 1: Escribir la prueba**

Agregar al final de `test/test_clickable_sprite.gd`:

```gdscript
func test_parpadea_cuando_pide_atencion() -> bool:
	var phone := _make_phone()
	# Lejos del mouse, para que no se resalte.
	phone.position = Vector2(5000, 5000)
	var material := phone.material as ShaderMaterial
	phone.blinking = true
	phone._process(0.1)
	check_eq(material.get_shader_parameter("enabled"), true, "encendido")
	phone._process(0.4)
	check_eq(material.get_shader_parameter("enabled"), false, "apagado")
	phone._process(0.4)
	check_eq(material.get_shader_parameter("enabled"), true, "encendido otra vez")
	phone.blinking = false
	phone._process(0.1)
	check_eq(material.get_shader_parameter("enabled"), false, "deja de parpadear")
	phone.free()
	return true
```

- [ ] **Paso 2: Verificar que falla**

Importar y correr las pruebas.

Esperado: `362 pruebas OK, 1 fallidas`. Falla `test_clickable_sprite.gd :: test_parpadea_cuando_pide_atencion` ("la prueba no terminó"), porque `blinking` no existe.

- [ ] **Paso 3: El parpadeo**

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
## Objeto del escritorio que se resalta al pasar el mouse y emite `clicked`.
```

por:

```gdscript
## Objeto del escritorio que se resalta al pasar el mouse y emite `clicked`. Desde el Plan 7, su contorno
## también puede parpadear para pedir atención (así se enseña el celular, decisión de Benja).
```

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
```

por:

```gdscript
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
## Segundos que el contorno está encendido, y después apagado, mientras parpadea.
const BLINK_SECONDS := 0.4
```

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
		(material as ShaderMaterial).set_shader_parameter("enabled", value)

var _bitmap: BitMap
```

por:

```gdscript
		_refresh_outline()
## Pide atención: el contorno parpadea hasta que se apague.
var blinking := false:
	set(value):
		blinking = value
		_blink_time = 0.0

var _bitmap: BitMap
var _blink_time := 0.0
```

En `scripts/desk/clickable_sprite.gd`, reemplazar:

```gdscript
func _process(_delta: float) -> void:
	# Si un panel abierto (como el chat) tapa el objeto, el mouse está sobre el panel: no se resalta.
	hovered = is_visible_in_tree() and get_viewport().gui_get_hovered_control() == null \
			and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)
```

por:

```gdscript
func _process(delta: float) -> void:
	_blink_time += delta
	# Si un panel abierto (como el chat) tapa el objeto, el mouse está sobre el panel: no se resalta.
	hovered = is_visible_in_tree() and get_viewport().gui_get_hovered_control() == null \
			and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)
	_refresh_outline()


## El contorno se ve con el mouse encima o, si parpadea, en la mitad encendida de cada parpadeo.
func _refresh_outline() -> void:
	if material == null:
		return
	var blink_on := blinking and fmod(_blink_time, BLINK_SECONDS * 2.0) < BLINK_SECONDS
	(material as ShaderMaterial).set_shader_parameter("enabled", hovered or blink_on)
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `363 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ test/
git commit -m "El contorno que parpadea" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: Los screamers en el escritorio

**Archivos:**

- Crear: `scripts/desk/screamer_manager.gd`, `test/test_screamer_manager.gd`
- Modificar: `scenes/desk/desk.tscn`, `scripts/desk/desk.gd`, `test/run_tests.gd`

`ScreamerManager` es un nodo del escritorio (`Screamers`). El escritorio lo avanza en cada frame con lo que se ve (`_scare_view()`) y con si hay una ronda de Audio Sync:

- cuando el director dice que toca un screamer, elige uno con `Screamer.pick()` y lo anuncia con su señal previa: la oscuridad (`Darkness`) parpadea y el sonido ambiente (`Ambient`) baja. Al terminar la señal, lo muestra (`play()`) con su sonido y resta Sanity;
- los screamers: la cortina se mece, la figura aparece en la ventana, el celular vibra, las luces se apagan, el cuaderno se cierra de golpe o se mancha de tinta, y el jumpscare (`Overlay/Jumpscare`, entre la viñeta y la pantalla final) tapa la pantalla y pausa la noche;
- el susto guionado llega cuando el director lo dice, y después empieza su chat guionado;
- con Sanity bajo, `HallucinationClock` dice cuándo suena una alucinación: uno de sus 6 sonidos al azar (`hallucination_sounds`), a la izquierda o a la derecha de la pantalla (`Hallucination`, un `AudioStreamPlayer2D`);
- nada de esto empieza durante una ronda de Audio Sync, durante la pausa del jumpscare ni después de que termina la noche.

La figura de la ventana (`WallPlane/Enemy`) empieza escondida (decisión de Benja). El ejecutor de pruebas espera 0,2 s antes de salir, para que se liberen los sonidos que las pruebas dejan sonando.

- [ ] **Paso 1: Escribir las pruebas**

Las pruebas llaman a `desk._process()`, que avanza los screamers, sin avanzar la noche: así la hora queda quieta y nada llega solo.

`test/test_screamer_manager.gd`:

```gdscript
extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")


## El escritorio en la noche 3, con un azar fijo. Nada avanza solo: las pruebas llaman a desk._process().
func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").random_seed = 11
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func _screamers(desk: Node2D) -> Node:
	return desk.get_node_or_null("Screamers")


func _state(desk: Node2D) -> NightState:
	return desk.get_node("RequestManager").state


## El próximo screamer del director toca ahora. Si `jumpscare`, es el jumpscare.
func _scare_now(desk: Node2D, jumpscare := false) -> void:
	var director: RefCounted = desk.get_node("RequestManager").director
	director.scare_times.assign([_state(desk).elapsed])
	director.jumpscare_at = 0 if jumpscare else -1


## Guarda en `kinds` cada screamer que empieza.
func _record(desk: Node2D, kinds: Array) -> void:
	_screamers(desk).scare_started.connect(func(kind: ScareKind.Kind) -> void: kinds.append(kind))


## Avanza el escritorio `seconds` segundos, de a 1.
func _process(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk._process(1.0)


func test_la_figura_de_la_ventana_esta_escondida() -> bool:
	var desk := _make_desk()
	check(not (desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura no está (decisión de Benja)")
	check(not (desk.get_node("Overlay/Jumpscare") as Control).visible, "sin jumpscare")
	check((desk.get_node("Ambient") as AudioStreamPlayer).playing, "suena el ambiente del cuarto")
	desk.free()
	return true


func test_un_screamer_se_anuncia_y_resta_sanity() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	var sanity := _state(desk).sanity
	_scare_now(desk)
	desk._process(0.0)
	check(_screamers(desk).is_warning(), "primero, la señal previa")
	check(kinds.is_empty(), "todavía no asusta")
	desk._process(1.0)
	check_eq(kinds.size(), 1, "después de 1 s, el screamer")
	if kinds.size() == 1:
		check(kinds[0] in [ScareKind.Kind.LIGHTS, ScareKind.Kind.CURTAINS, ScareKind.Kind.WINDOW, ScareKind.Kind.PHONE],
				"con el escritorio a la vista, uno ambiental: %s" % kinds[0])
	check_eq(_state(desk).sanity, sanity - 8.0, "Sanity −8")
	desk.free()
	return true


func test_el_jumpscare_tapa_la_pantalla_y_pausa_la_noche() -> bool:
	var desk := _make_desk()
	var sanity := _state(desk).sanity
	_scare_now(desk, true)
	desk._process(0.0)
	desk._process(1.0)
	check((desk.get_node("Overlay/Jumpscare") as Control).visible, "tapa la pantalla")
	check(desk.get_node("NightManager").is_paused(), "la noche se pausa")
	check_eq(_state(desk).sanity, sanity - 15.0, "Sanity −15")
	desk.get_node("NightManager").advance(1.0)
	check_eq(_state(desk).elapsed, 0.0, "la hora no avanza durante el jumpscare")
	desk.free()
	return true


func test_cada_screamer_hace_lo_suyo() -> bool:
	var desk := _make_desk()
	var screamers := _screamers(desk)
	var notebook := desk.get_node("UI/NotebookPanel") as Control
	screamers.play(ScareKind.Kind.WINDOW)
	check((desk.get_node("WallPlane/Enemy") as CanvasItem).visible, "la figura aparece en la ventana")
	for kind: ScareKind.Kind in [ScareKind.Kind.CURTAINS, ScareKind.Kind.PHONE, ScareKind.Kind.LIGHTS]:
		screamers.play(kind)
		check((screamers.get_node(screamers.SOUND_NODES[kind]) as AudioStreamPlayer).playing, "suena: %s" % kind)
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	screamers.play(ScareKind.Kind.INK)
	check((notebook.get_node("InkBlot") as Control).visible, "la tinta tapa la página")
	screamers.play(ScareKind.Kind.NOTEBOOK_SLAM)
	check(not notebook.visible, "el cuaderno se cierra de golpe")
	desk.free()
	return true


func test_nunca_en_los_ultimos_5_s_de_una_decision() -> bool:
	var desk := _make_desk()
	var request: RefCounted = desk.get_node("RequestManager").start_request(0)
	request.time_left = 6.0
	_scare_now(desk)
	desk._process(0.0)
	check(not _screamers(desk).is_warning(), "a la decisión le quedan 6 s: espera")
	request.time_left = 20.0
	desk._process(0.0)
	check(_screamers(desk).is_warning(), "con tiempo de sobra, sí")
	desk.free()
	return true


func test_nada_durante_audio_sync() -> bool:
	var desk := _make_desk()
	var kinds := []
	_record(desk, kinds)
	var sounds := []
	_screamers(desk).hallucinated.connect(func(sound: AudioStream) -> void: sounds.append(sound))
	desk.open_mixer_for(0)
	_state(desk).sanity = 1.0
	_scare_now(desk)
	_process(desk, 30)
	check(kinds.is_empty(), "ningún screamer durante la ronda")
	check(sounds.is_empty(), "ninguna alucinación durante la ronda")
	desk.close_modes()
	_process(desk, 2)
	check_eq(kinds.size(), 1, "al terminar, llega el que esperaba")
	desk.free()
	return true


func test_alucinaciones_con_sanity_bajo() -> bool:
	var desk := _make_desk()
	var sounds := []
	var screamers := _screamers(desk)
	screamers.hallucinated.connect(func(sound: AudioStream) -> void: sounds.append(sound))
	_process(desk, 60)
	check(sounds.is_empty(), "con Sanity llena, ninguna")
	_state(desk).sanity = 1.0
	_process(desk, 60)
	check(sounds.size() >= 4, "con Sanity en 1, varias: %d" % sounds.size())
	var allowed: Array = screamers.hallucination_sounds
	check_eq(allowed.size(), 6, "golpes, pasos, susurros, rasguños, la estática y el celular")
	check(sounds.all(func(sound: AudioStream) -> bool: return allowed.has(sound)), "solo esos")
	desk.free()
	return true


func test_al_terminar_la_noche_no_hay_mas_screamers() -> bool:
	var desk := _make_desk()
	check(_screamers(desk) != null, "el escritorio tiene sus screamers")
	var kinds := []
	_record(desk, kinds)
	_state(desk).sanity = 0.1
	desk.get_node("NightManager").advance(1.0)
	_scare_now(desk)
	_process(desk, 2)
	check(kinds.is_empty(), "la noche terminó")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `363 pruebas OK, 8 fallidas`. Fallan las 8 pruebas de `test_screamer_manager.gd`, porque el escritorio no tiene `Screamers`, y la figura de la ventana todavía se ve.

- [ ] **Paso 3: Los screamers en el escritorio**

`scripts/desk/screamer_manager.gd`:

```gdscript
extends Node
## Los screamers de la noche (Plan 7, diseño §11). El director dice cuándo toca uno y el escritorio, qué se ve;
## aquí se elige cuál (Screamer), se anuncia con su señal previa (las luces parpadean y baja el sonido
## ambiente) y se muestra con su sonido. Cada uno resta Sanity, y el jumpscare pausa la noche mientras tapa la
## pantalla. Después del susto guionado empieza su chat guionado (decisión de Benja).
## Con Sanity bajo suenan alucinaciones: golpes, pasos, susurros y rasguños, y también la estática y el
## celular, que no vienen de nada (decisión de Benja). Nada de esto empieza durante una ronda de Audio Sync.
## Hasta el arte de Benja (docs/06 §3), los screamers usan las piezas del escritorio y la figura de la ventana.

## Empezó un screamer, después de su señal previa.
signal scare_started(kind: ScareKind.Kind)
## Sonó una alucinación.
signal hallucinated(sound: AudioStream)

const HallucinationClock := preload("res://scripts/core/hallucination_clock.gd")
const NightManager := preload("res://scripts/desk/night_manager.gd")
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const Screamer := preload("res://scripts/core/screamer.gd")

## Volumen del sonido ambiente durante la señal previa y el screamer, en decibeles.
const DUCKED_DB := -40.0
## Segundos que tarda en bajar el sonido ambiente y, después del screamer, en volver.
const DUCK_SECONDS := 0.3
const RETURN_SECONDS := 2.0
## Segundos que duran la cortina, la figura, el celular y las luces.
const EFFECT_SECONDS := 1.5
## Opacidad de la oscuridad con las luces apagadas.
const DARK := 0.85
## El sonido de cada screamer: sus nodos.
const SOUND_NODES := {
	ScareKind.Kind.CURTAINS: "CurtainsSound",
	ScareKind.Kind.WINDOW: "WindowSound",
	ScareKind.Kind.PHONE: "PhoneSound",
	ScareKind.Kind.LIGHTS: "LightsSound",
	ScareKind.Kind.NOTEBOOK_SLAM: "SlamSound",
	ScareKind.Kind.INK: "InkSound",
	ScareKind.Kind.JUMPSCARE: "JumpscareSound",
}
## Desde dónde suena una alucinación: fuera de la pantalla, a la izquierda o a la derecha.
const HALLUCINATION_SIDES: Array[Vector2] = [Vector2(-200, 360), Vector2(1480, 360)]

@export var curtains: Node2D
## La figura de la ventana: escondida, aparece en el screamer de la ventana (decisión de Benja).
@export var figure: CanvasItem
## El celular del escritorio.
@export var phone: Node2D
## Oscurece el cuarto cuando las luces parpadean.
@export var darkness: CanvasItem
## La pantalla del jumpscare: la silueta de la figura a ×2 sobre un destello gris, provisional hasta el arte de
## Benja.
@export var jumpscare: Control
@export var notebook: Control
@export var ambient: AudioStreamPlayer
## Los sonidos que pueden ser una alucinación.
@export var hallucination_sounds: Array[AudioStream] = []

var _requests: RequestManager
var _night: NightManager
var _clock: HallucinationClock
## El screamer anunciado, que empieza al terminar su señal previa, o Screamer.NONE.
var _pending := Screamer.NONE
var _pending_scripted := false
var _warning_left := 0.0
var _ambient_db := 0.0
var _phone_rest := Vector2.ZERO

@onready var _hallucination: AudioStreamPlayer2D = $Hallucination


func setup(requests: RequestManager, night: NightManager) -> void:
	_requests = requests
	_night = night
	_clock = HallucinationClock.new(requests.catalog.balance, requests.rng)
	_ambient_db = ambient.volume_db
	_phone_rest = phone.position
	# El sonido ambiente se repite sin fin.
	ambient.finished.connect(ambient.play)


## Hay un screamer anunciado, esperando que termine su señal previa.
func is_warning() -> bool:
	return _pending != Screamer.NONE


## Avanza `delta` segundos con lo que se ve del escritorio (`view`). Con `busy` (una ronda de Audio Sync),
## no empieza nada: ni screamers ni alucinaciones.
func advance(delta: float, view: Screamer.View, busy: bool) -> void:
	if _requests == null or _night.ended:
		return
	var calm := not busy and not is_warning() and not _night.is_paused()
	if _clock.advance(delta, _requests.state.sanity, calm):
		_hallucinate()
	if is_warning():
		_warning_left -= delta
		if _warning_left <= 0.0:
			var kind := _pending
			_pending = Screamer.NONE
			play(kind, _pending_scripted)
		return
	if not calm:
		return
	var now := _requests.state.elapsed
	var director := _requests.director
	if director.scripted_scare_due(now, _requests.active_count()):
		director.scripted_scare_started(now)
		_announce(_requests.night().scripted_scare, true)
		return
	if not director.scare_due(now):
		return
	var time_lefts := []
	for request: RefCounted in _requests.requests:
		if request != null:
			time_lefts.append(request.time_left)
	var kind := Screamer.pick(view, director.next_is_jumpscare(), time_lefts, _requests.catalog.balance, _requests.rng)
	if kind == Screamer.NONE:
		return
	director.scare_started(now)
	_announce(kind, false)


## Muestra el screamer `kind` ahora, con su sonido, y resta Sanity. Después del susto guionado (`scripted`)
## empieza su chat guionado.
func play(kind: ScareKind.Kind, scripted := false) -> void:
	var balance := _requests.catalog.balance
	_requests.state.scare(Screamer.sanity_cost(kind, balance))
	(get_node(SOUND_NODES[kind]) as AudioStreamPlayer).play()
	match kind:
		ScareKind.Kind.CURTAINS:
			_sway_curtains()
		ScareKind.Kind.WINDOW:
			_show_figure()
		ScareKind.Kind.PHONE:
			_shake_phone()
		ScareKind.Kind.LIGHTS:
			_flicker_lights()
		ScareKind.Kind.NOTEBOOK_SLAM:
			notebook.slam()
		ScareKind.Kind.INK:
			notebook.splash_ink(balance.ink_seconds)
		ScareKind.Kind.JUMPSCARE:
			_show_jumpscare(balance.jumpscare_seconds)
	var back := create_tween()
	back.tween_interval(EFFECT_SECONDS)
	back.tween_property(ambient, ^"volume_db", _ambient_db, RETURN_SECONDS)
	if scripted:
		_requests.start_chat_script(_requests.night().scripted_chat)
	scare_started.emit(kind)


## Anuncia el screamer `kind` con su señal previa: las luces parpadean y baja el sonido ambiente (diseño §11).
func _announce(kind: ScareKind.Kind, scripted: bool) -> void:
	_pending = kind
	_pending_scripted = scripted
	_warning_left = _requests.catalog.balance.scare_warning
	var flicker := create_tween()
	for alpha: float in [0.6, 0.0, 0.75, 0.0]:
		flicker.tween_property(darkness, ^"modulate:a", alpha, 0.08)
	create_tween().tween_property(ambient, ^"volume_db", DUCKED_DB, DUCK_SECONDS)


## La cortina se mece, colgada de su barra.
func _sway_curtains() -> void:
	var tween := create_tween()
	for skew_value: float in [0.08, -0.05, 0.03, 0.0]:
		tween.tween_property(curtains, ^"skew", skew_value, EFFECT_SECONDS / 4.0)


## La figura aparece en la ventana y se desvanece.
func _show_figure() -> void:
	figure.modulate.a = 1.0
	figure.show()
	var tween := create_tween()
	tween.tween_interval(EFFECT_SECONDS * 0.6)
	tween.tween_property(figure, ^"modulate:a", 0.0, EFFECT_SECONDS * 0.4)
	tween.tween_callback(figure.hide)


## El celular del escritorio vibra: se mueve 2 píxeles a cada lado.
func _shake_phone() -> void:
	var tween := create_tween()
	for index in 12:
		var side := 2.0 if index % 2 == 0 else -2.0
		tween.tween_property(phone, ^"position", _phone_rest + Vector2(side, 0.0), EFFECT_SECONDS / 12.0)
	tween.tween_property(phone, ^"position", _phone_rest, 0.05)


## Las luces se apagan y se prenden varias veces.
func _flicker_lights() -> void:
	var tween := create_tween()
	for alpha: float in [DARK, 0.2, DARK, 0.0, DARK, DARK, 0.3, 0.0]:
		tween.tween_property(darkness, ^"modulate:a", alpha, EFFECT_SECONDS / 8.0)


## El jumpscare tapa la pantalla `seconds` segundos, con parpadeos rojos, y la noche se pausa mientras tanto.
func _show_jumpscare(seconds: float) -> void:
	_night.pause(seconds)
	jumpscare.show()
	var red := jumpscare.get_node("Red") as ColorRect
	var tween := create_tween()
	for alpha: float in [0.5, 0.0, 0.35, 0.0, 0.25, 0.0]:
		tween.tween_property(red, ^"color:a", alpha, seconds / 6.0)
	tween.tween_callback(jumpscare.hide)


## Suena una alucinación al azar, a un lado de la pantalla, más fuerte mientras más baja Sanity.
func _hallucinate() -> void:
	if hallucination_sounds.is_empty():
		return
	var rng := _requests.rng
	var sound := hallucination_sounds[rng.randi_range(0, hallucination_sounds.size() - 1)]
	_hallucination.stream = sound
	_hallucination.position = HALLUCINATION_SIDES[rng.randi_range(0, HALLUCINATION_SIDES.size() - 1)]
	_hallucination.volume_db = _clock.volume_db(_requests.state.sanity)
	_hallucination.play()
	hallucinated.emit(sound)
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
```

por:

```ini
[ext_resource type="AudioStream" path="res://audio/sfx/interference_static.wav" id="static_sound"]
[ext_resource type="Script" path="res://scripts/desk/screamer_manager.gd" id="screamers_script"]
[ext_resource type="AudioStream" path="res://audio/sfx/ambient_room.wav" id="ambient_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_curtains.wav" id="curtains_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_window.wav" id="window_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_phone.wav" id="phone_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_lights.wav" id="lights_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_slam.wav" id="slam_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_ink.wav" id="ink_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/scare_jumpscare.wav" id="jumpscare_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/hallucination_knock.wav" id="knock_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/hallucination_steps.wav" id="steps_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/hallucination_whisper.wav" id="whisper_sound"]
[ext_resource type="AudioStream" path="res://audio/sfx/hallucination_scratch.wav" id="scratch_sound"]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
[node name="Enemy" type="AnimatedSprite2D" parent="WallPlane"]
```

por:

```ini
[node name="Enemy" type="AnimatedSprite2D" parent="WallPlane"]
visible = false
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
display_name = "Agustín"

[node name="LookCamera" type="Camera2D" parent="."]
```

por:

```ini
display_name = "Agustín"

[node name="Darkness" type="Polygon2D" parent="."]
modulate = Color(1, 1, 1, 0)
color = Color(0, 0, 0, 1)
polygon = PackedVector2Array(-64, -64, 1344, -64, 1344, 784, -64, 784)

[node name="LookCamera" type="Camera2D" parent="."]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
volume_db = -6.0

[node name="Overlay" type="CanvasLayer" parent="."]
```

por:

```ini
volume_db = -6.0

[node name="Ambient" type="AudioStreamPlayer" parent="."]
stream = ExtResource("ambient_sound")
volume_db = -12.0
autoplay = true

[node name="Screamers" type="Node" parent="." node_paths=PackedStringArray("curtains", "figure", "phone", "darkness", "jumpscare", "notebook", "ambient")]
script = ExtResource("screamers_script")
curtains = NodePath("../WallPlane/Curtains")
figure = NodePath("../WallPlane/Enemy")
phone = NodePath("../DeskPlane/Phone")
darkness = NodePath("../Darkness")
jumpscare = NodePath("../Overlay/Jumpscare")
notebook = NodePath("../UI/NotebookPanel")
ambient = NodePath("../Ambient")
hallucination_sounds = Array[AudioStream]([ExtResource("knock_sound"), ExtResource("steps_sound"), ExtResource("whisper_sound"), ExtResource("scratch_sound"), ExtResource("static_sound"), ExtResource("phone_sound")])

[node name="CurtainsSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("curtains_sound")

[node name="WindowSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("window_sound")

[node name="PhoneSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("phone_sound")

[node name="LightsSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("lights_sound")

[node name="SlamSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("slam_sound")

[node name="InkSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("ink_sound")

[node name="JumpscareSound" type="AudioStreamPlayer" parent="Screamers"]
stream = ExtResource("jumpscare_sound")

[node name="Hallucination" type="AudioStreamPlayer2D" parent="Screamers"]

[node name="Overlay" type="CanvasLayer" parent="."]
```

En `scenes/desk/desk.tscn`, reemplazar:

```ini
mouse_filter = 2

[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

por:

```ini
mouse_filter = 2

[node name="Jumpscare" type="Control" parent="Overlay"]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Flash" type="ColorRect" parent="Overlay/Jumpscare"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.45, 0.43, 0.48, 1)

[node name="Figure" type="AnimatedSprite2D" parent="Overlay/Jumpscare"]
position = Vector2(640, 380)
scale = Vector2(2, 2)
sprite_frames = ExtResource("enemy")

[node name="Red" type="ColorRect" parent="Overlay/Jumpscare"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0.55, 0, 0.04, 0)

[node name="EndScreen" parent="Overlay" instance=ExtResource("end_screen")]
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Cuando se anuncia una interferencia, suena estática.
```

por:

```gdscript
## Cuando se anuncia una interferencia, suena estática.
## Desde el Plan 7 suena el ambiente del cuarto, y los screamers (ScreamerManager) asustan con lo que se ve
## del escritorio, con el cuaderno y con el jumpscare.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
const RequestManager := preload("res://scripts/desk/request_manager.gd")
```

por:

```gdscript
const RequestManager := preload("res://scripts/desk/request_manager.gd")
const Screamer := preload("res://scripts/core/screamer.gd")
const ScreamerManager := preload("res://scripts/desk/screamer_manager.gd")
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _interference_sound: AudioStreamPlayer = $InterferenceSound
```

por:

```gdscript
@onready var _interference_sound: AudioStreamPlayer = $InterferenceSound
@onready var _screamers: ScreamerManager = $Screamers
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_phone.setup(_requests.state, _requests.catalog.phone_posts)
```

por:

```gdscript
	_phone.setup(_requests.state, _requests.catalog.phone_posts)
	_screamers.setup(_requests, _night)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
func _process(_delta: float) -> void:
	_refresh_entries()
	_refresh_meters()
```

por:

```gdscript
func _process(delta: float) -> void:
	_refresh_entries()
	_refresh_meters()
	_screamers.advance(delta, _scare_view(), _mixer.is_playing())


## Lo que se ve del escritorio, para elegir un screamer: el chat, el mixer y el celular ampliado tapan la
## ventana y el celular del escritorio.
func _scare_view() -> Screamer.View:
	var view := Screamer.View.new()
	view.desk_visible = not (_chat_panel.visible or _mixer.visible or _phone.visible)
	view.notebook_open = _notebook_panel.visible
	view.notebook_page = _notebook_panel.shows_page()
	return view
```

En `test/run_tests.gd`, reemplazar:

```gdscript
	print("\n%d pruebas OK, %d fallidas" % [_passed, _failed])
```

por:

```gdscript
	print("\n%d pruebas OK, %d fallidas" % [_passed, _failed])
	# Los sonidos que las pruebas dejaron sonando se liberan en el hilo de audio: se le da un momento antes de
	# salir, para que no queden recursos en uso.
	await create_timer(0.2).timeout
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `371 pruebas OK, 0 fallidas`, sin ningún `ERROR` en la salida completa:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | grep -E "ERROR|pruebas OK"
```

Esperado: solo `371 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ test/
git commit -m "Los screamers en el escritorio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 13: El chat guionado en el escritorio

**Archivos:**

- Modificar: `scenes/ui/chat_panel.tscn`, `scripts/ui/chat_panel.gd`, `scripts/desk/desk.gd`, `test/test_chat_panel.gd`, `test/test_screamer_manager.gd`

- En el chat, mientras el chat guionado espera la respuesta de Matías, en lugar de las respuestas y del aviso del cuaderno aparece un botón con su línea (`ScriptReply`). Al presionarlo, Matías la escribe.
- En el escritorio, la entrada del amigo parpadea mientras espera esa respuesta, y cuando termina un chat guionado que lo pide, el contorno del celular parpadea hasta que Matías lo abre.

La prueba nueva de `test_screamer_manager.gd` juega el susto guionado de la noche 1 de principio a fin: el jumpscare, la línea de Gonzalo, el botón de Matías, la última línea y el celular.

- [ ] **Paso 1: Escribir las pruebas**

Agregar al final de `test/test_chat_panel.gd`:

```gdscript
func test_el_chat_guionado_se_responde_con_un_boton() -> bool:
	var panel := _make_panel()
	var data := ChatScriptData.new()
	data.friend = _manager.catalog.friends[1]
	for speaker: ChatLineData.Speaker in [ChatLineData.Speaker.FRIEND, ChatLineData.Speaker.PLAYER]:
		var line := ChatLineData.new()
		line.speaker = speaker
		line.text_key = "K_LINE_%d" % speaker
		data.lines.append(line)
	_manager.start_chat_script(data)
	_manager.advance(2.5)
	panel.open_for(1)
	var reply := panel.get_node("Panel/ScriptReply") as Button
	check(reply.visible, "el botón de Matías")
	check(not (panel.get_node("Panel/AnswerHint") as Label).visible, "sin el aviso del cuaderno")
	check_eq(reply.text, String(TranslationServer.translate("K_LINE_1")), "con su línea")
	panel.open_for(0)
	check(not reply.visible, "solo en el chat de Gonzalo")
	panel.open_for(1)
	reply.pressed.emit()
	panel._process(0.0)
	check(not reply.visible, "ya respondió")
	check_eq(panel.message_views(1).size(), 2, "la línea de Gonzalo y la respuesta de Matías")
	_free(panel)
	return true
```

En `test/test_screamer_manager.gd`, reemplazar:

```gdscript
const NightState := preload("res://scripts/core/night_state.gd")


## El escritorio en la noche 3, con un azar fijo. Nada avanza solo: las pruebas llaman a desk._process().
func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
```

por:

```gdscript
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")
const NightState := preload("res://scripts/core/night_state.gd")


## El escritorio en la noche `night_number`, con un azar fijo. Nada avanza solo: las pruebas llaman a
## desk._process().
func _make_desk(night_number := 3) -> Node2D:
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = night_number
```

Agregar al final de `test/test_screamer_manager.gd`:

```gdscript
## Avanza la noche y el escritorio `seconds` segundos, de a 1, como en el juego.
func _play(desk: Node2D, seconds: int) -> void:
	for _i in seconds:
		desk.get_node("NightManager").advance(1.0)
		desk._process(1.0)


func test_el_susto_guionado_ensena_el_celular() -> bool:
	var desk := _make_desk(1)
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	var phone := desk.get_node("DeskPlane/Phone")
	var kinds := []
	_record(desk, kinds)
	# A los 60 s, sin solicitudes: la señal previa y, 1 s después, el jumpscare.
	_play(desk, 61)
	check_eq(kinds, [ScareKind.Kind.JUMPSCARE], "el susto guionado de la noche 1")
	# La pausa del jumpscare (1,5 s) y lo que tarda Gonzalo en escribir (2,5 s).
	_play(desk, 4)
	check_eq(gonzalo.state, ChatEntry.State.WARNING, "Gonzalo escribió y espera la respuesta de Matías")
	gonzalo.pressed.emit()
	var reply := desk.get_node("UI/ChatPanel/Panel/ScriptReply") as Button
	check(reply.visible, "el botón con la respuesta de Matías")
	check_eq(reply.text, String(TranslationServer.translate("SCRIPT_SCARE_REPLY")), "su línea")
	reply.pressed.emit()
	_play(desk, 3)
	check_eq(desk.get_node("UI/ChatPanel").message_views(1).size(), 3, "las 3 líneas del chat guionado")
	check(phone.blinking, "Gonzalo le dijo que use el celular, y el celular parpadea")
	phone.clicked.emit()
	check(not phone.blinking, "al abrirlo, deja de parpadear")
	check((desk.get_node("UI/PhoneView") as Control).visible, "se abrió el celular")
	desk.free()
	return true
```

- [ ] **Paso 2: Verificar que fallan**

Importar y correr las pruebas.

Esperado: `371 pruebas OK, 2 fallidas`. Fallan `test_chat_panel.gd :: test_el_chat_guionado_se_responde_con_un_boton` y `test_screamer_manager.gd :: test_el_susto_guionado_ensena_el_celular`, porque el chat no tiene `ScriptReply` y la entrada de Gonzalo no avisa.

- [ ] **Paso 3: El botón de Matías, la entrada y el celular**

En `scenes/ui/chat_panel.tscn`, reemplazar:

```ini
columns = 2

[node name="Scanlines" type="ColorRect" parent="Panel"]
```

por:

```ini
columns = 2

[node name="ScriptReply" type="Button" parent="Panel"]
visible = false
layout_mode = 0
offset_left = 25.0
offset_top = 541.0
offset_right = 423.0
offset_bottom = 605.0
autowrap_mode = 3

[node name="Scanlines" type="ColorRect" parent="Panel"]
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
## (decisión de Benja).
```

por:

```gdscript
## (decisión de Benja).
## En un chat guionado, Matías responde con un botón que tiene su línea (decisión de Benja, Plan 7).
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
@onready var _answers: GridContainer = $Panel/Answers
```

por:

```gdscript
@onready var _answers: GridContainer = $Panel/Answers
@onready var _script_reply: Button = $Panel/ScriptReply
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	_sync_button.pressed.connect(_on_sync_pressed)
```

por:

```gdscript
	_sync_button.pressed.connect(_on_sync_pressed)
	_script_reply.pressed.connect(_on_script_reply_pressed)
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
func _update_answers() -> void:
```

por:

```gdscript
func _update_answers() -> void:
	# Mientras el chat guionado espera la respuesta de Matías, solo está su botón.
	var reply := _manager.chat_script_reply(selected_friend)
	_script_reply.visible = reply != null
	_answer_hint.visible = reply == null
	if reply != null:
		_script_reply.text = tr(reply.text_key)
		_answers.visible = false
		return
```

En `scripts/ui/chat_panel.gd`, reemplazar:

```gdscript
	sync_requested.emit(selected_friend)


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
```

por:

```gdscript
	sync_requested.emit(selected_friend)


func _on_script_reply_pressed() -> void:
	_manager.reply_chat_script()


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## del escritorio, con el cuaderno y con el jumpscare.
```

por:

```gdscript
## del escritorio, con el cuaderno y con el jumpscare. En un chat guionado, la entrada del amigo avisa mientras
## espera la respuesta de Matías, y si el guion lo pide, el celular parpadea hasta que Matías lo abre.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
@onready var _screamers: ScreamerManager = $Screamers
```

por:

```gdscript
@onready var _screamers: ScreamerManager = $Screamers
@onready var _phone_sprite: AnimatedSprite2D = $DeskPlane/Phone
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	_requests.request_started.connect(_on_request_started)
```

por:

```gdscript
	_requests.request_started.connect(_on_request_started)
	_requests.chat_script_finished.connect(_on_chat_script_finished)
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Las redes sociales: el celular se usa sin paneles y sin el mixer.
func open_phone() -> void:
	close_panels()
	_mixer.close()
```

por:

```gdscript
## Las redes sociales: el celular se usa sin paneles y sin el mixer. Si parpadeaba, ya cumplió.
func open_phone() -> void:
	close_panels()
	_mixer.close()
	_phone_sprite.blinking = false
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
	notebook_memory.close_page(friend_index)


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
```

por:

```gdscript
	notebook_memory.close_page(friend_index)


## Terminó un chat guionado: si su guion lo pide, el celular parpadea hasta que Matías lo abre (así se enseña
## que el celular calma, decisión de Benja).
func _on_chat_script_finished(chat: RefCounted) -> void:
	if chat.data.highlight_phone:
		_phone_sprite.blinking = true


## Muestra cómo terminó la noche. Los paneles quedan como estaban, debajo: así se ve lo que pasó. El mixer
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta o la
## descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le queda para responder,
## para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y si viene una
## interferencia.
```

por:

```gdscript
## Seleccionada si su chat está abierto; si no, gris sin señal, en alerta mientras espera respuesta (también en
## un chat guionado) o la descarga de su video, o más oscura si el amigo está aturdido. Muestra el tiempo que le
## queda para responder, para descargar su video o para recuperarse, o que está sin señal; y su vida, su señal y
## si viene una interferencia.
```

En `scripts/desk/desk.gd`, reemplazar:

```gdscript
		elif request != null or offer != null:
```

por:

```gdscript
		elif request != null or offer != null or _requests.chat_script_reply(index) != null:
```

- [ ] **Paso 4: Importar y verificar que pasan**

Esperado: `373 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/ scenes/ test/
git commit -m "El chat guionado en el escritorio" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Tarea 14: Revisión a ojo, instrucciones para Benja y cierre

**Archivos:**

- Crear: `test/capture_screamers.gd`
- Modificar: `docs/04_instrucciones_godot.md`, `docs/06_plan_v1.md`, `docs/02_bucle_central.md`, `docs/00_log.md`, `resumen.md`

- [ ] **Paso 1: Correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tail -1
```

Esperado: `373 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Capturar los screamers y revisarlos**

`test/capture_screamers.gd` no empieza con `test_`, así que el ejecutor de pruebas no lo corre.

`test/capture_screamers.gd`:

```gdscript
extends SceneTree
## Capturas de los screamers para revisarlos a ojo (Plan 7). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_screamers.gd -- /mnt/c/dev/capturas/window.png /mnt/c/dev/capturas/ink.png /mnt/c/dev/capturas/jumpscare.png /mnt/c/dev/capturas/script.png /mnt/c/dev/capturas/script_phone.png
## 1. Noche 3: la figura aparece en la ventana, con el escritorio a la vista.
## 2. El cuaderno, en la página de El Trauco, con la mancha de tinta.
## 3. El jumpscare.
## 4. Noche 1, después del susto guionado: el chat de Gonzalo, con el botón de la respuesta de Matías.
## 5. Después de responder: el chat cerrado y el celular del escritorio con su contorno encendido.

const DESK := preload("res://scenes/desk/desk.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := _make_desk(3)
	var screamers := desk.get_node("Screamers")
	screamers.play(ScareKind.Kind.WINDOW)
	await create_timer(0.3).timeout
	await _save(0)
	var manager := desk.get_node("RequestManager")
	desk.get_node("DeskPlane/Notebook").clicked.emit()
	desk.notebook_memory.open_page(0, manager.catalog.known_entities(3)[0])
	screamers.play(ScareKind.Kind.INK)
	await create_timer(0.5).timeout
	await _save(1)
	desk.close_panels()
	screamers.play(ScareKind.Kind.JUMPSCARE)
	await create_timer(0.2).timeout
	await _save(2)
	desk.free()
	desk = _make_desk(1)
	desk.get_node("RequestManager").state.elapsed = 59.5
	# La señal previa, el jumpscare (1,5 s, con la noche en pausa) y lo que tarda Gonzalo en escribir (2,5 s).
	await create_timer(6.0).timeout
	desk.get_node("DeskPlane/Entries/EntryGonzalo").pressed.emit()
	# Lo que tarda en escribirse su mensaje.
	await create_timer(1.5).timeout
	await _save(3)
	desk.get_node("UI/ChatPanel/Panel/ScriptReply").pressed.emit()
	await create_timer(3.0).timeout
	desk.close_panels()
	var phone := desk.get_node("DeskPlane/Phone")
	phone.blinking = true
	await create_timer(0.1).timeout
	await _save(4)
	desk.free()
	# Los sonidos que quedaron sonando se liberan en el hilo de audio, como al terminar las pruebas.
	await create_timer(0.2).timeout
	quit()


## El escritorio en la noche `night_number`, sin solicitudes, interferencias ni videos que lleguen solos,
## y sin screamers del director: cada captura muestra el que pide.
func _make_desk(night_number: int) -> Node2D:
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = night_number
	manager.random_seed = 5
	manager.requests_arrive = false
	root.add_child(desk)
	var state: RefCounted = manager.state
	state.videos.pending.clear()
	state.interferences.pending.clear()
	manager.director.scare_times.clear()
	return desk


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

Se ejecuta **con ventana** (sin `--headless`): Godot abre una ventana unos 15 segundos y se cierra solo.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_screamers.gd -- /mnt/c/dev/capturas/window.png /mnt/c/dev/capturas/ink.png /mnt/c/dev/capturas/jumpscare.png /mnt/c/dev/capturas/script.png /mnt/c/dev/capturas/script_phone.png 2>&1 | grep -E "Captura|ERROR"
```

Esperado: `Captura guardada en C:\dev\capturas\window.png`, y lo mismo con `ink.png`, `jumpscare.png`, `script.png` y `script_phone.png`, sin ningún `ERROR`. Abrir las imágenes (con la herramienta Read) y comprobar.

En `window.png`:

- el escritorio sin paneles, a las 00:00;
- en la ventana, la figura oscura con dos ojos rojos tapa la luna.

En `ink.png`:

- a la derecha, el cuaderno en la página de El Trauco ("Ayudando a León");
- una mancha negra tapa casi toda la página, del folclore a las reglas, con chorreones hacia abajo y salpicaduras alrededor, sin salirse de la página.

En `jumpscare.png`:

- toda la pantalla tapada: la silueta de la figura, grande (a ×2) y al centro, con sus ojos rojos, sobre un fondo gris teñido de rojo.

En `script.png`:

- el chat de Gonzalo (su pestaña elegida) con su mensaje completo: "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar";
- abajo, en lugar del aviso "Abre el cuaderno para responder", un botón con "Creo que me estoy volviendo loco, no sé si puedo seguir";
- en el PC, "Videos: 0 de 2" (la noche 1).

En `script_phone.png`:

- el escritorio sin paneles, y el celular con su contorno amarillo encendido;
- la hora del celular, cerca de las 00:57.

Si algo no coincide, revisarlo antes de seguir.

- [ ] **Paso 3: Actualizar las instrucciones de Godot (`docs/04_instrucciones_godot.md`)**

En `docs/04_instrucciones_godot.md`, reemplazar:

```markdown
| **J.** Probar el mantenimiento (Plan 6) | ⬜ Pendiente (unos 20 minutos) |
```

por:

```markdown
| **J.** Probar el mantenimiento (Plan 6) | ⬜ Pendiente (unos 20 minutos) |
| **K.** Probar los screamers y el director (Plan 7) | ⬜ Pendiente (unos 20 minutos) |
```

Agregar al final de `docs/04_instrucciones_godot.md`:

````markdown
---

## K. Probar los screamers y el director (Plan 7)

Antes de abrir Godot, avísale a Claude si está trabajando: no pueden estar los dos abiertos a la vez.

1. Abre Godot y el proyecto. Abre `scenes/desk/desk.tscn` y presiona **F5**. Se juega la noche 3. Ahora suena de fondo el ambiente del cuarto (viento y un zumbido), y la figura de la ventana ya no está.
2. **El ritmo:** las solicitudes llegan en olas de 3. Dentro de una ola llegan con unos 20 a 35 segundos entre una y otra, y después de cada ola hay un respiro unos 25 segundos más largo, sin solicitudes nuevas. Hacia las 06:00 llegan más seguidas. Si un amigo queda herido, la siguiente se atrasa unos 10 segundos.
3. **Los screamers:** en la noche 3 hay 4, desde los 30 segundos, y uno de ellos es el jumpscare.
   - Antes de cada uno, las luces parpadean y baja el sonido ambiente durante 1 segundo.
   - Con el escritorio a la vista (sin el chat, el mixer ni el celular abiertos), puede ser que la cortina se meza, que aparezca la figura en la ventana, que el celular vibre o que se apaguen las luces. Con el chat abierto, solo las luces. Con el cuaderno abierto, también puede cerrarse de golpe o mancharse de tinta durante 5 segundos.
   - Cada uno baja de golpe el dial de Sanity (el del medio): 8 puntos, y el jumpscare, 15.
   - El jumpscare tapa toda la pantalla un segundo y medio, con un grito. Mientras dura, la noche se pausa: la hora y los temporizadores no avanzan.
4. **Justicia:** ningún screamer empieza si a una solicitud le quedan 6 segundos o menos, ni durante una ronda de Audio Sync.
5. **Alucinaciones:** para no esperar a que baje Sanity, haz doble clic en `data/balance.tres` y, en el **Inspector**, en el grupo **Alucinaciones**, cambia **Hallucination Start** de 50 a 100 y **Hallucination Slowest** de 40 a 10. Presiona **F5**.
   - Cada unos 10 segundos suena algo a un lado de la pantalla: golpes en la ventana, pasos, susurros, rasguños, la estática de una interferencia o el celular vibrando. No pasa nada más: son falsos.
   - Durante una ronda de Audio Sync no suena ninguno.
   - **Al terminar, vuelve a dejar 50 y 40.** Si no, `test_balance.gd` falla.
6. **El susto guionado:** en el panel **Scene**, selecciona el nodo `RequestManager` y, en el **Inspector**, cambia **Night Number** de 3 a 1. Presiona **F5**. La noche 1 todavía no tiene entidades, así que no llegan solicitudes.
   - Al minuto (cerca de las 00:51), las luces parpadean y llega el jumpscare.
   - Unos segundos después, la entrada de Gonzalo parpadea. Abre su chat: "Todo bien hermano?? Se te quedó el micro prendido y te escuché gritar". Abajo, en lugar de las respuestas, hay un botón con la respuesta de Matías. Presiónalo.
   - Gonzalo contesta "Mati wn relájate, tú puedes. Usa tu celu pa despejarte un rato, te va a calmar". Cierra el chat: el borde del celular parpadea. Haz clic en el celular: se abre y deja de parpadear.
   - **Al terminar, vuelve Night Number a 3.**

**Verifica:** los pasos 1 a 6 se cumplen. Si algo falla, anota cuál y qué pasó.

### Para ajustar

- **Los valores de equilibrio** están en `data/balance.tres`. Haz doble clic en él y cámbialos en el **Inspector**:
  - **Director:** cuándo llega la primera solicitud (**First Request Delay**), cuánto dura el respiro después de cada ola (**Wave Respite**), cuánto se aprietan hacia las 06:00 (**Wave Tightening**: 0,5 es la mitad), cuánto tiempo mínimo pasa entre dos (**Request Min Gap**) y cuánto las atrasa un amigo herido (**Hurt Respite**);
  - **Screamers:** cuánto dura la señal previa (**Scare Warning**), cuántos segundos le tienen que quedar a una decisión (**Scare Margin**), cuánto tiempo mínimo pasa entre dos (**Scare Min Gap**), desde cuándo hay (**First Scare After**), cuánto restan (**Scare Sanity** y **Jumpscare Sanity**) y cuánto duran el jumpscare (**Jumpscare Seconds**) y la tinta (**Ink Seconds**);
  - **Alucinaciones:** desde qué Sanity suenan (**Hallucination Start**) y cada cuánto, al empezar (**Hallucination Slowest**) y con Sanity en 0 (**Hallucination Fastest**).
  - Si cambias un valor a propósito, avísale a Claude: `test_balance.gd` compara el archivo con `docs/02`.
- **Por noche** (`data/nights/night_N.tres`): cuántas solicitudes trae cada ola (**Wave Size**, en **Solicitudes**); cuántos screamers hay y si uno es el jumpscare (**Scare Count** y **Has Jumpscare**, en **Screamers**); y el guion (en **Guion**): a qué segundo llega el susto guionado (**Scripted Scare Time**; 0 si no hay), qué screamer es (**Scripted Scare**) y su chat (**Scripted Chat**: el amigo, las líneas con quién habla y su texto, y si al final parpadea el celular).
- **Los textos del chat guionado** están en `data/text/messages.csv` (`SCRIPT_SCARE_*`).
- **Los sonidos provisionales** están en `audio/sfx/`. Para probar otro, reemplaza el archivo por uno con el mismo nombre.
````

- [ ] **Paso 4: Actualizar la hoja de ruta, el modelo de datos, el registro y el resumen**

En `docs/06_plan_v1.md`, reemplazar:

```markdown
- El **Plan 7** está escrito paso a paso en `docs/14_plan_screamers_director.md` (por ejecutar).
```

por:

```markdown
- El **Plan 7** está escrito paso a paso en `docs/14_plan_screamers_director.md` (ejecutado).
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
Implementado en el Plan 2 (`docs/08`). Los señuelos se agregan en el Plan 3 (`docs/10`); `BalanceData`, en el Plan 5 (`docs/12`), y las publicaciones del celular, en el Plan 6 (`docs/13`). Las clases están en `scripts/data/` y el contenido en `data/`.
```

por:

```markdown
Implementado en el Plan 2 (`docs/08`). Los señuelos se agregan en el Plan 3 (`docs/10`); `BalanceData`, en el Plan 5 (`docs/12`); las publicaciones del celular, en el Plan 6 (`docs/13`), y los screamers y los chats guionados, en el Plan 7 (`docs/14`). Las clases están en `scripts/data/` y el contenido en `data/`.
```

En `docs/02_bucle_central.md`, reemplazar:

```text
                 decoys_in_first_message,
                 signal_decays, signal_decay_interval, interference_count,
                 audio_sync_beats, sanity_drain_interval, content_quota
BalanceData      night_seconds, friend_health, stun_seconds, consecuencias (probabilidad, daño y Trust), recuperación de Trust, vignette_start, el scroll del celular, la señal (interferencias y Trust sin señal), Audio Sync (tempo y tolerancia) y los videos (plazos y descarga)
```

por:

```text
                 decoys_in_first_message, wave_size (solicitudes por ola),
                 signal_decays, signal_decay_interval, interference_count,
                 audio_sync_beats, sanity_drain_interval, content_quota,
                 scare_count, has_jumpscare,
                 scripted_scare_time, scripted_scare (ScareKind), scripted_chat (ChatScriptData)
ChatScriptData   friend, lines[] (ChatLineData: speaker FRIEND/PLAYER, text_key), highlight_phone
BalanceData      night_seconds, friend_health, stun_seconds, consecuencias (probabilidad, daño y Trust), recuperación de Trust, vignette_start, el scroll del celular, la señal (interferencias y Trust sin señal), Audio Sync (tempo y tolerancia), los videos (plazos y descarga), el director (olas y respiros), los screamers (señal previa, justicia, Sanity, jumpscare y tinta) y las alucinaciones
```

En `docs/02_bucle_central.md`, reemplazar:

```markdown
- `screamer_rate` se agrega a `NightData` en el Plan 7.
```

por:

```markdown
- Los tipos de screamer son `ScareKind`: la cortina, la ventana, el celular, las luces, el golpe del cuaderno, la tinta y el jumpscare (Plan 7).
```

Además:

- `resumen.md`: entrada de la sesión con Realizado, Errores encontrados, Pendientes Código y Pendientes Externos. En los Pendientes Externos deben figurar:
  - la sección K de `docs/04`;
  - entre los textos que Benja corrige: el chat guionado en `messages.csv` (`SCRIPT_SCARE_*`), que es suyo, por si quiere ajustarlo, y quién lo escribe (Gonzalo, en `data/nights/night_1.tres`);
  - el arte de los screamers (ver "Fuera de este plan").
- `docs/00_log.md`:
  - S17 queda ✅;
  - S18 (escribir el Plan 8: noches, menú, guardado y opciones, con la noche 0) queda como siguiente;
  - en "Qué documentos son planes de sesión", `docs/14` queda como ejecutado.

- [ ] **Paso 5: Commit final**

`git add` incluye los `.uid` y `.import` que Godot haya creado en el último import. Después, `git status` no debe mostrar nada.

```bash
git add docs/ resumen.md scripts/ test/ scenes/ data/ audio/ tools/
git commit -m "Plan 7 terminado: screamers y director" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git status --short
```

---

## Fuera de este plan, a propósito

- **El arte de Benja** (`arte_pendiente.md` §3 y `docs/06` §3). Cuando esté, Claude lo integra sin cambiar la lógica ni las pruebas de comportamiento:
  - **los screamers:** las manos o el rostro que tapan la pantalla, los jumpscares y la mancha de tinta. Reemplazan la figura a ×2 de `Overlay/Jumpscare` y el dibujo de `ink_blot.gd`;
  - **la animación `scare` de las cortinas**, en lugar del `skew` de `_sway_curtains()`;
  - **las luces** (`pcLightOver`, `pcLightUnder` y `pcDesklight`) como archivos aparte: el apagón podría bajar solo las luces, en lugar de oscurecer todo el cuarto con `Darkness`.
- **Las publicaciones perturbadoras del celular** con Sanity bajo (`arte_pendiente.md` §3): dependen del celular ampliado de Benja.
- **Plan 8 (noches, menú, guardado y opciones):**
  - la noche 0 (tutorial, decisión de Benja): qué enseña y cuánto dura. El susto guionado y su chat se mueven de la noche 1 a la 0 en el Inspector (grupo **Guion**), sin código;
  - "Reducir destellos" debe suavizar el parpadeo de la señal previa, el apagón de las luces y los parpadeos rojos del jumpscare;
  - "Temporizadores ×1,5": el margen de justicia de los screamers se calcula con el tiempo que le queda a cada decisión, así que no cambia.
- **Después de la v1** (`docs/05`): la progresión guionada entre los amigos. Los chats guionados ya son datos de una noche; lo que falta es poder empezarlos por otras razones que el susto guionado (a una hora, después de una solicitud, entre noches).
- **Plan 9 (sonido):** los sonidos definitivos reemplazan los de `audio/sfx/` (con los mismos nombres) y van a sus buses: el ambiente, los screamers y las alucinaciones. El ambiente definitivo puede usar el bucle del importador de Godot en lugar de volver a empezar al terminar.
- **El director no mueve los videos ni las interferencias:** siguen repartidos uno por tramo. Si en las pruebas con personas se juntan con las olas, se ajusta.
- **Las alucinaciones solo suenan:** no muestran nada en la pantalla ni en el chat. Si Benja quiere alucinaciones visuales (una entrada que parpadea sin razón, por ejemplo), irían a la lista de `docs/05`.

## Autorrevisión del plan

- **Cobertura** (`docs/06` §2, Plan 7; diseño §5, §10.2, §11 y §14; decisiones de Benja):

  | Requisito | Tarea |
  | --- | --- |
  | Las solicitudes llegan en olas, con un respiro después de cada una, y se aprietan hacia las 06:00 (decisión de Benja) | 1, 2 y 7 |
  | Un amigo herido atrasa las solicitudes; nunca empieza una que no alcanza a terminar | 2 y 7 |
  | Los screamers: ambientales (cortina, ojos en la ventana, celular, luces), sobre el cuaderno (golpe, tinta 5 s) y el jumpscare, como máximo uno por noche desde la noche 2 | 1, 3, 4, 10 y 12 |
  | Llegan en cualquier momento (decisión de Benja), con señal previa: un parpadeo de luz y una caída del sonido ambiente | 3, 9 y 12 |
  | Justicia: nunca en los últimos 5 s de una decisión; los que tapan la pantalla pausan los temporizadores | 4, 6 y 12 |
  | Cada uno resta una cantidad fija de Sanity | 1, 4, 6 y 12 |
  | Alucinaciones con Sanity bajo, más seguidas y más fuertes; del cuarto y del juego; sin restar Sanity y nunca durante Audio Sync (decisión de Benja) | 1, 5, 9 y 12 |
  | La figura de la ventana, escondida: aparece al asustar y es el jumpscare provisional (decisión de Benja) | 12 |
  | El susto guionado y su chat, como datos de una noche (la 1, hasta la noche 0), con la respuesta de Matías en un botón y el celular que parpadea (decisión de Benja) | 1, 3, 8, 11, 12 y 13 |
  | "Una noche con ritmo controlado y screamers justos" | 7, 12, 13 y 14 (`docs/04`, K) |

- **Nombres consistentes:**
  - `BalanceData` (`first_request_delay`, `wave_respite`, `wave_tightening`, `request_min_gap`, `hurt_respite`, `scare_*`, `first_scare_after`, `jumpscare_*`, `ink_seconds` y `hallucination_*`) y `NightData` (`wave_size`, `scare_count`, `has_jumpscare`, `scripted_scare_time`, `scripted_scare` y `scripted_chat`) se usan igual en el director, `Screamer`, `HallucinationClock`, `ScreamerManager` y las pruebas;
  - `PacingDirector` (`request_times`, `request_due()`, `request_started()`, `friend_hurt()`, `delay()`, `scare_times`, `jumpscare_at`, `scare_due()`, `next_is_jumpscare()`, `scare_started()`, `scripted_scare_due()` y `scripted_scare_started()`) coincide entre las tareas 2, 3, 7 y 12;
  - `Screamer` (`View`, `NONE`, `candidates()`, `sanity_cost()`, `blocking_seconds()`, `is_fair()` y `pick()`) y `ScareKind.Kind` coinciden entre las tareas 1, 4 y 12;
  - `HallucinationClock` (`QUIET_DB`, `LOUD_DB`, `interval()`, `volume_db()` y `advance()`) coincide entre las tareas 5 y 12;
  - `NightState.scare()` y `NightManager` (`pause()` e `is_paused()`) coinciden entre las tareas 6 y 12;
  - `ChatScriptData` (`friend`, `lines` y `highlight_phone`), `ChatLineData` (`Speaker`, `speaker` y `text_key`), `ChatScript` (`LINE_DELAY`, `data`, `friend_index`, `advance()`, `pending_reply()`, `reply()` e `is_done()`) y `RequestManager` (`director`, `chat_script`, `start_chat_script()`, `chat_script_reply()`, `reply_chat_script()` y `chat_script_finished`) coinciden entre las tareas 7, 8, 12 y 13;
  - `NotebookPanel` (`slam()`, `splash_ink()` y `shows_page()`), `ClickableSprite.blinking` y `ScreamerManager` (`setup()`, `advance()`, `play()`, `is_warning()`, `SOUND_NODES`, `hallucination_sounds`, `scare_started` y `hallucinated`) coinciden con `desk.gd` y las pruebas;
  - los nodos nuevos (`InkBlot` del cuaderno, `Panel/ScriptReply` del chat, y `Darkness`, `Ambient`, `Screamers` con sus sonidos y `Hallucination`, y `Overlay/Jumpscare` con `Flash`, `Figure` y `Red` del escritorio) son los que usan los scripts y las pruebas.
- **Conteo de pruebas acumulado:** 326 → 328, 336, 340, 346, 350, 352, 354, 359, 359, 362, 363, 371 y 373.
