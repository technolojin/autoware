#!/bin/sh
# cSpell: ignore usbhid uevent
_base_id="1-8"
_sub_id="1.0"

_retry_cnt=0
_retry_max=10

while true; do
    if [ -d /sys/bus/usb/devices/$_base_id:$_sub_id ]; then
        grep "DRIVER=usbhid" /sys/bus/usb/devices/$_base_id:$_sub_id/uevent
        grep_result=$?
        if [ $grep_result -eq 0 ]; then
            echo "MOT Touch Display is configured properly as HID device."
            exit 0
        else
            echo "MOT Touch Display is detected, but not configured."
        fi
    else
        echo "MOT Touch Display is not detected."
    fi

    _retry_cnt=$((_retry_cnt + 1))
    if [ $_retry_cnt -gt $_retry_max ]; then
        echo "Failed to configure MOT Touch Display ..."
        exit 1
    fi

    echo "Now try to perform unplug-plug to configure again ..."
    echo "1-0:1.0" >/sys/bus/usb/drivers/hub/unbind
    sleep 1
    echo "1-0:1.0" >/sys/bus/usb/drivers/hub/bind
    sleep 6
done
