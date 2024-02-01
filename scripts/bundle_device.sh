#!/bin/bash

PRODUCT="$1"

# Define the source and destination directories
source_dir="$PRODUCT.pdx"
destination_dir="$PRODUCT"_device.pdx

echo "Bundle device PDX from source_dir ${source_dir} to destination_dir ${destination_dir}"


rsync -avrti --delete --prune-empty-dirs --exclude="*.dylib" --exclude="*.dSYM" "$source_dir/" "$destination_dir"
