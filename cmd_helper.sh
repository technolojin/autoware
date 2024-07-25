#!/bin/bash
set -eu

# Get the location where this script is saved
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Set Environment Variables when not sourced
if [ "${VEHICLE_MODEL:-false}" ]; then
    export VEHICLE_MODEL=j6_gen2
fi

if [ "${SENSOR_MODEL:-false}" ]; then
    export SENSOR_MODEL=aip_x2_gen2
fi

# --rosdep:        rosdep update and install
function rosdep_update() {
    rosdep update && rosdep install -y --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"
}

# --build:        Normal build
function build() {
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release "$@"
}

# --build_ccache: Build with ccache
function build_ccache() {
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache "$@"
}

# --autoware:     Launch autoware
function launch_autoware() {
    ros2 launch autoware_launch autoware.launch.xml map_path:=/opt/autoware/maps lanelet2_map_file:=lanelet2_map.osm pointcloud_map_file:=pcd vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --psim:         Launch simple planning simulator
function launch_psim() {
    ros2 launch autoware_launch planning_simulator.launch.xml map_path:=/opt/autoware/maps lanelet2_map_file:=lanelet2_map.osm pointcloud_map_file:=pcd vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --kill:         Kill all ros2 zombie nodes
function kill_zombie() {
    pgrep -a -f ros | grep -v Microsoft | grep -v ros2_daemon | awk '{ print "kill -9", $1 }' | sh
}

# --clean:        Delete '/install', '/build' and '/log' directories
function clean() {
    rm -rf "${SCRIPT_DIR}"/install "${SCRIPT_DIR}"/build "${SCRIPT_DIR}"/log
}

function help() {
    echo "Usage: ${0##\*/} [arg]"
    echo
    echo "    --rosdep          :execute rosdep install and install command"
    echo "    --build           :Normal build  {You can add additional build options after the arg}"
    echo "    --build_ccache    :Build with ccache {You can add additional build options after the arg}"
    echo "    --autoware        :Launch autoware"
    echo "    --psim            :Launch simple planning simulator"
    echo "    --kill            :Kill all ros2 zombie nodes"
    echo "    --clean           :Delete '/install', '/build' and '/log' directories"
    echo "    --help or -h      :Display this help message"
    exit 0 #default exit code
}

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    help "$@"
elif [ "${1-}" = "--rosdep" ]; then
    rosdep_update
elif [ "${1-}" = "--build" ]; then
    build "${@:2}"
elif [ "${1-}" = "--build_ccache" ]; then
    build_ccache "${@:2}"
elif [ "${1-}" = "--autoware" ]; then
    launch_autoware "${@:2}"
elif [ "${1-}" = "--psim" ]; then
    launch_psim "${@:2}"
elif [ "${1-}" = "--kill" ]; then
    kill_zombie
elif [ "${1-}" = "--clean" ]; then
    clean
else
    echo "please pass the correct arguments! Use '-h' or '--help' command if you check the arguments"
fi
