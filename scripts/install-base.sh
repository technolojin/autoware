#!/bin/bash
set -e

# Default values
PILOT_AUTO_INSTALL_BASE_DIR=~/.pilot-auto
VERSION=""

# Parse command line arguments
positional_args=()
i=0
while [ $i -lt $# ]; do
    i=$((i + 1))
    arg="${!i}"

    case $arg in
    --install-dir=*)
        PILOT_AUTO_INSTALL_BASE_DIR="${arg#*=}"
        ;;
    --install-dir)
        if [ $i -lt $# ]; then
            i=$((i + 1))
            PILOT_AUTO_INSTALL_BASE_DIR="${!i}"
        else
            echo "Error: --install-dir requires a value"
            echo "Usage: $0 [VERSION] [--install-dir=/path/to/install]"
            exit 1
        fi
        ;;
    -*)
        echo "Unknown option: $arg"
        echo "Usage: $0 [VERSION] [--install-dir=/path/to/install]"
        exit 1
        ;;
    *)
        positional_args+=("$arg")
        ;;
    esac
done

# Handle positional arguments (version)
if [ ${#positional_args[@]} -gt 0 ]; then
    VERSION="${positional_args[0]}"
fi

# If version is not specified, prompt to install latest
if [ -z "$VERSION" ]; then
    echo "Version not specified. Would you like to install the latest version? (Y/n)"
    read -r install_latest
    if [[ $install_latest =~ ^[Yy]$ ]] || [[ -z $install_latest ]]; then
        USE_LATEST=true
    else
        echo "Please specify a version as the first argument (e.g., $0 v0.64.1)"
        exit 1
    fi
fi

# Clone the repository into tmp directory
tmp_pilot_auto_install_repo=$(mktemp -d)
echo "Cloning pilot-auto repository..."
git clone git@github.com:tier4/pilot-auto.git "$tmp_pilot_auto_install_repo"
cd "$tmp_pilot_auto_install_repo"

# If using latest version, determine what it is (the largest vX.Y.Z)
if [ "$USE_LATEST" = true ]; then
    echo "Fetching latest version tag..."
    git fetch --tags --quiet
    latest_tag=$(git tag -l "v*.*.*" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
    if [ -z "$latest_tag" ]; then
        echo "Failed to determine latest version. Please specify a version manually."
        exit 1
    fi
    VERSION="$latest_tag"
    echo "Installing latest version: $VERSION"
fi

# Checkout the version
git checkout "$VERSION"

# Wait up to 5 seconds for autoware.repos to appear
for i in {1..5}; do
    if [ -f "autoware.repos" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "autoware.repos" ]; then
    echo "Error: autoware.repos not found in the repository at $VERSION after waiting."
    ls -l
    exit 1
fi

# Source ROS Humble or Jazzy setup
if [ -f "/opt/ros/jazzy/setup.bash" ]; then
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
elif [ -f "/opt/ros/humble/setup.bash" ]; then
    # shellcheck disable=SC1091
    source /opt/ros/humble/setup.bash
else
    echo "ROS not found. Please make sure ROS Humble or Jazzy is installed."
    exit 1
fi

# Create installation directory (at this point $ROS_DISTRO should be set)
PILOT_AUTO_INSTALL_DIR="$PILOT_AUTO_INSTALL_BASE_DIR/$ROS_DISTRO/$VERSION"
mkdir -p "$PILOT_AUTO_INSTALL_DIR"

# extract base repositories
# base=true / base=false is a rough way to provide reusable cache
# before full dependency analysis and caching is implemented
echo "Extracting base repositories..."
yq e '.repositories | with_entries(select(.value.base == true))' autoware.repos |
    yq e '{"repositories": .}' - >"$PILOT_AUTO_INSTALL_DIR/base.repos"

cd "$PILOT_AUTO_INSTALL_DIR"
mkdir -p src
vcs import src <base.repos

colcon build --merge-install --cmake-args -DCMAKE_BUILD_TYPE=Release

printf "\n\n\nInstallation completed successfully. %s/base.repos are installed. To use them, source the setup.bash file in the %s directory.\n" "$PILOT_AUTO_INSTALL_DIR" "$PILOT_AUTO_INSTALL_DIR"
