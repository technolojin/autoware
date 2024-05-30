#!/bin/bash

# shellcheck disable=SC1091
source /opt/autoware/services/set-autoware-env/setup.sh
ros2 launch autoware_launch autoware.launch.xml \
    vehicle_model:="$VEHICLE_MODEL" \
    sensor_model:="$SENSOR_MODEL" \
    map_path:=/opt/autoware/maps \
    lanelet2_map_file:=lanelet2_map.osm \
    pointcloud_map_file:=pcd \
    2>&1 | tee /home/autoware/autoware.log
