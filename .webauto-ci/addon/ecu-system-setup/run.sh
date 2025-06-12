#!/bin/bash -e

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK:?is not set}"

sudo -E apt-get -y update
sudo -E apt-get -y install "linux-image-$(uname -r)" "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"
sudo -E apt-get -y install ubuntu-minimal openssh-server fonts-ubuntu systemd-coredump vim grub-efi-amd64
sudo -E apt-get -y install ubuntu-desktop-minimal --no-install-recommends

# Disable auto suspend
sudo sed -i 's/\(.*sleep-inactive-ac-timeout=.*\)/sleep-inactive-ac-timeout=0/g' /etc/gdm3/greeter.dconf-defaults
sudo sed -i 's/\(.*sleep-inactive-battery-timeout=.*\)/sleep-inactive-battery-timeout=0/g' /etc/gdm3/greeter.dconf-defaults

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "git@github.com:"

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
eval ansible-playbook "'${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK}'" \
    -e github_token="${GITHUB_TOKEN}" \
    -e reload_systemd=no

git config --global --unset-all url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf

sudo mkdir -p /etc/ota
sudo cp "$(dirname "$0")/persistents.txt" /etc/ota/
sudo cp "$(dirname "$0")/ignore.txt" /etc/ota/

# clean up ecu firmware
. .webauto-ci/common/ecu-clean-up/run.sh

sudo sed -i '/^autoware\sALL=(ALL)\sNOPASSWD:ALL/d' /etc/sudoers
