#!/usr/bin/env bash

[ "$#" -ne 3 ] && echo "Usage: $0 <filename> <scale> <frame_rate>" && echo "Example: $0 input.mp4" && exit 1

FILENAME=$1
SCALE=$2
FRAMERATE=$3
OUTPUT_FILE="${FILENAME%.mp4}.gif"
PALETTE_FILE="${FILENAME%.mp4}_palette.png"

#Generate palette
ffmpeg -i "$FILENAME" -vf "fps=$FRAMERATE,scale=$SCALE:-1:flags=lanczos,palettegen" "$PALETTE_FILE"
ffmpeg -i "$FILENAME" -i "$PALETTE_FILE" -vf "fps=$FRAMERATE,scale=$SCALE:-1:flags=lanczos [x]; [x][1:v] paletteuse" "$OUTPUT_FILE"

rm -f $PALETTE_FILE

echo "$FILENAME has been optimized has a GIF"
