## Syncs levels from the source/levels to the simulator's data folder,
## which allows a running game to access them

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="$SCRIPT_DIR/../source/levels"
DEST_DIR="$HOME/Developer/PlaydateSDK/Disk/Data/com.ninovanhooff.wheelsprung"
alias run_rsync='rsync -azP --exclude ".*/" --exclude ".*" --exclude "tmp/" $SOURCE_DIR $DEST_DIR'
alias run_level_updater="$SCRIPT_DIR/run_level_updater.sh"
alias compile_images="$SCRIPT_DIR/compile_images.sh"

run_rsync
run_level_updater
compile_images

fswatch -o "$SOURCE_DIR" | while read -r f; do
  run_rsync
  run_level_updater
  compile_images
done