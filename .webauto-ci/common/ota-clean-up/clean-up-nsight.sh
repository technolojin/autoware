#!/bin/bash -e
# cspell: ignore nsight webauto

echo "----- Start to remove nsight packages ..."
nsight_packages=(
    "nsight-compute"
    "nsight-system"
    "nsight-graphics"
)

packages_to_remove=()
packages_to_remove+=("${nsight_packages[@]}")

# remove the listed packages here
echo "Current working directory is: $(pwd)"
. .webauto-ci/common/ota-clean-up/package-processor.sh "${packages_to_remove[@]}"
