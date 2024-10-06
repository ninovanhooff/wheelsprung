#!/bin/bash

## Create rotated images for the bike and rider sprites, in a png format that can be converted
## to pdt using the" "./compile_images.sh script

## Requires spriterot to be installed.
## Install it using: https://github.com/samdze/spriterot/releases/tag/v1.0.1

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SUPPORT_IMAGES_DIR="$SCRIPT_DIR/../support/images"
SOURCE_IMAGES_DIR="$SCRIPT_DIR/../source/images"

function call_spriterot {
  local size="$2"
  local subdirectory
  subdirectory="$(dirname "$1")"
  find "$SOURCE_IMAGES_DIR/$subdirectory/" -name "$(basename "$1")-table-*" -exec rm {} \;
  local output_file="$SOURCE_IMAGES_DIR/$1-table-$size-$size.png"
  local input_file="$SUPPORT_IMAGES_DIR/$1.png"
  local rotations="$3"
  local algorithm="${4:-rotsprite}"

  spriterot -a "$algorithm" -r "$rotations" --width "$size" --height "$size" -o "$output_file" "$input_file"
}

call_spriterot "bike-wheel" 22 64
call_spriterot "bike-ghost-wheel" 22 64
call_spriterot "bike-chassis" 48 64
call_spriterot "rider/upper-arm" 14 64
call_spriterot "rider/lower-arm" 11 64 linear
call_spriterot "rider/upper-leg" 16 64
call_spriterot "rider/lower-leg" 14 64
call_spriterot "rider/tail" 27 64
call_spriterot "rider/torso" 21 64
call_spriterot "rider/head" 22 64
call_spriterot "rider/ghost-head" 20 64
call_spriterot "killer/killer" 20 64
call_spriterot "dynamic_objects/tall-book" 140 240

