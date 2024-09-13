#!/bin/bash

## Create rotated images for the bike and rider sprites, in a png format that can be converted
## to pdt using the" "./compile_images.sh script

## Requires spriterot to be installed.
## Install it using: https://github.com/samdze/spriterot/releases/tag/v1.0.1

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SUPPORT_IMAGES_DIR="$SCRIPT_DIR/../support/images"
SOURCE_IMAGES_DIR="$SCRIPT_DIR/../source/images"
spriterot -v -r 64 --width 22 --height 22 -o "$SOURCE_IMAGES_DIR/bike-wheel-table-22-22.png" "$SUPPORT_IMAGES_DIR/wheel.png"
spriterot -v -r 64 --width 22 --height 22 -o "$SOURCE_IMAGES_DIR/bike-ghost-wheel-table-22-22.png" "$SUPPORT_IMAGES_DIR/ghost-wheel.png"
spriterot -v --width 48 --height 48 -k -r 64 -o "$SOURCE_IMAGES_DIR/bike-chassis-table-48-48.png" "$SUPPORT_IMAGES_DIR/bike-chassis.png"

spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/upper-arm-table-14-14.png" "$SUPPORT_IMAGES_DIR/rider/upper-arm.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/lower-arm-table-16-16.png" "$SUPPORT_IMAGES_DIR/rider/lower-arm.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/upper-leg-table-16-16.png" "$SUPPORT_IMAGES_DIR/rider/upper-leg.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/lower-leg-table-14-14.png" "$SUPPORT_IMAGES_DIR/rider/lower-leg.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/torso-table-20-20.png" "$SUPPORT_IMAGES_DIR/rider/torso.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/head-table-22-22.png" "$SUPPORT_IMAGES_DIR/rider/head.png"
spriterot -v -r 64 -o "$SOURCE_IMAGES_DIR/rider/ghost-head-table-20-20.png" "$SUPPORT_IMAGES_DIR/rider/ghost-head.png"

spriterot -r 240 -o "$SOURCE_IMAGES_DIR/dynamic_objects/tall-book-table-88-88.png" "$SUPPORT_IMAGES_DIR/dynamic_objects/tall-book.png"
