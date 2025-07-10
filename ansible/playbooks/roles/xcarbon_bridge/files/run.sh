#!/bin/bash

# shellcheck disable=SC1091
source /opt/autoware/services/set-autoware-env/setup.sh
ros2 run xcarbon_bridge xcarbon_bridge
