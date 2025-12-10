#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Error: a file name must be set, e.g. \"Butterflies Algorithmic\""
  exit 1
fi
file_name="${1// /-}"           # Replace spaces with hyphens
file_name="${file_name:l}"      # Convert to lowercase
formatted_file_name=$(date "+%Y-%m-%d")_"${file_name}".md
cd "$OBSIDIAN_VAULT" || exit 2
touch "fleeting/${formatted_file_name}"
lvim -c "ObsidianTemplate note" -c "execute 'normal! dd'" -c "execute 'normal! 20G'" -c "s/# \d\{4}-\d\{2}-\d\{2}_/\# /g" -c "s/-/ /g" -c "nohlsearch" "fleeting/${formatted_file_name}"

