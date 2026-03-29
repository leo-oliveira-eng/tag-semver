#!/usr/bin/env bash

set -euo pipefail

target_dir="${1:?Target directory is required.}"

mkdir -p "$target_dir"
find "$target_dir" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

cp action.yml "$target_dir/action.yml"
cp Dockerfile "$target_dir/Dockerfile"
cp entrypoint.sh "$target_dir/entrypoint.sh"
cp -R lib "$target_dir/lib"
cp README.md "$target_dir/README.md"
cp LICENSE "$target_dir/LICENSE"
