#!/bin/bash -e

# [Temporary workaround] Remove the existing ROS 2 APT source list file
rm -f /etc/apt/sources.list.d/ros2.list
rm -f /usr/share/keyrings/ros-archive-keyring.gpg

apt-get update

# [Temporary workaround]
apt-get -y install curl
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
export ROS_APT_SOURCE_VERSION
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
apt install /tmp/ros2-apt-source.deb

user=autoware
echo "$user:$user" | chpasswd
echo "$user ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
gpasswd -a "$user" sudo
