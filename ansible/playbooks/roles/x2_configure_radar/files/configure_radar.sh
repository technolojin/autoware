#!/bin/bash
# cSpell:ignore powersave

FLAG_DIR="/opt/autoware/services/ota_first_boot_flag"
FLAG_FILE="${FLAG_DIR}/.first_boot_done"

if [[ -f $FLAG_FILE ]]; then
    echo "It's not the first boot after OTA, so skipping."
    systemd-notify --ready
    exit 0
fi

# shellcheck disable=SC1091
source /home/autoware/autoware.env && true
export ROS_LOG_DIR="/home/autoware/.ros/log"

# Wait for the robot state publisher to be ready
wait_robot_state_publisher() {
    local node_name="/robot_state_publisher"
    local interval=10
    local max_attempts=30
    local attempts=0

    while ! ros2 node list 2>/dev/null | grep -q "$node_name"; do
        attempts=$((attempts + 1))
        echo "Attempt $attempts: Waiting for $node_name..."

        if [ $attempts -ge $max_attempts ]; then
            echo "[NG] Robot state publisher not found after $((max_attempts * interval)) seconds."
            exit 1
        fi

        sleep $interval
    done
}

# Check if the service call is successful, exit if not
call_service_or_exit() {
    local label="$1"
    local service="$2"
    local srv_type="$3"
    local args="$4"
    local max_attempts=5
    local attempt=1

    echo "$label"
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt for service: $service"
        if ros2 service call "$service" "$srv_type" "$args" | tee /tmp/service_output.txt | grep -q "success=True"; then
            echo "[OK] Success: $service"
            return 0
        fi

        echo "[WARN]  Attempt $attempt failed"
        cat /tmp/service_output.txt
        attempt=$((attempt + 1))
        sleep 5
    done
    if ! ros2 service call "$service" "$srv_type" "$args" | tee /tmp/service_output.txt | grep -q "success=True"; then
        echo "[NG] Failed: $service"
        cat /tmp/service_output.txt
        exit 1
    fi
}

# Main script execution starts here
wait_robot_state_publisher

echo "********* Get Current Parameters *********"
/opt/autoware/services/configure_radar/get_cfg.sh

TMP_FILES=(
    "/tmp/front_center.cfg"
    "/tmp/front_left.cfg"
    "/tmp/front_right.cfg"
    "/tmp/rear_center.cfg"
    "/tmp/rear_left.cfg"
    "/tmp/rear_right.cfg"
)

for FILE in "${TMP_FILES[@]}"; do
    if [ ! -s "$FILE" ]; then
        echo "Error: $FILE is empty or does not exist." >&2
        exit 1
    fi
done

echo "********* Front Center *********"
position=front_center

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/front_center/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/front_center/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: false}"
    call_service_or_exit "Radar Params" /sensing/radar/front_center/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: mid, cycle_time_ms: 100, time_slot_ms: 79, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Front Left *********"
position=front_left

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/front_left/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/front_left/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: true}"
    call_service_or_exit "Radar Params" /sensing/radar/front_left/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: low, cycle_time_ms: 100, time_slot_ms: 54, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Front Right *********"
position=front_right

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/front_right/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/front_right/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: false}"
    call_service_or_exit "Radar Params" /sensing/radar/front_right/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: high, cycle_time_ms: 100, time_slot_ms: 10, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Rear Center *********"
position=rear_center

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/rear_center/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/rear_center/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: false}"
    call_service_or_exit "Radar Params" /sensing/radar/rear_center/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: mid, cycle_time_ms: 100, time_slot_ms: 29, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Rear Left *********"
position=rear_left

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/rear_left/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/rear_left/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: true}"
    call_service_or_exit "Radar Params" /sensing/radar/rear_left/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: high, cycle_time_ms: 100, time_slot_ms: 54, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Rear Right *********"
position=rear_right

if diff -q /tmp/${position}.cfg /opt/autoware/services/configure_radar/${position}.cfg; then
    echo "No differences found in ${position}"
else
    echo "Difference found in ${position}, applying changes..."
    call_service_or_exit "Vehicle Params" /sensing/radar/rear_right/set_vehicle_parameters continental_srvs/srv/ContinentalArs548SetVehicleParameters "{vehicle_length: -1.0, vehicle_width: -1.0, vehicle_height: -1.0, vehicle_wheelbase: -1.0}"
    call_service_or_exit "Sensor Mounting" /sensing/radar/rear_right/set_sensor_mounting continental_srvs/srv/ContinentalArs548SetSensorMounting "{longitudinal: 0.0, lateral: 0.0, vertical: 0.5, yaw: 0.0, pitch: 0.0, plug_orientation: false}"
    call_service_or_exit "Radar Params" /sensing/radar/rear_right/set_radar_parameters continental_srvs/srv/ContinentalArs548SetRadarParameters "{maximum_distance: 301, frequency_band: low, cycle_time_ms: 100, time_slot_ms: 10, country_code: japan, powersave_standstill: 0}"
fi

echo "********* Radar configuration complete *********"

systemd-notify --ready
