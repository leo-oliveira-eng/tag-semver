#!/bin/bash
set -e

git config --global --add safe.directory /github/workspace

# Logging helpers
info() { echo "::notice::ℹ️ $*"; }
success() { echo "::notice::✅ $*"; }
error() { echo "::error::❌ $*"; }

get_latest_tag() {
  git fetch --tags --quiet
  git tag --list | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$' | sort -V | tail -n 1
}

increment_version() {
  local version=$1
  local part=$2

  IFS='.' read -r major minor patch <<<"${version#v}"

  case "$part" in
    major) ((major++)); minor=0; patch=0 ;;
    minor) ((minor++)); patch=0 ;;
    patch) ((patch++)) ;;
  esac

  echo "$major.$minor.$patch"
}

extract_pr_number() {
  echo "$GITHUB_REF" | grep -oE '[0-9]+$'
}

get_pr_labels() {
  gh pr view "$1" --json labels --jq '.labels[].name'
}

determine_bump_type() {
  local labels=("$@")
  for label in "${labels[@]}"; do
    case "$label" in
      version:major) echo "major"; return ;;
      version:minor) echo "minor"; return ;;
      version:patch) echo "patch"; return ;;
    esac
  done
  echo "patch"
}

determine_pre_release() {
  local labels=("$@")
  for label in "${labels[@]}"; do
    case "$label" in
      pre-release:alpha) echo "alpha"; return ;;
      pre-release:beta) echo "beta"; return ;;
      pre-release:rc) echo "rc"; return ;;
    esac
  done
}

determine_build_metadata() {
  local labels=("$@")
  for label in "${labels[@]}"; do
    [[ "$label" =~ ^build:(.+)$ ]] && echo "${BASH_REMATCH[1]}" && return
  done
}

get_next_pre_release_number() {
  local base_version=$1
  local pre_id=$2

  git tag --list "${base_version}-${pre_id}.*" \
    | sed -E "s/^${base_version}-${pre_id}\.//" \
    | grep -E '^[0-9]+$' \
    | sort -n | tail -n 1 | { read latest || true; echo $((latest + 1)); }
}

main() {
  info "🔧 Setting up Git config"
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"

  info "🔍 Getting PR number from event payload"
  pr_number=$(extract_pr_number)
  [[ -z "$pr_number" ]] && error "Cannot determine PR number" && exit 1

  info "🔍 Fetching PR labels..."
  mapfile -t labels < <(get_pr_labels "$pr_number")
  info "🏷️ PR Labels: ${labels[*]}"

  bump_type=$(determine_bump_type "${labels[@]}")
  info "📦 Bump type: $bump_type"

  pre_release=$(determine_pre_release "${labels[@]}")
  build_meta=$(determine_build_metadata "${labels[@]}")

  info "📥 Fetching tags..."
  latest_tag=$(get_latest_tag)
  [[ -z "$latest_tag" ]] && latest_tag="v0.0.0"
  info "🏷️ Latest tag: $latest_tag"

  base_version="v$(increment_version "$latest_tag" "$bump_type")"

  if [[ -n "$pre_release" ]]; then
    suffix=$(get_next_pre_release_number "$base_version" "$pre_release")
    new_tag="${base_version}-${pre_release}.${suffix}"
  else
    new_tag="$base_version"
  fi

  [[ -n "$build_meta" ]] && new_tag="${new_tag}+${build_meta}"

  info "🚀 New tag: $new_tag"

  git tag "$new_tag"
  git push origin "$new_tag"

  success "Tag $new_tag created and pushed."
}

main "$@"
