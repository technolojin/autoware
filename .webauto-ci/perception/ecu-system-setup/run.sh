#!/bin/bash -e

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK:?is not set}"
: "${PERCEPTION_TYPE:?is not set}"
: "${VEHICLE_MODEL:?is not set}"

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "git@github.com:"

eval ansible-playbook "'${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK}'" \
    -e perception_type="${PERCEPTION_TYPE}" \
    -e vehicle_model="${VEHICLE_MODEL}" \
    -e use_oem_setup=yes \
    -e github_token="${GITHUB_TOKEN}" \
    -e reload_systemd=no

git config --global --unset-all url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf

sudo mkdir -p /etc/ota
sudo cp "$(dirname "$0")/persistents.txt" /etc/ota/
