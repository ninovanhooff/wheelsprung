#!/bin/bash

# bundle a simulator build without levels for level editor testing

# For nim, the name of the root folder is used as pdx name
# Get the name of the current working directory
PRODUCT="$(basename "$(pwd)")"

# Define the source and destination directories
source_dir="${PRODUCT}.pdx"
destination_dir="${PRODUCT}_nolevels.pdx"

echo "Bundle simulator PDX without levels from source_dir ${source_dir} to destination_dir ${destination_dir}"

rsync -avrti --delete --prune-empty-dirs --exclude="levels" "$source_dir/" "$destination_dir"

# Remove the existing zip file if it exists
# this is done because the zip command will append to the existing zip file
# and we want to create a new zip file
rm -f "${destination_dir}.zip"
# zip the destination directory
zip -r "${destination_dir}.zip" "$destination_dir"