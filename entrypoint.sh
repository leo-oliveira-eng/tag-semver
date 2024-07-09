#!/bin/sh -l

set -e

echo "Starting tag creation process"

# Fetch all tags
echo "Fetching tags..."
git remote set-url origin https://x-access-token:${ACTIONS_TOKEN}@github.com/${GITHUB_REPOSITORY}
git fetch --tags

# Get the latest tag or default to 0.0.0 if no tags exist
latest_tag=$(git describe --tags `git rev-list --tags --max-count=1` 2>/dev/null || echo "0.0.0")
echo "Latest tag: $latest_tag"

# Get current branch
branch_name=$(echo "${GITHUB_REF#refs/heads/}")
echo "Branch name: $branch_name"

# Increment version based on branch
if [[ "$branch_name" == "main" || "$branch_name" == "master" ]]; then
  new_tag=$(echo $latest_tag | awk -F. '{print $1"."$2"."$3+1}')
elif [[ "$branch_name" == *"feature"* ]]; then
  new_tag=$(echo $latest_tag | awk -F. '{print $1"."$2+1".0"}')
else
  new_tag=$(echo $latest_tag | awk -F. '{print $1+1".0.0"}')
fi

echo "New tag: $new_tag"

# Output the new tag version
echo "::set-output name=new_tag::$new_tag"
