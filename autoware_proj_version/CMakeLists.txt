cmake_minimum_required(VERSION 3.5)
project(autoware_proj_version)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()

# Workaround for files not updating by rebuild.
# ament_index_register_resource(autoware_metadata_packages CONTENT_FILE resource/version.json)
install(
  FILES "resource/version.json"
  DESTINATION "share/ament_index/resource_index/autoware_metadata_packages"
  RENAME "${PROJECT_NAME}"
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_auto_package()
