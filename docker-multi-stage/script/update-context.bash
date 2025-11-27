#!/bin/bash
set -eu

: "${1:?Arg1 is not set}"
: "${2:?Arg2 is not set}"

VCS_DIR="$1"
PKG_DIR="$2/pkg"
SRC_DIR="$2/src"

function generate_colcon_depends() {
    search_paths="${PKG_DIR}/search-paths-${1}.txt"
    colcon_names="${PKG_DIR}/colcon-names-${1}.txt"
    colcon_paths="${PKG_DIR}/colcon-paths-${1}.txt"

    xargs -a "${search_paths}" -I {} colcon list --names-only --base-paths "${VCS_DIR}/{}" >"${colcon_names}"
    sort -u "${colcon_names}" -o "${colcon_names}"

    xargs -a "${colcon_names}" colcon list --paths-only --base-paths "${VCS_DIR}" --packages-up-to >"${colcon_paths}"
    sort -u "${colcon_paths}" -o "${colcon_paths}"
}

function exclude_common_depends() {
    target="${PKG_DIR}/colcon-paths-${1}.txt"
    common="${PKG_DIR}/colcon-paths-${2}.txt"
    tmp="${PKG_DIR}/tmp.txt"

    comm -2 -3 "${target}" "${common}" >"${tmp}" && mv "${tmp}" "${target}"
}

function append_common_depends() {
    target="${PKG_DIR}/colcon-paths-${1}.txt"
    common="${PKG_DIR}/colcon-paths-${2}.txt"

    cat "${target}" >>"${common}" && sort -u "${common}" -o "${common}"
}

function clone_packages() {
    target="${PKG_DIR}/colcon-paths-${1}.txt"
    prefix="${SRC_DIR}/${1}"

    # shellcheck disable=SC2016
    mkdir -p "${prefix}" && xargs -a "${target}" -I {} bash -c 'cp -r {} ${1}/$(basename {})' -- "${prefix}"
}

# TODO set rosdistro
function generate_rosdep_depends() {
    prefix="${SRC_DIR}/${1}"

    unset AMENT_PREFIX_PATH
    unset ROS_PACKAGE_PATH
    ROS_PACKAGE_PATH=${VCS_DIR} rosdep keys --ignore-src --from-paths "${prefix}" | xargs rosdep resolve --rosdistro humble | grep -v '^#' | sed 's/ \+/\n/g' | sort -u >"${PKG_DIR}/rosdep-build-${1}.txt"
    ROS_PACKAGE_PATH=${VCS_DIR} rosdep keys --ignore-src --from-paths "${prefix}" -t exec | xargs rosdep resolve --rosdistro humble | grep -v '^#' | sed 's/ \+/\n/g' | sort -u >"${PKG_DIR}/rosdep-exec-${1}.txt"
}

# Check src directory exists.
if [ ! -e "${VCS_DIR}" ]; then
    echo "vcs directory does not exist"
    exit 1
fi

# Remove old files
find "${PKG_DIR}" -type f -name "colcon-*" -delete
find "${PKG_DIR}" -type f -name "rosdep-*" -delete
rm -rf "${SRC_DIR}"

# Prepare exclude file.
echo -n >"${PKG_DIR}/colcon-paths-exclude.txt"

# Resolve common package dependencies.
modules=("tier4-ros" "core-common" "core-all" "universe-common")
for module in "${modules[@]}"; do
    echo "update context for ${module}"
    generate_colcon_depends "${module}"
    exclude_common_depends "${module}" exclude
    append_common_depends "${module}" exclude
    clone_packages "${module}"
    generate_rosdep_depends "${module}"
done

# Resolve component package dependencies.
components=("localization-mapping" "planning-control" "vehicle-system" "sensing-perception" "api" "visualization" "simulation" "evaluation")
for component in "${components[@]}"; do
    echo "update context for ${component}"
    generate_colcon_depends "${component}"
    exclude_common_depends "${component}" exclude
    clone_packages "${component}"
    generate_rosdep_depends "${component}"
done

# Workaround for launcher package.
echo "copy launcher"
cp -r "${VCS_DIR}/autoware/launcher" "${SRC_DIR}/launcher"

# Remove git directory
find "${SRC_DIR}" -type d -name .git -exec rm -rf {} +
