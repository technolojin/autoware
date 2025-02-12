#!/bin/bash

MAX_RETRIES=10
attempt=1

while [ $attempt -le $MAX_RETRIES ]; do
    echo "Attempt #$attempt"

    if [ -e "/sys/class/net/pcan1" ]; then
        echo "Found /sys/class/net/pcan1"

        sudo ip link set pcan1 type can bitrate 250000
        sudo ip link set pcan1 up
        exit 0
    fi

    sleep 1
    attempt=$((attempt + 1))
done

# If we reach here, the command failed after MAX_RETRIES attempts
echo "Command failed after $MAX_RETRIES attempts."
exit 1
