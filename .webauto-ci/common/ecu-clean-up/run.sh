#!/bin/bash -e

# reference
# https://nvidia-ai-iot.github.io/jetson-min-disk/step3.html

# cspell: ignore nsight prerm cupti nvgraph nvrtc libcudla libcufft libcusolver

# Important: Don't run "apt autoremove" in this script
# See details in https://tier4.atlassian.net/browse/RT4-16721

echo "----- Start to remove Jetson *-dev and nsight packages ..."
dev_packages=(
    "cuda-cupti-dev"
    "cuda-driver-dev"
    "cuda-nvml-dev"
    "cuda-libraries-dev"
    "cuda-nvgraph-dev"
    "cuda-nvrtc-dev"
    "libcublas-dev"
    "libcudla-dev"
    "libcudnn8-dev"
    "libcufft-dev"
    "libcurand-dev"
    "libcusolver-dev"
    "libcusparse-dev"
    "libnpp-dev"
    "libnvinfer-dev"
    "libnvinfer-plugin-dev"
    "libnvonnxparsers-dev"
    "libnvparsers-dev"
    "python3-libnvinfer-dev"
    "vpi1-dev"
    "vpi2-dev"
)

nsight_packages=(
    "nsight-system"
)

example_packages=(
    "cuda-samples"
    "libcudnn8-samples"
    "libnvinfer-samples"
    "nvidia-l4t-vulkan-sc-samples"
    "vpi2-samples"
)

demo_packages=(
    "nvidia-l4t-graphics-demos"
    "vpi2-demos"
)

packages_to_remove=()
packages_to_remove+=("${dev_packages[@]}")
packages_to_remove+=("${nsight_packages[@]}")
packages_to_remove+=("${example_packages[@]}")
packages_to_remove+=("${demo_packages[@]}")

for package_prefix in "${packages_to_remove[@]}"; do
    full_name=$(dpkg -l | grep "^ii  ${package_prefix}" | awk '{print $2}')
    version_name=$(dpkg -l | grep "^ii  ${package_prefix}" | awk '{print $3}')

    if [ -n "$full_name" ]; then
        echo ""
        echo "---------  processing : ${full_name}  ${version_name} --------"
        echo "Found installed package: $package_prefix, package full name is: $full_name"
        sudo -E apt-mark unhold "$full_name"

        # Remove the "*-dev" package here.
        # Use "dpkg -r --force-depends "
        # Don't use "apt purge" or "apt remove"! Or additional packages will be removed !

        if [ "$package_prefix" == "nsight-system" ]; then
            sudo rm -rf /var/lib/dpkg/info/nsight-system*.prerm
        fi

        echo "Start to remove $full_name"
        sudo dpkg -r --force-depends "$full_name"

        # Create dummy packages to fix the dependency

        # step 1: setup folders
        # Debian package names cannot contain underscores.
        # Convert underscores to hyphens for the package name
        dummy_package_base_name="${full_name//_/-}"
        dummy_foldername="dummy-${dummy_package_base_name}-package-builder"

        # Create a temporary directory for the dummy package build
        # Using mktemp is safer to avoid conflicts if the script is run multiple times concurrently

        base_dir=/home/autoware/deb_temp
        sudo mkdir $base_dir
        temp_build_dir=$(sudo mktemp -d "${base_dir}/${dummy_foldername}.XXXXXX")

        output_dir="${base_dir}/output"
        sudo mkdir -p ${output_dir}

        # Navigate into the temporary directory
        pushd "$temp_build_dir" >/dev/null # pushd allows returning to previous directory with popd

        sudo mkdir -p DEBIAN # This directory holds control files

        # step 2: create "DEBIAN/control" file for build
        dummy_package_name="dummy-package-${dummy_package_base_name}"
        dummy_version="99.0.0-1"

        # Use printf to write to the control file.
        # The 'Provides' field should not have a literal '\n' at the end of its value.
        {
            printf "Package: %s\n" "${dummy_package_name}"
            printf "Version: %s\n" "${dummy_version}"
            printf "Architecture: all\n"
            printf "Maintainer: ota update <dummy_email@email.com>\n"
            printf "Description: Dummy package for %s to resolve dependencies.\n" "${full_name}"
            # Correctly format the Provides line:
            printf "Provides: %s (= %s)\n" "${full_name}" "${version_name}"
            printf "Installed-Size: 1\n"
        } >>DEBIAN/control

        # step 3: build the Dummy .deb Package
        # Pop back to the original directory before building
        popd >/dev/null

        # Define the output .deb file name
        deb_filename="${output_dir}/${dummy_package_name}_${dummy_version}_all.deb"

        echo "Building dummy package: $deb_filename from $temp_build_dir"
        sudo dpkg-deb --build "$temp_build_dir" "$deb_filename"

        # step 4: install the dummy .deb Package
        echo "Installing dummy package: $deb_filename"
        sudo dpkg -i "$deb_filename"

        # step 5: remove all the temp files
        echo "Cleaning up temporary build directory: $temp_build_dir and .deb file: $deb_filename"
        sudo rm -rf "$base_dir"
    else
        echo "No installed packages found matching '$package_prefix'."
    fi
done

# step 6: resolve dependencies with apt
sudo -E apt update
sudo -E apt --fix-broken install -y

echo "----- Finished removing Jetson *-dev and nsight packages ..."

# These are Ubuntu pre-installed packages.
# Their dependency structure are simply.
# We use "apt remove <package name>" to remove them.
echo "----- Start to remove Ubuntu Desktop Packages ..."
ubuntu_desktop_packages=(
    "firefox"
    "gnome-accessibility-themes"
    "gnome-calculator"
    "gnome-calendar"
    "gnome-getting-started-docs"
    "gnome-mahjongg"
    "gnome-sudoku"
    "gnome-todo"
    "gnome-todo-common"
    "gnome-user-docs"
    "gnome-user-guide"
    "gnome-weather"
)

for package_name in "${ubuntu_desktop_packages[@]}"; do
    search_results=$(dpkg -l | grep -E "^ii\\s+${package_name}\\b" | awk '{print $2}')
    if [ -n "$search_results" ]; then
        echo ""
        echo "---------  processing : $package_name --------"
        echo "Start to remove $package_name"
        sudo -E apt remove "$package_name" -y
    else
        echo "No installed packages found matching '$package_name'."
    fi
done
echo "----- Finished removing Ubuntu Desktop Packages ..."

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
