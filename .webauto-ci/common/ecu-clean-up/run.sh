#!/bin/bash -e

# reference
# https://nvidia-ai-iot.github.io/jetson-min-disk/step3.html

# cspell: ignore nsight
# cspell: ignore prerm

# Important: Don't run "apt autoremove" in this script
# See details in https://tier4.atlassian.net/browse/RT4-16721

echo "----- Start to Remove Jetson development packages ..."
dev_packages=(
    "libnvonnxparsers-dev"
    "libnvparsers-dev"
    "libnvinfer-plugin-dev"
    "libnvinfer-dev"
    "libcudnn8-dev"
    "cuda-cudart-dev"
    "cuda-libraries-dev"
    "cuda-nvml-dev"
    "libnpp-dev"
    "libcusparse-dev"
    "libcublas-dev"
    "libnccl-dev"
)

for package_prefix in "${dev_packages[@]}"; do
    full_name=$(dpkg -l | grep "${package_prefix}" | awk '{print $2}')
    if [ -n "$full_name" ]; then
        echo "Found installed package: $package_prefix, package full name is: $full_name"
        sudo -E apt-mark unhold "$full_name"

        echo "Start to remove $full_name"
        sudo -E apt purge -y --allow-change-held-packages "$full_name"
    else
        echo "No installed packages found matching '$package_prefix'."
    fi
done

echo "----- Finished Removing Jetson development packages ..."

echo "----- Start to Remove nsight-system packages ..."
nsight_system_packages=(
    "nvidia-nsight-sys"
    "nsight-system"
)

sudo rm -rf /var/lib/dpkg/info/nsight-system*.prerm

for package_prefix in "${nsight_system_packages[@]}"; do
    while read -r full_name; do
        if [ -n "$full_name" ]; then
            echo "Found installed package: $full_name, start to remove it:"
            sudo -E apt purge -y --allow-change-held-packages "$full_name"
        fi
    done < <(dpkg -l | grep "${package_prefix}" | awk '{print $2}')
done

echo "----- Finished Removing nsight-system packages ..."
