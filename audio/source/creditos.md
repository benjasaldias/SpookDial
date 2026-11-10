# Grabaciones usadas en los sonidos

Casi todos los sonidos del juego se sintetizan con `tools/make_sounds.py`. Estas cinco grabaciones son la excepción: la síntesis no logra un gallo, una oveja, una guagua ni un gruñido creíbles. Todas son de **dominio público o CC0**, así que no obligan a dar crédito. Igual se nombran aquí, y conviene ponerlas en los créditos del juego (Plan 10).

Las bajó Claude de Wikimedia Commons el 10 de noviembre de 2026. Junto a cada archivo hay un `.json` con su ficha completa. Godot no ve esta carpeta (`.gdignore`).

| Archivo | Dónde suena | Licencia | Autor | Origen |
| --- | --- | --- | --- | --- |
| `small_rooster_crowing.ogg` | El gallo del Basilisco (`basilisco_crows_*`), apagado como si cantara bajo el piso | Dominio público | alys (pdsounds.org) | [Commons](https://commons.wikimedia.org/wiki/File:Small_rooster_crowing.ogg) |
| `sheep_bleating.ogg` | Los balidos que lloran de La Calchona (`calchona_bleat_tone_weeping`), más graves y temblando | Dominio público | earthcalling (pdsounds.org) | [Commons](https://commons.wikimedia.org/wiki/File:Sheep_bleating.ogg) |
| `crying_newborn_baby.ogg` | El llanto de guagua del Imbunche (`imbunche_baby_cry_yes`), lejos, en la cueva | CC0 | the_yura (Freesound) | [Commons](https://commons.wikimedia.org/wiki/File:Crying_newborn_baby.ogg) |
| `monster_growls.ogg` | Los gruñidos del Imbunche (`imbunche_baby_cry_*`) y el chillido de la figura de la ventana (`scare_window`), acelerado | Dominio público | stilgar (pdsounds.org) | [Commons](https://commons.wikimedia.org/wiki/File:Monster_growls.ogg) |
| `monster_growls_2.ogg` | El gruñido ronco al exhalar de la criatura de la ventana (`scare_creature_breathing`), más lento | Dominio público | stilgar (pdsounds.org) | [Commons](https://commons.wikimedia.org/wiki/File:Monster_growls_2.ogg) |

Para reemplazar una, deja el archivo nuevo con el mismo nombre y vuelve a correr `tools/make_sounds.py`: los tramos que se usan están en el código (los segundos de inicio y fin).
