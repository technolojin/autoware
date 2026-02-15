#!/bin/bash

# shellcheck disable=SC1090,1091
set -e

# Default values
MAP_PATH="$HOME/autoware_map/sample-map-planning"
V2X_LOCATION="komatsu"
RUN_SIMULATOR=false
CLEAN_BUILD=false
ROSDEP_RUN=false
REMOTE_PRODUCT=""
REMOTE_BRANCH=""
LOCAL_PRODUCT_PATH=""
SOURCE_MODE=false

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
    echo "  --map PATH               Set the map path (default: $MAP_PATH)"
    echo "  --vehicle MODEL          Set the vehicle model (default: set in defaults.env)"
    echo "  --sensor MODEL           Set the sensor model (default: set in defaults.env)"
    echo "  --run|-r                 Run the simulator after building"
    echo "  --source-mode|--only-run Only run the simulator (skip build, local repo only)"
    echo "  --help|-h                Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --remote xx1 --branch main --clean --rosdep"
    echo "  $0 --local /path/to/local/repo --run"
    echo "  $0 --local /path/to/local/repo --source-mode"
    echo ""
}

# Source ROS and sync version
source_setup() {
    # Source ROS Humble setup
    if [ -f "/opt/ros/humble/setup.bash" ]; then
        source /opt/ros/humble/setup.bash
    else
        echo "ROS Humble setup.bash not found. Please make sure ROS Humble is installed."
        exit 1
    fi

    #check sync version in .release_info.yaml
    sync_version=$(yq -r '.parent_repository.sync_version' .release_info.yaml)
    # check if sync version is installed in ~/.pilot-auto/$version
    if [ -f ~/.pilot-auto/"$sync_version"/install/setup.bash ]; then
        echo "Sync version $sync_version is installed. Proceeding..."
        source ~/.pilot-auto/"$sync_version"/install/setup.bash
    else
        echo "Sync version $sync_version is not installed. Please install base pilot auto first."
        exit 1
    fi

    # Source local setup if it exists
    if [ -f install/setup.bash ]; then
        source install/setup.bash
    fi
}

# Import repositories
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
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
    source install/setup.bash
    echo "Build completed."
}

# Run the simulator
run_simulator() {
    echo "Launching the simulator with:"
    echo "  Map path: $MAP_PATH"
    echo "  Vehicle model: $VEHICLE_MODEL"
    echo "  Sensor model: $SENSOR_MODEL"
    echo "  V2X location: $V2X_LOCATION"

    ros2 launch autoware_launch planning_simulator.launch.xml map_path:="$MAP_PATH" vehicle_model:="$VEHICLE_MODEL" sensor_model:="$SENSOR_MODEL" v2x_location:="$V2X_LOCATION"
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
    --map)
        shift
        MAP_PATH="$1"
        shift
        ;;
    --vehicle)
        shift
        VEHICLE_MODEL="$1"
        shift
        ;;
    --sensor)
        shift
        SENSOR_MODEL="$1"
        shift
        ;;
    --run | -r)
        RUN_SIMULATOR=true
        shift
        ;;
    --source-mode | --only-run)
        SOURCE_MODE=true
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

# --source-mode/--only-run is only valid for local repo
if [ "$SOURCE_MODE" = true ] && [ -n "$REMOTE_PRODUCT" ]; then
    echo "Error: --source-mode/--only-run can only be used with --local."
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
        git clone "$REMOTE_REPO" "$CLONE_DIR"
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
source defaults.env

# Source environment
source_setup

# If --source-mode/--only-run, skip build and just run
if [ "$SOURCE_MODE" = true ]; then
    if [ ! -f "install/setup.bash" ]; then
        echo "Error: In source mode, could not find install/setup.bash. Please build the workspace first."
        exit 1
    fi
    run_simulator
    exit 0
fi

# Build the workspace
build_workspace

# Optionally run the simulator
if [ "$RUN_SIMULATOR" = true ]; then
    run_simulator
elif [ -n "$REMOTE_PRODUCT" ] && [ "$SOURCE_MODE" = false ]; then
    echo ""
    echo "Remote product was built in: $PRODUCT_PATH"
    echo "To run the simulator later, use:"
    echo "  $0 --local $PRODUCT_PATH --source-mode"
    echo "(You may also add --map, --vehicle, or --sensor options as needed.)"
fi
