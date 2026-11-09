# Prompt: rediseñar la red social del celular

Sesión de **diseño y plan**, y de ejecución si alcanza. Modelo sugerido: Opus 5.5 · high. Benja la abre escribiendo: `Lee docs/20_prompt_red_social.md y sigue sus instrucciones.`

---

## Tu tarea

Benja quiere que la red social del celular **imite una real, como Instagram**, en vez de ser "algo tan excesiva y absurdamente temático chileno". Hoy se llama "copuchas", y sus publicaciones son de completos, sopaipillas y once. Diseña el cambio con él, con `superpowers:brainstorming`, y después impleméntalo o déjalo en un plan.

Antes de preguntar nada, lee:

- `CLAUDE.md` completo, `docs/00_log.md` y la entrada más reciente de `resumen.md`;
- `spook_dial_design.md` §10.2 (Sanity y el celular);
- `scripts/ui/phone_view.gd`, `scenes/ui/phone_view.tscn`, `scripts/data/phone_post_data.gd`, `data/text/phone.csv`, y las publicaciones en `data/catalog.tres` (`phone_posts`);
- `test/test_phone_view.gd`, y las pruebas de `test_catalog.gd` y `test_desk_scene.gd` que tocan el celular;
- `arte_pendiente.md`, la fila "Celular ampliado" y "Publicaciones perturbadoras".

Mira cómo se ve hoy: `C:\dev\capturas\plan9_phone.png`.

## Lo que hay hoy

- Una vista de 260×520 dibujada con rectángulos (`_draw_feed`): hora y batería, el nombre "copuchas" y un feed de publicaciones de 236 px de alto con autor, imagen, "me gusta" y texto. Se repiten sin fin.
- 12 `PhonePostData`, con `author_key`, `text_key`, `picture` (opcional) y `color`. Sin imagen se dibuja un paisaje de ese color.
- Lo que **no debe cambiar** (mecánica decidida): scrollear con la rueda sube Sanity, la batería da unos 38 s de scroll por noche sin recarga, sin batería dice "Sin batería" y el feed no avanza, clic derecho o `Esc` lo cierran, y la hora se sigue viendo.

## Lo que hay que decidir con Benja

Una pregunta a la vez, con opciones y una recomendada. Muestra cada propuesta de pantalla (maqueta en texto o captura) antes de programarla.

1. **Qué elementos imita.** Lo reconocible de Instagram: barra superior con el logo y los íconos, fila de historias con avatares en círculo, cabecera de publicación (avatar, usuario y `···`), imagen cuadrada, fila de acciones (me gusta, comentar, enviar y guardar), "me gusta" contados, texto con el usuario en negrita, "ver los comentarios", hace cuánto se publicó y barra de navegación abajo. A 260×520 no cabe todo con la fuente pixel: propón qué se queda.
2. **Nombre e identidad.** Recomienda **un nombre y un logo propios**: el juego se va a entregar y publicar, así que imita la forma de una red social sin usar la marca, el logo ni el nombre de Instagram. Es el nombre en `PHONE_APP_NAME` y lo que dibuje Benja.
3. **Imágenes.** Es lo que más pesa. Claude no dibuja el arte y Benja hace el arte en Aseprite, con el congelamiento el 25 de noviembre. Opciones: Benja dibuja las 12 imágenes (qué tamaño, en `arte_pendiente.md`), se generan por código imágenes más variadas que los paisajes actuales como provisional, o una mezcla. Revisa la regla 10 de pixel art: sin escalar, salvo ×2 exacto.
4. **Contenido.** Publicaciones como las de una red real: mascotas, comida, viajes, memes, deporte y selfies, con nombres de usuario creíbles. Puede haber algo de Chile, pero normal, no como chiste repetido. Todo va en `data/text/phone.csv`, como borrador real que Benja corrige (regla 8).
5. **¿Es solo decorado?** Hoy solo se scrollea. Decide si los botones hacen algo (por ejemplo, un corazón al hacer clic) o son dibujo. Cualquier mecánica nueva se compara con `docs/05` (regla 6). Recomienda solo decorado, salvo que Benja pida otra cosa.
6. **Terror.** `arte_pendiente.md` deja pendientes 3 "publicaciones perturbadoras" para cuando Sanity está baja, y un feed realista las haría funcionar mejor. Pregunta si entran ahora o si siguen pendientes. También pregunta si el canal de los amigos aparece en el feed: eso depende del lore (`docs/19_prompt_lore.md` y, si ya existe, `docs/21_lore_por_noche.md`).

## Cómo trabajar

- **El contenido es datos** (regla 7): si una publicación gana campos (avatar, likes, comentarios), van en `PhonePostData` y en `phone.csv`, no en constantes del código.
- Fuente Departure Mono en múltiplos de 11 px, y colores como tokens al inicio del script, como hoy.
- Prueba primero (`superpowers:test-driven-development`), con el ejecutor del proyecto; el comando está en `CLAUDE.md`. Quita el `\r` de la salida de Godot antes de comparar conteos. Las pruebas de Sanity y batería deben seguir pasando sin cambios: si tienes que tocarlas, algo se rompió.
- Revisa el resultado con una captura real, como `test/capture_plan9.gd`, y compárala con lo que Benja aprobó.
- Si Benja elige hacerlo en esta misma sesión y el cambio es solo de la vista y los datos, ejecútalo directamente. Si crece, escribe un plan `docs/NN_plan_*.md` con `superpowers:writing-plans`.

## Lo que tiene que quedar al terminar

- El celular con el diseño aprobado (o su plan), las pruebas pasando y la captura revisada.
- Actualizados: `arte_pendiente.md` (qué dibuja Benja, con tamaños), `docs/04_instrucciones_godot.md` (cómo probarlo), y `CLAUDE.md` y el diseño v2 con las decisiones de Benja. `resumen.md` y `docs/00_log.md`, como en todo cierre.
- Commits: pregunta antes de cada uno (regla 11). Sin push.
