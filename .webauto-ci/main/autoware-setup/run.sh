#!/bin/bash -e

: "${WEBAUTO_CI_GITHUB_TOKEN:?is not set}"

ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
export ROS_APT_SOURCE_VERSION
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
sudo apt install -y /tmp/ros2-apt-source.deb
rm /tmp/ros2-apt-source.deb

sudo -E apt-get -y update
sudo -E apt-get -y install usbutils # For kvaser

export GITHUB_TOKEN="$WEBAUTO_CI_GITHUB_TOKEN"
git config --global url."https://github.com/".insteadOf "git@github.com:"
# shellcheck disable=SC2016
git config --global credential."https://github.com".helper '!f() { echo "username=x-access-token"; echo "password=${GITHUB_TOKEN}"; }; f'

ansible_args=()
ansible_args+=("--extra-vars" "prompt_install_nvidia=y")
ansible_args+=("--extra-vars" "prompt_download_artifacts=y")
ansible_args+=("--extra-vars" "data_dir=$HOME/autoware_data")

# read amd64 env file and expand ansible arguments
source 'amd64.env'
while read -r env_name; do
    ansible_args+=("--extra-vars" "${env_name}=${!env_name}")
done < <(sed "s/=.*//" <amd64.env)

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
ansible-playbook "ansible/playbooks/local_dev_env.yaml" \
    "${ansible_args[@]}" \
    -e WORKSPACE_ROOT="$(pwd)" \
    -e install_devel="y" \
    --skip-tags vcs

git config --global --unset credential."https://github.com".helper
git config --global --unset url."https://github.com/".insteadOf
