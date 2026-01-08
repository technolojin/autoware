ARG AUTOWARE_BASE_IMAGE=ghcr.io/autowarefoundation/autoware-base:latest
ARG AUTOWARE_BASE_CUDA_IMAGE=ghcr.io/autowarefoundation/autoware-base:cuda-latest
ARG AUTOWARE_BASE_IMAGE_JAZZY=ghcr.io/autowarefoundation/autoware-base:jazzy-latest
ARG ROS_DISTRO=humble

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS rosdep-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY setup-dev-env.sh ansible-galaxy-requirements.yaml amd64.env amd64_jazzy.env arm64.env /autoware/
COPY ansible/ /autoware/ansible/
COPY docker/scripts/cleanup_apt.sh /autoware/cleanup_apt.sh
RUN chmod +x /autoware/cleanup_apt.sh
COPY docker/scripts/resolve_rosdep_keys.sh /autoware/resolve_rosdep_keys.sh
RUN chmod +x /autoware/resolve_rosdep_keys.sh
WORKDIR /autoware

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y rosdep --ros-distro "$ROS_DISTRO" \
  && pipx uninstall ansible\
  && /autoware/cleanup_apt.sh

# Generate install package lists
COPY src/core/autoware_adapi_msgs /autoware/src/core/autoware_adapi_msgs
COPY src/core/autoware_cmake /autoware/src/core/autoware_cmake
COPY src/core/autoware_internal_msgs /autoware/src/core/autoware_internal_msgs
COPY src/core/autoware_lanelet2_extension /autoware/src/core/autoware_lanelet2_extension
COPY src/core/autoware_msgs /autoware/src/core/autoware_msgs
COPY src/core/autoware_utils /autoware/src/core/autoware_utils
RUN rosdep update && /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-core-common-depend-packages.txt \
  && cat /rosdep-core-common-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-core-common-exec-depend-packages.txt \
  && cat /rosdep-core-common-exec-depend-packages.txt

COPY src/core/autoware_core /autoware/src/core/autoware_core
RUN rosdep update && /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-core-depend-packages.txt \
  && cat /rosdep-core-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-core-exec-depend-packages.txt \
  && cat /rosdep-core-exec-depend-packages.txt

COPY src/local_dev_env/external /autoware/src/local_dev_env/external
# trt_batched_nms depends on autoware_tensorrt_common and autoware_cuda_utils, which are not available in local_dev_env-common-devel stage
RUN rm -rf /autoware/src/local_dev_env/external/trt_batched_nms
COPY src/local_dev_env/autoware_local_dev_env/common /autoware/src/local_dev_env/autoware_local_dev_env/common
COPY src/middleware/external /autoware/src/middleware/external
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-common-depend-packages.txt \
  && cat /rosdep-local_dev_env-common-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-visualization-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/visualization /autoware/src/local_dev_env/autoware_local_dev_env/visualization
COPY src/core/autoware_rviz_plugins /autoware/src/core/autoware_rviz_plugins

RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-visualization-depend-packages.txt \
  && cat /rosdep-local_dev_env-visualization-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-local_dev_env-visualization-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-visualization-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-sensing-perception-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_perception_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_perception_launch
COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_sensing_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_sensing_launch
COPY src/local_dev_env/autoware_local_dev_env/perception /autoware/src/local_dev_env/autoware_local_dev_env/perception
COPY src/local_dev_env/autoware_local_dev_env/sensing /autoware/src/local_dev_env/autoware_local_dev_env/sensing
COPY src/local_dev_env/autoware_local_dev_env/evaluator/autoware_perception_online_evaluator /autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_perception_online_evaluator
COPY src/sensor_component /autoware/src/sensor_component
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-sensing-perception-depend-packages.txt \
  && cat /rosdep-local_dev_env-sensing-perception-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-localization-mapping-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_localization_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_localization_launch
COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_map_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_map_launch
COPY src/local_dev_env/autoware_local_dev_env/localization /autoware/src/local_dev_env/autoware_local_dev_env/localization
COPY src/local_dev_env/autoware_local_dev_env/map /autoware/src/local_dev_env/autoware_local_dev_env/map
# TODO(youtalk): Remove COPYs when https://github.com/autowarefoundation/autoware_local_dev_env/issues/10282 is resolved
COPY src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions /autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions
COPY src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor /autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor
COPY src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_helpers/autoware_automatic_pose_initializer /autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_helpers/autoware_automatic_pose_initializer
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-localization-mapping-depend-packages.txt \
  && cat /rosdep-local_dev_env-localization-mapping-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-local_dev_env-localization-mapping-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-localization-mapping-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-planning-control-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_control_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_control_launch
COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_planning_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_planning_launch
COPY src/local_dev_env/autoware_local_dev_env/control /autoware/src/local_dev_env/autoware_local_dev_env/control
COPY src/local_dev_env/autoware_local_dev_env/planning /autoware/src/local_dev_env/autoware_local_dev_env/planning
# TODO(youtalk): Remove COPYs when https://github.com/autowarefoundation/autoware_local_dev_env/issues/8805 is resolved
COPY src/local_dev_env/autoware_local_dev_env/evaluator/autoware_control_evaluator /autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_control_evaluator
COPY src/local_dev_env/autoware_local_dev_env/evaluator/autoware_planning_evaluator /autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_planning_evaluator
COPY src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions /autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions
COPY src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor /autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor
COPY src/local_dev_env/autoware_local_dev_env/vehicle/autoware_external_cmd_converter /autoware/src/local_dev_env/autoware_local_dev_env/vehicle/autoware_external_cmd_converter
COPY src/local_dev_env/autoware_local_dev_env/vehicle/autoware_raw_vehicle_cmd_converter /autoware/src/local_dev_env/autoware_local_dev_env/vehicle/autoware_raw_vehicle_cmd_converter
COPY src/local_dev_env/autoware_local_dev_env/system/autoware_command_mode_types /autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_command_mode_types

# diffusion_planner depends on cuda
COPY src/local_dev_env/autoware_local_dev_env/sensing/autoware_cuda_utils /autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_cuda_utils
COPY src/local_dev_env/autoware_local_dev_env/perception/autoware_tensorrt_common /autoware/src/local_dev_env/autoware_local_dev_env/perception/autoware_tensorrt_common
COPY src/local_dev_env/autoware_local_dev_env/perception/autoware_tensorrt_plugins /autoware/src/local_dev_env/autoware_local_dev_env/perception/autoware_tensorrt_plugins

RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-planning-control-depend-packages.txt \
  && cat /rosdep-local_dev_env-planning-control-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-local_dev_env-planning-control-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-planning-control-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-vehicle-system-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_vehicle_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_vehicle_launch
COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_system_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_system_launch
COPY src/local_dev_env/autoware_local_dev_env/vehicle /autoware/src/local_dev_env/autoware_local_dev_env/vehicle
COPY src/local_dev_env/autoware_local_dev_env/system /autoware/src/local_dev_env/autoware_local_dev_env/system

# planning_validator and its dependencies
COPY src/local_dev_env/autoware_local_dev_env/planning/planning_validator /autoware/src/local_dev_env/autoware_local_dev_env/planning/planning_validator
COPY src/core/autoware_core/planning/autoware_planning_factor_interface /autoware/src/core/autoware_core/planning/autoware_planning_factor_interface
COPY src/core/autoware_core/planning/autoware_route_handler /autoware/src/core/autoware_core/planning/autoware_route_handler

COPY src/core/autoware_core/map/autoware_map_height_fitter /autoware/src/core/autoware_core/map/autoware_map_height_fitter
COPY src/local_dev_env/autoware_local_dev_env/localization/autoware_pose2twist /autoware/src/local_dev_env/autoware_local_dev_env/localization/autoware_pose2twist
COPY src/sensor_component/external/sensor_component_description /autoware/src/sensor_component/external/sensor_component_description
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-vehicle-system-depend-packages.txt \
  && cat /rosdep-local_dev_env-vehicle-system-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-local_dev_env-vehicle-system-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-vehicle-system-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-api-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/local_dev_env/autoware_local_dev_env/launch/tier4_autoware_api_launch /autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_autoware_api_launch
COPY src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_local_dev_env /autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_local_dev_env
COPY src/core/autoware_core/api/autoware_adapi_adaptors /autoware/src/core/autoware_core/api/autoware_adapi_adaptors
COPY src/local_dev_env/autoware_local_dev_env/system/autoware_diagnostic_graph_utils /autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_diagnostic_graph_utils
COPY src/core/autoware_core/map/autoware_map_height_fitter /autoware/src/core/autoware_core/map/autoware_map_height_fitter

RUN /autoware/resolve_rosdep_keys.sh /autoware/src ${ROS_DISTRO} \
  > /rosdep-local_dev_env-api-depend-packages.txt \
  && cat /rosdep-local_dev_env-api-depend-packages.txt
RUN /autoware/resolve_rosdep_keys.sh /autoware/src ${ROS_DISTRO} --dependency-types=exec \
  > /rosdep-local_dev_env-api-exec-depend-packages.txt \
  && cat /rosdep-local_dev_env-api-exec-depend-packages.txt

FROM rosdep-depend AS rosdep-local_dev_env-depend
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO

COPY src/launcher /autoware/src/launcher
COPY src/sensor_component /autoware/src/sensor_component
COPY src/local_dev_env /autoware/src/local_dev_env
RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" \
  > /rosdep-local_dev_env-depend-packages.txt \
  && cat /rosdep-local_dev_env-depend-packages.txt

RUN /autoware/resolve_rosdep_keys.sh /autoware/src "${ROS_DISTRO}" --dependency-types=exec \
  > /rosdep-exec-depend-packages.txt \
  && cat /rosdep-exec-depend-packages.txt

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS core-common-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

COPY docker/scripts/build_and_clean.sh /autoware/build_and_clean.sh
RUN chmod +x /autoware/build_and_clean.sh

# Set up development environment and tools
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers openadkit --ros-distro $ROS_DISTRO \
  && ./setup-dev-env.sh -y --module dev-tools openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && /autoware/cleanup_apt.sh

# Install rosdep dependencies
COPY --from=rosdep-depend /rosdep-core-common-depend-packages.txt /tmp/rosdep-core-common-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-core-common-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && /autoware/cleanup_apt.sh

RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/core/autoware_adapi_msgs,target=/autoware/src/core/autoware_adapi_msgs \
  --mount=type=bind,source=src/core/autoware_cmake,target=/autoware/src/core/autoware_cmake \
  --mount=type=bind,source=src/core/autoware_internal_msgs,target=/autoware/src/core/autoware_internal_msgs \
  --mount=type=bind,source=src/core/autoware_lanelet2_extension,target=/autoware/src/core/autoware_lanelet2_extension \
  --mount=type=bind,source=src/core/autoware_msgs,target=/autoware/src/core/autoware_msgs \
  --mount=type=bind,source=src/core/autoware_utils,target=/autoware/src/core/autoware_utils \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM core-common-devel AS core-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-depend /rosdep-core-depend-packages.txt /tmp/rosdep-core-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-core-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && /autoware/cleanup_apt.sh

RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/core/autoware_core,target=/autoware/src/core/autoware_core \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM core-devel AS local_dev_env-common-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-depend /rosdep-local_dev_env-common-depend-packages.txt /tmp/rosdep-local_dev_env-common-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-common-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/common,target=/autoware/src/local_dev_env/autoware_local_dev_env/common \
  --mount=type=bind,source=src/local_dev_env/external/eagleye,target=/autoware/src/local_dev_env/external/eagleye \
  --mount=type=bind,source=src/local_dev_env/external/glog,target=/autoware/src/local_dev_env/external/glog \
  --mount=type=bind,source=src/local_dev_env/external/llh_converter,target=/autoware/src/local_dev_env/external/llh_converter \
  --mount=type=bind,source=src/local_dev_env/external/managed_transform_buffer,target=/autoware/src/local_dev_env/external/managed_transform_buffer \
  --mount=type=bind,source=src/local_dev_env/external/morai_msgs,target=/autoware/src/local_dev_env/external/morai_msgs \
  --mount=type=bind,source=src/local_dev_env/external/muSSP,target=/autoware/src/local_dev_env/external/muSSP \
  --mount=type=bind,source=src/local_dev_env/external/pointcloud_to_laserscan,target=/autoware/src/local_dev_env/external/pointcloud_to_laserscan \
  --mount=type=bind,source=src/local_dev_env/external/rtklib_ros_bridge,target=/autoware/src/local_dev_env/external/rtklib_ros_bridge \
  --mount=type=bind,source=src/local_dev_env/external/tier4_ad_api_adaptor,target=/autoware/src/local_dev_env/external/tier4_ad_api_adaptor \
  --mount=type=bind,source=src/local_dev_env/external/tier4_autoware_msgs,target=/autoware/src/local_dev_env/external/tier4_autoware_msgs \
  --mount=type=bind,source=src/middleware/external,target=/autoware/src/middleware/external \
  --mount=type=bind,source=src/launcher,target=/autoware/src/launcher \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-common-devel-cuda
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set up CUDA development environment
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  ./setup-dev-env.sh -y --module all --no-cuda-drivers openadkit --ros-distro "$ROS_DISTRO" \
  && pipx uninstall ansible \
  && /autoware/cleanup_apt.sh true

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-sensing-perception-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-sensing-perception-depend /rosdep-local_dev_env-sensing-perception-depend-packages.txt /tmp/rosdep-local_dev_env-sensing-perception-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-sensing-perception-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_perception_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_perception_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_sensing_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_sensing_launch \
  --mount=type=bind,source=src/local_dev_env/external/trt_batched_nms,target=/autoware/src/local_dev_env/external/trt_batched_nms \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/perception,target=/autoware/src/local_dev_env/autoware_local_dev_env/perception \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/evaluator/autoware_perception_online_evaluator,target=/autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_perception_online_evaluator \
  --mount=type=bind,source=src/sensor_component,target=/autoware/src/sensor_component \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel-cuda AS local_dev_env-sensing-perception-devel-cuda
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-sensing-perception-depend /rosdep-local_dev_env-sensing-perception-depend-packages.txt /tmp/rosdep-local_dev_env-sensing-perception-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-sensing-perception-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

COPY --from=local_dev_env-sensing-perception-devel /opt/autoware /opt/autoware

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/external/negotiated,target=/autoware/src/local_dev_env/external/negotiated \
  --mount=type=bind,source=src/local_dev_env/external/cuda_blackboard,target=/autoware/src/local_dev_env/external/cuda_blackboard \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/perception,target=/autoware/src/local_dev_env/autoware_local_dev_env/perception \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/common/autoware_cuda_dependency_meta,target=/autoware/src/local_dev_env/autoware_local_dev_env/common/autoware_cuda_dependency_meta \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware "--packages-above-and-dependencies autoware_cuda_dependency_meta"

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-localization-mapping-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-localization-mapping-depend /rosdep-local_dev_env-localization-mapping-depend-packages.txt /tmp/rosdep-local_dev_env-localization-mapping-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-localization-mapping-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_localization_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_localization_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_map_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_map_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/localization,target=/autoware/src/local_dev_env/autoware_local_dev_env/localization \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/map,target=/autoware/src/local_dev_env/autoware_local_dev_env/map \
  # TODO(youtalk): Remove COPYs when https://github.com/autowarefoundation/autoware_local_dev_env/issues/10282 is resolved
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_helpers/autoware_automatic_pose_initializer,target=/autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_helpers/autoware_automatic_pose_initializer \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

FROM local_dev_env-common-devel AS local_dev_env-planning-control-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-planning-control-depend /rosdep-local_dev_env-planning-control-depend-packages.txt /tmp/rosdep-local_dev_env-planning-control-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-planning-control-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_control_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_control_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_planning_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_planning_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/control,target=/autoware/src/local_dev_env/autoware_local_dev_env/control \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/planning,target=/autoware/src/local_dev_env/autoware_local_dev_env/planning \
  # TODO(youtalk): Remove --mount options when https://github.com/autowarefoundation/autoware_local_dev_env/issues/8805 is resolved
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/evaluator/autoware_control_evaluator,target=/autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_control_evaluator \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/evaluator/autoware_planning_evaluator,target=/autoware/src/local_dev_env/autoware_local_dev_env/evaluator/autoware_planning_evaluator \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pcl_extensions \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor,target=/autoware/src/local_dev_env/autoware_local_dev_env/sensing/autoware_pointcloud_preprocessor \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/vehicle/autoware_external_cmd_converter,target=/autoware/src/local_dev_env/autoware_local_dev_env/vehicle/autoware_external_cmd_converter \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/vehicle/autoware_raw_vehicle_cmd_converter,target=/autoware/src/local_dev_env/autoware_local_dev_env/vehicle/autoware_raw_vehicle_cmd_converter \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/system/autoware_command_mode_types,target=/autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_command_mode_types \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-vehicle-system-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-vehicle-system-depend /rosdep-local_dev_env-vehicle-system-depend-packages.txt /tmp/rosdep-local_dev_env-vehicle-system-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-vehicle-system-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_vehicle_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_vehicle_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_system_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_system_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/vehicle,target=/autoware/src/local_dev_env/autoware_local_dev_env/vehicle \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/system,target=/autoware/src/local_dev_env/autoware_local_dev_env/system \
  --mount=type=bind,source=src/core/autoware_core/map/autoware_map_height_fitter,target=/autoware/src/core/autoware_core/map/autoware_map_height_fitter \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/localization/autoware_pose2twist,target=/autoware/src/local_dev_env/autoware_local_dev_env/localization/autoware_pose2twist \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/planning/planning_validator,target=/autoware/src/local_dev_env/autoware_local_dev_env/planning/planning_validator \
  --mount=type=bind,source=src/sensor_component/external/sensor_component_description,target=/autoware/src/sensor_component/external/sensor_component_description \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-visualization-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-visualization-depend /rosdep-local_dev_env-visualization-depend-packages.txt /tmp/rosdep-local_dev_env-visualization-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-visualization-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/visualization,target=/autoware/src/local_dev_env/autoware_local_dev_env/visualization \
  --mount=type=bind,source=src/core/autoware_rviz_plugins,target=/autoware/src/core/autoware_rviz_plugins \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-api-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-api-depend /rosdep-local_dev_env-api-depend-packages.txt /tmp/rosdep-local_dev_env-api-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-api-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

# hadolint ignore=SC1091
RUN --mount=type=cache,target=${CCACHE_DIR} \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch/tier4_autoware_api_launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch/tier4_autoware_api_launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_local_dev_env,target=/autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_default_adapi_local_dev_env \
  --mount=type=bind,source=src/core/autoware_core/api/autoware_adapi_adaptors,target=/autoware/src/core/autoware_core/api/autoware_adapi_adaptors \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/system/autoware_diagnostic_graph_utils,target=/autoware/src/local_dev_env/autoware_local_dev_env/system/autoware_diagnostic_graph_utils \
  --mount=type=bind,source=src/core/autoware_core/map/autoware_map_height_fitter,target=/autoware/src/core/autoware_core/map/autoware_map_height_fitter \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh ${CCACHE_DIR} /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel AS local_dev_env-devel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ENV CCACHE_DIR="/root/.ccache"

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-depend /rosdep-local_dev_env-depend-packages.txt /tmp/rosdep-local_dev_env-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

COPY --from=local_dev_env-sensing-perception-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-localization-mapping-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-planning-control-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-vehicle-system-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-visualization-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-api-devel /opt/autoware /opt/autoware

# strip unneeded symbols from binaries in /opt/autoware
RUN find /opt/autoware -type f \( -executable -o -name "*.so" \) -exec strip --strip-unneeded --remove-section=.comment --remove-section=.note {} \;

# hadolint ignore=SC1091
RUN --mount=type=cache,target="${CCACHE_DIR}" \
  --mount=type=bind,source=src/sensor_component,target=/autoware/src/sensor_component \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/evaluator,target=/autoware/src/local_dev_env/autoware_local_dev_env/evaluator \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/launch,target=/autoware/src/local_dev_env/autoware_local_dev_env/launch \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/simulator,target=/autoware/src/local_dev_env/autoware_local_dev_env/simulator \
  --mount=type=bind,source=src/local_dev_env/autoware_local_dev_env/tools,target=/autoware/src/local_dev_env/autoware_local_dev_env/tools \
  source /opt/ros/"$ROS_DISTRO"/setup.bash \
  && source /opt/autoware/setup.bash \
  && /autoware/build_and_clean.sh "${CCACHE_DIR}" /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

FROM local_dev_env-common-devel-cuda AS local_dev_env-devel-cuda
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install rosdep dependencies
COPY --from=rosdep-local_dev_env-depend /rosdep-local_dev_env-depend-packages.txt /tmp/rosdep-local_dev_env-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update \
  && cat /tmp/rosdep-local_dev_env-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_apt.sh

COPY --from=local_dev_env-devel /opt/autoware /opt/autoware
COPY --from=local_dev_env-sensing-perception-devel-cuda /opt/autoware /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS core
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-depend /rosdep-core-exec-depend-packages.txt /tmp/rosdep-core-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-core-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=core-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-sensing-perception
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-sensing-perception-depend /rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt /tmp/rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-sensing-perception-devel /opt/autoware /opt/autoware
# TODO(youtalk): Fix https://github.com/autowarefoundation/autoware/pull/6235 workaround
COPY --from=local_dev_env-common-devel /opt/autoware/share/autoware_launch /opt/autoware/share/autoware_launch

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_CUDA_IMAGE AS local_dev_env-sensing-perception-cuda
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-sensing-perception-depend /rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt /tmp/rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-sensing-perception-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-sensing-perception-devel-cuda /opt/autoware /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-localization-mapping
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-localization-mapping-depend /rosdep-local_dev_env-localization-mapping-exec-depend-packages.txt /tmp/rosdep-local_dev_env-localization-mapping-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-localization-mapping-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-localization-mapping-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-planning-control
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-planning-control-depend /rosdep-local_dev_env-planning-control-exec-depend-packages.txt /tmp/rosdep-local_dev_env-planning-control-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-planning-control-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-planning-control-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-vehicle-system
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-vehicle-system-depend /rosdep-local_dev_env-vehicle-system-exec-depend-packages.txt /tmp/rosdep-local_dev_env-vehicle-system-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-vehicle-system-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-vehicle-system-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-visualization
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-visualization-depend /rosdep-local_dev_env-visualization-exec-depend-packages.txt /tmp/rosdep-local_dev_env-visualization-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-visualization-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-visualization-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env-api
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-api-depend /rosdep-local_dev_env-api-exec-depend-packages.txt /tmp/rosdep-local_dev_env-api-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-local_dev_env-api-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-api-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_IMAGE AS local_dev_env
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-depend /rosdep-exec-depend-packages.txt /tmp/rosdep-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-devel /opt/autoware /opt/autoware

# Copy bash aliases
COPY docker/etc/.bash_aliases /root/.bash_aliases
RUN echo "source /opt/autoware/setup.bash" > /etc/bash.bashrc

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# hadolint ignore=DL3006
FROM $AUTOWARE_BASE_CUDA_IMAGE AS local_dev_env-cuda
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG LIB_DIR

# Set up runtime environment
COPY --from=rosdep-local_dev_env-depend /rosdep-exec-depend-packages.txt /tmp/rosdep-exec-depend-packages.txt
# hadolint ignore=SC2002
RUN --mount=type=ssh \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  ./setup-dev-env.sh -y --module all --no-nvidia --no-cuda-drivers --runtime openadkit --ros-distro $ROS_DISTRO \
  && pipx uninstall ansible \
  && apt-get update \
  && cat /tmp/rosdep-exec-depend-packages.txt | xargs apt-get install -y --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && /autoware/cleanup_system.sh $LIB_DIR $ROS_DISTRO

COPY --from=local_dev_env-devel-cuda /opt/autoware /opt/autoware

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]
