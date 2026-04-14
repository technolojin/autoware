#!/bin/bash

mkdir -p /home/autoware/.ros/autoware_sub_log
export ROS_LOG_DIR=/home/autoware/.ros/autoware_sub_log
export ROS_DOMAIN_ID=2
ros2 launch autoware_launch autoware.sub.launch.xml \
    vehicle_model:="$VEHICLE_MODEL" \
    sensor_model:="$SENSOR_MODEL" 2>&1 | tee "$HOME"/autoware_sub.log
