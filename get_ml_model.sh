#!/bin/bash

# path to .webauto-ci.yml
file_path="./.webauto-ci.yml"

if ! (type "webauto" >/dev/null 2>&1); then
    echo -e "\e[31mPlease Install webauto cli.\e[m"
    echo -e "\e[31mhttps://github.com/tier4/WebAutoCLI\e[m"
    exit 1
fi

sudo mkdir -p /opt/autoware/mlmodels/
sudo rm -rf /opt/autoware/mlmodels/*

# get name and release in ml_packages
ml_packages=$(awk '/ml_packages:/,/^[^ ]/{if(/name:/){sub(/^[[:space:]]*-?[[:space:]]*name:[[:space:]]*/,""); name=$0} else if(/release:/){sub(/^[[:space:]]*-?[[:space:]]*release:[[:space:]]*/,""); release=$0; printf "%s %s\n", name, release}}' "$file_path")

if [ -z "$ml_packages" ]; then
    echo -e "\e[31mError: ml_packages is not found in .webauto-ci.yml\e[m"
    exit 1
fi

while read -r line; do
    ml_packages_name=$(echo "$line" | awk '{print $1}')
    ml_packages_release=$(echo "$line" | awk '{print $2}')
    echo "ml_packages_name: $ml_packages_name"

    # search release
    res=$(webauto ml package-release search \
        --project-id prd_jt \
        --package-name "$ml_packages_name" \
        --package-release-name "$ml_packages_release" \
        --output json --quiet)

    release=$(echo "$res" | jq -c '.releases[0]')

    package_id=$(echo "$release" | jq -r '.package_id')
    release_id=$(echo "$release" | jq -r '.id')

    # download release
    echo "start downloading the release $ml_packages_name [$release_id]"
    res=$(webauto ml package-release pull \
        --project-id prd_jt \
        --package-id "$package_id" \
        --package-release-id "$release_id" \
        --target-dir ./tmp \
        --output json--quiet 2>&1)
    # Check if the command output contains the error message
    if echo "$res" | grep -q "Error:" || echo "$res" | grep -q "\[403\]"; then
        echo -e "\e[31mError in downloading release. Please check network connection and try again.\e[0m"
        echo "$release_id: $res"
        exit 1
    fi

    echo "finished downloading the release $ml_packages_name [$release_id]"
    sudo mv ./tmp/"$release_id"/* /opt/autoware/mlmodels/
done <<<"$ml_packages"
