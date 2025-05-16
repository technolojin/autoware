#!/bin/bash
set -e

# Initialize an array to store issues
issues=()

# Function to check if a repository has a base tag (either true or false)
check_base_tag() {
    local repo_name="$1"
    # Use yq to check if base tag exists and is a boolean
    if ! yq -e ".repositories.\"$repo_name\".base | type == \"!!bool\"" autoware.repos >/dev/null 2>&1; then
        issues+=("❌ Repository $repo_name is missing 'base' tag or it's not a boolean value")
    fi
}

# Extract all repository names from autoware.repos using yq
repos=$(yq '.repositories | keys | .[]' autoware.repos)

# Check each repository
for repo in $repos; do
    check_base_tag "$repo"
done

# Print all issues if any exist
if [ ${#issues[@]} -ne 0 ]; then
    echo "Found the following issues:"
    printf '%s\n' "${issues[@]}"
    exit 1
fi

echo "✅ All repositories have a valid 'base' tag (true or false)"
