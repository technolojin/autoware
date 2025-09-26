#!/bin/bash -e
# cspell: ignore unhold nsight prerm

for package_prefix in "$@"; do
    dpkg_output1=$(dpkg -l | grep "^ii  ${package_prefix}" | awk '{print $2}')
    dpkg_output2=$(dpkg -l | grep "^hi  ${package_prefix}" | awk '{print $2}')
    # Merge the two variables, sort, and remove duplicates
    dpkg_output=$(echo "$dpkg_output1" "$dpkg_output2" | tr ' ' '\n' | sort -u)

    if [ -n "$dpkg_output" ]; then
        echo "$dpkg_output" | while IFS= read -r full_name; do
            version_name1=$(dpkg -l | grep "^ii  ${full_name}\s" | awk '{print $3}')
            version_name2=$(dpkg -l | grep "^hi  ${full_name}\s" | awk '{print $3}')

            if [ -n "$version_name1" ]; then
                version_name="$version_name1"
            elif [ -n "$version_name2" ]; then
                version_name="$version_name2"
            else
                continue
            fi

            # You can now use the version_name variable
            echo "The version is: $version_name"

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

            base_dir=/home/autoware/deb-temp
            mkdir -p "$base_dir"
            temp_build_dir=$(mktemp -d "${base_dir}/${dummy_foldername}.XXXXXX")

            output_dir="${base_dir}/output"
            sudo mkdir -p "${output_dir}"

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
            } | sudo tee DEBIAN/control >/dev/null

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
