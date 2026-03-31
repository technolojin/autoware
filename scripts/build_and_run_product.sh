#!/bin/bash

# shellcheck disable=SC1090,1091
set -e

# Default values
CLEAN_BUILD=false
ROSDEP_RUN=false
REMOTE_PRODUCT=""
REMOTE_BRANCH=""
LOCAL_PRODUCT_PATH=""

# Display help information
show_help() {
    echo "Usage: $0 [OPTIONS] (--remote PRODUCT_NAME | --local PRODUCT_PATH)"
    echo ""
    echo "Options:"
    echo "  --remote PRODUCT_NAME     Use remote repo: tier4/pilot-auto.{PRODUCT_NAME}"
    echo "  --local PRODUCT_PATH      Use local repo at PRODUCT_PATH"
    echo "  --branch BRANCH          Branch to checkout for remote repo (default: repo default)"
    echo "  --clean|-c               Clean build (removes src/, build/, install/) before building"
    echo "  --rosdep                 Run rosdep install before building"
    echo "  --help|-h                Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --remote xx1 --branch main --clean --rosdep"
    echo "  $0 --local /path/to/local/repo"
    echo ""
}

# Source ROS and sync version
source_setup() {
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

    release_info_file="$PRODUCT_PATH/.release_info.yaml"

    # check sync version in .release_info.yaml
    sync_version=$(yq -r '.parent_repository.sync_version' "$release_info_file")
    if [ -z "$sync_version" ]; then
        echo "Error: Could not determine sync version from $release_info_file"
        exit 1
    fi
    if [ -f "$HOME/.pilot-auto/$ROS_DISTRO/$sync_version/install/setup.bash" ]; then
        # check if sync version is installed in ~/.pilot-auto/$ROS_DISTRO/$sync_version
        echo "Sync version $sync_version is installed. Proceeding..."

        VANILLA_DIR="$HOME/.pilot-auto/$ROS_DISTRO/$sync_version"
        source "$VANILLA_DIR/install/setup.bash"
    elif [ -f "$HOME/.pilot-auto/$sync_version/install/setup.bash" ] && [ "$ROS_DISTRO" = "humble" ]; then
        # backward compatibility for old directory structure
        echo "Sync version $sync_version is installed in the old directory structure. Proceeding..."

        VANILLA_DIR="$HOME/.pilot-auto/$sync_version"
        source "$VANILLA_DIR/install/setup.bash"
    else
        echo "Sync version $sync_version is not installed. Please install vanilla pilot auto first."
        exit 1
    fi

    # Source local setup if it exists
    if [ -f install/setup.bash ]; then
        source install/setup.bash
    fi
}

# Import base=false repositories
import_repos() {
    mkdir -p src/

    tmp_product_repos=$(mktemp)
    yq e '.repositories | with_entries(select(.value.base == false))' autoware.repos |
        yq e '{"repositories": .}' - >"$tmp_product_repos"

    echo "Repositories to import:"
    cat "$tmp_product_repos"

    vcs import src <"$tmp_product_repos"
}

# Helper to clean workspace directories
clean_workspace_dirs() {
    for dir in src install build; do
        if [ -d "$dir" ]; then
            echo "Removing existing $dir/ directory..."
            rm -rf "${dir:?}/"
        fi
    done
}

# Unified build function
build_workspace() {
    if [ "$CLEAN_BUILD" = true ]; then
        echo "Performing clean build..."
        clean_workspace_dirs
        import_repos
    else
        echo "Building with existing src/ directory..."
        if [ ! -d "src" ] || [ -z "$(ls -A src/ 2>/dev/null)" ]; then
            echo "src/ directory is empty or doesn't exist. Importing repositories first..."
            import_repos
        fi
    fi
    if [ "$ROSDEP_RUN" = true ]; then
        echo "Running rosdep install..."
        export ROS_DISTRO=${ROS_DISTRO:-humble}
        sudo apt update && sudo apt upgrade -y
        rosdep update
        rosdep install -y --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"
    fi
    echo "Building packages..."
    # products may have some packages that fail to build (e.g. packages not used in the main ECU)
    # we continue on error and then build autoware_launch separately to ensure it gets built
    colcon build --merge-install --cmake-args -DCMAKE_BUILD_TYPE=Release --continue-on-error || true
    colcon build --merge-install --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-select autoware_launch
    source install/setup.bash
    echo "Build completed."
}

# Print the simulator launch guide command
print_simulator_guide_command() {
    source defaults.env
    MAP_PATH="$HOME/autoware_map/sample-map-planning"

    echo "Simulator launch command (from a fresh terminal):"
    echo ""
    echo "source $PRODUCT_PATH/install/setup.bash"
    echo "ros2 launch autoware_launch planning_simulator.launch.xml map_path:=\"$MAP_PATH\" vehicle_model:=\"$VEHICLE_MODEL\" sensor_model:=\"$SENSOR_MODEL\""
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
    --remote)
        shift
        if [ -n "$REMOTE_PRODUCT" ] || [ -n "$LOCAL_PRODUCT_PATH" ]; then
            echo "Error: Only one of --remote or --local can be specified."
            show_help
            exit 1
        fi
        REMOTE_PRODUCT="$1"
        shift
        ;;
    --local)
        shift
        if [ -n "$REMOTE_PRODUCT" ] || [ -n "$LOCAL_PRODUCT_PATH" ]; then
            echo "Error: Only one of --remote or --local can be specified."
            show_help
            exit 1
        fi
        LOCAL_PRODUCT_PATH="$1"
        shift
        ;;
    --branch)
        shift
        REMOTE_BRANCH="$1"
        shift
        ;;
    --clean | -c)
        CLEAN_BUILD=true
        shift
        ;;
    --rosdep)
        ROSDEP_RUN=true
        shift
        ;;
    --help | -h)
        show_help
        exit 0
        ;;
    *)
        echo "Unknown option or argument: $1"
        show_help
        exit 1
        ;;
    esac
done

# Require exactly one of remote or local
if [ -z "$REMOTE_PRODUCT" ] && [ -z "$LOCAL_PRODUCT_PATH" ]; then
    echo "Error: You must specify either --remote or --local."
    show_help
    exit 1
fi

# Handle remote product logic
if [ -n "$REMOTE_PRODUCT" ]; then
    REMOTE_REPO="https://github.com/tier4/pilot-auto.${REMOTE_PRODUCT}.git"
    CLONE_DIR=$(mktemp -d)
    echo "Cloning $REMOTE_REPO into $CLONE_DIR ..."
    if [ -n "$REMOTE_BRANCH" ]; then
        git clone --branch "$REMOTE_BRANCH" --single-branch "$REMOTE_REPO" "$CLONE_DIR"
    else
        git clone --single-branch "$REMOTE_REPO" "$CLONE_DIR"
    fi
    PRODUCT_PATH="$CLONE_DIR"
    echo "Cloned remote repo. Using PRODUCT_PATH: $PRODUCT_PATH"
else
    PRODUCT_PATH="$LOCAL_PRODUCT_PATH"
fi

# Change to the product directory
if [ ! -d "$PRODUCT_PATH" ]; then
    echo "Error: Product path '$PRODUCT_PATH' does not exist or is not a directory"
    exit 1
fi

echo "Changing to product directory: $PRODUCT_PATH"
cd "$PRODUCT_PATH" || {
    echo "Failed to change to directory $PRODUCT_PATH"
    exit 1
}

# Source environment
source_setup

# Build the workspace
build_workspace

echo ""
echo "Workspace was built in: $PRODUCT_PATH"
print_simulator_guide_command
