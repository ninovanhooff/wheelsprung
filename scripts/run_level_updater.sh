#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

. "$SCRIPT_DIR/set_release_env.sh"

if [ ${#WHEELSPRUNG_LEVEL_SALT} -ne 64 ]; then
  echo "Error: WHEELSPRUNG_LEVEL_SALT must be 64 characters long."
  exit 1
fi

## only print the first 7 characters of the salt for security reasons
echo "level salt run_updater ${WHEELSPRUNG_LEVEL_SALT:0:7}"

nim c -d:useHostOS -r "./scripts/level_hash_updater/update_level_hashes.nim"