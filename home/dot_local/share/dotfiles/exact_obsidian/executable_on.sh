#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Error: a file name must be set, e.g. \"Butterflies Algorithmic\""
  exit 1
fi

file_name=$(echo "$1" | tr ' ' '-' | tr '[A-Z]' '[a-z]')
formatted_file_name=$(date "+%Y-%m-%d")_"${file_name}".md
cd "$OBSIDIAN_VAULT" || exit 2
touch "inbox/${formatted_file_name}"
lvim -c "normal! <leader>oo" "inbox/${formatted_file_name}"
