#!/bin/bash

# Pyrocan
while [ ! -e "/sys/class/net/pcan1" ]; do
    sleep 1
done

sudo ip link set pcan1 type can bitrate 250000
sudo ip link set pcan1 up
