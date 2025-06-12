# Pilot.Auto Scripts

This directory contains helper scripts for working with Pilot.Auto and its products.

## 1. Installing the Pilot.Auto Base

To install the base version of Pilot.Auto, use the `install-base.sh` script:

```bash
./install-base.sh v0.45.0
```

- This will clone the base repository, build it, and install it under `~/.pilot-auto/v0.45.0` by default.
- You can specify a different install directory with `--install-dir`:

```bash
./install-base.sh v0.45.0 --install-dir /path/to/install
```

If you omit the version, the script will prompt you to install the latest available version.

## 2. Building and Running a Product

To build and/or run a Pilot.Auto product, use the `build_and_run_product.sh` script. This script supports both local and remote product repositories.

### Usage

```bash
./build_and_run_product.sh [OPTIONS] (--remote PRODUCT_NAME | --local PRODUCT_PATH)
```

### Main Options

- `--remote PRODUCT_NAME` Use remote repo: tier4/pilot-auto.{PRODUCT_NAME}
- `--local PRODUCT_PATH` Use local repo at PRODUCT_PATH
- `--branch BRANCH` Branch to checkout for remote repo
- `--clean, -c` Clean build (removes src/, build/, install/) before building
- `--rosdep` Run rosdep install before building
- `--map PATH` Set the map path
- `--vehicle MODEL` Set the vehicle model
- `--sensor MODEL` Set the sensor model
- `--run, -r` Run the simulator after building
- `--source-mode, --only-run` Only run the simulator (skip build, local repo only)
- `--help, -h` Display help message

### Common Use Cases

- **Build only (remote):**

  ```bash
  ./build_and_run_product.sh --remote xx1 --branch main --clean --rosdep
  ```

- **Build and run (local):**

  ```bash
  ./build_and_run_product.sh --local /path/to/repo --run
  ```

- **Only run (source mode, local only):**

  ```bash
  ./build_and_run_product.sh --local /path/to/repo --source-mode
  ```

- **After a remote build:**
  The script will print the path where the product was built and how to run it later, e.g.:

  ```bash
  ./build_and_run_product.sh --local /tmp/tmp.xxxxxxxx --source-mode
  ```

### Notes

- The script automatically sources the correct base environment as specified in your product's `.release_info.yaml`.
- `--source-mode`/`--only-run` is only valid for local repositories and requires a prior build.
- For more options, run `./build_and_run_product.sh --help` or `./install-base.sh --help`.
- **If you plan to run multiple products from the same terminal, run each script in a subshell to avoid environment variable conflicts:**

  ```bash
  ( ./build_and_run_product.sh --local /path/to/product --run )
  ( ./build_and_run_product.sh --remote xx1 --run )
  ```

  This ensures that environment variables set by one product do not affect others.

## Troubleshooting: yq File Not Found Errors

If you encounter errors like:

```bash
Error: open <file>: no such file or directory
```

when running `yq` commands, especially on files in `/tmp` or other temporary directories, and you have installed `yq` via **snap**, this may be due to a known bug in the snap version of `yq` that restricts file access in certain directories.

### Solution

1. **Uninstall the snap version of yq:**

   ```bash
   sudo snap remove yq
   ```

2. **Install the latest Go version of yq directly from the official binary:**

   ```bash
   wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
   chmod +x /usr/local/bin/yq
   ```

This will ensure you have the latest version of `yq` with full file access. For more details, see: <https://github.com/mikefarah/yq>
