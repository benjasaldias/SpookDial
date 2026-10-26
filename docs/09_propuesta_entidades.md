# Propuesta de entidades: El Tue Tué, La Calchona y El Trauco

**Es un borrador de Claude para inspirar a Benja**, no contenido decidido. Benja lo refina y decide qué queda. Las frases entre asteriscos y los textos de folclore son **ejemplos de intención**: los textos finales los escribe Benja (`CLAUDE.md`, regla 8).

Cada entidad sigue la plantilla de `docs/02` §7 y cumple lo que revisa el validador:

- 2 a 4 características, 4 acciones, 2 o 3 observaciones y como máximo 3 reglas, más "en cualquier otro caso";
- cada regla se aplica en al menos una situación;
- ninguna característica la comparten más de 2 entidades.

Al final están las fuentes y lo que se dejó fuera del folclore por el público de 13 años o más.

---

## Resumen del conjunto

| | El Tue Tué | La Calchona | El Trauco |
| --- | --- | --- | --- |
| Noche | 1 | 1 | 3 |
| Lugares | Techos, árboles, casas | Caminos, potreros | Bosque |
| Observaciones | 2 | 2 | 3 |
| Dificultad | Fácil (tutorial) | Fácil (tutorial) | Media: obliga a preguntar |
| Categorías de sus observaciones | Vista, Sonido | Sonido, Vista | Vista, Vista, Rastro |

**Características compartidas (a propósito):**

| Característica | Categoría | La comparten | Para qué |
| --- | --- | --- | --- |
| `ointment_smell`: "un *olor dulzón a ungüento*" | Ambiente | Tue Tué y Calchona | Las dos son brujos transformados con un ungüento o pociones. En la noche 1, el olor solo no basta: hay que mirar otra característica. |
| `snagged_threads`: "*hebras enganchadas* en las ramas" | Rastro | Calchona y Trauco | Lana de oveja o fibra de quilineja: a simple vista son iguales. En la noche 3 confunde a quien identifica solo por los rastros. |

Con eso, ninguna de las dos puede compartirse con una cuarta entidad (el máximo es 2). Las entidades de las noches 2 y 4 necesitan características compartidas nuevas, si se quieren.

---

## El Tue Tué

**Lugares donde aparece:** techos de las casas, sauces y árboles del patio, el cielo sobre la cabaña.

**Folclore para el cuaderno (borrador de la intención):**
Un brujo se unta la garganta con un ungüento, y su cabeza se desprende y sale volando de noche. Sus orejas se vuelven alas y su cara se cubre de plumas cenicientas. Su grito de dos notas anuncia una muerte cercana. Ronda la casa de los enfermos para beberles la sangre. En el campo le ofrecen sal: dicen que al día siguiente el brujo llega en persona a pedirla.

**Características:**

1. `bird_with_face` (Vista): un pájaro con *cara de persona*.
2. `two_note_cry` (Sonido): un *grito de dos notas*, como un queltehue. (No se escribe "tué, tué" para no regalar el nombre.)
3. `ointment_smell` (Ambiente, compartida con la Calchona): un *olor dulzón a ungüento*.

**Acciones:**

| id | Acción | Sabor |
| --- | --- | --- |
| `cross_scissors` | Abrir unas tijeras en cruz | Protección popular contra brujos |
| `stay_silent` | Quedarse callado y no mirar arriba | No responderle ni llamarlo |
| `offer_salt` | Ofrecerle sal | La costumbre del campo: el brujo vuelve a pedirla |
| `mimic_cry` | Imitarle el grito | **Tentadora:** se acerca, y el video sale espectacular |

**Observaciones:**

1. `circling` — ¿Está dando vueltas sobre una casa? (Vista) — valores: `over_house` (da vueltas sobre una casa) / `passing` (pasa de árbol en árbol).
2. `cried_three_times` — ¿Gritó tres veces seguidas? (Sonido) — valores: `yes` / `no`.

**Reglas (se aplica la primera que se cumple):**

1. Si da vueltas sobre una casa → correcta: **Abrir unas tijeras en cruz** · mayor riesgo: **Imitarle el grito**.
2. Si gritó tres veces seguidas → correcta: **Quedarse callado** · mayor riesgo: **Ofrecerle sal**.
3. En cualquier otro caso → correcta: **Ofrecerle sal** · mayor riesgo: **Imitarle el grito**.

Por qué funciona:

- **Ofrecerle sal** es la correcta cuando solo pasa, y la de mayor riesgo cuando ya gritó tres veces (lo llamaste: viene). Quien memoriza "sal = buena" se equivoca.
- La regla 1 se reconoce de un vistazo, como corresponde al tutorial.

**Qué tiene que comunicar el mensaje (intención):** el amigo oye algo en el techo o ve un pájaro raro sobre una casa; le pareció ver una cara y no está seguro. Cuenta cuántas veces gritó. Si se le pregunta "¿Cómo está el ambiente?", menciona el olor dulzón.

**Ejemplo de solicitud:** Gonzalo escribe desde el patio. Un pájaro con *cara de persona* da vueltas sobre la casa del vecino y se siente un *olor dulzón a ungüento*. Regla 1: **Abrir unas tijeras en cruz**. Si falta un video, el jugador puede arriesgarse con **Imitarle el grito**.

**Variante para más dificultad** (por ejemplo, si en la noche 5 se quiere más): una tercera observación `moon` (Ambiente: `moon` / `no_moon`), porque vuela en noches sin luna. Por ejemplo, "Si gritó tres veces y no hay luna → Quedarse callado".

**Ideas para el arte y el sonido:** el boceto, una cabeza con plumas grises y orejas como alas, vista desde abajo y recortada contra el cielo. El sonido, dos notas agudas, como un queltehue lejano, que se repiten. La luz, un parpadeo frío en la ventana.

---

## La Calchona

**Lugares donde aparece:** caminos de tierra, potreros, orillas de acequias y ríos.

**Folclore para el cuaderno (borrador de la intención):**
Una mujer del campo tomaba pociones a escondidas para volverse oveja y salir de noche. Una vez, su marido encontró los frascos, los tiró al río y se llevó a los niños. Ella se quedó para siempre como una oveja negra, con la cara, las manos y el pelo de mujer. Vaga sola, balando. Dicen que está arrepentida y que basta con dejarle un plato de comida. Pero no perdona a quien se acerca a burlarse.

**Características:**

1. `lone_bleat` (Sonido): una *oveja balando sola*, sin rebaño.
2. `long_tangled_hair` (Vista): *pelo largo y enredado*, como de mujer. ("Calchona" viene de *kalcha*, mecha de pelo largo y desordenado.)
3. `ointment_smell` (Ambiente, compartida con el Tue Tué): un *olor dulzón a ungüento*.
4. `snagged_threads` (Rastro, compartida con el Trauco): *hebras enganchadas* en las ramas.

**Acciones:**

| id | Acción | Sabor |
| --- | --- | --- |
| `leave_food` | Dejarle un plato de comida | La costumbre del campo |
| `back_away` | Retroceder sin darle la espalda | Prudencia ante un animal que embiste |
| `walk_past` | Seguir de largo sin mirarla | Respetar su pena |
| `see_her_face` | Acercarse a verle la cara | **Tentadora:** la cara de mujer en el cuerpo de oveja es el video del año |

**Observaciones:**

1. `bleat_tone` — ¿Cómo bala? (Sonido) — valores: `weeping` (como llorando) / `snorting` (bufa fuerte, enojada).
2. `approaching` — ¿Se está acercando? (Vista) — valores: `yes` / `no`.

**Reglas:**

1. Si bufa y se está acercando → correcta: **Retroceder sin darle la espalda** · mayor riesgo: **Acercarse a verle la cara**.
2. Si bala como llorando → correcta: **Dejarle un plato de comida** · mayor riesgo: **Acercarse a verle la cara**.
3. En cualquier otro caso → correcta: **Seguir de largo sin mirarla** · mayor riesgo: **Dejarle un plato de comida**.

Por qué funciona:

- La regla 1 tiene dos condiciones, así que enseña a leer la página completa: "bufa" solo no basta.
- **Dejarle comida** es la correcta cuando está triste y la de mayor riesgo cuando está enojada (hay que acercarse). Es el mismo giro que la sal del Tue Tué, para que el jugador aprenda en la noche 1 que una acción no es buena ni mala por sí sola.

**Qué tiene que comunicar el mensaje (intención):** el amigo va por un camino y oye una oveja sola. Le parece rara: tiene el pelo largo, como de persona, y no ve el rebaño. Describe cómo bala y si viene hacia él.

**Ejemplo de solicitud:** Agustín, en el camino, oye una *oveja balando sola* y ve *pelo largo y enredado*. Bufa y viene hacia él. Regla 1: **Retroceder sin darle la espalda**.

**Distinguirla del Tue Tué en la noche 1:** las dos tienen el *olor dulzón a ungüento*. Si el mensaje trae solo esa característica, el jugador necesita otra: preguntar "¿Qué ves?" o "¿Qué oyes?". Es una buena primera lección de cómo funcionan las preguntas.

**Ideas para el arte y el sonido:** el boceto, una oveja negra de perfil con una melena humana que le tapa la cara (lo inquietante es no verla). El sonido, un balido que se quiebra a mitad, casi como un sollozo.

---

## El Trauco

**Lugares donde aparece:** el bosque, troncos huecos, claros con árboles recién caídos.

**Folclore para el cuaderno (borrador de la intención):**
Un hombrecito del bosque de Chiloé, de menos de un metro, con traje y sombrero cónico de quilineja. En lugar de pies tiene muñones, y se apoya en un bastón retorcido, el *pahueldún*. Con su hacha de piedra derriba cualquier árbol en tres golpes. Su mirada tuerce la cara o deja jorobado a quien la recibe. Vive en troncos huecos y nunca actúa frente a testigos. Si le tiras arena, se queda contando los granos.

**Características:**

1. `little_man` (Vista): un *hombrecito* de menos de un metro.
2. `vine_hat` (Vista): un *sombrero puntiagudo de enredadera*.
3. `three_blows` (Sonido): *tres golpes secos* y un árbol que cae.
4. `snagged_threads` (Rastro, compartida con la Calchona): *hebras enganchadas* en las ramas.

**Acciones:**

| id | Acción | Sabor |
| --- | --- | --- |
| `look_down` | Mirar al suelo, nunca a los ojos | Su mirada tuerce |
| `talk_loud` | Hablar fuerte, como si vinieran más | No actúa frente a testigos |
| `throw_sand` | Tirarle un puñado de tierra o arena | Se queda contando los granos |
| `follow_to_tree` | Seguirlo hasta su tronco hueco | **Tentadora:** grabar dónde vive el Trauco |

**Observaciones:**

1. `saw_first` — ¿Quién vio a quién primero? (Vista) — valores: `friend` / `trauco`.
2. `in_hand` — ¿Qué lleva en la mano? (Vista) — valores: `axe` (hacha de piedra) / `cane` (bastón retorcido).
3. `ground` — ¿Cómo está el suelo? (Rastro) — valores: `muddy` (embarrado) / `dry` (seco).

**Reglas:**

1. Si el Trauco lo vio primero → correcta: **Mirar al suelo** · mayor riesgo: **Seguirlo hasta su tronco**.
2. Si lleva el bastón → correcta: **Hablar fuerte, como si vinieran más** · mayor riesgo: **Tirarle arena**.
3. Si el suelo está embarrado → correcta: **Seguirlo hasta su tronco** · mayor riesgo: **Tirarle arena**.
4. En cualquier otro caso → correcta: **Tirarle arena** · mayor riesgo: **Seguirlo hasta su tronco**.

Por qué funciona:

- **El giro de la regla 3:** el Trauco es muy limpio y no se mete al barro, así que en el barro se puede seguirlo. La acción "suicida" de las otras reglas es la correcta aquí. Es el tipo de sorpresa de Keep Talking que premia leer en orden.
- Las 3 observaciones van en categorías distintas de pregunta (Vista, Vista y Rastro). Como en la noche 3 el mensaje trae todas menos una, el jugador tiene que preguntar, y "¿Hay rastros?" se vuelve útil por primera vez.
- Con el bastón (regla 2), la arena es la de mayor riesgo: hay que acercarse a alguien que está golpeando el suelo.

**Qué tiene que comunicar el mensaje (intención):** el amigo oye tres golpes secos y un árbol que cae. Ve a alguien muy bajito con un sombrero raro. Dice si el hombrecito ya lo está mirando y qué tiene en la mano. Si se le pregunta "¿Hay rastros?", habla del barro o del suelo seco, y de las hebras en las ramas.

**Ejemplo de solicitud (noche 3, falta una observación):** León oyó *tres golpes secos* y ve un *hombrecito* con un hacha. Todavía no lo ha visto. No dice cómo está el suelo.

1. Las reglas 1 y 2 no se cumplen (lo vio León primero y lleva el hacha), así que todo depende del suelo.
2. El jugador pregunta **¿Hay rastros?** (−5 s): "el suelo está todo embarrado".
3. Regla 3: **Seguirlo hasta su tronco**.

**Lo que se dejó fuera (público de 13+):** el contenido sexual de la leyenda tradicional y la Fiura (su pareja, que tiene el mismo problema). Se usan solo el hacha, el bastón, la mirada que tuerce, la arena y el no actuar frente a testigos.

**Ideas para el arte y el sonido:** el boceto, una silueta baja con sombrero cónico entre troncos, con el hacha al hombro, y los ojos como lo único con brillo. El sonido, tres golpes secos de hacha, una pausa y el crujido del árbol al caer. El bastón golpeando el suelo puede ser su "aviso".

---

## Cómo pasarlas a datos

Cuando Benja las refine, cada una se convierte en un `.tres` como `data/entities/trauco.tres` (ahora es solo un ejemplo de formato), y sus textos van a `messages.csv` y `notebook.csv`. Las pruebas avisan si algo no cumple la plantilla. Claude puede hacer esa conversión en S8 o antes, si Benja lo pide.

---

## Fuentes

- **Tue Tué:** [Wikipedia, "Chonchón"](https://es.wikipedia.org/wiki/Chonch%C3%B3n) (cabeza con plumas cenicientas, orejas como alas, grito "tué, tué", sangre de los enfermos, ungüento, "Sin Dios ni Santa María"), [Wikipedia (en), "Chonchon"](https://en.wikipedia.org/wiki/Chonchon) y [BioBioChile, "Tue Tue, el pájaro maldito…"](https://www.biobiochile.cl/noticias/sociedad/curiosidades/2019/06/23/tue-tue-el-pajaro-maldito-que-no-debes-llamar-esta-noche-de-san-juan.shtml) (canto como de queltehue, ofrecerle sal, no llamarlo tres veces). Lo de las tijeras en cruz y que el brujo vuelve a pedir la sal es tradición oral extendida, pero estas fuentes no lo confirman.
- **La Calchona:** [Wikipedia, "Calchona"](https://es.wikipedia.org/wiki/Calchona) (pociones, el marido que las tira al río, oveja negra con cara, manos y pelo de mujer, plato de comida, *kalcha*) y [Currículum Nacional, material de 5° básico](https://www.curriculumnacional.cl/614/articles-25677_recurso_pdf.pdf).
- **El Trauco:** [Wikipedia, "Trauco"](https://es.wikipedia.org/wiki/Trauco) (estatura, quilineja, sombrero cónico, pahueldún, hacha de tres golpes, mirada que tuerce, troncos huecos, arena, no actúa frente a testigos, muy limpio) y [Museo de Chiloé en SURDOC](https://surdoc.cl/registro/22-1474/pdf).
- **Para profundizar:** Oreste Plath, *Geografía del mito y la leyenda chilenos* ([Memoria Chilena](https://www.memoriachilena.gob.cl/602/w3-article-9487.html)).
