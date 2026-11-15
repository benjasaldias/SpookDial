# Plan 9.9: la noche termina cuando se acaba, y la nota

> **Para quien ejecuta:** usa `superpowers:executing-plans` y sigue las tareas en orden. Cada paso tiene una casilla (`- [ ]`) para marcar el avance. Escrito por Claude (Opus 5.5) en S21n, el 14 y 15 de noviembre de 2026, sin probarlo antes: las pruebas de cada tarea lo verifican al ejecutarlo.

**Objetivo:** que la noche termine cuando se acaban la ola final y su diálogo, y no a una hora fija; que las olas vayan en cadena; que la historia se lea más lento; y que cada noche ganada tenga una nota S, A, B o C.

**Arquitectura:**
- **El director (`PacingDirector`)** deja de planear olas a una hora. Cada ola, también la final, llega cuando pasa su calma desde que se resolvió la anterior.
- **`RequestManager.night_complete()`** dice cuándo no queda nada. Unos segundos después marca `NightState.finished`, y `NightState.ending()` gana o pierde por la cuota.
- **La nota** sale de 2 números que lleva `NightState`: la espera de los pedidos de ayuda y las vidas perdidas. La calcula una clase de lógica pura (`NightGrade`) y la muestra la pantalla final.
- **El modelo de "jugar bien"** corre cada noche hasta que se completa. Con eso se calibran las calmas.

**Tecnología:** Godot 4.7.2 y GDScript con tipos estáticos. Las pruebas son las propias del proyecto (`test/run_tests.gd`).

---

## Por qué

En la segunda prueba con la historia (noche 1 de Normal), al tester le sobró 1:20 de reloj: la ola final y el cierre del vlog terminaron hacia las 05:10, y no pasó nada hasta las 06:30. Además, los diálogos del inicio se le hicieron rápidos.

**La causa** es que la ola final llegaba "lo más tarde posible", calculada para que todo terminara antes del final aunque cada consulta usara su tiempo completo (90 s en la noche 1 de Normal). Por eso llegaba a las 03:38, y quien juega bien la resolvía mucho antes de las 06:30. Medido con el modelo, el tiempo muerto al final era de 50 a 118 s en Normal, de 29 a 49 s en Difícil y de 20 a 35 s en Extremo.

Benja propuso que la hora marque solo cuándo empiezan los eventos, y que la noche termine con la última ola y su diálogo. Así el tiempo pasa a ser una mecánica, y con él una nota al estilo de Cuphead.

## Decisiones de Benja (14 de noviembre)

1. **La noche termina cuando se acaba:** cuando la ola final se resolvió, no queda nada abierto (consultas, accidentes, decisiones ni videos por recibir o descargar), la historia terminó de contarse y pasaron 3 s más (`end_pause`). Se gana con la cuota cumplida; sin ella, se pierde por cuota. Se acaban las 06:00 y las 06:30 como final (se quitan `overtime_minutes`, `NightData.length()` y `finale_margin`).
2. **Las olas van en cadena:** cada ola, también la final, llega cuando pasa su calma desde que se resolvió la anterior, o cuando termina la historia de esa calma, lo que sea más tarde. **Ninguna ola se salta.** Dentro de una ola, las consultas llegan como hoy, así que la final sigue trayendo a los 3 a la vez. La ola sigue esperando a la historia a lo más 45 s, como seguro.
3. **El reloj sigue igual** (70 s por hora) y marca cuándo terminaron: "Llegaste a las 04:52". Si alguien es lento, puede pasar de las 06:00.
4. **La lectura:** cada línea de la historia dura lo que tarda en escribirse (60 letras por segundo), más sus palabras divididas por 3,5, más 1 s, y nunca menos de 2 s. El tutorial no cambia.
5. **La nota (S, A, B, C)**, solo al ganar una noche de la 1 a la 5. No se guarda.
   - **La espera:** el promedio de segundos que estuvo abierto cada pedido de ayuda (consulta, accidente o decisión de la historia), comparado con la meta de la dificultad: Normal 15 s, Difícil 20 s y Extremo 15 s, que es lo que logra el modelo. Hasta la meta da 3 puntos, hasta 1,5 veces la meta 2, hasta el doble 1, y más, 0.
   - **Las vidas perdidas esa noche:** ninguna da 3 puntos, una 2, dos 1, y más, 0. La herida con que empieza un amigo en Extremo no cuenta.
   - **La letra:** S con 5 o 6 puntos, A con 4, B con 2 o 3, y C con 0 o 1.
6. **Las calmas se alargan solo donde falta:** en Extremo, hasta que la holgura vuelva a ser de 1 o más (sin el tiempo muerto del final, cae a 0,85); y en las noches que, jugando bien, terminan antes de las 04:30 en promedio (Normal 2, quizás Normal 3, y Difícil 2).
7. **Difícil 5 baja a 9 consultas:** antes se saltaba una ola que no cabía, así que Benja jugó una noche de 9 a 11 consultas. En cadena llegarían las 11.

**Consecuencia que Benja ya sabe:** como ya no se saltan olas, un jugador lento recibe todas las consultas y su noche se alarga. Antes, el juego le quitaba olas sin que se notara.

## Antes de empezar

- Lee `CLAUDE.md` y este plan entero.
- **El editor de Godot debe estar cerrado:** la Tarea 7 reimporta los textos.
- **Commits:** pregúntale a Benja antes de cada uno, salvo que te haya autorizado todos al empezar. Nunca hagas push.
- **No toques los cambios sin commit de Benja.** Al escribir este plan había 4: `docs/04` (la sección Z, sobre itch.io), `scripts/ui/main_menu.gd`, `docs/presentacion_testeo_1.pptx` y `export_presets.cfg`. En cada commit agrega solo los archivos de la tarea, por su nombre. En la Tarea 8 vas a editar `docs/04`, que trae la sección Z de Benja: pregúntale antes de commitearlo.
- **OneDrive:** a veces Edit o Write responden "no such file" porque OneDrive reemplaza el archivo mientras sincroniza. El cambio normalmente queda escrito: verifica con `grep` antes de reintentar.
- **Pruebas:** desde la carpeta del proyecto:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK"
  ```

  Con nombres después de `--` (`-- test_pacing_director test_story_runner`) corre solo esas suites. La suite entera toma unos 45 s. **Base: 851 pruebas OK** (commit `0a2b77a`).
- **Bloques "Reemplaza / por":** el texto de "Reemplaza" es una copia exacta del archivo, con tabulaciones. Usa Edit. Si no aparece exacto, lee el archivo con Read, busca la primera línea y adapta solo los espacios.
- **Funciones de prueba "Reemplaza la función X entera":** borra desde su comentario `##` y su `func` hasta justo antes del comentario o la `func` siguiente, y pega la versión nueva.
- **Si falla una prueba que el plan no menciona:** decide si es una consecuencia esperada del cambio (un valor medido con el horario viejo, como una hora fija o una ola que se saltaba) o un error. Si es esperada, actualiza el valor y explica por qué en un comentario. **Nunca debilites estas garantías:** jugando bien nada vence, Trust queda sobre 75, la batería no pasa de 100 %, la holgura es de 1 o más y la historia llega entera. Anota cada caso en la sección "Resultado" de este plan.

## Archivos

| Archivo | Qué cambia | Tarea |
| --- | --- | --- |
| `scripts/core/pacing_director.gd` | Olas en cadena: sin `finale_at`, `planned`, `finale_time()` ni olas saltadas; `request_due(now)` | 1 |
| `scripts/data/wave_data.gd`, `night_data.gd`, `balance_data.gd` | Comentarios del horario nuevo | 1 |
| `scripts/desk/request_manager.gd` | `request_due(now)` | 1 |
| `test/balance_model.gd` | `request_due(now)` | 1 |
| `scripts/core/story_runner.gd` | `line_seconds()` por palabras | 2 |
| `scripts/core/friend_state.gd` | `health_lost` | 3 |
| `scripts/core/video_schedule.gd` | `is_settled()` | 3 |
| `scripts/core/night_state.gd` | La espera (`waiting`, `waited`, `asked`, `wait_goal`), `average_wait()` y `lives_lost()` | 3 |
| `scripts/core/night_state.gd` | `finished` y el final por completarse | 4 |
| `scripts/data/balance_data.gd`, `data/balance.tres` | `end_pause` | 4 |
| `scripts/data/difficulty_data.gd`, `data/difficulty/hard.tres` | `wait_goal` | 4 |
| `scripts/desk/request_manager.gd` | `night_complete()`, `waiting_count()`, cuenta los pedidos y la meta | 4 |
| `scripts/desk/night_manager.gd` | `state.waiting` | 4 |
| `test/balance_model.gd` | Corre hasta que la noche se completa y mide con ese largo | 5 |
| `test/dump_waves.gd` | Las funciones nuevas del modelo | 5 |
| `test/dump_night_lengths.gd` | Nuevo: mide cada noche para calibrar | 5 |
| `data/nights/*` | Difícil 5 con 9 consultas y las calmas calibradas | 5 |
| `scripts/data/night_data.gd`, `night_state.gd`, `balance_data.gd`, `request_manager.gd` y 3 `night_1.tres` | Sin hora de término: se quitan `overtime_minutes`, `length` y `finale_margin` y el tope de las consultas | 6 |
| `scripts/core/night_grade.gd` | Nuevo: la nota | 7 |
| `scripts/data/balance_data.gd`, `data/balance.tres` | Los valores de la nota | 7 |
| `scripts/core/ending_text.gd`, `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn`, `data/text/ui.csv` | La nota en la pantalla final | 7 |
| `test/capture_plan99.gd` | Nuevo: capturas de la pantalla final | 7 |
| Documentos | `docs/02`, `docs/04`, `CLAUDE.md`, el diseño v2, `resumen.md`, `docs/00_log.md` y la sección "Resultado" de este plan | 8 |

Las pruebas que cambian están en cada tarea.

---

## Tarea 1: las olas en cadena

**Archivos:**
- Modificar: `scripts/core/pacing_director.gd`, `scripts/desk/request_manager.gd`, `test/balance_model.gd`, `scripts/data/wave_data.gd`, `scripts/data/night_data.gd` y `scripts/data/balance_data.gd`
- Pruebas: `test/test_pacing_director.gd`, `test/test_story_runner.gd` y `test/test_balance.gd`

- [ ] **Paso 1: las pruebas del director**

En `test/test_pacing_director.gd`:

1. Reemplaza las 2 líneas del comentario del encabezado:

```gdscript
## El director de olas (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## de verdad cuando se resuelven y una ola final grande, lo más tarde posible.
```

por:

```gdscript
## El director de olas (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## de verdad cuando se resuelven y una ola final grande. Desde el Plan 9.9 (docs/33), en cadena: cada ola, también la
## final, llega cuando pasa su calma desde que se resolvió la anterior, y ninguna se salta.
```

2. En `_run()`, reemplaza:

```gdscript
func _run(director: PacingDirector, night: NightData, answer_after: float) -> Dictionary:
	var result := {"arrivals": [], "waves": [], "calms": [], "interferences": [], "videos": []}
	var open: Array[float] = []
	var time := 0.0
	while time < NIGHT_SECONDS:
```

por:

```gdscript
func _run(director: PacingDirector, night: NightData, answer_after: float, until := NIGHT_SECONDS) -> Dictionary:
	var result := {"arrivals": [], "waves": [], "calms": [], "interferences": [], "videos": []}
	var open: Array[float] = []
	var time := 0.0
	while time < until:
```

y, en la misma función, `while director.request_due(time, night.base_decision_time):` por `while director.request_due(time):`. Agrega al final de su comentario: `## Con `until`, corre hasta esa hora (en cadena, una noche lenta dura más de 420 s).`

3. Reemplaza la función `test_el_primer_minuto_es_de_silencio` entera por:

```gdscript
func test_el_primer_minuto_es_de_silencio() -> bool:
	var night := _night()
	var director := _director(night)
	for second in 120:
		director.advance(second * 0.5, 0)
		check(not director.request_due(second * 0.5), "a los %s s, nada" % (second * 0.5))
	director.advance(60.0, 0)
	check(director.request_due(60.0), "a los 60 s llega la primera ola")
	return true
```

4. Reemplaza la función `test_la_calma_empieza_cuando_se_resuelve_la_ola` entera, con su comentario, por:

```gdscript
## La calma se cuenta desde que se resuelve la ola, y dura entre 40 y 60 s (Plan 9.9: ya no hay olas planeadas a una
## hora, así que tampoco dura más).
func test_la_calma_empieza_cuando_se_resuelve_la_ola() -> bool:
	for seed_value in 10:
		var result := _run(_director(_night(), seed_value), _night(), 30.0)
		var arrivals: Array = result["arrivals"]
		var calms: Array = result["calms"]
		var resolved: float = arrivals[1] + 30.0
		check(absf(calms[0] - resolved) <= 0.5, "semilla %d: la calma empieza al resolverse: %s" % [seed_value, calms[0]])
		var calm: float = arrivals[2] - calms[0]
		check(calm >= 40.0 and calm <= 60.5, "semilla %d: de 40 a 60 s de calma: %s" % [seed_value, calm])
	return true
```

5. Reemplaza la función `test_la_ola_final_es_de_3_y_llega_al_final` entera por:

```gdscript
## La ola final es de 3 y llega como las demás: cuando pasa su calma desde que se resolvió la última ola común (Plan 9.9;
## antes llegaba a una hora fija, lo más tarde posible).
func test_la_ola_final_es_de_3_y_llega_tras_su_calma() -> bool:
	var night := _night()
	for seed_value in 10:
		var result := _run(_director(night, seed_value), night, 30.0)
		var arrivals: Array = result["arrivals"]
		var waves: Array = result["waves"]
		var calms: Array = result["calms"]
		check_eq(arrivals.size(), 7, "semilla %d: las 7 solicitudes" % seed_value)
		var last_wave: Array = waves[-1]
		check(last_wave[2], "semilla %d: la última es la final" % seed_value)
		var calm: float = last_wave[0] - calms[-1]
		check(calm >= 40.0 and calm <= 60.5, "semilla %d: tras su calma de 40 a 60 s: %.1f" % [seed_value, calm])
		var finale: Array = arrivals.slice(4)
		check_eq(finale.size(), 3, "semilla %d: 3 en la final" % seed_value)
		check(finale[-1] - finale[0] <= 17.0, "semilla %d: juntas" % seed_value)
	return true
```

6. Reemplaza la función `test_una_ola_que_no_cabe_se_salta` entera, con su comentario, por:

```gdscript
## Un jugador lento no pierde olas (Plan 9.9): cada ola espera a que se resuelva la anterior, aunque la noche se alargue.
func test_ninguna_ola_se_salta() -> bool:
	var night := _night()
	night.requests_total = 11
	var result := _run(_director(night, 3), night, 60.0, 1500.0)
	check_eq(result["arrivals"].size(), 11, "llegan las 11")
	check_eq(result["waves"].size(), 5, "4 olas comunes y la final")
	check(result["waves"][-1][2], "la última es la final")
	return true
```

7. Reemplaza la función `test_nunca_empieza_una_que_no_alcanza` entera por:

```gdscript
## Ya no hay hora de término (Plan 9.9): una consulta llega aunque sea muy tarde.
func test_una_consulta_llega_aunque_sea_tarde() -> bool:
	var director := _director(_night())
	director.phase = PacingDirector.Phase.FINALE
	director.pending.assign([false])
	director.next_at = 0.0
	check(director.request_due(1000.0), "a los 1000 s, llega igual")
	return true
```

8. Reemplaza la función `test_el_video_no_llega_encima_de_la_ola` entera, con su comentario, por:

```gdscript
## Un video de una calma alcanza a descargarse antes de la ola siguiente: llega a más tardar 25 s antes (15 para
## empezar y 10 de descarga), o al empezar la calma, si es corta.
func test_el_video_no_llega_encima_de_la_ola() -> bool:
	var night := _night()
	night.wave_calm = Vector2(14, 14)
	var director := _director(night, 12)
	var balance := BalanceData.new()
	director.advance(60.0, 0)
	director.request_started(60.0)
	director.request_started(65.0)
	# La última ola común se resuelve, y su calma, corta, dura 14 s antes de la final.
	director.wave_index = director.waves.size() - 2
	var beat := director.advance(100.0, 0)
	check(beat.calm_started, "empezó la calma")
	check_eq(director.next_at, 114.0, "la final, 14 s después")
	check_eq(beat.videos.size(), 2, "la última calma suelta los 2 videos")
	if beat.videos.size() == 2:
		check_eq(beat.videos[0], 100.0, "con la calma corta, el primero llega enseguida")
	var window := balance.video_accept_seconds + balance.download_seconds
	var long_calm := _run(_director(_night(), 4), _night(), 30.0)
	for index in long_calm["videos"].size():
		var next_wave: float = long_calm["waves"][index + 1][0]
		check(long_calm["videos"][index] <= next_wave - window + 0.5, "llega 25 s antes de la ola siguiente")
	return true
```

9. Reemplaza la función `test_la_final_del_plan_llega_lo_mas_tarde_posible` entera, con su comentario, por:

```gdscript
## La final del plan llega como las demás olas: tras su calma (calm_before) desde que se resolvió la ola 2 (Plan 9.9).
func test_la_final_del_plan_llega_tras_su_calma() -> bool:
	for seed_value in 5:
		var night := _plan_night()
		var result := _run(_director(night, seed_value), night, 20.0, 600.0)
		var finale: Array = result["waves"][-1]
		check(finale[2], "semilla %d: es la final" % seed_value)
		var calm: float = finale[0] - result["calms"][-1]
		check(calm >= 30.0 and calm <= 45.5, "semilla %d: tras su calma de 30 a 45 s: %.1f" % [seed_value, calm])
		check_eq(result["arrivals"].size(), 5, "semilla %d: las 5 consultas" % seed_value)
	return true
```

10. En `test_en_la_final_nada_llega_junto`, reemplaza `var result := _run(_director(night, seed_value), night, 80.0)` por `var result := _run(_director(night, seed_value), night, 80.0, 800.0)`.

11. En el comentario de `test_la_noche_puede_traer_su_calma`, borra la frase `La\n## ola se resuelve después de la hora planeada de la siguiente, para que mande la calma.` y deja el comentario terminado en `en vez de la de balance.tres.`. En el de `_calm_after_late_wave`, reemplaza `si se resuelve a las 02:00 (140 s), pasada la hora planeada de la\n## siguiente.` por `si se resuelve a las 02:00 (140 s).`.

12. Reemplaza la función `test_la_final_espera_a_la_historia` entera por estas 2 funciones:

```gdscript
## Resuelve cada ola común apenas llega todo lo que trae, hasta la calma antes de la final. Devuelve la hora en que
## empezó esa calma.
func _reach_calm_before_finale(director: PacingDirector) -> float:
	var time := 0.0
	while not (director.phase == PacingDirector.Phase.CALM and director.wave_index == director.finale_index()):
		director.advance(time, 0)
		while director.request_due(time):
			director.request_started(time)
		time += 0.5
	return time - 0.5


func test_la_final_espera_a_la_historia() -> bool:
	var director := _director(_night())
	_reach_calm_before_finale(director)
	var finale_at := director.next_at
	director.story_hold = true
	check_eq(director.advance(finale_at, 0).wave_started, -1, "a su hora, espera")
	director.story_hold = false
	var beat := director.advance(finale_at + 20.0, 0)
	check(beat.wave_started == director.finale_index() and beat.finale_started, "llega cuando la historia termina")
	return true
```

13. Borra la sección entera `# --- El horario (Plan 9.8): la noche con historia hasta las 06:30...`, con sus 3 pruebas: `test_con_historia_la_final_deja_5_s`, `test_en_una_noche_mas_larga_la_final_llega_despues` y `test_no_empieza_una_consulta_que_no_alcanza_antes_del_final`. Las reemplazan `test_ninguna_ola_se_salta` y `test_una_consulta_llega_aunque_sea_tarde`.

14. En `_resolve_first_wave`, reemplaza `while director.request_due(time, 60.0):` por `while director.request_due(time):`.

15. Reemplaza la función `test_la_calma_antes_de_la_final_cuenta_la_historia` entera, con su comentario, por:

```gdscript
## La calma antes de la final dura lo que cuentan la reunión y lo de antes de la final, si es más que la calma (Plan 9.9:
## ya no se salta ninguna ola por eso).
func test_la_calma_antes_de_la_final_cuenta_la_historia() -> bool:
	var moment := StoryBeatData.Moment
	for needs: Dictionary in [{}, {moment.AFTER_LAST_WAVE: 60.0, moment.BEFORE_FINALE: 15.0}]:
		var night := _night()
		night.wave_calm = Vector2(40, 40)
		var director := _story_director(night, needs)
		var calm_start := _reach_calm_before_finale(director)
		var expected := 40.0 if needs.is_empty() else 75.0
		check_eq(director.next_at - calm_start, expected, "%.0f s de calma antes de la final" % expected)
	return true
```

- [ ] **Paso 2: las pruebas de la historia y del equilibrio**

En `test/test_story_runner.gd`:

1. En `Sim.run_until()`, reemplaza `while director.request_due(time, night.base_decision_time):` por `while director.request_due(time):`.
2. Reemplaza la función `test_si_se_salta_la_ultima_ola_se_salta_lo_de_antes` entera, con su comentario, por:

```gdscript
## Con las olas en cadena (Plan 9.9), un jugador lento no se salta ninguna ola: lo de antes de la última ola común llega
## igual, y se reúnen ahí.
func test_un_jugador_lento_no_se_salta_la_historia() -> bool:
	var night := _night(11)
	var story := StoryData.new()
	story.starts_together = false
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.BEFORE_LAST_WAVE,
			[Fixtures.make_step(StoryStepData.Kind.JOIN), _line(0, "K_B")]))
	story.beats.append(Fixtures.make_beat(StoryBeatData.Moment.AFTER_LAST_WAVE, [_line(1, "K_C")]))
	var sim := _sim(story, night)
	sim.answer_after = 40.0
	sim.run_until(1200.0)
	check_eq(sim.wave_times.size(), 5, "las 5 olas: ninguna se salta")
	check(sim.time_of("K_B") >= 0.0, "lo de antes de la última ola común llega")
	check_eq(sim.runner.skipped_beats, [], "nada se salta")
	var after := sim.item_of("K_C")
	check(after != null and after.command == StoryRunner.Command.CALL_LINE, "se reunieron: la llamada en la calma antes de la final")
	return true
```

3. Reemplaza la función `test_si_la_final_llega_encima_se_saltan_las_decisiones_y_se_reunen` entera, con su comentario, por:

```gdscript
## Con las olas en cadena (Plan 9.9), la final ya no llega encima de la ola 2: espera a que se resuelva. Aun un jugador
## muy lento recibe la reunión y su decisión (antes se saltaban; decisión de Benja en S21l).
func test_un_jugador_muy_lento_igual_recibe_la_decision() -> bool:
	var sim := _sim(Fixtures.make_story(_catalog))
	sim.answer_after = 200.0
	sim.run_until(1500.0)
	check_eq(sim.calm_times.size(), 2, "las 2 calmas")
	check_eq(sim.items.filter(func(entry: Array) -> bool: return entry[1].command == StoryRunner.Command.DECISION).size(),
			1, "la decisión llega")
	check(not sim.runner.skipped_beats.has(2), "la reunión no se salta")
	return true
```

En `test/test_balance.gd`, borra la sección `# --- La historia no regala tiempo (pedido de Benja, Plan 9.8)...` entera: su comentario, la constante `STORY_NIGHT_REFERENCES` y `test_la_historia_no_regala_tiempo`. Esa prueba comparaba con la noche hasta las 06:30, que deja de existir; la Tarea 5 la reemplaza.

- [ ] **Paso 3: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_pacing_director test_story_runner 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: las 2 suites no cargan (`request_due()` recibe 2 argumentos y el director pide 1). En Godot, una suite que no carga cuenta como falla.

- [ ] **Paso 4: el director en cadena**

En `scripts/core/pacing_director.gd`:

1. Reemplaza todo el comentario del encabezado (las líneas `##` entre `extends RefCounted` y `enum Phase`) por:

```gdscript
## El director de ritmo (diseño §5 y §11; decisiones de Benja, 2 y 11 de noviembre): decide cuándo llega cada
## solicitud y qué pasa en cada momento de la noche.
## La noche empieza con un minuto de silencio. Después llegan olas: las solicitudes de una ola llegan juntas, con pocos
## segundos de diferencia, y cuando se resuelven todas viene una calma de verdad.
## Desde el Plan 9.9 (docs/33; decisión de Benja, 14 de noviembre) las olas van en cadena: cada una, también la final
## (la más grande, el clímax), llega cuando pasa su calma desde que se resolvió la anterior. Ninguna se salta, y no hay
## hora de término: la noche se completa cuando se resuelve la final (RequestManager.night_complete), así que jugar
## rápido la acorta.
## Las interferencias, los accidentes y la Mano caen en las olas; los videos y los screamers, en las calmas, y una
## visita de la criatura, en la ola final. Un amigo herido atrasa lo que falta.
## Una noche puede traer sus olas armadas a mano (NightData.wave_plan, desde el Plan 9.4: la noche 1 de Normal). Cada ola
## dice cuántas consultas y videos trae, separados cuánto, y la calma que la precede. Sus videos llegan dentro de la ola:
## cuando a la consulta anterior le quedan unos segundos o, si ya se respondió, un poco después. La última es la final.
## Desde el Plan 9.7 (la historia, docs/31), cuenta las olas y las calmas que empezaron, para que la historia sepa en qué
## momento va, y una ola espera mientras la historia cuenta algo antes de ella (story_hold), a lo más story_hold_limit s.
## Desde el Plan 9.8, la historia está en el horario (story_needs): la primera ola llega cuando terminó lo de antes, y
## cada calma dura al menos lo que cuenta su historia. Así la espera queda solo de seguro.
## Lógica pura: RequestManager la avanza y le pregunta por las solicitudes y los accidentes; ScreamerManager, por los
## screamers, y HandManager, por la Mano. Las reglas de justicia de los screamers las revisa Screamer.
```

2. Reemplaza:

```gdscript
	var finale := false
	## A qué hora le toca, si la anterior se resolvió a tiempo (solo en las olas automáticas).
	var planned := 0.0
```

por:

```gdscript
	var finale := false
```

3. Reemplaza:

```gdscript
var wave_index := 0
## A qué hora llega la ola final.
var finale_at := 0.0
```

por:

```gdscript
var wave_index := 0
```

4. Reemplaza:

```gdscript
var _rng: RandomNumberGenerator
## Cuánto dura la noche (hasta las 06:00 o, con historia, hasta las 06:30).
var _night_length := 0.0
```

por:

```gdscript
var _rng: RandomNumberGenerator
```

5. Reemplaza:

```gdscript
	story_needs = needs
	_night_length = night.length(balance)
	_decision_time = night.base_decision_time
```

por:

```gdscript
	story_needs = needs
	_decision_time = night.base_decision_time
```

6. Borra la función `finale_time()` entera, con su comentario de 4 líneas: desde `## A qué hora llega la ola final: lo más tarde posible` hasta `return night.length(balance) - end - margin`, y una de las 2 líneas en blanco que la siguen.

7. En `advance()`, reemplaza:

```gdscript
			if pending.is_empty() and active == 0:
				_start_calm(now, beat)
			elif _has_finale() and now >= finale_at:
				# La final llega a su hora, aunque la ola no se haya resuelto. Si la ola tenía videos por llegar, llegan
				# ahora: son de la cuota.
				for is_video: bool in pending:
					if is_video:
						beat.videos.append(now)
				wave_index = waves.size() - 1
				_start_wave(now, beat)
```

por:

```gdscript
			if pending.is_empty() and active == 0:
				_start_calm(now, beat)
```

8. Reemplaza:

```gdscript
## Toca empezar una solicitud de la ola en curso. Si ya no alcanza a terminar antes de las 06:00 (dura
## `decision_seconds`), la ola pierde las consultas que le faltan; sus videos llegan igual.
func request_due(now: float, decision_seconds: float) -> bool:
	if not (phase == Phase.WAVE or phase == Phase.FINALE) or pending.is_empty() or pending[0] or now < next_at:
		return false
	if now + decision_seconds > _night_length:
		pending.assign(pending.filter(func(is_video: bool) -> bool: return is_video))
		return false
	return true
```

por:

```gdscript
## Toca empezar una solicitud de la ola en curso: lo próximo que trae es una consulta y llegó su hora. Desde el Plan 9.9
## no hay hora de término, así que nunca se corta.
func request_due(now: float) -> bool:
	return (phase == Phase.WAVE or phase == Phase.FINALE) and not pending.is_empty() and not pending[0] \
			and now >= next_at
```

9. En `_plan()`, reemplaza:

```gdscript
	finale_at = finale_time(night, _balance)
	var span := (finale_at - _balance.first_wave_at) / maxi(regular_count, 1)
	for index in regular_count:
		var wave := _requests_wave(mini(wave_size, regular - index * wave_size))
		wave.planned = _balance.first_wave_at + index * span
		waves.append(wave)
```

por:

```gdscript
	for index in regular_count:
		waves.append(_requests_wave(mini(wave_size, regular - index * wave_size)))
```

y:

```gdscript
		finale.finale = true
		finale.planned = finale_at
		finale.creature = night.creature_visits > 0
```

por:

```gdscript
		finale.finale = true
		finale.creature = night.creature_visits > 0
```

10. En `_plan_from()`, reemplaza:

```gdscript
	finale_at = finale_time(night, _balance)
	waves[-1].finale = true
	waves[-1].planned = finale_at
```

por:

```gdscript
	waves[-1].finale = true
```

y su comentario `## Arma las olas del plan de la noche, tal como vienen. La última es la final, a su hora; la primera llega a su calma` por `## Arma las olas del plan de la noche, tal como vienen. La última es la final; la primera llega a su calma`.

11. Reemplaza el comentario y el comienzo de `_start_calm()`:

```gdscript
## La ola se resolvió: empieza su calma, con sus videos y sus screamers. La ola siguiente llega después de la calma o
## a la hora que tenía planeada, la que sea más tarde. Si ya no cabe antes de la final, se salta.
func _start_calm(now: float, beat: Beat) -> void:
```

por:

```gdscript
## La ola se resolvió: empieza su calma, con sus videos y sus screamers. La ola siguiente, también la final, llega cuando
## pasa la calma o cuando termina lo que cuenta la historia, lo que sea más tarde (Plan 9.9: ninguna se salta).
func _start_calm(now: float, beat: Beat) -> void:
```

y, en la misma función:

```gdscript
	next_at = now + _rng.randf_range(calm.x, calm.y)
	if wave_index < waves.size() and not waves[wave_index].finale:
		next_at = maxf(next_at, waves[wave_index].planned)
		next_at = maxf(next_at, now + _calm_story(wave_index))
		if _has_finale() and next_at > finale_at - maxf(_wave_calm.x, _finale_story()):
			wave_index = waves.size() - 1
	if wave_index < waves.size() and waves[wave_index].finale:
		next_at = finale_at
	elif wave_index >= waves.size():
		phase = Phase.DONE
```

por:

```gdscript
	next_at = now + _rng.randf_range(calm.x, calm.y)
	if wave_index < waves.size():
		var need := _finale_story() if waves[wave_index].finale else _calm_story(wave_index)
		next_at = maxf(next_at, now + need)
	else:
		phase = Phase.DONE
```

12. Verifica que no quede nada del horario viejo:

```bash
grep -n "finale_at\|planned\|_night_length\|finale_time\|length(" scripts/core/pacing_director.gd
```

Esperado: sin resultados.

- [ ] **Paso 5: los que llaman a `request_due()` y los comentarios**

En `scripts/desk/request_manager.gd`, reemplaza:

```gdscript
## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
## Si no hay a quién dársela, espera. El director decide si alcanza a terminar antes de las 06:00 con el tiempo sin
## alargar: con "Temporizadores ×1,5", start_request lo corta a las 06:00.
func _maybe_start_request() -> void:
	if not director.request_due(_elapsed, RequestGenerator.decision_time(night(), state.trust)):
		return
```

por:

```gdscript
## Cuando el director lo pide, le da una solicitud a un amigo libre al azar, sin pasar de las simultáneas.
## Si no hay a quién dársela, espera.
func _maybe_start_request() -> void:
	if not director.request_due(_elapsed):
		return
```

En `test/balance_model.gd`, reemplaza `while director.request_due(time, RequestGenerator.decision_time(night, trust)) and busy.has(false) \` por `while director.request_due(time) and busy.has(false) \`.

En `scripts/data/wave_data.gd`, reemplaza:

```gdscript
## La última ola del plan es la final: llega lo más tarde posible, para que su última consulta alcance a terminar antes de
## las 06:00.
```

por:

```gdscript
## La última ola del plan es la final: como las demás, llega cuando pasa su calma (Plan 9.9).
```

y:

```gdscript
## que se resolvió la anterior. La final no los usa.
```

por:

```gdscript
## que se resolvió la anterior, también la final (Plan 9.9).
```

En `scripts/data/night_data.gd`, reemplaza:

```gdscript
## Solicitudes de la ola final, la más grande, que llega lo más tarde posible (decisión de Benja, 11 de noviembre).
```

por:

```gdscript
## Solicitudes de la ola final, la más grande (decisión de Benja, 11 de noviembre). Llega tras su calma (Plan 9.9).
```

En `scripts/data/balance_data.gd`, reemplaza:

```gdscript
## Olas de verdad (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## cuando se resuelven y una ola final grande, lo más tarde posible.
```

por:

```gdscript
## Olas de verdad (decisión de Benja, 11 de noviembre): un minuto de silencio, olas que llegan juntas, una calma
## cuando se resuelven y una ola final grande. Desde el Plan 9.9, en cadena: cada ola llega cuando pasa su calma.
```

y:

```gdscript
## Segundos de calma sin solicitudes nuevas desde que se resuelve una ola (mínimo y máximo, al azar). Si la ola
## siguiente estaba planeada para más tarde, la calma dura hasta entonces.
```

por:

```gdscript
## Segundos de calma sin solicitudes nuevas desde que se resuelve una ola (mínimo y máximo, al azar), o lo que cuente
## la historia, si es más (Plan 9.9).
```

- [ ] **Paso 6: correr todas las pruebas**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK"
```

Esperado: todas OK, con 4 pruebas menos: se borraron 3 de `test_pacing_director` y 1 de `test_balance`, y las reemplazadas no cambian la cuenta. Son **847 pruebas OK**. Si falla otra prueba, sigue la regla de "Antes de empezar". Hasta la Tarea 4, la noche todavía termina a las 06:00 o a las 06:30.

Las cuentas de pruebas de este plan están sumadas a mano, función por función. Si no coinciden, revisa que no haya quedado una función de más o de menos antes de seguir.

- [ ] **Paso 7: commit**

```bash
git add scripts/core/pacing_director.gd scripts/desk/request_manager.gd test/balance_model.gd scripts/data/wave_data.gd scripts/data/night_data.gd scripts/data/balance_data.gd test/test_pacing_director.gd test/test_story_runner.gd test/test_balance.gd
git commit -m "Las olas en cadena: cada ola, también la final, llega tras su calma, y ninguna se salta"
```

Termina el mensaje con las líneas de atribución que pida la sesión.

---

## Tarea 2: la historia se lee más lento

**Archivos:**
- Modificar: `scripts/core/story_runner.gd`
- Pruebas: `test/test_story_runner.gd`

- [ ] **Paso 1: las pruebas**

En `test/test_story_runner.gd`:

1. Agrega junto a los otros `preload` del comienzo:

```gdscript
const ChatMessageView := preload("res://scripts/ui/chat_message_view.gd")
```

2. Reemplaza:

```gdscript
## Cada texto de la traducción falsa tiene 45 letras: a 15 letras por segundo, se lee en 3 s (Plan 9.8).
const LINE_SECONDS := 3.0
const TEXT_LENGTH := 45
```

por:

```gdscript
## Cada texto de la traducción falsa tiene 60 letras y 7 palabras: se escribe en 1 s, se lee en 2 s (3,5 palabras por
## segundo) y espera 1 s más (Plan 9.9).
const LINE_TEXT := "xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxx"
const LINE_SECONDS := 4.0
```

3. Reemplaza las 2 apariciones de `var translate := func(key: String) -> String: return key.rpad(TEXT_LENGTH, ".")` (en `_sim()` y en `test_lo_que_dura_cada_momento`) por `var translate := func(_key: String) -> String: return LINE_TEXT`.

4. En `test_las_lineas_esperan_lo_que_tardan_en_escribirse`, reemplaza `sim.run_until(10.0)` por `sim.run_until(13.0)` y `"una cada 2 s"` por `"una cada %s s" % LINE_SECONDS`. La tercera línea llega a los 8 s y termina a los 12.

5. Reemplaza la función `test_una_linea_dura_lo_que_se_tarda_en_leerla` entera, con su comentario, por:

```gdscript
## Una línea dura lo que tarda en escribirse (60 letras por segundo, como el chat), lo que se tarda en leer sus palabras
## (3,5 por segundo) y 1 s más, y nunca menos de 2 s (pedido de Benja, Plan 9.9: el inicio se sentía rápido).
func test_una_linea_dura_lo_que_se_tarda_en_leerla() -> bool:
	check_eq(StoryRunner.line_seconds(LINE_TEXT), LINE_SECONDS, "60 letras y 7 palabras: 1 + 2 + 1 s")
	var intro := "Hoy vamos a una cabaña en medio del campo, donde dicen que penan el Tue Tué y la Calchona"
	var expected := intro.length() / 60.0 + 19 / 3.5 + 1.0
	check(is_equal_approx(StoryRunner.line_seconds(intro), expected), "19 palabras: %.1f s" % StoryRunner.line_seconds(intro))
	check_eq(StoryRunner.line_seconds("hola"), 2.0, "una corta, 2 s")
	check_eq(StoryRunner.TYPING_CHARS_PER_SECOND, ChatMessageView.CHARS_PER_SECOND, "se escribe como en el chat")
	return true
```

6. En `test_mientras_cuenta_algo_la_ola_espera`, reemplaza `sim.run_until(100.0)` por `sim.run_until(130.0)` y `check_eq(sim.wave_times[0], 75.5, "la primera ola espera las 25 líneas (75 s)")` por `check_eq(sim.wave_times[0], 100.5, "la primera ola espera las 25 líneas (100 s)")`. Sigue dentro del límite: la ola puede esperar hasta los 105 s.

7. En `test_un_momento_que_se_cierra_corta_sus_lineas_pero_se_reunen`, reemplaza el comentario `# 40 líneas (120 s): empiezan apenas empieza la noche y no alcanzan, ni con los 45 s de espera.` por `# 40 líneas (160 s): empiezan apenas empieza la noche y no alcanzan, ni con los 45 s de espera.`.

8. En `test_un_momento_largo_empieza_antes`, reemplaza `"32 s antes de la ola"` por `"42 s antes de la ola"`.

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_story_runner 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: la suite no carga, porque falta `StoryRunner.TYPING_CHARS_PER_SECOND`.

- [ ] **Paso 3: la lectura nueva**

En `scripts/core/story_runner.gd`, reemplaza:

```gdscript
## Una línea queda lo que se tarda en leerla (Plan 9.8): tantas letras por segundo, y nunca menos que MIN_LINE_SECONDS.
const READING_CHARS_PER_SECOND := 15.0
const MIN_LINE_SECONDS := 2.0
```

por:

```gdscript
## Una línea queda lo que tarda en escribirse, lo que se tarda en leerla y una pausa (pedido de Benja, Plan 9.9: el inicio
## se sentía rápido): se escribe a TYPING_CHARS_PER_SECOND letras por segundo (lo mismo que el chat,
## ChatMessageView.CHARS_PER_SECOND), se lee a READING_WORDS_PER_SECOND palabras por segundo y después espera LINE_PAUSE.
## Nunca menos que MIN_LINE_SECONDS.
const TYPING_CHARS_PER_SECOND := 60.0
const READING_WORDS_PER_SECOND := 3.5
const LINE_PAUSE := 1.0
const MIN_LINE_SECONDS := 2.0
```

y:

```gdscript
## Lo que queda una línea de `text`: lo que se tarda en leerla.
static func line_seconds(text: String) -> float:
	return maxf(text.length() / READING_CHARS_PER_SECOND, MIN_LINE_SECONDS)
```

por:

```gdscript
## Lo que queda una línea de `text`: lo que tarda en escribirse, en leerse (por sus palabras) y la pausa.
static func line_seconds(text: String) -> float:
	var typing := text.length() / TYPING_CHARS_PER_SECOND
	var reading := text.split(" ", false).size() / READING_WORDS_PER_SECOND
	return maxf(typing + reading + LINE_PAUSE, MIN_LINE_SECONDS)
```

En el comentario del encabezado, reemplaza:

```gdscript
##   separados, al chat de quien habla. Cada línea espera lo que se tarda en leerla, a 15 letras por segundo (el doble de
##   lento que antes: pedido de Benja, Plan 9.8).
```

por:

```gdscript
##   separados, al chat de quien habla. Cada línea espera lo que tarda en escribirse y en leerse, por sus palabras, más
##   una pausa (line_seconds; pedidos de Benja en los planes 9.8 y 9.9).
```

Verifica que no quede la constante vieja: `grep -rn "READING_CHARS_PER_SECOND" scripts test`, sin resultados.

- [ ] **Paso 4: correr todas las pruebas**

Esperado: **847 pruebas OK** (`test_una_linea_dura_lo_que_se_tarda_en_leerla` reemplaza a la anterior). La historia de la noche 1 ahora dura más: `test_la_noche_1_de_normal` calcula la hora de la primera ola con `story_needs`, así que se ajusta sola. Si `test_jugando_bien_la_final_casi_no_espera` falla (una ola esperó más de 10 s), anótalo en "Resultado" y revisa con `test/dump_waves.gd` qué momento de la historia no cabe en su calma: con las calmas en cadena no debería pasar.

- [ ] **Paso 5: commit**

```bash
git add scripts/core/story_runner.gd test/test_story_runner.gd
git commit -m "La historia se lee más lento: lo que tarda en escribirse, 3,5 palabras por segundo y 1 s"
```

---

## Tarea 3: la espera, las vidas y los videos asentados

Es lógica pura, sin efecto en el juego hasta la Tarea 4.

**Archivos:**
- Modificar: `scripts/core/friend_state.gd`, `scripts/core/video_schedule.gd` y `scripts/core/night_state.gd`
- Pruebas: `test/test_friend_state.gd`, `test/test_video_schedule.gd` y `test/test_night_state.gd`

- [ ] **Paso 1: las pruebas**

Al final de `test/test_friend_state.gd`:

```gdscript


## La nota cuenta la vida que se perdió en la noche (Plan 9.9): lo que quitó cada herida, sin pasar de la que tenía.
func test_cuenta_la_vida_perdida() -> bool:
	var friend := FriendState.new(3)
	check_eq(friend.health_lost, 0, "al empezar, nada")
	friend.hurt(1, 15.0)
	check_eq(friend.health_lost, 1, "una herida de 1")
	friend.hurt(5, 15.0)
	check_eq(friend.health_lost, 3, "una de 5 le quita las 2 que le quedaban")
	var wounded := FriendState.new(3)
	wounded.health = 1
	check_eq(wounded.health_lost, 0, "empezar herido (Extremo) no cuenta")
	return true
```

Al final de `test/test_video_schedule.gd`:

```gdscript


## La noche no se completa con videos por llegar o por descargar (Plan 9.9).
func test_asentado_cuando_no_queda_nada_por_llegar() -> bool:
	var schedule := _schedule(1)
	var friends := _friends()
	check(not schedule.is_settled(), "el programado no se ha soltado")
	schedule.release(0, 1.0)
	check(not schedule.is_settled(), "en camino")
	_advance(schedule, friends, 0.0, 1, -1)
	check_eq(schedule.offers.size(), 1, "llegó: espera su descarga")
	check(not schedule.is_settled(), "por descargar")
	_advance(schedule, friends, 1.0, 10, 0)
	check_eq(schedule.received, 1, "descargado")
	check(schedule.is_settled(), "ya no queda nada")
	check(_schedule(0).is_settled(), "sin cuota, nada que esperar")
	return true
```

Al final de `test/test_night_state.gd`:

```gdscript


## La espera de la nota (Plan 9.9): cada segundo suma los pedidos de ayuda abiertos, y el promedio es por pedido.
func test_la_espera_de_los_pedidos() -> bool:
	var state := _make_state()
	check_eq(state.average_wait(), 0.0, "sin pedidos, 0")
	state.asked = 3
	state.waiting = 2
	state.advance(10.0)
	state.waiting = 1
	state.advance(10.0)
	check_eq(state.waited, 30.0, "10 s con 2 abiertos y 10 s con 1")
	check_eq(state.average_wait(), 10.0, "30 s entre 3 pedidos")
	check_eq(state.wait_goal, 15.0, "la meta por defecto, la de Normal")
	return true


## Las vidas perdidas de la nota: las heridas de las consecuencias y de los accidentes.
func test_las_vidas_perdidas() -> bool:
	var state := _make_state()
	check_eq(state.lives_lost(), 0, "al empezar, ninguna")
	state.apply(0, _consequence(2, -15.0))
	state.injure(1)
	check_eq(state.lives_lost(), 3, "2 de León y 1 de Gonzalo")
	return true
```

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_friend_state test_video_schedule test_night_state 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: las 3 suites no cargan (faltan `health_lost`, `is_settled()` y la espera).

- [ ] **Paso 3: el código**

En `scripts/core/friend_state.gd`, reemplaza:

```gdscript
## Segundos por cada punto de señal que pierde con el tiempo. Con 0, la señal no baja (noche 1).
var signal_decay_interval := 0.0
```

por:

```gdscript
## Segundos por cada punto de señal que pierde con el tiempo. Con 0, la señal no baja (noche 1).
var signal_decay_interval := 0.0
## La vida que perdió en la noche, para la nota (Plan 9.9). La herida con que empieza en Extremo no cuenta, porque no pasa
## por hurt().
var health_lost := 0
```

y:

```gdscript
func hurt(damage: int, stun_seconds: float) -> void:
	health = maxi(health - damage, 0)
```

por:

```gdscript
func hurt(damage: int, stun_seconds: float) -> void:
	health_lost += mini(damage, health)
	health = maxi(health - damage, 0)
```

En `scripts/core/video_schedule.gd`, después de la función `is_quota_met()`:

```gdscript


## Ya no queda ningún video por llegar ni por descargar: los programados se soltaron, todos llegaron y ninguno espera su
## descarga (Plan 9.9). Antes, la noche no se completa.
func is_settled() -> bool:
	return unreleased == 0 and pending.is_empty() and offers.is_empty()
```

En `scripts/core/night_state.gd`, reemplaza:

```gdscript
var impatient := 0
var interferences: InterferenceSchedule
```

por:

```gdscript
var impatient := 0
var interferences: InterferenceSchedule
## Los pedidos de ayuda abiertos (consultas, accidentes y decisiones de la historia): lo pone NightManager antes de cada
## paso, como impatient. Mientras están abiertos, suman a la espera de la nota (Plan 9.9).
var waiting := 0
## Los segundos que esperaron los pedidos de ayuda, sumados: dos abiertos a la vez suman el doble.
var waited := 0.0
## Cuántos pedidos de ayuda llegaron en la noche. Los cuenta RequestManager al empezar cada uno.
var asked := 0
## La meta de espera por pedido de la dificultad (DifficultyData.wait_goal), con la que la nota compara average_wait().
## La pone RequestManager.
var wait_goal := 15.0
```

y, en `advance()`:

```gdscript
	elapsed = minf(elapsed + delta, length)
	var online: Array[bool] = []
```

por:

```gdscript
	elapsed = minf(elapsed + delta, length)
	waited += delta * waiting
	var online: Array[bool] = []
```

Después de la función `connection()`, agrega:

```gdscript


## Cuánto esperó en promedio cada pedido de ayuda, en segundos (0 si no hubo ninguno).
func average_wait() -> float:
	return waited / asked if asked > 0 else 0.0


## Las vidas que perdieron los amigos en la noche, sin la herida con que empieza uno en Extremo.
func lives_lost() -> int:
	var lost := 0
	for friend: FriendState in friends:
		lost += friend.health_lost
	return lost
```

- [ ] **Paso 4: correr todas las pruebas**

Esperado: **851 pruebas OK** (847 más 4).

- [ ] **Paso 5: commit**

```bash
git add scripts/core/friend_state.gd scripts/core/video_schedule.gd scripts/core/night_state.gd test/test_friend_state.gd test/test_video_schedule.gd test/test_night_state.gd
git commit -m "La espera de los pedidos de ayuda, las vidas perdidas y los videos asentados"
```

---

## Tarea 4: la noche termina cuando se completa

**Archivos:**
- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/data/difficulty_data.gd`, `data/difficulty/hard.tres`, `scripts/core/night_state.gd`, `scripts/desk/request_manager.gd` y `scripts/desk/night_manager.gd`
- Pruebas: `test/test_night_state.gd`, `test/test_night_manager.gd`, `test/test_request_manager.gd` y `test/test_balance.gd`

- [ ] **Paso 1: las pruebas**

En `test/test_night_state.gd`, reemplaza la función `test_a_las_06_gana_si_cumplio_la_cuota` entera por:

```gdscript
## La noche no termina por la hora (Plan 9.9): cuando se completa, gana si cumplió la cuota y, si no, pierde.
func test_al_completarse_gana_si_cumplio_la_cuota() -> bool:
	var state := _make_state()
	_advance_downloading(state, 420)
	check_eq(state.videos.received, 2, "descargó los 2 envíos")
	check_eq(state.ending(), NightState.Ending.NONE, "a las 06:00 la noche sigue")
	state.finished = true
	check_eq(state.ending(), NightState.Ending.WON, "ganó")
	state = _make_state()
	_advance(state, 420)
	check_eq(state.videos.lost, 2, "sin descargarlos, se pierden")
	state.finished = true
	check_eq(state.ending(), NightState.Ending.QUOTA, "pierde por la cuota")
	return true
```

y, en `test_en_el_tutorial_no_se_pierde`, reemplaza `state.elapsed = catalog.balance.night_seconds` por `state.finished = true`.

En `test/test_night_manager.gd`, agrega junto a los otros `preload`:

```gdscript
const PacingDirector := preload("res://scripts/core/pacing_director.gd")
```

y reemplaza las funciones `test_a_las_06_con_la_cuota_se_gana` y `test_a_las_06_sin_la_cuota_se_pierde` enteras por:

```gdscript
## La noche termina cuando se completa (Plan 9.9): la ola final resuelta (aquí, a mano), nada abierto y los videos
## recibidos, y 3 s después. Con la cuota, se gana.
func test_al_completarse_con_la_cuota_se_gana() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	_advance_downloading(night, 420)
	check(endings.is_empty(), "a las 06:00 sigue: la ola final no ha terminado")
	_requests.director.phase = PacingDirector.Phase.DONE
	_advance_downloading(night, 2)
	check(endings.is_empty(), "completa, espera 3 s")
	_advance_downloading(night, 1)
	check_eq(endings, [[NightState.Ending.WON, null]], "ganó")
	check(night.ended, "terminó")
	_free(night)
	return true


func test_al_completarse_sin_la_cuota_se_pierde() -> bool:
	var night := _make_night()
	var endings := []
	_record_endings(night, endings)
	night.state().videos.pending.clear()
	_requests.director.phase = PacingDirector.Phase.DONE
	_advance(night, 3)
	check_eq(endings, [[NightState.Ending.QUOTA, null]], "faltó contenido")
	_free(night)
	return true
```

Al final de `test/test_request_manager.gd`:

```gdscript



# --- La noche termina cuando se completa, y los pedidos de ayuda de la nota (Plan 9.9, docs/33).

## La noche se completa cuando la ola final llegó entera, no queda nada abierto ni videos por recibir y la historia
## terminó. 3 s después (end_pause), termina.
func test_la_noche_se_completa_cuando_no_queda_nada() -> bool:
	var manager := _make_manager()
	manager.state.videos.unreleased = 0
	check(not manager.night_complete(), "con olas por llegar, no")
	manager.director.phase = PacingDirector.Phase.DONE
	check(manager.night_complete(), "sin nada pendiente, sí")
	var request := manager.start_request(0)
	check(not manager.night_complete(), "con una consulta abierta, no")
	manager.answer(0, request.entity.actions[0])
	manager.state.videos.release(1, 0.0)
	check(not manager.night_complete(), "con un video en camino, no")
	manager.state.videos.pending.clear()
	check(manager.night_complete(), "respondida y sin videos, sí")
	manager.advance(2.9)
	check(not manager.state.finished, "a los 2,9 s, todavía no termina")
	manager.advance(0.2)
	check(manager.state.finished, "a los 3 s, termina")
	manager.free()
	return true


## El tutorial termina cuando León se despide, nunca solo (decisión de Benja).
func test_el_tutorial_no_se_completa_solo() -> bool:
	var manager := _make_manager()
	manager.state.videos.unreleased = 0
	manager.director.phase = PacingDirector.Phase.DONE
	manager.night_number = 0
	check(not manager.night_complete(), "en la noche 0, no")
	manager.free()
	return true


## Con historia, la noche espera a que terminen de contarla: el cierre del vlog.
func test_con_historia_espera_que_terminen_de_contarla() -> bool:
	var catalog := Fixtures.make_catalog()
	var manager := _story_manager([Fixtures.make_line(catalog.friends[0], "K_A")], false, catalog)
	manager.state.videos.unreleased = 0
	manager.director.phase = PacingDirector.Phase.DONE
	check(not manager.night_complete(), "la historia no ha terminado")
	for _step in 30:
		manager.advance(0.1)
	check(manager.story.is_done(), "terminaron de contarla")
	check(manager.night_complete(), "y la noche se completa")
	manager.free()
	return true


## Los pedidos de ayuda de la nota: consultas, accidentes y decisiones de la historia. Se cuentan al llegar, y los
## abiertos suman espera.
func test_cuenta_los_pedidos_de_ayuda() -> bool:
	var manager := _make_manager()
	manager.catalog.incidents.append(Fixtures.make_incident())
	check_eq(manager.waiting_count(), 0, "nada abierto")
	manager.start_request(0)
	manager.start_incident(1)
	check_eq(manager.waiting_count(), 2, "una consulta y un accidente")
	check_eq(manager.state.asked, 2, "2 pedidos")
	manager.free()
	var catalog := Fixtures.make_catalog()
	var story_manager := _story_manager([_decision_step(catalog)], false, catalog)
	story_manager.advance(0.1)
	check_eq([story_manager.waiting_count(), story_manager.state.asked], [1, 1], "la decisión de la historia, también")
	story_manager.free()
	return true


## La meta de espera de la nota es la de la dificultad.
func test_la_meta_de_espera_es_la_de_la_dificultad() -> bool:
	var manager := _make_manager()
	check_eq(manager.state.wait_goal, 15.0, "sin dificultad elegida, la de por defecto")
	manager.free()
	var catalog := Fixtures.make_catalog()
	var hard := Fixtures.add_hard(catalog)
	hard.wait_goal = 20.0
	manager = RequestManager.new()
	manager.catalog = catalog
	manager.difficulty = hard
	manager.night_number = 1
	manager.requests_arrive = false
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	check_eq(manager.state.wait_goal, 20.0, "la de Difícil")
	manager.free()
	return true
```

En `test/test_balance.gd`, en `test_valores_del_director_y_los_screamers`, después de la línea de `story_hold_limit`, agrega:

```gdscript
	check_eq(balance.end_pause, 3.0, "la noche termina 3 s después de completarse (Plan 9.9)")
```

y, después de esa función:

```gdscript


## La meta de espera de la nota en cada modo (decisión de Benja, 14 de noviembre): lo que logra quien juega bien.
func test_la_meta_de_espera_de_cada_modo() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	check_eq(catalog.find_difficulty(&"normal").wait_goal, 15.0, "Normal")
	check_eq(catalog.find_difficulty(&"hard").wait_goal, 20.0, "Difícil")
	check_eq(catalog.find_difficulty(&"extreme").wait_goal, 15.0, "Extremo")
	return true
```

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_night_state test_night_manager test_request_manager test_balance 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: las suites no cargan (faltan `finished`, `night_complete()`, `waiting_count()`, `end_pause` y `wait_goal`).

- [ ] **Paso 3: los datos**

En `scripts/data/balance_data.gd`, reemplaza:

```gdscript
@export var story_hold_limit := 45.0
```

por:

```gdscript
@export var story_hold_limit := 45.0
## Segundos entre que la noche se completa (la ola final resuelta, nada abierto y la historia contada) y su final: lo
## justo para leer lo último (decisión de Benja, 14 de noviembre; Plan 9.9).
@export var end_pause := 3.0
```

En `data/balance.tres`, después de la línea `story_hold_limit = 45.0`, agrega `end_pause = 3.0`.

En `scripts/data/difficulty_data.gd`, después de la línea `@export_range(1, 3) var wounded_health := 1`, agrega:

```gdscript

@export_group("Nota")
## La meta de espera por pedido de ayuda, en segundos: hasta aquí, la espera da 3 puntos de la nota (decisión de Benja, 14
## de noviembre; Plan 9.9). Es lo que logra quien juega bien (test/balance_model.gd): 15 en Normal, 20 en Difícil y 15
## en Extremo.
@export var wait_goal := 15.0
```

En `data/difficulty/hard.tres`, agrega al final de la sección `[resource]` la línea `wait_goal = 20.0`. Normal y Extremo usan el valor por defecto, 15.

- [ ] **Paso 4: el final de la noche**

En `scripts/core/night_state.gd`, reemplaza:

```gdscript
## La pone RequestManager.
var wait_goal := 15.0
```

por:

```gdscript
## La pone RequestManager.
var wait_goal := 15.0
## La noche se completó hace end_pause s: la ola final se resolvió, no queda nada abierto ni videos por recibir y la
## historia terminó (Plan 9.9). Lo pone RequestManager. Desde ahí se gana o, sin la cuota, se pierde.
var finished := false
```

y en `ending()`:

```gdscript
## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0.
## A las 06:00 se gana si se cumplió la cuota (diseño §5). El tutorial no termina solo: termina cuando se
## completa (decisión de Benja).
```

por:

```gdscript
## Cómo termina la noche, o NONE si sigue. Se pierde apenas muere un amigo o un dial llega a 0. Cuando la noche se
## completó (finished), se gana si se cumplió la cuota (Plan 9.9; antes, a las 06:00). El tutorial no termina solo:
## termina cuando León se despide (decisión de Benja).
```

y:

```gdscript
	if elapsed >= length:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
```

por:

```gdscript
	if finished:
		return Ending.WON if videos.is_quota_met() else Ending.QUOTA
```

En `scripts/desk/request_manager.gd`:

1. En el comentario del encabezado, antes de `## En el escritorio lo avanza NightManager, junto con el estado de la noche.`, agrega:

```gdscript
## Desde el Plan 9.9 (docs/33), dice cuándo se completa la noche (night_complete: la ola final resuelta, nada abierto,
## los videos recibidos y la historia contada) y, end_pause s después, la termina (NightState.finished). También cuenta
## los pedidos de ayuda para la nota.
```

2. Reemplaza:

```gdscript
var _seen_entities: Array[EntityData] = []
var _requests_started := 0
```

por:

```gdscript
var _seen_entities: Array[EntityData] = []
var _requests_started := 0
## Segundos que lleva completa la noche: a los end_pause, termina (Plan 9.9).
var _complete_seconds := 0.0
```

3. Reemplaza:

```gdscript
	state = NightState.new(night(), balance, catalog.friends.size(), rng)
```

por:

```gdscript
	state = NightState.new(night(), balance, catalog.friends.size(), rng)
	if current != null:
		state.wait_goal = current.wait_goal
```

4. Reemplaza el final de `advance()`:

```gdscript
			_maybe_start_request()
			_maybe_start_incident()
	_advance_story(delta)
```

por:

```gdscript
			_maybe_start_request()
			_maybe_start_incident()
	_advance_story(delta)
	_complete_seconds = _complete_seconds + delta if night_complete() else 0.0
	state.finished = _complete_seconds >= balance.end_pause
```

5. Después de la función `impatient_count()`, agrega:

```gdscript


## Los pedidos de ayuda abiertos: consultas, accidentes y decisiones de la historia. Con ellos se mide la espera de la
## nota (Plan 9.9).
func waiting_count() -> int:
	return active_count() + incidents.size() - incidents.count(null)


## La noche se completó (Plan 9.9): la ola final llegó entera, no queda nada abierto (consultas, accidentes ni
## decisiones), ningún video espera llegar ni descargarse, y la historia terminó de contarse. El tutorial nunca: termina
## cuando León se despide.
func night_complete() -> bool:
	if night().is_tutorial() or director.phase != PacingDirector.Phase.DONE:
		return false
	if _story_busy() or not state.videos.is_settled():
		return false
	return story == null or story.is_done()
```

6. En `start_request()`, reemplaza `	_requests_started += 1` por:

```gdscript
	_requests_started += 1
	state.asked += 1
```

7. En `start_incident()`, reemplaza:

```gdscript
	incidents[friend_index] = incident
	_add_friend_message(friend_index, MessageBuilder.incident(data, tr))
	return incident
```

por:

```gdscript
	incidents[friend_index] = incident
	state.asked += 1
	_add_friend_message(friend_index, MessageBuilder.incident(data, tr))
	return incident
```

8. En `_do_story()`, reemplaza:

```gdscript
			incidents[item.friend] = FriendIncident.for_decision(item.decision, item.friend,
					catalog.balance.incident_seconds * timer_scale) as FriendIncident
```

por:

```gdscript
			incidents[item.friend] = FriendIncident.for_decision(item.decision, item.friend,
					catalog.balance.incident_seconds * timer_scale) as FriendIncident
			state.asked += 1
```

En `scripts/desk/night_manager.gd`, reemplaza:

```gdscript
## El reloj de la noche (Plan 5): avanza las solicitudes y el estado de la noche, en ese orden, y decide
## cuándo termina. Se gana a las 06:00 con la cuota cumplida. Se pierde apenas muere un amigo o
## Sanity, Trust o Connection llegan a 0, o a las 06:00 si falta contenido (diseño §5).
```

por:

```gdscript
## El reloj de la noche (Plan 5): avanza las solicitudes y el estado de la noche, en ese orden, y decide
## cuándo termina. Desde el Plan 9.9, la noche termina cuando se completa (RequestManager.night_complete): con la cuota
## cumplida se gana y, sin ella, se pierde. Se pierde apenas muere un amigo o Sanity, Trust o Connection llegan a 0
## (diseño §5).
```

y:

```gdscript
	requests.state.impatient = requests.impatient_count()
```

por:

```gdscript
	requests.state.impatient = requests.impatient_count()
	requests.state.waiting = requests.waiting_count()
```

- [ ] **Paso 5: correr todas las pruebas**

Esperado: **857 pruebas OK** (851 más 6: 5 en `test_request_manager` y 1 en `test_balance`; las 2 de `test_night_manager` reemplazan a otras 2).

- [ ] **Paso 6: commit**

```bash
git add scripts/data/balance_data.gd data/balance.tres scripts/data/difficulty_data.gd data/difficulty/hard.tres scripts/core/night_state.gd scripts/desk/request_manager.gd scripts/desk/night_manager.gd test/test_night_state.gd test/test_night_manager.gd test/test_request_manager.gd test/test_balance.gd
git commit -m "La noche termina cuando se completa: la ola final, los videos y la historia, y 3 s después"
```

---

## Tarea 5: el modelo hasta que la noche se completa, y el equilibrio

**Archivos:**
- Reemplazar: `test/balance_model.gd`
- Modificar: `test/dump_waves.gd` y los `.tres` de las noches que se calibran
- Crear: `test/dump_night_lengths.gd`
- Pruebas: `test/test_balance.gd`

- [ ] **Paso 1: las pruebas**

En `test/test_balance.gd`:

1. En `test_identificacion_por_preguntas`, reemplaza `var requests := [7, 7, 9, 9, 11]` por:

```gdscript
	# Difícil 5 baja de 11 a 9 (decisión de Benja, 14 de noviembre): antes se saltaba una ola que no cabía, y con las olas
	# en cadena (Plan 9.9) llegarían las 11.
	var requests := [7, 7, 9, 9, 9]
```

2. Reemplaza la función `test_la_bateria_alcanza_en_cada_noche` entera, con su comentario, por:

```gdscript
## La batería de los flashes, más la que hace falta para reponer Sanity jugando bien, no pasa de 100 %, en las 5 noches
## de cada dificultad. Desde el Plan 9.9, la noche dura lo que tarda en completarse.
func test_la_bateria_alcanza_en_cada_noche() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var length := BalanceModel.night_length(night, catalog.balance, attention)
			var needed := BalanceModel.battery_needed(night, catalog.balance, length)
			check(needed <= 100.0, "%s, noche %d: pide %.1f %% de batería" % [difficulty.id, night.number, needed])
	return true
```

3. En `test_jugando_bien_nada_vence`, reemplaza:

```gdscript
				check(result["requests"] >= night.total_requests() - 2, "%s: llegan casi todas: %d"
						% [who, result["requests"]])
```

por:

```gdscript
				check_eq(result["requests"], night.total_requests(), who + ": llegan todas (Plan 9.9: ninguna ola se salta)")
```

4. En `test_extremo_es_mas_duro_que_dificil`, reemplaza:

```gdscript
		check(extreme[index].wave_calm.y < calm.x, who + ": calmas más cortas")
```

por:

```gdscript
		var hard_calm: Vector2 = hard[index].wave_calm if hard[index].wave_calm != Vector2.ZERO else calm
		check(extreme[index].wave_calm.x < hard_calm.x and extreme[index].wave_calm.y < hard_calm.y,
				who + ": calmas más cortas")
```

5. Al final del archivo, agrega:

```gdscript



# --- La noche termina cuando se acaba (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33).

## Jugando bien, la noche no deja tiempo muerto al final (el tester de la segunda prueba esperó 1:20 sin nada): termina
## end_pause s después de lo último que había que hacer o, con historia, de que terminan de despedirse.
func test_la_noche_termina_cuando_se_acaba() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			var outro := 0.0
			if night.story != null:
				var needs := StoryRunner.story_needs(night.story, Callable(TranslationServer, "translate"),
						catalog.balance.incident_seconds)
				outro = float(needs.get(StoryBeatData.Moment.AFTER_FINALE, 0.0))
			for seed_value in 5:
				var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty), catalog.friends)
				var last := 0.0
				for task: Dictionary in result["tasks"]:
					last = maxf(last, task["end"])
				var dead: float = result["end"] - last
				check(dead <= outro + catalog.balance.end_pause + 1.0, "%s, noche %d, semilla %d: %.1f s después de lo último"
						% [difficulty.id, night.number, seed_value + 1, dead])
	TranslationServer.set_locale(previous)
	return true


## Jugando bien, ninguna noche termina antes de las 04:30 en promedio (decisión de Benja, 14 de noviembre): donde las olas
## en cadena la dejaban muy corta, sus calmas son más largas.
func test_ninguna_noche_termina_antes_de_las_04_30() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var earliest := catalog.balance.night_seconds * 4.5 / 6.0
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var total := 0.0
			for seed_value in SEEDS:
				total += BalanceModel.simulate(night, catalog.balance, seed_value + 1, attention, catalog.friends)["end"]
			var average := total / SEEDS
			check(average >= earliest, "%s, noche %d: termina a las %s" % [difficulty.id, night.number,
					BalanceModel.clock(average, catalog.balance)])
	return true
```

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_balance 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: la suite no carga (faltan `night_length()`, `clock()` y el `"end"` del modelo).

- [ ] **Paso 3: el modelo nuevo**

Reemplaza `test/balance_model.gd` entero por:

```gdscript
extends RefCounted
## El modelo de "jugar bien" para la prueba de equilibrio (Plan 9.1, docs/24): Benja pidió que toda noche se pueda
## ganar. No es contenido del juego.
## Quien juega bien ya conoce a las entidades: a cada solicitud le dedica 12 s de atención (14 s en Difícil, donde no
## marca ni espera a Matías, pero lee y busca la página en el índice; Plan 9.4) y le hace 2 preguntas, que le quitan
## 10 s al temporizador; un accidente le toma 4 s, espantar a la Mano 4 s (antes de que agarre) y descargar un
## video 10 s. Atiende de a una tarea, la que vence primero. Cuando llega la criatura, cierra la cortina a los 3 s y la
## revisa 2 veces, 1 s cada vez. Nunca se equivoca ni pierde un video, y quiere terminar con Sanity sobre 10.
## Los valores al azar se toman en su peor caso: la criatura se queda lo más posible.
## En Extremo (Plan 9.6, docs/30) solo llega quien terminó Difícil: un experto que resuelve cada consulta en 11 s.
## El modelo no cuenta como tareas las sincronizaciones ni el scroll del celular: la holgura (free_time_ratio) revisa que
## quepan en el tiempo libre de la noche.
## Desde el Plan 9.7 (docs/31), juega la historia de la noche con el StoryRunner real: leer las líneas no es una tarea
## (es opcional), pero cada decisión sí, como un accidente, y ocupa a su amigo. Quien juega bien elige la buena opción que
## más Trust cuesta, y su castigo vale: Trust y los segundos menos de la próxima consulta de cada castigado. Mientras la
## historia cuenta algo, la próxima ola espera, como en el juego.
## Desde el Plan 9.9 (docs/33), la noche no termina a una hora: el modelo la corre hasta que se completa (la ola final
## llegó entera, no queda nada abierto salvo la Mano, los videos llegaron y la historia terminó) y end_pause s más, como
## el juego. Sanity, la batería y la holgura se miden con lo que dura.

const PacingDirector := preload("res://scripts/core/pacing_director.gd")
const RequestGenerator := preload("res://scripts/core/request_generator.gd")
const StoryRunner := preload("res://scripts/core/story_runner.gd")

const REQUEST_ATTENTION := 12.0
## En Difícil se identifica leyendo (decisión de Benja, D3). Con 15 s, la noche 5 de Difícil ya no se puede ganar.
const READING_ATTENTION := 14.0
## En Extremo juega un experto (docs/30). Con 12 s, las noches 4 y 5 de Extremo ya no se pueden ganar.
const EXPERT_ATTENTION := 11.0
## Se sincroniza a un amigo cuando su señal baja de 30 (mucha estática), y se recupera hasta 100.
const SYNC_RECOVERY := 70.0
## Lo que toma abrir el mixer y empezar la ronda, además de la ronda.
const SYNC_OVERHEAD := 2.0
## Corcheas de una ronda de Audio Sync: la cuenta (8), los 4 aplausos del amigo (8) y la respuesta (8).
const SYNC_ROUND_STEPS := 24
const QUESTIONS := 2
const INCIDENT_ATTENTION := 4.0
const HAND_ATTENTION := 4.0
const VIDEO_ATTENTION := 10.0
const CREATURE_REACTION := 3.0
const CREATURE_CHECKS := 2
const CHECK_SECONDS := 1.0
const SANITY_MARGIN := 10.0
const FRIENDS := 3
## Cada cuánto avanza la simulación.
const STEP := 0.1
## Un tope de seguridad, en segundos: ninguna noche jugada bien dura tanto. Si una llega aquí, no se completó.
const MAX_NIGHT_SECONDS := 1200.0


## Los segundos por consulta de quien juega bien en `difficulty`: guiado (Normal), leyendo (Difícil) o un experto que
## lee (Extremo).
static func attention_for(difficulty: DifficultyData) -> float:
	if difficulty.highlights:
		return REQUEST_ATTENTION
	return EXPERT_ATTENTION if difficulty.id == &"extreme" else READING_ATTENTION


## Lo que dura sincronizar a un amigo: sus rondas de Audio Sync (4 aplausos cada una, cada ronda más rápida) más lo que
## toma abrir el mixer.
static func sync_seconds(night: NightData, balance: BalanceData) -> float:
	var total := SYNC_OVERHEAD
	for index in maxi(night.audio_sync_beats / 4, 1):
		var bpm := night.audio_sync_bpm * pow(balance.audio_sync_round_speedup, index)
		total += SYNC_ROUND_STEPS * 30.0 / bpm
	return total


## Lo que dura la noche de quien juega bien: la más larga de `seeds` semillas (Plan 9.9: ya no tiene hora de término).
static func night_length(night: NightData, balance: BalanceData, attention: float, seeds := 5) -> float:
	var longest := 0.0
	for seed_value in seeds:
		longest = maxf(longest, float(simulate(night, balance, seed_value + 1, attention)["end"]))
	return longest


## Los segundos que quien juega bien necesita fuera de las tareas en una noche de `length` s: sincronizar a los amigos
## (lo que pierden de señal con el tiempo, a su ritmo promedio, y con las interferencias) y scrollear para reponer Sanity.
static func free_time_needed(night: NightData, balance: BalanceData, length: float) -> float:
	var loss := night.total_interferences() * balance.interference_damage
	if night.signal_decays:
		var decay := (night.signal_decay_interval.x + night.signal_decay_interval.y) / 2.0
		loss += FRIENDS * length / decay
	var scroll := scroll_battery(night, balance, length) / 100.0 * balance.phone_battery_seconds
	return loss / SYNC_RECOVERY * sync_seconds(night, balance) + scroll


## La holgura de la noche con `attention` segundos por consulta: el menor tiempo libre (sin tareas abiertas, desde la
## primera ola hasta que la noche termina) entre `seeds` semillas, dividido por lo que se necesita fuera de las tareas en
## la noche más larga. Con 1 o más, cabe.
static func free_time_ratio(night: NightData, balance: BalanceData, attention: float, seeds: int) -> float:
	var free := INF
	var length := 0.0
	for seed_value in seeds:
		var result := simulate(night, balance, seed_value + 1, attention)
		length = maxf(length, result["end"])
		var first: float = result["waves"][0][0] if not result["waves"].is_empty() else 0.0
		var idle := 0.0
		for second in result["load"].size():
			if second >= first and result["load"][second] == 0:
				idle += 1.0
		free = minf(free, idle)
	var needed := free_time_needed(night, balance, length)
	return INF if needed <= 0.0 else free / needed


## La batería que gasta quien juega bien en una noche de `length` s, en %: la que hace falta para reponer Sanity, más un
## flash por cada visita de la Mano. Tiene que ser 100 o menos.
static func battery_needed(night: NightData, balance: BalanceData, length: float) -> float:
	return scroll_battery(night, balance, length) + night.total_hands() * balance.flash_cost


## La batería que hace falta para reponer Sanity en una noche de `length` s, en %.
static func scroll_battery(night: NightData, balance: BalanceData, length: float) -> float:
	var to_recover := maxf(sanity_loss(night, balance, length) - (100.0 - SANITY_MARGIN), 0.0)
	return to_recover / balance.scroll_sanity_per_second / balance.phone_battery_seconds * 100.0


## Cuánta Sanity pierde quien juega bien en una noche de `length` s: con el tiempo, con los screamers y con la criatura
## (con la cortina abierta hasta cerrarla, cerrada mientras se queda y abierta en cada revisión).
static func sanity_loss(night: NightData, balance: BalanceData, length: float) -> float:
	var loss := length / night.sanity_drain_interval
	loss += (night.total_scares() - night.total_creatures()) * balance.scare_sanity
	loss += night.total_creatures() * balance.jumpscare_sanity
	var open := (CREATURE_REACTION + CREATURE_CHECKS * CHECK_SECONDS) * balance.creature_sanity
	loss += night.total_creatures() * (open + balance.creature_stay.y * balance.closed_curtains_sanity)
	return loss


## La espera promedio por pedido de ayuda (consultas, accidentes y decisiones) de una noche simulada, como la de la nota
## (Plan 9.9).
static func average_wait(result: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for task: Dictionary in result["tasks"]:
		if task["kind"] in ["request", "incident", "decision"]:
			total += task["end"] - task["arrival"]
			count += 1
	return total / count if count > 0 else 0.0


## La hora del reloj a los `seconds` de la noche, como en el celular: "04:52".
static func clock(seconds: float, balance: BalanceData) -> String:
	var minutes := int(seconds / balance.night_seconds * 360.0)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


## Corre la noche con el director real y quien juega bien, que dedica `attention` segundos a cada consulta
## (attention_for), hasta que se completa. Devuelve "missed" (las tareas que vencieron sin atender),
## "trust" (Trust al final: baja por las solicitudes que esperan más de la cuenta y por las decisiones de la historia),
## "requests" (cuántas llegaron), "tasks" (cada una con su tipo, su llegada, su fin y su plazo), "waves" y "calms" (las
## horas en que empezó cada una), "interferences", "videos", "scares" ([hora, es la criatura]), "load" (cuántas tareas
## había abiertas, cada segundo), "story" (los índices de los momentos de la historia enteros, saltados y cortados:
## "finished", "skipped" y "cut"), "story_hold" (lo más que esperó una ola a la historia, en segundos) y "end" (a qué hora
## terminó la noche: end_pause s después de completarse).
## `friends`: los amigos del catálogo, para la historia (sin ellos, los de data/catalog.tres).
static func simulate(night: NightData, balance: BalanceData, seed_value: int,
		attention := REQUEST_ATTENTION, friends: Array[FriendData] = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var previous_locale := TranslationServer.get_locale()
	var story_needs := {}
	if night.story != null:
		# Las líneas duran lo que se tarda en leer su texto en español.
		TranslationServer.set_locale("es")
		story_needs = StoryRunner.story_needs(night.story, Callable(TranslationServer, "translate"), balance.incident_seconds)
	var director := PacingDirector.new(night, balance, rng, story_needs)
	var result := {"missed": 0, "trust": 100.0, "requests": 0, "tasks": [], "waves": [], "calms": [],
			"interferences": [], "videos": [], "scares": [], "load": [],
			"story": {"finished": [], "skipped": [], "cut": []}, "story_hold": 0.0, "end": 0.0}
	var story: StoryRunner = null
	if night.story != null:
		if friends.is_empty():
			friends = (load("res://data/catalog.tres") as ContentCatalog).friends
		story = StoryRunner.new(night.story, friends, Callable(TranslationServer, "translate"), balance.incident_seconds)
	## Los segundos que la historia le quitó a la próxima consulta de cada amigo.
	var penalty: Array[float] = [0.0, 0.0, 0.0]
	var open: Array[Dictionary] = []
	var busy: Array[bool] = []
	busy.resize(FRIENDS)
	busy.fill(false)
	var pending_videos: Array[float] = []
	var time := 0.0
	var next_sample := 0.0
	## Desde qué hora está completa la noche, o -1.
	var complete_at := -1.0
	while time < MAX_NIGHT_SECONDS:
		var active := open.filter(func(task: Dictionary) -> bool: return task["kind"] == "request").size()
		if story != null:
			director.story_hold = story.holds()
			var waiting := director.phase in [PacingDirector.Phase.SILENCE, PacingDirector.Phase.CALM] \
					and director.wave_index < director.waves.size() and time >= director.next_at
			if director.story_hold and waiting:
				result["story_hold"] = maxf(result["story_hold"], time - director.next_at)
		var beat := director.advance(time, active)
		if beat.wave_started >= 0:
			result["waves"].append([time, beat.finale_started])
		if beat.calm_started:
			result["calms"].append(time)
		result["interferences"].append_array(beat.interferences)
		pending_videos.append_array(beat.videos)
		for video_time: float in pending_videos.duplicate():
			if video_time <= time:
				pending_videos.erase(video_time)
				result["videos"].append(video_time)
				open.append(_task("video", time, time + balance.video_accept_seconds + VIDEO_ATTENTION, VIDEO_ATTENTION, -1))
		var trust: float = result["trust"]
		while director.request_due(time) and busy.has(false) and active < night.max_simultaneous:
			director.request_started(time)
			var friend := busy.find(false)
			busy[friend] = true
			active += 1
			result["requests"] += 1
			var deadline := time + RequestGenerator.decision_time(night, trust) - QUESTIONS * balance.question_cost
			deadline -= penalty[friend]
			penalty[friend] = 0.0
			open.append(_task("request", time, deadline, attention, friend))
		if director.incident_due(time) and busy.has(false):
			director.incident_started()
			var friend := busy.find(false)
			busy[friend] = true
			open.append(_task("incident", time, time + balance.incident_seconds, INCIDENT_ATTENTION, friend))
		if director.hand_due(time):
			director.hand_started()
			open.append(_task("hand", time, time + balance.hand_approach_seconds, HAND_ATTENTION, -1))
		while director.scare_due(time):
			result["scares"].append([time, director.next_is_jumpscare()])
			director.scare_started(time)
		if story != null:
			_advance_story(story, open, busy, time, director)
		var closed_before: int = result["tasks"].size()
		_work(open, busy, result, balance, time)
		if story != null:
			_resolve_decisions(story, result, closed_before, friends, penalty)
		if time >= next_sample:
			result["load"].append(open.size())
			next_sample += 1.0
		if _complete(director, open, pending_videos, story):
			if complete_at < 0.0:
				complete_at = time
			if time >= complete_at + balance.end_pause:
				break
		else:
			complete_at = -1.0
		time += STEP
	result["end"] = time
	if story != null:
		TranslationServer.set_locale(previous_locale)
		result["story"] = {"finished": story.finished_beats, "skipped": story.skipped_beats, "cut": story.cut_beats}
	return result


## La noche está completa, como en RequestManager.night_complete(): la ola final llegó entera, no queda nada abierto
## (salvo la Mano, que no la detiene), ningún video espera llegar y la historia terminó.
static func _complete(director: PacingDirector, open: Array[Dictionary], pending_videos: Array[float],
		story: StoryRunner) -> bool:
	if director.phase != PacingDirector.Phase.DONE or not pending_videos.is_empty():
		return false
	if open.any(func(task: Dictionary) -> bool: return task["kind"] != "hand"):
		return false
	return story == null or story.is_done()


## La historia avanza: con consultas, accidentes o decisiones abiertas está ocupada; la llamada se ve sin eso y sin videos
## por descargar. Una decisión llega como un accidente (15 s, 4 s de atención) y ocupa a su amigo.
static func _advance_story(story: StoryRunner, open: Array[Dictionary], busy: Array[bool], time: float,
		director: PacingDirector) -> void:
	var playing := open.filter(func(task: Dictionary) -> bool: return task["kind"] != "hand")
	var engaged := playing.any(func(task: Dictionary) -> bool: return task["kind"] != "video")
	var is_free := func(friend: int) -> bool: return not busy[friend]
	for item: StoryRunner.Item in story.advance(STEP, time, director, engaged, playing.is_empty(), is_free):
		if item.command != StoryRunner.Command.DECISION:
			continue
		busy[item.friend] = true
		var task := _task("decision", time, time + BalanceData.new().incident_seconds, INCIDENT_ATTENTION, item.friend)
		task["decision"] = item.decision
		open.append(task)


## Las decisiones que terminaron en este paso: quien juega bien eligió la buena opción que más Trust cuesta; si venció,
## la de sin respuesta. Su castigo vale (Trust nunca baja de 1 por la historia), y la historia sigue.
static func _resolve_decisions(story: StoryRunner, result: Dictionary, closed_before: int, friends: Array[FriendData],
		penalty: Array[float]) -> void:
	for task: Dictionary in result["tasks"].slice(closed_before):
		if task["kind"] != "decision":
			continue
		var decision: StoryDecisionData = task["decision"]
		var option := decision.no_answer if task["work"] > 0.0 else worst_good_option(decision)
		var trust: float = result["trust"]
		result["trust"] = clampf(trust + option.trust_change, minf(trust, 1.0), 100.0)
		for friend: FriendData in option.penalized:
			var index := friends.find(friend)
			if index >= 0:
				penalty[index] += option.penalty_seconds
		story.decided(option)


## La buena opción de una decisión que más Trust cuesta (la peor de las buenas): quien juega bien no se equivoca, pero se
## prueba lo más caro que puede elegir.
static func worst_good_option(decision: StoryDecisionData) -> StoryOptionData:
	var worst: StoryOptionData = null
	for option: StoryOptionData in decision.options:
		if option.good and (worst == null or option.trust_change < worst.trust_change):
			worst = option
	return worst


static func _task(kind: String, arrival: float, deadline: float, work: float, friend: int) -> Dictionary:
	return {"kind": kind, "arrival": arrival, "deadline": deadline, "work": work, "friend": friend, "end": -1.0}


## Atiende la tarea que vence primero. Las que vencen sin atender cuentan como perdidas.
static func _work(open: Array[Dictionary], busy: Array[bool], result: Dictionary, balance: BalanceData,
		time: float) -> void:
	if open.is_empty():
		return
	open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["deadline"] < b["deadline"])
	var task: Dictionary = open[0]
	task["work"] -= STEP
	if task["work"] <= 0.0:
		_close(task, open, busy, result, balance, time + STEP)
	for late: Dictionary in open.duplicate():
		if time > late["deadline"]:
			result["missed"] += 1
			_close(late, open, busy, result, balance, time)


static func _close(task: Dictionary, open: Array[Dictionary], busy: Array[bool], result: Dictionary,
		balance: BalanceData, time: float) -> void:
	task["end"] = time
	open.erase(task)
	if task["friend"] >= 0:
		busy[task["friend"]] = false
	result["tasks"].append(task)
	if task["kind"] != "request":
		return
	# Lo que esperó, con lo que le quitaron las preguntas: más allá del plazo de gracia, Trust baja.
	var waited: float = time - task["arrival"] + QUESTIONS * balance.question_cost
	var slow := maxf(waited - balance.slow_answer_grace, 0.0) * balance.slow_answer_trust
	result["trust"] = maxf(result["trust"] - slow, 0.0)
```

En `test/dump_waves.gd`, reemplaza:

```gdscript
	result["night_seconds"] = catalog.balance.night_seconds
	result["battery"] = BalanceModel.battery_needed(night, catalog.balance)
	result["free_time_needed"] = BalanceModel.free_time_needed(night, catalog.balance)
```

por:

```gdscript
	# Lo que duró la noche (Plan 9.9: termina cuando se completa): tools/plot_waves.py dibuja hasta ahí.
	result["night_seconds"] = result["end"]
	result["battery"] = BalanceModel.battery_needed(night, catalog.balance, result["end"])
	result["free_time_needed"] = BalanceModel.free_time_needed(night, catalog.balance, result["end"])
```

y, en su comentario, `## La dificultad es "normal" (por defecto) o "hard".` por `## La dificultad es "normal" (por defecto), "hard" o "extreme".`.

Crea `test/dump_night_lengths.gd`:

```gdscript
extends SceneTree
## Mide las noches de los 3 modos con quien juega bien (test/balance_model.gd), para calibrar las calmas (Plan 9.9,
## docs/33, Tarea 5). No es una prueba.
## Uso: ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_night_lengths.gd 2>&1 | tr -d '\r' | grep noche
## Por noche: a qué hora termina en promedio (y la más temprana y la más tarde de 20 semillas), la holgura, la batería, la
## espera promedio por pedido de ayuda y la calma entre olas.

const BalanceModel := preload("res://test/balance_model.gd")
const SEEDS := 20


func _initialize() -> void:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	var balance := catalog.balance
	for difficulty: DifficultyData in catalog.difficulties:
		var attention := BalanceModel.attention_for(difficulty)
		for night: NightData in difficulty.nights:
			var total := 0.0
			var earliest := INF
			var latest := 0.0
			var wait := 0.0
			for seed_value in SEEDS:
				var result := BalanceModel.simulate(night, balance, seed_value + 1, attention, catalog.friends)
				var end: float = result["end"]
				total += end
				earliest = minf(earliest, end)
				latest = maxf(latest, end)
				wait += BalanceModel.average_wait(result)
			var ratio := BalanceModel.free_time_ratio(night, balance, attention, SEEDS)
			var battery := BalanceModel.battery_needed(night, balance, latest)
			var calm := "plan" if night.has_wave_plan() else str(night.wave_calm if night.wave_calm != Vector2.ZERO
					else balance.wave_calm)
			print("%s noche %d | termina %s (%s a %s) | holgura %.2f | batería %.0f %% | espera %.1f s | calma %s" % [
					difficulty.id, night.number, BalanceModel.clock(total / SEEDS, balance),
					BalanceModel.clock(earliest, balance), BalanceModel.clock(latest, balance), ratio, battery,
					wait / SEEDS, calm])
	quit()
```

- [ ] **Paso 4: Difícil 5 con 9 consultas**

En `data/nights/hard/night_5.tres`, reemplaza `requests_total = 11` por `requests_total = 9`.

- [ ] **Paso 5: medir**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_night_lengths.gd 2>&1 | tr -d '\r' | grep noche
```

Toma 1 o 2 minutos. Copia la tabla en la sección "Resultado" de este plan, como "antes de calibrar".

Para orientarte, esto midió S21n con un prototipo del director en cadena, la lectura nueva y Difícil 5 todavía con 11 consultas (máximo de 10 semillas):
- **Normal:** de 1 a 5 terminaban a las 05:24, 03:43, 04:39, 04:53 y 05:04.
- **Difícil:** 05:02, 04:03, 05:14, 05:18 y 06:36.
- **Extremo:** 05:53, 05:07, 05:09, 05:57 y 06:00, con holgura de 0,85 a 0,90 en las noches 2 a 5.

- [ ] **Paso 6: calibrar las calmas**

Ajusta, vuelve a medir con el Paso 5 y repite hasta cumplir las 2 reglas, en este orden:

1. **Extremo:** la holgura de las 5 noches debe ser de 1,00 o más. Todas las noches de Extremo comparten la calma, como hoy. Prueba `wave_calm = Vector2(25, 35)` en los 5 archivos `data/nights/extreme/night_*.tres` (reemplaza la línea `wave_calm = Vector2(20, 30)`). Si no alcanza, sube de 5 en 5: `(30, 40)`, `(35, 45)`… Quédate con la primera que cumpla.
2. **Normal y Difícil:** cada noche debe terminar, en promedio, a las 04:30 o después (la primera hora de la tabla). La noche 1 de Normal va armada a mano, así que si cae bajo las 04:30 (no debería: tiene la historia), avísale a Benja y no la toques. A cada otra noche que caiga antes, agrégale en su `.tres`, en la sección `[resource]` (por ejemplo después de `finale_size`), la línea `wave_calm = Vector2(45, 65)`. Si no alcanza, sube de 5 en 5: `(50, 70)`, `(55, 75)`… Quédate con la primera que cumpla. Las noches que ya terminan a las 04:30 o después no se tocan.

Después, vuelve a medir y copia la tabla final en "Resultado", como "después de calibrar", con los valores elegidos.

- [ ] **Paso 7: las pruebas con los valores medidos**

En `test/test_balance.gd`:

1. En `test_valores_de_extremo`, reemplaza `check_eq(night.wave_calm, Vector2(20, 30), who + ": calma de 20 a 30 s")` por la calma que elegiste, por ejemplo `check_eq(night.wave_calm, Vector2(25, 35), who + ": calma de 25 a 35 s (Plan 9.9: sin el tiempo muerto del final hacía falta más holgura)")`. En la misma prueba, cambia el comentario `# La noche 1 dura hasta las 06:30 (Plan 9.8): baja lo mismo en total, −1 cada 6,5 s.` por `# La noche 1 tiene −1 cada 6,5 s (Plan 9.8, cuando duraba hasta las 06:30).`.
2. En `test_valores_de_normal`, agrega al diccionario `expected` la línea `"wave_calm": [...]`, con la calma de las noches 2 a 5 de Normal, en orden. Usa `Vector2.ZERO` para las que no tocaste; por ejemplo, `"wave_calm": [Vector2(55, 75), Vector2(45, 65), Vector2.ZERO, Vector2.ZERO],`.
3. Si calibraste alguna noche de Difícil, agrega a `test_mantenimiento_de_cada_noche` (que lee Difícil):

   ```gdscript
   	check_eq(_nights(catalog, &"hard").map(func(night: NightData) -> Vector2: return night.wave_calm), [...],
   			"las calmas de Difícil (Plan 9.9: la noche 2 terminaba muy temprano)")
   ```

   con las 5 calmas, en orden y con `Vector2.ZERO` para las que no tocaste.
4. En `test_dificil_5_es_la_referencia`, la holgura de Difícil 5 con 9 consultas debe quedar entre 1 y 1,5. Si queda fuera, cambia el rango a `ratio >= 1.0 and ratio <= <medida + 0.25>` y agrega al comentario `Con 9 consultas y las olas en cadena (Plan 9.9), <medida>.`.

- [ ] **Paso 8: correr todas las pruebas**

Esperado: **859 pruebas OK** (857 más 2 en `test_balance`). Si falla una garantía (nada vence, Trust sobre 75, batería hasta 100 % o la historia entera), no la debilites: sube la calma de esa noche de 5 en 5, como en el Paso 6, y anótalo en "Resultado". Si `test_jugando_bien_la_final_casi_no_espera` falla, mira con `test/dump_waves.gd` qué momento de la historia no cabe.

- [ ] **Paso 9: commit**

```bash
git add test/balance_model.gd test/dump_waves.gd test/dump_night_lengths.gd test/test_balance.gd data/nights/
git commit -m "El modelo corre la noche hasta que se completa; Difícil 5 con 9 consultas y las calmas calibradas"
```

---

## Tarea 6: sin hora de término

**Archivos:**
- Modificar: `scripts/data/night_data.gd`, `scripts/core/night_state.gd`, `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/desk/request_manager.gd`, `scripts/core/ending_text.gd`, `data/nights/normal/night_1.tres`, `data/nights/hard/night_1.tres` y `data/nights/extreme/night_1.tres`
- Pruebas: `test/test_night_state.gd`, `test/test_catalog.gd`, `test/test_request_manager.gd` y `test/test_balance.gd`

- [ ] **Paso 1: las pruebas**

En `test/test_night_state.gd`, reemplaza la función `test_el_reloj_va_de_00_a_06` entera por:

```gdscript
## El reloj va a 70 s por hora y sigue después de las 06:00: la noche termina cuando se completa (Plan 9.9).
func test_el_reloj_sigue_despues_de_las_06() -> bool:
	var state := _make_state()
	state.advance(210.0)
	check_eq(state.clock_text(), "03:00", "a la mitad")
	state.advance(1.2)
	check_eq(state.clock_text(), "03:01", "un minuto de juego son 1,17 s")
	state.advance(210.0)
	check_eq(state.clock_text(), "06:01", "no se detiene a las 06:00")
	check(is_equal_approx(state.elapsed, 421.2), "segundos: %s" % state.elapsed)
	return true
```

y borra la función `test_una_noche_con_historia_termina_a_las_06_30` entera, con su comentario.

En `test/test_catalog.gd`, borra la función `test_las_noches_con_historia_terminan_a_las_06_30` entera, con su comentario.

En `test/test_request_manager.gd`, reemplaza la función `test_con_temporizadores_lentos_no_pasa_de_las_06` entera, con su comentario, por:

```gdscript
## Con "Temporizadores ×1,5", una solicitud dura 1,5 veces, también tarde en la noche: ya no hay hora de término (Plan
## 9.9).
func test_con_temporizadores_lentos_la_consulta_dura_mas() -> bool:
	var manager := _make_manager()
	manager.timer_scale = 1.5
	manager.advance(400.0)
	var request := manager.start_request(0)
	check_eq(request.time_left, 67.5, "45 s × 1,5")
	manager.free()
	return true
```

En `test/test_balance.gd`, borra la línea `check_eq(balance.finale_margin, 5.0, "la ola final deja 5 s libres al final (decisión de Benja, Plan 9.8)")`.

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_night_state test_request_manager 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK"
```

Esperado: fallan `test_el_reloj_sigue_despues_de_las_06` (el reloj se detiene en las 06:00) y `test_con_temporizadores_lentos_la_consulta_dura_mas` (la consulta se corta a lo que queda de noche: 20 s).

- [ ] **Paso 3: quitar el largo de la noche**

En `scripts/data/night_data.gd`, borra:

```gdscript
## Minutos de juego después de las 06:00: una noche con historia termina a las 06:30, para que la historia quepa sin
## regalar tiempo libre (decisión de Benja, Plan 9.8). El reloj sigue a la misma velocidad.
@export_range(0, 60) var overtime_minutes := 0
```

y la función `length()` entera, con su comentario (`## Cuánto dura la noche, en segundos reales: hasta las 06:00 ...`) y una de las líneas en blanco que la siguen.

En `scripts/core/night_state.gd`:

1. Reemplaza:

```gdscript
## La noche va de las 00:00 a las 06:00.
const NIGHT_HOURS := 6
```

por:

```gdscript
## Las 6 horas del reloj, de las 00:00 a las 06:00, duran night_seconds (70 s por hora). Desde el Plan 9.9 la noche no
## termina a una hora: el reloj sigue hasta que se completa.
const NIGHT_HOURS := 6
```

2. Borra:

```gdscript
## Cuánto dura la noche: hasta las 06:00 o, con historia, hasta las 06:30 (Plan 9.8).
var length := 0.0
```

3. En `_init()`, borra la línea `	length = night.length(balance)`.
4. En `advance()`, reemplaza `	elapsed = minf(elapsed + delta, length)` por `	elapsed += delta`.
5. Reemplaza el comentario `## La hora del celular, de "00:00" a "06:00" (o a "06:30", con historia): night_seconds son 6 horas.` por `## La hora del celular: night_seconds son 6 horas, y después de las 06:00 sigue (Plan 9.9).`.

En `scripts/data/balance_data.gd`:

1. Reemplaza:

```gdscript
## Segundos reales que dura una noche, de las 00:00 a las 06:00 (diseño §5). Una noche con historia sigue hasta las
## 06:30, a la misma velocidad (NightData.length).
```

por:

```gdscript
## Segundos reales de las 6 horas del reloj, de las 00:00 a las 06:00 (diseño §5): 70 s por hora. Desde el Plan 9.9 la
## noche no termina a una hora: termina cuando se completa, y el reloj sigue.
```

2. Borra:

```gdscript
## Lo que la ola final deja libre al final de una noche con historia: llega lo más tarde posible para que lo último que
## trae termine tantos segundos antes (decisión de Benja, Plan 9.8). Las noches sin historia dejan hurt_respite (10 s).
@export var finale_margin := 5.0
```

En `data/balance.tres`, borra la línea `finale_margin = 5.0`.

En los 3 `data/nights/*/night_1.tres`, borra la línea `overtime_minutes = 30`.

En `scripts/desk/request_manager.gd`, en el comentario de `start_request()`, reemplaza `## opción "Temporizadores ×1,5", más largo, pero nunca pasa de las 06:00. Si la historia le quitó segundos a la próxima` por `## opción "Temporizadores ×1,5", más largo, sin tope (Plan 9.9). Si la historia le quitó segundos a la próxima`, y en el código:

```gdscript
	request.time_left = minf(request.time_left * timer_scale, maxf(state.length - _elapsed, 0.0))
```

por:

```gdscript
	request.time_left *= timer_scale
```

En `scripts/core/ending_text.gd`, reemplaza `## Títulos (ui.csv). END_WON_TITLE lleva {time}, la hora en que terminó la noche (06:00, o 06:30 con historia).` por `## Títulos (ui.csv). END_WON_TITLE lleva {time}, la hora del reloj en que terminó la noche (Plan 9.9).`.

Verifica:

```bash
grep -rn "overtime_minutes\|finale_margin\|\.length(balance\|\.length(catalog\|state\.length\|night\.length" scripts test data tools
```

Esperado: sin resultados.

- [ ] **Paso 4: correr todas las pruebas**

Esperado: **857 pruebas OK** (859 menos 2: la de las 06:30 de `test_night_state` y la de `test_catalog`).

- [ ] **Paso 5: commit**

```bash
git add scripts/data/night_data.gd scripts/core/night_state.gd scripts/data/balance_data.gd data/balance.tres scripts/desk/request_manager.gd scripts/core/ending_text.gd data/nights/normal/night_1.tres data/nights/hard/night_1.tres data/nights/extreme/night_1.tres test/test_night_state.gd test/test_catalog.gd test/test_request_manager.gd test/test_balance.gd
git commit -m "Sin hora de término: se quitan las 06:00 y las 06:30 como final, y el tope de las consultas"
```

---

## Tarea 7: la nota

**Archivos:**
- Crear: `scripts/core/night_grade.gd`, `test/test_night_grade.gd` y `test/capture_plan99.gd`
- Modificar: `scripts/data/balance_data.gd`, `data/balance.tres`, `scripts/core/ending_text.gd`, `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn` y `data/text/ui.csv`
- Pruebas: `test/test_ending_text.gd`, `test/test_end_screen.gd` y `test/test_balance.gd`

- [ ] **Paso 1: las pruebas**

Crea `test/test_night_grade.gd`:

```gdscript
extends "res://test/test_case.gd"
## La nota de cada noche ganada (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33): la espera por pedido contra la
## meta de la dificultad y las vidas perdidas, de 0 a 3 puntos cada una. S con 5 o 6 puntos, A con 4, B con 2 o 3 y C con
## 0 o 1.

const Fixtures := preload("res://test/content_fixtures.gd")
const NightGrade := preload("res://scripts/core/night_grade.gd")
const NightState := preload("res://scripts/core/night_state.gd")


func test_puntos_por_la_espera() -> bool:
	var balance := BalanceData.new()
	check_eq(NightGrade.wait_points(15.0, 15.0, balance), 3, "en la meta, 3")
	check_eq(NightGrade.wait_points(22.5, 15.0, balance), 2, "hasta 1,5 veces la meta, 2")
	check_eq(NightGrade.wait_points(30.0, 15.0, balance), 1, "hasta el doble, 1")
	check_eq(NightGrade.wait_points(30.1, 15.0, balance), 0, "más, 0")
	return true


func test_puntos_por_las_vidas() -> bool:
	check_eq([NightGrade.life_points(0), NightGrade.life_points(1), NightGrade.life_points(2), NightGrade.life_points(5)],
			[3, 2, 1, 0], "ninguna 3, una 2, dos 1, más 0")
	return true


func test_la_letra() -> bool:
	var balance := BalanceData.new()
	var letters := range(7).map(func(points: int) -> String: return NightGrade.letter(points, balance))
	check_eq(letters, ["C", "C", "B", "B", "A", "S", "S"], "de 0 a 6 puntos")
	return true


func test_la_nota_de_una_noche() -> bool:
	var catalog := Fixtures.make_catalog()
	var state := NightState.new(catalog.nights()[0], catalog.balance, 3, RandomNumberGenerator.new())
	state.asked = 4
	state.waited = 4 * 19.0
	state.friends[1].hurt(1, 0.0)
	check_eq(NightGrade.letter_for(state), "A", "19 s contra 15 (2) y una vida perdida (2): 4 puntos")
	state.wait_goal = 20.0
	check_eq(NightGrade.letter_for(state), "S", "con la meta de Difícil, 19 s da 3: 5 puntos")
	return true
```

En `test/test_ending_text.gd`:

1. Agrega al diccionario `FORMATS`:

```gdscript
	"END_GRADE": "Nota {grade}",
	"END_WAIT": "Esperaron {seconds} de {goal}.",
	"END_LIVES": "Vidas: {lives}.",
```

2. En `test_sus_textos_existen`, agrega `EndingText.GRADE_KEY, EndingText.WAIT_KEY, EndingText.LIVES_KEY` a la lista `keys` (después de `EndingText.UNLOCKED_KEY`), y al diccionario `placeholders`:

```gdscript
		"END_GRADE": ["{grade}"],
		"END_WAIT": ["{seconds}", "{goal}"],
		"END_LIVES": ["{lives}"],
```

3. Al final del archivo:

```gdscript


## La nota al ganar (Plan 9.9): la letra, la espera por pedido contra la meta y las vidas perdidas.
func test_la_nota() -> bool:
	check_eq(EndingText.grade_title("A", _translate), "Nota A", "la letra")
	var state := _make_state()
	state.asked = 2
	state.waited = 37.0
	state.wait_goal = 20.0
	state.friends[0].hurt(2, 0.0)
	check_eq(EndingText.grade_detail(state, _translate), "Esperaron 19 de 20.\nVidas: 2.", "18,5 s se redondea a 19")
	return true
```

Al final de `test/test_end_screen.gd`:

```gdscript


## Al ganar una noche, la nota (Plan 9.9): la letra grande y, al final del resumen, la espera y las vidas.
func test_al_ganar_la_nota() -> bool:
	var screen := _make_screen()
	var state := _make_state()
	state.videos.received = 2
	state.asked = 4
	state.waited = 40.0
	screen.show_ending(NightState.Ending.WON, state, null, FRIENDS)
	var grade := screen.get_node("Center/Box/Grade") as Label
	check(grade.visible, "se ve")
	check_eq(grade.text, _translated("END_GRADE").format({"grade": "S"}), "10 s por pedido y ninguna vida perdida: S")
	var body := (screen.get_node("Center/Box/Body") as RichTextLabel).get_parsed_text()
	check(body.contains(_translated("END_WAIT").format({"seconds": 10, "goal": 15})), "la espera: " + body)
	check(body.contains(_translated("END_LIVES").format({"lives": 0})), "las vidas: " + body)
	screen.free()
	return true


func test_sin_nota_al_perder_ni_en_el_tutorial() -> bool:
	var screen := _make_screen()
	screen.show_ending(NightState.Ending.SANITY, _make_state(), null, FRIENDS)
	check(not (screen.get_node("Center/Box/Grade") as Label).visible, "al perder, no")
	screen.show_ending(NightState.Ending.WON, _make_state(), null, FRIENDS, 0)
	check(not (screen.get_node("Center/Box/Grade") as Label).visible, "en el tutorial, no")
	screen.free()
	return true
```

En `test/test_balance.gd`, agrega junto a los otros `const` de la sección del modelo (después de `const StoryRunner := ...`):

```gdscript
const NightGrade := preload("res://scripts/core/night_grade.gd")
```

y, al final del archivo:

```gdscript


## Los valores de la nota (decisiones de Benja, 14 de noviembre).
func test_valores_de_la_nota() -> bool:
	var balance: BalanceData = load(BALANCE_PATH)
	check_eq(balance.grade_wait_factors, Vector2(1.5, 2.0), "la espera da 2 puntos hasta 1,5 veces la meta y 1 hasta 2")
	check_eq([balance.grade_s_points, balance.grade_a_points, balance.grade_b_points], [5, 4, 2], "S desde 5, A con 4, B con 2")
	return true


## Jugando bien se saca S en toda noche (Plan 9.9): sin perder vidas y con una espera de 2 o 3 puntos.
func test_jugando_bien_se_saca_s() -> bool:
	var catalog: ContentCatalog = load("res://data/catalog.tres")
	for difficulty: DifficultyData in catalog.difficulties:
		for night: NightData in difficulty.nights:
			for seed_value in 5:
				var result := BalanceModel.simulate(night, catalog.balance, seed_value + 1,
						BalanceModel.attention_for(difficulty), catalog.friends)
				var wait := BalanceModel.average_wait(result)
				var points := NightGrade.wait_points(wait, difficulty.wait_goal, catalog.balance) + NightGrade.life_points(0)
				check_eq(NightGrade.letter(points, catalog.balance), "S", "%s, noche %d, semilla %d: %.1f s por pedido"
						% [difficulty.id, night.number, seed_value + 1, wait])
	return true
```

- [ ] **Paso 2: correr las pruebas y ver que fallan**

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd -- test_night_grade test_ending_text test_end_screen test_balance 2>&1 | tr -d '\r' | grep -E "^FALLA|pruebas OK|SCRIPT ERROR"
```

Esperado: las suites no cargan (faltan `night_grade.gd`, los valores y las funciones de la nota).

- [ ] **Paso 3: los valores**

En `scripts/data/balance_data.gd`, al final del archivo:

```gdscript

@export_group("Nota")
## La nota de cada noche ganada (decisiones de Benja, 14 de noviembre; Plan 9.9): la espera da 3 puntos hasta la meta de
## la dificultad (DifficultyData.wait_goal), 2 hasta x veces la meta y 1 hasta y veces; más, 0.
@export var grade_wait_factors := Vector2(1.5, 2.0)
## Desde cuántos puntos (de 6: 3 por la espera y 3 por las vidas) la nota es S, A o B; con menos, C.
@export var grade_s_points := 5
@export var grade_a_points := 4
@export var grade_b_points := 2
```

En `data/balance.tres`, al final de la sección `[resource]`:

```
grade_wait_factors = Vector2(1.5, 2)
grade_s_points = 5
grade_a_points = 4
grade_b_points = 2
```

- [ ] **Paso 4: la nota**

Crea `scripts/core/night_grade.gd`:

```gdscript
extends RefCounted
## La nota de una noche ganada (decisiones de Benja, 14 de noviembre; Plan 9.9, docs/33), como en Cuphead: S, A, B o C,
## según lo que esperaron los amigos y las vidas que perdieron esa noche.
## - **La espera** (0 a 3 puntos): el promedio de segundos que estuvo abierto cada pedido de ayuda (consulta, accidente o
##   decisión de la historia), contra la meta de la dificultad (DifficultyData.wait_goal). Hasta la meta, 3; hasta
##   grade_wait_factors.x veces la meta, 2; hasta grade_wait_factors.y veces, 1; más, 0.
## - **Las vidas** (0 a 3 puntos): ninguna perdida, 3; una, 2; dos, 1; más, 0. La herida con que empieza un amigo en
##   Extremo no cuenta.
## - **La letra:** S desde grade_s_points, A desde grade_a_points, B desde grade_b_points y, con menos, C (balance.tres).
## Lógica pura: la pantalla final la muestra.

const NightState := preload("res://scripts/core/night_state.gd")

## Lo más que da cada parte.
const MAX_POINTS := 3


## Los puntos de la espera: `average` segundos por pedido contra la meta `goal`.
static func wait_points(average: float, goal: float, balance: BalanceData) -> int:
	if average <= goal:
		return MAX_POINTS
	if average <= goal * balance.grade_wait_factors.x:
		return 2
	if average <= goal * balance.grade_wait_factors.y:
		return 1
	return 0


## Los puntos de las vidas: 3 menos las perdidas, nunca menos de 0.
static func life_points(lives_lost: int) -> int:
	return maxi(MAX_POINTS - lives_lost, 0)


## La letra de `points` puntos.
static func letter(points: int, balance: BalanceData) -> String:
	if points >= balance.grade_s_points:
		return "S"
	if points >= balance.grade_a_points:
		return "A"
	if points >= balance.grade_b_points:
		return "B"
	return "C"


## La nota de la noche de `state`.
static func letter_for(state: NightState) -> String:
	var points := wait_points(state.average_wait(), state.wait_goal, state.balance) + life_points(state.lives_lost())
	return letter(points, state.balance)
```

En `scripts/core/ending_text.gd`, después de `const UNLOCKED_KEY := "END_UNLOCKED"`:

```gdscript
## La nota al ganar una noche (Plan 9.9; ui.csv): END_GRADE lleva {grade}; END_WAIT, {seconds} y {goal}; END_LIVES,
## {lives}.
const GRADE_KEY := "END_GRADE"
const WAIT_KEY := "END_WAIT"
const LIVES_KEY := "END_LIVES"
```

y, después de la función `summary()`:

```gdscript


## El título de la nota: "Nota A" (Plan 9.9).
static func grade_title(grade: String, translate: Callable) -> String:
	return _text(translate, GRADE_KEY).format({"grade": grade})


## Lo que dio la nota: cuánto esperaron los amigos por pedido, contra la meta, y las vidas que perdieron.
static func grade_detail(state: NightState, translate: Callable) -> String:
	var wait := _line(translate, WAIT_KEY, {"seconds": roundi(state.average_wait()), "goal": roundi(state.wait_goal)})
	return wait + "\n" + _line(translate, LIVES_KEY, {"lives": state.lives_lost()})
```

En `scenes/ui/end_screen.tscn`, entre el nodo `Title` y el nodo `Body`, agrega:

```
[node name="Grade" type="Label" parent="Center/Box"]
visible = false
layout_mode = 2
theme_override_fonts/font = ExtResource("pixel_font")
theme_override_font_sizes/font_size = 66
horizontal_alignment = 1
```

con una línea en blanco antes y otra después, como los demás nodos. La letra de 66 ya es nítida a 1080p.

En `scripts/ui/end_screen.gd`:

1. Al final del comentario del encabezado, agrega:

```gdscript
## Desde el Plan 9.9, al ganar una noche de la 1 a la 5 muestra su nota (NightGrade): la letra grande y, al final del
## resumen, la espera y las vidas perdidas.
```

2. Después de `const NightState := preload("res://scripts/core/night_state.gd")`, agrega `const NightGrade := preload("res://scripts/core/night_grade.gd")`.
3. Después de `@onready var _title: Label = $Center/Box/Title`, agrega `@onready var _grade: Label = $Center/Box/Grade`.
4. En `show_ending()`, reemplaza:

```gdscript
	var won := ending == NightState.Ending.WON
	if won:
		_title.text = EndingText.won_title(night_number, tr, state.clock_text())
		_body.text = EndingText.summary(night_number, state, new_pages, tr, unlocked)
```

por:

```gdscript
	var won := ending == NightState.Ending.WON
	# La nota, solo al ganar una noche de la 1 a la 5 (Plan 9.9).
	var graded := won and night_number >= 1
	_grade.visible = graded
	if won:
		_title.text = EndingText.won_title(night_number, tr, state.clock_text())
		_body.text = EndingText.summary(night_number, state, new_pages, tr, unlocked)
		if graded:
			_grade.text = EndingText.grade_title(NightGrade.letter_for(state), tr)
			_body.text += "\n\n" + EndingText.grade_detail(state, tr)
```

En `data/text/ui.csv`, después de la línea `END_MENU,Volver al menú,`, agrega (son borradores de Claude que Benja corrige):

```
END_GRADE,Nota {grade},
END_WAIT,Tus amigos esperaron {seconds} s por pedido de ayuda (meta: {goal} s).,
END_LIVES,Vidas perdidas: {lives}.,
```

Reimporta los textos, con el editor de Godot cerrado:

```bash
~/tools/godot-wsl.sh --headless --path "$PWD" --import
```

- [ ] **Paso 5: correr todas las pruebas**

Esperado: **866 pruebas OK** (857 más 9: 4 en `test_night_grade`, 1 en `test_ending_text`, 2 en `test_end_screen` y 2 en `test_balance`).

Si `test_jugando_bien_se_saca_s` falla en alguna noche (el modelo espera más de 1,5 veces la meta), **no cambies la meta: es decisión de Benja**. Anota la noche y la espera medida en "Resultado", deja la prueba con esa noche como excepción explicada y pregúntale a Benja al cerrar.

- [ ] **Paso 6: las capturas**

Crea `test/capture_plan99.gd`:

```gdscript
extends SceneTree
## Capturas del Plan 9.9 (la nota) para revisarlas a ojo, a la resolución que se pida. No es una prueba: corre con
## ventana.
## Uso: timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan99.gd -- /mnt/c/dev/capturas 1920 1080
## Guarda plan99_<ancho>_<nombre>.png:
## - grade: el resumen de la noche 1 ganada a las 04:42, con nota A (19 s por pedido y una vida perdida);
## - victory: la victoria de la noche 5, con nota S (12 s por pedido y ninguna vida perdida).

const DESK := preload("res://scenes/desk/desk.tscn")
const NightState := preload("res://scripts/core/night_state.gd")

var _dir := ""
var _width := 1280


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[0]
	_width = int(args[1])
	DisplayServer.window_set_size(Vector2i(_width, int(args[2])))
	await create_timer(0.4).timeout
	var desk := DESK.instantiate()
	var manager := desk.get_node("RequestManager")
	manager.night_number = 1
	manager.requests_arrive = false
	manager.random_seed = 5
	root.add_child(desk)
	desk.get_node("NightManager").set_process(false)
	var state: NightState = manager.state
	state.videos.received = state.videos.quota
	state.asked = 7
	state.waited = 7 * 19.0
	state.friends[1].hurt(1, 0.0)
	state.elapsed = 330.0
	desk._on_night_ended(NightState.Ending.WON, null)
	await _save("grade", 2.0)
	desk.get_node("Overlay/EndScreen").hide()
	manager.night_number = 5
	state.waited = 7 * 12.0
	state.friends[1].health_lost = 0
	desk._on_night_ended(NightState.Ending.WON, null)
	await _save("victory", 2.0)
	desk.free()
	quit()


func _save(capture_name: String, wait: float) -> void:
	await create_timer(wait, true).timeout
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("plan99_%d_%s.png" % [_width, capture_name])
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
```

Córrelo a 1280×720 y a 1920×1080:

```bash
timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan99.gd -- /mnt/c/dev/capturas 1280 720
timeout 150 ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_plan99.gd -- /mnt/c/dev/capturas 1920 1080
```

Mira las 4 imágenes con Read. Revisa que la letra se vea grande y centrada, que el resumen quepa entero con los botones a la vista, y que nada se corte. Si algo no cabe, baja la letra de la nota a 44 en `end_screen.tscn` y vuelve a capturar.

- [ ] **Paso 7: commit**

```bash
git add scripts/core/night_grade.gd scripts/data/balance_data.gd data/balance.tres scripts/core/ending_text.gd scripts/ui/end_screen.gd scenes/ui/end_screen.tscn data/text/ui.csv test/test_night_grade.gd test/test_ending_text.gd test/test_end_screen.gd test/test_balance.gd test/capture_plan99.gd
git commit -m "La nota de cada noche: S, A, B o C por la espera de los pedidos y las vidas perdidas"
```

Agrega también los `.uid` nuevos que Godot haya creado (`git status` los muestra junto a los `.gd` nuevos).

---

## Tarea 8: los documentos

- [ ] **Paso 1: "Resultado"**

Completa la sección "Resultado" al final de este plan:
- las 2 tablas de `dump_night_lengths.gd` (antes y después de calibrar);
- las calmas elegidas;
- la holgura de Difícil 5;
- las pruebas que fallaron sin estar previstas y qué se hizo con cada una;
- el total de pruebas.

- [ ] **Paso 2: `docs/02_bucle_central.md`**

En §6, la tabla y el texto de las noches:
- Difícil 5 tiene 9 consultas;
- las calmas calibradas de Normal, Difícil y Extremo;
- la noche termina cuando se completa (ola final resuelta, nada abierto, videos recibidos e historia contada, más 3 s), ya no a las 06:00 ni a las 06:30;
- las olas van en cadena y ninguna se salta;
- la lectura de la historia (60 letras/s, 3,5 palabras/s y 1 s);
- la nota, con sus valores.

Busca con `grep -n "06:00\|06:30\|lo más tarde\|se salta\|15 letras" docs/02_bucle_central.md` lo que hay que cambiar.

- [ ] **Paso 3: `docs/04_instrucciones_godot.md`**

Al final, después de la sección Z de Benja, agrega la sección AA:

```markdown

---

## AA. Probar la noche que termina cuando se acaba, y la nota (Plan 9.9)

**Estado: pendiente.** Unos 25 minutos.

1. **El inicio de la noche 1.** Empieza una partida nueva en Normal y salta el tutorial (`Esc` > «Saltar tutorial»). Abre la llamada y lee la intro y el susto sin apurarte. **Dime** si ahora alcanzas a leer todo, o si se hace lento.
2. **El final.** Juega la noche 1 entera. Cuando se resuelve la ola final y se despiden en el vlog, la noche termina unos 3 s después. **Verifica:** la pantalla dice «Llegaste a las HH:MM», con la hora a la que terminó, y ya no queda tiempo muerto al final.
3. **La nota.** En el resumen aparecen la letra grande («Nota A»), cuánto esperaron tus amigos por pedido de ayuda (con la meta) y las vidas perdidas. **Dime** si la nota se siente justa para cómo jugaste.
4. **Más rápido o más lento.** Vuelve a jugar la noche 1 (desde el menú, «Continuar» repite la noche 2; para repetir la 1, pierde una noche a propósito o empieza de nuevo), una vez respondiendo rápido y otra tomándote tu tiempo. **Verifica:** jugando rápido la noche termina antes y la nota sube.
5. **La noche 2 de Normal.** Sus calmas son más largas para que no termine muy temprano. **Dime** si alguna calma se hace larga.

**Si quieres ajustar la nota**, en Godot:
- La meta de espera de cada modo: panel **FileSystem** (abajo a la izquierda) > doble clic en `data/difficulty/normal.tres` (o `hard.tres`, `extreme.tres`) > en el **Inspector** (a la derecha), sección **Nota** > **Wait Goal** (en segundos). Guarda con `Ctrl+S`.
- Cuánto pide cada letra: doble clic en `data/balance.tres` > **Inspector** > sección **Nota**: **Grade Wait Factors** (x: hasta cuántas veces la meta da 2 puntos; y: hasta cuántas da 1) y **Grade S Points**, **Grade A Points** y **Grade B Points** (desde cuántos puntos, de 6, es cada letra).
- **Verifica:** gana una noche y mira si la letra cambió como esperabas.

**Corrige los textos nuevos** en `data/text/ui.csv`: `END_GRADE`, `END_WAIT` y `END_LIVES`.
```

En la lista de secciones pendientes de `docs/00_log.md` (la fila de `docs/04` en la tabla de documentos), agrega AA.

- [ ] **Paso 4: `CLAUDE.md` y el diseño v2**

En `CLAUDE.md`, sección "Entorno técnico":
- reemplaza el párrafo **"El horario de una noche con historia (Plan 9.8)"** por uno del Plan 9.9: `NightData.length()` y `overtime_minutes` ya no existen; la noche termina cuando `RequestManager.night_complete()` lleva `end_pause` s (`NightState.finished`); el director encadena las olas (`request_due(now)`, sin `finale_at`); `StoryRunner.line_seconds()` cuenta palabras; la nota es `NightGrade` (`scripts/core/night_grade.gd`), con `DifficultyData.wait_goal` y el grupo «Nota» de `balance.tres`; las capturas, en `test/capture_plan99.gd`.
- en el párrafo **"Equilibrio"**, explica que el modelo corre cada noche hasta que se completa (`result["end"]`), que `night_length()`, `battery_needed()`, `sanity_loss()` y `free_time_needed()` reciben el largo, y que `test/dump_night_lengths.gd` mide las noches para calibrar las calmas. Actualiza la holgura de Difícil 5.

En la tabla de decisiones de `CLAUDE.md` y en `spook_dial_design.md` (§5, «Un tercer modo, Extremo»), cambia «calmas de 20 a 30 s» por la calma medida.

- [ ] **Paso 5: `resumen.md` y `docs/00_log.md`**

En `resumen.md`, agrega arriba la entrada de la sesión S21o (la que ejecuta este plan), con las 4 categorías de `CLAUDE.md` (regla 4), arrastrando los pendientes vigentes de la entrada S21n.

En `docs/00_log.md`:
- marca S21o como ✅;
- deja como siguiente a **S21m** (la noche 2 de la historia, cuando Benja apruebe su guion);
- en la tabla de planes, marca `docs/33` como ya ejecutado;
- agrega la fila de S21o a "Cambios a la secuencia".

- [ ] **Paso 6: commit**

Pregúntale a Benja antes, porque `docs/04` lleva también su sección Z, que no estaba commiteada.

```bash
git add docs/33_plan_tiempo_y_nota.md docs/02_bucle_central.md docs/04_instrucciones_godot.md CLAUDE.md spook_dial_design.md resumen.md docs/00_log.md
git commit -m "Documentos del Plan 9.9: la noche que termina cuando se acaba y la nota"
```

- [ ] **Paso 7: al cerrar, dile a Benja**
- qué probar (`docs/04`, AA);
- los textos nuevos que corregir (`END_GRADE`, `END_WAIT` y `END_LIVES`);
- las calmas que se alargaron;
- cualquier pregunta abierta, como una noche donde jugar bien no da S.

---

## Fuera de este plan

- **Guardar la mejor nota** de cada noche y mostrarla en el resumen o en la victoria final: Benja eligió que por ahora no se guarde (14 de noviembre).
- **El tutorial** no cambia su ritmo de lectura (`TUTORIAL_CHARS_PER_SECOND`, `TUTORIAL_LINE_PAUSE`): no se reportó.
- **Las noches 2 a 5 con historia** (S21m y después): ya no necesitan `overtime_minutes`. La noche espera sola a que termine la historia.

---

## Resultado

*Se completa al ejecutar el plan (Tarea 8, Paso 1).*
