#!/bin/bash

# Define the source and destination directories
source_dir="wheelsprung.pdx"
destination_dir="wheelsprung_device.pdx"

rsync -avrti --delete --prune-empty-dirs --exclude="*.dylib" --exclude="*.dSYM" "$source_dir/" "$destination_dir"
