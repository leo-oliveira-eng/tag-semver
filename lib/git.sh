#!/usr/bin/env bash

fetch_tags() {
  if git remote get-url origin >/dev/null 2>&1; then
    git fetch --force --tags origin
  else
    warn "No origin remote was found. Continuing with local tags only."
  fi
}

resolve_latest_semver_tag() {
  local prefix="$1"
  local tag=""

  while IFS= read -r tag; do
    [[ -n "$tag" ]] || continue
    if parse_semver_tag "$tag" "$prefix"; then
      printf '%s\n' "$tag"
      return 0
    fi
  done < <(git tag --list --sort=-v:refname)

  printf '%s0.0.0\n' "$prefix"
}
