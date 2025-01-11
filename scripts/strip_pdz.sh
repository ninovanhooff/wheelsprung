#!/bin/bash

# NOTE this script must be called with a preceding "." to set the environment variables in the current shell
# e.g. ". scripts/set_release_env.sh"
# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE_DIR="$SCRIPT_DIR/.."

# For nim, the name of the root folder is used as pdx name
# Get the name of the current working directory
PRODUCT="$(basename "$(pwd)")"

echo "PRODUCT ${PRODUCT}"
SIM_PDX_PATH="${WORKSPACE_DIR}/${PRODUCT}.pdx"
echo "SIM_PDX_PATH ${SIM_PDX_PATH}"
DEVICE_PDX="${PRODUCT}_device.pdx"
echo "DEVICE_PDX ${DEVICE_PDX}"
DEVICE_PDX_PATH="${WORKSPACE_DIR}/${DEVICE_PDX}"
echo "DEVICE_PDX_PATH ${DEVICE_PDX_PATH}"

strip_pdz() {
  local dir_path="$1"
  # both of these directories are included in panelsLoader.pdz
  rm -rf "${dir_path}/libraries/panels/modules"
  rm -rf "${dir_path}/comicData"
}

echo "Stripping pdz files..."
strip_pdz "${SIM_PDX_PATH}"
strip_pdz "${DEVICE_PDX_PATH}"
echo "Done stripping pdz files"

