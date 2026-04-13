#!/bin/bash
set -e

CURRENT_DIR=$(readlink -f "$(dirname "$0")")
CONTEXT_DIR="$CURRENT_DIR/context"
WORKSPACE_ROOT=$(readlink -f "$CURRENT_DIR/..")

# Check github-token file specified.
if [ -z "$1" ]; then
    echo "github-token file is required"
    exit 1
fi

ros_distro=humble
targets=("default")
github_token=$1
build_cuda=${2:-false}

echo "Settings:"
echo "- ros-distro: $ros_distro"
echo "- github-token: $github_token"
echo "- build-cuda: $build_cuda"
echo
echo -n "OK? [Y/n]: "
read -r ANS

case $ANS in
"" | [Yy]*) ;;
*)
    exit
    ;;
esac

# Prepare build context
mkdir -p "$CONTEXT_DIR/setup"
cd "$WORKSPACE_ROOT"
cp setup-dev-env.sh ansible-galaxy-requirements.yaml amd64.env arm64.env "$CONTEXT_DIR/setup"
cp -r ansible "$CONTEXT_DIR/setup"

# Set build targets
if "$build_cuda"; then
    targets+=("cuda")
fi

# Build docker images
docker buildx bake --load --progress=plain -f "$CURRENT_DIR/docker-bake-base.hcl" \
    --set "*.context=$CONTEXT_DIR" \
    --set "*.secrets=type=file,id=github_token,src=$github_token" \
    --set "*.args.ROS_DISTRO=$ros_distro" \
    "${targets[@]}"
