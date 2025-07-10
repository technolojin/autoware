#!/bin/bash

systemctl stop logpacker.service

# shellcheck disable=SC1091
source /opt/autoware/services/bagkeeper-launch/functions.sh

if pgrep -x rosbag_keeper; then
    echo "bagkeeper process is detected."
    WaitCopyingBag
else
    echo "bagkeeper process is not detected."
fi

systemctl stop bagkeeper.service

echo "Done."
