#!/usr/bin/env bash

# Check usage
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
echo "Usage: $0 <input_file> <quality> <scale>"
    echo "Example: $0 image.png 80 800"
    exit 1
fi

INPUT_FILE=$1
QUALITY=${2:-80}  # Default quality = 80
SCALE=${3:-0}     # Default (0) means no scaling

[ ! -f "$INPUT_FILE" ] && echo "Error: File '$INPUT_FILE' not found!" && exit 1
OUTPUT_FILE="${INPUT_FILE%.*}.webp"

# Scale option (only if user provided a scale value)
if [ "$SCALE" -gt 0 ]; then
    cwebp -q "$QUALITY" -resize "$SCALE" 0 "$INPUT_FILE" -o "$OUTPUT_FILE"
else
    cwebp -q "$QUALITY" "$INPUT_FILE" -o "$OUTPUT_FILE"
fi

[ "$?" -eq 0 ] && echo "$INPUT_FILE converted to webP"
