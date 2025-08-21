#!/bin/bash -e
# cspell: ignore nsight yaru gargi gubbi gujr gujr kacst kacst kalapi khmeros knda lklug sinhala lohit lohit lohit lohit gujr lohit knda mlym orya taml taml telu mlym nakula navilu opensymbol freefont
# cspell: ignore orya orya pagul sahadeva samyak samyak gujr samyak mlym samyak taml sarai abyssinica anjalioldlipi chilanka dyuthi gayathri karumbi keraleeyam manjari meera rachana raghumalayalamsans
# cspell: ignore suruma uroob taml telu telu tlwg tlwg garuda tlwg garuda tlwg kinnari tlwg kinnari laksaman laksaman loma loma norasi norasi purisa purisa sawasdee sawasdee umpush umpush waree waree
# cspell: ignore yrsa rasa hidpi adwaita xcursor prerm venvs

: "${ECU_ID:?is not set}"

echo "----- Start to remove unnecessary packages ..."
nsight_packages=(
    "nsight-compute"
    "nsight-system"
    "nsight-graphics"
)

example_packages=(
    "cuda-samples"
    "libcudnn8-samples"
    "libnvinfer-samples"
    "nvidia-l4t-vulkan-sc-samples"
    "vpi2-samples"
    "vpi3-samples"
)

demo_packages=(
    "nvidia-l4t-graphics-demos"
    "vpi2-demos"
)

ubuntu_desktop_packages=(
    "firefox"
    "gnome-calculator"
    "gnome-calendar"
    "gnome-getting-started-docs"
    "gnome-mahjongg"
    "gnome-menus"
    "gnome-mines"
    "gnome-online-accounts"
    "gnome-power-manager"
    "gnome-sudoku"
    "gnome-screenshot"
    "gnome-todo"
    "gnome-todo-common"
    "gnome-user-docs"
    "gnome-user-guide"
    "gnome-weather"
    "gnome-video-effects"
    "ubuntu-docs"
    "ubuntu-wallpapers"
)

font_packages=(
    "fonts-beng"
    "fonts-beng-extra"
    "fonts-deva"
    "fonts-deva-extra"
    "fonts-droid-fallback"
    "fonts-freefont-ttf"
    "fonts-gargi"
    "fonts-gubbi"
    "fonts-gujr"
    "fonts-gujr-extra"
    "fonts-guru"
    "fonts-guru-extra"
    "fonts-indic"
    "fonts-kacst"
    "fonts-kacst-one"
    "fonts-kalapi"
    "fonts-khmeros-core"
    "fonts-knda"
    "fonts-lao"
    "fonts-liberation"
    "fonts-liberation2"
    "fonts-lklug-sinhala"
    "fonts-lohit-beng-assamese"
    "fonts-lohit-beng-bengali"
    "fonts-lohit-deva"
    "fonts-lohit-gujr"
    "fonts-lohit-guru"
    "fonts-lohit-knda"
    "fonts-lohit-mlym"
    "fonts-lohit-orya"
    "fonts-lohit-taml"
    "fonts-lohit-taml-classical"
    "fonts-lohit-telu"
    "fonts-lyx"
    "fonts-mlym"
    "fonts-nakula"
    "fonts-navilu"
    # "fonts-noto-cjk"
    # "fonts-noto-color-emoji"
    # "fonts-noto-mono"
    "fonts-opensymbol"
    "fonts-orya"
    "fonts-orya-extra"
    "fonts-pagul"
    "fonts-sahadeva"
    "fonts-samyak-deva"
    "fonts-samyak-gujr"
    "fonts-samyak-mlym"
    "fonts-samyak-taml"
    "fonts-sarai"
    "fonts-sil-abyssinica"
    "fonts-sil-padauk"
    "fonts-smc"
    "fonts-smc-anjalioldlipi"
    "fonts-smc-chilanka"
    "fonts-smc-dyuthi"
    "fonts-smc-gayathri"
    "fonts-smc-karumbi"
    "fonts-smc-keraleeyam"
    "fonts-smc-manjari"
    "fonts-smc-meera"
    "fonts-smc-rachana"
    "fonts-smc-raghumalayalamsans"
    "fonts-smc-suruma"
    "fonts-smc-uroob"
    "fonts-taml"
    "fonts-telu"
    "fonts-telu-extra"
    "fonts-thai-tlwg"
    "fonts-tibetan-machine"
    "fonts-tlwg-garuda"
    "fonts-tlwg-garuda-ttf"
    "fonts-tlwg-kinnari"
    "fonts-tlwg-kinnari-ttf"
    "fonts-tlwg-laksaman"
    "fonts-tlwg-laksaman-ttf"
    "fonts-tlwg-loma"
    "fonts-tlwg-loma-ttf"
    "fonts-tlwg-mono"
    "fonts-tlwg-mono-ttf"
    "fonts-tlwg-norasi"
    "fonts-tlwg-norasi-ttf"
    "fonts-tlwg-purisa"
    "fonts-tlwg-purisa-ttf"
    "fonts-tlwg-sawasdee"
    "fonts-tlwg-sawasdee-ttf"
    "fonts-tlwg-typewriter"
    "fonts-tlwg-typewriter-ttf"
    "fonts-tlwg-typist"
    "fonts-tlwg-typist-ttf"
    "fonts-tlwg-typo"
    "fonts-tlwg-typo-ttf"
    "fonts-tlwg-umpush"
    "fonts-tlwg-umpush-ttf"
    "fonts-tlwg-waree"
    "fonts-tlwg-waree-ttf"
    # "fonts-ubuntu"
    "fonts-urw-base35"
    "fonts-yrsa-rasa"
)

icons_packages=(
    "apt-config-icons"
    "apt-config-icons-hidpi"
    "adwaita-icon-theme"
    "hicolor-icon-theme"
    "humanity-icon-theme"
    "sound-icons"
    # "tango-icon-theme"
    "yaru-theme-icon"
)

theme_packages=(
    "dmz-cursor-theme"
    "xcursor-themes"
    "gnome-accessibility-themes"
    "yaru-theme-gnome-shell"
    "yaru-theme-gtk"
    "yaru-theme-sound"
)

packages_to_remove=()
packages_to_remove+=("${nsight_packages[@]}")
packages_to_remove+=("${example_packages[@]}")
packages_to_remove+=("${demo_packages[@]}")
packages_to_remove+=("${ubuntu_desktop_packages[@]}")
packages_to_remove+=("${font_packages[@]}")
packages_to_remove+=("${icons_packages[@]}")
packages_to_remove+=("${theme_packages[@]}")

for package_prefix in "${packages_to_remove[@]}"; do
    dpkg_output=$(dpkg -l | grep "^ii  ${package_prefix}" | awk '{print $2}')

    if [ -n "$dpkg_output" ]; then
        echo "$dpkg_output" | while IFS= read -r full_name; do
            version_name=$(dpkg -l | grep "^ii  ${full_name}\s" | awk '{print $3}')
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
        done
    else
        echo "No installed packages found matching '$package_prefix'."
    fi
done

#step 6: resolve dependencies with apt
sudo -E apt update
sudo -E apt --fix-broken install -y
echo "----- Finished removing unnecessary packages ..."

echo "----- Start to remove unnecessary folders and files ..."
items_to_remove=(
    "/boot/Image.backup"
    "/root/.cache/pip"
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
