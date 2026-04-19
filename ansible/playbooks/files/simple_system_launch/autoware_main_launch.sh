#!/bin/bash

mkdir -p /home/autoware/.ros/autoware_main_log
export ROS_LOG_DIR=/home/autoware/.ros/autoware_main_log
# Temporary v4.4 workaround for planning_setting switching.
# Remove this block in the next version when planning_setting is handled centrally.
PLANNING_SETTINGS_FILE="/home/autoware/pilot-auto/parameter_settings/planning_settings.env"
if [ -f "$PLANNING_SETTINGS_FILE" ]; then
    # shellcheck disable=SC1090
    source "$PLANNING_SETTINGS_FILE"
fi
PLANNING_SETTING="${PLANNING_SETTING:-rule_based}"
case "$PLANNING_SETTING" in
rule_based | diffusion_planner) ;;
*)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Invalid PLANNING_SETTING=$PLANNING_SETTING, fallback to rule_based" | tee -a "$HOME"/autoware_main.log
    PLANNING_SETTING=rule_based
    ;;
esac

CENTERPOINT_ENGINE_DIR="/opt/autoware/mlmodels/centerpoint"
if [ -z "$(find "$CENTERPOINT_ENGINE_DIR" -maxdepth 1 -type f -name "*.engine" -print -quit)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting centerpoint model build..."
    START_TIME=$(date +%s)
    ros2 launch autoware_lidar_centerpoint lidar_centerpoint.launch.xml \
        model_name:=centerpoint \
        model_path:=/opt/autoware/mlmodels/centerpoint \
        model_param_path:="$(ros2 pkg prefix autoware_launch --share)/config/perception/object_recognition/detection/lidar_model/centerpoint.param.yaml" \
        build_only:=true 2>&1 | tee "$HOME"/autoware_centerpoint_model_build.log
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Centerpoint model build completed. Elapsed time: ${ELAPSED_TIME}s ($((ELAPSED_TIME / 60))m $((ELAPSED_TIME % 60))s)"
fi
ros2 launch autoware_launch autoware.main.launch.xml \
    is_redundant:="true" \
    map_path:=/opt/autoware/maps \
    lanelet2_map_file:=lanelet2_map.osm \
    pointcloud_map_file:=pcd \
    vehicle_model:="$VEHICLE_MODEL" \
    sensor_model:="$SENSOR_MODEL" \
    planning_setting:="$PLANNING_SETTING" \
    v2x_location:="$V2X_LOCATION" \
    launch_system:=false \
    rviz:=false 2>&1 | tee "$HOME"/autoware_main.log
