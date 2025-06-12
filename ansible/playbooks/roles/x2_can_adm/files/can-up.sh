#!/bin/bash

# VCU CAN Bus #1
while [ ! -e "/sys/class/net/fintekcan0" ]; do
    sleep 1
done
sudo ip link set fintekcan0 type can bitrate 500000
sudo ip link set fintekcan0 up

# IMU
while [ ! -e "/sys/class/net/fintekcan3" ]; do
    sleep 1
done
sudo ip link set fintekcan3 type can bitrate 500000
sudo ip link set fintekcan3 up

# VCU CAN Bus #2
while [ ! -e "/sys/class/net/peakcan0" ]; do
    sleep 1
done
sudo ip link set peakcan0 type can bitrate 500000
sudo ip link set peakcan0 up

# Brake CAN Bus
while [ ! -e "/sys/class/net/peakcan1" ]; do
    sleep 1
done
sudo ip link set peakcan1 type can bitrate 500000
sudo ip link set peakcan1 up
