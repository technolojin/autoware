#!/bin/bash

: "${WEBAUTO_CI_DEBUG_BUILD:?is not set}"
: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${CCACHE_DIR:=}"
: "${CCACHE_SIZE:=1G}"
: "${PARALLEL_WORKERS:=4}"

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)

sudo -E apt-get -y update

pip install pyopenssl --upgrade

if [ -n "$CCACHE_DIR" ]; then
    mkdir -p "$CCACHE_DIR"
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    export CC="/usr/lib/ccache/gcc"
    export CXX="/usr/lib/ccache/g++"
    ccache -M "$CCACHE_SIZE"
fi

[[ $WEBAUTO_CI_DEBUG_BUILD == "true" ]] && build_type="RelWithDebInfo" || build_type="Release"

sudo -E apt-get -y install python3-vcs2l
mkdir -p src

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global url."https://github.com/".insteadOf "git@github.com:"
# shellcheck disable=SC2016
git config --global credential."https://github.com".helper '!f() { echo "username=x-access-token"; echo "password=${GITHUB_TOKEN}"; }; f'

# Cloning repositories
# Not using --shallow option here:
# vcs export fails for shallow cloned and SHA-pinned repositories
./repos-filter.sh autoware.repos common perception | vcs import src
echo "--- exact.repos ---"
vcs export src --exact
echo "--- end of exact.repos ---"

git config --global --unset credential."https://github.com".helper
git config --global --unset url."https://github.com/".insteadOf

# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"

rosdep update
rosdep install --from-paths src --ignore-src -r -y --rosdistro "${ROS_DISTRO}"

colcon build \
    --symlink-install --allow-overriding image_view --cmake-force-configure \
    --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCMAKE_CXX_FLAGS="-w" -DCMAKE_CUDA_STANDARD=14 -DCMAKE_CUDA_ARCHITECTURES=87 -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc -DBUILD_TESTING=OFF \
    -DPython3_EXECUTABLE="$(which python3)" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    --executor parallel \
    --parallel-workers "$PARALLEL_WORKERS" \
    --packages-up-to edge_auto_jetson_launch autoware_diagnostics_bridge autoware_system_monitor
