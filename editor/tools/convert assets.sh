#!/bin/bash

# source ~/.bashrc


## A script to process all assets (images, audio, video) in source directory and add them as pdi
# pda, or pdt to the PDX file in the destination directory

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="$SCRIPT_DIR/pd_converter_source"
TEMP_DESTINATION_DIR="$SCRIPT_DIR/pd_converter_output"
TEMP_DESTINATION_DIR_PDX="$TEMP_DESTINATION_DIR.pdx"

INPUT="$1"
echo "Converting $INPUT"

DESTINATION_DIR="$(dirname "$INPUT")"
echo "Parent directory of the input: $PARENT_DIR"

removeDir() {
  if [ -d "$1" ]; then
    rm -rf "$1"
  fi
}

# print the location of the pdc command
echo "PDC command location: $(which pdc)"

if [ ! -e "$INPUT" ]; then
  echo "The specified input does not exist: $INPUT"
  exit 1
fi

if [ -d "$INPUT" ]; then
  echo "$INPUT is a directory."
elif [ -f "$INPUT" ]; then
  echo "$INPUT is a file."
else
  echo "$INPUT is neither a file nor a directory."
  exit 1
fi


# Remove the source directory if it exists
echo "Removing the temp source directory"
removeDir "$SOURCE_DIR"

# Create the source directory
echo "Creating the temp source directory"
mkdir -p "$SOURCE_DIR"

# Remove the destination directory if it exists
echo "Removing the temp output directory"
removeDir "$TEMP_DESTINATION_DIR"

# # Create the destination directory
# echo "Creating the temp output directory"
# mkdir -p "$TEMP_DESTINATION_DIR_PDX"

# Create an empty file "temp.lua" in the source directory
echo "Creating an empty file temp.lua in the source directory"
touch "$SOURCE_DIR/main.lua"

# copy the input file to the source directory
echo "Copying the input file to the temp source directory"
cp -r "$INPUT" "$SOURCE_DIR"


pdc -v -k "$SOURCE_DIR" "$TEMP_DESTINATION_DIR_PDX"

# Remove the source directory
echo "Removing the temp source directory"
removeDir "$SOURCE_DIR"

#remove .pdx from the output directory name
mv "$TEMP_DESTINATION_DIR_PDX" "$TEMP_DESTINATION_DIR"
rm "$TEMP_DESTINATION_DIR/main.pdz"
rm "$TEMP_DESTINATION_DIR/pdxinfo"

if [ -f "$INPUT" ]; then
  # we know this will be 1 file
  mv "$TEMP_DESTINATION_DIR"/* "$DESTINATION_DIR" || { echo "Failed to move files"; exit 1; }
else
  # we know this will be a directory
  cp -r $TEMP_DESTINATION_DIR/* "$DESTINATION_DIR" || { echo "Failed to move files"; exit 1; }
fi

echo "Removing the temp output directory"
rm -rf "$TEMP_DESTINATION_DIR"

echo "DONE"



# printf "0 $0 1 $1 SCRIPT DIR $SCRIPT_DIR SOURCE DIR $SOURCE_DIR\n\n"



