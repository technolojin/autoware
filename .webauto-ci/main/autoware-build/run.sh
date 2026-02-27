#!/bin/bash -e

: "${WEBAUTO_CI_DEBUG_BUILD:?is not set}"
: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${BUILD_LABELS:?is not set}" # space-separated labels to filter repositories for build
: "${CCACHE_DIR:=}"
: "${CCACHE_SIZE:=1G}"
: "${PARALLEL_WORKERS:=4}"

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)

SAVED_WORKING_DIR="$(pwd)" # should be identical to AUTOWARE_PATH

# CARET build
if [ "$WEBAUTO_CI_BUILD_OPTION_CARET_ENABLED" = "ENABLED" ]; then
    # TODO: Use proper version management
    echo "CARET ENABLED"

    cd "$HOME"
    rm -rf ros2_caret_ws

    # download CARET
    echo "===== GET CARET ====="
    CARET_VERSION="rc/v0.5.11-for-evaluator-agnocast-support"
    git clone https://github.com/tier4/caret.git ros2_caret_ws
    cd ros2_caret_ws
    git checkout "$CARET_VERSION"

    # setup CARET
    echo "===== Setup CARET ====="
    mkdir -p src
    vcs import src --shallow <caret.repos
    # shellcheck disable=SC1090
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
    ./setup_caret.sh -c

    # build caret
    echo "===== Build CARET ====="
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
fi

cd "$SAVED_WORKING_DIR"

if [ -n "$CCACHE_DIR" ]; then
    mkdir -p "$CCACHE_DIR"
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    export CC="/usr/lib/ccache/gcc"
    export CXX="/usr/lib/ccache/g++"
    ccache -M "$CCACHE_SIZE"
fi

echo "===== install xmlschema<4.0.0 before rosdep install as workaround for scenario_simulator_v2 ====="
sudo pip3 install xmlschema==3.4.5

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
# shellcheck disable=SC2086
./repos-filter.sh simulator.repos ${BUILD_LABELS} | vcs import src
# shellcheck disable=SC2086
./repos-filter.sh tools.repos ${BUILD_LABELS} | vcs import src
echo "--- exact.repos ---"
vcs export src --exact
echo "--- end of exact.repos ---"

git config --global --unset credential."https://github.com".helper
git config --global --unset url."https://github.com/".insteadOf

# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
rosdep update
rosdep install -y --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"

# CARET setup
ADDITIONAL_OPTIONS=""
if [ "$WEBAUTO_CI_BUILD_OPTION_CARET_ENABLED" = "ENABLED" ]; then
    echo "===== Modify ament_cmake_auto as workaround ====="
    backup_date="$(date +"%Y%m%d_%H%M%S")"
    cd /opt/ros/humble/share/ament_cmake_auto/cmake &&
        sudo cp ament_auto_add_executable.cmake ament_auto_add_executable.cmake_"$backup_date" &&
        sudo cp ament_auto_add_library.cmake ament_auto_add_library.cmake_"$backup_date" &&
        sudo sed -i -e 's/SYSTEM//g' ament_auto_add_executable.cmake &&
        sudo sed -i -e 's/SYSTEM//g' ament_auto_add_library.cmake

    # cspell: ignore libtracetools
    echo "===== Modify pcl_ros (libtracetools.so) as workaround ====="
    cd /opt/ros/humble/share/pcl_ros/cmake &&
        sudo cp export_pcl_rosExport.cmake export_pcl_rosExport.cmake_"$backup_date" &&
        sudo sed -i -e 's/\/opt\/ros\/humble\/lib\/libtracetools.so;//g' export_pcl_rosExport.cmake

    echo "===== Modify pcl_ros (rclcpp) as workaround ====="
    cd /opt/ros/humble/share/pcl_ros/cmake &&
        sudo cp export_pcl_rosExport.cmake export_pcl_rosExport.cmake_"$backup_date"_2 &&
        sudo sed -i -e 's/\/opt\/ros\/humble\/include\/rclcpp;//g' export_pcl_rosExport.cmake

    cd "$SAVED_WORKING_DIR"
    rm -f caret_topic_filter.bash
    wget https://raw.githubusercontent.com/tier4/caret_report/main/sample_autoware/caret_topic_filter.bash

    # shellcheck disable=SC1090
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
    # shellcheck disable=SC1091
    source "$HOME/ros2_caret_ws/install/local_setup.sh"
    echo "===== Finish CARET SETUP ====="

    ADDITIONAL_OPTIONS="--packages-skip rclcpp rclcpp_action rclcpp_components rclcpp_lifecycle"
fi
cd "$SAVED_WORKING_DIR"

[[ $WEBAUTO_CI_DEBUG_BUILD == "true" ]] && build_type="RelWithDebInfo" || build_type="Release"

# shellcheck disable=SC2086
colcon build \
    --symlink-install \
    --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCMAKE_CXX_FLAGS="-w" -DBUILD_TESTING=off \
    --catkin-skip-building-tests \
    --executor parallel \
    --parallel-workers "$PARALLEL_WORKERS" \
    $ADDITIONAL_OPTIONS

if [ "$WEBAUTO_CI_BUILD_OPTION_CARET_ENABLED" = "ENABLED" ]; then
    echo "===== Check CARET SETUP ====="
    # shellcheck disable=SC1090,SC1091,SC2015
    source "/opt/ros/${ROS_DISTRO}/setup.sh" &&
        source "$HOME/ros2_caret_ws/install/local_setup.sh" &&
        ros2 caret check_caret_rclcpp ./ ||
        (echo "CARET build is failed" && exit 1)
fi
