#!/bin/bash

STOP_STATUS=("in_progress" "failure")
LOGGING_MODE="/etc/autoware_logging_suite/logpacker/logging_mode"
TARGET_VALUE="event"
prev_status=""

ros2 topic echo -f /webauto/vehicle_info |
    while read -r line; do

        json=$(echo "$line" | sed -n "s/^data: '\(.*\)'$/\1/p")
        if [ -z "$json" ]; then
            continue
        fi

        current_status=$(echo "$json" | jq -r '.firmware_deployment_status')

        if [ ! -f "$LOGGING_MODE" ]; then
            echo "File not found: $LOGGING_MODE"
            continue
        fi

        if [ "$(cat "$LOGGING_MODE")" = "$TARGET_VALUE" ]; then
            if [[ -n $current_status && $current_status != "$prev_status" ]]; then
                echo "firmware_deployment_status changed: $prev_status -> $current_status"

                if [[ " ${STOP_STATUS[*]} " == *" $current_status "* ]]; then
                    systemctl is-active --quiet bagkeeper.service && systemctl stop bagkeeper.service
                else
                    ! systemctl is-active --quiet bagkeeper.service && systemctl start bagkeeper.service
                fi

                prev_status="$current_status"
            fi
        fi
    done
