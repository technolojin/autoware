#!/bin/bash -e

# Check required environment variables.
: "${WEBAUTO_CI_SOURCE_PATH:?is not set}"

# Set workspace path.
WORKSPACE_PATH="/tmp/workspace"

# Set ROS environment variables.
export ROS_VERSION=2
export ROS_PYTHON_VERSION=3
export ROS_DISTRO=humble

# Create workspace directory.
mkdir -p "${WORKSPACE_PATH}"
cd "${WORKSPACE_PATH}"
cp "${WEBAUTO_CI_SOURCE_PATH}/docker-multi-stage/docker-bake-main.hcl" "${WORKSPACE_PATH}/docker-bake-main.hcl"
cp "${WEBAUTO_CI_SOURCE_PATH}/docker-multi-stage/context" "${WORKSPACE_PATH}/context" -r

# Install apt packages
apt-get update && apt-get install -y --no-install-recommends ca-certificates curl apt-transport-https lsb-release

# Setup ROS apt source
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -sSL -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
apt-get install /tmp/ros2-apt-source.deb
rm -f /tmp/ros2-apt-source.deb

# Install colcon and rosdep
apt-get update && apt-get install -y --no-install-recommends python3-colcon-common-extensions python3-rosdep
rosdep init && rosdep update

# Register AutonomouStuff repository
sh -c 'echo "deb [trusted=yes] https://s3.amazonaws.com/autonomoustuff-repo/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/autonomoustuff-public.list'
sh -c 'echo "yaml https://s3.amazonaws.com/autonomoustuff-repo/autonomoustuff-public-${ROS_DISTRO}.yaml ${ROS_DISTRO}" > /etc/ros/rosdep/sources.list.d/40-autonomoustuff-public-${ROS_DISTRO}.list'
apt-get update && rosdep update

# Build docker images
bash "${WEBAUTO_CI_SOURCE_PATH}/docker-multi-stage/build-main.bash" evaluation --yes --use-ghcr --ros-distro "${ROS_DISTRO}" --context-dir "${WORKSPACE_PATH}/context" --vcs-src-dir "${WEBAUTO_CI_SOURCE_PATH}/src"
