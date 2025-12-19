# Docker images

## Build base images

Building the base image requires a GitHub token. Create a private access token and save it as a file with any name.
This document assumes the file path is `~/github-token`. Note that the file should not contain any line breaks.

1. Run the build script with the following command. The `<build-cuda>` argument should be either `true` or `false`.

   ```bash
   ./build-base.bash ~/github-token <build-cuda>
   ```

2. Check the build configuration and proceed.

   ```bash
   Settings:
   - ros-distro: humble
   - github-token: /home/user-name/github-token
   - build-cuda: false

   OK? [Y/n]:
   ```

3. Check that the following images have been built.
   - pilot-auto-base-image:runtime
   - pilot-auto-base-image:runtime-cuda
   - pilot-auto-base-image:build
   - pilot-auto-base-image:build-cuda

## Build main images

1. Run the build script with the following command.

   ```bash
   ./build-base.bash [options]
   ```

2. Check the build configuration and proceed.

   ```bash
   Settings:
   - update-context: true
   - ros-distro: humble
   - base-image-runtime: pilot-auto:base-image-runtime
   - base-image-build: pilot-auto:base-image-build
   - targets:

   OK? [Y/n]:
   ```

3. Check that the following images have been built.
   - pilot-auto:universe-all
   - pilot-auto:planning-control
   - pilot-auto:localization-mapping
   - pilot-auto:sensing-perception
   - pilot-auto:vehicle-system
   - pilot-auto:api
   - pilot-auto:visualization
   - pilot-auto:simulation

## Build CUDA images

1. Run the build script with the following command. The `--no-update` option is recommended if the source code has not been updated.

   ```bash
   ./build-cuda.bash --no-update [options]
   ```

2. Check the build configuration and proceed.

   ```bash
   Settings:
   - update-context: false
   - ros-distro: humble
   - base-image-runtime: pilot-auto-base-image:runtime-cuda
   - base-image-build: pilot-auto-base-image:build-cuda
   - targets:

   OK? [Y/n]:
   ```

3. Check that the following images have been built.
   - pilot-auto:sensing-perception-cuda

## Planning simulation

1. Edit the following values ​​in the `planning-simulation.env` according to your environment.

   | Value    | Description                         |
   | -------- | ----------------------------------- |
   | MAP_PATH | Directory where the map is located. |

2. Tune the [network settings](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/#tune-system-wide-network-settings) on the host.

   ```bash
   sudo sysctl -w net.core.rmem_max=2147483647
   sudo sysctl -w net.ipv4.ipfrag_time=3
   sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
   ```

3. Run the following command.

   ```bash
   xhost +local:
   docker compose --env-file planning-simulation.env --profile planning-simulation --profile visualization up
   ```

## Logging simulation

1. Edit the following values ​​in the `logging-simulation.env` according to your environment.

   | Value       | Description                                                       |
   | ----------- | ----------------------------------------------------------------- |
   | MAP_PATH    | Directory where the map is located.                               |
   | DATA_PATH   | Directory where ONNX model files and other artifacts are located. |
   | ROSBAG_PATH | Directory where the ROSBAG file is located.                       |

2. Tune the [network settings](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/#tune-system-wide-network-settings) on the host.

   ```bash
   sudo sysctl -w net.core.rmem_max=2147483647
   sudo sysctl -w net.ipv4.ipfrag_time=3
   sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
   ```

3. Run the following command.

   ```bash
   xhost +local:
   docker compose --env-file logging-simulation.env --profile logging-simulation --profile visualization up
   ```
