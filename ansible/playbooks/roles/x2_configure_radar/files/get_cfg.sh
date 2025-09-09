#!/bin/bash

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 front_left/radar_link -A 23 >/tmp/front_left.cfg
echo "save params to /tmp/front_left.cfg"

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 front_right/radar_link -A 23 >/tmp/front_right.cfg
echo "save params to /tmp/front_right.cfg"

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 front_center/radar_link -A 23 >/tmp/front_center.cfg
echo "save params to /tmp/front_center.cfg"

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 rear_left/radar_link -A 23 >/tmp/rear_left.cfg
echo "save params to /tmp/rear_left.cfg"

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 rear_right/radar_link -A 23 >/tmp/rear_right.cfg
echo "save params to /tmp/rear_right.cfg"

ros2 topic echo /diagnostics 2>/dev/null |
    grep "message: ARS548 configuration status" -A 25 |
    grep -m1 rear_center/radar_link -A 23 >/tmp/rear_center.cfg
echo "save params to /tmp/rear_center.cfg"
