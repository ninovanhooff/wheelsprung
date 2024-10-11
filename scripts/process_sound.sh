#!/bin/bash

# Set the input and output directories
input_dir="support/sounds/thud"
output_dir="source/audio/thud"

echo "Additional arg passed to adpcm-xq: $1"

# Loop through each wav file in the input directory
for file in "$input_dir"/*.wav; do
  # Get the filename
  filename=$(basename "$file")
  
  # Call the adpcm-xq program with the input and output filenames
  adpcm-xq -e "$1" "$file" "$output_dir/$filename"
done
