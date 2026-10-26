# Posiciones de los objetos en la escena

Coordenadas en píxeles del lienzo de 1280×720, medidas desde la esquina superior izquierda.

**Verificadas por Claude el 26 de octubre de 2026**, comparando los píxeles de cada archivo de `art/sprites/` con su capa en el maestro. Si recortas o cambias el tamaño de un archivo, actualiza su fila.

| Archivo | Posición (x, y) | Tamaño | Plano | Notas |
| --- | --- | --- | --- | --- |
| `background_sprite` | 0, 0 | 1280×720 | Pared | Pared y sombreado (sin termómetro, por decisión de Benja) |
| `window_sprite` | 266, 114 | 265×311 | Pared | Todavía trae el exterior pintado; sirve de respaldo bajo el exterior que se mueve |
| `exterior_sprite` | 273, 121 | 251×297 | Exterior (dentro de un recorte del tamaño del vidrio) | Calza al 100 % con el hueco del vidrio |
| `enemy_sprite` | 300, 172 | 177×237 | Pared | |
| `glasspane_sprite` | 273, 121 | 251×297 | Pared | |
| `curtains_sprite` | 219, 92 | 374×352 | Pared | |
| `dial_sprite` (×3) | 840, 89 · 840, 219 · 840, 348 | 112×113 | Pared | Arriba Connection, al medio Sanity, abajo Trust |
| `arrow_sprite` (×3) | Eje en 896, 145 · 896, 274 · 896, 403 | 15×48 | Pared | Eje de giro en el píxel (7, 43) del archivo; dentro del dial queda en (56, 56) |
| `desk_sprite` | 0, 505 | 1280×215 | Escritorio | |
| `notebook_sprite` | 1017, 562 | 146×78 | Escritorio | Clickeable |
| `microphone_sprite` | 830, 571 | 85×98 | Escritorio | |
| `phone_sprite` | 357, 618 | 86×55 | Escritorio | Clickeable |
| `mixer_sprite` | 130, 565 | 210×82 | Escritorio | Clickeable |
| `cables_sprite` | 241, 504 | 659×184 | Escritorio | |
| `pc_sprite` | 479, 433 | 322×229 | Escritorio | Pantalla: x 510–770, y 438–568 |
| `entry_sprite` (×3) | 518, 454 · 518, 494 · 518, 534 | 243×26 | Escritorio | León, Gonzalo y Agustín |
| `screen_sprite` | 11, 11 | 449×696 | Interfaz | Panel del chat |

## Maqueta

El maestro y su PNG están en `art/_layout/` (`scene_layout.aseprite` y `scene_layout.png`). Godot los ignora; sirven de referencia y para comparar capturas.

## Mejoras opcionales

- `exterior_sprite` 8 px más grande por lado (267×313), para que el exterior pueda moverse más sin mostrar bordes. Iría en (−8, −8) dentro de su recorte.
- `background_sprite` con 8 px extra por lado (1296×736), en (−8, −8). Hoy el borde lo tapa el color de fondo.
