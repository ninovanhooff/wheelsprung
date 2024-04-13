#!/bin/bash

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Get Game name from pdxinfo and remove whitespace and lowercase. pdutil cannot run files with whitespace in them
# PRODUCT="$(cat source/pdxinfo | grep name | cut -d "=" -f 2- | sed '/^$/d;s/[[:blank:]]//g' | tr '[:upper:]' '[:lower:]')"

# For nim, the name of the root folder is used as pdx name
# Get the name of the current working directory
PRODUCT="$(basename "$(pwd)")"

echo "PRODUCT ${PRODUCT}"
DEVICE_PDX="${PRODUCT}_device.pdx"


# Create a PDX file for the device
"$SCRIPT_DIR"/bundle_device.sh "$PRODUCT.pdx" "$DEVICE_PDX"

echo "Waiting for Data Disk to be mounted ... "
until [ -d /Volumes/PLAYDATE/GAMES ]
do
  sleep 1
done
echo "Game Dir mounted"
# #echo "Input anything to continue"
# trap 'tput setaf 1;tput bold;echo $BASH_COMMAND;read;tput init' DEBUG

# Only copy files which changed and are newer than the destination
rsync -zavrti --update --modify-window=1 --prune-empty-dirs "${DEVICE_PDX}" "/Volumes/PLAYDATE/Games/"

# Unmount
MOUNT_DEVICE="$(diskutil list | grep PLAYDATE | grep -oE '[^ ]+$')"
diskutil unmount "${MOUNT_DEVICE}"
diskutil eject PLAYDATE

# Wait for usb command mode connection
echo "Waiting for USB Device to be mounted ... "
until ls "${PDUTIL_DEVICE}"
do
  sleep 1
  PDUTIL_DEVICE="$(ls /dev/cu.usbmodemPD* | head -n 1)"
  echo "device $PDUTIL_DEVICE"
done
echo "Usb Device Connected"

# run
echo "Running ${DEVICE_PDX}"
pdutil "${PDUTIL_DEVICE}" run "/Games/${DEVICE_PDX}"