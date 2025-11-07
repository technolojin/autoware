#!/bin/bash
# Purpose:
# This script creates symbolic links from source package files to the `install/share` directories,
# allowing updates to configuration and launch files without rebuilding the ROS workspace.
#
# Background:
# When using `colcon build --merge-install`, it is necessary to rebuild the workspace every time
# a launch or configuration file is modified. This process is time-consuming and prone to human error
# such as forgetting to rebuild. In addition, Git cannot track changes made in the
# `install/share` directories.
#
# Usage:
# ./apply_symlink.sh
#
# Description:
# - Replaces files in `install/share/<package>/{launch,config}/` with symbolic links
#   pointing to the original source files
# - Processes only the packages specified in `REPLACE_PKG_LIST`
# - Processes only the directories specified in `TARGET_DIRS`

TARGET_DIRS=("launch" "config")
REPLACE_PKG_LIST=("individual_params" "autoware_launch")

SCRIPT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

cd "$SCRIPT_DIR" || exit
cd ../

install_share=./install/share

declare -A pkg_map # name → path

# get package names and paths
while read -r name path _; do
    pkg_map["$name"]="$path"
done < <(colcon list --base-paths ./src --paths)

# replace symbolic links in install/share
for pkg in "${!pkg_map[@]}"; do

    if [[ ! ${REPLACE_PKG_LIST[*]} =~ ${pkg} ]]; then
        continue
    fi

    install_pkg_dir="$install_share/$pkg"

    # check if package directory exists in install/share
    if [ -d "$install_pkg_dir" ]; then
        real_path=$(realpath "${pkg_map[$pkg]}")
        rel_path="${pkg_map[$pkg]}"

        # replace symbolic links for target directories
        for dir in "${TARGET_DIRS[@]}"; do

            if [ -d "$install_pkg_dir/$dir" ] && [ -d "$real_path/$dir" ]; then
                rm -rf "${install_pkg_dir:?}/${dir:?}"/*
                find "$rel_path/$dir" -type f | while read -r src_file; do
                    original_file_path="$(realpath "$src_file")"

                    # get relative path of src_file with respect to rel_path
                    rel_subpath="${src_file#"${rel_path}"/}"
                    dest_path="$install_pkg_dir/$rel_subpath"

                    # create the same directory structure
                    mkdir -p "$(dirname "$dest_path")"

                    # Create symbolic link
                    ln -sf "$original_file_path" "$dest_path"
                done
            fi
        done
    fi
done
