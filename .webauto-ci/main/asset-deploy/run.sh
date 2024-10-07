#!/bin/bash -e

: "${WEBAUTO_CI_ML_PACKAGES_PATH:=}"

: "${ML_MODELS_PATH:=}"

if [ -n "$WEBAUTO_CI_ML_PACKAGES_PATH" ] && [ -n "$ML_MODELS_PATH" ]; then
    # Ensure ML_MODELS_PATH exists and is owned by the current user
    sudo mkdir -p "$ML_MODELS_PATH"
    sudo chown -R "$(id -u):$(id -g)" "$ML_MODELS_PATH"

    # Copy files to target path
    src_path="${WEBAUTO_CI_ML_PACKAGES_PATH%/}" # Remove trailing slash if present
    cp -R "${src_path}/." "$ML_MODELS_PATH/"

    find "$ML_MODELS_PATH" -type d -exec chmod 755 {} +
    find "$ML_MODELS_PATH" -type f -exec chmod 644 {} +

    echo "The following ML models have been deployed:"
    ls "$ML_MODELS_PATH"
fi
