## Syncs levels from the source/levels to the simulator's data folder,
## which allows a running game to access them

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="$SCRIPT_DIR/../source/levels"
SUPPORT_DIR="$SCRIPT_DIR/../support/levels"
DEST_DIR="$HOME/Developer/PlaydateSDK/Disk/Data/com.ninovanhooff.wheelsprung/levels"
alias run_rsync_images='rsync -azP rsync --include="*/" --include="*.png" --exclude="*"  $SUPPORT_DIR $SOURCE_DIR/..'
alias run_rsync_data='rsync -azP --exclude ".*/" --exclude ".*" --exclude "tmp/" $SOURCE_DIR $DEST_DIR/..'
alias run_level_updater="$SCRIPT_DIR/run_level_updater.sh"
alias compile_images="$SCRIPT_DIR/compile_images.sh"

sync_and_update() {
  # convert wmj to flatty and update the flatty level hashes
  run_level_updater
  # sync the source level images (png) from the support to the source folder
  run_rsync_images
  # compile the images (png -> pdi) and put them in the pdx file
  compile_images
  # sync the flatty levels to the simulator data folder
  run_rsync_data
}

sync_and_update

fswatch -o "$SUPPORT_DIR" | while read -r f; do
  sync_and_update
done