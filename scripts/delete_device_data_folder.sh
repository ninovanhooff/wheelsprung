#!/bin/bash

# Assumes the Playdate is mounted or being mounted

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$SCRIPT_DIR/.."
PDXINFO_PATH="$ROOT_DIR/source/pdxinfo"
PLAYDATE_DATA_DIR="/Volumes/PLAYDATE/Data"
echo "PDXINFO_PATH ${PDXINFO_PATH}"

# Get bundleId from pdxinfo and use it to build the variable GAME_DATA_DIR
BUNDLE_ID="$(cat $PDXINFO_PATH | grep bundleId | cut -d "=" -f 2- | sed '/^$/d;s/[[:blank:]]//g')"
GAME_DATA_DIR="$PLAYDATE_DATA_DIR/$BUNDLE_ID"
echo "GAME_DATA_DIR ${GAME_DATA_DIR}"



echo "Waiting for Data Disk to be mounted ... "
until [ -d /Volumes/PLAYDATE/Data ]
do
  sleep 1
done
echo "Data Dir mounted"
echo "Removing $GAME_DATA_DIR"
rm -rf "$GAME_DATA_DIR"

echo "Data Dir removed"