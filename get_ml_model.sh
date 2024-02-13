#!/bin/bash

# path to .webauto-ci.yml
file_path="./.webauto-ci.yml"

# get name and release in ml_packages
ml_packages=$(awk '/ml_packages:/,/^[^ ]/{if(/name:/){sub(/^[[:space:]]*-?[[:space:]]*name:[[:space:]]*/,""); name=$0} else if(/release:/){sub(/^[[:space:]]*-?[[:space:]]*release:[[:space:]]*/,""); release=$0; printf "%s %s\n", name, release}}' "$file_path")
while read -r line; do
    ml_packages_name=$(echo "$line" | awk '{print $1}')
    ml_packages_release=$(echo "$line" | awk '{print $2}')
done <<<"$ml_packages"

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
echo "start downloading the release [$release_id]"
res=$(webauto ml package-release pull \
    --project-id prd_jt \
    --package-id "$package_id" \
    --package-release-id "$release_id" \
    --target-dir ./tmp \
    --output json--quiet)
echo "finished downloading the release [$release_id]"

sudo mv ./tmp/"$release_id"/* /opt/autoware/mlmodels/
