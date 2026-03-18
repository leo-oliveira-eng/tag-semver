#!/usr/bin/env bash

PARSED_BUMP_TYPE=""
PARSED_PRERELEASE_CHANNEL=""
PARSED_BUILD_LABEL=""

parse_labels() {
  local labels="$1"
  local major_label="$2"
  local minor_label="$3"
  local patch_label="$4"
  local prerelease_prefix="$5"
  local build_prefix="$6"
  local default_bump="$7"
  local label=""
  local bump_count=0

  PARSED_BUMP_TYPE=""
  PARSED_PRERELEASE_CHANNEL=""
  PARSED_BUILD_LABEL=""

  while IFS= read -r label; do
    [[ -n "$label" ]] || continue

    if [[ "$label" == "$major_label" ]]; then
      PARSED_BUMP_TYPE="major"
      ((bump_count += 1))
      continue
    fi

    if [[ "$label" == "$minor_label" ]]; then
      PARSED_BUMP_TYPE="minor"
      ((bump_count += 1))
      continue
    fi

    if [[ "$label" == "$patch_label" ]]; then
      PARSED_BUMP_TYPE="patch"
      ((bump_count += 1))
      continue
    fi

    if [[ -n "$prerelease_prefix" && "$label" == "$prerelease_prefix"* ]]; then
      [[ -z "$PARSED_PRERELEASE_CHANNEL" ]] || {
        error "Multiple prerelease labels were found."
        return 1
      }
      PARSED_PRERELEASE_CHANNEL="${label#"$prerelease_prefix"}"
      validate_prerelease_channel "$PARSED_PRERELEASE_CHANNEL" || {
        error "Invalid prerelease label value: $PARSED_PRERELEASE_CHANNEL"
        return 1
      }
      continue
    fi

    if [[ -n "$build_prefix" && "$label" == "$build_prefix"* ]]; then
      [[ -z "$PARSED_BUILD_LABEL" ]] || {
        error "Multiple build metadata labels were found."
        return 1
      }
      PARSED_BUILD_LABEL="${label#"$build_prefix"}"
      validate_build_metadata "$PARSED_BUILD_LABEL" || {
        error "Invalid build metadata label value: $PARSED_BUILD_LABEL"
        return 1
      }
      continue
    fi
  done <<<"$labels"

  if ((bump_count > 1)); then
    error "Multiple bump labels were found. Only one bump label is allowed."
    return 1
  fi

  if ((bump_count == 0)); then
    if [[ -n "$default_bump" ]]; then
      PARSED_BUMP_TYPE="$(normalize_bump_type "$default_bump")" || {
        error "Invalid default bump value: $default_bump"
        return 1
      }
    else
      error "No bump label was found and no default bump was configured."
      return 1
    fi
  fi
}
