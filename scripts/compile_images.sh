#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="${SCRIPT_DIR}/../source"
DESTINATION_DIR="${SCRIPT_DIR}/../wheelsprung.pdx"

pdc -k -s -v "$SOURCE_DIR" "$DESTINATION_DIR"
