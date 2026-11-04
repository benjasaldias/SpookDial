# Sonidos pendientes

Todos los sonidos del juego son **provisionales**: los generó Claude con `tools/make_placeholder_sounds.py` para que el juego suene mientras tanto. Benja pone los reales.

**Cómo reemplazar uno:** copia tu archivo a `audio/sfx/` con **el mismo nombre** del que reemplaza (`.wav`, mono o estéreo) y vuelve a abrir el proyecto en Godot. No hay que tocar nada más: la escena lo carga por nombre. Si el sonido nuevo dura distinto, avísale a Claude, porque `test/test_placeholder_sounds.gd` anota cuántos segundos dura cada uno. **No corras `make_placeholder_sounds.py` después de poner los tuyos:** vuelve a escribir los provisionales encima.

El sonido ambiente va en el canal `Ambience`, y todos los demás, en `Effects` (opciones del jugador, diseño §19).

---

## Primero: la criatura en la ventana (4 de noviembre)

Reemplazan al grito del jumpscare. La criatura se asoma por la ventana cuando el chat o el mixer la tapan, y se ve al cerrarlos.

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `scare_creature_breathing.wav` | 8 s | Desde que la criatura llega (bajito, detrás del panel) y más fuerte cuando se ve. Se corta a los 4 s de verse. | Respiración pesada y ronca, de algo grande al otro lado del vidrio. |
| `scare_creature_knocks.wav` | 7 s | Al llegar la criatura, mientras el panel está abierto. | Golpeteos en el vidrio, en tandas que se vuelven más fuertes. Los golpes caen en 0,6 s, 1,1 s, 2,9 s, 3,35 s, 3,8 s, 5,4 s, 5,8 s, 6,2 s y 6,5 s del archivo. |

## Screamers del escritorio

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `scare_curtains.wav` | 1,2 s | Las cortinas se mecen | Roce de tela |
| `scare_window.wav` | 1,5 s | La figura aparece un instante en la ventana (el screamer ambiental) | Un golpe grave y un chillido |
| `scare_phone.wav` | 1,2 s | El celular vibra solo | Tres zumbidos |
| `scare_lights.wav` | 1,5 s | Las luces parpadean | Zumbido eléctrico que se corta |
| `scare_slam.wav` | 0,5 s | El cuaderno se cierra de golpe | Un golpe seco |
| `scare_ink.wav` | 0,6 s | La mancha de tinta cae en la página | Algo húmedo que se aplasta |

## Ambiente y alucinaciones

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `ambient_room.wav` | 8 s | Siempre, en bucle | Viento grave y un zumbido eléctrico. Tiene que empalmar al repetirse. |
| `hallucination_knock.wav` | 1 s | Con Sanity bajo: golpes que no vienen de nada | Tres golpes en la ventana |
| `hallucination_steps.wav` | 2 s | Ídem | Pasos lentos sobre madera |
| `hallucination_whisper.wav` | 2 s | Ídem | Un susurro sin palabras |
| `hallucination_scratch.wav` | 1,5 s | Ídem | Rasguños en la pared |

Además, las alucinaciones reusan `interference_static.wav` y `scare_phone.wav`.

## Audio Sync, interferencias

| Archivo | Dura | Cuándo suena | Cómo tendría que sonar |
| --- | --- | --- | --- |
| `sync_kick.wav` | 0,22 s | La base, en cada golpe fuerte | Un bombo |
| `sync_tick.wav` | 0,06 s | La base, en los golpes intermedios | Un platillo cerrado |
| `sync_clap.wav` | 0,25 s | Los aplausos del amigo | Un aplauso |
| `sync_tap.wav` | 0,12 s | El golpe de Matías | Un golpe de madera, distinto del aplauso |
| `sync_success.wav` | 0,4 s | Se acierta una ronda | Cuatro notas que suben |
| `sync_fail.wav` | 0,44 s | Se falla una ronda | Dos notas que bajan |
| `interference_static.wav` | 3 s | Avisa una interferencia | Estática con chasquidos |

---

## Faltan (todavía no existen, ni como relleno)

Son del Plan 9 (sonido y pulido):

- Cuando llega un video y cuando se recibe.
- Los clics del menú, de los botones y del chat.
- La música o el ambiente del menú principal.
- La pantalla final: ganar una noche, perderla y la victoria.
- Los pasos o la voz de los amigos, si los quieres.
