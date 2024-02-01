#!/bin/bash

# Define the source and destination directories
source_dir="$1"
destination_dir="$2"

echo "Bundle device PDX from source_dir ${source_dir} to destination_dir ${destination_dir}"

rsync -avrti --delete --prune-empty-dirs --exclude="*.dylib" --exclude="*.dSYM" "$source_dir/" "$destination_dir"
