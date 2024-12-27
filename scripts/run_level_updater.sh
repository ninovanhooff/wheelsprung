#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

. "$SCRIPT_DIR/set_release_env.sh"

echo "level salt run_updater $WHEELSPRUNG_LEVEL_SALT"

nim c -d:useHostOS -r "./scripts/level_hash_updater/update_level_hashes.nim"