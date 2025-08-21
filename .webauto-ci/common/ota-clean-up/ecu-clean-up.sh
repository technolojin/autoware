#!/bin/bash -e

: "${ECU_ID:?is not set}"

echo "----- Start to remove unnecessary folders and files ..."
items_to_remove=(
    "/boot/Image.backup"
    "/opt/ros/humble/log"
    "/opt/autoware/tier4-camera-drivers-for-anvil.tar.gz"
    "/root/.cache/pip"
    "/root/pcl"
    "/root/range-v3"
)

for item in "${items_to_remove[@]}"; do
    if [ -e "$item" ]; then
        echo "----- Removing: $item"
        sudo rm -rf "$item"
    else
        echo "----- Did not find: $item"
    fi
done
echo "----- Finished removing  unnecessary folders and files  ..."

# Handle /var/cache/apt/archives separately using apt clean
if [ -d "/var/cache/apt/archives" ]; then
    echo "----- Cleaning APT cache: /var/cache/apt/archives"
    sudo apt clean
else
    echo "----- Did not find APT cache directory: /var/cache/apt/archives"
fi

echo "----- Start to reduce .git folder size ..."
INITIAL_DIR=$(pwd)
echo "----- current folder is $INITIAL_DIR"
find /home/autoware -type d -name ".git" -print0 | while IFS= read -r -d $'\0' git_dir; do
    # Get the parent directory of the .git folder, which is the actual repository root
    repo_root=$(dirname "$git_dir")
    echo "--- Processing Repository: ${repo_root#./} ---"
    (
        # Change to the repository root directory
        cd "$repo_root" || {
            echo "Error: Could not change to directory '$repo_root'. Skipping."
            exit 1
        }
        echo "Running 'git gc --aggressive --prune=now'..."
        # Run the git gc command
        sudo git gc --aggressive --prune=now
    )
    echo ""
done

cd "$INITIAL_DIR"
echo "----- finished reduce .git folder size ..."
