#!/bin/bash

# Get Game name from pdxinfo and remove whitespace and lowercase. pdutil cannot run files with whitespace in them
# PRODUCT="$(cat source/pdxinfo | grep name | cut -d "=" -f 2- | sed '/^$/d;s/[[:blank:]]//g' | tr '[:upper:]' '[:lower:]')"

# For nim, the name of the root folder is used as pdx name
# Get the name of the current working directory
PRODUCT="$(basename "$(pwd)")"

echo "PRODUCT ${PRODUCT}"
DEVICE_PDX="${PRODUCT}_device.pdx"

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