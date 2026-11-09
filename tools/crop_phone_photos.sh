#!/usr/bin/env bash
# Recorta las fotos de Benja (art/phone/source/) a 232×232 para Snapgram, sin tocar los originales.
# Uso, desde la carpeta del proyecto: bash tools/crop_phone_photos.sh
# Después hay que importar: ~/tools/godot-wsl.sh --headless --path "$PWD" --import (con el editor cerrado).
set -euo pipefail

SOURCE=art/phone/source
OUTPUT=art/phone

# Recorta un cuadrado y lo reduce. Por defecto va al centro; `top` lo pega arriba.
crop() {
	local input=$1 output=$2 anchor=${3:-center}
	local y="(ih-min(iw\\,ih))/2"
	if [[ $anchor == top ]]; then
		y=0
	fi
	ffmpeg -y -loglevel error -i "$SOURCE/$input" \
		-vf "crop=min(iw\\,ih):min(iw\\,ih):(iw-min(iw\\,ih))/2:$y,scale=232:232:flags=lanczos,format=rgb24" \
		-frames:v 1 -update 1 "$OUTPUT/$output"
}

for number in 1 2 3 5 6 7 8 9 10 11 12; do
	crop "cat$number.jpg" "$(printf 'post_%02d.png' "$number")"
done
# La cara de este gato está arriba de la foto: al centro quedaba sin orejas.
crop cat4.jpg post_04.png top

crop scary1.jpg disturbing_1.png
crop scary2.webp disturbing_2.png
crop scary3.jpg disturbing_3.png
crop scary4.jpg disturbing_4.png
