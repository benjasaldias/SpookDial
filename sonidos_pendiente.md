# Sonidos

Todos los sonidos del juego, dónde suena cada uno y qué falta. Actualizado el 10 de noviembre de 2026 (sesión S21d).

## Cómo se hacen

- **Ya no son de relleno.** Desde el 10 de noviembre los genera `tools/make_sounds.py` para que suenen reales y vayan con el terror del juego. Reemplazó a `make_placeholder_sounds.py`.
- **Casi todo se sintetiza:** el viento, la estática, los golpes en el vidrio, la tela, la vibración del celular, el agua, los pasos, los pájaros y los grillos.
- **Lo que la síntesis no logra** sale de 5 grabaciones de dominio público o CC0 de Wikimedia Commons: el gallo, la oveja, el llanto de guagua y dos de gruñidos. Están en `audio/source/`, con su ficha y sus créditos en `audio/source/creditos.md`.
- **Ningún sonido dice palabras** (decisión de Benja, 10 de noviembre).
- **El balance se fija en el script,** no en el volumen de cada nodo: cada sonido tiene su sonoridad (en LUFS) y ningún pico pasa de -1 dBFS.
- **Los audios de los amigos pasan por el micrófono de un celular**, y las voces y la estática, por un parlante chico.

**Para volver a generarlos** (desde la carpeta del proyecto):

```bash
/usr/bin/python3 tools/make_sounds.py              # todos
/usr/bin/python3 tools/make_sounds.py scare_slam   # solo los que se nombran
```

Usa `/usr/bin/python3`, que tiene numpy y scipy, y necesita `ffmpeg`.

**Para cambiar uno:**

- **Si lo pide Benja:** dile a Claude cómo debería sonar, y Claude ajusta su receta en el script.
- **Si Benja tiene su propio archivo:**
  1. Cópialo a `audio/sfx/` (o a `audio/clues/`, si es un audio de un amigo) con **el mismo nombre**.
  2. Vuelve a abrir Godot.
  3. **No vuelvas a correr `make_sounds.py`**, porque escribiría encima del tuyo.
  4. Si el tuyo dura distinto, avísale a Claude: `test/test_sounds.gd` anota cuántos segundos dura cada uno.

El ambiente va en el canal `Ambience` y todo lo demás en `Effects` (opciones, diseño §19). El ambiente y la respiración de la criatura se repiten en bucle: su importación lo dice (`edit/loop_mode`) y la prueba lo revisa.

---

## Los audios que mandan los amigos (`audio/clues/`)

Duran 3 s, con el lugar de fondo. **Son parte del juego:** lo que se oye cambia la acción correcta, así que hay que distinguirlos de oído. Los de una misma entidad comparten el fondo y el volumen; solo cambia lo que hay que distinguir.

| Archivo | Se oye | Fondo |
| --- | --- | --- |
| `tue_tue_cries_one.wav` | Un grito de dos notas, áspero y lúgubre, a la distancia | El patio de la cabaña: grillos y brisa |
| `tue_tue_cries_three.wav` | El mismo grito, tres veces seguidas | Ídem |
| `tue_tue_cries_none.wav` | Ningún grito | Ídem |
| `calchona_bleat_tone_weeping.wav` | Dos balidos reales, más graves y temblando, como si llorara | El campo: viento en el pasto |
| `calchona_bleat_tone_snorting.wav` | Tres bufidos fuertes y la pata que golpea la tierra | Ídem |
| `cuero_whistle_yes.wav` | Un silbido de dos notas que suben, como alguien que llama del otro lado del agua | El lago: el agua en la orilla |
| `cuero_whistle_no.wav` | Ningún silbido | Ídem |
| `viuda_heels_slow.wav` | 4 pasos de taco sobre piedra | Un camino junto a un estero |
| `viuda_heels_fast.wav` | 10 pasos de taco, rápidos | Ídem |
| `trauco_ground_muddy.wav` | 4 pasos que se hunden en el barro y chapotean al salir | El bosque de noche |
| `trauco_ground_dry.wav` | 4 pasos que crujen en tierra seca y hojas | Ídem |
| `basilisco_crows_once.wav` | Un canto de gallo real, apagado, como bajo el piso | Adentro de una casa: un zumbido y un reloj |
| `basilisco_crows_twice.wav` | El mismo canto dos veces, con un silencio claro entre los dos | Ídem |
| `imbunche_baby_cry_yes.wav` | Gruñidos roncos y, entre ellos, el llanto de una guagua, lejos | La cueva: retumbo, viento y gotas |
| `imbunche_baby_cry_no.wav` | Solo gruñidos | Ídem |

**El Imbunche ya no dice "Matías"** (decisión de Benja, 10 de noviembre): la observación pasó de `called_name` a `baby_cry` ("¿Se oye un llanto?"), con sus textos, su regla y una frase nueva en su lore. Son borradores para corregir.

## Las voces de los amigos (`audio/sfx/`)

Suenan mientras el amigo escribe, como en Undertale. Desde el 10 de noviembre cada letra es **una sílaba murmurada ("mə") que llega por un micrófono barato**, ya no un pitido de consola. El chat les cambia la altura con cada letra. Tienen que durar muy poco, porque se repiten muchas veces por segundo.

| Archivo | Quién | Cómo suena | Dura |
| --- | --- | --- | --- |
| `voice_leon.wav` | León | Tono medio, vocal abierta | 0,05 s |
| `voice_gonzalo.wav` | Gonzalo | Grave y redondo | 0,066 s |
| `voice_agustin.wav` | Agustín | Agudo y nasal | 0,034 s |

Sin cambiar los archivos, se ajustan en `data/friends/*.tres`, en el Inspector, grupo **Voice**: `Voice Pitch`, `Voice Spread` y `Voice Every`. Su volumen es `Volume Db` del nodo `Voice` en `scenes/ui/chat_panel.tscn` (−8).

## La criatura en la ventana

| Archivo | Dura | Cómo suena |
| --- | --- | --- |
| `scare_creature_breathing.wav` | 8 s, en bucle | Tres respiros pesados al otro lado del vidrio, con un gruñido ronco al exhalar |
| `scare_creature_knocks.wav` | 7 s | Golpes en el vidrio en tres tandas, cada vez más fuertes, en los mismos segundos de siempre (0,6, 1,1, 2,9, 3,35, 3,8, 5,4, 5,8, 6,2 y 6,5). Entre la segunda y la tercera tanda, las garras raspan el vidrio. |

## Screamers del escritorio

| Archivo | Dura | Cómo suena |
| --- | --- | --- |
| `scare_curtains.wav` | 1,2 s | La tela que roza y las argollas que corren por el fierro |
| `scare_window.wav` | 1,5 s | Una mano que golpea el vidrio y un chillido (un gruñido acelerado) |
| `scare_phone.wav` | 1,2 s | El celular que vibra tres veces sobre la madera |
| `scare_lights.wav` | 1,5 s | El zumbido de la corriente (50 Hz, como en Chile) que se corta y vuelve con chasquidos |
| `scare_slam.wav` | 0,5 s | El aire de las hojas, el golpe de la tapa y el escritorio que retumba |
| `scare_ink.wav` | 0,6 s | Algo húmedo que se aplasta y unas gotas que saltan |

## Ambiente y alucinaciones

| Archivo | Dura | Cómo suena |
| --- | --- | --- |
| `ambient_room.wav` | 24 s, en bucle, estéreo | El viento afuera, con ráfagas y un silbido por las rendijas, un zumbido eléctrico muy bajo, el ventilador del PC y la casa que cruje dos veces. Antes duraba 8 s y se notaba que se repetía. |
| `hallucination_knock.wav` | 1 s | Tres golpes de nudillos en la ventana |
| `hallucination_steps.wav` | 2 s | Pasos lentos sobre el piso de madera, en otra pieza, con una tabla que cruje |
| `hallucination_whisper.wav` | 2 s | Un susurro pegado al oído, sin palabras |
| `hallucination_scratch.wav` | 1,5 s | Uñas que raspan la madera, tres veces |

Las alucinaciones también reusan `interference_static.wav` y `scare_phone.wav`.

## Audio Sync e interferencias

| Archivo | Dura | Cómo suena |
| --- | --- | --- |
| `sync_kick.wav` | 0,22 s | Un bombo, con el golpe de la maza |
| `sync_tick.wav` | 0,06 s | Un platillo cerrado |
| `sync_clap.wav` | 0,25 s | El aplauso del amigo, que llega por su celular |
| `sync_tap.wav` | 0,12 s | Los nudillos de Matías contra el escritorio de madera |
| `sync_success.wav` | 0,4 s | Cuatro notas que suben, con el timbre suave de un aparato viejo |
| `sync_fail.wav` | 0,44 s | Dos notas graves que bajan, ásperas |
| `interference_static.wav` | 3 s | Estática de radio con chasquidos, cortes y un silbido que se mueve |

---

## Faltan (todavía no existen)

Son del Plan 10 (sonido y pulido):

- Cuando llega un video y cuando se recibe.
- Los clics del menú, de los botones y del chat.
- La música o el ambiente del menú principal.
- La pantalla final: ganar una noche, perderla y la victoria.
- Los pasos de los amigos, si los quieres.
