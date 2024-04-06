#!/bin/bash

# Put device in data disk mode. 
# Does not wait for mounting, but waits for the device to be connected
# Do this first because it takes many seconds. We can compile while mounting

# first, check if the device is already in data disk mode
if [ -e /Volumes/PLAYDATE ]; then
  echo "Playdate is already in data disk mode"
  exit 0
fi

until ls /dev/cu.usbmodemPD*
do
  echo "Playdate not found. Is it connected to USB and unlocked?"
  sleep 1
done
PDUTIL_DEVICE="$(ls /dev/cu.usbmodemPD* | head -n 1)"
echo "device $PDUTIL_DEVICE"
pdutil "${PDUTIL_DEVICE}" datadisk
