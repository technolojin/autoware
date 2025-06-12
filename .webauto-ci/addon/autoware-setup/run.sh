#!/bin/bash -e

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

sudo -E apt-get -y update
sudo -E apt-get -y install usbutils # For kvaser

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
git config --global --add url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "git@github.com:"

ansible_args=()
ansible_args+=("--extra-vars" "prompt_install_nvidia=y")
ansible_args+=("--extra-vars" "prompt_download_artifacts=n")
ansible_args+=("--extra-vars" "install_devel=y")

# read amd64 env file and expand ansible arguments
source 'amd64.env'
while read -r env_name; do
    ansible_args+=("--extra-vars" "${env_name}=${!env_name}")
done < <(sed "s/=.*//" <amd64.env)

sudo chmod 777 /tmp

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
ansible-playbook "ansible/playbooks/local_dev_env.yaml" \
    "${ansible_args[@]}" \
    -e WORKSPACE_ROOT="$(pwd)" \
    --skip-tags vcs

git config --global --unset-all url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf
