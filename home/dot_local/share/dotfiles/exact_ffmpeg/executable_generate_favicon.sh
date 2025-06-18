#!/bin/bash

# Check if the input image is provided
if [ -z "$1" ]; then
  echo "Usage: $0 path/to/image.png"
  exit 1
fi

# Set input image path from argument
INPUT_IMAGE="$1"

# Set output directory for favicons (optional: can be set to another directory)
OUTPUT_DIR="."

# Use Lanczos for smaller sizes to preserve details
ffmpeg -i "$INPUT_IMAGE" -vf "scale=16:16:force_original_aspect_ratio=decrease,pad=16:16:(ow-iw)/2:(oh-ih)/2:color=0x00000000" -sws_flags lanczos "$OUTPUT_DIR/favicon-16x16.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=32:32:force_original_aspect_ratio=decrease,pad=32:32:(ow-iw)/2:(oh-ih)/2:color=0x00000000" -sws_flags lanczos "$OUTPUT_DIR/favicon-32x32.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=48:48:force_original_aspect_ratio=decrease,pad=48:48:(ow-iw)/2:(oh-ih)/2:color=0x00000000" -sws_flags lanczos "$OUTPUT_DIR/favicon-48x48.png"

# Use default scaling for larger sizes (bicubic by default)
ffmpeg -i "$INPUT_IMAGE" -vf "scale=64:64:force_original_aspect_ratio=decrease,pad=64:64:(ow-iw)/2:(oh-ih)/2:color=0x00000000" "$OUTPUT_DIR/favicon-64x64.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=96:96:force_original_aspect_ratio=decrease,pad=96:96:(ow-iw)/2:(oh-ih)/2:color=0x00000000" "$OUTPUT_DIR/favicon-96x96.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=180:180:force_original_aspect_ratio=decrease,pad=180:180:(ow-iw)/2:(oh-ih)/2:color=0x00000000" "$OUTPUT_DIR/favicon-180x180.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=192:192:force_original_aspect_ratio=decrease,pad=192:192:(ow-iw)/2:(oh-ih)/2:color=0x00000000" "$OUTPUT_DIR/favicon-192x192.png"
ffmpeg -i "$INPUT_IMAGE" -vf "scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:(ow-iw)/2:(oh-ih)/2:color=0x00000000" "$OUTPUT_DIR/favicon-512x512.png"

# Generate .ico file combining multiple sizes
ffmpeg -i "$OUTPUT_DIR/favicon-16x16.png" -i "$OUTPUT_DIR/favicon-32x32.png" -i "$OUTPUT_DIR/favicon-48x48.png" -i "$OUTPUT_DIR/favicon-64x64.png" "$OUTPUT_DIR/favicon.ico"

# Create the site.webmanifest file
cat > "$OUTPUT_DIR/site.webmanifest" <<EOL
{
  "name": "Your Website Name",
  "short_name": "Short Name",
  "description": "A description of your website or app.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#ffffff",
  "icons": [
    {
      "src": "$OUTPUT_DIR/favicon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "$OUTPUT_DIR/favicon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
EOL

# Output HTML snippet
echo "Favicons and site.webmanifest generated and saved to $OUTPUT_DIR."
echo ""
echo "Add the following HTML to your <head> section:"
echo ""
echo "<link rel=\"icon\" type=\"image/x-icon\" href=\"$OUTPUT_DIR/favicon.ico\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"16x16\" href=\"$OUTPUT_DIR/favicon-16x16.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"32x32\" href=\"$OUTPUT_DIR/favicon-32x32.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"48x48\" href=\"$OUTPUT_DIR/favicon-48x48.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"64x64\" href=\"$OUTPUT_DIR/favicon-64x64.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"96x96\" href=\"$OUTPUT_DIR/favicon-96x96.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"180x180\" href=\"$OUTPUT_DIR/favicon-180x180.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"192x192\" href=\"$OUTPUT_DIR/favicon-192x192.png\">"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"512x512\" href=\"$OUTPUT_DIR/favicon-512x512.png\">"
echo ""
echo "<!-- For Apple Touch Icon -->"
echo "<link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"$OUTPUT_DIR/favicon-180x180.png\">"
echo ""
echo "<!-- For Android Chrome -->"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"192x192\" href=\"$OUTPUT_DIR/favicon-192x192.png\">"
echo ""
echo "<!-- Web App Manifest Icon (PWA) -->"
echo "<link rel=\"icon\" type=\"image/png\" sizes=\"512x512\" href=\"$OUTPUT_DIR/favicon-512x512.png\">"
echo ""
echo "<!-- Link to the web manifest -->"
echo "<link rel=\"manifest\" href=\"$OUTPUT_DIR/site.webmanifest\">"
