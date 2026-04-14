#!/bin/bash

mkdir -p /home/autoware/.ros/autoware_system_log
export ROS_LOG_DIR=/home/autoware/.ros/autoware_system_log
# Temporary v4.4 workaround for planning_setting switching.
# Remove this block in the next version when planning_setting is handled centrally.
PLANNING_SETTINGS_FILE="/home/autoware/pilot-auto/planning_settings.env"
if [ -f "$PLANNING_SETTINGS_FILE" ]; then
    # shellcheck disable=SC1090
    source "$PLANNING_SETTINGS_FILE"
fi
PLANNING_SETTING="${PLANNING_SETTING:-rule_based}"
case "$PLANNING_SETTING" in
rule_based | diffusion_planner) ;;
*)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Invalid PLANNING_SETTING=$PLANNING_SETTING, fallback to rule_based" | tee -a "$HOME"/autoware_system.log
    PLANNING_SETTING=rule_based
    ;;
esac

ros2 launch autoware_launch tier4_system_component.launch.xml \
    is_redundant:="true" \
    use_control_command_gate:="true" \
    system_run_mode:=online \
    launch_system_monitor:=true \
    launch_dummy_diag_publisher:=false \
    planning_setting:="$PLANNING_SETTING" \
    sensor_model:="$SENSOR_MODEL" 2>&1 | tee "$HOME"/autoware_system.log
