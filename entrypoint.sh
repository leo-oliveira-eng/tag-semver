#!/bin/sh
set -e

echo "Starting tag creation process"

echo "Fetching tags..."
git fetch --tags

latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")
branch_name=$(git rev-parse --abbrev-ref HEAD)

echo "Latest tag: $latest_tag"
echo "Branch name: $branch_name"

version=$(echo "$latest_tag" | sed 's/^v//')
major=$(echo "$version" | cut -d. -f1)
minor=$(echo "$version" | cut -d. -f2)
patch=$(echo "$version" | cut -d. -f3)

# Default to 0.1.0 if empty
major=${major:-0}
minor=${minor:-1}
patch=${patch:-0}

# Simple bumping logic (patch)
patch=$((patch + 1))
new_tag="v$major.$minor.$patch"

echo "New tag: $new_tag"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git tag "$new_tag"
git push origin "$new_tag"
