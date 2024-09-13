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
  local size="$3"
  local output_file="$SOURCE_IMAGES_DIR/$1-table-$size-$size.png"
  local input_file="$SUPPORT_IMAGES_DIR/$2.png"
  local rotation="$4"

  spriterot -v -r "$rotation" --width "$size" --height "$size" -o "$output_file" "$input_file"
}

call_spriterot "bike-wheel" "wheel.png" 22 64
call_spriterot "bike-ghost-wheel" "ghost-wheel" 22 64
call_spriterot "bike-chassis" "bike-chassis" 48 64
call_spriterot "rider/upper-arm" "rider/upper-arm" 14 64
call_spriterot "rider/lower-arm" "rider/lower-arm" 11 64
call_spriterot "rider/upper-leg" "rider/upper-leg" 16 64
call_spriterot "rider/lower-leg" "rider/lower-leg" 14 64
call_spriterot "rider/torso" "rider/torso" 21 64
call_spriterot "rider/head" "rider/head" 22 64
call_spriterot "rider/ghost-head" "rider/ghost-head" 20 64
call_spriterot "dynamic_objects/tall-book" "dynamic_objects/tall-book" 88 240

# #spriterot -v -r 64 --width 22 --height 22 -o "$SOURCE_IMAGES_DIR/bike-wheel-table-22-22.png" "$SUPPORT_IMAGES_DIR/wheel.png"
# #spriterot -v -r 64 --width 22 --height 22 -o "$SOURCE_IMAGES_DIR/bike-ghost-wheel-table-22-22.png" "$SUPPORT_IMAGES_DIR/ghost-wheel.png"
# spriterot -v --width 48 --height 48 -k -r 64 -o "$SOURCE_IMAGES_DIR/bike-chassis-table-48-48.png" "$SUPPORT_IMAGES_DIR/bike-chassis.png"

# spriterot -v -r 64 --width 14 --height 14 -o "$SOURCE_IMAGES_DIR/rider/upper-arm-table-14-14.png" "$SUPPORT_IMAGES_DIR/rider/upper-arm.png"
# #spriterot -a rotsprite -v --width 11 --height 11 -r 64 -o "$SOURCE_IMAGES_DIR/rider/lower-arm-table-11-11.png" "$SUPPORT_IMAGES_DIR/rider/lower-arm.png"
# spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/upper-leg-table-16-16.png" "$SUPPORT_IMAGES_DIR/rider/upper-leg.png"
# #spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/lower-leg-table-14-14.png" "$SUPPORT_IMAGES_DIR/rider/lower-leg.png"
# spriterot -v -r 64 --width 21 -- height 21 -o "$SOURCE_IMAGES_DIR/rider/torso-table-21-21.png" "$SUPPORT_IMAGES_DIR/rider/torso.png"
# #spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/head-table-22-22.png" "$SUPPORT_IMAGES_DIR/rider/head.png"
# #spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/ghost-head-table-20-20.png" "$SUPPORT_IMAGES_DIR/rider/ghost-head.png"
# #
# #spriterot -r 240 -o "$SOURCE_IMAGES_DIR/dynamic_objects/tall-book-table-88-88.png" "$SUPPORT_IMAGES_DIR/dynamic_objects/tall-book.png"
