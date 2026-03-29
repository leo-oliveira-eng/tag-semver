#!/usr/bin/env bash

SEMVER_REGEX='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'

PARSED_MAJOR=""
PARSED_MINOR=""
PARSED_PATCH=""
PARSED_PRERELEASE=""

normalize_bump_type() {
  case "$1" in
  major | minor | patch)
    printf '%s' "$1"
    ;;
  *)
    return 1
    ;;
  esac
}

validate_numeric_identifier() {
  [[ "$1" =~ ^0$|^[1-9][0-9]*$ ]]
}

validate_dot_separated_identifiers() {
  local value="$1"
  local strict_numeric="${2:-false}"
  local part
  local -a parts=()

  [[ -n "$value" ]] || return 1

  IFS='.' read -r -a parts <<<"$value"
  for part in "${parts[@]}"; do
    [[ -n "$part" ]] || return 1
    [[ "$part" =~ ^[0-9A-Za-z-]+$ ]] || return 1

    if [[ "$strict_numeric" == "true" && "$part" =~ ^[0-9]+$ ]]; then
      validate_numeric_identifier "$part" || return 1
    fi
  done
}

validate_prerelease_channel() {
  validate_dot_separated_identifiers "$1" "true"
}

validate_build_metadata() {
  validate_dot_separated_identifiers "$1" "false"
}

strip_tag_prefix() {
  local tag="$1"
  local prefix="$2"

  if [[ -z "$prefix" ]]; then
    printf '%s' "$tag"
    return 0
  fi

  if [[ "$tag" != "$prefix"* ]]; then
    return 1
  fi

  printf '%s' "${tag#"$prefix"}"
}

parse_semver_version() {
  local version="$1"
  local prerelease=""
  local build_metadata=""

  if [[ ! "$version" =~ $SEMVER_REGEX ]]; then
    return 1
  fi

  PARSED_MAJOR="${BASH_REMATCH[1]}"
  PARSED_MINOR="${BASH_REMATCH[2]}"
  PARSED_PATCH="${BASH_REMATCH[3]}"
  prerelease="${BASH_REMATCH[5]:-}"
  build_metadata="${BASH_REMATCH[8]:-}"

  if [[ -n "$prerelease" ]]; then
    validate_dot_separated_identifiers "$prerelease" "true" || return 1
  fi

  if [[ -n "$build_metadata" ]]; then
    validate_build_metadata "$build_metadata" || return 1
  fi

  PARSED_PRERELEASE="$prerelease"
  return 0
}

parse_semver_tag() {
  local tag="$1"
  local prefix="$2"
  local version=""

  version="$(strip_tag_prefix "$tag" "$prefix")" || return 1
  parse_semver_version "$version"
}

calculate_next_tag() {
  local previous_tag="$1"
  local bump_type="$2"
  local prerelease_channel="$3"
  local build_metadata="$4"
  local prefix="$5"
  local major=0
  local minor=0
  local patch=0
  local latest_prerelease=""
  local next_prerelease=""
  local latest_prerelease_channel=""
  local latest_prerelease_number=""
  local version=""

  parse_semver_tag "$previous_tag" "$prefix" || {
    error "Could not parse latest SemVer tag: $previous_tag"
    return 1
  }

  major="$PARSED_MAJOR"
  minor="$PARSED_MINOR"
  patch="$PARSED_PATCH"
  latest_prerelease="$PARSED_PRERELEASE"

  if [[ -n "$prerelease_channel" ]]; then
    if [[ -n "$latest_prerelease" && "$latest_prerelease" =~ ^(.*)\.([0-9]+)$ ]]; then
      latest_prerelease_channel="${BASH_REMATCH[1]}"
      latest_prerelease_number="${BASH_REMATCH[2]}"

      if [[ "$latest_prerelease_channel" == "$prerelease_channel" ]] && validate_numeric_identifier "$latest_prerelease_number"; then
        next_prerelease="$prerelease_channel.$((10#$latest_prerelease_number + 1))"
        version="${major}.${minor}.${patch}-${next_prerelease}"
      fi
    fi

    if [[ -z "$version" ]]; then
      case "$bump_type" in
      major)
        ((major += 1))
        minor=0
        patch=0
        ;;
      minor)
        ((minor += 1))
        patch=0
        ;;
      patch)
        ((patch += 1))
        ;;
      *)
        error "Unsupported bump type: $bump_type"
        return 1
        ;;
      esac

      next_prerelease="${prerelease_channel}.1"
      version="${major}.${minor}.${patch}-${next_prerelease}"
    fi
  else
    case "$bump_type" in
    major)
      ((major += 1))
      minor=0
      patch=0
      ;;
    minor)
      ((minor += 1))
      patch=0
      ;;
    patch)
      ((patch += 1))
      ;;
    *)
      error "Unsupported bump type: $bump_type"
      return 1
      ;;
    esac

    version="${major}.${minor}.${patch}"
  fi

  if [[ -n "$build_metadata" ]]; then
    version="${version}+${build_metadata}"
  fi

  printf '%s%s\n' "$prefix" "$version"
}
