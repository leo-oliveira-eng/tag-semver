#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
source "$LIB_DIR/log.sh"
# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/semver.sh
source "$LIB_DIR/semver.sh"
# shellcheck source=lib/labels.sh
source "$LIB_DIR/labels.sh"
# shellcheck source=lib/git.sh
source "$LIB_DIR/git.sh"
# shellcheck source=lib/github.sh
source "$LIB_DIR/github.sh"

write_common_outputs() {
  set_output "previous-tag" "${1-}"
  set_output "next-tag" "${2-}"
  set_output "base-branch" "${3-}"
  set_output "bump-type" "${4-}"
  set_output "prerelease" "${5-}"
  set_output "build-metadata" "${6-}"
  set_output "tag-created" "${7-}"
}

main() {
  local token="${INPUT_TOKEN:-}"
  local allowed_base_branches="${INPUT_ALLOWED_BASE_BRANCHES:-main,master}"
  local tag_prefix="${INPUT_TAG_PREFIX:-v}"
  local major_label="${INPUT_MAJOR_LABEL:-version:major}"
  local minor_label="${INPUT_MINOR_LABEL:-version:minor}"
  local patch_label="${INPUT_PATCH_LABEL:-version:patch}"
  local prerelease_label_prefix="${INPUT_PRERELEASE_LABEL_PREFIX:-pre-release:}"
  local build_label_prefix="${INPUT_BUILD_LABEL_PREFIX:-build:}"
  local default_bump="${INPUT_DEFAULT_BUMP:-}"
  local dry_run="${INPUT_DRY_RUN:-false}"
  local merged=""
  local pr_number=""
  local base_branch=""
  local labels=""
  local previous_tag=""
  local next_tag=""

  require_non_empty "$token" "Missing GitHub token. Set the 'token' input."
  require_non_empty "${GITHUB_EVENT_PATH:-}" "GITHUB_EVENT_PATH is required."

  if [[ -n "$default_bump" ]]; then
    default_bump="$(normalize_bump_type "$default_bump")" || {
      error "Invalid default bump value: $default_bump"
      return 1
    }
  fi

  export GH_TOKEN="$token"

  git config --global --add safe.directory /github/workspace
  git config --global user.name "github-actions[bot]"
  git config --global user.email "github-actions[bot]@users.noreply.github.com"

  pr_number="$(read_pr_field '.pull_request.number // empty')"
  merged="$(read_pr_field '.pull_request.merged // false')"
  base_branch="$(read_pr_field '.pull_request.base.ref // empty')"

  if [[ -z "$pr_number" || -z "$base_branch" ]]; then
    error "This action must be run from a pull_request event payload."
    return 1
  fi

  if [[ "$merged" != "true" ]]; then
    info "Pull request #$pr_number was not merged. Skipping tag creation."
    write_common_outputs "" "" "$base_branch" "" "" "" "false"
    return 0
  fi

  if ! is_allowed_branch "$base_branch" "$allowed_base_branches"; then
    info "Base branch '$base_branch' is not in the allowed branch list. Skipping."
    write_common_outputs "" "" "$base_branch" "" "" "" "false"
    return 0
  fi

  labels="$(github_get_pr_labels "$pr_number")"
  parse_labels \
    "$labels" \
    "$major_label" \
    "$minor_label" \
    "$patch_label" \
    "$prerelease_label_prefix" \
    "$build_label_prefix" \
    "$default_bump"

  fetch_tags
  previous_tag="$(resolve_latest_semver_tag "$tag_prefix")"
  next_tag="$(calculate_next_tag "$previous_tag" "$PARSED_BUMP_TYPE" "$PARSED_PRERELEASE_CHANNEL" "$PARSED_BUILD_LABEL" "$tag_prefix")"

  write_common_outputs \
    "$previous_tag" \
    "$next_tag" \
    "$base_branch" \
    "$PARSED_BUMP_TYPE" \
    "$PARSED_PRERELEASE_CHANNEL" \
    "$PARSED_BUILD_LABEL" \
    "false"

  if git rev-parse --verify --quiet "refs/tags/$next_tag" >/dev/null; then
    error "The computed tag already exists: $next_tag"
    return 1
  fi

  if is_truthy "$dry_run"; then
    info "Dry run enabled. Computed tag '$next_tag' was not created."
    return 0
  fi

  git tag "$next_tag"
  git push origin "$next_tag"

  set_output "tag-created" "true"
  info "Tag created and pushed: $next_tag"
}
