#!/bin/sh -l

sh -c "git config --global --add safe.directory $PWD"

set -e

git fetch --tags

latest_tag=$(git describe --tags `git rev-list --tags --max-count=1` 2>/dev/null || echo "0.0.0")

branch_name=$(echo "${GITHUB_REF#refs/heads/}")

if [[ "$branch_name" == "main" || "$branch_name" == "master" ]]; then
  new_tag=$(echo $latest_tag | awk -F. '{print $1"."$2"."$3+1}')
elif [[ "$branch_name" == *"feature"* ]]; then
  new_tag=$(echo $latest_tag | awk -F. '{print $1"."$2+1".0"}')
else
  new_tag=$(echo $latest_tag | awk -F. '{print $1+1".0.0"}')
fi

git tag $new_tag

git push origin $new_tag

echo "New tag created: $new_tag"
