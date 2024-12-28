#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
set -e

# WIP

# cd to the panels repo
cd "${SCRIPT_DIR}/../../wheelsprung-panels"

# Perhaps delete the subtrees


# recreate the subtrees
# echo "Splitting subtree for comicData..."
git subtree split --prefix=source/comicData -b subtree-comicdata 
echo "Subtree for comicData split into branch 'subtree-comicdata'"
# git subtree split --prefix=source/images/cutscenes -b subtree-images

# cd back to the nim repo
echo "Pulling subtrees..."
cd "${SCRIPT_DIR}/.."

# pull the subtrees
git subtree pull --prefix=source/comicData wheelsprung-panels subtree-comicdata
git subtree pull --prefix=source/images/cutscenes wheelsprung-panels subtree-images
