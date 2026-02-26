#!/bin/bash -e

: "${WEBAUTO_CI_SOURCE_PATH:?is not set}"

: "${AUTOWARE_PATH:?is not set}"

apt-get update

apt-get -y install sudo curl wget unzip gnupg lsb-release git ccache python3-apt python3-pip apt-utils software-properties-common rsync
add-apt-repository universe

# install yq (ARM64)
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.49.2/yq_linux_arm64
echo "783aa3c3beedcf2bf4aaf6262eca38b92a16d3ea31e2218ca80ba8ec7226b248  /usr/local/bin/yq" | sha256sum -c -
sudo chmod a+x /usr/local/bin/yq

pip install --no-cache-dir 'ansible==6.*'

user=autoware
# useradd -m "$user" -s /bin/bash
echo "$user:$user" | chpasswd
echo "$user ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
gpasswd -a "$user" sudo

mkdir -p "$AUTOWARE_PATH"
chmod 755 "$AUTOWARE_PATH"
cp -rfT "$WEBAUTO_CI_SOURCE_PATH" "$AUTOWARE_PATH"
chown -R "$user":"$user" "$AUTOWARE_PATH" /home/"$user"
