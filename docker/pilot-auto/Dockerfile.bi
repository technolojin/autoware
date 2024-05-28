# Image args should come at the beginning.
ARG BASE_IMAGE

# hadolint ignore=DL3006
FROM $BASE_IMAGE as devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ROS_DISTRO
ARG SETUP_ARGS
ARG GITHUB_TOKEN
ARG DESCRIPTION

LABEL org.opencontainers.image.description=$DESCRIPTION

## Install apt packages
# hadolint ignore=DL3008
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  git \
  ssh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

## Copy files
COPY autoware.repos setup-dev-env.sh ansible-galaxy-requirements.yaml amd64.env arm64.env /autoware/
COPY ansible/ /autoware/ansible/
WORKDIR /autoware
RUN ls /autoware

## Add GitHub to known hosts for private repositories
RUN mkdir -p ~/.ssh \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts

## replace git@github with https://x-access-token
RUN sed -i "s/git@github\.com:/https:\/\/github\.com\//g" ./ansible-galaxy-requirements.yaml \
  && sed -i "s/https:\/\/github.com/https:\/\/x-access-token:$GITHUB_TOKEN@github.com/g" ./ansible-galaxy-requirements.yaml
## Set up development environment
RUN --mount=type=ssh ./setup-dev-env.sh -y $SETUP_ARGS \
  && pip uninstall -y ansible ansible-core

RUN sed -i "s/git@github\.com:/https:\/\/github\.com\//g" ./autoware.repos \
  && sed -i "s/https:\/\/github.com/https:\/\/x-access-token:$GITHUB_TOKEN@github.com/g" ./autoware.repos \
  && cat ./autoware.repos \
  && mkdir -p src

RUN --mount=type=ssh vcs import src < autoware.repos

RUN rosdep update \
  && DEBIAN_FRONTEND=noninteractive rosdep install -y --ignore-src --from-paths src --rosdistro "$ROS_DISTRO" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/dependencies_record
# dump dependencies
RUN package_list=$(dpkg -l | grep "  ros-humble" | awk '{print $2","$3}') && \
    echo 'package_name,version' > ~/dependencies_record/ros_dependencies.csv; \
    for pkg in ${package_list}; do \
        pkg_name=$(echo "${pkg}" | cut -d , -f1); \
        echo "${pkg}" >> ~/dependencies_record/ros_dependencies.csv; \
        apt-mark hold "${pkg_name}"; \
    done

RUN pip3 freeze > ~/dependencies_record/requirements.txt

## Clean up unnecessary files
# hadolint ignore=DL3059
RUN rm -rf \
  "$HOME"/.cache \
  /etc/apt/sources.list.d/cuda*.list \
  /etc/apt/sources.list.d/docker.list \
  /etc/apt/sources.list.d/nvidia-docker.list \
  ~/.ros/ \
  ~/autoware_data/ \
  ~/.ssh/known_hosts \
  ~/.ansible \
  /autoware/

## Create entrypoint
# hadolint ignore=DL3059
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" > /etc/bash.bashrc
CMD ["/bin/bash"]
