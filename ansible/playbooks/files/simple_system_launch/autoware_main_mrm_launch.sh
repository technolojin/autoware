#!/bin/bash

mkdir -p /home/autoware/.ros/autoware_main_mrm_log
export ROS_LOG_DIR=/home/autoware/.ros/autoware_main_mrm_log
export ROS_DOMAIN_ID=3
ros2 launch autoware_launch autoware.main.mrm.launch.xml \
    vehicle_model:="$VEHICLE_MODEL" \
    sensor_model:="$SENSOR_MODEL" 2>&1 | tee "$HOME"/autoware_main_mrm.log
