#!/bin/bash

## A script to process all assets (images, audio, video) in source directory and add them as pdi
# pda, or pdt to the PDX file in the destination directory

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="${SCRIPT_DIR}/../source"
DESTINATION_DIR="${SCRIPT_DIR}/../wheelsprung.pdx"

pdc -s -v "$SOURCE_DIR" "$DESTINATION_DIR"
