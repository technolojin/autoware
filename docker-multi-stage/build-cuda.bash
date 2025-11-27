#!/bin/bash
set -e

CURRENT_DIR=$(readlink -f "$(dirname "$0")")
CONTEXT_DIR="$CURRENT_DIR/context"
WORKSPACE_ROOT=$(readlink -f "$CURRENT_DIR/..")

ros_distro=humble
update_context=true
use_ghcr=false

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
    *)
        targets+=("$1")
        shift
        ;;
    esac
done

if "$use_ghcr"; then
    echo "currently, CUDA base images are not supported in the GHCR"
    exit 1
else
    base_image_runtime=pilot-auto-base-image:runtime-cuda
    base_image_build=pilot-auto-base-image:build-cuda
fi

echo "Settings:"
echo "- update-context: $update_context"
echo "- ros-distro: $ros_distro"
echo "- base-image-runtime: $base_image_runtime"
echo "- base-image-build: $base_image_build"
echo "- targets: ${targets[*]}"
echo

echo -n "OK? [Y/n]: "
read -r ANS

case $ANS in
"" | [Yy]*) ;;
*)
    exit
    ;;
esac

# Check src directory exists
if [ ! -e "${WORKSPACE_ROOT}/src" ]; then
    echo "src directory does not exist"
    exit 1
fi

# Prepare build context
if "$update_context"; then
    bash "${CURRENT_DIR}/script/update-context.bash" "${WORKSPACE_ROOT}/src" "${CONTEXT_DIR}"
fi

# Build docker images
docker buildx bake --load --progress=plain -f "$CURRENT_DIR/docker-bake-cuda.hcl" \
    --set "*.context=$CONTEXT_DIR" \
    --set "*.args.ROS_DISTRO=$ros_distro" \
    --set "*.args.BASE_IMAGE_RUNTIME=$base_image_runtime" \
    --set "*.args.BASE_IMAGE_BUILD=$base_image_build" \
    "${targets[@]}"
