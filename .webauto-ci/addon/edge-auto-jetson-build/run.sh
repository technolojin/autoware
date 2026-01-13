#!/bin/bash

: "${WEBAUTO_CI_SOURCE_PATH:?is not set}"
: "${WEBAUTO_CI_DEBUG_BUILD:?is not set}"

: "${AUTOWARE_PATH:?is not set}"
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

# For incremental builds, the source files used in previous builds are already in place.
# Delete any files that have been removed from the new source, except for files specified in .gitignore.
# Also, to take advantage of incremental builds, preserve the timestamps of files with the same checksum.
src=$(mktemp -p /tmp -d src.XXXXX)
cp -rfT "$WEBAUTO_CI_SOURCE_PATH" "$src"
# shellcheck disable=SC2016
find "$src" -name '.gitignore' -printf '%P\0' | xargs -0 -I {} sh -c "sed -n "'s/^!//gp'" $src/{} > $src/"'$(dirname {})'"/.rsync-include"
# shellcheck disable=SC2016
find "$src" -name '.gitignore' -printf '%P\0' | xargs -0 -I {} sh -c "sed -n "'/^[^!]/p'" $src/{} > $src/"'$(dirname {})'"/.rsync-exclude"
rsync -rlpc -f":+ .rsync-include" -f":- .rsync-exclude" --del "$src"/ "$AUTOWARE_PATH"
# The `src` directory is excluded from the root .gitignore and must be synchronized separately.
rsync -rlpc -f":+ .rsync-include" -f":- .rsync-exclude" --del "$src"/src/ "$AUTOWARE_PATH"/src
# `.rsync-include` and `.rsync-exclude` must be included in the output of this phase for reference in the next incremental build.
# These files are removed in the ecu-system-setup phase.
#find "$AUTOWARE_PATH" \( -name ".rsync-include" -or -name ".rsync-exclude" \) -print0 | xargs -0 rm
rm -rf "$src"

chmod 755 "$AUTOWARE_PATH"
cd "$AUTOWARE_PATH" || exit 1

if [ -n "$CCACHE_DIR" ]; then
    mkdir -p "$CCACHE_DIR"
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    export CC="/usr/lib/ccache/gcc"
    export CXX="/usr/lib/ccache/g++"
    ccache -M "$CCACHE_SIZE"
fi

[[ $WEBAUTO_CI_DEBUG_BUILD == "true" ]] && build_type="RelWithDebInfo" || build_type="Release"

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
    --continue-on-error --cmake-clean-cache \
    --packages-up-to edge_auto_jetson_launch sxpf autoware_diagnostics_bridge autoware_system_monitor
