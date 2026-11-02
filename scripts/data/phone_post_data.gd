class_name PhonePostData
extends Resource
## Una publicación del celular (diseño §10.2), de las que Matías scrollea para recuperar Sanity.
## Hasta el arte del celular ampliado (docs/06 §3), su imagen se dibuja con `color`.

## Quién publica (phone.csv).
@export var author_key: String
## Lo que dice la publicación (phone.csv).
@export var text_key: String
## La imagen de la publicación. Sin imagen, se dibuja un paisaje provisional de este color.
@export var picture: Texture2D
@export var color := Color(0.3, 0.45, 0.7)
