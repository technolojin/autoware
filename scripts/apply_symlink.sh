#!/bin/bash

SCRIPT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

cd "$SCRIPT_DIR" || exit
cd ../

install_share=./install/share
TARGET_DIRS=("launch" "config")

REPLACE_PKG_LIST=("individual_params" "autoware_launch")

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
                    file_name="$(basename "$original_file_path")"
                    # echo $original_file_path $file_name
                    ln -sf "$original_file_path" "$install_pkg_dir/$dir/$file_name"
                done
            fi
        done
    fi
done
