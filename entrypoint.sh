#!/bin/sh -l

sh -c "git config --global --add safe.directory $PWD"

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

# Configure the remote URL with the token for authentication
echo "Setting up remote URL with authentication token..."
git remote set-url origin https://x-access-token:${ACTIONS_TOKEN}@github.com/${GITHUB_REPOSITORY}

# Verify remote URL is correctly set
git remote -v

# Create and push the new tag
echo "Creating and pushing the new tag..."
git tag $new_tag
git push origin $new_tag

echo "New tag created: $new_tag"
