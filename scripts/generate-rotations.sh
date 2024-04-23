#!/bin/bash

## Create rotated images for the bike and rider sprites, in a png format that can be converted
## to pdt using the ./compile_images.sh script

## Requires spriterot to be installed.
## Install it using: https://github.com/samdze/spriterot/releases/tag/v1.0.1

spriterot -v -r 64 -o ../../source/images/bike-wheel-table-22-22.png ./wheel.png
spriterot -v -w 48 -h 48 -k -r 64 -o ../../source/images/bike-chassis-table-48-48.png ./bike-chassis.png

spriterot -v -r 64 -o ../../source/images/rider/upper-arm-table-14-14.png ./rider/upper-arm.png
spriterot -v -r 64 -o ../../source/images/rider/lower-arm-table-12-12.png ./rider/lower-arm.png
spriterot -v -r 64 -o ../../source/images/rider/upper-leg-table-18-18.png ./rider/upper-leg.png
spriterot -v -r 64 -o ../../source/images/rider/lower-leg-table-14-14.png ./rider/lower-leg.png
spriterot -v -r 64 -o ../../source/images/rider/torso-table-18-18.png ./rider/torso.png
spriterot -v -r 64 -o ../../source/images/rider/head-table-14-14.png ./rider/head.png
