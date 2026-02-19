#!/bin/bash -e

: "${WEBAUTO_CI_DEBUG_BUILD:?is not set}"
: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${CCACHE_DIR:=}"
: "${CCACHE_SIZE:=1G}"
: "${PARALLEL_WORKERS:=4}"

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)

if [ -n "$CCACHE_DIR" ]; then
    mkdir -p "$CCACHE_DIR"
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    export CC="/usr/lib/ccache/gcc"
    export CXX="/usr/lib/ccache/g++"
    ccache -M "$CCACHE_SIZE"
fi

sudo -E apt-get -y update

sudo -E apt-get -y install python3-vcs2l
mkdir -p src

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global url."https://github.com/".insteadOf "git@github.com:"
# shellcheck disable=SC2016
git config --global credential."https://github.com".helper '!f() { echo "username=x-access-token"; echo "password=${GITHUB_TOKEN}"; }; f'

# Cloning repositories
# Not using --shallow option here:
# vcs export fails for shallow cloned and SHA-pinned repositories
vcs import src --recursive <autoware.repos
echo "--- exact.repos ---"
vcs export src --exact
echo "--- end of exact.repos ---"

git config --global --unset credential."https://github.com".helper
git config --global --unset url."https://github.com/".insteadOf

# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
rosdep update
rosdep install -y --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"

[[ $WEBAUTO_CI_DEBUG_BUILD == "true" ]] && build_type="RelWithDebInfo" || build_type="Release"

# shellcheck disable=SC2086
colcon build \
    --symlink-install \
    --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCMAKE_CXX_FLAGS="-w" -DBUILD_TESTING=off \
    --catkin-skip-building-tests \
    --executor parallel \
    --parallel-workers "$PARALLEL_WORKERS"
