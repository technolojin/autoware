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

# --autoware-main:     Launch autoware main
function launch_autoware_main() {
    ros2 launch autoware_launch autoware.main.launch.xml map_path:=/opt/autoware/maps lanelet2_map_file:=lanelet2_map.osm pointcloud_map_file:=pcd vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --autoware-start:     Start autoware services
function start_autoware_service() {
    echo "Starting Autoware services."
    sudo systemctl start autoware_system_launch.service
    sudo systemctl start autoware_launch.service
}

# --autoware-stop:     Stop autoware services
function stop_autoware_service() {
    sudo systemctl stop autoware_system_launch.service
    sudo systemctl stop autoware_launch.service
    echo "Stopped Autoware services."
}

# --autoware-restart:     Restart autoware services
function restart_autoware_service() {
    stop_autoware_service
    sleep 5
    start_autoware_service
    echo "Autoware services restarted."
}

function launch_autoware_main_mrm() {
    ROS_DOMAIN_ID=3 ros2 launch autoware_launch autoware.main.mrm.launch.xml vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --psim-main-mrm:     Launch autoware main mrm with planning simulator
function launch_psim_main_mrm() {
    ROS_DOMAIN_ID=3 ros2 launch autoware_launch autoware.main.mrm.launch.xml is_simulation:="true" vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --psim-main:       Launch autoware main with planning simulator
function launch_psim_main() {
    ros2 launch autoware_launch planning_simulator.main.launch.xml map_path:=/opt/autoware/maps lanelet2_map_file:=lanelet2_map.osm pointcloud_map_file:=pcd vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --autoware-sub: Launch autoware sub
function launch_autoware_sub() {
    ros2 launch autoware_launch autoware.sub.launch.xml vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --psim-sub: Launch autoware sub with planning simulator
function launch_psim_sub() {
    ros2 launch autoware_launch planning_simulator.sub.launch.xml vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --psim:         Launch simple planning simulator
function launch_psim() {
    ros2 launch autoware_launch planning_simulator.launch.xml map_path:=/opt/autoware/maps lanelet2_map_file:=lanelet2_map.osm pointcloud_map_file:=pcd vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" "$@" 2>&1 | tee "$SCRIPT_DIR"/autoware.log
}

# --start_record
function start_record() {
    ros2 service call /api/autoware/set/rosbag_record tier4_external_api_msgs/srv/SetRosbagRecord "record: true"
}

# --stop_record
function stop_record() {
    ros2 service call /api/autoware/set/rosbag_record tier4_external_api_msgs/srv/SetRosbagRecord "record: false"
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
    echo "    --autoware-main    :Launch autoware main"
    echo "    --autoware-start : start autoware all service"
    echo "    --autoware-stop : stop autoware all service"
    echo "    --autoware-restart : restart autoware all service"
    echo "    --psim-main     :Launch autoware main with planning simulator"
    echo "    --autoware-main-mrm    :Launch autoware main mrm"
    echo "    --psim-main-mrm    :Launch autoware main mrm with planning simulator"
    echo "    --autoware-sub    :Launch autoware sub"
    echo "    --psim-sub     :Launch autoware sub with planning simulator"
    echo "    --psim            :Launch simple planning simulator"
    echo "    --start_record    :Start recording rosbag with logpacker"
    echo "    --stop_record     :Stop recording rosbag with logpacker"
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
elif [ "${1-}" = "--autoware-start" ]; then
    start_autoware_service "${@:2}"
elif [ "${1-}" = "--autoware-stop" ]; then
    stop_autoware_service "${@:2}"
elif [ "${1-}" = "--autoware-restart" ]; then
    restart_autoware_service "${@:2}"
elif [ "${1-}" = "--autoware-main" ]; then
    launch_autoware_main "${@:2}"
elif [ "${1-}" = "--psim-main" ]; then
    launch_psim_main "${@:2}"
elif [ "${1-}" = "--autoware-main-mrm" ]; then
    launch_autoware_main_mrm "${@:2}"
elif [ "${1-}" = "--psim-main-mrm" ]; then
    launch_psim_main_mrm "${@:2}"
elif [ "${1-}" = "--autoware-sub" ]; then
    launch_autoware_sub "${@:2}"
elif [ "${1-}" = "--psim-sub" ]; then
    launch_psim_sub "${@:2}"
elif [ "${1-}" = "--psim" ]; then
    launch_psim "${@:2}"
elif [ "${1-}" = "--start_record" ]; then
    start_record
elif [ "${1-}" = "--stop_record" ]; then
    stop_record
elif [ "${1-}" = "--kill" ]; then
    kill_zombie
elif [ "${1-}" = "--clean" ]; then
    clean
else
    echo "please pass the correct arguments! Use '-h' or '--help' command if you check the arguments"
fi
