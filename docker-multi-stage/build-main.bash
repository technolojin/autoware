#!/bin/bash
set -e

CURRENT_DIR=$(readlink -f "$(dirname "$0")")
WORKSPACE_ROOT=$(readlink -f "$CURRENT_DIR/..")

ros_distro=humble
update_context=true
use_ghcr=false
context_dir="$CURRENT_DIR/context"
vcs_src_dir="${WORKSPACE_ROOT}/src"
confirm=true

# Parse arguments
while (($# > 0)); do
    case "$1" in
    --no-update)
        update_context=false
        shift
        ;;
    --use-ghcr)
        use_ghcr=true
        shift
        ;;
    --yes)
        confirm=false
        shift
        ;;
    --ros-distro)
        ros_distro="$2"
        shift 2
        ;;
    --context-dir)
        context_dir="$2"
        shift 2
        ;;
    --vcs-src-dir)
        vcs_src_dir="$2"
        shift 2
        ;;
    *)
        targets+=("$1")
        shift
        ;;
    esac
done

if "$use_ghcr"; then
    base_image_runtime=ghcr.io/tier4/pilot-auto/base-image-only-setup:latest
    base_image_build=ghcr.io/tier4/pilot-auto/base-image-only-setup:latest
else
    base_image_runtime=pilot-auto-base-image:runtime
    base_image_build=pilot-auto-base-image:build
fi

echo "Settings:"
echo "- update-context: $update_context"
echo "- ros-distro: $ros_distro"
echo "- base-image-runtime: $base_image_runtime"
echo "- base-image-build: $base_image_build"
echo "- targets: ${targets[*]}"
echo

if "$confirm"; then
    echo -n "OK? [Y/n]: "
    read -r ANS

    case $ANS in
    "" | [Yy]*) ;;
    *)
        exit
        ;;
    esac
fi

# Check src directory exists
if [ ! -e "${vcs_src_dir}" ]; then
    echo "src directory does not exist"
    exit 1
fi

# Prepare build context
if "$update_context"; then
    bash "${CURRENT_DIR}/script/update-context.bash" "${vcs_src_dir}" "${context_dir}"
fi

# Build docker images
docker buildx bake --load --progress=plain -f "$CURRENT_DIR/docker-bake-main.hcl" \
    --set "*.context=$context_dir" \
    --set "*.args.ROS_DISTRO=$ros_distro" \
    --set "*.args.BASE_IMAGE_RUNTIME=$base_image_runtime" \
    --set "*.args.BASE_IMAGE_BUILD=$base_image_build" \
    "${targets[@]}"
