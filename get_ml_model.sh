#!/bin/bash

# path to .webauto-ci.yml
file_path="./.webauto-ci.yml"

# select the target ECU for downloading the corresponding ml model
ecu_for_ml_packages=main

if ! (type "webauto" >/dev/null 2>&1); then
    echo -e "\e[31mPlease Install webauto cli.\e[m"
    echo -e "\e[31mhttps://github.com/tier4/WebAutoCLI\e[m"
    exit 1
fi

sudo mkdir -p /opt/autoware/mlmodels/

# cspell: ignore RLENGTH
ml_packages=$(awk -v ecu="$ecu_for_ml_packages" '
# check scope
match($0, "^  - name: "ecu"$")                { in_each_ecu = 1 }
/- name: asset-deploy/         && in_each_ecu { in_asset = 1}
/ml_packages:/                 && in_asset    { in_ml_packages = 1; match($0, /^ */); ml_packages_indent = RLENGTH; next }

# main
in_ml_packages {
    # check if out of scope
    match($0, /^ */); indent = RLENGTH;
    if (indent <= ml_packages_indent) {
        in_each_ecu = 0; in_asset = 0; in_ml_packages = 0; next
    }

    # get name and release in ml_packages
    if (/name:/) {
        sub(/^ *- name: /, ""); name=$0
    }
    else if (/release:/) {
        sub(/^ *release: /, ""); release=$0
        printf "%s %s\n", name, release
    }
}
' "$file_path")

while read -r line; do
    ml_packages_name=$(echo "$line" | awk '{print $1}')
    ml_packages_release=$(echo "$line" | awk '{print $2}')

    # search release of ml packages
    res=$(webauto ml package-release search \
        --project-id x2_dev \
        --package-name "$ml_packages_name" \
        --package-release-name "$ml_packages_release" \
        --output json --quiet)

    release=$(echo "$res" | jq -c '.releases[0]')
    package_id=$(echo "$release" | jq -r '.package_id')
    release_id=$(echo "$release" | jq -r '.id')

    echo "ml packages name: $ml_packages_name"
    echo "ml packages id  : $package_id"
    echo "release         : $ml_packages_release"
    echo "release id      : $release_id"

    # download ml packages
    res=$(webauto ml package-release pull \
        --project-id x2_dev \
        --package-id "$package_id" \
        --package-release-id "$release_id" \
        --target-dir ./tmp \
        --output json --quiet 2>&1)
    if echo "$res" | grep -q "Error:" || echo "$res" | grep -q "\[403\]"; then
        echo -e "\e[31m$res\e[0m"
        echo -e "\e[31mFailed to download ml model. [$ml_packages_name]\e[0m"
        exit 1
    fi
    echo "Successfully downloaded ml package. [./tmp/$release_id/$ml_packages_name]"

    # delete existing ml packages and move new ml packages
    sudo rm -rf /opt/autoware/mlmodels/"$ml_packages_name"
    if ! res=$(sudo mv ./tmp/"$release_id"/"$ml_packages_name" /opt/autoware/mlmodels/ 2>&1); then
        echo -e "\e[31m$res\e[0m"
        exit 1
    fi
    echo "Successfully move ml packages. [/opt/autoware/mlmodels/$ml_packages_name]"
    echo ""
done <<<"$ml_packages"
