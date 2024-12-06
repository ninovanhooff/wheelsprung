#!/bin/bash

echo "Additional arg passed to adpcm-xq: $1"

process_sounds() {
  local input_dir="$1"
  local output_dir="$2"
  local additional_arg="$3"

  # Loop through each wav file in the input directory
  for file in "$input_dir"/*.wav; do
    # Get the filename
    filename=$(basename "$file")
    
    # Call the adpcm-xq program with the input and output filenames
    adpcm-xq -e "$additional_arg" "$file" "$output_dir/$filename"
  done
}

# Call the function with the specified input and output directories
# process_sounds "support/sounds/thud" "source/audio/thud" "$1"
# process_sounds "support/sounds/star" "source/audio/pickup" "$1"
# process_sounds "support/sounds/thud" "source/audio/thud" "$1"
# process_sounds "support/sounds/star" "source/audio/pickup" "$1"
# process_sounds "support/sounds/coin" "source/audio/pickup" "$1"
# process_sounds "support/sounds/fall" "source/audio/fall" "$1"
# process_sounds "support/sounds/collision" "source/audio/collision" "$1"
# process_sounds "support/sounds/finish" "source/audio/finish" "$1"
# process_sounds "support/sounds/gravity" "source/audio/gravity" "$1"

# when uncommenting make sure no doubles wav files for music that is used as mpe)
#process_sounds "support/music" "source/audio/music" "$1"
