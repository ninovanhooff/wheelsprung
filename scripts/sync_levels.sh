## Syncs levels from the source/levels to the simulator's data folder,
## which allows a running game to access them

# Get the absolute path of the directory containing the current file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SOURCE_DIR="$SCRIPT_DIR/../source/levels"
DEST_DIR="$HOME/Developer/PlaydateSDK/Disk/Data/com.ninovanhooff.wheelsprung"
alias run_rsync='rsync -azP --exclude ".*/" --exclude ".*" --exclude "tmp/" $SOURCE_DIR $DEST_DIR'
run_rsync; fswatch -o $SOURCE_DIR | while read f; do run_rsync; done