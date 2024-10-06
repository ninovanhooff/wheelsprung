#!/bin/bash

# NOTE this script must be called with a preceding "." to set the environment variables in the current shell
# e.g. ". scripts/set_release_env.sh"
# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Load release env variables
set -o allexport
source "$SCRIPT_DIR/../release.env"

