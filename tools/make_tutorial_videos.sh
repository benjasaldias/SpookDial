#!/usr/bin/env bash
# Graba los videos de las tarjetas del tutorial (Plan 9.2) y los deja en video/tutorial/ como Theora.
# Cada clip se graba con el Movie Maker de Godot (test/record_tutorial_clips.gd) a 1280×720 y 30 cuadros por segundo,
# y se recorta sin escalar, para que el pixel art se vea igual que en el juego: 640×360, salvo la ventana, que es vertical
# (420×512) para que se vean la criatura y su sombra en el escritorio, y la Mano, que es más alta (640×512) para que quepa
# el celular con el botón FLASH bajo los diales.
# Uso, desde la carpeta del proyecto y con el editor de Godot cerrado:
#     tools/make_tutorial_videos.sh            # todos
#     tools/make_tutorial_videos.sh hand       # solo los que se nombran
set -euo pipefail
cd "$(dirname "$0")/.."

# Qué parte de la pantalla muestra cada clip: ancho, alto, x e y de la esquina, en el escritorio de 1280×720.
declare -A CROPS=(
	[meters]="640:360:460:0"
	[phone]="640:360:140:0"
	[window]="420:512:190:160"
	[hand]="640:512:640:0"
)
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
clips=("$@")
if [ ${#clips[@]} -eq 0 ]; then
	clips=(meters phone window hand)
fi
mkdir -p video/tutorial
for clip in "${clips[@]}"; do
	# El Godot de Windows escribe en una ruta de Windows: el archivo temporal va en la carpeta del proyecto.
	raw="video/tutorial/_${clip}.avi"
	~/tools/godot-wsl.sh --path "$PWD" --write-movie "$raw" --fixed-fps 30 -s res://test/record_tutorial_clips.gd -- "$clip" \
		> "$TMP/$clip.log" 2>&1
	ffmpeg -v error -y -i "$raw" -vf "crop=${CROPS[$clip]}" -c:v libtheora -q:v 8 -an "video/tutorial/$clip.ogv"
	rm -f "$raw"
	echo "video/tutorial/$clip.ogv"
done
