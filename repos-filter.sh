#!/bin/bash

# Usage: ./repos-filter.sh <repos_file> <label1> [label2] [label3] ...
# Example: ./repos-filter.sh autoware.repos lbl1 lbl2 | vcs import src

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <repos_file> <label1> [label2] ..." >&2
    echo "Example: $0 autoware.repos main common | vcs import src" >&2
    exit 1
fi

REPOS_FILE="$1"
shift

if [ ! -f "$REPOS_FILE" ]; then
    echo "Error: File '$REPOS_FILE' not found" >&2
    exit 1
fi

# Build the yq filter expression for multiple labels
# We want to select repositories where labels contain any of the provided labels
LABELS=("$@")

# Build the condition: (.value.labels // [] | any_c(. == "label1")) or (.value.labels // [] | any_c(. == "label2")) ...
CONDITION=""
for label in "${LABELS[@]}"; do
    if [ -n "$CONDITION" ]; then
        CONDITION="$CONDITION or "
    fi
    CONDITION="$CONDITION(.value.labels // [] | any_c(. == \"$label\"))"
done

# Apply the filter
yq ".repositories |= with_entries(select($CONDITION))" "$REPOS_FILE"
