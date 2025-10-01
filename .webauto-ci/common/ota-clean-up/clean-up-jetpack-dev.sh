#!/bin/bash -e
# cspell: ignore cuda cupti nvml nvgraph nvrtc libcublas libcudla libcudnn8 libcudnn9 libcufft libcufile libcunit1
# cspell: ignore libcurand libcusolver libcusparse libnpp libnvfatbin libnvinfer libnvonnxparsers libnvparsers jetpack
# cspell: ignore webauto

echo "----- Start to remove Jetpack dev packages ..."
jetpack_dev_packages=(
    "cuda-cupti-dev"
    "cuda-driver-dev"
    "cuda-nvml-dev"
    "cuda-libraries-dev"
    "cuda-nvgraph-dev"
    "cuda-nvrtc-dev"
    "libcublas-dev"
    "libcudla-dev"
    "libcudnn8-dev"
    "libcudnn9-dev"
    "libcufft-dev"
    "libcufile-dev"
    "libcunit1-dev"
    "libcurand-dev"
    "libcusolver-dev"
    "libcusparse-dev"
    "libnpp-dev"
    "libnvfatbin-dev"
    "libnvinfer-dev"
    "libnvinfer-dispatch-dev"
    "libnvinfer-headers-dev"
    "libnvinfer-headers-plugin-dev"
    "libnvinfer-lean-dev"
    "libnvinfer-plugin-dev"
    "libnvinfer-vc-plugin-dev"
    "libnvonnxparsers-dev"
    "libnvparsers-dev"
    "python3-libnvinfer-dev"
    "vpi1-dev"
    "vpi2-dev"
    "vpi3-dev"
)
packages_to_remove=()
packages_to_remove+=("${jetpack_dev_packages[@]}")

# remove the listed packages here
echo "Current working directory is: $(pwd)"
. .webauto-ci/common/ota-clean-up/package-processor.sh "${packages_to_remove[@]}"

#resolve dependencies with apt
# sudo -E apt update
# sudo -E apt --fix-broken install -y
echo "----- Finished removing Jetpack dev packages"
