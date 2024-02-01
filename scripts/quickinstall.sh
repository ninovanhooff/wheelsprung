#!/bin/bash

# Get Game name from pdxinfo and remove whitespace. pdutil cannot run files with whitespace in them
PRODUCT="$(cat source/pdxinfo | grep name | cut -d "=" -f 2- | sed '/^$/d;s/[[:blank:]]//g')"
echo "PRODUCT ${PRODUCT}"
DEVICE_PDX = "${PRODUCT}_device.pdx"

# Put device in data disk mode
until ls /dev/cu.usbmodemPD*
do
  echo "Playdate not found. Is it connected to USB and unlocked?"
  sleep 1
done
PDUTIL_DEVICE="$(ls /dev/cu.usbmodemPD* | head -n 1)"
echo "device $PDUTIL_DEVICE"
pdutil "${PDUTIL_DEVICE}" datadisk

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
done
echo "Usb Device Connected"

# run
echo "Running ${DEVICE_PDX}"
pdutil "${PDUTIL_DEVICE}" run "/Games/${DEVICE_PDX}"