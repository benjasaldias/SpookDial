# Plan de la primera versión (v1)

Hoja de ruta para construir la v1 (`docs/05` §1) antes del 10 de diciembre. Divide el trabajo en **9 planes**. Cada uno deja algo que funciona y se puede probar por sí solo.

- El **Plan 1** está escrito paso a paso en `docs/07_plan_escena_arte.md` (ejecutado).
- El **Plan 2** está escrito paso a paso en `docs/08_plan_datos_textos.md` (ejecutado).
- El **Plan 3** está escrito paso a paso en `docs/10_plan_solicitudes_chat.md` (ejecutado).
- El **Plan 4** está escrito paso a paso en `docs/11_plan_cuaderno.md` (ejecutado).
- El **Plan 5** está escrito paso a paso en `docs/12_plan_consecuencias_noche.md` (ejecutado).
- El **Plan 6** está escrito paso a paso en `docs/13_plan_mantenimiento.md` (por ejecutar).
- Cada plan siguiente se escribe en detalle al comenzar su sesión, con el mismo formato (skill `superpowers:writing-plans`).

---

## 1. Arquitectura común

```text
res://
  scenes/desk/          escena principal (escritorio) y sus piezas
  scenes/ui/            chat, entradas del PC, cuaderno, menús
  scripts/core/         lógica pura, sin nodos: reglas, estática, medidores, director
  scripts/data/         clases Resource (entidades, noches, amigos)
  scripts/desk/         componentes de la escena
  scripts/ui/           componentes de interfaz
  scripts/autoload/     GameState, EventBus, AudioManager, SaveManager
  data/                 recursos .tres y data/text/*.csv
  shaders/
  test/                 run_tests.gd, test_case.gd y test_*.gd
  art/sprites/          arte de Benja (.aseprite), importado con Aseprite Wizard
```

- **Pruebas:** un ejecutor mínimo propio (`test/run_tests.gd`), sin addons, que se ejecuta sin interfaz:

  ```bash
  ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd
  ```

  Se eligió en vez de GdUnit4 para no depender de la compatibilidad de un addon con Godot 4.7.
- **Se prueba la lógica pura:** reglas, estática, medidores y director. Las escenas se prueban instanciándolas en el mismo ejecutor, y lo visual se verifica comparando capturas con la maqueta.
- **Commits:** uno por tarea, con mensajes en español.

---

## 2. Los 9 planes

| Plan | Qué construye | Depende de | Está listo cuando… | Semana |
| --- | --- | --- | --- | --- |
| **1. Escena y arte** | Configuración de pantalla, importación del arte, escena del escritorio con todo en su lugar, diales que responden a un valor, entradas del PC con estados, panel del chat (provisional), resaltado y clic por píxel, parallax de la pared | Ruta de Aseprite corregida | Al ejecutar, la escena coincide con la maqueta; los diales y las entradas responden; el resaltado funciona | 1 |
| **2. Datos y textos** | Clases `TraitData`, `ObservationData`, `ActionData`, `RuleData`, `EntityData`, `FriendData` y `NightData`; evaluador de reglas; traducciones CSV con textos `[PROTO]`; El Trauco de ejemplo como `.tres` | — | Las pruebas del evaluador pasan; la entidad se edita en el Inspector | 1 |
| **3. Solicitudes y chat** | Generador de solicitudes, armado de mensajes con características marcadas, estática, preguntas, panel de chat (pestañas, mensajes, escritura progresiva), identificación por clic con espera, temporizadores | 1, 2 | Llegan solicitudes; se identifican clickeando; se pregunta | 2 |
| **4. Cuaderno** | Índice, páginas generadas desde `EntityData`, memoria de página por amigo y botones de respuesta desde la página abierta | 2, 3 | Se responde una solicitud desde el cuaderno | 2 |
| **5. Consecuencias, medidores y noche** | Resolución, vida y aturdimiento, Trust, Sanity y Connection con sus efectos graduales, diales conectados, reloj en el celular, cuota con envíos programados (por ahora se reciben solos), victoria, derrota y pantalla explicativa | 3, 4 | Una noche completa se gana o se pierde | 3 |
| **6. Mantenimiento** | Señal por amigo con interferencias y desconexión, Audio Sync en el mixer visto desde arriba, recepción de videos (empezar a descargar en 15 s y terminar en 20 s, manteniendo presionado en el chat) y scroll del celular. El mixer y el celular, provisionales hasta el arte | 5 | Las tres tareas de mantenimiento funcionan en la noche | 3 |
| **7. Screamers y director** | Director de ritmo (con reglas y pruebas), tipos de screamer con sus reglas de justicia y alucinaciones auditivas | 5, 6 | Una noche con ritmo controlado y screamers justos | 4 |
| **8. Noches, menú, guardado y opciones** | 5 `NightData`, menú principal, guardado al inicio de cada noche, resumen entre noches, victoria final y opciones | 7 | El juego se puede terminar | 4 |
| **9. Sonido, pulido y versión** | Buses de audio, efectos, ambiente, pulido y exportación a Windows | 8 | Versión candidata el 5 de diciembre | 6 |

La semana 5 queda para corregir y probar con personas (`docs/05` §2).

---

## 3. Estado del arte (revisado el 26 de octubre)

Revisé tus archivos de `art/sprites/` comparando sus píxeles con las capas del maestro: las posiciones son exactas. Actualizado el 26 de octubre (tarde) con `background_sprite` y `exterior_sprite`, el renombre de `arrow_sprite` y el maestro movido a `art/_layout/`.

| Archivo | Tamaño | Animaciones (tags) | Posición en la escena | Estado |
| --- | --- | --- | --- | --- |
| `curtains_sprite` | 374×352 | — | (219, 92) | ✅ |
| `window_sprite` | 265×311 | — | (266, 114) | ✅ Trae el exterior pintado, que sirve de respaldo bajo `exterior_sprite` |
| `background_sprite` | 1280×720 | — | (0, 0) | ✅ Pared y sombreado (sin termómetro) |
| `exterior_sprite` | 251×297 | — | (273, 121), recortado al vidrio | ✅ Opcional: 8 px más grande por lado para un parallax más amplio |
| `enemy_sprite` | 177×237 | — | (300, 172) | ✅ (parpadeo de ojos, más adelante) |
| `glasspane_sprite` | 251×297 | — | (273, 121) | ✅ |
| `dial_sprite` | 112×113 | — | (840, 89), (840, 219), (840, 348) | ⚠️ Sirve para los 3 diales, pero sigue con cara de reloj y sin ícono |
| `arrow_sprite` | 15×48 | `yellow`, `red`, `green` | Eje de giro: (896, 145), (896, 274), (896, 403) | ✅ El eje está en el píxel (7, 43) del archivo |
| `desk_sprite` | 1280×215 | — | (0, 505) | ✅ Ya cubre hasta la última fila (error corregido) |
| `cables_sprite` | 659×184 | — | (241, 504) | ✅ |
| `mixer_sprite` | 210×82 | — | (130, 565) | ✅ Puede quedar de una sola pieza: Audio Sync se juega en una vista del mixer desde arriba, aparte (Plan 6) |
| `phone_sprite` | 86×55 | — | (357, 618) | ⚠️ Todavía tiene "00:00" dibujado (la hora la escribe Godot, Plan 5) |
| `pc_sprite` | 322×229 | — (capas `PC`, `Entry1` a `Entry3`) | (479, 433) | ✅ Las capas `Entry` se excluyen al importar |
| `entry_sprite` | 243×26 | `idle`, `warning` (2 frames) | (518, 454), (518, 494), (518, 534) | ✅ |
| `microphone_sprite` | 85×98 | — | (830, 571) | ✅ |
| `notebook_sprite` | 146×78 | — | (1017, 562) | ✅ |
| `screen_sprite` | 449×696 | — | (11, 11) | ✅ Panel del chat |
| `art/_layout/scene_layout` (maestro y PNG) | 1280×720 | 2 frames | — | ✅ Godot lo ignora; es la maqueta de referencia |

### Arte que falta, por plan

| Plan | Arte | Prioridad |
| --- | --- | --- |
| 1 | Nada obligatorio. Opcional: `exterior_sprite` y `background_sprite` con 8 px extra por lado, para un parallax más amplio. | Baja |
| 3 | Barras de señal (5 niveles) para las entradas. Opcional: el chat ya tiene un estilo de terminal hecho en Godot (sesión 12), que el arte de burbujas, botones y pestañas puede reemplazar. | Alta (las barras) |
| 4 | Interfaz del cuaderno: página (449×696, como `screen_sprite`; va a la derecha), pestañas del índice y bocetos de las entidades (unos 96×96). | Alta |
| 5 | `phone_sprite` sin la hora y una tira de dígitos LCD "0123456789:". Diales rediseñados (manómetro con ícono). Pantallas de victoria y derrota. Opcional: marcas de vida para las entradas del PC. | Alta |
| 6 | Mixer visto desde arriba (decisión de Benja, sesión 14): el cuerpo, los dos VU-metros azules (el de la izquierda para Matías y el de la derecha para el amigo), la perilla de un fader, los LED y una fila de luces para el ritmo; en 440×430, o en 220×215 para mostrarlo a ×2. Celular ampliado con unas 12 publicaciones o con la animación del scroll; en 260×520, o en 130×260 a ×2. Mientras tanto, el Plan 6 los dibuja provisionales en Godot. | Alta |
| 7 | Luces (`pcLightOver`, `pcLightUnder` y `pcDesklight`) como archivos aparte. Arte de screamers. | Media |
| 8 | Menú principal y logo. | Media |

### Orden en `art/sprites` (hecho el 26 de octubre, con tu visto bueno)

- El maestro y la maqueta PNG quedaron en `art/_layout/` (`scene_layout.aseprite` y `scene_layout.png`).
- Se borraron los `.import` que sobraban.
- `arrrow_sprite` pasó a llamarse `arrow_sprite`.
