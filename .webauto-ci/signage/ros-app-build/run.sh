#!/bin/bash

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${BUILD_LABELS:?is not set}" # space-separated labels to filter repositories for build
: "${PARALLEL_WORKERS:=4}"

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)

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

# each chunks will be passed as separate argument
# shellcheck disable=SC2086
./repos-filter.sh autoware.repos ${BUILD_LABELS} | vcs import src
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
    --symlink-install \
    --executor parallel \
    --parallel-workers "$PARALLEL_WORKERS"
