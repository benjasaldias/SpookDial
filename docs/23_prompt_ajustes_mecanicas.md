# Prompt: ajustes de mecánicas y la Mano

Sesión de **diseño corto, plan y ejecución en la misma sesión**. Modelo sugerido: **Opus 5.5 · xhigh**. Benja la abre escribiendo: `Lee docs/23_prompt_ajustes_mecanicas.md y sigue sus instrucciones.`

---

## Tu tarea

El 10-nov, Claude hizo un diagnóstico de por qué el juego se siente plano (`docs/22_diagnostico_mecanicas.md`). El 11-nov, Benja eligió qué arreglar y sumó dos cambios propios: **la Mano**, un enemigo nuevo que se espanta con la linterna del celular, y **Trust sin recuperación**. Tienes que cerrar lo poco que queda abierto con Benja, escribir el plan e implementarlo con pruebas.

Antes de preguntar nada, lee:

- `CLAUDE.md` completo, `docs/00_log.md` y la entrada más reciente de `resumen.md`;
- `docs/22_diagnostico_mecanicas.md` completo, sobre todo §2.1, §2.3, §2.4 y la sección A;
- `spook_dial_design.md`: §5, §8.1 a §8.4, §10 y §11;
- `docs/02_bucle_central.md`, §2, §3 y §6 (los valores);
- el código que vas a tocar:
  - `scripts/core/request_generator.gd`, `friend_request.gd`, `message_builder.gd`, `pacing_director.gd`, `night_state.gd`, `video_schedule.gd` y `notebook_page.gd`;
  - `scripts/desk/request_manager.gd`, `screamer_manager.gd` y `desk.gd`;
  - `scripts/ui/phone_view.gd`, `stat_bars.gd` y `chat_entry.gd`;
  - `scripts/data/balance_data.gd`, `night_data.gd` y la clase de las características (`TraitData`);
  - `scripts/core/content_validator.gd`;
- los datos: `data/balance.tres`, `data/nights/*.tres`, `data/entities/*.tres` y `data/text/*.csv`.

## Skills

| Skill | Para qué |
| --- | --- |
| `superpowers:brainstorming` | Las preguntas de la sección "Lo que falta decidir": una a la vez, con opciones y una recomendada. Sé breve, porque lo grueso ya está decidido. |
| `superpowers:writing-plans` | Escribir `docs/24_plan_ajustes_mecanicas.md` (Plan 9.1), con tareas chicas y conteos de pruebas. |
| `superpowers:test-driven-development` | Cada cambio de lógica pura (`scripts/core/`) entra con su prueba primero. |
| `superpowers:executing-plans` | Ejecutar el plan en la misma sesión, tarea por tarea, con un commit por tarea (autorizado por Benja). |
| `superpowers:verification-before-completion` | No dar nada por terminado sin correr las pruebas, revisar las capturas y abrir el juego sin errores. |
| `godot:godot-gdscript` y `godot:godot-resources` | Los campos nuevos de `NightData`, `BalanceData` y `TraitData`, con tipado estático y editables en el Inspector (regla 7). |
| `godot:godot-animation` | La animación de la Mano (3 cuadros, pausada y con sacudidas). |
| `godot:godot-gdscript-headless-testing` | Correr `test/run_tests.gd` sin abrir el editor. |
| `disciplines:level-design` | La curva de tensión y calma de las olas, y el final fuerte. |
| `disciplines:game-feel` | Las sacudidas de la Mano, el flash y cómo se retira. |
| `disciplines:audio-design` | El sonido del flash con `tools/make_sounds.py`. La Mano no suena al acercarse. |
| `disciplines:game-ui-ux` | El aviso de que los videos no alcanzan y la batería que hay que guardar. |

Si el plan no alcanza a ejecutarse completo, la sesión siguiente lo continúa en Sonnet 5.5 · high. En ese caso, escríbelo con código completo, como los planes anteriores (ver la memoria "Planes desde commits").

## Lo que Benja ya decidió (11-nov)

No se vuelve a discutir. Los valores son de partida, salvo donde se indica.

### 1. El mensaje inicial ya no dice siempre el lugar

- Reemplaza al lugar fijo del mensaje inicial (decisión del 3-nov).
- El amigo saluda y dice **qué le pasa**: que está perdido, que algo lo persigue o que creyó escuchar algo.
- Dice **el lugar solo a veces**, con una probabilidad considerable. Propón el valor (por ejemplo, 50 %) y si cambia por noche.
- Reconocer rápido a la criatura es parte de la habilidad del jugador, así que no importa que a veces el lugar la delate.
- Las frases de lo que le pasa son textos nuevos en `messages.csv`, que tú escribes como borrador.

### 2. Los señuelos cuestan 1 s, y las características se dicen con otras palabras

- Clickear un señuelo le quita **1 s** al temporizador (antes no costaba nada; decisión del 26-oct).
- **Cada característica tiene varias formas de decirse**, con sinónimos y paráfrasis. Por ejemplo, "neblina helada" también puede ser "una niebla que te congela los huesos", y "hombrecito", "un enano" o "alguien chiquitito, como un niño viejo". Así hay que identificar de verdad.
  - Son 18 características: escribe de 2 a 4 variantes para cada una.
  - La pista del mensaje inicial también usa las variantes.
- **El cuaderno sigue mostrando un nombre fijo por característica.** Hoy ese nombre es la frase entre asteriscos de su texto (`docs/02` §9). Con las variantes ya no puede serlo, así que hace falta un nombre aparte.
- El clic sigue marcando la característica, aunque la frase sea otra.
- El validador tiene que exigir exactamente una frase entre asteriscos en cada variante.

### 3. Olas de verdad y un final fuerte

- **Las solicitudes de una ola llegan juntas**, con pocos segundos de diferencia (por ejemplo, de 3 a 8 s).
- **Después de cada ola viene una calma de verdad** (por ejemplo, de 40 a 60 s).
- **Las interferencias caen en las olas y los videos, en las calmas.** Decide dónde van los accidentes y los screamers.
- **La última hora (05:00 a 06:00) es el clímax:** la ola más grande, con la criatura.
- **El primer minuto es de silencio.**
- Ajusta la decisión del 2-nov (olas con respiro). Cuida que nunca empiece una solicitud que no alcanza a terminar antes de las 06:00, y que los amigos heridos sigan atrasando las solicitudes.
- Revisa `wave_size` contra `max_simultaneous`: en las noches 4 y 5, la ola es de 4 y el máximo de 3.

### 4. La cuota no sube

- La cuota sigue igual a los envíos programados (decisión del 26-oct). **No la cambies.**

### 5. Aviso cuando los videos ya no alcanzan

- Cuando los videos recibidos, más los que faltan llegar y los que están en descarga, ya no alcanzan la cuota, el juego avisa que **alguien tiene que arriesgarse**: la acción de mayor riesgo da un video extra.
- Propón dónde va el aviso: en el PC (por ejemplo, "Videos: 1 de 3" en rojo) y como aviso del juego en el chat.
- Avisa una sola vez por cada video que se pierde. El aviso desaparece si la cuota vuelve a alcanzar.

### 6. La criatura se queda un tiempo al azar

- Reemplaza a los 25 s fijos (decisión del 7-nov). Propón un rango, por ejemplo de 15 a 40 s.
- Revisa que el aviso de la noche 0 que enseña las cortinas siga teniendo sentido.

### 7. La Mano (enemigo nuevo)

Es idea de Benja. El celular solo sirve para subir Sanity, así que la batería siempre se gasta en eso: la Mano le da un segundo uso, y el jugador tiene que guardar batería.

- **El arte:** `art/sprites/hand_sprite.aseprite` (nuevo, todavía sin commit).
  - Mide 319×81, con 3 cuadros, 1 capa y sin tags.
  - Es un brazo negro y peludo, con las garras hacia la izquierda.
  - En la maqueta (`art/_layout/scene_layout.aseprite`, capa `Hand`, cuadro 2), la Mano llega desde el borde derecho y agarra el dial de arriba. Recortada, queda en (864, 105), de 249×63.
  - Los diales están en (840, 89), (840, 219) y (840, 348) (`art/positions.md`). Agrega la fila de `hand_sprite` a ese archivo.
- **Es el segundo enemigo del cuarto**, después de la criatura de la ventana.
- **Cómo se acerca:** asoma por el costado derecho de la pantalla de a poco, **sin hacer ningún sonido**, hacia un dial al azar (Connection, Sanity o Trust).
- **Qué hace:** cuando agarra el dial, lo baja rápido hasta un mínimo, **pero nunca hasta 0**.
- **Cómo se espanta:** con **el flash del celular**, que la hace desaparecer al instante. Cada flash gasta un porcentaje de la batería.
- **La animación:** alterna entre los 3 cuadros de forma pausada, y se sacude en cada movimiento, como algunas animaciones de Undertale que simulan un movimiento forzado, lento y a tirones.
  - Avanza a saltos y sigue con posiciones enteras (regla 10).
  - Por ejemplo: cada cuadro dura de 0,5 a 0,7 s, y al cambiar de cuadro tiembla 1 o 2 px durante 0,1 s y avanza unos píxeles.
- **Los valores los regulas tú,** sobre todo el costo del flash. Benja sugirió "como 5 %". Claude recomienda empezar con **10 %**: 5 % es casi 2 s de scroll (unos 8 de Sanity), muy poco para que guardar batería sea una decisión. También regulas cuántas veces llega por noche (por ejemplo, 0, 1, 1, 2 y 3), cuánto tarda en llegar al dial, a qué velocidad lo baja y cuál es el mínimo.
- **Toda noche tiene que ser ganable,** y es requisito de Benja. Hay que demostrarlo con una prueba de equilibrio (por ejemplo, en `test/test_balance.gd`): para cada noche, la batería de los flashes, más la que hace falta para reponer Sanity jugando bien, no pasa de 100 %. "Jugar bien" incluye cerrar las cortinas mientras está la criatura, con el rango nuevo del punto 6.

### 8. Trust no sube durante la noche

- Trust ya no se recupera durante la noche: se acaban el +1 cada 8 s y la espera de 20 s sin errores. Vuelve a 100 al empezar cada noche.
- Benja quiere una **segunda forma de que baje**, y Claude debe proponerla (ver la pregunta 1).
- Con Trust sin recuperación, reequilibra los castigos (`wrong_trust`, `no_answer_trust`, `slow_answer_trust` y la segunda forma) para que Trust amenace de verdad sin volver imposible una noche. Inclúyelo en la prueba de equilibrio del punto 7.
- Actualiza `TUTORIAL_DIALS` y `docs/04` (sección I, el paso que dice que Trust "empieza a subir de a poco").

## Lo que falta decidir con Benja

Una pregunta a la vez, con opciones y una recomendada:

1. **La segunda forma de que baje Trust.** Recomendada: **un video perdido baja Trust** (por ejemplo, −10), porque el amigo arriesgó para grabarlo y Matías no lo descargó, y así la descarga deja de ser un trámite sin consecuencias. Otra opción: **preguntar de más**, en la que desde la tercera pregunta de una solicitud cada pregunta baja Trust ("¿Otra vez, Mati? Apúrate"). Combina con los sinónimos, pero castiga a quien está aprendiendo.
2. **Cómo se usa el flash.** El celular es un modo exclusivo: al abrirlo se cierran los paneles. Opciones:
   - un ícono de linterna en la barra superior del celular abierto (recomendada: es coherente con los modos exclusivos, y abrir el celular cuesta atención);
   - clic derecho sobre el celular del escritorio, que es más rápido pero menos descubrible.

   Revisa que la Mano se vea con el celular abierto.
3. **La Mano y el cuaderno.** El cuaderno tapa la mitad derecha de la pantalla, justo donde están los diales y por donde entra la Mano. Opciones:
   - la Mano se dibuja **por encima del cuaderno** y estira el brazo sobre la página (recomendada: como no suena, verla es la única forma de notarla);
   - la Mano se arma detrás del cuaderno, como la criatura detrás del chat, y lo único que la delata son las barras de arriba, que bajan.
4. **La Mano sobre Connection.** El dial de Connection es el promedio de las 3 señales. Recomendada: la Mano baja las 3 señales parejo, así que también sube la estática. Y sobre Trust: como Trust ya no se recupera, revisa con Benja si la Mano puede elegirlo igual que los otros diales o si debe bajarlo más lento.
5. **Desde qué noche aparece la Mano y cómo se enseña.** La noche 0 es guiada y hoy enseña la criatura y las cortinas. Opciones:
   - un paso más en la noche 0;
   - un aviso del tutorial la primera vez que aparece en una noche normal.

   Revisa también que no coincida con la criatura en las primeras noches.
6. **Los valores de partida** de los puntos 1, 3, 6, 7 y 8, en una sola tabla para que Benja los confirme de una vez.

## Reglas

- Los textos nuevos son borradores reales, en `data/text/*.csv`: lo que le pasa al amigo, las variantes de las características, el aviso de los videos, el "−1 s" del señuelo, el flash y el aviso de la Mano. Dile a Benja en qué archivo quedó cada uno, para que los corrija antes del congelamiento del contenido del 25-nov (regla 8).
- Todos los valores van en `data/balance.tres` o `data/nights/*.tres`, nunca como constantes del código (regla 7).
- El `.aseprite` de la Mano y la maqueta son de Benja: solo se leen (regla 5). Si Godot no importa la Mano con Aseprite Wizard, deja instrucciones paso a paso en `docs/04` (regla 2).
- No uses `--import` con el editor de Benja abierto.
- No agregues nada que Benja no pidió. Lo demás de `docs/22` (las secciones B a E) queda para otro momento (regla 6).
- Commits: pregunta antes de cada uno, salvo que Benja autorice todos al empezar (regla 11). Sin push.

## Lo que tiene que quedar al terminar

1. **`docs/24_plan_ajustes_mecanicas.md`** (Plan 9.1), ejecutado y con las pruebas en verde.
2. **Capturas revisadas:**
   - la Mano acercándose y sobre un dial;
   - el flash;
   - un mensaje inicial sin lugar;
   - una característica dicha con otras palabras y su nombre en el cuaderno;
   - el aviso de videos;
   - un dibujo de la curva de olas de una noche.
3. **Las decisiones del 11-nov** completas, con sus valores, en `CLAUDE.md` y en el diseño v2:
   - §5 (ritmo);
   - §8.1 a §8.3 (mensaje inicial, señuelos y variantes);
   - §10.2 a §10.4 (batería, Trust, criatura y aviso de cuota);
   - §11 (la Mano).

   Actualiza también `docs/02` §6, `sonidos_pendiente.md` (el flash) y `arte_pendiente.md` (si la Mano necesita más cuadros).
4. **`docs/04`:** una sección nueva para que Benja pruebe todo esto (unos 20 minutos).
5. **`resumen.md`** con sus cuatro categorías, y **`docs/00_log.md`** con la sesión cerrada. Después viene S21b (el lore).
