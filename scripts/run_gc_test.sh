#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

. "$SCRIPT_DIR/set_release_env.sh"

if [ ${#WHEELSPRUNG_LEVEL_SALT} -ne 64 ]; then
  echo "Error: WHEELSPRUNG_LEVEL_SALT must be 64 characters long."
  exit 1
fi

nim c -d:useHostOS -d:nimAllocStats -r "./scripts/gc_test/gc_test.nim"