#!/bin/bash -e
# cspell: ignore webauto nsight jetpack

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

: "${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK:?is not set}"
: "${ECU_ID:?is not set}"

# cleanup base image first
. .webauto-ci/common/ota-clean-up/clean-up-base-image.sh

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "git@github.com:"

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
eval ansible-playbook "'${ECU_SYSTEM_SETUP_ANSIBLE_PLAYBOOK}'" \
    -e ecu_id="${ECU_ID}" \
    -e use_oem_setup=yes \
    -e github_token="${GITHUB_TOKEN}" \
    -e reload_systemd=no

git config --global --unset-all url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf

sudo mkdir -p /etc/ota
sudo cp "$(dirname "$0")/persistents.txt" /etc/ota/

# remove "jetpack" dev packages
. .webauto-ci/common/ota-clean-up/clean-up-jetpack-dev.sh
# remove "nsight" related packages
. .webauto-ci/common/ota-clean-up/clean-up-nsight.sh
# reduce "git" folder size, and other folders
. .webauto-ci/common/ota-clean-up/clean-up-ecu-image.sh
