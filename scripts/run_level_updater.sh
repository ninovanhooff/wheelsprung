#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SOURCE_DIR="${SCRIPT_DIR}/../source"

. "$SCRIPT_DIR/set_release_env.sh"

echo "level salt run_updater $WHEELSPRUNG_LEVEL_SALT"

# switch to source dire because level data definitions are relative to source directory
cd "$SOURCE_DIR" || exit

nim c --skipUserCfg --skipParentCfg -r "../scripts/level_hash_updater/update_level_hashes.nim"