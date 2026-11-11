class_name TutorialCardData
extends Resource
## Una tarjeta del final de la noche 0 (pedido de Benja, 11 de noviembre): un video del juego en bucle, un título y unas
## frases cortas. Los videos los graba tools/make_tutorial_videos.sh.

## El título (ui.csv).
@export var title_key: String
## Lo que explica, en frases cortas (ui.csv).
@export var text_key: String
## El video, en bucle (video/tutorial/*.ogv).
@export var video: VideoStream
