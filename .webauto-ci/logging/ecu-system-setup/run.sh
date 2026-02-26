#!/bin/bash -e
# cspell: ignore nsight

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK:?is not set}"

# cleanup base image first
. .webauto-ci/common/ota-clean-up/clean-up-base-image.sh

sudo -E apt-get -y update
sudo -E apt-get -y install "linux-image-$(uname -r)" "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"
sudo -E apt-get -y install ubuntu-minimal openssh-server fonts-ubuntu systemd-coredump vim grub-efi-amd64
sudo -E apt-get -y install ubuntu-desktop-minimal --no-install-recommends

# Disable auto suspend
sudo sed -i 's/\(.*sleep-inactive-ac-timeout=.*\)/sleep-inactive-ac-timeout=0/g' /etc/gdm3/greeter.dconf-defaults
sudo sed -i 's/\(.*sleep-inactive-battery-timeout=.*\)/sleep-inactive-battery-timeout=0/g' /etc/gdm3/greeter.dconf-defaults

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global url."https://github.com/".insteadOf "git@github.com:"
# shellcheck disable=SC2016
git config --global credential."https://github.com".helper '!f() { echo "username=x-access-token"; echo "password=${GITHUB_TOKEN}"; }; f'

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
eval ansible-playbook "'${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK}'" \
    -e github_token="${GITHUB_TOKEN}" \
    -e reload_systemd=no

git config --global --unset credential."https://github.com".helper
git config --global --unset url."https://github.com/".insteadOf

# remove "jetpack" dev packages
. .webauto-ci/common/ota-clean-up/clean-up-jetpack-dev.sh
# remove "nsight" related packages
. .webauto-ci/common/ota-clean-up/clean-up-nsight.sh
# reduce "git" folder size, and other folders
. .webauto-ci/common/ota-clean-up/clean-up-ecu-image.sh
# remove "ansible" related packages
. .webauto-ci/common/ota-clean-up/clean-up-ansible.sh
# remove build files and folders
python3 .webauto-ci/common/ota-clean-up/clean-up-build.py /

sudo sed -i '/^autoware\sALL=(ALL)\sNOPASSWD:ALL/d' /etc/sudoers
